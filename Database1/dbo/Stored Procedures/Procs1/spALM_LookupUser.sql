Create Procedure dbo.spALM_LookupUser
@UserId int, 
@UserName nvarchar(50) OUTPUT
AS
Select @UserName = UserName from Users Where User_Id = @UserId
