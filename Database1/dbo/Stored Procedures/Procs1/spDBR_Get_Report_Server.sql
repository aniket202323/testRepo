Create Procedure dbo.spDBR_Get_Report_Server
@ReportID int
AS
declare @server varchar(50)
declare @port varchar(50)
declare @node varchar(50)
set @node = (select dashboard_Report_server from dashboard_Reports where dashboard_report_id = @reportid)
execute spServer_CmnGetParameter 161,33 , @node, @port output
execute spServer_CmnGetParameter 165,33 , @node, @server output
if (@server is null or @server = '')
begin
 	 set @server = @node
end
if(@server is null or @server = '')
begin
 	 set @server = (select @@servername)
end 
select @server as dashboard_report_Server, @port as adhoc_portnum, @node as dashboard_report_node
 	  	  	 
