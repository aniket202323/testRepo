CREATE procedure [dbo].[spSDK_CheckWindowsLogin60]
  @WinUser VARCHAR(200)
AS
DECLARE @UserId INT
--Check to see if it is regular user:
SELECT @UserId = [User_Id]
FROM Users
WHERE WindowsUserInfo = @Winuser AND Mixed_Mode_Login = 1
-- ECR #34670 -- Susan Bonner -- User should not be able to sign on if mixed mode is false
--Return -1 if they were not found at all
IF @UserId IS NULL
  RETURN -1
ELSE
  RETURN @UserId
