Create Procedure dbo.spEMPE_GetAllUsers
@User_Id int
AS
select User_Id, Username from Users where System = 0 and Is_Role = 0
Order by Username
