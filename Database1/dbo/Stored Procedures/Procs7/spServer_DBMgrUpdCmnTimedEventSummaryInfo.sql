CREATE PROCEDURE dbo.spServer_DBMgrUpdCmnTimedEventSummaryInfo
  @PU_Id int,
  @Start_Time datetime,
  @Case tinyint,
  @Id int OUTPUT,
  @Start datetime OUTPUT,
  @End datetime OUTPUT
AS
Declare @DebugFlag tinyint,
       	 @@ID int
/*
Insert Into User_Parameters (Parm_Id, User_Id, Value, HostName) Values(100, 6, 1, '')
update User_Parameters set value = 0 where Parm_Id = 100 and User_Id = 6
*/
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
--select @DebugFlag = 1 
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @@ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@@ID, 'in DBMgrUpdCmnTimedEventSummaryInfo /PU_Id: ' + Coalesce(convert(nVarChar(4),@PU_Id),'Null') + 
 	 ' /Start_Time: ' + Coalesce(convert(nVarChar(25),@Start_Time),'Null') + ' /Case: ' + Coalesce(convert(nVarChar(4),@Case),'Null'))
  End
  --
  -- Case
  --   (   0) Previous Summary
  --   (   1) Current Summary
  --   (   2) Next Summary
  --
  Declare @Max_Start_Time datetime,
          @Max_End_Time datetime,
          @Min_Start_Time datetime,
          @Min_End_Time datetime,
          @Local_Start_Time datetime,
          @Local_End_Time datetime,
          @SPrev_Id int, 
          @SPrev_Start datetime,
          @SPrev_End datetime,
          @SCurr_Id int, 
          @SCurr_Start datetime,
          @SCurr_End datetime,
          @SNext_Id int,
          @SNext_Start datetime,
          @SNext_End datetime,
 	  	 @TimeCheck Int
 	 select @SPrev_Id = NULL, @SPrev_Start = NULL, @SPrev_End = NULL
 	 select @SCurr_Id = NULL, @SCurr_Start = NULL, @SCurr_End = NULL
 	 select @SNext_Id = NULL, @SNext_Start = NULL, @SNext_End = NULL
  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@Start_Time = ' + Coalesce(convert(nVarChar(30), @Start_Time),'Null'))
  select @Local_Start_Time = @Start_Time
  While (0=0) 
    Begin
 	 If @Case = 0
 	   Begin
 	  	 Select @Local_Start_Time = Min(Start_Time) From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time >= @Local_Start_Time
 	   End
 	 Else If @Case = 2
 	   Begin
 	  	 Select @Local_Start_Time = Max(Start_Time) From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time < = @Local_Start_Time
 	   End
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@Local_Start_Time = ' + Coalesce(convert(nVarChar(30), @Local_Start_Time),'Null'))
 	 select @Max_Start_Time = Max(Start_Time) From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time < @Local_Start_Time
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@Max_Start_Time = ' + Coalesce(convert(nVarChar(30), @Max_Start_Time),'Null'))
 	 select @Max_End_Time = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Max_Start_Time
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@Max_End_Time = ' + Coalesce(convert(nVarChar(30), @Max_End_Time),'Null'))
 	 if @Max_Start_Time is NULL
        break
      else if @Max_End_Time <> @Local_Start_Time and @SCurr_Start is NULL
        Begin
          select @SCurr_Id = TEDet_Id, @SCurr_Start = Start_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Local_Start_Time
          select @SPrev_End = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Max_Start_Time
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SCurr_Id = ' + Coalesce(convert(nVarChar(30), @SCurr_Id),'Null'))
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SCurr_Start = ' + Coalesce(convert(nVarChar(30), @SCurr_Start),'Null'))
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SPrev_End = ' + Coalesce(convert(nVarChar(30), @SPrev_End),'Null'))
        End
      else if @Max_End_Time <> @Local_Start_Time and @SPrev_End is NOT NULL and @SPrev_Start is NULL
 	  	 Begin
 	  	  	 select @SPrev_Id = TEDet_Id, @SPrev_Start = Start_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Local_Start_Time
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SPrev_Id = ' + Coalesce(convert(nVarChar(30), @SPrev_Id),'Null'))
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SPrev_Start = ' + Coalesce(convert(nVarChar(30), @SPrev_Start),'Null'))
 	  	 End
      else if @Max_End_Time <> @Local_Start_Time
        break
      select @Local_Start_Time = @Max_Start_Time
    End
if @SCurr_Start is NULL
 	 Begin
 	   select @SCurr_Id = TEDet_Id, @SCurr_Start = Start_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Local_Start_Time  
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SCurr_Id = ' + Coalesce(convert(nVarChar(30), @SCurr_Id),'Null'))
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SCurr_Start = ' + Coalesce(convert(nVarChar(30), @SCurr_Start),'Null'))
 	 End
  select @Local_End_Time = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @SCurr_Start
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@Local_End_Time = ' + Coalesce(convert(nVarChar(30), @Local_End_Time),'Null'))
  While (0=0) 
    Begin
      select @Min_Start_Time = Min(Start_Time) From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time >= @Local_End_Time
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@Min_Start_Time = ' + Coalesce(convert(nVarChar(30), @Min_Start_Time),'Null'))
      select @Min_End_Time = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Min_Start_Time
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@Min_End_Time = ' + Coalesce(convert(nVarChar(30), @Min_End_Time),'Null'))
      if @Min_Start_Time is NULL
        break
      else if @Min_Start_Time <> @Local_End_Time and @SCurr_End is NULL
        Begin
          select @SCurr_End = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and End_Time = @Local_End_Time
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SCurr_End = ' + Coalesce(convert(nVarChar(30), @SCurr_End),'Null'))
          select @SNext_Id = TEDet_Id, @SNext_Start = Start_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Min_Start_Time        
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SNext_Id = ' + Coalesce(convert(nVarChar(30), @SNext_Id),'Null'))
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SNext_Start = ' + Coalesce(convert(nVarChar(30), @SNext_Start),'Null'))
        End
      else if @Min_Start_Time <> @Local_End_Time and @SNext_Start is NOT NULL and @SNext_End is NULL
 	  	  	  	 Begin
 	         select @SNext_End = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and End_Time = @Local_End_Time
 	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@SNext_End = ' + Coalesce(convert(nVarChar(30), @SNext_End),'Null'))
 	  	  	  	 End
      else if @Min_Start_Time <> @Local_End_Time or @Min_Start_Time = @Min_End_Time
        break
      select @Local_End_Time = @Min_End_Time
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@Local_End_Time = ' + Coalesce(convert(nVarChar(30), @Local_End_Time),'Null'))
     End
if @SCurr_End is NULL
 	 Begin
 	   select @SCurr_End = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and End_Time = @Local_End_Time
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, '@Local_End_Time = ' + Coalesce(convert(nVarChar(30), @Local_End_Time),'Null'))
 	 End
If @Case = 0  --Previous Summary
  select @Id = @SPrev_Id, @Start = @SPrev_Start, @End = @SPrev_End
Else if @Case = 1  --Current Summary
  select @Id = @SCurr_Id, @Start = @SCurr_Start, @End = @SCurr_End
Else If @Case = 2  --Next Summary
  select @Id = @SNext_Id, @Start = @SNext_Start, @End = @SNext_End
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@@ID, 'END')
