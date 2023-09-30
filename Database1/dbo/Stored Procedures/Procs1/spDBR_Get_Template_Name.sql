Create Procedure dbo.spDBR_Get_Template_Name
@TemplateID int,
@LanguageId int = 0
AS
select 
 	 case when isnumeric(dashboard_template_name) = 1 then (dbo.fnDBTranslate(@LanguageId, dashboard_template_name, dashboard_template_name)) 
 	 else (dashboard_template_name)
 	 end as dashboard_template_name
 	 from dashboard_templates 
 	 where dashboard_template_id = @TemplateID
