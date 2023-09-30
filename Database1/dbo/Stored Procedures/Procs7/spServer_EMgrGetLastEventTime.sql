CREATE PROCEDURE dbo.spServer_EMgrGetLastEventTime
@PU_Id int,
@EYear int OUTPUT,
@EMonth int OUTPUT,
@EDay int OUTPUT,
@EHour int OUTPUT,
@EMin int OUTPUT
 AS
Declare
  @TimeStamp Datetime
Select @EYear = 0
Select @EMonth = 0
Select @EDay = 0
Select @EHour = 0
Select @EMin = 0
Select @TimeStamp = Max(TimeStamp) From Events Where (PU_Id = @PU_Id)
If (@TimeStamp Is Null)
  Return
Select @EYear = Datepart(Year,@TimeStamp)
Select @EMonth = Datepart(Month,@TimeStamp)
Select @EDay = Datepart(Day,@TimeStamp)
Select @EHour = Datepart(Hour,@TimeStamp)
Select @EMin = Datepart(Minute,@TimeStamp)
