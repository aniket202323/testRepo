CREATE PROCEDURE dbo.spEM_GetDefaultView --  spEM_GetDefaultView  67
  @UserId Int,
  @ADGroupList varchar(7000)
  AS
Declare @IsAdmin Int
Declare @IsRole Int
--Parse the comma-sep list of AD group names into a Table
Create table #GroupList (GroupName varchar(max) NOT NULL)
declare @i integer
declare @tchar char
declare @tvchar varchar(max)
declare @GroupId integer
select @tvchar='' -- make SP work on 7.0
Select @i = 1 	  	     
Select @tchar = SUBSTRING (@ADGroupList, @i, 1)
While (@tchar <> '$')
  Begin
     If @tchar <> ','
       Select @tvchar = @tvchar + @tchar
     Else
       Begin
         Select @tvchar = LTRIM(RTRIM(@tvchar))
         If @tvchar <> '' 
           Begin
              if 1 = 1 
              Begin
               Insert into #GroupList (GroupName) values (@tvchar)
              End
           End
           If @tchar = ','
             Begin
 	        Select @tvchar = ''
 	      End
       End
     Select @i = @i + 1
     Select @tchar = SUBSTRING(@ADGroupList, @i, 1)
  End
 	  	 
Select @tvchar = LTRIM(RTRIM(@tvchar))
If @tvchar <> '' and (@tvchar is not null)
  Begin
    If 1 = 1 
    Begin
      Insert into #GroupList (GroupName) values (@tvchar)
    End
  End
DECLARE @RoleGroups Table (UserId Int)
select @IsRole = Role_Based_Security from Users where User_Id = @UserId 
If @IsRole = 0
BEGIN
 	 Select @IsAdmin = Access_Level
 	  	 From User_Security
 	  	 Where Access_Level = 4 and user_Id = @UserId and Group_Id = 1
END
Else
BEGIN
 	 INSERT INTO @RoleGroups(UserId)
 	  	 Select Role_User_Id from User_Role_Security Where User_Id = @UserId
 	 Select @IsAdmin = Access_Level
 	  	 From User_Security
 	  	 Where Access_Level = 4 and Group_Id = 1 and user_Id In (select UserId From  @RoleGroups)
END
Create Table #Views (View_Id int,View_Desc nvarchar(50))
If @IsAdmin is Null
BEGIN
 	 Create Table #Groups (Group_Id int NULL)
 	 IF @IsRole = 0
 	 BEGIN 
 	  	 Insert Into #Groups (Group_Id)
 	  	     Select DISTINCT Group_Id
 	  	      From User_Security
 	  	      Where User_Id = @UserId and Access_Level >=1
 	 END
 	 ELSE 
 	 BEGIN 
 	  	 Insert Into #Groups (Group_Id)
 	  	     Select DISTINCT Group_Id
 	  	      From User_Security
 	  	      Where User_Id  In (select UserId From  @RoleGroups) and Access_Level >=1
 	  	 Insert Into #Groups (Group_Id) 
 	  	   Select DISTINCT us.Group_Id from User_Role_Security urs
 	  	   join Users u on urs.Role_User_Id = u.User_Id
 	  	   join User_Security us on us.User_Id = u.User_Id
 	  	   join #GroupList gl on gl.GroupName = urs.GroupName
 	 END
   Insert Into #Views
    Select  v.View_Id, v.View_Desc
      From Views v 
      Join View_Groups g on g.View_Group_Id = v.View_Group_Id
      Join #Groups gr on gr.Group_Id = v.Group_Id 
    UNION 
    Select  v.View_Id, v.View_Desc
      From Views v 
      Join View_Groups g on g.View_Group_Id = v.View_Group_Id
       Where  v.Group_Id is Null
   End
Else
 Insert Into #Views Select  View_Id, View_Desc From Views
Select View_Id,View_Desc
  From #Views
  Order by View_Desc
drop table #GroupList
drop table #Groups
drop table #Views
