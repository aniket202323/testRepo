Create Procedure dbo.spDBR_Get_Template_Procedure
@TemplateID int
AS
select dashboard_template_procedure from dashboard_templates where  dashboard_template_id = @TemplateID
