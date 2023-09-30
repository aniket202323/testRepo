/*
set nocount on
exec spRS_GetEventsByUnit 2, 'E4,A2,E1,c0'
*/
CREATE PROCEDURE dbo.spRS_GetEventsByUnit
 	 @Units varchar(8000),
 	 @ExcludeList varchar(5000) = NULL
AS
Declare @ExcludeTable Table (ID varchar(10))
Declare @INstr VarChar(7999), @Id varchar(10), @Comma int
Select @INstr = @ExcludeList + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Comma = CharIndex(',', @Instr)
 	 Select @Id = SubString(@INstr,1,@Comma - 1)
    insert into @ExcludeTable (Id) Values (@Id)
 	 Select @Instr = Right(@Instr, DataLength(@Instr) - @Comma)
  End
Create Table #LocalEventsByUnit(
 	 EventTypeId int,
 	 EventSubTypeId int,
 	 EventDescription varchar(4000),
 	 IdCode varchar(10),
 	 QualifiedDescription varchar(4000)
)
Create Table #UnitArray([Order] int, UnitId int)
Insert Into #UnitArray([Order], UnitId) Exec spRS_MakeOrderedResultSet @Units
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
Declare @sAlarm VARCHAR(100)
SET @sAlarm = dbo.fnTranslate(@LangId, 34902, 'Alarm')
------------------------------------------------
insert into #LocalEventsByUnit
Select EventTypeId = 0, EventSubTypeId = 0, dbo.fnTranslate(@LangId, 34903, 'Crew Schedule') As [EventDescription],
 	 IdCode = 'C0', QualifiedDescription = dbo.fnTranslate(@LangId, 34903, 'Crew Schedule')
Union
Select EventTypeId = ec.et_id, EventSubTypeId = es.event_subtype_id,
 	 EventDescription = coalesce(es.event_subtype_desc, et.et_desc),
 	 IdCode = 'E' + Cast(ec.EC_Id As Varchar(10)),
 	 QualifiedDescription = Coalesce(pu.PU_Desc + '->', '') + coalesce(es.event_subtype_desc, et.et_desc)
  From Event_Configuration ec
  Join Event_Types et on et.et_id = ec.et_id
 	 Left Outer Join Prod_Units pu On pu.PU_Id = ec.PU_Id
  Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
  Where (@Units Is Null Or ec.PU_Id In (Select UnitId From #UnitArray))
 	  and ec.et_id not in (0,5,6,7,8,9,10,11,16,17,18,20,21,22) 
Union
Select EventTypeId = 11, EventSubTypeId = v.var_id, EventDescription = v.var_desc + ' ' + @sAlarm,
 	 IdCode = 'A' + Cast(v.var_id As Varchar(10)),
 	 QualifiedDescription = Coalesce(pu.PU_Desc + '->', '') + v.var_desc + ' ' + @sAlarm
  From variables v  
  Join Prod_units pu on pu.pu_id = v.pu_id and (@Units Is Null Or pu.pu_id In (Select UnitId From #UnitArray) Or pu.master_unit In (Select UnitId From #UnitArray))
  Join alarm_template_var_data a on a.var_id = v.var_id
Delete From #LocalEventsByUnit where IdCode in (Select id from @ExcludeTable)
Select IdCode, QualifiedDescription from #LocalEventsByUnit
drop table #LocalEventsByUnit
