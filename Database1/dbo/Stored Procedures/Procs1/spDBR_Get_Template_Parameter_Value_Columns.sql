Create Procedure dbo.spDBR_Get_Template_Parameter_Value_Columns
@parameterid int = 189
AS
 	 
 	  	 
 	  	 /*this query fills in the column procs table with the cell identifier and sp name to run*/
 	  	 
 	  	 select distinct h.dashboard_datatable_column
 	  	 from  	 dashboard_datatable_headers h,
 	  	 dashboard_template_parameters tp
 	  	 where h.dashboard_parameter_type_id  = tp.dashboard_parameter_type_id
 	  	 and tp.dashboard_template_parameter_id = @parameterid
 	  	 and h.dashboard_datatable_presentation = 0
 	  	 order by h.dashboard_datatable_column
 	  	 
 	 
 	 
