CREATE PROCEDURE dbo.spSupport_ImportEDTables
@dbname varchar(20)
AS
set nocount on
declare @field_id int, @id int, @i int
declare @model_id int, @model_desc varchar(255), @derived_from int, @model_num int, @et_id int, @server_version varchar(20), @interval_based tinyint, @num_of_fields int, @comment_id int, @user_defined tinyint, @modelnum int
declare @user_id int, @modified_on datetime, @cs_id int, @old_comment_id int, @installed_on datetime, @locked tinyint, @model_version varchar(20), @default_value varchar(255)
declare @field_order int, @ed_field_type_id int, @field_desc varchar(255), @optional tinyint, @max_instances int, @field_type_desc varchar(200), @prefix varchar(20), @sp_lookup tinyint
create table #tmpModels (ed_model_id int, model_desc varchar(255), derived_from int null, model_num int, et_id tinyint, server_version varchar(20) null, interval_based tinyint, num_of_fields int null, comment_id int null, user_defined tinyint, modelnum int null, modeldesc text null, model_version varchar(20) null, installed_on datetime null, locked tinyint)
create table #tmpFields (ed_field_id int, ed_model_id int, field_order int, ed_field_type_id int, field_desc varchar(100), optional tinyint, max_instances int, comment_id int null, default_value text null, locked tinyint)
create table #tmpFieldTypes (ed_field_type_id int, field_type_desc varchar(200), prefix varchar(20), sp_lookup tinyint)
create table #tmpComments (comment_id int, comment text, user_id int, modified_on datetime, cs_id int, shoulddelete tinyint null, comment_text text null)
execute ('insert into #tmpModels (ed_model_id, model_desc, derived_from, model_num, et_id, server_version, interval_based, num_of_fields, comment_id, modelnum, modeldesc, user_defined, model_version, installed_on, locked) select ed_model_id, model_desc, derived_from, model_num, et_id, server_version, interval_based, num_of_fields, comment_id, modelnum, modeldesc, user_defined, model_version, installed_on, locked from ' + @dbname + '..ed_models') 
execute ('insert into #tmpFields select * from ' + @dbname + '..ed_fields')
execute('insert into #tmpFieldTypes (ed_field_type_id, field_type_desc, prefix, sp_lookup) select ed_field_type_id, field_type_desc, prefix, sp_lookup from ' + @dbname + '..ed_fieldtypes')
execute ('insert into #tmpComments select * from ' + @dbname + '..comments where comment_id in (select comment_id from #tmpFields where comment_id is not null) or comment_id in (select comment_id from #tmpModels where comment_id is not null)')
set identity_insert ed_fieldtypes on
declare tmp_cur3 insensitive cursor
  for(select ed_field_type_id, field_type_desc, prefix, sp_lookup from #tmpFieldTypes) 
  for read only
open tmp_cur3
fetch next from tmp_cur3 into @ed_field_type_id, @field_type_desc, @prefix, @sp_lookup
field_types_loop:
  if(@@fetch_status = 0) 
    begin
    update ed_fieldtypes set field_type_desc = @field_type_desc, prefix = @prefix, sp_lookup = @sp_lookup where ed_field_type_id = @ed_field_type_id
    if @@rowcount = 0 
      insert into ed_fieldtypes (ed_field_type_id, field_type_desc, prefix, sp_lookup) values(@ed_field_type_id, @field_type_desc, @prefix, @sp_lookup)
    fetch next from tmp_cur3 into @ed_field_type_id, @field_type_desc, @prefix, @sp_lookup
    goto field_types_loop
    end
close tmp_cur3
deallocate tmp_cur3
set identity_insert ed_fieldtypes off
set identity_insert ed_models on
declare tmp_cur insensitive cursor
  for (select ed_model_id, model_desc, derived_from, model_num, et_id, server_version, interval_based, num_of_fields, comment_id, user_defined, modelnum, model_version, installed_on, locked from #tmpModels)
  for read only
open tmp_cur
fetch next from tmp_cur into @model_id, @model_desc, @derived_from, @model_num, @et_id, @server_version, @interval_based, @num_of_fields, @comment_id, @user_defined, @modelnum, @model_version, @installed_on, @locked
comments_loop:
  if(@@fetch_status = 0)
    begin --
    select @old_comment_id = (select distinct comment_id from ed_models where ed_model_id = @model_id)
    update ed_models set model_desc = @model_desc, derived_from = @derived_from, model_num = @model_num, et_id = @et_id, server_version = @server_version, interval_based = @interval_based, num_of_fields = @num_of_fields, user_defined = @user_defined, modelnum = @modelnum, modeldesc = convert(text, @model_desc), model_version = @model_version, installed_on = @installed_on, locked = @locked where ed_model_id = @model_id
      begin --
      --case1 - new model, new comment
      if @@rowcount = 0
        begin --
        if(0 < (select count(*) from #tmpModels where ed_model_id = @model_id and comment_id is not null))
          begin --
          insert into comments (comment, user_id, modified_on, cs_id, shoulddelete, comment_text) select comment, user_id, modified_on, cs_id, shoulddelete, comment_text from #tmpComments where comment_id = (select comment_id from #tmpModels where ed_model_id = @model_id)
          select @id = Scope_Identity()
          update #tmpModels set comment_id = @id where ed_model_id = @model_id
          end --
          insert into ed_models (ed_model_id, model_desc, derived_from, model_num, et_id, server_version, interval_based, num_of_fields, comment_id, user_defined, modelnum, modeldesc, model_version, installed_on, locked) select ed_model_id, model_desc, derived_from, model_num, et_id, server_version, interval_based, num_of_fields, comment_id, user_defined, modelnum, modeldesc, model_version, installed_on, locked from #tmpModels where ed_model_id = @model_id
        end --
      --case2 - old model
      else
        begin --
        -- old comment
        if(0 < (select count(*) from #tmpModels where ed_model_id = @model_id and comment_id is not null) and (select distinct comment_id from ed_models where ed_model_id = @model_id) is not null)
          begin --
            update comments set comments.comment = f.comment, comments.user_id = f.user_id, comments.modified_on = f.modified_on, comments.cs_id = f.cs_id, comments.comment_text = f.comment_text from comments join ed_models    d on d.comment_id  = comments.comment_id join #tmpModels   e on e.ed_model_id = d.ed_model_id join #tmpComments f on f.comment_id  = e.comment_id where e.ed_model_id = @model_id
          end --
        -- new comment
        else if (0 < (select count(*) from #tmpModels where ed_model_id = @model_id and comment_id is not null) and (select distinct comment_id from ed_models where ed_model_id = @model_id) is null)
          begin --
          insert into comments (comment, user_id, modified_on, cs_id, shoulddelete, comment_text) select comment, user_id, modified_on, cs_id, shoulddelete, comment_text from #tmpComments where comment_id = @comment_id
          select @comment_id = Scope_Identity()
          update #tmpModels set comment_id = @comment_id where ed_model_id = @model_id
          update ed_models set comment_id = @comment_id where ed_model_id = @model_id
          end --
        -- comment destroyed
        else  
          begin --
          update comments set comment = '', comment_text = '', shoulddelete = 1 where comment_id = @old_comment_id
          end --
        end --
      end --
    fetch next from tmp_cur into @model_id, @model_desc, @derived_from, @model_num, @et_id, @server_version, @interval_based, @num_of_fields, @comment_id, @user_defined, @modelnum, @model_version, @installed_on, @locked
    goto comments_loop
    end --
close tmp_cur
deallocate tmp_cur
set identity_insert ed_models off
-------------------------------------------------------------------
set identity_insert ed_fields on
declare tmp_cur2 insensitive cursor
  for (select ed_field_id, ed_model_id, field_order, ed_field_type_id, field_desc, optional, max_instances, comment_id, default_value, locked from #tmpFields)
  for read only
open tmp_cur2
fetch next from tmp_cur2 into @field_id, @model_id, @field_order, @ed_field_type_id, @field_desc, @optional, @max_instances, @comment_id, @default_value, @locked
comments_loop2:
  if(@@fetch_status = 0)
    begin --
    select @old_comment_id = (select distinct comment_id from ed_fields where ed_field_id = @field_id)
    update ed_fields set field_desc = @field_desc, ed_field_type_id = @ed_field_type_id, optional = @optional, max_instances = @max_instances, default_value = convert(text, @default_value), locked = @locked where ed_field_id = @field_id
      begin --
      --case1 - new model, new comment
      if @@rowcount = 0
        begin --
        if(0 < (select count(*) from #tmpFields where ed_field_id = @field_id and comment_id is not null))
          begin --
          insert into comments (comment, user_id, modified_on, cs_id, shoulddelete, comment_text) select comment, user_id, modified_on, cs_id, shoulddelete, comment_text from #tmpComments where comment_id = (select comment_id from #tmpFields where ed_field_id = @field_id)
          select @id = Scope_Identity()
          update #tmpFields set comment_id = @id where ed_field_id = @field_id
          end --
          insert into ed_fields (ed_field_id, ed_model_id, field_order, ed_field_type_id, field_desc, optional, max_instances, comment_id, default_value, locked) select ed_field_id, ed_model_id, field_order, ed_field_type_id, field_desc, optional, max_instances, comment_id, convert(text, @default_value), @locked from #tmpFields where ed_field_id = @field_id
        end --
      --case2 - old model
      else
        begin --
        -- old comment
        if(0 < (select count(*) from #tmpFields where ed_field_id = @field_id and comment_id is not null) and (select distinct comment_id from ed_fields where ed_field_id = @field_id) is not null)
          begin --
          update comments set comments.comment = d.comment, comments.user_id = d.user_id, comments.modified_on = d.modified_on, comments.cs_id = d.cs_id, comments.comment_text = d.comment_text from comments join #tmpComments d on comments.comment_id = d.comment_id
          end --
        -- new comment
        else if (0 < (select count(*) from #tmpFields where ed_field_id = @field_id and comment_id is not null) and (select distinct comment_id from ed_fields where ed_field_id = @field_id) is null)
          begin --
          insert into comments (comment, user_id, modified_on, cs_id, shoulddelete, comment_text) select comment, user_id, modified_on, cs_id, shoulddelete, comment_text from #tmpComments where comment_id = @comment_id
          select @comment_id = Scope_Identity()
          update #tmpFields set comment_id = @comment_id where ed_field_id = @field_id
          update ed_fields set comment_id = @comment_id where ed_field_id = @field_id
          end --
        -- comment destroyed
        else  
          begin --
          update comments set comment = '', comment_text = '', shoulddelete = 1 where comment_id = @old_comment_id
          end --
        end --
      end --
    fetch next from tmp_cur2 into @field_id, @model_id, @field_order, @ed_field_type_id, @field_desc, @optional, @max_instances, @comment_id, @default_value, @locked
    goto comments_loop2
    end --
close tmp_cur2
deallocate tmp_cur2
set identity_insert ed_fields off
drop table #tmpModels
drop table #tmpFields
drop table #tmpFieldTypes
drop table #tmpComments
