CREATE PROCEDURE dbo.spServer_EMgrFutureEvents
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
  @MaxEventTime datetime,
  @MaxPreEventTime datetime,
  @MaxTime datetime
Select @Found = 0
Select @MaxYear = 0
Select @MaxMonth = 0
Select @MaxDay = 0
Select @MaxHour = 0
Select @MaxMin = 0
Select @MaxSec = 0
Select @MaxEventTime = Max(TimeStamp)
  From Events
  Where (PU_Id = @PU_Id) And 
        (TimeStamp >= @TimeStamp)
Select @MaxPreEventTime = Max(TimeStamp)
  From PreEvents
  Where (PU_Id = @PU_Id) And 
        (TimeStamp >= @TimeStamp)
If (@MaxEventTime Is Null) And (@MaxPreEventTime Is NULL)
  Return
If (@MaxEventTime Is NULL)
  Select @MaxTime = @MaxPreEventTime
Else
  If (@MaxPreEventTime Is NULL)
    Select @MaxTime = @MaxEventTime
  Else
    If (@MaxEventTime > @MaxPreEventTime)
      Select @MaxTime = @MaxEventTime
    Else
      Select @MaxTime = @MaxPreEventTime
If (@MaxTime >= @TimeStamp)
  Begin
    Select @Found = 1
    Select @MaxYear = DatePart(Year,@MaxTime)
    Select @MaxMonth = DatePart(Month,@MaxTime)
    Select @MaxDay = DatePart(Day,@MaxTime)
    Select @MaxHour = DatePart(Hour,@MaxTime)
    Select @MaxMin = DatePart(Minute,@MaxTime)
    Select @MaxSec = DatePart(Second,@MaxTime)
  End
