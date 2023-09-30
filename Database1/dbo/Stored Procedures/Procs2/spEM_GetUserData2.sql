CREATE PROCEDURE dbo.spEM_GetUserData2 
  @User_Id   int,
  @User_Desc nvarchar(50) OUTPUT,
  @Password  nvarchar(30) OUTPUT,
  @Active bit OUTPUT,
  @UserView Int OUTPUT,
  @WindowsLoginInfo nvarchar(30) OUTPUT,
  @RoleBased bit OUTPUT,
  @MixedMode bit OUTPUT,
  @UseSSO bit OUTPUT,
  @SSOUserId nvarchar(50) OUTPUT,
  @ReturnResults Int = 1
  AS
  --
  -- Return Codes:
  --
  --   0 = Success.
  --   1 = User not found.
  --
  -- Declare local variables.
  --
  DECLARE @Id int
  --
  -- Fetch the user data.
  --
  SELECT @Id     = User_Id,
         @User_Desc = User_Desc,
         @Password  = Password,
 	  	  @Active = Active,
 	  	  @UserView = View_Id,
 	  	  @WindowsLoginInfo =WindowsUserInfo,
 	  	  @RoleBased =Role_Based_Security,
 	  	  @MixedMode =Mixed_Mode_Login,
 	  	  @UseSSO=UseSSO,
 	  	  @SSOUserId =SSOUserId
    FROM Users
    WHERE User_Id = @User_Id
  IF @Id IS NULL RETURN(1)
    IF  @ReturnResults = 1
    BEGIN
    --Return info to refresh the tree for this user (Role based security)
      Select User_Role_Security_Id, Role_User_Id, User_Id, GroupName 
        From User_Role_Security
          Where User_Id = @User_Id
    --Return into to refresh the tree for this user (Group based security)
      Select Security_Id, User_Id, Group_Id, Access_Level
        From User_Security
          Where User_Id = @User_Id
    END
  --
  -- Return success.
  --
  RETURN(0)
