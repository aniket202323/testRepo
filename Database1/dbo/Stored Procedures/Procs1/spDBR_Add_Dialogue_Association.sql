Create Procedure dbo.spDBR_Add_Dialogue_Association
@parameter_type_id int,
@dialogue_id int,
@checked bit
AS
 	 declare @id int
 	 
 	 insert into dashboard_dialogue_parameters (Dashboard_Dialogue_ID ,Dashboard_Parameter_Type_Id, default_dialogue) values(@dialogue_id, @parameter_type_id, @checked)
 	 set @id= (select scope_identity())
 	 select @id as id
