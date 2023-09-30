CREATE PROCEDURE dbo.spCSS_MaintainUserSecurity 
@User_Id int
AS
Declare @MaxAccessLevel int,
        @GroupId int
Create Table #User_Security (
 	 UserId int NOT NULL,
 	 GroupId int NOT NULL,
 	 AccessLevel tinyint NOT NULL)
--Build temporary table of what the new user_security table will look like for this user
Insert into #User_Security (UserId, GroupId, AccessLevel)
  Select @User_Id, us.Group_Id, us.Access_Level
    From User_Security us
      Join User_Role_Security ur on ur.User_Id = @User_Id
      Where us.User_Id = ur.Role_User_Id
Declare MyCursor INSENSITIVE CURSOR
    For (Select GroupId from #User_Security)
    For Read Only
    Open MyCursor
  MyLoop1:
    Fetch Next From MyCursor Into @GroupId
    If (@@Fetch_Status = 0)  
      Begin
        Select @MaxAccessLevel = Max(AccessLevel) From #User_Security Where GroupId = @GroupId
      If Exists (Select Group_Id From User_Security Where Group_Id = @GroupId and User_Id = @User_Id)
        Begin
        --Update Access Level on all existing Groups for this User
          Update User_Security
            Set Access_Level = @MaxAccessLevel
            From #User_Security
             Where Group_Id = @GroupId and User_Id = @User_Id
        goto MyLoop1
        End
      Else
        --Add any new Groups this User did not previously have access to
        Begin
          Insert into User_Security (User_Id, Group_Id, Access_Level)
            Values (@User_Id, @GroupId, @MaxAccessLevel)
        goto MyLoop1
        End
      End
  Close MyCursor
  Deallocate MyCursor
--Remove User from any Groups they no longer have access to
Delete from User_Security
  Where User_Id = @User_Id and Group_Id not in (Select GroupId from #User_Security)
Drop Table #User_Security
