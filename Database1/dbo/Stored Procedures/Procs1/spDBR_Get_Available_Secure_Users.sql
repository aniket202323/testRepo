Create Procedure dbo.spDBR_Get_Available_Secure_Users
@currentuser varchar(30)
AS
 	 select user_id, username, password from users where not user_id in (select user_id from  dashboard_user_security_table) and system = 1 or username = @currentuser
