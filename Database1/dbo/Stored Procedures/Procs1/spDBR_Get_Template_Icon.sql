Create Procedure dbo.spDBR_Get_Template_Icon
@dashboard_template_id int
AS
 	 select dashboard_template_preview from dashboard_templates where dashboard_template_id = @dashboard_template_id 	  
