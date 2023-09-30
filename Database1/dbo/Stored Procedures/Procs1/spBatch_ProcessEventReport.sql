CREATE Procedure dbo.spBatch_ProcessEventReport
 	 @EventTransactionId Int,
 	 @BatchUnitId 	  	  	  	 Int,
 	 @BatchProcedureUnitId 	 Int,
 	 @BatchProcedureGroupId 	  	 Int,
 	 @ProcedureUnitId 	  	  	  	  	  	  	 Int,
 	 @UserId 	  	  	  	 Int,
 	 @SecondUserId  	  	 Int,
 	 @Debug 	  	  	  	  	  	 int = NULL
AS
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
-------------------------------------------------------------------------------
-- Declare Generic Variables
-------------------------------------------------------------------------------
Declare 
 	  	 @EventTimeStamp 	  	  	  	  	  	  	 DateTime,
 	  	 @EventName 	  	  	  	  	  	  	  	  	 nvarchar(100),
 	  	 @BatchName 	  	  	  	  	  	  	  	  	 nvarchar(100),
 	  	 @UnitProcedureName 	  	  	  	  	 nvarchar(50),
 	  	 @OperationName 	  	  	  	  	  	  	 nvarchar(50),
 	  	 @PhaseName 	  	  	  	  	  	  	  	  	 nvarchar(50),
 	  	 @PhaseInstance 	  	  	  	  	  	  	 Int,
 	  	 @ProcedureStartTime 	  	  	  	  	 DateTime,
 	  	 @ProcedureEndTime 	  	  	  	  	  	 DateTime,
 	  	 @ParameterName 	  	  	  	  	  	  	 nvarchar(50),
 	  	 @ParameterAttributeName 	  	  	 nvarchar(50),
 	  	 @ParameterAttributeValue 	  	 nvarchar(50),
 	  	 @ParameterAttributeComments 	 nvarchar(255),
 	  	 @EventSTName 	  	  	  	  	  	  	  	 nvarchar(50),
 	  	 @ECId 	  	  	  	  	  	  	  	  	  	  	  	 Int
Declare
 	  	 @ESID 	  	  	  	  	  	 Int
Declare 
 	  	 @Error 	  	  	  	 nvarchar(255),
    @Rc  	  	  	  	  	 int,
 	  	 @Id 	  	  	  	  	  	 Int
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
Select  	 @Error = '', 
 	  	  	  	 @Rc = 0
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START(spBatch_ProcessEventReport)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_ProcessEventReport /EventTransactionId: ' + Isnull(convert(nvarchar(10),@EventTransactionId),'Null') +
   	  	  	  	  	 ' /BatchUnitId: ' + Isnull(convert(nvarchar(10),@BatchUnitId),'Null')  +
   	  	  	  	  	 ' /BatchProcedureUnitId: ' + Isnull(convert(nvarchar(10),@BatchProcedureUnitId),'Null')  +
   	  	  	  	  	 ' /BatchProcedureGroupId: ' + Isnull(convert(nvarchar(10),@BatchProcedureGroupId),'Null')  +
   	  	  	  	  	 ' /ProcedureUnitId: ' + Isnull(convert(nvarchar(10),@ProcedureUnitId),'Null')  +
   	  	  	  	  	 ' /UserId: ' + Isnull(convert(nvarchar(10),@UserId),'Null')  +
   	  	  	  	  	 ' /SecondUserId: ' + Isnull(convert(nvarchar(10),@SecondUserId),'Null')  +
   	  	  	  	  	 ' /Debug: ' + Isnull(convert(nvarchar(10),@Debug),'Null')
)
  End
-------------------------------------------------------------------------------
-- Read Event_Transactions record for the passed Id
-------------------------------------------------------------------------------
Select  	 @EventTimeStamp  	  	  	 = EventTimeStamp,
 	  	 @BatchName 	  	  	  	  	 = LTrim(RTrim(BatchName)),
 	  	 @EventName 	  	  	  	  	 = LTrim(RTrim(EventName)),
 	  	 @UnitProcedureName 	  	  	 = LTrim(RTrim(UnitProcedureName)),
 	  	 @OperationName 	  	  	  	 = LTrim(RTrim(OperationName)),
 	  	 @PhaseName 	  	  	  	  	 = LTrim(RTrim(PhaseName)),
 	  	 @PhaseInstance 	  	  	  	 = PhaseInstance,
 	  	 @ProcedureStartTime 	  	  	 = ProcedureStartTime,
 	  	 @ProcedureEndTime 	  	  	 = ProcedureEndTime,
 	  	 @ParameterName 	  	  	  	 = LTrim(RTrim(ParameterName)),
 	  	 @ParameterAttributeName 	  	 = LTrim(RTrim(ParameterAttributeName)),
 	  	 @ParameterAttributeValue 	 = LTrim(RTrim(ParameterAttributeValue)),
 	  	 @ParameterAttributeComments 	 = LTrim(RTrim(ParameterAttributeComments)),
 	  	 @EventSTName 	  	  	  	  	  	  	  	 =  LTrim(RTrim(EventReportType))
From  Event_Transactions
 Where EventTransactionId = @EventTransactionId
-------------------------------------------------------------------------------
-- Check record
-------------------------------------------------------------------------------
If @BatchName = '' Select @BatchName = Null
If @EventName = '' Select @EventName = Null
If @UnitProcedureName = '' Select @UnitProcedureName = Null
If @OperationName = '' Select @OperationName = Null
If @PhaseName = '' Select @PhaseName = Null
If @ParameterName = '' Select @ParameterName = Null
If @ParameterAttributeName = '' Select @ParameterAttributeName = Null
If @ParameterAttributeValue = '' Select @ParameterAttributeValue = Null
If @ParameterAttributeComments = '' Select @ParameterAttributeComments = Null
If @EventSTName = '' Select @EventSTName = Null
If (isdate(@ProcedureStartTime) = 0) and (@ProcedureStartTime is Not Null) and (@ProcedureStartTime <> '')
  Begin
 	 Select @Error = 'Bad Procedure Start Time[' + Convert(nvarchar(25),@ProcedureStartTime) + ']'
 	 Goto Errc
  End
If (isdate(@ProcedureEndTime) = 0) and (@ProcedureEndTime is Not Null) and (@ProcedureEndTime <> '')
  Begin
 	 Select @Error = 'Bad Procedure End Time[' + Convert(nvarchar(25),@ProcedureEndTime) + ']'
 	 Goto Errc
  End
If (@EventName is Null) and (@ParameterName is Null)
  Begin
 	 Select @Error = 'Missing Parameter Name or Event Type'
 	 Goto Errc
  End
If (@EventName is Not Null) and (@EventSTName is Null)
  Begin
 	 Select @Error = 'Missing Event Report Type'
 	 Goto Errc
  End
Select @ProcedureStartTime = Isnull(@ProcedureStartTime,@EventTimeStamp)
Select @ProcedureEndTime = coalesce(@ProcedureEndTime,@ProcedureStartTime,@EventTimeStamp)
Select @BatchProcedureUnitId = isnull(@BatchProcedureUnitId,@BatchUnitId)
If @OperationName is Null and @PhaseName is null  -- Can put variables  on phase, operation  or batch not procedure unit
 	  	 Select @BatchProcedureUnitId = @BatchUnitId
-------------------------------------------------------------------------------
-- Process Record Based On Alarm Or User Defined Event
-------------------------------------------------------------------------------
If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'EventName:' + isnull(@EventName,'Null'))
If (@EventName is Not Null) -- UserDefined Event
  Begin
 	 Select @ESID = Null
 	 Select @ESID = Event_Subtype_Id from event_subtypes Where Event_Subtype_Desc = @EventSTName
 	 If @ESID Is null
 	   Begin
 	  	  	 Execute spEMEC_UpdateUDEEvent NULL,@EventSTName, 121,0,0,0,0,Null,1,@ESID OUTPUT
 	  	  	 If @ESID Is null
 	  	  	   Begin
 	  	  	  	  	 Select @Error = 'Unable to create new User Defined Event Type'
 	  	  	  	  	 Goto Errc
 	  	  	   End
 	  	  	 Select @ECId = NUll
 	  	  	 Select @ECId = Ec_ID from Event_Configuration Where PU_Id = @BatchProcedureUnitId and Event_Subtype_Id = @ESID And ET_Id = 14
 	  	  	 If @ECId Is Null
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into Event_Configuration (ET_Id, Event_Subtype_Id, PU_Id) 	 Values  (14, @ESID, @BatchProcedureUnitId)
 	  	  	  	 End
 	  	   End
 	  	  	 If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Execute spBatch_CreateUDEvents ')
 	  	   Execute @Rc = spBatch_CreateUDEvents  @EventTransactionId,@EventName,@EventSTName, @EventTimeStamp,@ProcedureEndTime,@ProcedureStartTime,
 	  	  	  	  	  	 @BatchProcedureUnitId,@BatchProcedureUnitId,@BatchProcedureGroupId,@ProcedureUnitId, @UserId,@UnitProcedureName,@OperationName,@PhaseName,
 	  	  	  	  	  	 @PhaseInstance,@ESID,@Debug
 	  	 If @ParameterName is not Null
 	  	  	 Begin
 	  	  	  	 Execute @rc = spBatch_ProcessParameterReport @EventTransactionId,@BatchUnitId,@BatchProcedureUnitId,@BatchProcedureGroupId,@ProcedureUnitId,@UserId,@SecondUserId,@Debug
 	  	  	 End
  End
Else  -- Alarm
  Begin
 	   Execute @rc = spBatch_ProcessParameterReport @EventTransactionId,@BatchUnitId,@BatchProcedureUnitId,@BatchProcedureGroupId,@ProcedureUnitId,@UserId,@SecondUserId,@Debug
  End
If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessEventReport)')
Finish:
---------------------------------------------------------------------------------------------------
-- Normal Exit
--------------------------------------------------------------------------------------------------
RETURN(@Rc)
---------------------------------------------------------------------------------------------------
-- Error Handling
--------------------------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	 = coalesce(OrphanedReason, @Error),
 	  	 OrphanedFlag  	 = 1 
 	 WHERE 	 EventTransactionId = @EventTransactionId
If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
Return (-100)
