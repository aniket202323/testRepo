Create Procedure dbo.spDBR_Get_Available_Parameter_Types
AS
 	 select dashboard_parameter_type_id, 
 	  	  	 case when isnumeric(dashboard_parameter_type_desc) = 1 then (dbo.fnDBTranslate(N'0', dashboard_parameter_type_desc, dashboard_parameter_type_desc) + ' v.' + Convert(varchar(7), version)) 
 	  	  	 else (dashboard_parameter_type_desc + ' v.' + Convert(varchar(7), version))
 	  	  	 end as dashboard_parameter_type_desc
 	  	 from dashboard_parameter_types order by dashboard_parameter_type_Desc  
 	  	  
