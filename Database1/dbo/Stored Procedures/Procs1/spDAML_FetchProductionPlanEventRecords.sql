Create Procedure dbo.spDAML_FetchProductionPlanEventRecords
  @EventId INT = NULL,
  @UnitId  INT = NULL,
  @LineId  INT = NULL,
  @ProdId  INT = NULL,
  @StartTime DATETIME = NULL,
  @EndTime DATETIME = NULL,
  @ProcessOrder VARCHAR(50) = NULL,
  @ProductionPath VARCHAR(50) = NULL,
  @BoundFilter INT = 0,
  @StatusId  INT = NULL,
  @UTCOffset VARCHAR(30) = NULL,
  @UserId  INT = NULL
AS
-- Local variables
DECLARE 
  @SecurityClause VARCHAR(100),
  @IdClause  VARCHAR(50),
  @OptionsClause  VARCHAR(1000),
  @TimeClause  VARCHAR(1000),
  @WhereClause VARCHAR(3000),
  @SelectClause VARCHAR(5000),
  @FromClause VARCHAR(5000),
  @OrderClause VARCHAR(100),
  @BoundClause VARCHAR(500),
  @UnBoundClause VARCHAR(500),
  @MinTime  VARCHAR(25),
  @MaxTime  VARCHAR(25),
  @STime   VARCHAR(100),
  @ETime   VARCHAR(100)
-- The minimum time in SQL 2005
SET @MinTime = '''1/1/1753'''
SET @MaxTime = '''12/31/9999'''
-- The production unit and production line have security levels
SET @SecurityClause = ' WHERE (Coalesce(pus.Access_Level, pls.Access_Level, 3) >= 2) '
-- Only one of the following id values, if any, is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@EventId<>0 AND @EventId IS NOT NULL) THEN ' AND (pp.PP_Id = ' + CONVERT(VARCHAR(10),@EventId) + ') '
   WHEN (@UnitId<>0 AND @UnitId IS NOT NULL) THEN ' AND (pepu.PU_Id = ' + CONVERT(VARCHAR(10),@UnitId) + ') '
   WHEN (@LineId<>0 AND @LineId IS NOT NULL) THEN 'AND (pu.PL_Id = ' + CONVERT(VARCHAR(10),@LineId) + ') '
   WHEN (@ProdId<>0 AND @ProdId IS NOT NULL) THEN 'AND (pp.Prod_Id = ' + CONVERT(VARCHAR(10),@ProdId) + ') '
   ELSE ''
END
IF (@StatusId<>0 AND @StatusId IS NOT NULL)
  SELECT @IdClause = @IdClause + 'AND (pp.PP_Status_Id = ' + CONVERT(VARCHAR(10),@StatusId) + ') '
-- All of the following are optional and some or none can apply
SET @OptionsClause = ''
IF (@ProcessOrder<>'' AND @ProcessOrder IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProcessOrder)=0 AND CHARINDEX('_', @ProcessOrder)=0 )
     SET @OptionsClause = @OptionsClause + ' AND (pp.Process_Order = ''' + CONVERT(VARCHAR(50),@ProcessOrder) + ''') '
   ELSE
     SET @OptionsClause = @OptionsClause + ' AND (pp.Process_Order LIKE ''' + CONVERT(VARCHAR(50),@ProcessOrder) + ''') '
END
-- The bound filter determines whether or not Production Plans that have been bound to
-- a path are displayed
-- When a path has been bound, the query returns information about the bound path
-- When a path has not been bound, the query returns information about all possible paths 
-- that can create the desired product
IF (@BoundFilter IS NULL) SET @BoundFilter = 0     
IF (@ProductionPath<>'' AND @ProductionPath IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @ProductionPath)=0 AND CHARINDEX('_', @ProductionPath)=0 ) BEGIN
      SET @BoundClause = '(pep.Path_Code = ''' + CONVERT(VARCHAR(50),@ProductionPath) + ''') '
      SET @UnBoundClause = '(pp.Path_Id is NULL AND
       pp.Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Prod_Id = pp.Prod_Id 
       and Path_Id In (Select Path_Id From PrdExec_Paths Where Path_Code = ''' + 
       CONVERT(VARCHAR(50),@ProductionPath) + '''))) '
   END
   ELSE BEGIN
      SET @BoundClause = '(pep.Path_Code LIKE ''' + CONVERT(VARCHAR(50),@ProductionPath) + ''') '
      SET @UnBoundClause = '(pp.Path_Id is NULL AND
       pp.Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Prod_Id = pp.Prod_Id 
       and Path_Id In (Select Path_Id From PrdExec_Paths Where Path_Code LIKE ''' + 
       CONVERT(VARCHAR(50),@ProductionPath) + '''))) '
   END
   SET @OptionsClause = @OptionsClause + 
       CASE WHEN @BoundFilter = 0 THEN ' AND (' + @BoundClause + ' OR ' + @UnBoundClause + ') '
            WHEN @BoundFilter = 1 THEN ' AND ' + @BoundClause 
            ELSE ' AND ' + @UnBoundClause
       END
END
ELSE BEGIN
  IF (@BoundFilter = 2)
 SET @OptionsClause = @OptionsClause + ' AND (pp.Path_Id IS NULL) '
  ELSE IF (@BoundFilter = 1)
    SET @OptionsClause = @OptionsClause + ' AND (pp.Path_Id IS NOT NULL) '
END
-- The TimeClause determines the interval of time to return
IF (@StartTime IS NULL) SET @STime = @MinTime ELSE SET @STime = '''' + CONVERT(VARCHAR(100),@StartTime,21) + ''''
IF (@EndTime IS NULL) SET @ETime = @MaxTime ELSE SET @ETime = '''' + CONVERT(VARCHAR(100),@EndTime,21) + ''''
SET @TimeClause = ' AND (COALESCE(pp.Actual_Start_Time, pp.Forecast_Start_Date) < ' + @ETime + ') 
      AND (((pp.Actual_Start_Time is not null) AND ((pp.Actual_End_Time > ' +  @STime + ') OR (pp.Actual_End_Time is null)))
        OR ((pp.Actual_Start_Time is null) AND ((pp.Forecast_End_Date > ' +  @STime + ') OR (pp.Forecast_End_Date is null)))) '
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
--   All DATES are converted to UTC
SET @SelectClause =
'SELECT DISTINCT ProductionPlanId = pp.PP_Id,
   ProcessOrder = IsNull(pp.Process_Order,''''),
   ForecastStartTime = CASE WHEN pp.Forecast_Start_Date IS NULL THEN ' + @MaxTime +
                     ' ELSE dbo.fnServer_CmnConvertFromDbTime(pp.Forecast_Start_Date,''UTC'')  ' +
                     ' END, 
   ForecastEndTime = CASE WHEN pp.Forecast_End_Date IS NULL THEN ' + @MaxTime +
                   ' ELSE dbo.fnServer_CmnConvertFromDbTime(pp.Forecast_End_Date,''UTC'')  ' + 
                   ' END,
   ForecastQuantity = IsNull(pp.Forecast_Quantity,0),
   ActualStartTime = CASE WHEN pp.Actual_Start_Time IS NULL THEN ' + @MaxTime +
                   ' ELSE dbo.fnServer_CmnConvertFromDbTime(pp.Actual_Start_Time,''UTC'')  ' + 
                   ' END,
   ActualEndTime = CASE WHEN pp.Actual_End_Time IS NULL THEN ' + @MaxTime +
                 ' ELSE dbo.fnServer_CmnConvertFromDbTime(pp.Actual_End_Time,''UTC'')  ' + 
                 ' END,
   ActualQuantity = IsNull(pp.Actual_Good_Quantity,0),
   MostRecentStartId = IsNull(pps.PP_Start_Id,0),
   MostRecentStartTime = CASE WHEN pps.Start_Time IS NULL THEN ' + @MaxTime +
                       ' ELSE dbo.fnServer_CmnConvertFromDbTime(pps.Start_Time,''UTC'')  ' + 
                       ' END,
   DepartmentId = IsNull(d.Dept_Id,0),
   Department = IsNull(d.Dept_Desc, ''''),
   ProductionLineId = IsNull(pl.PL_Id,0),
   ProductionLine = IsNull(pl.PL_Desc, ''''),
   ProductionUnitId = IsNull(pu.PU_Id,0),
   ProductionUnit = IsNull(pu.PU_Desc,''''),
   PathId = IsNull(pep.Path_Id,0),
   PathCode = IsNull(pep.Path_Code,''''),
   BlockNumber = IsNull(pp.Block_Number,''''), 
   ImpliedSequence = IsNull(pp.Implied_Sequence,0),
   ProductionPlanStatusId = IsNull(ppst.PP_Status_Id,0),
   ProductionPlanStatus = IsNull(ppst.PP_Status_Desc,0),
   ProductId = p.Prod_Id,
   ProductCode = p.Prod_Code, 
   CommentId = IsNull(pp.Comment_Id, 0),
   ExtendedInfo = IsNull(pp.Extended_Info,''''),
   UserGeneral1 = IsNUll(pp.User_General_1,''''),
   UserGeneral2 = IsNull(pp.User_General_2,''''),
   UserGeneral3 = IsNUll(pp.User_General_3,''''),
   ProductionRate = IsNull(pp.Production_Rate,0),
   ProductionPlanTypeId = IsNull(pp.PP_Type_Id,0),
   ProductionPlanType = IsNull(ppt.PP_Type_Name,''''),
   ControlTypeId = IsNull(pp.Control_Type,0),
   ControlType = IsNull(ct.Control_Type_Desc,''''),
   AdjustedQuantity = IsNull(pp.Adjusted_Quantity,0),
   ParentProductionPlanId = IsNull(pp.Parent_PP_id,0),
   ParentProcessOrder = IsNull(pp3.Process_Order,''''),
   ParentPathId = IsNull(pep3.Path_Id,0),
   ParentPathCode = IsNull(pep3.Path_Code,''''),
   SourceProductionPlanId = IsNull(pp.Source_PP_id,0),
   SourceProcessOrder = IsNull(pp2.Process_Order,''''),
   SourcePathId = IsNull(pep2.Path_Id,0),
   SourcePathCode = IsNull(pep2.Path_Code,''''),
   PredictedRemainingQuantity = IsNull(pp.Predicted_Remaining_Quantity,0),
   ActualBadQuantity = IsNull(pp.Actual_Bad_Quantity,0),
   PredictedTotalDuration = IsNull(pp.Predicted_Total_Duration,0),
   PredictedRemainingDuration = IsNull(pp.Predicted_Remaining_Duration,0),
   ActualRunningTime = IsNull(pp.Actual_Running_Time,0),
   ActualDownTime = IsNull(pp.Actual_Down_Time,0),
   ActualGoodItems = IsNull(pp.Actual_Good_Items,0),
   ActualBadItems = IsNull(pp.Actual_Bad_Items,0),
   AlarmCount = IsNull(pp.Alarm_Count,0),
   LateItems = IsNull(pp.Late_Items,0),
   ActualRepetitions = IsNull(pp.Actual_Repetitions,0) '
SET @FromClause = ' FROM Production_Plan pp
   JOIN PrdExec_Paths pep ON pep.Path_Id = pp.Path_Id
   JOIN  PrdExec_Path_Units pepu ON pepu.Path_Id = pp.Path_Id and pepu.Is_Schedule_Point = 1
   JOIN  Prod_Units pu ON pu.PU_Id = pepu.PU_Id 
   JOIN  Prod_Lines pl ON pl.PL_Id = pu.PL_Id
   JOIN  Departments d ON d.Dept_Id = pl.Dept_Id
   JOIN  Products p ON pp.Prod_Id = p.Prod_Id 
   LEFT JOIN  Production_Plan_Statuses ppst ON pp.PP_Status_Id = ppst.PP_Status_Id
   LEFT JOIN  Production_Plan_Starts pps  ON pp.PP_Id = pps.PP_Id and pps.PP_Start_Id = (Select Max(PP_Start_Id) From Production_Plan_Starts Where PP_Id = pp.PP_Id)
   LEFT JOIN  Events e ON pepu.PU_Id = e.PU_Id AND e.Timestamp BETWEEN pps.Start_Time AND pps.End_Time
   LEFT JOIN  Variables v ON pu.Production_Variable = v.Var_Id AND v.Data_Type_Id IN (1,2)
   JOIN Production_Plan_Types ppt ON ppt.PP_Type_Id = pp.PP_Type_Id
   LEFT OUTER JOIN Production_Plan pp2 ON pp2.PP_Id = pp.Source_PP_Id
   LEFT OUTER JOIN Control_Type ct ON ct.Control_Type_Id = pp.Control_Type
   LEFT OUTER JOIN Production_Plan pp3 ON pp3.PP_Id = pp.Parent_PP_Id
   LEFT JOIN  User_Security pls  ON pl.Group_Id = pls.Group_Id AND pls.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
   LEFT JOIN  User_Security pus  ON pu.Group_Id = pus.Group_Id AND pus.User_Id = ' + CONVERT(VARCHAR(10),@UserId) + '
   LEFT OUTER JOIN PrdExec_Paths pep2 ON pep2.Path_Id = pp2.Path_Id
   LEFT OUTER JOIN PrdExec_Paths pep3 ON pep3.Path_Id = pp3.Path_Id '
-- order clause
SET @OrderClause = ' ORDER BY COALESCE(ForecastStartTime, ActualStartTime, MostRecentStartTime) '
--SELECT sc=@SelectClause, wc=@WhereClause, oc=@OrderClause -- For debugging
EXECUTE ('Select * from (' + @SelectClause + @FromClause + @WhereClause + ') data ' + @OrderClause )
