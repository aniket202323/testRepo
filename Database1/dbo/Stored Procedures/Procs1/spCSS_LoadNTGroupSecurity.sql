CREATE PROCEDURE dbo.spCSS_LoadNTGroupSecurity 
AS
--Select all Windows User Groups that are Members of Security Roles only if the Role is a Member of a User Group
--Ya Got that?
Select Distinct GroupName, Role_User_Id
  From User_Role_Security ur
    Join User_Security us on us.User_Id = ur.Role_User_Id
    Where ur.User_Id is NULL
