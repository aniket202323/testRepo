CREATE PROCEDURE dbo.spSDK_GetProdSetupById
 	 @PPSetupId 	  	  	  	  	 INT
AS
SELECT PPSetupId = ps.PP_Setup_Id,
      PathCode = pep.Path_Code,
 	  	  	 ProcessOrder = pp.Process_Order, 
 	  	  	 ForecastQuantity = ps.Forecast_Quantity, 
 	  	  	 ImpliedSequence = ps.Implied_Sequence, 
 	  	  	 PPStatusDesc = pps.pp_status_desc, 
 	  	  	 Repetitions = ps.Pattern_Repititions, 
 	  	  	 Shrinkage = ps.Shrinkage, 
 	  	  	 DimensionX = ps.Base_Dimension_X, 
 	  	  	 DimensionY = ps.Base_Dimension_Y, 
 	  	  	 DimensionZ = ps.Base_Dimension_Z, 
 	  	  	 DimensionA = ps.Base_Dimension_A, 
 	  	  	 BaseGeneral1 = ps.Base_General_1, 
 	  	  	 BaseGeneral2 = ps.Base_General_2, 
 	  	  	 BaseGeneral3 = ps.Base_General_3, 
 	  	  	 BaseGeneral4 = ps.Base_General_4, 
 	  	  	 PatternCode = ps.Pattern_Code,
 	  	  	 ParentPatternCode = ps2.Pattern_Code, 
 	  	  	 ActualStartTime = ps.Actual_Start_Time, 
 	  	  	 ActualEndTime = ps.Actual_End_Time, 
 	  	  	 ActualQuantity = ps.Actual_Good_Quantity,
 	  	  	 CommentId = ps.Comment_Id,
 	  	  	 ExtendedInfo = ps.Extended_Info,
  	  	  	 UserGeneral1 = ps.User_General_1,
  	  	  	 UserGeneral2 = ps.User_General_2,
  	  	  	 UserGeneral3 = ps.User_General_3,
      PredictedRemainingQuantity = ps.Predicted_Remaining_Quantity,
      ActualBadQuantity = ps.Actual_Bad_Quantity,
      PredictedTotalDuration = ps.Predicted_Total_Duration,
      PredictedRemainingDuration = ps.Predicted_Remaining_Duration,
      ActualRunningTime = ps.Actual_Running_Time,
      ActualDownTime = ps.Actual_Down_Time,
      ActualGoodItems = ps.Actual_Good_Items,
      ActualBadItems = ps.Actual_Bad_Items,
      AlarmCount = ps.Alarm_Count,
      LateItems = ps.Late_Items,
      ActualRepetitions = ps.Actual_Repetitions
 	 FROM 	 Production_Setup ps JOIN 
      Production_Plan pp ON pp.PP_Id = ps.PP_Id JOIN
      PrdExec_Paths pep ON pep.Path_Id = pp.Path_Id JOIN
 	  	  	 Production_Plan_Statuses pps ON pps.PP_Status_Id = ps.PP_Status_Id LEFT OUTER JOIN
      Production_Setup ps2 ON ps2.PP_Setup_Id = ps.Parent_PP_Setup_Id
 	 WHERE 	 ps.PP_Setup_Id = @PPSetupId
