CREATE PROCEDURE dbo.spWD_GetDelaySummaryInfo
  @PU_Id int,
  @Start_Time datetime,
  @Limit 	 Int,
  @Id int OUTPUT,
  @Start datetime OUTPUT,
  @End datetime OUTPUT,
  @LimitReached Int Output
AS
Declare @DebugFlag tinyint,
       	 @logId int,
 	  	 @Counter Int
SELECT @LimitReached = 0
SELECT @DebugFlag = 0
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) 
 	  	 SELECT dbo.fnServer_CmnGetDate(getUTCdate())
 	 SELECT @logId = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@logId, 'in spWD_GetDelaySummaryInfo /PU_Id: ' + Coalesce(convert(nVarchar(4),@PU_Id),'Null') + 
 	 ' /Start_Time: ' + Coalesce(convert(nVarchar(25),@Start_Time,20),'Null') )
  End
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
          @SNext_End datetime
 	 SELECT @SPrev_Id = NULL, @SPrev_Start = NULL, @SPrev_End = NULL
 	 SELECT @SCurr_Id = NULL, @SCurr_Start = NULL, @SCurr_End = NULL
 	 SELECT @SNext_Id = NULL, @SNext_Start = NULL, @SNext_End = NULL
  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Start_Time = ' + Coalesce(convert(nvarchar(30), @Start_Time,20),'Null'))
SELECT @Local_Start_Time = @Start_Time
SELECT @Counter = 0
WHILE (0=0) AND @Counter < @Limit
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Local_Start_Time = ' + Coalesce(convert(nvarchar(30), @Local_Start_Time,20),'Null'))
 	 SELECT @Max_Start_Time = Max(Start_Time) From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time < @Local_Start_Time
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Max_Start_Time = ' + Coalesce(convert(nvarchar(30), @Max_Start_Time,20),'Null'))
 	 SELECT @Max_End_Time = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Max_Start_Time
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Max_End_Time = ' + Coalesce(convert(nvarchar(30), @Max_End_Time,20),'Null'))
 	 if @Max_Start_Time is NULL
        break
 	 else if @Max_End_Time <> @Local_Start_Time and @SCurr_Start is NULL
 	 BEGIN
          SELECT @SCurr_Id = TEDet_Id, @SCurr_Start = Start_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Local_Start_Time
          SELECT @SPrev_End = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Max_Start_Time
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SCurr_Id = ' + Coalesce(convert(nvarchar(30), @SCurr_Id),'Null'))
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SCurr_Start = ' + Coalesce(convert(nvarchar(30), @SCurr_Start,20),'Null'))
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SPrev_End = ' + Coalesce(convert(nvarchar(30), @SPrev_End,20),'Null'))
 	  	 BREAK
 	 END
 	 else if @Max_End_Time <> @Local_Start_Time and @SPrev_End is NOT NULL and @SPrev_Start is NULL
 	 BEGIN
 	  	 SELECT @SPrev_Id = TEDet_Id, @SPrev_Start = Start_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Local_Start_Time
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SPrev_Id = ' + Coalesce(convert(nvarchar(30), @SPrev_Id),'Null'))
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SPrev_Start = ' + Coalesce(convert(nvarchar(30), @SPrev_Start),'Null'))
 	 END
 	 else if @Max_End_Time <> @Local_Start_Time
        break
 	 
 	 If @DebugFlag = 1 
 	 BEGIN
 	  	 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Counter = ' + Coalesce(convert(nvarchar(30), @Counter),'Null'))
 	  	 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Max_End_Time = ' + Coalesce(convert(nvarchar(30), @Max_End_Time,20),'Null'))
 	 END
 	 SELECT @Counter = @Counter + 1
 	 SELECT @Local_Start_Time = @Max_Start_Time
END
If @Counter > = @Limit
BEGIN
 	 SELECT @LimitReached = 1
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, 'END(limit)')
 	 Return
END
if @SCurr_Start is NULL
BEGIN
 	 SELECT @SCurr_Id = TEDet_Id, @SCurr_Start = Start_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Local_Start_Time  
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SCurr_Id = ' + Coalesce(convert(nvarchar(30), @SCurr_Id),'Null'))
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SCurr_Start = ' + Coalesce(convert(nvarchar(30), @SCurr_Start,20),'Null'))
END
SELECT @Local_End_Time = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @SCurr_Start
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Local_End_Time = ' + Coalesce(convert(nvarchar(30), @Local_End_Time,20),'Null'))
SELECT @Counter = 0
WHILE (0=0) AND @Counter < @Limit
BEGIN
 	 SELECT @Min_Start_Time = Min(Start_Time) From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time >= @Local_End_Time
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Min_Start_Time = ' + Coalesce(convert(nvarchar(30), @Min_Start_Time,20),'Null'))
 	 SELECT @Min_End_Time = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Min_Start_Time
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Min_End_Time = ' + Coalesce(convert(nvarchar(30), @Min_End_Time,20),'Null'))
 	 if @Min_Start_Time is NULL
 	  	 break
 	 else if @Min_Start_Time <> @Local_End_Time and @SCurr_End is NULL
 	 BEGIN
 	  	 SELECT @SCurr_End = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and End_Time = @Local_End_Time
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SCurr_End = ' + Coalesce(convert(nvarchar(30), @SCurr_End,20),'Null'))
 	  	 SELECT @SNext_Id = TEDet_Id, @SNext_Start = Start_Time From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Min_Start_Time        
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SNext_Id = ' + Coalesce(convert(nvarchar(30), @SNext_Id),'Null'))
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SNext_Start = ' + Coalesce(convert(nvarchar(30), @SNext_Start,20),'Null'))
 	  	 BREAK
 	 END
 	 else if @Min_Start_Time <> @Local_End_Time and @SNext_Start is NOT NULL and @SNext_End is NULL
 	 BEGIN
 	  	 SELECT @SNext_End = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and End_Time = @Local_End_Time
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@SNext_End = ' + Coalesce(convert(nvarchar(30), @SNext_End,20),'Null'))
 	 END
 	 else if @Min_Start_Time <> @Local_End_Time or @Min_Start_Time = @Min_End_Time
 	  	 break
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Local_End_Time = ' + Coalesce(convert(nvarchar(30), @Local_End_Time,20),'Null'))
 	 SELECT @Counter = @Counter + 1
 	 SELECT @Local_End_Time = @Min_End_Time
END
If @Counter > = @Limit
BEGIN
 	 SELECT @LimitReached = 1
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, 'END(limit)')
 	 Return
END
if @SCurr_End is NULL
BEGIN
 	 SELECT @SCurr_End = End_Time From Timed_Event_Details Where PU_Id = @PU_Id and End_Time = @Local_End_Time
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, '@Local_End_Time = ' + Coalesce(convert(nvarchar(30), @Local_End_Time,20),'Null'))
END
SELECT @Id = @SCurr_Id, @Start = @SCurr_Start, @End = @SCurr_End
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@logId, 'END')
