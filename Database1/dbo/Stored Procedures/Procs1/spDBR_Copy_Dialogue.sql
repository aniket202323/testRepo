Create Procedure dbo.spDBR_Copy_Dialogue
@dialogueID int,
@dialogueName varchar(1000)
AS
 	 declare  @URL varchar(1000), @Parameter_Count int
 	 set @URL = (select URL from dashboard_dialogues where dashboard_dialogue_id = @dialogueID)
 	 set @Parameter_Count = (select Parameter_Count from dashboard_dialogues where dashboard_dialogue_id = @dialogueID)
 	 
 	 declare @sqlstmt  nvarchar(4000)
 	 set @sqlstmt = N'spdbr_add_new_dialogue "' + Convert(nvarchar, @dialogueName) + '", "' + Convert(nvarchar(1000), @URL) + '", ' + Convert(nvarchar, @Parameter_Count)
 	 
 	 execute sp_executesql @sqlstmt
 	 
