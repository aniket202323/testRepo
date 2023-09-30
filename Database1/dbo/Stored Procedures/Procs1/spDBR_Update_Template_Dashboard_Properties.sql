Create Procedure dbo.spDBR_Update_Template_Dashboard_Properties
@dashboard_template_id int,
@dashboard_template_description varchar(4000),
@dashboard_template_column int,
@dashboard_template_column_position int,
@dashboard_template_has_frame int,
@dashboard_template_expanded int,
@dashboard_template_allow_remove int,
@dashboard_template_allow_minimize int,
@dashboard_template_cache_code int,
@dashboard_template_cache_timeout int,
@fixedheight bit,
@fixedwidth bit,
@height int,
@width int
AS
 	 update dashboard_templates set dashboard_template_description = @dashboard_template_description, 
 	  	  	  	  	  	  	  	  	 dashboard_template_column = @dashboard_template_column,
 	  	  	  	  	  	  	  	  	 dashboard_template_column_position = @dashboard_template_column_position,
 	  	  	  	  	  	  	  	  	 dashboard_template_has_frame = @dashboard_template_has_frame,
 	  	  	  	  	  	  	  	  	 dashboard_template_expanded = @dashboard_template_expanded,
 	  	  	  	  	  	  	  	  	 dashboard_template_allow_remove = @dashboard_template_allow_remove,
 	  	  	  	  	  	  	  	  	 dashboard_template_allow_minimize = @dashboard_template_allow_minimize,
 	  	  	  	  	  	  	  	  	 dashboard_template_cache_code = @dashboard_template_cache_code,
 	  	  	  	  	  	  	  	  	 dashboard_template_cache_timeout = @dashboard_template_cache_timeout,
 	  	  	  	  	  	  	  	  	 dashboard_templatE_fixed_height = @fixedheight,
 	  	  	  	  	  	  	  	  	 dashboard_template_fixed_width = @fixedwidth,
 	  	  	  	  	  	  	  	  	 height = @height,
 	  	  	  	  	  	  	  	  	 width = @width,
 	  	  	  	  	  	  	  	  	 dashboard_template_size_unit = 5
 	  	  	  	  	  	  	  	  	 where dashboard_template_id = @dashboard_template_id
 	   
