CREATE PROCEDURE dbo.spServer_StbChkEventStub
@PU_Id int,
@TimeStamp datetime,
@SheetId int,
@DoAll int OUTPUT,
@NumEventsIntoRun int OUTPUT,
@Prod_Id int OUTPUT,
@SYear int OUTPUT,
@SMonth int OUTPUT,
@SDay int OUTPUT,
@SHour int OUTPUT,
@SMinute int OUTPUT,
@SSecond int OUTPUT,
@EventType int = 1,
@EventSubtype int = 0
AS
Declare
  @Prev_TimeStamp datetime,
  @Run_Start datetime,
  @Prev_Run_Start datetime,
  @Prev_Prod_Id int,
  @Prev_Testing_Status int,
  @LastResetTime datetime,
  @FreqStartTime datetime
Select @DoAll = 1
Select @NumEventsIntoRun = 1
Select @Run_Start = Start_Time, 
       @Prod_Id   = Prod_Id,
       @SYear     = DatePart(Year,Start_Time),
       @SMonth    = DatePart(Month,Start_Time),
       @SDay      = DatePart(Day,Start_Time),
       @SHour     = DatePart(Hour,Start_Time),
       @SMinute   = DatePart(Minute,Start_Time),
       @SSecond   = DatePart(Second,Start_Time)
  From Production_Starts 
  Where (PU_Id = @PU_Id) And 
        (Start_Time < @TimeStamp) And 
        ((End_Time >= @TimeStamp) Or (End_Time Is Null))
If @Run_Start = '1-Jan-1970' and @Prod_Id = 1 
  Return
if (@SheetId > 0)
  begin
    Select @Prev_TimeStamp = NULL
    Select TOP 1 @Prev_TimeStamp = 
 	 --Max(Result_On)
 	 Result_On
 	 From Sheet_Columns Where (Sheet_Id = @SheetId) And (Result_On < @TimeStamp) ORDER BY Result_On DESC
    If (@Prev_TimeStamp Is NULL)
      return
    Select @Prev_Run_Start = Start_Time,
           @Prev_Prod_Id = Prod_Id
      From Production_Starts 
      Where (PU_Id = @PU_Id) and 
            (Start_Time < @Prev_TimeStamp) and 
            ((End_Time >= @Prev_TimeStamp) or (End_Time Is Null))
    If @Prod_Id <> @Prev_Prod_Id
      Return
    Select @DoAll = 0
    Select @NumEventsIntoRun = Count(Result_On) 
      From Sheet_Columns
      Where (Sheet_Id = @SheetId) And 
            (Result_On > @Prev_Run_Start) And 
            (Result_On < @TimeStamp)
  end
else
  begin
    Select @Prev_TimeStamp = NULL
    if (@EventType = 1) -- Production
      Select 
 	   TOP 1 @Prev_TimeStamp = 
 	   --Max(Timestamp) 
 	   Timestamp
 	   From Events Where (PU_Id = @PU_Id) And (TimeStamp < @TimeStamp) Order by Timestamp Desc
    else if (@EventType = 2) -- Downtime
      Select TOP 1 @Prev_TimeStamp = 
 	   --Max(End_Time) 
 	   End_Time
 	   From Timed_Event_Details Where (PU_Id = @PU_Id) And (End_Time < @TimeStamp) Order By End_Time DESC
    else if (@EventType = 3) -- Waste
      Select TOP 1 @Prev_TimeStamp = 
 	   --Max(Timestamp) 
 	   Timestamp 
 	   From Waste_Event_Details Where (PU_Id = @PU_Id) And (TimeStamp < @TimeStamp) Order by Timestamp Desc
    else if (@EventType = 14) -- UDE
      Select TOP 1 @Prev_TimeStamp = 
 	   --Max(End_Time) 
 	   End_Time
        From User_Defined_Events With(Index(UDE_IDX_PUIdESIdEndTimeTestingstatus)) 
        Where (PU_Id = @PU_Id) And (End_Time < @TimeStamp) And (Event_Subtype_id = @EventSubtype) Order by End_Time DESC
    else if (@EventType = 22) -- Uptime
      Select TOP 1 @Prev_TimeStamp = 
 	   --Max(Start_Time) 
 	   Start_Time
 	   From Timed_Event_Details Where (PU_Id = @PU_Id) And (Start_Time < @TimeStamp) Order by Start_Time DESC
    If (@Prev_TimeStamp Is NULL)
      return
    Select @Prev_Testing_Status = 1
    if (@EventType = 1) -- Production
      Select @Prev_Testing_Status = Testing_Status From Events Where (PU_Id = @PU_Id) and (TimeStamp = @Prev_TimeStamp)
    else if (@EventType = 14) -- UDE
      Select @Prev_Testing_Status = Testing_Status From User_Defined_Events Where (PU_Id = @PU_Id) and (End_Time = @Prev_TimeStamp) And (Event_Subtype_id = @EventSubtype)
    If (@Prev_Testing_Status = 3)
      Return
    Select @Prev_Run_Start = Start_Time,
           @Prev_Prod_Id = Prod_Id
      From Production_Starts 
      Where (PU_Id = @PU_Id) and 
            (Start_Time < @Prev_TimeStamp) and 
            ((End_Time >= @Prev_TimeStamp) or (End_Time Is Null))
    If @Prod_Id <> @Prev_Prod_Id
      Return
    Select @LastResetTime = NULL
    if (@EventType = 1) -- Production
      Select TOP 1 @LastResetTime = 
 	   --Max(TimeStamp) 
 	   TimeStamp
 	   From Events Where (PU_Id = @PU_Id) And (TimeStamp < @TimeStamp) And (TimeStamp > @Prev_Run_Start) and (Testing_Status = 3) Order by TimeStamp DESC
    else if (@EventType = 14) -- UDE
      Select TOP 1 @LastResetTime = 
 	   --Max(End_Time) 
 	   End_Time
 	   From User_Defined_Events With(Index(UDE_IDX_PUIdESIdEndTimeTestingstatus)) Where (PU_Id = @PU_Id) And (End_Time < @TimeStamp) And (End_Time > @Prev_Run_Start) And (Event_Subtype_id = @EventSubtype) and (Testing_Status = 3)
 	   ORDER BY End_Time DESC
    If (@LastResetTime Is NULL) Or (@LastResetTime < @Prev_Run_Start)
      Select @FreqStartTime = @Prev_Run_Start
    Else
      Select @FreqStartTime = @LastResetTime
    Select @DoAll = 0
    if (@EventType = 1) -- Production
      Select @NumEventsIntoRun = Count(Event_Id) From Events Where (PU_Id = @PU_Id) And (TimeStamp > @FreqStartTime) And (TimeStamp < @TimeStamp) And ((Testing_Status <> 2) Or (Testing_Status Is Null))
    else if (@EventType = 2) -- Downtime
      Select @NumEventsIntoRun = Count(TEDet_Id) From Timed_Event_Details Where (PU_Id = @PU_Id) And (End_Time > @FreqStartTime) And (End_Time < @TimeStamp)
    else if (@EventType = 3) -- Waste
      Select @NumEventsIntoRun = Count(WED_Id) From Waste_Event_Details Where (PU_Id = @PU_Id) And (TimeStamp > @FreqStartTime) And (TimeStamp < @TimeStamp)
    else if (@EventType = 14) -- UDE
      Select @NumEventsIntoRun = Count(UDE_Id) From User_Defined_Events Where (PU_Id = @PU_Id) And (End_Time > @FreqStartTime) And (End_Time < @TimeStamp) And (Event_Subtype_id = @EventSubtype) And ((Testing_Status <> 2) Or (Testing_Status Is Null))
    else if (@EventType = 22) -- Uptime
      Select @NumEventsIntoRun = Count(TEDet_Id) From Timed_Event_Details Where (PU_Id = @PU_Id) And (Start_Time > @FreqStartTime) And (Start_Time < @TimeStamp)
  end
Select @NumEventsIntoRun = @NumEventsIntoRun + 1
If (@NumEventsIntoRun = 1)
  Select @DoAll = 1
