Create Procedure dbo.spDBR_Get_Report_Gallery_Server
@reportid int
AS
select dashboard_report_server as server from dashboard_reports where dashboard_report_id = @reportid
 	  	 
