Create Procedure dbo.spDBR_Delete_Template_Parameter
@parameter_id int
AS
 	 delete from dashboard_template_dialogue_parameters where dashboard_template_parameter_id = @parameter_id
 	 delete from dashboard_parameter_values where dashboard_template_parameter_id = @parameter_id
 	 delete from dashboard_parameter_default_values where dashboard_template_parameter_id = @parameter_id
 	 delete from dashboard_template_parameters where dashboard_template_parameter_id = @parameter_id
 	 
