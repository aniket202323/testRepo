Create Procedure dbo.spDBR_Get_Template_Fixed_Size
@templateid int
AS 	 
 	 select dashboard_template_fixed_height, dashboard_template_fixed_width, height, width, dashboard_Template_size_unit from dashboard_templates where  dashboard_template_id = @templateid
