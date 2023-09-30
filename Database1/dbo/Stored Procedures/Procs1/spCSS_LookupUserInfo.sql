CREATE PROCEDURE dbo.spCSS_LookupUserInfo 
@User_Id int,
@UserName nVarChar(30) OUTPUT
AS
Select @UserName = UserName
    From Users
    Where User_Id = @User_Id
