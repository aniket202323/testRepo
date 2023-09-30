--*********************************************/
create procedure [dbo].spRS_WOListEventTypes
@Units varchar(255) = NULL
AS
Declare @MasterEventTable TABLE(EventTypeId int, EventSubTypeId int, EventDescription varchar(1000))
declare @DuplicateEventTable TABLE (Counter int, EventDescription varchar(1000))
DECLARE @UnitTable TABLE(PU_ID INT)
Declare @Unit int, @UnitCount int
INSERT into @UnitTable
 	 SELECT Id_Value FROM fnRS_MakeOrderedResultSet(@Units)
Select @UnitCount = Count(*) from @UnitTable
If @UnitCount = 0
 	 Insert into @UnitTable(PU_ID) Values(NULL)
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
-- Get Common Prompts
DECLARE @sAlarm VARCHAR(100)
SET @sAlarm = dbo.fnTranslate(@LangId, 34902, 'Alarm')
------------------------------------------
-- NEW Looping Example
------------------------------------------
Declare MyCursor INSENSITIVE CURSOR
  For ( Select PU_ID From @UnitTable)
  For Read Only
  Open MyCursor  
  Fetch Next From MyCursor Into @Unit
  While (@@Fetch_Status = 0)
    Begin
 	  	 Insert into @MasterEventTable(EventTypeId, EventSubTypeId, EventDescription)
 	  	  	 Select EventTypeId = 0, EventSubTypeId = 0, EventDescription = dbo.fnTranslate(@LangId, 34903, 'Crew Schedule')
 	  	  	 Union
 	  	  	 Select EventTypeId = ec.et_id, EventSubTypeId = es.event_subtype_id, EventDescription = coalesce(es.event_subtype_desc, et.et_desc)  
 	  	  	   From Event_Configuration ec
 	  	  	   Join Event_Types et on et.et_id = ec.et_id
 	  	  	   Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id 
 	  	  	   Where (@Unit Is Null Or ec.PU_Id = @Unit)
 	  	  	  	  and ec.et_id not in (0,5,6,7,8,9,10,11,16,17,18,20,21,22) 
 	  	  	 Union
 	  	  	 Select EventTypeId = 11, EventSubTypeId = v.var_id, EventDescription = v.var_desc + @sAlarm
 	  	  	   From variables v  
 	  	  	   Join Prod_units pu on pu.pu_id = v.pu_id and (pu.pu_id = @Unit or pu.master_unit = @Unit)
 	  	  	   Join alarm_template_var_data a on a.var_id = v.var_id
 	  	  	 Union
 	  	  	 Select EventTypeId = -2, EventSubTypeId = Null, EventDescription = dbo.fnTranslate(@LangId, 35132, 'Non-Productive Time')
 	  	 Fetch Next From MyCursor Into @Unit
    End 
Close MyCursor
Deallocate MyCursor
--if @UnitCount > 0
--Begin
-- 	 insert into @DuplicateEventTable(Counter, EventDescription)
-- 	 select count(EventDescription) [Count], EventDescription from @MasterEventTable
-- 	 group by EventDescription
-- 
-- 	 delete from @DuplicateEventTable where Counter > 1
--
-- 	 delete from @MasterEventTable where EventDescription Not In(select eventDescription from @DuplicateEventTable)
--End
select distinct EventTypeId, EventSubTypeId, EventDescription from @MasterEventTable
