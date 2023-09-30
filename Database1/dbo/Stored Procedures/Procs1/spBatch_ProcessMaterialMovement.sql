CREATE 	 PROCEDURE dbo.spBatch_ProcessMaterialMovement
 	 @EventTransactionId  	 Int,
 	 @BatchUnitId 	  	 Int,
 	 @RawMaterialUnitId 	  	  	 Int,
 	 @UserId  	  Int,
 	 @SecondUserId Int,
 	 @DefaultProdFamily 	 Int,
 	 @DefaultDSId 	  	 Int,
 	 @IsVirtualBatch 	 Bit,
 	 @Debug  	  	  	 int = NULL
AS
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
Declare @ID Int
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START (spBatch_ProcessMaterialMovement)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_ProcessMaterialMovement /EventTransactionId: ' + 
 	  	  	  	 Isnull(convert(nvarchar(10),@EventTransactionId),'Null') + 
 	  	  	  	 isnull(convert(nvarchar(10),@BatchUnitId),'Null') + 
 	  	  	  	 ' /RawMaterialUnitId: ' + isnull(convert(nvarchar(10),@RawMaterialUnitId),'Null') +
 	  	  	  	 ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null') + 
   	  	  	  	 ' /SecondUserId: ' + isnull(convert(nvarchar(10),@SecondUserId),'Null') + 
   	  	  	  	 ' /@DefaultProdFamily: ' + isnull(convert(nvarchar(10),@DefaultProdFamily),'Null') + 
   	  	  	  	 ' /@DefaultDSId: ' + isnull(convert(nvarchar(10),@DefaultDSId),'Null') + 
   	  	  	  	 ' /@IsVirtualBatch: ' + isnull(convert(nvarchar(10),@IsVirtualBatch),'Null') + 
 	  	  	  	 ' /Debug: ' + isnull(convert(nvarchar(10),@Debug),'Null'))
  End
-------------------------------------------------------------------------------
-- Declare Generic Variables
-------------------------------------------------------------------------------
Declare
 	  	 @EventTimeStamp 	  	  	  	 DateTime,
 	  	 @BatchName 	  	  	  	  	 nvarchar(50),
 	  	 @BatchProductCode 	  	  	 nvarchar(20),
 	  	 @ProcedureStartTime 	  	  	 DateTime,
 	  	 @ProcedureEndTime 	  	  	 DateTime,
 	  	 @RawMaterialProductCode 	  	 nvarchar(20),
 	  	 @RawMaterialBatchName 	  	 nvarchar(50),
 	  	 @RawMaterialContainerId 	  	 nvarchar(50),
 	  	 @RawMaterialDimensionX 	  	 Float,
 	  	 @RawMaterialDimensionY 	  	 Float,
 	  	 @RawMaterialDimensionZ 	  	 Float,
 	  	 @RawMaterialDimensionA 	  	 Float,
 	  	 @ProcedureName 	  	  	  	 nvarchar(50),
 	  	 @BatchInstance 	  	  	  	 Int,
 	  	 @UnitProcedureInstance 	  	 Int
Declare
 	  	 @RawMaterialProductdId 	  	  	  	 Int,
 	  	 @SourceId 	  	  	 Int,
 	  	 @EventId 	  	  	 Int,
 	  	 @SourceCount  	  	  	 Int,
 	  	 @MaxTS  	  	  	  	 Datetime,
 	  	 @ECId  	  	  	  	 Int,
 	  	 @TransType 	  	  	 Int,
 	  	 @StartTime 	  	  	 DateTime
Declare  	 @InputName  	  	 nvarchar(100),
 	  	 @InputOrder  	  	 Int,
 	  	 @EventSubtypeId  	 Int,
 	  	 @PEIId 	  	  	 Int
Declare 
 	  	 @Error 	  	  	  	 nvarchar(255),
    @Rc  	  	  	  	  	 int
-------------------------------------------------------------------------------
-- Create Temporary tables
-------------------------------------------------------------------------------
/*
Create Table #EventUpdates 
(
 	 Id 	  	       	 Int,
 	 Transaction_Type  	 Int, 
 	 Event_Id  	  	 Int  	  	 Null, 
 	 Event_Num  	  	 nvarchar(50), 
 	 PU_Id  	  	  	 Int, 
 	 TimeStamp  	  	 DateTime, 
 	 Applied_Product  	 Int  	  	 Null, 
 	 Source_Event  	  	 Int  	  	 Null, 
 	 Event_Status  	  	 Int  	  	 Null, 
 	 Confirmed  	  	 Int  	  	 Null,
 	 User_Id 	  	  	 Int  	  	 Null,
 	 Post_Update 	  	 Int  	  	 Null,
 	 Conformance 	  	 Int  	  	 Null,
 	 TestPctComplete 	  	 Int  	  	 Null,
 	 Start_Time 	  	 DateTime  	 Null,
 	 TransNum 	  	 Int  	  	 Null,
 	 TestingStatus 	  	 Int  	  	 Null,
 	 CommentId 	  	 Int  	  	 Null,
 	 EventSubTypeId 	  	 Int  	  	 Null,
 	 EntryOn 	  	  	 Int  	  	 Null
)
*/
CREATE 	 TABLE #EventComp (
 	 Pre 	  	  	 Int,
 	 UserId 	  	  	 Int,
 	 TransType 	  	 Int,
 	 TransNum 	  	 Int,
 	 ComponentId 	  	 Int,
 	 EventId 	  	  	 Int,
 	 SrcEventId 	  	 Int,
 	 DimX 	  	  	 Float,
 	 DimY 	  	  	 Float,
 	 DimZ 	  	  	 Float,
 	 DimA 	  	  	 Float,
 	 StartCoordinateX 	 Real 	  	 Null,
 	 StartCoordinateY 	 Real 	  	 Null,
 	 StartCoordinateZ 	 Real 	  	 Null,
 	 StartCoordinateA 	 Real 	  	 Null,
 	 StartTime 	  	 DateTime 	 Null,
 	 [TimeStamp] 	  	 DateTime 	 Null
)
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
SELECT
  @Rc = 0, 	 
  @Error 	 = '',
 	 @UserId = 1
-------------------------------------------------------------------------------
-- Read Event_Transactions record for the passed Id
-------------------------------------------------------------------------------
SELECT 	 @EventTimeStamp  	  	 = EventTimeStamp,
 	 @BatchName 	  	  	 = LTrim(RTrim(BatchName)),
 	 @ProcedureStartTime 	  	 = ProcedureStartTime,
 	 @ProcedureEndTime 	  	 = ProcedureEndTime,
 	 @RawMaterialProductCode 	  	 = LTrim(RTrim(RawMaterialProductCode)),
 	 @RawMaterialContainerId 	  	 = LTrim(RTrim(RawMaterialContainerId)),
 	 @RawMaterialBatchName 	  	 = LTrim(RTrim(RawMaterialBatchName)),
 	 @RawMaterialDimensionX 	  	 = RawMaterialDimensionX,
 	 @RawMaterialDimensionY 	  	 = RawMaterialDimensionY,
 	 @RawMaterialDimensionZ 	  	 = RawMaterialDimensionZ,
 	 @RawMaterialDimensionA 	  	 = RawMaterialDimensionA,
 	 @ProcedureName 	  	  	  	 = UnitProcedureName,
  	 @BatchInstance 	  	  	  	 = BatchInstance,
 	 @UnitProcedureInstance = 	  UnitProcedureInstance
 	 FROM 	 Event_Transactions 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
-------------------------------------------------------------------------------
-- Check record
-------------------------------------------------------------------------------
IF 	 @BatchName = '' SELECT 	 @BatchName = Null
IF 	 @RawMaterialProductCode = '' SELECT 	 @RawMaterialProductCode = Null
IF 	 @RawMaterialContainerId = '' SELECT 	 @RawMaterialContainerId = Null
IF 	 @RawMaterialBatchName = '' SELECT 	 @RawMaterialBatchName = Null
If  	 @ProcedureName  = '' SELECT 	 @ProcedureName = Null
If @BatchName is not null AND @BatchInstance IS NOT NULL
BEGIN
  	  Select @BatchName =  @BatchName + '|' + CONVERT(nvarchar(10), @BatchInstance)
END
IF  @ProcedureName is not null AND @UnitProcedureInstance IS NOT NULL
BEGIN
 	 SELECT @ProcedureName = @ProcedureName + ':' + CONVERT(nvarchar(10), @UnitProcedureInstance)
END
If @IsVirtualBatch = 0 and @BatchName is not null and @ProcedureName is not null
 	 Select @BatchName = 'U:' + @BatchName + '!' + @ProcedureName
If len(@BatchName) > 50
  BEGIN
 	 UPDATE 	 Event_Transactions 
 	   SET 	 OrphanedReason  	  	 = 'Warning - Batch Name Truncated - [' + @BatchName + '] > 50 characters'
 	   WHERE 	 EventTransactionId  	 = @EventTransactionId
 	 Select @BatchName = substring(@BatchName,1,50)
  END
If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, '@BatchName-' + @BatchName + ':@BatchUnitId -' + isnull(convert(nvarchar(10),@BatchUnitId),'Null') )
IF 	 @RawMaterialProductCode Is Null 
BEGIN
 	 SELECT 	 @Error = 'Missing Raw Material Product Code'
 	 GOTO 	 Errc
END
IF 	 @RawMaterialBatchName Is Null
BEGIN
 	 SELECT 	 @Error = 'Missing Raw Material Batch Name'
 	 GOTO 	 Errc
END
IF 	 @RawMaterialDimensionX Is Null
BEGIN
 	 SELECT 	 @Error  	  	  	  	 = 'Warning - Missing Raw Material Dimension X'
        UPDATE 	 Event_Transactions 
 	  	 SET 	 OrphanedReason  	  	 = @Error,
 	  	  	 OrphanedFlag 	  	 = 0 
 	  	 WHERE 	 EventTransactionId  	 = @EventTransactionId
 	 SELECT 	 @RawMaterialDimensionX = 0.0
END
-------------------------------------------------------------------------------
-- Check For existing input
-------------------------------------------------------------------------------
 	 
IF (Select Count(PEIS_Id)
  From PrdExec_Input_Sources pis
  Join PrdExec_Inputs p  On pis.PEI_Id = p.PEI_Id And p.PU_Id = @BatchUnitId
 	  	  	  	  	  	 and pis.PU_Id = @RawMaterialUnitId) = 0 
 	 BEGIN
 	  	 Select @InputName = PU_Desc From Prod_Units_Base where PU_Id = @RawMaterialUnitId
 	    	 Select @PEIId = p.PEI_Id
 	  	  	 From  PrdExec_Inputs p 
 	  	  	 Where p.PU_Id = @BatchUnitId and Input_Name = @InputName
 	  	 If @PEIId is null
 	  	   Begin
 	  	  	 Select @InputOrder = Max(Input_Order) + 1 from Prdexec_inputs Where PU_Id = @BatchUnitId
 	  	  	 Select @InputOrder = isnull(@InputOrder,1)
 	  	  	 Select @EventSubTypeId = Event_subtype_id
 	  	  	   From Event_Configuration 
 	  	  	   Where PU_Id = @BatchUnitId and ET_Id = 1
 	      	  	 Insert  into Prdexec_Inputs (input_name, input_order, pu_id, event_subtype_id, primary_spec_id, alternate_spec_id, lock_inprogress_input)
 	        	  	 values(@InputName, @InputOrder, @BatchUnitId, @EventSubtypeId, Null, Null, 1)
 	  	  	 Select @PEIId = PEI_Id from Prdexec_inputs Where  Input_Name = @InputName and PU_Id = @BatchUnitId
 	  	   End
 	  	 Insert into PrdExec_Input_Sources (PEI_Id, PU_Id)values(@PEIId, @RawMaterialUnitId)
 	 END
-------------------------------------------------------------------------------
-- Get Product
-------------------------------------------------------------------------------
SELECT 	 @RawMaterialProductdId = Null
EXEC 	 spCmn_ProductSearch @RawMaterialProductdId OUTPUT, @RawMaterialProductCode, Null,@DefaultDSId
IF 	 @RawMaterialProductdId Is Null
BEGIN
 	 EXEC 	 spEM_CreateProd  
 	  	 @RawMaterialProductCode,
 	  	 @RawMaterialProductCode,
 	  	 @DefaultProdFamily,
 	  	 @UserId, 
 	  	 0,--@Serialized
 	  	 @RawMaterialProductdId OUTPUT 
 	 IF 	 @RawMaterialProductdId Is Null
 	 BEGIN
 	  	 SELECT 	 @Error = 'Unable to create Product [' + @RawMaterialProductCode + ']'
 	  	 GOTO 	 Errc
 	 END
END
-------------------------------------------------------------------------------
-- Find Source Event 
-------------------------------------------------------------------------------
SELECT 	 @SourceId = Null
IF 	 @RawMaterialUnitId Is Not Null
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Search the Source Event based on PUId and EventNum  if Raw Material Unit was passed
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @SourceId  	  	 = Event_Id 
 	  	 FROM 	 Events 
 	  	 WHERE 	 Event_Num  	 = @RawMaterialBatchName 
 	  	 AND 	 PU_Id 	  	 = @RawMaterialUnitId
 	 IF 	 @SourceId Is Null
 	 BEGIN
 	  	 -------------------------------------------------------------------------------
 	  	 -- Create RM (Raw Material) event
 	  	 -------------------------------------------------------------------------------
 	  	 -- Call SP server that adds the record to the Proficy Core tables
 	  	 -------------------------------------------------------------------------------
 	  	 EXEC 	 spServer_DBMgrUpdEvent  
 	  	  	 @SourceId  	  	 OUTPUT, 
 	  	  	 @RawMaterialBatchName,
 	  	  	 @RawMaterialUnitId,
 	  	  	 @EventTimeStamp,
 	  	  	 @RawMaterialProductdId,
 	  	  	 Null, 	 
 	  	  	 Null,
 	  	  	 1,
 	  	  	 0,
 	  	  	 @UserId,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 1,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 Null,
 	  	  	 1
/*
 	  	 -------------------------------------------------------------------------------
 	  	 -- Populate the temporary result set table
 	  	 -------------------------------------------------------------------------------
 	    	 INSERT 	 #EventUpdates (Id, Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Applied_Product,
 	  	  	  	        Source_Event, Event_Status, Confirmed, User_Id, Post_Update, Conformance,
 	  	  	  	        TestPctComplete, Start_Time, TransNum, TestingStatus, CommentId, EventSubTypeId,
 	  	  	  	        EntryOn)
 	  	  	 VALUES (1, 1, @SourceId, @RawMaterialBatchName, @RawMaterialUnitId, @EventTimeStamp, Null, Null, 5, 1,
 	  	  	  	 @UserId, 1, Null, Null, Null, 0, Null, Null, 1, Null)
*/
 	 END
END
ELSE
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Search the Source Event based on the EventNum  if Raw Material Unit was not passed
 	 -------------------------------------------------------------------------------
  Select @SourceCount = 0, @SourceId = NULL
 	 SELECT 	 @SourceCount = Count(Event_Id), @SourceId = min(Event_Id) 
 	  	 FROM 	 Events 
 	  	 WHERE 	 event_Num = @RawMaterialBatchName
 	 IF 	 @SourceCount > 1
 	 BEGIN 	 
 	  	 SELECT 	 @Error = 'Unable to find unique raw material batch [' + @RawMaterialBatchName + ']'
 	  	 GOTO 	 Errc
 	 END
 	 ELSE 
 	 IF 	 @SourceCount = 1
 	 BEGIN
 	  	 SELECT 	 @SourceId = @SourceId --already set 
 	 END
  ELSE -- @SourceCount = 0
 	 BEGIN
 	  	 SELECT 	 @Error = 'No Raw Material Batch Found, And No Unit Found For [' + @RawMaterialBatchName + ']'
 	  	 GOTO 	 Errc
 	 END
END
-------------------------------------------------------------------------------
-- Find Destination Event 
-------------------------------------------------------------------------------
IF 	 @BatchName is Not Null 
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Process Main Batch
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @EventId  	  	 = Event_Id 
 	  	 FROM 	 Events 
 	  	 WHERE 	 Event_Num  	 = @BatchName 
 	  	 AND 	 PU_Id 	  	 = @BatchUnitId
END
ELSE
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Find Current Batch 
 	 -------------------------------------------------------------------------------
  Select @MaxTS = coalesce(@ProcedureEndTime, @EventTimeStamp)
 	 SELECT 	 @MaxTS  	  	 = Max(TimeStamp) 
 	  	 FROM 	 Events 
 	  	 WHERE 	 PU_Id  	 = @BatchUnitId and
          Timestamp <= @MaxTs
 	 SELECT 	 @EventId 	 = Event_Id,
 	  	 @BatchName  	 = Event_Num 
 	  	 FROM 	 Events 
 	  	 WHERE 	 TimeStamp  	 = @MaxTS 
 	  	 AND 	 PU_Id  	  	 = @BatchUnitId 
 	 IF 	 @EventId Is Null
 	 BEGIN
 	  	 SELECT 	 @Error = 'Unable to find current batch to establish link'
 	  	 GOTO 	 Errc
 	 END
END
IF 	 @EventId Is Null 
BEGIN
 	 SELECT 	 @Error = 'Unable to find batch to establish link'
 	 GOTO 	 Errc
END
-------------------------------------------------------------------------------
-- 
-- If S88 sees an ProcedureEndTime, it means it needs to update the timestamp
-- column for an EXISTING EC record. The below routine finds the youngest
-- 'open' record for the sourceId/EventId combination and sets some variables
-- so when the spServer is called, it updates the existing record instead 
-- create a new one.
-- I used max(start_time) because in theory you could have multiple 'open'
-- ec records (without timestamp)  for the same sourceId/eventId combination 
-- since the spServer does not check for existing records based on the starttime
-------------------------------------------------------------------------------
SELECT 	 @TransType 	 = 1
IF 	 @ProcedureEndTime Is Not Null AND 	 @ProcedureStartTime 	 Is Null
BEGIN
 	 SELECT 	 @StartTime 	 = Max(Start_Time)
 	  	 FROM 	 Event_Components
 	  	 WHERE 	 Source_Event_Id 	 = @SourceId
 	  	 AND 	 Event_Id 	 = @EventId
 	  	 AND 	 TimeStamp 	 = Start_Time
 	 IF 	 @StartTime Is Null
 	 BEGIN
 	     Select @Error = 'Could not find specific Genealogy Link to update end time for'
 	     Goto Errc
 	 END
 	 SELECT 	 @ECId 	  	  	 = Component_Id,
 	  	 @ProcedureStartTime 	 = Start_Time
 	  	 FROM 	 Event_Components
 	  	 WHERE 	 Source_Event_Id 	 = @SourceId
 	  	 AND 	 Event_Id 	 = @EventId
 	  	 AND 	 Start_Time 	 = @StartTime 	 
 	 SELECT 	 @TransType 	  	 = 2
END
-------------------------------------------------------------------------------
-- Call SpServer that will add a record to the event_components table
--
-- Modified to:
-- pass the ProcedureStartTime (StartTime) and ProcedureEndTime (TimeStamp) to 
-- the spServer send these 2 columns on the real-time message (added to the temp 
--table too)
--------------------------------------------------------------------------------
EXEC 	 spServer_DBMgrUpdEventComp 
 	 @UserId,
 	 @EventId,
 	 @ECId 	 OUTPUT,
 	 @SourceId,
 	 @RawMaterialDimensionX,
 	 @RawMaterialDimensionY,
 	 @RawMaterialDimensionZ,
 	 @RawMaterialDimensionA,
 	 0,
 	 @TransType,
 	 Null,
 	 Null,
 	 Null,
 	 Null,
 	 Null,
 	 @ProcedureStartTime, 
 	 @ProcedureEndTime
INSERT 	 #EventComp(Pre, UserId, TransType, TransNum, ComponentId, EventId, 
 	  	    SrcEventId, DimX, DimY, DimZ, DimA, StartCoordinateX, StartCoordinateY,
 	  	    StartCoordinateZ, StartCoordinateA, StartTime, TimeStamp) 
 	 VALUES 	 (0, 1, @TransType, 0, @ECId, @EventId, @SourceId, @RawMaterialDimensionX,
 	  	 @RawMaterialDimensionY, @RawMaterialDimensionZ, @RawMaterialDimensionA, Null,
 	         Null, Null, Null, @ProcedureStartTime, @ProcedureEndTime)
---------------------------------------------------------------------------------------------------
-- Return Real-Time Updates
--------------------------------------------------------------------------------------------------
/*
IF 	 (SELECT Count(*) 
 	  	 FROM #EventUpdates) > 0
 	 SELECT 	 1,* 
 	  	 FROM #EventUpdates
*/
IF 	 (SELECT Count(*) 
 	  	 FROM 	 #EventComp) > 0
 	 SELECT 	 11,Pre,UserId,TransType,TransNum,ComponentId,EventId,SrcEventId,DimX,DimY,DimZ,DimA,StartCoordinateX,StartCoordinateY,StartCoordinateZ,StartCoordinateA,StartTime,[TimeStamp]
 	  	 FROM #EventComp
Finish:
---------------------------------------------------------------------------------------------------
-- Normal Exit
--------------------------------------------------------------------------------------------------
Select @Rc = 1
If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessMaterialMovement)')
RETURN(@Rc)
---------------------------------------------------------------------------------------------------
-- Error Handling
--------------------------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	 = coalesce(OrphanedReason, @Error),
 	  	 OrphanedFlag  	 = 1 
 	 WHERE 	 EventTransactionId = @EventTransactionId
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessMaterialMovement)')
Return (-100)
