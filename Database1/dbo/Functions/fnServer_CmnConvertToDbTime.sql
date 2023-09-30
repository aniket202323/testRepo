CREATE FUNCTION dbo.fnServer_CmnConvertToDbTime(
@InTime DateTime,
@InTZ nvarchar (200)
)
returns DateTime
AS
begin
Declare
  @DbTZ nvarchar(200)
if (@InTZ is null)
 	 return @InTime
if (len(@InTZ) = 0)
 	 return @InTime
if (@InTime is null)
 	 return @InTime
select @DbTZ = null
select @DbTZ=value from site_parameters where parm_id=192
return dbo.fnServer_CmnConvertTime (@InTime, @InTZ, @DbTZ)
 	 
end
