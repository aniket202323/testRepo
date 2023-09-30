Create Procedure dbo.spDBR_Get_Parameter_Columns
@parameter_id int
AS
 	 select dashboard_datatable_header_id, dashboard_datatable_column, 
 	  	 case when isnumeric(dashboard_datatable_header) = 1 then (dbo.fnDBTranslate(N'0', dashboard_datatable_header, dashboard_datatable_header) + ' [Prompt# ' + dashboard_datatable_header + ']') 
 	  	 else (dashboard_datatable_header)
 	  	 end as dashboard_datatable_header,
 	  	 dashboard_datatable_header as raw_header,
 	  	 dashboard_datatable_presentation, dashboard_datatable_column_sp
 	 from dashboard_datatable_headers where dashboard_parameter_type_id = @parameter_id order by dashboard_datatable_column
 	 
 	 
