Create Procedure dbo.spAL_LookupUser
  @Username nvarchar(30)  AS
  Select * from users WITH (INDEX(username))
    where Username = @Username
