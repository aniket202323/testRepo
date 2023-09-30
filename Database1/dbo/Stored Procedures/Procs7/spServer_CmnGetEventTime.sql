CREATE PROCEDURE dbo.spServer_CmnGetEventTime
@MasterUnit int,
@EventNum nVarChar(50),
@UseLike int,
@EYear int OUTPUT,
@EMonth int OUTPUT,
@EDay int OUTPUT,
@EHour int OUTPUT,
@EMinute int OUTPUT,
@ESecond int OUTPUT,
@Success int OUTPUT
 AS
Declare
  @TimeStamp datetime
Select @Success = 0
Select @EYear = 0
Select @EMonth = 0
Select @EDay = 0
Select @EHour = 0
Select @EMinute = 0
Select @ESecond = 0
Select @TimeStamp = NULL
If (@UseLike = 1)
  Select @TimeStamp = Max(TimeStamp) From Events Where (PU_Id = @MasterUnit) And (Event_Num Like '%' + @EventNum + '%')
Else
  Select @TimeStamp = TimeStamp From Events Where (PU_Id = @MasterUnit) And (Event_Num = @EventNum)
If (@TimeStamp Is Null)
  Return
Select @EYear = DatePart(Year,@TimeStamp)
Select @EMonth = DatePart(Month,@TimeStamp)
Select @EDay = DatePart(Day,@TimeStamp)
Select @EHour = DatePart(Hour,@TimeStamp)
Select @EMinute = DatePart(Minute,@TimeStamp)
Select @ESecond = DatePart(Second,@TimeStamp)
Select @Success = 1
