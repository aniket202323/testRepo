Create Procedure dbo.spDBR_Get_User_Info
@user varchar(50)
AS
 	 
 	 select COALESCE(password, password, '') as password from users where username = @user 
