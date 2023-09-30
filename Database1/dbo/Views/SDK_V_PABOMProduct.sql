CREATE view SDK_V_PABOMProduct
as
select
Bill_Of_Material_Product.BOM_Product_Id as Id,
Formulation.BOM_Formulation_Desc as BOMFormulation,
Bill_Of_Material_Product.BOM_Formulation_Id as BOMFormulationId,
Products.Prod_Code as ProductCode,
Bill_Of_Material_Product.Prod_Id as ProductId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Units_Base.PU_Desc as ProductionUnit,
Bill_Of_Material_Product.PU_Id as ProductionUnitId
FROM Bill_Of_Material_Product
 JOIN Bill_Of_Material_Formulation Formulation On Formulation.BOM_Formulation_Id = Bill_Of_Material_Product.BOM_Formulation_Id
 LEFT JOIN Prod_Units_Base On Bill_Of_Material_Product.PU_Id = Prod_Units_Base.PU_Id
 LEFT JOIN Prod_Lines_Base ON Prod_Units_Base.PL_Id = Prod_Lines_Base.PL_Id AND Prod_Units_Base.PU_Id > 0
 LEFT JOIN Departments_Base ON Prod_Lines_Base.Dept_Id = Departments_Base.Dept_Id AND Prod_Lines_Base.PL_Id > 0
 LEFT JOIN Products On Products.Prod_Id = Bill_Of_Material_Product.Prod_Id
