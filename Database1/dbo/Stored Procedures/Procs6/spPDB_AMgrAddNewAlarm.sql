CREATE PROCEDURE dbo.spPDB_AMgrAddNewAlarm
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
@AlarmTypeId int,
@UserId int,
@ATSRD_Id int,
@SubType int,
-- Start Historian extra attributes
@Ack_On_Ms int = Null,
@Ack_Comment_Id Int= Null,
@Cause_Comment_Id Int= Null,
@End_Time_Ms int= Null,
@EngUnitLabel nvarchar(25)= Null,
@EventSubCategory_Id int = Null,
@Modified_On datetime = Null,
@Modified_On_Ms int = Null,
@OPCCondition_Id int = Null, 
@OPCSubCondition_Id int = Null, 
@OPCEventCategory_Id int = Null,
@OPCSeverity int = Null,
@Data_Type_Id int = Null,
@Signature_Id int = Null,
@Source_Id int = Null,
@Start_Time_Ms int = Null,
@Quality_Id int = Null
AS
declare @Prio int
declare @AlarmId int
select @Prio = null
select @AlarmId = null
If (@AlarmTypeId = 3)
Begin
    Insert Into Alarms (Alarm_Desc, Alarm_Type_Id, Key_Id, Start_Time, End_Time, Ack, Ack_On, Ack_By, Start_Result, End_Result, Min_Result, Max_Result, User_Id, Modified_On,SubType) 
      Values(@AlarmDesc, @AlarmTypeId, @KeyId, @StartTime, @EndTime, @ack, @AckOn, @AckBy, @StartValue, @EndValue, @MinValue, @MaxValue, @UserId, GetDate(),@SubType)
    Select @AlarmId=Alarm_Id From Alarms where (Key_Id = @KeyId) and (SubType = @SubType)
    Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1, ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id, Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType
      From Alarms
      where (Key_Id = @KeyId) and (SubType = @SubType)
End Else If (@AlarmTypeId = 6)
Begin
  -- Historian Alarm.  Add the new alarm, and return.
  If (@Modified_On Is NULL)
  Begin
    set @Modified_On = GETDATE()
 	 set @Modified_On_Ms = 0
  End
  Insert Into Alarms (Ack, Ack_On, Ack_On_Ms, Ack_By, Ack_Comment_Id, Alarm_Desc, Alarm_Type_Id, Cause_Comment_Id, End_Time, End_Time_Ms, End_Result, EventSubCategory_Id, OPCCondition_Id, OPCSubCondition_Id, OPCEventCategory_Id, OPCSeverity, Data_Type_Id, Signature_Id, Source_Id, Start_Result, Start_Time, Start_Time_Ms, Historian_Quality_Id, EngUnitLabel, User_Id, SubType, Modified_On, Modified_On_Ms)
    Values(@Ack, @AckOn, @Ack_On_Ms, @AckBy, @Ack_Comment_Id, @AlarmDesc, @AlarmTypeId, @Cause_Comment_Id, @EndTime, @End_Time_Ms, @EndValue, @EventSubCategory_Id, @OPCCondition_Id, @OPCSubCondition_Id, @OPCEventCategory_Id, @OPCSeverity, @Data_Type_Id, @Signature_Id, @Source_Id, @StartValue, @StartTime, @Start_Time_Ms, @Quality_Id, @EngUnitLabel, @UserId, @SubType, @Modified_On, @Modified_On_Ms)
    Select @AlarmId = Alarm_Id From Alarms Where ((Source_Id = @Source_Id) AND (Start_Time = @StartTime) AND (Start_Time_Ms = @Start_Time_Ms) AND (OPCCondition_Id = @OPCCondition_Id))
    if @AlarmId Is Null
 	   set @AlarmId = -1
 	 return @AlarmId
End Else
Begin
Insert Into Alarms (Alarm_Desc, ATD_Id, Alarm_Type_Id, Key_Id, Start_Time, 
 	  	  	  	  	 End_Time, Ack, Ack_On, Ack_By, Start_Result, End_Result, 
 	  	  	  	  	 Min_Result, Max_Result, User_Id, Cause1, Cause2, 
 	  	  	  	  	 Cause3, Cause4, Action1, Action2, Action3, 
 	  	  	  	  	 Action4, Source_PU_Id, Research_Open_Date, Research_Close_Date,Modified_On,ATSRD_Id,SubType) 
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
 	  	 CURRENT_TIMESTAMP,
 	  	 @ATSRD_Id ,
                @SubType
From Alarm_Template_Var_Data d
Join Alarm_Templates t on t.AT_Id = d.AT_Id
Join Variables v on d.Var_Id = v.Var_Id
Join Prod_Units P on P.PU_Id = v.PU_Id
Where d.ATD_Id = @ATDId and d.Var_Id = @KeyId
Select @AlarmId=Alarm_Id From Alarms 
 	 where Key_Id = @KeyId and ATD_Id = @ATDId and Start_Time = @StartTime 
exec spPDB_AMgrGetAlarmPriority @AlarmId, @Prio output
Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
       ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	    Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
       User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id,SubType, @Prio
From Alarms
 	 where Key_Id = @KeyId and ATD_Id = @ATDId and Start_Time = @StartTime 
End
