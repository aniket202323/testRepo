CREATE view SDK_V_PACharacteristicAssignment
as
select
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Product_Properties.Prop_Desc as ProductProperty,
Characteristics.Char_Desc as Characteristic,
Products.Prod_Code as ProductCode,
Prod_Units_Base.PL_Id as ProductionLineId,
PU_Characteristics.PU_Id as ProductionUnitId,
PU_Characteristics.Prop_Id as ProductPropertyId,
PU_Characteristics.Char_Id as CharacteristicId,
PU_Characteristics.Prod_Id as ProductId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id 
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 JOIN PU_Products ON Prod_Units_Base.PU_Id = PU_Products.PU_Id
 JOIN PU_Characteristics ON PU_Characteristics.PU_Id = Prod_Units_Base.PU_Id AND PU_Characteristics.Prod_Id = PU_Products.Prod_Id
 JOIN Products ON Products.Prod_id = PU_Products.Prod_Id
 JOIN Characteristics ON PU_Characteristics.Char_Id = Characteristics.Char_Id
 JOIN Product_Properties ON Product_Properties.Prop_Id = Characteristics.Prop_Id
