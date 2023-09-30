Create Procedure dbo.spDBR_Delete_All_Dialogue_Associations
@parmid int
AS
 	 delete from dashboard_dialogue_parameters where dashboard_parameter_type_id = @parmid 	 
