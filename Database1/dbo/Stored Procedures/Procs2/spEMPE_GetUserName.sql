Create Procedure dbo.spEMPE_GetUserName
@ID int,
@User_Id int
AS
Select Username from Users
where User_Id = @ID
