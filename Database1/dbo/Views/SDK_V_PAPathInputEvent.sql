CREATE view SDK_V_PAPathInputEvent
as
select
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
PrdExec_Inputs.Input_Name as PathInput,
PrdExec_Input_Positions.PEIP_Desc as PathInputPosition,
sourcepl.PL_Desc as SourceProductionLine,
sourcepu.PU_Desc as SourceProductionUnit,
Events.Event_Num as SourceEventName,
PrdExec_Input_Event.Timestamp as Timestamp,
PrdExec_Input_Event.Dimension_X as DimensionX,
PrdExec_Input_Event.Dimension_Y as DimensionY,
PrdExec_Input_Event.Dimension_Z as DimensionZ,
PrdExec_Input_Event.Dimension_A as DimensionA,
PrdExec_Input_Event.Unloaded as Unloaded,
PrdExec_Input_Event.Comment_Id as CommentId,
Prod_Units_Base.PU_Id as ProductionUnitId,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Lines_Base.Dept_Id as DepartmentId,
Departments_Base.Dept_Desc as Department,
PrdExec_Inputs.PU_Id as SourceProductionUnitId,
Prod_Units_Base.PL_Id as SourceProductionLineId,
sourcedept.Dept_Desc as SourceDepartment,
Prod_Lines_Base.Dept_Id as SourceDepartmentId,
PrdExec_Input_Event.Input_Event_Id as Id,
PrdExec_Input_Event.Input_Event_Id as PathInputEventId,
PrdExec_Input_Event.PEI_Id as PathInputId,
PrdExec_Input_Event.PEIP_Id as PathInputPositionId,
PrdExec_Input_Event.Event_Id as SourceEventId,
Comments.Comment_Text as CommentText,
Prod_Units_Base.PU_Order as ProductionUnitOrder,
PrdExec_Inputs.Input_Order as InputOrder,
PrdExec_Input_Event.Entry_On as EntryOn,
PrdExec_Input_Event.Signature_Id as ESignatureId,
Users.User_Id as UserId,
Users.Username as Username
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id 
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id 
 JOIN PrdExec_Inputs ON Prod_Units_Base.PU_Id = PrdExec_Inputs.PU_Id 
 JOIN PrdExec_Input_Event ON PrdExec_Inputs.PEI_Id = PrdExec_Input_Event.PEI_Id 
 LEFT JOIN PrdExec_Input_Positions ON PrdExec_Input_Positions.PEIP_Id = PrdExec_Input_Event.PEIP_Id
 LEFT JOIN Events ON PrdExec_Input_Event.Event_Id = events.Event_Id
 LEFT JOIN Prod_Units_Base sourcepu ON events.PU_Id = sourcepu.PU_Id
 LEFT JOIN Prod_Lines_Base sourcepl ON sourcepu.PL_Id = sourcepl.PL_Id
 LEFT JOIN Departments_Base sourcedept ON sourcepl.Dept_Id = sourcedept.Dept_Id
 Left JOIN Users on Users.User_Id = PrdExec_Input_Event.User_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=prdexec_input_event.Comment_Id
