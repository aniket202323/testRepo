CREATE procedure [dbo].[spWA_GetUserInfo]
  @UserId INT
AS
SELECT *
FROM Users
WHERE [User_Id] = @UserId
