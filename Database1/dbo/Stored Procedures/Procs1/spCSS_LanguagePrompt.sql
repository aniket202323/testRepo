CREATE PROCEDURE dbo.spCSS_LanguagePrompt 
@LanguageNumber int,
@PromptNumber int, 
@Prompt nVarChar(255) OUTPUT
AS
DECLARE @LocalLangId 	 Int
SELECT @LocalLangId = 0 - @LanguageNumber - 1
Select @Prompt = Null
Select @Prompt = case
       When p2.Prompt_String is not Null then p2.Prompt_String
       Else p.Prompt_String End
From Language_Data p
Left Outer Join Language_Data p2 on p2.Prompt_Number = p.Prompt_Number and p2.Language_Id = @LocalLangId
Where p.Prompt_Number = @PromptNumber and p.language_Id = @LanguageNumber
