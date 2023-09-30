Create Procedure dbo.spDBR_Get_All_Parameters
AS
 	 select p.dashboard_parameter_type_id, 
 	  	 case when isnumeric(p.dashboard_parameter_type_desc) = 1 then (dbo.fnDBTranslate(N'0', p.dashboard_parameter_type_desc, p.dashboard_parameter_type_desc) + ' [Prompt# ' + p.dashboard_parameter_type_desc + ']') 
 	  	 else (p.dashboard_parameter_type_desc)
 	  	 end as dashboard_parameter_type_desc,
 	  	 p.dashboard_parameter_type_desc as raw_desc,
 	  	 d.dashboard_parameter_data_type, p.locked,
 	 (select count(h.dashboard_datatable_header_id) from dashboard_datatable_headers h where h.dashboard_parameter_type_id = p.dashboard_parameter_type_id) as NumberColumns, p.version,
 	 (select count(dashboard_template_parameter_id) as Parameter_Use_Count  from dashboard_template_parameters
 	 where dashboard_parameter_type_id = p.dashboard_parameter_type_id) as Usage_Count, p.value_type
 	 from dashboard_parameter_types p, dashboard_parameter_data_types d  where p.dashboard_parameter_data_Type_id = d.dashboard_parameter_data_type_id order by p.dashboard_parameter_type_desc
 	 
