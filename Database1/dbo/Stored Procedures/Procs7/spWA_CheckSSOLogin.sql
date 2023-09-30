CREATE procedure [dbo].[spWA_CheckSSOLogin]
  @SSOUser nVarChar(200)
AS
DECLARE @UserId INT
--Check to see if it is regular user:
SELECT @UserId = [User_Id]
FROM USERS_BASE
WHERE SSOUserId = @SSOUser
And  UseSSO=1
And Active = 1
--Return -1 if they were not found at all
IF @UserId IS NULL
  RETURN -1
ELSE
  RETURN @UserId
