Create Procedure dbo.spWDGetWasteDetailsTestUntilNow
@PUId int,
@HourWindow int
AS
declare @StartTime datetime, @EndTime datetime
set @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
set @StartTime = dateadd(hour, -@HourWindow, @EndTime) 
exec spWDGetWasteDetailsTest @PUId, @StartTime, @EndTime
