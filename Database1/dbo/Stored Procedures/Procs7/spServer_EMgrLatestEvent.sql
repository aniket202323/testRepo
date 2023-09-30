CREATE PROCEDURE dbo.spServer_EMgrLatestEvent
@PU_Id int,
@Event_Num nVarChar(100) OUTPUT,
@Year int OUTPUT,
@Month int OUTPUT,
@Day int OUTPUT,
@Hour int OUTPUT,
@Minute int OUTPUT,
@Second int OUTPUT,
@Found int OUTPUT
 AS
Declare
  @EventTime datetime,
  @PreEventTime datetime,
  @EventNum nVarChar(50),
  @PreEventNum nvarchar(50)
Select @Found = 0
Select @Event_Num = ''
Select @EventTime = NULL
Select @EventNum = Event_Num,
       @EventTime = TimeStamp
  From Events 
  Where (PU_Id = @PU_Id) And (TimeStamp = (Select Max(TimeStamp) From Events Where (PU_Id = @PU_Id)))
Select @PreEventTime = NULL
Select @PreEventNum = Event_Num,
       @PreEventTime = TimeStamp
  From PreEvents 
  Where (PU_Id = @PU_Id) And (TimeStamp = (Select Max(TimeStamp) From PreEvents Where (PU_Id = @PU_Id)))
If (@EventTime Is NULL) And (@PreEventTime Is NULL)
  Return
Select @Found = 1
If (@PreEventTime Is NULL)
  Begin
    Select @Event_Num = @EventNum
    Select @Year = DatePart(Year,@EventTime)
    Select @Month = DatePart(Month,@EventTime)
    Select @Day = DatePart(Day,@EventTime)
    Select @Hour = DatePart(Hour,@EventTime)
    Select @Minute = DatePart(Minute,@EventTime)
    Select @Second = DatePart(Second,@EventTime)
    Return
  End
If (@EventTime Is NULL)
  Begin
    Select @Event_Num = @PreEventNum
    Select @Year = DatePart(Year,@PreEventTime)
    Select @Month = DatePart(Month,@PreEventTime)
    Select @Day = DatePart(Day,@PreEventTime)
    Select @Hour = DatePart(Hour,@PreEventTime)
    Select @Minute = DatePart(Minute,@PreEventTime)
    Select @Second = DatePart(Second,@PreEventTime)
    Return
  End
If (@EventTime > @PreEventTime)
  Begin
    Select @Event_Num = @EventNum
    Select @Year = DatePart(Year,@EventTime)
    Select @Month = DatePart(Month,@EventTime)
    Select @Day = DatePart(Day,@EventTime)
    Select @Hour = DatePart(Hour,@EventTime)
    Select @Minute = DatePart(Minute,@EventTime)
    Select @Second = DatePart(Second,@EventTime)
    Return
  End
Select @Event_Num = @PreEventNum
Select @Year = DatePart(Year,@PreEventTime)
Select @Month = DatePart(Month,@PreEventTime)
Select @Day = DatePart(Day,@PreEventTime)
Select @Hour = DatePart(Hour,@PreEventTime)
Select @Minute = DatePart(Minute,@PreEventTime)
Select @Second = DatePart(Second,@PreEventTime)
