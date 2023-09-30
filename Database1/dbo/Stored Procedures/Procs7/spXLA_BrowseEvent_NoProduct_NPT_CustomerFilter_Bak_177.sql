/* NOTE  
   ECR #24541:mt/1-15-2003:added Conformance & Testing_Prct_Compete
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
   NOT to add more branches of SQL Statement into spXLA_BrowseEvent_NoProduct but to expand into 8 stored procedures listed 
   below. Future bug fix to core code, if any, should be done in all 8 stored procedures.  
   The 8 stored procedures are:
   (1) spXLA_BrowseEvent_NoProduct 	  	  	  	 'Master copy
   (2) spXLA_BrowseEvent_NoProduct_ShipFilter
   (3) spXLA_BrowseEvent_NoProduct_NPT_CustomerFilter 	  	 'This stored Procedure
   (4) spXLA_BrowseEvent_NoProduct_CustomerShipFilters
   (5) spXLA_BrowseEvent_NoProduct_PlantFilter
   (6) spXLA_BrowseEvent_NoProduct_PlantShipFilters
   (7) spXLA_BrowseEvent_NoProduct_PlantCustomerFilters
   (8) spXLA_BrowseEvent_NoProduct_PlantCustomerShip
*/
-- USAGE: 
-- spXLA_BrowseEvent_NoProduct_NPT_CustomerFilter should be called when no-product join condition is met and 
-- Customer_Code filter is specified. MSi/mt/9-30-20002
--
CREATE PROCEDURE dbo.[spXLA_BrowseEvent_NoProduct_NPT_CustomerFilter_Bak_177] 
 	   @SearchString  	 VarChar(50)
 	 , @Start_Time  	  	 DateTime
 	 , @End_Time 	  	 DateTime
 	 , @MasterUnit 	  	 Int
 	 , @MasterUnitName 	 VarChar(50)
 	 , @Crew_Desc            Varchar(10)
 	 , @Shift_Desc           Varchar(10)
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
 	 --Needed for crew,shift
DECLARE @CrewShift              TinyInt
DECLARE @NoCrewNoShift          TinyInt
DECLARE @HasCrewNoShift         TinyInt
DECLARE @NoCrewHasShift         TinyInt
DECLARE @HasCrewHasShift        TinyInt
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
CREATE TABLE #Events (Event_Num Varchar(25), Event_Id Int, Pu_Id Int, Start_Time DateTime, TimeStamp DateTime
                    , Extended_Info Varchar(255) NULL, Event_Status Int NULL
                    , Event_Conformance TinyInt NULL, Testing_Prct_Complete TinyInt NULL,NPT tinyint NULL) --ECR #24541:mt/1-15-2003
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
 	 --Define crew,shift types
SELECT @NoCrewNoShift           = 1
SELECT @HasCrewNoShift          = 2
SELECT @NoCrewHasShift          = 3
SELECT @HasCrewHasShift         = 4
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
               , e.Conformance, e.Testing_Prct_Complete, NULL  	  	                                --ECR #24541:mt/1-15-2003
            FROM Events e
           WHERE e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    Else --@EventStatusFilter NOT NULL
      BEGIN
        INSERT INTO #Events
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status
               , e.Conformance, e.Testing_Prct_Complete , NULL                                  --ECR #24541:mt/1-15-2003
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
               , e.Conformance, e.Testing_Prct_Complete , NULL                                  --ECR #24541:mt/1-15-2003
            FROM Events e
           WHERE e.Pu_Id = @MasterUnit AND e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    Else --@EventStatusFilter NOT null
      BEGIN
        INSERT INTO #Events
          SELECT e.Event_Num, e.Event_Id, e.Pu_Id, COALESCE(e.Start_Time, DATEADD(ss, -1, e.TimeStamp)), e.TimeStamp, e.Extended_Info, e.Event_Status
               , e.Conformance, e.Testing_Prct_Complete , NULL                                  --ECR #24541:mt/1-15-2003
            FROM Events e
            JOIN #Event_Status es ON es.Event_Status = e.Event_Status
           WHERE e.Pu_Id = @MasterUnit AND e.TimeStamp BETWEEN @Start_Time AND @End_Time
      END
    --EndIf @EventStatusFilter
  END
--EndIf @MasterUnit...
/*
 	  	 Non Productive Time
 	  	 TODO: Copy the below lines to a new sp so that we can just call that new sp
*/
DECLARE @Periods_NPT TABLE ( PeriodId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,StartTime Datetime, EndTime Datetime,NPDuration int)
      INSERT INTO @Periods_NPT ( Starttime,Endtime)
      SELECT      
                  StartTime               = CASE      WHEN np.Start_Time < @Start_Time THEN @Start_Time
                                                ELSE np.Start_Time
                                                END,
                  EndTime           = CASE      WHEN np.End_Time > @End_time THEN @End_time
                                                ELSE np.End_Time
                                                END
      FROM dbo.NonProductive_Detail np WITH (NOLOCK)
            JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON      ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
                                                                                                      AND ercd.ERC_Id = (SELECT Non_Productive_Category FROM prod_units where PU_id =@MasterUnit)
      WHERE PU_Id = @MasterUnit
                  AND np.Start_Time < @End_time
                  AND np.End_Time > @Start_Time
-------NPT OF Downtime-------
-- Case 1 :  Downtime    St---------------------End
-- 	  	  	  NPT   St--------------End
UPDATE #Events SET Start_Time = n.Endtime,
 	  	  	  	  	 NPT = 1
FROM #Events  JOIN @Periods_NPT n ON (Start_Time > n.StartTime AND TimeStamp > n.EndTime AND Start_Time < n.EndTime)
-- Case 2 :  Downtime    St---------------------End
-- 	  	  	  NPT 	  	  	  	  	 St--------------End
UPDATE #Events SET TimeStamp = n.Starttime,
 	  	  	  	    NPT = 1
FROM 	 #Events 	  	    
JOIN @Periods_NPT n ON (Start_Time < n.StartTime AND TimeStamp < n.Endtime AND TimeStamp > n.StartTime)
 	  	 
-- Case 3 :  Downtime   St-----------------------End
-- 	  	  	  NPT   St-------------------------------End
UPDATE #Events SET Start_Time = TimeStamp,
 	  	  	  	  	 NPT = 1
FROM 	 #Events  	  	    
JOIN @Periods_NPT n ON( (Start_Time BETWEEN n.StartTime AND n.EndTime) AND (TimeStamp BETWEEN n.StartTime AND n.EndTime))
--Update #Events Set Duration =DateDiff(ss,Start_Time,TimeStamp)/60.0
-- Case 4 :  Downtime   St-----------------------End
-- 	  	  	  NPT 	  	    St-----------------End
UPDATE #Events  SET NPT = 1
FROM #Events  JOIN @Periods_NPT n ON( (n.StartTime BETWEEN Start_Time AND TimeStamp) AND (n.Endtime BETWEEN Start_Time AND TimeStamp))  
Delete from #Events where NPT = 1
--Determine Crew,Shift Type
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL      SELECT @CrewShift = @NoCrewNoShift
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL  SELECT @CrewShift = @HasCrewNoShift
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL  SELECT @CrewShift = @NoCrewHasShift
Else                                                    SELECT @CrewShift = @HasCrewHasShift
--EndIf @Crew_Desc 
--Decide What/How To Include In ResultSet
If      @ShowOrderInfo = 1 AND @ShowShipmentInfo = 1  GOTO ORDER_AND_SHIPMENT_RESULTSET
Else If @ShowOrderInfo = 0 AND @ShowShipmentInfo = 1  GOTO SHIPMENT_RESULTSET
Else If @ShowOrderInfo = 1 AND @ShowShipmentInfo = 0  GOTO ORDER_RESULTSET
Else If @ShowOrderInfo = 0 AND @ShowShipmentInfo = 0  GOTO BASIC_EVENT_INFO_RESULTSET
--EndIf
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
-- BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET BASIC_EVENT_INFO_RESULTSET
BASIC_EVENT_INFO_RESULTSET:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If      @CrewShift = @NoCrewNoShift   GOTO NOCREW_NOSHIFT_BASIC_INFO_RESULTSET
  Else If @CrewShift = @HasCrewNoShift  GOTO HASCREW_NOSHIFT_BASIC_INFO_RESULTSET
  Else If @CrewShift = @NoCrewHasShift  GOTO NOCREW_HASSHIFT_BASIC_INFO_RESULTSET
  Else                                  GOTO HASCREW_HASSHIFT_BASIC_INFO_RESULTSET
  --EndIf:Crew,shift
NOCREW_NOSHIFT_BASIC_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_BASIC_INFO_RESULTSET:
HASCREW_NOSHIFT_BASIC_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End HASCREW_NOSHIFT_BASIC_INFO_RESULTSET:
NOCREW_HASSHIFT_BASIC_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End NOCREW_HASSHIFT_BASIC_INFO_RESULTSET:
HASCREW_HASSHIFT_BASIC_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End HASCREW_HASSHIFT_BASIC_INFO_RESULTSET:
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
--  ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET ORDER_RESULTSET
ORDER_RESULTSET:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If      @CrewShift = @NoCrewNoShift   GOTO NOCREW_NOSHIFT_ORDER_INFO_RESULTSET
  Else If @CrewShift = @HasCrewNoShift  GOTO HASCREW_NOSHIFT_ORDER_INFO_RESULTSET
  Else If @CrewShift = @NoCrewHasShift  GOTO NOCREW_HASSHIFT_ORDER_INFO_RESULTSET
  Else                                  GOTO HASCREW_HASSHIFT_ORDER_INFO_RESULTSET
  --EndIf:Crew,shift
NOCREW_NOSHIFT_ORDER_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_ORDER_INFO_RESULTSET:
HASCREW_NOSHIFT_ORDER_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End HASCREW_NOSHIFT_ORDER_INFO_RESULTSET:
NOCREW_HASSHIFT_ORDER_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End NOCREW_HASSHIFT_ORDER_INFO_RESULTSET:
HASCREW_HASSHIFT_ORDER_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End HASCREW_HASSHIFT_ORDER_INFO_RESULTSET:
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
-- SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET SHIPMENT_RESULTSET
SHIPMENT_RESULTSET:
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If      @CrewShift = @NoCrewNoShift   GOTO NOCREW_NOSHIFT_SHIPMENT_INFO_RESULTSET
  Else If @CrewShift = @HasCrewNoShift  GOTO HASCREW_NOSHIFT_SHIPMENT_INFO_RESULTSET
  Else If @CrewShift = @NoCrewHasShift  GOTO NOCREW_HASSHIFT_SHIPMENT_INFO_RESULTSET
  Else                                  GOTO HASCREW_HASSHIFT_SHIPMENT_INFO_RESULTSET
  --EndIf:Crew,shift
NOCREW_NOSHIFT_SHIPMENT_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_SHIPMENT_INFO_RESULTSET:
HASCREW_NOSHIFT_SHIPMENT_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End HASCREW_NOSHIFT_SHIPMENT_INFO_RESULTSET:
NOCREW_HASSHIFT_SHIPMENT_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End NOCREW_HASSHIFT_SHIPMENT_INFO_RESULTSET:
HASCREW_HASSHIFT_SHIPMENT_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End HASCREW_HASSHIFT_SHIPMENT_INFO_RESULTSET:
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
-- ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET ORDER_AND_SHIPMENT_RESULTSET
ORDER_AND_SHIPMENT_RESULTSET:                                                                          
  --SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
  If      @CrewShift = @NoCrewNoShift   GOTO NOCREW_NOSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET
  Else If @CrewShift = @HasCrewNoShift  GOTO HASCREW_NOSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET
  Else If @CrewShift = @NoCrewHasShift  GOTO NOCREW_HASSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET
  Else                                  GOTO HASCREW_HASSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET
  --EndIf:Crew,shift
NOCREW_NOSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info
          FROM #Events e
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET:
HASCREW_NOSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End HASCREW_NOSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET:
NOCREW_HASSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End NOCREW_HASSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET:
HASCREW_HASSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET:
  If @MyType = @NoStringHasStatusAsc --1
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringHasStatusDesc --2
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusAsc --3
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringHasStatusDesc --4
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc, s.ProdStatus_Desc as 'Event_Status'
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
          LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
        WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusAsc --5
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @NoStringNoStatusDesc --6
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusAsc --7
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp ASC, e.Event_Num
    END
  Else If @MyType = @HasStringNoStatusDesc --8
    BEGIN
        SELECT Primary_Event_Num = e.Event_Num, Event_Id = e.Event_Id, Start_Time = dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
             , e.Event_Conformance, e.Testing_Prct_Complete                            --ECR #24541:mt/1-15-2003
             , Production_Unit = pu.Pu_Desc
             , ed.Initial_Dimension_A, ed.Initial_Dimension_X, ed.Initial_Dimension_Y, ed.Initial_Dimension_Z
             , ed.Final_Dimension_A, ed.Final_Dimension_X, ed.Final_Dimension_Y, ed.Final_Dimension_Z
             , ed.Orientation_X, ed.Orientation_Y, ed.Orientation_Z
             , co.Customer_Order_Number, co.Plant_Order_Number, sh.Shipment_Number, e.Extended_Info, CS.Crew_Desc, CS.Shift_Desc
          FROM #Events e
          JOIN Crew_Schedule CS ON CS.Pu_Id = e.Pu_Id AND CS.Crew_Desc = @Crew_Desc AND CS.Shift_Desc = @Shift_Desc AND e.TimeStamp BETWEEN CS.Start_Time AND CS.End_Time 
          JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
          LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
          LEFT OUTER JOIN Customer_Order_Line_Items l ON l.Order_Line_Id = ed.Order_Line_Id
          JOIN Customer_Orders co ON co.Order_Id = l.Order_Id
          JOIN Customer c ON c.Customer_Id =  co.Customer_Id AND c.Customer_Code = @Customer_Code
          LEFT OUTER JOIN Shipment_Line_Items sl ON sl.Shipment_Item_Id = ed.Shipment_Item_Id
          LEFT OUTER JOIN Shipment sh ON sh.Shipment_Id = sl.Shipment_Id
         WHERE e.Event_Num Like '%' + ltrim(rtrim(@SearchString)) + '%'
      ORDER BY e.TimeStamp DESC, e.Event_Num
    END
  --EndIf @MyType 
  GOTO DROP_TEMP_TABLES
--End HASCREW_HASSHIFT_ORDER_AND_SHIPMENT_INFO_RESULTSET:
DROP_TEMP_TABLES:
  DROP TABLE #Event_Status
  DROP TABLE #Events
