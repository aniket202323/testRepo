CREATE PROCEDURE dbo.spServer_AMgrGetAlarmPrioNames
AS
  Select ap_id, ap_desc from alarm_priorities
