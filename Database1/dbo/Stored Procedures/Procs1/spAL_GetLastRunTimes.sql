Create Procedure dbo.spAL_GetLastRunTimes
@UnitId int,
@Prod_Id int,
@RelativeTime datetime,
@StartTime datetime OUTPUT,
@EndTime datetime OUTPUT
AS
Select @StartTime = Start_Time, @EndTime = End_Time
  From Production_Starts
  Where PU_Id = @UnitId and
        End_Time = 
       (Select max(end_time) 
         From Production_Starts
           Where PU_Id = @UnitId and
            Prod_Id = @Prod_Id and
            Start_Time < @RelativeTime and
            End_Time < @RelativeTime) 
If @StartTime Is Not Null 
  return(100)
Else
  return(1)
