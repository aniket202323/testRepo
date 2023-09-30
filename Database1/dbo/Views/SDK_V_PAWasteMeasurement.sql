CREATE view SDK_V_PAWasteMeasurement
as
select
Waste_Event_Meas.WEMT_Id as Id,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Waste_Event_Meas.WEMT_Name as WasteMeasurement,
Waste_Event_Meas.Conversion as Conversion,
Prod_Units_Base.PL_Id as ProductionLineId,
Waste_Event_Meas.PU_Id as ProductionUnitId,
Prod_Lines_Base.Dept_Id as DepartmentId,
Departments_Base.Dept_Desc as Department,
waste_event_meas.Conversion_Spec as ConversionSpec
FROM Departments_Base
 JOIN Prod_Lines_Base ON Prod_Lines_Base.Dept_Id = Departments_Base.Dept_Id
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id AND Prod_Units_Base.PU_Id > 0
 JOIN Waste_Event_Meas ON Waste_Event_Meas.PU_Id = Prod_Units_Base.PU_Id
