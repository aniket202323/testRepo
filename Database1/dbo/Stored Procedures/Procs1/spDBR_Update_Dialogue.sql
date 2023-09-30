Create Procedure dbo.spDBR_Update_Dialogue
@dialogueID int,
@dialoguename varchar(100),
@external int,
@url varchar(1000),
@paramcount int,
@version int
AS
 	 if (@external = 0)
 	 begin
 	  	 update dashboard_dialogues set external_address = @external, dashboard_dialogue_name = @dialoguename where dashboard_dialogue_id = @dialogueID
 	 end
 	 else
 	 begin
 	  	  	 declare @count int
 	  	  	 set @count = (select count(dashboard_dialogue_name) from dashboard_dialogues where dashboard_dialogue_name = @dialoguename and version = @version and not dashboard_dialogue_id = @dialogueid)
 	  	  	 if (@count > 0)
 	  	  	 begin
 	  	  	  	 set @version = (select max(version) from dashboard_dialogues where dashboard_dialogue_name = @dialoguename) + 1
 	  	  	 end 	 
 	  	  	 update dashboard_dialogues set external_address= @external, URL=@url, dashboard_dialogue_name = @dialoguename, parameter_count = @paramcount, version = @version where dashboard_dialogue_id = @dialogueID
 	 end
