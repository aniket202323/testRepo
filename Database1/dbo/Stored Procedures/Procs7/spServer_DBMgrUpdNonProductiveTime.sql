CREATE PROCEDURE dbo.spServer_DBMgrUpdNonProductiveTime
  @NPDetId          Int        OUTPUT,
  @PUId             	 Int, 	 
  @StartTime        	 Datetime, 
  @EndTime          	 Datetime,
  @ReasonLevel1     	 Int, 	 
  @ReasonLevel2     	 Int,
  @ReasonLevel3     	 Int,
  @ReasonLevel4     	 Int,
  @TransactionType  	 Int,
  @TransNum  	  	 Int,
  @UserId  	  	 Int,
  @CommentId 	  	 Int,
  @ERTDataId  	  	 Int,
  @EntryOn 	  	 DateTime,
  @NPTGroupId 	 Int = Null,
  @ReturnAllResults Int = 0, 	 -- 0 = Return only RS of other NPT affected by this one, 1 = Return All result sets including this one, 2 = No result sets
  @ReturnResultSets 	 Int = 1 	  	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
 	 
AS
IF @ReturnAllResults is Null SET @ReturnAllResults = 0
Declare @DebugFlag  	  	 Tinyint
Declare @DeleteCommentId 	 Int
Declare @MyOwnTrans  	 Int
Declare @ID 	  	  	 Int
Declare @CursorDetId Int
Declare @CursorStartTime Datetime
Declare @CursorEndTime Datetime
Declare @ReturnCode int
Declare @NPTUpdates TABLE ( 
 NPDetid int null , 
 TransType int)
 Declare @NPTUpdatesNoDups TABLE ( 
 NPDetid int null , 
 TransType int)
If @@Trancount = 0
 	 Select @MyOwnTrans = 1
Else
 	 Select @MyOwnTrans = 0
--select @DebugFlag = 1 
If @DebugFlag = 1 
BEGIN 
 	 Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
 	 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
 	 Insert into Message_Log_Detail (Message_Log_Id, Message)
 	  Values(@ID, 'in DBMgrUpdNonProductiveTime /NPDetId: ' + Isnull(convert(nVarChar(4),@NPDetId),'Null') + 
 	 ' /PUId: ' + Isnull(convert(nVarChar(4),@PUId),'Null') +  	 ' /StartTime: ' + Isnull(convert(nVarChar(25),@StartTime),'Null') + 
 	 ' /EndTime: ' + Isnull(convert(nVarChar(25),@EndTime),'Null') + ' /ReasonLevel1: ' + Isnull(convert(nVarChar(4),@ReasonLevel1),'Null') + 
 	 ' /ReasonLevel2: ' + Isnull(convert(nVarChar(4),@ReasonLevel2),'Null') + ' /ReasonLevel3: ' + Isnull(convert(nVarChar(4),@ReasonLevel3),'Null') + 
 	 ' /ReasonLevel4: ' + Isnull(convert(nVarChar(4),@ReasonLevel4),'Null') + ' /TransactionType: ' + Isnull(convert(nVarChar(4),@TransactionType),'Null') + 
 	 ' /TransNum: ' + Isnull(convert(nVarChar(4),@TransNum),'Null') + ' /UserId ' + Isnull(convert(nVarChar(4),@UserId),'Null') +  
 	 ' /CommentId: ' + Isnull(convert(nVarChar(4),@CommentId),'Null') + ' /ERTDataId ' + Isnull(convert(nVarChar(4),@ERTDataId),'Null') + 
 	 ' /EntryOn ' + Isnull(convert(nVarChar(25),@EntryOn),'Null') )
END
  --
  -- Return Values:
  --
  --   (-100) Error.
  --   (   1) Success: New record added.
  --   (   2) Success: Existing record modified.
  --   (   3) Success: Existing record deleted.
  --   (   4) Success: No action taken.
  --
  -- Transaction Types
  --   (   1) Insert/Add
  --   (   2) Update 
  --   (   3) Delete 
  --
DECLARE  	 @CheckId  	 Int,
 	  	 @PrevET 	 DateTime,
 	  	 @NextST 	 DateTime,
 	  	 @TreeId 	 Int
SELECT @EntryOn = IsNull(@EntryOn,dbo.fnServer_CmnGetDate(getUTCdate()))
  -- Make sure mandatory arguments are not null.
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Make sure mandatory arguments are not null.')
If (@TransNum =1010) -- Transaction From WebUI
  SELECT @TransNum = 2
If @TransNum NOT IN (0,2,1000)
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransNum NOT IN (0,2,1000)') 
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	 Return(-100)
END
IF @TransNum = 1000 /* Update Comment*/
 	 BEGIN
 	  	 IF @NPDetId is Null or @UserId Is Null -- Check required fields
 	  	  	 RETURN(4)
 	  	 SET @CheckId  = NULL
 	  	 SELECT  @CheckId = NPDet_Id FROM NonProductive_Detail WHERE NPDet_Id  = @NPDetId
 	  	 IF @CheckId is Null RETURN(4)-- Not Found
 	  	  	 UPDATE NonProductive_Detail SET Comment_id = @CommentId,User_Id  = @UserId,Entry_On = @EntryOn  
 	  	  	  	 WHERE NPDet_Id  = @NPDetId
 	  	  	 Insert into @NPTUpdates (NPDetid, TransType) Values (@NPDetId, @TransactionType)
 	  	 select @ReturnCode = 2
 	  	 goto OutputResults
 	 END
IF @PUId IS NULL
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@PUId IS NULL') 
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	 RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@PUId')
 	 RETURN(-100)
END
IF @TransactionType IS NULL
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransactionType IS NULL') 
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	 RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@TransactionType')
 	 RETURN(-100)
END
IF @StartTime IS NULL
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@StartTime IS NULL') 
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	 RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@StartTime')
 	 RETURN(-100)
END
IF @EndTime IS NULL
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@EndTime IS NULL') 
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	 RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@EndTime')
 	 RETURN(-100)
END
IF @StartTime >= @EndTime
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@StartTime >= @EndTime') 
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	 RAISERROR('Start Time Must be < End Time', 11, -1)
 	 RETURN(-100)
END
-- Make sure the transaction type is ok. Depending on the transaction type,
-- other arguments may also become mandatory. Make sure these dependant
-- mandatory arguments are not null.
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Make sure the transaction type is ok. Depending on the transaction type,')
IF @TransactionType = 2 OR @TransactionType = 3
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransactionType = 2 OR @TransactionType = 3') 
 	 IF @NPDetId IS NULL
 	 BEGIN
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update or Delete AND @NPDetId IS NULL') 
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	 RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@NPDetId')
 	  	 RETURN(-100)
 	 END
 	 SELECT @CheckId = Null
 	 SELECT @CheckId = NPDet_Id From NonProductive_Detail Where  NPDet_Id = @NPDetId
 	 IF @CheckId IS NULL
 	 BEGIN
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update or Delete AND @NPDetId Not Found') 
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	 RAISERROR('Mandatory stored procedure argument %s not found.', 11, -1, '@NPDetId')
 	  	 RETURN(-100)
 	 END    
END
ELSE IF @TransactionType = 1
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransactionType = 1') 
END
ELSE
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransactionType <> 1,2, or 3') 
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	 RAISERROR('Unknown transaction type detected:  %lu', 11, -1, @TransactionType)
 	 RETURN(-100)
END
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'begin transaction') 
If @MyOwnTrans = 1 
  BEGIN
    BEGIN TRANSACTION
    DECLARE @XLock BIT SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
  END
If @ERTDataId is null and @ReasonLevel1 is not null
BEGIN
 	 Select @TreeId = Non_Productive_Reason_Tree From Prod_Units_Base where PU_Id = @PUId
 	 If @ReasonLevel2 Is null
 	  	 Select @ERTDataId = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @ReasonLevel1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	 Else If @ReasonLevel3 Is null
 	  	 Select @ERTDataId = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @ReasonLevel1 and  Level2_Id = @ReasonLevel2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	 Else If @ReasonLevel4 Is null
 	  	 Select @ERTDataId = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @ReasonLevel1 and  Level2_Id = @ReasonLevel2 and  Level3_Id = @ReasonLevel3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	 Else 
 	  	 Select @ERTDataId = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @ReasonLevel1 and  Level2_Id = @ReasonLevel2 and  Level3_Id = @ReasonLevel3 and Level4_Id  = @ReasonLevel4 and Tree_Name_Id = @TreeId
END
IF  @TransactionType = 1 -- INSERT
BEGIN
 	     --Ignore this add if this record will be completely contained in an existing event
 	     Declare @ExistsNPDetId int
 	     select @ExistsNPDetId = null --Initialize
 	     Select @ExistsNPDetId = NPDet_Id from NonProductive_Detail where Start_Time <= @StartTime and End_Time >= @EndTime and PU_Id = @PUId
 	     
 	     if not @ExistsNPDetId is Null
 	       Begin
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 Select @ReturnCode = 4
 	  	  	 goto OutputResults
 	       End
 	       
 	  	 --Cleanup any overlapping Non-productive times before updating row
 	  	  Declare CleanUpCursor Cursor
 	  	   For Select NPDet_Id, Start_Time, End_Time
 	  	   From NonProductive_Detail 
 	  	  	 where (Pu_Id = @PUid) and ((start_time >= @StartTime) and (start_time <= @EndTime) or (end_Time >= @StartTime and end_time <= @EndTime))           
 	  	  	 order by Start_Time
 	  	  Open CleanUpCursor
 	  	  Cleanuploop:
 	  	  Fetch Next From CleanUpCursor Into @CursorDetId, @CursorStartTime, @CursorEndTime
 	  	  If @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	   --skip this record
 	  	  	   if (@CursorDetId = @NPDetId) goto Cleanuploop
 	  	  	   --This NPT exists completely within the new record - delete it
 	  	  	   if (@CursorStartTime >= @StartTime) and (@CursorEndTime <= @EndTime)
 	  	  	     Begin
 	  	  	       Select @DeleteCommentId = NULL
 	  	  	  	   Select @DeleteCommentId = Comment_Id FROM NonProductive_Detail Where NPDet_Id = @CursorDetId
 	  	  	  	   If  @DeleteCommentId IS NOT NULL
 	  	  	  	   BEGIN
 	  	  	  	  	 Delete From Comments Where TopOfChain_Id = @DeleteCommentId 
 	  	  	  	  	 Delete From Comments Where Comment_Id = @DeleteCommentId 
 	  	  	  	   END 
 	  	  	       Delete from NonProductive_Detail Where NPDet_Id = @CursorDetId
 	  	  	       Insert into @NPTUpdates(NPDetid, TransType) values(@CursorDetId, 3)
 	  	  	     End
 	  	  	   --Move the NPT start time to End time of this record
 	  	  	   if (@CursorStartTime < @EndTime and @CursorStartTime > @StartTime) 	  	  	   
 	  	  	     Begin
 	  	  	       Update NonProductive_Detail
 	  	  	         Set Start_Time = @EndTime where NPDet_Id = @CursorDetId
 	  	  	       Insert into @NPTUpdates(NPDetid, TransType) values(@CursorDetId, 2)
 	  	  	     End
 	  	  	   --Move the NPT end time to Start time of this record
 	  	  	   if (@CursorEndTime > @StartTime and @CursorEndTime < @EndTime)
 	  	  	     Begin
 	  	  	       Update NonProductive_Detail
 	  	  	         Set End_Time = @StartTime where NPDet_Id = @CursorDetId
 	  	  	       Insert into @NPTUpdates(NPDetid, TransType) values(@CursorDetId, 2)
 	  	  	     End
 	  	  	   Goto Cleanuploop
 	  	  	 End
 	  	   Close CleanUpCursor
 	  	   Deallocate CleanUpCursor
     If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransactionType = 1 (Inserting)') 
 	 INSERT INTO NonProductive_Detail(PU_Id, Start_Time, End_Time, Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4,User_Id, Event_Reason_Tree_Data_Id,Comment_Id,Entry_On,NPT_Group_Id)
 	   VALUES(@PUId, @StartTime, @EndTime, @ReasonLevel1, @ReasonLevel2, @ReasonLevel3,@ReasonLevel4,@UserId,@ERTDataId, @CommentId, @EntryOn,@NPTGroupId)
     SELECT @NPDetId = NPDet_Id 
 	   FROM NonProductive_Detail
 	   WHERE PU_Id = @PUId and Start_Time = @StartTime
 	 IF @NPDetId is null 
 	 BEGIN
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@NPDetId is null') 
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	  	 If @MyOwnTrans = 1 rollback transaction
 	  	 RAISERROR('Could Not find Row After Insert', 11, -1)              
 	  	 return(-100)
 	 END
 	 IF @ReturnAllResults = 1 
 	  	 Insert Into @NPTUpdates(NPDetid, TransType) values(@NPDetId, 1)
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'New NPDet_Id = ' + isnull(convert(nvarchar(10), @NPDetId),'Null'))
 	 If @MyOwnTrans = 1 Commit transaction
 	 Select @ReturnCode = 1
 	 goto OutputResults
END
ELSE IF (@TransactionType = 2)
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransactionType = 2') 
 	     --Delete if this record will be completely contained in an existing event
 	     Declare @DeleteNPDetId int
 	     select @DeleteNPDetId = null --Initialize
 	     Select @DeleteNPDetId = NPDet_Id from NonProductive_Detail where Start_Time <= @StartTime and End_Time >= @EndTime and PU_Id = @PUId
 	     
 	  	 if not @DeleteNPDetId is Null and @DeleteNPDetId <> @NPDetId
 	  	   Begin
 	  	  	 Select @DeleteCommentId = NULL
 	  	  	 Select @DeleteCommentId = Comment_Id FROM NonProductive_Detail Where NPDet_Id = @CursorDetId
 	  	  	 If  @DeleteCommentId IS NOT NULL
 	  	  	   BEGIN
 	  	  	   Delete From Comments Where TopOfChain_Id = @DeleteCommentId 
 	  	  	   Delete From Comments Where Comment_Id = @DeleteCommentId 
 	  	  	   END  	  	  	      	  	   
 	  	     If @MyOwnTrans = 1 Commit transaction
 	  	     Delete from NonProductive_Detail where NPDet_Id = @NPDetId
 	  	  	  	 Insert into @NPTUpdates(NPDetid, TransType) values(@NPDetId, 3)
 	  	     Select @ReturnCode = 3
 	  	     goto OutputResults
 	  	   End
 	  	   
 	  	 --Cleanup any overlapping Non-productive times before updating row
 	  	  Declare CleanUpCursor2 Cursor
 	  	   For Select NPDet_Id, Start_Time, End_Time
 	  	   From NonProductive_Detail 
 	  	  	 where (Pu_Id = @PUid) and ((start_time >= @StartTime) and (start_time <= @EndTime) or (end_Time >= @StartTime and end_time <= @EndTime))           
 	  	  	 order by Start_Time
 	  	  Open CleanUpCursor2
 	  	  Cleanuploop2:
 	  	  Fetch Next From CleanUpCursor2 Into @CursorDetId, @CursorStartTime, @CursorEndTime
 	  	  If @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	   --skip this record
 	  	  	   if (@CursorDetId = @NPDetId) goto Cleanuploop2
 	  	  	   --This NPT exists completely within the new record - delete it
 	  	  	   if (@CursorStartTime >= @StartTime) and (@CursorEndTime <= @EndTime)
 	  	  	     Begin
 	  	  	       Select @DeleteCommentId = NULL
 	  	  	  	   Select @DeleteCommentId = Comment_Id FROM NonProductive_Detail Where NPDet_Id = @CursorDetId
 	  	  	  	   If  @DeleteCommentId IS NOT NULL
 	  	  	  	   BEGIN
 	  	  	  	  	 Delete From Comments Where TopOfChain_Id = @DeleteCommentId 
 	  	  	  	  	 Delete From Comments Where Comment_Id = @DeleteCommentId 
 	  	  	  	   END  	  	  	     
 	  	  	       Delete from NonProductive_Detail Where NPDet_Id = @CursorDetId
 	  	  	       Insert into @NPTUpdates(NPDetid, TransType) values(@CursorDetId, 3)
 	  	  	     End
 	  	  	   --Move the NPT start time to End time of this record
 	  	  	   if (@CursorStartTime < @EndTime and @CursorStartTime > @StartTime) 	  	  	   
 	  	  	     Begin
 	  	  	       Update NonProductive_Detail
 	  	  	         Set Start_Time = @EndTime where NPDet_Id = @CursorDetId
 	  	  	       Insert into @NPTUpdates(NPDetid, TransType) values(@CursorDetId, 2)
 	  	  	     End
 	  	  	   --Move the NPT end time to Start time of this record
 	  	  	   if (@CursorEndTime > @StartTime and @CursorEndTime < @EndTime)
 	  	  	     Begin
 	  	  	       Update NonProductive_Detail
 	  	  	         Set End_Time = @StartTime where NPDet_Id = @CursorDetId
 	  	  	       Insert into @NPTUpdates(NPDetid, TransType) values(@CursorDetId, 2)
 	  	  	     End
 	  	  	   Goto Cleanuploop2
 	  	  	 End
 	  	   Close CleanUpCursor2
 	  	   Deallocate CleanUpCursor2
 	  	 
 	 If @TransNum = 0
 	 BEGIN
 	    	 SELECT  @StartTime = isnull(@StartTime,Start_Time),
 	      	  	 @EndTime = isnull(@EndTime,End_Time),
 	      	  	 @ReasonLevel1 = isnull(@ReasonLevel1,Reason_Level1),
 	      	  	 @ReasonLevel2 = isnull(@ReasonLevel2,Reason_Level2),
 	      	  	 @ReasonLevel3 = isnull(@ReasonLevel3,Reason_Level3),
 	      	  	 @ReasonLevel4 = isnull(@ReasonLevel4,Reason_Level4),
 	      	  	 @CommentId = isnull(@CommentId,Comment_Id),
 	      	  	 @UserId = isnull(@UserId,User_Id)
 	  	 FROM 	 NonProductive_Detail
 	    	 WHERE (NPDet_Id =  @NPDetId)
 	 END
 	 IF @ERTDataId is null and @ReasonLevel1 is not null
 	 BEGIN
 	  	 Select @TreeId = Non_Productive_Reason_Tree From Prod_Units_Base where PU_Id = @PUId
 	  	 If @ReasonLevel2 Is null
 	  	  	 Select @ERTDataId = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @ReasonLevel1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	 Else If @ReasonLevel3 Is null
 	  	  	 Select @ERTDataId = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @ReasonLevel1 and  Level2_Id = @ReasonLevel2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	 Else If @ReasonLevel4 Is null
 	  	  	 Select @ERTDataId = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @ReasonLevel1 and  Level2_Id = @ReasonLevel2 and  Level3_Id = @ReasonLevel3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	 Else 
 	  	  	 Select @ERTDataId = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @ReasonLevel1 and  Level2_Id = @ReasonLevel2 and  Level3_Id = @ReasonLevel3 and Level4_Id  = @ReasonLevel4 and Tree_Name_Id = @TreeId
 	 END
 	 UPDATE NonProductive_Detail Set  	 Start_Time = @StartTime,
 	  	  	  	  	  	  	  	 End_Time = @EndTime,
 	  	  	  	  	  	  	  	 Reason_Level1 = @ReasonLevel1,
 	  	   	  	  	  	  	  	 Reason_Level2 = @ReasonLevel2, 
 	  	  	  	  	  	  	  	 Reason_Level3 =@ReasonLevel3, 
 	  	  	  	  	  	  	  	 Reason_Level4 = @ReasonLevel4,
 	  	  	  	  	  	  	  	 User_Id = @UserId,
 	  	  	  	  	  	  	  	 Event_Reason_Tree_Data_Id = @ERTDataId,
 	  	  	  	  	  	  	  	 Comment_Id = @CommentId,
 	  	  	  	  	  	  	  	 Entry_On = @EntryOn,
 	  	  	  	  	  	  	  	 NPT_Group_Id = @NPTGroupId
 	  	 WHERE NPDet_Id =  @NPDetId
 	 IF @ReturnAllResults = 1 
 	  	 Insert into @NPTUpdates (NPDetid, TransType) Values (@NPDetId, 2)
 	 If @MyOwnTrans = 1 Commit transaction
 	 Select @ReturnCode = 2
 	 goto OutputResults
END
ELSE  -- This Is Delete Transaction
BEGIN
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'This Is Delete Transaction')
 	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TransactionType = 3') 
 	 Select @DeleteCommentId = NULL
 	 Select @DeleteCommentId = Comment_Id FROM NonProductive_Detail Where NPDet_Id = @NPDetId
 	 If  @DeleteCommentId IS NOT NULL
 	 BEGIN
 	  	 Delete From Comments Where TopOfChain_Id = @DeleteCommentId 
 	  	 Delete From Comments Where Comment_Id = @DeleteCommentId 
 	 END 
    Delete from NonProductive_Detail where NPDet_Id =  @NPDetId 
 	 If @MyOwnTrans = 1 Commit transaction
 	 IF @ReturnAllResults = 1 
 	  	 Insert into @NPTUpdates (NPDetid, TransType) Values (@NPDetId, 3)
 	 Select @ReturnCode = 3
 	 goto OutputResults
END
If @MyOwnTrans = 1 Commit transaction
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'commit transaction') 
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
OutputResults:   
if exists (Select * from @NPTUpdates)  and @ReturnAllResults != 2 --(2 = none)
begin
 	 -- Eliminate duplicates
 	 Insert Into @NPTUpdatesNoDups (NPDetId, TransType) Select DISTINCT NPDetId, TransType from @NPTUpdates
 	 if (@ReturnResultSets = 1) -- Send out the Result Sets
 	 Begin
 	  	 --Inserts/Updates only 
 	  	 Select 21, 0, u.TransType,  2, n.PU_Id, n.Start_Time, n.End_Time, n.Reason_Level1, n.Reason_Level2, n.Reason_Level3, n.Reason_Level4, @UserId, n.Comment_Id, n.Event_Reason_Tree_Data_Id, @EntryOn, u.NPDetid
 	  	   From NonProductive_Detail n
 	  	   Join @NPTUpdatesNoDups u on u.NPDetId = n.NPDet_Id and u.TransType = 2  
 	  	 Select 21, 0, u.TransType, 2, n.PU_Id, n.Start_Time, n.End_Time, n.Reason_Level1, n.Reason_Level2, n.Reason_Level3, n.Reason_Level4, @UserId, n.Comment_Id, n.Event_Reason_Tree_Data_Id, @EntryOn, u.NPDetid
 	  	   From NonProductive_Detail n
 	  	   Join @NPTUpdatesNoDups u on u.NPDetId = n.NPDet_Id and u.TransType = 1
 	  	 --Deletes
 	  	 Select 21, 0, u.TransType, 0, @PUId, null, null, null, null, null, null, null, null, null, null, u.NPDetid
 	  	   From @NPTUpdatesNoDups u 
 	  	  	 Where u.TransType = 3
 	 End
 	 Else if (@ReturnResultSets = 2) -- Put the Result Sets into the Pending Result Sets table for DBMgr to pickup later
 	 Begin
 	  	 --Inserts/Updates only 
 	  	 if (exists(select * From NonProductive_Detail n Join @NPTUpdatesNoDups u on u.NPDetId = n.NPDet_Id and u.TransType = 2))
 	  	 begin
 	  	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	  	 SELECT 0, (
 	  	  	  	 Select RSTId = 21, PreDB = 0, TransactionType = u.TransType, TransNum = 2, PUId = n.PU_Id,
 	  	  	  	  	  	 StartTime = n.Start_Time, EndTime = n.End_Time,
 	  	  	  	  	  	 Reason1 = n.Reason_Level1, Reason2 = n.Reason_Level2, Reason3 = n.Reason_Level3, Reason4 = n.Reason_Level4, 
 	  	  	  	  	  	 UserId = @UserId, CommentId = n.Comment_Id, RsnTreeDataId = n.Event_Reason_Tree_Data_Id, EntryOn = @EntryOn,
 	  	  	  	  	  	 NPDetId = u.NPDetid
 	  	  	  	   From NonProductive_Detail n
 	  	  	  	   Join @NPTUpdatesNoDups u on u.NPDetId = n.NPDet_Id and u.TransType = 2
 	  	  	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())  
 	  	 End
 	  	 if (exists(select * From NonProductive_Detail n Join @NPTUpdatesNoDups u on u.NPDetId = n.NPDet_Id and u.TransType = 1))
 	  	 begin
 	  	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	  	 SELECT 0, (
 	  	  	  	 Select RSTId = 21, PreDB = 0, TransactionType = u.TransType, TransNum = 2, PUId = n.PU_Id,
 	  	  	  	  	  	 StartTime = n.Start_Time, EndTime = n.End_Time,
 	  	  	  	  	  	 Reason1 = n.Reason_Level1, Reason2 = n.Reason_Level2, Reason3 = n.Reason_Level3, Reason4 = n.Reason_Level4, 
 	  	  	  	  	  	 UserId = @UserId, CommentId = n.Comment_Id, RsnTreeDataId = n.Event_Reason_Tree_Data_Id, EntryOn = @EntryOn,
 	  	  	  	  	  	 NPDetId = u.NPDetid
 	  	  	  	   From NonProductive_Detail n
 	  	  	  	   Join @NPTUpdatesNoDups u on u.NPDetId = n.NPDet_Id and u.TransType = 1
 	  	  	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())  
 	  	 End
 	  	 --Deletes
 	  	 if (exists(select * From @NPTUpdatesNoDups u Where u.TransType = 3))
 	  	 begin
 	  	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	  	 SELECT 0, (
 	  	  	  	 Select RSTId = 21, PreDB = 0, TransactionType = u.TransType, TransNum = 0, PUId = @PUId,
 	  	  	  	  	  	 StartTime = null, EndTime = null,
 	  	  	  	  	  	 Reason1 = null, Reason2 = null, Reason3 = null, Reason4 = null, 
 	  	  	  	  	  	 UserId = null, CommentId = null, RsnTreeDataId = null, EntryOn = null,
 	  	  	  	  	  	 NPDetId = u.NPDetid
 	  	  	  	   From @NPTUpdatesNoDups u 
 	  	  	  	  	 Where u.TransType = 3
 	  	  	  	 for xml path ('row'), ROOT('rows'), ELEMENTS XSINIL), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())  
 	  	 End
 	 End
end
--If we get to the bottom of this proc and the transaction is still open something bad happpened rollback the changes. 
If @@Trancount > 0 
BEGIN
 	 If @MyOwnTrans = 1 
 	 BEGIN
 	  	 ROLLBACK TRANSACTION
 	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'TranCount>0,rolling back.') 
 	  	 RAISERROR('TranCount > 0 ,rolling back ', 11, -1)
 	  	 return(-100)
 	 END
END
Return(@ReturnCode)
