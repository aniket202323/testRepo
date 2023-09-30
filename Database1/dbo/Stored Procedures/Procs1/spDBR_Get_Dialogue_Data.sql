Create Procedure dbo.spDBR_Get_Dialogue_Data
AS
 	 select d.dashboard_dialogue_id, 
case when isnumeric(d.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(N'0', d.dashboard_dialogue_name, d.dashboard_dialogue_name) + ' [Prompt# ' + d.dashboard_dialogue_name + ']') 
 	 else (d.dashboard_dialogue_name)
 	 end as dashboard_dialogue_name,
 	  	  	    d.URL, 
 	  	    d.Parameter_Count,
 	  	    d.locked,
 	  	   
 	  	    (select count(p.dashboard_dialogue_parameter_id) 
 	  	  	  	 from dashboard_dialogue_parameters p
 	  	  	  	  	 where p.dashboard_dialogue_id = d.dashboard_dialogue_id) as parameters_using,
 	  	  	 d.Version
 	  	  	 from dashboard_dialogues d
 	 order by d.dashboard_dialogue_name, d.version
