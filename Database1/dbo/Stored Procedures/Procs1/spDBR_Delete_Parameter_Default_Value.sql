Create Procedure dbo.spDBR_Delete_Parameter_Default_Value
@id int
AS
 	 update dashboard_template_parameters set has_default_value = 0 where dashboard_template_parameter_id = @id
 	 delete from dashboard_parameter_default_values where dashboard_template_parameter_id = @id
 	 
