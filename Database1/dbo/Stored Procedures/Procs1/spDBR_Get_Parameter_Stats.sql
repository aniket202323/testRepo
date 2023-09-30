Create Procedure dbo.spDBR_Get_Parameter_Stats
@parameter_id int
AS
 	 select count(dashboard_template_parameter_id) as Parameter_Use_Count from dashboard_template_parameters
 	 where dashboard_parameter_type_id = @parameter_id
