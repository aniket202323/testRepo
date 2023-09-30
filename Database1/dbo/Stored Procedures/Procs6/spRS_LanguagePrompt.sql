/*
-- This prompt is in the database
spRS_LanguagePrompt 0, 38053, '72 Hours'
*/
CREATE PROCEDURE dbo.spRS_LanguagePrompt 
@LanguageNumber int,
@PromptNumber int,
@Prompt varchar(255)
AS
DECLARE @TempPrompt VarChar(255), @OverRideLanguage Int
Select @OverRideLanguage = 0 - (@LanguageNumber + 1)
Select @TempPrompt = Null
--Check For User Defined Over-ride Prompt
select @TempPrompt = Prompt_String from language_data Where Language_Id = @OverRideLanguage and Prompt_Number = @PromptNumber
If @@RowCount = 0
  Begin
 	 -- If No Over-ride Exists Then Check For Existing Translation
 	 Select @TempPrompt = Prompt_String
 	 From Language_Data
 	 Where Language_Id = @LanguageNumber
 	 AND 	  Prompt_Number = @PromptNumber
 	 -- If No Translation Exists Then Return The String Passed In
 	 If @@RowCount = 0
 	  	 Select @TempPrompt = @Prompt
  End
Select @PromptNumber 'Id', @TempPrompt 'Prompt'
