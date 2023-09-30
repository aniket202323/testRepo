Create Procedure dbo.spDBR_Delete_Dialogue_Association
@dialogue_association_id int
AS
 	 delete from dashboard_dialogue_parameters where dashboard_dialogue_parameter_id = @dialogue_association_id 	 
