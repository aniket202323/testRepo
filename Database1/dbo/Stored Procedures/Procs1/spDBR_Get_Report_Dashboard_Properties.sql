Create Procedure dbo.spDBR_Get_Report_Dashboard_Properties
@reportid int
AS 	 
 	 select dashboard_report_description, 
 	        dashboard_report_column, 
 	        dashboard_report_column_position, 
 	        dashboard_report_has_frame, 
 	        dashboard_report_expanded,
 	        dashboard_report_allow_remove,
 	        dashboard_report_allow_minimize,
 	        dashboard_report_cache_code,
 	        dashboard_report_cache_timeout,
 	        dashboard_report_detail_link,
 	        dashboard_report_help_link
 	         from dashboard_reports where  dashboard_report_id = @reportid
