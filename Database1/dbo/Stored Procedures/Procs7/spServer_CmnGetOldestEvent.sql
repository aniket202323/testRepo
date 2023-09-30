CREATE PROCEDURE dbo.spServer_CmnGetOldestEvent
@PU_Id int,
@Event_Status int,
@Success int OUTPUT,
@Event_Id int OUTPUT,
@EYear int OUTPUT,
@EMonth int OUTPUT,
@EDay int OUTPUT,
@EHour int OUTPUT,
@EMin int OUTPUT
 AS
Declare
  @TimeStamp Datetime
Select @Success = 0
Select @Event_Id = Event_Id,
       @TimeStamp = TimeStamp
  From Events
  Where (PU_Id = @PU_Id) And
        (TimeStamp = (Select Min(TimeStamp) From Events Where (PU_Id = @PU_Id) And (Event_Status = @Event_Status)))
If (@Event_Id Is Not Null) And (@TimeStamp Is Not Null)
  Begin
    Select @Success = 1
    Select @EYear = DatePart(Year,@TimeStamp)
    Select @EMonth = DatePart(Month,@TimeStamp)
    Select @EDay = DatePart(Day,@TimeStamp)
    Select @EHour = DatePart(Hour,@TimeStamp)
    Select @EMin = DatePart(Minute,@TimeStamp)
  End
