CREATE PROCEDURE dbo.spSDK_QueryProductionPlans
 	 @PathMask nvarchar(50) 	  	 = NULL,
 	 @PPMask 	  nvarchar(50) 	  	 = NULL,
 	 @StartTime DATETIME 	  	  	 = NULL,
 	 @EndTime DATETIME 	  	  	 = NULL,
 	 @BoundFilter INT 	  	  	  	 = NULL,
 	 @UserId 	  INT 	  	  	  	 = NULL
AS
--sdkPPBFAll = 0
--sdkPPBFBound = 1
--sdkPPBFUnbound = 2
SELECT @PPMask = ISNULL(@PPMask,'*')
SELECT @PathMask = ISNULL(@PathMask,'*')
IF @BoundFilter is NULL
 	 Select @BoundFilter = 0
IF @EndTime IS NULL
BEGIN
 	 IF @StartTime IS NULL
 	 BEGIN
 	  	 SELECT 	 @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @EndTime = DATEADD(DAY, 1, @StartTime)
 	 END
END
IF @StartTime IS NULL
BEGIN
 	 SELECT 	 @StartTime = DATEADD(DAY, -1, @EndTime)
END
IF 	 @PathMask IS NOT NULL
BEGIN
 	 SELECT 	 @PathMask = 	 REPLACE(COALESCE(@PathMask, '*'), '*', '%')
 	 SELECT 	 @PathMask = 	 REPLACE(REPLACE(@PathMask, '?', '_'), '[', '[[]')
END
IF @PPMask IS NOT NULL
BEGIN
 	 SELECT 	 @PPMask = 	 REPLACE(COALESCE(@PPMask, '*'), '*', '%')
 	 SELECT 	 @PPMask = 	 REPLACE(REPLACE(@PPMask, '?', '_'), '[', '[[]')
END
--select @StartTime,@EndTime,@PathMask,@PPMask
--Create Table #ProductionPlans 
DECLARE @ProductionPlans Table 
(PPId int, DepartmentName nvarchar(50), PathCode nvarchar(50), LineName nvarchar(50), UnitName nvarchar(50), ProcessOrder nvarchar(50), 
 	  	  	  	 BlockNumber nvarchar(50), ImpliedSequence int, PPStatusDesc nvarchar(50), ProductCode nvarchar(25), ForecastStartTime datetime, 
 	  	  	  	 ForecastEndTime datetime, ForecastQuantity float, ActualStartTime datetime, ActualEndTime datetime, ActualQuantity float, CommentId int, 
 	  	  	  	 ExtendedInfo nvarchar(255), UserGeneral1 nvarchar(255), UserGeneral2 nvarchar(255), UserGeneral3 nvarchar(255), ProductionRate float, 
 	       PPTypeName nvarchar(25), SourceProcessOrder nvarchar(50), ControlTypeDesc nvarchar(25), AdjustedQuantity float, ParentProcessOrder nvarchar(50), 
 	       PredictedRemainingQuantity float, ActualBadQuantity float, PredictedTotalDuration float, PredictedRemainingDuration float, 
 	       ActualRunningTime float, ActualDownTime float, ActualGoodItems int, ActualBadItems int, AlarmCount int, LateItems int, ActualRepetitions int, 
 	       SourcePathCode nvarchar(50), ParentPathCode nvarchar(50), ProductionPlanStartDate datetime)
if @BoundFilter = 0 or @BoundFilter = 1
 	 BEGIN
 	  	 Insert Into @ProductionPlans
 	  	  	 (PPId, DepartmentName, PathCode, LineName, UnitName, ProcessOrder, 
 	  	  	 BlockNumber, ImpliedSequence, PPStatusDesc, ProductCode, ForecastStartTime, 
 	  	  	 ForecastEndTime, ForecastQuantity, ActualStartTime, ActualEndTime, ActualQuantity, CommentId, 
 	  	  	 ExtendedInfo, UserGeneral1, UserGeneral2, UserGeneral3, ProductionRate, 
 	     PPTypeName, SourceProcessOrder, ControlTypeDesc, AdjustedQuantity, ParentProcessOrder, 
 	     PredictedRemainingQuantity, ActualBadQuantity, PredictedTotalDuration, PredictedRemainingDuration, 
 	     ActualRunningTime, ActualDownTime, ActualGoodItems, ActualBadItems, AlarmCount, LateItems, ActualRepetitions, 
 	     SourcePathCode, ParentPathCode, ProductionPlanStartDate)
 	  	  	 SELECT PPId = pp.PP_Id, 
 	  	  	  	  	  	 DepartmentName = d.Dept_Desc, 
 	  	  	       PathCode = pep.Path_Code,
 	  	  	  	  	  	 LineName = pl.PL_Desc, 
 	  	  	  	  	  	 UnitName = pu.PU_Desc, 
 	  	  	  	  	  	 ProcessOrder = pp.Process_Order, 
 	  	  	  	  	  	 BlockNumber = pp.Block_Number, 
 	  	  	  	  	  	 ImpliedSequence = pp.Implied_Sequence, 
 	  	  	  	  	  	 PPStatusDesc = ppst.PP_Status_Desc, 
 	  	  	  	  	  	 ProductCode = p.Prod_Code, 
 	  	  	  	  	  	 ForecastStartTime = pp.Forecast_Start_Date, 
 	  	  	  	  	  	 ForecastEndTime = pp.Forecast_End_Date, 
 	  	  	  	  	  	 ForecastQuantity = pp.Forecast_Quantity, 
 	  	  	  	  	  	 ActualStartTime = pp.Actual_Start_Time, 
 	  	  	  	  	  	 ActualEndTime = pp.Actual_End_Time, 
 	  	  	  	  	  	 ActualQuantity = 	 pp.Actual_Good_Quantity,
 	  	  	  	  	  	 CommentId = pp.Comment_Id, 
 	  	  	  	  	  	 ExtendedInfo = pp.Extended_Info,
 	  	  	  	  	  	 UserGeneral1 = pp.User_General_1,
 	  	  	  	  	  	 UserGeneral2 = pp.User_General_2,
 	  	  	  	  	  	 UserGeneral3 = pp.User_General_3,
 	  	  	       ProductionRate = pp.Production_Rate,
 	  	  	       PPTypeName = ppt.PP_Type_Name,
 	  	  	       SourceProcessOrder = pp2.Process_Order,
 	  	  	       ControlTypeDesc = ct.Control_Type_Desc,
 	  	  	       AdjustedQuantity = pp.Adjusted_Quantity,
 	  	  	       ParentProcessOrder = pp3.Process_Order,
 	  	  	       PredictedRemainingQuantity = pp.Predicted_Remaining_Quantity,
 	  	  	       ActualBadQuantity = pp.Actual_Bad_Quantity,
 	  	  	       PredictedTotalDuration = pp.Predicted_Total_Duration,
 	  	  	       PredictedRemainingDuration = pp.Predicted_Remaining_Duration,
 	  	  	       ActualRunningTime = pp.Actual_Running_Time,
 	  	  	       ActualDownTime = pp.Actual_Down_Time,
 	  	  	       ActualGoodItems = pp.Actual_Good_Items,
 	  	  	       ActualBadItems = pp.Actual_Bad_Items,
 	  	  	       AlarmCount = pp.Alarm_Count,
 	  	  	       LateItems = pp.Late_Items,
 	  	  	       ActualRepetitions = pp.Actual_Repetitions,
 	  	  	       SourcePathCode = pep2.Path_Code,
 	  	  	       ParentPathCode = pep3.Path_Code,
 	  	  	  	  	  	 ProductionPlanStartDate = pps.Start_Time
 	  	  	  	 FROM 	  	  	 PrdExec_Paths pep
 	  	  	  	 LEFT JOIN 	  	  	 PrdExec_Path_Units pepu       ON pepu.Path_Id = pep.Path_Id and pepu.Is_Schedule_Point = 1
 	  	  	  	 LEFT JOIN 	  	  	 Prod_Units pu 	  	  	  	  	  	       ON pu.PU_Id = pepu.PU_Id
 	  	  	  	 LEFT JOIN 	  	  	 Prod_Lines pl 	  	  	  	  	  	       ON pl.PL_Id = pu.PL_Id
 	  	  	  	 LEFT JOIN 	  	  	 Departments d 	  	  	  	  	  	       ON d.Dept_Id = pl.Dept_Id
 	  	  	  	 JOIN 	  	  	 Production_Plan pp 	  	  	       ON pp.Path_Id = pepu.Path_Id
 	  	  	  	 LEFT JOIN 	  	  	 Products p 	  	  	  	  	  	  	       ON pp.Prod_Id = p.Prod_Id 
 	  	  	  	 LEFT JOIN 	 Production_Plan_Statuses ppst 	 ON pp.PP_Status_Id = ppst.PP_Status_Id
 	  	  	  	 LEFT JOIN 	 Production_Plan_Starts pps 	  	 ON pp.PP_Id = pps.PP_Id and pps.Start_Time = (Select Max(Start_Time) From Production_Plan_Starts Where PP_Id = pp.PP_Id)
 	  	  	  	 LEFT JOIN 	 Events e 	  	  	  	  	  	  	  	       ON pepu.PU_Id = e.PU_Id AND 	 e.Timestamp BETWEEN pps.Start_Time AND pps.End_Time
 	  	  	  	 LEFT JOIN 	 Variables v 	  	  	  	  	  	  	       ON pu.Production_Variable = v.Var_Id AND 	 v.Data_Type_Id IN (1,2)
 	  	  	   JOIN      Production_Plan_Types ppt     ON ppt.PP_Type_Id = pp.PP_Type_Id
 	  	  	   LEFT OUTER JOIN Production_Plan pp2     ON pp2.PP_Id = pp.Source_PP_Id
 	  	  	   LEFT OUTER JOIN Control_Type ct         ON ct.Control_Type_Id = pp.Control_Type
 	  	  	   LEFT OUTER JOIN Production_Plan pp3     ON pp3.PP_Id = pp.Parent_PP_Id
 	  	  	  	 LEFT JOIN 	 User_Security pls 	  	  	  	       ON pl.Group_Id = pls.Group_Id AND pls.User_Id = @UserId
 	  	  	  	 LEFT JOIN 	 User_Security pus 	  	  	  	       ON pu.Group_Id = pus.Group_Id AND pus.User_Id = @UserId
 	  	  	   LEFT OUTER JOIN PrdExec_Paths pep2      ON pep2.Path_Id = pp2.Path_Id
 	  	  	   LEFT OUTER JOIN PrdExec_Paths pep3      ON pep3.Path_Id = pp3.Path_Id
 	  	  	  	 WHERE pep.Path_Code LIKE @PathMask AND
 	  	  	       (COALESCE(pps.Start_Time, pp.Forecast_Start_Date) BETWEEN @StartTime AND @EndTime
 	  	  	  	  	  	 OR 	 (pps.Start_Time IS NOT NULL AND COALESCE(pps.End_Time, dbo.fnServer_CmnGetDate(getUTCdate())) BETWEEN @StartTime AND @EndTime)
 	  	  	  	  	  	 OR 	 (pps.Start_Time IS NULL AND pp.Forecast_End_Date BETWEEN @StartTime and @EndTime)) 	 
 	  	  	  	 AND   pp.Process_Order LIKE @PPMask 
 	  	  	  	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
--  	  	  	  	 GROUP BY pp.PP_Id, d.Dept_Desc, pep.Path_Code, pl.PL_Desc, pu.PU_Desc, pp.Process_Order, pp.Block_Number, 
--  	  	  	  	  	  	  	 pp.Implied_Sequence, ppst.pp_status_desc, p.Prod_Code, pp.Forecast_Start_Date, pp.Forecast_End_Date, 
--  	  	  	  	  	  	  	 pp.Forecast_Quantity, pp.Actual_Start_Time, pp.Actual_End_Time, pp.Actual_Good_Quantity, pp.Comment_Id, 
--  	  	  	         pp.Extended_Info, pu.Production_Type, pp.User_General_1, pp.User_General_2, pp.User_General_3, 
--  	  	  	         pp.Production_Rate, ppt.PP_Type_Name, pp2.Process_Order,ct.Control_Type_Desc, pp.Adjusted_Quantity, 
--  	  	  	         pp3.Process_Order, pp.Predicted_Remaining_Quantity, pp.Actual_Bad_Quantity, pp.Predicted_Total_Duration, 
--  	  	  	         pp.Predicted_Remaining_Duration, pp.Actual_Running_Time, pp.Actual_Down_Time, pp.Actual_Good_Items, 
--  	  	  	         pp.Actual_Bad_Items, pp.Alarm_Count, pp.Late_Items, pp.Actual_Repetitions, pep2.Path_Code, pep3.Path_Code, pps.Start_Time
--  	  	  	  	 ORDER BY COALESCE(MIN(pps.Start_Time), pp.Forecast_Start_Date)
 	 End
if @BoundFilter = 0 or @BoundFilter = 2
 	 Begin
 	  	 Insert Into @ProductionPlans
 	  	  	 (PPId, DepartmentName, PathCode, LineName, UnitName, ProcessOrder, 
 	  	  	 BlockNumber, ImpliedSequence, PPStatusDesc, ProductCode, ForecastStartTime, 
 	  	  	 ForecastEndTime, ForecastQuantity, ActualStartTime, ActualEndTime, ActualQuantity, CommentId, 
 	  	  	 ExtendedInfo, UserGeneral1, UserGeneral2, UserGeneral3, ProductionRate, 
 	     PPTypeName, SourceProcessOrder, ControlTypeDesc, AdjustedQuantity, ParentProcessOrder, 
 	     PredictedRemainingQuantity, ActualBadQuantity, PredictedTotalDuration, PredictedRemainingDuration, 
 	     ActualRunningTime, ActualDownTime, ActualGoodItems, ActualBadItems, AlarmCount, LateItems, ActualRepetitions, 
 	     SourcePathCode, ParentPathCode, ProductionPlanStartDate)
 	  	  	 SELECT PPId = pp.PP_Id, 
 	  	  	  	  	  	 DepartmentName = d.Dept_Desc, 
 	  	  	       PathCode = pep.Path_Code,
 	  	  	  	  	  	 LineName = pl.PL_Desc, 
 	  	  	  	  	  	 UnitName = pu.PU_Desc, 
 	  	  	  	  	  	 ProcessOrder = pp.Process_Order, 
 	  	  	  	  	  	 BlockNumber = pp.Block_Number, 
 	  	  	  	  	  	 ImpliedSequence = pp.Implied_Sequence, 
 	  	  	  	  	  	 PPStatusDesc = ppst.PP_Status_Desc, 
 	  	  	  	  	  	 ProductCode = p.Prod_Code, 
 	  	  	  	  	  	 ForecastStartTime = pp.Forecast_Start_Date, 
 	  	  	  	  	  	 ForecastEndTime = pp.Forecast_End_Date, 
 	  	  	  	  	  	 ForecastQuantity = pp.Forecast_Quantity, 
 	  	  	  	  	  	 ActualStartTime = pp.Actual_Start_Time, 
 	  	  	  	  	  	 ActualEndTime = pp.Actual_End_Time, 
 	  	  	  	  	  	 ActualQuantity = 	 pp.Actual_Good_Quantity,
 	  	  	  	  	  	 CommentId = pp.Comment_Id, 
 	  	  	  	  	  	 ExtendedInfo = pp.Extended_Info,
 	  	  	  	  	  	 UserGeneral1 = pp.User_General_1,
 	  	  	  	  	  	 UserGeneral2 = pp.User_General_2,
 	  	  	  	  	  	 UserGeneral3 = pp.User_General_3,
 	  	  	       ProductionRate = pp.Production_Rate,
 	  	  	       PPTypeName = ppt.PP_Type_Name,
 	  	  	       SourceProcessOrder = pp2.Process_Order,
 	  	  	       ControlTypeDesc = ct.Control_Type_Desc,
 	  	  	       AdjustedQuantity = pp.Adjusted_Quantity,
 	  	  	       ParentProcessOrder = pp3.Process_Order,
 	  	  	       PredictedRemainingQuantity = pp.Predicted_Remaining_Quantity,
 	  	  	       ActualBadQuantity = pp.Actual_Bad_Quantity,
 	  	  	       PredictedTotalDuration = pp.Predicted_Total_Duration,
 	  	  	       PredictedRemainingDuration = pp.Predicted_Remaining_Duration,
 	  	  	       ActualRunningTime = pp.Actual_Running_Time,
 	  	  	       ActualDownTime = pp.Actual_Down_Time,
 	  	  	       ActualGoodItems = pp.Actual_Good_Items,
 	  	  	       ActualBadItems = pp.Actual_Bad_Items,
 	  	  	       AlarmCount = pp.Alarm_Count,
 	  	  	       LateItems = pp.Late_Items,
 	  	  	       ActualRepetitions = pp.Actual_Repetitions,
 	  	  	       SourcePathCode = pep2.Path_Code,
 	  	  	       ParentPathCode = pep3.Path_Code,
 	  	  	  	  	  	 ProductionPlanStartDate = pps.Start_Time
 	  	  	  	 FROM 	  	  	 Production_Plan pp
 	  	  	  	 LEFT OUTER JOIN PrdExec_Paths pep 	  	  	  	 ON pep.Path_Id = pp.Path_Id
 	  	  	  	 LEFT OUTER JOIN 	  	  	 PrdExec_Path_Units pepu       ON pepu.Path_Id = pp.Path_Id
 	  	  	  	 LEFT OUTER JOIN 	  	  	 Prod_Units pu 	  	  	  	  	  	       ON pu.PU_Id = pepu.PU_Id
 	  	  	  	 LEFT OUTER JOIN 	  	  	 Prod_Lines pl 	  	  	  	  	  	       ON pl.PL_Id = pu.PL_Id
 	  	  	  	 LEFT OUTER JOIN 	  	  	 Departments d 	  	  	  	  	  	       ON d.Dept_Id = pl.Dept_Id
 	  	  	  	 LEFT JOIN 	  	  	 Products p 	  	  	  	  	  	  	       ON pp.Prod_Id = p.Prod_Id 
 	  	  	  	 LEFT JOIN 	 Production_Plan_Statuses ppst 	 ON pp.PP_Status_Id = ppst.PP_Status_Id
 	  	  	  	 LEFT JOIN 	 Production_Plan_Starts pps 	  	 ON pp.PP_Id = pps.PP_Id and pps.Start_Time = (Select Max(Start_Time) From Production_Plan_Starts Where PP_Id = pp.PP_Id)
 	  	  	  	 LEFT JOIN 	 Events e 	  	  	  	  	  	  	  	       ON pepu.PU_Id = e.PU_Id AND 	 e.Timestamp BETWEEN pps.Start_Time AND pps.End_Time
 	  	  	  	 LEFT JOIN 	 Variables v 	  	  	  	  	  	  	       ON pu.Production_Variable = v.Var_Id AND 	 v.Data_Type_Id IN (1,2)
 	  	  	   JOIN      Production_Plan_Types ppt     ON ppt.PP_Type_Id = pp.PP_Type_Id
 	  	  	   LEFT OUTER JOIN Production_Plan pp2     ON pp2.PP_Id = pp.Source_PP_Id
 	  	  	   LEFT OUTER JOIN Control_Type ct         ON ct.Control_Type_Id = pp.Control_Type
 	  	  	   LEFT OUTER JOIN Production_Plan pp3     ON pp3.PP_Id = pp.Parent_PP_Id
 	  	  	  	 LEFT JOIN 	 User_Security pls 	  	  	  	       ON pl.Group_Id = pls.Group_Id AND pls.User_Id = @UserId
 	  	  	  	 LEFT JOIN 	 User_Security pus 	  	  	  	       ON pu.Group_Id = pus.Group_Id AND pus.User_Id = @UserId
 	  	  	   LEFT OUTER JOIN PrdExec_Paths pep2      ON pep2.Path_Id = pp2.Path_Id
 	  	  	   LEFT OUTER JOIN PrdExec_Paths pep3      ON pep3.Path_Id = pp3.Path_Id
 	  	  	  	 WHERE pp.Path_Id is NULL AND
 	  	  	   pp.Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Prod_Id = pp.Prod_Id and Path_Id In (Select Path_Id From PrdExec_Paths Where Path_Code LIKE @PathMask)) AND
 	  	  	       (COALESCE(pps.Start_Time, pp.Forecast_Start_Date) BETWEEN @StartTime AND @EndTime
 	  	  	  	  	  	 OR 	 (pps.Start_Time IS NOT NULL AND COALESCE(pps.End_Time, dbo.fnServer_CmnGetDate(getUTCdate())) BETWEEN @StartTime AND @EndTime)
 	  	  	  	  	  	 OR 	 (pps.Start_Time IS NULL AND pp.Forecast_End_Date BETWEEN @StartTime and @EndTime)) 	 
 	  	  	  	 AND   pp.Process_Order LIKE @PPMask 
 	  	  	  	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
--  	  	  	  	 GROUP BY pp.PP_Id, d.Dept_Desc, pep.Path_Code, pl.PL_Desc, pu.PU_Desc, pp.Process_Order, pp.Block_Number, 
--  	  	  	  	  	  	  	 pp.Implied_Sequence, ppst.pp_status_desc, p.Prod_Code, pp.Forecast_Start_Date, pp.Forecast_End_Date, 
--  	  	  	  	  	  	  	 pp.Forecast_Quantity, pp.Actual_Start_Time, pp.Actual_End_Time, pp.Actual_Good_Quantity, pp.Comment_Id, 
--  	  	  	         pp.Extended_Info, pu.Production_Type, pp.User_General_1, pp.User_General_2, pp.User_General_3, 
--  	  	  	         pp.Production_Rate, ppt.PP_Type_Name, pp2.Process_Order,ct.Control_Type_Desc, pp.Adjusted_Quantity, 
--  	  	  	         pp3.Process_Order, pp.Predicted_Remaining_Quantity, pp.Actual_Bad_Quantity, pp.Predicted_Total_Duration, 
--  	  	  	         pp.Predicted_Remaining_Duration, pp.Actual_Running_Time, pp.Actual_Down_Time, pp.Actual_Good_Items, 
--  	  	  	         pp.Actual_Bad_Items, pp.Alarm_Count, pp.Late_Items, pp.Actual_Repetitions, pep2.Path_Code, pep3.Path_Code, pps.Start_Time
--  	  	  	  	 ORDER BY COALESCE(MIN(pps.Start_Time), pp.Forecast_Start_Date)
 	 End
SELECT * FROM @ProductionPlans
GROUP BY PPId, DepartmentName, PathCode, LineName, UnitName, ProcessOrder, 
BlockNumber, ImpliedSequence, PPStatusDesc, ProductCode, ForecastStartTime, 
ForecastEndTime, ForecastQuantity, ActualStartTime, ActualEndTime, ActualQuantity, CommentId, 
ExtendedInfo, UserGeneral1, UserGeneral2, UserGeneral3, ProductionRate, 
PPTypeName, SourceProcessOrder, ControlTypeDesc, AdjustedQuantity, ParentProcessOrder, 
PredictedRemainingQuantity, ActualBadQuantity, PredictedTotalDuration, PredictedRemainingDuration, 
ActualRunningTime, ActualDownTime, ActualGoodItems, ActualBadItems, AlarmCount, LateItems, ActualRepetitions, 
SourcePathCode, ParentPathCode, ProductionPlanStartDate
ORDER BY COALESCE(MIN(ProductionPlanStartDate), ForecastStartTime)
--drop table #ProductionPlans
