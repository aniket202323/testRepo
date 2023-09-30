CREATE PROCEDURE dbo.spServer_EMgrGetRunningEvent
@PU_Id int,
@Event_Id int OUTPUT,
@EYear int OUTPUT,
@EMonth int OUTPUT,
@EDay int OUTPUT,
@EHour int OUTPUT,
@EMin int OUTPUT,
@EventNum nvarchar(50) OUTPUT
 AS
Declare
  @TimeStamp Datetime
Select @Event_Id = Event_Id ,
       @TimeStamp = TimeStamp,
       @EventNum = Event_Num
  From Events
  Where (PU_Id = @PU_Id) And 
        (TimeStamp = 
           (Select Min(TimeStamp) From Events Where (PU_Id = @PU_Id) And (Event_Status = 4)))
If @Event_Id Is Null
  Begin
    Select @Event_Id = 0
    Return
  End
Select @EYear = DatePart(Year,@TimeStamp)
Select @EMonth = DatePart(Month,@TimeStamp)
Select @EDay = DatePart(Day,@TimeStamp)
Select @EHour = DatePart(Hour,@TimeStamp)
Select @EMin = DatePart(Minute,@TimeStamp)
