Create Procedure dbo.spDBR_Update_User
@dashboard_user_id int,
@securitylevel int
AS
 	 update dashboard_users set securitylevel= @securitylevel where dashboard_user_id = @dashboard_user_id 
