Create Procedure dbo.spDAML_FetchProductionStatistics
  @ProductionPlanId INT = NULL,
  @StartTime DATETIME = NULL,
  @EndTime DATETIME = NULL,
  @UTCOffset VARCHAR(30) = NULL
AS
-- Local variables
DECLARE 
  @SecurityClause VARCHAR(100),
  @IdClause  VARCHAR(50),
  @OptionsClause  VARCHAR(2000),
  @TimeClauseA VARCHAR(500),
  @TimeClauseB VARCHAR(500),
  @WhereClauseA VARCHAR(2000),
  @WhereClauseB VARCHAR(2000),
  @SelectClauseA   VARCHAR(4000),
  @SelectClauseB   VARCHAR(4000),
  @OrderClause VARCHAR(100),
  @MinTime  VARCHAR(25),
  @MaxTime  VARCHAR(25),
  @STime   VARCHAR(25),
  @ETime   VARCHAR(25)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- Production Statistics have no special security
SET @SecurityClause = ' WHERE 1=1 '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@ProductionPlanId<>0 AND @ProductionPlanId IS NOT NULL) THEN 'AND pp.PP_Id = ' + CONVERT(VARCHAR(10),@ProductionPlanId) 
   ELSE ''
END
-- Production Statistics have no options
SET @OptionsClause = ''
-- The TimeClause determines the interval of time to return
-- EventStartTime must be strictly less than IntervalEnd
-- EventEndTime must be strictly greater than IntervalStart
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClauseA = ' AND pp.Actual_Start_Time < ' + @ETime + 
         ' AND (pp.Actual_End_Time > ' + @STime + ' OR pp.Actual_End_Time IS NULL) '
SET @TimeClauseB = ' AND ps.Actual_Start_Time < ' + @ETime + 
         ' AND (ps.Actual_End_Time > ' + @STime + ' OR ps.Actual_End_Time IS NULL) '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClauseA = @SecurityClause + @IdClause + @OptionsClause + @TimeClauseA
SET @WhereClauseB = @SecurityClause + @IdClause + @OptionsClause + @TimeClauseB
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClauseA = ' SELECT StatsType = 1,
   StatsTypeName = ''Production Plan'',
   ProductionPlanId = pp.PP_Id,
   ProcessOrder = IsNull(pp.Process_Order,''''),
   ProductionSetupId = 0,
   ControlTypeId  = IsNull(pp.Control_Type,0),
   ControlType = IsNull(ct.Control_Type_Desc,''''),
   ActualStartTime = CASE WHEN pp.Actual_Start_Time IS NULL THEN ' + @MaxTime +
                    ' ELSE dbo.fnServer_CmnConvertFromDbTime(pp.Actual_Start_Time,''UTC'')  ' + 
                    ' END,  
   ActualEndTime = CASE WHEN pp.Actual_End_Time IS NULL THEN ' + @MaxTime +
                  ' ELSE dbo.fnServer_CmnConvertFromDbTime(pp.Actual_End_Time,''UTC'')  ' + 
                  ' END, 
   ActualRunningTime = IsNull(pp.Actual_Running_Time,0),
   ActualDownTime = IsNull(pp.Actual_Down_Time,0),
   ActualGoodItems = IsNull(pp.Actual_Good_Items,0),
   ActualGoodQuantity = IsNull(pp.Actual_Good_Quantity,0),
   ActualBadItems = IsNull(pp.Actual_Bad_Items,0),
   ActualBadQuantity = IsNull(pp.Actual_Bad_Quantity,0),
   PredictedRemainingDuration = IsNull(pp.Predicted_Remaining_Duration,0),
   PredictedTotalDuration = IsNull(pp.Predicted_Total_Duration,0),
   PredictedRemainingQuantity = IsNull(pp.Predicted_Remaining_Quantity,0),
   LateItems = IsNull(pp.Late_Items,0),
   AlarmCount = IsNull(pp.Alarm_Count,0),
   Repetitions = IsNull(pp.Actual_Repetitions,0),
   ProductionPathId = IsNull(pp.Path_Id,0),
   ProductionPathCode = IsNull(p.Path_Code,'''')
 FROM Production_Plan pp
 LEFT JOIN PrdExec_Paths p ON pp.path_id = p.path_id
 LEFT JOIN Control_Type ct ON pp.Control_Type = ct.Control_Type_Id '
SET @SelectClauseB = ' SELECT StatsType = 2,
   StatsTypeName = ''Production Setup'',
   ProductionPlanId = ps.PP_Id,
   ProcessOrder = IsNull(pp.Process_Order,''''),
   ProductionSetupId = ps.PP_Setup_Id,
   ControlTypeId  = IsNull(pp.Control_Type,0),
   ControlType = IsNull(ct.Control_Type_Desc,''''),
   ActualStartTime = CASE WHEN ps.Actual_Start_Time IS NULL THEN ' + @MaxTime +
                   ' ELSE dbo.fnServer_CmnConvertFromDbTime(ps.Actual_Start_Time,''UTC'')  ' + 
                   ' END,  
   ActualEndTime = CASE WHEN ps.Actual_End_Time IS NULL THEN ' + @MaxTime +
                 ' ELSE dbo.fnServer_CmnConvertFromDbTime(ps.Actual_End_Time,''UTC'')  ' + 
                 ' END, 
   ActualRunningTime = IsNull(ps.Actual_Running_Time,0),
   ActualDownTime = IsNull(ps.Actual_Down_Time,0),
   ActualGoodItems = IsNull(ps.Actual_Good_Items,0),
   ActualGoodQuantity = IsNull(ps.Actual_Good_Quantity,0),
   ActualBadItems = IsNull(ps.Actual_Bad_Items,0),
   ActualBadQuantity = IsNull(ps.Actual_Bad_Quantity,0),
   PredictedRemainingDuration = IsNull(ps.Predicted_Remaining_Duration,0),
   PredictedTotalDuration  = IsNull(ps.Predicted_Total_Duration,0),
   PredictedRemainingQuantity = IsNull(ps.Predicted_Remaining_Quantity,0),
   LateItems = IsNull(ps.Late_Items,0),
   AlarmCount = IsNull(ps.Alarm_Count,0),
   Repetitions = IsNull(ps.Actual_Repetitions,0),
   ProductionPathId = IsNull(pp.Path_Id,0),
   ProductionPathCode = IsNull(p.Path_Code,'''')
 FROM Production_Setup ps
 JOIN Production_Plan pp ON pp.PP_Id = ps.PP_Id 
 LEFT JOIN PrdExec_Paths p ON pp.path_id = p.path_id
 LEFT JOIN Control_Type ct ON pp.Control_Type = ct.Control_Type_Id '
-- Order clause
SET @OrderClause = ' ORDER BY ActualStartTime ASC '
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE (@SelectClauseA + @WhereClauseA + ' Union ' + @SelectClauseB + @WhereClauseB  + @OrderClause)
