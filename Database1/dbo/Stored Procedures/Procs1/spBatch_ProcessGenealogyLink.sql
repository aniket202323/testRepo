CREATE 	 PROCEDURE dbo.spBatch_ProcessGenealogyLink 
 	 @EventTransactionId 	 Int,
 	 @UserId 	  	  	  	 Int,
 	 @Debug 	  	  	  	 int = NULL
AS
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
-------------------------------------------------------------------------------
-- Declare General Variables
-------------------------------------------------------------------------------
DECLARE
 	 @EventTimeStamp 	  	  	  	  	  	  	  	 DateTime,
 	 @ParentAreaName 	  	  	  	  	  	  	  	 nVarChar(100),
 	 @ParentCellName 	  	  	  	  	  	  	  	 nVarChar(100),
 	 @ParentUnitName 	  	  	  	  	  	  	  	 nVarChar(100),
 	 @ParentBatchName 	  	  	  	  	  	  	 nVarChar(50),
 	 @ChildAreaName 	  	  	  	  	  	  	  	 nVarChar(100),
 	 @ChildCellName 	  	  	  	  	  	  	  	 nVarChar(100),
 	 @ChildUnitName 	  	  	  	  	  	  	  	 nVarChar(100),
 	 @ChildBatchName 	  	  	  	  	  	  	  	 nVarChar(50),
 	 @Error 	  	  	  	  	  	  	  	  	  	 nVarChar(255),
 	 @RC 	  	  	  	  	  	  	  	  	  	  	 Int,
 	 @Id 	  	  	  	  	  	  	  	  	  	  	 Int,
 	 @TransType 	  	  	  	  	  	  	  	  	 Int,
 	 @TransNum 	  	  	  	  	  	  	  	  	 Int,
 	 @ParentEventId 	  	  	  	  	  	  	  	 int = Null,
 	 @ParentUnitId 	  	  	  	  	  	  	  	 int = Null,
 	 @ChildEventId 	  	  	  	  	  	  	  	 int = Null,
 	 @ChildUnitId 	  	  	  	  	  	  	  	 int = Null,
 	 @ComponentId 	  	  	  	  	  	  	  	 int = Null,
 	 @DimensionX 	  	  	  	  	  	  	  	  	 Float = Null,
 	 @DimensionY 	  	  	  	  	  	  	  	  	 Float = Null,
 	 @DimensionZ 	  	  	  	  	  	  	  	  	 Float = Null,
 	 @DimensionA 	  	  	  	  	  	  	  	  	 Float = Null,
 	 @Start_Coordinate_X 	  	  	  	  	  	  	 Float = Null,
 	 @Start_Coordinate_Y 	  	  	  	  	  	  	 Float = Null,
 	 @Start_Coordinate_Z 	  	  	  	  	  	  	 Float = Null,
 	 @Start_Coordinate_A 	  	  	  	  	  	  	 Float = Null,
 	 @Start_Time 	  	  	  	  	  	  	  	  	 DateTime = Null,
 	 @Entry_On 	  	  	  	  	  	  	  	  	 DateTime = Null,
 	 @PEI_Id 	  	  	  	  	  	  	  	  	  	 Int = Null
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START (spBatch_ProcessGenealogyLink)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_ProcessGenealogyLink /EventTransactionId: ' + Isnull(convert(nvarchar(10),@EventTransactionId),'Null') + 
 	   ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null') + ' /Debug: ' + isnull(convert(nvarchar(10),@Debug),'Null'))
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
 	  	 @ParentAreaName 	  	  	 = LTrim(RTrim(RawMaterialAreaName)),
 	  	 @ParentCellName 	  	  	 = LTrim(RTrim(RawMaterialCellName)),
 	  	 @ParentUnitName 	  	  	 = LTrim(RTrim(RawMaterialUnitName)),
 	  	 @ParentBatchName 	  	 = LTrim(RTrim(RawMaterialBatchName)),
 	  	 @ChildAreaName 	  	  	 = LTrim(RTrim(AreaName)),
 	  	 @ChildCellName 	  	  	 = LTrim(RTrim(CellName)),
 	  	 @ChildUnitName 	  	  	 = LTrim(RTrim(UnitName)),
 	  	 @ChildBatchName 	  	  	 = LTrim(RTrim(BatchName)),
 	  	 @DimensionX 	  	  	  	 = RawMaterialDimensionX,
 	  	 @DimensionY 	  	  	  	 = RawMaterialDimensionY,
 	  	 @DimensionZ 	  	  	  	 = RawMaterialDimensionZ,
 	  	 @DimensionA 	  	  	  	 = RawMaterialDimensionA
 	 FROM 	 Event_Transactions 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
-------------------------------------------------------------------------------
-- Check record
-------------------------------------------------------------------------------
IF 	 @ParentAreaName = '' 	 SELECT @ParentAreaName = Null
IF 	 @ParentCellName = '' 	 SELECT @ParentCellName = Null
IF 	 @ParentUnitName = '' 	 SELECT @ParentUnitName = Null
IF 	 @ParentBatchName = '' 	 SELECT @ParentBatchName = Null
IF 	 @ChildAreaName = '' 	  	 SELECT @ChildAreaName = Null
IF 	 @ChildCellName = '' 	  	 SELECT @ChildCellName = Null
IF 	 @ChildUnitName = '' 	  	 SELECT @ChildUnitName = Null
IF 	 @ChildBatchName = '' 	 SELECT @ChildBatchName = Null
-------------------------------------------------------------------------------
-- Lookup Parent Event Id
-------------------------------------------------------------------------------
Select @ParentEventId = Null
Select @ParentEventId = e.Event_Id, @ParentUnitId = u.PU_Id
  from Events e
  join Prod_Units_Base u on u.PU_Id = e.PU_Id
  join Prod_Lines_Base l on l.PL_Id = u.PL_Id
  join Departments_Base d on d.Dept_Id = l.Dept_Id
  where d.Dept_Desc 	 = @ParentAreaName and
 	  	 l.PL_Desc 	 = @ParentCellName and
 	  	 u.PU_Desc 	 = @ParentUnitName and
 	  	 e.Event_Num = @ParentBatchName
IF 	 @ParentEventId is Null 
BEGIN
 	 SELECT 	 @Error = 'Cannot find Parent Event'
 	 GOTO 	 Errc
END
-------------------------------------------------------------------------------
-- Lookup Child Event ID
-------------------------------------------------------------------------------
Select @ChildEventId = Null
Select @ChildEventId = e.Event_Id, @ChildUnitId = u.PU_Id
  from Events e
  join Prod_Units_Base u on u.PU_Id = e.PU_Id
  join Prod_Lines_Base l on l.PL_Id = u.PL_Id
  join Departments_Base d on d.Dept_Id = l.Dept_Id
  where d.Dept_Desc 	 = @ChildAreaName and
 	  	 l.PL_Desc 	 = @ChildCellName and
 	  	 u.PU_Desc 	 = @ChildUnitName and
 	  	 e.Event_Num = @ChildBatchName
IF 	 @ChildEventId is Null 
BEGIN
 	 SELECT 	 @Error = 'Cannot find Child Event'
 	 GOTO 	 Errc
END
-------------------------------------------------------------------------------
-- Make sure link doesn't allready exist
-------------------------------------------------------------------------------
IF 	 Exists(Select 1 from Event_Components where Event_Id = @ChildEventId and Source_Event_Id = @ParentEventId and Timestamp = @EventTimeStamp)
BEGIN
 	 SELECT 	 @Error = 'Genealogy Link allready exists'
 	 GOTO 	 Errc
END
-------------------------------------------------------------------------------
-- Create Event Component Record
-------------------------------------------------------------------------------
-- Dimensions?   Do we decrement the source event?
 	 Set @TransType = 1 -- Add
 	 Set @TransNum = 0 -- Coallesce
 	 EXEC dbo.spServer_DBMgrUpdEventComp
 	  	 @UserId,
 	  	 @ChildEventId Output,
 	  	 @ComponentId Output,
 	  	 @ParentEventId Output, 
 	  	 @DimensionX Output,
 	  	 @DimensionY Output,
 	  	 @DimensionZ Output,
 	  	 @DimensionA Output,
 	  	 @TransNum,
 	  	 @TransType,
 	  	 @ChildUnitId Output,
 	  	 @Start_Coordinate_X Output,
 	  	 @Start_Coordinate_Y Output,
 	  	 @Start_Coordinate_Z Output,
 	  	 @Start_Coordinate_A Output,
 	  	 @Start_Time,
 	  	 @EventTimeStamp,
 	  	 Null, -- Parent Component Id
 	  	 @Entry_On Output,
 	  	 Null, -- Extended Info
 	  	 @PEI_Id Output,
 	  	 Null, -- ReportAsConsumption
 	  	 Null, -- SignatureId
 	  	 1 -- SendPost
-------------------------------------------------------------------------------
-- Normal Exit
-------------------------------------------------------------------------------
Select @Rc = 1
If @Debug = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessGenealogyLink)')
RETURN(@Rc)
-------------------------------------------------------------------------------
-- Handle exceptions
-------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	  	 = coalesce(OrphanedReason, @Error),
 	  	 OrphanedFlag 	  	 = 1 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
If @Debug = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_ProcessGenealogyLink)')
If @Debug = 1    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID,  @Error)
RETURN(-100)
