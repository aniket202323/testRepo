CREATE PROCEDURE dbo.spCSS_MaintainUserSecurityByRole 
@RoleUserIdList varchar(8000) =NULL,
@User_Id int
AS
Create table #RoleIdList (
  RoleUserId int NOT NULL
)
declare @i integer
declare @tchar char
declare @tvchar nvarchar(10)
declare @tID integer
declare @MaxAccessLevel integer
declare @GroupId integer
select @tvchar='' -- make SP work on 7.0
Select @i = 1 	  	     
Select @tchar = SUBSTRING (@RoleUserIdList, @i, 1)
While (@tchar <> '$') /*And (@i < 254)*/ and (@tchar is not null)
  Begin
     If @tchar <> ','
       Select @tvchar = @tvchar + @tchar
     Else
       Begin
         Select @tvchar = LTRIM(RTRIM(@tvchar))
         If @tvchar <> '' 
           Begin
             Select @tID = CONVERT(integer, @tvchar)
              if 1 = 1 
              Begin
               Insert into #RoleIdList (RoleUserId) values (@tID)
              End
           End
           If @tchar = ','
             Begin
 	        Select @tvchar = ''
 	      End
       End
     Select @i = @i + 1
     Select @tchar = SUBSTRING(@RoleUserIdList, @i, 1)
  End
 	  	 
Select @tvchar = LTRIM(RTRIM(@tvchar))
If @tvchar <> '' and (@tvchar is not null)
  Begin
    Select @tID = CONVERT(integer, @tvchar)
    If 1 = 1 
    Begin
      Insert into #RoleIdList (RoleUserId) values (@tID)
    End
  End
Create Table #User_Security (
 	 UserId int NOT NULL,
 	 GroupId int NOT NULL,
 	 AccessLevel tinyint NOT NULL)
--Build temporary table of what the new user_security table will look like for this user (For all applicable Roles)
Insert into #User_Security (UserId, GroupId, AccessLevel)
  Select Distinct @User_Id, us.Group_Id, us.Access_Level 
    From User_Role_Security urs
      Join User_Security us on us.User_Id = urs.Role_User_Id
        Where urs.User_Id = @User_Id
Insert into #User_Security (UserId, GroupId, AccessLevel)
  Select Distinct @User_Id, us.Group_Id, us.Access_Level
    From User_Security us
      Join #RoleIdList r on r.RoleUserId = us.User_Id
If (Select count(*) from #User_Security) = 0
  Begin
    Insert into #User_Security (UserId, GroupId, AccessLevel)
 	 Select @User_Id, us.Group_Id, us.Access_Level
 	   From User_Security us
 	     Join User_Role_Security ur on ur.User_Id = @User_Id
 	     Where us.User_Id = ur.Role_User_Id
  End
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
--Add any new Groups this User did not previously have access to
Insert into User_Security (User_Id, Group_Id, Access_Level)
  Select UserId, GroupId, Max(AccessLevel)
   From #User_Security
    Where GroupId not in (Select Group_Id from User_Security Where User_Id = @User_Id)
    Group by UserId,GroupId
Drop Table #User_Security
