Create Procedure dbo.spDBR_Get_User_ID
@user varchar(50) = 'ComXClient'
AS
declare @@uid int 	 
 	 select @@uid = user_id from users where username = @user 
select @@uid as UserId
return @@uid
