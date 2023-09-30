/*
Summary: Retrieves the password for the specified plant applications username.  This is
 	 used so that the ISI can attempt to hash the password for authentication.
*/
CREATE procedure [dbo].[spSDK_GetPlantAppsUserPassword_Bak_177]
  @Username nvarchar(30), 	 --The username to retrieve the password for
 	 @Password nvarchar(30) Output, --The users password, coalesced to be non-null, unless it was not found
 	 @UserId Int Output --The user ID for the specified username, otherwise NULL
AS
Select @Password = IsNull(Password, NULL), @UserId = [User_Id]
From Users
Where Username = @Username
-- ECR#34670 -- Susan Bonner -- Return password for all users regardless of 
-- role, mixed mode, or windows information
--And Is_Role = 0
--Their PA password is only valid in mixed mode, or in standard
--mode if they don't have windows credentials
--And (WindowsUserInfo Is Null Or Mixed_Mode_Login = 1)
