CREATE PROCEDURE dbo.spEM_CheckUserDuplicate 
  @DomainUserName nvarchar(200),
  @User           nvarchar(30) OUTPUT
  AS
  --
  -- Fetch the user data.
  --
  SELECT @User   = Coalesce(UserName, '')    
    FROM Users
    WHERE WindowsUserInfo = @DomainUserName
  if  @User is null
  BEGIN
    SELECT @User   = Coalesce(UserName, '')    
    FROM Users
    WHERE SSOUserId = @DomainUserName
  END 
  --
  -- Return success.
  --
  RETURN(0)
