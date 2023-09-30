Create Procedure dbo.spDBR_Get_Report_Page
@ReportID int,
@Page int
AS
declare @timestamp datetime
set @timestamp = (select dashboard_time_stamp from dashboard_report_data where dashboard_report_id = @reportid and dashboard_report_version = 1)
select @timestamp as dashboard_time_stamp, page_xml from dashboard_report_data_pages where report_id = @reportid and report_page = @page
