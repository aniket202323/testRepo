Create Procedure dbo.spDBR_Get_Dashboard_Engine_Server
@UserID int,
@Node varchar(50)
AS
declare @server varchar(50)
set @server = ''
execute spServer_CmnGetParameter 165,@UserID, @Node, @server output
if (@server = '')
begin
 	 set @server= (select @@servername)
end
select @server as server
 	  	  	 
