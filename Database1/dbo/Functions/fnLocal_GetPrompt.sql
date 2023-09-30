-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_GetPrompt] (@LanguageId int, @PromptNumber int)
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-02
Version		:	1.0.0
Purpose		:	Find the Prompt_String corresponding to the Prompt Number and Language
					received as parameters.
-------------------------------------------------------------------------------------------------
*/

RETURNS varchar(8000)

AS
BEGIN
	DECLARE
	@PromptString	varchar(8000)

	SET @PromptString = (SELECT Prompt_String FROM dbo.Language_Data WHERE Language_Id = @LanguageId AND Prompt_Number = @PromptNumber)

	RETURN @PromptString

END

