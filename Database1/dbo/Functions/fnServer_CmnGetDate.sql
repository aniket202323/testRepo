CREATE FUNCTION dbo.fnServer_CmnGetDate(
@UTCDate datetime
) 
     RETURNS DateTime
AS 
begin
Declare
  @DbTZ nvarchar(200),
 	 @bias int
select @DbTZ = null
select @DbTZ=value from site_parameters where parm_id=192
select @bias = 0
select @bias = UTCbias from TimeZoneTranslations where TimeZone = @DbTz and @UtcDate >= UtcStartTime and @UtcDate < UtcEndTime
return DateAdd(mi,-@bias,@UtcDate)
 	 
end
