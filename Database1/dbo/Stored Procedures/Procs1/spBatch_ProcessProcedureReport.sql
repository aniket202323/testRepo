CREATE 	 PROCEDURE dbo.spBatch_ProcessProcedureReport 
 	 @EventTransactionId 	 Int,
 	 @BatchUnitId 	  	 Int,
 	 @BatchProcedureUnitId 	  	 Int,
 	 @ProcedureUnitId 	  	 Int,
 	 @BatchProcedureGroupId 	  	 Int,
 	 @UserId 	  	  	 Int,
 	 @SecondUserId  	  	 Int,
 	 @DefaultProdFamily 	 int,
 	 @DefaultDSId 	  	 Int,
 	 @Debug int = NULL
AS
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
-------------------------------------------------------------------------------
-- Declare General Variables
-------------------------------------------------------------------------------
DECLARE 	 @EventTimeStamp 	  	  	  	  	  	  	 DateTime,
 	 @BatchName 	  	  	  	  	  	  	  	  	  	  	  	 nvarchar(50),
 	 @BatchInstance 	  	  	  	  	  	  	  	  	  	 Int,
 	 @BatchProductCode 	  	  	  	  	  	  	  	  	 nvarchar(25),
 	 @BatchProductId 	  	  	  	  	  	  	  	  	  	 Int,
 	 @UnitProcedureName 	  	  	  	  	  	  	  	 nvarchar(50),
 	 @UnitProcedureInstance 	  	  	  	  	  	 Int,
 	 @OperationName 	  	  	  	  	  	  	  	  	  	 nvarchar(50),
 	 @OperationInstance 	  	  	  	  	  	  	  	 Int,
 	 @PhaseName 	  	  	  	  	  	  	  	  	  	  	  	 nvarchar(50),
 	 @PhaseInstance 	  	  	  	  	  	  	  	  	  	 Int,
 	 @StateValue 	  	  	  	  	  	  	  	  	  	  	  	 nvarchar(50),
 	 @ProcedureStartTime 	  	  	  	  	  	  	  	 DateTime,
 	 @ProcedureEndTime 	  	  	  	  	  	  	  	  	 DateTime,
 	 @RawMaterialProductCode 	  	  	  	  	  	 nvarchar(25),
 	 @RawMaterialProductId 	  	  	  	  	  	  	 Int,
 	 @Error 	  	  	  	  	  	  	  	  	  	  	  	  	  	 nvarchar(255),
 	 @ProcedureStatusId 	  	  	  	  	  	  	  	 Int,
 	 @RC 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Int,
 	 @TransactionId 	  	  	  	  	  	  	  	  	  	 Int,
 	 @TransactionDesc 	  	  	  	  	  	  	  	  	 nvarchar(255),
 	 @Id 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Int,
 	 @BatchAssociated 	  	  	  	  	  	  	  	  	 Int,
 	 @UPAssociated 	  	  	  	  	  	  	  	  	  	  	 Int,
 	 @ProcessOrderId 	  	  	  	  	  	  	  	  	  	 int,
 	 @InitialDimensionX 	  	  	  	  	  	  	  	 float,
 	 @InitialDimensionY 	  	  	  	  	  	  	  	 float,
 	 @InitialDimensionZ 	  	  	  	  	  	  	  	 float,
 	 @InitialDimensionA 	  	  	  	  	  	  	  	 float,
 	 @FinalDimensionX 	  	  	  	  	  	  	  	 float,
 	 @FinalDimensionY 	  	  	  	  	  	  	  	 float,
 	 @FinalDimensionZ 	  	  	  	  	  	  	  	 float,
 	 @FinalDimensionA 	  	  	  	  	  	  	  	 float,
 	 @EventSubtype 	  	  	  	  	  	  	  	  	 nvarchar(50),
 	 @LotIdentifier 	  	  	  	  	  	  	  	  	 nVarChar(100),
 	 @FriendlyOperationName 	  	  	  	  	  	  	 nVarChar(100)
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START (spBatch_ProcessProcedureReport)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_ProcessProcedureReport /EventTransactionId: ' + Isnull(convert(nvarchar(10),@EventTransactionId),'Null') + ' /BatchUnitId: ' + isnull(convert(nvarchar(10),@BatchUnitId),'Null') + 
 	 ' /BatchProcedureUnitId: ' + isnull(convert(nvarchar(10),@BatchProcedureUnitId),'Null') + ' /ProcedureUnitId: ' + isnull(convert(nvarchar(10),@ProcedureUnitId),'Null') + 
 	 ' /BatchProcedureGroupId: ' + isnull(convert(nvarchar(10),@BatchProcedureGroupId),'Null') +  	 ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null') + 
  ' /SecondUserId: ' + isnull(convert(nvarchar(10),@SecondUserId),'Null') + ' /Debug: ' + isnull(convert(nvarchar(10),@Debug),'Null'))
  End
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
Select @Error = ''
Select @Rc = 0
-------------------------------------------------------------------------------
-- Load Variables with the Event_Transactions record being processed
-------------------------------------------------------------------------------
SELECT 	 @EventTimeStamp  	  	 = EventTimeStamp,
 	  	  	  	 @BatchName 	  	  	 = LTrim(RTrim(BatchName)),
 	  	  	  	 @BatchProductCode 	  	 = LTrim(RTrim(BatchProductCode)),
 	  	  	  	 @UnitProcedureName 	  	 = LTrim(RTrim(UnitProcedureName)),
 	  	  	  	 @OperationName 	  	  	 = LTrim(RTrim(OperationName)),
 	  	  	  	 @PhaseName 	  	  	 = LTrim(RTrim(PhaseName)),
 	  	  	  	 @PhaseInstance 	  	  	 = PhaseInstance,
 	  	  	  	 @StateValue 	  	  	 = LTrim(RTrim(StateValue)),
 	  	  	  	 @ProcedureStartTime 	  	 = ProcedureStartTime,
 	  	  	  	 @ProcedureEndTime 	  	 = ProcedureEndTime,
 	  	  	  	 @RawMaterialProductCode 	  	  	 = LTrim(RTrim(RawMaterialProductCode)),
 	  	  	  	 @BatchInstance = BatchInstance,
 	  	  	  	 @UnitProcedureInstance = UnitProcedureInstance,
 	  	  	  	 @OperationInstance = OperationInstance,
 	  	  	  	 @ProcessOrderId 	 = ProcessOrderId,
 	  	  	  	 @InitialDimensionX 	 = InitialDimensionX,
 	  	  	  	 @InitialDimensionY 	 = InitialDimensionY,
 	  	  	  	 @InitialDimensionZ 	 = InitialDimensionZ,
 	  	  	  	 @InitialDimensionA 	 = InitialDimensionA,
 	  	  	  	 @FinalDimensionX 	 = FinalDimensionX,
 	  	  	  	 @FinalDimensionY 	 = FinalDimensionY,
 	  	  	  	 @FinalDimensionZ 	 = FinalDimensionZ,
 	  	  	  	 @FinalDimensionA 	 = FinalDimensionA,
 	  	  	  	 @EventSubtype 	 = EventSubtype,
 	  	  	  	 @LotIdentifier 	 = LotIdentifier,
 	  	  	  	 @FriendlyOperationName 	 = FriendlyOperationName
 	 FROM 	 Event_Transactions 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
-------------------------------------------------------------------------------
-- Check record
-------------------------------------------------------------------------------
IF 	 @BatchName = '' SELECT 	 @BatchName = Null
IF 	 @BatchProductCode = '' SELECT 	 @BatchProductCode = Null
IF 	 @StateValue = '' SELECT 	 @StateValue = Null
IF 	 @RawMaterialProductCode = '' SELECT 	 @RawMaterialProductCode = Null
IF 	 @UnitProcedureName = '' SELECT 	 @UnitProcedureName = Null
IF 	 @OperationName = '' SELECT 	 @OperationName = Null
IF 	 @PhaseName = '' SELECT 	 @PhaseName = Null
IF 	 IsDate(@ProcedureStartTime) = 0 
 	 AND 	 @ProcedureStartTime Is Not Null 
 	 AND 	 @ProcedureStartTime <> ''
BEGIN
 	 SELECT 	 @Error = 'Bad Procedure Start Time[' + Convert(nvarchar(25),@ProcedureStartTime) + ']'
 	 GOTO 	 Errc
END
IF 	 IsDate(@ProcedureEndTime) = 0
 	 AND 	 @ProcedureEndTime is Not Null
 	 AND 	 @ProcedureEndTime <> ''
BEGIN
 	 SELECT 	 @Error = 'Bad Procedure End Time[' + Convert(nvarchar(25),@ProcedureEndTime) + ']'
 	 GOTO 	 Errc
END
IF 	 @StateValue Is Null
BEGIN
 	 SELECT 	 @Error = 'Missing State Value'
 	 GOTO 	 Errc
END
-------------------------------------------------------------------------------
-- Retrieve Production Status
-------------------------------------------------------------------------------
SELECT 	 @ProcedureStatusId = Null
SELECT 	 @ProcedureStatusId = ProdStatus_Id 
 	 FROM 	 Production_Status 
 	 WHERE 	 ProdStatus_Desc = @StateValue
IF 	 @ProcedureStatusId Is Null
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Create it, if not found
 	 -------------------------------------------------------------------------------
 	 EXEC 	 @ProcedureStatusId = spEMPSC_ProductionStatusConfigUpdate
 	  	 Null,
 	  	 84, --blue flag
 	  	 6,  -- Blue
 	  	 0,
 	  	 0,
 	  	 0,
 	  	 @StateValue
 	 IF 	 @ProcedureStatusId Is Null
 	 BEGIN
 	  	 SELECT 	 @Error = 'Unable to create State Value [' + @StateValue + ']'
 	  	 GOTO 	 Errc
 	 END
END
-------------------------------------------------------------------------------
-- Handle Raw Material (source) Product 
-------------------------------------------------------------------------------
IF 	 @RawMaterialProductCode Is Not Null
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Retrieve Raw Material (source) Product using the XRef Table, ProdCode and 
 	 -- ProdDesc
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @RawMaterialProductId = Null
 	 EXEC 	 spCmn_ProductSearch @RawMaterialProductId OUTPUT, @RawMaterialProductCode, Null,@DefaultDSId
 	 IF 	 @RawMaterialProductId Is Null
 	 BEGIN
 	  	 -------------------------------------------------------------------------------
 	  	 -- If not found: Create the Raw Material (source) Product and associate
 	  	 -- with the Raw Production Unit
 	  	 -------------------------------------------------------------------------------
 	  	 --  Create the Raw Material (source) Product
 	  	 -------------------------------------------------------------------------------
 	  	 EXEC 	 spEM_CreateProd  
 	  	  	 @RawMaterialProductCode,
 	  	  	 @RawMaterialProductCode,
 	  	  	 @DefaultProdFamily,
 	  	  	 @UserId, 
 	  	  	 0,--@Serialized
 	  	  	 @RawMaterialProductId 	 OUTPUT 
 	   IF 	 @RawMaterialProductId Is Null
 	  	 BEGIN
 	  	  	 SELECT 	 @Error = 'Unable to create Raw Material Product [' + @RawMaterialProductCode + ']'
 	  	  	 GOTO 	 Errc
 	  	 END
 	 END
END
-------------------------------------------------------------------------------
-- Handle Material Product 
-------------------------------------------------------------------------------
IF @BatchProductCode Is Not Null
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Retrieve Product using the Product Code
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @BatchProductId = Null
 	 EXEC 	 spCmn_ProductSearch @BatchProductId OUTPUT, @BatchProductCode, Null,@DefaultDSId
 	 IF 	 @BatchProductId Is Null
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- If not found: Create Product and associate with the Raw Production Unit
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 --  Create the Material Product
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 EXEC 	 spEM_CreateProd  
 	  	  	  	 @BatchProductCode,
 	  	  	  	 @BatchProductCode,
 	  	  	  	 @DefaultProdFamily,
 	  	  	  	 @UserId, 
 	  	  	  	 0,--@Serialized
 	  	  	  	 @BatchProductId  	  	 OUTPUT 
 	  	   IF 	 @BatchProductId Is Null
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT 	 @Error = 'Unable to create Product [' + @BatchProductCode + ']'
 	  	  	     	  	 GOTO 	 Errc
 	  	       	 END
 	  	 End
 	 Select @UPAssociated = Null,@BatchAssociated = Null
 	 If @BatchProcedureUnitId is Null
 	  	 Select @UPAssociated 	 = 1
 	 Else
 	  	 Select @UPAssociated 	 = PU_Id From pu_Products Where Prod_Id = @BatchProductId and PU_Id = @BatchProcedureUnitId
 	 Select @BatchAssociated 	 = PU_Id From pu_Products Where Prod_Id = @BatchProductId and PU_Id = @BatchUnitId
 	 If @Debug = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adding Product:' + @BatchProductCode)
 	 IF 	 (@UPAssociated Is Null) Or (@BatchAssociated Is Null)
 	  	 BEGIN
 	  	 -------------------------------------------------------------------------------
 	  	 -- Associate the product with the PUId
 	  	 -------------------------------------------------------------------------------
 	  	 -------------------------------------------------------------------------------
 	  	 -- Create new PU_product transaction
 	  	 -------------------------------------------------------------------------------
 	  	 SELECT 	 @RC 	  	  	 = 0,
 	  	  	 @TransactionId 	  	 = Null,
 	  	  	 @TransactionDesc 	 = 'S88-Id: ' + Convert(nvarchar(10), Coalesce(@EventTransactionId,0))  	 + '-'  + Convert(nvarchar(25), dbo.fnServer_CmnGetDate(getUTCdate()), 120) 	 
 	  	 EXEC 	 @RC 	 = spEM_CreateTransaction 
 	  	  	  	 @TransactionDesc,  	 
 	  	  	  	 Null, 	  	  	 -- @Corp_Trans_Id  	 Int,
 	  	  	  	 1 	  	 ,  	 -- @Trans_Type 	  	 Int,
 	  	  	  	 Null, 	  	  	 -- @Corp_Trans_Desc 	 nvarchar(25),
 	  	  	  	 @UserId, 	  	 -- @User_Id
 	  	  	  	 @TransactionId OUTPUT 	 -- @Trans_Id 	  	 Int 	 Output
 	  	 IF 	 @TransactionId 	 Is Null
 	  	 BEGIN
 	  	  	 SELECT 	 @Error = 'Unable to create PU/Product transaction header'
 	  	  	 GOTO 	 Errc
 	  	 END
 	  	 If @Debug = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adding Product to:' + Convert(nvarchar(10),@BatchUnitId))
 	  	 -------------------------------------------------------------------------------
 	  	 -- Create PU/Product detail record on Trans_Products table
 	  	 -------------------------------------------------------------------------------
 	  	 SELECT 	 @RC 	 = 0
 	  	 EXEC 	 @RC  	 = spEM_PutTransProduct
 	  	  	 @TransactionId, 	 -- @Trans_Id 	 Int,
 	  	  	 @BatchProductId, 	 -- @Prod_Id  	 Int,
 	  	  	 @BatchUnitId, 	 -- @Unit_Id 	 Int,
 	  	  	 0, 	  	 -- @IsDelete 	 nvarchar(25),
 	  	  	 @UserId 	  	 -- @User_Id 	 Int
 	  	 If @UPAssociated is null
 	  	  	 Begin
 	  	  	  	 If @Debug = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adding Product to:' + Convert(nvarchar(10),@BatchProcedureUnitId))
 	  	    	 EXEC 	 @RC  	 = spEM_PutTransProduct
 	  	  	  	  	  	  	 @TransactionId, 	 -- @Trans_Id 	 Int,
 	  	  	  	  	  	  	 @BatchProductId, 	 -- @Prod_Id  	 Int,
 	  	  	  	  	  	  	 @BatchProcedureUnitId, 	 -- @Unit_Id 	 Int,
 	  	  	  	  	  	  	 0, 	  	 -- @IsDelete 	 nvarchar(25),
 	  	  	  	  	  	  	 @UserId 	  	 -- @User_Id 	 Int
 	  	  	 End
 	  	 -------------------------------------------------------------------------------
 	  	 -- Approve PU/Product transaction
 	  	 -------------------------------------------------------------------------------
 	  	 SELECT 	 @RC 	  	  	 = 0
 	  	  	 EXEC 	 @RC 	  = spEM_ApproveTrans
 	  	  	 @TransactionId, 	   	 -- @Trans_Id 	  	 Int,
 	  	  	 @UserId, 	  	 -- @User_Id 	  	 Int
 	  	  	 1, 	  	  	 -- @Group_Id  	  	 Int,
 	  	  	 Null,  	  	  	 -- @Deviation_Date 	 DateTime,
 	  	  	 @EventTimeStamp, 	 -- @Approved_Date 	 DateTime,
 	  	  	 @EventTimeStamp 	  	 -- @Effective_Date 	 DateTime 	 
  END
END
-------------------------------------------------------------------------------
-- Add Status to Units if necessary
-------------------------------------------------------------------------------
Declare @StatusCheck Int
Select @StatusCheck = null
Select @StatusCheck = PEXP_Id From prdexec_status
 	 Where pu_id = @BatchUnitId and  valid_status = @ProcedureStatusId
If @StatusCheck Is null
 	 Execute spEMEPC_ExecPathConfig_TableMod 20,@BatchUnitId,0,@ProcedureStatusId,0,'',1
Select @StatusCheck = null
Select @StatusCheck = PEXP_Id From prdexec_status
 	 Where pu_id = @BatchProcedureUnitId and  valid_status = @ProcedureStatusId
If @StatusCheck Is null
 	 Execute spEMEPC_ExecPathConfig_TableMod 20,@BatchProcedureUnitId,0,@ProcedureStatusId,0,'',1
-------------------------------------------------------------------------------
-- Call SP that handles Production Events
-------------------------------------------------------------------------------
EXEC 	 @RC = spBatch_CreateEvents
 	 @EventTransactionId,
 	 @BatchName,
 	 @BatchInstance, 	 
 	 @EventTimeStamp,
 	 @ProcedureEndTime,
 	 @ProcedureStartTime,
 	 @BatchUnitId,
 	 @BatchProductId,
 	 @UserId,
 	 @ProcedureStatusId,
 	 @UnitProcedureName,
 	 @UnitProcedureInstance, 	 
 	 @OperationName,
 	 @OperationInstance, 	 
 	 @PhaseName,
 	 @PhaseInstance, 	 
 	 @BatchProcedureUnitId,
 	 @BatchProcedureGroupId,
 	 Null,
 	 @ProcedureUnitId,
 	 @RawMaterialProductId,
 	 @SecondUserId,
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
 	 @EventSubtype,
 	 @LotIdentifier,
 	 @FriendlyOperationName
-------------------------------------------------------------------------------
-- Normal Exit
-------------------------------------------------------------------------------
If @Debug = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessProcedureReport)')
RETURN(@Rc)
-------------------------------------------------------------------------------
-- Handle exceptions
-------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	  	 = coalesce(OrphanedReason, @Error),
 	  	 OrphanedFlag 	  	 = 1 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
If @Debug = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessProcedureReport)')
If @Debug = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID,  @Error)
RETURN(-100)
