Create Procedure dbo.spDBR_Get_Proficy_System_Users
AS
 	 select user_id, username, password from users where system = 1
