CREATE view SDK_V_PAGenealogyEvent
as
select
Event_Components.Component_Id as Id,
Event_Components.Component_Id as GenealogyEventId,
sourcepl.PL_Desc as ParentProductionLine,
sourcepu.PU_Desc as ParentProductionUnit,
sourceevent.Event_Num as ParentEventName,
sourcesubtype.Event_Subtype_Desc as ParentEventSubType,
Prod_Lines_Base.PL_Desc as ChildProductionLine,
Prod_Units_Base.PU_Desc as ChildProductionUnit,
Events.Event_Num as ChildEventName,
Event_Subtypes.Event_Subtype_Desc as ChildEventSubType,
Event_Components.Dimension_X as DimensionX,
Event_Components.Dimension_Y as DimensionY,
Event_Components.Dimension_Z as DimensionZ,
Event_Components.Dimension_A as DimensionA,
Event_Components.Extended_Info as ExtendedInfo,
Event_Components.Start_Coordinate_X as StartCoordinateX,
Event_Components.Start_Coordinate_Y as StartCoordinateY,
Event_Components.Start_Coordinate_Z as StartCoordinateZ,
Event_Components.Start_Coordinate_A as StartCoordinateA,
Event_Components.Start_Time as StartTime,
Event_Components.Timestamp as EndTime,
Event_Components.Parent_Component_Id as ParentGenealogyEventId,
Event_Components.Signature_Id as ESignatureId,
Event_Components.Event_Id as ChildEventId,
Event_Subtypes.Event_Subtype_Id as ChildEventSubTypeId,
Prod_Lines_Base.PL_Id as ChildProductionLineId,
Prod_Units_Base.PU_Id as ChildProductionUnitId,
Event_Components.Source_Event_Id as ParentEventId,
Event_Subtypes.Event_Subtype_Id as ParentEventSubTypeId,
sourcepl.PL_Id as ParentProductionLineId,
sourcepu.PU_Id as ParentProductionUnitId,
Departments_Base.Dept_Desc as ChildDepartment,
Prod_Lines_Base.Dept_Id as ChildDepartmentId,
Departments_Base.Dept_Desc as ParentDepartment,
Prod_Lines_Base.Dept_Id as ParentDepartmentId,
Event_Components.Entry_On as EntryOn,
PrdExec_Inputs.Input_Name as PathInput,
Event_Components.PEI_Id as PathInputId,
Event_Components.Report_As_Consumption as ReportAsConsumption,
Users.User_Id as UserId,
Users.Username as Username
FROM event_components
 JOIN Events sourceevent ON sourceevent.Event_id = Event_Components.Source_Event_id
 LEFT JOIN Event_Configuration sourceconfiguration ON sourceevent.PU_Id = sourceconfiguration.PU_Id AND sourceconfiguration.ET_Id = 1
 LEFT JOIN Event_SubTypes sourcesubtype ON sourceconfiguration.Event_Subtype_Id = sourcesubtype.Event_Subtype_Id
 LEFT JOIN 	 PrdExec_Inputs ON 	  	 event_components.PEI_Id = PrdExec_Inputs.PEI_Id
 JOIN Prod_Units_Base sourcepu ON sourcepu.PU_id = sourceevent.PU_Id
 JOIN Prod_Lines_Base sourcepl ON sourcepl.pl_id = sourcepu.PL_Id
 JOIN Departments_Base sourcedept ON sourcepl.Dept_Id = sourcedept.Dept_Id
 JOIN Events ON Events.Event_id = Event_Components.Event_id
 LEFT JOIN Event_Configuration ON Events.PU_Id = Event_Configuration.PU_Id AND Event_Configuration.ET_Id = 1
 LEFT JOIN Event_SubTypes ON Event_Configuration.Event_Subtype_Id = Event_SubTypes.Event_Subtype_Id
 JOIN Prod_Units_Base ON Prod_Units_Base.PU_id = Events.PU_Id
 JOIN Prod_Lines_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 JOIN Departments_Base ON Prod_Lines_Base.Dept_Id = Departments_Base.Dept_Id
 Left JOIN Users on Users.User_Id = Event_Components.User_Id
