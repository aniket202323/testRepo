Create Procedure dbo.spDBR_Get_Available_Dialogue_Types
@parameter_type_id int
AS
 	 
 	 
 	 select d.dashboard_dialogue_id, 
 	 case when isnumeric(d.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(N'0', d.dashboard_dialogue_name, d.dashboard_dialogue_name)  + ' v.' + Convert(varchar(7), d.version)) 
 	 else (d.dashboard_dialogue_name + ' v.' + Convert(varchar(7), d.version))
 	 end as dashboard_dialogue_name
from dashboard_dialogues d, dashboard_dialogue_parameters dp where d.dashboard_dialogue_id = dp.dashboard_dialogue_id and dp.dashboard_parameter_type_id = @parameter_type_id 	  	  
 	  	 order by d.dashboard_dialogue_name
 	 
