Create Procedure dbo.spDBR_Update_Template_XSL
@dashboard_template_id int,
@dashboard_template_xsl_filename varchar(100),
@dashboard_template_xsl text
AS
 	 if @dashboard_template_xsl_filename = '' 
 	 begin
 	  	 update dashboard_templates set dashboard_template_xsl_filename = 'None', dashboard_template_xsl = 'None' where dashboard_template_id = @dashboard_template_id 	  
 	 end
 	 else
 	 begin
 	  	 update dashboard_templates set dashboard_template_xsl_filename = @dashboard_template_xsl_filename, dashboard_template_xsl = @dashboard_template_xsl where dashboard_template_id = @dashboard_template_id 	  
 	 end
