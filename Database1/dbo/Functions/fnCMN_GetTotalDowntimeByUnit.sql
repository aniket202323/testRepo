CREATE FUNCTION dbo.fnCMN_GetTotalDowntimeByUnit(@StartTime DATETIME, @EndTime DATETIME, @Unit INT, @FILTER_NP_TIME INT) 
     RETURNS @UnitDowntime Table (TotalDowntimeSeconds INT, TotalCount INT)
AS 
Begin
--*********************************************/
/***********************************************
set nocount on
Declare @UnitDowntime Table (TotalDowntimeSeconds INT, TotalCount INT)
Declare @Unit int, @StartTime datetime, @EndTime datetime, @FILTER_NP_TIME int, @Case int
Select @Unit = 9, @FILTER_NP_TIME=0,  @StartTime='2006-01-02 01:12:00', @EndTime='2006-01-02 01:34:00'
Select @StartTime='2006-08-30 22:48:00', @EndTime='2006-08-30 23:00:00'
select @Filter_NP_Time=0, @Unit=9, @StartTime='2006-08-30 22:36:00', @EndTime='2006-08-30 23:12:00'
Select @StartTime='2006-08-30 07:00:00', @EndTime='2006-08-30 07:12:00'
Select @StartTime='2006-08-30 07:12:00', @EndTime='2006-08-30 07:36:00'
-- 10 to 10:12 did not get credit
-- 20:48 to 21:00 did not get credit for 2nd dt event
-- what about events that are not linked and dt begins before an event begins
Select @STartTime [@Start_Time], @EndTime [@EndTime]
--*********************************************/
--------------------------------------------------------------
-- Local Variables
--------------------------------------------------------------
 	 Declare @TotalDowntime int
 	 Declare @TotalCount int
 	 Declare @TotalNPTTime int
 	 -- Initialize Local Variables
 	 select @TotalDowntime = 0, @TotalCount = 0, @TotalNPTTime=0
 	 -- Initialized Filter Default = Do Not Filter
 	 If @FILTER_NP_TIME Is Null Select @FILTER_NP_TIME = 0
 	 -- Table to hold downtime rows
 	 Declare @LocalUnitDowntime Table (Start_Time datetime, End_Time dateTime, NP_Time int)
 	 -- Insert Matching Downtime Rows
 	 insert into @LocalUnitDowntime(Start_Time, End_Time)
 	  	 select Start_Time, End_Time 
 	  	 from timed_event_details d
 	  	 Where  d.pu_id = @Unit 
 	  	 and (d.Start_Time < @EndTime and (d.End_Time > @StartTime or  d.End_Time is null)) 	 
--select * from @LocalUnitDowntime
 	 ----------------------------------------------------------- 	 
 	 -- Only count downtime events as a unique event if it began during the selected time range
 	 -- this is to avoid double counting of the downtime event as a unique occurance
 	 -- the actual downtime will be included
 	 -----------------------------------------------------------
 	 -- Update Timestamps in accordance with Requested Time Range
 	 Update @LocalUnitDowntime Set End_Time = @EndTime where End_Time is null
 	 
 	 Select @TotalCount = Coalesce(Count(Start_Time), 0) From @LocalUnitDowntime 
 	 --Where @StartTime <= End_Time and End_Time < @EndTime
 	 Where @StartTime <= Start_Time and Start_Time < @EndTime
 	 --Where @StartTime < Start_Time and Start_Time <= @EndTime  -- too few
 	 --Where End_Time >= @StartTime and End_Time < @EndTime  -- this works but Wade doesn't like it
 	 --where Start_Time > @StartTime and Start_Time <= @EndTime
 	 --where Start_Time between @StartTime and @EndTime
 	 
 	 Update @LocalUnitDowntime Set Start_Time = @StartTime Where Start_Time < @StartTime
 	 Update @LocalUnitDowntime Set End_Time = @EndTime where End_Time > @EndTime
 	 -- Get NP Time for each downtime event
 	 Update @LocalUnitDowntime Set NP_Time = dbo.fnCmn_SecondsNPTime(@Unit, Start_Time, End_Time)
 	 Delete from @LocalUnitDowntime where Start_Time = @EndTime
 	 
 	 Select @TotalDowntime = @TotalDowntime + Coalesce(Sum(DateDiff(second, Start_Time, End_Time)), 0), 
 	  	  	 @TotalNPTTime = @TotalNPTTime + Coalesce(Sum(NP_Time), 0)
 	 From @LocalUnitDowntime
 	 -- Filter out NP time if required
 	 If @FILTER_NP_TIME > 0
 	  	 If @TotalNPTTime > @TotalDowntime
 	  	  	 Select @TotalNPTTime = 0
 	  	 Else
 	  	  	 Select @TotalDowntime = @TotalDowntime - @TotalNPTTime
 	 -- copy to the result of the function the required columns
 	 insert Into @UnitDowntime(TotalDowntimeSeconds, TotalCount)
 	 Values(@TotalDowntime, @TotalCount)
--select * from @UnitDowntime
--/***************************
     RETURN
END
--*************************/
