CREATE PROCEDURE dbo.spServer_DBMgrUpdUserEvent
 	 @TransNum  	  	  	 int,
 	 @EventSubTypeDesc  	  	 nVarChar(100),
 	 @ActionCommentId  	  	 int,
 	 @Action4  	  	  	  	 int,
 	 @Action3 	  	  	  	 int,
 	 @Action2 	  	  	  	 int,
 	 @Action1 	  	  	  	 int,
 	 @CauseCommentId 	  	 int,
 	 @Cause4 	  	  	  	 int,
 	 @Cause3 	  	  	  	 int,
 	 @Cause2 	  	  	  	 int,
 	 @Cause1 	  	  	  	 int,
 	 @AckBy 	  	  	  	 int,
 	 @Ack 	  	  	  	  	 int,
 	 @Duration 	  	  	  	 int,
 	 @EventSubTypeId 	  	 int,
 	 @PUId 	  	  	  	 int,
 	 @EventNum  	  	  	 nVarChar(1000),
 	 @UDE_Id  	  	  	  	 int 	  	 Output,
 	 @UserId  	  	  	  	 int,
 	 @AckOn  	  	  	  	 datetime,
 	 @StartTime 	   	  	 datetime,
 	 @EndTime  	  	  	  	 datetime,
 	 @ResearchCommentId 	  	 int,
 	 @ResearchStatusId  	  	 int,
 	 @ResearchUserId  	  	 int,
 	 @ResearchOpenDate  	  	 datetime,
 	 @ResearchCloseDate 	  	 datetime, 
 	 @TransType  	  	  	 int,
 	 @UDECommentId  	  	  	 int,
 	 @Event_Reason_Tree_Data_Id Int = Null, 	  	  -- User for categories
 	 @SignatureId                    int = Null,
 	 @EventId 	  	  	 Int = Null,
 	 @ParentUDEId 	  	 Int = Null,
 	 @Event_Status 	  	 Int = Null,
 	 @TestingStatus 	  	 Int = Null,
 	 @Conformance 	  	 TinyInt = Null OUTPUT,
 	 @TestPctComplete 	 TinyInt = Null OUTPUT, 
 	 @ReturnResultSet 	 int = 1, 	 -- 0 = Don't Return Result sets, caller will do it, 1 = Return Result Sets, 2 = Defer Result Sets to Pending Result Sets Table
 	 @FriendlyDesc 	  	 nvarchar(1000) = null
 AS
  --
  -- Return Values:
  --
  --   (-100) Error.
  --   (   1) Success: New record added.
  --   (   2) Success: Existing record modified.
  --   (   3) Success: Existing record deleted.
  --   (   4) Success: No action taken.
  --
  --
  -- Trans Type:
  --   GBTrans_Undefined = 0,
  --   GBTrans_Add =1  
  --   GBTrans_Upd=2
  --   GBTrans_Del=3
  --   GBTrans_Complete=4
  --   OpenClose=5
 -- Trans Nums
 	  	 -- 3 = Open  Current
 	  	 -- 4 = Close Current
 	  	 -- 5 = Create new  StartTime = EndTime
 	  	 -- 6 = Only updating the TestPctComplete and Conformance columns
 	  	 -- 1000 = UPDATE Cause comment
 	  	 -- 1001 = UPDATE Action comment
 	  	 -- 1002 = UPDATE Research comment
 	  	 -- 1003 = UPDATE UDE comment
Declare @XLock BIT, 
 	  	 @LastAck  	  	 bit,
 	  	 @TreeId  	  	 Int,
 	  	 @OldEndTime 	  	 DateTime,
 	  	 @OldStartTime 	 DateTime,
 	  	 @OldEventNum 	 nVarChar(1000),
 	  	 @DurationReq 	 Int,
 	  	 @MyOwnTrans 	  	 Int,
 	  	 @MaxEndTime 	  	 DateTime,
 	  	 @MaxUDEId 	  	 Int,
 	  	 @modifiedOn 	  	 DateTime,
 	  	 @OldUDEId 	  	  	  	 Int,
 	  	 @LastResearchStatus 	  	 Int,
 	  	 @LastOpenDate 	  	 DateTime,
 	  	 @OldEventStatus 	  	 Int,
 	  	 @DefEventStatus 	  	 Int
DECLARE @originalContextInfo VARBINARY(128)
DECLARE @ContextInfo varbinary(128)
Declare @OpenUde Table (Id Int Identity(1,1),UdeId Int)
Declare @Id 	  	  	 Int,
 	  	 @DebugFlag 	 Int,
 	  	 @NewLocked 	 Int,
 	  	 @OldLocked 	 Int,
 	  	 @AckReq 	  	 Int,
 	  	 @OldConformance Int,
 	  	 @OldTestPctComplete Int,
 	  	 @Changed Int
DECLARE /*@PreRelease Int,*/
 	  	 @OpenStart 	 Int,
 	  	 @OpenEnd 	 Int,
 	  	 @OpenUDEId 	 Int
--SELECT @PreRelease = CONVERT(Int, COALESCE(Value, '0')) 
-- 	 FROM Site_Parameters 
-- 	 WHERE Parm_Id = 608
--SELECT @PreRelease = Coalesce(@PreRelease,0) 	 
 	  
SELECT @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) 
 	 FROM User_Parameters 
 	 WHERE User_Id = 6 and Parm_Id = 100
SET @DebugFlag = 0
IF @DebugFlag = 1 
BEGIN 
 	 Insert into Message_Log_Header (Timestamp) SELECT dbo.fnServer_CmnGetDate(getUTCdate()) SELECT @ID = Scope_Identity() 
 	 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
 	 Insert into Message_Log_Detail (Message_Log_Id, Message)
 	   Values(@ID, 'in spServer_DBMgrUpdUserEvent /TransNum: ' + Coalesce(convert(nvarchar(10),@TransNum),'Null') + 
 	  	  	 ' /EventSubtypeId: ' + Coalesce(convert(nvarchar(10),@EventSubtypeId),'Null') + 
 	  	  	 ' /PUId: ' + Coalesce(convert(nvarchar(10),@PUId),'Null') +
 	  	  	 ' /UDE_Id: ' + Coalesce(convert(nvarchar(10),@UDE_Id),'Null') +
 	  	  	 ' /EventStatus: ' + Isnull(convert(nvarchar(10),@Event_Status),'Null') +  
 	  	  	 ' /TestingStatus: ' + Isnull(convert(nvarchar(10),@TestingStatus),'Null') +  
 	  	  	 ' /Conformance: ' + Isnull(convert(nvarchar(10),@Conformance),'Null') + 
 	  	  	 ' /TestPctComplete: ' + coalesce(convert(nvarchar(10),@TestPctComplete),'Null') + 
 	  	  	 ' /ST: ' + Isnull(convert(nVarChar(25),@StartTime,120),'Null') + 
 	  	  	 ' /ET: ' + Isnull(convert(nVarChar(25),@EndTime,120),'Null'))
END
SELECT @modifiedOn = dbo.fnServer_CmnGetDate(getUTCdate())
IF @@Trancount = 0
 	 SELECT @MyOwnTrans = 1
ELSE
 	 SELECT @MyOwnTrans = 0
IF @UDE_Id IS Not Null
BEGIN
 	 SET @NewLocked = 0
 	 SET @OldLocked = 0
 	 SELECT 	 @OldLocked = Coalesce(b.LockData,0),
 	  	  	 @Event_Status = Coalesce(@Event_Status,a.Event_Status)
 	   FROM User_Defined_Events a
 	   JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status
 	   WHERE a.UDE_Id = @UDE_Id
 	 SELECT @NewLocked = Coalesce(a.LockData,0)
 	  	 FROM Production_Status a
 	  	 WHERE a.ProdStatus_Id = @Event_Status
 	 IF @OldLocked = 1 and @NewLocked <> 1
 	 BEGIN
 	  	 RETURN(-200)
 	 END
 	 IF @OldLocked = 1 and @TransType  <> 2
 	 BEGIN
 	  	 RETURN(-200)
 	 END
END
SELECT @DurationReq = coalesce(Duration_Required,0),@AckReq = Coalesce(a.Ack_Required,0)
 	 FROM Event_Subtypes a
 	 WHERE Event_Subtype_Id = @EventSubTypeId
IF (@TransNum =1010) -- Transaction FROM WebUI
BEGIN
  SELECT @TransNum = 2
  IF @UDE_Id IS Not Null
  BEGIN
 	 SELECT 	 @LastAck = a.Ack,
 	  	  	 @LastResearchStatus = a.Research_Status_Id,
 	  	  	 @LastOpenDate = a.Research_Open_Date
 	   FROM User_Defined_Events a
 	   WHERE a.UDE_Id = @UDE_Id
 	 IF @LastAck <> @Ack
 	 BEGIN
 	  	 IF @Ack = 0
 	  	 BEGIN
 	  	  	 SET @AckBy = null
 	  	  	 SET @AckOn = Null
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 SET @AckBy = @UserId 
 	  	  	 SET @AckOn = @modifiedOn
 	  	 END
 	 END
  END
  ELSE
  BEGIN
 	 IF @Ack = 1
 	 BEGIN
 	  	 SET @AckBy = @UserId 
 	  	 SET @AckOn = @modifiedOn
 	 END
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
IF @TransNum  Not IN (0, 2,3,4,5,6,13,14,15,1000,1001,1002,1003)
BEGIN
  IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return(4)' )
 	 Return(4)
END
IF @TransNum in (1000,1001,1002,1003)/* UPDATE Comment*/
BEGIN
 	 IF @UDE_Id is Null or @UserId Is Null -- Check required fields
 	  	 RETURN(4)
 	 SET @OldUDEId  = NULL
 	 SELECT  @OldUDEId = UDE_Id FROM User_Defined_Events WHERE UDE_Id = @UDE_Id
 	 IF @OldUDEId is Null RETURN(4)-- Not Found
 	 IF @TransNum = 1000
 	  	 UPDATE User_Defined_Events SET Cause_Comment_Id  = @CauseCommentId ,User_Id  = @UserId,Modified_On = @modifiedOn  
 	  	  	  	 WHERE UDE_Id = @UDE_Id
 	 IF @TransNum = 1001
 	  	 UPDATE User_Defined_Events SET Action_Comment_Id = @ActionCommentId,User_Id  = @UserId,Modified_On = @modifiedOn   
 	  	  	  	 WHERE UDE_Id = @UDE_Id
 	 IF @TransNum = 1002
 	  	 UPDATE User_Defined_Events SET Research_Comment_Id = @ResearchCommentId,User_Id  = @UserId,Modified_On = @modifiedOn   
 	  	  	  	 WHERE UDE_Id = @UDE_Id
 	 IF @TransNum = 1003
 	  	 UPDATE User_Defined_Events SET Comment_Id = @UDECommentId,User_Id  = @UserId,Modified_On = @modifiedOn   
 	  	  	  	 WHERE UDE_Id = @UDE_Id
 	 RETURN(2)
END
-- Update conformance information only and return
If @TransNum = 6
BEGIN
 	 SELECT @OldUDEId = a.UDE_Id,
 	  	  @OldConformance  = a.Conformance,
 	  	  @OldTestPctComplete = a.Testing_Prct_Complete,
 	  	  @OldLocked = coalesce(b.LockData,0)
 	 FROM User_Defined_Events  a
 	 JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status 
 	 WHERE UDE_Id = @UDE_Id
 	 IF @OldUDEId IS NULL
 	 BEGIN
 	  	 RAISERROR('Mandatory stored procedure argument %s is NULL or not found.', 11, -1, '@UDE_Id')
 	  	 RETURN(-100)
 	 END
 	 IF @OldLocked = 1
 	 BEGIN
 	  	 If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	     Return (-200)
 	 END
 	 SELECT @Changed = 0
 	 IF @OldConformance Is Null and @Conformance is Not Null 
 	  	 SELECT @Changed = 1
 	 IF @OldConformance Is Not Null and @Conformance is Null
 	  	 SELECT @Changed = 1
 	 IF (@OldConformance Is Not Null and @Conformance is Not Null)
 	  	 IF @OldConformance != @Conformance
 	  	  	 SELECT @Changed = 1
 	 IF @OldTestPctComplete Is Null and @TestPctComplete is Not Null 
 	  	 SELECT @Changed = 1
 	 IF @OldTestPctComplete Is Not Null and @TestPctComplete is Null
 	  	 SELECT @Changed = 1
 	 IF (@OldTestPctComplete Is Not Null and @TestPctComplete is Not Null)
 	  	 IF @OldTestPctComplete != @TestPctComplete
 	  	  	 SELECT @Changed = 1
 	 IF @Changed = 1
 	 BEGIN
 	  	 If @MyOwnTrans = 1 
 	  	 BEGIN
 	  	  	 BEGIN TRANSACTION
 	  	 END
 	  	 UPDATE User_Defined_Events 
 	  	  	 SET Conformance           = @Conformance,
 	  	  	 Testing_Prct_Complete = @TestPctComplete
 	  	  	 WHERE UDE_Id = @UDE_Id
 	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
 	  	 Return (2)
 	 END
 	 ELSE
 	 BEGIN
 	  	 Return (4)
 	 END
END
IF @TransNum IN (3,13) --Open new Ude (Close all open First)
BEGIN
 	 SELECT @StartTime = Coalesce(@StartTime,@EndTime)
 	 SET @EndTime = Null
 	 --Has to be Current Record
 	 SELECT @MaxEndTime = Max(End_Time) FROM User_Defined_Events WHERE PU_Id = @PUId and Event_SubType_Id = @EventSubTypeId
 	 IF @MaxEndTime > @StartTime 
 	  	 RETURN (1)
 	 /* Close all open records */ 
 	 INSERT INTO @OpenUde(UdeId) 
 	  	 SELECT UDE_Id 
 	  	 FROM User_Defined_Events 
 	  	 WHERE PU_Id = @PUId And End_Time Is Null And Start_Time <= @StartTime and Event_SubType_Id = @EventSubTypeId
 	  	 UPDATE User_Defined_Events Set End_Time = @StartTime, 
 	  	  	  	  	  	  	  	  	 Modified_On = @modifiedOn 
 	  	  	 WHERE  UDE_ID IN (SELECT UdeId FROM @OpenUde)
 	  	 SELECT 8,0, UDE_Id, UDE_Desc, PU_Id,
 	  	  	     Event_SubType_Id, Start_Time, End_Time, Duration, Ack,
 	  	  	     Ack_On, Ack_By, Cause1, Cause2,Cause3,
 	  	  	     Cause4, Cause_Comment_Id,  Action1, Action2, Action3,
 	  	  	     Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,Research_Open_Date,
 	  	  	     Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,
 	  	  	     @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,Event_Status,
 	  	  	     Testing_Status,Conformance,Testing_Prct_Complete
 	  	  	 FROM User_Defined_Events
 	  	  	 WHERE UDE_Id  IN (SELECT UdeId FROM @OpenUde)
 	  	 IF /*@PreRelease = 1  and*/ Exists(SELECT 1 FROM @OpenUde)
 	  	 BEGIN
 	  	  	 SELECT @OpenStart = Min(Id),@OpenEnd = Max(Id) FROM @OpenUde
 	  	  	 WHILE @OpenStart <= @OpenEnd
 	  	  	 BEGIN
 	  	  	  	 SELECT @OpenUDEId = UdeId FROM @OpenUde Where Id = @OpenStart
 	  	  	  	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	 Null,null,Null,3,@OpenUDEId,
 	  	  	  	  	  	  	  	 @StartTime, 	 Null,Null,Null,Null,
 	  	  	  	  	  	  	  	 1,0,@UserId, @PUId,Null,
 	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet,@EventSubTypeId
 	  	  	  	 SET @OpenStart = @OpenStart + 1
 	  	  	 END
 	  	 END
 	 SELECT @TransType = 1
 	 SELECT @TransNum = 0
END 
IF @TransNum IN ( 4,14) --Close  UDE
BEGIN
 	 SELECT @EndTime = ISNULL(@EndTime, @StartTime)
 	 IF @MyOwnTrans = 1 
 	  	 BEGIN
 	  	  	 BEGIN TRANSACTION
 	  	  	 SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
 	  	 END
 	 INSERT INTO @OpenUde(UdeId) 
 	  	 SELECT UDE_Id 
 	  	 FROM User_Defined_Events 
 	  	 WHERE PU_Id = @PUId And End_Time Is Null And Start_Time <= @EndTime and Event_SubType_Id = @EventSubTypeId
 	 UPDATE User_Defined_Events Set End_Time = @EndTime, 
 	  	 Modified_On = @modifiedOn 
 	  	 WHERE  UDE_Id  IN (SELECT UdeId FROM @OpenUde)
 	 SELECT 8,0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
 	  	  	 Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
 	  	  	 Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,
 	  	  	 Event_Status,Testing_Status,Conformance,Testing_Prct_Complete
 	  	 FROM User_Defined_Events
 	  	 WHERE UDE_Id  IN (SELECT UdeId FROM @OpenUde)
    IF @MyOwnTrans = 1 Commit Transaction 
 	 IF /*@PreRelease = 1  and*/ Exists(SELECT 1 FROM @OpenUde)
 	 BEGIN
 	  	 SELECT @OpenStart = Min(Id),@OpenEnd = Max(Id) FROM @OpenUde
 	  	 WHILE @OpenStart <= @OpenEnd
 	  	 BEGIN
 	  	  	 SELECT @OpenUDEId = UdeId FROM @OpenUde Where Id = @OpenStart
 	  	  	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,null,Null,3,@OpenUDEId,
 	  	  	  	  	  	  	 @EndTime, 	 Null,Null,Null,Null,
 	  	  	  	  	  	  	 1,0,@UserId, @PUId,Null,
 	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet,@EventSubTypeId
 	  	  	 SET @OpenStart = @OpenStart + 1
 	  	 END
 	 END
 	 Return(1)
END 
IF @TransNum in (5,15) --INSERT OpenClose (current time only)
BEGIN
 	 SELECT @EndTime = Coalesce(@EndTime,@StartTime)
 	 SELECT @StartTime =  Dateadd(second,-1,@EndTime)
 	 SELECT @MaxEndTime = Max(End_Time) 
 	  	 FROM User_Defined_Events 
 	  	 WHERE PU_Id = @PUId and Event_SubType_Id = @EventSubTypeId
 	 IF @MaxEndTime is not null
 	 BEGIN
 	  	 IF @MaxEndTime > @StartTime
 	  	  	 RETURN (1)
 	  	 IF @TransNum = 15 and @MaxEndTime <> @StartTime --Chain
 	  	 BEGIN
 	  	  	 SELECT @StartTime = @MaxEndTime
 	  	 END
 	 END
 	 SELECT @TransType = 1
 	 SELECT @TransNum = 0
END 
IF @TransType = 1
BEGIN
 	 IF @UserId = 1 OR @UserId > 50
 	  	 SELECT @TestingStatus = coalesce(@TestingStatus,Value)
 	  	  	 FROM Site_Parameters WHERE Parm_Id = 96 and HostName = ''
 	 SET @TestingStatus =  coalesce(@TestingStatus,1)
  	 SELECT @DefEventStatus = Default_Event_Status
 	  FROM Event_Subtypes 
 	  WHERE Event_Subtype_Id = @EventSubTypeId
 	 SELECT @Event_Status = COALESCE(@Event_Status,@DefEventStatus)
  -- Look up @Event_Reason_Tree_Data_Id IF necessary
 	 IF @Event_Reason_Tree_Data_Id is null and @Cause1 is not null
 	 BEGIN
 	   SELECT @TreeId = Cause_Tree_Id FROM Event_Subtypes WHERE Event_Subtype_Id = @EventSubTypeId
   	   IF @Cause2 Is null
 	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   ELSE IF @Cause3 Is null
 	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   ELSE IF @Cause4 Is null
 	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   ELSE 
 	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id  = @Cause4 and Tree_Name_Id = @TreeId
 	 END
 	 IF @MyOwnTrans = 1 
 	 BEGIN
 	  	 BEGIN TRANSACTION
 	  	 SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
 	 END
 	 IF @DebugFlag = 1 
 	  	  	 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '\EndTime :' + Isnull(Convert(nVarChar(25),@EndTime,120),'Null') + 
 	  	  	  	 '\StartTime :' + Isnull(Convert(nVarChar(25),@StartTime,120),'Null') )
 	 IF @NewLocked = 1
 	 BEGIN
 	  	 IF @EndTime Is Null or (@Ack = 0 and @AckReq = 1 or @Ack is null)
 	  	 BEGIN
 	  	  	 SET @Event_Status = @DefEventStatus
 	  	 END
 	 END
     Insert Into User_Defined_Events 
 	  	  	  	 (UDE_Desc,PU_Id,Event_Subtype_Id,Start_Time,End_Time,
 	  	  	  	  	 Duration,Ack,Ack_On,Ack_By,Comment_Id,
 	  	  	  	  	 Cause1,Cause2,Cause3,Cause4,Cause_Comment_Id,
 	  	  	  	  	 Action1,Action2,Action3,Action4,Action_Comment_Id,
 	  	  	  	  	 Research_User_Id,Research_Status_Id,Research_Open_Date,Research_Close_Date,Research_Comment_Id,
 	  	  	  	  	 Event_Reason_Tree_Data_Id,Signature_Id,[User_Id],Modified_On,Event_Id,
 	  	  	  	  	 Parent_UDE_Id,Event_Status,Testing_Status, Friendly_Desc)
 	  	  	 Values(@EventNum ,@PUId ,@EventSubTypeId ,@StartTime ,@EndTime ,
 	  	  	  	  	  	  	 @Duration,@Ack,@AckOn,@AckBy,@UDECommentId,
 	  	  	  	  	  	  	 @Cause1,@Cause2,@Cause3,@Cause4,@CauseCommentId ,
 	  	  	  	  	  	  	 @Action1,@Action2,@Action3,@Action4,@ActionCommentId ,
 	  	  	  	  	  	  	 @ResearchUserId,@ResearchStatusId ,@ResearchOpenDate ,@ResearchCloseDate,@ResearchCommentId,
 	  	  	  	  	  	  	 @Event_Reason_Tree_Data_Id,@SignatureId,@UserId,@modifiedOn,@EventId,
 	  	  	  	  	  	  	 @ParentUDEId,@Event_Status,@TestingStatus,@FriendlyDesc)
    IF @@ERROR > 0 
     BEGIN
      IF @MyOwnTrans = 1 RollBack Transaction
 	  	  	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return(-100)' )
      RETURN(-100)
     END
     SELECT @UDE_Id = Scope_Identity() 
     IF @MyOwnTrans = 1 Commit Transaction
 	  
 	 if (@ReturnResultSet = 2)
 	 Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	  	 SELECT RSTId=8,PreDB=0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
 	  	  	  	  	  Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
 	  	  	  	  	  Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,
 	  	  	  	  	  Event_Status,Testing_Status,Conformance,Testing_Prct_Complete
 	  	  	   FROM 	 User_Defined_Events
 	  	  	   WHERE 	 UDE_Id = @UDE_Id
 	  	  	 for xml path ('row'), ROOT('rows')), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	 end
 	 else if (@ReturnResultSet = 1)
 	 Begin
 	  	 SELECT RSTId=8,PreDB=0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
 	  	  	  	  Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
 	  	  	  	  Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,
 	  	  	  	  Event_Status,Testing_Status,Conformance,Testing_Prct_Complete
 	  	   FROM 	 User_Defined_Events
 	  	   WHERE 	 UDE_Id = @UDE_Id
 	 end
 	   
 	 IF /*@PreRelease = 1 and*/ @EndTime Is Not Null
 	 BEGIN
 	  	  	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,null,Null,3,@UDE_Id,
 	  	  	  	  	  	  	 @EndTime, 	 Null,Null,Null,Null,
 	  	  	  	  	  	  	 1,0,@UserId, @PUId,Null,
 	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet,@EventSubTypeId
 	 END
 	  	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return(1)' )
    RETURN(1)
END
ELSE IF @TransType = 2
BEGIN
 	 If @MyOwnTrans = 1 BEGIN TRANSACTION
  -- If new value is null use old value use 0 for null
 	 SELECT @OldEndTime = End_Time,
 	  	  	 @OldStartTime = Start_Time,
   	  	  	 @OldConformance  = a.Conformance,
   	  	  	 @OldTestPctComplete = a.Testing_Prct_Complete,
 	  	  	 @EventSubTypeId = Event_Subtype_Id,
 	  	  	 @OldEventStatus = Event_Status,
 	  	  	 @OldEventNum = UDE_Desc
 	  	  FROM User_Defined_Events  a
 	  	  WHERE UDE_Id = @UDE_Id
 	 IF @OldLocked = 1 and @NewLocked = 1 -- Allow Status change only
 	 BEGIN
 	   If @OldEventStatus = @Event_Status or @Event_Status is null
 	   BEGIN
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	 If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	  	 RETURN(-200) -- Record Locked
 	   END
 	   UPDATE User_Defined_Events SET Event_Status =  @Event_Status WHERE UDE_Id  = @UDE_Id
 	   GOTO SENDPOST
 	 END
 	 IF @OldLocked = 1
 	 BEGIN
 	   If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	   If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	   RETURN(-200) -- Record Locked
 	 END
  	  If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ACK -' + CONVERT(nvarchar(10),@ack))
 	 IF @TransNum = 0
   	 BEGIN
 	  	 SELECT @EventNum = Coalesce(@EventNum,UDE_Desc),
 	  	  	 @StartTime = Coalesce(@StartTime,Start_Time),
 	  	  	 @EndTime = Coalesce(@EndTime,End_Time),
 	  	  	 @Duration 	 = Coalesce(@Duration,Duration),
 	  	  	 @Ack = Coalesce(@Ack,Ack),
 	  	  	 @AckOn = Coalesce(@AckOn,Ack_On),
 	  	  	 @AckBy = Coalesce(@AckBy,Ack_By),
 	  	  	 @Cause1 = Coalesce(@Cause1,Cause1),
 	  	  	 @Cause2 = Coalesce(@Cause2,Cause2),
 	  	  	 @Cause3 = Coalesce(@Cause3,Cause3),
 	  	  	 @Cause4 = Coalesce(@Cause4,Cause4),
 	  	  	 @Action1 = Coalesce(@Action1,Action1),
 	  	  	 @Action2 = Coalesce(@Action2,Action2),
 	  	  	 @Action3 = Coalesce(@Action3,Action3),
 	  	  	 @Action4 = Coalesce(@Action4,Action4),
 	  	  	 @ResearchUserId = Coalesce(@ResearchUserId,Research_User_Id),
 	  	  	 @ResearchStatusId = Coalesce(@ResearchStatusId,Research_Status_Id),
 	  	  	 @ResearchOpenDate = Coalesce(@ResearchOpenDate,Research_Open_Date),
 	  	  	 @ResearchCloseDate = Coalesce(@ResearchCloseDate,Research_Close_Date),
 	  	  	 @UserId = isnull(@UserId,[User_Id]),
 	  	  	 @SignatureId = Coalesce(@SignatureId,Signature_Id),
 	  	  	 @UDECommentId = ISNULL(@UDECommentId,Comment_Id),
 	  	  	 @EventId = Isnull(@EventId,Event_Id),
 	  	  	 @ParentUdEId = Isnull(@ParentUdEId,Parent_UDE_Id),
 	  	  	 @Event_Status = ISNULL(@Event_Status,Event_Status),
 	  	  	 @TestingStatus = ISNULL(@TestingStatus,Testing_Status),
 	  	  	 @FriendlyDesc = ISNULL(@FriendlyDesc,Friendly_Desc)
 	  	  FROM User_Defined_Events
 	  	  WHERE (UDE_Id = @UDE_Id)
   	   END
  	  If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ACK -' + CONVERT(nvarchar(10),@ack))
 	 IF @NewLocked = 1
 	 BEGIN
 	  	 IF (@EndTime Is Null and @TransNum != 0) 
 	  	 or (@EndTime Is Null and @OldEndTime is null) 
 	  	 or (@Ack = 0 and @AckReq = 1)
 	  	  	 SET @Event_Status = @OldEventStatus
 	 END
 	 SET @Event_Status = ISNULL(@Event_Status,@OldEventStatus)
  	 SELECT @Conformance = Coalesce(@Conformance,@OldConformance)
 	 SELECT @TestPctComplete = Coalesce(@TestPctComplete,@OldTestPctComplete)
  -- Look up @Event_Reason_Tree_Data_Id IF necessary
 	 IF @Event_Reason_Tree_Data_Id is null and @Cause1 is not null
 	 BEGIN
 	   SELECT @TreeId = Cause_Tree_Id FROM Event_Subtypes WHERE Event_Subtype_Id = @EventSubTypeId
   	   IF @Cause2 Is null
 	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   ELSE IF @Cause3 Is null
 	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   ELSE IF @Cause4 Is null
 	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   ELSE 
 	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id  = @Cause4 and Tree_Name_Id = @TreeId
 	 END
 	 IF @DebugFlag = 1 
 	  	  	 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '\OldEndTime :' + Isnull(Convert(nVarChar(25),@OldEndTime,120),'Null') +
 	  	  	  	 '\EndTime :' + Isnull(Convert(nVarChar(25),@EndTime,120),'Null') + '\OldStartTime :' + Isnull(Convert(nVarChar(25),@OldStartTime,120),'Null') +
 	  	  	  	 '\StartTime :' + Isnull(Convert(nVarChar(25),@StartTime,120),'Null') )
 	 IF @OldEndTime is not null and @EndTime is null  -- Event opened
   	  	 Execute spServer_DBMgrCleanupUserDefined  @UDE_Id,null,@ReturnResultSet,@EventSubTypeId,@OldEndTime,@PUId,@UserId
 	 ELSE IF (@OldEndTime is not null and @EndTime is Not null) and  (@OldEndTime <> @EndTime) -- Event Moved
   	  	 Execute spServer_DBMgrCleanupUserDefined @UDE_Id,@EndTime,@ReturnResultSet,@EventSubTypeId,@OldEndTime,@PUId,@UserId
    UPDATE User_Defined_Events 
     SET  UDE_Desc = @EventNum,
 	  	   Start_Time =@StartTime,
 	  	   End_Time =@EndTime,
 	  	   Duration =@Duration,
 	  	   Ack =@Ack,
 	  	   Ack_On =@AckOn,
 	  	   Ack_By =@AckBy,
 	  	   Cause1 =@Cause1,
 	  	   Cause2 =@Cause2,
 	  	   Cause3 =@Cause3,
 	  	   Cause4 =@Cause4,
 	  	   Action1 =@Action1,
 	  	   Action2 =@Action2 ,
 	  	   Action3 =@Action3 ,
 	  	   Action4 =@Action4 ,
 	  	   Research_User_Id =@ResearchUserId ,
 	  	   Research_Status_Id = @ResearchStatusId,
 	  	   Research_Open_Date = @ResearchOpenDate,
 	  	   Research_Close_Date =@ResearchCloseDate,
 	  	   Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id,
 	  	   Signature_Id = @SignatureId,
 	  	  [User_Id] = @UserId,
 	  	   Comment_Id = @UDECommentId,
 	  	  Modified_On = @modifiedOn,
 	  	  Event_Id = @EventId,
 	  	  Parent_UDE_Id = @ParentUDEId,
 	  	  Event_Status = @Event_Status,
 	  	  Testing_Status = @TestingStatus,
 	  	  Friendly_Desc = @FriendlyDesc
     WHERE UDE_Id = @UDE_Id
    IF @@ERROR > 0
 	  	  	 BEGIN
 	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return(-100)' )
 	  	  	  	 RETURN(-100)
 	  	  	 END
SENDPOST:
 	 If @MyOwnTrans = 1 COMMIT TRANSACTION
 	 if (@ReturnResultSet = 2)
 	 Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	  	 SELECT RSTId=8,PreDB=0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
 	  	  	  	  	  Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
 	  	  	  	  	  Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,
 	  	  	  	  	  Event_Status,Testing_Status,Conformance,Testing_Prct_Complete
 	  	  	   FROM User_Defined_Events
 	  	  	   WHERE UDE_Id = @UDE_Id
 	  	  	 for xml path ('row'), ROOT('rows')), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	 end
 	 else if (@ReturnResultSet = 1)
 	 Begin
 	  	 SELECT RSTId=8,PreDB=0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
 	  	  	  	  Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
 	  	  	  	  Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,
 	  	  	  	  Event_Status,Testing_Status,Conformance,Testing_Prct_Complete
 	  	   FROM User_Defined_Events
 	  	   WHERE UDE_Id = @UDE_Id
 	 end
 	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return(2)' )
 	 IF @OldEndTime is not null and @EndTime is null  -- Event opened
   	  	 Execute spServer_DBMgrCleanupUserDefined  @UDE_Id,null,@ReturnResultSet,@EventSubTypeId,@OldEndTime,@PUId,@UserId
 	 ELSE IF (@OldEndTime is not null and @EndTime is Not null) and  (@OldEndTime <> @EndTime) -- Event Moved
   	  	 Execute spServer_DBMgrCleanupUserDefined @UDE_Id,@EndTime,@ReturnResultSet,@EventSubTypeId,@OldEndTime,@PUId,@UserId
 	 --IF @PreRelease = 1
 	 --BEGIN
 	  	 IF @OldEndTime is not null and @EndTime is null 
 	  	 BEGIN -- Deleted
 	  	  	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,null,Null,3,@UDE_Id,
 	  	  	  	  	  	  	 @OldEndTime, 	 Null,Null,Null,Null,
 	  	  	  	  	  	  	 3,0,@UserId, @PUId,Null,
 	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet,@EventSubTypeId
 	  	 END
 	  	 ELSE IF @OldEndTime is null and @EndTime is Not null 
 	  	 BEGIN -- Added
 	  	  	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,null,Null,3,@UDE_Id,
 	  	  	  	  	  	  	 @EndTime, 	 Null,Null,Null,Null,
 	  	  	  	  	  	  	 1,0,@UserId, @PUId,Null,
 	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet,@EventSubTypeId
 	  	 END
 	  	 ELSE IF @OldEndTime is not null and @EndTime is Not null and (@OldEndTime <> @EndTime or @OldEventNum <> @EventNum)
 	  	 BEGIN -- An update to Desc or Endtime occured - Activity needs to be updated
 	  	  	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,null,Null,3,@UDE_Id,
 	  	  	  	  	  	  	 null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 2,0,@UserId, @PUId,Null,
 	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet,@EventSubTypeId
 	  	 END
 	 --END
    RETURN(2)
 END
ELSE IF @TransType = 3 -- Delete
BEGIN
 	 if (@ReturnResultSet = 2)
 	 Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	    SELECT RSTId=8,PreDB=0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
 	  	  	  	  	  Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
 	  	  	  	  	  Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,
 	  	  	  	  	  Event_Status,Testing_Status,Conformance,Testing_Prct_Complete
 	  	  	  FROM User_Defined_Events
 	  	  	   WHERE UDE_Id = @UDE_Id
 	  	  	 for xml path ('row'), ROOT('rows')), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	 end
 	 else if (@ReturnResultSet = 1)
 	 Begin
 	    SELECT RSTId=8,PreDB=0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
 	  	  	  	  Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
 	  	  	  	  Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,
 	  	  	  	  Event_Status,Testing_Status,Conformance,Testing_Prct_Complete
 	  	  FROM User_Defined_Events
 	  	   WHERE UDE_Id = @UDE_Id
 	 end
   	 SELECT @OldEndTime = End_Time,@EventSubTypeId = Event_Subtype_Id,@PUId = PU_Id 
   	  	 FROM User_Defined_Events WHERE UDE_Id = @UDE_Id
 	 Execute spServer_DBMgrCleanupUserDefined @UDE_Id,null,@ReturnResultSet,@EventSubTypeId,@OldEndTime,@PUId,@UserId
    UPDATE  User_Defined_Events Set Parent_Ude_Id = Null, Modified_On = @modifiedOn WHERE Parent_Ude_Id = @UDE_Id
 	 SET @originalContextInfo = Context_Info()
 	 SET @ContextInfo = CAST(@UserId AS varbinary(128))
 	 SET Context_Info @ContextInfo
    Delete User_Defined_Events WHERE UDE_ID = @UDE_Id
    IF @@ERROR > 0
 	  	  	 BEGIN
 	  	  	  	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return(-100)' )
 	  	  	  	 RETURN(-100)
 	  	  	 END
 	  	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return(3)' )
 	  	 IF @originalContextInfo Is NULL SET Context_Info 0x ELSE SET Context_Info @originalContextInfo
 	  	 --IF @PreRelease = 1
 	  	 --BEGIN
 	  	  	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,null,Null,3,@UDE_Id,
 	  	  	  	  	  	  	 @OldEndTime, 	 Null,Null,Null,Null,
 	  	  	  	  	  	  	 3,0,@UserId, @PUId,Null,
 	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet,@EventSubTypeId
 	  	 --END
    RETURN(3)
END
ELSE IF @TransType = 0
BEGIN
    SELECT @LastAck = Ack
      FROM User_Defined_Events
      WHERE UDE_Id = @UDE_Id
    IF @Ack <> @LastAck
      BEGIN 
        UPDATE User_Defined_Events 
          Set Ack = @Ack, 
              Ack_On = 
                CASE 
                  WHEN @Ack = 1 THEN dbo.fnServer_CmnGetDate(getUTCdate())
                  ELSE NULL
                END,
              Ack_By = 
                CASE 
                  WHEN @Ack = 1 THEN @UserId
                  ELSE NULL
                END, Modified_On = @modifiedOn
          WHERE UDE_ID = @UDE_Id
      END   
    IF @Cause1 IS NOT NULL 
      BEGIN 
 	   -- Look up @Event_Reason_Tree_Data_Id IF necessary
 	   IF @Event_Reason_Tree_Data_Id is null
 	  	 BEGIN
 	  	   SELECT @TreeId = Cause_Tree_Id FROM Event_Subtypes WHERE Event_Subtype_Id = @EventSubTypeId
 	    	   IF @Cause2 Is null
 	  	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   ELSE IF @Cause3 Is null
 	  	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   ELSE IF @Cause4 Is null
 	  	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   ELSE 
 	  	  	 SELECT @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) FROM Event_Reason_Tree_Data WHERE  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id  = @Cause4 and Tree_Name_Id = @TreeId
 	  	 END
        UPDATE User_Defined_Events 
          Set Cause1 = @Cause1, 
 	  	  	  	 Cause2 = @Cause2, 
 	  	  	  	 Cause3 = @Cause3, 
 	  	  	  	 Cause4 = @Cause4,
 	  	  	  	 Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id,
 	  	  	  	 Signature_Id = @SignatureId, 
 	  	  	  	 Modified_On = @modifiedOn
          WHERE UDE_ID = @UDE_Id
      END
    IF @Action1 IS NOT NULL 
      BEGIN 
        UPDATE User_Defined_Events 
          Set Action1 = @Action1, 
              Action2 = @Action2, 
              Action3 = @Action3, 
              Action4 = @Action4,
              Signature_Id = @SignatureId, 
 	  	  	  	 Modified_On = @modifiedOn
          WHERE UDE_ID = @UDE_Id
      END
    IF @ResearchStatusId IS NOT NULL or 
       @ResearchOpenDate IS NOT NULL or 
       @ResearchCloseDate IS NOT NULL 
      BEGIN 
        UPDATE User_Defined_Events 
          Set 
            Research_User_Id = @UserId,
            Research_Status_Id = @ResearchStatusId,
            Research_Open_Date = @ResearchOpenDate,
            Research_Close_Date = @ResearchCloseDate,
            Signature_Id = @SignatureId, 
 	  	  	 Modified_On = @modifiedOn
          WHERE UDE_ID = @UDE_Id
      END
 	 if (@ReturnResultSet = 2)
 	 Begin
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (
 	  	    SELECT RSTId=8,PreDB=0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
 	  	  	  	  	  Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
 	  	  	  	  	  Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,
 	  	  	  	  	  Event_Status,Testing_Status,Conformance,Testing_Prct_Complete
 	  	  	  FROM User_Defined_Events
 	  	  	   WHERE UDE_Id = @UDE_Id
 	  	  	 for xml path ('row'), ROOT('rows')), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	 end
 	 else if (@ReturnResultSet = 1)
 	 Begin
 	    SELECT RSTId=8,PreDB=0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
 	  	  	  	  Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
 	  	  	  	  Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId, @SignatureId,Event_Id,Parent_UDE_Id,
 	  	  	  	  Event_Status,Testing_Status,Conformance,Testing_Prct_Complete
 	  	  FROM User_Defined_Events
 	  	   WHERE UDE_Id = @UDE_Id
 	 end
 	  	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return(2)' )
    RETURN(2)
END
ELSE 
BEGIN
 	 IF @DebugFlag = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END: Return(4)' )
 	 RETURN(4)
END
