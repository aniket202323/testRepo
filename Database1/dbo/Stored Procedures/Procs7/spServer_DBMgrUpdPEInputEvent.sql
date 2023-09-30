/*
Stored Procedure: 	 spServer_DBMgrUpdPEInputEvent
Author: 	  	  	 MSI
Date Created: 	  	 00/00/00
Description:
===========
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
07/01/04 	 MKW 	 Added some checks for events on the inputs so that we don't get unnecessary records in the
 	  	  	 PrdExec_Input_Event_History table (Case #51901 - No Error Checking in spServer_DBMgrUpdPEInputEvent)
*/
CREATE PROCEDURE dbo.spServer_DBMgrUpdPEInputEvent
@TransType int,
@TransNum int,
@Timestamp datetime,
@UserId int,
@CommentId int,
@PEIId int,
@PEIPId int,
@EventId int,
@DimensionX float,
@DimensionY float,
@DimensionZ float,
@DimensionA float,
@Unloaded int,
@EntryOn datetime output,
@SignatureId int = Null
AS
  --
  -- Return Values:
  --
  --   (-100)  Error.
  --   (   1)  Success: New record added.
  --   (   2)  Success: Existing record modified.
  --   (   3)  Success: Existing record deleted.
  --   (   4)  Success: No action taken.
/*
*******TransType*************
(1) Complete Position
(2) Load Position
(3) Unload Position
*/
Declare @PU_Id 	  	 int, 
 	 @ETimeStamp 	  	 Datetime, 
 	 @Applied_Product 	 int, 
 	 @Source_Event 	  	 int,
 	 @Event_Status 	  	 int,  
 	 @Transaction_Type 	 int,
 	 @ECommentId 	  	 int,
 	 @EventSubtypeId 	 int,
 	 @TestingStatus 	  	 int,
 	 @SchedulingUnit 	  	 Int,
 	 @PathId 	  	  	  	 Int,
 	 @PP_Id 	  	  	  	 Int,
 	 @ControlType 	  	 Int,
 	 @CurrentPPId 	  	 Int,
 	 @CurrentppSetupId 	 Int,
 	 @ppSetupId 	  	  	 Int,
 	 @Changed 	  	  	 Int,
 	 @ReturnCode 	  	  	 int,
 	 @MyOwnTrans 	  	  	 Int
If @@Trancount = 0
 	 Select @MyOwnTrans = 1
Else
 	 Select @MyOwnTrans = 0
If (@TransNum =1010) -- Transaction From WebUI
  SELECT @TransNum = 2
  If @TransNum NOT IN (0,2)
    Return(4)
Select @EntryOn = isnull(@EntryOn,dbo.fnServer_CmnGetDate(getutcdate()))
Declare @InputExists Int,
 	 @OldEventId 	 Int,
 	 @EventPuId Int,
 	 @EventTimestamp 	 Datetime
Select @InputExists = Null,
 	 @OldEventId 	 = NULL, 	  	 -- MKW 07/01/04
 	 @ReturnCode 	 = 4 	  	 -- MKW 07/01/04
If @EventId is not null and @PEIPId = 1  -- check to see if path needs to be propagated
  Begin
 	 Select @EventPuId = PU_Id,@EventTimestamp = timestamp from events where event_Id = @EventId
 	 Select @PU_Id = PU_Id From PrdExec_Inputs where PEI_Id = @PEIId
 	 Select @PP_Id = PP_Id,@ppSetupId = PP_Setup_Id   from Event_Details where Event_Id =  @EventId
 	 If @PP_Id is null
 	  	 Select @PP_Id =PP_Id
 	  	  	 From production_Plan_starts
 	  	    	 Where PU_Id = @EventPuId and Start_Time < @EventTimestamp and (End_Time >= @EventTimestamp or End_Time is null)
 	 If @ppSetupId is null
 	  	 Select @ppSetupId = PP_Setup_Id
 	  	  	 From production_Plan_starts
 	  	    	 Where PU_Id = @EventPuId and Start_Time < @EventTimestamp and (End_Time >= @EventTimestamp or End_Time is null)
 	 Select @PathId = Path_Id from production_Plan where PP_Id = @PP_Id
 	 If @PathId is not null and @PP_Id is not null
 	   Begin
 	  	 Select @ControlType = Schedule_Control_Type from Prdexec_Paths where path_Id = @PathId
 	  	 If @ControlType = 1 -- Event Controlled
 	  	   Begin
 	  	  	 Select @CurrentPPId = PP_Id, @CurrentppSetupId = pp_setup_id From production_Plan_starts
 	  	  	   Where PU_Id = @PU_Id and End_time is null
 	  	  	 Select @Changed = 0
 	  	  	 If (@CurrentPPId <> @PP_Id) or (@CurrentPPId is null) 
 	  	  	  	 Select @Changed = 1
 	  	  	 If ((@CurrentppSetupId is null and @ppSetupId is not null) or (@CurrentppSetupId is not null and @ppSetupId is null)) and @Changed = 0
 	  	  	     Select @Changed = 1
 	  	  	 else
 	  	  	   If (@CurrentppSetupId is not null and  @ppSetupId is not null)  and @Changed = 0
 	  	  	  	 If @CurrentppSetupId <>  @ppSetupId
 	  	  	  	  	 Select @Changed = 1
 	  	  	    	 else
 	  	  	  	   Select @Changed = 0
 	  	  	  IF NOT EXISTS(SELECT 1 FROM PrdExec_Path_Units WHERE  PU_Id = @PU_Id and Path_Id = @PathId)
 	  	  	  	  Select @Changed = 0
 	  	  	  If @Changed = 1
 	  	  	   Begin
 	  	  	  	 Update Production_Plan_starts set End_Time = @Timestamp Where PU_Id = @PU_Id and End_time is null
 	  	  	  	 Insert Into Production_Plan_starts (Start_Time,End_Time,PP_Id,PU_Id,pp_setup_id,User_Id)
 	  	  	  	  	 Values(@Timestamp,Null,@PP_Id,@PU_Id,@ppSetupId,@UserId)
 	  	  	   End
 	  	   End
 	   End
  End
If @MyOwnTrans = 1 
 	 Begin
 	  	 BEGIN TRANSACTION
    DECLARE @XLock BIT SELECT @XLock = dbo.fnServer_DBMgrUpdGetExclusiveLock()
 	 End
Select @InputExists = PEI_Id,@OldEventId = Event_Id From PrdExec_Input_Event Where PEI_Id = @PEIId and  PEIP_Id = @PEIPId
If @TransNum = 0 and (@TransType = 3 or @InputExists is Not Null)
  Begin
   	 Select  @EventID = Coalesce(@EventID, Event_Id),
   	  	 @DimensionX = Coalesce(@DimensionX,Dimension_X),
   	  	 @DimensionY = Coalesce(@DimensionY,Dimension_Y),
   	  	 @DimensionZ = Coalesce(@DimensionZ,Dimension_Z),
   	  	 @DimensionA = Coalesce(@DimensionA,Dimension_A)
   	  From PrdExec_Input_Event
   	  Where (PEI_Id = @PEIId and PEIP_Id = @PEIPId)
  End
If  @TransType = 1  -- Complete
  Begin
    If @InputExists is Not Null
      Begin
 	 --MKW 07/01/04 - Only complete the event if an event is actually loaded
 	 -- 	  	 - We SHOULD also be checking to see if the PrdExec_Input_Event.Event_Id = @EventId (argument)
 	 IF @OldEventId IS NOT NULL
 	  	 BEGIN
 	          -- changed for andrew to include dimensions
 	          UPDATE 	 PrdExec_Input_Event 
 	           	 SET 	 Event_Id = null,Timestamp = @TimeStamp,User_Id = @UserId,Entry_On = @EntryOn,Unloaded = 0,
 	         	  	  	 Dimension_X = @DimensionX,Dimension_Y = @DimensionY,Dimension_Z = @DimensionZ, Dimension_A = @DimensionA,
                                Signature_id = @SignatureId, Comment_Id=null
 	           	 WHERE  PEI_Id = @PEIId and  PEIP_Id = @PEIPId
 	  	 END
 	 ELSE 	  	  	  	 -- MKW 07/01/04 - If no event, rollback and issue error
 	  	 BEGIN
 	  	 If @MyOwnTrans = 1  ROLLBACK TRANSACTION
 	  	 RAISERROR('Cannot complete event as no event is loaded', 11, -1) 
 	  	 RETURN(-100)
 	  	 END
      End
    Else
      Insert into PrdExec_Input_Event (PEI_Id,Event_Id,PEIP_Id,Timestamp,User_Id,Entry_On,Unloaded,Dimension_X,Dimension_Y,Dimension_Z,Dimension_A,Signature_Id,Comment_Id)
       	 Values (@PEIId,null,@PEIPId,@TimeStamp,@UserId,@EntryOn,0,@DimensionX,@DimensionY,@DimensionZ,@DimensionA,@SignatureId,Null)
      SELECT @ReturnCode = 1 	  	 -- MKW 07/01/04
  End
Else If @TransType = 2  -- Load
  Begin
    If @InputExists is Null
      Begin
        Insert InTo PrdExec_Input_Event (PEI_Id,Event_Id,PEIP_Id,Timestamp,User_Id,Entry_On,Dimension_X,Dimension_Y,Dimension_Z,Dimension_A,Signature_Id,Comment_Id)
         	 Values (@PEIId,@EventID,@PEIPId,Dateadd(ms,100,@TimeStamp),@UserId,@EntryOn,@DimensionX,@DimensionY,@DimensionZ,@DimensionA,@SignatureId,@CommentId)
      End
    Else
      Begin
 	  	 --MKW 07/01/04 - Only complete the event if an event is actually loaded
 	  	 -- 	  	 - We SHOULD also be checking to see if the PrdExec_Input_Event.Event_Id = @EventId (argument)
 	  	 IF @OldEventId IS NULL
 	  	  	 BEGIN
 	  	         Update PrdExec_Input_Event 
 	  	           set Event_Id = @EventID,Timestamp = Dateadd(ms,100,@TimeStamp),User_Id =  @UserId,Entry_On = @EntryOn,Unloaded = 0,
 	  	         	     Dimension_X = @DimensionX,Dimension_Y = @DimensionY,Dimension_Z = @DimensionZ,Dimension_A = @DimensionA, Signature_Id = @SignatureId,Comment_Id = @CommentId
 	  	           Where  PEI_Id = @PEIId and  PEIP_Id = @PEIPId
 	  	  	 END
 	  	 ELSE 	  	  	  	 -- MKW 07/01/04 - If existing event, rollback and issue error
 	  	  	 BEGIN
 	  	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	  	 RAISERROR('Cannot load event as another event is already in the position', 11, -1)              
 	  	  	  	 RETURN(-100)
 	  	  	 END
      End
      SELECT @ReturnCode = 1 	  	 -- MKW 07/01/04
  End
Else If  @TransType = 3  --Unload
  Begin
 	 --MKW 07/01/04 - Only complete the event if an event is actually loaded
 	 -- 	  	 - We SHOULD also be checking to see if the PrdExec_Input_Event.Event_Id = @EventId (argument)
 	 IF @OldEventId IS NOT NULL
 	  	 BEGIN
 	  	     Update PrdExec_Input_Event 
 	  	       Set Timestamp = @TimeStamp, Entry_On =  @EntryOn,User_Id = @UserId,Unloaded = 1,
 	  	         Dimension_X = @DimensionX,Dimension_Y = @DimensionY,Dimension_Z = @DimensionZ,Dimension_A = @DimensionA,
                        Signature_Id = @SignatureId,Comment_Id = @CommentId
 	  	       Where  PEI_Id = @PEIId and  PEIP_Id = @PEIPId
 	  	     Update PrdExec_Input_Event 
 	  	       Set Event_Id = Null,Timestamp = @TimeStamp, Entry_On =  @EntryOn,User_Id = @UserId,Unloaded = 0,
 	  	         Dimension_X = null,Dimension_Y = null,Dimension_Z = null,Dimension_A = null, Signature_Id = @SignatureId,Comment_Id = Null
 	  	       Where  PEI_Id = @PEIId and  PEIP_Id = @PEIPId
 	  	 END
 	 ELSE 	  	  	  	 -- MKW 07/01/04 - If no event, rollback and issue error
 	  	 BEGIN
 	  	  	 If @MyOwnTrans = 1 ROLLBACK TRANSACTION
 	  	  	 RAISERROR('Cannot unload event as no event is loaded', 11, -1)              
 	  	  	 RETURN(-100)
 	  	 END
      SELECT @ReturnCode = 1 	  	 -- MKW 07/01/04
  End
If @MyOwnTrans = 1 COMMIT TRANSACTION
RETURN(@ReturnCode) 	  	  	 -- MKW 07/01/04
