CREATE PROCEDURE dbo.spCSS_LookupUsername 
@UserName nVarChar(30)
AS
Declare @AppUser nVarChar(30)
Select @AppUser = ''
Select @AppUser = UserName
  From Users
  Where UserName = @UserName
If @AppUser = ''
  Begin
    Return(1)
  End
Return(0)
