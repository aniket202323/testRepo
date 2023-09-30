CREATE PROCEDURE dbo.spServer_CmnGetAlarmId   
@KeyId int,
@SubTypeId int,
@AlarmId int OUTPUT
AS
Select @AlarmId = NULL
Select @AlarmId = Alarm_Id From Alarms Where (Key_Id = @KeyId) And (SubType = @SubTypeId)
If (@AlarmId Is NULL)
  Select @AlarmId = 0
