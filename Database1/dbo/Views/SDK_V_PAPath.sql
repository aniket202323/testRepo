CREATE view SDK_V_PAPath
as
select
Prdexec_Paths.Path_Id as Id,
Prdexec_Paths.Path_Code as PathCode,
Prdexec_Paths.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
Prdexec_Paths.Path_Desc as PathDescription,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prdexec_Paths.PL_Id as ProductionLineId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
PrdExec_Paths.Is_Line_Production as IsLineProduction,
PrdExec_Paths.Is_Schedule_Controlled as IsScheduleControlled,
PrdExec_Paths.Schedule_Control_Type as ScheduleControlTypeId,
prdexec_paths.Create_Children as CreateChildren
FROM PrdExec_Paths 
 Join Prod_Lines_Base on Prod_Lines_Base.PL_Id = PrdExec_Paths.PL_Id
 JOIN Departments_Base ON Prod_Lines_Base.Dept_Id = Departments_Base.Dept_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=prdexec_paths.Comment_Id
