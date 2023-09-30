-- DESCRIPTION: spXLA_AlarmSummary_AP replaces spXLA_AlarmSummary (has bug will not patch). spXLA_AlarmSummary_AP handles
-- three filter options: no product, original product, and applied product. MT/3-22-2002. 
-- REVISED: MT/5-3-2002
CREATE PROCEDURE dbo.spXLA_AlarmSummary_AP
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50)
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @Acknowledged 	  	 TinyInt
 	 , @SelectR1 	  	 Int
 	 , @SelectR2 	  	 Int
 	 , @SelectR3 	  	 Int
 	 , @SelectR4 	  	 Int
 	 , @ReasonLevel 	  	 Int
 	 , @Prod_Id 	  	 Int
 	 , @Group_Id 	  	 Int
 	 , @Prop_Id 	  	 Int
 	 , @Char_Id 	  	 Int
 	 , @IsAppliedProdFilter 	 TinyInt 	  	 -- 1 = Yes filter by Applied Product; 0 = No, Filter By Original Product
 	 , @Username Varchar(50) = NULL
 	 , @Langid Int = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
 	 --Local query assistance
DECLARE @QueryType  	  	 TinyInt
DECLARE @SingleProduct 	  	 TinyInt 	 --1
DECLARE @Group 	  	  	 TinyInt --2
DECLARE @Characteristic 	  	 TinyInt 	 --3
DECLARE @GroupAndProperty 	 TinyInt --4
DECLARE @NoProductSpecified 	 TinyInt --5
 	 --Identifiers for Alarms
DECLARE @TotalDurations 	  	 Real
DECLARE @TotalOperating  	 Real
DECLARE @MasterUnit 	  	 Int
 	 --Pertaining Data To Be included in ResultSet
DECLARE @Pu_Id 	  	  	 Integer
DECLARE @Data_Type_Id 	  	 Integer
DECLARE @VariableFetchCount 	 Integer
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
-- Get Variable-Related Information...
--
If @Var_Desc Is NULL
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @MasterUnit = pu.Master_Unit --@Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, 
      FROM Variables v 
      JOIN Prod_Units pu  ON pu.Pu_Id = v.Pu_Id  
     WHERE v.Var_Id = @Var_Id
    SELECT @VariableFetchCount = @@ROWCOUNT
  END
Else --@Var_Desc NOT null, use it
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @MasterUnit = pu.Master_Unit  --@Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, 
      FROM Variables v
      JOIN Prod_Units pu on pu.Pu_Id = v.Pu_Id
     WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
  END
--EndIf
If @VariableFetchCount = 0 
  BEGIN
    SELECT ReturnStatus = -10 	  	 --Tells the Add-In "Variable specified not found"
    RETURN
  END
--EndIf
If @MasterUnit Is NULL SELECT @MasterUnit = @Pu_Id
-- CREATE All TEMP TABLES here .................
CREATE TABLE #MyReport 
  ( ReasonName 	  	 Varchar(100) 	 
  , NumberOfOccurances 	 Int  NULL
  , TotalReasonMinutes  	 Real NULL
  , AvgReasonMinutes  	 Real NULL
  , TotalAlarmMinutes 	 Real NULL
  , TotalOperatingMinutes Real NULL
  )
-- Create All Temp tables we would need here.....
CREATE TABLE #TempAlarmData 
  ( Alarm_Id 	  	 Int
  , Alarm_Desc 	  	 Varchar(1000) NULL
  , Start_Time 	  	 DateTime
  , End_Time 	  	 DateTime    NULL
  , Duration 	  	 real        NULL
  , Reason_Name 	         Varchar(100) NULL  --extra for Summary to report Reason Name at reason level Summary being sought
  , Source_Pu_Id 	 Int         NULL
  , Prod_Id 	  	 Int         NULL
  , Applied_Prod_Id 	 Int         NULL
  , Reason1_Id 	  	 Int         NULL
  , Reason2_Id 	  	 Int         NULL 
  , Reason3_Id  	  	 Int         NULL
  , Reason4_Id  	  	 Int         NULL
  , Comment_Id 	  	 Int         NULL
  , Max_Result          Varchar(25) NULL
  , Min_Result          Varchar(25) NULL
  , Start_Result        Varchar(25) NULL
  , End_Result          Varchar(25) NULL
  , Modified_On         DateTime    NULL    
  , Ack_On              DateTime    NULL
  , Action1             Int         NULL
  , Action2             Int         NULL
  , Action3             Int         NULL
  , Action4             Int         NULL
  , Cutoff              TinyInt     NULL
  , User_Id             Int         NULL
  , Research_User_Id    Int         NULL
  , Research_Status_Id  Int         NULL
  , Research_Open_Date  DateTime    NULL
  , Research_Close_Date DateTime    NULL
  )
/*
CREATE TABLE #TempAlarmData 
  ( Alarm_Id         Int
  , Start_Time 	      DateTime
  , End_Time 	      DateTime     NULL
  , Duration  	      Real         NULL
  , Reason_Name 	      Varchar(100) NULL
  , Source_Pu_Id  	      Int          NULL
  , Prod_Id          Int          NULL
  , Applied_Prod_Id  Int          NULL
  , Reason1_Id 	      Int          NULL
  , Reason2_Id 	      Int          NULL
  , Reason3_Id 	      Int          NULL
  , Reason4_Id 	      Int          NULL
  )
*/
CREATE TABLE #Products (Prod_Id Int)
CREATE TABLE #Prod_Starts (PU_Id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Applied_Products (Pu_Id Int, Ps_Start_Time DateTime, Ps_End_Time DateTime NULL, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL, Keep_Event TinyInt NULL)
--If @ProductSpecified = 0 GOTO PRODUCT_NOT_SPECIFIED
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
If @Prod_Id Is NOT NULL 	  	  	  	  	 SELECT @QueryType = @SingleProduct   	 --1
Else If @Group_Id Is NOT NULL AND @Prop_Id Is NULL 	 SELECT @QueryType = @Group   	  	 --2
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NULL 	 SELECT @QueryType = @Characteristic  	 --3
Else If @Prop_Id Is NOT NULL AND @Group_Id Is NOT NULL 	 SELECT @QueryType = @GroupAndProperty 	 --4
Else 	  	  	  	  	  	  	 SELECT @QueryType = @NoProductSpecified 	 --5
--EndIf
If @IsAppliedProdFilter = 1 GOTO DO_FILTER_BY_APPLIED_PRODUCT
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Build Temp Product_Starts Table Our Time Duration and Product Info
If @QueryType = @NoProductSpecified 	 --5
  BEGIN
    IF @MasterUnit IS NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM Production_Starts ps
           WHERE (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
                 )
      END
    ELSE     --@MasterUnit not null
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM Production_Starts ps
           WHERE PU_Id = @MasterUnit AND PU_Id <> 0
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
                 )
      END
    --ENDIF @MasterUnit
  END
Else If @QueryType = @SingleProduct 	 --1
  BEGIN
    IF @MasterUnit IS NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM Production_Starts ps
           WHERE Prod_Id = @Prod_Id 
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
                 )
      END
    ELSE     --@MasterUnit not null
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM Production_Starts ps
           WHERE PU_Id = @MasterUnit 
             AND PU_Id <> 0
             AND Prod_Id = @Prod_Id 
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
                 )
      END
    --ENDIF @MasterUnit
  END
Else 	  	  	  	  	 --We have product grouping info
  BEGIN
    If @QueryType = @Group 	  	  	 --2
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
      END
    Else If @QueryType = @Characteristic 	 --3
      BEGIN
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id  FROM Pu_Characteristics  WHERE Prop_Id = @Prop_Id AND Char_Id = @Char_Id
      END
    Else 	  	  	  	  	 --4 Group & Property
      BEGIN
        INSERT INTO #Products
        SELECT Prod_Id FROM Product_Group_Data WHERE Product_Grp_Id = @Group_Id
        INSERT INTO #Products
        SELECT DISTINCT Prod_Id  FROM Pu_Characteristics  WHERE Prop_Id = @Prop_Id  AND Char_Id = @Char_Id
      END
    --EndIf @QueryType = Single Product...
    IF @MasterUnit IS NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM Production_Starts ps
            JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
           WHERE (Start_Time BETWEEN @Start_Time AND @End_Time)
              OR (End_Time BETWEEN @Start_Time AND @End_Time) 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
      END
    Else     --@MasterUnit not null
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.PU_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM Production_Starts ps
            JOIN #Products p ON ps.Prod_Id = p.Prod_Id 
           WHERE PU_Id = @MasterUnit 
             AND PU_Id <> 0
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                  OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time IS NULL))
                 )
      END
    --ENDIF @MasterUnit
  END
--EndIf @QueryType...
-- Fill In TopNDR Table ..................
If @Acknowledged = 1 
  BEGIN
    INSERT INTO #TempAlarmData 
                     (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration
                      , Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                      , Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
                      , Modified_On, Ack_On, Action1, Action2, Action3, Action4, Cutoff
                      , User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date 
                     )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When a.Start_Time < ps.Start_Time Then ps.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case
                                       When a.End_Time  Is NULL        Then ps.End_Time
                                       When ps.End_Time Is NULL        Then a.End_Time
                                       When a.End_Time  <= ps.End_Time Then a.End_Time
                                       When ps.End_Time <= a.End_Time  Then ps.End_Time
                                       Else a.End_Time
                                     End
                    , a.Duration
                    , a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4
                    , a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
                    , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff
                    , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Prod_Starts ps ON
        (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
          OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
          OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
          OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
          OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
        ) AND ps.Pu_Id = @MasterUnit
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
         AND a.Ack = 1
  END
Else --@Acknowledged = 0
  BEGIN
    INSERT INTO #TempAlarmData 
                     (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration
                      , Source_Pu_Id, Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                      , Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
                      , Modified_On, Ack_On, Action1, Action2, Action3, Action4, Cutoff
                      , User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date 
                     )
      SELECT DISTINCT a.Alarm_Id, a.Alarm_Desc
                    , [Start_Time] = Case When a.Start_Time < ps.Start_Time Then ps.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case
                                       When a.End_Time  Is NULL        Then ps.End_Time
                                       When ps.End_Time Is NULL        Then a.End_Time
                                       When a.End_Time  <= ps.End_Time Then a.End_Time
                                       When ps.End_Time <= a.End_Time  Then ps.End_Time
                                       Else a.End_Time
                                     End
                    , a.Duration
                    , a.Source_PU_Id, ps.Prod_Id, a.Cause1, a.Cause2, a.Cause3, a.Cause4
                    , a.Cause_Comment_Id, a.Max_Result, a.Min_Result, a.Start_Result, a.End_Result
                    , a.Modified_On, a.Ack_On, a.Action1, a.Action2, a.Action3, a.Action4, a.Cutoff
                    , a.User_Id, a.Research_User_Id, a.Research_Status_Id, a.Research_Open_Date, a.Research_Close_Date
        FROM Alarms a
        JOIN #Prod_Starts ps ON
        (    (a.Start_Time BETWEEN ps.Start_Time AND ps.End_Time AND ps.End_Time Is NOT NULL)
          OR (a.End_Time > ps.Start_Time AND a.End_Time <= ps.End_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NOT NULL)
          OR (a.Start_Time <= ps.Start_Time AND (a.End_Time > ps.End_Time OR a.End_Time Is NULL) AND ps.End_Time Is NOT NULL)
          OR (a.Start_Time >= ps.Start_Time AND a.End_Time Is NULL AND ps.End_Time Is NULL) 
          OR (a.End_Time > ps.Start_Time AND a.End_Time Is NOT NULL AND ps.End_Time Is NULL)
        ) AND ps.Pu_Id = @MasterUnit
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
  END
--EndIf @Acknowledged ..
GOTO FINISH_UP_TEMP_ALARM_TABLE
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
DO_FILTER_BY_APPLIED_PRODUCT:
  --First Grab Relevant Original Product & Related Information From Production_Starts Table 
  BEGIN
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.pu_id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM Production_Starts ps
           WHERE (    ps.Start_Time BETWEEN @Start_Time AND @End_Time 
 	  	    OR ps.End_Time BETWEEN @Start_Time AND @End_Time 
 	  	    OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR End_Time Is NULL) )
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
 	  	    OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR End_Time Is NULL) )
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
  -- (Note: JOIN condition for Production_Starts consistent with AutoLog's )
  -- (Note2: Current MSI Start_Time inEvents table are mostly null, software update will insert values into Start_Time
  --         for current and older data, we'll give start_time 1 second less than Time_Stamp.
  --         For Customers who are concern about correct result, MSI will give them a script for one-time update of 
  --         their Events table. This update is time/disk-space consuming, thus, available upon request only. MT/3-20-2002.)
  --Make TEMP TABLE: Split ANY PRODUCT In #Prod_Starts into individual events.
  INSERT INTO #Applied_Products ( Pu_Id, Ps_Start_Time, Ps_End_Time, Start_Time, End_Time, Prod_Id, Applied_Prod_Id )
      SELECT e.Pu_Id, ps.Start_Time, ps.End_Time, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, ps.Prod_Id, e.Applied_Product 
        FROM #Prod_Starts ps 
        JOIN Events e ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL ) 
         AND ps.Pu_Id = e.Pu_Id 
    ORDER BY e.Pu_Id, ps.Start_Time, e.TimeStamp, ps.Prod_Id
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
  -- Insert Data Into Temp Table #TempAlarmData
  If @Acknowledged = 1  --Get only acknowledged Alarms
    INSERT INTO #TempAlarmData 
                     (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration
                      , Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                      , Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
                      , Modified_On, Ack_On, Action1, Action2, Action3, Action4, Cutoff
                      , User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id
                    , a.Alarm_Desc
                    , [Start_Time] = Case When a.Start_Time < ap.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case
                                       When a.End_Time  Is NULL        Then ap.End_Time
                                       When ap.End_Time Is NULL        Then a.End_Time
                                       When a.End_Time  <= ap.End_Time Then a.End_Time
                                       When ap.End_Time <= a.End_Time  Then ap.End_Time
                                       Else a.End_Time
                                     End
                    , a.Duration
                    , a.Source_PU_Id
                    , ap.Prod_Id
                    , ap.Applied_Prod_Id
                    , a.Cause1
                    , a.Cause2
                    , a.Cause3
                    , a.Cause4
                    , a.Cause_Comment_Id
                    , a.Max_Result
                    , a.Min_Result
                    , a.Start_Result
                    , a.End_Result
                    , a.Modified_On
                    , a.Ack_On
                    , a.Action1
                    , a.Action2
                    , a.Action3
                    , a.Action4
                    , a.Cutoff
                    , a.User_Id
                    , a.Research_User_Id
                    , a.Research_Status_Id
                    , a.Research_Open_Date
                    , a.Research_Close_Date
        FROM Alarms a
        --JOIN #Applied_Products ap ON ap.Start_Time <= a.Start_Time AND (ap.End_Time > a.Start_Time OR ap.End_Time Is NULL)
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
         AND a.Ack = 1
  Else                  --Any alarm data; @Acknowledement not required
    INSERT INTO #TempAlarmData 
                     (  Alarm_Id, Alarm_Desc, Start_Time, End_Time, Duration
                      , Source_Pu_Id, Prod_Id, Applied_Prod_Id, Reason1_Id, Reason2_Id, Reason3_Id, Reason4_Id
                      , Comment_Id, Max_Result, Min_Result, Start_Result, End_Result
                      , Modified_On, Ack_On, Action1, Action2, Action3, Action4, Cutoff
                      , User_Id, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date )
      SELECT DISTINCT a.Alarm_Id
                    , a.Alarm_Desc
                    , [Start_Time] = Case When a.Start_Time < ap.Start_Time Then ap.Start_Time Else a.Start_Time End
                    , [End_Time]   = Case
                                       When a.End_Time  Is NULL        Then ap.End_Time
                                       When ap.End_Time Is NULL        Then a.End_Time
                                       When a.End_Time  <= ap.End_Time Then a.End_Time
                                       When ap.End_Time <= a.End_Time  Then ap.End_Time
                                       Else a.End_Time
                                     End
                    , a.Duration
                    , a.Source_PU_Id
                    , ap.Prod_Id
                    , ap.Applied_Prod_Id
                    , a.Cause1
                    , a.Cause2
                    , a.Cause3
                    , a.Cause4
                    , a.Cause_Comment_Id
                    , a.Max_Result
                    , a.Min_Result
                    , a.Start_Result
                    , a.End_Result
                    , a.Modified_On
                    , a.Ack_On
                    , a.Action1
                    , a.Action2
                    , a.Action3
                    , a.Action4
                    , a.Cutoff
                    , a.User_Id
                    , a.Research_User_Id
                    , a.Research_Status_Id
                    , a.Research_Open_Date
                    , a.Research_Close_Date
        FROM Alarms a
        --JOIN #Applied_Products ap ON ap.Start_Time <= a.Start_Time AND (ap.End_Time > a.Start_Time OR ap.End_Time Is NULL)
        JOIN #Applied_Products ap ON
        (    (a.Start_Time BETWEEN ap.Start_Time AND ap.End_Time AND ap.End_Time Is NOT NULL)
          OR (a.End_Time > ap.Start_Time AND a.End_Time <= ap.End_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time <= ap.Start_Time AND (a.End_Time > ap.End_Time OR a.End_Time Is NULL) AND ap.End_Time Is NOT NULL)
          OR (a.Start_Time >= ap.Start_Time AND a.End_Time Is NULL AND ap.End_Time Is NULL) 
          OR (a.End_Time > ap.Start_Time AND a.End_Time Is NOT NULL AND ap.End_Time Is NULL)
        )
        JOIN Alarm_Template_Var_Data T ON T.ATD_Id = a.ATD_Id AND T.Var_Id = @Var_Id
       WHERE (    a.Start_Time BETWEEN @Start_Time AND @End_Time
               OR (a.End_Time > @Start_Time AND (a.End_Time < @End_Time OR a.End_Time Is NULL))
               OR (a.Start_Time <= @Start_Time AND (a.End_Time > @End_Time OR a.End_Time Is NULL))
             )
  --EndIf @Acknowledged = 1
  GoTo FINISH_UP_TEMP_ALARM_TABLE
-- FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-
-- FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-
-- FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-
-- FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-
-- FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-
-- FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-
-- FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-
-- FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-FINISH UP TEMP ALARM TABLE AND PROCESS RESULTSET-
FINISH_UP_TEMP_ALARM_TABLE:
  -- Clean up zero PU_Id
  DELETE FROM #TempAlarmData WHERE Source_Pu_Id = 0
  -- We have inserted into #TempAlarmData alarms that may have started and ended beyond user-requested time range.
  -- To only report Alarms for the specified time range; need to change start_time and End_Time
  UPDATE #TempAlarmData  SET Start_Time = @Start_Time WHERE Start_Time < @Start_Time
  UPDATE #TempAlarmData  SET End_Time = @End_Time  WHERE End_Time > @End_Time OR End_Time IS NULL
  UPDATE #TempAlarmData  SET Duration = DATEDIFF(ss, Start_Time, End_Time) / 60.0
  -- Calculate Total Alarm Duration
  SELECT @TotalDurations = (SELECT SUM(Duration) FROM #TempAlarmData) 
  --Adjust For Scheduled Alarm 
  SELECT @TotalOperating = 0
  SELECT @TotalOperating = (DATEDIFF(ss, @Start_Time, @End_Time) / 60.0) - @TotalOperating
  -- Deleted rows with Null Reason IDs or unmatched reason IDs, keeping only the "Selected Reason" 
  If @SelectR1 Is NOT NULL DELETE FROM #TempAlarmData Where Reason1_Id Is NULL Or Reason1_Id <> @SelectR1   
  If @SelectR2 Is NOT NULL DELETE FROM #TempAlarmData Where Reason2_Id Is NULL Or Reason2_Id <> @SelectR2
  If @SelectR3 Is NOT NULL DELETE FROM #TempAlarmData Where Reason3_Id Is NULL Or Reason3_Id <> @SelectR3
  If @SelectR4 Is NOT NULL DELETE FROM #TempAlarmData Where Reason4_Id Is NULL Or Reason4_Id <> @SelectR4
  -- Fill in TopNDR with Reason Names
  UPDATE #TempAlarmData 
      SET Reason_Name = Case @ReasonLevel
                          When 0 Then PU.PU_Desc
                          When 1 Then R1.Event_Reason_Name
                          When 2 Then R2.Event_Reason_Name
                          When 3 Then R3.Event_Reason_Name
                          When 4 Then R4.Event_Reason_Name
                        End
     FROM #TempAlarmData t
     JOIN Prod_Units PU ON PU.Pu_Id = t.Source_Pu_Id
     LEFT OUTER JOIN Event_Reasons R1 on (t.Reason1_Id = R1.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons R2 on (t.Reason2_Id = R2.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons R3 on (t.Reason3_Id = R3.Event_Reason_Id)
     LEFT OUTER JOIN Event_Reasons R4 on (t.Reason4_Id = R4.Event_Reason_Id)
  --If there still are 'Null' reason names, replace it with "Unspecified"
  UPDATE #TempAlarmData  SET Reason_Name = dbo.fnDBTranslate(@Langid, 38333, 'Unspecified') Where Reason_Name Is NULL
  -- Populate Temp Table With Reason Ordered By
  INSERT INTO #MyReport (ReasonName, NumberOfOccurances, TotalReasonMinutes, AvgReasonMinutes, TotalAlarmMinutes, TotalOperatingMinutes)
      SELECT Reason_Name, COUNT(Duration), Total_Duration = SUM(Duration),  (SUM(Duration) / COUNT(Duration)), @TotalDurations, @TotalOperating
        FROM #TempAlarmData
    GROUP BY Reason_Name
    ORDER BY Total_Duration DESC
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  SELECT * FROM #MyReport
DROP_TEMP_TABLES:
  DROP TABLE #TempAlarmData
  DROP TABLE #MyReport
  DROP TABLE #Products
  DROP TABLE #Prod_Starts
  DROP TABLE #Applied_Products
DELETE FROM User_Connections Where SPID = @@SPID and User_Id = @UserId and Language_Id = @LangId
