Create Procedure [dbo].spWAIC_GetEventListByUnit
 	 @Units Varchar(8000) = Null
AS
Create Table #UnitArray([Order] int, UnitId int)
Insert Into #UnitArray([Order], UnitId) Exec spRS_MakeOrderedResultSet @Units
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
Declare @sAlarm nVarChar(100)
SET @sAlarm = dbo.fnTranslate(@LangId, 34902, 'Alarm')
------------------------------------------------
Select EventTypeId = 0, EventSubTypeId = 0, dbo.fnTranslate(@LangId, 34903, 'Crew Schedule') As [EventDescription],
 	 IdCode = 'C0', QualifiedDescription = dbo.fnTranslate(@LangId, 34903, 'Crew Schedule'), UnitId = ua.UnitId
 	 From #UnitArray ua
Union
Select EventTypeId = ec.et_id, EventSubTypeId = es.event_subtype_id,
 	 EventDescription = coalesce(es.event_subtype_desc, et.et_desc),
 	 IdCode = 'E' + Cast(ec.EC_Id As nvarchar(10)),
 	 QualifiedDescription = Coalesce(pu.PU_Desc + '->', '') + coalesce(es.event_subtype_desc, et.et_desc),
 	 UnitId = ec.PU_Id
  From Event_Configuration ec
  Join Event_Types et on et.et_id = ec.et_id
 	 Left Outer Join Prod_Units pu On pu.PU_Id = ec.PU_Id
  Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
  Where (@Units Is Null Or ec.PU_Id In (Select UnitId From #UnitArray))
 	  and ec.et_id not in (0,5,6,7,8,9,10,11,16,17,18,20,21,22) 
Union
Select EventTypeId = 11, EventSubTypeId = v.var_id, EventDescription = v.var_desc + ' ' + @sAlarm,
 	 IdCode = 'A' + Cast(v.var_id As nvarchar(10)),
 	 QualifiedDescription = Coalesce(pu.PU_Desc + '->', '') + v.var_desc + ' ' + @sAlarm,
 	 UnitId = pu.pu_id
  From variables v  
  Join Prod_units pu on pu.pu_id = v.pu_id and (@Units Is Null Or pu.pu_id In (Select UnitId From #UnitArray) Or pu.master_unit In (Select UnitId From #UnitArray))
  Join alarm_template_var_data a on a.var_id = v.var_id
Union
Select EventType = -2, EventSubTypeId = Null, EventDescription = dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time'),
 	 IdCode = 'N' + Cast(pu.PU_Id As nvarchar(10)),
 	 QualifiedDescription = Coalesce(pu.PU_Desc + '->', '') + dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time'),
 	 UnitId = pu.PU_Id
 	 From Prod_Units pu
 	 Where (@Units Is Null Or pu.PU_Id In (Select UnitId From #UnitArray))
