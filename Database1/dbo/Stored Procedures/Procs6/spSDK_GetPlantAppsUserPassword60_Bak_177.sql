/*
Summary: Retrieves the password for the specified plant applications username.  This is
 	 used so that the ISI can attempt to hash the password for authentication.
*/
CREATE procedure [dbo].[spSDK_GetPlantAppsUserPassword60_Bak_177]
 	 @Username nvarchar(30), 	 --The username to retrieve the password for
 	 @Password nvarchar(30) Output, --The users password, coalesced to be non-null, unless it was not found
 	 @UserId Int Output --The user ID for the specified username, otherwise NULL
AS
IF CHARINDEX('\',@Username) = 0
 	 Select @Password = IsNull(Password, NULL), @UserId = [User_Id]
 	 From Users 
 	 Where Username = @Username and Active = 1
ELSE
 	 Select @Password = IsNull(Password, NULL), @UserId = [User_Id]
 	 From Users 
 	 Where WindowsUserInfo  = @Username and Active = 1
