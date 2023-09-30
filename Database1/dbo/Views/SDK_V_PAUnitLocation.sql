CREATE view SDK_V_PAUnitLocation
as
select
Unit_Locations.Location_Id as Id,
Unit_Locations.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
Unit_Locations.Location_Code as LocationCode,
Unit_Locations.Location_Desc as UnitLocation,
Unit_Locations.Maximum_Alarm_Enabled as MaximumAlarmEnabled,
Unit_Locations.Maximum_Dimension_A as MaximumDimensionA,
Unit_Locations.Maximum_Dimension_X as MaximumDimensionX,
Unit_Locations.Maximum_Dimension_Y as MaximumDimensionY,
Unit_Locations.Maximum_Dimension_Z as MaximumDimensionZ,
Unit_Locations.Maximum_Items as MaximumItems,
Unit_Locations.Minimum_Alarm_Enabled as MinimumAlarmEnabled,
Unit_Locations.Minimum_Dimension_A as MinimumDimensionA,
Unit_Locations.Minimum_Dimension_X as MinimumDimensionX,
Unit_Locations.Minimum_Dimension_Y as MinimumDimensionY,
Unit_Locations.Minimum_Dimension_Z as MinimumDimensionZ,
Unit_Locations.Minimum_Items as MinimumItems,
Unit_Locations.Prod_Id as ProductId,
Products.Prod_Code as ProductCode,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Units_Base.PU_Desc as ProductionUnit,
Unit_Locations.PU_Id as ProductionUnitId
FROM Departments_Base
JOIN Prod_Lines_Base ON Prod_Lines_Base.Dept_Id = Departments_Base.Dept_Id AND Prod_Lines_Base.PL_Id > 0 
JOIN Prod_Units_Base ON Prod_Units_Base.PL_Id = Prod_Lines_Base.PL_Id AND Prod_Units_Base.PU_Id > 0
JOIN Unit_Locations On Unit_Locations.PU_Id = Prod_Units_Base.PU_Id
LEFT
 JOIN Products On Products.Prod_Id = Unit_Locations.Prod_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=Unit_Locations.Comment_Id
