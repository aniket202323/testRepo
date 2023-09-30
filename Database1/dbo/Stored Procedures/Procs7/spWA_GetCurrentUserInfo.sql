CREATE PROCEDURE [dbo].[spWA_GetCurrentUserInfo]
  @UserId INT = NULL OUTPUT,
  @LangId INT = NULL OUTPUT
AS
SELECT @UserId = [User_Id], @LangId = Language_Id
FROM User_Connections
WHERE spid = @@Spid
IF @LangId IS NULL
  SET @LangId = 0
