CREATE view SDK_V_PADowntimeStatus
as
select
Timed_Event_Status.TEStatus_Id as Id,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Timed_Event_Status.TEStatus_Name as DowntimeStatus,
Timed_Event_Status.TEStatus_Value as DowntimeStatusValue,
Timed_Event_Status.PU_Id as ProductionUnitId,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId
FROM Timed_Event_Status
 INNER JOIN Prod_Units_Base ON Timed_Event_Status.PU_ID = Prod_Units_Base.PU_Id
 INNER JOIN Prod_Lines_Base ON Prod_Units_Base.PL_Id = Prod_Lines_Base.PL_Id 
 INNER JOIN Departments_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id 
