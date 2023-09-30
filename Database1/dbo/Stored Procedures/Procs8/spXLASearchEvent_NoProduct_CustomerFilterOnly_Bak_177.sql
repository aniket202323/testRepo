/* NOTE ON spXLASearchEvent_NoProduct: Derived from spXLASearchEvent_APMax with the "Applied Product" code removed. Thus
   the SP name "_NoProduct". 
   Originally, we divide stored procedures into 5 groups based on the need for joins to obtain the required attributes for
   the events sought. The four groups carry unique suffixes as outlined below:
     0) _NoProduct 	 indicate no product join at all
     1) _APMin: 	  	 indicates minimum joins (join production_Starts only)
     2) _APOrder: 	 indicates joins to get Order information Plant_Order_Number, Customer_Order_Number
     3) _APShipment: 	 indicates joins to get Shipment information
     4) _APMax: 	  	 indicates joins to get both Order and shipment information
   Note On @ShowEventStatus & @EventStatusFilter -- @ShowEventStatus signifies user wants to retrieve Event status, whereas
   @EventStatusFilter is a list of Event_Status by which user wants to filter. They are independent of each other; e.g., 
   user may specify filter but don't want to retrieve event status.
   MSi/mt/11-12-2001
   MSi/mt/01-22-2002
   Major expansion. Add 3 additional filters, Plant_Order_Number, Customer_Code, Shipment_Number. Choose
   NOT to add more branches of SQL Statement into spXLASearchEvent_NoProduct but to expand into 8 stored procedures listed 
   below. Future bug fix to core code, if any, should be done in all 8 stored procedures.  
   The 8 stored procedures are:
   (1) spXLASearchEvent_NoProduct 	  	  	  	 'Master copy
   (2) spXLASearchEvent_NoProduct_ShipFilterOnly
   (3) spXLASearchEvent_NoProduct_CustomerFilterOnly 	  	 'This stored Procedure
   (4) spXLASearchEvent_NoProduct_CustomerAndShipFilters
   (5) spXLASearchEvent_NoProduct_PlantFilterOnly
   (6) spXLASearchEvent_NoProduct_PlantAndShipFilters
   (7) spXLASearchEvent_NoProduct_PlantAndCustomerFilters
   (8) spXLASearchEvent_NoProduct_PlantCustomerAndShip
*/
-- USAGE: 
-- spXLASearchEvent_NoProduct_CustomerFilterOnly should be called when no-product join condition is met and 
-- Customer_Code filter is specified. MSi/mt/1-29-2002
--
CREATE PROCEDURE dbo.[spXLASearchEvent_NoProduct_CustomerFilterOnly_Bak_177] 
 	   @SearchString  	 VarChar(50)
 	 , @Start_Time  	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @MasterUnit 	  	 Int
 	 , @MasterUnitName 	 VarChar(50)
 	 , @ShowEventStatus 	 TinyInt 	  	 -- 1 = include event status in resultSet: 0 = exclude
 	 , @EventStatusFilter 	 VarChar(500) 	 -- NULL OR Comma-separated-$-terminating list of Event_Status (tinyint)
 	 , @ShowOrderInfo 	 TinyInt 	  	 -- 1 = include order information in resultSet 0 = exclude
 	 , @ShowShipmentInfo 	 TinyInt 	  	 -- 1 = include shipment information in resultSet: 0 = exclude it
 	 , @Customer_Code 	 Varchar(50) 	 -- Filter By Customer_Code; MSi/mt/12-05-2001
 	 , @TimeSort 	  	 TinyInt = NULL 	 -- 1 = Ascending, Otherwise Descending
 	 , @InTimeZone 	 varchar(200) = null
AS
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
If @TimeSort IS NULL    SELECT @TimeSort = 1  --Ascending, DEFAULT
If @Start_Time Is NULL 	 SELECT @Start_Time = '1-jan-1971'
If @End_Time Is NULL 	 SELECT @End_Time = dateadd(day,7,getdate())
SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,@InTimeZone)
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,@InTimeZone)
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
CREATE TABLE #Event_Status (Event_Status Int)
CREATE TABLE #Events (Event_Num Varchar(25), Event_Id Int, Pu_Id Int, Start_Time DateTime, End_Time DateTime
                    , Extended_Info Varchar(255) NULL, Event_Status Int NULL)
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
    If @ShowEventStatus = 1
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
    If @ShowEventStatus = 1
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
-- Build Events Temp Table From Given MasterUnit, EventStatusFilter in the specified time range.
-- NOTE: As of 3-25-2002 MSI Start_Time inEvents table are mostly null. This storec procedure will insert
--   a dummy value of TimeStamp minus one seconde for null Start_Time. For Customers who are concern about correct 
--   Start_Time, which affect correct time-dependent results, MSI will give them a script for one-time update of 
--   the Events table. This update is time/disk-space consuming, thus, available upon request only.
--
--
If @MasterUnit Is NULL
  BEGIN
    If @EventStatusFilter Is NULL
      BEGIN
        INSERT INTO #Events
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status
            FROM Events e
           WHERE e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    Else --@EventStatusFilter NOT NULL
      BEGIN
        INSERT INTO #Events
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status
            FROM Events e
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
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status
            FROM Events e
           WHERE e.Pu_Id = @MasterUnit AND e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    Else --@EventStatusFilter NOT null
      BEGIN
        INSERT INTO #Events
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status
            FROM Events e
            JOIN #Event_Status es ON es.Event_Status = e.Event_Status
           WHERE e.Pu_Id = @MasterUnit AND e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    --EndIf @EventStatusFilter
  END
--EndIf @MasterUnit...
--Decide What/How To Include In ResultSet
If      @ShowOrderInfo = 1 AND @ShowShipmentInfo = 1  GOTO RESULT_SET_INCLUDE_ORDER_AND_SHIPMENT_INFORMATION
Else If @ShowOrderInfo = 0 AND @ShowShipmentInfo = 1  GOTO RESULT_SET_INCLUDE_SHIPMENT_INFORMATION
Else If @ShowOrderInfo = 1 AND @ShowShipmentInfo = 0  GOTO RESULT_SET_INCLUDE_ORDER_INFORMATION
Else If @ShowOrderInfo = 0 AND @ShowShipmentInfo = 0  GOTO RESULT_SET_INCLUDE_BASIC_EVENT_INFORMATION_ONLY
--EndIf
-- BASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFO
-- BASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFO
-- BASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFO
-- BASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFOBASICEVENTINFO
RESULT_SET_INCLUDE_BASIC_EVENT_INFORMATION_ONLY:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--  ORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDER
--  ORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDER
--  ORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDER
--  ORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDERORDER
RESULT_SET_INCLUDE_ORDER_INFORMATION:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
-- SHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENT
-- SHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENT
-- SHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENT
-- SHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENT
-- SHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENTSHIPMENT
RESULT_SET_INCLUDE_SHIPMENT_INFORMATION:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
-- ORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENT
-- ORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENT
-- ORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENT
-- ORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENTORDERANDSHIPMENT
RESULT_SET_INCLUDE_ORDER_AND_SHIPMENT_INFORMATION:                                                                          
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num
             , Event_Id = e.Event_Id
             , Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone)                                                      --2002Jan21;mt
             , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.End_Time,@InTimeZone)
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number
             , sh.Shipment_Number
             , e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id        --30-Nov-2001;mt
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id        --29Jan2002;mt
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id                                      --29Jan2002;mt
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code  --29Jan2002;mt
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.End_Time DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
DROP_TEMP_TABLES:
  DROP TABLE #Event_Status
  DROP TABLE #Events
