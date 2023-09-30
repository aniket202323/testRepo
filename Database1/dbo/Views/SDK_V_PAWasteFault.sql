CREATE view SDK_V_PAWasteFault
as
select
Waste_Event_Fault.WEFault_Id as Id,
Waste_Event_Fault.WEFault_Name as WasteFault,
Waste_Event_Fault.WEFault_Value as Value,
Waste_Event_Fault.PU_Id as ProductionUnitId,
Waste_Event_Fault.Reason_Level1 as ReasonLevel1Id,
ReasonLevel1_Src.Event_Reason_Name as ReasonLevel1,
Waste_Event_Fault.Reason_Level2 as ReasonLevel2Id,
ReasonLevel2_Src.Event_Reason_Name as ReasonLevel2,
Waste_Event_Fault.Reason_Level3 as ReasonLevel3Id,
ReasonLevel3_Src.Event_Reason_Name as ReasonLevel3,
Waste_Event_Fault.Reason_Level4 as ReasonLevel4Id,
ReasonLevel4_Src.Event_Reason_Name as ReasonLevel4,
Prod_Units_Base.PU_Desc as ProductionUnit,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Source_Departments_Base.Dept_Desc as SourceDepartment,
Source_Lines.Dept_Id as SourceDepartmentId,
Source_Units.PU_Desc as SourceProductionUnit,
Waste_Event_Fault.Source_PU_Id as SourceProductionUnitId,
Source_Lines.PL_Desc as SourceProductionLine,
Source_Units.PL_Id as SourceProductionLineId
from Waste_Event_Fault 
Left
 Join Event_Reasons ReasonLevel1_Src on ReasonLevel1_Src.Event_Reason_Id = Waste_Event_Fault.Reason_Level1  
Left
 Join Event_Reasons ReasonLevel2_Src on ReasonLevel2_Src.Event_Reason_Id = Waste_Event_Fault.Reason_Level2  
Left
 Join Event_Reasons ReasonLevel3_Src on ReasonLevel3_Src.Event_Reason_Id = Waste_Event_Fault.Reason_Level3  
Left
 Join Event_Reasons ReasonLevel4_Src on ReasonLevel4_Src.Event_Reason_Id = Waste_Event_Fault.Reason_Level4 
Left
 Join Prod_Units_Base on Prod_Units_Base.PU_Id = Waste_Event_Fault.PU_Id
Left
 Join Prod_Lines_Base on Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
Left
 Join Departments_Base on Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
Left
 Join Prod_Units_Base Source_Units on Source_Units.PU_Id = Waste_Event_Fault.Source_PU_Id
Left
 Join Prod_Lines_Base Source_Lines on Source_Lines.PL_Id = Source_Units.PL_Id
Left
 Join Departments_Base Source_Departments_Base on Source_Departments_Base.Dept_Id = Source_Lines.Dept_Id
