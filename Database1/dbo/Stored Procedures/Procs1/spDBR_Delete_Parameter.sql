Create Procedure dbo.spDBR_Delete_Parameter
@parameter_id int
AS
 	 delete from dashboard_dialogue_parameters where dashboard_parameter_type_id = @parameter_id
 	 delete from dashboard_datatable_presentation_parameters where dashboard_datatable_header_id in (select dashboard_datatable_header_id from dashboard_datatable_headers where dashboard_parameter_type_id = @parameter_id)
 	 delete from dashboard_datatable_headers where dashboard_parameter_type_id = @parameter_id
 	 delete from dashboard_parameter_types where dashboard_parameter_type_id = @parameter_id 
 	 
