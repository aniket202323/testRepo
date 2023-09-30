CREATE PROCEDURE dbo.spServer_DBMgrUpdTimedEvent
  @TEDet_Id         int        OUTPUT,  --  1: Input/Output
  @PU_Id            int, 	  	             --  2: Input
  @Source_PU_Id     int, 	  	             --  3: Input
  @Start_Time       Datetime,           --  4: Input
  @End_Time         Datetime OUTPUT,    --  5: Input/Output
  @TEStatus_Id      int, 	   	             --  6: Input
  @TEFault_Id       int, 	  	             --  7: Input
  @Reason_Level1    int, 	  	             --  8: Input
  @Reason_Level2    int, 	  	             --  9: Input
  @Reason_Level3    int, 	  	             -- 10: Input
  @Reason_Level4    int, 	  	             -- 11: Input
  @Future1  real = Null, 	  	                     -- 12: Input   /* Duration  (Changed to calculated field */
  @Future2  real = Null, 	  	                     -- 13: Input   /* Production_Rate 11/20/02 Not Used */
  @Transaction_Type int, 	  	             -- 14: Input
  @TransNum int, 	  	                     -- New Param
  @UserId int, 	  	  	                     -- New Param
  @Action1 int, 	  	  	                     -- New Param
  @Action2 int, 	  	  	                     -- New Param
  @Action3 int, 	  	  	                     -- New Param
  @Action4 int, 	  	  	                     -- New Param
  @ActionCommentId int, 	  	               -- New Param
  @ResearchCommentId int, 	               -- New Param
  @ResearchStatusId int, 	               -- New Param
  @CommentId int, 	  	                     -- New Param
  @DemX1 float = null,  	  	                     -- New Param
  @DemX2 float = null,  	  	                     -- New Param
  @DemY1 float = null,  	  	                     -- New Param
  @DemY2 float = null,  	  	                     -- New Param
  @DemZ1 float = null,  	  	                     -- New Param
  @DemZ2 float = null,  	  	                     -- New Param
  @TargetProdRate float = Null, 	               -- New Param
  @ResearchOpenDate datetime, 	           -- New Param
  @ResearchCloseDate datetime, 	         -- New Param
  @ResearchUserId int,                   -- New Param
  @Event_Reason_Tree_Data_Id Int = Null, 	  	  -- User for categories
  @SignatureId int = Null,
  @ReturnResultSets 	 Int = 1
AS
SET @ReturnResultSets = Coalesce(@ReturnResultSets,1)
Declare 
    @XLock BIT,
    @DebugFlag tinyint,
 	 @ID int,
 	 @ErrorMsg nVarChar(255),
 	 @DaysBackOpenDowntimeEventCanBeAdded int,
 	 @OpenDowntimeEventCanBeAddedDaysBack bit,
 	 @TreeId 	 Int,
 	 @OldEndTime 	 DateTime,
 	 @OldStartTime DateTime,
 	 @MyOwnTrans Int,
 	 @RecordCounter 	 Int, 
 	 @DeleteComment_Id int,
 	 @DetailCommentSaved 	  	 Int,
 	 @SummaryCommentSaved 	 Int
DECLARE @originalContextInfo VARBINARY(128)
DECLARE @ContextInfo varbinary(128)
/*  2/2009 - JG
  to improve performance and ease of use of the downtime clients and SDK apps (e.g. PMG), return DT result set records
  at the end of this procedure of all rows that were updated, inserted or deleted. 
  To minimize the chance of locking, just get the TEDID on each update/insert/delete then pull 
  from the timed_event_details at the end 
*/
Declare @DTUpdates TABLE ( 
 TEDId int null , 
 TransType int) 
Declare @DTUpdatesNoDup TABLE ( 
 TEDId int null , 
 TransType int) 
Declare @DTUpdateID int
Declare @ReturnStatus int
DECLARE @CommentsToDelete Table(CommentId1 Int,CommentId2 Int,CommentId3 Int,CommentId4 Int,CommentId5 Int,CommentId6 Int)
DECLARE @CommentsToDelete2 Table(CommentId Int)
If @@Trancount = 0
 	 Select @MyOwnTrans = 1
Else
 	 Select @MyOwnTrans = 0
/*
Insert Into User_Parameters (Parm_Id, User_Id, Value, HostName) Values(100, 6, 1, '')
update User_Parameters set value = 0 where Parm_Id = 100 and User_Id = 6
*/
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdTimedEvent /TEDet_Id: ' + Coalesce(convert(nvarchar(10),@TEDet_Id),'Null') + ' /PU_Id: ' + Coalesce(convert(nVarChar(4),@PU_Id),'Null') + 
 	 ' /Source_PU_Id: ' + Coalesce(convert(nVarChar(4),@Source_PU_Id),'Null') + ' /Start_Time: ' + Coalesce(convert(nVarChar(25),@Start_Time,120),'Null') + 
 	 ' /End_Time: ' + Coalesce(convert(nVarChar(25),@End_Time,120),'Null') + ' /TEStatus_Id: ' + Coalesce(convert(nVarChar(4),@TEStatus_Id),'Null') + 
 	 ' /TEFault_Id: ' + Coalesce(convert(nVarChar(4),@TEFault_Id),'Null') + ' /Reason_Level1: ' + Coalesce(convert(nVarChar(4),@Reason_Level1),'Null') + 
 	 ' /Reason_Level2: ' + Coalesce(convert(nVarChar(4),@Reason_Level2),'Null') + ' /Reason_Level3: ' + Coalesce(convert(nVarChar(4),@Reason_Level3),'Null') + 
 	 ' /Reason_Level4: ' + Coalesce(convert(nVarChar(4),@Reason_Level4),'Null') + ' /Future2: ' + Coalesce(convert(nvarchar(10),@Future2),'Null') + 
 	 ' /Future1 ' + Coalesce(convert(nvarchar(10),@Future1),'Null') + ' /Transaction_Type: ' + Coalesce(convert(nVarChar(4),@Transaction_Type),'Null') + 
 	 ' /TransNum: ' + Coalesce(convert(nVarChar(4),@TransNum),'Null') + ' /UserId ' + Coalesce(convert(nVarChar(4),@UserId),'Null') +  
 	 ' /Action1: ' + Coalesce(convert(nVarChar(4),@Action1),'Null') + ' /Action2: ' + Coalesce(convert(nVarChar(4),@Action2),'Null') +
 	 ' /Action3: ' + Coalesce(convert(nVarChar(4),@Action3),'Null') + ' /Action4: ' + Coalesce(convert(nVarChar(4),@Action4),'Null') +
 	 ' /ActionCommentId: ' + Coalesce(convert(nVarChar(4),@ActionCommentId),'Null') + ' /ResearchCommentId: ' + Coalesce(convert(nVarChar(4),@ResearchCommentId),'Null') + 
 	 ' /ResearchStatusId: ' + Coalesce(convert(nVarChar(4),@ResearchStatusId),'Null') + ' /CommentId: ' + Coalesce(convert(nVarChar(4),@CommentId),'Null') + 
 	 ' /DemX1: ' + Coalesce(convert(nvarchar(10),@DemX1),'Null') + ' /DemX2: ' + Coalesce(convert(nvarchar(10),@DemX2),'Null') + 
 	 ' /DemY1: ' + Coalesce(convert(nvarchar(10),@DemY1),'Null') + ' /DemY2: ' + Coalesce(convert(nvarchar(10),@DemY2),'Null') + 
 	 ' /DemZ1: ' + Coalesce(convert(nvarchar(10),@DemZ1),'Null') + ' /DemZ2: ' + Coalesce(convert(nvarchar(10),@DemZ2),'Null') + 
 	 ' /TargetProdRate ' + Coalesce(convert(nvarchar(10),@TargetProdRate),'Null') + ' /ResearchOpenDate ' + Coalesce(convert(nVarChar(25),@ResearchOpenDate),'Null') + 
 	 ' /ResearchCloseDate ' + Coalesce(convert(nVarChar(25),@ResearchCloseDate),'Null') + ' /ResearchUserId ' + Coalesce(convert(nVarChar(4),@ResearchUserId),'Null'))
  End
Select @DaysBackOpenDowntimeEventCanBeAdded = CONVERT(int, COALESCE(Value, '0')) From Site_Parameters Where Parm_Id = 77
Select @OpenDowntimeEventCanBeAddedDaysBack = CONVERT(tinyint, COALESCE(Value, '0')) From Site_Parameters Where Parm_Id = 78
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DaysBackOpenDowntimeEventCanBeAdded = ' + convert(nVarChar(4),@DaysBackOpenDowntimeEventCanBeAdded)) 
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@OpenDowntimeEventCanBeAddedDaysBack = ' + convert(nVarChar(4),@OpenDowntimeEventCanBeAddedDaysBack)) 
  if @Source_PU_Id = 0 
     Select @Source_PU_Id = NULL 
  if @Start_Time < '8-aug-97 13:17'
    Begin
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Start_Time < 8-aug-97 13:17') 
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
      Return(5)
    End
  if @End_Time < '8-aug-97 13:17'
    Begin
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@End_Time < 8-aug-97 13:17') 
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
      Return(5)
    End
  --
  -- Return Values:
  --
  --   (-100) Error.
  --   (-200) ignored error, 'Complete Transaction Did Not Find Null Record (Detail)'
  --   (   1) Success: New record added.
  --   (   2) Success: Existing record modified.
  --   (   3) Success: Existing record deleted.
  --   (   4) Success: Existing record completed.
  --   (   5) Success: No action taken.
  --
  -- Transaction Types
  --   (   1) Insert/Add
  --   (   2) Update 
  --   (   3) Delete 
  --   (   4) Complete
  --  (   4) Complete
  Declare @DCurrent_Start datetime,
 	  	  	 @DCurrent_End datetime,
 	  	  	 @DPrev_Id int, 
 	  	  	 @DNext_Id int,
 	  	  	 @DPrev_Start datetime,
 	  	  	 @DPrev_End datetime,
 	  	  	 @DCheck_Id int, 
 	  	  	 @DNext_Start datetime,
 	  	  	 @DNext_End datetime,
 	  	  	 @SPrev_Id int, 
 	  	  	 @SNext_Id int,
 	  	  	 @SPrev_Start datetime,
 	  	  	 @SPrev_End datetime,
 	  	  	 @SNext_Start datetime,
 	  	  	 @SNext_End datetime,
 	  	  	 @DetailOrder nvarchar(10),
 	  	  	 @CheckId int,
 	  	  	 @Msg nVarChar(50),
 	  	  	 @Preserve_Detail_Start_Time datetime,
 	  	  	 @Preserve_Detail_TEDet_Id int,
 	  	  	 @Preserve_Detail_Cause_Comment_Id int,
 	  	  	 @Preserve_Summary_Start_Time datetime,
 	  	  	 @Preserve_Summary_TEDet_Id int,
 	  	  	 @Preserve_Summary_Cause_Comment_Id int,
 	  	  	 @Preserve_UserId 	  int,
 	  	  	 @Uptime 	  	 Real,
 	  	  	 @NextUptime 	 Real,
 	  	  	 @Summary_Cause_Comment_Id 	  	  	 Int,
 	  	  	 @Cause_Comment_Id 	  	  	  	  	 Int,
 	  	  	 @SCurr_Id 	  	 Int,
 	  	  	 @SCurr_Start 	 datetime,
 	  	  	 @SCurr_End  	 datetime
 	  	 
Declare  	 @SUptimePrev_Id Int,
 	  	 @SUptimePrev_Start DateTime,
 	  	 @SUptimePrev_End DateTime,
 	  	 @LastResearchStatus Int,
 	  	 @LastOpenDate 	 DateTime,
 	  	 @modifiedOn 	  	 DateTime
  -- Make sure mandatory arguments are not null.
  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Make sure mandatory arguments are not null.')
  If (@TransNum =1010) -- Transaction From WebUI
  BEGIN/* Temp check to disallow deletes */
 	 SET @Event_Reason_Tree_Data_Id = Null 	   
 	 Select @modifiedOn = dbo.fnServer_CmnGetDate(getUTCdate())
 	 IF @TEDet_Id Is Not Null
 	 BEGIN
 	  	 IF Exists(SELECT 1 FROM Timed_Event_Details WHERE  (PU_Id = @PU_Id) and (Start_Time >= @Start_Time) and ((end_time <= @End_Time) or (@end_time is null)) and TEDet_Id <> @TEDet_Id)
 	  	  	 Return(-101)
 	  	 SELECT @LastResearchStatus = Research_Status_Id,@LastOpenDate = Research_Open_Date 
 	  	   FROM Timed_Event_Details WHERE TEDet_Id  = @TEDet_Id
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF Exists(SELECT 1 FROM Timed_Event_Details WHERE  (PU_Id = @PU_Id) and (Start_Time >= @Start_Time) and ((end_time <= @End_Time) or (@end_time is null)))
 	  	  	 SET @OpenDowntimeEventCanBeAddedDaysBack = 0
 	 END
 	 IF @ResearchStatusId is Null And  @LastResearchStatus is Not Null -- Not used
 	 BEGIN
 	  	 SET @ResearchOpenDate = Null
 	  	 SET @ResearchCloseDate = Null
 	  	 SET @ResearchUserId = Null 
 	 END
 	 IF @ResearchStatusId = 1 and (@LastResearchStatus != 1 or  @LastResearchStatus is Null)-- Open
 	 BEGIN
 	  	 SET @ResearchOpenDate = @modifiedOn
 	  	 SET @ResearchCloseDate = Null
 	  	 SET @ResearchUserId = @UserId 
 	 END
 	 IF @ResearchStatusId = 2 and (@LastResearchStatus != 2  or  @LastResearchStatus is Null)-- Close
 	 BEGIN
 	  	 SET @ResearchCloseDate = @modifiedOn
 	  	 IF @LastOpenDate Is Null
 	  	 SET @ResearchOpenDate = @modifiedOn
 	  	 SET @ResearchUserId = @UserId 
 	 END
  END
  If (@TransNum = 100) -- Update reasons only
  BEGIN
 	 IF @Transaction_Type = 2 and @TEDet_Id is not null
 	 BEGIN
 	  	 SELECT  	 @PU_Id = PU_Id,
 	  	  	 @Source_PU_Id = Coalesce(Source_PU_Id,PU_Id),
 	  	  	 @Start_Time = Start_Time,
 	  	  	 @End_Time = End_Time,
 	  	  	 @TEStatus_Id = TEStatus_Id,
 	  	  	 @TEFault_Id = TEFault_Id,
 	  	  	 @Action1 = Action_Level1,
 	  	  	 @Action2 = Action_Level2,
 	  	  	 @Action3 = Action_Level3,
 	  	  	 @Action4 = Action_Level4,
 	  	  	 @ActionCommentId = a.Action_Comment_Id,
 	  	  	 @ResearchCommentId = a.Research_Comment_Id, 
 	  	  	 @ResearchStatusId = Research_Status_Id,
 	  	  	 @CommentId = a.Cause_Comment_Id,
 	  	  	 @ResearchUserId = Research_User_Id,
 	  	  	 @ResearchOpenDate = Research_Open_Date,
 	  	  	 @ResearchCloseDate = Research_Close_Date,
 	  	  	 @UserId = Coalesce(@UserId,User_Id),
 	  	  	 @Uptime = Uptime,
 	  	  	 @SignatureId =Signature_Id
 	  	 FROM Timed_Event_Details a
 	  	 WHERE (Tedet_Id =  @TEDet_Id)
 	  	 SET @TransNum = 2
 	 END
 	 IF @Transaction_Type = 1
 	 BEGIN
 	  	 SET @TransNum = 0
 	 END
  END
  If @TransNum NOT IN (0, 2,1010) AND (@Transaction_Type <> 4) -- Type 4 has (-) trans num for duration check
    Begin
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '(@TransNum <> 0) And (@TransNum <> 2) -- e.g. From TimedEventMgr') 
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
      Return(5)
    End
  IF @PU_Id IS NULL
    BEGIN
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@PU_Id IS NULL') 
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
      RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@PU_Id')
      RETURN(-100)
    END
  IF @Transaction_Type IS NULL
    BEGIN
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type IS NULL') 
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
      RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@Transaction_Type')
      RETURN(-100)
    END
  -- Make sure the transaction type is ok. Depending on the transaction type,
  -- other arguments may also become mandatory. Make sure these dependant
  -- mandatory arguments are not null.
  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Make sure the transaction type is ok. Depending on the transaction type,')
  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'other arguments may also become mandatory. Make sure these dependant')
  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'mandatory arguments are not null.')
  IF @Transaction_Type = 1 OR @Transaction_Type = 2 OR @Transaction_Type = 3
    BEGIN
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type = 1 OR @Transaction_Type = 2 OR @Transaction_Type = 3 -- e.g. From TimedEventMgr') 
      IF @Start_Time IS NULL
        BEGIN
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Start_Time IS NULL') 
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
          RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@Start_Time')
          RETURN(-100)
        END
      -- Check for an operator entry or result set error
      IF @End_Time IS NOT NULL AND (@Transaction_Type = 1 OR @Transaction_Type = 2) 
        BEGIN
          IF @End_Time <= @Start_Time 
            BEGIN
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@End_Time <= @Start_Time - This must be an operator or resultset error') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	       Select @ErrorMsg = 'Negative duration - Data entry or resultset err'
              RAISERROR(@ErrorMsg, 11, -1)
              RETURN(-100)
            END
        END
      IF @Transaction_Type <> 1 AND @TEDet_Id IS NULL
        BEGIN
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type <> 1 AND @TEDet_Id IS NULL') 
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
          RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@TEDet_Id')
          RETURN(-100)
        END    
    END
  ELSE IF @Transaction_Type = 4
    BEGIN
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type = 4 -- e.g. From TimedEventMgr') 
      IF @End_Time IS NULL
        BEGIN
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@End_Time IS NULL') 
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
          RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@End_Time')
          RETURN(-100)
        END
    END
  ELSE
    BEGIN
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type <> 1 AND @Transaction_Type <> 2 AND @Transaction_Type <> 3 AND @Transaction_Type <> 4') 
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
      RAISERROR('Unknown transaction type detected:  %lu', 11, -1, @Transaction_Type)
      RETURN(-100)
    END
-- is this an open record
If @End_Time is NULL and (@OpenDowntimeEventCanBeAddedDaysBack = 0 or @DaysBackOpenDowntimeEventCanBeAdded <> 0)
  Begin
 	 Select @RecordCounter = Count(*) 
 	  	 From Timed_Event_Details 
 	  	 where (PU_Id = @PU_Id) and (Start_Time >= @Start_Time) and (End_Time is NOT NULL) AND (@Transaction_Type <> 2 OR TEDet_Id <> @TEDet_Id) 
 	 If @RecordCounter > 0 and @OpenDowntimeEventCanBeAddedDaysBack = 0
 	   Begin
 	       If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'OPEN Downtime Event Cannot Be Inserted In The Past.')
 	       Return(5)
 	   End
 	 If @RecordCounter > 0 and @DaysBackOpenDowntimeEventCanBeAdded <> 0
 	   Begin
 	  	 If  @Start_Time <  DateAdd(day, -1 * @DaysBackOpenDowntimeEventCanBeAdded, dbo.fnServer_CmnGetDate(getUTCdate()))
 	  	   Begin
 	  	       If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'OPEN Downtime Event Cannot Be Inserted In The Past.')
 	  	       Return(5)
 	  	   End
 	   End
   End
 	 
  -- 
  --  Find The Previous and Next Detail Record If Not Complete Transaction
  --
  if @Transaction_Type = 1
    Begin
   	   select @DCheck_Id = Null
      select @DCheck_Id = TeDet_Id
      from Timed_Event_Details 
      where (Pu_Id = @Pu_Id) and (start_time = @Start_Time) and ((end_time = @End_Time) or ((end_time is null) and (@End_Time is null)))          
       if @DCheck_Id is not null
        begin
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DCheck_Id is not null') 
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
          -- We Found An Identical Record
          select @Transaction_Type = 2
          select @TEDet_Id = @DCheck_Id
        end
    End
  if (@Transaction_Type <> 4) 
    begin
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Find The Previous and Next Detail Record If Not Complete Transaction')
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type <> 4 -- e.g. From TimedEventMgr') 
      -- look for detail record falling in start time range
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'look for detail record falling in start time range')
      select @DPrev_Id = Null, @DPrev_Start = NULL, @DPrev_End = NULL
 	   Select TOP 1 @DPrev_Id = TeDet_Id, @DPrev_Start = Start_Time, @DPrev_End = End_Time
 	  	 From Timed_Event_Details 
 	  	 Where (Pu_Id = @Pu_Id) and (start_time < @Start_Time)
 	  	 Order By Start_Time Desc
 	   If @DPrev_End Is Not Null And @DPrev_End < @Start_Time
 	     Begin
 	       Select  	 @DPrev_Id 	 = Null,
 	  	   @DPrev_Start 	 = Null,
 	  	   @DPrev_End 	 = Null
 	     End
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DPrev_Id = ' + Coalesce(convert(nvarchar(10), @DPrev_Id),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DPrev_Start = ' + Coalesce(convert(nVarChar(30), @DPrev_Start),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DPrev_End = ' + Coalesce(convert(nVarChar(30), @DPrev_End),'Null'))
      -- look for detail record falling in end time range
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'look for detail record falling in end time range')
      if @End_Time is Null
        begin
       	   If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@End_Time is Null') 
          select @DNext_Id = Null
        end
      else
        begin
       	   If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@End_Time is NOT Null') 
          select @DNext_Id = Null, @DNext_Start = NULL, @DNext_End = NULL
          select @DNext_Id = TeDet_Id, @DNext_Start = Start_Time, @DNext_End = End_Time
          from Timed_Event_Details With (index (TEvent_Details_IDX_PUIdETime))
          where (Pu_Id = @Pu_Id) and (start_time <= @End_Time) and ((end_time > @End_Time) or (end_time is null))
        end
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_Id = ' + Coalesce(convert(nvarchar(10), @DNext_Id),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_Start = ' + Coalesce(convert(nVarChar(30), @DNext_Start),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_End = ' + Coalesce(convert(nVarChar(30), @DNext_End),'Null'))
      -- look for summary record falling in start time range
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'look for summary record falling in start time range')
 	  If @Transaction_Type = 1
 	       exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @PU_Id, @Start_Time, 1, @SPrev_Id OUTPUT, @SPrev_Start OUTPUT, @SPrev_End OUTPUT
 	  Else
 	       exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @PU_Id, @Start_Time, 0, @SPrev_Id OUTPUT, @SPrev_Start OUTPUT, @SPrev_End OUTPUT
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@SPrev_Id = ' + Coalesce(convert(nvarchar(10), @SPrev_Id),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@SPrev_Start = ' + Coalesce(convert(nVarChar(30), @SPrev_Start),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@SPrev_End = ' + Coalesce(convert(nVarChar(30), @SPrev_End),'Null'))
      -- look for summary record falling in end time range
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'look for summary record falling in end time range')
      exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @PU_Id, @Start_Time, 2, @SNext_Id OUTPUT, @SNext_Start OUTPUT, @SNext_End OUTPUT
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@SNext_Id = ' + Coalesce(convert(nvarchar(10), @SNext_Id),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@SNext_Start = ' + Coalesce(convert(nVarChar(30), @SNext_Start),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@SNext_End = ' + Coalesce(convert(nVarChar(30), @SNext_End),'Null'))
      -- Check Update,Delete Transaction
      if (@Transaction_Type = 2) or (@Transaction_Type = 3) 
        begin
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Check Update,Delete Transaction')
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type = 2 or @Transaction_Type = 3 -- e.g. From TimedEventMgr') 
          select @CheckId = null
          select @CheckId = tedet_id, @DCurrent_Start = Start_Time, @DCurrent_End = End_Time          
            from timed_event_details
            where tedet_id = @TEDet_Id
          if (@CheckID is null) 
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@CheckID is null') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
              RAISERROR('Could Not Find Id To Update', 11, -1)
              return(-100)
            end
          if (@CheckID = @DPrev_Id) select @DPrev_Id = Null 
          if (@CheckID = @DNext_Id) select @DNext_Id = Null    
        end
      -- Determine Relationship Of The Detail To Other Details
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Determine Relationship Of The Detail To Other Details')
      if (@DPrev_Id is not null) and (@DNext_Id is not null)
        Begin
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DPrev_Id is not null and @DNext_Id is not null') 
          if @DPrev_Id <> @DNext_Id
            Begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DPrev_Id <> @DNext_Id') 
              select @DetailOrder = 'Middle'
            End
          else
            Begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DPrev_Id = @DNext_Id') 
              select @DetailOrder = 'Inside'          
            End
        End
      else if (@DPrev_Id is not null) 
        Begin
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DPrev_Id is not null') 
          select @DetailOrder = 'Last'
        End
      else if (@DNext_Id is not null)
        Begin
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_Id is not null') 
          select @DetailOrder = 'First'
        End
      else
        Begin
         If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DPrev_Id is null and @DNext_Id is null') 
          select @DetailOrder = 'Only'
        End
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'DetailOrder = ' + @DetailOrder) 
 	  	  	 If @MyOwnTrans = 1 
 	  	  	  	 Begin
 	  	  	  	  	 BEGIN TRANSACTION
          SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
 	  	  	  	 End
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'begin transaction') 
      -- Clean Out All Records Totally Within This Detail's Time Range
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Clean Out All Records Totally Within This Details Time Range')
      -- Preserve Original Comment On Merge
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Preserve Original Comment On Merge')
      select @Preserve_Detail_Start_Time = NULL
      select @Preserve_Detail_Start_Time = Min(Start_Time) from Timed_Event_Details
      where PU_Id = @PU_Id and Start_Time >= @Start_Time and (End_Time <= @End_Time or @End_Time is NULL) and Cause_Comment_Id is NOT NULL
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Preserve_Detail_Start_Time = ' + Coalesce(convert(nVarChar(30), @Preserve_Detail_Start_Time),'Null'))
      select @Preserve_Detail_TEDet_Id = NULL
      select @Preserve_Detail_Cause_Comment_Id = NULL
 	   SELECT @Preserve_UserId = Null
      select @Preserve_Detail_TEDet_Id = TEDet_Id, @Preserve_Detail_Cause_Comment_Id = Cause_Comment_Id,@Preserve_UserId = Initial_User_Id from Timed_Event_Details where PU_Id = @PU_Id and Start_Time = @Preserve_Detail_Start_Time
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Preserve_Detail_TEDet_Id = ' + Coalesce(convert(nvarchar(10), @Preserve_Detail_TEDet_Id),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Preserve_Detail_Cause_Comment_Id = ' + Coalesce(convert(nvarchar(10), @Preserve_Detail_Cause_Comment_Id),'Null'))
      select @Preserve_Summary_Start_Time = NULL
      if @End_Time < @DNext_Start or @DNext_Start is NULL or @End_Time is NULL
        select @Preserve_Summary_Start_Time = Min(Start_Time) from Timed_Event_Details With(index( TEvent_Details_IDX_PUIdSTime)) 
        where PU_Id = @PU_Id and Start_Time >= @SPrev_Start and (End_Time <= @End_Time or @End_Time is NULL) and Summary_Cause_Comment_Id is NOT NULL
      else
        select @Preserve_Summary_Start_Time = Min(Start_Time) from Timed_Event_Details With (index (TEvent_Details_IDX_PUIdSTime))
        where PU_Id = @PU_Id and Start_Time >= @SPrev_Start and (End_Time <= @DNext_End or @DNext_End is NULL) and Summary_Cause_Comment_Id is NOT NULL
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Preserve_Summary_Start_Time = ' + Coalesce(convert(nVarChar(30), @Preserve_Summary_Start_Time),'Null'))
      select @Preserve_Summary_TEDet_Id = NULL
      select @Preserve_Summary_Cause_Comment_Id = NULL
      select @Preserve_Summary_TEDet_Id = TEDet_Id, @Preserve_Summary_Cause_Comment_Id = Summary_Cause_Comment_Id from Timed_Event_Details where PU_Id = @PU_Id and Start_Time = @Preserve_Summary_Start_Time
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Preserve_Summary_TEDet_Id = ' + Coalesce(convert(nvarchar(10), @Preserve_Summary_TEDet_Id),'Null'))
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Preserve_Summary_Cause_Comment_Id = ' + Coalesce(convert(nvarchar(10), @Preserve_Summary_Cause_Comment_Id),'Null'))
      -- Regardless of Transaction Type Clean Up Extra Details
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Regardless of Transaction Type Clean Up Extra Details')
   	   If @Transaction_Type = 2
        Begin
         Update timed_event_details set cause_comment_id = NULL, Signature_Id = @SignatureId
          where TEDet_Id <> @TEDet_Id and TEDet_Id = @Preserve_Detail_TEDet_Id and (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
         -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
         Insert into @DTUpdates(TEDId, TransType)
 	  	  	 Select TEDet_Id, 2 from timed_event_details 
              where TEDet_Id <> @TEDet_Id and TEDet_Id = @Preserve_Detail_TEDet_Id and (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
         Update timed_event_details set summary_cause_comment_id = NULL, Signature_Id = @SignatureId
          where TEDet_Id <> @TEDet_Id and TEDet_Id = @Preserve_Summary_TEDet_Id and (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
         -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
         Insert into @DTUpdates(TEDId, TransType)
 	  	  	 Select TEDet_Id, 2 from timed_event_details 
          where TEDet_Id <> @TEDet_Id and TEDet_Id = @Preserve_Summary_TEDet_Id and (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
 	  	  Declare @CleanUpDetId 	 Int
 	  	  Declare CleanUpCursor Cursor
 	  	  For Select TEDet_Id
 	  	   From timed_event_details 
       	  	 where (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
 	  	  Open CleanUpCursor
 	  	  Cleanuploop:
 	  	  Fetch Next From CleanUpCursor Into @CleanUpDetId
 	  	  If @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	  If @CleanUpDetId <> @TEDet_Id
 	  	  	    Begin
 	  	  	  	   Execute spServer_DBMgrCleanupDownTime  @CleanUpDetId,Null,@ReturnResultSets,@UserId
 	  	  	  	   EXEC spServer_DBMgrUpdPendingResultSet NULL, 16, @CleanUpDetId, 3, @TransNum, 5, @UserId
 	  	  	    	   Execute spServer_DBMgrCleanupUpTime @CleanUpDetId,Null,@ReturnResultSets,@UserId
 	  	  	  	   INSERT INTO @CommentsToDelete(CommentId1,CommentId2,CommentId3,CommentId4,CommentId5,CommentId6)
 	  	  	  	  	  SELECT Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id, Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id 
 	  	  	  	  	  FROM Timed_Event_Details  
 	  	  	  	  	  WHERE TEDet_Id = @CleanUpDetId
 	  	  	  	  	 SET @originalContextInfo = Context_Info()
 	  	  	  	  	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	  	  	  	  	 SET Context_Info @ContextInfo 
 	  	  	  	  	 Delete from timed_event_details  Where TEDet_Id = @CleanUpDetId
 	  	  	  	  	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo 
 	  	  	  	   Insert into @DTUpdates(TEDId, TransType) values(@CleanUpDetId, 3)
 	  	  	    End
 	  	  	  Goto Cleanuploop
 	  	  	 End
 	  	   Close CleanUpCursor
 	  	   Deallocate CleanUpCursor
        End
   	   Else
        Begin
          update timed_event_details set cause_comment_id = NULL, Signature_id = @SignatureId
          where TEDet_Id = @Preserve_Detail_TEDet_Id and (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
 	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	   Insert into @DTUpdates(TEDId, TransType)
 	  	     Select TEDet_Id, 2 from timed_event_details 
              where TEDet_Id = @Preserve_Detail_TEDet_Id and (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
          update timed_event_details set summary_cause_comment_id = NULL, Signature_Id = @SignatureId
          where TEDet_Id = @Preserve_Summary_TEDet_Id and (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
 	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	   Insert into @DTUpdates(TEDId, TransType)
 	  	     Select TEDet_Id, 2 from timed_event_details 
              where TEDet_Id = @Preserve_Detail_TEDet_Id and (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
 	  	  Declare CleanUpCursor1 Cursor
 	  	   For Select TEDet_Id
 	  	   From timed_event_details 
       	  	 where (Pu_Id = @Pu_Id) and (start_time > @Start_Time) and ((end_time <= @End_Time) or (@end_time is null))
 	  	  Open CleanUpCursor1
 	  	  Cleanuploop1:
 	  	  Fetch Next From CleanUpCursor1 Into @CleanUpDetId
 	  	  If @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	   Execute spServer_DBMgrCleanupDownTime @CleanUpDetId,Null,@ReturnResultSets,@UserId
 	  	  	   Execute spServer_DBMgrCleanupUpTime @CleanUpDetId,Null,@ReturnResultSets,@UserId
 	  	  	   INSERT INTO @CommentsToDelete(CommentId1,CommentId2,CommentId3,CommentId4,CommentId5,CommentId6)
 	  	  	  	  SELECT Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id, Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id 
 	  	  	  	  FROM Timed_Event_Details  
 	  	  	  	  WHERE TEDet_Id = @CleanUpDetId
 	  	  	    	 SET @originalContextInfo = Context_Info()
 	  	  	  	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	  	  	  	 SET Context_Info @ContextInfo 
 	  	  	  	 Delete from timed_event_details  Where TEDet_Id = @CleanUpDetId
 	  	  	  	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo 
 	  	  	   Insert into @DTUpdates(TEDId, TransType) values(@CleanUpDetId, 3)
 	  	  	   Goto Cleanuploop1
 	  	  	 End
 	  	   Close CleanUpCursor1
 	  	   Deallocate CleanUpCursor1
       End
      if @Transaction_Type = 1
        begin
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type = 1') 
          -- Check To See If Insert Record Is Identical To Existing
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Check To See If Insert Record Is Identical To Existing')
          -- Clean Up Extra Details That Fall Inside Insert Record Time
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Clean Up Extra Details That Fall Inside Insert Record Time')
 	  	  Declare CleanUpCursor2 Cursor
 	  	   For Select TEDet_Id
 	  	   From timed_event_details 
           where (Pu_Id = @Pu_Id) and (start_time >= @Start_Time) and (((end_time <= @End_Time) and (@End_Time is not null)) or (@end_time is null))
 	  	  Open CleanUpCursor2
 	  	  Cleanuploop2:
 	  	  Fetch Next From CleanUpCursor2 Into @CleanUpDetId
 	  	  If @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	   Execute spServer_DBMgrCleanupDownTime @CleanUpDetId,Null,@ReturnResultSets,@UserId
 	  	  	   Execute spServer_DBMgrCleanupUpTime @CleanUpDetId,Null,@ReturnResultSets,@UserId
 	  	  	   INSERT INTO @CommentsToDelete(CommentId1,CommentId2,CommentId3,CommentId4,CommentId5,CommentId6)
 	  	  	  	  SELECT Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id, Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id 
 	  	  	  	  FROM Timed_Event_Details  
 	  	  	  	  WHERE TEDet_Id = @CleanUpDetId
 	  	  	    	 SET @originalContextInfo = Context_Info()
 	  	  	  	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	  	  	  	 SET Context_Info @ContextInfo 
 	  	  	  	 Delete from timed_event_details  Where TEDet_Id = @CleanUpDetId
 	  	  	  	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo 
 	  	  	     Insert into @DTUpdates(TEDId, TransType) values(@CleanUpDetId, 3)
 	  	  	   Goto Cleanuploop2
 	  	  	 End
 	  	   Close CleanUpCursor2
 	  	   Deallocate CleanUpCursor2
          -- Insert The New Record
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert The New Record')
          -- Added UserId, CauseCommentId, ActionCommentId, Action_Level1, 2, 3, 4, ResearchUserId, ResearchStatusId, ResearchOpenDate and ResearchCloseDate
 	  	   -- Look up @Event_Reason_Tree_Data_Id If necessary
 	  	   If @Event_Reason_Tree_Data_Id is null and @Reason_Level1 is not null
 	  	  	 Begin
 	  	  	   Select @TreeId = Name_Id From Prod_Events where PU_Id = @Source_PU_Id and Event_Type = 2
 	  	    	   If @Reason_Level2 Is null
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	    	   Else If @Reason_Level3 Is null
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	    	   Else If @Reason_Level4 Is null
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	    	   Else 
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id  = @Reason_Level4 and Tree_Name_Id = @TreeId
 	  	  	 End
 	  	 If @DetailOrder = 'First' 
 	  	   Begin
 	        	 Exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @PU_Id, @Start_Time, 1, @SCurr_Id OUTPUT, @SCurr_Start OUTPUT, @SCurr_End OUTPUT
 	  	  	 If @SPrev_End > @start_time  --Incorrect summary record for uptime
 	  	  	   Begin
 	        	  	 exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @PU_Id, @Start_Time, 0, @SUptimePrev_Id OUTPUT, @SUptimePrev_Start OUTPUT, @SUptimePrev_End OUTPUT
 	  	  	   End
 	  	  	 Else
 	  	  	   Begin
 	  	  	  	 Select @SUptimePrev_End = @SPrev_End
 	  	  	   End
 	           	 Select @Uptime = convert(real, datediff(second,@SUptimePrev_End,@start_time)) / 60
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @SUptimePrev_End =[' + isnull(convert(nVarChar(25),@SUptimePrev_End,120),'Null')  + ']') 
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @SPrev_End =[' + isnull(convert(nVarChar(25),@SPrev_End,120),'Null')  + ']') 
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @start_time=[' +  isnull(convert(nVarChar(25),@start_time,120),'Null')+ ']') 
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @Uptime=[' +  isnull(convert(nvarchar(10),@Uptime),'Null')+ ']')
 	  	  	 If @Uptime < 0 Select @Uptime = Null
 	  	   End
          if @DetailOrder = 'Last' or @DetailOrder = 'Only'
 	  	   Begin
           	 Select @NextUptime = convert(real, datediff(second,@End_time,@SNext_Start)) / 60
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @SNext_Start =[' + isnull(convert(nVarChar(25),@SNext_Start,120),'Null')  + ']') 
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @End_time=[' +  isnull(convert(nVarChar(25),@End_time,120),'Null')+ ']') 
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @NextUptime=[' +  isnull(convert(nvarchar(10),@NextUptime),'Null')+ ']')
 	  	  	 Update Timed_Event_Details set uptime = @NextUptime, Signature_Id = @SignatureId where TeDet_Id = @SNext_Id
 	  	  	 -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	 Insert into @DTUpdates(TEDId, TransType) Values(@SNext_Id, 2)
 	  	   End
          if  @DetailOrder = 'Only'
 	  	   Begin
 	  	  	 If @SPrev_End > @start_time  --Incorrect summary record for uptime
 	  	  	   Begin
 	        	  	 exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @PU_Id, @Start_Time, 0, @SUptimePrev_Id OUTPUT, @SUptimePrev_Start OUTPUT, @SUptimePrev_End OUTPUT
 	  	  	   End
 	  	  	 Else
 	  	  	   Begin
 	  	  	  	 Select @SUptimePrev_End = @SPrev_End
 	  	  	   End
 	           	 Select @Uptime = convert(real, datediff(second,@SUptimePrev_End,@start_time)) / 60
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @SUptimePrev_End =[' + isnull(convert(nVarChar(25),@SUptimePrev_End,120),'Null')  + ']') 
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @SPrev_End =[' + isnull(convert(nVarChar(25),@SPrev_End,120),'Null')  + ']') 
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @start_time=[' +  isnull(convert(nVarChar(25),@start_time,120),'Null')+ ']') 
 	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Uptime1, @Uptime=[' +  isnull(convert(nvarchar(10),@Uptime),'Null')+ ']')
 	  	  	 If @Uptime < 0 Select @Uptime = Null
 	  	   End
          if @Preserve_Summary_TEDet_Id is NOT NULL and @SPrev_Start = @Start_Time
 	  	   BEGIN
           	 Select  @Summary_Cause_Comment_Id = @Preserve_Summary_Cause_Comment_Id
           	 Select  @SummaryCommentSaved = @Preserve_Summary_Cause_Comment_Id
 	  	   END
          if @Preserve_Detail_Cause_Comment_Id is NOT NULL
 	  	   BEGIN
           	 Select @CommentId = @Preserve_Detail_Cause_Comment_Id
           	 Select @DetailCommentSaved = @Preserve_Detail_Cause_Comment_Id
 	  	   END
 	  	   IF @Preserve_UserId Is Null
 	  	  	 SELECT @Preserve_UserId = @UserId
         insert into Timed_Event_Details(User_Id, PU_Id, Source_PU_Id, Start_Time, End_Time, TEStatus_Id,TEFault_Id, Reason_Level1, Reason_Level2, 
                      Reason_Level3, Reason_Level4,  Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id,Action_Level1, Action_Level2, 
                      Action_Level3, Action_Level4, Research_User_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,Event_Reason_Tree_Data_Id,
 	  	  	  	  	   Uptime,Summary_Cause_Comment_Id,Signature_Id,Initial_User_Id)
          values(@UserId, @PU_Id, @Source_PU_Id, @Start_Time, @End_Time, @TEStatus_Id,@TEFault_Id, @Reason_Level1, @Reason_Level2, 
                 @Reason_Level3,@Reason_Level4, @CommentId, @ActionCommentId,@ResearchCommentId, @Action1, @Action2, 
                 @Action3, @Action4, @ResearchUserId, @ResearchStatusId, @ResearchOpenDate, @ResearchCloseDate,@Event_Reason_Tree_Data_Id,@Uptime,@Summary_Cause_Comment_Id,@SignatureId,@Preserve_UserId)
          --EU: changed    5/14/01 For Trigger Issues
          --select @TEDet_Id = Scope_Identity()
          Select @TEDet_Id = TEDet_Id From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @Start_Time
          if @TEDet_Id is null 
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TEDet_Id is null') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
              If @MyOwnTrans = 1 rollback transaction
              RAISERROR('Could Not find Row After Insert', 11, -1)              
              return(-100)
            end
 	  	   -- 2/2009 - JG Added for post updates 
 	  	   Insert into @DTUpdates(TEDId, TransType) Values(@TEDet_Id, 1)
          -- New TEDet_Id
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'New TEDet_Id = ' + Coalesce(convert(nvarchar(10), @TEDet_Id),'Null'))
          -- Preserve Original Comment On Merge
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Preserve Original Comment On Merge')
          if @Preserve_Summary_TEDet_Id is NOT NULL
            Begin
              If @SPrev_Start <> @Start_Time
 	  	  	  	 begin
 	  	  	  	   Select  @SummaryCommentSaved = @Preserve_Summary_Cause_Comment_Id
                  update Timed_Event_Details set Summary_Cause_Comment_Id = @Preserve_Summary_Cause_Comment_Id, Signature_Id = @SignatureId where TEDet_Id = @SPrev_Id
 	  	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@SPrev_Id, 2)
                end 
            End
          -- Update Prev and Next When Detail In Middle
          if @DetailOrder = 'Middle'
            begin                   
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Prev and Next When Detail In Middle')      
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Middle') 
              -- Update End_Time of Previous Detail Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update End_Time of Previous Detail Record')
 	  	  	   Execute spServer_DBMgrCleanupDownTime @DPrev_Id,@start_time,@ReturnResultSets,@UserId
              update timed_event_details set end_time = @start_time, Signature_Id = @SignatureId where Tedet_id = @DPrev_Id
 	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@DPrev_Id, 2)
              -- Update Start_Time of Next Detail Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Start_Time of Next Detail Record')
              update timed_event_details set start_time = @end_time, Signature_Id = @SignatureId where Tedet_id = @DNext_Id
 	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@DNext_Id, 2)
              -- Check To See If We Are Combining Multiple Summary Records.
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Check To See If We Are Combining Multiple Summary Records.')
              if (@SPrev_Id <> @SNext_Id) and (@SNext_Id is not null)
                begin
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@SPrev_Id <> @SNext_Id and @SNext_Id is not null') 
                  -- We Have Combining Summaries, Update The End Time Of Prev To End Time Next
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'We Have Combining Summaries, Delete The Next Summary Comment')
                  -- Delete The Next Summary Comment
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete The Next Summary Comment')
                  -- Performs better than a straight delete 'cuz you don't have to touch the comments table 
                  --    and an OR on comments.comment_id and comments.topofchain_id causes a table scan of Timed_Event_Details 
                  Select @DeleteComment_Id = NULL
                  Select @DeleteComment_Id = Summary_Cause_Comment_Id FROM Timed_Event_Details Where TEDet_Id = @SNext_Id
                  If  @DeleteComment_Id IS NOT NULL
                    BEGIN
                      Delete From Comments Where TopOfChain_Id = @DeleteComment_Id 
                      Delete From Comments Where Comment_Id = @DeleteComment_Id 
                      Update Timed_Event_Details Set Summary_Cause_Comment_Id = NULL, Signature_Id = @SignatureId Where TEDet_Id = @SNext_Id
 	  	  	  	       -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	       Insert into @DTUpdates(TEDId, TransType) Values(@SNext_Id, 2)
                    END 
                end 
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 1
              GOTO PROCEND
            end
          -- Update Prev Detail Record If Last Detail
          if @DetailOrder = 'Last' 
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Prev Detail Record If Last Detail')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Last') 
              -- Update End_Time of Previous Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update End_Time of Previous Record')
 	  	  	   Execute spServer_DBMgrCleanupDownTime @DPrev_Id,@start_time,@ReturnResultSets,@UserId
              update timed_event_details set end_time = @start_time, Signature_Id = @SignatureId  where Tedet_id = @DPrev_Id
 	  	       -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	       Insert into @DTUpdates(TEDId, TransType) Values(@DPrev_Id, 2)
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 1
              GOTO PROCEND
            end
          -- Update Next Detail Record When First In List
          if @DetailOrder = 'First'
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Next Detail Record When First In List')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = First') 
              -- Update Start_Time of Next Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Start_Time of Next Record')
 	  	     Execute spServer_DBMgrCleanupUpTime @DNext_Id,@end_time,@ReturnResultSets,@UserId
              update timed_event_details  set start_time = @end_time,Uptime = Null, Signature_Id = @SignatureId where Tedet_id = @DNext_Id
 	  	       -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	       Insert into @DTUpdates(TEDId, TransType) Values(@DNext_Id, 2)
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 1
              GOTO PROCEND
            end
          -- No Action Needed
          if @DetailOrder = 'Only'
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Action Needed') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Only') 
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 1
              GOTO PROCEND
            end
          -- This Detail Is Competeley Inside The Previous Detail
          if @DetailOrder = 'Inside'             
            begin
             If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'This Detail Is Competeley Inside The Previous Detail')
             If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Inside') 
              -- Update End_Time of Previous Detail Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update End_Time of Previous Detail Record')
 	  	     Execute spServer_DBMgrCleanupDownTime @DPrev_Id,@start_time,@ReturnResultSets,@UserId
              update timed_event_details set end_time = @start_time, Signature_Id = @SignatureId where Tedet_id = @DPrev_Id
 	  	       -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	       Insert into @DTUpdates(TEDId, TransType) Values(@DPrev_Id, 2)
              --Insert New Detail Record On The Other Side Of This Detail
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert New Detail Record On The Other Side Of This Detail')
              If ((@DPrev_End Is Null) Or ((@DPrev_End > @End_Time) and (@DPrev_End Is Not Null))) and (@End_Time Is Not Null)
                Begin
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '((@DPrev_End Is Null) Or ((@DPrev_End > @End_Time) and (@DPrev_End Is Not Null))) and (@End_Time Is Not Null)') 
                  insert into Timed_Event_Details(PU_Id, Source_PU_Id, Start_Time, End_Time, TEStatus_Id,TEFault_Id, Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4,Event_Reason_Tree_Data_Id)
                  Select @PU_Id, Source_PU_Id, @End_Time, @DPrev_End, TEStatus_Id,TEFault_Id, Reason_Level1, Reason_Level2, Reason_Level3,Reason_Level4,Event_Reason_Tree_Data_Id
                  From Timed_Event_Details Where TEDet_Id = @DPrev_Id
 	  	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	   Select @DTUpdateId = Scope_Identity()
 	  	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@DTUpdateId, 1)
                End
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 1
              GOTO PROCEND
            end
        end
      else if (@Transaction_Type = 2)
        begin          
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type = 2') 
          -- This should never happen on an update (@Transaction_Type = 2)
          -- If this happens the data is most likely screwed up (i.e. negative duration). In this case check the 
          -- detail records on either side of the record to be deleted. 
          If @DetailOrder = 'Inside'
            BEGIN
              If @MyOwnTrans = 1 ROLLBACK TRANSACTION
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Invalid Upd, @DetailOrder=[Inside]. Neg dur?') 
              Select @ErrorMsg = 'Invalid Upd, @DetailOrder=[Inside]. Neg dur?'
              RAISERROR(@ErrorMsg, 11, -1)
              return(-100)
            END
 	  	   Select @OldEndTime = End_Time,@OldStartTime = Start_Time From Timed_Event_Details Where (Tedet_Id =  @TEDet_Id)
 	        if @DetailOrder = 'First' or @DetailOrder = 'Only'
 	  	  	  	 Select @Uptime = convert(real, datediff(second,@SPrev_End,@start_time)) / 60
 	   	   If @TransNum = 0
 	  	     Begin
 	    	  	   Select  @Source_PU_Id = Coalesce(@Source_PU_Id,Source_PU_Id),
 	  	  	     @Start_Time = Coalesce(@Start_Time,Start_Time),
 	      	  	 @End_Time = Coalesce(@End_Time,End_Time),
 	      	  	 @TEStatus_Id = Coalesce(@TEStatus_Id,TEStatus_Id),
 	      	  	 @TEFault_Id = Coalesce(@TEFault_Id,TEFault_Id),
 	      	  	 @Reason_Level1 = Coalesce(@Reason_Level1,Reason_Level1),
 	      	  	 @Reason_Level2 = Coalesce(@Reason_Level2,Reason_Level2),
 	      	  	 @Reason_Level3 = Coalesce(@Reason_Level3,Reason_Level3),
 	      	  	 @Reason_Level4 = Coalesce(@Reason_Level4,Reason_Level4),
 	      	  	 @Action1 = Coalesce(@Action1,Action_Level1),
 	      	  	 @Action2 = Coalesce(@Action2,Action_Level2),
 	      	  	 @Action3 = Coalesce(@Action3,Action_Level3),
 	      	  	 @Action4 = Coalesce(@Action4,Action_Level4),
 	      	  	 @ResearchUserId = Coalesce(@ResearchUserId,Research_User_Id),
 	      	  	 @ResearchStatusId = Coalesce(@ResearchStatusId,Research_Status_Id),
 	      	  	 @ResearchOpenDate = Coalesce(@ResearchOpenDate,Research_Open_Date),
 	      	  	 @ResearchCloseDate = Coalesce(@ResearchCloseDate,Research_Close_Date),
 	      	  	 @UserId = Coalesce(@UserId,User_Id),
 	  	  	  	  	 @Uptime = Coalesce(@Uptime,Uptime),
 	  	  	  	  	 @OldEndTime = End_Time,
 	  	  	  	  	 @OldStartTime = Start_Time,
                        @SignatureId = Coalesce(@SignatureId, Signature_Id)
 	    	  	  From Timed_Event_Details
 	    	  	  Where (Tedet_Id =  @TEDet_Id)
 	  	  	   End
 	  	   ELSE IF @TransNum = 1010
 	  	   BEGIN
 	  	  	 SELECT @Start_Time = Coalesce(@Start_Time,Start_Time),
 	  	  	  	  	 @OldEndTime = End_Time,
 	  	  	  	  	 @OldStartTime = Start_Time
 	    	  	  From Timed_Event_Details
 	    	  	  Where (Tedet_Id =  @TEDet_Id)
 	  	   END
 	  	   If @Event_Reason_Tree_Data_Id is null and @Reason_Level1 is not null
 	  	  	 Begin
 	  	  	   Select @TreeId = Name_Id From Prod_Events where PU_Id = @Source_PU_Id and Event_Type = 2
 	  	    	   If @Reason_Level2 Is null
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	    	   Else If @Reason_Level3 Is null
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	    	   Else If @Reason_Level4 Is null
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	    	   Else 
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id  = @Reason_Level4 and Tree_Name_Id = @TreeId
 	  	  	 End
 	  	   If @OldEndTime is null and @End_Time is not null --record opened
 	  	  	 Execute spServer_DBMgrCleanupDownTime @TEDet_Id,null,@ReturnResultSets,@UserId
 	  	   Else If (@OldEndTime is Not null and @End_Time is not null) and (@OldEndTime <> @End_Time) --Moved
 	  	  	 Execute spServer_DBMgrCleanupDownTime @TEDet_Id,@End_Time,@ReturnResultSets,@UserId
 	  	   If (@OldStartTime is Not null and @Start_Time is not null) and (@OldStartTime <> @Start_Time) --Moved
 	  	  	 Execute spServer_DBMgrCleanupUpTime @TEDet_Id,@Start_Time,@ReturnResultSets,@UserId
 	  	  	 
          update Timed_Event_Details 
             set Source_PU_Id = @Source_PU_Id, 
                 Start_Time = @Start_Time, 
                 End_Time = @End_Time, 
                 TEStatus_Id = @TEStatus_Id,
                 TEFault_Id = @TEFault_Id, 
                 Reason_Level1 = @Reason_Level1, 
                 Reason_Level2 = @Reason_Level2, 
                 Reason_Level3 = @Reason_Level3, 
                 Reason_Level4 = @Reason_Level4,
 	  	  	   Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id,
                 Action_Level1 = @Action1,
                 Action_Level2 = @Action2,
                 Action_Level3 = @Action3,
                 Action_Level4 = @Action4,
                 Research_User_Id = @ResearchUserId,
                 Research_Status_Id = @ResearchStatusId,
                 Research_Open_Date = @ResearchOpenDate,
                 Research_Close_Date = @ResearchCloseDate,
                 User_Id = @UserId,
 	  	          Uptime  = @Uptime,
                 Signature_Id = @SignatureId
 	  	  	  	  ,Action_Comment_Id = Case when @ActionCommentId is NULL THEN Action_Comment_Id ELSE @ActionCommentId END,Cause_Comment_Id = Case when @CommentId is NULL THEN Cause_Comment_Id ELSE @CommentId END,Research_Comment_Id =Case when @ResearchCommentId is NULL THEN Research_Comment_Id ELSE @ResearchCommentId END
              where Tedet_Id =  @TEDet_Id
 	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	   Insert into @DTUpdates(TEDId, TransType) Values(@TEDet_Id, 2)
          -- Update Prev and Next Detail If In Middle
          if @DetailOrder = 'Middle'
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Prev and Next Detail If In Middle')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Middle') 
              -- Update End_Time of Previous Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update End_Time of Previous Record')
 	  	  	   Execute spServer_DBMgrCleanupDownTime @DPrev_Id,@start_time,@ReturnResultSets,@UserId
              Update timed_event_details set end_time = @start_time, Signature_Id = @SignatureId where Tedet_id = @DPrev_Id
 	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@DPrev_Id, 2)
              -- Update Start_Time of Next Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Start_Time of Next Record')
              update timed_event_details set start_time = @end_time, Signature_Id = @SignatureId where Tedet_id = @DNext_Id
 	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@DNext_Id, 2)
              -- Check To See If We Are Combining Multiple Summary Records.
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Check To See If We Are Combining Multiple Summary Records.')
              if (@SPrev_Id <> @SNext_Id) and not(@SNext_Id is null)
                begin
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@SPrev_Id <> @SNext_Id) and @SNext_Id is not null') 
                  -- We Have Combining Summaries, Update The End Time Of Prev To End Time Next
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'We Have Combining Summaries, Delete the Next Summary Comment')
                  -- Delete The Next Summary Comment
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete The Next Summary Comment')
                  -- Performs better than a straight delete 'cuz you don't have to touch the comments table 
                  --    and an OR on comments.comment_id and comments.topofchain_id causes a table scan of Timed_Event_Details 
                  Select @DeleteComment_Id = NULL
                  Select @DeleteComment_Id = Summary_Cause_Comment_Id FROM Timed_Event_Details Where TEDet_Id = @SNext_Id
                  If  @DeleteComment_Id IS NOT NULL
                    BEGIN
                      Delete From Comments Where TopOfChain_Id = @DeleteComment_Id 
                      Delete From Comments Where Comment_Id = @DeleteComment_Id 
                      Update Timed_Event_Details Set Summary_Cause_Comment_Id = NULL, Signature_Id = @SignatureId Where TEDet_Id = @SNext_Id
 	  	  	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@SNext_Id, 2)
                    END 
                end 
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 2
              GOTO PROCEND
            end 
          -- Update Prev Detail Record When Last
          if @DetailOrder = 'Last'
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Prev Detail Record When Last')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Last') 
              -- Update End_Time of Previous Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update End_Time of Previous Record')
 	  	     Execute spServer_DBMgrCleanupDownTime @DPrev_Id,@start_time,@ReturnResultSets,@UserId
              update timed_event_details set end_time = @start_time, Signature_Id = @SignatureId where Tedet_id = @DPrev_Id
 	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@DPrev_Id, 2)
 	  	     If @End_Time is Not Null and @SNext_Start is Not Null
 	  	  	   begin
                update timed_event_details 
                  set Uptime = convert(real, datediff(second,@End_Time,@SNext_Start)) / 60, Signature_Id = @SignatureId
                    where Tedet_id = @SNext_Id
 	  	  	     -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	     Insert into @DTUpdates(TEDId, TransType) Values(@SNext_Id, 2)
 	  	  	   end
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 2
              GOTO PROCEND
            end 
          -- Update Next Detail When First
          if @DetailOrder = 'First'
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Next Detail When First')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = First') 
              -- Update Start_Time of Next Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Start_Time of Next Record')
 	  	  	  	  	  	   Execute spServer_DBMgrCleanupUpTime @DNext_Id,@end_time,@ReturnResultSets,@UserId
              update timed_event_details set start_time = @end_time, Signature_Id = @SignatureId where Tedet_id = @DNext_Id
 	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@DNext_Id, 2)
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 2
              GOTO PROCEND
            end
          -- No Action Needed
          if @DetailOrder = 'Only'
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Action Needed')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Only') 
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 2
              GOTO PROCEND
            end  
        end
      else -- This Is Delete Transaction
        begin
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'This Is Delete Transaction')
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type = 3') 
          --Summary Comment Check
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Summary Comment Check')
          if (@DetailOrder = 'Only' or @DetailOrder = 'First') and @DNext_Id is NOT NULL
            Begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Only or @DetailOrder = First')
              if @DNext_Id is NULL
                Begin
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_Id is NULL...Delete Summary Comment')
                  -- Performs better than a straight delete 'cuz you don't have to touch the comments table 
                  --    and an OR on comments.comment_id and comments.topofchain_id causes a table scan of Timed_Event_Details 
                  Select @DeleteComment_Id = NULL
                  Select @DeleteComment_Id = Summary_Cause_Comment_Id FROM Timed_Event_Details Where TEDet_Id = @TEDet_Id
                  If  @DeleteComment_Id IS NOT NULL
                    BEGIN
                      Delete From Comments Where TopOfChain_Id = @DeleteComment_Id 
                      Delete From Comments Where Comment_Id = @DeleteComment_Id 
                    END 
                End
              else
                Begin
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_Id is NOT NULL...Attach Summary Comment To First Detail')
                  Update Timed_Event_Details Set Summary_Cause_Comment_Id = (Select Summary_Cause_Comment_Id From Timed_Event_Details Where TEDet_Id = @TEDet_Id), Signature_Id = @SignatureId Where TEDet_Id = @DNext_Id
 	  	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@DNext_Id, 2)
                End
            End
          Else
            Begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder <> Only and @DetailOrder <> First')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_Id is NULL...Delete Summary Comment')
              -- Performs better than a straight delete 'cuz you don't have to touch the comments table 
              --    and an OR on comments.comment_id and comments.topofchain_id causes a table scan of Timed_Event_Details 
              Select @DeleteComment_Id = NULL
              Select @DeleteComment_Id = Summary_Cause_Comment_Id FROM Timed_Event_Details Where TEDet_Id = @TEDet_Id
              If  @DeleteComment_Id IS NOT NULL
                BEGIN
                  Delete From Comments Where TopOfChain_Id = @DeleteComment_Id 
                  Delete From Comments Where Comment_Id = @DeleteComment_Id 
                END 
            End
          -- Go Ahead And Toast The Record, Comments First
          If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Go Ahead And Toast The Record, Comments First')
          -- Performs better than a straight delete 'cuz you don't have to touch the comments table 
          --    and an OR on comments.comment_id and comments.topofchain_id causes a table scan of Timed_Event_Details 
 	  	  	 Execute spServer_DBMgrCleanupDownTime @TEDet_Id,Null,@ReturnResultSets,@UserId
 	  	  	 Execute spServer_DBMgrCleanupUpTime @TEDet_Id,Null,@ReturnResultSets,@UserId
 	  	  	 INSERT INTO @CommentsToDelete(CommentId1,CommentId2,CommentId3,CommentId4,CommentId5,CommentId6)
 	  	  	  	 SELECT Cause_Comment_Id, Action_Comment_Id, Research_Comment_Id, Summary_Cause_Comment_Id, Summary_Action_Comment_Id, Summary_Research_Comment_Id 
 	  	  	  	 FROM Timed_Event_Details  
 	  	  	  	 WHERE TEDet_Id = @TEDet_Id
 	  	  	    	 SET @originalContextInfo = Context_Info()
 	  	  	  	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	  	  	  	 SET Context_Info @ContextInfo 
 	  	  	  	 Delete from Timed_Event_Details where Tedet_Id =  @TEDet_Id 
 	  	    	  	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo 
 	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	   Insert into @DTUpdates(TEDId, TransType) Values(@TEDet_Id, 3)
          -- If this happens the data is most likely screwed up. In this case check the 
          -- detail records on either side of the record to be deleted. 
          if @DetailOrder = 'Inside'
            begin
               If @MyOwnTrans = 1 rollback transaction
 	            Select @ErrorMsg = '[Inside] on delete. Details out of sync TED_Id:' + Coalesce(convert(nVarChar(50),@TEDet_Id),'Null')
               RAISERROR(@ErrorMsg, 11, -1)
               return(-100)
            end
          -- Update Prev If Neccessary
          -- Bounded By Prev Detail Records
          if @DetailOrder = 'Middle' or @DetailOrder = 'First'
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Prev If Neccessary')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Bounded By Prev Detail Records')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Middle or @DetailOrder = First') 
              -- Make sure the deleted record is not prev
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Make sure the deleted record is not prev')
              if (@Tedet_ID = @DPrev_Id) 
               begin
                 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Tedet_ID = @DPrev_Id') 
                 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END') 
                 If @MyOwnTrans = 1 rollback transaction
                 RAISERROR('Tried To Delete Previous', 11, -1)
                 return(-100)
               end                      
              -- Update Start Time Next Record To Start Time Of Deleted Record
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Start Time Next Record To Start Time Of Deleted Record')
              if @DNext_End is null 
                begin
 	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_End is null') 
 	  	  	  	 Execute spServer_DBMgrCleanupUpTime @DNext_Id,@DCurrent_Start,@ReturnResultSets,@UserId
 	  	  	  	 update timed_event_details  set start_time = @DCurrent_Start, Signature_Id = @SignatureId where Tedet_id = @DNext_Id
 	  	  	  	 -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	 Insert into @DTUpdates(TEDId, TransType) Values(@DNext_Id, 2)
 	  	  	  	 If @DetailOrder = 'First'
 	  	  	  	   begin
 	  	  	  	  	 update timed_event_details 
 	  	  	  	  	 set Uptime = convert(real, datediff(second,@SPrev_End,@DCurrent_Start)) / 60, Signature_Id = @SignatureId
 	  	  	  	  	 where Tedet_id = @DPrev_Id
 	  	  	  	  	 -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	  	 Insert into @DTUpdates(TEDId, TransType) Values(@DPrev_Id, 2)
 	  	  	  	   end
                end
              else
                begin
                  If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_End is NOT null') 
 	  	  	    Execute spServer_DBMgrCleanupUpTime @DNext_Id,@DCurrent_Start,@ReturnResultSets,@UserId
 	  	  	  	 IF @DNext_End <=  @DCurrent_Start 
 	  	  	  	 BEGIN
 	  	  	  	   If @MyOwnTrans = 1 Rollback transaction
 	  	  	  	   If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DNext_End <= @DCurrent_Start - Delete Caused a (-) duration') 
 	  	  	  	   If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	  	   Select @ErrorMsg = 'Invalid Delete Neg dur?'
 	  	  	  	   RAISERROR(@ErrorMsg, 11, -1)
 	  	  	  	   RETURN(-100)
 	  	  	  	 END
                  update timed_event_details 
                  set start_time = @DCurrent_Start, Signature_Id = @SignatureId
                  where Tedet_id = @DNext_Id
 	  	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@DNext_Id, 2)
 	  	  	  	   EXEC spServer_DBMgrUpdPendingResultSet NULL, 16, @DNext_Id, 2, @TransNum, 5, @UserId
                  If @DetailOrder = 'First'
 	  	  	  	  	 begin
 	  	  	  	  	  	 update timed_event_details 
 	  	  	  	  	  	 set Uptime = convert(real, datediff(second,@SPrev_End,@DCurrent_Start)) / 60, Signature_Id = @SignatureId
 	  	  	  	  	  	 where Tedet_id = @DNext_Id
 	  	  	  	  	     -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	  	     Insert into @DTUpdates(TEDId, TransType) Values(@DNext_Id, 2)
 	  	  	  	  	 end
                end
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 3
              GOTO PROCEND
            end           
          -- No Action Needed
          if @DetailOrder = 'Last'
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Action Needed')
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Last') 
 	  	     -- Fix Uptime
 	  	     Exec spServer_DBMgrUpdCmnTimedEventSummaryInfo @PU_Id, @Start_Time, 1, @SCurr_Id OUTPUT, @SCurr_Start OUTPUT, @SCurr_End OUTPUT
 	  	     If @SCurr_End Is Not Null and @SNext_Start is not Null
 	  	  	  Begin
                    update timed_event_details 
                    set Uptime = convert(real, datediff(second,@SCurr_End,@SNext_Start)) / 60, Signature_Id = @SignatureId
                    where Tedet_id = @SNext_Id
 	  	  	  	  	 -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	  	 Insert into @DTUpdates(TEDId, TransType) Values(@SNext_Id, 2)
 	  	  	  End
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 3
              GOTO PROCEND
            end
          -- Delete Summary Comment When Only
          if @DetailOrder = 'Only'
            begin
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Summary Comment When Only') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DetailOrder = Only') 
              -- This Is The Only Detail Record For The Summary
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'This Is The Only Detail Record For The Summary')
              -- Delete The Summary Comment
              -- Performs better than a straight delete 'cuz you don't have to touch the comments table 
              --    and an OR on comments.comment_id and comments.topofchain_id causes a table scan of Timed_Event_Details 
              Select @DeleteComment_Id = NULL
              Select @DeleteComment_Id = Summary_Cause_Comment_Id FROM Timed_Event_Details Where TEDet_Id = @SPrev_Id
              If  @DeleteComment_Id IS NOT NULL
                BEGIN
                  Delete From Comments Where TopOfChain_Id = @DeleteComment_Id 
                  Delete From Comments Where Comment_Id = @DeleteComment_Id 
                  Update Timed_Event_Details Set Summary_Cause_Comment_Id = NULL, Signature_Id = @SignatureId Where TEDet_Id = @SPrev_Id
 	  	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@SPrev_Id, 2)
                END 
 	  	     -- Fix Uptime
 	  	     If @SPrev_End Is Not Null and @SNext_Start is not Null
 	  	  	  Begin
                    update timed_event_details 
                    set Uptime = convert(real, datediff(second,@SPrev_End,@SNext_Start)) / 60, Signature_Id = @SignatureId
                    where Tedet_id = @SNext_Id
 	  	  	  	   -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	  	   Insert into @DTUpdates(TEDId, TransType) Values(@SNext_Id, 2)
 	  	  	  End
              If @MyOwnTrans = 1 commit transaction
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
              If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	  	   Select @ReturnStatus = 3
              GOTO PROCEND
            end          
        end
    end
ELSE
BEGIN /* @Transaction_Type = 4 */
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@Transaction_Type = 4 -- e.g. From TimedEventMgr') 
 	 -- 'Complete Transaction Simply Closes Open Records 
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Complete Transaction Simply Closes Open Records')
 	 select @DPrev_Id = null
 	 Select @DPrev_Start = Max(start_time)
 	  	 From timed_event_details
 	  	 where  Pu_Id = @Pu_Id 
 	 select @DPrev_Id = TeDet_Id,@DPrev_Start = Start_Time,@DPrev_End = End_Time
 	  	 from timed_event_details
 	  	 where (Pu_Id = @Pu_Id) and (start_time = @DPrev_Start)
 	 if (@DPrev_Id is null) or (@DPrev_Start >= @End_Time) Or (@DPrev_End is not null)
 	 begin
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@DPrev_Id is null or @DPrev_Start >= @End_Time Or @DPrev_End is not null') 
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	 --RAISERROR('Complete Transaction Did Not Find Null Record (Detail)', 11, -1)
 	  	 return(5)
 	 end
 	 If @MyOwnTrans = 1 
 	 Begin
 	  	 BEGIN TRANSACTION
 	  	 SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
 	 End
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'begin transaction') 
 	 -- update detail
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'update detail')
 	 Execute spServer_DBMgrCleanupDownTime @DPrev_Id,@end_time,@ReturnResultSets,@UserId
    IF @TransNum = 2
 	 BEGIN
 	  	 If @Event_Reason_Tree_Data_Id is null and @Reason_Level1 is not null
 	  	 Begin
 	  	  	 Select @TreeId = Name_Id From Prod_Events where PU_Id = @Source_PU_Id and Event_Type = 2
 	  	  	 If @Reason_Level2 Is null
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	  	 Else If @Reason_Level3 Is null
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	  	 Else If @Reason_Level4 Is null
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	  	 Else 
 	  	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Reason_Level1 and  Level2_Id = @Reason_Level2 and  Level3_Id = @Reason_Level3 and Level4_Id  = @Reason_Level4 and Tree_Name_Id = @TreeId
 	  	 End
 	     UPDATE timed_event_details set end_time = @end_time,
 	  	     TEStatus_Id = @TEStatus_Id,
 	  	     TEFault_Id = @TEFault_Id, 
 	  	     Reason_Level1 = @Reason_Level1, 
 	  	     Reason_Level2 = @Reason_Level2, 
 	  	     Reason_Level3 = @Reason_Level3, 
 	  	     Reason_Level4 = @Reason_Level4,
 	  	     Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id,
 	  	     Source_PU_Id = @Source_PU_Id,
 	  	     Signature_Id = @SignatureId
 	     WHERE tedet_id = @DPrev_Id
 	     SELECT @TEDet_Id = @DPrev_Id
 	     -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	     Insert into @DTUpdates(TEDId, TransType) Values(@DPrev_Id, 2)
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @TransNum < 0 AND DATEDIFF(Second,@End_Time,@DPrev_Start) > @TransNum -- This is a Min duration close
 	  	 BEGIN
 	  	  	 Execute spServer_DBMgrCleanupUpTime @DPrev_Id,Null,@ReturnResultSets,@UserId
 	  	  	 SET @originalContextInfo = Context_Info()
 	  	  	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	  	  	 SET Context_Info @ContextInfo 
 	  	  	 DELETE FROM  Timed_Event_Details where Tedet_Id =  @DPrev_Id 
 	  	  	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo 
 	  	  	 Insert into @DTUpdates(TEDId, TransType) Values(@DPrev_Id, 3)
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 UPDATE timed_event_details set end_time = @end_time, Signature_Id = @SignatureId where tedet_id = @DPrev_Id
 	  	  	 SELECT @TEDet_Id = @DPrev_Id
 	  	  	 -- 2/2009 - JG Added for post updates - WHERE clause must match previous one
 	  	  	 Insert into @DTUpdates(TEDId, TransType) Values(@DPrev_Id, 4)
 	  	  	 -- 7/2/2010
 	  	  	 Select 5, t.PU_Id, t.Source_PU_Id, t.TEStatus_Id, t.TEFault_Id, t.Reason_Level1, t.Reason_Level2, t.Reason_Level3, t.Reason_Level4, 
 	  	  	  	 null, (CONVERT([decimal](10,2),datediff(second,t.Start_Time,t.End_Time)/(60.0),0)), 4, Start_Time, End_Time, t.TEDet_Id, 1, null, Action_Level1, Action_Level2, Action_Level3, Action_Level4, 
 	  	  	  	 Action_Comment_Id, Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date, Cause_Comment_Id,null,  
 	  	  	  	 NULL, NULL, NULL, NULL, NULL, NULL,Research_User_Id, Event_Reason_Tree_Data_Id,Signature_Id
 	  	  	 From Timed_event_details t
 	  	  	 WHERE t.TEDet_Id = @DPrev_Id
 	  	 END
 	 END
    If @MyOwnTrans = 1 commit transaction
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
      Select @ReturnStatus = 4
    GOTO PROCEND
END
/* Check and Fix Uptime */
  --If we get to the bottom of this proc and the transaction is still open something bad happpened rollback the changes. 
  If @@Trancount > 0 
    BEGIN
      If @MyOwnTrans = 1 ROLLBACK TRANSACTION
      If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'TranCount>0,rolling back.') 
      Select @ErrorMsg = 'TranCount>0,rolling back. @DetailOrder = ' + @DetailOrder
      RAISERROR(@ErrorMsg, 11, -1)
      return(-100)
    END
return(5) 
PROCEND:
 	 INSERT INTO @CommentsToDelete2(CommentId)
 	  	 SELECT CommentId1
 	  	 FROM @CommentsToDelete
 	 INSERT INTO @CommentsToDelete2(CommentId)
 	  	 SELECT CommentId2
 	  	 FROM @CommentsToDelete
 	 INSERT INTO @CommentsToDelete2(CommentId)
 	  	 SELECT CommentId3
 	  	 FROM @CommentsToDelete
 	 INSERT INTO @CommentsToDelete2(CommentId)
 	  	 SELECT CommentId4
 	  	 FROM @CommentsToDelete
 	 INSERT INTO @CommentsToDelete2(CommentId)
 	  	 SELECT CommentId5
 	  	 FROM @CommentsToDelete
 	 INSERT INTO @CommentsToDelete2(CommentId)
 	  	 SELECT CommentId6
 	  	 FROM @CommentsToDelete
 	 DELETE FROM @CommentsToDelete2 WHERE CommentId Is Null
 	 IF @SummaryCommentSaved is Not Null
 	  	 DELETE FROM @CommentsToDelete2 WHERE CommentId = @SummaryCommentSaved
 	 IF @DetailCommentSaved is Not Null
 	  	 DELETE FROM @CommentsToDelete2 WHERE CommentId = @DetailCommentSaved
 	 DECLARE @ThisCommentId Int
 	 DECLARE Comment_Del_Cursor CURSOR
 	  	 FOR SELECT CommentId
 	  	 FROM @CommentsToDelete2
 	 OPEN Comment_Del_Cursor
 	 Fetch_Next_Cmmt:
 	 FETCH NEXT FROM Comment_Del_Cursor INTO @ThisCommentId
 	 IF @@FETCH_STATUS = 0
 	 BEGIN
 	  	 Delete From Comments Where TopOfChain_Id = @ThisCommentId 
 	  	 Delete From Comments Where Comment_Id = @ThisCommentId 
 	  	 GOTO Fetch_Next_Cmmt
    END
  if exists (Select 1 from @DTUpdates) And @ReturnResultSets = 1 
    begin
 	  	 -- Clear out NULLs and Duplicate records - 
 	  	 -- 	 this allows us to avoid a bunch of IF statements on the above INSERTS
 	  	 Delete @DTUpdates where TEDId is NULL
 	  	 Insert Into @DTUpdatesNoDup (TEDId, TransType) Select DISTINCT TEDId, TransType from @DTUpdates
 	  	 --Inserts/Updates only 
 	  	 Select 5, t.PU_Id, t.Source_PU_Id, t.TEStatus_Id, t.TEFault_Id, t.Reason_Level1, t.Reason_Level2, t.Reason_Level3, t.Reason_Level4, 
 	  	   -1, (CONVERT([decimal](10,2),datediff(second,t.Start_Time,t.End_Time)/(60.0),0)), u.TransType, Start_Time, End_Time, u.TEDId, 1, null, Action_Level1, Action_Level2, Action_Level3, Action_Level4, 
 	  	   Action_Comment_Id, Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date, Cause_Comment_Id,null,  
 	  	   NULL, NULL, NULL, NULL, NULL, NULL,Research_User_Id, Event_Reason_Tree_Data_Id,Signature_Id,User_Id,Duration 
 	  	   From Timed_event_details t
 	  	   Join @DTUpdatesNoDup u on u.TEDId = t.TEDet_Id and u.TransType <> 3  
 	     --Deletes
 	  	 Select 5, @PU_Id, null, null, null, null, null, null, null, 
 	  	   -1, null, u.TransType, null, null, u.TEDId, 1, null, null, null, null, null, 
 	  	   null, null, null, null, null, null,null,  
 	  	   NULL, NULL, NULL, NULL, NULL, NULL,null, null,null,@UserId
 	  	   From @DTUpdatesNoDup u 
 	  	  	 Where u.TransType = 3  
    end
   return(@ReturnStatus)  
