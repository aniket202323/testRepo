CREATE procedure [dbo].[spSDK_GetUserLanguage60_Bak_177]
 	 @UserId int
AS
Declare @LanguageId int
Select @LanguageId = Max(Value)
From User_Parameters 
Where Parm_Id = 8 And [User_Id] = @UserId
IF @LanguageId is null
  Select @LanguageId = [Value] From Site_Parameters Where Parm_Id = 8
Select IsNull(@LanguageId, 0) LanguageId
