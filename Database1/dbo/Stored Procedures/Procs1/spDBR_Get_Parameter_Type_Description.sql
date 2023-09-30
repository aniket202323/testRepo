Create Procedure dbo.spDBR_Get_Parameter_Type_Description
@parameter_type_desc varchar(100)
AS
 	 select dashboard_parameter_type_id from dashboard_parameter_types where dashboard_parameter_type_desc = @parameter_type_desc
