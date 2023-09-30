CREATE Procedure dbo.spEMED_EDManagerUpdate
@ListType int,
@id1 int, @id2 int = NULL,
@id3 int = NULL, @id4 int = NULL,
--@str1 nvarchar(255) = NULL, @str2 nvarchar(255) = NULL --ECR 29329: increase string length to accommodate default_value
@str1 varchar(8000) = NULL, @str2 nvarchar(255) = NULL
AS
--set IDENTITY_INSERT ed_models on
if @ListType = 2 	  	  	  	 -- delete model with id = @id1
  begin
    update comments set comment = '', shoulddelete = 1 where comment_id in (select comment_id from ed_models where ed_model_id = @id1) or comment_id in (select comment_id from ed_fields where ed_model_id = @id1)
    delete from ed_fields where ed_model_id = @id1
 	 Delete From ED_Field_Properties where ed_model_id = @id1
    delete from ed_models where ed_model_id = @id1
  end
else if @ListType = 3 	  	  	  	 -- get next valid model_num for use
  begin
    declare @ser_ver nVarChar(10)
    select @ser_ver = (select app_version from appversions where app_id = 2)
    declare @tmp int
    insert into ed_models (model_num, model_desc, server_version, locked, interval_based, num_of_fields, model_version, et_id)
        values(1, '<>', @ser_ver, 0, 0, 0, 1.0, 1)
   select @tmp = Scope_Identity()
    update ed_models 
        set model_desc = '<New Model ' + rtrim(ltrim(convert(nVarChar(200),@tmp))) + '>', model_num = @tmp
            where ed_model_id = @tmp
   select m.ed_model_id, m.model_num, m.model_desc, m.server_version, m.num_of_fields, m.model_version,  m.locked, m.et_id, t.et_desc from ed_models m
      join event_types t on t.et_id = m.et_id
      where ed_model_id = @tmp
  end
else if @ListType = 8 -- replicate an ed_field 
  begin
    Declare @MaxOrder Int
    DECLARE @DerivedFromModel Int
    SELECT @DerivedFromModel = ED_Model_Id  from ED_Fields where ED_Field_Id = @id1
    IF @DerivedFromModel = 5196
    BEGIN
 	  	 Select  @MaxOrder = Max(field_order) 
 	  	   From Ed_Fields 
 	  	   Where Ed_Model_Id = @Id2  and field_order < 100
    END
    ELSE
    BEGIN
 	  	 Select  @MaxOrder = Max(field_order) 
 	  	   From Ed_Fields 
 	  	   Where Ed_Model_Id = @Id2
 	 END
    insert into ed_fields (ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from,Percision,Use_Percision)
      select  ed_field_type_id, max_instances, comment_id, @id2,@MaxOrder + 1 , default_value, optional, locked, field_desc, @id1,Percision,Use_Percision
        from ed_fields
        where ed_field_id = @id1 -- @id1 used as field_order for unique number 
    update ed_models 
        set num_of_fields = (select count(ed_field_id) from ed_fields where ed_model_id = @id2)
           where ed_model_id = @id2
    select f.ed_field_id, f.ed_field_type_id, f.max_instances, f.comment_id, f.ed_model_id, f.field_order, def_value = '', is_optional = f.optional, is_locked = f.locked, f.field_desc, f.derived_from, t.field_type_desc, t.sp_lookup,
 	  	  	  	  	 Percision = Coalesce(f.Percision,0),Use_Percision = Coalesce(f.Use_Percision,0)
 	  	  from ed_fields f
      join ed_fieldtypes t on t.ed_field_type_id = f.ed_field_type_id
      where f.ed_field_id = Scope_Identity()
  end
else if @ListType = 23
  begin
  delete from ed_fields where ed_field_id = @id1
  update ed_models
    set num_of_fields = (select count(ed_field_id) from ed_fields f
    where f.ed_model_id = ed_models.ed_model_id)
  end
else if @ListType = 93  	 --delete entire model, fields, comment
  begin
    if @id1 > 50000
    begin
      update comments
        set shoulddelete = 1, comment = '', comment_text = ''
          where comment_id in (select comment_id from ed_models where ed_model_id = @id1)
      update comments
        set shoulddelete = 1, comment = '', comment_text = ''
          where comment_id in (select comment_id from ed_fields where ed_model_id = @id1)
 	   Delete From Event_Configuration_Properties Where  ED_Field_Prop_Id in (Select ED_Field_Prop_Id From ED_Field_Properties 	 Where  ED_Model_Id = @id1)
      Delete From ED_Field_Properties Where   ED_Model_Id = @id1
      delete from ed_fields where ed_model_id = @id1
      delete from ed_models where ed_model_id = @id1 
    end
  end
else if @ListType = 94
  begin
   	 if @id1 > 100000 or @id1 in (Select ED_Field_Id From ed_fields Where ED_Model_Id = 49000) --allow edit of model 49000
 	   If @id1 = 2821 and @str1 = '-1' 
 	     update ed_fields
 	       set default_value = Null
 	       where ed_field_id = @id1
 	   Else
 	     update ed_fields
 	       set default_value = @str1
 	       where ed_field_id = @id1
  end
else if @ListType = 95
  begin
  if @id1 > 100000
    update ed_fields
      set locked = @id2,Percision = @id3
      where ed_field_id = @id1
    update Event_Configuration_Data
      set Input_Precision = @id3
      where ed_field_id = @id1
  end
else if @ListType = 96 	  	  	  	 -- save derived info
  begin
  if @id1 > 100000
    update ed_models
      set derived_from = @id2
      where ed_model_id = @id1
  end
else if @ListType = 97 	  	  	  	 -- save field
  begin
    if @id1 = 0
      begin
        insert into ed_fields (ed_model_id, ed_field_type_id, max_instances, field_desc, optional, field_order) values(@id2, @id3, @id4, convert(nVarChar(100), @str1), convert(tinyint, @str2), 1)
        update ed_models
          set num_of_fields = (select count(*) from ed_fields f
          where f.ed_model_id = ed_models.ed_model_id)
        select ed_field_id = Scope_Identity()
      end
    else if @id1 > 100000
      begin
        update ed_fields
          set ed_field_type_id = @id3, max_instances = @id4, field_desc = convert(nVarChar(100), @str1), optional = convert(tinyint, @str2)
          where ed_field_id = @id1
        update ed_models
          set num_of_fields = (select count(*) from ed_fields f
          where f.ed_model_id = ed_models.ed_model_id)
        select ed_field_id = @id1
      end
    else
      select ed_field_id = @id1
  end  
else if @ListType = 98 	  	  	  	 -- update field order
  begin
  if @id1 > 100000
    update ed_fields
      set field_order = @id2
      where ed_field_id = @id1
  end
else if @ListType = 99 	  	  	  	 -- save model
  begin
    if @str2 = ''
       select @str2 = null
    if @id1 > 50000
    begin
        update ed_models
          set model_num = @id2, modelnum = @id2, et_id = @id3, interval_based = @id4, model_desc = @str1, modeldesc = @str1, model_version = convert(nvarchar(20), @str2) 
 	 where ed_model_id = @id1
        select ed_model_id = @id1
    end
    else 
        select ed_model_id = @id1
  end
