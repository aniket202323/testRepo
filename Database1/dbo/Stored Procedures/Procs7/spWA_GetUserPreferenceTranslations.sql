CREATE procedure [dbo].[spWA_GetUserPreferenceTranslations]
@UserId int
AS
DECLARE @LanguageId int
SELECT @LanguageId = MAX(Value)
FROM User_Parameters 
WHERE Parm_Id = 8 And [User_Id] = @UserId
IF @LanguageId is null
  Select @LanguageId = ISNULL(Value,0) from Site_Parameters where Parm_Id = 8
Select @LanguageId LanguageId
