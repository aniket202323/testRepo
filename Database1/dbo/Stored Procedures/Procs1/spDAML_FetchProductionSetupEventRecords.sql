Create Procedure dbo.spDAML_FetchProductionSetupEventRecords
  @EventId INT = NULL,
  @LineId  INT = NULL,
  @UnitId  INT = NULL,
  @ProductionPath VARCHAR(50) = NULL,
  @ProcessOrder VARCHAR(50) = NULL,
  @UTCOffset VARCHAR(30) = NULL,
  @UserId  INT = NULL
AS
-- Local variables
DECLARE 
  @SecurityClause VARCHAR(100),
  @IdClause  VARCHAR(50),
  @OptionsClause  VARCHAR(1000),
  @TimeClause  VARCHAR(1000),
  @WhereClause VARCHAR(2000),
  @SelectClause   VARCHAR(5000),
  @OrderClause VARCHAR(100),
  @MinTime  VARCHAR(25),
  @MaxTime  VARCHAR(25),
  @STime   VARCHAR(100),
  @ETime   VARCHAR(100)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE Coalesce(pus.Access_Level, pls.Access_Level, 3) >= 2 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN ' AND (ps.PP_Setup_Id = ' + CONVERT(VARCHAR(10),@EventId) + ') '
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN ' AND (pepu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId) + ') '
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND (pu.PL_Id = ' + CONVERT(VARCHAR(10),@LineId) + ') '
   ELSE ''
END
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@ProcessOrder<>'' AND @ProcessOrder IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProcessOrder)=0 AND CHARINDEX('_', @ProcessOrder)=0 )
     SET @OptionsClause = @OptionsClause + ' AND (pp.Process_Order = ''' + CONVERT(VARCHAR(50),@ProcessOrder) + ''') '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND (pp.Process_Order LIKE ''' + CONVERT(VARCHAR(50),@ProcessOrder) + ''') '
END
IF (@ProductionPath<>'' AND @ProductionPath IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProductionPath)=0 AND CHARINDEX('_', @ProductionPath)=0 )
      SET @OptionsClause = @OptionsClause + ' AND (pep.Path_Code = ''' + CONVERT(VARCHAR(50),@ProductionPath) + ''') '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND (pep.Path_Code LIKE ''' + CONVERT(VARCHAR(50),@ProductionPath) + ''') '
END
-- The TimeClause determines the interval of time to return
SET @TimeClause = ' '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
'SELECT ProductionPlanSetupId = ps.PP_Setup_Id,
  PatternCode = IsNull(ps.Pattern_Code,''''),
  ProductionPlanId = ps.PP_Id,
  ProcessOrder = IsNull(pp.Process_Order,''''),
  ForecastQuantity = IsNull(ps.Forecast_Quantity,0),
  ActualStartTime = CASE WHEN ps.Actual_Start_Time IS NULL THEN ' + @MaxTime +
                  ' ELSE dbo.fnServer_CmnConvertFromDbTime(ps.Actual_Start_Time,''UTC'')  ' + 
                  ' END,
  ActualEndTime = CASE WHEN ps.Actual_End_Time IS NULL THEN ' + @MaxTime +
                ' ELSE dbo.fnServer_CmnConvertFromDbTime(ps.Actual_End_Time,''UTC'')  ' + 
                ' END,
  ActualQuantity = IsNull(ps.Actual_Good_Quantity,0),
  DepartmentId = IsNull(pl.Dept_Id,0),
  Department = IsNull(d.Dept_Desc, ''''),
  ProductionLineId = IsNull(pu.PL_Id,0),
  ProductionLine = IsNull(pl.PL_Desc, ''''),
  ProductionUnitId = IsNull(pepu.PU_Id,0),
  ProductionUnit = IsNull(pu.PU_Desc, ''''),
  PathId = IsNull(pep.Path_Id,0),
  PathCode = IsNull(pep.Path_Code,''''),
  ImpliedSequence = IsNull(ps.Implied_Sequence,0),
  ParentProductionPlanSetupId = IsNull(ps.Parent_PP_Setup_Id, 0),
  ParentPatternCode = IsNull(ps2.Pattern_Code, 0),
  ProductionPlanStatusId = IsNull(ps.PP_Status_Id,0),
  ProductionPlanStatus = IsNull(ppst.PP_Status_Desc,0),
  CommentId = IsNull(ps.Comment_Id, 0),
  BaseGeneral1 = IsNUll(ps.Base_General_1,''''),
  BaseGeneral2 = IsNull(ps.Base_General_2,''''),
  BaseGeneral3 = IsNUll(ps.Base_General_3,''''),
  BaseGeneral4 = IsNUll(ps.Base_General_4,''''),
  UserGeneral1 = IsNUll(ps.User_General_1,''''),
  UserGeneral2 = IsNull(ps.User_General_2,''''),
  UserGeneral3 = IsNUll(ps.User_General_3,''''),
  PredictedRemainingQuantity = IsNull(ps.Predicted_Remaining_Quantity,0),
  ActualBadQuantity = IsNull(ps.Actual_Bad_Quantity,0),
  PredictedTotalDuration = IsNull(ps.Predicted_Total_Duration,0),
  PredictedRemainingDuration = IsNull(ps.Predicted_Remaining_Duration,0),
  ActualRunningTime = IsNull(ps.Actual_Running_Time,0),
  ActualDownTime = IsNull(ps.Actual_Down_Time,0),
  ActualGoodItems = IsNull(ps.Actual_Good_Items,0),
  ActualBadItems = IsNull(ps.Actual_Bad_Items,0),
  Repetitions = IsNull(ps.Pattern_Repititions, 0),
  AlarmCount = IsNull(ps.Alarm_Count,0),
  LateItems = IsNull(ps.Late_Items,0),
  Shrinkage = IsNull(ps.Shrinkage, 0),
  ActualRepetitions = IsNull(ps.Actual_Repetitions,0),
  DimensionX = IsNull(ps.Base_Dimension_X, 0),
  DimensionY = IsNull(ps.Base_Dimension_Y, 0),
  DimensionZ = IsNull(ps.Base_Dimension_Z, 0),
  DimensionA = IsNull(ps.Base_Dimension_A, 0),
  EntryOn = CASE WHEN ps.Entry_On IS NULL THEN ' + @MaxTime +
           ' ELSE dbo.fnServer_CmnConvertFromDbTime(ps.Entry_On,''UTC'')  ' + 
           ' END,
  ExtendedInfo = IsNull(ps.Extended_Info,'''')
FROM PrdExec_Paths pep 
 JOIN Production_Plan pp ON pp.Path_Id = pep.Path_Id 
 JOIN Production_Setup ps ON ps.PP_Id = pp.PP_Id 
 JOIN Production_Plan_Statuses ppst ON ppst.PP_Status_Id = ps.PP_Status_Id 
 LEFT OUTER JOIN Production_Setup ps2 ON ps2.PP_Setup_Id = ps.Parent_PP_Setup_Id
 LEFT OUTER JOIN PrdExec_Path_Units pepu  ON pepu.Path_Id = pp.Path_Id and pepu.Is_Schedule_Point = 1
 LEFT OUTER JOIN Prod_Units pu ON pu.PU_Id = pepu.PU_Id 
 LEFT OUTER JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
 LEFT OUTER JOIN Departments d ON d.Dept_Id = pl.Dept_Id
 LEFT JOIN User_Security pls ON pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
 LEFT JOIN User_Security pus ON pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId)
-- order clause
SET @OrderClause = ' ORDER BY ps.Implied_Sequence '
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause )
