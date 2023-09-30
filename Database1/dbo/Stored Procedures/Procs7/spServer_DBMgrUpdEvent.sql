CREATE     PROCEDURE dbo.spServer_DBMgrUpdEvent
  @Event_Id         int OUTPUT,           
  @Event_Num        nVarChar(50) OUTPUT, 
  @PU_Id            int,                  
  @TimeStamp        Datetime,             
  @Applied_Product  int,                  
  @Source_Event     int,                  
  @Event_Status     int,              
  @Transaction_Type int,              
  @TransNum int, 	  	  	 
  @UserId int, 	  	  	  	 
  @CommentId int, 	  	  	 
  @EventSubtypeId int, 	  	  	 
  @TestingStatus int OUTPUT, 	  	  	 
  @StartTime Datetime, 	  	 
  @EntryOn Datetime OUTPUT, 	  	 
  @ReturnResultSet int 	 , 	  	 
  @Conformance int = NULL OUTPUT,
  @TestPctComplete int = NULL OUTPUT,
  @SecondUserId int = NULL, -- NewParam
  @ApproverUserId int = NULL, -- NewParam
  @ApproverReasonId int = NULL, -- NewParam
  @UserReasonId int = NULL, -- NewParam
  @UserSignoffId int = NULL, -- NewParam
  @Extended_Info nVarChar(255) = Null, -- Used in batch
  @SendEventPost int = NULL, -- Send Event Post between sending Test delete/update resultsets
  @SignatureId int = NULL, --New Param
  @LotIdentifier 	  	  	 nvarchar(100) = NULL,
  @FriendlyOperationName 	 nvarchar(100) = NULL
AS
SET NOCOUNT ON
Declare @DebugFlag Int,@ID Int
DECLARE @Now 	  	  	 DateTime,
 	  	 @MaxOffset 	  	 INT,
 	  	 @Changed 	  	 Bit
DECLARE @Locked TinyInt
SELECT @Event_Num = Ltrim(Rtrim(@Event_Num))
SELECT @MaxOffset =  CONVERT(INT, Value) From User_Parameters Where User_Id = 6 and Parm_Id = 85
SELECT @MaxOffset = coalesce(@MaxOffset,0)
Select @DebugFlag = CONVERT(tinyint, COALESCE(Value, '0')) From User_Parameters Where User_Id = 6 and Parm_Id = 100
--Select @DebugFlag = 1 
If @DebugFlag = 1 
BEGIN 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in DBMgrUpdEvent  /EventId: ' + Isnull(convert(nvarchar(10),@Event_Id),'Null') + 
 	 ' /EventNum: ' + Isnull(@Event_Num,'Null') +
   	 ' /PUId: ' + Isnull(convert(nvarchar(10),@PU_Id),'Null') + 
 	 ' /TimeStamp: ' + Isnull(convert(nVarChar(25),@TimeStamp,120),'Null') + 
 	 ' /AppliedProduct: ' + Isnull(convert(nvarchar(10),@Applied_Product),'Null') + 
 	 ' /SourceEvent: ' + Isnull(convert(nvarchar(10),@Source_Event),'Null') + 
 	 ' /EventStatus: ' + Isnull(convert(nvarchar(10),@Event_Status),'Null') +  
 	 ' /TransType: ' + Isnull(convert(nvarchar(10),@Transaction_Type),'Null') + 
 	 ' /TransNum: ' + Isnull(convert(nvarchar(10),@TransNum),'Null') + 
 	 ' /UserId: ' + Isnull(convert(nvarchar(10),@UserId),'Null') + 
 	 ' /CommentId: ' + Isnull(convert(nvarchar(10),@CommentId),'Null') + 
 	 ' /EventSubtypeId: ' + Isnull(convert(nvarchar(10),@EventSubtypeId),'Null') + 
 	 ' /TestingStatus: ' + Isnull(convert(nvarchar(10),@TestingStatus),'Null') +  
 	 ' /StartTime: ' + Isnull(convert(nVarChar(25),@StartTime,120),'Null') + 
 	 ' /EntryOn: ' + Isnull(convert(nVarChar(25),@EntryOn,120),'Null') +
 	 ' /ReturnResultSet: ' + Isnull(convert(nvarchar(10),@ReturnResultSet),'Null') + 
 	 ' /Conformance: ' + Isnull(convert(nvarchar(10),@Conformance),'Null') + 
 	 ' /TestPctComplete: ' + coalesce(convert(nvarchar(10),@TestPctComplete),'Null') + 
 	 ' /SecondUserId: ' + Isnull(convert(nvarchar(10),@SecondUserId),'Null') + 
 	 ' /ApproverUserId: ' + Isnull(convert(nvarchar(10),@ApproverUserId),'Null') + 
 	 ' /ApproverReasonId: ' + Isnull(convert(nvarchar(10),@ApproverReasonId),'Null') + 
 	 ' /UserReasonId: ' + Isnull(convert(nvarchar(10),@UserReasonId),'Null') + 
 	 ' /UserSignoffId ' + Isnull(convert(nvarchar(10),@UserSignoffId),'Null') + 
 	 ' /ExtendedInfo ' + Isnull(convert(nvarchar(10),@Extended_Info),'Null') + 
 	 ' /SendEventPost ' + Isnull(convert(nvarchar(10),@SendEventPost),'Null') + 
 	 ' /SignatureId: ' + Isnull(convert(nvarchar(10),@SignatureId),'Null'))
 END
  -- Transaction Type
  --   1 = Insert
  --   2 = Update
  --   3 = Delete
  --
 	 -- TransNum
 	 --   0 = Coalesce all input values with values from database before updating
 	 --   2 = Update database using only input values to this stored procedure
 	 --   3 = Only updating the TestPctComplete and Conformance columns
 	 -- 	  4 = Approve for ProfSDK
 	 -- 	  5 = UnApprove for ProfSDK
 	 --   6 = Append _YYMMDDhhmmss to duplicates MODEL 800
 	 --   7 = DO NOT Update to timestamp  MODEL 800
 	 --   8 = Only updating the Applied Product, Status and Comment - (added in 4.4.1 for Unisolar 6/2010) NO COALESCE! Send NULL, NULL goes in DB
 	 --   9 = Material Lot / sub lot Create and Links
 	 --  10 = Event Prod Unit Change
 	 -- 1000 = Update Comment
  -- Return Values:
  --
  --   (-100)  Error.
  --   (   1)  Success: New record added.
  --   (   2)  Success: Existing record modified.
  --   (   3)  Success: Existing record deleted.
  --   (   4)  Success: No action taken.
  --
  -- Declare local variables.
  --
  Select @SendEventPost = isnull(@SendEventPost, 0)
  DECLARE @Old_Event_Id      int,
 	  	  	 @Old_Event_Num     nVarChar(50),
 	  	  	 @Old_Timestamp     Datetime,
 	  	  	 @Check_Event_Id    int,
 	  	  	 @Check_Timestamp   Datetime,
 	  	  	 @Next_Timestamp    Datetime,
 	  	  	 @Window            Datetime,
 	  	  	 @T1                char(20),
 	  	  	 @T2                char(20),
 	  	  	 @T3                char(20),
 	  	  	 @Old_Start_Time    Datetime, 	  	 /* 3/29/01 -  MKW - Added variable to support new code. */
 	  	  	 @Next_Event_Id     int,              --* 3/21/02 -  JOE - Added variable to support new code. 
 	  	  	 @NextEventLocked    Tinyint,              --* 3/21/02 -  JOE - Added variable to support new code. 
 	  	  	 @Next_Start_Time   Datetime,         --* 6/04/02 -  JOE - Added variable to support new code. 
 	  	  	 @Prev_Start_Time   Datetime,         --* 6/04/02 -  JOE - Added variable to support new code. 
 	  	  	 @Prev_Timestamp    Datetime,         --* 6/04/02 -  JOE
 	  	  	 @Prev_Event_Id     int,              --* 6/04/02 -  JOE 
 	  	  	 @Old_Conformance   Int,
 	  	  	 @Old_TestPctComplete   Int, 
 	  	  	 @Old_AppliedProduct Int,
 	  	  	 @UsesStartTime      tinyint,
 	  	  	 @ChainStartTime     TinyInt, 	  	  	 -- Batch to stop chaining of events
 	  	  	 @Prod_Id           Int,
 	  	  	 @MyOwnTrans 	  	  	 Int,
 	  	  	 @XLock BIT, 
 	  	  	 @ClearAppliedProductIfSame int,
 	  	  	 @MaterialLotGuid 	 UniqueIdentifier,
 	  	  	 @ParentLotGuid 	  	 UniqueIdentifier,
 	  	  	 @CheckGuid 	  	  	 UniqueIdentifier,
 	  	  	 @SrcEventId 	  	  	 Int,
 	  	  	 @OldPUId 	  	  	 Int,
 	  	  	 @OldLocked 	  	  	 TinyInt,
 	  	  	 @IsLocked 	  	  	 TinyInt,
 	  	  	 @oldStatus 	  	  	 Int,
 	  	  	 @SkipMoves 	  	  	 TinyInt = 0
  --DECLARE @PreRelease Int
 -- SELECT @PreRelease = CONVERT(Int, COALESCE(Value, '0')) 
 	 --FROM Site_Parameters 
 	 --WHERE Parm_Id = 608
 -- SELECT @PreRelease = Coalesce(@PreRelease,0)
  If @@Trancount = 0
 	   Select @MyOwnTrans = 1
  Else
 	   Select @MyOwnTrans = 0
  Select @ReturnResultSet = isnull(@ReturnResultSet,1)
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  If @EntryOn is null Select @EntryOn = @Now
If (@TransNum =1010) -- Transaction From WebUI
  SELECT @TransNum = 2
  If @TransNum not in (0,2,3,4,5,6,7,8,9,10,1000)
  BEGIN
 	 If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Bad Trans Num')
    Return(4)
  END
IF @TransNum = 1000 /* Update Comment*/
 	 BEGIN
 	  	 IF @Event_Id is Null or @UserId Is Null -- Check required fields
 	  	  	 RETURN(4)
 	  	 SET @Old_Event_Id  = NULL
 	  	 SELECT  @Old_Event_Id = a.Event_Id,
 	  	  	  	 @OldLocked = Coalesce(b.LockData,0)
 	  	  	 FROM Events a
 	  	  	 JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status 
 	  	  	 WHERE Event_Id  = @Event_Id
 	  	 IF @Old_Event_Id is Null RETURN(4)-- Not Found
 	  	 IF @OldLocked = 1 
 	  	 BEGIN
 	  	  	 If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	  	  	 RETURN(-200)-- Record Locked
 	  	 END
 	  	 UPDATE Events SET Comment_id = @CommentId,User_Id  = @UserId,Entry_On = @EntryOn  
 	  	  	  	 WHERE Event_Id  = @Event_Id
 	  	 RETURN(2)
 	 END
-- Update conformance information only and return
 	 If @TransNum = 3
 	 BEGIN
 	  	 
 	  	 SELECT @Old_Event_Id = a.Event_Id,
 	  	  	  @Old_Conformance  = a.Conformance,
 	  	  	  @Old_TestPctComplete = a.Testing_Prct_Complete,
 	  	  	  @OldLocked = coalesce(b.LockData,0)
 	  	 FROM Events a
 	  	 JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status 
 	  	 WHERE Event_Id = @Event_Id
 	  	 IF @Old_Event_Id IS NULL
 	  	 BEGIN
 	  	  	 RAISERROR('Mandatory stored procedure argument %s is NULL or not found.', 11, -1, '@Event_Id')
 	  	  	 RETURN(-100)
 	  	 END
 	  	 IF @OldLocked = 1
 	  	 BEGIN
 	  	  	 If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	  	     Return (-200)
 	  	 END
 	  	 SELECT @Changed = 0
 	  	 IF @Old_Conformance Is Null and @Conformance is Not Null 
 	  	  	 SELECT @Changed = 1
 	  	 IF @Old_Conformance Is Not Null and @Conformance is Null
  	  	  	 SELECT @Changed = 1
 	  	 IF (@Old_Conformance Is Not Null and @Conformance is Not Null)
 	  	  	 IF @Old_Conformance != @Conformance
  	  	  	  	 SELECT @Changed = 1
 	  	 IF @Old_TestPctComplete Is Null and @TestPctComplete is Not Null 
 	  	  	 SELECT @Changed = 1
 	  	 IF @Old_TestPctComplete Is Not Null and @TestPctComplete is Null
  	  	  	 SELECT @Changed = 1
 	  	 IF (@Old_TestPctComplete Is Not Null and @TestPctComplete is Not Null)
 	  	  	 IF @Old_TestPctComplete != @TestPctComplete
  	  	  	  	 SELECT @Changed = 1
 	  	 IF @Changed = 1
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 
 	  	  	 BEGIN
 	  	  	  	 BEGIN TRANSACTION
 	  	  	  	 SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock() 
 	  	  	 END
 	  	  	 UPDATE Events
 	  	  	  	 SET Conformance           = @Conformance,
 	  	  	  	 Testing_Prct_Complete = @TestPctComplete
 	  	  	  	 WHERE Event_Id = @Event_Id
 	  	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
 	  	  	 Return (2)
 	  	 END
 	  	 ELSE
 	  	   BEGIN
 	  	     Return (4)
 	  	   END
 	 END
  -- Update Applied_Product, status and/or comment only and return. Ignore NULLs - consider them a COALESCE 
 	 If @TransNum = 8
 	 BEGIN
 	  	 SELECT @Old_Event_Id = a.Event_Id,
 	  	  	    @OldLocked = coalesce(b.LockData,0)
 	  	  	 FROM Events a
 	  	  	 JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status 
 	  	   WHERE Event_Id = @Event_Id
 	  	 IF @Old_Event_Id IS NULL
 	  	 BEGIN
 	  	  	 RAISERROR('Mandatory stored procedure argument %s is NULL or not found.', 11, -1, '@Event_Id')
 	  	  	 RETURN(-100)
 	  	 END
 	  	 IF @UserId IS NULL
 	  	 BEGIN
 	  	  	 RAISERROR('Mandatory stored procedure argument %s is NULL or not found.', 11, -1, '@User_Id')
 	  	  	 RETURN(-100)
 	  	 END
 	  	 IF ((@Event_Status in (1,2)) OR (@Event_Status IS NULL)) 
 	  	 BEGIN
 	  	  	 RAISERROR('Event_Status (%d) cannot be NULL, 1 or 2 with TransNum = 8.', 11, -1, @Event_Status)
 	  	  	 RETURN(-100)
 	  	 END
 	  	 IF @OldLocked = 1
 	  	 BEGIN
 	  	  	 RETURN(-200) -- Record Locked
 	  	 END
 	  	 --NOTE, TransNum 8 will be slightly faster if you set Site Parm 188 to 0 
 	  	 Select @ClearAppliedProductIfSame=CONVERT(INT,Value) from Site_Parameters WITH (NOLOCK) Where Parm_Id = 188
 	  	 If (Select ISNULL(@ClearAppliedProductIfSame, 1)) = 1 
 	  	 BEGIN
 	  	   SELECT @Prod_Id = Prod_Id From Production_Starts ps WITH (NOLOCK) 
 	  	  	   JOIN EVENTS e on e.event_Id = @Event_Id and 
 	  	  	  	   (ps.PU_Id = e.PU_Id) AND (ps.Start_Time <= e.TimeStamp) AND ((ps.End_Time > e.TimeStamp) OR (End_Time is NULL))
 	               
 	  	   IF @Prod_Id = @Applied_Product
 	  	  	 Select @Applied_Product = NULL
 	  	  END
 	  	 If @MyOwnTrans = 1 
 	  	 BEGIN
 	  	   BEGIN TRANSACTION
 	  	   SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock() 
 	  	 END
 	  	 UPDATE e 
 	  	   SET Applied_Product = @Applied_Product  
 	  	  	 , Comment_Id =      @CommentId 
 	  	  	 , Event_Status =    @Event_Status 
 	  	  	 , Entry_On =        @EntryOn
 	  	  	 , User_Id =         @UserId
 	  	   FROM Events e
 	  	   WHERE Event_Id = @Event_Id
 	  	 IF @SendEventPost = 1
 	  	 BEGIN
 	  	  	 if (@ReturnResultSet = 2)
 	  	  	 BEGIN
 	  	  	  	 --Send Post event resultset
 	  	  	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	  	  	 SELECT 0, (
 	  	  	  	   Select RSTId=1, NotUsed=0, TransType=1, Event_Id, Event_Num, PU_Id, Timestamp, Applied_Product, Source_Event,
 	  	  	  	  	  	  Event_Status, Confirmed=0, User_Id, PostDB=1, Conformance, Testing_Prct_Complete, Start_Time, TransNum=0, Testing_Status, 
 	  	  	  	  	  	    Comment_Id, Event_Subtype_Id, Entry_On, Approver_User_Id, Second_User_Id, Approver_Reason_Id,
 	  	  	  	  	  	  User_Reason_Id, User_Signoff_Id, Extended_Info,Signature_Id 
 	  	  	  	  	 From Events 
 	  	  	  	  	 Where Event_Id = @Event_Id
 	  	  	  	 for xml path ('row'), ROOT('rows')), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	  	  	 END
 	  	  	 ELSE if (@ReturnResultSet = 1)
 	  	  	 BEGIN
 	  	  	  	 --Send Post event resultset
 	  	  	   Select 1, 0, 1, Event_Id, Event_Num, PU_Id, Timestamp, Applied_Product, Source_Event,
 	  	  	  	  	  Event_Status, 0, User_Id, 1, Conformance, Testing_Prct_Complete, Start_Time, 0, Testing_Status, 
 	  	  	  	  	    Comment_Id, Event_Subtype_Id, Entry_On, Approver_User_Id, Second_User_Id, Approver_Reason_Id,
 	  	  	  	  	  User_Reason_Id, User_Signoff_Id, Extended_Info,Signature_Id 
 	  	  	  	 From Events 
 	  	  	  	 Where Event_Id = @Event_Id
 	  	  	 END
 	  	 END
 	  	 If @MyOwnTrans = 1 COMMIT TRANSACTION
 	  	 Return (2)
 	 END
 	 If @TransNum = 9
 	 BEGIN
 	  	 IF @UserId IS NULL
 	  	 BEGIN
 	  	  	 RAISERROR('Mandatory stored procedure argument %s is NULL or not found.', 11, -1, '@User_Id')
 	  	  	 RETURN(-100)
 	  	 END
 	  	 DECLARE @Start Int
 	  	 SET @Start = CHARINDEX('|',@Extended_Info)
 	  	 SET @Extended_Info = REPLACE(@Extended_Info,'{','')
 	  	 SET @Extended_Info = REPLACE(@Extended_Info,'}','')
 	  	 SET @Extended_Info = REPLACE(@Extended_Info,'|','')
 	  	 IF @Start > 0
 	  	 BEGIN
 	  	  	 IF LEN(@Extended_Info) != 72
 	  	  	 BEGIN
 	  	  	  	 RAISERROR('Extended Info (%d) not a guid with TransNum = 9.', 11, -1, @Extended_Info)
 	  	  	  	 RETURN(-100)
 	  	  	 END
 	  	  	 SELECT @ParentLotGuid = CONVERT(uniqueIdentifier,substring(@Extended_Info,37,36))
 	  	  	 SELECT @MaterialLotGuid = CONVERT(uniqueIdentifier,substring(@Extended_Info,1,36))
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 IF LEN(@Extended_Info) != 36
 	  	  	 BEGIN
 	  	  	  	 RAISERROR('Extended Info (%d) not a guid with TransNum = 9.', 11, -1, @Extended_Info)
 	  	  	  	 RETURN(-100)
 	  	  	 END
 	  	  	 SET @MaterialLotGuid = CONVERT(uniqueIdentifier,@Extended_Info)
 	  	 END
 	  	 SET @TransNum = 0
 	  	 SET @Extended_Info = null
   END
 	 
 	 SELECT @Event_Num = Upper(@Event_Num)
  -- Make sure mandatory arguments are not null.
  --
 	 IF @PU_Id IS NULL
 	 BEGIN
 	  	 RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@PU_Id')
 	  	 RETURN(-100)
 	 END
 	 IF @TimeStamp IS NULL
 	 BEGIN
 	   RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@TimeStamp')
 	   RETURN(-100)
 	 END
 	 IF @MaxOffset > 0
 	 BEGIN
 	   IF @TimeStamp  > DateAdd(Hour,@MaxOffset,@Now)
 	   BEGIN
 	  	  	 Declare @sTimestamp nVarChar(25)
 	  	  	 Select  @sTimestamp = convert(nVarChar(25),@TimeStamp,120)
 	  	  	 RAISERROR('Timestamp [%s] is to far in the future.', 11, -1,@sTimestamp )
 	  	  	 RETURN(-100)
 	   END
 	 END
 	 
 	 /* TimeStamp Check For Material Lots*/
 	 If @TransNum = 9
 	 BEGIN
 	  	 IF Not EXISTS(SELECT 1 FROM Events WHERE Event_Num = @Event_Num AND PU_Id = @PU_Id)
 	  	 BEGIN
 	  	  	 DECLARE @TempTs DateTime
 	  	  	 SELECT @TempTs = @TimeStamp 
 	  	  	 WHILE EXISTS(SELECT 1 FROM Events WHERE TimeStamp = @TempTs AND PU_Id = @PU_Id)
 	  	  	 BEGIN
 	  	  	  	 SELECT @TempTs = DATEADD(second,1,@TempTs)
 	  	  	 END
 	  	  	 SELECT @TimeStamp = @TempTs
 	  	 END
 	 END
 	 IF @StartTime Is Not NULL
 	 BEGIN
 	  	 -- Check for max timespan of 1 year
 	  	 IF DateDiff(day,@StartTime,@TimeStamp) > 365
 	  	  	 SELECT @StartTime = Null
 	 END
 	 IF @Transaction_Type IS NULL
 	 BEGIN
 	   RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@Transaction_Type')
 	   RETURN(-100)
 	 END
 	 IF ((@event_status is null) or (@event_status = 0)) and @Transaction_Type = 1
 	 Begin
 	  	 Select @event_status = Null
 	  	 Select @event_status = Min(Valid_Status) From prdexec_status Where Is_Default_Status = 1 and PU_Id = @PU_Id
 	  	 If @event_status is null
 	  	  	 select @event_status = 5
 	 End
 	 Select @UsesStartTime = COALESCE(Uses_Start_Time, 0),@ChainStartTime = Coalesce(Chain_Start_Time,1)
 	  	 From Prod_Units_Base 
 	  	 Where PU_Id = @PU_Id
 	 If @UsesStartTime = 0 
    BEGIN
      Select @StartTime = NULL 
    END
 	 IF @TransNum = 10
 	 BEGIN
 	  	 IF @Event_Id IS NULL
 	  	 BEGIN
 	  	  	 RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@Event_Id')
 	  	  	 RETURN(-100)
 	  	 END
 	 END
  --
  -- Make sure the transaction type is ok. Depending on the transaction type,
  -- other arguments may also become mandatory. Make sure these dependant
  -- mandatory arguments are not null.
  --
  -- DO NOT check for a null StartTime here because the timestamp may have changed
  -- in which case if the start time is null we need to adjust it later 
  IF @Transaction_Type = 2 OR @Transaction_Type = 3
    BEGIN
 	  	 IF @Event_Id IS NULL
 	  	 BEGIN
 	  	  	 -- Try to look up by event_Num
 	  	  	 SELECT @Event_Id = Event_Id From Events Where pu_Id = @PU_Id and Event_Num = @Event_Num
 	  	  	 IF @Event_Id IS NULL
 	  	  	 BEGIN
 	  	  	  	 RAISERROR('Mandatory stored procedure argument %s is NULL.', 11, -1, '@Event_Id')
 	  	  	  	 RETURN(-100)
 	  	  	 END
 	  	 END
    END
  ELSE IF @Transaction_Type <> 1
    BEGIN
      RAISERROR('Unknown transaction type detected:  %lu', 11, -1, @Transaction_Type)
      RETURN(-100)
    END
  --* 3/27/02-JOE - fetch start time from previous event if null sent
  -- IMPORTANT: Only do this for inserts, updates are done below
  ELSE  -- @Transaction_Type = 1 
    BEGIN
      If @UsesStartTime > 0 
        BEGIN
 	  	   IF @ChainStartTime > 0 -- added to force chaining
 	  	   BEGIN
 	  	  	 SELECT @StartTime = NULL
 	  	   END
          -- Start time can't be null
          If @StartTime is null 
            BEGIN
              Select @StartTime = COALESCE(MAX(TimeStamp), DATEADD(minute, -1, @Timestamp))
                FROM Events 
                WHERE Pu_Id = @PU_Id 
                  AND TimeStamp < @TimeStamp
            END
          -- Start time can't be greater than this events timestamp (except for trans num 7 this (they will get overridden
          Else if @StartTime > @Timestamp and @TransNum <> 7
            BEGIN
              RAISERROR('Start time > Timestamp. %s aborted, Identity = %lu.', 11, -1, 'Insert', 0)  
              RETURN(-100)
            END
        END
    END
  --
  -- Begin a new transaction.
  --
  If @MyOwnTrans = 1 
    BEGIN
      BEGIN TRANSACTION
      SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock() 
    END
  --
  -- Handle a delete transaction.
  --
  IF @Transaction_Type = 3 --DELETE
    BEGIN
      --
      -- Find the record. If it cannot be found, return success as it is
      -- already deleted. Otherwise make sure that its event number and
      -- timestamp match the request. If not, abort the delete.
      --
      SELECT @Old_Event_Id  = a.Event_Id,
             @Old_Event_Num = a.Event_Num,
             @Old_Timestamp = a.Timestamp,
             @OldLocked = Coalesce(b.LockData,0)
        FROM Events a
        JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status 
 	  	 WHERE Event_Id = @Event_Id
      IF @OldLocked = 1
        BEGIN
 	  	   If @MyOwnTrans = 1 ROLLBACK TRANSACTION
  	  	  	 If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
      	   RETURN(-200)
        END
 	 
      IF @Old_Event_Id IS NULL
        BEGIN
 	  	  	     If @MyOwnTrans = 1 ROLLBACK TRANSACTION
       	   RETURN(3)
        END
      ELSE IF (@Old_Timestamp <> @Timestamp)
 	 BEGIN
          SELECT @T1 = CONVERT(char(20), @TimeStamp, 113),
                 @T2 = CONVERT(char(20), @Old_TimeStamp , 113)
  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	 RAISERROR('Timestamp mismatch detected in delete request for table [Events] (Request/Database = %s/%s). Request aborted.', 11, -1, @T1, @T2)
          RETURN(-100)
        END
      ELSE IF (@Old_Event_Num <> @Event_Num)
 	 BEGIN
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
          RAISERROR('Event_Num mismatch detected in delete request for table [Events] (Request/Database = %s/%s). Request aborted.', 11, -1, @Event_Num, @Old_Event_Num)
          RETURN(-100)
        END
      --
      -- Delete the record.
      --
      Execute spServer_DBMgrDeleteEvent @Event_Id,@ReturnResultSet,@UserId
      If @MyOwnTrans = 1 COMMIT TRANSACTION
 	  	 --IF @PreRelease = 1
 	  	 --BEGIN
 	  	  	  	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	 Null,null,Null,2,@Event_Id,
 	  	  	  	  	  	  	  	  	  	 @TimeStamp, 	 Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	 3,0,@UserId, @PU_Id,Null,
 	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet,
 	  	  	  	  	  	  	  	  	  	 Null,Null
 	  	 --END
      RETURN(3)
    END
  --
  -- Check for an existing event with the same event number on the same
  -- production unit.
  --
  SELECT @Check_Event_Id = a.Event_Id, 
 	  	 @Check_TimeStamp = a.TimeStamp,
 	  	 @OldLocked = Coalesce(b.lockData,0) 
 	 FROM Events a
 	 JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status 
    WHERE (Event_Num = @Event_Num) AND (PU_Id = @PU_Id)
  --
  -- Handle an insert transaction.
  --
IF @Transaction_Type = 1 --ADD
BEGIN
 	 IF @UserId = 1 OR @UserId > 50
 	  	 SELECT @TestingStatus = coalesce(@TestingStatus,Value)
 	  	  	 FROM Site_Parameters WHERE Parm_Id = 96 and HostName = ''
 	 SET @TestingStatus =  coalesce(@TestingStatus,1)
      --
      -- If an insert is attempted for an existing event, abort the
      -- operation unless we have an exact match of event number,
      -- production unit, and timestamp. Then convert it to an update.
      --
 	  	 IF @Check_Event_Id Is Not Null AND @Check_TimeStamp <> @TimeStamp AND @TransNum = 6
 	  	   --Create New EventNum 
 	  	 BEGIN
 	  	  	 SELECT @Event_Num = RIGHT(@Event_Num,12) + '_' + RIGHT(CONVERT(nVarChar(4),datepart(Year,@TimeStamp)),2)
 	  	  	 IF LEN(datepart(Month,@TimeStamp)) = 1
 	  	  	  	 SELECT @Event_Num = @Event_Num + '0' + CONVERT(nVarChar(1),datepart(Month,@TimeStamp))
 	  	  	 ELSE
 	  	  	  	 SELECT @Event_Num = @Event_Num + CONVERT(nVarChar(2),datepart(Month,@TimeStamp))
 	  	  	 IF LEN(datepart(Day,@TimeStamp)) = 1
 	  	  	  	 SELECT @Event_Num = @Event_Num + '0' + CONVERT(nVarChar(1),datepart(Day,@TimeStamp))
 	  	  	 ELSE
 	  	  	  	 SELECT @Event_Num = @Event_Num + CONVERT(nVarChar(2),datepart(Day,@TimeStamp))
 	  	  	 IF LEN(datepart(Hour,@TimeStamp)) = 1
 	  	  	  	 SELECT @Event_Num = @Event_Num + '0' + CONVERT(nVarChar(1),datepart(Hour,@TimeStamp))
 	  	  	 ELSE
 	  	  	  	 SELECT @Event_Num = @Event_Num + CONVERT(nVarChar(2),datepart(Hour,@TimeStamp))
 	  	  	 IF LEN(datepart(Minute,@TimeStamp)) = 1
 	  	  	  	 SELECT @Event_Num = @Event_Num + '0' + CONVERT(nVarChar(1),datepart(Minute,@TimeStamp))
 	  	  	 ELSE
 	  	  	  	 SELECT @Event_Num = @Event_Num + CONVERT(nVarChar(2),datepart(Minute,@TimeStamp))
 	  	  	 IF LEN(datepart(Second,@TimeStamp)) = 1
 	  	  	  	 SELECT @Event_Num = @Event_Num + '0' + CONVERT(nVarChar(1),datepart(Second,@TimeStamp))
 	  	  	 ELSE
 	  	  	  	 SELECT @Event_Num = @Event_Num + CONVERT(nVarChar(2),datepart(Second,@TimeStamp))
 	  	  	 SELECT @Check_Event_Id = Null,@Check_TimeStamp = NULL
 	  	  	 SELECT @Check_Event_Id = Event_Id, @Check_TimeStamp = TimeStamp FROM Events
 	  	  	  	 WHERE (Event_Num = @Event_Num) AND (PU_Id = @PU_Id)
 	  	 END
 	 IF @Check_Event_Id IS NOT NULL
 	 BEGIN
 	  	 IF @Check_TimeStamp = @TimeStamp
 	  	 BEGIN
 	  	  	 SELECT @Event_Id = @Check_Event_Id
 	  	  	 GOTO DoModify
 	  	 END
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	 RAISERROR('Duplicate event number %s on production unit %lu detected in insert request for table [Events]. Insert request aborted.', 11, -1, @Event_Num, @PU_Id)
 	  	 RETURN(-100)
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @Check_Event_Id = Event_Id
 	  	  	 FROM Events
 	  	  	 WHERE (PU_Id = @PU_Id) AND (TimeStamp = @TimeStamp)
 	  	 SELECT @T1 = CONVERT(char(20), @TimeStamp, 113)
 	  	 IF @Check_Event_Id IS Not Null
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 RAISERROR('Event already exists at %s on production unit %lu  for table [Events]. Insert request aborted.', 11, -1, @T1, @PU_Id)
 	  	  	 RETURN(-100)
 	  	 END
 	 END
      --
      -- Insert the reel.
      --
      -- 3/27/02-JOE - insert start_time
      -- On a: 
      --  EVENT1 <INSERTEDEVENT> EVENT2
      --    if EVENT2.ST = EVENT1.TS: 
      --      Update EVENT2.ST 
      --      EVENT2.ST = <INSERTEDEVENT>.TS 
      --    else (if EVENT2.ST has been adjusted), leave EVENT2.ST as is.
      --
      IF (@UsesStartTime > 0) and (@ChainStartTime > 0)
        BEGIN 
          SELECT @Next_Timestamp = MIN(Timestamp) FROM Events WHERE Pu_Id = @PU_Id AND TimeStamp > @TimeStamp
          IF (@Next_Timestamp is not NULL)  -- NOT Appending
            BEGIN
              SELECT @Prev_Timestamp = MAX(Timestamp) FROM Events WHERE Pu_Id = @PU_Id AND TimeStamp < @Next_TimeStamp
              SELECT @Next_Event_Id = a.Event_Id,
 	  	  	  	  	 @NextEventLocked = coalesce(b.lockData,0) 
 	  	  	  	  	 FROM Events a
 	  	  	  	  	 JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status 
  	  	  	  	  	 WHERE Pu_Id = @PU_Id AND TimeStamp = @Next_TimeStamp
              SELECT @Next_Start_Time = Start_Time FROM Events WHERE Pu_Id = @PU_Id AND Event_Id = @Next_Event_Id
              IF (@Next_Start_Time = @Prev_Timestamp)
                BEGIN
 	  	  	  	  	 IF @NextEventLocked = 1
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	  	 RETURN(-200)
 	  	  	  	  	 END
 	  	  	  	  	 UPDATE Events Set Start_Time = @Timestamp, User_Id = @UserId WHERE Event_Id = @Next_Event_Id
                END
            END
        END
      INSERT INTO Events(Event_Num, PU_Id, Start_Time, TimeStamp, Applied_Product,
                         Source_Event, Event_Status, Entry_On, User_Id,Conformance,Testing_Prct_Complete,
                         Second_User_Id, Approver_User_Id, Approver_Reason_Id, User_Reason_Id, User_Signoff_Id,Extended_Info, Signature_Id,Comment_Id,Testing_Status,
 	  	  	  	  	  	  Lot_Identifier, Operation_Name )
        VALUES(@Event_Num, @PU_Id, @StartTime, @TimeStamp, @Applied_Product,
               @Source_Event, @Event_Status, @EntryOn, @UserId,@Conformance,@TestPctComplete,
               @SecondUserId, @ApproverUserId, @ApproverReasonId, @UserReasonId, @UserSignoffId,@Extended_Info,@SignatureId,@CommentId,@TestingStatus,
 	  	  	    @LotIdentifier, @FriendlyOperationName)
      -- SELECT @Event_Id = Scope_Identity()
      SELECT @Event_Id = Event_Id FROM Events 
        WHERE PU_Id = @PU_Id AND TimeStamp = @TimeStamp AND Event_Num = @Event_Num
      IF @Event_Id IS NULL
        BEGIN
           If @MyOwnTrans = 1 ROLLBACK TRANSACTION
         RAISERROR('Failed to determine new created identity in insert request for table %s. Request aborted.', 11, -1, 'Events')
          RETURN(-100)
        END
 	  	 IF @MaterialLotGuid Is Not Null
 	  	 BEGIN
 	  	  	 SELECT @CheckGuid = LotId FROM Events_Xref_Lots WHERE LotId = @MaterialLotGuid 
 	  	  	 IF @CheckGuid is NULL
 	  	  	  	 Insert INto Events_Xref_Lots(LotId,EventId) 
 	  	  	  	  	 SELECT @MaterialLotGuid,@Event_Id
 	  	  	 IF @ParentLotGuid Is not Null
 	  	  	 BEGIN
 	  	  	  	 SELECT @SrcEventId = EventId FROM Events_Xref_Lots WHERE LotId = @ParentLotGuid
 	  	  	  	 IF @SrcEventId Is Not Null
 	  	  	  	 BEGIN
 	  	  	  	  	 EXECUTE spServer_DBMgrUpdEventComp @UserId,@Event_Id ,Null,@SrcEventId,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,0,1,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 @TimeStamp,@TimeStamp,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 Null,Null,Null,1
 	  	  	  	 END
 	  	  	 END
 	  	 END
      If @MyOwnTrans = 1 COMMIT TRANSACTION
 	  	 IF @SendEventPost = 1
 	  	 BEGIN
 	  	  	 if (@ReturnResultSet = 2)
 	  	  	 BEGIN
 	  	  	  	 --Send Post event resultset
 	  	  	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	  	  	 SELECT 0, (
 	  	  	  	  	 Select RSTId=1, NotUsed=0, TransType=1, Event_Id, Event_Num, PU_Id, Timestamp, Applied_Product, Source_Event,
 	  	  	  	  	  	  	 Event_Status, Confirmed=0, User_Id, PostDB=1, Conformance, Testing_Prct_Complete, Start_Time, TransNum=0, Testing_Status, 
 	  	  	  	  	  	  	 Comment_Id, Event_Subtype_Id, Entry_On, Approver_User_Id, Second_User_Id, Approver_Reason_Id,
 	  	  	  	  	  	  	 User_Reason_Id, User_Signoff_Id, Extended_Info,Signature_Id
 	  	  	  	  	 From Events 
 	  	  	  	  	 Where Event_Id = @Event_Id
 	  	  	  	 for xml path ('row'), ROOT('rows')), @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	  	  	 END
 	  	  	 ELSE if (@ReturnResultSet = 1)
 	  	  	 BEGIN
 	  	  	  	 --Send Post event resultset
 	  	  	  	 Select 1, 0, 1, Event_Id, Event_Num, PU_Id, Timestamp, Applied_Product, Source_Event,
 	  	  	  	  	  	 Event_Status, 0, User_Id, 1, Conformance, Testing_Prct_Complete, Start_Time, 0, Testing_Status, 
 	  	  	  	  	  	  	  	  	 Comment_Id, Event_Subtype_Id, Entry_On, Approver_User_Id, Second_User_Id, Approver_Reason_Id,
 	  	  	  	  	  	 User_Reason_Id, User_Signoff_Id, Extended_Info,Signature_Id
 	  	  	  	 From Events 
 	  	  	  	 Where Event_Id = @Event_Id
 	  	  	 END
 	  	 END
 	  	 --IF @PreRelease = 1
 	  	 --BEGIN
 	  	  	  	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	 Null,null,Null,2,@Event_Id,
 	  	  	  	  	  	  	  	 @TimeStamp, 	 Null,Null,Null,Null,
 	  	  	  	  	  	  	  	 1,0,@UserId, @PU_Id,Null,
 	  	  	  	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	 Null,Null,Null,@ReturnResultSet,
 	  	  	  	  	  	  	  	 Null,Null
 	  	 --END
      RETURN(1)
END
  --
  -- Get The Existing Event Record
  --
DoModify:
/*
*  03/29/01 - MKW - Added @Old_Start_Time to the following SELECT
*/
 	 SELECT @Old_Event_Id = a.Event_Id,
 	  	  @Old_Event_Num = a.Event_Num,
 	  	  @Old_Timestamp = a.Timestamp,
 	  	  @Old_Start_Time    = a.Start_Time,
   	  	  @Old_Conformance  = a.Conformance,
   	  	  @Old_TestPctComplete = a.Testing_Prct_Complete,
   	  	  @OldPUId = a.PU_Id,
   	  	  @OldLocked = coalesce(b.LockData,0),
   	  	  @oldStatus = a.Event_Status,
 	  	  @Old_AppliedProduct = a.Applied_Product 
 	 FROM Events a
 	 JOIN Production_Status b on b.ProdStatus_Id = a.Event_Status
 	  WHERE Event_Id = @Event_Id
 	 IF @Old_Event_Id IS NULL
 	 BEGIN
 	   If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	   RAISERROR('Unable to find record in table %s in modify request, Identity = %lu. Request aborted.', 11, -1, 'Events', @Event_Id)
 	   RETURN(-100)
 	 END
 	 SET @IsLocked = @OldLocked
 	 IF @Event_Status Is not null
 	 BEGIN
 	  	 SELECT @IsLocked= ISNULL(LockData,0)
 	  	 FROM Production_Status a
 	  	 WHERE a.ProdStatus_Id = @Event_Status
 	 END
 	 If @DebugFlag = 1 
 	 BEGIN 
 	  	 Insert into Message_Log_Detail (Message_Log_Id, Message) 
 	  	  	 SELECT @ID, 'Old Lock:' + CONVERT(nvarchar(10),@OldLocked) + '  New Lock:' + CONVERT(nvarchar(10),@IsLocked)
 	 END
 	 IF @OldLocked = 1 and @IsLocked = 1 -- Allow Status change only
 	 BEGIN
 	   If @oldStatus = @Event_Status or @Event_Status is null
 	   BEGIN
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	 If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	  	 RETURN(-200) -- Record Locked
 	   END
 	   UPDATE Events SET Event_Status =  @Event_Status WHERE Event_Id = @Event_Id
 	   Set @SkipMoves = 1
 	   GOTO SENDPOST
 	 END
 	 IF @OldLocked = 1
 	 BEGIN
 	   If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	   If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	   RETURN(-200) -- Record Locked
 	 END
 	 
 	 
 	 IF @TransNum = 10 and  @OldPUId = @PU_Id
 	 BEGIN
 	  	 --RAISERROR('Call to change Location and Location did not change for event %s.', 11, -1, @Event_Id)
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	 --RETURN(-100)
 	  	 RETURN(2)
 	 END
 	 IF @TransNum = 10 and  (@TimeStamp <= @Old_TimeStamp)
 	 BEGIN
 	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	 RAISERROR('Call to change Location and EndTime did not change or was earlier for event %lu.', 11, -1, @Event_Id)
 	  	 RETURN(-100)
 	 END
 	 
 	 IF @TransNum = 7  --Do not change timestamp
 	 BEGIN
 	  	 SELECT @TimeStamp = @Old_Timestamp
 	  	 SELECT @StartTime = @Old_Start_Time
 	 END
 	 
  -- 
  -- Make sure we do not have another event with the same event number
  -- and a different identity.
  --
 	 IF (@Check_Event_Id <> @Event_Id) and (@Check_Event_Id IS NOT NULL)
 	 BEGIN
 	   If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	   RAISERROR('Event identity mismatch for event number %s on production unit %lu deteced in update request for table [Events] (Request/Database = %lu/%lu). Request aborted.', 11, -1, @Event_Num, @PU_Id, @Event_Id, @Old_Event_Id)
 	   RETURN(-100)
 	 END
 	 IF @TimeStamp <> @Old_TimeStamp
 	 BEGIN
 	 
 	 -- 
 	 -- Make sure we do not move the event beyond the window of its neighboring
 	 -- events.
 	 --
 	   /* 
 	   *  03/29/01 - MKW - Changed the following IF statement to include a check for a NULL Start_Time.  If the Start_Time
 	   *  isn't NULL then allow the Timestamp of the record to be changed, even if there are records following it.
 	   *      IF @TimeStamp > @Old_TimeStamp
 	   */
 	   IF @TimeStamp > @Old_TimeStamp And @Old_Start_Time Is Null
 	  	 SELECT @Window = MIN(TimeStamp) FROM Events
 	  	   WHERE (PU_Id = @PU_Id) AND
 	  	  	  	 (TimeStamp > @Old_TimeStamp) AND
 	  	  	  	 (TimeStamp <= @TimeStamp)
 	   ELSE IF @TimeStamp < @Old_TimeStamp
 	  	 SELECT @Window = MAX(TimeStamp) FROM Events
 	  	   WHERE (PU_Id = @PU_Id) AND
 	  	  	  	 (TimeStamp < @Old_TimeStamp) AND
 	  	  	  	 (TimeStamp >= @TimeStamp)
 	   /* 
 	   *  09/24/01 - JOE - Added Site_Parameter to allow movement outside of the current 
 	   *  events "window" (timestamps of preceeding and following events). Used first at Fraser Paper.
 	   */
 	   IF ((Select COALESCE(Value,0) From Site_Parameters Where Parm_Id = 142 and HostName = '') = 0)
 	  	 BEGIN
 	  	   IF @Window IS NOT NULL
 	  	  	 BEGIN
 	  	  	   SELECT @T1 = CONVERT(char(20), @TimeStamp, 113),
 	  	  	  	  	  @T2 = CONVERT(char(20), @Old_TimeStamp , 113),
 	  	  	  	  	  @T3 = CONVERT(char(20), @Window, 113)
 	  	  	   If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	   RAISERROR('Attempt to move event out of window of neighboring events in table [Events] (Request/Database/Window TimeStamp = %s/%s/%s). Modify request aborted.', 11, -1, @T1, @T2, @T3)
 	  	  	   RETURN(-100)
 	  	  	 END
 	  	 END
 	   --* 06/04/02 - JOE - adjust next start time if new timestamp > NEXT start time 
 	   -- TS moved (in window):  (NOTE: This is handled by "@StartTime is NULL" logic after "IF @TimeStamp <> @Old_TimeStamp" logic)
 	   --     EVENT1 EVENT2 <UPDATEDEVENT> EVENT3  --> EVENT1 EVENT2 <UPDATEDEVENT> EVENT3  
 	   -- ----------------------------------   
 	   --   if INPUTPARM.ST = NULL 
 	   --    	 expected result: <UPDATEDEVENT>.ST = <UPDATEDEVENT>.ST (i.e. leave it alone)
 	   --   else (INPUTPARM.ST <> NULL)
 	   --    	 expected result: <UPDATEDEVENT>.ST = INPUTPARM.ST 
 	   --
 	   -- TS moved (out of window):
 	   --     EVENT1 EVENT2 <UPDATEDEVENT> EVENT3 EVENT4 --> EVENT1 EVENT2 EVENT3 <UPDATEDEVENT> EVENT4
 	   --     Or                                         --> EVENT1 <UPDATEDEVENT> EVENT2 EVENT3 EVENT4
 	   --     Or                                         --> EVENT1 EVENT2 EVENT3 EVENT4 <UPDATEDEVENT>
 	   -- ---------------------------------- (test synopsis: if chained preserve chain)
 	   --   if INPUTPARM.ST <> NULL
 	   --    	 expected result: <UPDATEDEVENT>.ST = INPUTPARM.ST 
 	   --   else if INPUTPARM.ST = NULL 
 	   --     if (Prev_Timestamp = Old_Start_Time)
 	   --    	 expected result: INPUTPARM.ST = New Prev Timestamp
 	   --     else leave <UPDATEDEVENT>.ST alone
 	   --
 	   --   if there is a Next Event AND Next_Start_Time = Old_TimeStamp
 	   --    	 expected result:historize Next Event 
 	   --                        adjust Next Event.ST = PrevEvent.TS
 	   --   if NewNEXTEVENT.ST = Old_TimeStamp
 	   --    	 expected result:historize NewNEXTEVENT 
 	   --                        adjust NewNEXTEVENT.ST = NewPREVEVENT.TS
 	   -- 
 	  	 IF (@UsesStartTime > 0)  and (@ChainStartTime > 0)
 	  	 BEGIN
 	  	  	   SET @NextEventLocked = 0
 	  	  	   SELECT  @Next_Event_Id = a.Event_Id, 
 	  	  	  	  	   @Next_Timestamp = a.Timestamp, 
 	  	  	  	  	   @Next_Start_Time = a.Start_Time,
 	  	  	  	  	   @NextEventLocked = Coalesce(b.LockData,0)
 	  	  	  	 FROM Events a
 	  	  	  	 Join Production_Status b on b.ProdStatus_Id = a.Event_Status 
 	  	  	  	 WHERE Pu_Id = @PU_Id AND 
 	  	  	  	  	   TimeStamp = (SELECT MIN(Timestamp) FROM Events WHERE Pu_Id = @PU_Id AND TimeStamp > @Old_TimeStamp)
 	  	  	   -- From Window check logic above, 
 	  	  	   --  @Window is NULL = 
 	  	  	   --     EVENT1 EVENT2 <UPDATEDEVENT> EVENT3 EVENT4 --> EVENT1 <UPDATEDEVENT> EVENT2 EVENT3 EVENT4
 	  	  	   --  (@TimeStamp > @Next_Timestamp AND @Old_Start_Time Is NOT Null) =
 	  	  	   --     EVENT1 EVENT2 <UPDATEDEVENT> EVENT3 EVENT4 --> EVENT1 EVENT2 EVENT3 <UPDATEDEVENT> EVENT4
 	  	  	   --     Or                                         --> EVENT1 EVENT2 EVENT3 EVENT4 <UPDATEDEVENT>
 	  	  	   IF ((@Window is NOT NULL) OR (@TimeStamp > @Next_Timestamp AND @Old_Start_Time Is NOT Null))
 	  	  	  	 BEGIN
 	  	  	  	   SELECT @Prev_Event_Id = Event_Id, @Prev_Timestamp = Timestamp
 	  	  	  	  	 FROM Events 
 	  	  	  	  	 WHERE Pu_Id = @PU_Id AND 
 	  	  	  	  	  	   TimeStamp = (SELECT MAX(Timestamp) FROM Events WHERE Pu_Id = @PU_Id AND TimeStamp < @Old_TimeStamp)
 	  	  	  	   -- If no starttime sent in and existing record chained to previous, don't break the chain
 	  	  	  	   IF (@StartTime is NULL) AND (@Prev_Timestamp = @Old_Start_Time)
 	  	  	  	  	 BEGIN 
 	  	  	  	  	   SELECT @StartTime = Timestamp
 	  	  	  	  	  	 FROM Events 
 	  	  	  	  	  	 WHERE Event_Id = 
 	  	  	  	  	  	   (SELECT Event_Id
 	  	  	  	  	  	  	  FROM Events 
 	  	  	  	  	  	  	  WHERE Pu_Id = @PU_Id AND 
 	  	  	  	  	  	  	  	    TimeStamp = (SELECT MAX(Timestamp) FROM Events WHERE Pu_Id = @PU_Id AND TimeStamp < @TimeStamp))
 	  	  	  	  	 END
 	  	  	  	   -- Check start_time of record after record to be updated, 
 	  	  	  	   --    if same as timestamp of record to be updated, adjust it with prev timestamp  
 	  	  	  	   IF (@Next_Event_Id is not NULL) AND (@Next_Start_Time = @Old_TimeStamp) 
 	  	  	  	  	 BEGIN
 	  	  	  	  	   IF @NextEventLocked = 1
 	  	  	  	  	   BEGIN
 	  	  	  	  	  	   If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	  	   If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	  	  	  	  	  	   RETURN(-200) -- Record Locked
 	  	  	  	  	   END
 	  	  	  	  	   UPDATE Events Set Start_Time = @Prev_Timestamp, User_Id = @UserId WHERE Event_Id = @Next_Event_Id
 	  	  	  	  	 END
 	  	  	  	   -- Check start_time of record after new timestamp, 
 	  	  	  	   --    if = to record just before it, adjust it with timestamp  
 	  	  	  	   SET @NextEventLocked = 0
 	  	  	  	   SELECT @Next_Event_Id = a.Event_Id
 	  	  	  	  	  	 ,@Next_Start_Time = a.Start_Time
 	  	  	  	  	  	 ,@NextEventLocked = Coalesce(b.LockData,0)
 	  	  	  	  	 FROM Events a
 	  	  	  	  	 JOIN Production_Status b on a.Event_Status = b.ProdStatus_Id
 	  	  	  	  	 WHERE Pu_Id = @PU_Id AND 
 	  	  	  	  	  	   TimeStamp = (SELECT MIN(Timestamp) FROM Events WHERE Pu_Id = @PU_Id AND TimeStamp > @TimeStamp)
 	  	  	  	   SELECT @Prev_Event_Id = Event_Id, @Prev_Timestamp = Timestamp
 	  	  	  	  	 FROM Events 
 	  	  	  	  	 WHERE Pu_Id = @PU_Id AND 
 	  	  	  	  	  	   TimeStamp = (SELECT MAX(Timestamp) FROM Events WHERE Pu_Id = @PU_Id AND TimeStamp < @TimeStamp)
 	  	  	  	  	 IF (@Next_Event_Id is not NULL) AND (@Next_Start_Time = @Prev_Timestamp)
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 IF @NextEventLocked = 1
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	  	  	 If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	  	  	  	  	  	  	 RETURN(-200) -- Record Locked
 	  	  	  	  	  	 END
 	  	  	  	  	  	 UPDATE Events Set Start_Time = @Timestamp, User_Id = @UserId WHERE Event_Id = @Next_Event_Id
 	  	  	  	  	 END
 	  	  	  	 END  
 	  	  	   ELSE
 	  	  	  	 BEGIN
 	  	  	  	   -- Check start_time of record after record to be updated, 
 	  	  	  	   --    if same as timestamp of record to be updated, adjust it with prev timestamp  
 	  	  	  	   IF (@Next_Event_Id is not NULL) AND (@Next_Start_Time = @Old_TimeStamp)
 	  	  	  	  	 BEGIN
 	  	  	  	  	   IF @NextEventLocked = 1
 	  	  	  	  	   BEGIN
 	  	  	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	  	  	 If @DebugFlag = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END - Locked Record')
 	  	  	  	  	  	 RETURN(-200) -- Record Locked
 	  	  	  	  	   END
 	  	  	  	  	   UPDATE Events Set Start_Time = @Timestamp, User_Id = @UserId WHERE Event_Id = @Next_Event_Id
 	  	  	  	  	 END
 	  	  	  	 END  -- for "IF ((@Window is NOT NULL) OR (@TimeStamp > @Next_Timestamp AND @Old_Start_Time Is NOT Null))"
 	  	  	 END  -- for "IF (@UsesStartTime > 0)"
 	   --*
 	 END  -- for "IF @TimeStamp <> @Old_TimeStamp"
  --* 03/21/02 - JOE - Can't null out the start_time, if null is sent get from Events  
 	 If @UsesStartTime > 0 
 	 BEGIN
 	   --* 03/21/02 - JOE - Can't null out the start_time OR have start_time > timestamp 
 	  	 If @StartTime is null 
 	  	 BEGIN
 	  	   Select @StartTime = Start_Time
 	  	  	 FROM Events 
 	  	  	 WHERE Event_Id = @Event_Id 
 	  	 END
 	   --* 5/31/02 - JOE - if no start time on original record (still null), use timestamp of previous record.
 	   If @StartTime is null 
 	  	 BEGIN
 	  	   SELECT @StartTime = COALESCE(MAX(TimeStamp), DATEADD(minute, -1, @Timestamp)) 
 	  	  	 FROM Events 
 	  	  	 WHERE Pu_Id = @PU_Id AND TimeStamp < @TimeStamp
 	  	 END
 	   Else If @StartTime > @Timestamp 
 	  	 BEGIN
 	  	   If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	   RAISERROR('Start time > Timestamp. %s aborted, Identity = %lu.', 11, -1, 'Update', @Event_Id)  
 	  	   RETURN(-100)
 	  	 END
 	 END
  -- If new value is null use old value use 0 for null
  Select @Conformance = Coalesce(@Conformance,@Old_Conformance)
  Select @TestPctComplete = Coalesce(@TestPctComplete,@Old_TestPctComplete)
  --
  -- Update the event.
  --
 	 If @TransNum IN (0,4,5,7,10)
 	   Begin
   	  	 Select  @Event_Num = ISNULL(NULLIF(@Event_Num, ''),Event_Num),
 	  	  	 @StartTime = ISNULL(@StartTime,Start_Time),
 	  	  	 @EntryOn 	 = ISNULL(@EntryOn,Entry_On),
 	  	  	 @Applied_Product = ISNULL(@Applied_Product,Applied_Product),
 	  	  	 @Source_Event = ISNULL(@Source_Event,Source_Event),
 	  	  	 @Event_Status = ISNULL(@Event_Status,Event_Status),
 	  	  	 @UserId = ISNULL(@UserId,User_Id),
 	  	  	 @Conformance = ISNULL(@Conformance,Conformance),
 	  	  	 @TestPctComplete = ISNULL(@TestPctComplete,Testing_Prct_Complete),
 	  	  	 @SecondUserId = Case When @TransNum = 0 Then ISNULL(@SecondUserId,Second_User_Id) Else @SecondUserId End,
 	  	  	 @Extended_Info = ISNULL(@Extended_Info,Extended_Info),
 	  	  	 @ApproverUserId = Case When @TransNum <> 5 Then ISNULL(@ApproverUserId, Approver_User_Id) Else @ApproverUserId End,
 	  	  	 @ApproverReasonId = Case When @TransNum <> 5 Then ISNULL(@ApproverReasonId, Approver_Reason_Id) Else @ApproverReasonId End,
 	  	  	 @UserReasonId = Case When @TransNum <> 5 Then ISNULL(@UserReasonId, User_Reason_Id) Else @UserReasonId End,
 	  	  	 @UserSignoffId = Case When @TransNum <> 5 Then ISNULL(@UserSignoffId, User_Signoff_Id) Else @UserSignoffId End,
 	  	  	 @PU_Id = ISNULL(@PU_Id, PU_Id),
 	  	  	 @SignatureId = ISNULL(@SignatureId, Signature_Id),
 	  	  	 @CommentId = ISNULL(@CommentId, Comment_Id),
 	  	  	 @TestingStatus = ISNULL(@TestingStatus,Testing_Status),
 	  	  	 @LotIdentifier = ISNULL(@LotIdentifier,Lot_Identifier),
 	  	  	 @FriendlyOperationName = ISNULL(@FriendlyOperationName,Operation_Name)
   	  	  From Events
   	  	  Where (Event_Id = @Event_Id)
 	   End
  Select @ClearAppliedProductIfSame=CONVERT(INT,Value) from Site_Parameters Where Parm_Id = 188
  If (Select ISNULL(@ClearAppliedProductIfSame, 1)) = 1 
  BEGIN
    -- Null Applied Product if it matches the Production Starts product for this Timestamp
    SELECT @Prod_Id = Prod_Id From Production_Starts
 	     WHERE (PU_Id = @PU_Id) AND (Start_Time <= @TimeStamp) AND ((End_Time > @TimeStamp) OR (End_Time is NULL))
    IF @Prod_Id = @Applied_Product
          Select @Applied_Product = NULL
   END
 	 IF @TransNum = 10 -- Change Location
 	 BEGIN
 	  	 UPDATE Events
        SET Event_Num       = @Event_Num,
            TimeStamp       = @TimeStamp,
            Start_Time      = @StartTime,
            Entry_On        = @EntryOn,
            Applied_Product = @Applied_Product,
            Source_Event    = @Source_Event,
            Event_Status    = @Event_Status,
            User_Id         = @UserId,
            Conformance     = @Conformance,
            Testing_Prct_Complete = @TestPctComplete,
            Second_User_Id  = @SecondUserId,
            Approver_User_Id = @ApproverUserId,
            Approver_Reason_Id = @ApproverReasonId,
            User_Reason_Id = @UserReasonId,
            User_Signoff_Id = @UserSignoffId,
            Extended_Info   = @Extended_Info,
            Signature_Id    = @SignatureId,
            Comment_Id      = @CommentId,
            PU_Id = @PU_Id,
            Testing_Status = @TestingStatus,
 	  	  	 Lot_Identifier = @LotIdentifier,
 	  	  	 Operation_Name = @FriendlyOperationName
        WHERE Event_Id = @Event_Id
 	 END
 	 ELSE IF @TimeStamp <> @Old_TimeStamp
 	 BEGIN
 	  	 UPDATE Events
        SET Event_Num       = @Event_Num,
            TimeStamp       = @TimeStamp,
            Start_Time      = @StartTime,
            Entry_On        = @EntryOn,
            Applied_Product = @Applied_Product,
            Source_Event    = @Source_Event,
            Event_Status    = @Event_Status,
            User_Id         = @UserId,
            Conformance     = @Conformance,
            Testing_Prct_Complete = @TestPctComplete,
            Second_User_Id  = @SecondUserId,
            Approver_User_Id = @ApproverUserId,
            Approver_Reason_Id = @ApproverReasonId,
            User_Reason_Id = @UserReasonId,
            User_Signoff_Id = @UserSignoffId,
            Extended_Info   = @Extended_Info,
            Signature_Id    = @SignatureId,
            Comment_Id      = @CommentId,
            Testing_Status = @TestingStatus,
 	  	  	 Lot_Identifier = @LotIdentifier,
 	  	  	 Operation_Name = @FriendlyOperationName
        WHERE Event_Id = @Event_Id
 	   --
 	   -- If Status Is Unidentified Delete Data, Otherwise Move Event Data To New Time
 	   --
 	  	   IF @Event_Status in (1,2)
 	  	  	 Begin 
 	  	  	   EXECUTE spServer_DBMgrDeleteEventData @PU_Id,@Old_TimeStamp,1,@ReturnResultSet
 	  	  	 End
 	  	   ELSE
 	  	  	 Begin 
 	  	  	   EXECUTE spServer_DBMgrMoveEventData @PU_Id, @Old_TimeStamp,@TimeStamp, 1, @ReturnResultSet, Null, Null, @SendEventPost
 	  	  	 End
 	 END
 	 ELSE
 	 BEGIN
 	  	 UPDATE Events
        SET Event_Num       = @Event_Num,
            Start_Time      = @StartTime,
            Entry_On        = @EntryOn,
            Applied_Product = @Applied_Product,
            Source_Event    = @Source_Event,
            Event_Status    = @Event_Status,
            User_Id         = @UserId,  
            Conformance     = @Conformance,
            Testing_Prct_Complete = @TestPctComplete,
            Second_User_Id  = @SecondUserId,
            Approver_User_Id = @ApproverUserId,
            Approver_Reason_Id = @ApproverReasonId,
            User_Reason_Id = @UserReasonId,
            User_Signoff_Id = @UserSignoffId,
            Extended_Info   = @Extended_Info,
            Signature_Id    = @SignatureId,
            Comment_Id      = @CommentId,
            Testing_Status = @TestingStatus,
 	  	  	 Lot_Identifier = @LotIdentifier,
 	  	  	 Operation_Name = @FriendlyOperationName
        WHERE Event_Id = @Event_Id
 	  	  	 --
 	  	  	 --  If Status Is Being Changed To Unidentified, Timestamp Not Changed, Delete The Data
 	  	  	 --
 	  	  	 IF (@Event_Status in (1,2)) 
 	  	  	 Begin
 	  	  	  	  	 EXECUTE spServer_DBMgrDeleteEventData @PU_Id,@TimeStamp,1,@ReturnResultSet
 	  	  	 End
 	   	 END
SENDPOST:
IF @SendEventPost = 1
BEGIN
 	 if (@ReturnResultSet = 2)
 	 BEGIN
 	  	 --Send Post event resultset
 	  	 INSERT INTO Pending_ResultSets(Processed,RS_Value,User_Id,Entry_On)
 	  	 SELECT 0, (Select 	 RSTId = 1, NotUsed=0, @Transaction_Type, Event_Id, Event_Num, PU_Id, Timestamp, Applied_Product, Source_Event,
 	  	  	  	  	  	 Event_Status, Confirmed=0, User_Id, PostDB=1, Conformance, Testing_Prct_Complete, Start_Time, TransNum=0, Testing_Status, 
 	  	  	  	  	  	 Comment_Id, Event_Subtype_Id, Entry_On, Approver_User_Id, Second_User_Id, Approver_Reason_Id,
 	  	  	  	  	  	 User_Reason_Id, User_Signoff_Id, Extended_Info, Signature_Id
 	  	  	         From 	 Events 
 	  	  	  	  	 Where 	 Event_Id = @Event_Id for xml path ('row'), ROOT('rows')), 
 	  	  	    @UserId, dbo.fnServer_CmnGetDate(GetUtcDate())
 	 END
 	 ELSE if (@ReturnResultSet = 1)
 	 BEGIN
 	  	 --Send Post event resultset
 	  	 Select 	 1, 0, @Transaction_Type, Event_Id, Event_Num, PU_Id, Timestamp, Applied_Product, Source_Event,
 	  	  	  	 Event_Status, 0, User_Id, 1, Conformance, Testing_Prct_Complete, Start_Time, 0, Testing_Status, 
 	  	  	  	 Comment_Id, Event_Subtype_Id, Entry_On, Approver_User_Id, Second_User_Id, Approver_Reason_Id,
 	  	  	  	 User_Reason_Id, User_Signoff_Id, Extended_Info, Signature_Id
 	         From 	 Events 
 	  	  	 Where 	 Event_Id = @Event_Id
 	 END
END
IF @SkipMoves = 0 and @TransNum <> 10 and @TimeStamp <> @Old_TimeStamp
BEGIN
 	 --
 	 -- If Status Is Unidentified Delete Data, Otherwise Move Event Data To New Time
 	 --
 	 IF @Event_Status in (1,2)
 	 Begin 
 	  	 EXECUTE spServer_DBMgrDeleteEventData @PU_Id,@Old_TimeStamp,1,@ReturnResultSet
 	 End
 	 ELSE
 	 Begin
 	  	 EXECUTE spServer_DBMgrMoveEventData @PU_Id, @Old_TimeStamp,@TimeStamp, 1, @ReturnResultSet, Null, Null
 	 End
END
If @MyOwnTrans = 1 COMMIT TRANSACTION
IF @Old_TimeStamp <> @TimeStamp or @Old_Event_Num <> @Event_Num or ISNUll(@Old_AppliedProduct,-1) <> ISNUll(@Applied_Product,-1)
BEGIN -- An update to Desc or Endtime occured - Activity needs to be updated
 	 EXECUTE spServer_DBMgrUpdActivities  Null,Null,Null,Null,Null,
 	  	  	  	  	 Null,null,Null,2,@Event_Id,
 	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	 2,0,@UserId, @PU_Id,Null,
 	  	  	  	  	 Null,Null,Null,Null,Null,
 	  	  	  	  	 Null,Null,Null,@ReturnResultSet,
 	  	  	  	  	 Null,Null
END
If @DebugFlag = 1 
BEGIN 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END')
END
  IF @Transaction_Type = 2
    RETURN(2)
  ELSE
    RETURN(1)
