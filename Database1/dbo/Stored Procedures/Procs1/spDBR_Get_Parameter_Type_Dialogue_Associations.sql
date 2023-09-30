Create Procedure dbo.spDBR_Get_Parameter_Type_Dialogue_Associations
@parameter_type_id int,
@dialogue_id int
AS
 	 select count(dtp.dashboard_template_dialogue_parameter_id) as numassociations
 	 from dashboard_template_dialogue_parameters dtp,
 	 dashboard_template_parameters tp
 	 where dtp.dashboard_template_parameter_id = tp.dashboard_template_parameter_id
 	 and dtp.dashboard_dialogue_id = @dialogue_id
 	 and tp.dashboard_parameter_type_id = @parameter_type_id
