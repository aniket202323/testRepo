Create Procedure dbo.spDBR_Delete_Gallery_Server
@ServerName varchar(50)
AS
 	 delete from dashboard_Gallery_Generator_Servers where Server = @ServerName
