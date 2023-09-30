Create Procedure dbo.spDBR_Delete_Dialogue
@dialogueID int
AS
 	 delete from dashboard_dialogue_parameters where dashboard_dialogue_id = @dialogueID
 	 delete from dashboard_dialogues where dashboard_dialogue_id = @dialogueID
