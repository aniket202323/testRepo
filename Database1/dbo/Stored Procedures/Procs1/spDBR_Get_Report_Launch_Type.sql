Create Procedure dbo.spDBR_Get_Report_Launch_Type
@reportid int
AS
 	 declare @templateid int
 	 set @templateid = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	 select dashboard_template_launch_type from dashboard_templates where dashboarD_template_id = @templateid
