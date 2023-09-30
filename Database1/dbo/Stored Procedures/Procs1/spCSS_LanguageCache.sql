CREATE PROCEDURE dbo.spCSS_LanguageCache 
@LanguageNumber int,
@ApplicationID int,
@UserId int
AS
Declare @IgnoreLocalPrompts nvarchar(25)
DECLARE @LocalLangId 	 Int
SELECT @LocalLangId = 0 - @LanguageNumber - 1
Select Language_Desc from Languages where Language_Id = @LanguageNumber
Select @IgnoreLocalPrompts = 'False' /*Default to substitute all local prompts */
Select @IgnoreLocalPrompts = Value from User_Parameters where User_Id = @UserId and Parm_Id = 62
If @IgnoreLocalPrompts = 'False'
--Substitute system message prompts with the Local message prompts
 BEGIN
    Select p.Prompt_Number, case
           When p2.Prompt_String is not Null then p2.Prompt_String
           Else p.Prompt_String End as Prompt_String
    From Language_Data p
    Join AppVersions a on a.App_Id = @ApplicationId
    Left Outer Join Language_Data p2 on p2.Prompt_Number = p.Prompt_Number and p2.Language_Id = @LocalLangId
    Where p.Prompt_Number >= a.Min_Prompt and p.Prompt_Number <= a.Max_Prompt and 
                p.language_Id = @LanguageNumber order by p.Prompt_Number
 END
Else
--Ignore any Local message prompts
 BEGIN
  Select Distinct p.Prompt_Number, p.Prompt_String
   From Language_Data p
   Join AppVersions a on a.App_Id = @ApplicationId
   Where p.Prompt_Number >= a.Min_Prompt and p.Prompt_Number <= a.Max_Prompt
     and p.language_Id = @LanguageNumber
      order by p.Prompt_Number
 END
