Create Procedure dbo.spWD_GetMergeCount
@PU_Id int,
@StartTime datetime,
@EndTime datetime,
@MergeCount int OUTPUT
AS
If @EndTime is null
 	 Select @MergeCount = Count(*) 
 	   From Timed_Event_Details
 	   Where PU_Id = @PU_Id
 	   And Start_Time >= @StartTime
Else
 	 Begin
 	  	 Select @MergeCount = Count(*) 
 	  	   From Timed_Event_Details
 	  	   Where PU_Id = @PU_Id   And Start_Time >= @StartTime  And End_Time <= @EndTime
 	  	 Select @MergeCount = @MergeCount + Count(*) 
 	  	   From Timed_Event_Details
 	  	   Where PU_Id = @PU_Id   And Start_Time >= @StartTime and End_Time is NULL and Start_Time < @EndTime
 	 End
