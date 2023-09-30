CREATE PROCEDURE dbo.spServer_AMgrAddNewAlarm
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
@AlarmTypeId int,
@UserId int,
@ATSRD_Id int,
@SubType int,
@ATVRD_Id int,
@SignatureId int = NULL,
@PathId int = NULL
AS
declare @Prio int
declare @AlarmId int
select @Prio = null
select @AlarmId = null
If (@AlarmTypeId = 3)
  Begin
    Insert Into Alarms (Alarm_Desc, Alarm_Type_Id, Key_Id, Start_Time, End_Time, Ack, Ack_On, Ack_By, Start_Result, End_Result, Min_Result, Max_Result, User_Id, Modified_On,SubType,Signature_Id, Path_Id) 
      Values(@AlarmDesc, @AlarmTypeId, @KeyId, @StartTime, @EndTime, @ack, @AckOn, @AckBy, @StartValue, @EndValue, @MinValue, @MaxValue, @UserId, dbo.fnServer_CmnGetDate(GetUTCDate()),@SubType, @SignatureId, @PathId)
    Select @AlarmId=Alarm_Id From Alarms where (Key_Id = @KeyId) and (SubType = @SubType)
    Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1, ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id, Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType, NULL, NULL, Signature_Id, Path_Id
      From Alarms
      where (Key_Id = @KeyId) and (SubType = @SubType)
  End
Else
Begin
Insert Into Alarms (Alarm_Desc, ATD_Id, Alarm_Type_Id, Key_Id, Start_Time, 
 	  	  	  	  	 End_Time, Ack, Ack_On, Ack_By, Start_Result, End_Result, 
 	  	  	  	  	 Min_Result, Max_Result, User_Id, Cause1, Cause2, 
 	  	  	  	  	 Cause3, Cause4, Action1, Action2, Action3, 
 	  	  	  	  	 Action4, Source_PU_Id, Research_Open_Date, Research_Close_Date,Modified_On, ATSRD_Id, SubType, ATVRD_Id, Signature_Id,
 	  	  	  	  	 Event_Reason_Tree_Data_Id) 
Select @AlarmDesc, @ATDId, @AlarmTypeId, @KeyId, @StartTime, 
 	  	 @EndTime, @ack, @AckOn, @AckBy, @StartValue, @EndValue, 
 	  	 @MinValue, @MaxValue, @UserId, 
 	  	 CASE 
      WHEN Override_Cause_Tree_Id IS NOT NULL THEN Override_Default_Cause1
      ELSE COALESCE(Override_Default_Cause1, Default_Cause1) END,
    CASE 
      WHEN Override_Cause_Tree_Id IS NOT NULL THEN Override_Default_Cause2
      ELSE COALESCE(Override_Default_Cause2, Default_Cause2) END,
    CASE 
      WHEN Override_Cause_Tree_Id IS NOT NULL THEN Override_Default_Cause3
      ELSE COALESCE(Override_Default_Cause3, Default_Cause3) END,
    CASE 
      WHEN Override_Cause_Tree_Id IS NOT NULL THEN Override_Default_Cause4
      ELSE COALESCE(Override_Default_Cause4, Default_Cause4) END,
    CASE 
      WHEN Override_Action_Tree_Id IS NOT NULL THEN Override_Default_Action1
      ELSE COALESCE(Override_Default_Action1, Default_Action1) END,
    CASE 
      WHEN Override_Action_Tree_Id IS NOT NULL THEN Override_Default_Action2
      ELSE COALESCE(Override_Default_Action2, Default_Action2) END,
    CASE 
      WHEN Override_Action_Tree_Id IS NOT NULL THEN Override_Default_Action3
      ELSE COALESCE(Override_Default_Action3, Default_Action3) END,
    CASE 
      WHEN Override_Action_Tree_Id IS NOT NULL THEN Override_Default_Action4
      ELSE COALESCE(Override_Default_Action4, Default_Action4) END,
    COALESCE(P.PU_Id, P.Master_Unit),
 	  	 @ResearchOpenDate,
 	  	 @ResearchCloseDate,
 	  	 dbo.fnServer_CmnGetDate(GetUTCDate()),
 	  	 @ATSRD_Id ,
    @SubType,
 	  	 @ATVRD_Id,
    @SignatureId,
    CASE 
      WHEN Override_Cause_Tree_Id IS NOT NULL THEN d.Event_Reason_Tree_Data_Id
      ELSE COALESCE(d.Event_Reason_Tree_Data_Id, t.Event_Reason_Tree_Data_Id) END
From Alarm_Template_Var_Data d
Join Alarm_Templates t on t.AT_Id = d.AT_Id
Join Variables_Base v on d.Var_Id = v.Var_Id
Join Prod_Units_Base P on P.PU_Id = v.PU_Id
Where d.ATD_Id = @ATDId and d.Var_Id = @KeyId
Select @AlarmId=Alarm_Id From Alarms 
 	 where Key_Id = @KeyId and ATD_Id = @ATDId and Start_Time = @StartTime 
exec spServer_AMgrGetAlarmPriority @AlarmId, @Prio output
Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
       a.ATD_Id, a.Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	    Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
       User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, a.ATSRD_Id,SubType, @Prio, a.ATVRD_ID, att.ESignature_Level
From Alarms a
  Join Alarm_Template_Var_Data atv on atv.ATD_Id = @ATDId
  Join Alarm_Templates att on att.AT_Id = atv.AT_Id
 	 where Key_Id = @KeyId and a.ATD_Id = @ATDId and Start_Time = @StartTime 
End
