CREATE PROCEDURE dbo.spEM_LookupUserWindowsInfo 
@User_Id int,
@WindowsInfo nVarChar(200) OUTPUT
AS
Select @WindowsInfo = WindowsUserInfo
    From Users
    Where User_Id = @User_Id
