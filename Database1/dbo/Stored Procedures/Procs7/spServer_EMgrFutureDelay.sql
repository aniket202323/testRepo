CREATE PROCEDURE dbo.spServer_EMgrFutureDelay
@PU_Id int,
@TimeStamp datetime,
@Found int OUTPUT,
@MaxYear int OUTPUT,
@MaxMonth int OUTPUT,
@MaxDay int OUTPUT,
@MaxHour int OUTPUT,
@MaxMin int OUTPUT,
@MaxSec int OUTPUT
 AS
Declare
  @MaxStartTime datetime,
  @MaxEndTime datetime,
  @MaxTime datetime
Select @Found = 0
Select @MaxYear = 0
Select @MaxMonth = 0
Select @MaxDay = 0
Select @MaxHour = 0
Select @MaxMin = 0
Select @MaxSec = 0
Select @MaxEndTime = NULL
Select @MaxEndTime = Max(End_Time)
  From Timed_Event_Details
  Where (PU_Id = @PU_Id) And
        (End_Time Is Not Null)  
Select @MaxStartTime = NULL
Select @MaxStartTime = Max(Start_Time)
  From Timed_Event_Details
  Where (PU_Id = @PU_Id)
If (@MaxStartTime Is Null) And (@MaxEndTime Is Null)
  Return
If (@MaxStartTime Is Null)
  Select @MaxTime = @MaxEndTime
Else
  If (@MaxEndTime Is Null)
    Select @MaxTime = @MaxStartTime
  Else
    Begin
      If (@MaxEndTime > @MaxStartTime)
        Select @MaxTime = @MaxEndTime
      Else
        Select @MaxTime = @MaxStartTime
    End
-- MPP(1/11/08): This used to be >=, but to allow for a new event to start at the same end time of the prev event, I changed it
If (@MaxTime > @TimeStamp)
  Begin
    Select @Found = 1
    Select @MaxYear = DatePart(Year,@MaxTime)
    Select @MaxMonth = DatePart(Month,@MaxTime)
    Select @MaxDay = DatePart(Day,@MaxTime)
    Select @MaxHour = DatePart(Hour,@MaxTime)
    Select @MaxMin = DatePart(Minute,@MaxTime)
    Select @MaxSec = DatePart(Second,@MaxTime)
  End
