Create Procedure dbo.spDBR_Delete_Parameter_Value
@reportid int,
@id int
AS
 	 delete from dashboard_parameter_values where dashboard_template_parameter_id = @id and dashboard_report_id = @reportid
 	 
