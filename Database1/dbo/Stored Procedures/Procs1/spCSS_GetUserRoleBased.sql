CREATE PROCEDURE dbo.spCSS_GetUserRoleBased 
@UserId int, 
@UserRoleBased int OUTPUT
AS
Select @UserRoleBased = 0
Select @UserRoleBased = Role_Based_Security
  From Users
  Where User_Id = @UserId
Return(0)
