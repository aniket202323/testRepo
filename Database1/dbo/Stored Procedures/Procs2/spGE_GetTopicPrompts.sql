Create Procedure dbo.spGE_GetTopicPrompts
 AS
 	 Select PromptId = Prompt_Number, Prompt = Prompt_String 
 	 From language_Data
 	 Where Prompt_Number In( 24300,24301,24302,24303,24275,24310,24311,24312,24313,24314,24315,24316,24317,24318,24319)
 	   and Language_Id = 0
