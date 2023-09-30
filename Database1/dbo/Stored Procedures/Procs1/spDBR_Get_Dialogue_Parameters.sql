Create Procedure dbo.spDBR_Get_Dialogue_Parameters
@dialog_id int
AS
 	 select distinct(pt.Dashboard_Parameter_Type_ID), 
 	  	  	 case when isnumeric(dashboard_parameter_type_desc) = 1 then (dbo.fnDBTranslate(N'0', dashboard_parameter_type_desc, dashboard_parameter_type_desc) + ' v.' + Convert(varchar(7), version)) 
 	  	  	 else (dashboard_parameter_type_desc )
 	  	  	 end as dashboard_parameter_type_desc,
 	 
 	 (select count(t.dashboard_template_parameter_id) from dashboard_template_parameters t where t.dashboard_parameter_type_id = pt.dashboard_parameter_type_id) as Dependencies  
 	  from dashboard_parameter_types pt, dashboard_dialogue_parameters d
 	  	 where d.dashboard_dialogue_id = @dialog_id and pt.dashboard_parameter_type_id = d.dashboard_parameter_type_id 
order by dashboard_parameter_type_desc
