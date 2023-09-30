CREATE view SDK_V_PAProductionSetupEvent
as
select
Production_Setup.PP_Setup_Id as Id,
Production_Setup.PP_Setup_Id as ProductionSetupEventId,
Production_Setup.Pattern_Code as PatternCode,
Prdexec_Paths.Path_Code as PathCode,
Production_Plan.Process_Order as ProcessOrder,
Production_Setup.Forecast_Quantity as ForecastQuantity,
Production_Setup.Implied_Sequence as ImpliedSequence,
Production_Plan_Statuses.PP_Status_Desc as ProductionPlanStatus,
Production_Setup.Pattern_Repititions as Repetitions,
Production_Setup.Shrinkage as Shrinkage,
Production_Setup.Base_Dimension_X as DimensionX,
Production_Setup.Base_Dimension_Y as DimensionY,
Production_Setup.Base_Dimension_Z as DimensionZ,
Production_Setup.Base_Dimension_A as DimensionA,
Production_Setup.Base_General_1 as BaseGeneral1,
Production_Setup.Base_General_2 as BaseGeneral2,
Production_Setup.Base_General_3 as BaseGeneral3,
Production_Setup.Base_General_4 as BaseGeneral4,
Production_Setup.Actual_Start_Time as StartTime,
Production_Setup.Actual_End_Time as EndTime,
Production_Setup.Actual_Good_Quantity as ActualGoodQuantity,
Production_Setup.Comment_Id as CommentId,
Production_Setup.Extended_Info as ExtendedInfo,
Production_Setup.User_General_1 as UserGeneral1,
Production_Setup.User_General_2 as UserGeneral2,
Production_Setup.User_General_3 as UserGeneral3,
Production_Setup.Predicted_Remaining_Quantity as PredictedRemainingQuantity,
Production_Setup.Actual_Bad_Quantity as ActualBadQuantity,
Production_Setup.Predicted_Total_Duration as PredictedTotalDuration,
Production_Setup.Predicted_Remaining_Duration as PredictedRemainingDuration,
Production_Setup.Actual_Running_Time as ActualRunningTime,
Production_Setup.Actual_Down_Time as ActualDownTime,
Production_Setup.Actual_Good_Items as ActualGoodItems,
Production_Setup.Actual_Bad_Items as ActualBadItems,
Production_Setup.Alarm_Count as AlarmCount,
Production_Setup.Late_Items as LateItems,
Production_Setup.Actual_Repetitions as ActualRepetitions,
Production_Setup.Parent_PP_Setup_Id as ParentProductionSetupId,
Prdexec_Paths.Path_Id as PathId,
Production_Setup.PP_Id as ProductionPlanId,
Production_Setup.Entry_On as EntryOn,
Production_Setup.PP_Status_Id as ProductionPlanStatusId,
Comments.Comment_Text as CommentText,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prdexec_Paths.PL_Id as ProductionLineId,
Users.User_Id as UserId,
Users.Username as Username
FROM PrdExec_Paths
 JOIN Production_Plan ON Production_Plan.Path_Id = PrdExec_Paths.Path_Id
 JOIN Production_Setup ON Production_Setup.PP_Id = Production_Plan.PP_Id
 JOIN Production_Plan_Statuses ON Production_Plan_Statuses.PP_Status_Id = Production_Setup.PP_Status_Id
 LEFT OUTER JOIN Production_Setup parentsetup ON parentsetup.PP_Setup_Id = Production_Setup.Parent_PP_Setup_Id
 LEFT OUTER JOIN PrdExec_Path_Units ON PrdExec_Path_Units.Path_Id = Production_Plan.Path_Id and PrdExec_Path_Units.Is_Schedule_Point = 1
 LEFT OUTER JOIN Prod_Units_Base ON Prod_Units_Base.PU_Id = PrdExec_Path_Units.PU_Id
 LEFT OUTER JOIN Prod_Lines_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 LEFT OUTER JOIN Departments_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 Left JOIN Users on Users.User_Id = Production_Setup.User_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=production_setup.Comment_Id
