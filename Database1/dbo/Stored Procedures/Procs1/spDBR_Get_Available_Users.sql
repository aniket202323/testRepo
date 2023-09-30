Create Procedure dbo.spDBR_Get_Available_Users
AS
 	 declare @dashboard_user_count int
 	 set @dashboard_user_count = (select count(Dashboard_User_ID) from Dashboard_Users)
 	 
 	 if (@dashboard_user_count > 0)
 	 begin
 	  	 select u.user_id, u.username from users u where u.system=0 and  not(u.user_id in (select du.user_id from dashboard_users du where du.user_id = u.user_id))
 	 end
 	 else
 	 begin
 	  	 select user_id, username from users where system = 0
 	 end
 	 
