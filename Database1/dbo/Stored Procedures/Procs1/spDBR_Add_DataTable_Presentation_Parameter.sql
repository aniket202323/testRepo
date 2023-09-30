Create Procedure dbo.spDBR_Add_DataTable_Presentation_Parameter
@datatable_header_id int,
@parameter_order int,
@source int
AS
 	 insert into dashboard_datatable_presentation_parameters (Dashboard_DataTable_Header_ID ,Dashboard_DataTable_Presentation_Parameter_Order ,Dashboard_DataTable_Presentation_Parameter_Input)  values (@datatable_header_id, @parameter_order, @source)
