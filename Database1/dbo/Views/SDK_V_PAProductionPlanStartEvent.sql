CREATE view SDK_V_PAProductionPlanStartEvent
as
select
Production_Plan_Starts.PP_Start_Id as Id,
Production_Plan_Starts.PP_Start_Id as ProductionPlanStartEventId,
Prdexec_Paths.Path_Code as PathCode,
Production_Plan.Process_Order as ProcessOrder,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Production_Plan_Starts.Start_Time as StartTime,
Production_Plan_Starts.End_Time as EndTime,
Production_Setup.Pattern_Code as PatternCode,
Production_Plan_Starts.Is_Production as IsProduction,
Production_Plan_Starts.PP_Id as ProductionPlanId,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
Production_Plan_Starts.PU_Id as ProductionUnitId,
Prdexec_Paths.Path_Id as PathId,
Products.Prod_Id as ProductId,
Products.Prod_Code as ProductCode,
Production_Plan_Starts.pp_setup_id as ProductionSetupId,
Production_Plan_Starts.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
Users.User_Id as UserId,
Users.Username as Username
FROM Production_Plan_Starts
 JOIN Production_Plan ON Production_Plan_Starts.PP_Id = Production_Plan.PP_Id
 JOIN Products ON Production_Plan.Prod_Id = Products.Prod_Id
 JOIN PrdExec_Paths ON Production_Plan.Path_Id = PrdExec_Paths.Path_Id
 JOIN Prod_Units_Base ON Production_Plan_Starts.PU_Id = Prod_Units_Base.PU_Id
 JOIN Prod_Lines_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 JOIN Departments_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 LEFT JOIN Production_Setup ON Production_Plan_Starts.PP_Setup_Id = Production_Setup.PP_Setup_Id
 Left JOIN Users on Users.User_Id = Production_Plan_Starts.User_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=production_plan_starts.Comment_Id
