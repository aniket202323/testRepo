CREATE FUNCTION dbo.fnServer_CmnConvertFromDbTime(
@InTime DateTime,
@OutTZ nvarchar (200)
)
returns DateTime
AS
begin
Declare
  @DbTZ nvarchar(200)
if (@OutTZ is null)
 	 return @InTime
if (len(@OutTZ) = 0)
 	 return @InTime
if (@InTime is null)
 	 return @InTime
select @DbTZ = null
select @DbTZ = value from site_parameters where parm_id=192
return dbo.fnServer_CmnConvertTime (@InTime, @DbTZ, @OutTZ)
 	 
end
