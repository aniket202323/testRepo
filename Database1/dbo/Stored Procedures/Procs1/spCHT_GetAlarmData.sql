Create Procedure dbo.spCHT_GetAlarmData 
@VarId int,
@TimeStamp datetime,
@AlarmTypeId int
AS
 	 -- Get Alarm Information for all Alarm Types (ignoring @AlarmTypeId input parameter)
 	 Select Alarm_Id, Alarm_Desc
 	     From Alarms 
 	       Where Key_Id = @VarId and
 	              @TimeStamp >= Start_Time and (@TimeStamp < End_Time or End_Time is NULL)
