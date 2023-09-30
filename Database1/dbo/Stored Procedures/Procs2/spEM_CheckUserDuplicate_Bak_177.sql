CREATE PROCEDURE dbo.[spEM_CheckUserDuplicate_Bak_177] 
  @DomainUserName nvarchar(30),
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
