Create Procedure dbo.spDBR_Get_Gallery_State
@ServerName varchar(50)
AS
  declare @Dirty int
  set @Dirty = (select dirtybit from dashboard_gallery_generator_servers where server = @servername)
  set @Dirty = (select ISNULL(@Dirty, 0))
  select @Dirty as State
