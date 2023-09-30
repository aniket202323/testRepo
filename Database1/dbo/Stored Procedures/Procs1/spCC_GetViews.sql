Create Procedure dbo.spCC_GetViews
  @User_Id int = NULL
 AS 
Declare @AdminToAdmin int
Select @AdminToAdmin = Count(*) from User_Security where User_Id = @User_Id and Group_Id = 1 and Access_Level = 4
Create Table #Views (
 View_Group_Id int, 
 View_Group_Desc nvarchar(50), 
 View_Id int, 
 View_Desc nvarchar(50),
 ToolBar_Version nvarchar(25),
 Group_Id int)
Insert Into #Views
  Select g.View_Group_id, View_Group_Desc, v.View_Id, v.View_Desc, Coalesce(v.Toolbar_Version, 'Menu Bar v0.00'), Coalesce(v.Group_Id,  g.Group_Id)
    From Views v 
    Join View_Groups g on g.View_Group_Id = v.View_Group_Id
If @AdminToAdmin = 1
  Begin
 	 Select 
 	  View_Group_Id , 
 	  View_Group_Desc, 
 	  View_Id , 
 	  View_Desc,
 	  ToolBar_Version,
 	  Group_Id
 	   from #Views
 	   Order by View_Group_Desc, View_Desc
 	 drop table #Views
  End
Else
  Begin
-- Retrieve only views that the user has access to
    Create Table #Groups (Group_Id int NULL)
    Insert Into #Groups (Group_Id)
      Select DISTINCT Group_Id
       From User_Security
       Where User_Id = @User_Id and Access_Level >=1
    Create Table #Views2 (
     View_Group_Id int, 
     View_Group_Desc nvarchar(50), 
     View_Id int, 
     View_Desc nvarchar(50),
     ToolBar_Version nvarchar(25),
     Group_Id int)
    Insert Into #Views2 (View_Group_Id, View_Group_Desc, View_Id, View_Desc, ToolBar_Version, Group_Id)
      Select View_Group_id, View_Group_Desc, View_Id, View_Desc, Toolbar_Version, Group_Id
        From #Views
         Where Group_Id is null
    Delete from #Views where Group_id is null
    Delete from #Views
      Where Group_Id not in (Select Group_Id from #Groups)
    --Remaining Views
    Insert Into #Views2 (View_Group_Id, View_Group_Desc, View_Id, View_Desc, ToolBar_Version, Group_Id)
      Select View_Group_id, View_Group_Desc, View_Id, View_Desc, Toolbar_Version, Group_Id
        From #Views
    Select 
     View_Group_Id , 
     View_Group_Desc, 
     View_Id, 
     View_Desc,
     ToolBar_Version,
     Group_Id
      from #Views2
      Order by View_Group_Desc, View_Desc
    Drop Table #Views
    Drop Table #Views2
    Drop Table #Groups
  End
  Select u.View_Id, v.View_Desc from Users u
    Join Views v on v.View_Id = u.View_Id
    where User_Id = @User_Id
