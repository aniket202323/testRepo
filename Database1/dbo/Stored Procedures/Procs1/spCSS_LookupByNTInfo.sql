CREATE PROCEDURE dbo.spCSS_LookupByNTInfo 
@UserName nvarchar(20),
@DomainName nvarchar(20),
@AppUser nVarChar(30) OUTPUT,
@AppPassWord nVarChar(30) OUTPUT
AS
Select @AppUser = ''
Select @AppPassWord = ''
Select @AppUser = UserName, @AppPassWord = Password
  From Users
  Where WindowsUserInfo = @DomainName + '\' + @UserName and Active = 1
--Unable to match Domain\Username to a Proficy User
If @AppPassWord = '' Or @AppUser = ''
  Begin
    Return(1)
  End
Return(0)
