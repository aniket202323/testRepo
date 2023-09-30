CREATE PROCEDURE dbo.spServer_EMgrEventExists
@PU_Id int,
@Event_Num nVarChar(100),
@EYear int OUTPUT,
@EMonth int OUTPUT,
@EDay int OUTPUT,
@EHour int OUTPUT,
@EMinute int OUTPUT,
@ESecond int OUTPUT,
@ActualPUId int OUTPUT,
@Found int OUTPUT
 AS
Declare
  @TimeStamp datetime
Select @EYear = 0
Select @EMonth = 0
Select @EDay = 0
Select @EHour = 0
Select @EMinute = 0
Select @ESecond = 0
Select @ActualPUId = @PU_Id
If (@PU_Id = 0)
  Begin
    Select @Found = NULL
    Select @Found = Event_Id,@TimeStamp = TimeStamp,@ActualPUId = PU_Id From Events Where (Event_Num = @Event_Num)
    If @Found Is NULL
      Select @Found = 0
    Select @EYear = DatePart(Year,@TimeStamp)
    Select @EMonth = DatePart(Month,@TimeStamp)
    Select @EDay = DatePart(Day,@TimeStamp)
    Select @EHour = DatePart(Hour,@TimeStamp)
    Select @EMinute = DatePart(Minute,@TimeStamp)
    Select @ESecond = DatePart(Second,@TimeStamp)
    Return
  End
Select @TimeStamp = NULL
Select @TimeStamp = TimeStamp From PreEvents Where (PU_Id = @PU_Id) And (Event_Num = @Event_Num)
If @TimeStamp Is Not NULL
  Begin
    Select @Found = -1
    Select @EYear = DatePart(Year,@TimeStamp)
    Select @EMonth = DatePart(Month,@TimeStamp)
    Select @EDay = DatePart(Day,@TimeStamp)
    Select @EHour = DatePart(Hour,@TimeStamp)
    Select @EMinute = DatePart(Minute,@TimeStamp)
    Select @ESecond = DatePart(Second,@TimeStamp)
    Return
  End
Select @Found = NULL
Select @Found = Event_Id,@TimeStamp = TimeStamp From Events Where (PU_Id = @PU_Id) And (Event_Num = @Event_Num)
If @Found Is Null
  Select @Found = 0
Else
  Begin
    Select @EYear = DatePart(Year,@TimeStamp)
    Select @EMonth = DatePart(Month,@TimeStamp)
    Select @EDay = DatePart(Day,@TimeStamp)
    Select @EHour = DatePart(Hour,@TimeStamp)
    Select @EMinute = DatePart(Minute,@TimeStamp)
    Select @ESecond = DatePart(Second,@TimeStamp)
  End
