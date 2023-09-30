Create Procedure dbo.spDBR_Get_Report_Title
@ReportID int
AS
select dashboard_report_name from dashboard_reports where dashboard_report_id = @reportid 
 	  	  	 
