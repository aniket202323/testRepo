CREATE view SDK_V_PAPathUnit
as
select
PrdExec_Path_Units.PEPU_Id as Id,
PrdExec_Path_Units.Is_Production_Point as IsProductionPoint,
PrdExec_Path_Units.Is_Schedule_Point as IsSchedulePoint,
PrdExec_Path_Units.Unit_Order as UnitOrder,
PrdExec_Path_Units.Path_Id as PathId,
PrdExec_Paths.Path_Code as PathCode,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Units_Base.PU_Desc as ProductionUnit,
PrdExec_Path_Units.PU_Id as ProductionUnitId
From PrdExec_Path_Units
LEFT
 JOIN Prod_Units_Base on Prod_Units_Base.PU_Id = PrdExec_Path_Units.PU_Id
LEFT
 JOIN Prod_Lines_Base on Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
LEFT
 JOIN Departments_Base on Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
LEFT
 JOIN Prdexec_Paths on Prdexec_Paths.Path_Id = PrdExec_Path_Units.Path_Id
