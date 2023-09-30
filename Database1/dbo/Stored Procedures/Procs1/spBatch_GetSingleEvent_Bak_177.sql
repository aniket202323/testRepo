CREATE 	 PROCEDURE dbo.[spBatch_GetSingleEvent_Bak_177]
 	 @EventTransactionId 	  	 Int,
 	 @EventId  	  	  	  	 int OUTPUT,
 	 @EventName  	  	  	 nvarchar(50),
 	 @EventUnitId 	  	  	 int,
 	 @NewStartTime 	  	  	 datetime,
 	 @NewEndTime 	  	  	 datetime, 	  	  	  	 
 	 @NewProductId  	  	  	 int,
 	 @ChangeProductFlag 	  	 int,
 	 @NewStatusId  	  	  	 int,
 	 @ChangeStatusFlag 	  	 int,
 	 @ParentEventId 	  	  	 int,
 	 @ExtendedInfo  	  	  	 nvarchar(255),
 	 @CurrentFilter 	  	  	 nvarchar(100),
 	 @UserId 	  	  	  	 int,
 	 @SecondUserId 	  	  	 Int,
 	 @HaveUnitProcedure 	  	 Int,
 	 @MoveEndTime 	  	 Int,
 	 @Debug 	  	  	  	  	 int = NULL,
 	 @ProcessOrderId 	  	  	 int = NULL,
 	 @InitialDimensionX 	  	 float = NULL,
 	 @InitialDimensionY 	  	 float = NULL,
 	 @InitialDimensionZ 	  	 float = NULL,
 	 @InitialDimensionA 	  	 float = NULL,
 	 @FinalDimensionX 	  	 float = NULL,
 	 @FinalDimensionY 	  	 float = NULL,
 	 @FinalDimensionZ 	  	 float = NULL,
 	 @FinalDimensionA 	  	 float = NULL,
 	 @LotIdentifier 	  	  	 nVarChar(100) = NULL,
 	 @FriendlyOperationName 	 nVarChar(100) = NULL
AS
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
SET 	 @NewStartTime 	 = DATEADD(MS, -DATEPART(MS, @NewStartTime), @NewStartTime)
SET 	 @NewEndTime 	  	 = DATEADD(MS, -DATEPART(MS, @NewEndTime), @NewEndTime)
DECLARE 	 
 	 @CurrentId  	  	  	  	  	  	  	  	 Int,
 	 @TestProduct 	  	  	  	  	     int
Declare
 	 @OldStartTime 	  	 DateTime,
 	 @OldEndTime 	  	 DateTime,
 	 @OldProductId 	  	 int,
 	 @OldStatusId 	  	 int,
 	 @TransType 	  	 Int,
 	 @ExistingETime 	  	 DateTime,
 	 @ActualEndTime 	  	 DateTime,
 	 @EventSubTypeId 	  	 Int,
 	 @ECId 	  	  	  	 Int
Declare 
 	 @Error 	  	  	 nvarchar(255),
  @Rc  	  	  	  	  	  	  	  	  	  	  	  	 int
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
SELECT 	 @Error = ''
SELECT 	 @Rc = 0
Declare @ID Int
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START (spBatch_GetSingleEvent)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_GetSingleEvent /EventTransactionId: ' + Coalesce(convert(nvarchar(10),@EventTransactionId),'Null') + ' /EventId: ' + Coalesce(convert(nvarchar(10),@EventId),'Null') + 
            ' /POId: ' + isnull(convert(nvarchar(10),@ProcessOrderId),'Null') + ' /IDimX: ' + isnull(convert(nvarchar(10),@InitialDimensionX),'Null') + 
 	  	  	 ' /IDimY: ' + isnull(convert(nvarchar(10),@InitialDimensionY),'Null') + ' /IDimZ: ' + isnull(convert(nvarchar(10),@InitialDimensionZ),'Null') + 
 	  	  	 ' /IDimA: ' + isnull(convert(nvarchar(10),@InitialDimensionA),'Null') + ' /FDimX: ' + isnull(convert(nvarchar(10),@FinalDimensionX),'Null') + 
 	  	  	 ' /FDimY: ' + isnull(convert(nvarchar(10),@FinalDimensionY),'Null') + ' /FDimZ: ' + isnull(convert(nvarchar(10),@FinalDimensionZ),'Null') + 
 	  	  	 ' /FDimA: ' + isnull(convert(nvarchar(10),@FinalDimensionA),'Null') + ' /LotId: ' + isnull(@LotIdentifier,'Null') + 
 	  	  	 ' /FOpName: ' + isnull(@FriendlyOperationName,'Null') + ' /EventName: ' + isnull(@EventName,'Null') + ' /EventUnitId: ' + isnull(convert(nvarchar(10),@EventUnitId),'Null') + 
 	  	  	 ' /EventName: ' + isnull(@EventName,'Null') + ' /EventUnitId: ' + isnull(convert(nvarchar(10),@EventUnitId),'Null') + 
 	  	  	 ' /NewStartTime: ' + isnull(convert(nvarchar(25),@NewStartTime,120),'Null') + ' /NewEndTime: ' + isnull(convert(nvarchar(25),@NewEndTime,120),'Null') + 
 	  	  	 ' /NewProductId: ' + isnull(convert(nvarchar(10),@NewProductId),'Null') + ' /ChangeProductFlag: ' + isnull(convert(nVarchar(4),@ChangeProductFlag),'Null') + 
 	  	  	 ' /NewStatusId: ' + isnull(convert(nvarchar(10),@NewStatusId),'Null') + ' /SecondUserId: ' + isnull(convert(nvarchar(10),@SecondUserId),'Null') +
 	  	  	 ' /ParentEventId: ' + isnull(convert(nvarchar(10),@ParentEventId),'Null') + ' /ExtendedInfo: ' + isnull(@ExtendedInfo,'Null') + 
 	  	  	 ' /CurrentFilter: ' + isnull(@CurrentFilter,'Null') + ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null'))
  End
IF 	 @EventName Is Not Null 
BEGIN
 	 If len(@EventName) > 50
 	   BEGIN
 	  	 UPDATE 	 Event_Transactions 
 	  	   SET 	 OrphanedReason  	  	 = 'Warning - Batch Name Truncated - [' + @EventName + '] > 50 characters'
 	  	   WHERE 	 EventTransactionId  	 = @EventTransactionId
 	  	 Select @EventName = substring(@EventName,1,50)
 	   END
 	 -------------------------------------------------------------------------------
 	 -- Search For Event By Event Name
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @EventId 	  	  	  	  	  	  	 = Null,
 	  	  	  	  	 @OldStartTime 	  	  	  	  	 = Null,
          @OldEndTime 	  	  	  	  	  	 = Null,
 	  	  	  	  	 @OldProductId 	  	  	  	  	 = Null,
 	  	  	  	  	 @OldStatusId 	  	  	  	  	 = Null
 	 SELECT 	 @EventId 	  	  	  	  	  	  	  	 = Event_Id,
 	  	  	 @OldStartTime 	  	  	  	  	  	 = Start_Time,
 	  	  	   @OldEndTime  	  	  	  	  	  	 = Timestamp,
 	  	  	 @OldProductId  	  	  	  	  	 = Applied_Product,
          @OldStatusId  	  	  	  	  	  	 = Event_Status 
 	  	 FROM 	 Events 
 	  	 WHERE 	 Event_Num 	 = @EventName and
 	  	       PU_Id  	  	 = @EventUnitId
 	 -------------------------------------------------------------------------------
 	 -- See if there if already a different Event at this time If Yes move by 1 second
 	 -------------------------------------------------------------------------------
 	 Select @ExistingETime = @NewEndTime
 	 While  @ExistingETime Is not Null
 	  	 Begin
 	  	  	 Select @ExistingETime = Null
 	  	  	 Select @ExistingETime = TimeStamp 
 	  	  	  	  	 FROM 	 Events 
 	  	  	  	  	 WHERE 	 PU_Id = @EventUnitId and TimeStamp = @NewEndTime and  Event_Num <> @EventName
 	  	  	 If @ExistingETime is not null
 	  	  	  	 Begin
 	  	  	  	  	 Select @NewEndTime = DateAdd(Second,1,@NewEndTime)
 	  	  	  	 End
 	  	 End
END
ELSE
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Event Name Was Not Specified, So Assume The Latest Event Before Procedure Time
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @OldEndTime 	  	  	  	  	  	  	 = Null 	 
  IF @CurrentFilter Is Null
    BEGIN
 	  	  	 SELECT 	 @OldEndTime  	  	  	  	 = Max(TimeStamp) 
 	  	  	  	 FROM 	 Events 
 	  	  	  	 WHERE 	 PU_Id = @EventUnitId and 
              Timestamp <= @NewEndTime
    END
  ELSE
    BEGIN
 	  	  	 SELECT 	 @OldEndTime  	  	  	  	 = Max(TimeStamp) 
 	  	  	  	 FROM 	 Events 
 	  	  	  	 WHERE 	 PU_Id = @EventUnitId and 
              Timestamp <= @NewEndTime and
              Event_Num Like @CurrentFilter + '%'
    END
 	 IF 	 @OldEndTime Is Null
 	 BEGIN
 	  	 SELECT 	 @Error = 'Unable to Find Current Procedure, And No Procedure Specified, Unit = [' + convert(nvarchar(10),@EventUnitId)  + ']'
 	  	 GOTO 	 Errc
 	 END
 	 SELECT 	 @EventId 	  	  	  	  	  	  	  	 = Event_Id,
 	  	  	  	  	 @OldStartTime 	  	  	  	  	  	 = Start_Time,
          @OldEndTime  	  	  	  	  	  	 = Timestamp,
 	  	  	  	  	 @OldProductId  	  	  	  	  	 = Applied_Product,
          @OldStatusId  	  	  	  	  	  	 = Event_Status,
          @EventName  	  	  	  	  	  	  	 = Event_Num 
 	  	 FROM 	 Events 
 	  	 WHERE 	 PU_Id  	  	 = @EventUnitId and
          Timestamp = @OldEndTime
END
 	 -------------------------------------------------------------------------------
 	 -- See if there if already a different Event at this time If Yes move by 1 second
 	 -------------------------------------------------------------------------------
 	 Select @ExistingETime = @OldEndTime
 	 Select @ActualEndTime =  @OldEndTime
 	 While  @ExistingETime Is not Null
 	  	 Begin
 	  	  	 Select @ExistingETime = Null
 	  	  	 Select @ExistingETime = TimeStamp 
 	  	  	  	  	 FROM 	 Events 
 	  	  	  	  	 WHERE 	 PU_Id = @EventUnitId and TimeStamp = @OldEndTime and  Event_Num <> @EventName
 	  	  	 If @ExistingETime is not null
 	  	  	  	 Begin
 	  	  	  	  	 Select @OldEndTime = DateAdd(Second,1,@OldEndTime)
 	  	  	  	 End
 	  	 End
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'EventId:' + Isnull(convert(nvarchar(25),@EventId),'Null'))
IF 	 @EventId Is Null 
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- We DO NOT Have An Event, Create One
 	 ------------------------------------------------------------------------------- 	  	  	  	          
 	 -------------------------------------------------------------------------------
 	 -- Fix Status
 	 ------------------------------------------------------------------------------- 	  	  	  	          
  If @ChangeStatusFlag = 1
    Select @NewStatusId = coalesce(@NewStatusId, 5)
 	 -------------------------------------------------------------------------------
 	 -- Fix Product
 	 ------------------------------------------------------------------------------- 	  	  	  	          
-- 	 SELECT @TestProduct = case  	  	  	  	  	  	  	  	  	  	  	  	  	 
--          	  	  	  	  	  	  	  	  	 when @ChangeProductFlag = 0 Then @NewProductId 
--          	  	  	  	  	  	  	  	  	 Else NULL
--       	  	  	  	  	  	  	  	  	 End
 	 -------------------------------------------------------------------------------
 	 -- Call SPServer that creates production events
 	 ------------------------------------------------------------------------------- 	  	 
 	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'INSERT:' + Isnull(convert(nvarchar(25),@NewEndTime,120),'Null'))
 	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@EventUnitId:' + Isnull(convert(nvarchar(10),@EventUnitId),'Null'))
 	 SELECT @NewStartTime = Isnull(@NewStartTime,@NewEndTime) --ECR #30524 if no startime starttime = endtime
 	 --Make sure the uses_start_time and Chain_Start_Time are set on the unit.
 	 UPDATE 	 Prod_Units_Base
 	  	 SET 	 Uses_Start_Time = 1,Chain_Start_Time  	 = 0 
 	  	 WHERE 	 PU_Id = @EventUnitId and ((Uses_Start_Time = 0) or (Chain_Start_Time  	 = 1) or (Uses_Start_Time Is Null) or (Chain_Start_Time Is Null))
 	 EXEC 	 SpServer_DBMgrUpdEvent  
 	  	  	 @EventId 	 OUTPUT,  	  	  	  	  	  	 -- Event_Id
 	  	  	 @EventName, 	  	  	  	  	  	  	  	  	  	 -- Event_Num
 	  	  	 @EventUnitId, 	  	  	  	  	  	  	  	  	 -- PU_Id
 	  	  	 @NewEndTime, 	  	  	  	  	  	  	  	  	 -- TimeStamp
-- 	  	  	 @TestProduct, 	  	  	  	  	  	  	  	  	 -- Applied Product 	  	  	  	 
 	  	  	 @NewProductId,
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	  	  	 -- Source Event
 	  	  	 @NewStatusId, 	  	  	  	  	  	  	  	  	 -- Event Status
 	  	  	 1, 	  	  	  	  	  	  	  	  	  	  	  	  	  	 -- Transaction_type
 	  	  	 0, 	  	  	  	  	  	  	  	  	  	  	  	  	  	 -- TransNum
 	  	  	 @UserId, 	  	  	  	  	  	  	  	  	  	  	 -- UserId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	  	  	 -- CommentId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	 -- EventSubtypeid
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	  	  	 -- TestingStatus
 	  	  	 @NewStartTime, 	  	  	  	  	  	  	  	 -- StartTime
 	  	  	 Null,  	  	  	  	  	  	  	  	  	  	  	  	 -- EntryOn
 	  	  	 1, 	  	  	  	  	  	  	  	  	  	  	  	  	  	 -- ReturnResultSet
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	  	  	 -- Conformance
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	  	  	 -- TestPctComplete
 	  	  	 @SecondUserId, 	  	  	  	  	  	  	  	 -- SecondUserId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	  	  	 -- ApproverUserId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	  	  	 -- ApproverReasonId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	  	  	 -- UserReasonId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	  	  	 -- UserSignOffId
 	  	  	 @ExtendedInfo, 	  	  	  	  	  	  	  	  	 -- ExtendedInfo
 	  	  	 1 	  	  	  	  	  	  	  	  	  	  	 --Send Posts out
 	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Update Done:' + Isnull(convert(nvarchar(10),@EventId),'null'))
/*
 	 -------------------------------------------------------------------------------
 	 -- Return Real-Time Update
 	 ------------------------------------------------------------------------------- 	  	  	  	 
 	 SELECT  	 ResultsetType  	  	  	  	  	 = 1, 
          	 Id  	  	  	  	  	  	  	  	  	  	  	 = 1, 
          	 Transaction_Type  	  	  	  	 = 1, 
          	 Event_Id  	  	  	  	  	  	  	  	 = @EventId, 
          	 Event_Num  	  	  	  	  	  	  	 = @EventName, 
          	 PU_Id  	  	  	  	  	  	  	  	  	 = @EventUnitId,
 	  	  	  	  	 TimeStamp  	  	  	  	  	  	  	 = @NewEndTime, 
          Applied_Product  	  	  	  	 = @TestProduct, 	  	  	  	  	  	  	  	  	  	  	  	 
          Source_Event  	  	  	  	  	  	 =  NULL, 
          Event_Status  	  	  	  	  	  	 = @NewStatusId, 
          Confirmed  	  	  	  	  	  	  	 = 1, 	  	 
          User_Id  	  	  	  	  	  	  	  	 = @UserId, 
          Post_Update  	  	  	  	  	  	 = 1, 
          Conformance  	  	  	  	  	  	 = null, 
          TestPctComplete  	  	  	  	 = null, 
          Start_Time  	  	  	  	  	  	  	 = @NewStartTime,
 	  	       TransNum  	  	  	  	  	  	  	  	 = 0, 
          TestingStatus  	  	  	  	  	 = null, 
          CommentId  	  	  	  	  	  	  	 = null, 
          EventSubTypeId  	  	  	  	  	 = null, 
          EntryOn  	  	  	  	  	  	  	  	 = null,
 	  	  	  	  	 ApproverId 	  	  	  	  	  	  	 = Null,
 	  	  	  	  	 SecondUserId 	  	  	  	  	  	 = @SecondUserId
*/
  IF @ChangeProductFlag = 1
    BEGIN
 	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Grade Change')
 	  	  	  	 EXEC 	 spServer_DBMgrUpdGrade2  
 	  	  	  	  	 @CurrentId   	 OUTPUT, 
 	  	  	  	  	 @EventUnitId,
 	  	  	  	  	 @NewProductId,
 	  	  	  	  	 0,
 	  	  	  	  	 @NewEndTime,
 	  	  	  	  	 0,
 	  	  	  	  	 1, --UserId
 	  	  	  	  	 Null,
 	  	  	  	  	 Null,
 	  	  	  	  	 Null,
 	  	  	  	  	 Null,
 	  	  	  	  	 0,
 	  	  	  	  	 Null,
 	  	  	  	  	 Null,
 	  	  	  	  	 Null
 	  	 
 	  	  	 IF 	 @CurrentId Is Not Null
 	  	  	   SELECT  	 ResultsetType = 3,
 	  	  	  	  	  	  	  	 StartId = @CurrentId, 
                PU_Id = @EventUnitId, 
 	  	  	  	  	  	  	  	 Prod_Id = @NewProductId, 
 	  	  	  	  	  	  	  	 Start_Time = @NewEndTime, 
 	  	  	  	  	  	  	  	 PostUpdate = 1, 
 	  	  	  	  	  	  	  	 UserId = @UserId
    END
END
ELSE
BEGIN 	 
 	 -------------------------------------------------------------------------------
 	 -- We Already Have An Event - Update The Event
 	 ------------------------------------------------------------------------------- 	  	  	  	     
 	 -------------------------------------------------------------------------------
 	 -- Determine New Timestamps
  -- start time should only be reset if earlier than previous
  -- end time should be moved to current procedure end time
 	 ------------------------------------------------------------------------------- 	  	  	  	     
 	 SELECT 	 @NewStartTime = case
                                 When @OldStartTime Is Null Then @NewStartTime
                                 When @NewStartTime < @OldStartTime Then @NewStartTime
                                 Else @OldStartTime
                               end,
 	  	  	 @NewEndTime = case
                                 When @NewEndTime < @OldEndTime Then @OldEndTime
                                 Else @NewEndTime
                               end
 --         @NewEndTime = @NewEndTime
IF @MoveEndTime = 0
 	 SET @NewEndTime = @OldEndTime
 	 -------------------------------------------------------------------------------
 	 -- Determine New Status
 	 ------------------------------------------------------------------------------- 	  	  	  	     
  Select @NewStatusId = Case
                           When @ChangeStatusFlag = 1 Then coalesce(@NewStatusId, @OldStatusId)
                           Else @OldStatusId 
                        End 
 	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@NewProductId:' + IsNull(convert(nvarchar(10),@NewProductId),'Null'))
  If @ChangeProductFlag = 1 
    BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Check Product Of Event
 	  	  	 ------------------------------------------------------------------------------- 	  	  	  	     
 	  	  	 SELECT 	 @TestProduct 	  	 = Prod_Id 
 	  	  	 FROM 	 Production_Starts 
 	  	  	 WHERE 	 PU_Id  	  	 = @EventUnitId 
 	  	  	 AND 	 Start_Time  	 <= @NewEndTime 
 	  	  	 AND  	 (End_Time > @NewEndTime 
 	  	  	  	 OR 	 End_Time Is Null)
 	  	 
 	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@TestProduct:' + IsNull(convert(nvarchar(10),@TestProduct),'Null'))
 	  	 
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Assign passed product as the applied one if different than the current one
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 IF 	 @TestProduct <> @NewProductId 
 	  	  	  	 SELECT 	 @NewProductId = coalesce(@NewProductId, @OldProductId)
 	  	  	 ELSE
 	  	  	  	 SELECT 	 @NewProductId = Null
 	  	  	 If @HaveUnitProcedure = 1 and Left(@EventName,2) <> 'U:'
 	  	  	  	 SELECT 	 @NewProductId = Null
    END
  ELSE
    BEGIN
 	  	   SELECT 	 @NewProductId = coalesce(@NewProductId, @OldProductId)
    END
 	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@NewProductId:' + IsNull(convert(nvarchar(10),@NewProductId),'Null'))
 	 -------------------------------------------------------------------------------
 	 -- Call SPServer that updates events
 	 ------------------------------------------------------------------------------- 	  	 
 	 If ((@NewProductId <> @OldProductId) or (@NewProductId is not null and  @OldProductId is null)) or (@NewStatusId <> @OldStatusId) or (@NewStartTime <> @OldStartTime) or (@NewEndTime <> @OldEndTime) 
 	 BEGIN
 	  	 If (Select isnull(Convert(Int,Value),0) From Site_Parameters Where Parm_Id = 506) = 1
 	  	  	 SELECT @NewStatusId = NULL
 	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'UPDATE2:' + convert(nvarchar(25),@NewEndTime,120))
 	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@EventUnitId2:' + convert(nvarchar(10),@EventUnitId))
 	  	 EXEC 	 spServer_DBMgrUpdEvent  
 	  	  	 @EventId  	 OUTPUT,  	  	  	  	  	  	  	  	  	 -- Event_Id
 	  	  	 @EventName, 	  	  	  	  	  	  	  	  	  	 -- Event_Num
 	  	  	 @EventUnitId, 	  	  	  	  	  	  	  	  	  	 -- PU_Id
 	  	  	 @NewEndTime, 	  	  	  	  	  	  	  	  	  	 -- TimeStamp
 	  	  	 @NewProductId, 	  	  	  	  	  	  	  	  	  	 -- Applied Product
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- Source Event 	 
 	  	  	 @NewStatusId, 	  	  	  	  	  	  	  	  	  	 -- Event Status
 	  	  	 2, 	  	  	  	  	  	  	  	  	  	  	  	 -- Transaction_type
 	  	  	 0, 	  	  	  	  	  	  	  	  	  	  	  	 -- TransNum
 	  	  	 @UserId, 	  	  	  	  	  	  	  	  	  	  	 -- UserId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- CommentId
 	  	  	 Null, 	  	  	  	  	  	  	  	 -- EventSubtypeid
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- TestingStatus
 	  	  	 @NewStartTime, 	  	  	  	  	  	  	  	  	  	 -- StartTime
 	  	  	 Null, 	  	  	  	   	  	  	  	  	  	  	 -- EntryOn
 	  	  	 1, 	  	  	  	  	  	  	  	  	  	  	  	 -- ReturnResultSet
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- Conformance
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- TestPctComplete
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- SecondUserId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- ApproverUserId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- ApproverReasonId 	 
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- UserReasonId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- UserSignOffId
 	  	  	 Null, 	  	  	  	  	  	  	  	  	  	  	 -- ExtendedInfo
 	  	  	 1 	  	  	  	  	  	  	  	  	  	  	  	 --Send Posts out
 	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'UPDATE2Done:' )
 	 END
END
-------------------------------------------------------------------------------
-- Update LotIdentifier 	 and FriendlyOperationName if given
--    These should maybe be part of the spServer_DBMgrUpdEvent sproc,
--    but they're not part of the message, so it seems better to keep
--    them separate
-------------------------------------------------------------------------------
if (@LotIdentifier is not null) or (@FriendlyOperationName is not null)
Begin
  update Events
     Set Lot_Identifier = Coalesce(@LotIdentifier, Lot_Identifier),
 	      Operation_Name = Coalesce(@FriendlyOperationName, Operation_Name)
   where Event_Id = @EventId
End
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Event_Components')
-------------------------------------------------------------------------------
-- See If We Need To Link Back To Parent Genealogy
-------------------------------------------------------------------------------
IF @ParentEventId Is Not Null
  BEGIN
    SELECT @CurrentId = NULL
 	  	 Select @CurrentId = Component_Id From Event_Components where Source_Event_Id = @ParentEventId and Event_Id = @EventId
 	  	 If @CurrentId is Null
 	  	  	 Select @TransType = 1
 	  	 Else
 	  	  	 Select @TransType = 2
 	  	 EXECUTE 	 spServer_DBMgrUpdEventComp 	 
 	  	  	 @UserId,
 	  	  	 @EventId,
 	  	  	 @CurrentId  	  	  	  	 OUTPUT,
 	  	  	 @ParentEventId,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 0,
 	  	  	 @TransType,
 	  	  	 Null,-- @ChildUnitId
 	  	  	 Null,--Start_Coordinate X
 	  	  	 Null,--Start_Coordinate Y
 	  	  	 Null,--Start_Coordinate Z
 	  	  	 Null,--Start_Coordinate A
 	  	  	 @NewStartTime,--Start_Time
 	  	  	 @NewEndTime, --TimeStamp
 	  	  	 Null,--@Parent_Component_Id
 	  	  	 Null,--@Entry_On
 	  	  	 Null,--@Extended_Info
 	  	  	 Null,--@PEI_Id
 	  	  	 0 	  	  --@ReportAsConsumption
 	  	 -------------------------------------------------------------------------------
 	  	 -- Perform Real-Time Update
 	  	 ------------------------------------------------------------------------------- 	  	 
 	  	 SELECT  	 ResultsetType = 11,
 	  	  	  	 Pre = 0, 
 	  	  	  	 UserId = @UserId, 
 	  	  	  	 TransType = @TransType, 
 	  	  	  	 TransNum = 0, 
 	  	  	  	 ComponentId = @CurrentId, 
 	  	  	  	 EventId = @EventId,
 	  	  	  	 SrcEventId = @ParentEventId, 
 	  	  	  	 DimX = NULL, 
 	  	  	  	 DimY = NULL, 
 	  	  	  	 DimZ = NULL, 
 	  	  	  	 DimA = NULL, 
 	  	  	  	 StartCoordinateX = NULL, 
 	  	  	  	 StartCoordinateY = NULL, 
 	  	  	  	 StartCoordinateZ = NULL, 
 	  	  	  	 StartCoordinateA = NULL, 
 	  	  	  	 StartTime = @NewStartTime, 
 	  	  	  	 [Timestamp] = @NewEndTime, 
 	  	  	  	 PPComponentId = NULL,
 	  	  	  	 EntryOn = NULL,
 	  	  	  	 ExtendedInfo = NULL
  END
-------------------------------------------------------------------------------
-- Call SPServer that creates production event details if needed
------------------------------------------------------------------------------- 	  	 
If (@ProcessOrderId is not null) or (@InitialDimensionX is not null) or (@InitialDimensionY is not null) or (@InitialDimensionZ is not null) or (@InitialDimensionA is not null) or (@FinalDimensionX is not null) or (@FinalDimensionY is not null) or (@FinalDimensionZ is not null) or (@FinalDimensionA is not null)
BEGIN
 	 SET @TransType = 1 	 
 	 if Exists(SELECT 1 FROM Event_Details WHERE Event_Id = @EventId) SET @TransType = 2
 	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Begin Detail Insert:' + Isnull(convert(nvarchar(10),@EventId),'null'))
 	 EXEC spServer_DBMgrUpdEventDet
 	  	 @UserId, 	  	  	  	 -- @UserId
 	  	 @EventId, 	  	  	  	 -- @EventId
 	  	 @EventUnitId, 	  	  	 -- @PUId
 	  	 null, 	  	  	  	  	 -- @Future1
 	  	 @TransType, 	  	  	  	 -- @TransType
 	  	 0, 	  	  	  	  	  	 -- @TransNum
 	  	 null, 	  	  	  	  	 -- @AltEventNum
 	  	 null, 	  	  	  	  	 -- @Future2
 	  	 @InitialDimensionX, 	  	 -- @InitialDimX
 	  	 @InitialDimensionY, 	  	 -- @InitialDimY
 	  	 @InitialDimensionZ, 	  	 -- @InitialDimZ
 	  	 @InitialDimensionA, 	  	 -- @InitialDimA
 	  	 @FinalDimensionX, 	  	 -- @FinalDimX
 	  	 @FinalDimensionY, 	  	 -- @FinalDimY
 	  	 @FinalDimensionZ, 	  	 -- @FinalDimZ
 	  	 @FinalDimensionA, 	  	 -- @FinalDimA
 	  	 null, 	  	  	  	  	 -- @OrientationX
 	  	 null, 	  	  	  	  	 -- @OrientationY
 	  	 null, 	  	  	  	  	 -- @OrientationZ
 	  	 null, 	  	  	  	  	 -- @Future3
 	  	 null, 	  	  	  	  	 -- @Future4
 	  	 null, 	  	  	  	  	 -- @OrderId
 	  	 null, 	  	  	  	  	 -- @OrderLineId
 	  	 @ProcessOrderId, 	  	 -- @PPId
 	  	 null, 	  	  	  	  	 -- @PPSetupDetailId
 	  	 null, 	  	  	  	  	 -- @ShipmentId
 	  	 null, 	  	  	  	  	 -- @CommentId
 	  	 null, 	  	  	  	  	 -- @EntryOn
 	  	 @NewEndTime, 	  	  	 -- @TimeStamp
 	  	 null, 	  	  	  	  	 -- @Future6
 	     null, 	  	  	  	  	 -- @SignatureId
 	  	 null 	  	  	  	  	 -- @ProductDefId
 	 -- result set
 	 SELECT 	 10, 	  	  	  	  	  	 -- RSTId
 	  	  	 0, 	  	  	  	  	  	 -- PreDB
 	  	  	 @UserId, 	  	  	  	 -- UserId
 	  	  	 @TransType, 	  	  	  	 -- TransType
 	  	  	 0, 	  	  	  	  	  	 -- TransNum
 	  	  	 Event_Id, 	  	  	  	 -- EventId
 	  	  	 PU_Id, 	  	  	  	  	 -- PUId
 	  	  	 NULL, 	  	  	  	  	 -- Obsolete
 	  	  	 Alternate_Event_Num, 	 -- AltEventNum
 	  	  	 Comment_Id, 	  	  	  	 -- CommentId
 	  	  	 NULL, 	  	  	  	  	 -- Obsolete
 	  	  	 NULL, 	  	  	  	  	 -- Obsolete
 	  	  	 NULL, 	  	  	  	  	 -- Obsolete
 	  	  	 NULL, 	  	  	  	  	 -- Obsolete
 	  	  	 @NewEndTime, 	  	  	 -- TimeStamp
 	  	  	 Entered_On, 	  	  	  	 -- EntryOn
 	  	  	 PP_Setup_Detail_Id, 	  	 -- PPSetupDetailId
 	  	  	 Shipment_Id, 	  	  	 -- ShipmentId
 	  	  	 Order_Id, 	  	  	  	 -- OrderId
 	  	  	 Order_Line_Id, 	  	  	 -- OrderLineId
 	  	  	 PP_Id, 	  	  	  	  	 -- PPId
 	  	  	 Initial_Dimension_X, 	 -- InitialDimensionX
 	  	  	 Initial_Dimension_Y, 	 -- InitialDimensionY
 	  	  	 Initial_Dimension_Z, 	 -- InitialDimensionZ
 	  	  	 Initial_Dimension_A, 	 -- InitialDimensionA
 	  	  	 Final_Dimension_X, 	  	 -- FinalDimensionX
 	  	  	 Final_Dimension_Y, 	  	 -- FinalDimensionY
 	  	  	 Final_Dimension_Z, 	  	 -- FinalDimensionZ
 	  	  	 Final_Dimension_A, 	  	 -- FinalDimensionA
 	  	  	 Orientation_X, 	  	  	 -- OrientationX
 	  	  	 Orientation_Y, 	  	  	 -- OrientationY
 	  	  	 Orientation_Z, 	  	  	 -- OrientationZ
 	  	  	 Signature_Id 	  	  	 -- ESigId
 	   FROM 	 Event_Details
 	   WHERE 	 Event_Id = @EventId
 	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Done Detail Insert:' + Isnull(convert(nvarchar(10),@EventId),'null'))
END
Finish:
-------------------------------------------------------------------------------
-- Normal exit
-------------------------------------------------------------------------------
Select @Rc = 1
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_GetSingleEvent)')
RETURN(@Rc)
-------------------------------------------------------------------------------
-- Handle exceptions
-------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	  	 = @Error,
 	  	 OrphanedFlag  	  	 = 1 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_GetSingleEvent)')
RETURN(-100)
