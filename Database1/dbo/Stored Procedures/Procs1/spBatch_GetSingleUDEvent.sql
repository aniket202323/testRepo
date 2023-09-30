CREATE 	 PROCEDURE dbo.spBatch_GetSingleUDEvent
 	 @EventTransactionId 	  	  	  	  	  	 Int,
 	 @EventId  	  	  	  	  	  	  	  	  	  	  	 int,
 	 @Operation_Or_Phase_Name 	  	  	  	 nvarchar(100),
 	 @EventName  	  	  	  	  	  	  	  	  	  	 nvarchar(50),
 	 @EventUnitId 	  	  	  	  	  	  	  	  	 int,
 	 @NewStartTime 	  	  	  	  	  	  	  	  	 datetime,
 	 @NewEndTime 	  	  	  	  	  	  	  	  	  	 datetime, 	  	  	  	 
 	 @CurrentFilter 	  	  	  	  	  	  	  	 nvarchar(100),
 	 @UserId 	  	  	  	  	  	  	  	  	  	  	  	 int,
 	 @UDEEventId 	  	  	  	  	  	  	  	  	  	 Int Output,
 	 @Debug 	  	  	  	  	  	  	  	  	  	  	  	 int = NULL,
 	 @EventSubType 	  	  	  	  	  	  	 nvarchar(50) = NULL,
 	 @FriendlyDesc 	  	  	  	  	  	  	 nvarchar(1000) = NULL
AS
SET 	 @NewStartTime 	 = DATEADD(MS, -DATEPART(MS, @NewStartTime), @NewStartTime)
SET 	 @NewEndTime 	  	 = DATEADD(MS, -DATEPART(MS, @NewEndTime), @NewEndTime)
Declare
 	 @OldStartTime 	  	  	  	  	 DateTime,
 	 @OldEndTime 	  	  	  	  	  	 DateTime,
 	 @OldFriendlyDesc        nvarchar(1000),
 	 @Update 	  	  	  	  	  	  	  	 Int,
 	 @EventSubTypeId 	  	  	  	 Int,
 	 @ECId 	  	  	  	  	  	  	  	  	 Int,
 	 @ExistingUDETime 	  	  	 DateTime,
 	 @VarId 	  	  	  	  	  	  	  	 Int,
 	 @VarName 	  	  	  	  	  	 nvarchar(100),
 	 @VarUnitId 	  	  	  	  	  	 Int,
 	 @Test_Id 	  	  	  	  	  	  	 BigInt,
 	 @BatchProcedureGroupId 	 Int,
 	 @GroupOrder 	  	  	  	  	  	  	 Int,
 	 @EntryOn 	  	  	  	  	  	  	  	 DateTime,
 	 @ActualEndTime 	  	  	  	  	 DateTime,
 	 @TimeStampChanged 	  	  	  	 Int,
 	 @FriendlyDescChanged    int
--Select @Debug = 1
Declare 
 	 @Error 	  	  	 nvarchar(255),
  @Rc  	  	  	  	  	  	  	  	  	  	  	  	 int
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
SELECT 	 @Error = ''
SELECT 	 @Rc = 0
SELECT  	 @TimeStampChanged = 0,
        @FriendlyDescChanged = 0
Declare @ID Int
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START (spBatch_GetSingleUDEvent)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_GetSingleUDEvent /EventTransactionId: ' + Coalesce(convert(nvarchar(10),@EventTransactionId),'Null') + ' /EventId: ' + Coalesce(convert(nvarchar(10),@EventId),'Null') + 
 	 ' /Operation_Or_Phase_Name: ' + isnull(@Operation_Or_Phase_Name,'Null') +  	 
 	 ' /EventName: ' + isnull(@EventName,'Null') + ' /EventUnitId: ' + isnull(convert(nvarchar(10),@EventUnitId),'Null') + 
 	 ' /NewStartTime: ' + isnull(convert(nvarchar(25),@NewStartTime),'Null') + ' /NewEndTime: ' + isnull(convert(nvarchar(25),@NewEndTime),'Null') + 
 	 ' /CurrentFilter: ' + isnull(@CurrentFilter,'Null') + ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null') + ' /FriendlyDesc: ' + isnull(convert(NVarchar(100),@FriendlyDesc),'Null'))
  End
If @Operation_Or_Phase_Name is Null
 	 Begin
 	  	 SELECT 	 @Error = 'Unable to Find Description'
 	  	 GOTO 	 Errc
 	 End
If (@EventSubType is null) and (@CurrentFilter = 'O:')
 	 Select @EventSubType = 'Operation';
If (@EventSubType is null) and (@CurrentFilter = 'P:')
 	 Select @EventSubType = 'Phase';
Select @EventSubTypeId = Event_Subtype_Id 
  From Event_Subtypes 
  Where Event_Subtype_Desc = @EventSubType
If @EventSubTypeId Is Null
 	 Begin
 	  	 Execute spEMEC_UpdateUDEEvent  NULL,@EventSubType,Null,1,0,0,0,0,@UserId,@EventSubTypeId Output
 	 End
Select @ECId = NUll
Select @ECId = Ec_ID from Event_Configuration Where PU_Id = @EventUnitId and Event_Subtype_Id = @EventSubTypeId And ET_Id = 14
If @ECId Is Null
 	 Begin
 	  	 Insert Into Event_Configuration (ET_Id, Event_Subtype_Id, PU_Id) 	 Values  (14, @EventSubTypeId, @EventUnitId)
 	 End
IF 	 @EventName Is Not Null 
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Search For Event By UDE Event Name
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @UDEEventId 	  	  	  	  	 = Null,
 	  	  	 @OldStartTime 	  	  	  	  	 = Null,
           	 @OldEndTime 	  	  	  	  	 = Null,
           	 @OldFriendlyDesc     = NULL         
 	 IF @CurrentFilter = 'O:'
 	  	 SELECT 	 @UDEEventId 	  	  	  	  	  	 = UDE_Id,
 	  	  	  	 @OldStartTime 	  	  	  	  	  	 = Start_Time,
 	            	 @OldEndTime  	  	  	  	  	  	 = End_Time,
 	            	 @OldFriendlyDesc = Friendly_Desc
 	  	  	 FROM 	 User_Defined_Events 
 	  	  	 WHERE 	 UDE_Desc 	 = @EventName and
 	  	  	  	  	 PU_Id = @EventUnitId and 	 
 	  	  	  	  	 Event_Subtype_Id = @EventSubTypeId and
 	  	  	  	  	 Event_Id = @EventId 
 	 IF @CurrentFilter = 'P:'
 	  	 SELECT 	 @UDEEventId 	  	  	  	  	  	  	  	 = UDE_Id,
 	             @OldStartTime 	  	  	  	  	  	 = Start_Time,
 	             @OldEndTime  	  	  	  	  	  	 = End_Time,
 	             @OldFriendlyDesc       = Friendly_Desc
 	  	  	 FROM 	 User_Defined_Events 
 	  	  	 WHERE 	 UDE_Desc 	 = @EventName and
 	  	  	       PU_Id  	  	 = @EventUnitId and
 	  	  	  	  	  	 Event_Subtype_Id = @EventSubTypeId and
 	  	  	  	  	  	 Parent_UDE_Id = @EventId 
END
ELSE
BEGIN
 	 -------------------------------------------------------------------------------
 	 -- Event Name Was Not Specified, So Assume The Latest Event Before Procedure Time
 	 -------------------------------------------------------------------------------
 	 SELECT 	 @OldEndTime 	 = Null 	 
 	 SELECT 	 @OldEndTime = Max(End_Time) 
 	  	  	  	 FROM 	 User_Defined_Events 
 	  	  	  	 WHERE 	 PU_Id = @EventUnitId and 
              End_Time <= @NewEndTime and 
              Event_Subtype_Id  = @EventSubTypeId
  IF @OldEndTime is Null and  @CurrentFilter = 'O:'
    BEGIN
 	  	  	 SELECT 	 @OldEndTime = Max(TimeStamp) 
 	  	  	  	 FROM 	 Events 
 	  	  	  	 WHERE 	 PU_Id = @EventUnitId and  Timestamp <= @NewEndTime
    END
  ELSE
 	 IF 	 @OldEndTime Is Null
 	 BEGIN
 	  	 SELECT 	 @Error = 'Unable to Find Current Procedure, And No Procedure Specified, Unit = [' + convert(nvarchar(10),@EventUnitId)  + ']'
 	  	 GOTO 	 Errc
 	 END
 	 SELECT 	 @UDEEventId 	  	  	  	  	  	 = UDE_Id,
 	  	  	 @OldStartTime 	  	  	  	  	  	 = Start_Time,
 	  	  	 @OldEndTime  	  	  	  	  	  	 = End_Time,
 	  	  	 @OldFriendlyDesc = Friendly_Desc,
 	  	  	 @EventName  	  	  	  	  	  	  	 = UDE_Desc 
 	  	 FROM 	 User_Defined_Events 
 	  	 WHERE 	 PU_Id  	  	 = @EventUnitId and   End_Time = @OldEndTime and Event_Subtype_Id  = @EventSubTypeId
END
If @OldStartTime is not null and @NewStartTime is not null
  Begin
 	 If @NewStartTime < @OldStartTime 
 	    Begin
 	  	 Select @TimeStampChanged = 1
 	  	 Select @OldStartTime = @NewStartTime
 	    End
  End
Else
 	 SELECT @OldStartTime = Coalesce(@OldStartTime,@NewStartTime)
If @OldEndTime is not null and @NewEndTime is not null
  Begin
 	 If @OldEndTime < @NewEndTime 
 	    Begin
 	  	 Select @TimeStampChanged = 1
 	  	 Select @OldEndTime = @NewEndTime
 	    End
  End
Else
 	 SELECT @OldEndTime = isnull(@NewEndTime,@OldEndTime)
IF @FriendlyDesc IS NOT NULL AND
 	 (@OldFriendlyDesc IS NULL OR 
 	 @FriendlyDesc <> @OldFriendlyDesc)
BEGIN;
 	 SELECT @FriendlyDescChanged = 1
END;
-------------------------------------------------------------------------------
-- Need to save the Actual Batch timeStamp For the timestamp variable
-------------------------------------------------------------------------------
Select @Update = 2
IF @UDEEventId is null
 	  	 Select @Update = 1 
-------------------------------------------------------------------------------
-- Need to save the Actual Batch time in a Variable
-------------------------------------------------------------------------------
Select @BatchProcedureGroupId = PUG_Id From PU_Groups Where External_Link = 'P:Common Variables' and pu_Id = @EventUnitId
IF 	 @BatchProcedureGroupId Is Null
BEGIN
 	 SELECT @BatchProcedureGroupId = PUG_Id 
 	 FROM 	 PU_Groups 
 	 WHERE PU_Id = @EventUnitId and PUG_Desc = 'P:Common Variables'
 	 If @BatchProcedureGroupId is null
 	   Begin
 	  	 SELECT 	 @GroupOrder 	 = Null
 	  	 SELECT 	 @GroupOrder  	 = Coalesce(Max(PUG_Order),0) + 1 
 	  	  	 FROM 	 PU_Groups 
 	  	  	 WHERE 	 PU_Id  	 = @EventUnitId
 	  	 EXEC 	 spEM_CreatePUG  
 	  	  	 'P:Common Variables',
 	  	  	 @EventUnitId,
 	  	  	 @GroupOrder,
 	  	  	 @UserId,
 	  	  	 @BatchProcedureGroupId OUTPUT
 	   End
 	 Update 	 PU_Groups SET 	 External_Link  	 = 'P:Common Variables' WHERE 	 PUG_Id = @BatchProcedureGroupId
END
-------------------------------------------------------------------------------
-- Need to save the Actual Batch time in a Variable
-------------------------------------------------------------------------------
Set @VarName = '<' + @EventSubType + 'Timestamp>'
Select  @VarId = Var_Id From Variables_Base Where Input_tag = 'P:' + @VarName and PU_Id = @EventUnitId
If @VarId is null
BEGIN
    Execute @Rc = spEM_CreateVariable  @VarName,@EventUnitId,@BatchProcedureGroupId,-1,@UserId,@VarId OUTPUT
 	 If @Rc <> 0
 	 Begin
 	     Select @Error = @VarName + ' Variable Not Created'
 	     Goto errc
 	 End
 	 Update Variables_Base set Input_tag = 'P:' + @VarName, DS_ID = 15,Event_Type = 14,Event_Subtype_Id = @EventSubTypeId,Data_Type_Id = 3,SA_Id = 1 Where Var_Id = @VarId
END
 	  	 -------------------------------------------------------------------------------
 	  	 -- See if there if already a different ude at this time
 	  	 -------------------------------------------------------------------------------
 	  	 Select @ExistingUDETime = @OldEndTime
 	  	 Select @ActualEndTime =  @OldEndTime
 	  	 While  @ExistingUDETime Is not Null
 	  	 Begin
 	  	  	 Select @ExistingUDETime = Null
 	  	  	 If @UDEEventId is not null
 	  	  	  	 Select @ExistingUDETime =  case when UDE_Id = @UDEEventId  then null else End_Time END
 	  	  	  	  	 FROM 	 User_Defined_Events 
 	  	  	  	  	 WHERE 	 PU_Id = @EventUnitId and End_Time = @OldEndTime and Event_Subtype_Id  = @EventSubTypeId 
 	  	  	 Else
 	  	  	  	 Select @ExistingUDETime = End_Time 
 	  	  	  	  	  	 FROM 	 User_Defined_Events 
 	  	  	  	  	  	 WHERE 	 PU_Id = @EventUnitId and End_Time = @OldEndTime and Event_Subtype_Id  = @EventSubTypeId
 	  	  	 If @ExistingUDETime is not null
 	  	  	  	 Begin
 	  	  	  	  	 Select  	 @TimeStampChanged = 1
 	  	  	  	  	 Select @OldEndTime = DateAdd(Second,1,@OldEndTime)
 	  	  	  	 End
 	  	 End
If  @TimeStampChanged = 1 or @Update = 1 OR @FriendlyDescChanged = 1
  BEGIN
 	 Execute spServer_DBMgrUpdUserEvent 0,@EventSubType,Null,Null,Null,Null,Null,Null,Null,Null,
   	  	  	  	 Null,Null,Null,0,null,@EventSubTypeId,@EventUnitId,@EventName,@UDEEventId Output ,@UserId,Null,@OldStartTime,@OldEndTime,Null,Null,Null,Null,Null,@Update,
 	  	  	  	 NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,@FriendlyDesc
 	 If @CurrentFilter = 'P:'
 	  	 Begin
 	  	  	 Update 	 User_Defined_Events Set Parent_UDE_Id = @EventId where UDE_Id  = @UDEEventId
 	  	 End
 	 If @Update = 1
 	  	 Begin
 	  	  	 If @CurrentFilter = 'O:'
 	  	  	  	 Update 	 User_Defined_Events Set Event_Id = @EventId where UDE_Id  = @UDEEventId
 	  	 End
 	 Declare @Result nvarchar(25)
 	 Select @Result = Convert(nvarchar(25),@ActualEndTime,120)
 	 Execute spServer_DBMgrUpdTest2 @VarId,@UserId,0,@Result,@OldEndTime,0,Null,null,Null,@VarUnitId  OUTPUT,@Test_Id OUTPUT,
   	    	    	    	    	    	    @EntryOn OUTPUT,Null
 	 Select 2,@VarId,@VarUnitId,@UserId,0,@Result,@OldEndTime,0,1
  END
Finish:
-------------------------------------------------------------------------------
-- Normal exit
-------------------------------------------------------------------------------
Select @Rc = 1
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_GetSingleUDEvent)')
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
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_GetSingleUDEvent)')
RETURN(-100)
