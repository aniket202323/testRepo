CREATE PROCEDURE dbo.spCSS_GetUserId 
@UserName nVarChar(30),
@UserId int OUTPUT
AS
Select @UserId = 0
Select @UserId = User_Id
  From Users
  Where Username = @Username
Return(0)
