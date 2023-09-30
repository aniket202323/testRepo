CREATE FUNCTION [dbo].[fnRS_wrGetCrewSchedule](
     @StartTime DateTime,
     @EndTime DateTime,
     @Unit Int)
RETURNS @retTempTable TABLE(Start_Time datetime, End_Time datetime, Shift_Desc nvarchar(10), Crew_Desc nvarchar(10))
AS
BEGIN
Declare @ReferenceTime datetime
Declare @FirstShiftTime datetime
Declare @ProductionDayStart int
Declare @ShiftLength int
Declare @NoCrew int
Declare @TodayMillStartTime datetime
Declare @YesterdayMillStartTime datetime
Declare @LastShiftStartTime datetime
Declare @TomorrowMillStartTime datetime
Declare @NextShiftStartTime datetime
Declare @MillStartTime nvarchar(8)
Declare @DayBeforeStartTime datetime
Declare @DayAfterEndTime datetime
--------------------------------------
-- Get 1st Shift Start Time For Today
--------------------------------------
Select @MillStartTime = dbo.fnRS_GetMillStartTime()
-- Get Timestamp of 1 day before and 1 day after the selected range
Select @DayBeforeStartTime = Convert(datetime, Convert(nvarchar(4),DatePart(yyyy, dateadd(d, -1, @StartTime))) + '-' + Convert(nvarchar(2), DatePart(mm, dateadd(d, -1, @StartTime))) + '-' + Convert(nvarchar(2), DatePart(dd, dateadd(d, -1, @StartTime))) + ' ' + @MillStartTime) 
Select @DayAfterEndTime =  Convert(datetime, Convert(nvarchar(4),DatePart(yyyy, dateadd(d, 1, @EndTime))) + '-' + Convert(nvarchar(2), DatePart(mm, dateadd(d, 1, @EndTime))) + '-' + Convert(nvarchar(2), DatePart(dd, dateadd(d, 1, @EndTime))) + ' ' + @MillStartTime) 
-- The start time of the first shift today
Select @TodayMillStartTime = Convert(datetime, Convert(nvarchar(4),DatePart(yyyy, @StartTime)) + '-' + Convert(nvarchar(2), DatePart(mm, @StartTime)) + '-' + Convert(nvarchar(2), DatePart(dd, @StartTime)) + ' ' + @MillStartTime)
Select @YesterdayMillStartTime = DateAdd(d, -1, @TodayMillStartTime)
Select @TomorrowMillStartTime = DateAdd(d, 1, @TodayMillStartTime)
Select @ShiftLength = (select convert(int,Value) from site_parameters where parm_id = 16)
Declare @MyCrewSchedule Table(
     Start_Time datetime,
     End_Time datetime,
     Shift_Desc nvarchar(10),
     Crew_Desc nvarchar(10)
)
--------------------------------
-- CREW SCHEDULE EXISTS
--------------------------------
If (Select count(Start_Time) From Crew_Schedule Where PU_Id = @Unit and Start_Time <= @StartTime and End_Time > @StartTime) > 0
  Begin
    -- This Event Actually Began Yesterday
     Insert Into @MyCrewSchedule(Start_Time, End_Time, Shift_Desc, Crew_Desc)
     Select Start_Time, End_Time, Shift_Desc, Crew_Desc 
     from crew_schedule 
     Where PU_ID = @Unit
          and Start_Time >= @DayBeforeStartTime
          and End_Time <= @DayAfterEndTime
  End
--------------------------------
-- CREW SCHEDULE DOES NOT EXIST
--------------------------------
Else
  Begin
     -- Begin with first shift of the the StartTime and count shifts until EndTime
     Select @NextShiftStartTime = @TodayMillStartTime
     While (@NextShiftStartTime <= @EndTime)
          Begin
               Insert Into @MyCrewSchedule(Start_Time, End_Time, Shift_Desc, Crew_Desc)        
               Values(@NextShiftStartTime, DateAdd(mi, @ShiftLength, @NextShiftStartTime),
                    Case
                         When @NextShiftStartTime < @TodayMillStartTime
                         Then DateDiff(mi, @YesterdayMillStartTime, @NextShiftStartTime) / @ShiftLength + 1
                         Else DateDiff(mi, @TodayMillStartTime, @NextShiftStartTime) / @ShiftLength + 1
                    End,
                    'Unknown'
               )
               Select @NextShiftStartTime = DateAdd(mi, @ShiftLength, @NextShiftStartTime)   
               Select @TodayMillStartTime = Convert(datetime, Convert(nvarchar(4),DatePart(yyyy, @NextShiftStartTime)) + '-' + Convert(nvarchar(2), DatePart(mm, @NextShiftStartTime)) + '-' + Convert(nvarchar(2), DatePart(dd, @NextShiftStartTime)) + ' ' + @MillStartTime)
               Select @YesterdayMillStartTime = DateAdd(d, -1, @TodayMillStartTime)
          End
  End
/*
     DECLARE @TempTable TABLE(User_Id INT, UserName VarChar(30), Password VarChar(30))
     Insert Into @TempTable
          select User_Id, UserName, Password from users
*/
   -- copy to the result of the function the required columns
   INSERT @retTempTable
     Select Start_Time, End_Time, Shift_Desc, Crew_Desc From @MyCrewSchedule
return
END
