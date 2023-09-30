Create Procedure dbo.spDBR_Store_Gallery_Server
@ServerName varchar(50)
AS
declare @ServerCount int
set @ServerCount = (select count(Server) from Dashboard_Gallery_Generator_Servers where Server = @ServerName)
if (@ServerCount = 0)
begin
 	 insert into Dashboard_Gallery_Generator_Servers (Server) values(@ServerName)
end
