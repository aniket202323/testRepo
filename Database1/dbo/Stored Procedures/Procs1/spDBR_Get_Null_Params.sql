Create Procedure dbo.spDBR_Get_Null_Params
@reportid int,
@filtercode int = 0
AS
 	 if (@filtercode = 0)
 	 begin 	  	 
 	  	 select p.dashboard_template_parameter_id, p.dashboard_template_parameter_order, d.dashboard_dialogue_id,  	 
 	  	 case when isnumeric(dd.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(N'0', dd.dashboard_dialogue_name, dd.dashboard_dialogue_name)) 
 	 else (dd.dashboard_dialogue_name)
 	 end as dashboard_dialogue_name 	  	 
 	  	 from dashboard_template_parameters p, dashboard_template_dialogue_parameters d, dashboard_dialogues dd
 	  	 where p.dashboard_template_parameter_id = d.dashboard_template_parameter_id
 	  	 and p.dashboard_template_id = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	  	 and p.dashboard_template_parameter_id not in (select pv.dashboard_template_parameter_id from dashboard_parameter_values pv where pv.dashboard_report_id = @reportid)
 	  	 and d.dashboard_dialogue_id = dd.dashboard_dialogue_id and p.allow_nulls = 0
 	 end
 	 else
 	 begin
 	  	 select p.dashboard_template_parameter_id, p.dashboard_template_parameter_order, d.dashboard_dialogue_id, 
 	  	 case when isnumeric(dd.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(N'0', dd.dashboard_dialogue_name, dd.dashboard_dialogue_name)) 
 	 else (dd.dashboard_dialogue_name)
 	 end as dashboard_dialogue_name 	  	 
 	  	 from dashboard_template_parameters p, dashboard_template_dialogue_parameters d, dashboard_dialogues dd
 	  	 where p.dashboard_template_parameter_id = d.dashboard_template_parameter_id
 	  	 and p.dashboard_template_id = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @reportid)
 	  	 and p.dashboard_template_parameter_id not in (select pv.dashboard_template_parameter_id from dashboard_parameter_values pv where pv.dashboard_report_id = @reportid)
 	  	 and d.dashboard_dialogue_id = dd.dashboard_dialogue_id
 	 end
