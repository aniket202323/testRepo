CREATE Procedure dbo.spEMED_EDManager
@ListType int,
@id1 int, @id2 int = NULL,
@id3 int = NULL, @id4 int = NULL,
@str1 nvarchar(255) = NULL, @str2 nvarchar(255) = NULL
AS
--set IDENTITY_INSERT ed_models on
if @ListType = 1 	  	  	  	  	 -- search models
  select m.ed_model_id, model_num, m.model_desc, m.model_version, et_desc, m.locked, m.num_of_fields, m.derived_from, count(ec_id),Allow_Derived = Coalesce(m.Allow_Derived,0)
 	 from ed_models m
    left outer join event_types e on e.et_id = m.et_id
    left outer join event_configuration c on c.ed_model_id = m.ed_model_id
    where (model_desc like '%' + @str1 + '%') and (m.ed_model_id <> 50000)
    group by m.ed_model_id, model_num, model_desc, model_version, et_desc, m.locked, num_of_fields, m.derived_from,m.Allow_Derived
    order by model_num
else if @ListType = 4
  select et_id, et_desc from event_types
else if @ListType = 5
  select  m.ed_model_id, model_num, model_desc, model_version, e.et_desc, locked, num_of_fields, derived_from, count(ec_id),Allow_Derived = Coalesce(m.Allow_Derived,0)
 	 from ed_models m
    left outer join event_types e on e.et_id = m.et_id
    left outer join event_configuration c on c.ed_model_id = m.ed_model_id
    where (model_desc like '%' + @str1 + '%' and m.et_id = @id1) and (m.ed_model_id <> 50000)
    group by m.ed_model_id, model_num, model_desc, model_version, et_desc, locked, num_of_fields, derived_from,m.Allow_Derived
    order by model_num
else if @ListType = 9
   select model_num, model_desc  from ed_models where (derived_from is null) and (ed_model_id < 50000)
else if @ListType = 10 	  	  	  	 -- get info on one model w/ id = @id1
  select e.ed_model_id, e.installed_on, e.modelnum, e.derived_from, e.model_num, e.num_of_fields, e.comment_id, e.user_defined, 
 	 e.locked, e.et_id, i_b = convert(int,e.interval_based), e.model_desc, e.server_version, e.model_version, userdef = e.user_defined,
 	  	 Base_is_Generic = case when e.derived_from is null then 0
 	  	  	  	  	  	  	    When e2.Et_Id = 15 then 1
 	  	  	  	  	  	   Else 0
 	  	  	  	  	  	   End
 	  from ed_models e
 	  Left Join ed_models e2 on e2.model_num = e.derived_from
 	 where e.ed_model_id = @id1
else if @ListType = 11 	  	  	  	 -- get list of all event types
  Select et_id, et_desc
   From Event_Types
   Order by et_desc
else if @ListType = 12 	  	  	  	 -- get list of all event types
  Select et_id, et_desc
    From Event_Types
    Where Event_Models > 0
    Order by et_desc
else if @ListType = 20 	  	  	  	 -- get fields belonging to @id1 model (Properties Tab)
  select f.field_order, f.ed_field_id, f.field_desc, t.field_type_desc,
 	  f.optional, f.locked, def_value = Case When f.Default_value is not null then Convert(nVarChar(10),f.ed_field_id)
                                                Else ''
 	  	  	  	  	  	 End,
 	  f.derived_from,  i.max_instances, t.sp_lookup,f.ed_field_type_id,Use_Percision = Coalesce(f.Use_Percision,0),Percision = Coalesce(f.Percision,0),t.Store_Id
    From ed_fields f 
    Left outer join ed_fields i on i.ed_field_id = f.derived_from 
    join ed_fieldtypes t on t.ed_field_type_id = f.ed_field_type_id 
    where f.ed_model_id = @id1
    order by f.field_order
else if @ListType = 21 	  	  	  	 -- get field details of select field
--mpr01/31  select ed_field_id, ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from from ed_fields f 
  select ed_field_id, ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, def_value = '', optional, locked, field_desc, derived_from,Percision = Coalesce(f.Percision,0) from ed_fields f 
    where ed_field_id = @id1
else if @ListType = 22 	  	  	  	 -- get all field types
BEGIN
  select ed_field_type_id, field_type_desc,SP_Lookup,Store_Id 
 	  	 from ed_fieldtypes 
 	 order by Field_Type_Desc
END
else if @ListType = 23 	  	  	  	 -- get all UDP field types
BEGIN
  select ed_field_type_id, field_type_desc,SP_Lookup,Store_Id 
 	  	 from ed_fieldtypes 
 	 WHERE User_Defined_Property = 1
 	 order by Field_Type_Desc
END
else if @ListType = 24 	  	  	  	 -- get server version
  select app_version from appversions where app_id = 2
--else if @ListType = 40
--  select num_of_fields = ??? from ???          -- <--- get num of avail fields
--  select field_order = 1, ed_field_id = 0, field_desc = '<new field>', Field_Type_Desc, optional = 0 from ed_fieldtypes where ed_field_type_id = 1
else if @ListType = 30 	  	  	  	 -- export table data
  select ed_model_id, installed_on, modelnum, derived_from, model_num, num_of_fields, comment_id, model_desc, user_defined, locked, et_id, interval_based, model_desc, server_version, model_version from ed_models where ed_model_id = @id1
else if @ListType = 31 	  	  	  	 -- export table data
  select ed_field_id, ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, optional, locked, field_desc, derived_from from ed_fields where ed_field_id = @id1
else if @ListType = 32
  select ed_field_id from ed_fields where ed_model_id = @id1
else if @ListType = 33
  select modeldesc from ed_models where ed_model_id = @id1
else if @ListType = 34
  select comment_id from ed_models where ed_model_id = @id1
else if @ListType = 35
  select default_value from ed_fields where ed_field_id = @id1
else if @ListType = 36
  select comment_id from ed_fields where ed_field_id = @id1
else if @ListType = 50
  select prodstatus_id, prodstatus_desc from production_status
else if @ListType = 51
  select var_id, var_desc from variables
else if @ListType = 52
  select pu_id, pu_desc from prod_units
else if @ListType = 53
  select st_id, st_desc from sampling_type Where ST_Id <> 48
