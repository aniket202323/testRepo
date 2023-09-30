CREATE PROCEDURE dbo.spServer_AMgrUpdateAlarm
@AlarmId int,
@KeyId int,
@ATDId int,
@StartTime datetime,
@EndTime datetime,
@StartValue nVarChar(100),
@EndValue nVarChar(100),
@MinValue nVarChar(100),
@MaxValue nVarChar(100),
@Ack int,
@AckOn datetime,
@AckBy int,
@AlarmDesc nVarChar(1000),
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
@Event_Reason_Tree_Data_Id  Int = Null,  -- Used For Categories
@ATVRD_Id int = NULL,
@Signature_Id int = NULL,
@PathId int = NULL
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
@Compare_ATVRD_Id int,
@Compare_SubType int,
@Compare_Cutoff tinyint,
@Compare_End_Result nvarchar(25),
@Compare_Max_Result nvarchar(25),
@Compare_Min_Result nvarchar(25),
@Compare_Start_Result nvarchar(25),
@Compare_SigId int,
@Found int,
@Prio int,
@TreeId Int
select @Prio = null
-- Look up @Event_Reason_Tree_Data_Id If necessary
If @Event_Reason_Tree_Data_Id is null and @Cause1 is not null
Begin
 	 IF @ATDId Is Null and @ATVRD_Id Is Null
 	 BEGIN
 	  	 SELECT @ATDId= a.ATD_Id ,@ATVRD_Id = a.ATVRD_Id  FROM Alarms a WHERE a.Alarm_Id = @AlarmId 
 	 END
 	 IF @ATDId IS Not NULL
 	 BEGIN
 	  	 Select @TreeId = b.Cause_Tree_Id
 	  	 FROM Alarm_Template_Var_Data a
 	  	 JOIN Alarm_Templates  b on b.AT_Id = a.AT_Id  
 	  	 where a.ATD_Id   = @ATDId
 	 END
 	 IF @ATVRD_Id IS Not NULL AND @TreeId Is Null
 	 BEGIN
 	  	 Select @TreeId = b.Cause_Tree_Id
 	  	 FROM Alarm_Template_Variable_Rule_Data a
 	  	 JOIN Alarm_Templates  b on b.AT_Id = a.AT_Id  
 	  	 where a.ATVRD_Id  = @ATVRD_Id
 	 END
 	 
 	 IF @TreeId Is Not Null
 	 BEGIN
 	  	 If @Cause2 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id Is Null and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	 Else If @Cause3 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id Is Null and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	 Else If @Cause4 Is null
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id Is Null and Tree_Name_Id = @TreeId
 	  	 Else 
 	  	  	 Select @Event_Reason_Tree_Data_Id = Min(Event_Reason_Tree_Data_Id) From Event_Reason_Tree_Data Where  Level1_Id = @Cause1 and  Level2_Id = @Cause2 and  Level3_Id = @Cause3 and Level4_Id  = @Cause4 and Tree_Name_Id = @TreeId
  END
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
        ATVRD_Id = COALESCE(@ATVRD_Id,ATVRD_Id),
        Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id,
 	  	  	  	 Signature_Id = COALESCE(@Signature_Id,Signature_Id),
 	  	  	  	 Path_Id = COALESCE(@PathId,Path_Id)
      Where (Alarm_Id = @AlarmId)
    -- For Post Alarm Message
    Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType, NULL, ATVRd_id,Signature_Id,Path_Id
      From Alarms
      Where Alarm_Id = @AlarmId
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
  @Compare_ATVRD_Id = ATVRD_Id,
  @Compare_SubType = SubType,
  @Compare_SigId = Signature_Id
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
    and (@Compare_ATVRD_Id=@ATVRD_Id)
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
    and (@Compare_Alarm_Id=@AlarmId) and (@Compare_SigId = @Signature_Id))
begin
  exec spServer_AMgrGetAlarmPriority @AlarmId, @Prio output
 	 if  NOT(@TransNum = 0 or @TransNum is NULL)
 	   Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
 	  	   ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	  	  	 Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
 	  	  	 User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType, @Prio, ATVRD_Id, Signature_Id
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
 	 ack=@Ack, ack_on=@AckOn, ack_by=@AckBy, Alarm_Desc=@AlarmDesc,
 	 Research_Open_Date=@ResearchOpenDate, Research_Close_Date=@ResearchCloseDate,
 	 Cause1=@Cause1,Cause2=@Cause2,Cause3=@Cause3,Cause4=@Cause4,
 	 Action1=@Action1,Action2=@Action2,Action3=@Action3,Action4=@Action4,
 	 Alarm_Type_Id=@AlarmTypeId, Cause_Comment_Id=@CauseCommentId, Action_Comment_Id=@ActionCommentId,
 	 Modified_On=dbo.fnServer_CmnGetDate(GetUTCDate()), User_Id=@UserId, Source_PU_Id=@PUId,
 	 Research_Comment_Id=@ResearchCommentId, 	 Duration=@Duration,
 	 Research_User_Id=@ResearchUserId, Research_Status_Id=@ResearchStatusId,
 	 Cutoff=@Cutoff, ATSRD_Id=@ATSRD_Id, ATVRD_Id=@ATVRD_Id , SubType = @SubType,
        Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id, Signature_Id = COALESCE(@Signature_Id,Signature_Id)
    where Alarm_Id = @AlarmId
  end
  Else If @TransNum = 99 -- Client Initiated Updates
  begin
 	 DECLARE @MyAckOn DateTime,
 	  	    @MyAckBy 	 Int
     Select @LastAck = Ack,
 	  	  @MyAckOn = Ack_On,
 	  	  @MyAckBy = Ack_By
      From Alarms
      Where Alarm_Id = @AlarmId
    If @Ack <> @LastAck
 	 BEGIN 
 	     	 If @Ack = 1
 	  	  	 Select @MyAckOn = dbo.fnServer_CmnGetDate(GetUTCDate()),@MyAckBy = @UserId
 	  	 ELSE
 	  	  	 Select @MyAckOn = Null,@MyAckBy = Null
 	 END
    If @ResearchStatusId IS NOT NULL or 
       @ResearchOpenDate IS NOT NULL or 
       @ResearchCloseDate IS NOT NULL or
       @ResearchUserId IS NOT NULL
      BEGIN 
        UPDATE Alarms 
          Set  Ack = @Ack,
 	  	  	 Ack_By = @MyAckBy,
 	  	  	 Ack_On = @MyAckOn,
 	  	  	 Cause1 = @Cause1, 
 	  	  	 Cause2 = @Cause2, 
 	  	  	 Cause3 = @Cause3, 
 	  	  	 Cause4 = @Cause4,
 	  	  	 Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id ,
 	  	  	 Action1 = @Action1, 
 	  	  	 Action2 = @Action2, 
 	  	  	 Action3 = @Action3, 
 	  	  	 Action4 = @Action4,
 	  	  	 Research_User_Id = @ResearchUserId,
 	  	  	 Research_Status_Id = @ResearchStatusId,
 	  	  	 Research_Open_Date = @ResearchOpenDate,
 	  	  	 Research_Close_Date = @ResearchCloseDate,
 	  	  	 Signature_id = COALESCE(@Signature_Id,Signature_Id),
 	  	  	 User_Id = @UserId
      Where Alarm_Id = @AlarmId
      END
 	  	 else
 	  	  	 begin
 	  	     UPDATE Alarms 
 	  	       Set Ack = @Ack,
 	  	  	  	 Ack_By = @MyAckBy,
 	  	  	  	 Ack_On = @MyAckOn,
 	  	  	  	 Cause1 = @Cause1, 
 	  	  	  	 Cause2 = @Cause2, 
 	  	  	  	 Cause3 = @Cause3, 
 	  	  	  	 Cause4 = @Cause4,
 	  	  	  	 Event_Reason_Tree_Data_Id = @Event_Reason_Tree_Data_Id ,
 	  	  	  	 Action1 = @Action1, 
 	  	  	  	 Action2 = @Action2, 
 	  	  	  	 Action3 = @Action3, 
 	  	  	  	 Action4 = @Action4,
 	  	  	  	 Signature_id = COALESCE(@Signature_Id,Signature_Id),
 	  	  	  	 User_Id = @UserId
 	  	       Where Alarm_Id = @AlarmId
 	  	  	 end
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
  exec spServer_AMgrGetAlarmPriority @AlarmId, @Prio output
  Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
    a.ATD_Id, a.Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
    Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
    User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, a.ATSRD_Id, SubType, @Prio, a.ATVRD_Id, att.ESignature_Level
  From Alarms a
    Join Alarm_Template_Var_Data atv on atv.ATD_Id = a.ATD_Id
    Join Alarm_Templates att on att.AT_Id = atv.AT_Id
    Where Alarm_Id = @AlarmId
  return (2)
end
RETURN(4)
