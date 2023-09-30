Create Procedure dbo.spDBR_Get_Parameter_Query
@templateparamid int,
@reportid int
AS
 	 select dashboard_parameter_value from dashboard_parameter_values where dashboard_template_parameter_id =@templateparamid and dashboard_report_id = @reportid and dashboard_parameter_column = 3
