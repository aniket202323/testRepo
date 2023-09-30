Create Procedure dbo.spAL_GetAlarmData
@VarId int,
@TimeStamp datetime
AS
  -- Get Alarm Information
  Select Alarm_Id, Alarm_Desc
      From Alarms 
        Where Key_Id = @VarId and
              (@TimeStamp >= Start_Time and (@TimeStamp < End_Time or End_Time is NULL)) and Alarm_Type_Id in (1,2,4)
