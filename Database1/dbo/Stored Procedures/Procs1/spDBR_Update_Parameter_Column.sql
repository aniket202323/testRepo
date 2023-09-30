Create Procedure dbo.spDBR_Update_Parameter_Column
@column_id int,
@column_header varchar(100),
@presentation_Bit int
AS
 	 update dashboard_datatable_headers set dashboard_datatable_header = @column_header, dashboard_datatable_presentation = @presentation_Bit where dashboard_datatable_header_id = @column_id
