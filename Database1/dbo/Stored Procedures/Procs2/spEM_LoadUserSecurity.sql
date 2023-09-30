CREATE PROCEDURE dbo.spEM_LoadUserSecurity 
@User_Id int
AS
Select Security_Id,User_Id,Group_Id, Access_Level
    From User_Security
    Where User_Id = @User_Id
