-- spEMED_AvailableFields 1,50021
CREATE PROCEDURE dbo.spEMED_AvailableFields 
@ListType int,
@id int
AS
-- create temp table
DECLARE @T_AvailableFields  table  (ed_field_id int, ed_field_type_id int, max_instances int, comment_id int null, ed_model_id int, field_order int, default_value text null, optional tinyint, locked tinyint, field_desc nVarChar(100), derived_from int)
-- insert all derivable fields
insert into @T_AvailableFields (ed_field_id, ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from)
  select ed_field_id, ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from from ed_fields
    where ed_model_id in (select ed_model_id from ed_models where model_num in (select derived_from from ed_models where ed_model_id = @id))
--  insert all derived fields
insert into @T_AvailableFields (ed_field_id, ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from)
  select ed_field_id, ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from from ed_fields
    where (derived_from in (select ed_field_id from @T_AvailableFields))
      and (ed_model_id = @id)
-- delete fields already derived
delete from @T_AvailableFields 
  where ed_field_id in (select derived_from from @T_AvailableFields)
if @ListType = 1 -- result in list of un-used fields
begin
  delete from @T_AvailableFields 
    where ed_field_id > 100000
  select field_order, ed_field_id, field_desc, field_type_desc, optional, locked, default_value, derived_from 
 	  from @T_AvailableFields a
    join ed_fieldtypes b on a.ed_field_type_id = b.ed_field_type_id
 	 ORDER BY field_order
end
else if @ListType = 2 -- result in count of un-used fields
begin
  delete from @T_AvailableFields 
    where ed_field_id > 100000
  select count(ed_field_id) from @T_AvailableFields
end
else if @ListType = 3 -- result in list of used fields
begin
  delete from @T_AvailableFields 
    where ed_field_id < 100000
  select field_order, ed_field_id, field_desc, field_type_desc, optional, locked, default_value, derived_from 
 	 from @T_AvailableFields  a
    join ed_fieldtypes b on a.ed_field_type_id = b.ed_field_type_id
 	 ORDER BY field_order
end
else if @ListType = 4 -- result in count of used fields
begin
  delete from @T_AvailableFields 
    where ed_field_id < 100000
  select count(ed_field_id) from @T_AvailableFields
end
