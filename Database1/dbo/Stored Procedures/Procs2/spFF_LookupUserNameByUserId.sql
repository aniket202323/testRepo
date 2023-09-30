Create Procedure dbo.spFF_LookupUserNameByUserId
  @User_Id int,
  @UserName nVarChar(30) OUTPUT AS
  SELECT @UserName = u.username
    From Users u
     WHERE u.User_Id = @User_Id
