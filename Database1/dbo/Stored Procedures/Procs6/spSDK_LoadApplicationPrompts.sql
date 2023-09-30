Create Procedure [dbo].[spSDK_LoadApplicationPrompts]
  @LanguageId Int,
 	 @SamplePromptNumber Int,
 	 @MinRange Int Output,
 	 @MaxRange Int Output
AS
Declare @ApplicationId Int
Select @ApplicationId = App_Id, @MinRange = Min_Prompt, @MaxRange = Max_Prompt
From AppVersions
Where @SamplePromptNumber >= Min_Prompt
And @SamplePromptNumber <= Max_Prompt
Print 'Prompt belongs to application #' + Cast(@ApplicationId As VarChar(100))
Select Prompt_Number, Prompt_String
From AppVersions av
Join Language_Data ld On ld.Prompt_Number Between av.Min_Prompt and av.Max_Prompt
Where @ApplicationId Is Not Null
And Language_Id = @LanguageId
And av.App_Id = @ApplicationId
