Create  Procedure [dbo].[spMSITopic_CalculateStartandEndTimes]
@RangeType int,
@StartTime DateTime Output,
@EndTime   DateTime Output,
@PUId 	    Int
 AS
/*
Type 1 = Day
Type 2 = Shift
Type 3 = 24 Hour
Declare @StartTime DateTime,@EndTime DateTime,@PUId Int
Select @PUId = null
Execute spMSITopic_CalculateStartandEndTimes 2,@StartTime Output,@EndTime Output,@PUId
Select @StartTime,@EndTime
*/
Declare @Now 	  	  	 DateTime,
 	  	 @TotalMinutes 	 Int,
 	  	 @Hour 	  	  	 Int,
 	  	 @Minute 	  	  	 Int,
 	  	 @ShiftInt 	  	 Int,
 	  	 @ShiftOffset 	 Int
Select @EndTime =    dbo.fnServer_CmnGetDate(GetutcDate())
Select @Now = @EndTime
If @RangeType = 1
  BEGIN
 	 SELECT @StartTime = dbo.fnCMN_CalculateDayStartTime(@PUId)
  END
Else If @RangeType = 2
  Begin
 	 Select @StartTime = dbo.fnCMN_CalculateShiftStartTime(@PUId)
  End
Else If @RangeType = 3
  Begin
 	   Select @StartTime = Dateadd(Day,-1,@EndTime) 
  End
