Create Procedure dbo.spDBR_Get_Report_Parameters
@report_id int,
@lanugageid int = 0
AS
 	 declare @template_id int
 	 
 	 set @template_id = (select dashboard_template_id from dashboard_reports where dashboard_report_id = @report_id)
 	 select tp.dashboard_template_parameter_id, 
 	  	  	 case when isnumeric(tp.dashboard_template_parameter_name) = 1 then (dbo.fnDBTranslate(@lanugageid, tp.dashboard_template_parameter_name, tp.dashboard_template_parameter_name)) 
 	  	  	 else (tp.dashboard_template_parameter_name)
 	  	  	 end as dashboard_template_parameter_name, 	 
 	  	  	 tp.dashboard_template_parameter_name as raw_name, 
 	  	  	 type.dashboard_parameter_type_desc, 
 	  	  	 dt.dashboard_parameter_data_type, 
 	  	  	 case when isnumeric(dia.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(@lanugageid, dia.dashboard_dialogue_name, dia.dashboard_dialogue_name)) 
 	  	  	 else (dia.dashboard_dialogue_name)
 	  	  	 end as dashboard_dialogue_name,
 	  	  	 tp.dashboard_parameter_type_id, 
 	  	  	 dia.dashboard_dialogue_id, 
 	  	  	 tp.dashboard_template_parameter_order,
 	  	  	 tp.has_default_value,
 	  	  	 type.value_type,
 	  	  	 tp.allow_nulls
/*,
 	  	  	 i.dashboard_icon_name,
 	  	  	 i.dashboard_icon
 	 */ 	  	 
 	  	 from  dashboard_template_parameters tp, dashboard_parameter_data_types dt,
 	 dashboard_parameter_types type, dashboard_dialogues dia, dashboard_template_dialogue_parameters dtdp/*,
 	 dashboard_icons i
*/
 	 where
 	 /* 	 i.dashboard_icon_id = type.dashboard_icon_id
 	  	 and */type.dashboard_parameter_data_type_id = dt.dashboard_parameter_data_type_id 
 	  	 and tp.dashboard_parameter_type_id = type.dashboard_parameter_type_id 
 	  	 and tp.dashboard_template_parameter_id = dtdp.dashboard_template_parameter_id
 	  	 and dtdp.dashboard_dialogue_id = dia.dashboard_dialogue_id 
 	  	 and tp.dashboard_template_id = @template_id
 	 order by tp.dashboard_template_parameter_order
 	 
