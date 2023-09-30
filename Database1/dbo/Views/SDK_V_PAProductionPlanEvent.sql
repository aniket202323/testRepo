CREATE view SDK_V_PAProductionPlanEvent
as
select
Production_Plan.PP_Id as Id,
Production_Plan.PP_Id as ProductionPlanEventId,
Departments_Base.Dept_Desc as Department,
Prdexec_Paths.Path_Code as PathCode,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Production_Plan.Process_Order as ProcessOrder,
Production_Plan.Block_Number as BlockNumber,
Production_Plan.Implied_Sequence as ImpliedSequence,
Production_Plan_Statuses.PP_Status_Desc as ProductionPlanStatus,
Products.Prod_Code as ProductCode,
Production_Plan.Forecast_Start_Date as ForecastStartTime,
Production_Plan.Forecast_End_Date as ForecastEndTime,
Production_Plan.Actual_Start_Time as StartTime,
Production_Plan.Actual_End_Time as EndTime,
Production_Plan.Actual_Good_Quantity as ActualGoodQuantity,
Production_Plan.Forecast_Quantity as ForecastQuantity,
Production_Plan.Comment_Id as CommentId,
Production_Plan.Extended_Info as ExtendedInfo,
Production_Plan.User_General_1 as UserGeneral1,
Production_Plan.User_General_2 as UserGeneral2,
Production_Plan.User_General_3 as UserGeneral3,
Production_Plan.Production_Rate as ProductionRate,
Production_Plan_Types.PP_Type_Name as ProductionPlanType,
sourcepp.Process_Order as SourceProcessOrder,
Control_Type.Control_Type_Desc as ControlType,
Production_Plan.Adjusted_Quantity as AdjustedQuantity,
parentpp.Process_Order as ParentProcessOrder,
Production_Plan.Predicted_Remaining_Quantity as PredictedRemainingQuantity,
Production_Plan.Actual_Bad_Quantity as ActualBadQuantity,
Production_Plan.Predicted_Total_Duration as PredictedTotalDuration,
Production_Plan.Predicted_Remaining_Duration as PredictedRemainingDuration,
Production_Plan.Actual_Running_Time as ActualRunningTime,
Production_Plan.Actual_Down_Time as ActualDownTime,
Production_Plan.Actual_Good_Items as ActualGoodItems,
Production_Plan.Actual_Bad_Items as ActualBadItems,
Production_Plan.Alarm_Count as AlarmCount,
Production_Plan.Late_Items as LateItems,
Production_Plan.Actual_Repetitions as ActualRepetitions,
sourcepath.Path_Code as SourcePathCode,
parentpath.Path_Code as ParentPathCode,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Units_Base.PU_Id as ProductionUnitId,
Production_Plan.Path_Id as PathId,
Production_Plan.PP_Status_Id as ProductionPlanStatusId,
Production_Plan.Prod_Id as ProductId,
Production_Plan.Parent_PP_Id as ParentProductionPlanId,
Prdexec_Paths.Path_Id as ParentPathId,
Production_Plan.Source_PP_Id as SourceProductionPlanId,
Prdexec_Paths.Path_Id as SourcePathId,
Production_Plan.PP_Type_Id as ProductionPlanTypeId,
Production_Plan.Control_Type as ControlTypeId,
Comments.Comment_Text as CommentText,
Production_Plan.BOM_Formulation_Id as BOMFormulationId,
Production_Plan.Entry_On as EntryOn,
Users.User_Id as UserId,
Users.Username as Username
FROM Production_Plan
 LEFT JOIN PrdExec_Paths ON PrdExec_Paths.Path_Id = Production_Plan.Path_Id 
 LEFT JOIN PrdExec_Path_Units ON PrdExec_Path_Units.Path_Id = Production_Plan.Path_Id
 LEFT JOIN Prod_Units_Base ON Prod_Units_Base.PU_Id = PrdExec_Path_Units.PU_Id
 LEFT JOIN Prod_Lines_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 LEFT JOIN Departments_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 LEFT JOIN Products ON Production_Plan.Prod_Id = products.Prod_Id
 LEFT JOIN Production_Plan_Statuses ON Production_Plan.PP_Status_Id = Production_Plan_Statuses.PP_Status_Id
 LEFT JOIN Production_Plan_Starts ON Production_Plan.PP_Id = Production_Plan_Starts.PP_Id and Production_Plan_Starts.PP_Start_Id = (Select Max(PP_Start_Id) From Production_Plan_Starts Where PP_Id = Production_Plan.PP_Id)
 LEFT join Variables_Base as Variables on Prod_Units_Base.Production_Variable = Variables.Var_Id AND Variables.Data_Type_Id IN (1,2)
 JOIN Production_Plan_Types ON Production_Plan_Types.PP_Type_Id = Production_Plan.PP_Type_Id
 LEFT OUTER JOIN Production_Plan sourcepp ON sourcepp.PP_Id = Production_Plan.Source_PP_Id
 LEFT OUTER JOIN Control_Type ON Control_Type.Control_Type_Id = Production_Plan.Control_Type
 LEFT OUTER JOIN Production_Plan parentpp ON parentpp.PP_Id = Production_Plan.Parent_PP_Id
 LEFT OUTER JOIN PrdExec_Paths sourcepath ON sourcepath.Path_Id = sourcepp.Path_Id
 LEFT OUTER JOIN PrdExec_Paths parentpath ON parentpath.Path_Id = parentpp.Path_Id
 Left JOIN Users on Users.User_Id = Production_Plan.User_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=production_plan.Comment_Id
