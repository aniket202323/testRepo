create function dbo.fnDBTranslate(@LanguageId INT, @PromptId INT, @DefaultString VARCHAR(8000))
returns varchar(8000)
as
BEGIN
  DECLARE @FoundPrompt VARCHAR(8000)
  Declare @IgnoreLocalPrompts Bit
  Declare @UserId Int
  Declare @OverRideLanguage Int
 	 Select @LanguageId = Language_Id,
            @UserId = [User_Id]
 	 From User_Connections
 	 Where SPID = @@Spid
 	 If @LanguageId Is Null
 	 BEGIN
 	  	 Select @LanguageId=Value  From User_Parameters where Parm_Id=8 and User_Id=@UserId and HostName=@@Servername
 	  	 If (@LanguageId Is Null)
 	  	 BEGIN
 	  	  	 Select @LanguageId=Value  From User_Parameters where Parm_Id=8 and User_Id=@UserId and (HostName is NULL or HostName = '')
 	  	  	 If (@LanguageId Is Null)
 	  	  	 BEGIN
 	  	  	  	 Select @LanguageId=Value  From Site_Parameters where Parm_Id=8 and HostName=@@Servername
 	  	  	  	 If (@LanguageId Is Null)
 	  	  	  	 BEGIN
 	  	  	  	  	 Select @LanguageId=Value  From Site_Parameters where Parm_Id=8 and (HostName is NULL or HostName = '')
 	  	  	  	 END
 	  	  	 END
 	  	 END
 	 END
  If @LanguageId Is Null
    Set @LanguageId = 0
  Select @OverRideLanguage = 0 - (@LanguageId + 1)
  Select @IgnoreLocalPrompts = Case Value When 'True' Then 1 Else 0 End
  from User_Parameters
  where [User_Id] = @UserId and Parm_Id = 62
  SELECT @FoundPrompt = Prompt_String from Language_Data where Prompt_Number = @PromptId and Language_Id = @OverRideLanguage
  if (@FoundPrompt is NULL)
  begin
    SELECT @FoundPrompt = Coalesce(ld2.Prompt_String, ld.Prompt_String)
    FROM Language_Data ld
    Left Outer Join Language_Data ld2 On @IgnoreLocalPrompts = 0 And (ld2.Prompt_Number = ld.Prompt_Number) And ld2.Language_Id = -1
    Where ld.Prompt_Number = @PromptId
    And ld.Language_Id = @LanguageId
    IF @FoundPrompt IS NULL
      SET @FoundPrompt = @DefaultString
  end 
  if (isnumeric(@FoundPrompt) = 1 and not @LanguageId = 0)
  begin
   select @FoundPrompt = (dbo.fnTranslate(N'0',  @PromptId, @DefaultString))
  end
  RETURN @FoundPrompt
END
