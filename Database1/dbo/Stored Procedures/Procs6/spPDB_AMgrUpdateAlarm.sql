CREATE PROCEDURE dbo.spPDB_AMgrUpdateAlarm
@AlarmId int,
@KeyId int,
@ATDId int,
@StartTime datetime,
@EndTime datetime,
@StartValue nvarchar(100),
@EndValue nvarchar(100),
@MinValue nvarchar(100),
@MaxValue nvarchar(100),
@Ack int,
@AckOn datetime,
@AckBy int,
@AlarmDesc nvarchar(1000),
@ResearchOpenDate datetime,
@ResearchCloseDate datetime,
@Cause1 int,
@Cause2 int,
@Cause3 int,
@Cause4 int,
@Action1 int,
@Action2 int,
@Action3 int,
@Action4 int,
@AlarmTypeId int,
@CauseCommentId int,
@ActionCommentId int,
@UserId int,
@PUId int,
@ResearchCommentId int,
@Duration int,
@ResearchUserId int,
@ResearchStatusId int,
@Cutoff int,
@ATSRD_Id int,
@TransNum int,
@SubType int,
@Event_Reason_Tree_Data_Id  Int = Null,  
-- Added for Historian
@Ack_On_Ms int = Null,
@Ack_Comment_Id int = Null ,
@End_Time_Ms int = Null, 
@EngUnitLabel nvarchar(25)= Null,
@EventSubCategory_Id int = Null, 
@Historian_Quality_Id int = Null,
@Modified_Time DateTime = Null,
@Modified_Time_Ms int = Null,
@OPCCondition_Id int= Null,
@OPCSubCondition_Id int= Null,
@OPCEventCategory_Id int= Null,
@OPCSeverity int= Null,
@Data_Type_Id int= Null,
@Signature_Id int= Null,
@Source_Id int= Null,
@Start_Time_Ms int = Null
AS
-- Return Values:
--   (-100) Error.
--   (1)    Success: New record added.
--   (2)    Success: Existing record modified.
--   (3)    Success: Existing record deleted.
--   (4)    Success: No action taken.
-- Trans Nums:
-- (0)  From AlarmMgr
-- (1)  Comment only updates initiated from the client (e.g. ProfALM.OCX, Common Dialogs) 
-- (99) Updates initiated from the client (e.g. ProfALM.OCX, Common Dialogs)
Declare @Compare_Alarm_Id int,
@Compare_Ack bit,
@Compare_Alarm_Desc char(1000),
@Compare_Research_Close_Date datetime,
@Compare_Start_Time datetime,
@Compare_Modified_On datetime,
@Compare_End_Time datetime,
@Compare_Ack_On datetime,
@Compare_Research_Open_Date datetime,
@Compare_Research_Status_Id int,
@Compare_Source_PU_Id int,
@Compare_User_Id int,
@Compare_Action4 int,
@Compare_Duration int,
@Compare_Research_User_Id int,
@Compare_Action1 int,
@Compare_Research_Comment_Id int,
@Compare_Action3 int,
@Compare_Cause3 int,
@Compare_Action_Comment_Id int,
@Compare_Cause_Comment_Id int,
@Compare_Ack_By int,
@Compare_Action2 int,
@Compare_Cause2 int,
@Compare_Alarm_Type_Id int,
@Compare_Cause4 int,
@Compare_Key_Id int,
@Compare_Cause1 int,
@Compare_ATD_Id int,
@Compare_ATSRD_Id int,
@Compare_SubType int,
@Compare_Cutoff tinyint,
@Compare_End_Result Varchar_Value,
@Compare_Max_Result Varchar_Value,
@Compare_Min_Result Varchar_Value,
@Compare_Start_Result Varchar_Value,
@Found int,
@Prio int,
@TreeId Int
select @Prio = null
-- Look up @Event_Reason_Tree_Data_Id If necessary
If @Event_Reason_Tree_Data_Id is null and @Cause1 is not null
Begin
  Select @TreeId = Cause_Tree_Id From Event_Subtypes where Event_Subtype_Id = @SubType
  If @Cause2 Is null
    Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
  Else If @Cause3 Is null
    Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
  Else If @Cause4 Is null
    Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
  Else 
    Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id  = @Cause4 and Tree_Name_Id = @TreeId
End
if (@AlarmTypeId = 3)
  Begin
    Select @Found = NULL
    Select @Found = Alarm_Id From Alarms Where (Alarm_Id = @AlarmId)
    If (@Found Is NULL)
      return(4)
    Update Alarms
      Set 
        Start_Time = COALESCE(@StartTime,Start_Time),
        End_Time = COALESCE(@EndTime,End_Time),
        Start_Result = COALESCE(@StartValue,Start_Result),
        End_Result = COALESCE(@EndValue,End_Result),
        Min_Result = COALESCE(@MinValue,Min_Result),
        Max_Result = COALESCE(@MaxValue,Max_Result),
        Ack = COALESCE(@Ack,Ack),
        Ack_On = COALESCE(@AckOn,Ack_On),
        Ack_By = COALESCE(@AckBy,Ack_By),
        Alarm_Desc = COALESCE(@AlarmDesc,Alarm_Desc),
        Research_Open_Date = COALESCE(@ResearchOpenDate,Research_Open_Date),
        Research_Close_Date = COALESCE(@ResearchCloseDate,Research_Close_Date),
        Cause1 = COALESCE(@Cause1,Cause1),
        Cause2 = COALESCE(@Cause2,Cause2),
        Cause3 = COALESCE(@Cause3,Cause3),
        Cause4 = COALESCE(@Cause4,Cause4),
        Action1 = COALESCE(@Action1,Action1),
        Action2 = COALESCE(@Action2,Action2),
        Action3 = COALESCE(@Action3,Action3),
        Action4 = COALESCE(@Action4,Action4),
        Cause_Comment_Id = COALESCE(@CauseCommentId,Cause_Comment_Id),
        Action_Comment_Id = COALESCE(@ActionCommentId,Action_Comment_Id),
        User_Id = COALESCE(@UserId,User_Id),
        Source_PU_Id = COALESCE(@PUId,Source_PU_Id),
        Research_Comment_Id = COALESCE(@ResearchCommentId,Research_Comment_Id),
        Duration = COALESCE(@Duration,Duration),
        Research_User_Id = COALESCE(@ResearchUserId,Research_User_Id),
        Research_Status_Id = COALESCE(@ResearchStatusId,Research_Status_Id),
        Cutoff = COALESCE(@Cutoff,Cutoff),
        ATSRD_Id = COALESCE(@ATSRD_Id,ATSRD_Id),
        Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id
      Where (Alarm_Id = @AlarmId)
    -- For Post Alarm Message
    Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType
      From Alarms
      Where Alarm_Id = @AlarmId
    return(2)
  End
Else if (@AlarmTypeId = 6)
  -- Historical Alarm
  Begin
    Select @Found = NULL
    Select @Found = Alarm_Id From Alarms Where (Alarm_Id = @AlarmId)
    If (@Found Is NULL)
      return(4)
   	 If (@Modified_Time Is NULL)
  	 Begin
      set @Modified_Time = GETDATE()
  	   set @Modified_Time_Ms = 0
    End
    Update Alarms
      Set 
        Ack = COALESCE(@Ack,Ack),
        Ack_On = COALESCE(@AckOn,Ack_On),
 	  	 Ack_On_Ms = COALESCE(@Ack_On_Ms,Ack_On_Ms),
        Ack_By = COALESCE(@AckBy,Ack_By),
 	  	 Ack_Comment_id = COALESCE(@Ack_Comment_Id, Ack_Comment_Id),
        Alarm_Desc = COALESCE(@AlarmDesc, Alarm_Desc),
        Cause_Comment_Id = COALESCE(@CauseCommentId,Cause_Comment_Id),
        End_Time = COALESCE(@EndTime,End_Time),
 	  	 End_Time_Ms = COALESCE(@End_Time_Ms, End_Time_Ms),
        End_Result = COALESCE(@EndValue,End_Result),
    	     EngUnitLabel = COALESCE(@EngUnitLabel, EngUnitLabel),
 	  	 EventSubCategory_Id = COALESCE(@EventSubCategory_Id, EventSubCategory_Id),
    	     Historian_Quality_Id = COALESCE(@Historian_Quality_Id, Historian_Quality_Id),
 	  	 OPCCondition_Id = COALESCE(@OPCCondition_Id, OPCCondition_Id),
 	  	 OPCSubCondition_Id = COALESCE(@OPCSubCondition_Id, OPCSubCondition_Id),
 	  	 OPCEventCategory_Id = COALESCE(@OPCEventCategory_Id, OPCEventCategory_Id),
 	  	 OPCSeverity = COALESCE(@OPCSeverity, OPCSeverity),
        Modified_On = COALESCE(@Modified_Time,Modified_On),
 	  	 Modified_On_Ms = COALESCE(@Modified_Time_Ms, Modified_On_Ms),
 	  	 Data_Type_Id = COALESCE(@Data_Type_Id, Data_Type_Id),
 	  	 Signature_Id = COALESCE(@Signature_Id, Signature_Id),
    	     Source_Id = COALESCE(@Source_Id, Source_Id),
        Start_Time = COALESCE(@StartTime,Start_Time),
 	  	 Start_Time_Ms = COALESCE(@Start_Time_Ms, Start_Time_Ms),
        Start_Result = COALESCE(@StartValue,Start_Result)
      Where (Alarm_Id = @AlarmId)
    return(2)
  End
Select
  @Compare_Alarm_Id = Alarm_Id,
  @Compare_Ack = Ack,
  @Compare_Alarm_Desc = Alarm_Desc,
  @Compare_Research_Close_Date = Research_Close_Date,
  @Compare_Start_Time = Start_Time,
  @Compare_Modified_On = Modified_On,
  @Compare_End_Time = End_Time,
  @Compare_Ack_On = Ack_On,
  @Compare_Research_Open_Date = Research_Open_Date,
  @Compare_Research_Status_Id = Research_Status_Id,
  @Compare_Source_PU_Id = Source_PU_Id,
  @Compare_User_Id = User_Id,
  @Compare_Action4 = Action4,
  @Compare_Duration = Duration,
  @Compare_Research_User_Id = Research_User_Id,
  @Compare_Action1 = Action1,
  @Compare_Research_Comment_Id = Research_Comment_Id,
  @Compare_Action3 = Action3,
  @Compare_Cause3 = Cause3,
  @Compare_Action_Comment_Id = Action_Comment_Id,
  @Compare_Cause_Comment_Id = Cause_Comment_Id,
  @Compare_Ack_By = Ack_By,
  @Compare_Action2 = Action2,
  @Compare_Cause2 = Cause2,
  @Compare_Alarm_Type_Id = Alarm_Type_Id,
  @Compare_Cause4 = Cause4,
  @Compare_Key_Id = Key_Id,
  @Compare_Cause1 = Cause1,
  @Compare_ATD_Id = ATD_Id,
  @Compare_Cutoff = Cutoff,
  @Compare_End_Result = End_Result,
  @Compare_Max_Result = Max_Result,
  @Compare_Min_Result = Min_Result,
  @Compare_Start_Result = Start_Result,
  @Compare_ATSRD_Id = ATSRD_Id,
  @Compare_SubType = SubType
From Alarms
Where Alarm_Id = @AlarmId
if  ((@TransNum = 0 or @TransNum is NULL)
    and (@Compare_Start_Time=@StartTime) 
    and (@Compare_End_Time=@EndTime or (@Compare_End_Time is NULL and @EndTime is NULL)) 
    and (@Compare_Start_Result=@StartValue or (@Compare_Start_Result is NULL and @StartValue is NULL)) 
    and (@Compare_Min_Result=@MinValue or (@Compare_Min_Result is NULL and @MinValue is NULL)) 
    and (@Compare_Max_Result=@MaxValue or (@Compare_Max_Result is NULL and @MaxValue is NULL)) 
    and (@Compare_End_Result=@EndValue or (@Compare_End_Result is NULL and @EndValue is NULL)) 
    and (@Compare_Ack=@Ack) 
    and (@Compare_ATSRD_Id=@ATSRD_Id)
    and (@Compare_SubType=@SubType)
    and (@Compare_Ack_On=@AckOn or (@Compare_Ack_On is NULL and @AckOn is NULL)) 
    and (@Compare_Ack_By=@AckBy or (@Compare_Ack_By is NULL and @AckBy is NULL)) 
    and (@Compare_Alarm_Desc=@AlarmDesc) 
    and (@Compare_Research_Open_Date=@ResearchOpenDate or (@Compare_Research_Open_Date is NULL and @ResearchOpenDate is NULL)) 
    and (@Compare_Research_Close_Date=@ResearchCloseDate or (@Compare_Research_Close_Date is NULL and @ResearchCloseDate is NULL)) 
    and (@Compare_Cause1=@Cause1 or (@Compare_Cause1 is NULL and @Cause1 is NULL)) 
    and (@Compare_Cause2=@Cause2 or (@Compare_Cause2 is NULL and @Cause2 is NULL)) 
    and (@Compare_Cause3=@Cause3 or (@Compare_Cause3 is NULL and @Cause3 is NULL)) 
    and (@Compare_Cause4=@Cause4 or (@Compare_Cause4 is NULL and @Cause4 is NULL)) 
    and (@Compare_Action1=@Action1 or (@Compare_Action1 is NULL and @Action1 is NULL)) 
    and (@Compare_Action2=@Action2 or (@Compare_Action2 is NULL and @Action2 is NULL)) 
    and (@Compare_Action3=@Action3 or (@Compare_Action3 is NULL and @Action3 is NULL)) 
    and (@Compare_Action4=@Action4 or (@Compare_Action4 is NULL and @Action4 is NULL)) 
    and (@Compare_Alarm_Type_Id=@AlarmTypeId) 
    and (@Compare_Cause_Comment_Id=@CauseCommentId or (@Compare_Cause_Comment_Id is NULL and @CauseCommentId is NULL)) 
    and (@Compare_Action_Comment_Id=@ActionCommentId or (@Compare_Action_Comment_Id is NULL and @ActionCommentId is NULL)) 
    and (@Compare_User_Id=@UserId) 
    and (@Compare_Source_PU_Id=@PUId or (@Compare_Source_PU_Id is NULL and @PUId is NULL)) 
    and (@Compare_Research_Comment_Id=@ResearchCommentId or (@Compare_Research_Comment_Id is NULL and @ResearchCommentId is NULL)) 
    and (@Compare_Duration=@Duration or (@Compare_Duration is NULL and @Duration is NULL)) 
    and (@Compare_Research_User_Id=@ResearchUserId or (@Compare_Research_User_Id is NULL and @ResearchUserId is NULL)) 
    and (@Compare_Research_Status_Id=@ResearchStatusId or (@Compare_Research_Status_Id is NULL and @ResearchStatusId is NULL)) 
    and (@Compare_Cutoff=@Cutoff or (@Compare_Cutoff is NULL and @Cutoff is NULL)) 
    and (@Compare_Key_Id=@KeyId or (@Compare_Key_Id is NULL and @KeyId is NULL)) 
    and (@Compare_ATD_Id=@ATDId) 
    and (@Compare_Alarm_Id=@AlarmId))
    or  (@TransNum = 99
    and (@Compare_Ack=@Ack) 
    and (@Compare_Research_Open_Date=@ResearchOpenDate or (@Compare_Research_Open_Date is NULL and @ResearchOpenDate is NULL)) 
    and (@Compare_Research_Close_Date=@ResearchCloseDate or (@Compare_Research_Close_Date is NULL and @ResearchCloseDate is NULL)) 
    and (@Compare_Cause1=@Cause1 or (@Compare_Cause1 is NULL and @Cause1 is NULL)) 
    and (@Compare_Cause2=@Cause2 or (@Compare_Cause2 is NULL and @Cause2 is NULL)) 
    and (@Compare_Cause3=@Cause3 or (@Compare_Cause3 is NULL and @Cause3 is NULL)) 
    and (@Compare_Cause4=@Cause4 or (@Compare_Cause4 is NULL and @Cause4 is NULL)) 
    and (@Compare_Action1=@Action1 or (@Compare_Action1 is NULL and @Action1 is NULL)) 
    and (@Compare_Action2=@Action2 or (@Compare_Action2 is NULL and @Action2 is NULL)) 
    and (@Compare_Action3=@Action3 or (@Compare_Action3 is NULL and @Action3 is NULL)) 
    and (@Compare_Action4=@Action4 or (@Compare_Action4 is NULL and @Action4 is NULL)) 
    and (@Compare_Research_User_Id=@ResearchUserId or (@Compare_Research_User_Id is NULL and @ResearchUserId is NULL)) 
    and (@Compare_Research_Status_Id=@ResearchStatusId or (@Compare_Research_Status_Id is NULL and @ResearchStatusId is NULL)) 
    and (@Compare_Alarm_Id=@AlarmId))
begin
  exec spPDB_AMgrGetAlarmPriority @AlarmId, @Prio output
 	 if  NOT(@TransNum = 0 or @TransNum is NULL)
 	   Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
 	  	   ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	  	  	 Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
 	  	  	 User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType, @Prio
 	  	 From Alarms
 	  	 Where Alarm_Id = @AlarmId
  RETURN(4)
end
else
begin
  Declare @LastAck bit
  -- Begin a new transaction.
  --
  BEGIN TRANSACTION
  if (@TransNum = 0 or @TransNum is NULL) -- AlarmMgr Initiated
  begin
    Update Alarms 
      set Start_Time=@StartTime, End_Time=@EndTime, Start_Result=@StartValue, 
 	 Min_Result=@MinValue, Max_Result=@MaxValue, End_Result=@EndValue,
 	 ack=@Ack, ack_on=@AckOn, Ack_By=@AckBy, Alarm_Desc=@AlarmDesc,
 	 Research_Open_Date=@ResearchOpenDate, Research_Close_Date=@ResearchCloseDate,
 	 Cause1=@Cause1,Cause2=@Cause2,Cause3=@Cause3,Cause4=@Cause4,
 	 Action1=@Action1,Action2=@Action2,Action3=@Action3,Action4=@Action4,
 	 Alarm_Type_Id=@AlarmTypeId, Cause_Comment_Id=@CauseCommentId, Action_Comment_Id=@ActionCommentId,
 	 Modified_On=CURRENT_TIMESTAMP, User_Id=@UserId, Source_PU_Id=@PUId,
 	 Research_Comment_Id=@ResearchCommentId, 	 Duration=@Duration,
 	 Research_User_Id=@ResearchUserId, Research_Status_Id=@ResearchStatusId,
 	 Cutoff=@Cutoff, ATSRD_Id=@ATSRD_Id , SubType = @SubType,
        Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id
    where Alarm_Id = @AlarmId
  end
  Else If @TransNum = 99 -- Client Initiated Updates
  begin
    Select @LastAck = Ack
      From Alarms
      Where Alarm_Id = @AlarmId
    If @Ack <> @LastAck
      BEGIN 
        UPDATE Alarms 
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
          Where Alarm_Id = @AlarmId
      END
    UPDATE Alarms 
      Set Cause1 = @Cause1, 
          Cause2 = @Cause2, 
          Cause3 = @Cause3, 
          Cause4 = @Cause4,
          Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id 
      Where Alarm_Id = @AlarmId
    UPDATE Alarms 
      Set Action1 = @Action1, 
          Action2 = @Action2, 
          Action3 = @Action3, 
          Action4 = @Action4 
      Where Alarm_Id = @AlarmId
    If @ResearchStatusId IS NOT NULL or 
       @ResearchOpenDate IS NOT NULL or 
       @ResearchCloseDate IS NOT NULL or
       @ResearchUserId IS NOT NULL
      BEGIN 
        UPDATE Alarms 
          Set 
            Research_User_Id = @ResearchUserId,
            Research_Status_Id = @ResearchStatusId,
            Research_Open_Date = @ResearchOpenDate,
            Research_Close_Date = @ResearchCloseDate
          Where Alarm_Id = @AlarmId
      END
  end
 if @@ERROR <> 0  
   Begin
     -- Need to add messages before using: RAISERROR(50003, 11, -1, 'Events')
     ROLLBACK TRANSACTION
     return (-100)
   End
 else 
   Begin
     COMMIT TRANSACTION
   End
  -- For Post Alarm Message
  exec spPDB_AMgrGetAlarmPriority @AlarmId, @Prio output
  Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
    ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
    Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
    User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType, @Prio
  From Alarms
  Where Alarm_Id = @AlarmId
  return (2)
end
RETURN(4)
