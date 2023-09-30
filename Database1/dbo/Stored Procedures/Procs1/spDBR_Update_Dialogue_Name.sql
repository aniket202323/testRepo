Create Procedure dbo.spDBR_Update_Dialogue_Name
@dialogueID int,
@dialogueName varchar(100)
AS
 	 declare @count int, @version int
 	 set @version = 1
 	 set @count = (select count(dashboard_dialogue_name) from dashboard_dialogues where dashboard_dialogue_name = @dialoguename and not dashboard_dialogue_id = @dialogueid)
 	 if (@count > 0)
 	 begin
 	  	 set @version = (select max(version) from dashboard_dialogues where dashboard_dialogue_name = @dialoguename) + 1
 	 end
 	  
 	 update dashboard_dialogues set dashboard_dialogue_name = @dialogueName, version = @version where dashboard_dialogue_id = @dialogueID
