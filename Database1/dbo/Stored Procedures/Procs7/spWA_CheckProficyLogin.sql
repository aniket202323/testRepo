CREATE procedure [dbo].[spWA_CheckProficyLogin]
  @Username nVarChar(30),
  @Password nVarChar(30)
AS
DECLARE @UserId INT
--Check to see if it is regular user:
SELECT @UserId = [User_Id]
FROM Users
WHERE Username = @Username
AND (([Password] = @Password) OR ([Password] Is NULL AND @Password = ''))
And Active = 1
--Return -1 if they were not found at all
IF @UserId IS NULL
  RETURN -1
ELSE
  RETURN @UserId
