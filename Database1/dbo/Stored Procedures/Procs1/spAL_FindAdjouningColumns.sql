Create Procedure dbo.spAL_FindAdjouningColumns
@Type int,
@Sheet_Id int,
@PU_Id int,
@TargetTime datetime,
@StartTime datetime OUTPUT,
@EndTime datetime OUTPUT
AS
Select @EndTime = NULL
Select @StartTime = NULL
If @Type = 1 --Event based
  Begin
 	  	 Select @StartTime = Max(TimeStamp)
 	  	   From Events
 	  	   Where TimeStamp < @TargetTime and PU_Id = @PU_Id
 	  	 Select @EndTime = Min(TimeStamp)
 	  	   From Events
 	  	   Where TimeStamp > @TargetTime and PU_Id = @PU_Id
  End
Else --Time based
  Begin
 	  	 Select @StartTime = Max(Result_On)
 	  	   From Sheet_Columns
 	  	   Where Result_On < @TargetTime and Sheet_Id = @Sheet_Id
 	  	 Select @EndTime = Min(Result_On)
 	  	   From Sheet_Columns
 	  	   Where Result_On > @TargetTime and Sheet_Id = @Sheet_Id    
  End
If @StartTime Is Null Select @StartTime = @TargetTime
If @EndTime Is Null Select @EndTime = @TargetTime
Return(0)
