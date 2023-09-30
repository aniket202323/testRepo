Create Procedure dbo.spDBR_Get_DB_Build_Version
AS
declare @version varchar(50)
set @version = ''
execute spServer_CmnGetDbBuildVersion @version output
if (@version = '')
begin
 	 set @version = 'Unknown'
end
select @version as version
 	  	  	 
