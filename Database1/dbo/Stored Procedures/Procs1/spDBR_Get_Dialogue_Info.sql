Create Procedure dbo.spDBR_Get_Dialogue_Info
@dialogueID int,
@paramid int
AS 	 select
 	 (select case when isnumeric(dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(N'0', dashboard_dialogue_name, dashboard_dialogue_name)) 
 	 else (dashboard_dialogue_name)
 	 end as dashboard_dialogue_name from dashboard_dialogues where dashboard_dialogue_id = @dialogueID) as dashboard_dialogue_name,
 	 (select dashboard_template_parameter_name from dashboard_template_parameters where dashboard_template_parameter_id = @paramid) as dashboard_template_parameter_name
