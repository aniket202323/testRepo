CREATE view SDK_V_PADowntimeFault
as
select
Timed_Event_Fault.TEFault_Id as Id,
Timed_Event_Fault.TEFault_Name as DowntimeFault,
Timed_Event_Fault.TEFault_Value as Value,
Timed_Event_Fault.Event_Reason_Tree_Data_Id as ReasonTreeDataId,
Timed_Event_Fault.Reason_Level3 as ReasonLevel3Id,
Timed_Event_Fault.Reason_Level2 as ReasonLevel2Id,
Timed_Event_Fault.Reason_Level1 as ReasonLevel1Id,
Timed_Event_Fault.Reason_Level4 as ReasonLevel4Id,
r1.Event_Reason_Name as ReasonLevel1Name,
r2.Event_Reason_Name as ReasonLevel2Name,
r3.Event_Reason_Name as ReasonLevel3Name,
r4.Event_Reason_Name as ReasonLevel4Name,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Units_Base.PU_Desc as ProductionUnit,
Timed_Event_Fault.PU_Id as ProductionUnitId,
Departments_Source.Dept_Desc as SourceDepartment,
Prod_Lines_Source.Dept_Id as SourceDepartmentId,
Prod_Lines_Source.PL_Desc as SourceProductionLine,
Prod_Units_Source.PL_Id as SourceProductionLineId,
Prod_Units_Source.PU_Desc as SourceProductionUnit,
Timed_Event_Fault.Source_PU_Id as SourceProductionUnitId
from Timed_Event_Fault
LEFT
 JOIN Event_Reason_Tree_Data on Event_Reason_Tree_Data.Event_Reason_Tree_Data_Id = Timed_Event_Fault.Event_Reason_Tree_Data_Id
LEFT
 JOIN Event_Reasons r1 on r1.Event_Reason_Id = Timed_Event_Fault.Reason_Level1
LEFT
 JOIN Event_Reasons r2 on r2.Event_Reason_Id = Timed_Event_Fault.Reason_Level2
LEFT
 JOIN Event_Reasons r3 on r3.Event_Reason_Id = Timed_Event_Fault.Reason_Level3
LEFT
 JOIN Event_Reasons r4 on r4.Event_Reason_Id = Timed_Event_Fault.Reason_Level4
LEFT
 JOIN Prod_Units_Base on Prod_Units_Base.PU_Id = Timed_Event_Fault.PU_Id
LEFT
 JOIN Prod_Lines_Base on Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
LEFT
 JOIN Departments_Base on Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
LEFT
 JOIN Prod_Units_Base Prod_Units_Source on Prod_Units_Source.PU_Id = Timed_Event_Fault.Source_PU_Id
LEFT
 JOIN Prod_Lines_Base Prod_Lines_Source on Prod_Lines_Source.PL_Id = Prod_Units_Source.PL_Id
LEFT
 JOIN Departments_Base Departments_Source on Departments_Source.Dept_Id = Prod_Lines_Source.Dept_Id
