---------------------------------------------------------------------------------------------------
-- This SP is called from a model 602 or similar. It processes the records from the event_transaction
-- table. This intermediate table can have records added by S88 Compliants/non Compliants Batching
-- sytems.
-- This Stored Procedure calls other ones that will update some of the Proficy core tables such as
-- Events, Event_Components and Tests
---------------------------------------------------------------------------------------------------
CREATE 	 PROCEDURE 	 dbo.spBatch_CheckEventTable
 	 @ReturnStatus  	  	  	 Int  	  	  	  	  	 OUTPUT,
 	 @ReturnMessage 	  	  	 nvarchar(255)  	 OUTPUT,
 	 @EConfig_Id  	  	  	  	 Int,
 	 @ETId 	  	  	  	  	  	  	  	 Int 	  	 = Null
AS
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
-------------------------------------------------------------------------------
-- Declare General variables
-------------------------------------------------------------------------------
DECLARE 	 @EventTransactionId 	  	 Int,
 	 @EventType 	  	  	  	 nvarchar(20),
 	 @AreaName 	  	  	  	  	 nvarchar(100),
 	 @CellName 	  	  	  	  	 nvarchar(100),
 	 @UnitName 	  	  	  	  	 nvarchar(100),
 	 @RawMaterialAreaName 	  	 nvarchar(100),
 	 @RawMaterialCellName 	  	 nvarchar(100),
 	 @RawMaterialUnitName 	  	 nvarchar(100),
 	 @EventTimeStamp 	  	  	 DateTime,
 	 @BatchUnitId 	  	  	  	 Int,
 	 @BatchLineId 	  	  	  	 Int,
 	 @BatchDepartmentId 	  	  	 Int,
 	 @BatchProcedureUnitId 	  	 Int,
 	 @BatchProcedureGroupId 	  	 Int,
 	 @BatchProcedureOrder 	  	 Int,
 	 @RawMaterialLineId 	  	  	 Int,
 	 @RawMaterialUnitId 	  	  	 Int,
 	 @ProcedureUnitId 	  	  	 Int,
 	 @ProcedureLink 	  	  	  	 nvarchar(255),
 	 @UnitProcedureName 	  	  	 nvarchar(100),
 	 @OperationName 	  	  	  	 nvarchar(100),
 	 @PhaseName 	  	  	  	 nvarchar(100),
 	 @UserName 	  	  	  	  	 nvarchar(100),
 	 @UserSignature 	  	  	  	 nvarchar(100),
 	 @UserId 	  	  	  	  	 Int,
 	 @SecondUserId 	  	  	  	 Int,
 	 @DestPUId 	  	  	  	 Int,
 	 @IsVirtualBatch 	  	  	 Bit
Declare
 	 @UnitDescription    nvarchar(255),
 	 @Count 	  	  	 Int,
 	 @EC_Id 	  	  	 Int,
 	 @ECV_Id 	  	  	 Int,
 	 @Value 	  	  	 int,
 	 @DelayTime 	  	 nvarchar(15)
Declare
 	 @Error 	  	  	  	  	  	  	 nvarchar(255),
 	 @Rc 	  	  	  	  	  	  	  	 int,
 	 @AutoConfigure 	  	  	  	  	  	 int,
 	 @Debug 	  	  	  	  	  	  	 int,
 	 @PurgeProcessedDays 	  	  	  	  	 int,
 	 @PurgeOrphanedDays 	  	  	  	  	 int,
 	 @WaitMilliseconds 	  	  	  	  	 int,
 	 @ID 	  	  	  	  	  	  	  	 int,
 	 @ActualBatchUnitId 	  	  	  	  	 Int,
 	 @GroupName  	  	  	  	  	  	 nvarchar(50),
 	 @DefProdFamilyId 	  	  	  	  	 Int,
 	 @DefDataSourceId 	  	  	  	  	 Int,
 	 @RawProdFamilyId 	  	  	  	  	 Int,
 	 @RawDataSourceId 	  	  	  	  	 Int,
 	 @MyUnitProcedureName 	  	  	  	 nvarchar(100),
 	 @EventTransLoopEnd 	  	  	  	  	 Int,
 	 @CurEventTransId 	  	  	  	  	 Int,
 	 @SkipUnitChecks 	  	  	  	  	  	 Int = 0
 	 
SELECT 	 @ReturnStatus = 1,
 	 @ReturnMessage = ''
-------------------------------------------------------------------------------
-- If there's nothing to do, just get out quickly
-------------------------------------------------------------------------------
--converted "*" into "1" 
--To support the query Create nonclustered index ix_Event_Transactions_ProcFlg_Orpflg on Event_Transactions(ProcessedFlag,OrphanedFlag)
IF (not exists(SELECT 1 FROM Event_Transactions  with (nolock) WHERE ProcessedFlag = 0 AND OrphanedFlag = 0))
 	 Return
-------------------------------------------------------------------------------
-- Initialize variables, set defaults
-------------------------------------------------------------------------------
Declare @ClearAppliedProductIfSame int,
 	    @ParmId Int
Select @ClearAppliedProductIfSame=CONVERT(INT,Value) from Site_Parameters Where Parm_Id = 188
If (Select Isnull(@ClearAppliedProductIfSame,1)) = 1
BEGIN
 	 Select @ParmId = Parm_Id from Parameters Where Parm_Id = 188
 	 If @ParmId Is Null
 	 BEGIN
 	  	 Select @ReturnMessage = 'Unable To Find Site Parameter 188'
 	 END
 	 ELSE
 	 BEGIN
 	  	 Select @ParmId = Null
 	  	 Select @ParmId = Parm_Id from Site_Parameters Where Parm_Id = 188 and HostName = ''
 	  	 If @ParmId Is Null
 	  	 BEGIN
 	  	  	 Insert Into Site_Parameters(Parm_Id,HostName,Value,Parm_Required)Values(188,'','0',0)
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 Update Site_Parameters set Value = '0' Where Parm_Id = 188 and HostName = ''
 	  	 END
 	 END
END
Select  
 	 @AutoConfigure = 1,
 	 @PurgeProcessedDays 	 = 0,
 	 @PurgeOrphanedDays = 0,
 	 @WaitMilliseconds = 0,
 	 @DefProdFamilyId = 1
-- When Run Directly (Not Through Model, Turn On Debug
Select @Debug = Case When @EConfig_Id Is Null Then 1 Else 0 End
--Select @Debug = 1 
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) 
 	  	 Select dbo.fnServer_CmnGetDate(getUTCdate())
 	 Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START(spBatch_CheckEventTable)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_CheckEventTable /EConfig_Id: ' + Isnull(convert(nvarchar(10),@EConfig_Id),'Null') +
   	  	  	  	  	 ' /ETId: ' + Isnull(convert(nvarchar(10),@ETId),'Null'))
  End
-------------------------------------------------------------------------------
-- Retrieve Model Parameters For This Model To Override Default Settings
-------------------------------------------------------------------------------
If @EConfig_Id Is Not Null
BEGIN
 	 -- stored in the Site Parameters 
 	 SELECT 	 @Value = Null
 	 SELECT 	 @Value = Convert(int,convert(nvarchar(10), Value)) 
 	  	 FROM 	 Site_Parameters 
 	  	 WHERE 	 Parm_Id = 500
 	 SELECT @AutoConfigure = coalesce(@Value, @AutoConfigure)
 	 -- Go After Purge (Orphaned) Days      
 	 SELECT 	 @Value = Null
 	 SELECT 	 @Value = Convert(int,convert(nvarchar(10), Value)) 
 	  	 FROM 	 Site_Parameters 
 	  	 WHERE 	 Parm_Id = 501
     SELECT @PurgeOrphanedDays = coalesce(@Value, @PurgeOrphanedDays)
      -- Go After Purge (Processed) Days
 	 SELECT 	 @Value = Null
 	 SELECT 	 @Value = Convert(int,convert(nvarchar(10), Value)) 
 	  	 FROM 	 Site_Parameters 
 	  	 WHERE 	 Parm_Id = 502
     SELECT @PurgeProcessedDays = coalesce(@Value, @PurgeProcessedDays)
     -- Go After Wait Time (In Between Transactions)
 	 SELECT 	 @Value = Null
 	 SELECT 	 @Value = Convert(int,convert(nvarchar(10), Value)) 
 	  	 FROM 	 Site_Parameters 
 	  	 WHERE 	 Parm_Id = 503
     SELECT @WaitMilliseconds = coalesce(@Value, @WaitMilliseconds)
      -- Go After Product Family
 	 SELECT 	 @Value = Null
 	 SELECT 	 @Value = Convert(int,convert(nvarchar(10), Value)) 
 	  	 FROM 	 Site_Parameters 
 	  	 WHERE 	 Parm_Id = 504
     SELECT @DefProdFamilyId = coalesce(@Value, @DefProdFamilyId)
      -- Go After Data Source
 	 SELECT 	 @Value = Null
 	 SELECT 	 @Value = Convert(int,convert(nvarchar(10), Value)) 
 	  	 FROM 	 Site_Parameters 
 	  	 WHERE 	 Parm_Id = 505
 	 If @Value = 0 Select @Value = null
     SELECT @DefDataSourceId = @Value
END
-------------------------------------------------------------------------------
-- Create temporary tables
-------------------------------------------------------------------------------
Declare @CurrentModels Table
(
 	 EC_ID 	  	  	 Int NULL,
 	 PUID  	  	  	 Int,
 	 Area  	  	  	 nvarchar(100) 	 Null,
 	 Cell  	  	  	 nvarchar(100)  	 Null,
 	 Unit  	  	  	 nvarchar(100)  	 Null,
 	 ProcedureUnitId 	 Int  	  	 Null,
 	 ProdFamilyId 	  	 Int 	  	 Null,
 	 DataSourceId 	  	 Int 	  	 Null
)
Declare @Event_Trans Table
(
 	 ETransId int Identity(1,1),
 	 EventTransactionId 	 Int,
 	 EventType 	  	  	 nvarchar(20),
 	 EventTimeStamp 	  	 DateTime,
 	 AreaName 	  	  	 nvarchar(100),
 	 CellName 	  	  	 nvarchar(100),
 	 UnitName 	  	  	 nvarchar(100),
 	 UnitProcedureName 	 nvarchar(100),
 	 OperationName 	  	 nvarchar(100),
 	 PhaseName 	  	  	 nvarchar(100),
 	 RawMaterialAreaName 	 nvarchar(100),
 	 RawMaterialCellName 	 nvarchar(100),
 	 RawMaterialUnitName 	 nvarchar(100),
 	 UserName 	  	  	 nvarchar(100),
 	 UserSignature 	  	 nvarchar(100)
)
-------------------------------------------------------------------------------
-- Load temporary table with all 118 instances (where to get Area/Cell/Unit info)
-------------------------------------------------------------------------------
INSERT 	 @CurrentModels 	 (Ec_Id,PUId)
 	 SELECT 	 Ec_Id,PU_Id 
 	 FROM 	 Event_Configuration 
 	 WHERE 	 ED_Model_Id = 100
-------------------------------------------------------------------------------
-- Loop through each found model 100 (model 118)
-------------------------------------------------------------------------------
DECLARE 	 EventConfig Cursor FOR
 	 SELECT 	 EC_ID,PU_Id 
 	 FROM 	 Event_Configuration 
 	 WHERE 	 ED_Model_Id = 100
OPEN 	 EventConfig
FETCH 	 NEXT FROM EventConfig INTO @EC_Id, @BatchUnitId
WHILE 	 @@Fetch_Status 	 = 0
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Retrieve the Area, Cell and Unit model parameters for each instance
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @Ecv_Id = Null
 	 SELECT 	 @Ecv_Id = Ecv_Id 
 	  	 FROM 	 Event_Configuration_Data 
 	  	 WHERE 	 Ec_ID = @EC_Id 
 	  	 AND 	 Ed_Field_Id = 2767
 	 UPDATE 	 @CurrentModels 
 	  	 SET 	 Area = 
 	  	  	 (SELECT 	 Convert(nvarchar(50),Value) 
 	  	  	  	 FROM 	 Event_Configuration_Values 
 	  	  	  	 WHERE 	 Ecv_Id = @Ecv_Id) 
 	  	 WHERE 	 Ec_ID = @EC_Id
 	 SELECT 	 @Ecv_Id = Null
 	 SELECT 	 @Ecv_Id = Ecv_Id 
 	  	 FROM 	 Event_Configuration_Data 
 	  	 WHERE 	 Ec_ID = @EC_Id 
 	  	 AND 	 Ed_Field_Id = 2768
 	 UPDATE 	 @CurrentModels 
 	  	 SET 	 Cell = 
 	  	  	 (SELECT 	 Convert(nvarchar(50),Value) 
 	  	  	  	 FROM 	 Event_Configuration_Values 
 	  	  	  	 WHERE 	 Ecv_Id = @Ecv_Id) 
 	  	 WHERE 	 Ec_ID = @EC_Id
 	 SELECT 	 @Ecv_Id = Null
 	 SELECT 	 @Ecv_Id = Ecv_Id 
 	  	 FROM 	 Event_Configuration_Data 
 	  	 WHERE 	 Ec_ID = @EC_Id 
 	  	 AND 	 Ed_Field_Id = 2769
 	 UPDATE 	 @CurrentModels 
 	  	 SET 	 Unit = 
 	  	  	 (SELECT 	 Convert(nvarchar(50),Value) 
 	  	  	  	 FROM 	 Event_Configuration_Values 
 	  	  	  	 WHERE 	 Ecv_Id = @Ecv_Id) 
 	  	 WHERE 	 Ec_ID = @EC_Id
 	 SELECT 	 @Ecv_Id = Null
 	 SELECT 	 @Ecv_Id = Ecv_Id 
 	  	 FROM 	 Event_Configuration_Data 
 	  	 WHERE 	 Ec_ID = @EC_Id 
 	  	 AND 	 Ed_Field_Id = 2819
 	 UPDATE 	 @CurrentModels 
 	  	 SET 	 ProdFamilyId = 
 	  	  	 (SELECT 	 Convert(Int,Convert(nvarchar(10),Value)) 
 	  	  	  	 FROM 	 Event_Configuration_Values 
 	  	  	  	 WHERE 	 Ecv_Id = @Ecv_Id) 
 	  	 WHERE 	 Ec_ID = @EC_Id
 	 SELECT 	 @Ecv_Id = Null
 	 SELECT 	 @Ecv_Id = Ecv_Id 
 	  	 FROM 	 Event_Configuration_Data 
 	  	 WHERE 	 Ec_ID = @EC_Id 
 	  	 AND 	 Ed_Field_Id = 2820
 	 UPDATE 	 @CurrentModels 
 	  	 SET 	 DataSourceId = 
 	  	  	 (SELECT 	 Convert(Int,Convert(nvarchar(10),Value)) 
 	  	  	  	 FROM 	 Event_Configuration_Values 
 	  	  	  	 WHERE 	 Ecv_Id = @Ecv_Id) 
 	  	 WHERE 	 Ec_ID = @EC_Id
 	 FETCH 	 NEXT FROM EventConfig INTO @EC_Id, @BatchUnitId
END
CLOSE 	  	 EventConfig
DEALLOCATE 	 EventConfig
Update @CurrentModels Set ProdFamilyId = @DefProdFamilyId Where ProdFamilyId Is Null
Update @CurrentModels Set DataSourceId = @DefDataSourceId Where DataSourceId Is Null
-------------------------------------------------------------------------------
-- Remove model 118s not properly configured
-------------------------------------------------------------------------------
DELETE 	 @CurrentModels 
 	 WHERE 	 Area Is Null 
 	 OR 	 Cell Is 	 Null 
-------------------------------------------------------------------------------
-- Check whether there is something to process
-------------------------------------------------------------------------------
IF 	 (SELECT 	 Count(EventTransactionId) 
 	  	 FROM 	 Event_Transactions 
 	  	 WHERE 	 ProcessedFlag = 0 
 	  	 AND 	 OrphanedFlag = 0) > 0
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- read the single record passed as an input parameter when the sp is called
 	 -- by a model 601/603
 	 -------------------------------------------------------------------------------
 	 IF 	 @ETId 	 Is Not Null
 	 BEGIN
 	  	 -------------------------------------------------------------------------------
 	  	 -- Declare a cursor to read only the single record passed as input parameter
 	  	 -------------------------------------------------------------------------------
 	  	 Insert Into @Event_Trans (EventTransactionId,EventType,EventTimeStamp,AreaName,CellName,
 	  	  	  	  	  	  	 UnitName,UnitProcedureName,OperationName,PhaseName,RawMaterialAreaName,
 	  	  	  	  	  	  	 RawMaterialCellName,RawMaterialUnitName,UserName,UserSignature)
 	  	 SELECT 	 EventTransactionId, LTrim(RTrim(EventType)), EventTimeStamp, LTrim(RTrim(AreaName)), LTrim(RTrim(CellName)),
 	  	  	  	 LTrim(RTrim(UnitName)), LTrim(RTrim(UnitProcedureName)), LTrim(RTrim(OperationName)), LTrim(RTrim(PhaseName)),
 	  	  	  	 LTrim(RTrim(RawMaterialAreaName)), LTrim(RTrim(RawMaterialCellName)), LTrim(RTrim(RawMaterialUnitName)),
 	  	  	  	 LTrim(RTrim(UserName)), LTrim(RTrim(UserSignature))
 	  	   FROM 	 Event_Transactions
 	  	   WHERE EventTransactionId = @ETId AND ProcessedFlag = 0 AND OrphanedFlag = 0
 	 END
 	 ELSE
 	 BEGIN
 	  	 -------------------------------------------------------------------------------
 	  	 -- Declare a cursor to read up to 5000 records from the Event_Transactions_table
 	  	 -------------------------------------------------------------------------------
 	  	 Insert Into @Event_Trans (EventTransactionId,EventType,EventTimeStamp,AreaName,CellName,
 	  	  	  	  	  	  	 UnitName,UnitProcedureName,OperationName,PhaseName,RawMaterialAreaName,
 	  	  	  	  	  	  	 RawMaterialCellName,RawMaterialUnitName,UserName,UserSignature)
 	  	 SELECT 	 Top 1500 EventTransactionId, LTrim(RTrim(EventType)), EventTimeStamp, LTrim(RTrim(AreaName)), LTrim(RTrim(CellName)),
 	  	  	  	 LTrim(RTrim(UnitName)), LTrim(RTrim(UnitProcedureName)), LTrim(RTrim(OperationName)), LTrim(RTrim(PhaseName)),
 	  	  	  	 LTrim(RTrim(RawMaterialAreaName)), LTrim(RTrim(RawMaterialCellName)), LTrim(RTrim(RawMaterialUnitName)),
 	  	  	  	 LTrim(RTrim(UserName)), LTrim(RTrim(UserSignature))
 	  	   FROM 	 Event_Transactions
 	  	   WHERE ProcessedFlag = 0 AND OrphanedFlag = 0
 	  	   ORDER BY EventTimeStamp,EventTransactionId ASC
 	 END
 	 -------------------------------------------------------------------------------
 	 -- Loop through each Event_Transactions Record
 	 -------------------------------------------------------------------------------
 	 SET @CurEventTransId = 1
 	 SELECT  @EventTransLoopEnd = Max(ETransId) FROM @Event_Trans
 	 WHILE @CurEventTransId <= @EventTransLoopEnd
 	 BEGIN
 	  	 Select 	 @EventTransactionId = EventTransactionId, @EventType = EventType, @EventTimeStamp = EventTimeStamp,
 	  	  	  	 @AreaName = AreaName, @CellName = CellName, @UnitName = UnitName, @UnitProcedureName = UnitProcedureName,
 	  	  	  	 @OperationName = OperationName, @PhaseName = PhaseName, @RawMaterialAreaName = RawMaterialAreaName,
 	  	  	  	 @RawMaterialCellName = RawMaterialCellName, @RawMaterialUnitName = RawMaterialUnitName,
 	  	  	  	 @UserName = UserName, @UserSignature = UserSignature
 	  	   From @Event_Trans
 	  	   where ETransId = @CurEventTransId
 	     If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Processing Id = ' + convert(nvarchar(10),@EventTransactionId))
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Check data consistency
 	  	  	 -------------------------------------------------------------------------------
 	     If Ltrim(rtrim(@AreaName))  	  	  	  	 = '' Select @AreaName = NULL
 	     If Ltrim(rtrim(@CellName))  	  	  	  	 = '' Select @CellName = NULL
 	     If Ltrim(rtrim(@UnitName))  	  	  	  	 = '' Select @UnitName = NULL
 	     If Ltrim(rtrim(@UnitProcedureName))  	 = '' Select @UnitProcedureName = NULL
 	     If Ltrim(rtrim(@OperationName))  	  	 = '' Select @OperationName = NULL
 	     If Ltrim(rtrim(@PhaseName))  	  	  	 = '' Select @PhaseName = NULL
 	     If Ltrim(rtrim(@RawMaterialAreaName)) 	 = '' Select @RawMaterialAreaName = NULL
 	     If Ltrim(rtrim(@RawMaterialCellName)) 	 = '' Select @RawMaterialCellName = NULL
 	     If Ltrim(rtrim(@RawMaterialUnitName)) 	 = '' Select @RawMaterialUnitName = NULL
 	     If Ltrim(rtrim(@UserName))  	  	  	  	 = '' Select @UserName = NULL
 	     If Ltrim(rtrim(@UserSignature))  	  	 = '' Select @UserSignature = NULL
 	  	 ----------------------------------------------------------------------------------------
 	  	 -- In the case of unplanned SQL errors which will throw us out of this sproc,
 	  	 -- this Retries logic allows for deadlock errors to get reprocessed
 	  	 -- (Marty)
 	  	 ----------------------------------------------------------------------------------------
 	  	 UPDATE 	 Event_Transactions 
 	  	  	 SET 	 Retries = case when Retries is null then 0 else Retries + 1 end,
 	  	  	  	 OrphanedFlag = case when Retries >= 5 then 1 else 0 end,
 	  	  	    	 ProcessedTimeStamp  	 = dbo.fnServer_CmnGetDate(getUTCdate()) 
 	  	  	 WHERE 	 EventTransactionId 	 = @EventTransactionId
 	  	 ------------------------------------------------------------------------------------
 	  	 -- For GenealogyLink transaction, we don't need to validate the unit.
 	  	 -- The called sproc will do it.
 	  	 ------------------------------------------------------------------------------------
 	  	 Select @SkipUnitChecks = 0
 	  	 IF 	 @EventType = 'GenealogyLink'
 	  	 BEGIN
 	  	  	 Select @SkipUnitChecks = 1
 	  	 END
 	  	 IF 	 @EventTimeStamp < '01/01/1970 00:00'
 	  	 BEGIN
 	  	  	 SELECT 	 @Error = 'Bad Event TimeStamp [' + Convert(nvarchar(25),@EventTimeStamp) + ']'
 	  	  	 GOTO 	 Errc
 	  	 END
 	  	 IF (@SkipUnitChecks = 0)
 	  	 BEGIN
 	  	  	 IF 	 @AreaName Is Null 
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @Error = 'Missing Area Name'
 	  	  	  	 GOTO 	 Errc
 	  	  	 END
 	  	  	 IF 	 @CellName Is Null 
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @Error = 'Missing Cell Name'
 	  	  	  	 GOTO 	 Errc
 	  	  	 END
 	  	  	 IF 	 @UnitName Is Null 
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @Error = 'Missing Unit Name'
 	  	  	  	 GOTO 	 Errc
 	  	  	 END
 	  	 END
--************************************************************************************
--************************************************************************************
--
--  Check User Name and User Signature
--
--************************************************************************************
--************************************************************************************
Select @UserId  = NULL
If @UserName Is Not Null
  Begin
 	  	 SELECT 	 @UserId  	 = User_Id 
 	  	  	 FROM 	 Users 
 	  	  	 WHERE 	 UserName = @UserName
  End
If @UserId Is Null
  Select @UserId = 1
Select @SecondUserId  = NULL
If @UserSignature Is Not Null
  Begin
 	  	 SELECT 	 @SecondUserId  	 = User_Id 
 	  	  	 FROM 	 Users 
 	  	  	 WHERE 	 UserName = @UserSignature
  End
-- DO NOT Set Default Second Signature
--************************************************************************************
--************************************************************************************
--
--  Set Up Core Parts Of The Plant Model Before Processing Transactions
--
--************************************************************************************
--************************************************************************************
 	  	 IF @SkipUnitChecks = 1
 	  	  	 GOTO SkipUnitChecks001
 	  	 -------------------------------------------------------------------------------
 	  	 -- Find out if there is a model 118 configured for the unit this record belongs
 	  	 -------------------------------------------------------------------------------
 	  	 SELECT 	 @BatchProcedureUnitId 	 = Null, 
 	  	  	  	  	  	 @UnitDescription  	 = Null,
 	  	  	  	  	  	 @BatchLineId  	  	 = Null,
 	  	  	  	  	  	 @BatchUnitId  	  	 = Null,
 	  	  	  	  	  	 @ActualBatchUnitId = Null
 	  	 SELECT 	 @BatchProcedureUnitId  	 = PUId,@DefProdFamilyId = ProdFamilyId,@DefDataSourceId = DataSourceId
 	  	  	 FROM 	 @CurrentModels 
 	  	  	 WHERE 	 Area 	 = @AreaName and
   	  	  	  	  	 Unit = @UnitName and
 	  	  	  	  	 Cell = @CellName
 	  	 If @BatchProcedureUnitId is Not Null
 	  	  	 Begin
 	  	  	 SELECT @BatchLineId = Null
 	           SELECT @BatchLineId = Pl_Id From Prod_Units_Base Where PU_Id = @BatchProcedureUnitId
 	  	  	 SELECT  @ActualBatchUnitId = PU_ID
 	  	  	 From Prod_Units_Base Where PL_Id = @BatchLineId and Extended_Info = 'BATCH:' 
 	  	  	 End
    If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'BatchUnitId:' + isnull(convert(nvarchar(10),@ActualBatchUnitId),'Null'))
    If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ProcedureUnitId:' + isnull(convert(nvarchar(10),@BatchProcedureUnitId),'Null'))
 	  	 -------------------------------------------------------------------------------
 	  	 -- See if we should go ahead and create this unit
 	  	 -------------------------------------------------------------------------------
 	 IF 	 @BatchProcedureUnitId 	 Is Null
 	 BEGIN
 	  	 If @AutoConfigure = 1
 	         Begin
           	  	  	 --NOTE: This Is Similar Logic To Addition Of Raw Material Unit; However
 	  	  	  	  	 -- 	  	  	 The Raw Material Logic Is More Strict / Takes More Effort To Find
 	  	  	  	  	 -- 	  	  	 A Match - The Assumption Is That Raw Material Units Are Less Likely
 	  	  	  	  	 --  	  	  	 To Be Batch Controlled And Fall Under The Same Plant Model Assumptions
 	  	  	  	  	 -- 	  	  	 As The Batch Contolled Units
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 -- Try To Find Line Of Unit With Same Area and Cell
 	  	  	  	  	 -------------------------------------------------------------------------------
 	         SELECT 	 @BatchLineId = Null
 	         SELECT 	 @BatchDepartmentId = Null
 	         SELECT 	 @BatchUnitId = Min(PUID) 
 	  	  	  	  	  	 FROM 	 @CurrentModels 
 	  	  	  	  	  	 WHERE 	 Area  = @AreaName and 
 	  	  	  	  	  	  	  	  	 Cell  	 = @CellName
 	 
          If @BatchUnitId Is Not Null
            Begin
              -- We Found A Matching Department and Line
              Select @BatchLineId = Pl_Id From Prod_Units_Base Where PU_Id = @BatchUnitId
              Select @BatchDepartmentId = Dept_Id From Prod_Lines_Base Where PL_Id = @BatchLineId
            End --@BatchUnitId Is Not Null
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 -- Try To Find Department Of Unit With Same Area
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	 IF 	 @BatchUnitId Is Null
 	  	  	 BEGIN
 	  	         SELECT 	 @BatchUnitId = Min(PUID) 
 	  	  	  	  	  	  	 FROM 	 @CurrentModels 
 	  	  	  	  	  	  	 WHERE 	 Area  = @AreaName 	  	  	  	 
            If @BatchUnitId Is Not Null
              Begin
               	 -- We Only Found A Matching Department
                Select @BatchLineId = Pl_Id From Prod_Units_Base Where PU_Id = @BatchUnitId
                Select @BatchDepartmentId = Dept_Id From Prod_Lines_Base Where PL_Id = @BatchLineId
                Select @BatchLineId = NULL
              End --@BatchUnitId Is Not Null
 	  	  	  	  	 END   --@BatchUnitId Is Null     	  	 
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 -- Add The Unit With What We Know So Far
 	  	  	  	  	 -------------------------------------------------------------------------------
     	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adding Unit [' + @UnitName + '] Department = ' + coalesce(convert(nvarchar(10), @BatchDepartmentId),'?') + 'Line = ' + coalesce(convert(nvarchar(10), @BatchLineId),'?') )
 	  	  	  	  	 Select @BatchUnitId = NULL
 	  	  	  	  	 Exec @Rc = dbo.spBatch_CreateBatchUnit
 	  	  	  	  	  	  	 @EventTransactionId,
 	  	  	  	  	  	  	 @BatchUnitId OUTPUT,
 	  	  	  	  	  	  	 @BatchLineId, 
 	  	  	  	  	  	  	 @BatchDepartmentId, 
 	  	  	  	  	  	  	 @AreaName,
 	  	  	  	  	  	  	 @CellName,
 	  	  	  	  	  	  	 @UnitName,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 0,
 	  	  	  	  	  	  	 @Debug
          If @Rc <> 1 
            Begin
 	  	  	  	  	  	  	 SELECT 	 @Error = 'Unable to Add Unit for [' + @AreaName + ']['+ @CellName + ']['+ @UnitName + ']'
 	  	  	  	  	  	  	 GOTO 	 Errc
            End --@Rc <> 1 
 	  	  	  	  	 Select @BatchLineId = Pl_Id From Prod_Units_Base Where PU_Id = @BatchUnitId
 	  	  	  	  	 Select @BatchProcedureUnitId = @BatchUnitId
        End -- @AutoConfigure = 1
     If @BatchUnitId Is Null
       Begin
 	  	  	  	 SELECT 	 @Error = 'Unable to find model for [' + @AreaName + ']['+ @CellName + ']['+ @UnitName + ']'
 	  	  	  	 GOTO 	 Errc
       End
     Else
       Begin
 	  	 SELECT  @ActualBatchUnitId = PU_ID 	 From Prod_Units_Base Where PL_Id = @BatchLineId and Extended_Info = 'BATCH:' 
 	  	 SELECT 	 @BatchProcedureGroupId = PUG_Id
 	  	  	 FROM 	 PU_Groups
 	  	  	 WHERE 	 PU_Id = @ActualBatchUnitId and External_Link = 'BATCH'
     	  	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ActualBatchUnitId:' + IsNull(Convert(nvarchar(10),@ActualBatchUnitId),'Null'))
         -- Go Ahead And Add To Model List To Limit Future Searching
          Insert Into @CurrentModels (PUId, Area, Cell, Unit,ProdFamilyId,DataSourceId)
            Values (@BatchUnitId, @AreaName, @CellName, @UnitName,@DefProdFamilyId,@DefDataSourceId)
       End
 END -- @BatchProcedureUnitId 	 Is Null
 	  	 -------------------------------------------------------------------------------
 	  	 -- Search for a Procedure / Event Unit (<PU_Desc>) for the Batch Unit
 	  	 -------------------------------------------------------------------------------
 	  	 IF 	 @ActualBatchUnitId Is Null
 	  	 BEGIN
 	  	  	 Select @UnitDescription =  '<' + @AreaName + ':' + @CellName + '>'
 	  	  	 Exec @Rc = dbo.spBatch_CreateBatchUnit
 	  	  	  	 @EventTransactionId,
 	  	  	  	 @ActualBatchUnitId OUTPUT,
 	  	  	  	 @BatchLineId, 
 	  	  	  	 @BatchDepartmentId, 
 	  	  	  	 @AreaName,
 	  	  	  	 @CellName,
 	  	  	  	 @UnitDescription,
 	  	  	  	 @UserId,
 	  	  	  	 1,
 	  	  	  	 @Debug
 	  	 END --@ActualBatchUnitId Is Null
------------------------------------------------------------------
-- Need to do inputs for batch unit to unit procedures
------------------------------------------------------------------
 	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ActualBatchUnitId:' + IsNull(Convert(nvarchar(10),@ActualBatchUnitId),'Null'))
 	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'BatchProcedureUnitId:' + IsNull(Convert(nvarchar(10),@BatchProcedureUnitId),'Null'))
 	  	 If @ActualBatchUnitId is not Null and @BatchProcedureUnitId is Not Null
 	  	 BEGIN
 	  	  	 Declare  	 @PEIId Int,
 	  	  	  	  	 @InputCount Int,
 	  	  	  	  	 @EventSubTypeId Int,
 	  	  	  	  	 @InputName 	 nvarchar(100),
 	  	  	  	  	 @InputOrder 	 Int
 	  	  	 Select @InputCount = Count(*)
 	  	  	  	 From PrdExec_Inputs p
 	  	  	  	 Join PrdExec_Input_Sources pis On p.PEI_Id = pis.PEI_Id and pis.PU_Id = @ActualBatchUnitId
 	  	  	  	 WHERE p.PU_Id = @BatchProcedureUnitId
 	  	  	 If @InputCount = 0
 	  	  	 BEGIN
 	  	  	  	 Select @EventSubTypeId = event_subtype_id
 	  	  	  	   From Event_Configuration 
 	  	  	  	   Where PU_Id = @BatchProcedureUnitId and ET_Id = 1
 	  	  	  	 Select @PEIId = Min(PEI_Id)
 	  	  	  	  	 From PrdExec_Inputs p
 	  	  	  	  	 WHERE PU_Id = @BatchProcedureUnitId And Event_Subtype_Id = @EventSubTypeId
 	  	  	  	 If @PEIId Is Null
 	  	  	  	 BEGIN
 	  	  	  	  	 --create Input
 	  	  	  	  	 Select @InputOrder = Max(Input_Order) + 1 from Prdexec_inputs Where PU_Id = @BatchProcedureUnitId
 	  	  	  	  	 Select @InputOrder = isnull(@InputOrder,1)
 	  	  	  	  	 Select @InputName = '<' + PU_Desc + ' Input>' From Prod_Units_Base where PU_Id = @BatchProcedureUnitId
 	  	  	      	  	 Insert  into Prdexec_Inputs (input_name, input_order, pu_id, event_subtype_id, primary_spec_id, alternate_spec_id, lock_inprogress_input)
 	  	  	        	  	 values(@InputName, @InputOrder, @BatchProcedureUnitId, @EventSubtypeId, Null, Null,  1)
 	  	  	  	  	 Select @PEIId = PEI_Id from Prdexec_inputs Where  Input_Name = @InputName and PU_Id = @BatchProcedureUnitId
 	  	  	  	 END
 	  	  	  	 Insert into PrdExec_Input_Sources (PEI_Id, PU_Id)values(@PEIId, @ActualBatchUnitId)
 	  	  	 END
 	  	 END
 	  	 Select @BatchProcedureGroupId = Null
 	  	 SELECT 	 @BatchProcedureGroupId  	  	 = PUG_Id 
 	  	  	 FROM 	 PU_Groups 
 	  	  	 WHERE 	 PU_Id  	  	  	  	 = @ActualBatchUnitId and
 	  	  	  	  	  	 External_Link = 'BATCH'
 	  	 IF 	 @BatchProcedureGroupId Is Null
 	  	 BEGIN
 	  	  	 SELECT @BatchProcedureGroupId = PUG_Id 
 	  	  	 FROM 	 PU_Groups 
 	  	  	 WHERE PU_Id = @ActualBatchUnitId and
 	  	  	  	  	  	 PUG_Desc = 'Batch Parameters'
 	  	  	 IF @BatchProcedureGroupId Is Null
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @BatchProcedureOrder  	 = Coalesce(Max(PUG_Order),0) + 1 
 	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	 WHERE 	 PU_Id  	 = @ActualBatchUnitId
 	  	  	  	 EXEC 	 spEM_CreatePUG  
 	  	  	  	  	 'Batch Parameters',
 	  	  	  	  	 @ActualBatchUnitId,
 	  	  	  	  	 @BatchProcedureOrder,
 	  	  	  	  	 @UserId,
 	  	  	  	  	 @BatchProcedureGroupId OUTPUT 	 
 	  	  	  	 IF 	 @BatchProcedureGroupId Is Null 
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT 	 @Error = 'Unable to create [BATCH Parameters Group] For Unit [' + convert(nvarchar(10),@BatchUnitId) + ']' 
 	  	  	  	  	 GOTO 	 Errc
 	  	  	  	 END
 	  	  	 END
 	  	  	 UPDATE 	 PU_Groups 
 	  	  	  	 SET 	 External_Link  	 = 'BATCH' 
 	  	  	  	 WHERE 	 PUG_Id = @BatchProcedureGroupId
 	  	 END
 	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'CheckEventTable:BATCH:' + IsNull(Convert(nvarchar(10),@BatchProcedureGroupId),'Null'))
 	  	 If @OperationName is not null  
 	  	  	 Select @BatchUnitId = Isnull(@BatchProcedureUnitId,@BatchUnitId)
 	  	 
 	  	 SELECT 	 @BatchLineId = PL_Id 
 	  	  	 FROM 	 Prod_Units_Base 
 	  	  	 WHERE 	 PU_Id = @BatchUnitId
 	  	 -------------------------------------------------------------------------------
 	  	 -- Handle Unit Procedure, if passed
 	  	 -------------------------------------------------------------------------------
 	  	 IF 	 @UnitProcedureName Is Not Null 
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Handle Operation if Unit Procedure was passed
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 IF 	 @OperationName Is Not Null 
 	  	  	 BEGIN
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Unit Procedure and Operation were passed
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 SELECT 	 @ProcedureLink 	  	 = Null,
 	  	  	  	  	  	  	  	 @BatchProcedureUnitId  	 = Null
 	  	  	  	 SELECT 	 @ProcedureLink 	  	 = @UnitProcedureName + ':' + @OperationName
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Search The (Child) Unit For This Unit Procedure/Operation
 	  	  	  	 --
 	  	  	  	 -- Its External link should be equal to UnitProcedureName:OperationName
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 SELECT 	 @BatchProcedureUnitId = @BatchUnitId
 	  	  	  	 
 	  	  	  	 IF 	 @BatchProcedureUnitId Is Null 
 	  	  	  	 BEGIN
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 -- Create Procedure Unit (For Combination Unit Procedure + Operation)
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 SELECT 	 @UnitDescription 	 = Null
 	  	            	 SELECT 	 @UnitDescription 	 = @ProcedureLink + '.' + Convert(nvarchar(10),@BatchUnitId)
 	  	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Creating Procedure Child Unit [' + @UnitDescription + ']' )
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 -- Test For Length And Uniqueness
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	     If len(@UnitDescription) > 100
 	  	  	       BEGIN
 	  	  	         Select @Count = 0
 	  	  	  	    Select @Count = count(pu_id) From Prod_Units_Base Where pu_desc like left(@UnitDescription,96) + '%' 	         
 	  	  	 
 	  	  	         Select @Count = @Count + 1
 	  	  	 
 	  	  	         Select @UnitDescription = left('*' + convert(nvarchar(10),@Count) + '*' + @UnitDescription,100)
     	  	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Had To Adjust Procedure Child Unit Description  [' + @UnitDescription + ']')
 	  	  	       END    
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 -- Go Ahead and Add The Batch Procedure / Child Unit
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 EXEC 	 spEM_CreateProdUnit  
 	  	  	  	  	  	 @UnitDescription,
 	  	  	  	  	  	 @BatchLineId,
 	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	 @BatchProcedureUnitId 	 OUTPUT
 	  	  	  	  	 IF 	 @BatchProcedureUnitId Is Null
 	  	  	  	  	 BEGIN
 	  	  	  	    	 SELECT 	 @Error = 'Unable to create[' + @ProcedureLink + ']'
 	  	  	  	  	  	 GOTO 	 Errc
 	  	  	  	  	 END
 	  	  	  	  	 EXEC 	 spEM_SetMasterUnit   
 	  	  	  	  	  	 @BatchProcedureUnitId,
 	  	  	  	  	  	 @BatchUnitId,
 	  	  	  	  	  	 @UserId
 	  	  	  	  	 UPDATE 	 Prod_Units_Base 
 	  	  	  	  	  	 SET 	 External_Link = @ProcedureLink,Uses_Start_Time = 1,Chain_Start_Time = 0
 	  	  	  	  	  	 WHERE 	 PU_Id = @BatchProcedureUnitId
 	  	  	  	 END
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Search for a Variable Group for the 'Operation' attached to the Procedure Unit  
 	  	  	  	 -- for the Unit Procedure
 	  	  	  	 --
 	  	  	  	 -- Its External link should be equal to Operation!OperationName
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 SELECT 	 @BatchProcedureGroupId  	  	 = Null
 	  	  	  	 SELECT 	 @BatchProcedureOrder  	 = Coalesce(Max(PUG_Order),0) + 1 
 	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	 WHERE 	 PU_Id  	 = @BatchProcedureUnitId
 	  	  	  	 If Len(@OperationName) > 48
 	  	  	  	  	 Select @GroupName = left('O:' + @OperationName,50)
 	  	  	  	 Else
 	  	  	  	  	 Select @GroupName = 'O:' + @OperationName
 	  	  	  	 SELECT 	 @BatchProcedureGroupId  	  	 = PUG_Id 
 	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	 WHERE 	 PU_Id  	 = @BatchProcedureUnitId and
 	  	  	  	  	  	  	  	 External_Link = @GroupName
 	  	  	  	 IF 	 @BatchProcedureGroupId Is Null and @PhaseName is Null and @EventType In ('ParameterReport','RecipeSetup','EventReport')
 	  	  	  	 BEGIN
 	  	  	  	  	 Select @BatchProcedureGroupId = PUG_Id 
 	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	 WHERE 	 PU_Id = @BatchProcedureUnitId AND 	 PUG_Desc = @GroupName
 	  	  	  	  	 IF @BatchProcedureGroupId is Null
 	  	  	  	  	    BEGIN
 	  	  	  	  	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Create Operation Group Desc:' + IsNull(@GroupName,'Null'))
 	  	  	  	  	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Create Operation Group PU:' + IsNull(Convert(nvarchar(10),@BatchProcedureUnitId),'Null'))
 	  	  	  	  	  	 EXEC 	 spEM_CreatePUG  
 	  	  	  	  	  	  	 @GroupName,
 	  	  	  	  	  	  	 @BatchProcedureUnitId,
 	  	  	  	  	  	  	 @BatchProcedureOrder,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @BatchProcedureGroupId 	 OUTPUT
 	  	  	  	  	  	 IF 	 @BatchProcedureGroupId Is Null 
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	    	  	 SELECT 	 @Error = 'Unable to create [OPERATION:' + @OperationName + ']'
 	  	  	  	  	  	  	 GOTO 	 Errc
 	  	  	  	  	  	 END
 	  	  	  	  	   END
 	  	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'CheckEventTable:OPERATION:' + IsNull(Convert(nvarchar(10),@BatchProcedureGroupId),'Null'))
 	  	  	  	  	 UPDATE 	 PU_Groups 
 	  	  	  	  	  	 SET 	 External_Link = 'O:' + @OperationName 
 	  	  	  	  	  	 WHERE 	 PUG_Id = @BatchProcedureGroupId
 	  	  	  	 END
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Search for a Variable Group for the Phase attached to the slave PU for 
 	  	  	  	 -- the Unit Procedure
 	  	  	  	 --
 	  	  	  	 -- Its External link should be equal to 'PhaseName:Instance#'
        -- Note: PhaseName Already Concatenates Phase Instance
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 IF 	 @PhaseName is Not Null 
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT 	 @BatchProcedureGroupId  	  	 = Null,
 	  	  	  	  	  	  	  	  	 @BatchProcedureOrder 	 = Null
 	  	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'BatchProcedureUnitId:' +  IsNull(Convert(nvarchar(10),@BatchProcedureUnitId),'Null'))
 	  	  	  	  	 SELECT 	 @BatchProcedureOrder = Coalesce(Max(PUG_Order),0) + 1 
 	  	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	  	 WHERE 	 PU_Id = @BatchProcedureUnitId
 	  	  	  	  	 If Len(@PhaseName) > 48
 	  	  	  	  	  	 Select @GroupName = left('P:' + @PhaseName,50)
 	  	  	  	  	 Else
 	  	  	  	  	  	 Select @GroupName = 'P:' + @PhaseName
 	  	  	  	  	 SELECT 	 @BatchProcedureGroupId = PUG_Id 
 	  	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	  	 WHERE 	 PU_Id = @BatchProcedureUnitId and
 	  	  	  	  	  	  	  	  	 External_Link = @GroupName
 	  	  	  	  	 IF 	 @BatchProcedureGroupId Is Null and @EventType In ('ParameterReport','RecipeSetup','EventReport')
 	  	  	  	  	   BEGIN
 	  	  	  	  	  	 Select @BatchProcedureGroupId = PUG_Id 
 	  	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	  	 WHERE 	 PU_Id = @BatchProcedureUnitId AND 	 PUG_Desc = @GroupName
 	  	  	  	  	  	 IF @BatchProcedureGroupId is Null
 	  	  	  	  	  	   BEGIN
 	  	  	  	  	  	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Create Phase Group Desc:' + IsNull(@GroupName,'Null'))
 	  	  	  	  	  	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Create Phase Group PU:' + IsNull(Convert(nvarchar(10),@BatchProcedureUnitId),'Null'))
 	  	  	  	  	  	  	 EXEC 	 spEM_CreatePUG  
 	  	  	  	  	  	  	  	 @GroupName,
 	  	  	  	  	  	  	  	 @BatchProcedureUnitId,
 	  	  	  	  	  	  	  	 @BatchProcedureOrder,
 	  	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	  	 @BatchProcedureGroupId 	 OUTPUT
 	 
 	  	  	  	  	  	  	 IF 	 @BatchProcedureGroupId Is Null 
 	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	 SELECT 	 @Error = 'Unable to create[' + @PhaseName + '] For Unit [' + convert(nvarchar(10),@BatchProcedureUnitId) + ']'
 	  	  	  	  	  	  	  	 GOTO 	 Errc
 	  	  	  	  	  	  	 END
 	  	  	  	  	  	   END
 	  	  	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'CheckEventTable:' + @PhaseName + ':' + IsNull(Convert(nvarchar(10),@BatchProcedureGroupId),'Null'))
 	  	  	  	  	  	 UPDATE 	 PU_Groups 
 	  	  	  	  	  	  	 SET 	 External_Link = 'P:' + @PhaseName 
 	  	  	  	  	  	  	 WHERE 	 PUG_Id = @BatchProcedureGroupId
 	  	  	  	  	 END
 	  	  	  	 END
 	  	  	 END
 	  	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Only Unit Procedure was passed
 	  	  	  	 --
 	  	  	  	 -- Search for a Variable Group for the Batch Unit (not procedure unit!) for the Unit 
 	  	  	  	 -- Procedure.  Its External link should be equal to UP:!ProcedureName
 	  	  	  	 -------------------------------------------------------------------------------
     	  	  	  	 SELECT 	 @BatchProcedureGroupId  	  	 = Null,
 	  	  	  	  	  	  	  	 @BatchProcedureOrder 	 = Null
 	  	  	  	 Select @BatchUnitId = Isnull(@BatchUnitId,@BatchProcedureUnitId)
 	  	  	  	 SELECT 	 @BatchProcedureOrder  	 = Coalesce(Max(PUG_Order),0) + 1 
 	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	 WHERE 	 PU_Id 	 = @BatchUnitId
 	  	  	  	 If Len(@UnitProcedureName) > 50
 	  	  	  	  	 Select @UnitProcedureName = left(@UnitProcedureName,50)
 	  	  	  	 SELECT 	 @BatchProcedureGroupId  	  	 = PUG_Id 
 	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	 WHERE 	 PU_Id = @BatchUnitId 
 	  	  	  	  	 AND 	 External_Link = 'UP:' + @UnitProcedureName
 	  	  	  	 IF 	 @BatchProcedureGroupId Is Null  and @OperationName is Null and @EventType In ('ParameterReport','RecipeSetup','EventReport')
 	  	  	  	 BEGIN
 	  	  	  	  	 Select @MyUnitProcedureName = @UnitProcedureName
 	  	  	  	  	 Select @BatchProcedureGroupId = PUG_Id 
 	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	 WHERE 	 PU_Id = @BatchUnitId AND 	 PUG_Desc = @MyUnitProcedureName
 	  	  	  	  	 If @BatchProcedureGroupId is not Null
 	  	  	  	  	   Begin
 	  	  	  	  	  	 Select @MyUnitProcedureName = 'UP:'+ @MyUnitProcedureName
 	  	  	  	  	  	 Select @BatchProcedureGroupId = Null
 	  	  	  	  	  	 If Len(@MyUnitProcedureName) > 50
 	  	  	  	  	  	  	 Select @MyUnitProcedureName = left(@MyUnitProcedureName,50)
 	  	  	  	  	  	 Select @BatchProcedureGroupId = PUG_Id 
 	  	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	  	 WHERE 	 PU_Id = @BatchUnitId AND 	 PUG_Desc = @MyUnitProcedureName
 	  	  	  	  	   End
 	  	  	  	  	 If @BatchProcedureGroupId is not Null
 	  	  	  	  	   Begin
 	  	  	  	  	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Duplicate Procedure Group Desc:' + IsNull(@MyUnitProcedureName,'Null'))
 	  	  	  	  	  	 SELECT 	 @Error = 'Unable to create [PROCEDURE GROUP:' + @MyUnitProcedureName + '] For Unit [' + convert(nvarchar(10),@BatchUnitId)+ ']'
 	  	  	  	  	  	 GOTO 	 Errc
 	  	  	  	  	   End
 	  	  	  	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Create Unit Procedure Group Desc:' + IsNull(@MyUnitProcedureName,'Null'))
 	  	  	  	  	 If @Debug = 1  Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Create Unit Procedure Group PU:' + IsNull(Convert(nvarchar(10),@BatchUnitId),'Null'))
 	  	  	  	  	 EXEC 	 spEM_CreatePUG  
 	  	  	  	  	  	 @MyUnitProcedureName,
 	  	  	  	  	  	 @BatchUnitId,
 	  	  	  	  	  	 @BatchProcedureOrder,
 	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	 @BatchProcedureGroupId 	 OUTPUT
 	  	  	  	  	 IF 	 @BatchProcedureGroupId Is Null 
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT 	 @Error = 'Unable to create [PROCEDURE:' + @MyUnitProcedureName + '] For Unit [' + convert(nvarchar(10),@BatchUnitId)+ ']'
 	  	  	  	  	  	 GOTO 	 Errc
 	  	  	  	  	 END
 	  	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'CheckEventTable:PROCEDURE:' + IsNull(Convert(nvarchar(10),@BatchProcedureGroupId),'Null'))
 	  	  	  	  	 UPDATE 	 PU_Groups 
 	  	  	  	  	  	 SET 	 External_Link = 'UP:'+ @UnitProcedureName 
 	  	  	  	  	  	 WHERE 	 PUG_Id = @BatchProcedureGroupId
 	  	  	  	 END
 	  	  	 END
 	  	   END
SkipUnitChecks001:
--************************************************************************************
--************************************************************************************
--
--  Ready To Process Specific Transactions
--
--************************************************************************************
--************************************************************************************
 	  	 -------------------------------------------------------------------------------
 	  	 -- Based on the event type, this SP will call others SPs that will update the
 	  	 -- Proficy Core tables
 	  	 --
 	  	 -- Common section for when UnitProc or UnitProc/Oper or none are passed
 	  	 -------------------------------------------------------------------------------
    If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Processing Event Type [' + coalesce(@EventType,'?') + ']')
 	  	 IF 	 @EventType Is Null
 	  	 BEGIN 	 
 	  	  	 SELECT 	 @Error = 'Event Type Not Found'
 	  	  	 GOTO 	 Errc
 	  	 END
 	  	 ELSE
 	  	 IF 	 @EventType = 'RecipeSetup'
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Handle RecipeSetup Transaction (Var_Specs)
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 EXEC 	 @Rc = spBatch_ProcessRecipeSetup 
 	  	  	  	 @EventTransactionId,
 	  	  	  	 @ActualBatchUnitId,
 	  	  	  	 @BatchProcedureUnitId,
  	  	  	  	 @BatchProcedureGroupId,
 	  	  	  	 @ProcedureUnitId,
 	  	  	  	 @UserId,
 	  	  	  	 @SecondUserId,
         	  	  	 @Debug
 	  	 END
 	  	 ELSE
 	  	 IF 	 @EventType = 'ProcedureReport'
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Handle ProcedureReport Transaction (Events)
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 EXEC 	 @Rc = spBatch_ProcessProcedureReport 
 	  	  	  	 @EventTransactionId,
 	  	  	  	 @ActualBatchUnitId,
 	  	  	  	 @BatchProcedureUnitId,
 	  	  	  	 @ProcedureUnitId,
 	  	  	  	 @BatchProcedureGroupId,
 	  	  	  	 @UserId,
 	  	  	  	 @SecondUserId,
 	  	  	  	 @DefProdFamilyId,
 	  	  	  	 @DefDataSourceId,
 	  	  	  	 @Debug
 	  	 END
 	  	 ELSE
 	  	 IF 	 @EventType = 'ParameterReport'
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Handle ParameterReport Transaction (Tests)
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 SELECT 	 @BatchProcedureUnitId = Coalesce(@BatchProcedureUnitId, @BatchUnitId)
 	  	  	 EXEC 	 @Rc = spBatch_ProcessParameterReport 
 	  	  	  	 @EventTransactionId,
 	  	  	  	 @ActualBatchUnitId,
 	  	  	  	 @BatchProcedureUnitId,
  	  	  	  	 @BatchProcedureGroupId,
 	  	  	  	 @ProcedureUnitId,
 	  	  	  	 @UserId,
 	  	  	  	 @SecondUserId,
 	  	  	  	 @Debug
 	  	 END
 	  	 ELSE
 	  	 IF 	 @EventType = 'MaterialMovement'
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Handle MaterialMovement Transaction (Event_Components)
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Check if the Raw material information is present
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 IF 	 @RawMaterialAreaName Is Null 
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @Error = 'Missing Raw Material Area Name'
 	  	  	  	 GOTO 	 Errc
 	  	  	 END
 	  	  	 IF 	 @RawMaterialCellName is Null 
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @Error = 'Missing Raw Material Cell Name'
 	  	  	  	 GOTO 	 Errc
 	  	  	 END
 	  	  	 IF 	 @RawMaterialUnitName is Null 
 	  	  	 BEGIN
 	  	  	  	 SELECT 	 @Error = 'Missing Raw Material Unit Name'
 	  	  	  	 GOTO 	 Errc
 	  	  	 END
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Retrieve Area, Cell, Unit for model 118 attached to the Raw material unit
 	  	  	 -- (SourcePU)
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 SELECT 	 @RawMaterialUnitId = NUll
 	  	  	 SELECT 	 @RawMaterialUnitId = PUID,@RawProdFamilyId = ProdFamilyId,@RawDataSourceId = DataSourceId
 	  	  	  	 FROM 	 @CurrentModels 
 	  	  	  	 WHERE 	 Area  = @RawMaterialAreaName and 
 	  	  	  	  	  	  	 Unit = @RawMaterialUnitName and
 	  	  	  	  	  	  	 Cell = @RawMaterialCellName
 	  	  	 IF 	 @RawMaterialUnitId Is Null
 	  	  	 BEGIN
     	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Searching For Raw Material Unit [' + @RawMaterialAreaName + ']['+ @RawMaterialCellName + ']['+ @RawMaterialUnitName + ']')
         	  	  	 --NOTE: This Is Similar Logic To Addition Of Batch Units; However
 	  	  	  	 -- 	  	  	 The Raw Material Logic Is More Strict / Takes More Effort To Find
 	  	  	  	 -- 	  	  	 A Match - The Assumption Is That Raw Material Units Are Less Likely
 	  	  	  	 --  	  	  	 To Be Batch Controlled And Fall Under The Same Plant Model Assumptions
 	  	  	  	 -- 	  	  	 As The Batch Contolled Units
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Try To Find Line Of Unit With Same Area and Cell
 	  	  	  	 -------------------------------------------------------------------------------
         	  	  	 SELECT 	 @RawMaterialUnitId = Min(PUID) 
 	  	  	  	  	 FROM 	 @CurrentModels 
 	  	  	  	  	 WHERE 	 Area  = @RawMaterialAreaName and 
 	  	  	  	  	  	  	  	 Cell  	 = @RawMaterialCellName
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Try To Find Line Of Unit With Same Area
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 IF 	 @RawMaterialUnitId Is Null
 	  	  	  	 BEGIN
 	          	  	  	 SELECT 	 @RawMaterialUnitId = Min(PUID) 
 	  	  	  	  	  	 FROM 	 @CurrentModels 
 	  	  	  	  	  	 WHERE 	 Area  = @RawMaterialAreaName 	  	  	  	 
 	  	  	  	 END       
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- If We Found A Line With One Of The Methods Above
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 IF 	 @RawMaterialUnitId Is Not Null
 	  	  	  	 BEGIN
 	  	      	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Found A Similar Unit...')
 	  	  	  	  	 SELECT 	 @RawMaterialLineId  	 = PL_Id 
 	  	  	  	  	  	 FROM 	 Prod_Units_Base
 	  	  	  	  	  	 WHERE 	 PU_Id  	 = @RawMaterialUnitId
 	  	  	  	  	 ------------------------------------------------------------------------------- 	 
 	          	  	  	 -- See If Unit With Exteral_Link = UnitName exists
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 SELECT @RawMaterialUnitId = NULL
 	  	  	  	  	 SELECT @RawMaterialUnitId = PU_Id 
 	  	  	  	  	  	 FROM 	 Prod_Units_Base
 	  	  	  	  	  	 WHERE PL_Id  	  	 = @RawMaterialLineId and 
 	  	  	  	  	  	  	 External_Link  	 = @RawMaterialUnitName
 	  	  	  	  	 ------------------------------------------------------------------------------- 	 
 	  	  	  	  	 -- If Unit Does Not Exist, Add It
 	  	  	  	  	 ------------------------------------------------------------------------------- 	 
 	  	  	  	  	 IF 	 @RawMaterialUnitId Is Null
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	  	 -- Test For Uniqueness
 	  	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	  	 Select @Count = 0
 	  	  	  	  	  	 Select @Count = count(pu_id) From Prod_Units_Base Where pu_desc like left(@RawMaterialUnitName,96) + '%' 	         
 	  	  	  	  	  	 
 	  	  	  	  	  	 Select @Count = @Count + 1
 	  	 
 	  	  	  	  	  	 If @Count > 1 
 	  	  	  	  	  	  	 Select @RawMaterialUnitName = left('*' + convert(nvarchar(10),@Count) + '*' + @RawMaterialUnitName,100)
 	  	  	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Need To Add A New Unit [' + @RawMaterialUnitName + ']')
 	  	  	  	  	  	 EXEC 	 spEM_CreateProdUnit  
 	  	  	  	  	  	  	 @RawMaterialUnitName,
 	  	  	  	  	  	  	 @RawMaterialLineId,
 	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	 @RawMaterialUnitId 	 OUTPUT
 	  	  	  	  	  	 IF 	 @RawMaterialUnitId Is null
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT 	 @Error = 'Unable to create [' + @RawMaterialUnitName + '] For Raw Material Unit'
 	  	  	  	  	  	  	 GOTO 	 Errc
 	  	  	  	  	  	 END
 	  	  	  	  	  	 EXEC 	 spEM_SetMasterUnit   
 	  	  	  	  	  	  	 @RawMaterialUnitId,
 	  	  	  	  	  	  	 @RawMaterialUnitId,
 	  	  	  	  	  	  	 @UserId
 	  	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	  	 -- Update Parameters Of The Raw Material Unit
 	  	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	  	 UPDATE 	 Prod_Units_Base
 	  	  	  	  	  	  	 SET 	 External_Link = @RawMaterialUnitName, 
 	  	  	  	  	  	  	     Uses_Start_Time 	  	 = 1,
 	  	  	  	  	  	  	  	  	 Chain_Start_Time  	 = 0 
 	  	  	  	  	  	  	 WHERE 	 PU_Id = @RawMaterialUnitId
 	  	  	  	  	 END -- we found a line, and needed to create a unit   
 	  	  	    	 END -- we did find a line with the same area, cell     
 	  	  	  	 ELSE  
 	  	  	  	 BEGIN 
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 -- We didnt find a line to create the raw material unit on 
 	  	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	  	 SELECT 	 @Error = 'Warning - Unable to find Raw Material Unit For [' + @RawMaterialAreaName + ']['+ @RawMaterialCellName + ']['+ @RawMaterialUnitName + ']'
 	  	  	  	  	 UPDATE 	 Event_Transactions 
 	  	  	  	  	  	 SET 	 OrphanedReason  	  	 = @Error 
 	  	  	  	  	  	 WHERE 	 EventTransactionId  	 = @EventTransactionId
 	  	  	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
 	  	  	  	 END
 	  	  	 END  -- if we found a unit
 	  	  	 IF @UnitProcedureName is Null or @BatchProcedureUnitId Is Null
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT @DestPUId = @ActualBatchUnitId
 	  	  	  	  	 Select @IsVirtualBatch = 1
 	  	  	  	 END
 	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT @DestPUId = @BatchProcedureUnitId
 	  	  	  	  	 SELECT @DestPUId = @BatchProcedureUnitId
 	  	  	  	  	 Select @IsVirtualBatch = 0
 	  	  	  	 END
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Go Ahead With Material Movement Transaction
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 Select @RawProdFamilyId = isnull(@RawProdFamilyId,@DefProdFamilyId)
 	  	  	 Select @RawDataSourceId = isnull(@RawDataSourceId,@DefDataSourceId)
 	  	  	 EXEC 	 @Rc = spBatch_ProcessMaterialMovement 
 	  	  	  	 @EventTransactionId,
 	  	  	  	 @DestPUId,
 	  	  	  	 @RawMaterialUnitId,
 	  	  	  	 @UserId,
 	  	  	  	 @SecondUserId,
 	  	  	  	 @DefProdFamilyId,
 	  	  	  	 @DefDataSourceId,
 	  	  	  	 @IsVirtualBatch,
 	  	  	  	 @Debug
 	  	 END  -- material movement
 	  	 ELSE
 	  	 IF 	 @EventType = 'EventReport'
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Handle EventReport Transaction (UDE and Alarms)
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 EXEC 	 @Rc = spBatch_ProcessEventReport 
 	  	  	  	 @EventTransactionId,
 	  	  	  	 @ActualBatchUnitId,
 	  	  	  	 @BatchProcedureUnitId,
 	  	  	  	 @BatchProcedureGroupId,
 	  	  	  	 @ProcedureUnitId, 	  	  	  	 
 	  	  	  	 @UserId,
 	  	  	  	 @SecondUserId,
 	  	  	  	 @Debug
 	  	 END
 	  	 ELSE
 	  	 IF 	 @EventType = 'GenealogyLink'
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Handle GenealogyLink Transaction (Event_Components)
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 EXEC @Rc = spBatch_ProcessGenealogyLink 
 	  	  	  	 @EventTransactionId,
 	  	  	  	 @UserId,
 	  	  	  	 @Debug
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 -- Event Type not handled by the interface
 	  	  	 -------------------------------------------------------------------------------
 	  	  	 SELECT 	 @Error = 'Event Type [' + @EventType + '] Not Valid'
 	  	  	 GOTO 	 Errc
 	  	 END
 	  	 -------------------------------------------------------------------------------
 	  	 -- Mark the Event_Transactions record as processed
 	  	 -------------------------------------------------------------------------------
    If @Rc = 1 
      BEGIN
        -- Processing Of Transaction Succeeded
 	  	  	  	 UPDATE 	 Event_Transactions 
 	  	  	  	  	 SET 	 ProcessedFlag  	  	 = 1, OrphanedFlag = 0,
 	  	  	  	  	  	 ProcessedTimeStamp  	 = dbo.fnServer_CmnGetDate(getUTCdate()) 
 	  	  	  	  	 WHERE 	 EventTransactionId  	 = @EventTransactionId
      END
    ELSE
      BEGIN
        -- Processing Of Transaction Failed (likely orphaned reason is already set)
   	  	  	 SELECT 	 @Error = 'Event Type [' + @EventType + '] General Failure Return = ' + convert(nvarchar(10), @Rc)
 	  	  	  	 UPDATE 	 Event_Transactions 
 	  	  	  	  	 SET 	 OrphanedReason =  coalesce(OrphanedReason, @Error), 
 	  	  	  	  	  	  	 OrphanedFlag  	  	 = 1, 
 	  	  	  	  	  	   ProcessedTimeStamp  	 = dbo.fnServer_CmnGetDate(getUTCdate()) 
 	  	  	  	  	 WHERE 	 EventTransactionId  	 = @EventTransactionId
     	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
      END
 	  	 -------------------------------------------------------------------------------
 	  	 -- Wait In Between Records Prescribed Amount
 	  	 -------------------------------------------------------------------------------
 	  	 If @WaitMilliseconds > 0 
      Begin
        Select @DelayTime = '000:00:00.' + right('000' + convert(nvarchar(10),@WaitMilliseconds),3)
        Waitfor delay @DelayTime
     End
DoNextEvent:
 	  	 SET @CurEventTransId = @CurEventTransId + 1
 	 END -- WHILE @CurEventTransId <= @EventTransLoopEnd
END 	 -- Select count.. (records to process)
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Done With Record Processing')
-------------------------------------------------------------------------------
-- Purge Processed Records 
-------------------------------------------------------------------------------
If  @PurgeProcessedDays 	 > 0
  Begin
 	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Purging Processed Records')
 	   Delete From Event_Transactions where ProcessedFlag = 1 and OrphanedFlag = 0 and ProcessedTimeStamp < DateAdd(day,-1 * @PurgeProcessedDays,dbo.fnServer_CmnGetDate(getUTCdate()))
  End
If  @PurgeOrphanedDays 	 > 0
  Begin
 	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Purging Orphaned Records')
 	   Delete From Event_Transactions where OrphanedFlag = 1 and ProcessedTimeStamp < DateAdd(day,-1 * @PurgeOrphanedDays,dbo.fnServer_CmnGetDate(getUTCdate()))
  End
-------------------------------------------------------------------------------
-- Normal Exit
-------------------------------------------------------------------------------
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_CheckEventTable)')
RETURN
-------------------------------------------------------------------------------
-- Exception Handling
-------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	  	 = coalesce(OrphanedReason, @Error),
 	  	 OrphanedFlag  	  	 = 1, 
 	   ProcessedTimeStamp  	 = dbo.fnServer_CmnGetDate(getUTCdate()) 
 	 WHERE 	 EventTransactionId 	 = @EventTransactionId
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_CheckEventTable)')
-- Return and get the next record
GOTO DoNextEvent
