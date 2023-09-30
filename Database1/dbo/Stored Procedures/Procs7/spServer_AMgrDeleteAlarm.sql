CREATE PROCEDURE dbo.spServer_AMgrDeleteAlarm
@AlarmId int
AS
Delete from Alarms 
where Alarm_Id = @AlarmId
