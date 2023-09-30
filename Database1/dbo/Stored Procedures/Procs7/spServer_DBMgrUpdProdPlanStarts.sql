CREATE PROCEDURE dbo.spServer_DBMgrUpdProdPlanStarts
@PPStartId int OUTPUT,
@TransType int,
@TransNum int,
@PUId int, 
@StartTime datetime, 
@EndTime datetime,
@PPId int,
@CommentId int,
@PPSetupId int,
@UserId int,
@ScheduleControlled Int = 0,
@Unused int = 0, --Formally @TransactionOpen, removed to reduce complexity. This was only used by Server side procs so it can be reused.
@InsertIntoPendingResultSet int = 0 --Flag asking to put ProductionPlanStart record in Pending_ResultSets table which inturn gets publised to RabbitMQ
AS
Declare @XLock BIT,
 	  	 @DebugFlag tinyint,
 	  	 @ID 	  	  	  	 int,
 	  	 @OldEndTime 	  	 DateTime,
 	  	 @Prod_Id 	  	 Int,
 	  	 @Rc 	  	  	  	 int,
 	  	 @MyOwnTrans 	  	 Int,
 	  	 @IsProduction 	 Bit 
 	  	  	  
Declare @Check int
Declare @ScheduleControlType tinyint
Declare @PathId int, @IsSchedulePointUnit int
Declare @CurrentStartTime datetime, @CurrentEndTime datetime
Declare @PreviousEndTime datetime, @NextStartTime datetime
Declare @OldPPSId int, @OldStartTime datetime
Declare @CurrentId Int, @ModifiedStart    datetime ,@ModifiedEnd datetime,@Product_Code nVarChar(25)
--For Flows Independantly (aka manual order flow)
-- Assumptions/Constraints: 
--   PU-1 through PU-5 PU-1 is Scheduling Point, 
--   PU-5 is Production Counting Point
--   flow is 1->2->3->4->5
--   Start & End times cannot be moved outside of the boundary of the previous PPStart?s start or end time. 
--
-- Logic Pseudocode for all use cases below:
--   1. Look for the MAX(start time) and if Scheduling Point unit for this pp_id, (do in this SP) 
--   2. Insert new record set the ST to current server time, set ET to NULL (capture in RS table)
--   3. If the MAX(start_time) record is NOT the Scheduling Point and its ET is NULL
-- 	  	  	  	 set ET of the MAX(start_time) record to the ST of the new record (capture in RS table)
-- 	  	  	 end if 
--
-- Use Cases: 
-- #1 - open end time (i.e. NULL) at Scheduling Point station 
--   Before:
--      PU-1  |-------->
--   After:
--      PU-1  |-------->
--      PU-2       |--->
-- #2 - open end time (i.e. NULL) at station, NOT Scheduling Point unit
--   Before:
--      PU-1  |-------->
--      PU-2       |--->
--   1. same logic as #1
--   After:
--      PU-1  |------------>
--      PU-2       |-----|    
--      PU-3             |->
-- #3 - closed end time (i.e. NOT NULL) at station; order Status=Active - 
--      (use case: the operators took a break in processing this order - e.g. the weekend)
--   Before:
--      PU-1  |-------->
--      PU-2       |---|
--   1. IN CLIENT: if the end time is closed and Advance is clicked, 
--        ask if they want to open the closed one or create a new one. 
-- 	  	  	  	 if they want to open the existing one
-- 	  	  	  	  	 send update message on the existing one
--        else
--          send insert message using current server time as the start time
--   After:
--      PU-1  |------------------->
--      PU-2       |-------------->    
--   OR
--      PU-1  |------------------->
--      PU-2       |---|    
--      PU-3                    |->
-- #4 - Order Status=Complete then Status=Active - 
--      (use case: the operators took a break in processing this order - e.g. the weekend)
--   Before:
--      PU-1  |--------| <-set to complete
--      PU-2       |---| <-Note didn't go thru all stations!
--      PU-1                  |-------->
--   This should work, as we are getting the MAX(ST) for the PPId
--   After:
--      PU-1  |--------| 
--      PU-2       |---| 
--      PU-1                  |-------->
--      PU-2                           |->
If @@Trancount = 0
 	 Select @MyOwnTrans = 1
Else
  	  Select @MyOwnTrans = 0
--0 FOR this value means dont put the message record onto Pending_ResultSets
SET @InsertIntoPendingResultSet = Coalesce(@InsertIntoPendingResultSet,0);
/*
--turn on debug
Insert Into User_Parameters (Parm_Id, User_Id, Value, HostName) Values(100, 6, 1, '')
update User_Parameters set value = 0 where Parm_Id = 100 and User_Id = 6
*/
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100 
--select @DebugFlag = 1
If @DebugFlag = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdProdPlanStarts /PPStartId: ' + Coalesce(convert(nvarchar(10),@PPStartId),'Null') + ' /TransType: ' + Coalesce(convert(nVarChar(4),@TransType),'Null') + 
 	 ' /TransNum: ' + Coalesce(convert(nvarchar(10),@TransNum),'Null') + ' /PUId: ' + Coalesce(convert(nvarchar(10),@PUId),'Null') + 
  ' /StartTime: ' + Coalesce(convert(nVarChar(25),@StartTime),'Null') + ' /EndTime: ' + Coalesce(convert(nVarChar(25),@EndTime),'Null') +
  ' /PPId: ' + Coalesce(convert(nvarchar(10),@PPId),'Null') + ' /CommentId: ' + Coalesce(convert(nvarchar(10),@CommentId),'Null') + 
  ' /PPSetupId: ' + Coalesce(convert(nvarchar(10),@PPSetupId),'Null') + ' /UserId: ' + Coalesce(convert(nvarchar(10),@UserId),'Null'))
  End
Create Table #PPStartsResultSet(Result tinyint, PreDB tinyint, TransType int, TransNum int, PUId Int, PPStartId Int, 
 	 StartTime DateTime, EndTime DateTime, PPId Int, CommentId Int, PPSetupId Int, UserId Int)
  --
  -- Transaction Types
  -- 1 - Insert
  -- 2 - Update
  -- 3 - Delete
  --
  -- Transaction Numbers
  -- 00 - Coalesce
  -- 02 - No Coalesce
  -- 03 - Manual Order Flow - Close Previous
  -- 1000 Comment Update
 	 --
  -- Return Values:
  --
  --   (-100)  Error.  11/08/04 (BJO) - Errors will now be specific to error so we can pass this back to the calling SP.
  --   (   1)  Success: New record added.
  --   (   2)  Success: Existing record modified.
  --   (   3)  Success: Existing record deleted.
  --   (   4)  Success: No action taken.
  --
If (@TransNum is NULL)
  select @TransNum = 2
If (@TransNum =1010) -- Transaction From WebUI
 	 SELECT @TransNum = 2
If @TransNum Not In (0,2,3,1000)
  Begin
 	 Drop Table #PPStartsResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Invalid TransNum') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-2000)
  End
 	 IF @TransNum = 1000 /* Update Comment*/
 	 BEGIN
 	  	 IF @PPStartId is Null or @UserId Is Null -- Check required fields
 	  	  	 RETURN(4)
 	  	 SET @Check  = NULL
 	  	 SELECT  @Check = pp_setup_id FROM Production_Plan_Starts WHERE PP_Start_Id  = @PPStartId
 	  	 IF @Check is Null RETURN(4)-- Not Found
 	  	  	 UPDATE Production_Plan_Starts SET Comment_id = @CommentId,User_Id  = @UserId  
 	  	  	  	 WHERE PP_Start_Id  = @PPStartId
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
               IF(@PPStartId is not NULL)
                 BEGIN
 	  	  	  	 --Publish Message for Production Plan Start here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	  	 RSTId = 17
 	  	  	  	  	  	  	 ,PreDB = 0
 	  	  	  	  	  	  	 ,TransType = @TransType
 	  	  	  	  	  	  	 ,TransNum = @TransNum
 	  	  	  	  	  	  	 ,PUId = PU_Id
 	  	  	  	  	  	  	 ,PPStartId = PP_Start_Id
 	  	  	  	  	  	  	 ,StartTime = Start_Time
 	  	  	  	  	  	  	 ,EndTime = End_Time
 	  	  	  	  	  	  	 ,PPId = PP_Id
 	  	  	  	  	  	  	 ,CommentId = Comment_Id
 	  	  	  	  	  	  	 ,PPSetupId = pp_setup_id
 	  	  	  	  	  	  	 ,UserId = User_Id
 	  	  	  	  	  	 FROM Production_Plan_Starts WHERE PP_Start_Id  = @PPStartId
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
                                                 END
 	  	 RETURN(2)
 	 END
Select @Check = NULL
Select @Prod_Id = Null
If @PUId = 0
  Select @PUId = NULL
If @PPId = 0
  Select @PPId = NULL
If @PPSetupId = 0
  Select @PPSetupId = NULL
If @PPId is not null
 	 select @Prod_Id  = Prod_Id from Production_plan Where PP_Id = @PPId
Select @StartTime = dateadd(ms,-datepart(millisecond,@StartTime),@StartTime) --remove ms
Select @EndTime = dateadd(ms,-datepart(millisecond,@EndTime),@EndTime) --remove ms
Select @PathId = Path_Id From Production_Plan Where PP_Id = @PPId
/*
Possible values of @ScheduleControlType: 
Private Const ALL_UNITS_RUN_SAME_SCHEDULE_SIMULTANEOUSLY As Long = 0 meaning all have null end times and the same start time
Private Const SCHEDULE_FLOWS_BY_EVENT As Long = 1 meaning the start and end times come from the Production Event. 
Private Const SCHEDULE_FLOWS_INDEPENDENTLY As Long = 2 (aka Manual Order Flow) meaning the start & end times can be set independantly 
*/
SELECT @ScheduleControlType = Schedule_Control_Type
 	 FROM Prdexec_Paths
 	 WHERE Path_Id = @PathId
SELECT @IsSchedulePointUnit = PU_Id
 	 FROM PrdExec_Path_Units 
 	 WHERE Path_Id = @PathId and Is_Schedule_Point = 1
SELECT @IsProduction = Is_Production_Point 
 	 FROM PrdExec_Path_Units 
 	 WHERE Path_Id = @PathId and PU_Id = @PUId
SELECT @IsProduction = IsNull(@IsProduction,1)
Select @CurrentStartTime = Start_Time, @CurrentEndTime = End_Time
 	 From Production_Plan_Starts
 	 Where PP_Start_Id = @PPStartId
-- Inserts are always appends - we never insert between PPStarts records
If @TransType = 1
  Begin
    -- Begin a new transaction.
    --
 	  	 If @MyOwnTrans = 1 
 	  	  	 Begin
 	  	  	  	 BEGIN TRANSACTION
        SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
  	  	  	 End
 	  	 /* Check old start_time*/
 	  	 Select @OldPPSId = Null,@OldStartTime = Null,@OldEndTime = Null
 	  	 -- Close the Previous PPStart 	 
    if @ScheduleControlType = 2 --Flows Independantly (Manual Order Flow)
 	  	  	 begin
-- Logic Pseudocode for all use cases below:
--   1. Look for the MAX(start time) and if Scheduling Point unit for this pp_id, (do in this SP) 
--   2. If the MAX(start_time) record is NOT the Scheduling Point and its ET is NULL
-- 	  	  	  	 set ET of the MAX(start_time) record to the ST of the new record (capture in RS table)
-- 	  	  	 end if 
--   3. Insert new record set the ST to current server time, set ET to NULL (capture in RS table)
 	  	  	 Select @OldStartTime = NULL, @OldPPSId = NULL
 	  	  	 Select @OldStartTime=MAX(Start_Time) --@OldPPSId = PP_Start_Id,@OldStartTime = Start_Time 
 	  	       From Production_Plan_Starts 
 	  	       Where PP_Id = @PPId
 	  	  	 Select @OldPPSId = PP_Start_id, @OldEndTime = End_Time
 	  	       From Production_Plan_Starts 
 	  	       Where Start_Time = @OldStartTime  	 and PP_Id = @PPId  	 and PU_id != @IsSchedulePointUnit 
--TODO 	  	 : Raise error messages
 	  	  	  	 --make sure start time < end time 
 	  	  	  	 if ((@endtime IS NOT NULL) AND (@StartTime >= @EndTime))
 	  	  	  	  	 begin
 	  	  	  	  	  	 Drop Table #PPStartsResultSet
 	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'MOF Insert - new start time <= NEW END TIME')
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'MOF END')
 	  	  	  	  	  	 return (-2010)
 	  	  	  	  	 end
 	  	  	  	 --check the start time - make sure within boundaries of previous end time
 	  	  	  	 if (@StartTime < @OldStartTime) or (@OldEndTime IS NOT NULL and @StartTime < @OldEndTime) --Outside boundary of previous unit
 	  	  	  	  	 begin
 	  	  	  	  	  	 Drop Table #PPStartsResultSet
 	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'MOF Insert - new start time <=  previous start time or < non-null end_time')
 	  	  	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'MOF END')
 	  	  	  	  	  	 return (-2010)
 	  	  	  	  	 end
 	  	  	   if @OldPPSId IS NOT NULL And @OldEndTime is NULL -- its not the scheduling point unit AND it's end time is null, set the end time
 	  	  	  	  	 Begin
 	  	  	  	     Insert Into #PPStartsResultSet
 	  	  	  	       Select 17, 0, 2, 0, PU_Id, PP_Start_Id, Start_Time, @StartTime, PP_Id, Comment_Id, PP_Setup_Id, @UserId
 	  	  	  	         From Production_Plan_Starts
 	  	  	  	  	  	  	 Where PP_Start_Id = @OldPPSId
 	  	  	  	  	  	 Update Production_Plan_Starts
 	  	  	  	  	  	  	 Set End_Time = @StartTime
 	  	  	  	  	  	  	 Where PP_Start_Id = @OldPPSId
 	  	  	  	   End
 	  	  	 end --if @ScheduleControlType = 2
 	  	 else If @ScheduleControlType is not Null --Flows Simultaineously or Flows by Event
 	  	  	 BEGIN
 	  	  	  	 Select @OldPPSId = PP_Start_Id,@OldStartTime = Start_Time 
 	  	       From Production_Plan_Starts 
 	  	       Where End_Time is null and PU_Id = @PUId 
 	  	  	  	 If @OldPPSId is not null
 	  	  	  	  Begin
 	  	  	  	  	 If @StartTime > @OldStartTime
 	  	  	  	  	  	 Begin
 	  	  	  	  	     Insert Into #PPStartsResultSet
 	  	  	  	  	       Select 17, 0, 2, 0, PU_Id, PP_Start_Id, Start_Time, @StartTime, PP_Id, Comment_Id, PP_Setup_Id, @UserId
 	  	  	  	  	         From Production_Plan_Starts
 	  	  	  	  	  	  	  	 Where PP_Start_Id = @OldPPSId
 	 
 	  	  	  	  	  	  	 Update Production_Plan_Starts
 	  	  	  	  	  	  	  	 Set End_Time = @StartTime
 	  	  	  	  	  	  	  	 Where PP_Start_Id = @OldPPSId
 	  	  	  	  	  	 End
 	  	  	  	  	 Else
 	  	  	  	  	   Begin
 	  	  	  	  	  	  	 Drop Table #PPStartsResultSet
 	          	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	      	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert - new start time <=  previous start time')
 	          	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	        	  	  	 return (-2010)
 	  	  	  	  	   End
 	  	  	  	  End
 	  	  	  	 Else 
 	  	  	  	   Begin
 	  	  	  	  	 Select @OldEndTime = Max(End_Time) From Production_Plan_Starts where PU_Id = @PUId
 	  	  	  	  	 If @StartTime < @OldEndTime and @OldEndTime is not null
 	  	  	  	  	   Begin
 	  	  	  	  	  	  	 Drop Table #PPStartsResultSet
 	          	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	      	  	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert - new start time <  last end time')
 	          	  	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
 	        	  	  	 return (-2020)
 	  	  	  	  	   End
 	  	  	  	   End
 	  	  	 End --if @ScheduleControlType != 2
/* client will never send this - removed as part of 30286
 	  	 --Manual Order Flow Extended Edit = False (80% Use Case)
 	  	 If @TransNum = 3
 	  	  	 Update Production_Plan_Starts Set End_Time = @StartTime Where PP_Id = @PPId and PU_Id <> @IsSchedulePointUnit and End_Time is NULL
*/
/* ONLY ALLOW ONE Start per Production pu_Id*/
/* Marty/Wade - Allow multiple open PPStarts if the unit is not controled by PA (Not Schedule Controlled) */
IF @ScheduleControlType is not Null and @IsProduction = 1 and @EndTime Is NUll
BEGIN
 	 Insert Into #PPStartsResultSet
 	   Select 17, 0,  2, 0, PU_Id, PP_Start_Id, Start_Time, @StartTime, PP_Id, Comment_Id, PP_Setup_Id, @UserId
 	  	 From Production_Plan_Starts
 	  	 Where PU_Id = @PUId AND End_Time Is NULL and Is_Production = 1  AND PP_Id <> @PPId
 	 Update Production_Plan_Starts
 	  	 Set End_Time = @StartTime
 	  	 Where PU_Id = @PUId AND End_Time Is NULL and Is_Production = 1  AND PP_Id <> @PPId
END
    Insert Into Production_Plan_Starts (
      PU_Id,
      Start_Time,
      End_Time,
      PP_Id,
      Comment_Id,     
      pp_setup_id,
      User_Id,
 	   Is_Production)
    Values (
      @PUId,
      @StartTime,
      @EndTime,
      @PPId,
      @CommentId,     
      @PPSetupId,
      @UserId,
 	   @IsProduction)
 	    
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	  	 Drop Table #PPStartsResultSet
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
     	  	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert Failed')
         	 If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 return (-2030)
      End
    else 
      Begin
        If @MyOwnTrans = 1 COMMIT TRANSACTION
  	  	 Select @PPStartId = PP_Start_Id
 	  	  	 From Production_Plan_Starts
 	  	  	 Where PU_Id = @PUId AND Start_Time = @StartTime
 	  	    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ScheduleControlled:' + isnull(Convert(nvarchar(10),@ScheduleControlled),'Null') + ' /ProdId: ' +  isnull(Convert(nvarchar(10),@Prod_Id),'Null'))
 	  	  	   If @ScheduleControlled = 1 and @Prod_Id is Not Null
 	  	  	  	 Begin
 	  	  	  	  	 Select @CurrentId = Null,@Product_Code = Null,@ModifiedStart = Null,@ModifiedEnd = Null
 	  	  	  	  	 Execute @Rc = spServer_DBMgrUpdGrade2  @CurrentId  OUTPUT,  @PUId,@Prod_Id,0,@StartTime,2,@UserId,Null,Null,Null,@Product_Code OUTPUT,1, @ModifiedStart  OUTPUT, @ModifiedEnd   OUTPUT,Null
 	  	  	  	  	 If (@Rc = 1 or @Rc = 2) and @ModifiedStart is not null
 	  	  	  	  	  	 Select 3,@CurrentId,@PUId,@Prod_Id,@ModifiedStart,1,@UserId,Null,@Rc
 	  	  	  	 End
 	  	  	  	 Select Result,PreDB,TransType,TransNum,PUId,PPStartId,StartTime,EndTime,PPId,CommentId,PPSetupId,UserId
 	  	  	  	  From #PPStartsResultSet
 	  	  	  	   --Before dropping temp table and returning, publish production_plan_Start message
 	  	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  	  BEGIN
                   if EXISTS (select 1 from #PPStartsResultSet)
                    BEGIN
 	  	  	  	  	 --Publish Message for Production Plan Start here
 	  	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	  	 (
 	  	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	  	  	 ,PUId = PUId
 	  	  	  	  	  	  	  	 ,PPStartId = PPStartId
 	  	  	  	  	  	  	  	 ,StartTime = StartTime
 	  	  	  	  	  	  	  	 ,EndTime = EndTime
 	  	  	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	  	  	 ,PPSetupId = PPSetupId
 	  	  	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	  	  	 FROM #PPStartsResultSet
 	  	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  	  END
                    If(@PPStartId is not null) 
                        BEGIN
                           INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
                             SELECT 0,
                             (
                             SELECT  
                                 RSTId = 17
                                 ,PreDB = 0
                                 ,TransType = @TransType
                                 ,TransNum = @TransNum
                                 ,PUId = PU_Id
                                 ,PPStartId = PP_Start_Id
                                 ,StartTime = Start_Time
                                 ,EndTime = End_Time
                                 ,PPId = PP_Id
                                 ,CommentId = Comment_Id
                                 ,PPSetupId = pp_setup_id
                                 ,UserId = User_Id
                             FROM Production_Plan_Starts WHERE PP_Start_Id  = @PPStartId
                             FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
                             ,@UserId
                             ,dbo.fnServer_CmnGetDate(GETUTCDATE())
                        END
  	    	    	    	    	  
  	    	    	    	   END
 	  	  	  	 Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Insert Production Plan Start Successful')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 return (1)
      End
  End   
Else If @TransType = 2
  Begin
    -- Begin a new transaction.
    --
 	   Select @OldEndTime = End_Time From Production_Plan_Starts Where PP_Start_Id = @PPStartId
 	  	 If @ScheduleControlType = 2 --Schedule Flows Independently
 	  	  	 Begin
 	  	  	  	 If (Select Count(*) From Production_Plan_Starts Where PP_Id = @PPId and PU_Id = @PUId) > 1
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Select @PreviousEndTime = Max(End_Time)
 	  	  	  	  	  	  	 From Production_Plan_Starts
 	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	 And PU_Id = @PUId
 	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	  	 And End_Time <= @CurrentStartTime
 	  	  	  	  	  	 
 	  	  	  	  	  	 Select @NextStartTime = Min(Start_TIme)
 	  	  	  	  	  	  	 From Production_Plan_Starts
 	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	 And PU_Id = @PUId
 	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	  	 And Start_Time >= @CurrentEndTime
 	  	  	  	  	  	  	  	 
 	  	  	  	  	  	 If @StartTime <= @PreviousEndTime or @EndTime >= @NextStartTime
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 --PPStart Record Where Only StartTime Inside of Updated PPStart Time Range
 	  	  	  	  	  	     Insert Into #PPStartsResultSet
 	  	  	  	  	  	       Select 17, 0, 2, 0, PU_Id, PP_Start_Id, @EndTime, End_Time, PP_Id, Comment_Id, PP_Setup_Id, User_Id
 	  	  	  	  	  	         From Production_Plan_Starts
 	  	  	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	  	  	 And PU_Id = @PUId
 	  	  	  	  	  	  	  	  	 And Start_Time > @StartTime 
 	  	  	  	  	  	  	  	  	 And Start_Time <= @EndTime
 	  	  	  	  	  	  	  	  	 And (End_Time > @EndTime or End_Time is NULL)
 	  	  	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	  	  	 Update Production_Plan_Starts
 	  	  	  	  	  	  	  	  	 Set Start_Time = @EndTime
 	  	  	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	  	  	 And PU_Id = @PUId
 	  	  	  	  	  	  	  	  	 And Start_Time > @StartTime 
 	  	  	  	  	  	  	  	  	 And Start_Time <= @EndTime
 	  	  	  	  	  	  	  	  	 And (End_Time > @EndTime or End_Time is NULL)
 	  	  	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	  	  	 --PPStart Record Where Only EndTime Inside of Updated PPStart Time Range
 	  	  	  	  	  	     Insert Into #PPStartsResultSet
 	  	  	  	  	  	       Select 17, 0, 2, 0, PU_Id, PP_Start_Id, Start_Time, @StartTime, PP_Id, Comment_Id, PP_Setup_Id, User_Id
 	  	  	  	  	  	         From Production_Plan_Starts
 	  	  	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	  	  	 And PU_Id = @PUId
 	  	  	  	  	  	  	  	  	 And End_Time >= @StartTime 
 	  	  	  	  	  	  	  	  	 And Start_Time < @StartTime
 	  	  	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	  	  	 Update Production_Plan_Starts
 	  	  	  	  	  	  	  	  	 Set End_Time = @StartTime
 	  	  	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	  	  	 And PU_Id = @PUId
 	  	  	  	  	  	  	  	  	 And End_Time >= @StartTime 
 	  	  	  	  	  	  	  	  	 And Start_Time < @StartTime
 	  	  	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	     Insert Into #PPStartsResultSet
 	  	  	  	  	  	       Select 17, 0, 3, 0, PU_Id, PP_Start_Id, Start_Time, End_Time, PP_Id, Comment_Id, PP_Setup_Id, User_Id
 	  	  	  	  	  	         From Production_Plan_Starts
 	  	  	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	  	  	 And PU_Id = @PUId
 	  	  	  	  	  	  	  	  	 And Start_Time >= @StartTime 
 	  	  	  	  	  	  	  	  	 And (Start_Time < @EndTime or @EndTime is NULL)
 	  	  	  	  	  	  	  	  	 And End_Time > @StartTime 
 	  	  	  	  	  	  	  	  	 And (End_Time <= @EndTime or @EndTime is NULL)
 	  	  	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	  	  	 Delete From Production_Plan_Starts
 	  	  	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	  	  	 And PU_Id = @PUId
 	  	  	  	  	  	  	  	  	 And Start_Time >= @StartTime 
 	  	  	  	  	  	  	  	  	 And (Start_Time < @EndTime or @EndTime is NULL)
 	  	  	  	  	  	  	  	  	 And End_Time > @StartTime 
 	  	  	  	  	  	  	  	  	 And (End_Time <= @EndTime or @EndTime is NULL)
 	  	  	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
--  	  	  	  	  	  	  	  	 Delete From Production_Plan_Starts
--  	  	  	  	  	  	  	  	  	 Where PP_Id = @PPId
--  	  	  	  	  	  	  	  	  	 And PU_Id = @PUId
--  	  	  	  	  	  	  	  	  	 And ((Start_Time >= @StartTime and (Start_Time <= @EndTime or @EndTime is NULL))
--  	  	  	  	  	  	  	  	  	 Or (End_Time >= @StartTime and (End_Time <= @EndTime or @EndTime is NULL)))
--  	  	  	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	  	 End 	  	 
 	  	  	  	  	 End
 	  	  	 End
   	 If @TransNum = 0
   	   Begin
     	  	 Select @PUId = Coalesce(@PUId,PU_Id),
     	  	  	 @StartTime = Coalesce(@StartTime,Start_Time),
     	  	  	 @EndTime = Coalesce(@EndTime,End_Time),
          @PPId = Coalesce(@PPId,PP_Id),
     	  	  	 @CommentId = Coalesce(@CommentId,Comment_Id),
     	  	  	 @PPSetupId = Coalesce(@PPSetupId,PP_Setup_Id),
     	  	  	 @UserId = Coalesce(@UserId,User_Id)
     	  	  From Production_Plan_Starts
     	  	  Where (PP_Start_Id = @PPStartId)
   	   End
 	  	 If @MyOwnTrans = 1 
 	  	  	 Begin
 	  	  	  	 BEGIN TRANSACTION
        SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
  	  	  	 End
 	  	 
 	   If @OldEndTime is not null
   	   Begin
   	     If @EndTime is null
   	  	     Execute spServer_DBMgrCleanupProcessOrder @PPStartId,Null,1
   	     Else
     	  	  Execute spServer_DBMgrCleanupProcessOrder @PPStartId,@EndTime,1
   	   End
    Update Production_Plan_Starts 
      Set PU_Id = @PUId,
      Start_Time = @StartTime,
      End_Time = @EndTime,
      PP_Id = @PPId,
      Comment_Id = @CommentId, 
      PP_Setup_Id = @PPSetupId,
      User_Id = @UserId
    Where PP_Start_Id = @PPStartId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	 Drop Table #PPStartsResultSet
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        return (-2040)
      End
    else 
      Begin
        If @MyOwnTrans = 1 COMMIT TRANSACTION
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ScheduleControlled:' + isnull(Convert(nvarchar(10),@ScheduleControlled),'Null') + ' /ProdId: ' +  isnull(Convert(nvarchar(10),@Prod_Id),'Null'))
 	  	   If @ScheduleControlled = 1 and @Prod_Id is Not Null
 	  	  	 Begin
 	  	  	  	 Select @CurrentId = Null,@Product_Code = Null,@ModifiedStart = Null,@ModifiedEnd = Null
 	  	  	  	 Execute @Rc = spServer_DBMgrUpdGrade2  @CurrentId  OUTPUT,  @PUId,@Prod_Id,0,@StartTime,2,@UserId,Null,Null,Null,@Product_Code OUTPUT,1, @ModifiedStart  OUTPUT, @ModifiedEnd   OUTPUT,Null
 	  	  	  	 If (@Rc = 1 or @Rc = 2) and @ModifiedStart is not null
 	  	  	  	  	 Select 3,@CurrentId,@PUId,@Prod_Id,@ModifiedStart,1,@UserId,Null,@Rc
  	    	    	  End
 	  	  	  --Before dropping temp table and returning, publish production_plan_Start message
 	  	  	  IF (@InsertIntoPendingResultSet = 1)
 	  	  	  BEGIN
            if EXISTS (select 1 from #PPStartsResultSet)
                    BEGIN
 	  	  	  	 --Publish Message for Production Plan Start here
 	  	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	  	 SELECT 0,
 	  	  	  	  	  	 (
 	  	  	  	  	  	 SELECT  
 	  	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	  	 ,PUId = PUId
 	  	  	  	  	  	  	 ,PPStartId = PPStartId
 	  	  	  	  	  	  	 ,StartTime = StartTime
 	  	  	  	  	  	  	 ,EndTime = EndTime
 	  	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	  	 ,PPSetupId = PPSetupId
 	  	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	  	  	 FROM #PPStartsResultSet
 	  	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	  	 ,@UserId
 	  	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	  	  END
  	    	    	   END
 	  	  	 Drop Table #PPStartsResultSet
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Production Plan Start Successful')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
        	 return (2)
      End
  End
Else If @TransType = 3
  Begin
    -- Begin a new transaction.
    --
 	  	 If @MyOwnTrans = 1 
 	  	  	 Begin
 	  	  	  	 BEGIN TRANSACTION
        SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
  	  	  	 End
    --These qualifiers should be handled by the client code but double-check here
    Select @Check = Comment_Id From Production_Plan_Starts Where PP_Start_Id = @PPStartId
    If (@Check Is Not Null)
      Begin
        Update Comments 
          Set ShouldDelete = 1, 
              Comment = '',
              Comment_Text = ''
          Where Comment_Id = @Check
        if @@ERROR <> 0  
          Begin
            -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
 	  	  	 Drop Table #PPStartsResultSet
            If @MyOwnTrans = 1 ROLLBACK TRANSACTION
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Failed')
            If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
            return (-2050)
          End
      End
   	  Execute spServer_DBMgrCleanupProcessOrder @PPStartId,Null,1
 	 --before removing the record get the record
 	 Insert Into #PPStartsResultSet
  	    	 Select 17, 0, 3, 0, PU_Id, PP_Start_Id, Start_Time, End_Time, PP_Id, Comment_Id, PP_Setup_Id, User_Id
  	    	  From Production_Plan_Starts Where PP_Start_Id = @PPStartId
    Delete From Production_Plan_Starts Where PP_Start_Id = @PPStartId
    if @@ERROR <> 0  
      Begin
        -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Error deleting Setup')
 	  	 Drop Table #PPStartsResultSet
        If @MyOwnTrans = 1 ROLLBACK TRANSACTION
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Failed')
        If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
       	 return (-2060)
      End
    If @MyOwnTrans = 1 COMMIT TRANSACTION
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ScheduleControlled:' + isnull(Convert(nvarchar(10),@ScheduleControlled),'Null') + ' /ProdId: ' +  isnull(Convert(nvarchar(10),@Prod_Id),'Null'))
 	  If @ScheduleControlled = 1 and @Prod_Id is Not Null
 	  	 Begin
 	  	  	 Select @CurrentId = Null,@Product_Code = Null,@ModifiedStart = Null,@ModifiedEnd = Null
 	  	  	 Execute  @Rc = spServer_DBMgrUpdGrade2  @CurrentId  OUTPUT,  @PUId,@Prod_Id,0,@StartTime,2,@UserId,Null,Null,Null,@Product_Code OUTPUT,1, @ModifiedStart  OUTPUT, @ModifiedEnd   OUTPUT,Null
 	  	  	 If (@Rc = 1 or @Rc = 2) and @ModifiedStart is not null
 	  	  	  	 Select 3,@CurrentId,@PUId,@Prod_Id,@ModifiedStart,1,@UserId,Null,@Rc
  	    	  End
  	  --send the message before deleting the temp table
 	  If (SELECT count(*) FROM #PPStartsResultSet) > 0
 	  BEGIN
 	  	 IF (@InsertIntoPendingResultSet = 1)
 	  	 BEGIN
            if EXISTS (select 1 from #PPStartsResultSet)
                    BEGIN
 	  	  	 --Publish Message for Production Plan Start here, as this record has been deleted from this sproc only
 	  	  	 INSERT INTO Pending_ResultSets( Processed, RS_Value, User_Id, Entry_On )
 	  	  	  	  	 SELECT 0,
 	  	  	  	  	 (
 	  	  	  	  	 SELECT  
 	  	  	  	  	  	 RSTId = Result
 	  	  	  	  	  	 ,PreDB = PreDB
 	  	  	  	  	  	 ,TransType = TransType
 	  	  	  	  	  	 ,TransNum = TransNum
 	  	  	  	  	  	 ,PUId = PUId
 	  	  	  	  	  	 ,PPStartId = PPStartId
 	  	  	  	  	  	 ,StartTime = StartTime
 	  	  	  	  	  	 ,EndTime = EndTime
 	  	  	  	  	  	 ,PPId = PPId
 	  	  	  	  	  	 ,CommentId = CommentId
 	  	  	  	  	  	 ,PPSetupId = PPSetupId
 	  	  	  	  	  	 ,UserId = UserId
 	  	  	  	  	 FROM #PPStartsResultSet
 	  	  	  	  	 FOR XML PATH('row'), ROOT('rows') , ELEMENTS XSINIL)
 	  	  	  	  	 ,@UserId
 	  	  	  	  	 ,dbo.fnServer_CmnGetDate(GETUTCDATE())
 	  	 END
 	  END
  	   END
 	  	 Drop Table #PPStartsResultSet
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Delete Production Plan Start Successful')
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    return (3)
  End
--If we get to the bottom of this proc and the transaction is still open something bad happpened rollback the changes. 
If @@Trancount > 0 
  BEGIN
 	  	 Drop Table #PPStartsResultSet
    If @MyOwnTrans = 1 ROLLBACK TRANSACTION
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'TranCount > 0, Rolling Back.') 
    If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
    Return (-2070)
  END
Drop Table #PPStartsResultSet
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Return (4)') 
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'No Change')
If @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
Return (4)
