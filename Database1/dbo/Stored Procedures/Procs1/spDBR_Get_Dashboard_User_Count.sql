Create Procedure dbo.spDBR_Get_Dashboard_User_Count
@dashboard_key varchar(1000)
AS
 	 
 	 select count(du.dashboard_user_id) as user_count from dashboard_users du, users u 
 	 where du.user_id = u.user_id and du.dashboard_key = @dashboard_key 
