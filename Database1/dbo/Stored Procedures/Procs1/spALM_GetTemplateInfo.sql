CREATE PROCEDURE dbo.spALM_GetTemplateInfo
as
select distinct atd_id, action_required, cause_required from alarm_templates t
join alarm_template_var_data d on d.at_id = t.at_id
