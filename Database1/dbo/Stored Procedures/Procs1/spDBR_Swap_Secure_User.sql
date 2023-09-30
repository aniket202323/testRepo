Create Procedure dbo.spDBR_Swap_Secure_User
@olduid int,
@newuid int
AS
 	 update dashboard_user_Security_table set user_id = @newuid where user_id = @olduid 	 
