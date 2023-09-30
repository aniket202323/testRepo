CREATE procedure [dbo].[spWA_CheckWindowsLogin]
  @WinUser nVarChar(200)
AS
DECLARE @UserId INT
--Check to see if it is regular user:
SELECT @UserId = [User_Id]
FROM Users
WHERE WindowsUserInfo = @Winuser
--Make sure the user is configured for a mixed-mode
--login
And Mixed_Mode_Login = 1
And Active = 1
--Return -1 if they were not found at all
IF @UserId IS NULL
  RETURN -1
ELSE
  RETURN @UserId
