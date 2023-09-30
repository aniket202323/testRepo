CREATE PROCEDURE dbo.spSupport_SetParam
  @ParamId int,
  @Value varchar(50)
AS
DECLARE @parmid as int
declare @userid as int
select @parmid = (select parm_id from parameters where parm_id = @ParamId)
if @parmid is null
  begin
     select "Invalid parameter id"
  end
else
  begin
     select @userid = (select user_id from user_parameters where parm_id = @parmid)
     if @userid is not null
     begin
        update user_parameters set value = @Value where parm_id = @parmid and user_id = @userid
     end
     update site_parameters set value = @Value where parm_id = @parmid
  end
