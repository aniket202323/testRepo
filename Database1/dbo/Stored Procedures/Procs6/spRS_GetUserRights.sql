CREATE PROCEDURE dbo.spRS_GetUserRights
@User_Id int
 AS
Declare @User int
Select @User = User_Id
From Report_Tree_Users
Where User_Id = @User_Id
IF @User is NULL
  BEGIN
    Return(1)
  END
Else
  BEGIN
    Select *
    From Report_Tree_Users
    Where User_Id = @User_Id
    Return(0)
  END
