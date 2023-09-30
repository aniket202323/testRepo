Create Procedure dbo.spDBR_Get_Dialogue
@dialogueID int
AS 	 
 	 select  	 case when isnumeric(dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(N'0', dashboard_dialogue_name, dashboard_dialogue_name)) 
 	 else (dashboard_dialogue_name)
 	 end as dashboard_dialogue_name
, external_address, url, parameter_count, version from dashboard_dialogues where dashboard_dialogue_id = @dialogueid
