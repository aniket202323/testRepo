CREATE view SDK_V_PAProductAssignment
as
select
PU_Products.Prod_Id as ProductId,
Products.Prod_Code as ProductCode,
Products.Prod_Desc as ProductDescription,
Product_Family.Product_Family_Desc as ProductFamily,
Products.Is_Manufacturing_Product as IsManufacturingProduct,
Products.Is_Sales_Product as IsSalesProduct,
Products.Product_Family_Id as ProductFamilyId,
PU_Products.PU_Id as ProductionUnitId,
Prod_Units_Base.PU_Desc as ProductionUnit,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Lines_Base.Dept_Id as DepartmentId,
Departments_Base.Dept_Desc as Department
FROM Departments_Base 
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id 
 JOIN Prod_Units_Base  ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id 
 JOIN PU_Products  ON Prod_Units_Base.PU_Id = PU_Products.PU_Id 
 JOIN Products  ON products.Prod_id = PU_Products.Prod_Id 
 JOIN Product_Family ON products.Product_Family_Id = Product_Family.Product_Family_Id 
