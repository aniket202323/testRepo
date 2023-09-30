CREATE PROCEDURE dbo.spServer_DBMgrSaveDSTChange
@StartUTC datetime,
@EndUTC datetime,
@StartLocal datetime,
@EndLocal datetime,
@TZName nvarchar(200),
@Bias int
AS
declare @Count int
select @Count=0
select @Count=count(UTCBias) from TimeZoneTranslations where TimeZone=@TZName and UTCBias=@Bias and UTCStartTime = @StartUTC and UTCEndTime = @EndUTC and StartTime = @StartLocal  and EndTime = @EndLocal
if (@count = 0)
begin
 	 delete from TimeZoneTranslations 
 	  	  	 where TimeZone=@TZName and ((@StartUTC < UTCEndTime and @EndUTC > UTCStartTime) or (@StartLocal < EndTime and @EndLocal > StartTime))
 	 insert into TimeZoneTranslations (UTCStartTime, UTCEndTime, StartTime, EndTime, TimeZone, UTCBias) values(@StartUTC, @EndUTC, @StartLocal, @EndLocal, @TZName, @Bias)
end
