Create Procedure dbo.spDAML_FetchProductionDetailEventRecords
  @EventId INT = NULL,
  @LineId  INT = NULL,
  @UnitId  INT = NULL,
  @StartTime DATETIME = NULL,
  @EndTime DATETIME = NULL,
  @EventName VARCHAR(25) = NULL,
  @ProductCode VARCHAR(25) = NULL,
  @UTCOffset VARCHAR(30) = NULL,
  @UserId  INT = NULL,
  @MaxRecords INT = NULL
AS
-- Local variables
DECLARE 
  @TOPClause VARCHAR(20),
  @SecurityClause VARCHAR(100),
  @IdClause  VARCHAR(50),
  @OptionsClause  VARCHAR(1000),
  @TimeClause  VARCHAR(1000),
  @WhereClause VARCHAR(2000),
  @SelectClause   VARCHAR(5000),
  @OrderClause VARCHAR(100),
  @MinTime  VARCHAR(25),
  @MaxTime  VARCHAR(25),
  @STime   VARCHAR(25),
  @ETime   VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- Setup Top Clause if needed
SET @TOPClause = ''
if (@MaxRecords is not null) SET @TOPClause = ' TOP ' + Convert(VARCHAR(15), @MaxRecords)
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE Coalesce(pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN 'AND e.Event_Id = ' + CONVERT(VARCHAR(10),@EventId) 
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN 'AND e.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId)
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND pu.PL_Id = ' + CONVERT(VARCHAR(10),@LineId)
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@EventName<>'' AND @EventName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @EventName)=0 AND CHARINDEX('_', @EventName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND e.Event_Num = ''' + CONVERT(VARCHAR(25),@EventName) + ''' '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND e.Event_Num LIKE ''' + CONVERT(VARCHAR(25),@EventName) + ''' '
END
IF (@ProductCode<>'' AND @ProductCode IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProductCode)=0 AND CHARINDEX('_', @ProductCode)=0 )
     SET @OptionsClause = @OptionsClause + ' AND ISNULL(p2.Prod_Code, p1.Prod_Code) = ''' + CONVERT(VARCHAR(25),@ProductCode) + ''' '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND ISNULL(p2.Prod_Code, p1.Prod_Code) LIKE ''' + CONVERT(VARCHAR(25),@ProductCode) + ''' '
END
-- The TimeClause determines the interval of time to return
-- If the StartInterval is NULL, this is a TimeStamp
-- If there is no EventStartTime,
--   EventEndTime (TimeStamp) must be equal to the TimeStamp (IntervalEnd)
-- If there is an EventStartTime,
--   EventStartTime must be strictly less than the TimeStamp (IntervalEnd)
--   EventEndTime (TimeStamp) must be greater than or equal to the TimeStamp (IntervalEnd)
IF (@StartTime=@EndTime) SET @StartTime = NULL
IF (@EndTime IS NULL) AND (@StartTime IS NULL) BEGIN
  SET @ETime = @MaxTime
  SET @STime = @MinTime
  SET @TimeClause = ''
END
ELSE IF (@StartTime IS NULL) BEGIN
 SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
    SET @STime = @ETime
 SET @TimeClause = ' AND ((e.Start_Time is NULL ' +
       ' AND e.TimeStamp = ' + @ETime + ') ' +
       ' OR (e.Start_Time is NOT NULL AND e.Start_Time<>e.TimeStamp ' +
       ' AND e.Start_Time < ' + @ETime +  
       ' AND e.TimeStamp >= ' + @ETime + ') ' +
       ' OR (e.Start_Time is NOT NULL AND e.Start_Time=e.TimeStamp ' +
       ' AND e.TimeStamp = ' + @ETime + ')) ' 
END
-- If StartInterval is not NULL, this is an Interval
-- If there is no EventStartTime,
--    EventEndTime(TimeStamp) must be less than or equal to IntervalEnd
--    EventEndTime(TimeStamp) must be strictly greater than IntervalStart
-- If there is an EventStartTime and it is not equal to the TimeStamp (EventEndTime),
--    EventStartTime must be strictly less then IntervalEnd
--    EventEndTime (TimeStamp) must be strictly greater than IntervalStart
-- If there is an EventStartTime and it is equal to the TimeStamp (EventEndTime),
--   EventEndTime (TimeStamp) must be less than or eqaul to IntervalEnd
--   EventEndTime (TimeStamp) must be strictly greater than IntervalStart 
ELSE BEGIN
 SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
    IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
 SET @TimeClause = ' AND ((e.Start_Time is NULL ' +
      ' AND e.TimeStamp <= ' + @ETime + 
      ' AND e.TimeStamp > ' + @STime + ') ' +
      ' OR (e.Start_Time is NOT NULL AND e.Start_Time<>e.TimeStamp ' +
      ' AND e.Start_Time < ' + @ETime + 
      ' AND e.TimeStamp > ' + @STime + ') ' +
      ' OR (e.Start_Time IS NOT NULL AND e.Start_Time = e.TimeStamp ' +
      ' AND e.TimeStamp <= ' + @ETime + ' ' +
      ' AND e.TimeStamp > ' + @STime + ')) '
END
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
'SELECT' + @TOPClause + ' ProductionDetailEventId = ed.Event_Id,
  AlternateEventName = ed.Alternate_Event_Num,
  EventId = e.Event_Id,
  EventName = e.Event_Num,
  DepartmentId = d.Dept_Id,
  Department = d.Dept_Desc,
  ProductionLineId = pl.PL_Id,
  ProductionLine = pl.PL_Desc,
  ProductionUnitId = e.PU_Id,
  ProductionUnit = pu.PU_Desc, 
  TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,''UTC'')  ' +  ',
  EntryOn = CASE WHEN ed.Entered_On IS NULL THEN ' + @MaxTime +
          ' ELSE dbo.fnServer_CmnConvertFromDbTime(ed.Entered_On,''UTC'')  ' +
          ' END,
  EntryById = ed.Entered_By,
  EntryBy = u.Username,
  OriginalProductId = IsNull(s.Prod_Id,0),
  OriginalProduct = IsNull(p1.Prod_Code,''''), 
  AppliedProductId = IsNull(e.Applied_Product,0),
  AppliedProduct = IsNull(p2.Prod_Code, ''''), 
  ProductionPlanId = IsNull(pp.PP_Id,0),
  ProcessOrder = IsNull(pp.Process_Order, ''''),
  InitialDimensionX = IsNull(ed.Initial_Dimension_X, 0),
  InitialDimensionY = IsNull(ed.Initial_Dimension_Y, 0),
  InitialDimensionZ = IsNull(ed.Initial_Dimension_Z, 0),
  InitialDimensionA = IsNull(ed.Initial_Dimension_A, 0),
  FinalDimensionX = IsNull(ed.Final_Dimension_X, 0),
  FinalDimensionY = IsNull(ed.Final_Dimension_Y, 0),
  FinalDimensionZ = IsNull(ed.Final_Dimension_Z, 0),
  FinalDimensionA = IsNull(ed.Final_Dimension_A, 0),
  OrientationX = IsNull(ed.Orientation_X, 0),
  OrientationY = IsNull(ed.Orientation_Y, 0),
  OrientationZ = IsNull(ed.Orientation_Z, 0),
  OrientationA = IsNull(ed.Orientation_A, 0),
  CommentId = IsNull(ed.Comment_Id, 0),
  OrderId = IsNull(ed.Order_Id,0),
  OrderLineId = IsNull(ed.Order_Line_Id,0),
  ShipmentId = IsNull(ed.Shipment_Id,0),
  ProductionPlanSetupDetailId = IsNull(ed.PP_Setup_Detail_Id,0),
  ESignatureId = IsNull(e.Signature_Id, 0),
  UserId = IsNull(e.User_Id,0)
FROM  Event_Details ed 
 INNER JOIN events e ON ed.Event_Id = e.Event_Id
 INNER JOIN Production_Starts s ON s.PU_Id = e.PU_Id AND e.PU_Id > 0 
    AND e.TimeStamp > s.Start_Time AND (e.TimeStamp <= s.End_Time OR s.End_Time Is Null)
 INNER JOIN Products p1 ON p1.Prod_Id = s.Prod_Id 
 LEFT JOIN Products p2 ON p2.Prod_Id = e.Applied_Product 
 INNER JOIN Prod_Units pu ON pu.PU_Id = e.PU_Id
 INNER JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
 INNER JOIN Departments d ON d.Dept_Id = pl.Dept_Id
 LEFT JOIN Production_Plan_Starts pps ON pps.PU_Id = e.PU_Id AND e.PU_Id > 0 
    AND e.TimeStamp > pps.Start_Time AND (e.TimeStamp <= pps.End_Time OR pps.End_Time Is Null) 
 LEFT JOIN Production_Plan pp ON pps.PP_Id = pp.PP_Id 
 LEFT JOIN Users u ON ed.Entered_By = u.User_Id 
 LEFT JOIN User_Security pls ON pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 LEFT JOIN User_Security pus ON  pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId) 
-- order clause
SET @OrderClause = ' ORDER BY e.TimeStamp '
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
