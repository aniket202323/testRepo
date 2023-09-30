Create Procedure dbo.spDBR_Clear_DataTable_Presentation_Parameters
@datatable_header_id int
AS
 	 delete from dashboard_datatable_presentation_parameters where dashboard_datatable_header_id = @datatable_header_id
 	 
