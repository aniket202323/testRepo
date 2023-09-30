CREATE PROCEDURE dbo.spCSS_GetWindowsUserInfo 
@UserId int,
@WindowsUserInfo nvarchar(200) OUTPUT
AS
Select @WindowsUserInfo = ''
Select @WindowsUserInfo = WindowsUserInfo
  From Users
  Where User_Id = @UserId
Return(0)
