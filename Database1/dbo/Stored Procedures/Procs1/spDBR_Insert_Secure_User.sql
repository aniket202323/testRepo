Create Procedure dbo.spDBR_Insert_Secure_User
@uid int,
@securitylevel int
AS
 	 insert into dashboard_user_Security_table (user_id, security_level) values(@uid, @securitylevel)
 	 
