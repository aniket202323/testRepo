Create Procedure dbo.spDBR_Update_Template
@dashboard_template_id int,
@dashboard_template_name varchar(100),
@dashboard_template_stored_proc varchar(100),
@dashboard_template_launch_type int,
@Version int,
@TemplateType int,
@XSL_FileName varchar(100),
@BaseTemplate bit = 1
AS
 	 declare @count int
 	 set @count =  (select count(dashboard_template_id) from dashboard_templates where dashboard_template_name = @dashboard_template_name and not dashboard_template_id = @dashboard_Template_id and version = @version)
 	 if (@count > 0)
 	 begin
 	  	 set @version = (select version from dashboard_templates where dashboard_template_id = @dashboard_template_id)
 	  	 /*(select max(version) from dashboard_templates where dashboard_template_name = @dashboard_template_name) + 1*/
 	 end
 	 
 	 update dashboard_templates set dashboard_template_name = @dashboard_template_name,dashboard_template_procedure = @dashboard_template_stored_proc,
 	 dashboard_template_launch_type = @dashboard_template_launch_type, version = @Version, type = @templateType,
 	 dashboard_template_xsl_filename = @XSL_FileName, BaseTemplate = @BaseTemplate 	 
 	  where dashboard_template_id = @dashboard_template_id
