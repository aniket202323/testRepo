CREATE view SDK_V_PAReasonTreeAssignment
as
select
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
master.PU_Desc as MasterUnit,
Event_Types.ET_Desc as EventType,
causetree.Tree_Name as CauseTree,
Prod_Events.Action_Reason_Enabled as ActionEnabled,
actiontree.Tree_Name as ActionTree,
Prod_Events.Research_Enabled as ResearchEnabled,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Events.PU_Id as ProductionUnitId,
Prod_Events.Event_Type as EventTypeId,
Prod_Events.Name_Id as CauseTreeId,
Prod_Events.Action_Tree_Id as ActionTreeId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.Master_Unit as MasterUnitId,
Prod_Units_Base.PU_Order as ProductionUnitOrder
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 LEFT JOIN Prod_Units_Base master ON Prod_Units_Base.Master_Unit = master.PU_Id
 JOIN Prod_Events prod_events ON Prod_Units_Base.PU_Id = prod_events.PU_Id
 LEFT JOIN Event_Types ON prod_events.Event_Type = event_types.ET_Id
 LEFT JOIN Event_Reason_Tree causetree ON prod_events.Name_Id = causetree.Tree_Name_Id
 LEFT JOIN Event_Reason_Tree actiontree ON prod_events.Action_Tree_Id = actiontree.Tree_Name_Id
