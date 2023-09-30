Create Procedure dbo.spDBR_Delete_User
@dashboard_user_id int
AS
 	 delete from dashboard_session where dashboard_user_id = @dashboard_user_id
 	 delete from dashboard_users where dashboard_user_id = @dashboard_user_id 	 
