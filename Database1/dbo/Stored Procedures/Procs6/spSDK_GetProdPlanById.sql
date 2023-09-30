CREATE PROCEDURE dbo.spSDK_GetProdPlanById
 	 @PPId 	  	  	  	  	 INT
AS
--ECR 31897 SDK Problem-GetRealtimeRecordById does not return Production Plans that are Unbound
--Return production plan with no path information if Path_Id is null
declare @pathId as int
select @pathId = Path_Id from Production_Plan where PP_Id = @PPId
if @pathId is null
SELECT 	 PPId = pp.PP_Id,
 	  	  	 DepartmentName = null,
      PathCode = null,
 	  	  	 UnitName = null,
 	  	  	 LineName = null, 
 	  	  	 ProcessOrder = pp.Process_Order, 
 	  	  	 BlockNumber = pp.Block_Number, 
 	  	  	 ImpliedSequence = pp.Implied_Sequence, 
 	  	  	 PPStatusDesc = os.pp_status_desc, 
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ForecastStartTime = pp.Forecast_Start_Date, 
 	  	  	 ForecastEndTime = pp.Forecast_End_Date, 
 	  	  	 ForecastQuantity = pp.Forecast_Quantity, 
 	  	  	 ActualStartTime = pp.Actual_Start_Time, 
 	  	  	 ActualEndTime = pp.Actual_End_Time, 
 	  	  	 ActualQuantity = pp.Actual_Good_Quantity,
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
      SourcePathCode = null,
      ParentPathCode = null
 	 FROM Production_Plan pp JOIN 
 	  	  	 Products p ON p.Prod_Id = pp.Prod_Id JOIN
 	  	  	 Production_Plan_Statuses os ON os.PP_Status_Id = pp.PP_Status_Id JOIN
      Production_Plan_Types ppt ON ppt.PP_Type_Id = pp.PP_Type_Id LEFT OUTER JOIN
      Production_Plan pp2 ON pp2.PP_Id = pp.Source_PP_Id LEFT OUTER JOIN
      Control_Type ct ON ct.Control_Type_Id = pp.Control_Type LEFT OUTER JOIN
      Production_Plan pp3 ON pp3.PP_Id = pp.Parent_PP_Id
 	 WHERE 	 pp.PP_Id = @PPId
else
--Return production plan with path information if Path_Id is not null
SELECT 	 PPId = pp.PP_Id,
 	  	  	 DepartmentName = d.Dept_Desc,
      PathCode = pep.Path_Code,
 	  	  	 UnitName = pu.PU_Desc,
 	  	  	 LineName = pl.PL_Desc, 
 	  	  	 ProcessOrder = pp.Process_Order, 
 	  	  	 BlockNumber = pp.Block_Number, 
 	  	  	 ImpliedSequence = pp.Implied_Sequence, 
 	  	  	 PPStatusDesc = os.pp_status_desc, 
 	  	  	 ProductCode = p.Prod_Code, 
 	  	  	 ForecastStartTime = pp.Forecast_Start_Date, 
 	  	  	 ForecastEndTime = pp.Forecast_End_Date, 
 	  	  	 ForecastQuantity = pp.Forecast_Quantity, 
 	  	  	 ActualStartTime = pp.Actual_Start_Time, 
 	  	  	 ActualEndTime = pp.Actual_End_Time, 
 	  	  	 ActualQuantity = pp.Actual_Good_Quantity,
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
      ParentPathCode = pep3.Path_Code
 	 FROM Production_Plan pp JOIN 
 	  	  	 Products p ON p.Prod_Id = pp.Prod_Id JOIN 
      PrdExec_Paths pep ON pep.Path_Id = pp.Path_Id JOIN
      PrdExec_Path_Units pepu ON pepu.Path_Id = pep.Path_Id and pepu.Is_Schedule_Point = 1 JOIN
 	  	  	 Prod_Units pu ON pu.pu_id = pepu.pu_id JOIN 
 	  	  	 Prod_Lines pl ON pl.pl_id = pu.pl_id LEFT JOIN 
     	 Departments d 	 ON d.Dept_Id = pl.Dept_Id JOIN
 	  	  	 Production_Plan_Statuses os ON os.PP_Status_Id = pp.PP_Status_Id JOIN
      Production_Plan_Types ppt ON ppt.PP_Type_Id = pp.PP_Type_Id LEFT OUTER JOIN
      Production_Plan pp2 ON pp2.PP_Id = pp.Source_PP_Id LEFT OUTER JOIN
      Control_Type ct ON ct.Control_Type_Id = pp.Control_Type LEFT OUTER JOIN
      Production_Plan pp3 ON pp3.PP_Id = pp.Parent_PP_Id LEFT OUTER JOIN 
      PrdExec_Paths pep2 ON pep2.Path_Id = pp2.Path_Id LEFT OUTER JOIN 
      PrdExec_Paths pep3 ON pep3.Path_Id = pp3.Path_Id
 	 WHERE 	 pp.PP_Id = @PPId
