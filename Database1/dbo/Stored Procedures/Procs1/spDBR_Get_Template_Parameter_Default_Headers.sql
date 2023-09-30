Create Procedure dbo.spDBR_Get_Template_Parameter_Default_Headers
@template_parameter_id int
AS
 	 
 	 
 	  	 
 	  	 /*this query fills in the column procs table with the cell identifier and sp name to run*/
 	  	 select 
 	  	 case when isnumeric(h.dashboard_datatable_header) = 1 then (dbo.fnDBTranslate(N'0', h.dashboard_datatable_header, h.dashboard_datatable_header)) 
 	  	 else (h.dashboard_datatable_header)
 	  	 end as dashboard_datatable_header,
 	  	 h.dashboard_datatable_presentation
 	  	 from  	 dashboard_datatable_headers h,
 	  	 dashboard_parameter_types pt, 
 	  	 dashboard_template_parameters tp
 	 
 	  	 where h.dashboard_parameter_type_id  = pt.dashboard_parameter_type_id 
 	  	 and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id 
 	  	 and tp.dashboard_template_parameter_id = @template_parameter_id 
 	  	 order by h.dashboard_datatable_column
 	  	 
 	 
 	 
