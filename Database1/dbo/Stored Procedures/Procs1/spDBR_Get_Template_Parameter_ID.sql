Create Procedure dbo.spDBR_Get_Template_Parameter_ID
@TemplateID int,
@ParameterName varchar(100),
@LanguageId int = 0
AS
if (isnumeric(@ParameterName) = 1)
begin
 	 select dashboard_template_parameter_id, dashboard_template_parameter_name, 
 	 dbo.fnDBTranslate(@LanguageId, dashboard_template_parameter_name, dashboard_template_parameter_name) as parameter_name_text 
 	 from dashboard_template_parameters where dashboard_template_id = @templateid and dashboard_template_parameter_name = @parametername
end
else
begin
 	 select dashboard_template_parameter_id, dashboard_template_parameter_name, 
 	 case when isnumeric(dashboard_template_parameter_name) = 1 then (dbo.fnDBTranslate(@LanguageId, dashboard_template_parameter_name, dashboard_template_parameter_name)) 
 	 else (dashboard_template_parameter_name)
 	 end as parameter_name_text
 	 from dashboard_template_parameters 
 	 where dashboard_template_id = @templateid and 
 	 case when isnumeric(dashboard_template_parameter_name) = 1 then (dbo.fnDBTranslate(@LanguageId, dashboard_template_parameter_name, dashboard_template_parameter_name)) 
 	 else (dashboard_template_parameter_name)
 	 end  = @parametername
end
