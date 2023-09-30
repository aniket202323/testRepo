Create Procedure dbo.spDBR_Update_Template_Parameter_Order
@dashboard_template_parameter_id int,
@dashboard_template_parameter_order int
AS
 	 update dashboard_template_parameters set dashboard_template_parameter_order = @dashboard_template_parameter_order
 	  	    where dashboard_template_parameter_id = @dashboard_template_parameter_id
