CREATE 	 PROCEDURE dbo.spBatch_GetSingleVariable
 	 @EventTransactionId 	  	  	  	 Int,
 	 @VariableId  	  	  	  	  	 int OUTPUT,
 	 @BatchName  	  	  	  	  	 nvarchar(50) OUTPUT,
 	 @BatchUnitId 	  	  	  	  	 int,
 	 @BatchProcedureUnitId 	  	  	 int,
 	 @BatchProcedureGroupId 	  	  	 int,
 	 @BatchStartTime 	  	  	  	 datetime OUTPUT,
 	 @BatchEndTime 	  	  	  	  	 datetime OUTPUT, 	  	  	  	 
 	 @BatchProductId  	  	  	  	 int OUTPUT,
 	 @GetProductFlag 	  	  	  	 int,
 	 @UnitProcedureName  	    	    	  	 nvarchar(50),
 	 @OperationName  	    	    	    	 nvarchar(50),
 	 @PhaseName  	    	    	    	   	 nvarchar(50),
 	 @PhaseInstance 	  	  	  	  	 Int,
 	 @ParameterName  	    	    	    	 nvarchar(50),
 	 @ParameterAttributeUOM 	  	  	 nvarchar(50),
 	 @DataType 	  	  	  	  	  	 int,
 	 @ParameterType 	  	  	  	  	 nvarchar(25) OUTPUT,
 	 @VarUOM 	  	  	  	  	  	 nvarchar(15) OUTPUT,
 	 @VarPercision 	  	  	  	  	 Int 	 OUTPUT,
 	 @UserId 	  	  	  	  	  	 int,
 	 @Debug 	  	  	  	  	  	 int = NULL
AS
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
SET 	 @BatchStartTime 	 = DATEADD(MS, -DATEPART(MS, @BatchStartTime), @BatchStartTime)
SET 	 @BatchEndTime 	 = DATEADD(MS, -DATEPART(MS, @BatchEndTime), @BatchEndTime)
Declare @ID Int
--Select  @Debug = 1 
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START (spBatch_GetSingleVariable)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_GetSingleVariable /EventTransactionId: ' + Isnull(convert(nvarchar(10),@EventTransactionId),'Null') + ' /VariableId: ' + IsNull(convert(nvarchar(10),@VariableId),'Null') + 
 	 ' /BatchName: ' + isnull(@BatchName,'Null') + ' /@BatchUnitId: ' + isnull(convert(nvarchar(10),@BatchUnitId),'Null') + 
 	 ' /BatchProcedureUnitId: ' + isnull(convert(nvarchar(10),@BatchProcedureUnitId),'Null') + ' /BatchProcedureGroupId: ' + isnull(convert(nvarchar(10),@BatchProcedureGroupId),'Null') + 
 	 ' /BatchStartTime: ' + isnull(convert(nvarchar(25),@BatchStartTime),'Null') + ' /BatchEndTime: ' + isnull(convert(nvarchar(25),@BatchEndTime),'Null') + 
 	 ' /BatchProductId: ' + isnull(convert(nvarchar(10),@BatchProductId),'Null') + ' /GetProductFlag: ' + isnull(convert(nvarchar(10),@GetProductFlag),'Null') + 
 	 ' /UnitProcedureName: ' + isnull(@UnitProcedureName,'Null') + ' /OperationName: ' + isnull(@OperationName,'Null') + 
 	 ' /PhaseName: ' + isnull(@PhaseName,'Null') + ' /ParameterName: ' + isnull(@ParameterName,'Null') + 
 	 ' /ParameterAttributeUOM: ' + isnull(@ParameterAttributeUOM,'Null') + ' /DataType: ' + isnull(convert(nvarchar(10),@DataType),'Null') + 
 	 ' /ParameterType: ' + isnull(@ParameterType,'Null') + ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null') + 
  ' /Debug: ' + isnull(convert(nvarchar(10),@Debug),'Null'))
  End
-------------------------------------------------------------------------------
-- Declare General Variables
-------------------------------------------------------------------------------
Declare 
    	  @EventId  	  	  	 int,
  	  @ChildUnitDesc  	    	 nvarchar(100),
  	  @VarInputTag  	    	   	 nvarchar(255),
  	  @VarDescription  	    	 nvarchar(255),
 	  @VarCount 	  	  	 int,
 	  @MyPUId 	  	  	  	 int,
 	  @MyPUGId 	  	  	  	 Int,
 	  @PUGDesc 	  	  	  	 nvarchar(50),
 	  @MyVarDescription 	  	 nvarchar(50),
 	  @EventSubtypeId 	  	 Int,
 	  @GroupOrder 	  	  	 Int,
 	  @EventType 	  	  	 nvarchar(25),
 	  @ESID 	  	  	  	 Int,
 	  @ReportType 	  	  	 nvarchar(100),
 	  @ETID 	  	  	  	 Int,
 	  @UDEDesc 	  	  	  	 nvarchar(255),
 	  @UDEEventId 	  	  	 Int,
 	  @EventNum 	  	  	 nvarchar(255),
 	  @OldDataType 	  	  	 Int
 	 Select 	 @EventType  	  	 = EventType, @ReportType =EventReportType
 	  	 From Event_Transactions
 	 WHERE 	 EventTransactionId  	 = @EventTransactionId
If @EventType = 'EventReport'
 	 BEGIN
 	  	 SELECT @ESID =  Event_Subtype_Id,@ETID = 14 From Event_Subtypes where Event_Subtype_Desc = @ReportType
 	 END
Declare
  	  @Error  	    	    	    	   	 nvarchar(255),
   @Rc  	  	  	  	  	  	  	  	  	  	 int,
 	  @SpReturn 	  	  	  	  	  	  	 Int
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
Select @Error = ''
Select @Rc = 0
Select @VariableId = NULL
Select @EventId = NULL
Select @BatchProductId = NULL
-------------------------------------------------------------------------------
-- Validate Inputs
-------------------------------------------------------------------------------
If @BatchUnitId Is Null
  Begin
    Select @Error = 'Unit Not Specified For Get Variable'
    Goto errc
  End
-------------------------------------------------------------------------------
-- Find Timestamp Of Batch - Used For All Data Timestamps
-------------------------------------------------------------------------------
If @BatchName is Null /* Select Current Batch */
  Begin
    Select @BatchEndTime = Max(TimeStamp) 
      From Events 
      Where PU_Id = @BatchUnitId and
            Timestamp <= @BatchEndTime
    Select @EventId = Event_Id,
           @BatchName = Event_Num,
           @BatchStartTime = start_time,
           @BatchEndTime = Timestamp,
           @BatchProductId = applied_product
      From Events 
      Where TimeStamp = @BatchEndTime and 
            PU_Id = @BatchUnitId 
    IF @EventId is null
      Begin
 	  	  	   	  Select @Error = 'Unable to find current batch'
 	  	  	   	  Goto Errc
      End
  End
Else
  Begin
    Select @EventId = Event_Id,
           @BatchName = Event_Num,
           @BatchStartTime = start_time,
           @BatchEndTime = Timestamp, 
           @BatchProductId = applied_product
      From Events 
      Where PU_Id = @BatchUnitId and 
            Event_Num = @BatchName
    IF @EventId is null
      Begin
        Select @Error = 'Unable to find specified batch [' + @BatchName + '] On Unit [' + convert(nvarchar(10),@BatchUnitId)  + ']'
        Goto Errc
      End
  End
-------------------------------------------------------------------------------
-- Check The Current Product If Applied Product Not Set
-------------------------------------------------------------------------------
If @GetProductFlag = 1
  BEGIN
    If @BatchProductId Is Null
      BEGIN
 	   	     Select @BatchProductId = prod_Id 
 	         from Production_Starts 
 	         where PU_Id = @BatchUnitId  and 
 	               Start_Time <= @BatchEndTime and  
 	              (End_time > @BatchEndTime or End_time is null)
      END
  END
-------------------------------------------------------------------------------
-- Build Up Input Tag For Variable - Primary Key To Search By
-------------------------------------------------------------------------------
Select @MyPUId = @BatchProcedureUnitId
select @ParameterType = NULL
Select @ChildUnitDesc = ''
If @UnitProcedureName is not Null
  Begin
  	  Select @ChildUnitDesc = @UnitProcedureName
  	  If  @OperationName is not Null
          Begin
  	       	  	  	 Select @ChildUnitDesc = @ChildUnitDesc + ':' + @OperationName
            If @PhaseName Is Not Null 
              Begin
                -- This is a phase parameter
                Select @ParameterType = 'Phase'
                Select @VarInputTag =   'P:' + @ParameterName
                Select @VarDescription = @ParameterName
              End
            Else
              Begin
                -- This is an operation parameter
                Select @ParameterType = 'Operation'
                Select @VarInputTag = 'O:' + @ParameterName
                Select @VarDescription = 'O:' + @ParameterName
              End
          End
        Else
          Begin
            -- This is a unit procedure parameter
            Select @ParameterType = 'Procedure'
            Select @VarInputTag = 'PROCEDURE:' + @ChildUnitDesc +   ':' + @ParameterName
            Select @VarDescription = @VarInputTag
          End
  End
Else 
  Begin
    -- This is a batch parameter
    Select @ParameterType = 'Batch'
    Select @VarInputTag = 'BATCH:' + @ParameterName
    Select @VarDescription = @VarInputTag
 	  	 Select @MyPUId = @BatchUnitId
 	  	 Select @BatchProcedureGroupId =  PUG_ID from Pu_Groups where PU_Id = @BatchUnitId and External_Link  	 = 'BATCH' 
  End
-------------------------------------------------------------------------------
-- See If Variable Exists
-------------------------------------------------------------------------------
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Searching For Variable [' + @VarInputTag + ']')
Select @VariableId  = Null, @VarUOM = NULL,@MyPUGId = Null,@PUGDesc = Null,@VarPercision = Null,@OldDataType = Null
Select  	 @VariableId = v.Var_Id,
 	  	 @VarUOM = Eng_Units,
 	  	 @PUGDesc = pug.External_Link,
 	  	 @VarPercision = Var_Precision,
 	  	 @OldDataType = Data_Type_Id
 From Variables_Base v
 Join Prod_Units_Base pu On v.pu_Id = pu.PU_Id
 Join PU_Groups pug On v.pug_Id = pug.PUG_Id
Where Input_Tag = @VarInputTag and 
 	  	  	 (pu.Master_Unit = @MyPUId or pu.pu_id = @MyPUId)
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'ParameterType [' + @ParameterType + ']')
If @ParameterType = 'Operation' or @ParameterType = 'Phase'
 	 Begin
 	  	 Select @UDEDesc  = @BatchName + ':' + @OperationName
 	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Searching for UDE [' + @UDEDesc + ']')
 	  	 Select @EventNum = 'U:' + @BatchName + '!' + @UnitProcedureName
 	  	 If len(@EventNum) > 50
 	  	  	 Select @EventNum = substring(@EventNum,1,50)
 	  	 Select @EventId = Event_Id From Events Where Event_Num = @EventNum and PU_Id = @BatchProcedureUnitId
 	  	 Select @BatchStartTime = Null,@BatchEndTime = Null
 	  	 Select @BatchStartTime = start_time,@BatchEndTime = End_Time,@UDEEventId = UDE_Id
 	  	  	  	 From User_Defined_Events 
 	  	  	  	 Where PU_Id = @BatchProcedureUnitId and  UDE_Desc = @UDEDesc and Event_Id = @EventId
 	 End
If @ParameterType = 'Operation'
 	 Begin
 	  	 If (@PUGDesc <> 'O:' + @OperationName) and  @PUGDesc <> 'O:Common Variables' and @VariableId is not null
 	  	  	 Begin
 	  	  	  	 Select @MyPUGId = PUG_Id From PU_Groups Where External_Link = 'O:Common Variables' and pu_Id = @BatchProcedureUnitId
 	  	  	  	 IF 	 @MyPUGId Is Null
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT @MyPUGId = PUG_Id 
 	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	 WHERE PU_Id = @BatchProcedureUnitId and 	 PUG_Desc = 'O:Common Variables'
 	  	  	  	  	 If @MyPUGId is null
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 SELECT 	 @GroupOrder 	 = Null
 	  	  	  	  	  	  	 SELECT 	 @GroupOrder  	 = Coalesce(Max(PUG_Order),0) + 1 
 	  	  	  	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	  	  	  	 WHERE 	 PU_Id  	 = @BatchProcedureUnitId
 	  	  	  	  	  	  	 EXEC 	 spEM_CreatePUG  
 	  	  	  	  	  	  	  	 'O:Common Variables',
 	  	  	  	  	  	  	  	 @BatchProcedureUnitId,
 	  	  	  	  	  	  	  	 @GroupOrder,
 	  	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	  	 @MyPUGId OUTPUT
 	  	  	  	  	  	 End
 	  	  	  	  	  Update 	 PU_Groups SET 	 External_Link  	 = 'O:Common Variables' WHERE 	 PUG_Id  	  	 = @MyPUGId
 	  	  	  	  End --@MyPUGId is null
 	  	  	  	 Update Variables_Base set PUG_Id = @MyPUGId Where Var_Id = @VariableId
 	  	  	 End --(@PUGDesc <> 'O:' + @OperationName)
 	  	  	 Select @EventSubtypeId = Null
 	  	  	 Select @EventSubtypeId = Event_Subtype_Id From Event_Subtypes where Event_Subtype_Desc = @ParameterType
 	 End --@ParameterType = 'Operation'
If @ParameterType = 'Phase'
 	 Begin
 	  	 IF @PhaseInstance Is Null
 	  	  	 Select @UDEDesc  =@BatchName + ':' + @PhaseName
 	  	 ELSE
 	  	  	 Select @UDEDesc  =@BatchName + ':' + @PhaseName + ':' + Convert(nvarchar(10),@PhaseInstance)
 	  	 If (@PUGDesc <> 'P:' + @PhaseName) and  @PUGDesc <> 'P:Common Variables' and @VariableId is not null
 	  	  	 Begin
 	  	  	  	 Select @MyPUGId = PUG_Id From PU_Groups Where External_Link = 'P:Common Variables' and pu_Id = @BatchProcedureUnitId
 	  	  	  	 IF 	 @MyPUGId Is Null
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT @MyPUGId = PUG_Id 
 	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	 WHERE PU_Id = @BatchProcedureUnitId and 	 PUG_Desc = 'P:Common Variables'
 	  	  	  	  	 If @MyPUGId is null
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 SELECT 	 @GroupOrder 	 = Null
 	  	  	  	  	  	  	 SELECT 	 @GroupOrder  	 = Coalesce(Max(PUG_Order),0) + 1 
 	  	  	  	  	  	  	  	 FROM 	 PU_Groups 
 	  	  	  	  	  	  	  	 WHERE 	 PU_Id  	 = @BatchProcedureUnitId
 	  	  	  	  	  	  	 EXEC 	 spEM_CreatePUG  
 	  	  	  	  	  	  	  	 'P:Common Variables',
 	  	  	  	  	  	  	  	 @BatchProcedureUnitId,
 	  	  	  	  	  	  	  	 @GroupOrder,
 	  	  	  	  	  	  	  	 @UserId,
 	  	  	  	  	  	  	  	 @MyPUGId OUTPUT
 	  	  	  	  	  	 End
 	  	  	   	  	 Update 	 PU_Groups SET 	 External_Link  	 = 'P:Common Variables' WHERE 	 PUG_Id = @MyPUGId
 	  	  	  	 End
 	  	  	  If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Moving  [' + Convert(nvarchar(10),@VariableId) + '] to common variables' )
 	  	  	  Update Variables_Base set PUG_Id = @MyPUGId Where Var_Id = @VariableId
 	  	  	 End
 	  	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Searching for UDE [' + @UDEDesc + ']')
 	  	  	 Select @BatchStartTime = Null,@BatchEndTime = Null,@EventSubtypeId = Null
 	  	  	 Select @EventSubtypeId = Event_Subtype_Id From Event_Subtypes where Event_Subtype_Desc = @ParameterType
 	  	  	 Select @BatchStartTime = start_time,
 	         	  	  @BatchEndTime = End_Time
 	  	  	  	  From User_Defined_Events 
 	  	  	  	  Where PU_Id = @BatchProcedureUnitId and  UDE_Desc = @UDEDesc and Parent_UDE_Id = @UDEEventId
 	 End
-------------------------------------------------------------------------------
-- Create Variable If Necessary
-------------------------------------------------------------------------------
If @VariableId Is null
BEGIN
    SELECT @VarUOM = @ParameterAttributeUOM,@VarPercision = Case When @DataType = 3 Then 0 Else 4 END
    Select @VarDescription = ltrim(rtrim(@VarDescription))
 	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Preparing To Add New Variable [' + @VarDescription + ']')
 	  	 -------------------------------------------------------------------------------
 	  	 -- Test For Length And Uniqueness
 	  	 -------------------------------------------------------------------------------
    If len(@VarDescription) > 50
      BEGIN
        Select @VarCount = 0
 	  	  	  	 Select @VarCount = count(var_id) From Variables_Base Where Var_Desc like '%' + left(@VarDescription,46) + '%'        
        Select @VarCount = @VarCount + 1
        Select @VarDescription = left('*' + convert(nvarchar(10),@VarCount) + '*' + @VarDescription,50)
 	    If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adjusted Variable Name To [' + @VarDescription + ']')
      END  
 	  	 -------------------------------------------------------------------------------
 	  	 -- Go Ahead And Add The Variable
 	  	 -------------------------------------------------------------------------------
    If @ParameterType = 'Phase' or @ParameterType = 'Operation'
      Begin
 	  	  	  	 Select @EventSubtypeId = Event_Subtype_Id From Event_Subtypes where Event_Subtype_Desc = @ParameterType
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Make sure there is no duplicate.
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 SET 	  	  	 @VarCount = 0
 	  	  	  	 SELECT 	 @VarCount = COUNT(Var_Id) 
 	  	  	  	  	 FROM 	 Variables_Base 
 	  	  	  	  	 WHERE Var_Desc = @VarDescription
 	  	  	  	  	 AND   PU_Id = @BatchProcedureUnitId
 	  	 
 	  	  	  	 IF @VarCount <> 0
 	  	  	  	 BEGIN
 	  	  	  	  	 SET 	  	 @Error = 'Duplicate Variable Exists'
 	  	  	  	  	 GOTO 	 errc
 	  	  	  	 END
 	      	  	  	 Execute @SpReturn = spEM_CreateVariable  @VarDescription,@BatchProcedureUnitId,@BatchProcedureGroupId,-1,@UserId,@VariableId OUTPUT
 	  	  	  	 If @SpReturn <> 0
 	  	  	  	  	 Begin
 	  	  	  	     Select @Error = 'Variable Not Created'
 	  	  	  	     Goto errc
 	  	  	  	  	 End
  	    	   Update Variables_Base set Var_Precision = @VarPercision,Input_tag = @VarInputTag,Eng_Units = @ParameterAttributeUOM, DS_ID = 15,Event_Type = 14,Event_Subtype_Id = isnull(@ESID,@EventSubtypeId),Test_Name = @ParameterName,Data_Type_Id = @DataType,SA_Id = 1 Where Var_Id = @VariableId
      End
    Else If @ParameterType = 'Procedure'
      Begin
 	  	 -------------------------------------------------------------------------------
 	  	 -- Make sure there is no duplicate.
 	  	 -------------------------------------------------------------------------------
 	  	 SET 	  	  	 @VarCount = 0
 	  	 SELECT 	 @VarCount = COUNT(Var_Id) 
 	  	  	 FROM 	 Variables_Base 
 	  	  	 WHERE Var_Desc = @VarDescription
 	  	  	 AND   PU_Id = @BatchProcedureUnitId
 	    If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adding Variable To @BatchProcedureUnitId [' + convert(nvarchar(10),@BatchProcedureUnitId) + ']')
 	    If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Adding Variable To @BatchProcedureGroupId[' + convert(nvarchar(10),@BatchProcedureGroupId) + ']')
 	  	 IF @VarCount <> 0
 	  	 BEGIN
 	  	  	 SET 	  	 @Error = 'Duplicate Variable Exists'
 	  	  	 GOTO 	 errc
 	  	 END
      	 Execute @SpReturn = spEM_CreateVariable  @VarDescription,@BatchProcedureUnitId,@BatchProcedureGroupId,-1,@UserId,@VariableId OUTPUT
 	  	 If @SpReturn <> 0
 	  	  	 Begin
 	  	  	  	 Select @Error = 'Variable Not Created'
 	  	  	  	 Goto errc
 	  	  	 End
   	   	 Update Variables_Base set Var_Precision = @VarPercision,Input_tag = @VarInputTag,Eng_Units = @ParameterAttributeUOM, DS_ID = 15,Event_Type = isnull(@ETID,1),Event_Subtype_Id = @ESID,Test_Name = @ParameterName,Data_Type_Id = @DataType,SA_Id = 1 Where Var_Id = @VariableId
      End
    Else If @ParameterType = 'Batch'
      Begin
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 -- Make sure there is no duplicate.
 	  	  	  	 -------------------------------------------------------------------------------
 	  	  	  	 SET 	  	  	 @VarCount = 0
 	  	  	  	 SELECT 	 @VarCount = COUNT(Var_Id) 
 	  	  	  	  	 FROM 	 Variables_Base
 	  	  	  	  	 WHERE Var_Desc = @VarDescription
 	  	  	  	  	 AND   PU_Id = @BatchUnitId
 	  	 
 	  	  	  	 IF @VarCount <> 0
 	  	  	  	 BEGIN
 	  	  	  	  	 SET 	  	 @Error = 'Duplicate Variable Exists'
 	  	  	  	  	 GOTO 	 errc
 	  	  	  	 END
  	      	 Execute @SpReturn = spEM_CreateVariable  @VarDescription,@BatchUnitId,@BatchProcedureGroupId,-1,@UserId,@VariableId OUTPUT
 	  	  	  	 If @SpReturn <> 0
 	  	  	  	  	 Begin
 	  	  	  	     Select @Error = 'Batch Variable Not Created'
 	  	  	  	     Goto errc
 	  	  	  	  	 End
  	    	   Update Variables_Base set Var_Precision = @VarPercision,Input_tag = @VarInputTag,Eng_Units = @ParameterAttributeUOM, DS_ID = 15,Event_Type = isnull(@ETID,1),Event_Subtype_Id = @ESID,Test_Name = @ParameterName,Data_Type_Id = @DataType,SA_Id = 1 Where Var_Id = @VariableId
      End
 	  	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Created Variable [' + convert(nvarchar(10),@VariableId) +  ']')
END
ELSE
BEGIN
 	 If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'Found Variable [' + convert(nvarchar(10),@VariableId) + '] Type [' + @ParameterType + ']')
    --Update Engineeting Units In Case Recipe Setup Or Parameter Report Was Missing
 	 If @VarUOM Is Null and @ParameterAttributeUOM Is Not Null
 	 BEGIN
 	  	 SELECT @VarUOM = @ParameterAttributeUOM
 	  	 Update Variables_Base set Eng_Units = @ParameterAttributeUOM Where Var_Id = @VariableId 
 	 END
 	 --Update Datatype if data is string and old type = Float
 	 If @OldDataType = 2  and  @DataType = 3
 	 BEGIN
 	  	 Update Variables_Base set Data_Type_Id = 3 Where Var_Id = @VariableId 
 	 END
END
Finish:
-------------------------------------------------------------------------------
-- Normal exit
-------------------------------------------------------------------------------
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_GetSingleVariable)')
Select @Rc = 1
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
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_GetSingleVariable)')
RETURN(-100)
