Create Procedure dbo.spDBR_Get_Template_ID
@TemplateName varchar(50),
@TemplateVersion int = 1,
@LanguageId int = 0
AS
select dashboard_template_id from dashboard_templates 
where 
case when isnumeric(dashboard_template_name) = 1 then (dbo.fnDBTranslate(@LanguageId, dashboard_template_name, dashboard_template_name)) 
else (dashboard_template_name)
end  = case when isnumeric(@TemplateName) = 1 then (dbo.fnDBTranslate(@LanguageId, @TemplateName, @TemplateName)) else (@TemplateName) end
and version = @templateversion
