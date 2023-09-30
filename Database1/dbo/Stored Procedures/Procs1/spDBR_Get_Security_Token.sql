Create Procedure dbo.spDBR_Get_Security_Token
@security_level int
AS
 	 declare @userid int
 	 set @userid = (select user_id from dashboard_user_security_table where security_level = @security_level)
 	 select username, password from users where user_id = @userid 	 
