CREATE view SDK_V_PAPathStatusTransition
as
select
Production_Plan_Status.PPS_Id as Id,
FromPPStatuses.PP_Status_Desc as FromPPStatus,
Production_Plan_Status.From_PPStatus_Id as FromPPStatusId,
ToPPStatuses.PP_Status_Desc as ToPPStatus,
Production_Plan_Status.To_PPStatus_Id as ToPPStatusId,
PrdExec_Paths.Path_Code as PathCode,
Production_Plan_Status.Path_Id as PathId,
Production_Plan.Process_Order as ParentProductionPlan,
Production_Plan_Status.Parent_PP_Id as ParentProductionPlanId
FROM Production_Plan_Status
 LEFT JOIN PrdExec_Paths ON PrdExec_Paths.Path_Id = Production_Plan_Status.Path_Id
 LEFT JOIN Production_Plan_Statuses FromPPStatuses ON Production_Plan_Status.From_PPStatus_Id = FromPPStatuses.PP_Status_Id
 LEFT JOIN Production_Plan_Statuses ToPPStatuses ON Production_Plan_Status.To_PPStatus_Id = ToPPStatuses.PP_Status_Id
 LEFT JOIN Production_Plan ON Production_Plan.PP_Id = Production_Plan_Status.Parent_PP_Id
