Create Procedure dbo.spDBR_Get_Available_Dialogue_Associations
AS 
 	 select d.dashboard_dialogue_id, 
 	 case when isnumeric(d.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(N'0', d.dashboard_dialogue_name, d.dashboard_dialogue_name)  + ' v.' + Convert(varchar(7), d.version)) 
 	 else (d.dashboard_dialogue_name + ' v.' + Convert(varchar(7), d.version))
 	 end as dashboard_dialogue_name
 	 from dashboard_dialogues d order by d.dashboard_dialogue_name
