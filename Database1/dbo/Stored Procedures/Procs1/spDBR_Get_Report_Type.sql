Create Procedure dbo.spDBR_Get_Report_Type
@ReportID int
AS
select dashboard_report_ad_hoc_flag from dashboard_reports where dashboard_report_id = @reportid 
 	  	  	 
