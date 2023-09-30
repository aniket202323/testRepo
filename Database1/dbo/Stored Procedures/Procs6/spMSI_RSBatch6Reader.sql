CREATE   Procedure dbo.spMSI_RSBatch6Reader
@ReturnStatus int OUTPUT,
@ReturnMessage varchar(255) OUTPUT,
@UpdateStatement Varchar(255) OUTPUT,
@LclTime datetime,
@BatchID varchar (125),
@Recipe varchar (125),
@Descript varchar (125),
@Event varchar (125),
@PValue varchar (125),
@EU varchar (125),
@Area varchar (125),
@ProcCell varchar (125),
@Unit varchar (125),
@Phase varchar (125),
@UniqueID varchar (12),
@PhaseDesc varchar (125),
@UserID varchar (255),
@RecpType varchar (50),
@Sequence int,
@ServerName varchar (64)
AS
Declare @Testing  	  	 int
Declare @SQL  	  	  	 varchar(3000)
Declare @ProductCodeParameter 	 varchar(255)
--*************************************************************
-- Set Initial Values
--*************************************************************
Select @ReturnStatus = 1
Select @ReturnMessage = ''
Select @UpdateStatement = ''
Select @ProductCodeParameter 	 = 'Product Code'
Select @UpdateStatement = 'Delete From BatchAnalysis Where Sequence = ' + Convert(Varchar(25),@Sequence) + 'And UniqueId = ' + Convert(Varchar(25),@UniqueID)
--*************************************************************
-- Create Temporary Table For Event Transactions
--*************************************************************
Create Table #BatchEvents (
  EventTimeStamp  	  	 datetime,
  EventType  	  	  	 varchar(255) NULL,
  AreaName  	  	  	 varchar(255) NULL,
  CellName  	  	  	 varchar(255) NULL,
  UnitName  	  	  	 varchar(255) NULL,
  BatchName  	  	  	 varchar(255) NULL,
  BatchProductCode  	  	 varchar(255) NULL,
  UnitProcedureName 	  	 varchar(255) NULL,
  OperationName 	  	  	 varchar(255) NULL,
  PhaseName 	  	  	 varchar(255) NULL,
  PhaseInstance 	  	  	 varchar(255) NULL,
  ProcedureStartTime 	  	 datetime NULL,
  ProcedureEndTime 	  	 datetime NULL,
  ParameterName 	  	  	 varchar(255) NULL,
  ParameterAttributeName 	 varchar(255) NULL,
  ParameterAttributeUOM 	  	 varchar(255) NULL,
  ParameterAttributeValue 	 varchar(255) NULL,
  RawMaterialAreaName 	  	 varchar(255) NULL,
  RawMaterialCellName 	  	 varchar(255) NULL,
  RawMaterialUnitName 	  	 varchar(255) NULL,
  RawMaterialProductCode 	 varchar(255) NULL,
  RawMaterialBatchName 	  	 varchar(255) NULL,
  RawMaterialContainerId 	 varchar(255) NULL,
  RawMaterialDimensionA 	  	 float NULL,
  RawMaterialDimensionX 	  	 float NULL,
  RawMaterialDimensionY 	  	 float NULL,
  RawMaterialDimensionZ 	  	 float NULL,
  StateValue 	  	  	 varchar(255) NULL,
  EventName 	  	  	 varchar(255) NULL,
  UserName 	  	  	 varchar(255) NULL,
  UserSignature 	  	  	 varchar(255) NULL,
  RecipeString 	  	  	 varchar(255) NULL,
  RecordNumber  	  	  	 int
)
--*************************************************************
-- Load Available Transactions Into Temporary Table
--*************************************************************
Insert Into #BatchEvents (
  EventTimeStamp,
  EventType,
  AreaName,
  CellName,
  UnitName,
  BatchName,
  BatchProductCode,
  UnitProcedureName,
  OperationName,
  PhaseName,
  PhaseInstance,
  ProcedureStartTime,
  ProcedureEndTime,
  ParameterName,
  ParameterAttributeName,
  ParameterAttributeUOM,
  ParameterAttributeValue,
  RawMaterialAreaName,
  RawMaterialCellName,
  RawMaterialUnitName,
  RawMaterialProductCode,
  RawMaterialBatchName,
  RawMaterialContainerId,
  RawMaterialDimensionA,
  RawMaterialDimensionX,
  RawMaterialDimensionY,
  RawMaterialDimensionZ,
  StateValue,
  EventName,
  UserName,
  UserSignature,
  RecipeString,
  RecordNumber)
Select EventTimeStamp = @lcltime,
 	  	  	   EventType = NULL,
 	  	  	   AreaName = @Area,
 	  	  	   CellName = @ProcCell,
 	  	  	   UnitName = @Unit,
 	  	  	   BatchName = @BatchID,
 	  	  	   BatchProductCode = NULL,
                          UnitProcedureName = case when charindex('\',@Recipe,1) = 0 Then NULL Else substring(@Recipe, charindex('\',@Recipe,1)+1,charindex('-',@Recipe,1) - (charindex('\',@Recipe,1)+1)) End,
                          OperationName = NULL,
 	  	  	   PhaseName = @Phase,
 	  	  	   PhaseInstance = NULL,
 	  	  	   ProcedureStartTime = NULL,
 	  	  	   ProcedureEndTime = NULL,
 	  	  	   ParameterName = @Descript,
 	  	  	   ParameterAttributeName = NULL,
 	  	  	   ParameterAttributeUOM = @EU,
 	  	  	   ParameterAttributeValue = @PValue,
 	  	  	   RawMaterialAreaName = NULL,
 	  	  	   RawMaterialCellName = NULL,
 	  	  	   RawMaterialUnitName = NULL,
 	  	  	   RawMaterialProductCode = NULL,
 	  	  	   RawMaterialBatchName = NULL,
 	  	  	   RawMaterialContainerId = NULL,
 	  	  	   RawMaterialDimensionA = NULL,
 	  	  	   RawMaterialDimensionX = NULL,
 	  	  	   RawMaterialDimensionY = NULL,
 	  	  	   RawMaterialDimensionZ = NULL,
 	  	  	   StateValue = NULL,
 	  	  	   EventName = @Event,
 	  	  	   UserName = @UserID,
 	  	  	   UserSignature = NULL,
 	  	  	   RecipeString = @Recipe,
 	  	  	   RecordNumber = @Sequence
--*************************************************************
-- Parse Recipe Strings To Expose UP, OP, Phase Instance
--*************************************************************
Update #BatchEvents
  Set UnitProcedureName = Case 
                            When charindex(':',UnitProcedureName,1) = 0 Then 
                              UnitProcedureName 
                            Else 
                              substring(UnitProcedureName,1,charindex(':',UnitProcedureName,1)-1) 
                            End,
      OperationName = Case 
                        When charindex('\',UnitProcedureName,1) = 0 Then 
                          NULL 
                        Else 
                          substring(UnitProcedureName, charindex('\',UnitProcedureName,1)+1, 1000)
                        End
Update #BatchEvents
  Set OperationName = Case 
                        When charindex(':',OperationName,1) = 0 Then 
                          OperationName 
                        Else 
                          substring(OperationName,1,charindex(':',OperationName,1)-1) 
                      End,
      PhaseName = Case 
                    When charindex('\',OperationName,1) = 0 Then 
                      NULL 
                    Else 
                      substring(OperationName, charindex('\',OperationName,1)+1, 1000)
                  End
Update #BatchEvents
  Set PhaseName = Case 
                    When charindex(':',PhaseName,1) = 0 Then 
                      PhaseName 
                    Else 
                      substring(PhaseName,1,charindex(':',PhaseName,1)-1) 
                   End,
      PhaseInstance = Case 
                        When charindex(':',PhaseName,1) = 0 Then 
                          Case When PhaseName Is Not Null Then 1 Else NULL End 
                        Else 
                          convert(int, substring(PhaseName,charindex(':',PhaseName,1)+1,1000))
                       End
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Unsupported Events
Step Activity
Event File Name
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
--*************************************************************
-- Move Batch Header Information To "First" Unit
--*************************************************************
Declare @@BatchName varchar(255)
Declare @@AreaName varchar(255)
Declare @MinTime datetime
Declare @CellName varchar(255)
Declare @UnitName varchar(255)
Declare Batch_Cursor Insensitive Cursor 
  For Select Distinct BatchName, AreaName From #BatchEvents Where (UnitName Is Null Or UnitName = '') --and EventName = 	 'Recipe Header'
  For Read Only
Open Batch_Cursor
Fetch Next From Batch_Cursor Into @@BatchName, @@AreaName
While @@Fetch_Status = 0
  Begin
    Select @MinTime = NULL
    Select @MinTime = min(EventTimeStamp)
      From #BatchEvents
      Where BatchName = @@BatchName and
            AreaName = @@AreaName and
            UnitName Is Not Null and 
            UnitName <> ''
    If @MinTime Is Not Null
      Begin
        Select @UnitName = NULL
        Select @Cellname = NULL
        Select @CellName = CellName, 
               @UnitName = UnitName
          From #BatchEvents 
          Where EventTimeStamp = @MinTime and
                BatchName = @@Batchname and
                AreaName = @@AreaName and 
                UnitName Is Not Null and
                UnitName <> ''
        If @UnitName Is Not Null and @CellName Is Not Null
          Begin
 	           Update #BatchEvents
 	             Set UnitName = @UnitName,
 	                 CellName = @CellName,
                  EventTimeStamp = dateadd(second,-1,@MinTime)
 	             Where BatchName = @@BatchName and
 	                   AreaName = @@AreaName and 
 	  	  	  	             ((UnitName Is Null) or 
 	  	  	  	             (UnitName = ''))
             If @Testing = 1 
               Select 'Updating Header For Batch ' + @@BatchName
           End
         Else
           Begin
             If @Testing = 1 
               Select 'Failed To Update Header For Batch ' + @@BatchName
           End   
      End    
 	  	 Fetch Next From Batch_Cursor Into @@BatchName, @@AreaName
  End
Close Batch_Cursor
Deallocate Batch_Cursor
--*************************************************************
-- Convert "Product" Batch Header Parameter Into Procedure Report
--*************************************************************
Update #BatchEvents
  Set EventName = NULL,
      EventType = 'ProcedureReport',
 	  	  	 BatchProductCode = ParameterAttributeValue,
      StateValue = 'SETUP',  --TODO:????
 	  	   ParameterName = NULL,
 	  	   ParameterAttributeName = NULL,
 	  	   ParameterAttributeUOM = NULL,
 	  	   ParameterAttributeValue = NULL
  Where EventName = 	 'Recipe Header' and
        (ParameterName = @ProductCodeParameter) or (ParameterName = 'Product Code')
--TODO: Need to support "null" statevalue to just advance batch end time, no status change, update product code
--TODO: What About Product Code On Each Unit Besides The Start Unit?
--*************************************************************
-- Prepare Procedure Reports
--*************************************************************
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Supported Events
State Change
State Command
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
Update #BatchEvents
  Set EventName = NULL,
      EventType = 'ProcedureReport',
      StateValue = ParameterAttributeValue,
 	  	   ParameterName = NULL,
 	  	   ParameterAttributeName = NULL,
 	  	   ParameterAttributeUOM = NULL,
 	  	   ParameterAttributeValue = NULL
  Where EventName in (
 	  	  	 'State Change',
 	  	  	 'State Command'
                     )
--*************************************************************
-- Prepare Recipe Setups
--*************************************************************
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- Supported Events
Recipe Value Change
Recipe Value
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
Update #BatchEvents
  Set EventName = NULL,
      EventType = 'RecipeSetup',
 	  	   ParameterAttributeName = 'Target',
 	  	   RawMaterialProductCode = NULL,
 	  	   RawMaterialBatchName = NULL,
 	  	   RawMaterialContainerId = NULL
  Where EventName in (
 	  	  	 'Recipe Value Change',
 	  	  	 'Recipe Value'
 	  	      ) 	 
--*************************************************************
-- Prepare Parameter Reports
--*************************************************************
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- Supported Events
Recipe Header
Report
Scale Factor
Param Download Verified
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
Update #BatchEvents
  Set EventName = NULL,
      EventType = 'ParameterReport',
 	  	   ParameterAttributeName = 'Value',
 	  	   RawMaterialProductCode = NULL,
 	  	   RawMaterialBatchName = NULL,
 	  	   RawMaterialContainerId = NULL
  Where EventName in (
 	  	  	 'Recipe Header',
 	  	  	 'Report',
 	  	  	 'Scale Factor',
 	  	  	 'Param Download Verified'
                     )
--*************************************************************
-- Process Material Movements
--*************************************************************
Insert Into #BatchEvents (
  EventTimeStamp,
  EventType,
  AreaName,
  CellName,
  UnitName,
  BatchName,
  BatchProductCode,
  UnitProcedureName,
  OperationName,
  PhaseName,
  PhaseInstance,
  ProcedureStartTime,
  ProcedureEndTime,
  ParameterName,
  ParameterAttributeName,
  ParameterAttributeUOM,
  ParameterAttributeValue,
  RawMaterialAreaName,
  RawMaterialCellName,
  RawMaterialUnitName,
  RawMaterialProductCode,
  RawMaterialBatchName,
  RawMaterialContainerId,
  RawMaterialDimensionA,
  RawMaterialDimensionX,
  RawMaterialDimensionY,
  RawMaterialDimensionZ,
  StateValue,
  EventName,
  UserName,
  UserSignature,
  RecipeString,
 	 RecordNumber
)
Select 
 	   EventTimeStamp = EventTimeStamp,
 	   EventType = 'MaterialMovement',
 	   AreaName = AreaName,
 	   CellName = CellName,
 	   UnitName = UnitName,
 	   BatchName = BatchName,
 	   BatchProductCode = BatchProductCode,
 	   UnitProcedureName = UnitProcedureName,
 	   OperationName = OperationName,
 	   PhaseName = PhaseName,
 	   PhaseInstance = PhaseInstance,
 	   ProcedureStartTime = ProcedureStartTime,
 	   ProcedureEndTime = ProcedureEndTime,
 	   ParameterName = NULL,
 	   ParameterAttributeName = NULL,
 	   ParameterAttributeUOM = NULL,
 	   ParameterAttributeValue = NULL,
 	   RawMaterialAreaName = NULL,
 	   RawMaterialCellName = NULL,
 	   RawMaterialUnitName = NULL,
 	   RawMaterialProductCode = RawMaterialProductCode,
 	   RawMaterialBatchName = RawMaterialBatchName,
 	   RawMaterialContainerId = RawMaterialContainerId,
 	   RawMaterialDimensionA = NULL,
 	   RawMaterialDimensionX = NULL,
 	   RawMaterialDimensionY = NULL,
 	   RawMaterialDimensionZ = NULL,
 	   StateValue = NULL,
 	   EventName = NULL,
 	   UserName = UserName,
 	   UserSignature = UserSignature,
 	   RecipeString = RecipeString,
 	   RecordNumber = RecordNumber
  From #BatchEvents 
  Where EventType = 'ProcedureReport' and
        RawMaterialBatchName Is Not Null and
        RawMaterialBatchName <> ''
Update #BatchEvents
  Set RawMaterialProductCode = NULL,
 	  	   RawMaterialBatchName = NULL,
 	  	   RawMaterialContainerId = NULL
  Where EventType = 'ProcedureReport' and
        RawMaterialBatchName Is Not Null and
        RawMaterialBatchName <> ''
--*************************************************************
-- Process "Other" Events
--*************************************************************
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- Supported Events
Unit Verified
System Message
Owner Change
Creation Bind
Arbitration
Attribute Change
Batch Deletion
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
--TODO: Create User Defined Events
--*************************************************************
-- Purge Unsupported Events
--*************************************************************
If @Testing = 1
  Select * From #BatchEvents
  Where Eventtype Is Null or
        UnitName Is Null or 
        UnitName = ''
/**
Declare @@RecordNumber int
Declare Unsupported_Cursor Insensitive Cursor 
  For Select Distinct RecordNumber 
        From #BatchEvents
 	  	  	   Where Eventtype Is Null or
 	  	  	         UnitName Is Null or 
 	  	  	         UnitName = ''
  For Read Only
Open Unsupported_Cursor
Fetch Next From Unsupported_Cursor Into @@RecordNumber
While @@Fetch_Status = 0
  Begin
    Select @SQL = 'Update ' + @TableName + ' Set lcltime = dateadd(year,10,lcltime) Where ' + @Fieldname + ' = ' + convert(varchar(25),@@RecordNumber)
    If @Testing = 1 
      Select @SQL
    Else
      Exec (@SQL)
 	  	 Fetch Next From Unsupported_Cursor Into @@RecordNumber
  End
Close Unsupported_Cursor
Deallocate Unsupported_Cursor
**/
Delete From #BatchEvents 
  Where Eventtype Is Null or
        UnitName Is Null or 
        UnitName = ''
If @Testing = 1
  Select * From #BatchEvents
--*************************************************************
-- Move Temporary Transactions To Event_Transactions
--*************************************************************
Insert Into Event_Transactions (
  EventTimeStamp,
  EventType,
  AreaName,
  CellName,
  UnitName,
  BatchName,
  BatchProductCode,
  UnitProcedureName,
  OperationName,
  PhaseName,
  PhaseInstance,
  ProcedureStartTime,
  ProcedureEndTime,
  ParameterName,
  ParameterAttributeName,
  ParameterAttributeUOM,
  ParameterAttributeValue,
  RawMaterialAreaName,
  RawMaterialCellName,
  RawMaterialUnitName,
  RawMaterialProductCode,
  RawMaterialBatchName,
  RawMaterialContainerId,
  RawMaterialDimensionA,
  RawMaterialDimensionX,
  RawMaterialDimensionY,
  RawMaterialDimensionZ,
  StateValue,
  EventName,
  UserName,
  UserSignature,
  RecipeString,
  ProcessedFlag,
  OrphanedFlag
)
Select 
 	   EventTimeStamp,
 	   EventType,
 	   AreaName,
 	   CellName,
 	   UnitName,
 	   BatchName,
 	   BatchProductCode,
 	   UnitProcedureName,
 	   OperationName,
 	   PhaseName,
 	   PhaseInstance,
 	   ProcedureStartTime,
 	   ProcedureEndTime,
 	   ParameterName,
 	   ParameterAttributeName,
 	   ParameterAttributeUOM = convert(varchar(15),ParameterAttributeUOM),
 	   ParameterAttributeValue = convert(varchar(25),ParameterAttributeValue),
 	   RawMaterialAreaName,
 	   RawMaterialCellName,
 	   RawMaterialUnitName,
 	   RawMaterialProductCode,
 	   RawMaterialBatchName,
 	   RawMaterialContainerId,
 	   RawMaterialDimensionA,
 	   RawMaterialDimensionX,
 	   RawMaterialDimensionY,
 	   RawMaterialDimensionZ,
 	   StateValue,
 	   EventName,
 	   UserName,
 	   UserSignature,
 	   RecipeString,
    ProcessedFlag = 0,
    OrphanedFlag = 0
  From #BatchEvents 
--*************************************************************
-- Purge Processed Transactions From BATCHHIS
--*************************************************************
/**
Declare Record_Cursor Insensitive Cursor 
  For Select Distinct RecordNumber From #BatchEvents
  For Read Only
Open Record_Cursor
Fetch Next From Record_Cursor Into @@RecordNumber
While @@Fetch_Status = 0
  Begin
    Select @SQL = 'Delete From ' + @TableName + ' Where ' + @Fieldname + ' = ' + convert(varchar(25),@@RecordNumber)
    If @Testing = 1 
      Select @SQL
    Else
      Exec (@SQL)
 	  	 Fetch Next From Record_Cursor Into @@RecordNumber
  End
Close Record_Cursor
Deallocate Record_Cursor
**/
--*************************************************************
-- Finish
--*************************************************************
Drop Table #BatchEvents 
