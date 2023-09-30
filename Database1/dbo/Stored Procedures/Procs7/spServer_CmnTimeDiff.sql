CREATE PROCEDURE dbo.spServer_CmnTimeDiff
@Mode int,
@StartTime nVarChar(30),
@EndTime nVarChar(30),
@Diff int OUTPUT
 AS
-- Mode
--
-- 1 Years
-- 2 Months
-- 3 Days
-- 4 Hours
-- 5 Minutes
-- 6 Seconds
Select @Diff = 0
If @Mode = 1
  Select @Diff = DateDiff(Year,@StartTime,@EndTime)
Else
  If @Mode = 2
    Select @Diff = DateDiff(Month,@StartTime,@EndTime)
Else
  If @Mode = 3
    Select @Diff = DateDiff(Day,@StartTime,@EndTime)
Else
  If @Mode = 4
    Select @Diff = DateDiff(Hour,@StartTime,@EndTime)
Else
  If @Mode = 5
    Select @Diff = DateDiff(Minute,@StartTime,@EndTime)
Else
  If @Mode = 6
    Select @Diff = DateDiff(Second,@StartTime,@EndTime)
