Create Procedure dbo.spDBR_Get_Secure_Users
AS
 	 select u.user_id, u.username, s.security_level from users u, dashboard_user_security_table s where u.user_id=s.user_id order by s.security_level desc
 	 
