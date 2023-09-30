Create Procedure dbo.spDBR_Get_Report_XSL_FileName
@ReportID int
AS
 	 declare @TemplateID int
 	 set @TemplateID = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	 select dashboard_template_xsl_filename from dashboard_templates where dashboard_template_id = @templateid
