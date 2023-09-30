CREATE PROCEDURE dbo.spServer_EMgrEventExistsEx
@PU_Id int,
@Event_Num nVarChar(100),
@TrimDir int,
@TrimNum int,
@NumDays int,
@EYear int OUTPUT,
@EMonth int OUTPUT,
@EDay int OUTPUT,
@EHour int OUTPUT,
@EMinute int OUTPUT,
@ESecond int OUTPUT,
@ActualPUId int OUTPUT,
@Found int OUTPUT
AS
-- Trim Dir
--   1 - Left
--   2 - Right
Declare
  @TimeStamp datetime,
  @StartTime datetime
Select @StartTime = dbo.fnServer_CmnGetDate(GetUTCDate())
If (@NumDays <= 0)
  Select @StartTime = DateAdd(DAY,-1,@StartTime)
Else
  Select @StartTime = DateAdd(DAY,-@NumDays,@StartTime)
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
    If (@TrimNum <= 0)
      Select @Found = Event_Id,@TimeStamp = TimeStamp,@ActualPUId = PU_Id From Events Where (Event_Num = @Event_Num)
    Else
      Begin
 	 Select @TimeStamp = NULL
 	 If (@TrimDir = 1) 
          Begin
 	     Select @TimeStamp = Max(TimeStamp) 
            From Events 
            Where (TimeStamp > @StartTime) And 
                  (SubString(Event_Num,@TrimNum + 1,100) = @Event_Num)
          End
        Else
          Begin
 	     Select @TimeStamp = Max(TimeStamp) 
            From Events 
            Where (TimeStamp > @StartTime) And 
                  (SubString(Event_Num,1,Len(@Event_Num)) = @Event_Num)
          End
 	 If (@TimeStamp Is NULL)
  	   Select @Found = NULL
        Else 
          Begin
            Select @Found = 1
       	     Select @ActualPUId = PU_Id 
              From Events 
              Where (TimeStamp = @TimeStamp) And 
                (SubString(Event_Num,@TrimNum + 1,100) = @Event_Num)
          End
      End
    If @Found Is NULL
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
    Return
  End
Select @TimeStamp = NULL
if (@TrimNum <= 0)
  Select @TimeStamp = TimeStamp From PreEvents Where (PU_Id = @PU_Id) And (Event_Num = @Event_Num)
Else
  Begin
    Select @TimeStamp = NULL
    If (@TrimDir = 1) 
      Begin
 	 Select @TimeStamp = Max(TimeStamp) 
        From PreEvents 
        Where (TimeStamp > @StartTime) And 
              (SubString(Event_Num,@TrimNum + 1,100) = @Event_Num)
      End
    Else
      Begin
 	 Select @TimeStamp = Max(TimeStamp) 
        From PreEvents 
        Where (TimeStamp > @StartTime) And 
              (SubString(Event_Num,1,Len(@Event_Num)) = @Event_Num)
      End
  End
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
If (@TrimNum <= 0)
  Select @Found = Event_Id,@TimeStamp = TimeStamp From Events Where (PU_Id = @PU_Id) And (Event_Num = @Event_Num)
Else
  Begin
    Select @TimeStamp = NULL
    If (@TrimDir = 1) 
      Begin
 	 Select @TimeStamp = Max(TimeStamp) 
        From Events 
        Where (PU_Id = @PU_Id) And
              (TimeStamp > @StartTime) And 
              (SubString(Event_Num,@TrimNum + 1,100) = @Event_Num)
      End
    Else
      Begin
 	 Select @TimeStamp = Max(TimeStamp) 
        From Events 
        Where (PU_Id = @PU_Id) And
 	       (TimeStamp > @StartTime) And 
              (SubString(Event_Num,1,Len(@Event_Num)) = @Event_Num)
      End
    If (@TimeStamp Is NULL)
      Select @Found = NULL
    Else 
      Begin
        Select @Found = 1
        Select @ActualPUId = PU_Id 
          From Events 
          Where (TimeStamp = @TimeStamp) And 
                (SubString(Event_Num,@TrimNum + 1,100) = @Event_Num)
      End
  End
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
