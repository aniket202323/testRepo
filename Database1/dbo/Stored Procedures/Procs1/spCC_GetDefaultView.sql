CREATE PROCEDURE dbo.spCC_GetDefaultView
@UserId int,
@GroupId int OUTPUT,
@ViewToolbarVersion nvarchar(15) OUTPUT,
@ViewName nvarchar(50) OUTPUT, 
@ViewId int OUTPUT
 AS 
Declare @HasDefaultView int
Create Table #View (
GroupId int,
ViewToolbarVersion nvarchar(25),
ViewName nvarchar(50),
ViewId int
)
-- Determine if the User has a default view specified
Select @HasDefaultView = U.View_Id
  From Users U
  Where U.User_Id = @UserId
Insert Into #View
  Select V.Group_Id, Coalesce(V.Toolbar_Version, 'Menu Bar v0.00'), V.View_Desc, U.View_Id
    From Users U
      Join Views V on V.View_Id = U.View_Id 
      Join User_Security S on S.Group_Id = V.Group_Id
      Where U.User_Id = @UserId and S.User_Id = @UserId
    UNION
      Select V.Group_Id, Coalesce(V.Toolbar_Version, 'Menu Bar v0.00'), V.View_Desc, U.View_Id
        From Users U
          Inner Join Views V on V.View_Id = U.View_Id
          Where V.Group_Id = 0 or V.Group_Id is NULL and U.User_Id = @UserId
Select @ViewToolbarVersion = ViewToolbarVersion, @ViewName = ViewName, @ViewId = ViewId
  from #View
-- if the User doesn't belong to the group associated to their Default View, reset their Default view to nothing
If @ViewName Is NULL and @HasDefaultView <> ''
  Begin
    Update Users
      Set View_Id = NULL
      Where User_Id = @UserId
    Select @ViewName = "Invalid"
  End
if @HasDefaultView Is NULL --no view specified in users tabls
  Begin
    Select @ViewName = ''
  End
Drop Table #View  
RETURN
