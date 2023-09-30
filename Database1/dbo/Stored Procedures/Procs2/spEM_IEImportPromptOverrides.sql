CREATE PROCEDURE dbo.spEM_IEImportPromptOverrides
@Prompt 	  	  	   	  	  	 nvarchar(50),
@Language  	  	  	  	  	 nvarchar(50),
@EnglishString  	  	  	  	 nvarchar(1000),
@TranslatedString 	  	  	 nvarchar(1000),
@OverrideString 	  	  	  	 nvarchar(1000),
@UserId  	  	  	  	  	 int
AS
Declare 	 @Prompt_Number 	 int,
 	  	 @Language_Id 	 int,
 	  	 @LangDataId 	  	 Int
/* Initialize */
Select  	 @Prompt_Number  	 = Null,
 	  	 @Language_Id 	 = Null,
 	  	 @LangDataId 	  	 = Null
/* Clean and verify arguments */
Select 	 @Prompt  	  	  	 = LTrim(RTrim(@Prompt)),
 	  	 @Language  	  	  	 = LTrim(RTrim(@Language)),
 	  	 @OverrideString 	  	 =  LTrim(RTrim(@OverrideString))
/******************************************************************************************************************************************************
*  	  	  	  	  	  	 Get Configuration Ids 	   	  	  	  	  	  	 *
******************************************************************************************************************************************************/
Select @Language_Id = Language_Id
 From Languages
 Where Language_Desc = @Language
If @Language_Id Is Null 
  Begin
     Select 'Failed - Language not found'
     RETURN (-100)
  End
If isnumeric(@Prompt) <> 0
  Begin
 	 Select @Prompt_Number = convert(Int,@Prompt)
  End
Else
  Begin
 	 Select 'Failed - invalid prompt number'
 	 RETURN (-100)
  End
Select @LangDataId = Language_Data_Id
 From Language_Data
  Where Prompt_Number = @Prompt and Language_Id = @Language_Id
If @LangDataId Is Null
  Begin
 	 Select 'Failed - invalid prompt number / Language'
 	 RETURN (-100)
  End
 	 
If (Select Prompt_String From Language_Data where Language_Data_Id = @LangDataId) <> @TranslatedString
  Begin
 	 Select 'Failed - invalid prompt number / Language'
 	 RETURN (-100)
  End
If @OverrideString = '' Select @OverrideString = Null
Execute spEM_EditLangTrans @Prompt_Number,@OverrideString,@UserId,@Language_Id
