Create Procedure dbo.spSV_UpdatePPStarts
@PP_Start_Id int,
@New_Start_Time datetime,
@New_End_Time datetime
AS
if (@New_Start_Time >= @New_End_Time and @New_End_Time is not NULL)
  return(0)
Declare @PU_Id int
Select @PU_Id = NULL
select @PU_Id = PU_Id
From Production_Plan_Starts
Where PP_Start_Id = @PP_Start_Id
--Test for overlaps
if (select count(pp_start_id) from production_plan_starts
where (((@New_Start_Time >= start_time and ((@New_Start_Time < end_time and DateDiff(Second, @New_Start_Time, end_time) <> 0) or end_time is NULL))
or (@New_End_Time > start_time and DateDiff(Second, @New_End_Time, start_time) <> 0 and (@New_End_Time <= end_time or end_time is NULL)))
and PP_Start_Id <> @PP_Start_Id and PU_Id = @PU_Id)) = 0
  Begin
--    select 'No Overlap exists!'
    Update Production_Plan_Starts
    set Start_Time = @New_Start_Time,  End_Time = @New_End_Time
    where PP_Start_Id = @PP_Start_Id
    return(1)
  End
else
  Begin
--    select 'Overlap exists!'
    return(0)
  End
