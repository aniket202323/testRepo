CREATE 	 PROCEDURE 	 dbo.spBatch_CreateEvents
 	 @EventTransactionId 	  	  	  	  	 Int,
 	 @BatchName 	  	  	  	  	  	 nvarchar(100),
 	 @BatchInstance 	  	  	  	  	  	 Int,
 	 @EventTimeStamp 	  	  	  	  	 DateTime,
 	 @ProcedureEndTime 	  	  	  	  	 DateTime,
 	 @ProcedureStartTime 	  	  	  	  	 DateTime,
 	 @BatchUnitId 	  	  	  	  	  	 Int,
 	 @BatchProductId 	  	  	  	  	 Int,
 	 @UserId 	  	  	  	  	  	  	 Int,
 	 @ProcedureStatusId 	  	  	  	  	 Int,
 	 @UnitProcedureName 	  	  	  	  	 nvarchar(100),
 	 @UnitProcedureInstance 	  	  	  	 Int,
 	 @OperationName 	  	  	  	  	  	 nvarchar(100),
 	 @OperationInstance 	  	  	  	  	 Int,
 	 @PhaseName 	  	  	  	  	  	 nvarchar(100),
 	 @PhaseInstance 	  	  	  	  	  	 Int,
 	 @BatchProcedureUnitId 	  	  	  	 Int,
 	 @BatchProcedureGroupId 	  	  	  	 Int,
 	 @Event_SubType 	  	  	  	  	  	 Int,
 	 @ProcedureUnitId 	  	  	  	  	 Int,
 	 @RawMaterialProductId 	  	  	  	 Int,
 	 @SecondUserId 	  	  	  	  	  	 Int,
 	 @Debug 	  	  	  	  	  	  	  	 int = NULL,
 	 @ProcessOrderId 	  	  	  	  	  	 int = NULL,
 	 @InitialDimensionX 	  	  	  	  	 float = NULL,
 	 @InitialDimensionY 	  	  	  	  	 float = NULL,
 	 @InitialDimensionZ 	  	  	  	  	 float = NULL,
 	 @InitialDimensionA 	  	  	  	  	 float = NULL,
 	 @FinalDimensionX 	  	  	  	  	 float = NULL,
 	 @FinalDimensionY 	  	  	  	  	 float = NULL,
 	 @FinalDimensionZ 	  	  	  	  	 float = NULL,
 	 @FinalDimensionA 	  	  	  	  	 float = NULL,
 	 @EventSubtype 	  	  	  	  	  	 nvarchar(50) = NULL,
 	 @LotIdentifier 	  	  	  	  	  	 nVarChar(100) = NULL,
 	 @FriendlyOperationName 	  	  	  	 nVarChar(100) = NULL
AS
SET 	 @EventTimeStamp 	 = DATEADD(MS, -DATEPART(MS, @EventTimeStamp), @EventTimeStamp)
SET 	 @ProcedureEndTime 	 = DATEADD(MS, -DATEPART(MS, @ProcedureEndTime), @ProcedureEndTime)
SET 	 @ProcedureStartTime 	  	 = DATEADD(MS, -DATEPART(MS, @ProcedureStartTime), @ProcedureStartTime)
-------------------------------------------------------------------------------
-- Declare General Variables
-------------------------------------------------------------------------------
DECLARE 	 
 	 @ChangeStatus  	  	  	  	 int,
 	 @ChangeProduct       	  	 int,
 	 @CurrentId  	  	  	  	 Int,
 	 @Start_Year  	  	  	  	 Int,
 	 @Start_Month  	  	  	  	 Int,
 	 @Start_Day  	  	  	  	 Int,
 	 @Start_Hour  	  	  	  	 Int,
 	 @Start_Minute  	  	  	  	 Int, 	 
 	 @Start_Second  	  	  	  	 Int,
 	 @DefaultProcedureStatusId 	 Int,
 	 @DefaultBatchStatusId 	  	 Int,
 	 @ProcedureEventNumber 	  	 nvarchar(100),
 	 @ProcedureFriendlyDesc 	  	 NVarChar(1000),
 	 @HaveUnitProcedure 	  	  	 Int,
 	 @BatchInstanceSep 	  	  	  	 nVarChar(1)
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
SELECT @BatchInstanceSep = '|'
Declare
 	 @BatchEventId 	  	  	 Int,
 	 @UnitProcedureEventId 	 Int,
 	 @OperationEventId 	  	 Int,
 	 @PhaseEventId 	  	  	 Int,
 	 @NewProductId  	  	  	 Int,
 	 @NewStatusId  	  	  	 Int,
 	 @MoveTime 	  	  	  	 Int
Declare @Rc  	 Int,
 	 @Id 	  	 Int
--Select  @Debug = 1 
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START(spBatch_CreateEvents)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_CreateEvents /EventTransactionId: ' + Isnull(convert(nvarchar(10),@EventTransactionId),'Null') + ' /BatchName: ' + isnull(@BatchName,'Null') + 
 	 ' /EventTimeStamp: ' + isnull(convert(nvarchar(25),@EventTimeStamp),'Null') + ' /ProcedureEndTime: ' + isnull(convert(nvarchar(25),@ProcedureEndTime),'Null') + 
 	 ' /ProcedureStartTime: ' + isnull(convert(nvarchar(25),@ProcedureStartTime),'Null') +  	 ' /BatchUnitId: ' + Isnull(convert(nvarchar(10),@BatchUnitId),'Null') + 
 	 ' /BatchProductId: ' + isnull(convert(nvarchar(10),@BatchProductId),'Null') + ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null') + 
 	 ' /ProcedureStatusId: ' + isnull(convert(nvarchar(10),@ProcedureStatusId),'Null') + ' /UnitProcedureName: ' + isnull(@UnitProcedureName,'Null') + 
 	 ' /OperationName: ' + isnull(@OperationName,'Null') + ' /PhaseName: ' + isnull(@PhaseName,'Null') + ' /SecondUserId: ' + isnull(convert(nvarchar(10),@SecondUserId),'Null') + 
 	 ' /PhaseInstance: ' + isnull(convert(nvarchar(10),@PhaseInstance),'Null') + ' /BatchProcedureUnitId: ' + isnull(convert(nvarchar(10),@BatchProcedureUnitId),'Null') + 
 	 ' /BatchProcedureGroupId: ' + isnull(convert(nvarchar(10),@BatchProcedureGroupId),'Null') 	 + ' /Event_SubType: ' + isnull(convert(nvarchar(10),@Event_SubType),'Null')  +
 	 ' /ProcedureUnitId: ' + isnull(convert(nvarchar(10),@ProcedureUnitId),'Null') + ' /RawMaterialProductId: ' + isnull(convert(nvarchar(10),@RawMaterialProductId),'Null'))
  End
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
SELECT 	 @Rc = 0
Select  @DefaultProcedureStatusId 	 = 5 -- Complete
Select  @DefaultBatchStatusId 	 = 5 -- Complete
IF 	 @OperationName Is Null  	 AND 	 @PhaseName Is Null 
 	 SET @MoveTime = 1
ELSE
 	 SET @MoveTime = 0
-------------------------------------------------------------------------------
-- Prepare Timestamps
-- if no start time is set, use event time
-- if no end time is set, use start time
-------------------------------------------------------------------------------
Select @ProcedureStartTime = coalesce(@ProcedureStartTime, @EventTimeStamp)
Select @ProcedureEndTime =  coalesce(@ProcedureEndTime, @ProcedureStartTime) 
--*****************************************************************************
--*****************************************************************************
-- Handle Main Batch
--*****************************************************************************
--*****************************************************************************
IF 	 ltrim(rtrim(@BatchName)) = '' SELECT 	 @BatchName = Null
-------------------------------------------------------------------------------
-- If This Procedure Report Is About The Batch Itself, Allow Status Changes
-------------------------------------------------------------------------------
IF 	 @UnitProcedureName Is Null 
 	 AND 	 @OperationName Is Null 
 	 AND 	 @PhaseName Is Null 
BEGIN
 	 SELECT @ChangeStatus = 1
 	 SELECT @NewStatusId = coalesce(@ProcedureStatusId, @DefaultBatchStatusId)
END
Else
BEGIN
 	 SELECT @ChangeStatus = 0
 	 SELECT @NewStatusId = NULL
END
If @BatchInstance is not Null
 	 SELECT 	 @BatchName = @BatchName  	 + @BatchInstanceSep  	 + Convert(nvarchar(10),@BatchInstance)
Select @HaveUnitProcedure  = 0
If @UnitProcedureName is not null
 	 Select @HaveUnitProcedure  = 1
Select @Rc = 0
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Call spBatch_GetSingleEvent')
EXEC @Rc = spBatch_GetSingleEvent
 	 @EventTransactionId,
 	 @BatchEventId OUTPUT,
 	 @BatchName,
 	 @BatchUnitId,
 	 @ProcedureStartTime,
 	 @ProcedureEndTime, 	  	  	  	 
 	 @BatchProductId,
 	 1,
 	 @NewStatusId,
 	 @ChangeStatus,
 	 NULL,
 	 NULL,
 	 NULL,
 	 @UserId,
 	 @SecondUserId,
 	 @HaveUnitProcedure,
 	 @MoveTime,
 	 @Debug,
 	 @ProcessOrderId,
 	 @InitialDimensionX,
 	 @InitialDimensionY,
 	 @InitialDimensionZ,
 	 @InitialDimensionA,
 	 @FinalDimensionX,
 	 @FinalDimensionY,
 	 @FinalDimensionZ,
 	 @FinalDimensionA,
 	 @LotIdentifier,
 	 null
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Done Call spBatch_GetSingleEvent')
If @Rc <> 1 Goto Errc
-------------------------------------------------------------------------------
-- If No Procedure Names Were Specified, We Are Done
-------------------------------------------------------------------------------
IF 	 @UnitProcedureName Is Null 
 	 AND 	 @OperationName Is Null 
 	 AND 	 @PhaseName Is Null 
 	 GOTO 	 Finish
--*****************************************************************************
--*****************************************************************************
-- Handle Unit Procedure
--*****************************************************************************
--*****************************************************************************
SELECT @NewStatusId = coalesce(@ProcedureStatusId, @DefaultProcedureStatusId)
-------------------------------------------------------------------------------
-- Construct The Event Number For Unit Procedure Events 
--
-- NOTE: Intended To Be Null If Unit Procedure Name Is Not Specified
-------------------------------------------------------------------------------
SELECT 	 @ProcedureEventNumber 	 = Null
SELECT 	 @ProcedureEventNumber = 'U:' 
 	   + @BatchName 
 	   + '!' 
 	   + @UnitProcedureName
If @UnitProcedureInstance is not Null
 	 SELECT 	 @ProcedureEventNumber = @ProcedureEventNumber  	 + ':'  	 + Convert(nvarchar(10),@UnitProcedureInstance)
-------------------------------------------------------------------------------
-- If This Procedure Report Is About The Unit Procedure Itself, Allow Status Changes
-------------------------------------------------------------------------------
IF @OperationName Is Null AND 	 @PhaseName Is Null
  BEGIN
   	 Select @ChangeStatus = 1
    Select @NewProductId = @RawMaterialProductId
  END
ELSE
  BEGIN
   	 Select @ChangeStatus = 0
    Select @NewProductId = NULL
  END 
Select @Rc = 0
If @BatchProductId is null and @BatchProcedureUnitId is Not Null and @ProcedureEndTime is not null
 	 Begin 
 	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Looking up Batch code')
 	  	 Select @BatchProductId = Applied_Product From Events where Event_Id = @BatchEventId
 	  	 IF @BatchProductId Is Null
 	  	 BEGIN
 	  	  	 Select @BatchProductId = prod_Id
 	  	  	  	  From Production_Starts ps
 	  	  	 Where PU_Id = @BatchUnitId and Start_Time <= @ProcedureEndTime and (End_time > @ProcedureEndTime or End_time is null) and ps.prod_Id <> 1
 	  	 END
 	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Batch code: '+ isnull(Convert(nvarchar(10),@BatchProductId),'null'))
 	  	 If @BatchProductId is not null and (Select count(*) from pu_Products where pu_Id = @BatchProcedureUnitId and Prod_Id = @BatchProductId) = 0
 	  	  	 Execute spEM_CreateUnitProd   @BatchProcedureUnitId, @BatchProductId, @UserId
 	 End
 	 
--Select @BatchProductId = Prod_Id From Production_Starts Where PU_Id = @BatchUnitId and Start_Time <= @ProcedureEndTime and (End_Time > @ProcedureEndTime or End_Time is Null)
If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Time:' + Isnull(Convert(nvarchar(25),@ProcedureEndTime,120),'Null') + ' : ' + Isnull(Convert(nvarchar(10),@BatchUnitId),'Null'))
If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Call spBatch_GetSingleEvent')
EXEC @Rc = spBatch_GetSingleEvent
 	 @EventTransactionId,
 	 @UnitProcedureEventId OUTPUT,
 	 @ProcedureEventNumber,
 	 @BatchProcedureUnitId,
 	 @ProcedureStartTime,
 	 @ProcedureEndTime, 	  	  	  	 
 	 @BatchProductId,
 	 1,
 	 @NewStatusId,
 	 @ChangeStatus,
 	 @BatchEventId,
 	 @UnitProcedureName,
 	 'U:',
 	 @UserId,
 	 @SecondUserId,
 	 1,
 	 @MoveTime,
 	 @Debug,
 	 null,
 	 null,
 	 null,
 	 null,
 	 null,
 	 null,
 	 null,
 	 null,
 	 null,
 	 null,
 	 @FriendlyOperationName
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Done Call spBatch_GetSingleEvent')
If @Rc <> 1 Goto Errc
-------------------------------------------------------------------------------
-- If No Operation Or Phase Names Were Specified, We Are Done
-------------------------------------------------------------------------------
IF 	 @OperationName Is Null 
 	  	 AND 	 @PhaseName Is Null 
 	 GOTO 	 Finish
-- Lookup the Lot Identifier because we use it in the Friendly UDE Description for operations and phases
If (@LotIdentifier is null) and (@BatchEventId is not null) and (@FriendlyOperationName is not Null)
Begin
  Select @LotIdentifier = Lot_Identifier from Events where Event_Id = @BatchEventId
End
--*****************************************************************************
--*****************************************************************************
-- Handle Operation
--*****************************************************************************
--*****************************************************************************
-------------------------------------------------------------------------------
-- Construct The Event Number For Operation Events 
--
-- NOTE: Intended To Be Null If Operation Name Is Not Specified
-------------------------------------------------------------------------------
SELECT 	 @ProcedureEventNumber 	 = Null --UDE Desc
If @OperationName Is Not Null
 	 SELECT 	 @ProcedureEventNumber = @BatchName + ':' + @OperationName 
If @OperationInstance is not Null
 	 SELECT 	 @ProcedureEventNumber = @ProcedureEventNumber  	 + ':'  	 + Convert(nvarchar(10),@OperationInstance)
SELECT 	 @ProcedureFriendlyDesc 	 = Null
If (@LotIdentifier is not null) and (@FriendlyOperationName is not Null)
 	 SELECT 	 @ProcedureFriendlyDesc = @LotIdentifier  	 + ' - '  	 + @FriendlyOperationName
-------------------------------------------------------------------------------
-- If This Procedure Report Is About The Operation Itself, Allow Status Changes
-------------------------------------------------------------------------------
IF @PhaseName Is Null
  BEGIN
   	 Select @ChangeStatus = 1
    Select @NewProductId = @RawMaterialProductId
  END
ELSE
  BEGIN
   	 Select @ChangeStatus = 0
    Select @NewProductId = NULL
  END 
Select @Rc = 0
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Call spBatch_GetSingleUDEvent')
EXEC @Rc = spBatch_GetSingleUDEvent
 	 @EventTransactionId,
 	 @UnitProcedureEventId,
 	 @OperationName,
 	 @ProcedureEventNumber,
 	 @BatchProcedureUnitId,
 	 @ProcedureStartTime,
 	 @ProcedureEndTime,
 	 'O:',
 	 @UserId,
 	 @OperationEventId Output,
 	 @Debug,
 	 @EventSubtype,
 	 @ProcedureFriendlyDesc
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Done Call spBatch_GetSingleUDEvent')
If @Rc <> 1 Goto Errc
-------------------------------------------------------------------------------
-- If No Phase Names Were Specified, We Are Done
-------------------------------------------------------------------------------
IF 	 @PhaseName Is Null 
 	 GOTO 	 Finish
--*****************************************************************************
--*****************************************************************************
-- Handle Phase
--*****************************************************************************
--*****************************************************************************
-------------------------------------------------------------------------------
-- Construct The Event Number For Phase Events 
--
-- NOTE: Intended To Be Null If Phase Name Is Not Specified
-------------------------------------------------------------------------------
IF @PhaseInstance IS Not NULL
 	 SELECT 	 @PhaseName = @PhaseName  	 + ':'  	 + Convert(nvarchar(10),@PhaseInstance)
SELECT 	 @ProcedureEventNumber = Null --UDE Desc
SELECT 	 @ProcedureEventNumber = @BatchName + ':' + @PhaseName
SELECT 	 @ProcedureFriendlyDesc 	 = Null
If (@LotIdentifier is not null) and (@FriendlyOperationName is not Null)
 	 SELECT 	 @ProcedureFriendlyDesc = @LotIdentifier  	 + ' - ' + @FriendlyOperationName + ' - ' + @PhaseName
-------------------------------------------------------------------------------
-- Always Allow Status Changes For Phases
-------------------------------------------------------------------------------
Select @ChangeStatus = 1
Select @NewProductId = @RawMaterialProductId
Select @Rc = 0
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Call spBatch_GetSingleUDEvent')
EXEC @Rc = spBatch_GetSingleUDEvent
 	 @EventTransactionId,
 	 @OperationEventId,
 	 @PhaseName,
 	 @ProcedureEventNumber,
 	 @BatchProcedureUnitId,
 	 @ProcedureStartTime,
 	 @ProcedureEndTime,
 	 'P:',
 	 @UserId,
 	 @PhaseEventId OUTPUT,
 	 @Debug,
 	 @EventSubtype,
 	 @ProcedureFriendlyDesc
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Done Call spBatch_GetSingleUDEvent')
If @Rc <> 1 Goto Errc
Finish:
-------------------------------------------------------------------------------
-- Normal exit
-------------------------------------------------------------------------------
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END ...spBatch_CreateEvents')
RETURN(1)
-------------------------------------------------------------------------------
-- Handle exceptions
-------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET OrphanedFlag  	  	 = 1 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Error In Create Events')
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END ...spBatch_CreateEvents')
RETURN(-100)
