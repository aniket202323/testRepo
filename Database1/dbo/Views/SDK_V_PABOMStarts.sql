CREATE view SDK_V_PABOMStarts
as
select
Bill_Of_Material_Starts.Start_Id as Id,
Formulation.BOM_Formulation_Desc as BOMFormulation,
Bill_Of_Material_Starts.BOM_Formulation_Id as BOMFormulationId,
Bill_Of_Material_Starts.End_Time as EndTime,
Bill_Of_Material_Starts.Start_Time as StartTime,
Bill_Of_Material_Starts.User_Id as UserId,
Users.Username as Username,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Units_Base.PU_Desc as ProductionUnit,
Bill_Of_Material_Starts.PU_Id as ProductionUnitId
FROM Departments_Base
LEFT
 JOIN Prod_Lines_Base ON Prod_Lines_Base.Dept_Id = Departments_Base.Dept_Id AND Prod_Lines_Base.PL_Id > 0 
LEFT
 JOIN Prod_Units_Base ON Prod_Units_Base.PL_Id = Prod_Lines_Base.PL_Id AND Prod_Units_Base.PU_Id > 0
LEFT
 JOIN Bill_Of_Material_Starts On Bill_Of_Material_Starts.PU_Id = Prod_Units_Base.PU_Id
JOIN Bill_Of_Material_Formulation Formulation On Formulation.BOM_Formulation_Id = Bill_Of_Material_Starts.BOM_Formulation_Id 
LEFT
 JOIN Users on Users.User_Id = Bill_Of_Material_Starts.User_Id
