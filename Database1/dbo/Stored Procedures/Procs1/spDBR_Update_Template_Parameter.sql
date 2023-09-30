Create Procedure dbo.spDBR_Update_Template_Parameter
@dashboard_template_parameter_id int,
@dashboard_template_parameter_name varchar(100),
@dashboard_template_parameter_type int,
@dashboard_template_dialogue_id int,
@dashboard_template_parameter_order int,
@Allow_Nulls int
AS
 	 update dashboard_template_parameters set dashboard_parameter_type_id = @dashboard_template_parameter_type,
 	  	    dashboard_template_parameter_name = @dashboard_template_parameter_name,
 	  	    dashboard_template_parameter_order = @dashboard_template_parameter_order,
 	  	    allow_nulls = @allow_nulls
 	  	    where dashboard_template_parameter_id = @dashboard_template_parameter_id
 	 update dashboard_template_dialogue_parameters set dashboard_dialogue_id = @dashboard_template_dialogue_id where dashboard_template_parameter_id = @dashboard_template_parameter_id 
