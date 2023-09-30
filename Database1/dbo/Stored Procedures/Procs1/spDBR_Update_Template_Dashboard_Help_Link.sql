Create Procedure dbo.spDBR_Update_Template_Dashboard_Help_Link
@dashboard_template_id int,
@dashboard_template_help_link varchar(500)
AS
 	 if (@dashboard_template_help_link = '')
 	 begin
 	  	 update dashboard_templates set dashboard_template_help_link = null
 	  	  	  	  	  	  	  	  	 where dashboard_template_id = @dashboard_template_id 	 
 	 end
 	 else
 	 begin
 	  	 update dashboard_templates set dashboard_template_help_link = @dashboard_template_help_link
 	  	  	  	  	  	  	  	  	 where dashboard_template_id = @dashboard_template_id 	 
 	 end
 	   
