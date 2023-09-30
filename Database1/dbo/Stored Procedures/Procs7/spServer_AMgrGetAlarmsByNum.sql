CREATE PROCEDURE dbo.spServer_AMgrGetAlarmsByNum
@Key_Id int,
@ATD_Id int,
@RefTime datetime,
@NumValuesBefore int,
@NumValuesAfter int
AS
Declare @Count 	 Int,
 	 @TS 	 DateTime,
 	 @NextTime Datetime,
 	 @Now 	 DateTime,
 	 @AType Int
set nocount on
Declare @GetAlarmsByNum Table (Alarm_Id int, Ack bit, Alarm_Desc nVarChar(1000) COLLATE DATABASE_DEFAULT, End_Time datetime, Ack_On datetime, Research_Open_Date datetime, Research_Close_Date datetime, Start_Time datetime, 
 	  	  	  	 Cause1 int, ATD_Id int, Alarm_Type_Id int, Cause4 int, Key_Id int, Ack_By int, Action2 int, Cause2 int, 
 	  	  	  	 Cause3 int, Action_Comment_Id int, Cause_Comment_Id int, Action1 int, Research_Comment_Id int, Action3 int, Action4 int, Duration int, 
 	  	  	  	 Research_User_Id int, Research_Status_Id int, Source_PU_Id int, User_Id int, Cutoff tinyint, Max_Result nVarChar(100) COLLATE DATABASE_DEFAULT, Min_Result nVarChar(100) COLLATE DATABASE_DEFAULT, Start_Result nVarChar(100) COLLATE DATABASE_DEFAULT, 
 	  	  	  	 End_Result nVarChar(100) COLLATE DATABASE_DEFAULT, Modified_On datetime, ATSRDId int NULL, SubType int NULL, ATVRDID int NULL, Path_Id int NULL)
Declare @ATypes Table (AType int)
Select @AType = at.Alarm_Type_Id
  from Alarm_Template_Var_Data atd
  join Alarm_Templates at on at.AT_Id = atd.AT_Id
  where atd.ATD_ID = @ATD_Id
Insert into @ATypes (AType) Values (@AType)
if (@AType = 4)
  Insert into @ATypes (AType) Values (2) -- SPC Group Alarms ar in the alarm table as SPC Alarms
if @NumValuesBefore > 0
begin
  Select @NextTime = convert(dateTime,@RefTime)
 	 Insert Into @GetAlarmsByNum(Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
 	  	  	  	  	 ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	  	  	  	  	 Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
 	  	  	  	  	 User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRDId, SubType, ATVRDId, Path_Id)
 	 Select top (@NumValuesBefore + 1) Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
 	  	  	  	  	 ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	  	  	  	  	 Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
 	  	  	  	  	 User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType, ATVRD_Id, Path_Id
 	   From 	 Alarms
 	   Where key_id = @Key_Id and ATD_Id = @ATD_Id and Alarm_Type_Id in (select AType from @ATypes) and Start_Time <= @NextTime
 	   order by Start_Time desc
end
if @NumValuesAfter > 0
begin
  Select @NextTime = convert(dateTime,@RefTime)
  Insert Into @GetAlarmsByNum(Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
 	  	  	  	  	 ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	  	  	  	  	 Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
 	  	  	  	  	 User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRDId, SubType, ATVRDId, Path_Id)
  Select Top (@NumValuesAfter + 1) Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
 	  	  	  	  	 ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	  	  	  	  	 Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
 	  	  	  	  	 User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType, ATVRD_Id, Path_Id
  	  	 From 	 Alarms
  	  	 Where key_id = @Key_Id and ATD_Id = @ATD_Id and Alarm_Type_Id in (select AType from @ATypes) and Start_Time >= @NextTime
 	   order by Start_Time asc
end
Select distinct Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
 	 ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	 Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
 	 User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRDId, SubType, NULL, ATVRDID, Path_Id
from @GetAlarmsByNum order by Start_Time 
set nocount off
