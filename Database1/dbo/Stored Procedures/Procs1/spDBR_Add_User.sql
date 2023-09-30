Create Procedure dbo.spDBR_Add_User
@user_id int,
@dashboard_key varchar(1000)
AS
 	 declare @dashboard_user_id int
 	 
 	 --set @dashboard_key = (select replace(@dashboard_key, '{', ''))
 	 --set @dashboard_key = (select replace(@dashboard_key, '}', ''))
 	 insert into dashboard_users (user_id, securitylevel, dashboard_key) values(@user_id, 0, @dashboard_key)
 	 
 	 set @dashboard_user_id = (select scope_identity())
 	 
 	 select @dashboard_user_id as id
 	 
