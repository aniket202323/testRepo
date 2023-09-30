Create Procedure dbo.spDBR_Get_Template_Dashboard_Properties
@templateid int
AS 	 
 	 select dashboard_template_description, 
 	        dashboard_template_column, 
 	        dashboard_template_column_position, 
 	        dashboard_template_has_frame, 
 	        dashboard_template_expanded,
 	        dashboard_template_allow_remove,
 	        dashboard_template_allow_minimize,
 	        dashboard_template_cache_code,
 	        dashboard_template_cache_timeout,
 	        dashboard_template_detail_link,
 	        dashboard_template_help_link
 	         from dashboard_templates where  dashboard_template_id = @templateid
