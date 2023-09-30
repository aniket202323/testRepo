CREATE PROCEDURE dbo.spServer_EMgrGetLastWasteEvent
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
  @MaxTime datetime
Select @Found = 0
Select @MaxYear = 0
Select @MaxMonth = 0
Select @MaxDay = 0
Select @MaxHour = 0
Select @MaxMin = 0
Select @MaxSec = 0
Select @MaxTime = Max(TimeStamp)
  From Waste_Event_Details
  Where (PU_Id = @PU_Id)
If (@MaxTime Is Null)
  Return
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
