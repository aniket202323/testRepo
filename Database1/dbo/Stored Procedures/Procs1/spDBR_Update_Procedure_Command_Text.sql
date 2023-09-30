Create Procedure dbo.spDBR_Update_Procedure_Command_Text
@datatable_header_id int,
@command_text varchar(100)
AS
 	 update dashboard_datatable_headers set dashboard_datatable_column_sp = @command_text where dashboard_datatable_header_id = @datatable_header_id
