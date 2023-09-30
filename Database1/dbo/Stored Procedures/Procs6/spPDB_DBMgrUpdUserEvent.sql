CREATE PROCEDURE dbo.spPDB_DBMgrUpdUserEvent
@TransNum int,
@EventSubTypeDesc nvarchar(100),
@ActionCommentId int,
@Action4 int,
@Action3 int,
@Action2 int,
@Action1 int,
@CauseCommentId int,
@Cause4 int,
@Cause3 int,
@Cause2 int,
@Cause1 int,
@AckBy int,
@Ack int,
@Duration int,
@EventSubTypeId int,
@PUId int,
@EventNum nvarchar(1000),
@EventId int,
@UserId int = NULL,
@AckOn datetime,
@StartTime datetime,
@EndTime datetime,
@ResearchCommentId int,
@ResearchStatusId int,
@ResearchUserId int,
@ResearchOpenDate datetime,
@ResearchCloseDate datetime, 
@TransType int,
@UDECommentId int,
@Event_Reason_Tree_Data_Id Int = Null, 	  	  -- User for categories
-- Added for Historian 3.0
@EventSubCategory_Id int = NULL,
@NewValue nvarchar(25) = NULL,
@NewEngUnitLabel nvarchar(255) = NULL,
@OldEngUnitLabel nvarchar(255) = NULL,
@OldValue nvarchar(25) = NULL,
@OPCEventCategory_Id int = NULL,
@OPCSeverity int = NULL,
@Historian_Quality_Id int = NULL,
@Signature_Id int = NULL,
@Source_Id int = NULL,
@Start_Time_Ms int = NULL
 AS
  --
  -- Return Values:
  --
  --   (-100) Error.
  --   (   1) Success: New record added.
  --   (   2) Success: Existing record modified.
  --   (   3) Success: Existing record deleted.
  --   (   4) Success: No action taken.
  --
  --
  -- Trans Type:
  --   GBTrans_Undefined = 0,
  --   GBTrans_Add =1  
  --   GBTrans_Upd=2
  --   GBTrans_Del=3
  --   GBTrans_Complete=4
/*
 Insert Into DebugInputUDE Values (@TransNum,@EventSubTypeDesc,@ActionCommentId,@Action4,@Action3,@Action2,
                                   @Action1, @CauseCommentId,@Cause4,@Cause3,@Cause2,@Cause1,@AckBy,
 	  	  	            @Ack, @Duration, @EventSubTypeId, @PUId, @EventNum, @EventId,
                                   @UserId, @AckOn, @StartTime, @EndTime, @ResearchCommentId, @ResearchStatusId,
                                   @ResearchUserId, @ResearchOpenDate, @ResearchCloseDate, @TransType,
                                   @UDECommentId, getDate()) 
*/
Declare @LastAck  	 bit,
 	  	 @TreeId  	 Int,
 	  	 @OldEndTime DateTime,
 	  	 @OldStartTime DateTime,
 	  	 @DurationReq 	 Int
If @EventId is not null and @TransType = 3
 	 Select  @EventSubTypeId = Event_Subtype_Id From user_Defined_Events where UDE_Id = @EventId
Select @DurationReq = coalesce(Duration_Required,0) From Event_Subtypes where Event_Subtype_Id = @EventSubTypeId
If (@TransNum <> 0) And (@TransNum <> 2)
 	 Return(4)
If @TransType = 1
  begin
  -- Look up @Event_Reason_Tree_Data_Id If necessary
  If @Event_Reason_Tree_Data_Id is null and @Cause1 is not null
 	 Begin
 	   Select @TreeId = Cause_Tree_Id From Event_Subtypes where Event_Subtype_Id = @EventSubTypeId
   	   If @Cause2 Is null
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   Else If @Cause3 Is null
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   Else If @Cause4 Is null
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   Else 
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id  = @Cause4 and Tree_Name_Id = @TreeId
 	 End
    Begin Transaction
     Insert Into User_Defined_Events 
 	  	 (UDE_Desc,
 	  	 PU_Id,
 	  	 Event_Subtype_Id,
 	  	 Start_Time,
 	  	 End_Time,
 	  	 Duration,
 	  	 Ack,
 	  	 Ack_On,
 	  	 Ack_By,
 	  	 Comment_Id,
 	  	 Cause1,
 	  	 Cause2,
 	  	 Cause3,
 	  	 Cause4,
 	  	 Cause_Comment_Id,
 	  	 Action1,
 	  	 Action2,
 	  	 Action3,
 	  	 Action4,
 	  	 Action_Comment_Id,
 	  	 Research_User_Id,
 	  	 Research_Status_Id,
 	  	 Research_Open_Date,
 	  	 Research_Close_Date,
 	  	 Research_Comment_Id,
 	  	 Event_Reason_Tree_Data_Id,
 	  	 User_Id,
 	  	 EventSubCategory_Id,
 	  	 NewValue,
 	  	 NewEngUnitLabel,
 	  	 OldEngUnitLabel,
 	  	 OldValue,
 	  	 OPCEventCategory_Id,
 	  	 OPCSeverity,
 	  	 Historian_Quality_Id,
 	  	 Signature_Id,
 	  	 Source_Id,
 	  	 Start_Time_Ms,
 	  	 Modified_On,
 	  	 Modified_On_Ms
       )
       Values(
 	  	 @EventNum ,
 	  	 @PUId ,
 	  	 @EventSubTypeId ,
 	  	 @StartTime ,
 	  	 @EndTime ,
 	  	 @Duration ,
 	  	 @Ack,   
 	  	 @AckOn ,
 	  	 @AckBy ,
 	  	 @UDECommentId,
 	  	 @Cause1 ,
 	  	 @Cause2,
 	  	 @Cause3,
 	  	 @Cause4 ,
 	  	 @CauseCommentId ,
 	  	 @Action1 ,
 	  	 @Action2 ,
 	  	 @Action3 ,
 	  	 @Action4 ,
 	  	 @ActionCommentId ,
 	  	 @ResearchUserId ,
 	  	 @ResearchStatusId ,
 	  	 @ResearchOpenDate ,
 	  	 @ResearchCloseDate,  
 	  	 @ResearchCommentId,
 	  	 @Event_Reason_Tree_Data_Id,
 	  	 @UserId,
 	  	 @EventSubCategory_Id,
 	  	 @NewValue,
 	  	 @NewEngUnitLabel,
 	  	 @OldEngUnitLabel,
 	  	 @OldValue,
 	  	 @OPCEventCategory_Id,
 	  	 @OPCSeverity,
 	  	 @Historian_Quality_Id,
 	  	 @Signature_Id,
 	  	 @Source_Id,
 	  	 @Start_Time_Ms,
 	  	 @StartTime,  -- Modified_On
 	  	 @Start_Time_Ms  -- Modified_On_Ms
        )
    If @@ERROR > 0 
     Begin
      RollBack Transaction
      RETURN(-100)
     End
     Select @EventId = Scope_Identity() 
     Commit Transaction 
     Select 8,0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
             Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
             Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId
     From User_Defined_Events
      Where UDE_Id = @EventId
/*
Insert Into DebugOutputUDE 
 Select @TransNum,@EventSubTypeDesc,Action_Comment_Id,Action4,Action3,Action2,
        Action1, Cause_Comment_Id,Cause4,Cause3,Cause2,Cause1,Ack_By,
 	 Ack, Duration, Event_SubType_Id, PU_Id, UDE_Desc, UDE_Id,
        @UserId, Ack_On, Start_Time, End_Time, Research_Comment_Id, Research_Status_Id,
        Research_User_Id, Research_Open_Date, Research_Close_Date, @TransType,
        Comment_Id, getDate()
  From User_Defined_Events
      Where UDE_Id = @EventId
*/
    RETURN(1)
  end
else if @TransType = 2
  begin
 	 Select @OldEndTime = End_Time,@OldStartTime = Start_Time From User_Defined_Events Where UDE_Id = @EventId
   	 If @TransNum = 0
   	   Begin
     	  	 Select @EventNum = Coalesce(@EventNum,UDE_Desc),
     	  	  	 @StartTime = Coalesce(@StartTime,Start_Time),
     	  	  	 @EndTime = Coalesce(@EndTime,End_Time),
     	  	  	 @Duration 	 = Coalesce(@Duration,Duration),
     	  	  	 @Ack = Coalesce(@Ack,Ack),
     	  	  	 @AckOn = Coalesce(@AckOn,Ack_On),
     	  	  	 @AckBy = Coalesce(@AckBy,Ack_By),
     	  	  	 @Cause1 = Coalesce(@Cause1,Cause1),
     	  	  	 @Cause2 = Coalesce(@Cause2,Cause2),
     	  	  	 @Cause3 = Coalesce(@Cause3,Cause3),
     	  	  	 @Cause4 = Coalesce(@Cause4,Cause4),
     	  	  	 @Action1 = Coalesce(@Action1,Action1),
     	  	  	 @Action2 = Coalesce(@Action2,Action2),
     	  	  	 @Action3 = Coalesce(@Action3,Action3),
     	  	  	 @Action4 = Coalesce(@Action4,Action4),
     	  	  	 @ResearchUserId = Coalesce(@ResearchUserId,Research_User_Id),
     	  	  	 @ResearchStatusId = Coalesce(@ResearchStatusId,Research_Status_Id),
     	  	  	 @ResearchOpenDate = Coalesce(@ResearchOpenDate,Research_Open_Date),
     	  	  	 @ResearchCloseDate = Coalesce(@ResearchCloseDate,Research_Close_Date)
     	  	  From User_Defined_Events
     	  	  Where (UDE_Id = @EventId)
   	   End
  -- Look up @Event_Reason_Tree_Data_Id If necessary
  If @Event_Reason_Tree_Data_Id is null and @Cause1 is not null
 	 Begin
 	   Select @TreeId = Cause_Tree_Id From Event_Subtypes where Event_Subtype_Id = @EventSubTypeId
   	   If @Cause2 Is null
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   Else If @Cause3 Is null
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   Else If @Cause4 Is null
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
   	   Else 
 	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id  = @Cause4 and Tree_Name_Id = @TreeId
 	 End
 	 If @DurationReq = 1
 	   Begin
 	  	 If @OldEndTime is not null and @EndTime is null  -- Event opened
 	    	  	 Execute spPDB_DBMgrCleanupUserDefined @EventId,null,1,@EventSubTypeId,@DurationReq
 	  	 Else If (@OldEndTime is not null and @EndTime is Not null) and  (@OldEndTime <> @EndTime) -- Event Moved
 	    	  	 Execute spPDB_DBMgrCleanupUserDefined @EventId,@EndTime,1,@EventSubTypeId,@DurationReq
 	   End
 	 Else
 	   Begin
 	  	 If @OldStartTime is not null and @StartTime is null  -- Event opened
 	    	  	 Execute spPDB_DBMgrCleanupUserDefined @EventId,null,1,@EventSubTypeId,@DurationReq
 	  	 Else If (@OldStartTime is not null and @StartTime is Not null) and  (@OldStartTime <> @StartTime) -- Event Moved
 	    	  	 Execute spPDB_DBMgrCleanupUserDefined @EventId,@StartTime,1,@EventSubTypeId,@DurationReq
 	   End
    Update User_Defined_Events 
     SET 
      UDE_Desc = @EventNum,
      Start_Time =@StartTime,
      End_Time =@EndTime,
      Duration =@Duration,
      Ack =@Ack,
      Ack_On =@AckOn,
      Ack_By =@AckBy,
      Cause1 =@Cause1,
      Cause2 =@Cause2,
      Cause3 =@Cause3,
      Cause4 =@Cause4,
      Action1 =@Action1,
      Action2 =@Action2 ,
      Action3 =@Action3 ,
      Action4 =@Action4 ,
      Research_User_Id =@ResearchUserId ,
      Research_Status_Id = @ResearchStatusId,
      Research_Open_Date = @ResearchOpenDate,
      Research_Close_Date =@ResearchCloseDate,
 	   Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id
     Where UDE_Id = @EventId
    If @@ERROR > 0 RETURN(-100)
    Select 8,0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
             Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
             Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId
     From User_Defined_Events
      Where UDE_Id = @EventId
    RETURN(2)
  end
else if @TransType = 3 -- Delete
  begin
   Select 8,0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
             Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
             Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId
     From User_Defined_Events
      Where UDE_Id = @EventId
 	 Execute spPDB_DBMgrCleanupUserDefined @EventId,null,1,@EventSubTypeId,@DurationReq
    Delete User_Defined_Events 
      Where UDE_ID = @EventId
    If @@ERROR > 0 RETURN(-100)
    RETURN(3)
  end
else if @TransType = 0
  begin
    Select @LastAck = Ack
      From User_Defined_Events
      Where UDE_Id = @EventId
    If @Ack <> @LastAck
      BEGIN 
        UPDATE User_Defined_Events 
          Set Ack = @Ack, 
              Ack_On = 
                CASE 
                  WHEN @Ack = 1 THEN GETDATE()
                  ELSE NULL
                END,
              Ack_By = 
                CASE 
                  WHEN @Ack = 1 THEN @UserId
                  ELSE NULL
                END
          Where UDE_ID = @EventId
      END
    If @Cause1 IS NOT NULL 
      BEGIN 
 	   -- Look up @Event_Reason_Tree_Data_Id If necessary
 	   If @Event_Reason_Tree_Data_Id is null
 	  	 Begin
 	  	   Select @TreeId = Cause_Tree_Id From Event_Subtypes where Event_Subtype_Id = @EventSubTypeId
 	    	   If @Cause2 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   Else If @Cause3 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   Else If @Cause4 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	    	   Else 
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id  = @Cause4 and Tree_Name_Id = @TreeId
 	  	 End
        UPDATE User_Defined_Events 
          Set Cause1 = @Cause1, 
              Cause2 = @Cause2, 
              Cause3 = @Cause3, 
              Cause4 = @Cause4,
 	  	  	   Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id
          Where UDE_ID = @EventId
      END
    If @Action1 IS NOT NULL 
      BEGIN 
        UPDATE User_Defined_Events 
          Set Action1 = @Action1, 
              Action2 = @Action2, 
              Action3 = @Action3, 
              Action4 = @Action4 
          Where UDE_ID = @EventId
      END
    If @ResearchStatusId IS NOT NULL or 
       @ResearchOpenDate IS NOT NULL or 
       @ResearchCloseDate IS NOT NULL 
      BEGIN 
        UPDATE User_Defined_Events 
          Set 
            Research_User_Id = @UserId,
            Research_Status_Id = @ResearchStatusId,
            Research_Open_Date = @ResearchOpenDate,
            Research_Close_Date = @ResearchCloseDate
          Where UDE_ID = @EventId
      END
   Select 8,0, UDE_Id, UDE_Desc, PU_Id, Event_SubType_Id, Start_Time, End_Time, Duration, Ack, Ack_On, Ack_By, Cause1, Cause2, 
             Cause3, Cause4, Cause_Comment_Id,  Action1, Action2, Action3, Action4, Action_Comment_Id, Research_User_Id, Research_Status_Id,
             Research_Open_Date, Research_Close_Date, Research_Comment_Id, Comment_Id, @TransType, @EventSubTypeDesc,  @TransNum, @UserId
     From User_Defined_Events
      Where UDE_Id = @EventId
    RETURN(2)
  end
else 
  begin
    RETURN(4)
  end
