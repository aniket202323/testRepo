Create Procedure dbo.spDBR_Validate_User
@username varchar(50),
@password varchar(50)
AS
 	 declare @userid int
 	 declare @dbuid int
 	 declare @sessionid int
 	 
 	 set @userid = (select user_id from users where Username = @username and Password = @password)
 	 set @dbuid = (select dashboard_user_id from dashboard_users where user_id=@userid)
 	 
 	 if (not @userid is null)
 	 begin
-- 	  	 set @sessionid = (select dashboard_session_id from dashboard_session where dashboard_user_id = @dbuid)
-- 	  	 if (@sessionid is null)
-- 	  	  	 begin
 	  	  	 
 	  	  	 
-- 	  	  	 
-- 	  	  	  	 insert into dashboard_session (Dashboard_User_ID,Dashboard_Session_Start_Date) values (@dbuid, dbo.fnServer_CmnGetDate(getutcdate()))
-- 	  	  	  	 set @sessionid = (select dashboard_session_id from dashboard_session where dashboard_user_id = @dbuid)
-- 	  	  	 end
-- 	  	 else
-- 	  	  	 begin
-- 	  	  	  	 update dashboard_session set dashboard_session_Start_date = dbo.fnServer_CmnGetDate(getutcdate()) where dashboard_session_id = @sessionid
-- 	  	  	 end 	  	 
 	  	 --, @sessionid as dashboard_session_id 
 	  	 select dashboard_key, SecurityLevel, @dbuid as user_id from dashboard_users where user_id = @userid
 	 end
