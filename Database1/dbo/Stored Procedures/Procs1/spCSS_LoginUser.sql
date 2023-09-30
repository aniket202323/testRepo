CREATE PROCEDURE dbo.spCSS_LoginUser 
@UserName nvarchar(50),
@PassWord nvarchar(50),
@LoggedIn int OUTPUT,
@User_Id int OUTPUT,
@Role_Based_Security bit OUTPUT
AS
Select @User_Id = NULL
Select @User_Id = User_Id, @Role_Based_Security = Role_Based_Security
  From Users
  Where UserName = @UserName and Active = 1 and Is_Role = 0 and
             ((Password = @Password) or (((@Password Is Null) or (@Password = '')) and (Password Is Null))) 
--Null User_Id Indicates Unsuccessful Login
If @User_Id Is Null 
  Select @LoggedIn = 0
Else
  Select @LoggedIn = 1
