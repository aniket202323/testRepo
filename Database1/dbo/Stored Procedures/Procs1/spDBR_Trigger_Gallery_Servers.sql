Create Procedure dbo.spDBR_Trigger_Gallery_Servers
@ServerName varchar(50)
AS
 	 if (@ServerName = '')
 	 begin
 	  	 update dashboard_gallery_generator_servers set dirtybit = 1
 	 end
 	 else
 	 begin
 	  	 update dashboard_gallery_generator_servers set dirtybit = 1 where server = @servername
 	 end
