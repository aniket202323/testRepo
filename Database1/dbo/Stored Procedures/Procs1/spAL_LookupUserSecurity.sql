/*Comment to test auto versioning */
Create Procedure dbo.spAL_LookupUserSecurity
  @UserId int  AS
  select * from user_security 
    where user_id = @UserId
