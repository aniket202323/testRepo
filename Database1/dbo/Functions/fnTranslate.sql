create function dbo.fnTranslate(@LanguageId INT, @PromptId INT, @DefaultString VARCHAR(8000))
returns varchar(8000)
as
BEGIN
  DECLARE @FoundPrompt VARCHAR(8000)
  Declare @IgnoreLocalPrompts Bit
  Declare @UserId Int
  Declare @LangId Int
  Select @LanguageId = Coalesce(@LanguageId, Language_Id),
            @UserId = [User_Id]
  From User_Connections
  Where SPID = @@Spid
  --Default to English
  If @LanguageId Is Null
    Set @LanguageId = 0
  Select @IgnoreLocalPrompts = Case Value When 'True' Then 1 Else 0 End
  from User_Parameters
  where [User_Id] = @UserId and Parm_Id = 62
  If @IgnoreLocalPrompts Is Null
 	 Set @IgnoreLocalPrompts = 0
  SELECT @FoundPrompt = Coalesce(ld2.Prompt_String, ld.Prompt_String)
  FROM Language_Data ld
  Left Outer Join Language_Data ld2 On @IgnoreLocalPrompts = 0 And (ld2.Prompt_Number = ld.Prompt_Number) And ld2.Language_Id = -1
  Where ld.Prompt_Number = @PromptId
  And ld.Language_Id = @LanguageId
  IF @FoundPrompt IS NULL
    SET @FoundPrompt = @DefaultString
  RETURN @FoundPrompt
END
