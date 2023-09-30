Create Procedure dbo.spCC_UpdateUserDefault
  @ViewId int,
  @UserId int
 AS 
  Update Users
    Set View_Id = @ViewId
    Where User_Id = @UserId
