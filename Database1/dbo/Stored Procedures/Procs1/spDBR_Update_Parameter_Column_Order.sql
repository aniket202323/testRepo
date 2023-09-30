Create Procedure dbo.spDBR_Update_Parameter_Column_Order
@datatable_header_id_1 int,
@datatable_header_id_2 int
AS
 	 declare @column_1 int
 	 declare @column_2 int
 	 
 	 set @column_1 = (select dashboard_datatable_column from dashboard_datatable_headers where dashboard_datatable_header_id = @datatable_header_id_1)
 	 set @column_2 = (select dashboard_datatable_column from dashboard_datatable_headers where dashboard_datatable_header_id = @datatable_header_id_2)
 	 
 	 
 	 /*update default values*/
 	 update dashboard_parameter_default_values set dashboard_parameter_column =-1
 	 where dashboard_parameter_column = @column_1 and dashboard_template_parameter_id in 
 	 (select tp.dashboard_template_parameter_id from dashboard_template_parameters tp, dashboard_parameter_types pt, dashboard_datatable_headers h
 	 where tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and dashboard_template_parameter_id = tp.dashboard_template_parameter_id
 	 and h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and h.dashboard_datatable_header_id = @datatable_header_id_1)
update dashboard_parameter_default_values set dashboard_parameter_column = -2
 	 where dashboard_parameter_column = @column_2 and dashboard_template_parameter_id in 
 	 (select tp.dashboard_template_parameter_id from dashboard_template_parameters tp, dashboard_parameter_types pt,  dashboard_datatable_headers h
 	 where tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and dashboard_template_parameter_id = tp.dashboard_template_parameter_id
 	 and h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and h.dashboard_datatable_header_id = @datatable_header_id_1)
 	 update dashboard_parameter_default_values set dashboard_parameter_column = @column_2 where dashboard_parameter_column = -1
 	 update dashboard_parameter_default_values set dashboard_parameter_column = @column_1 where dashboard_parameter_column = -2
 	 /*update dashboard_parameter_values*/
 	  	 update dashboard_parameter_values set dashboard_parameter_column =-1
 	 where dashboard_parameter_column = @column_1 and dashboard_template_parameter_id in 
 	 (select tp.dashboard_template_parameter_id from dashboard_template_parameters tp, dashboard_parameter_types pt, dashboard_datatable_headers h
 	 where tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and dashboard_template_parameter_id = tp.dashboard_template_parameter_id
 	 and h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and h.dashboard_datatable_header_id = @datatable_header_id_1)
update dashboard_parameter_values set dashboard_parameter_column = -2
 	 where dashboard_parameter_column = @column_2 and dashboard_template_parameter_id in 
 	 (select tp.dashboard_template_parameter_id from dashboard_template_parameters tp, dashboard_parameter_types pt,  dashboard_datatable_headers h
 	 where tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and dashboard_template_parameter_id = tp.dashboard_template_parameter_id
 	 and h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and h.dashboard_datatable_header_id = @datatable_header_id_1)
 	 
 	 update dashboard_parameter_values set dashboard_parameter_column = @column_2 where dashboard_parameter_column = -1
 	 update dashboard_parameter_values set dashboard_parameter_column = @column_1 where dashboard_parameter_column = -2
 	 
 	 update dashboard_datatable_headers set dashboard_datatable_column = @column_2 where dashboard_datatable_header_id = @datatable_header_id_1
 	 update dashboard_datatable_headers set dashboard_datatable_column = @column_1 where dashboard_datatable_header_id = @datatable_header_id_2
