CREATE PROCEDURE dbo.spSDK_QueryActiveProductionPlans
 	 @PathMask 	  	 nvarchar(50) = NULL,
 	 @LineMask 	  	 nvarchar(50) = NULL,
 	 @UnitMask 	  	 nvarchar(50) = NULL,
 	 @Timestamp 	  	 DATETIME 	  	 = NULL,
 	 @UserId 	  	  	 INT 	  	  	 = NULL
AS
IF @PathMask IS NOT NULL
BEGIN
 	 SELECT 	 @PathMask = REPLACE(COALESCE(@PathMask, '*'), '*', '%')
 	 SELECT 	 @PathMask = REPLACE(REPLACE(@PathMask, '?', '_'), '[', '[[]')
END
IF 	 @LineMask IS NOT NULL
BEGIN
 	 SELECT 	 @LineMask = REPLACE(COALESCE(@LineMask, '*'), '*', '%')
 	 SELECT 	 @LineMask = REPLACE(REPLACE(@LineMask, '?', '_'), '[', '[[]')
END
IF 	 @UnitMask IS NOT NULL
BEGIN
 	 SELECT 	 @UnitMask = REPLACE(COALESCE(@UnitMask, '*'), '*', '%')
 	 SELECT 	 @UnitMask = REPLACE(REPLACE(@UnitMask, '?', '_'), '[', '[[]')
END
IF @Timestamp IS NULL
BEGIN
 	 SELECT 	 @Timestamp = DATEADD(DAY, 1, dbo.fnServer_CmnGetDate(getUTCdate()))
END
SELECT 	 PPId = pp.PP_Id,
 	  	  	 DepartmentName = d.Dept_Desc,
 	  	  	 PathCode = pep.Path_Code,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 UnitName = pu.PU_Desc, 
 	  	  	 ProcessOrder = pp.Process_Order, 
 	  	  	 BlockNumber = pp.Block_Number, 
 	  	  	 ImpliedSequence = pp.Implied_Sequence, 
 	  	  	 PPStatusDesc = os.PP_Status_Desc, 
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ForecastStartTime = pp.Forecast_Start_Date, 
 	  	  	 ForecastEndTime = pp.Forecast_End_Date, 
 	  	  	 ForecastQuantity = pp.Forecast_Quantity, 
 	  	  	 ActualStartTime = pp.Actual_Start_Time, 
 	  	  	 ActualEndTime = pp.Actual_End_Time,
 	  	  	 CommentId = pp.Comment_Id,
 	  	  	 ActualQuantity = pp.Actual_Good_Quantity,
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
 	  	  	 ParentPathCode = pep3.Path_Code
 	 FROM 	  	  	 PrdExec_Paths pep
 	 LEFT JOIN 	 PrdExec_Path_Units pepu       ON 	  	 pepu.Path_Id = pep.Path_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pepu.Is_Schedule_Point = 1
 	 LEFT JOIN 	 Prod_Units pu 	  	  	  	  	  	 ON 	  	 pu.PU_Id = pepu.PU_Id
 	 LEFT JOIN 	 Prod_Lines pl 	  	  	  	  	  	 ON 	  	 pl.PL_Id = pu.PL_Id
 	 LEFT JOIN 	 Departments d 	  	  	  	  	  	 ON 	  	 d.Dept_Id = pl.Dept_Id
 	 LEFT JOIN 	 Production_Plan_Starts pps 	  	 ON 	  	 pu.PU_Id = pps.PU_Id
 	 JOIN Production_Plan pp 	  	  	  	 ON 	  	 pps.PP_Id = pp.PP_Id
                        and pp.Path_Id 	 = pep.Path_Id
 	 LEFT JOIN 	 Production_Plan_Statuses os 	 ON 	  	 pp.PP_Status_Id = os.PP_Status_Id
 	 JOIN Products p  	  	  	  	  	  	  	 ON  	 p.Prod_Id = pp.Prod_Id
 	 JOIN Production_Plan_Types ppt 	  	 ON  	 ppt.PP_Type_Id = pp.PP_Type_Id
 	 LEFT OUTER JOIN 	 Production_Plan pp2 	  	  	  	 ON  	 pp2.PP_Id = pp.Source_PP_Id
 	 LEFT OUTER JOIN 	 Control_Type ct 	  	  	  	  	 ON  	 ct.Control_Type_Id = pp.Control_Type
 	 LEFT OUTER JOIN 	 Production_Plan pp3 	  	  	  	 ON  	 pp3.PP_Id = pp.Parent_PP_Id
 	 LEFT JOIN 	 User_Security pls 	  	  	  	  	 ON  	 pl.Group_Id = pls.Group_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pls.User_Id = @UserId
 	 LEFT JOIN 	 User_Security pus 	  	  	  	  	 ON  	 pu.Group_Id = pus.Group_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND 	 pus.User_Id = @UserId
 	 LEFT OUTER JOIN 	 PrdExec_Paths pep2       	  	 ON 	  	 pep2.Path_Id = pp2.Path_Id
 	 LEFT OUTER JOIN 	 PrdExec_Paths pep3       	  	 ON 	  	 pep3.Path_Id = pp3.Path_Id
 	 WHERE 	 (pep.Path_Code 	 LIKE @PathMask 	 
 	  	 OR 	  	 (pl.PL_Desc 	 LIKE @LineMask 
 	  	 AND 	 pu.PU_Desc 	 LIKE @UnitMask))
 	 AND 	 pps.Start_Time <= @Timestamp
 	 AND 	 (pps.End_Time > @Timestamp 
 	  	 OR 	 pps.End_Time IS NULL)
 	 AND 	 COALESCE(pus.Access_Level, COALESCE(pls.Access_Level, 3)) >= 2
 	 ORDER BY pl.PL_Desc, pu.PU_Order
RETURN(0)
