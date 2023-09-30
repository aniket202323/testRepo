
CREATE PROCEDURE [dbo].[spLocal_eCIL_GetResultPrompts]
/*
Stored Procedure		:		spLocal_eCIL_GetResultPrompts
Author					:		Normand Carbonneau (System Technologies for Industry Inc)
Date Created			:		10-Apr-2007
SP Type					:		eCIL
Editor Tab Spacing		:		3
Description:
===========
Get the list of possible values for a Task depending of the language.
CALLED BY				:  eCIL
Revision 		Date			Who						What
========		===========		==================		=================================================================================
1.0.0			10-Apr-2007		Normand Carbonneau		Creation of SP
2.0.0			15-Jun-2008		Normand Carbonneau		Prompts are no longer located at fixed Prompt_Numbers.
																		Retrieve prompts from fnLocal_GetPromptByIndex function.
3.0.0			31-Jul-2008		Normand Carbonneau		@PagePosition parameter removed
																		Compliant with new Prompts Manager v2.0
																		Prompts are no longer at fixed range
4.0.0			10-Sep-2008		Normand Carbonneau		@Include parameters are no longer required. Managed in the application.
4.0.1			31-Jul-2015		Santosh Shanbhag		Matched the version with Serena, Replaced SP registration section & encrypted the script
4.0.2			21-Oct-2020		Megha Lohana			eCIL 4.1 SP Standardized , Added no locks and base tables
4.0.3			23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
4.0.4 			03-May-2023             Aniket B			Remove grant permissions statement from the SP as moving it to permissions grant script
4.0.5			02-Aug-2023		Payal Gadhvi			Updated SP with version management and to meet coding standard 
Test Code:
EXEC spLocal_eCIL_GetResultPrompts 8
*/
@LanguageId			INT = NULL		/* Indicate the user language for which we want the prompts */
									/* If not specified, English is set by default */

AS
SET NOCOUNT ON

DECLARE
@ServerLanguageId		INT,
@eCIL_DataType_Start	INT,
@PendingPosition		INT,
@OkPosition				INT,
@DefectPosition			INT,
@LatePosition			INT,
@MissedPosition			INT,
@PromptCategory			VARCHAR(50);

DECLARE	@Phrases TABLE
(
Prompt_Number			INT,
ServerPrompt			VARCHAR(50),
UserPrompt				VARCHAR(50)
);

/* Retrieves the language used on the server */
SET @ServerLanguageId = (SELECT Value FROM dbo.Site_Parameters WITH (NOLOCK) WHERE Parm_Id = 8) ;

/* If the user language is not specified, English language is set by default */
IF @LanguageId IS NULL
	
		SET @LanguageId = 0;
	

/* Set the Category used for prompts retrieval */
SET @PromptCategory = 'eCIL_DataType' ;

/* Get the starting Prompt_Number for the eCIL_Global category */
SET @eCIL_DataType_Start = (SELECT Min_Prompt FROM dbo.AppVersions WITH (NOLOCK) WHERE App_Name = @PromptCategory) ;

/* Initialize Position for prompts retrieval in eCIL_Global category */
SELECT	@PendingPosition		=	1,
			@OkPosition			=	2,
			@DefectPosition		=	3,
			@LatePosition		=	4,
			@MissedPosition		=	5;

/* Pending */
INSERT @Phrases (Prompt_Number, ServerPrompt)
	SELECT	@eCIL_DataType_Start + @PendingPosition - 1,
				dbo.fnLocal_STI_Cmn_GetPrompt(@PromptCategory, @PendingPosition, DEFAULT);
	
/* Ok */
INSERT @Phrases (Prompt_Number, ServerPrompt)
	SELECT	@eCIL_DataType_Start + @OkPosition - 1,
				dbo.fnLocal_STI_Cmn_GetPrompt(@PromptCategory, @OkPosition, DEFAULT);

/* Defect */
INSERT @Phrases (Prompt_Number, ServerPrompt)
	SELECT	@eCIL_DataType_Start + @DefectPosition - 1,
				dbo.fnLocal_STI_Cmn_GetPrompt(@PromptCategory, @DefectPosition, DEFAULT) ;

/* Late */
INSERT @Phrases (Prompt_Number, ServerPrompt)
	SELECT	@eCIL_DataType_Start + @LatePosition - 1,
				dbo.fnLocal_STI_Cmn_GetPrompt(@PromptCategory, @LatePosition, DEFAULT) ;

/* Missed */
INSERT @Phrases (Prompt_Number, ServerPrompt)
	SELECT	@eCIL_DataType_Start + @MissedPosition - 1,
				dbo.fnLocal_STI_Cmn_GetPrompt(@PromptCategory, @MissedPosition, DEFAULT) ;

/* Get the translation in the user's language for each prompt */
UPDATE		p
SET			UserPrompt = ld.Prompt_String
FROM			@Phrases p
LEFT JOIN	dbo.Language_Data ld WITH (NOLOCK) ON (p.Prompt_Number = ld.Prompt_Number)
WHERE			ld.Language_Id = @LanguageId ;

SELECT		PromptPosition	=	Prompt_Number - @eCIL_DataType_Start + 1,
			ServerPrompt,
			UserPrompt		=	ISNULL(UserPrompt, ServerPrompt)
FROM		@Phrases
ORDER BY UserPrompt ASC ;

