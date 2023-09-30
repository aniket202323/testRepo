Create Procedure dbo.spDBR_Get_Parameter_Type_Dialogues
@parameter_type_id int
AS
 	 select dp.dashboard_dialogue_parameter_id,d.dashboard_dialogue_id,dp.default_dialogue, 
 	 case when isnumeric(d.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(N'0', d.dashboard_dialogue_name, d.dashboard_dialogue_name)  + ' v.' + Convert(varchar(7), d.version)) 
 	 else (d.dashboard_dialogue_name + ' v.' + Convert(varchar(7), d.version))
 	 end as dashboard_dialogue_name,
(select count(dtp.dashboard_template_dialogue_parameter_id)
 	 from dashboard_template_dialogue_parameters dtp,
 	 dashboard_template_parameters tp
 	 where dtp.dashboard_template_parameter_id = tp.dashboard_template_parameter_id
 	 and dtp.dashboard_dialogue_id = d.dashboard_dialogue_id
 	 and tp.dashboard_parameter_type_id = @parameter_type_id) as Usage_Count 	 
 	 from dashboard_dialogue_parameters dp, dashboard_dialogues d
 	 where dp.dashboard_dialogue_id = d.dashboard_dialogue_id
 	 and dp.dashboard_parameter_type_id = @parameter_type_id 	  
