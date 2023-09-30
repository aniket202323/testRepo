create procedure [dbo].[spWO_ListEventTypes]
@VariableId int = Null,
@UnitId int = NULL
AS
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sAlarm nVarChar(100)
SET @sAlarm = dbo.fnTranslate(@LangId, 34902, 'Alarm')
If @VariableId Is Not Null
  Begin
    Select @UnitId = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End
      From Prod_Units 
      Where PU_Id = (Select PU_Id From Variables Where Var_Id = @VariableId)
  End
Select EventTypeId = 0, EventSubTypeId = 0, EventDescription = dbo.fnTranslate(@LangId, 34903, 'Crew Schedule')
Union
Select EventTypeId = ec.et_id, EventSubTypeId = es.event_subtype_id, EventDescription = coalesce(es.event_subtype_desc, et.et_desc)  
  From Event_Configuration ec
  Join Event_Types et on et.et_id = ec.et_id
  Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
  Where (@UnitId Is Null Or ec.PU_Id = @UnitId)
 	  and ec.et_id not in (0,5,6,7,8,9,10,11,16,17,18,20,21,22) 
Union
Select EventTypeId = 11, EventSubTypeId = v.var_id, EventDescription = v.var_desc + @sAlarm
  From variables v  
  Join Prod_units pu on pu.pu_id = v.pu_id and (pu.pu_id = @UnitId or pu.master_unit = @UnitId)
  Join alarm_template_var_data a on a.var_id = v.var_id
Union
Select EventTypeId = -2, EventSubTypeId = Null, EventDescription = dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time')
