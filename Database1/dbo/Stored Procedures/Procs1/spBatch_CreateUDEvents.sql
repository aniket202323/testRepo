CREATE Procedure dbo.spBatch_CreateUDEvents
 	 @EventTransactionId 	  	  	  	  	 Int,
 	 @BatchName 	  	  	  	  	  	  	  	  	 nvarchar(100),
  @EventName 	  	  	  	  	  	  	  	  	 nvarchar(100),
 	 @EventTimeStamp 	  	  	  	  	  	  	 DateTime,
 	 @ProcedureEndTime 	  	  	  	  	  	 DateTime,
 	 @ProcedureStartTime 	  	  	  	  	 DateTime,
 	 @BatchUnitId 	  	  	  	  	  	  	  	 Int,
 	 @BatchProcedureUnitId  	  	  	 Int,
 	 @BatchProcedureGroupId 	  	  	 Int,
  @ProcedureUnitId 	  	  	  	  	  	 Int,
 	 @UserId 	  	  	  	  	  	  	  	  	  	  	 Int,
 	 @UnitProcedureName 	  	  	  	  	 nvarchar(100),
 	 @OperationName 	  	  	  	  	  	  	 nvarchar(100),
 	 @PhaseName 	  	  	  	  	  	  	  	  	 nvarchar(100),
 	 @PhaseInstance 	  	  	  	  	  	  	 Int,
 	 @Event_SubType 	  	  	  	  	  	  	 Int,
 	 @Debug  	  	  	  	  	  	  	  	  	  	  	 Int = NULL 	 
AS
SET 	 @ProcedureStartTime 	 = DATEADD(MS, -DATEPART(MS, @ProcedureStartTime), @ProcedureStartTime)
SET 	 @ProcedureEndTime 	  	 = DATEADD(MS, -DATEPART(MS, @ProcedureEndTime), @ProcedureEndTime)
SET 	 @EventTimeStamp 	  	  	 = DATEADD(MS, -DATEPART(MS, @EventTimeStamp), @EventTimeStamp)
-------------------------------------------------------------------------------
-- nocount is a must (for systems with multilingual)
-------------------------------------------------------------------------------
Set Nocount on
-------------------------------------------------------------------------------
-- Declare Generic Variables
-------------------------------------------------------------------------------
Declare @STs DateTime,@ETs DateTime
Declare 
  @Rc  	  	 int,
  @Error 	 nvarchar(255)
Declare 	 @OldStartTime 	  	 DateTime,
 	  	 @NewStartTime 	  	 DateTime,
 	  	 @OldEndTime 	  	  	 DateTime,
 	  	 @UserDefinedEventId 	  	 Int,
 	  	 @EventNum 	  	  	 nvarchar(50),
 	  	 @EventSubTypeDesc 	 nvarchar(100),
 	  	 @UDEId 	  	  	  	 Int,
 	  	 @EventId 	  	  	 Int,
 	  	 @Update 	  	  	  	 Int,
 	  	 @MaxTS 	  	  	  	 DateTime
 	  	 
Declare @ID Int
If @Debug = 1 
  Begin 
    Insert into Message_Log_Header (Timestamp) Select dbo.fnServer_CmnGetDate(getUTCdate()) Select @ID = Scope_Identity() 
    Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'START (spBatch_CreateUDEvents)')
    Insert into Message_Log_Detail (Message_Log_Id, Message)
      Values(@ID, 'in spBatch_CreateUDEvents /EventTransactionId: ' + Coalesce(convert(nvarchar(10),@EventTransactionId),'Null') + ' /BatchName: ' + Coalesce(@BatchName,'Null') + 
 	 ' /EventName: ' + isnull(@EventName,'Null') +  	 ' /EventTimeStamp: ' + isnull(convert(nvarchar(25),@EventTimeStamp),'Null') + 
  ' /ProcedureEndTime: ' + isnull(convert(nvarchar(25),@ProcedureEndTime),'Null') + ' /ProcedureStartTime: ' + isnull(convert(nvarchar(25),@ProcedureStartTime),'Null') +
  ' /BatchUnitId: ' + isnull(convert(nvarchar(10),@BatchUnitId),'Null') + ' /BatchProcedureUnitId: ' + isnull(convert(nvarchar(10),@BatchProcedureUnitId),'Null') +
  ' /BatchProcedureGroupId: ' + isnull(convert(nvarchar(10),@BatchProcedureGroupId),'Null') + 	 ' /ProcedureUnitId: ' + isnull(convert(nvarchar(10),@ProcedureUnitId),'Null') +
  ' /UserId: ' + isnull(convert(nvarchar(10),@UserId),'Null')  + 	 ' /UnitProcedureName: ' + isnull(@UnitProcedureName,'Null') +
 	 ' /OperationName: ' + isnull(@OperationName,'Null') + ' /PhaseName: ' + isnull(@PhaseName,'Null') +
 	 ' /PhaseInstance: ' + isnull(convert(nvarchar(10),@PhaseInstance),'Null') +' /Event_SubType: ' + isnull(convert(nvarchar(10),@Event_SubType),'Null') +
 	 ' /Debug: ' + isnull(convert(nvarchar(10),@Debug),'Null'))
End
-------------------------------------------------------------------------------
-- Initialize variables
-------------------------------------------------------------------------------
Select  	 @Error = '', 
 	  	  	  	 @Rc = 0
Select @EventSubTypeDesc = Event_Subtype_Desc 
  From Event_Subtypes 
  Where Event_Subtype_Id = @Event_SubType 
-------------------------------------------------------------------------------
-- Get Event Start Time, Based On Precedure It Is Associated With
--
-- Note Event Names Need To Be Consistent With "Create Events" Stored Procedure
-------------------------------------------------------------------------------
Select @NewStartTime = Null
If @BatchName is Not Null /* Process Main Batch */
  Begin
 	   If @ProcedureStartTime Is Null  /* Find startTime */
 	     Begin
 	  	  	   If @BatchProcedureGroupId Is not null
 	  	  	  	 Begin
 	  	   	    	   Select @EventNum = 'P:' + Convert(nvarchar(10),@BatchProcedureGroupId)  + ':' + @BatchName
 	  	   	    	   Select @EventId = Event_Id,@NewStartTime = Timestamp From Events Where  Event_Num = @EventNum and PU_Id = @ProcedureUnitId
 	  	  	  	 End
 	  	  	   If @NewStartTime is Null and @OperationName Is Not Null
 	  	  	  	 Begin
 	  	  	  	   Select @EventNum = 'O:' + Convert(nvarchar(10),@BatchProcedureUnitId) + ':' + @BatchName
 	  	      	   Select @EventId = Event_Id,@NewStartTime = Timestamp From Events Where  Event_Num = @EventNum and PU_Id = @ProcedureUnitId
 	  	  	  	 end
 	  	  	   If @NewStartTime is Null and @UnitProcedureName Is Not Null
 	  	  	  	 Begin
 	  	  	  	   Select @EventNum = 'U:' + @BatchName + '!' + @UnitProcedureName
 	  	  	  	   Select @EventId = Event_Id,@NewStartTime = Timestamp From Events Where  Event_Num = @EventNum and PU_Id = @ProcedureUnitId
 	  	  	  	 End
 	  	  	   If @NewStartTime is Null
 	  	  	  	 Begin
 	  	      	   Select @EventId = Event_Id,@NewStartTime = Timestamp From Events Where  Event_Num = @BatchName and PU_Id = @BatchUnitId
 	  	  	  	 End
 	  	  	   If @NewStartTime is Null
 	  	  	  	  	 Select @NewStartTime = @EventTimeStamp
 	     End
   End
Else /* Find Current Batch */
  Begin
 	   Select @MaxTs = coalesce(@ProcedureEndTime, @EventTimestamp)
 	 
 	  	 Select @MaxTS = Max(TimeStamp) 
 	     From Events 
 	     Where PU_Id = @BatchUnitId and
 	           Timestamp <= @MaxTS
 	            
 	   Select @EventId = Event_Id,@BatchName = Event_Num,@NewStartTime = Timestamp From Events Where TimeStamp = @MaxTS and PU_Id = @BatchUnitId 
 	  	 IF @EventId is null
 	      Begin
 	  	  	    Select @Error = 'Unable to find current batch'
 	  	  	    Goto Errc
 	      End
  End
If @BatchName is Not Null /* Process Main Batch */
  Begin 
 	 If @ProcedureEndTime Is null and @ProcedureStartTime Is null
 	  	 Begin -- No StartTime or EndTime
       Select @UserDefinedEventId = UDE_Id,
              @ProcedureStartTime = Start_Time 
          From User_Defined_Events
 	  	  	     Where  UDE_Desc = @BatchName and 
                 PU_Id = @BatchUnitId and 
                 End_Time Is Null
 	  	  	 If @UserDefinedEventId Is Null -- New
 	  	  	   Begin
 	  	  	     Select @ETs = Null
 	  	  	     Select @STs = @NewStartTime
 	  	  	   End
 	  	  	 Else -- Close
 	  	  	   Begin
 	  	  	     Select @ETs = @EventTimeStamp
 	  	  	     Select @STs = @ProcedureStartTime
 	  	  	   End
 	  	 End
 	 Else If @ProcedureEndTime Is null
 	  	 Begin -- Have StartTime Only
       Select @UserDefinedEventId = UDE_Id 
         From User_Defined_Events
 	  	  	    Where  UDE_Desc = @BatchName and 
                PU_Id = @BatchUnitId and 
                Start_Time = @ProcedureStartTime
 	  	  	 If @UserDefinedEventId Is Null -- New
 	  	  	  Begin
 	  	  	     Select @ETs = Null
 	  	  	     Select @STs = @ProcedureStartTime
 	  	  	  End
 	  	  	 Else --Update
 	  	  	  Begin
 	  	  	     Select @ETs = @EventTimeStamp
 	  	  	     Select @STs = @ProcedureStartTime
 	  	  	  End
 	  	 End
 	 Else If @ProcedureStartTime Is null
 	  	 Begin -- Have EndTime Only
       Select @UserDefinedEventId = UDE_Id,
              @ProcedureStartTime = Start_Time 
         From User_Defined_Events
 	  	  	    Where  UDE_Desc = @BatchName and 
                PU_Id = @BatchUnitId and 
                End_Time Is Null
 	  	  	 If @UserDefinedEventId Is Null --ERROR
 	  	  	  Begin
 	  	  	   Select @Error = 'Unable to find open Event Record To Set End Time For'
 	  	  	   Goto Errc
 	  	  	  End
 	  	  	 Else --Update
 	  	  	  Begin
 	  	  	   Select @ETs = @EventTimeStamp
 	  	  	   Select @STs = @ProcedureStartTime
 	  	  	  End
 	  	 End
 	 Else
 	   Begin --Have StartTime and EndTime
 	  	  	 Select @ETs = @ProcedureEndTime
 	  	  	 Select @STs = @ProcedureStartTime
 	     Select @UserDefinedEventId = UDE_Id,
 	            @OldStartTime = Start_Time,
 	            @OldEndTime = End_Time 
 	       From User_Defined_Events
 	  	  	   Where  UDE_Desc = @BatchName and 
 	              PU_Id = @BatchUnitId and 
 	              Start_Time = @ProcedureStartTime
 	 
 	     If @UserDefinedEventId is null
 	       Select @UserDefinedEventId = UDE_Id,
 	              @OldStartTime = Start_Time,
 	              @OldEndTime = End_Time 
 	         From User_Defined_Events
 	  	   	  	   Where  UDE_Desc = @BatchName and 
 	                PU_Id = @BatchUnitId and 
 	                End_Time = @ProcedureEndTime
 	   End
 	  Select @Update = 2
 	  IF @UserDefinedEventId is null 
 	  	  Select @Update = 1
 	  Execute spServer_DBMgrUpdUserEvent 0,@EventSubTypeDesc,Null,Null,Null,Null,Null,Null,Null,Null,
 	  	  	  	  	 Null,Null,Null,0,null,@Event_SubType,@BatchUnitId,@BatchName,@UserDefinedEventId,@UserId,Null,@STs,@ETs,Null,Null,Null,Null,Null,@Update,Null
   --TODO: Real Time Update?
  End
else
   Begin
     Select @Error = 'Unable To Find Batch To Associate Event Report'
     Goto Errc
   End
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_CreateUDEvents)')
Finish:
---------------------------------------------------------------------------------------------------
-- Normal Exit
--------------------------------------------------------------------------------------------------
RETURN(1)
---------------------------------------------------------------------------------------------------
-- Error Handling
--------------------------------------------------------------------------------------------------
Errc:
UPDATE 	 Event_Transactions 
 	 SET 	 OrphanedReason  	 = coalesce(OrphanedReason, @Error),
 	  	 OrphanedFlag  	 = 1 
 	 WHERE 	 EventTransactionId = @EventTransactionId
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, @Error)
If @Debug = 1 Insert into Message_Log_Detail (Message_Log_Id, Message) Values(@ID, 'END (spBatch_CreateUDEvents)')
Return (-100)
