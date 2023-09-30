CREATE PROCEDURE dbo.spCSS_Approvers 
@GroupId int
AS
If @GroupId = 0
  Begin
    Select u.Username, u.WindowsUserInfo, u.User_Desc
      From Users u
        Join User_Security us on us.User_Id = u.User_Id
        Where us.Group_Id = 1 and us.Access_Level >= 3
  End
Else
  Begin
    Select u.Username, u.WindowsUserInfo, u.User_Desc
      From Users u
        Join User_Security us on us.User_Id = u.User_Id
        Where us.Group_Id = @GroupId and us.Access_Level >= 3
    Union
    Select u.Username, u.WindowsUserInfo, u.User_Desc
      From Users u
        Join User_Security us on us.User_Id = u.User_Id
        Where us.Group_Id = 1 and us.Access_Level >= 3
  End
