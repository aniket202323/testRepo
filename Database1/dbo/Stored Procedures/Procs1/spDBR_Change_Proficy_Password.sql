Create Procedure dbo.spDBR_Change_Proficy_Password
@user_id int,
@password varchar(30)
AS
 	 update users set password = @password where user_id = @user_id
