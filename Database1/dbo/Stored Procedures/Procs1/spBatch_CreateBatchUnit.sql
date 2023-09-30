--  Execute spBatch_CreateBatchUnit  1 ,Null ,Null,Null,'0288-DFM_DCM','Componenter', 'W_701', 1,1
CREATE PROCEDURE dbo.spBatch_CreateBatchUnit
 	 @EventTransactionId  	  	  	  	 int,
 	 @BatchUnitId  	  	  	  	  	  	  	  	 int OUTPUT,
 	 @BatchLineId  	  	  	  	  	  	  	  	 int, 
 	 @BatchDepartmentId  	  	  	  	  	 int, 
 	 @AreaName 	  	  	  	  	  	  	  	  	  	 nvarchar(100),
 	 @CellName 	  	  	  	  	  	  	  	  	  	 nvarchar(100),
 	 @UnitName 	  	  	  	  	  	  	  	  	  	 nvarchar(100),
 	 @UserId  	  	  	  	  	  	  	  	  	  	 int,
 	 @IsMainBatch 	  	  	  	  	  	  	  	 Int = 0,
 	 @Debug  	  	  	  	  	  	  	  	  	  	  	 int = NULL
AS
-------------------------------------------------------------------------------
-- Declare General Variables
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
Declare
 	  	 @ECId 	  	  	  	  	  	  	  	  	 int,
 	  	 @ECVId 	  	  	  	  	  	  	  	 int,
 	  	 @ModelId 	  	  	  	  	  	  	 int,
 	  	 @EventSubTypeId 	  	  	  	 int
 	  	 
Declare
  	   	 @Error  	    	    	    	   	 nvarchar(255),
    	 @Rc  	  	  	  	  	  	  	  	  	 int,
 	  	 @ID 	  	  	  	  	  	  	  	  	  	 Int
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START(spBatch_CreateBatchUnit)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_CreateBatchUnit /EventTransactionId: ' + Isnull(convert(nvarchar(10),@EventTransactionId),'Null') +
   	  	  	  	  	 ' /BatchUnitId: ' + Isnull(convert(nvarchar(10),@BatchUnitId),'Null') + ' /BatchLineId: ' + Isnull(convert(nvarchar(10),@BatchLineId),'Null') +
   	  	  	  	  	 ' /BatchDepartmentId: ' + Isnull(convert(nvarchar(10),@BatchDepartmentId),'Null') + ' /AreaName: ' + Isnull(@AreaName,'Null') +
   	  	  	  	  	 ' /CellName: ' + Isnull(@CellName,'Null') + ' /UnitName: ' + Isnull(@UnitName,'Null') +
   	  	  	  	  	 ' /UserId: ' + Isnull(convert(nvarchar(10),@UserId),'Null') + ' /Debug: ' + Isnull(convert(nvarchar(10),@Debug),'Null'))
  End
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
Select @Error = ''
Select @Rc = 0
-------------------------------------------------------------------------------
-- If Department Is Not Specified, Create One
-------------------------------------------------------------------------------
If @BatchDepartmentId Is Null and @BatchLineId Is Not Null
 	  	 SELECT @BatchDepartmentId = Dept_Id From Prod_Lines_Base Where PL_Id = @BatchLineId
If @BatchDepartmentId Is Null
BEGIN
 	 
    Select @BatchDepartmentId = Dept_Id
      From Departments_Base 
      Where Dept_Desc = @AreaName   
    If @BatchDepartmentId Is Null
      Begin
 	  	     -- Go ahead and create department
 	  	  	  	 exec spEM_CreateDepartment
 	  	  	  	  	 @AreaName, 
 	  	  	  	   @UserId, 
 	  	  	  	   @BatchDepartmentId OUTPUT
 	  	 
 	  	     If @BatchDepartmentId Is Null
 	  	       Begin
 	  	          Select @Error = 'Could Not Create Department [' + @AreaName + ']'  
 	  	          Goto errc
 	  	       End
      End 
END
-------------------------------------------------------------------------------
-- If Line Is Not Specified, Create One
-------------------------------------------------------------------------------
If @BatchLineId Is Null
  Begin
    Select @BatchLineId = PL_Id
      From Prod_Lines_Base
      Where PL_Desc = @CellName and 
            Dept_Id = @BatchDepartmentId   
    If @BatchLineId Is Null
      Begin
 	  	     -- Go ahead and create line
 	  	  	  	 exec spEM_CreateProdLine
 	  	  	  	  	 @CellName,
 	  	  	  	  	 @BatchDepartmentId,
 	  	  	  	  	 @UserId,
 	  	  	  	  	 @BatchLineId OUTPUT
 	  	     If @BatchLineId Is Null
 	  	       Begin
 	  	          Select @Error = 'Could Not Create Line [' + @CellName + ']'  
 	  	          Goto errc
 	  	       End
      End 
  End
-------------------------------------------------------------------------------
-- Add The Unit
-------------------------------------------------------------------------------
Select @BatchUnitId = PU_Id
  From Prod_Units_Base
  Where PU_Desc = @UnitName and 
        PL_Id = @BatchLineId  
If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'BatchUnitId:' + Isnull(Convert(nvarchar(10),@BatchUnitId),'Null'))
If @BatchUnitId Is Null
  Begin
    -- Go ahead and create unit
 	  	 EXEC 	 spEM_CreateProdUnit  
 	  	  	 @UnitName,
 	  	  	 @BatchLineId,
 	  	  	 @UserId,
 	  	  	 @BatchUnitId 	 OUTPUT
    If @BatchUnitId Is Null
      Begin
         Select @Error = 'Could Not Create Unit [' + @UnitName + ']'  
         Goto errc
      End
  End 
If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'BatchUnitId:' + Isnull(Convert(nvarchar(10),@BatchUnitId),'Null'))
-------------------------------------------------------------------------------
--  Set Key Unit Properties
-------------------------------------------------------------------------------
If @IsMainBatch = 1
 	 Begin
 	  	 If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Add Batch to BatchUnitId:' + Isnull(Convert(nvarchar(10),@BatchUnitId),'Null'))
 	  	 UPDATE 	 Prod_Units_Base
 	  	 SET 	 Uses_Start_Time  	 = 1,
 	  	  	  	 Chain_Start_Time  	 = 0 ,
 	  	  	  	 Extended_Info = 'BATCH:' 
 	  	 WHERE 	 PU_Id 	  	 = @BatchUnitId and ((Extended_Info <> 'BATCH:') or (Extended_Info Is Null) Or (Uses_Start_Time = 0) or (Chain_Start_Time  	 = 1) or (Uses_Start_Time Is Null) or (Chain_Start_Time Is Null)) 
 	 End
Else
  Begin
 	  	 UPDATE 	 Prod_Units_Base
 	  	 SET 	 Uses_Start_Time  	 = 1, 	 Chain_Start_Time  	 = 0 
 	  	 WHERE 	 PU_Id 	  	 = @BatchUnitId and ((Uses_Start_Time = 0) or (Chain_Start_Time  	 = 1) or (Uses_Start_Time Is Null) or (Chain_Start_Time Is Null))
 	 End
-------------------------------------------------------------------------------
-- Add Batch Event To Unit
-------------------------------------------------------------------------------
Select @ECId = NULL
Select @ECId = EC_Id,
       @ModelId = ed_Model_id,
       @EventSubTypeId = event_subtype_id
  From Event_Configuration 
  Where PU_Id = @BatchUnitId and
        ET_Id = 1
If @ECId Is Not Null
  Begin
    -- We Already Have A Production Event Configured, See If We Have A Model Already
    If @ModelId Is Not Null And @ModelId <> 100
      Begin
         Select @Error = 'Unit [' + @UnitName + '] Already Has A Non-Batch Model Configured, Aborting'  
         Goto errc
      End    
    If @ModelId = 100
      Begin
         Select @Error = 'Unit [' + @UnitName + '] Already Has A Batch Model Configured For A Different Unit, Aborting'  
         Goto errc
      End    
  End
Else
  Begin
    -- Go Ahead An Add Production Event To Unit
    -- Try To Find The "Batch" Event
    Select @EventSubTypeId = event_subtype_id
      From event_subtypes 
      Where et_id = 1 and
            event_subtype_desc = 'Batch'    
    -- Add New Event Subtype
    If @EventSubtypeId Is Null
      Begin
        Insert Into event_subtypes (et_id, event_subtype_desc, Dimension_X_Name, Dimension_X_Eng_Units)
          Values (1, 'Batch', 'Weight', 'Kg')
        Select @EventSubTypeId = Scope_Identity()
      End
    -- Add Batch Event To Unit
    Insert Into event_configuration (et_id, event_subtype_id, pu_id)
      Values  (1, @EventSubTypeId, @BatchUnitId)
    Select @ECId = Scope_Identity()
  End
-------------------------------------------------------------------------------
-- Add Model 118 To Batch Event
-------------------------------------------------------------------------------
If @ECId Is Null 
  Begin
     Select @Error = 'Could Not Associate Batch Event With Unit [' + @UnitName + ']'  
     Goto errc
  End
-- Clean Up Model Parameters To Make Sure
Delete From Event_Configuration_data where ec_id = @ECId
If @IsMainBatch = 0
 	 Begin
 	  	 -- Assign New Model: Model Id = 100, Num = 118
 	  	 Exec spEMEC_UpdateAssignModel
 	  	  	 @ECId,
 	  	  	 100,
 	  	  	 @BatchUnitId,
 	  	  	 @UserId
 	  	 
 	  	 
 	  	 
 	  	 -------------------------------------------------------------------------------
 	  	 -- Update Model Parameters
 	  	 -------------------------------------------------------------------------------
 	  	 
 	  	 
 	  	 --Update Area Parameter
 	  	 Select @ECVId = NULL
 	  	 SELECT 	 @ECVId = Ecv_Id 
 	  	  	 FROM 	 Event_Configuration_Data 
 	  	  	 WHERE 	 Ec_ID = @ECId and
 	  	  	       Ed_Field_Id = 2767
 	  	 
 	  	 UPDATE 	 Event_Configuration_Values 
 	  	  	 SET 	 Value = @AreaName 
 	  	  	 WHERE 	 Ecv_Id = @ECVId
 	  	 
 	  	 
 	  	 --Update Cell Parameter
 	  	 Select @ECVId = NULL
 	  	 SELECT 	 @ECVId = Ecv_Id 
 	  	  	 FROM 	 Event_Configuration_Data 
 	  	  	 WHERE 	 Ec_ID = @ECId and
 	  	  	       Ed_Field_Id = 2768
 	  	 
 	  	 UPDATE 	 Event_Configuration_Values 
 	  	  	 SET 	 Value = @CellName 
 	  	  	 WHERE 	 Ecv_Id = @ECVId
 	  	 
 	  	 --Update Unit Parameter
 	  	 Select @ECVId = NULL
 	  	 SELECT 	 @ECVId = Ecv_Id 
 	  	  	 FROM 	 Event_Configuration_Data 
 	  	  	 WHERE 	 Ec_ID = @ECId and
 	  	  	       Ed_Field_Id = 2769
 	  	 
 	  	 UPDATE 	 Event_Configuration_Values 
 	  	  	 SET 	 Value = @UnitName 
 	  	  	 WHERE 	 Ecv_Id = @ECVId
 	 End
Finish:
-------------------------------------------------------------------------------
-- Normal exit
-------------------------------------------------------------------------------
Select @Rc = 1
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_CreateBatchUnit)')
RETURN(@Rc)
-------------------------------------------------------------------------------
-- Handle exceptions
-------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	  	 = @Error,
 	  	 OrphanedFlag  	  	 = 1 
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
Select @BatchUnitId = NULL
If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
If @Debug = 1     Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_CreateBatchUnit)')
Print @Error
RETURN(-100)
