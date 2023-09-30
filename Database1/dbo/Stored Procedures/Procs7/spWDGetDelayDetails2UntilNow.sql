CREATE PROCEDURE dbo.spWDGetDelayDetails2UntilNow
@PUId int,
@HourWindow int,
@SheetName nvarchar(50)=''
AS
DECLARE @StartTime datetime, @EndTime datetime, @Now datetime
SET @Now = dbo.fnServer_CmnGetDate(getUTCdate())
SET @EndTime = dateadd(day, 1, @Now)
SET @StartTime = dateadd(hour, -@HourWindow, @Now) 
EXEC spWDGetDelayDetails2 @PUId, @StartTime, @EndTime, @SheetName
