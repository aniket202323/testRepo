CREATE PROCEDURE dbo.spServer_CmnGetTimeWeight
@StartSubTime datetime,
@EndSubTime datetime,
@StartTime datetime,
@EndTime datetime,
@Weighting float OUTPUT
AS
Declare
  @TimeDiff float,
  @SubTimeDiff float
Select @TimeDiff = DateDiff(Minute,@StartTime,@EndTime)
Select @SubTimeDiff = DateDiff(Minute,@StartSubTime,@EndSubTime)
If (@TimeDiff > 0)
  Select @Weighting = (@SubTimeDiff / @TimeDiff)
Else
  Select @Weighting = 0
