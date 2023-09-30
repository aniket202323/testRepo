CREATE PROCEDURE dbo.spEMED_ImportFieldData
@ed_model_id int,
@field_desc nVarChar(100),
@ed_field_type_id int,
@max_instances int,
@derived_from int,
@optional int,
@locked int,
@field_order int
AS
insert into ed_fields 
  (field_desc, ed_field_type_id, max_instances, derived_from, optional, locked, field_order, ed_model_id)
  values(@field_desc, @ed_field_type_id, @max_instances, @derived_from, @optional, @locked, @field_order, @ed_model_id)
select ed_field_id = Scope_Identity()
