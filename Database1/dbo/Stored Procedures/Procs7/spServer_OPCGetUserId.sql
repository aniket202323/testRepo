CREATE PROCEDURE dbo.spServer_OPCGetUserId
@UserName nVarChar(100),
@User_Id int Output
AS
set @User_Id = Null
select @User_Id = User_Id from Users where rtrim(ltrim(lower(WindowsUserInfo))) = rtrim(ltrim(lower(@UserName)))
