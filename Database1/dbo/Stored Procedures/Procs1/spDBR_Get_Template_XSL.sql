Create Procedure dbo.spDBR_Get_Template_XSL
@TemplateID int
AS
declare @dashboard_template_xsl_filename varchar(100)
set @dashboard_template_xsl_filename = (select dashboard_Template_xsl_filename from dashboard_templates where dashboard_template_id = @TemplateID)
IF (@dashboard_template_xsl_filename = 'None')
begin
 	 select XSL as dashboard_template_xsl,XSL_Filename as dashboard_template_xsl_filename  from dashboard_default_xsl where xsl_id=1 
end
else
begin
select dashboard_template_xsl, dashboard_template_xsl_filename from dashboard_templates 
where dashboard_template_id = @TemplateID
end
