Create Procedure dbo.spDBR_Delete_Parameter_Column
@column_id int
AS
 	 declare @column int
 	 set @column = (select dashboard_datatable_column from dashboard_datatable_headers where dashboard_datatable_header_id = @column_id)
 	 declare @parameter_id nvarchar(100)
 	 set @parameter_id = (select dashboard_parameter_type_id from dashboard_datatable_headers where dashboard_datatable_header_id = @column_id)
 	 
 	 delete from dashboard_parameter_default_values where dashboard_parameter_column = @column and dashboard_template_parameter_id in
 	 (select tp.dashboard_template_parameter_id from dashboard_template_parameters tp, dashboard_parameter_types pt, dashboard_datatable_headers h
 	 where dashboard_template_parameter_id = tp.dashboard_template_parameter_id and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id
 	 and h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and h.dashboard_datatable_header_id = @column_id)
 	 
 	 delete from dashboard_parameter_values where dashboard_parameter_column = @column and dashboard_template_parameter_id in
 	 (select tp.dashboard_template_parameter_id from dashboard_template_parameters tp, dashboard_parameter_types pt, dashboard_datatable_headers h
 	 where dashboard_template_parameter_id = tp.dashboard_template_parameter_id and tp.dashboard_parameter_type_id = pt.dashboard_parameter_type_id
 	 and h.dashboard_parameter_type_id = pt.dashboard_parameter_type_id and h.dashboard_datatable_header_id = @column_id)
 	 
 	 delete from dashboard_datatable_presentation_parameters where dashboard_datatable_header_id = @column_id
 	 delete from dashboard_datatable_headers where dashboard_datatable_header_id = @column_id
 	 
 	 declare @updatetext nvarchar(500)
 	 set @updatetext = ('spDBR_Update_DataTable_Parameter_Column_Order ' + @parameter_id)
 	 
 	 execute sp_executesql @updatetext
 	 
 	 
 	 
