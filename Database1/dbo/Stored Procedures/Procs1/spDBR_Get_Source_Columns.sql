Create Procedure dbo.spDBR_Get_Source_Columns
@paramid int
AS
 	 select dashboard_datatable_header_id, dashboard_datatable_header from dashboard_datatable_headers where dashboard_parameter_type_id = @paramid and dashboard_datatable_presentation = 0
