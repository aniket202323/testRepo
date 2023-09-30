CREATE PROCEDURE dbo.spServer_AMgrGetAlarmsByTime
@Key_Id int,
@ATD_Id int,
@StartTime datetime,
@EndTime datetime
AS
Declare @AType Int
Declare @ATypes Table (AType int)
Select @AType = Null
Select @AType = at.Alarm_Type_Id
  from Alarm_Template_Var_Data atd
  join Alarm_Templates at on at.AT_Id = atd.AT_Id
  where atd.ATD_ID = @ATD_Id
Insert into @ATypes (AType) Values (@AType)
if (@AType = 4)
  Insert into @ATypes (AType) Values (2) -- SPC Group Alarms ar in the alarm table as SPC Alarms
Select Alarm_Id, Ack, Alarm_Desc, End_Time, Ack_On, Research_Open_Date, Research_Close_Date, Start_Time, Cause1,
 	 ATD_Id, Alarm_Type_Id, Cause4, Key_Id, Ack_By, Action2, Cause2, Cause3, Action_Comment_Id,
 	 Cause_Comment_Id, Action1, Research_Comment_Id, Action3, Action4, Duration, Research_User_Id, Research_Status_Id, Source_PU_Id,
 	 User_Id, Cutoff, Max_Result, Min_Result, Start_Result, End_Result, Modified_On, ATSRD_Id, SubType, NULL, ATVRD_Id, Path_Id
From Alarms
Where key_id = @Key_Id
  and ATD_Id = @ATD_Id
  and Alarm_Type_Id in (select AType from @ATypes)
  and Start_Time <= @EndTime
  and (End_Time >= @StartTime or  End_Time is null)
order by Start_Time
