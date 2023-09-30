CREATE FUNCTION dbo.fnServer_CmnConvertTime(
@InTime DateTime,
@InTZ nvarchar (200),
@OutTZ nvarchar (200)
) 
     RETURNS DateTime
AS 
begin
Declare
  @DbTZ nvarchar(200),
 	 @bias int,
 	 @UtcTime datetime
select @bias = 0
select @bias = UTCbias from TimeZoneTranslations where TimeZone = @InTz and @InTime >= StartTime and @InTime < EndTime
select @UtcTime = DateAdd(mi,@bias,@InTime)
select @bias = 0
select @bias = UTCbias from TimeZoneTranslations where TimeZone = @OutTz and @UtcTime >= UtcStartTime and @UtcTime < UtcEndTime
return DateAdd(mi,-@bias,@UtcTime)
 	 
end
