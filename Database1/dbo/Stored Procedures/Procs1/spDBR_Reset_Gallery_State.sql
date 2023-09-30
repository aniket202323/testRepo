Create Procedure dbo.spDBR_Reset_Gallery_State
@ServerName varchar(50)
AS
 	 update dashboard_gallery_generator_servers set dirtybit = 0 where server = @servername
