Create Procedure dbo.spDBR_Get_Dashboard_Users
@dashboard_key varchar(1000)
AS
-- 	 set @dashboard_key = (select replace(@dashboard_key, '{', ''))
-- 	 set @dashboard_key = (select replace(@dashboard_key, '}', ''))
 	 
 	 select du.dashboard_user_id, u.username, du.securitylevel, u.WindowsUserInfo from dashboard_users du, users u 
 	 where du.user_id = u.user_id and du.dashboard_key = @dashboard_key 
