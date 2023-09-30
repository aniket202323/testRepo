Create Procedure dbo.spDBR_Get_Template_Parameters
@template_id int,
@languageid int
AS
 	 select tp.dashboard_template_parameter_id, 
 	  	 case when isnumeric(tp.dashboard_template_parameter_name) = 1 then (dbo.fnDBTranslate(@languageid, tp.dashboard_template_parameter_name, tp.dashboard_template_parameter_name)) 
 	  	 else (tp.dashboard_template_parameter_name)
 	  	 end as dashboard_template_parameter_name, 	 
 	  	  	 tp.dashboard_template_parameter_name as raw_name, 
 	  	  	 case when isnumeric(type.dashboard_parameter_type_desc) = 1 then (dbo.fnDBTranslate(@languageid, type.dashboard_parameter_type_desc, type.dashboard_parameter_type_desc) + ' v.' + Convert(varchar(7), type.version)) 
 	  	  	 else (type.dashboard_parameter_type_desc + ' v.' + Convert(varchar(7), type.version))
 	  	  	 end as dashboard_parameter_type_desc,
 	  	  	 dt.dashboard_parameter_data_type, 
 	  	  	 case when isnumeric(dia.dashboard_dialogue_name) = 1 then (dbo.fnDBTranslate(@languageid, dia.dashboard_dialogue_name, dia.dashboard_dialogue_name)) 
 	  	  	 else (dia.dashboard_dialogue_name)
 	  	  	 end as dashboard_dialogue_name,
 	  	  	 tp.dashboard_parameter_type_id, 
 	  	  	 dia.dashboard_dialogue_id, 
 	  	  	 tp.dashboard_template_parameter_order,
 	  	  	 tp.has_default_value,
 	  	  	 type.value_type,
 	  	  	 tp.allow_nulls 	  	  	 
 	  	 from  dashboard_template_parameters tp, dashboard_parameter_data_types dt,
 	 dashboard_parameter_types type, dashboard_dialogues dia, dashboard_template_dialogue_parameters dtdp
 	 where
 	  	 type.dashboard_parameter_data_type_id = dt.dashboard_parameter_data_type_id 
 	  	 and tp.dashboard_parameter_type_id = type.dashboard_parameter_type_id 
 	  	 and tp.dashboard_template_parameter_id = dtdp.dashboard_template_parameter_id
 	  	 and dtdp.dashboard_dialogue_id = dia.dashboard_dialogue_id 
 	  	 and tp.dashboard_template_id = @template_id
 	 order by tp.dashboard_template_parameter_order
 	 
