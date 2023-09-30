CREATE PROCEDURE dbo.spCSS_GetDatabaseTimeZone 
@DbTZName nvarchar(200) OUTPUT
AS
select @DbTZName = null
select @DbTZName = value from site_parameters where parm_id=192
if @DbTZName is null
 	 select @DbTZName = ''
