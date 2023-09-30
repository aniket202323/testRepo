-- DESCRIPTION: spXLA_DowntimeSummary_AP handles both original and applied product filter. Any product is not a valid option
-- for applied product filter. When no-product is req, we use a different stored procedure (spXLA_DowntimeDetail_NoProduct). 
-- MT/3-26-2002. 
-- MT/4-9-2002:  Added Uptime
-- MT/6-26-2002: Defect #24039 always returns totoal operating minutes, the difference between start & end times, even when 
--               there is no downtime data in specified time range.
-- MT/9-9-2002:  Defect #24434:fix join condition -- when unit is specified remove ps.Pu_Id = D.Source_Pu_Id; when unit NOT
--               specified use ps.PU_Id = D.PU_Id
--
-- ECR #30478: mt/8-8-2005 -- sync summary number of occurrences with row counts in downtime details; keep rows with null SourcePU if master unit matches input PU_Id
--
CREATE PROCEDURE dbo.spXLA_DowntimeSummary_AP
 	   @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Pu_Id 	  	 Int 	  	 --Add-In's "Line" Is masterUnit here
 	 , @SelectSource  	 Int 	  	 --Slave Units Pu_Id in Timed_Event_
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @ReasonLevel 	  	 Int
 	 , @Prod_Id 	  	 Int
 	 , @Group_Id 	  	 Int
 	 , @Prop_Id 	  	 Int
 	 , @Char_Id 	  	 Int
 	 , @IsAppliedProdFilter 	 TinyInt 	  	 --1=Yes filter by Applied Product; 0 = No, Filter By Original Product
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
-- SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Local query assistance
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
 	 --Downtime-Related Identifiers
DECLARE @TotalPLT 	  	 Real
DECLARE @TotalOperating  	 Real
DECLARE @MasterUnit 	  	 Int
DECLARE @RowCount 	  	 Int
 	 --Needed for Cursor ...
DECLARE @Prev_Ps_Start_Time     DateTime
DECLARE @Prev_Ps_End_Time       DateTime
DECLARE @Previous_End_Time 	 DateTime
DECLARE @Previous_Pu_Id 	  	 Int
DECLARE @Previous_Prod_Id  	 Int
DECLARE @Previous_ApProd_Id 	 Int
DECLARE @Original_Found 	         Int
DECLARE @Sum_Original_Found 	 Int
DECLARE @AP_Found 	  	 Int
DECLARE @Sum_AP_Found 	  	 Int
DECLARE @Saved_Start_Time 	 DateTime
DECLARE @Fetch_Count            Int
DECLARE @@Ps_Start_Time         DateTime
DECLARE @@Ps_End_Time           DateTime
DECLARE @@Start_Time            	 DateTime
DECLARE @@End_Time              	 DateTime
DECLARE @@Pu_Id                 	 Int
DECLARE @@Prod_Id 	  	 Int
DECLARE @@Applied_Prod_Id 	 Int
DECLARE @UserId 	 Int
SELECT @UserId = User_Id
FROM users
WHERE Username = @Username
EXEC dbo.spXLA_RegisterConnection @UserId,@Langid
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
If @Pu_Id Is NULL SELECT @MasterUnit = NULL Else Select @MasterUnit = @Pu_Id
CREATE TABLE #Prod_Starts (Pu_Id Int, prod_id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (prod_id Int)
CREATE TABLE #Applied_Products (Pu_Id Int, Ps_Start_Time DateTime, Ps_End_Time DateTime NULL, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL, Keep_Event TinyInt NULL)
CREATE TABLE #MyReport (
 	   ReasonName 	  	 varchar(100) NULL     --mt/6-26-2002 make nullable
 	 , NumberOfOccurances 	 Int          NULL
 	 , TotalReasonMinutes  	 Real         NULL
 	 , AvgReasonMinutes  	 Real         NULL
 	 , TotalDowntimeMinutes 	 Real         NULL
        , AvgUptimeMinutes      Real         NULL 	 --MT/4-9-2002
        , TotalUptimeMinutes    Real         NULL 	 --MT/4-9-2002
 	 , TotalOperatingMinutes Real         NULL
)
-- Get All TED Records In Field I Care About
CREATE TABLE #TopNDR (
          Detail_Id         Int  
  	 , Start_Time        DateTime
 	 , End_Time          DateTime     NULL
 	 , Duration          Real         NULL
        , Uptime            Real         NULL 	 --MT/4-9-2002
 	 , Reason_Name       varchar(100) NULL
 	 , SourcePU          Int          NULL
 	 , MasterUnit        Int          NULL
 	 , R1_Id 	             Int          NULL
 	 , R2_Id 	             Int          NULL
 	 , R3_Id 	             Int          NULL
 	 , R4_Id 	             Int          NULL
 	 , Prod_Id           Int          NULL
        , Applied_Prod_Id   Int          NULL
 	 , Fault_Id          Int          NULL
 	 , Status_Id         Int          NULL 
)
--Figure Out Query Type Based on Product Info given
-- NOTE: We DO NOT handle all possible NULL combinations of product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
-- Proficy Add-In blocks out illegal combinations, and allows only these combination:
--     * Property AND Characteristic 
--     * Group Only
--     * Group, Propery, AND Characteristic
--     * Product Only
--     * No Product Information At All 
SELECT @SingleProduct 	  	 = 1
SELECT @Group 	  	  	 = 2
SELECT @Characteristic 	  	 = 3
SELECT @GroupAndProperty 	 = 4
SELECT @NoProductSpecified 	 = 5
If      @Prod_Id Is NOT NULL 	  	  	  	 SELECT @QueryType = @SingleProduct   	 --1
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL 	 SELECT @QueryType = @Group   	  	 --2
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL 	 SELECT @QueryType = @Characteristic  	 --3
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL 	 SELECT @QueryType = @GroupAndProperty 	 --4
Else 	  	  	  	  	  	  	 SELECT @QueryType = @NoProductSpecified 	 --5
--EndIf
If @IsAppliedProdFilter = 1 GOTO APPLIED_PRODUCT_FILTER
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Get Product And Related Info from Production_Starts Table
-- NOTE: "No Product Specified" Case remains here for debugging (validity check against the older spXLA_DowntimeDetail)
If @QueryType = @NoProductSpecified 	 --5
  BEGIN
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #prod_starts
          SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE Start_Time BETWEEN @Start_Time AND @End_Time
              OR End_Time BETWEEN @Start_Time AND @End_Time 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null)) 	 --MSi/MT/3-14-2001 	  	     
      END
    Else    --@MasterUnit not null
      BEGIN
        INSERT INTO #prod_starts
          SELECT ps.PU_Id, ps.prod_id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE (ps.PU_Id = @MasterUnit AND  ps.PU_Id <> 0)
             AND (    Start_Time BETWEEN @Start_Time AND @End_Time 
                   OR End_Time BETWEEN @Start_Time AND @End_Time 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is null)) --change Start_Time & End_Time conditions ; MSi/MT/3-14-2001
                 )     
      END
    --EndIf @MasterUnit
  END
If @QueryType = @SingleProduct   	 --1
  BEGIN
    IF @MasterUnit IS NULL
      BEGIN
        INSERT INTO #Prod_Starts
 	     SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
 	       FROM production_starts ps
 	      WHERE prod_id = @Prod_Id 
 	        AND ( 	  Start_Time BETWEEN @Start_Time AND @End_Time
 	  	      OR End_Time BETWEEN @Start_Time AND @End_Time
 	  	      OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL)) --Change Start_Time < @Start_Time to Start_Time <= @Start_Time ; Msi/Mt/3-14-2001
                   )   
      END
    ELSE     --@MasterUnit not NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE Pu_Id = @MasterUnit 
             AND Pu_Id <> 0
             AND prod_id = @Prod_Id 
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL)) --Change Start_Time < @Start_Time to Start_Time <= @Start_Time ; Msi/Mt/3-14-2001
                 )    
      END
    --ENDIF @MasterUnit
  END
Else 	  	  	  	  	 --We have product grouping info
  BEGIN
    If @QueryType = @Group 	  	  	 --2
      BEGIN
        INSERT INTO #products
        SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @Characteristic  	 --3
      BEGIN
        INSERT INTO #products
        SELECT DISTINCT prod_id  FROM pu_characteristics  WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else 	  	  	  	  	 --Group & Property (4)
      BEGIN
        INSERT INTO #products
        SELECT prod_id FROM product_group_data WHERE product_grp_id = @Group_Id
        INSERT INTO #products
        SELECT DISTINCT prod_id  FROM pu_characteristics  WHERE prop_id = @Prop_Id  AND char_id = @Char_Id
      END
    --EndIf @QueryType =2 ...
    If @MasterUnit IS NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
            JOIN #Products p ON ps.prod_id = p.prod_id 
           WHERE (Start_Time BETWEEN @Start_Time AND @End_Time)
              OR (End_Time BETWEEN @Start_Time AND @End_Time) 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL)) --Change Start_Time < @Start_Time to Start_Time <= @Start_Time ; Msi/Mt/3-14-2001
      END
    ELSE     --@MasterUnit not NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.prod_id, ps.Start_Time, ps.End_Time
            FROM Production_Starts ps
            JOIN #Products p ON ps.prod_id = p.prod_id 
           WHERE Pu_Id = @MasterUnit AND Pu_Id <> 0
             AND (    Start_Time BETWEEN @Start_Time AND @End_Time
                   OR End_Time BETWEEN @Start_Time AND @End_Time
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL)) --Change Start_Time < @Start_Time to Start_Time <= @Start_Time ; Msi/Mt/3-14-2001
                 )   
      END
    --ENDIF @MasterUnit
  END
--EndIf QueryType ...
-- Insert Data Into Temp Table #TopNDR
If @MasterUnit IS NULL
  BEGIN
    INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Prod_Id, Fault_Id, Status_Id)
      SELECT DISTINCT 
             D.TEDet_Id
           , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
           , [End_Time]   = Case 
                              When D.End_Time Is NULL Then ps.End_Time
                              When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                              When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                              Else D.End_Time
                            End
           , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id, D.Reason_Level1 , D.Reason_Level2, D.Reason_Level3
           , D.Reason_Level4 , ps.Prod_Id , D.TEFault_Id, D.TEStatus_Id  
        FROM Timed_Event_Details D
        JOIN #Prod_Starts ps ON ps.Pu_Id = D.PU_Id --Defect 24434 replaced ps.Pu_Id = D.Source_PU_Id with current code
         AND (    (D.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
               OR (D.End_Time > ps.Start_Time AND D.End_Time <= ps.End_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time <= ps.Start_Time AND (D.End_Time > ps.End_Time OR D.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time >= ps.Start_Time AND D.End_Time Is NULL AND ps.End_Time Is NULL) 
               OR (D.End_Time > ps.Start_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NULL)
             )
        JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
       WHERE D.Start_Time BETWEEN @Start_Time AND @End_Time
          OR D.End_Time BETWEEN @Start_Time AND @End_Time
          OR (D.Start_Time <= @Start_Time AND (D.End_Time > @End_Time OR D.End_Time Is NULL))
  END
Else  --@MasterUnit not NULL
  BEGIN
    INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Prod_Id, Fault_Id, Status_Id)
      SELECT DISTINCT 
             D.TEDet_Id
           , [Start_Time] = Case When D.Start_Time >= ps.Start_Time Then D.Start_Time Else  ps.Start_Time End 
           , [End_Time]   = Case 
                              When D.End_Time Is NULL Then ps.End_Time
                              When ps.End_Time Is NOT NULL AND ps.End_Time <= D.End_Time Then ps.End_Time
                              When ps.End_Time Is NOT NULL AND D.End_Time <= ps.End_Time Then D.End_Time
                              Else D.End_Time
                            End
           , D.Duration, D.Uptime, D.Source_Pu_Id, PU.Pu_Id, D.Reason_Level1 , D.Reason_Level2, D.Reason_Level3
           , D.Reason_Level4 , ps.Prod_Id , D.TEFault_Id, D.TEStatus_Id  
        FROM  Timed_Event_Details D
        --  Defect #24434 removed JOIN #Prod_Starts ps ON ps.Pu_Id = D.Source_PU_Id and use times only
        JOIN #Prod_Starts ps ON 
             (    (D.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
               OR (D.End_Time > ps.Start_Time AND D.End_Time <= ps.End_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time <= ps.Start_Time AND (D.End_Time > ps.End_Time OR D.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
               OR (D.Start_Time >= ps.Start_Time AND D.End_Time Is NULL AND ps.End_Time Is NULL) 
               OR (D.End_Time > ps.Start_Time AND D.End_Time Is NOT NULL AND ps.End_Time Is NULL)
             )
        JOIN Prod_Units PU ON (PU.Pu_Id = D.Pu_Id AND PU.Pu_Id <> 0)
       WHERE (D.Pu_Id = @Pu_Id) 
         AND (    D.Start_Time BETWEEN @Start_Time AND @End_Time
               OR D.End_Time BETWEEN @Start_Time AND @End_Time
               OR (D.Start_Time <= @Start_Time AND (D.End_Time > @End_Time OR D.End_Time Is NULL))
             )
  END
--EndIf @MasterUnit...
GOTO MAKE_DOWNTIME_SUMMARY_REPORT
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
APPLIED_PRODUCT_FILTER:
  --First Grab Relevant Original Product & Related Information From Production_Starts Table 
  BEGIN
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
        SELECT ps.pu_id, ps.Prod_Id, ps.Start_Time, ps.End_Time
          FROM Production_Starts ps
         WHERE (    ps.Start_Time BETWEEN @Start_Time AND @End_Time 
 	  	  OR ps.End_Time BETWEEN @Start_Time AND @End_Time 
 	  	  OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR End_Time Is NULL) ) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               )
       END
    Else --@MasterUnit NOT NULL
      BEGIN
        INSERT INTO #Prod_Starts
        SELECT ps.pu_id, ps.Prod_Id, ps.Start_Time, ps.End_Time
          FROM Production_Starts ps
         WHERE ps.pu_id = @MasterUnit 
 	    AND (    ps.Start_Time BETWEEN @Start_Time AND @End_Time
 	  	  OR ps.End_Time BETWEEN @Start_Time AND @End_Time
 	  	  OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR End_Time Is NULL) ) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
               )
      END 
    --EndIf
  END
  --Grab all of the "Specified" product(s), put them into Temp Table #Products
  If @QueryType = @Group
    BEGIN
       INSERT INTO #Products
       SELECT Prod_Id FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
    END
  Else If @QueryType = @Characteristic
    BEGIN
       INSERT INTO #Products
       SELECT DISTINCT Prod_Id FROM Pu_Characteristics WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
    END
  Else If @QueryType = @GroupAndProperty
    BEGIN
       INSERT INTO #Products
       SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
      INSERT INTO #Products
      SELECT distinct Prod_Id FROM pu_characteristics WHERE Prop_Id = @Prop_Id AND char_id = @Char_Id
    END
  Else -- must be @OneProductFilter
    BEGIN
      INSERT INTO #Products
      SELECT Prod_Id = @Prod_Id
    END
  --EndIf
  -- Get Rows From Events Table for "Products" that fit applied products criteria ... 
  --  When matched product has Applied_Product = NULL, we take that the original product Is applied product.
  --  When matched product has Applied_Product <> NULL, include that product as applied product
  -- NOTE1: JOIN condition for Production_Starts consistent with AutoLog's )
  -- NOTE2: As of 3-25-2002 MSI Start_Time inEvents table are mostly null. This storec procedure will insert
  --        a dummy value of TimeStamp minus one second for null Start_Time. For Customers who are concern about correct 
  --        Start_Time, which affect correct time-dependent results, MSI will give them a script for one-time update of 
  --        the Events table. This update is time/disk-space consuming, thus, available upon request only.
  --Make TEMP TABLE: Split ANY PRODUCT In #Prod_Starts into individual events.
  INSERT INTO #Applied_Products ( Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id )
      SELECT e.Pu_Id, ps.Start_Time, ps.End_Time, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product 
        FROM #Prod_Starts ps 
        JOIN Events e ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
--        JOIN Events e ON ps.Start_Time <= e.Start_Time AND (ps.End_Time >= e.TimeStamp OR ps.End_Time Is NULL)
         AND ps.Pu_Id = e.Pu_Id 
    ORDER BY e.Pu_Id, ps.Start_Time, e.Start_Time, ps.Prod_Id
  -- Use Cursor to track the individual events in #Applied_Products 
  DECLARE TCursor INSENSITIVE CURSOR 
    FOR ( SELECT Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id FROM #Applied_Products )
    FOR READ ONLY
  --END Declare
OPEN_CURSOR_FOR_PROCESSING:
  -- Initialize local variables ......
  SELECT @Saved_Start_Time   = ''
  SELECT @Prev_Ps_Start_Time = ''
  SELECT @Prev_Ps_End_Time   = ''
  SELECT @Previous_Pu_Id     = -1
  SELECT @Previous_End_Time  = ''
  SELECT @Previous_Prod_Id   = -1
  SELECT @Previous_ApProd_Id = -1
  SELECT @Original_Found     = -1
  SELECT @Sum_Original_Found = 0
  SELECT @AP_Found 	      = -1
  SELECT @Sum_AP_Found       = 0
  SELECT @Fetch_Count        = 0
  SELECT @@Ps_Start_Time     = ''
  SELECT @@Ps_End_Time       = ''
  SELECT @@Start_Time        = ''
  SELECT @@End_Time          = ''
  SELECT @@Pu_Id             = -1
  SELECT @@Prod_Id           = -1
  SELECT @@Applied_Prod_Id   = -1
  OPEN TCursor
  --Tracking Product Events by counting successive applied events
  --(a) First loop: Save start time, store fetched variables in the "Previous" local variables
  --(a) Within same ID: 
  --    Switching occurs when Ps_Start_Time --> Ps_End_Time change.
  --    Switching occurs when previous running applied event(s) turn original, or previous running original event(s) 
  --    turn applied. When switching occurs, update the previous row with Saved start time, and mark "Keep": Update only if
  --    Prod_Id(original) or Applied_Prod_Id(applied) matches the filter.
  --(b) When product ID switch occurs: 
  --    Switching occurs when previous running original event(s) turn original, or previous running original event(s) turn
  --    applied, or previous running applied event(s) turn original, or previous running applied event(s) turn applied.
  --    When switching occurs, update the previous row with Saved start time, and mark "Keep": Update only if
  --    Prod_Id(original) or Applied_Prod_Id(applied) matches the filter.
TOP_OF_FETCH_LOOP:
  FETCH NEXT FROM TCursor INTO @@Pu_Id, @@Ps_Start_Time, @@Ps_End_Time, @@Start_Time, @@End_Time, @@Prod_Id, @@Applied_Prod_Id
  If (@@Fetch_Status = 0)
    BEGIN
      -- ********************************************************************************************
      -- FIRST FETCH: 
      If @Previous_Prod_Id = -1 	  	  	                 
        -- The very first fetch, collect row information and save start time
        BEGIN  
          --SELECT @Saved_Start_Time   = @@Start_Time
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
          SELECT @AP_Found           = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found     = 1 - @AP_Found
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
          --First Reel of a product uses start time from Production_Starts
          If @AP_Found = 1 --First reeel as applied product
            BEGIN
              If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @@Applied_Prod_Id)
                BEGIN
                  UPDATE #Applied_Products SET Start_Time = Ps_Start_Time WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                  SELECT @Saved_Start_Time = Ps_Start_Time FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                END
              --EndIf EXISTS
            END
          Else --1st Reel is original product
            BEGIN
             If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @@Prod_Id)
               BEGIN
                 UPDATE #Applied_Products SET Start_Time = Ps_Start_Time WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
                 SELECT @Saved_Start_Time = Ps_Start_Time FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
               END
             --EndIf EXISTS
            END
          --EndIf @AP_Found.
        END
      -- ********************************************************************************************
      -- PRODUCT ID SWITCHED OR PRODUCTION CHANGE OCCURS (SAME ID BUT DIFF START & END TIMES) 
         -- It is the time to 
         -- (a) process last events of previous product. Use Ps_End_Time for last reel)
         -- (b) Update start time for first reel (event) with Ps_Start_Time.
         --
      Else If @Previous_Prod_Id <> @@Prod_Id 
          OR ( @Previous_Prod_Id = @@Prod_Id AND @Prev_Ps_Start_Time <> @@Ps_Start_Time AND (@Prev_Ps_End_Time <> @@Ps_End_Time OR @Prev_Ps_End_Time Is NULL Or @@Ps_End_Time Is NULL) )
        BEGIN                    
          SELECT @AP_Found       = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found = 1 - @AP_Found
          --Update Previous Running Events ...
          If @AP_Found = 1  --fetched event is applied
            BEGIN
              If @Sum_AP_Found = 0  --Running original turns applied
                BEGIN
                  --Update last row of running original
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1  
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS    
                END
              Else --(@Sum_AP_Found >0): Running applied turns applied at new ID
                BEGIN
                  --Update last row of running applied (if Applied_Prod_Id matches filter)
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time                     
                      SELECT @Sum_AP_Found = 0 --reset applied running count
                    END
                  --EndIf:EXISTS
                END
              --EndIf:@Sum_AP_Found =0
            END
          Else  --@AP_Found = 0: Original fetched
            BEGIN
              If @Sum_AP_Found > 0  --Running applied switches to original
                BEGIN                  
                  --Update last row in running AP events (if Applied_Prod_Id matches filter), and reset the running sum
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS
                  SELECT @Sum_AP_Found = 0  --(reset running sum)                                    
                END
              Else --(@Sum_AP_Found = 0): Running original turns original at ID switch
                BEGIN
                  --Update last row in running original events
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                       WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time        
                    END
                  --EndIf:EXISTS
                END
              --EndIf:@Sum_AP_Found >0
            END           
          --EndIf:@AP_Found =1 Block
              --Reset counters (for original product only tracking)
          SELECT @Fetch_Count        = 0
          SELECT @Sum_Original_Found = 0
              --Collect relevant info for this ID ....
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
          --First Reel of product uses start time from Production_Starts
          SELECT @Saved_Start_Time = Ps_Start_Time  FROM #Applied_Products WHERE Pu_Id = @@Pu_Id AND Prod_Id = @@Prod_Id AND End_Time = @@End_Time
        END
      -- ********************************************************************************************
      -- RUNNING PRODUCT -- SAME PRODUCT FETCHED; Has this event been applied?
      Else If @Previous_Prod_Id = @@Prod_Id              
        BEGIN  
          --Get applied/original status
          SELECT @AP_Found       = Case When @@Applied_Prod_Id Is NULL Then 0 Else 1 End
          SELECT @Original_Found = 1 - @AP_Found
          If @AP_Found = 1 --fetched event is applied
            BEGIN
              If @Sum_AP_Found = 0 --Running original switches to applied
                BEGIN
                  --Update last row of running original
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf:EXISTS
                  SELECT @Saved_Start_Time = @@Start_Time --Save start_time
                END
              --EndIf:@Sum_AP_Found =0
            END     
          Else  --(@AP_Found = 0): fetched event is original
            BEGIN
              If @Sum_AP_Found > 0  --Running applied turns original
                BEGIN                  
                  --Update last row in running AP events (if Applied_Prod_Id matches filter), and reset the running sum
                  If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
                    BEGIN
                      UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, Keep_Event = 1 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
                    END
                  --EndIf                      
                  SELECT @Sum_AP_Found = 0  --(reset running sum)                                    
                  SELECT @Saved_Start_Time = @@Start_Time  --Save current original event's Start_Time
                END
              --Else --(@Sum_AP_Found = 0): Running original turns original turns original
                     --(do nothing, just continue accumulate running events)
              --EndIf:@Sum_AP_Found >0
            END           
          --EndIf:@AP_Found =1 Block
              --Collect information of current fetched
          SELECT @Previous_Pu_Id     = @@Pu_Id
          SELECT @Prev_Ps_Start_Time = @@Ps_Start_Time
          SELECT @Prev_Ps_End_Time   = @@Ps_End_Time
          SELECT @Previous_Prod_Id   = @@Prod_Id
          SELECT @Previous_End_Time  = @@End_Time
          SELECT @Previous_ApProd_Id = @@Applied_Prod_Id
              --Accumulate fetched data
          SELECT @Sum_AP_Found 	      = @Sum_AP_Found + @AP_Found
          SELECT @Sum_Original_Found = @Sum_Original_Found + @Original_Found
          SELECT @Fetch_Count        = @Fetch_Count + 1
        END
      --EndIf:@Previous_Prod_Id = -1( Main block )
      GOTO TOP_OF_FETCH_LOOP
    END
  --EndIf (@@Fetch_Status = 0)
  -- ****************************************************************
  --HANDLE END OF LOOP UPDATE: ( single event also included here )
    If @AP_Found = 1  --Last fetch was applied
      BEGIN
        --Handle previously 100% running applied
        If @Fetch_Count = @Sum_AP_Found 
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = Ps_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
          END        
        Else --Not 100% running applied
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_ApProd_Id )
              BEGIN
               UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
            --EndIf:EXISTS
        --EndIf @Fetch_Count
      END
    Else --Last fetch was original (@AP_Found =0)
      BEGIN
        --Handle previously 100% Running original events, use times from production_Starts table
        If @Fetch_Count = @Sum_Original_Found
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = Ps_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
          END     
        Else --not 100% running original event; use times from Events table
          BEGIN
            If EXISTS ( SELECT Prod_Id FROM #Products WHERE Prod_Id = @Previous_Prod_Id )
              BEGIN
                UPDATE #Applied_Products SET Start_Time = @Saved_Start_Time, End_Time = Ps_End_Time, Keep_Event = 1 
                 WHERE Pu_Id = @Previous_Pu_Id AND Prod_Id = @Previous_Prod_Id AND End_Time = @Previous_End_Time
              END
            --EndIf:EXISTS
          END
        --EndIf:@Fetch_Count = @Sum_Original_Found
      END
    --EndIf:@Sum_AP_Found =1
  CLOSE TCursor
  DEALLOCATE TCursor
  -- DELETE UNMARKED ROWS .....
  DELETE FROM #Applied_Products WHERE Keep_Event Is NULL
  -- Insert Data Into Temp Table #TopNDR
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ap.End_Time
                                When ap.End_Time Is NOT NULL AND ap.End_Time <= D.End_Time Then ap.End_Time
                                When ap.End_Time Is NOT NULL AND D.End_Time <= ap.End_Time Then D.End_Time
                                Else D.End_Time 
                              End
             , D.Duration , D.Uptime , D.Source_PU_Id , PU.PU_Id , D.Reason_Level1 , D.Reason_Level2 , D.Reason_Level3
             , D.Reason_Level4 , ap.Prod_Id , ap.Applied_Prod_Id , D.TEFault_Id , D.TEStatus_Id
          FROM Timed_Event_Details D
          JOIN #Applied_Products ap ON ap.PU_Id = D.PU_Id --Defect #24434: replaced ap.PU_Id = D.Source_PU_Id with current code
           AND (    (D.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
                 OR (D.End_Time > ap.Start_Time AND D.End_Time <= ap.End_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time <= ap.Start_Time AND (D.End_Time > ap.End_Time OR D.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time >= ap.Start_Time AND D.End_Time Is NULL AND ap.End_Time Is NULL) 
                 OR (D.End_Time > ap.Start_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NULL)
               )
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
         WHERE D.Start_Time BETWEEN @Start_Time AND @End_Time
            OR D.End_Time BETWEEN @Start_Time AND @End_Time
            OR (D.Start_Time <= @Start_Time AND (D.End_Time > @End_Time OR D.End_Time Is NULL))
      END
  Else    --@MasterUnit NOT NULL
    BEGIN
      INSERT INTO #TopNDR (Detail_Id, Start_Time, End_Time, Duration, Uptime, SourcePU, MasterUnit, R1_Id, R2_Id, R3_Id, R4_Id, Prod_Id, Applied_Prod_Id, Fault_Id, Status_Id)
        SELECT DISTINCT
               D.TEDet_Id
             , [Start_Time] = Case When D.Start_Time >= ap.Start_Time Then D.Start_Time Else ap.Start_Time End
             , [End_Time]   = Case 
                                When D.End_Time Is NULL Then ap.End_Time
                                When ap.End_Time Is NOT NULL AND ap.End_Time <= D.End_Time Then ap.End_Time
                                When ap.End_Time Is NOT NULL AND D.End_Time <= ap.End_Time Then D.End_Time
                                Else D.End_Time 
                              End
             , D.Duration , D.Uptime , D.Source_PU_Id , PU.PU_Id , D.Reason_Level1 , D.Reason_Level2 , D.Reason_Level3 
             , D.Reason_Level4 , ap.Prod_Id , ap.Applied_Prod_Id , D.TEFault_Id , D.TEStatus_Id
          FROM  Timed_Event_Details D
          -- Defect #24434: removed JOIN #Applied_Products ap ON ap.PU_Id = D.Source_PU_Id and use join by times only
          JOIN #Applied_Products ap ON
               (    (D.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
                 OR (D.End_Time > ap.Start_Time AND D.End_Time <= ap.End_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time <= ap.Start_Time AND (D.End_Time > ap.End_Time OR D.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
                 OR (D.Start_Time >= ap.Start_Time AND D.End_Time Is NULL AND ap.End_Time Is NULL) 
                 OR (D.End_Time > ap.Start_Time AND D.End_Time Is NOT NULL AND ap.End_Time Is NULL)
               )
          JOIN Prod_Units PU ON (PU.PU_Id = D.PU_Id AND PU.PU_Id <> 0)  
         WHERE D.PU_Id = @MasterUnit 
           AND (    D.Start_Time BETWEEN @Start_Time AND @End_Time
                 OR D.End_Time BETWEEN @Start_Time AND @End_Time
                 OR (D.Start_Time <= @Start_Time AND (D.End_Time > @End_Time OR D.End_Time Is NULL))
               )
    END
  --EndIf @MasterUnit
  GOTO MAKE_DOWNTIME_SUMMARY_REPORT
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
-- PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-PROCESS DOWNTIME SUMMARY RESULT SET-
MAKE_DOWNTIME_SUMMARY_REPORT:
  --Clean up zero Pu_Id (comes from
  DELETE FROM #TopNDR WHERE MasterUnit = 0 OR SourcePU = 0
  UPDATE #TopNDR  SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
  UPDATE #TopNDR  SET End_Time = @End_Time  WHERE End_Time > @End_Time OR End_Time Is NULL
  UPDATE #TopNDR  SET Duration = DATEDIFF(ss, Start_Time, End_Time) / 60.0
  -- Calculate Total Downtime
  SELECT @TotalPLT = (SELECT SUM(Duration) FROM #TopNDR)
  --Adjust For Scheduled Down If Necessary
  SELECT @TotalOperating = 0
  SELECT @TotalOperating = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0) - @TotalOperating
  -- Delete Rows not matching additional additional Selection Criteria
  If @SelectSource Is NOT NULL      --@SelectSource = AddIn's Location
    BEGIN
      If @SelectSource = -1     --MSi/MT/4-11-2001: AddIn's "None" keyword; Want to retain NULL location, delete others
        DELETE FROM #TopNDR WHERE SourcePU Is NOT NULL
      Else
        --DELETE FROM #TopNDR WHERE SourcePU Is NULL Or SourcePU <> @SelectSource                             -- ECR #30478: mt/8-8-2005
        DELETE FROM #TopNDR WHERE ( SourcePU Is NULL AND MasterUnit <> @PU_Id ) Or SourcePU <> @SelectSource  -- ECR #30478: mt/8-8-2005
      --EndIf
    END
  --EndIf @SelectSource ...
  If @SelectR1 Is NOT NULL  DELETE FROM #TopNDR WHERE R1_Id Is NULL Or R1_Id <> @SelectR1
  If @SelectR2 Is NOT NULL  DELETE FROM #TopNDR WHERE R2_Id Is NULL Or R2_Id <> @SelectR2
  If @SelectR3 Is NOT NULL  DELETE FROM #TopNDR WHERE R3_Id Is NULL Or R3_Id <> @SelectR3
  If @SelectR4 Is NOT NULL  DELETE FROM #TopNDR WHERE R4_Id Is NULL Or R4_Id <> @SelectR4
  If @MasterUnit Is NULL
    BEGIN
      UPDATE #TopNDR
        SET Reason_Name = Case @ReasonLevel
                            When 0 Then PU.PU_Desc            --Location (Slave Unit)
                            When 1 Then R1.Event_Reason_Name
                            When 2 Then R2.Event_Reason_Name
                            When 3 Then R3.Event_Reason_Name
                            When 4 Then R4.Event_Reason_Name
                            When 5 Then F.TEFault_Name
                            When 6 Then S.TEStatus_Name
                            When -1 Then PU2.PU_Desc      --Line (Master Unit)
                          End
      FROM #TopNDR
      LEFT OUTER JOIN Prod_Units PU on (#TopNDR.SourcePU = PU.Pu_Id)  --SourcePU's contain master and slave
      LEFT OUTER JOIN Prod_Units PU2 ON (#TopNDR.MasterUnit = PU2.Pu_Id AND PU2.Master_Unit Is NULL)
      LEFT OUTER JOIN Event_Reasons R1 on (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 on (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 on (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 on (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Timed_Event_Fault F on (#TopNDR.Fault_Id = F.TEFault_Id)
      LEFT OUTER JOIN Timed_Event_Status S on (#TopNDR.Status_Id = S.TEStatus_Id)
    END
  Else    --@masterUnit not NULL
    BEGIN
      UPDATE #TopNDR
        SET Reason_Name = Case @ReasonLevel
                            When 0 Then PU.PU_Desc     --Location (Slave Pu_Id)
                            When 1 Then R1.Event_Reason_Name
                            When 2 Then R2.Event_Reason_Name
                            When 3 Then R3.Event_Reason_Name
                            When 4 Then R4.Event_Reason_Name
                            When 5 Then F.TEFault_Name
                            When 6 Then S.TEStatus_Name
                          End
      FROM #TopNDR
      LEFT OUTER JOIN Prod_Units PU on (#TopNDR.SourcePU = PU.Pu_Id)  --SourcePU's contain master and slave
      LEFT OUTER JOIN Event_Reasons R1 on (#TopNDR.R1_Id = R1.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R2 on (#TopNDR.R2_Id = R2.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R3 on (#TopNDR.R3_Id = R3.Event_Reason_Id)
      LEFT OUTER JOIN Event_Reasons R4 on (#TopNDR.R4_Id = R4.Event_Reason_Id)
      LEFT OUTER JOIN Timed_Event_Fault F on (#TopNDR.Fault_Id = F.TEFault_Id)
      LEFT OUTER JOIN Timed_Event_Status S on (#TopNDR.Status_Id = S.TEStatus_Id)
    END
  --EndIf @MasterUnit
  UPDATE #TopNDR  SET Reason_Name = dbo.fnDBTranslate(@LangId, 38333, 'Unspecified') WHERE Reason_Name Is NULL
  --Start Defect #24039
  SELECT @RowCount = 0 
  SELECT @RowCount = Count(*) FROM #TopNDR
  If @RowCount = 0 
    BEGIN
      --Defect #24415:mt/9-4-2002:Select doesn't always work
      --INSERT INTO #MyReport SELECT TotalOperatingMinutes = @TotalOperating 
      INSERT INTO #MyReport (TotalOperatingMinutes) VALUES(@TotalOperating)
      GOTO RETURN_RESULT_SET
    END
  --EndIf:@RowCount = 0
  --End Defect #24039
  -- Populate Temp Table With Reason Information
  INSERT INTO #MyReport ( ReasonName, NumberOfOccurances, TotalReasonMinutes, AvgReasonMinutes, TotalDowntimeMinutes, AvgUptimeMinutes, TotalUptimeMinutes, TotalOperatingMinutes )
  -- ECR #25108 : Arjun/2-2-2010       
 	 SELECT Reason_Name, COUNT(Duration), Total_Duration = SUM(Duration), (SUM(Duration) / COUNT(Duration)), @TotalPLT, ((@TotalOperating-@TotalPLT) / COUNT(Duration)), (@TotalOperating-@TotalPLT), @TotalOperating
    FROM #TopNDR
    GROUP BY Reason_Name
    ORDER BY Total_Duration DESC
RETURN_RESULT_SET:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)  
  SELECT * FROM #MyReport ORDER BY TotalReasonMinutes DESC
DROP_TEMP_TABLES:
  DROP TABLE #TopNDR
  DROP TABLE #MyReport
  DROP TABLE #products
  DROP TABLE #Prod_Starts
  DROP TABLE #Applied_Products
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
