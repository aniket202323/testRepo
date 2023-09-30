Create Procedure dbo.spDBR_Update_Template_Icon
@dashboard_template_id int,
@dashboard_template_icon_filename varchar(100),
@dashboard_template_icon_file varchar(500)
AS
 	 update dashboard_templates set dashboard_template_preview_filename = @dashboard_template_icon_filename, dashboard_template_preview = @dashboard_template_icon_file where dashboard_template_id = @dashboard_template_id 	  
