CREATE PROCEDURE dbo.spBF_CalcDowntimeWindow 
  @MasterUnit int,
  @StartTime datetime,
  @EndTime datetime,
  @Direction tinyint = 0,
  @InTimeZone nVarChar(200) = null
AS 
--Convert incoming timestamps from TW from @InTimeZone to DB time
Select @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime, @InTimeZone)
Select @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime, @InTimeZone)
Declare @@Start_Time datetime,
 	  	 @@End_Time datetime,
 	  	 @@Duration int
Select @@Duration = DateDiff(minute, @StartTime, @EndTime)
if @Direction = 0 --get next Downtime event outside the current window and calc the new window
begin
  select @@Start_Time = Min(Start_Time) from Timed_Event_Details where PU_Id = @MasterUnit and Start_Time > @EndTime
  select @@End_Time = DateAdd(minute, @@Duration, @@Start_Time)
end
else --get previous Downtime event outside the current window and calc the new window
begin
  select @@End_Time = Max(End_Time) from Timed_Event_Details where PU_Id = @MasterUnit and End_Time < @StartTime
  select @@Start_Time = DateAdd(minute, @@Duration * -1, @@End_Time)
end
SELECT dbo.fnServer_CmnConvertFromDbTime(@@Start_Time, @InTimeZone) as 'Start_Time', dbo.fnServer_CmnConvertFromDbTime(@@End_Time, @InTimeZone) as 'End_Time'
