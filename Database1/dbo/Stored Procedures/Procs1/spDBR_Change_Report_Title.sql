Create Procedure dbo.spDBR_Change_Report_Title
@ReportID int,
@ReportTitle varchar(100)
AS
update dashboard_reports set dashboard_report_name = @ReportTitle where dashboard_report_id = @reportid
