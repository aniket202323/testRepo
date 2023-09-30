Create Procedure dbo.spDBR_Get_Report_Procedures
@ReportID int
AS
select t.dashboard_template_procedure, t.dashboard_template_id from dashboard_templates t,dashboard_reports r where r.dashboard_report_id = @ReportID and t.dashboard_template_id = r.dashboard_template_id
