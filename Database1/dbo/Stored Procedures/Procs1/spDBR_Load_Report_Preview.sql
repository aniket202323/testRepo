Create Procedure dbo.spDBR_Load_Report_Preview
@reportid int
AS
 	 declare @templateid int
 	 set @templateid = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	 select dashboard_template_preview_filename, dashboard_template_preview from dashboard_templates where dashboard_template_id = @templateid
 	 
