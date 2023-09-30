﻿/* NOTE 
   ECR #27992: mt/5-11-2004: added Customer_Order_Number, Plant_Order_Number and Shipment_Number to the return resultset since PrfXla.XLA requested this information
               users may want to see it.
   Added Crew,shift filter: Defect #24503: mt/10-4-2002
   ECR #24541: mt/1-20-2003: added fields "Conformance" and "Testing_Prct_Complete"
   Originally (in the spXLASearchEvent_ series ), we divide stored procedures into 4 groups based on the need for joins to obtain the required attributes for
   the events sought. The four groups carry unique suffixes as outlined below:
     1) _APMin: 	  	 indicates minimum joins (join production_Starts only)
     2) _APOrder: 	 indicates joins to get Order information Plant_Order_Number, Customer_Order_Number
     3) _APShipment: 	 indicates joins to get Shipment information
     4) _APMax: 	  	 indicates joins to get both Order and shipment information
   Note On @NeedEventStatus & @EventStatusFilter -- @NeedEventStatus signifies user wants to retrieve Event status, whereas
   @EventStatusFilter is a list of Event_Status by which user wants to filter. They are independent of each other; e.g., 
   user may specify filter but don't want to retrieve event status.
   MSi/mt/1-22-2002
   mt/1-20-2003; spXLA_BrowseEvent_Min is the based stored procedure which is used when minimum join condition is met.
   When 3 more filters are added into the design, all Event Search's stored procedures, must be expanded to handle these
   additional filters regardless of whether or not the filter is in the seleceted event attributes (for example; users may
   specify shipment filter without selecting shipment_number from event attribute list)
   We chose NOT to add more branches of SQL Statements to spXLA_BrowseEvent_Min, but rather to expand 
   it into 8 stored procedures (listed below). Each incorporate additional filter(s) hinted in its name
   The 8 stored procedures are:
    (1) spXLA_BrowseEvent_Min 	  	  	  	 'Master Copy
    (2) spXLA_BrowseEvent_Min_ShipmentFilter
    (3) spXLA_BrowseEvent_Min_CustomerFilter
    (4) spXLA_BrowseEvent_Min_CustomerShipFilters
    (5) spXLA_BrowseEvent_Min_PlantFilter
    (6) spXLA_BrowseEvent_Min_PlantShipFilters
    (7) spXLA_BrowseEvent_Min_PlantCustomerFilters
    (8) spXLA_BrowseEvent_Min_PlantCustomerShip 	  	 'This stored procedure; mt/1-20-2003
*/
-- USAGE: 
-- spXLA_BrowseEvent_Min_PlantCustomerShip should be called only when minimum join condition is met AND 
-- Plant_Order_Number, Customer_Code, & Shipment_Number filters are specified. mt/1-20-2003
--
CREATE PROCEDURE dbo.spXLA_BrowseEvent_Min_PlantCustomerShip 
 	   @SearchString 	  	 Varchar(50)
 	 , @Start_Time  	  	 DateTime
 	 , @End_Time  	  	 DateTime
 	 , @MasterUnit  	  	 Integer
 	 , @MasterUnitName  	 Varchar(50)
 	 , @Crew_Desc            Varchar(10)
 	 , @Shift_Desc           Varchar(10)
 	 , @Prod_Id  	  	 Integer
 	 , @Group_Id  	  	 Integer
 	 , @Prop_Id  	  	 Integer
 	 , @Char_Id  	  	 Integer
 	 , @AppliedProductFilter 	 TinyInt 	  	 --1 = Filter By Applied Product; 0 = Filter By Original Product
 	 , @NeedEventStatus 	 TinyInt 	  	 --1 = Yes;  0 = No
 	 , @EventStatusFilter 	 Varchar(500) 	 --null OR Comma-separated Event_Status list (of TinyInt) with $-termination
 	 , @Plant_Order_Number 	 Varchar(50) 	 --Filter By Plant_Order_Number (Required)
 	 , @Customer_Code 	 Varchar(50) 	 --Filter By Customer_Code (Required)
 	 , @Shipment_Number 	 Varchar(50) 	 --Filter By Shipment_Numnber (Required)
 	 , @TimeSort  	  	 TinyInt = NULL 	 --1 = Ascending; Else Descending
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
DECLARE @MyType 	  	  	 TinyInt  --Determines Type of SQL For Retrieving Recordset
 	 --Define query type for both applied & original products
DECLARE @NoStringHasStatusAsc  	 TinyInt --1
DECLARE @NoStringHasStatusDesc 	 TinyInt --2
DECLARE @HasStringHasStatusAsc  	 TinyInt --3
DECLARE @HasStringHasStatusDesc TinyInt --4
 	  	 --(No request for Event Status)
DECLARE @NoStringNoStatusAsc  	 TinyInt --5
DECLARE @NoStringNoStatusDesc 	 TinyInt --6
DECLARE @HasStringNoStatusAsc  	 TinyInt --7
DECLARE @HasStringNoStatusDesc  	 TinyInt --8
 	 --Define production_Starts query type for original product
DECLARE @QueryType  	  	 TinyInt
DECLARE @OneProductFilter 	 TinyInt  --51
DECLARE @GroupFilter 	  	 TinyInt  --52
DECLARE @CharacteristicFilter 	 TinyInt  --53
DECLARE @GroupAndPropertyFilter 	 TinyInt  --54
DECLARE @NoProductSpecified 	 TinyInt  --55
If @TimeSort IS NULL    SELECT @TimeSort = 1  --Ascending, DEFAULT
If @Start_Time Is NULL 	 SELECT @Start_Time = '1-jan-1971'
If @End_Time Is NULL 	 SELECT @End_Time = dateadd(day,7,getdate())
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
-- Assign @MasterUnit As Either Master or Slave
If @MasterUnitName Is Not NULL
    SELECT @MasterUnit = Case When Master_Unit Is NULL Then PU_Id Else Master_Unit End 
    FROM   Prod_Units 
    WHERE  PU_Desc = @MasterUnitName  
Else If @MasterUnit Is Not NULL
    SELECT @MasterUnit = Case When Master_Unit Is NULL Then PU_Id Else Master_Unit End 
    FROM   Prod_Units 
    WHERE  PU_Id = @MasterUnit  
--EndIf
CREATE TABLE #Prod_Starts (Pu_Id int, Prod_Id int, Start_Time DateTime, End_Time DateTime NULL)
CREATE TABLE #Products (Prod_Id int)
CREATE TABLE #Event_Status (Event_Status Int)
CREATE TABLE #Events (Event_Num Varchar(50), Event_Id Int, Pu_Id Int, Prod_Id Int, Start_Time DateTime, TimeStamp DateTime
                    , Extended_Info Varchar(255) NULL, Event_Status Int NULL, Applied_Product Int NULL --)
                    , Event_Conformance TinyInt NULL, Testing_Prct_Complete TinyInt NULL )     --ECR #24541: mt/1-20-2003
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
SELECT @NoProductSpecified 	 = 55
--Define "query type" which can be used with AppliedProduct Or OriginalProduct filter
If @Prod_Id is not NULL 	  	  	  	  	 SELECT @QueryType = @OneProductFilter 	  	 --51
Else If @Group_Id Is NOT NULL AND @Prop_Id is NULL 	 SELECT @QueryType = @GroupFilter 	  	 --52
Else If @Prop_Id Is NOT NULL AND @Group_Id is NULL 	 SELECT @QueryType = @CharacteristicFilter 	 --53
Else If @Prop_Id Is NOT NULL AND @Group_Id is not NULL 	 SELECT @QueryType = @GroupAndPropertyFilter 	 --54
Else 	  	  	  	  	  	  	 SELECT @QueryType = @NoProductSpecified 	  	 --55 
--EndIf
--Build #Event_Status Table From the "Comma-Separated-$-Terminated" Event_Status List (EventStatusFilter)
--
DECLARE @CurrentInputString 	 Varchar(255) 	 --holds input string being processed
DECLARE @CurrentChar  	  	 Char 	  	 --current character from input string being examined
DECLARE @CharCount  	  	 Integer 	  	 --Characters count in Input string
DECLARE @CurrentEventStatus 	 Varchar(10) 	 --current Event_Status string to be converted
DECLARE @EventStatusCount  	 Integer
DECLARE @Event_Status  	  	 Int 	  	 --Event_Status converted
If @EventStatusFilter Is NOT NULL
  BEGIN
    --Initialzation
    SELECT @CurrentChar = ''
    SELECT @CurrentEventStatus = ''
    --Initialize input
    SELECT @CurrentInputString = @EventStatusFilter
    SELECT @CharCount = 1
    SELECT @CurrentChar = SUBSTRING (@CurrentInputString, @CharCount, 1)
    --Loop through @EventStatusFilter char-by-char 
    WHILE (@CurrentChar <> '$') AND (@CharCount < 7999)
      BEGIN
        If @CurrentChar <> ',' --Not a marker, must be part of status ID, collect this char
 	   SELECT @CurrentEventStatus = @CurrentEventStatus + LTRIM(RTRIM(@CurrentChar))
 	 Else --Char is a marker (comma), we have collected all chars for @CurrentEventStatus, process it
          BEGIN
            SELECT @CurrentEventStatus = LTRIM(RTRIM(@CurrentEventStatus))
            If @CurrentEventStatus <> '' 
              BEGIN
                SELECT @Event_Status = CONVERT(Int, @CurrentEventStatus)
                SELECT @EventStatusCount = @EventStatusCount + 1
                INSERT #Event_Status VALUES(@Event_Status)
              END
            --EndIf @CurrentEventStatus ..
 	     If @CurrentChar = ',' SELECT @CurrentEventStatus = ''  --Reset current string for next loop
          END
        --EndIf @CurrentChar ...
        SELECT @CharCount = @CharCount + 1
        SELECT @CurrentChar = SUBSTRING(@CurrentInputString, @CharCount, 1)
      END
    --End While
    --Process the last Event_Status we accumulated before reaching the terminating $
    SELECT @CurrentEventStatus = LTRIM(RTRIM(@CurrentEventStatus))
      If @CurrentEventStatus <> '' 
        BEGIN
          SELECT @Event_Status = CONVERT(Int, @CurrentEventStatus)
          SELECT @EventStatusCount = @EventStatusCount + 1
          INSERT #Event_Status VALUES(@Event_Status)
        END
      --EndIf      
  END
--EndIf @EventStatusFilter 
--Define numeric "Types" for final recordset queries
SELECT @NoStringHasStatusAsc  	 = 1
SELECT @NoStringHasStatusDesc 	 = 2
SELECT @HasStringHasStatusAsc  	 = 3
SELECT @HasStringHasStatusDesc  	 = 4
 	 --No request for Event Status, dont get it
SELECT @NoStringNoStatusAsc  	 = 5
SELECT @NoStringNoStatusDesc 	 = 6
SELECT @HasStringNoStatusAsc  	 = 7
SELECT @HasStringNoStatusDesc  	 = 8
--Set Up "Types" For Final RecordSet Retrieval (For BOTH Original AND Applied products)
If @SearchString Is NULL
  BEGIN
    If @NeedEventStatus = 1
      BEGIN
        SELECT @MyType = Case @TimeSort When 1 Then @NoStringHasStatusAsc Else @NoStringHasStatusDesc End
      END
    Else
      BEGIN
        SELECT @MyType = Case @TimeSort When 1 Then @NoStringNoStatusAsc Else @NoStringNoStatusDesc End
      END
    --EndIf
  END
Else --@SearchString NOT NULL
  BEGIN
    If @NeedEventStatus = 1
      BEGIN
        SELECT @MyType = Case @TimeSort When 1 Then @HasStringHasStatusAsc Else @HasStringHasStatusDesc End
      END
    Else
      BEGIN
        SELECT @MyType = Case @TimeSort When 1 Then @HasStringNoStatusAsc Else @HasStringNoStatusDesc End
      END
    --EndIf
  END
--EndIf @SearchString ...
If @AppliedProductFilter = 1 GOTO DO_APPLIED_PRODUCT_FILTER_STUFF
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
-- ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--ORIGINAL PRODUCT FILTER CODE--
--Build Temp Table (#Prod_Starts) Based On Times And Specific Product Information Received
--
If @QueryType = @NoProductSpecified 	  	  	 --Any product
  BEGIN
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE (   Start_Time BETWEEN @Start_Time AND @End_Time 
 	  	    OR End_Time BETWEEN @Start_Time AND @End_Time 
 	  	    OR ( Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL) )
                 )
      END
    Else
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE Pu_Id = @MasterUnit 
 	      AND (    Start_Time BETWEEN @Start_Time AND @End_Time
 	  	    OR End_Time BETWEEN @Start_Time AND @End_Time
 	  	    OR ( Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL) )
                 )
      END 
    --EndIf
  END
Else If @QueryType = @OneProductFilter 	  	  	 --Single Product
  BEGIN
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE Prod_Id = @Prod_Id 
 	      AND (    Start_Time BETWEEN @Start_Time AND @End_Time
 	  	    OR End_Time BETWEEN @Start_Time AND @End_Time
 	  	    OR ( Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL) )
                 )
      END
    Else
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE Pu_Id = @MasterUnit 
 	      AND Prod_Id = @Prod_Id 
 	      AND (    Start_Time BETWEEN @Start_Time AND @End_Time
 	  	    OR End_Time BETWEEN @Start_Time AND @End_Time
 	  	    OR ( Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL) )
                 )
      END 
    --EndIf
  END
Else
  BEGIN
    If @QueryType = @GroupFilter 	  	  	 --Single Product Group
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
      END
    Else If @QueryType = @CharacteristicFilter 	  	 --Single Characteristic
      BEGIN
         INSERT INTO #Products
         SELECT distinct Prod_Id FROM pu_characteristics WHERE prop_id = @Prop_Id AND char_id = @Char_Id
      END
    Else 	  	  	  	 --Group and Property
      BEGIN
         INSERT INTO #Products
         SELECT Prod_Id FROM product_group_data WHERE product_grp_id = @Group_Id
 	  INSERT INTO #Products
         SELECT distinct Prod_Id FROM pu_characteristics WHERE Prop_Id = @Prop_Id AND char_id = @Char_Id
      END
    --EndIf
    If @MasterUnit Is NULL
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
            JOIN #Products p on p.Prod_Id = ps.Prod_Id 
           WHERE (    Start_Time BETWEEN @Start_Time AND @End_Time
 	  	    OR End_Time BETWEEN @Start_Time AND @End_Time
 	  	    OR ( Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL) )
                 ) 
      END
    Else
      BEGIN
        INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
            JOIN #Products p on ps.Prod_Id = p.Prod_Id 
           WHERE Pu_Id = @MasterUnit 
 	      AND (    Start_Time BETWEEN @Start_Time and @End_Time
 	  	    OR End_Time BETWEEN @Start_Time AND @End_Time
 	  	    OR ( Start_Time <= @Start_Time AND (End_Time > @End_Time OR End_Time is NULL) )
                 ) 
      END  
    --EndIf
  END
--EndIf @QueryType ...
-- Build Events Temp Table From Given MasterUnit, EventStatusFilter in the specified time range.
-- NOTE: As of 3-25-2002 MSI Start_Time inEvents table are mostly null. This storec procedure will insert
--   a dummy value of TimeStamp minus one second for null Start_Time. For Customers who are concern about correct 
--   Start_Time, which affect correct time-dependent results, MSI will give them a script for one-time update of 
--   the Events table. This update is time/disk-space consuming, thus, available upon request only.
If @MasterUnit Is NULL
  BEGIN
    If @EventStatusFilter Is NULL
      BEGIN
        INSERT INTO #Events
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
               , e.Conformance, e.Testing_Prct_Complete                                        --ECR #24541: mt/1-20-2003
            FROM Events e
            JOIN #Prod_Starts ps on ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL)
           WHERE e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    Else --@EventStatusFilter NOT NULL
      BEGIN
        INSERT INTO #Events
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
               , e.Conformance, e.Testing_Prct_Complete                                        --ECR #24541: mt/1-20-2003
            FROM Events e
            JOIN #Prod_Starts ps on ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL)
            JOIN #Event_Status es ON es.Event_Status = e.Event_Status
           WHERE e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    --EndIf @EventStatusFilter
  END
Else --@MasterUnit NOT NULL
  BEGIN
    If @EventStatusFilter Is NULL
      BEGIN
        INSERT INTO #Events
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
               , e.Conformance, e.Testing_Prct_Complete                                        --ECR #24541: mt/1-20-2003
            FROM Events e
            JOIN #Prod_Starts ps on ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL)
           WHERE e.Pu_Id = @MasterUnit AND e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    Else --@EventStatusFilter NOT null
      BEGIN
        INSERT INTO #Events
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
               , e.Conformance, e.Testing_Prct_Complete                                        --ECR #24541: mt/1-20-2003
            FROM Events e
            JOIN #Prod_Starts ps on ps.PU_Id = e.PU_Id AND ps.Start_Time <= e.TimeStamp AND (ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL)
            JOIN #Event_Status es ON es.Event_Status = e.Event_Status
           WHERE e.Pu_Id = @MasterUnit AND e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    --EndIf @EventStatusFilter
  END
--EndIf @MasterUnit...
GOTO PROCESS_THE_RESULT_SET
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
-- APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** APPLIED PRODUCT FILTER CODE ** 
DO_APPLIED_PRODUCT_FILTER_STUFF:
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
  --Make Temp Production_Starts; Grab All "Original Products" in the Specified Range
  If @MasterUnit Is NULL
    BEGIN
      INSERT INTO #Prod_Starts
        SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
          FROM production_starts ps
         WHERE (   ps.Start_Time BETWEEN @Start_Time AND @End_Time 
                OR ps.End_Time BETWEEN @Start_Time AND @End_Time 
                OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time is NULL) )
               )
     END
  Else --@MasterUnit NOT NULL
    BEGIN
      INSERT INTO #Prod_Starts
          SELECT ps.Pu_Id, ps.Prod_Id, ps.Start_Time, ps.End_Time
            FROM production_starts ps
           WHERE ps.Pu_Id = @MasterUnit 
             AND (    ps.Start_Time BETWEEN @Start_Time AND @End_Time
                   OR ps.End_Time BETWEEN @Start_Time AND @End_Time
                   OR ( ps.Start_Time <= @Start_Time AND (ps.End_Time > @End_Time OR ps.End_Time is NULL) )
                 )
    END
  --EndIf
  -- Grab "Applied Products's TimeStamp" from Events Table; 
  -- Keep rows w/ Applied_Product = NULL AND the product match the filter (i.e., unconsumed original product is regarded 
  -- as Applied Product )
  -- For rows with Applied_Product <> Null, keep them only if the applied product matches the Applied_Product filter.
  -- (NOTE: See explanation for Original Product above regarding NULL Start_Time; MT/3-25-2002 )
  If @MasterUnit Is NULL
    BEGIN
      If @EventStatusFilter Is NULL
        BEGIN
          INSERT INTO #Events
               SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
                    , e.Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
                 FROM Events e
                 JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
                  AND ps.Pu_Id = e.Pu_Id AND e.Applied_Product Is NULL
                 JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
                WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
            UNION
               SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
                    , e.Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
                 FROM Events e
                 JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
                 JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
                  AND ps.Pu_Id = e.Pu_Id AND e.Applied_Product Is NOT NULL
                WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
        END
      Else --@EventStatusFilter NOT null
        BEGIN
          INSERT INTO #Events
               SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
                    , e.Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
                 FROM Events e
                 JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
                  AND ps.Pu_Id = e.Pu_Id AND e.Applied_Product Is NULL
                 JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
                 JOIN #Event_Status es ON es.Event_Status = e.Event_Status
                WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
            UNION
               SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
                    , e.Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
                 FROM Events e
                 JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
                 JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
                  AND ps.Pu_Id = e.Pu_Id AND e.Applied_Product Is NOT NULL
                 JOIN #Event_Status es ON es.Event_Status = e.Event_Status
                WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
        END
      --EndIf @EventStatusFilter 
     END
  Else --@MasterUnit NOT NULL
    BEGIN
      If @EventStatusFilter Is NULL
        BEGIN
          INSERT INTO #Events
               SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
                    , e.Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
                 FROM Events e
                 JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
                  AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @MasterUnit AND e.Applied_Product Is NULL
                 JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
                WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
            UNION
               SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
                    , e.Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
                 FROM Events e
                 JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
                 JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
                  AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @MasterUnit AND e.Applied_Product Is NOT NULL
                WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
        END
      Else --@EventStatusFilter NOT null
        BEGIN
          INSERT INTO #Events
               SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
                    , e.Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
                 FROM Events e
                 JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
                  AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @MasterUnit AND e.Applied_Product Is NULL
                 JOIN #Products tp ON tp.Prod_Id = ps.Prod_Id
                 JOIN #Event_Status es ON es.Event_Status = e.Event_Status
                WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
            UNION
               SELECT e.Event_Num, e.Event_Id, e.Pu_Id, ps.Prod_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status, e.Applied_Product
                    , e.Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
                 FROM Events e
                 JOIN #Products tp ON tp.Prod_Id = e.Applied_Product
                 JOIN #Prod_Starts ps ON ps.Start_Time <= e.TimeStamp AND ( ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL )
                  AND ps.Pu_Id = e.Pu_Id AND e.Pu_Id = @MasterUnit AND e.Applied_Product Is NOT NULL
                 JOIN #Event_Status es ON es.Event_Status = e.Event_Status
                WHERE e.TimeStamp >= @Start_Time AND e.TimeStamp <= @End_Time
        END
      --EndIf @EventStatusFilter...
    END 
  --EndIf @MasterUnit...
  GOTO PROCESS_THE_RESULT_SET
PROCESS_THE_RESULT_SET:
  --Determine Crew,Shift Type
  If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL      GOTO NOCREW_NOSHIFT_RESULTSET
  Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL  GOTO HASCREW_NOSHIFT_RESULTSET
  Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL  GOTO NOCREW_HASSHIFT_RESULTSET
  Else                                                    GOTO HASCREW_HASSHIFT_RESULTSET
  --EndIf @Crew_Desc 
NOCREW_NOSHIFT_RESULTSET:                                                                          
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType Queries
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_RESULTSET:
HASCREW_NOSHIFT_RESULTSET:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType Queries
  GOTO DROP_TEMP_TABLES
--End HASCREW_NOSHIFT_RESULTSET:
NOCREW_HASSHIFT_RESULTSET:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType Queries
  GOTO DROP_TEMP_TABLES
--End NOCREW_HASSHIFT_RESULTSET:
HASCREW_HASSHIFT_RESULTSET:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = e.Start_Time at time zone @DBTz at time zone @InTimeZone, TimeStamp = e.TimeStamp at time zone @DBTz at time zone @InTimeZone
             , e.Event_Conformance, e.Testing_Prct_Complete                                   --ECR #24541: mt/1-20-2003
             , Original_Product = p.Prod_Code, Applied_Product = p2.Prod_Code, Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number            --ECR #27992: mt/5-11-2004
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Products p ON p.Prod_Id = e.Prod_Id
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id AND co.Plant_Order_Number = @Plant_Order_Number
          JOIN Customer c ON c.Customer_Id = co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id AND sh.Shipment_Number = @Shipment_Number
          LEFT OUTER JOIN Products p2 ON p2.Prod_Id = e.Applied_Product
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType Queries
  GOTO DROP_TEMP_TABLES
--End HASCREW_HASSHIFT_RESULTSET:
DROP_TEMP_TABLES:
  DROP TABLE #Prod_Starts
  DROP TABLE #Products
  DROP TABLE #Event_Status
  DROP TABLE #Events