/*
Declare @EventStartTime datetime, @EventEndTime datetime, @NPStartTime datetime, @NPEndTime datetime, @ActualProduction FLOAT
Select @EventStartTime='2006-01-26 13:00:00.000', @EventEndTime='2006-01-26 14:00:00.000', @ActualProduction=60.225
Select @NPStartTime='2006-01-26 12:00:00.000', @NPEndTime='2006-01-26 14:59:00.000' -- Case A
Select @NPStartTime='2006-01-26 13:05:00.000', @NPEndTime='2006-01-26 13:59:00.000' -- Case B
Select @NPStartTime='2006-01-26 12:00:00.000', @NPEndTime='2006-01-26 13:35:00.000' -- Case C
Select @NPStartTime='2006-01-26 13:25:00.000', @NPEndTime='2006-01-26 14:35:00.000' -- Case D
Select @NPStartTime=NULL, @NPEndTime=NULL -- Case A
select dbo.fnCMN_GetProRatedProduction(@EventStartTime, @EventEndTime, @NPStartTime, @NPEndTime, @ActualProduction)
 	 x- If the time range is encompassed by NP time, then NULL is returned for the start and end time
 	 - If the time is different than the start time or end time, then it's being affected by NP time
 	 - If the time range contains NP time, then the normal start time and end time are returned
 	 - If the time range is not affected by NP time, then the normal start time and end time are returned
EventTime  ----|--------|------>
Case A      |--------------|      Event is fully contained within NP Time - Production = 0
Case B           |----|           NP Time is fully contained within the event - Production is prorated (take out all NP time)
Case C     |------|               NP time was occuring when event started - prorate from NP End to event end
Case D              |------|      NP time began during an event and ended afterwards - prorate from event starttime to np starttime
*/
CREATE FUNCTION dbo.fnCMN_GetProRatedProduction(@EventStartTime DATETIME, @EventEndTime DATETIME, @NPStartTime DATETIME, @NPEndTime DATETIME, @ActualProduction FLOAT) 
     RETURNS FLOAT 
AS 
Begin
 	 Declare @ProRatedProduction FLOAT
 	 Declare @EventTime int, @ProRateTime int, @Case nVarChar(10)
 	 Select @EventTime = DateDiff(s, @EventStartTime, @EventEndTime)
 	 If ((@NPStartTime is null) AND (@NPEndTime IS Null)) or (@NPStartTime <= @EventStartTime and @NPEndTime >= @EventEndTime)
 	  	 Begin
 	  	  	 -- Case A - Event is fully contained within NP time
 	  	  	 Select @Case = 'Case A'
 	  	  	 Select @ProRateTime = 0
 	  	 End
 	 Else if (@NPStartTime Between @EventStartTime and @EventEndTime) and (@NPEndTime Between @EventStartTime and @EventEndTime)
 	  	 Begin
 	  	  	 -- Case B - NP Time Fully Contained within event
 	  	  	 Select @Case = 'Case B'
 	  	  	 Select @ProRateTime = DateDiff(s, @EventStartTime, @NPStartTime) + DateDiff(s, @NPEndTime, @EventEndTime)
 	  	 End
 	 Else if (@NPStartTime NOT Between @EventStartTime and @EventEndTime) and (@NPEndTime Between @EventStartTime and @EventEndTime)
 	  	 Begin
 	  	  	 -- Case C - NP Time was already occuring when event begain
 	  	  	 Select @Case = 'Case C'
 	  	  	 Select @ProRateTime = DateDiff(s, @NPEndTime, @EventEndTime)
 	  	 End
 	  	  	  	 
 	 Else
 	  	 Begin
 	  	  	 -- Case D - NP time begain during an event and ended afterwards
 	  	  	 Select @Case = 'Case D'
 	  	  	 Select @ProRateTime = DateDiff(s, @EventStartTime, @NPStartTime)
 	  	 End
 	  	  	 
/*
Print @Case
Print 'EventTime=' + convert(nVarChar(10), @EventTime) + ' seconds'
Print 'ProRateTime=' + convert(nVarChar(10), @ProRateTime) + ' seconds'
*/
Select @ProRatedProduction = (@ActualProduction / @EventTime) * @ProRateTime
--Select @ActualProduction [ActualProduction], @ProRatedProduction [ProRatedProduction]
     RETURN @ProRatedProduction
END
