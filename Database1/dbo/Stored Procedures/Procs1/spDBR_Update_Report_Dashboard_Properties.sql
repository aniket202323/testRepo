Create Procedure dbo.spDBR_Update_Report_Dashboard_Properties
@dashboard_report_id int,
@dashboard_report_description varchar(4000),
@dashboard_report_column int,
@dashboard_report_column_position int,
@dashboard_report_has_frame int,
@dashboard_report_expanded int,
@dashboard_report_allow_remove int,
@dashboard_report_allow_minimize int,
@dashboard_report_cache_code int,
@dashboard_report_cache_timeout int
AS
 	 update dashboard_reports set dashboard_report_description = @dashboard_report_description,
 	  	  	  	  	  	  	  	  dashboard_report_column = @dashboard_report_column,
 	  	  	  	  	  	  	  	  dashboard_report_column_position = @dashboard_report_column_position,
 	  	  	  	  	  	  	  	  dashboard_report_has_frame = @dashboard_report_has_frame,
 	  	  	  	  	  	  	  	  dashboard_report_expanded = @dashboard_report_expanded,
 	  	  	  	  	  	  	  	  dashboard_report_allow_remove = @dashboard_report_allow_remove,
 	  	  	  	  	  	  	  	  dashboard_report_allow_minimize = @dashboard_report_allow_minimize,
 	  	  	  	  	  	  	  	  dashboard_report_cache_code = @dashboard_report_cache_code,
 	  	  	  	  	  	  	  	  dashboard_report_cache_timeout = @dashboard_report_cache_timeout
 	  	  	  	  	  	  	  	   where dashboard_report_id = @dashboard_report_id
 	   
