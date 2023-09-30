CREATE PROCEDURE dbo.spCSS_ChangePassword 
@UserID int,
@Password nVarChar(30) 
AS
--Just in case, don't let them change passwords on system users.
Update Users Set Password = @password
  Where User_id = @UserID
        and System <> 1
