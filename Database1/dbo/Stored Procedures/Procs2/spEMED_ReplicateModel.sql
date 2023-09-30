CREATE PROCEDURE dbo.spEMED_ReplicateModel
@id1 int
AS
declare 
  @new_ed_model_id int,
  @new_ed_field_id int,
  @old_comment_id int, 
  @new_comment_id int,
  @model_id int, @model_desc nvarchar(255), 
  @NewModelNum int
select @model_id = ed_model_id from ed_models where model_num = @id1
select @NewModelNum  = MAX(Model_Num) + 1 from ed_models 
insert into ed_models (installed_on, modelnum, derived_from, model_num, num_of_fields, comment_id, modeldesc, user_defined, locked, et_id, interval_based, model_desc, server_version, model_version)
  select installed_on, @NewModelNum, model_num, @NewModelNum, num_of_fields, comment_id, '(' + ltrim(rtrim(convert(nvarchar(255), @NewModelNum))) + ') ' + model_desc, user_defined, 0, 
 	 Case When et_id = 15 then 1 else et_id end, interval_based, '(' + ltrim(rtrim(convert(nvarchar(255), @NewModelNum))) + ') ' + model_desc, server_version, '1.0' from ed_models
    where ed_model_id = @model_id
select @new_ed_model_id = Scope_Identity()
create table #ed_field_data (ed_field_id int, 
 	  	  	  	  	  	  	  ed_field_type_id int, 
 	  	  	  	  	  	  	 max_instances int, 
 	  	  	  	  	  	  	 comment_id int null, 
 	  	  	  	  	  	  	 ed_model_id int, 
 	  	  	  	  	  	  	 field_order int, 
 	  	  	  	  	  	  	 default_value text null, 
 	  	  	  	  	  	  	 optional tinyint, 
 	  	  	  	  	  	  	 locked tinyint, 
 	  	  	  	  	  	  	 field_desc nVarChar(100),
 	  	  	  	  	  	  	 derived_from int null,
 	  	  	  	  	  	  	 Percision 	 Int Null,
 	  	  	  	  	  	  	 Use_Percision 	 Int Null)
insert into #ed_field_data (ed_field_id, ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from,Percision,Use_Percision)
  select ed_field_id, ed_field_type_id, max_instances, comment_id, @new_ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from,Percision,Use_Percision from ed_fields 
    where (ed_model_id = @model_id)
        and (optional = 0) -- add only non-optional fields
update #ed_field_data
  set ed_model_id = @new_ed_model_id
update #ed_field_data
  set derived_from = ed_field_id
if (select comment_id from ed_models where ed_model_id = @new_ed_model_id) is not null 
  begin
    insert into comments (modified_on, user_id, cs_id, comment, comment_text, shoulddelete)
      select modified_on, user_id, cs_id, comment, comment_text, shoulddelete from comments where comment_id = (select comment_id from ed_models where ed_model_id = @new_ed_model_id)
    update ed_models
       set comment_id = Scope_Identity()
          where ed_model_id = @new_ed_model_id
  end
create table #ed_comment_data (comment_id int, modified_on datetime, user_id int, cs_id int, comment text, comment_text text null, shoulddelete tinyint null)
insert into #ed_comment_data (comment_id, modified_on, user_id, cs_id, comment, comment_text, shoulddelete)
  select comment_id, modified_on, user_id, cs_id, comment, comment_text, shoulddelete from comments
    where comment_id in (select comment_id from #ed_field_data)
declare cmt_cur insensitive cursor
  for (select comment_id from #ed_comment_data)
  for read only
  open cmt_cur
fetch next from cmt_cur into @old_comment_id
cmt_loop:
  if(@@fetch_status = 0)
  begin
    insert into comments (modified_on, user_id, cs_id, comment, comment_text, shoulddelete)
      select modified_on, user_id, cs_id, comment, comment_text, shoulddelete from #ed_comment_data
        where comment_id = @new_comment_id
    select @new_comment_id = Scope_Identity()
    update #ed_field_data 
      set comment_id = @new_comment_id
        where comment_id = @old_comment_id
    fetch next from cmt_cur into @old_comment_id
    goto cmt_loop
  end
close cmt_cur
deallocate cmt_cur
drop table #ed_comment_data
declare fld_cur insensitive cursor
  for (select ed_field_id from ed_fields)
  for read only
  open fld_cur
fetch next from fld_cur into @new_ed_field_id
fld_loop:
  if(@@fetch_status = 0)
  begin
    insert into ed_fields (ed_field_type_id, max_instances, comment_id, ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from,Percision,Use_Percision)
      select ed_field_type_id, max_instances, comment_id, @new_ed_model_id, field_order, default_value, optional, locked, field_desc, derived_from,Percision,Use_Percision from #ed_field_data
        where ed_field_id = @new_ed_field_id
    fetch next from fld_cur into @new_ed_field_id
    goto fld_loop
  end
close fld_cur
deallocate fld_cur
drop table #ed_field_data
--select ed_model_id, installed_on, modelnum, @id1, model_num, num_of_fields, comment_id, modeldesc, user_defined, locked, et_id, interval_based, model_desc, server_version, model_version from ed_models where ed_model_id = @new_ed_model_id
select m.ed_model_id, m.model_num, m.model_desc, m.server_version, m.num_of_fields, m.model_version,  m.locked, m.et_id, t.et_desc, m.derived_from from ed_models m
    join event_types t on t.et_id = m.et_id
    where ed_model_id = @new_ed_model_id
update ed_models 
  set num_of_fields = (select count(ed_field_id) from ed_fields where ed_model_id = @new_ed_model_id)
    where ed_model_id = @new_ed_model_id
