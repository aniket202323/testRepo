CREATE PROCEDURE dbo.spEM_GetUserData 
  @User_Id   int,
  @User_Desc nvarchar(50) OUTPUT,
  @Password  nvarchar(30) OUTPUT,
  @UserView  Int Output
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
  SELECT @Id        = User_Id,
         @User_Desc = User_Desc,
         @Password  = Password,
 	  @UserView  = View_Id
    FROM Users
    WHERE User_Id = @User_Id
  IF @Id IS NULL RETURN(1)
  --
  -- Return success.
  --
  RETURN(0)
