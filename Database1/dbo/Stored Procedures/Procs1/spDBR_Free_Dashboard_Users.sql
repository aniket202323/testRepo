Create Procedure dbo.spDBR_Free_Dashboard_Users
@dashboard_key varchar(1000)
AS
-- 	 set @dashboard_key = (select replace(@dashboard_key, '{', ''))
-- 	 set @dashboard_key = (select replace(@dashboard_key, '}', ''))
 	 
 	 delete from dashboard_users where dashboard_key = @dashboard_key
