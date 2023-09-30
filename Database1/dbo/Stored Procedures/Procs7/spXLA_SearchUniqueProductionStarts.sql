-- spXLA_SearchUniqueProductionStarts() is modified from spXLA_SearchProductionStarts. ECR #26207: mt/12-9-2003:
-- Goal: To list unique products for the specified unit in the specified time period. Users don't care about the detailed
--       timestamp records.
--
-- NOTE: Although the stored procedure code appears to be handling MasterUnit_Id = NULL, ProficyAddIn, in practice,
--       NEVER calls the stored procedure without a production unit; error if production unit is not specified
--       This design goes all the way back to PrfXla.xla v2.1B49
--
CREATE PROCEDURE dbo.spXLA_SearchUniqueProductionStarts
 	   @Start_Time  	  	 DateTime
 	 , @End_Time  	  	 DateTime
 	 , @MasterUnit_ID  	 Integer
 	 , @MasterUnit_Desc  	 varchar(50)
 	 , @Prod_Id  	  	 Integer
 	 , @Group_Id  	  	 Integer
 	 , @Prop_Id  	  	 Integer
 	 , @Char_Id  	  	 Integer
 	 , @AppliedProductFilter 	 TinyInt 	  	 --1= filter by Applied Product is set; 0 = No, Filter By Original Product
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
 	 --Needed for Product Info Query ...
DECLARE @QueryType  	  	 TinyInt  -- Determine "Type" of SQL for Filtering By Product (Applied Or Original)
DECLARE @OneProductFilter 	 TinyInt  --51
DECLARE @GroupFilter 	  	 TinyInt  --52
DECLARE @CharacteristicFilter 	 TinyInt  --53
DECLARE @GroupAndPropertyFilter 	 TinyInt  --54
DECLARE @NoProductFilter 	 TinyInt  --55
 	 --Needed for internal use
DECLARE @CountOfUnitDesc        Integer
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
--Figure Out Product-Related Query Types
/* NOTE: We DO NOT handle all possible null combinations of product parameters (@Prod_Id, @Group_Id, @Prop_Id, and @Char_Id.)
   Proficy Add-In blocks out illegal combinations, and allows only these combination:
     - Property AND Characteristic 
     - Group Only
     - Group, Propery, AND Characteristic
     - Product Only
     - No Product Information At All 
*/
SELECT @OneProductFilter 	 = 51
SELECT @GroupFilter 	  	 = 52
SELECT @CharacteristicFilter 	 = 53
SELECT @GroupAndPropertyFilter  	 = 54
SELECT @NoProductFilter 	  	 = 55
If @Start_Time Is NULL SELECT @Start_Time = '1-jan-1971'
If @End_Time Is NULL   SELECT @End_Time = dateadd(day,7,getdate())
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
--Handle Master Unit First
If @MasterUnit_ID Is NULL AND @MasterUnit_Desc Is NULL
  BEGIN
    SELECT [ReturnStatus] = -105 	  	 --Production Unit NOT SPECIFIED
    RETURN
  END
Else If @MasterUnit_Desc Is NULL --we have ID
  BEGIN
    SELECT @MasterUnit_ID = Case When Master_Unit Is NULL Then Pu_Id Else Master_Unit End From Prod_Units Where Pu_Id = @MasterUnit_ID  
    SELECT @CountOfUnitDesc = @@ROWCOUNT
    If @CountOfUnitDesc = 0 --not found
      BEGIN
        SELECT [ReturnStatus] = -100 	  	 --Production Unit specified NOT FOUND
        RETURN
      END
    --EndIf: count = 0
  END
Else --we have Description
  BEGIN
    SELECT @MasterUnit_ID = Case When Master_Unit Is NULL Then Pu_Id Else Master_Unit End From Prod_Units Where PU_Desc = @MasterUnit_Desc  
    SELECT @CountOfUnitDesc = @@ROWCOUNT
    If @CountOfUnitDesc <> 1
      BEGIN
        If @CountOfUnitDesc = 0
          SELECT [ReturnStatus] = -100 	  	 --production unit specified NOT FOUND
        Else --found too many PU_Desc
          SELECT [ReturnStatus] = -103 	  	 --DUPLICATE FOUND for PU_Desc
        --EndIf:count = 0
        RETURN
      END
    --EndIf:count <> 1
  END
--EndIf: Both ID and Desc are NULL
--Define "query type" which can be used with AppliedProduct Or OriginalProduct filter
If @Prod_Id is not NULL 	  	  	  	  	 SELECT @QueryType = @OneProductFilter 	  	 --51
Else If @Group_Id Is NOT NULL AND @Prop_Id is NULL 	 SELECT @QueryType = @GroupFilter 	  	 --52
Else If @Prop_Id Is NOT NULL AND @Group_Id is NULL 	 SELECT @QueryType = @CharacteristicFilter 	 --53
Else If @Prop_Id Is NOT NULL AND @Group_Id is not NULL 	 SELECT @QueryType = @GroupAndPropertyFilter 	 --54
Else 	  	  	  	  	  	  	 SELECT @QueryType = @NoProductFilter 	  	 --55 
--EndIf
CREATE TABLE #prod_starts (pu_id Int, Prod_Id Int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #products (Prod_Id Int)
CREATE TABLE #Applied_Products (Pu_Id Int, Ps_Start_Time DateTime, Ps_End_Time DateTime NULL, Start_Time DateTime, End_Time DateTime, Prod_Id Int, Applied_Prod_Id Int NULL, Keep_Event TinyInt NULL)
If @AppliedProductFilter = 1 GOTO DO_APPLIED_PRODUCT_FILTER_STUFF
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- Get distinct product codes for the specified parameters
If @QueryType = @NoProductFilter 	 --5  	  	  	 
  BEGIN
    If @MasterUnit_ID Is NULL
      BEGIN
          SELECT DISTINCT Production_Unit = pu.pu_desc, p.Prod_Code
            FROM production_starts ps
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products p on p.Prod_Id = ps.Prod_Id 
           WHERE Start_Time BETWEEN @Start_Time AND @End_Time
              OR (End_Time > @Start_Time AND End_Time < @End_Time) 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
      END
    Else -- @Master NOT NULL
      BEGIN
          SELECT DISTINCT Production_Unit = pu.pu_desc, p.Prod_Code
            FROM production_starts ps
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products p on p.Prod_Id = ps.Prod_Id 
           WHERE ps.Pu_Id = @MasterUnit_ID 
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                   --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                 )
      END
    --EndIf @MasterUnit_ID 
  END
Else If @QueryType = @OneProductFilter 	  	 --1
  BEGIN
    If @MasterUnit_ID Is NULL
      BEGIN
          SELECT DISTINCT Production_Unit = pu.pu_desc, p.Prod_Code
            FROM production_starts ps
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products p on p.Prod_Id = ps.Prod_Id 
           WHERE ps.Prod_Id = @Prod_Id 
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
                    --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
                   OR (End_Time > @Start_Time AND End_Time < @End_Time) 
                  OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
                 )
      END
    Else --@MasterUnit_ID NOT NULL
      BEGIN
          SELECT DISTINCT Production_Unit = pu.pu_desc, p.Prod_Code
            FROM production_starts ps
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products p on p.Prod_Id = ps.Prod_Id 
           WHERE ps.Pu_Id = @MasterUnit_ID 
             AND ps.Prod_Id = @Prod_Id 
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time)
                   OR (End_Time > @Start_Time AND End_Time < @End_Time)
                   OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time Is NULL))
                 )
      END 
    --EndIf @MasterUnit_ID...
  END
Else 	  	  	  	  	 --Some product grouping exist
  BEGIN
    If @QueryType = @GroupFilter 	  	 --52
      BEGIN
         INSERT INTO #products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @CharacteristicFilter 	 --53
      BEGIN
         INSERT INTO #products
         SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else 	  	  	  	 --Group and Property
      BEGIN
         INSERT INTO #products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
         INSERT INTO #products
         SELECT DISTINCT Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    --EndIf  @QueryType ..
    If @MasterUnit_ID Is NULL
      BEGIN
          SELECT DISTINCT Production_Unit = pu.pu_desc, pt.Prod_Code
            FROM production_starts ps
            JOIN #products p on ps.Prod_Id = p.Prod_Id 
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products pt on pt.Prod_Id = ps.Prod_Id 
           WHERE (Start_Time BETWEEN @Start_Time AND @End_Time)
              OR (End_Time > @Start_Time AND End_Time < @End_Time) 
 	       OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
      END
    Else --@MasterUnit_ID NOT NULL
      BEGIN
          SELECT DISTINCT Production_Unit = pu.pu_desc, pt.Prod_Code
            FROM production_starts ps
            JOIN #products p on ps.Prod_Id = p.Prod_Id 
            JOIN prod_units pu on pu.Pu_Id = ps.Pu_Id
            JOIN products pt on pt.Prod_Id = ps.Prod_Id 
           WHERE ps.Pu_Id = @MasterUnit_ID 
             AND (    (Start_Time BETWEEN @Start_Time AND @End_Time) 
               --OR (End_Time BETWEEN @Start_Time AND @End_Time) 
              OR (End_Time > @Start_Time AND End_Time < @End_Time) 
              OR (Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL)) --Start_time & End_time condition checked ; MSi/MT/3-21-2001
              ) 
      END
    --EndIf @Master ..  
  END
--EndIf @QueryType = 5
GOTO EXIT_PROCEDURE
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
DO_APPLIED_PRODUCT_FILTER_STUFF:
  --SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
  --Grab all of the "Specified" Applied Products, put them into Temp Table #Products
  BEGIN      
    If @QueryType = @GroupFilter
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @CharacteristicFilter
      BEGIN
         INSERT INTO #Products
         SELECT distinct Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else If @QueryType = @GroupAndPropertyFilter 	  	 
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
  END
  --Grab All "Original Products" information that we care in the Specified Time Range
  BEGIN
    If @MasterUnit_ID Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.pu_id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE (   ps.Start_Time BETWEEN @Start_Time AND @End_Time 
                  --OR ps.End_Time BETWEEN @Start_Time AND @End_Time 
                  OR (End_Time > @Start_Time AND End_Time < @End_Time)
 	  	   OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time is NULL) )
                 )
       END
    Else --@MasterUnit_ID NOT NULL
      BEGIN
        INSERT INTO #Prod_Starts
            SELECT ps.pu_id, ps.Prod_Id, ps.Start_Time, ps.End_Time
              FROM production_starts ps
             WHERE ps.Pu_Id = @MasterUnit_ID 
 	        AND (    ps.Start_Time BETWEEN @Start_Time AND @End_Time
                     --OR ps.End_Time BETWEEN @Start_Time AND @End_Time
                     OR (End_Time > @Start_Time AND End_Time < @End_Time)
                     OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time is NULL) )
                   )
      END
    --EndIf
  END
  --RETRIEVE RESULTSET BASED ON WHETHER OR NOT "Applied Products" information is asked for.
  --NOTE: Definition of "Applied Products" from Events Table.  
  --      When Applied_Product is NULL, we take that the original product is applied product.
  --      When Applied_Product is not NULL, only applied products that match search criteria count as applied product.
  --NOTE2: As of 3-25-2002 MSI Start_Time inEvents table are mostly null. This storec procedure will insert
  --     a dummy value of TimeStamp minus one second for null Start_Time. For Customers who are concern about correct 
  --     Start_Time, which affect correct time-dependent results, MSI will give them a script for one-time update of 
  --     the Events table. This update is time/disk-space consuming, thus, available upon request only.
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
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  -- Retrieve ResordSet
    SELECT DISTINCT Production_Unit = pu.Pu_Desc, p.Prod_Code /*, Applied_Prod_Code = p2.Prod_Code */
      FROM #Applied_Products ap
      JOIN Prod_Units pu ON pu.Pu_Id = ap.Pu_Id
      JOIN Products p ON p.Prod_Id = ap.Prod_Id
      --LEFT JOIN Products p2 ON p2.Prod_Id = ap.Applied_Prod_Id
     WHERE ap.Start_Time BETWEEN @Start_Time AND @End_Time
        OR ap.End_Time BETWEEN @Start_Time AND @End_Time
        OR (ap.Start_Time >= @Start_Time AND (ap.End_Time > @End_Time OR ap.End_Time Is NULL))
  ORDER BY pu.Pu_Desc, p.Prod_Code
  --EndIf @TimeSort ...
  GOTO EXIT_PROCEDURE
EXIT_PROCEDURE:
  DROP TABLE #prod_starts 
  DROP TABLE #products 
  DROP TABLE #Applied_Products
