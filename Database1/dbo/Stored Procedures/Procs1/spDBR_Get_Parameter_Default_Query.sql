Create Procedure dbo.spDBR_Get_Parameter_Default_Query
@templateparamid int
AS
 	 select dashboard_parameter_value from dashboard_parameter_Default_values where dashboard_template_parameter_id =@templateparamid and dashboard_parameter_column = 3
