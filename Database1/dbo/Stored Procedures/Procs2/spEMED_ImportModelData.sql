CREATE PROCEDURE dbo.spEMED_ImportModelData
@model_num int,
@modelnum int, 
@model_desc nvarchar(255),
@derived_from int,
@installed_on nvarchar(50),
@server_version nvarchar(20),
@model_version nvarchar(20),
@interval_based int,
@locked int,
@user_defined int,
@et_id int,
@num_of_fields int
AS
if @modelnum like '(null)'
  select @modelnum = null
if @derived_from like '(null)'
  select @derived_from = null
if @installed_on like '(null)'
  select @installed_on = null
if @server_version like '(null)'
  select @server_version = null
if @model_version like '(null)'
  select @model_version = null
if @num_of_fields like '(null)'
  select @num_of_fields = null
insert into ed_models 
  (model_num, modelnum, model_desc, derived_from, installed_on, server_version, model_version, interval_based, locked, user_defined, et_id, num_of_fields)
  values(@model_num, @modelnum, @model_desc, @derived_from, @installed_on, @server_version, @model_version, @interval_based, @locked, @user_defined, @et_id, @num_of_fields)
select ed_model_id = Scope_Identity()
