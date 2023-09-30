CREATE view SDK_V_PAPathProductAssignment
as
select
PrdExec_Path_Products.PEPP_Id as Id,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.PL_Desc as ProductionLine,
Products.Prod_Code as ProductCode,
Prdexec_Paths.PL_Id as ProductionLineId,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prdexec_Paths.Path_Code as PathCode,
PrdExec_Path_Products.Path_Id as PathId,
PrdExec_Path_Products.Prod_Id as ProductId
FROM Departments_Base
 INNER JOIN Prod_Lines_Base ON Prod_Lines_Base.Dept_Id = Departments_Base.Dept_Id
 INNER JOIN PrdExec_Paths ON PrdExec_Paths.PL_Id = Prod_Lines_Base.PL_Id
 INNER JOIN PrdExec_Path_Products ON PrdExec_Path_Products.Path_Id = PrdExec_Paths.Path_Id
 INNER JOIN Products ON products.Prod_Id =PrdExec_Path_Products.Prod_Id
