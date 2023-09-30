Create Procedure dbo.spEMAC_GetAlarmTypes
@User_Id int
AS
DECLARE @AlarmTypes TABLE (Alarm_Type_Id Int,Alarm_Type_Desc nVarChar(100))
INSERT INTO @AlarmTypes (Alarm_Type_Id,Alarm_Type_Desc)
 	 Select Alarm_Type_Id, Alarm_Type_Desc from Alarm_Types
 	 where Alarm_Type_Id < 50 and Alarm_Type_Id Not in (3,6) --Do not allow Production Plan alarms to be configured or historian
INSERT INTO @AlarmTypes (Alarm_Type_Id,Alarm_Type_Desc) VALUES (-1,'Variable Limits String - (Equal Spec)')
INSERT INTO @AlarmTypes (Alarm_Type_Id,Alarm_Type_Desc) VALUES (-2,'Variable Limits String - (Not Equal Spec)')
INSERT INTO @AlarmTypes (Alarm_Type_Id,Alarm_Type_Desc) VALUES (-3,'Variable Limits String - (Use Phrase Order)')
SELECT * From @AlarmTypes
Order By Alarm_Type_Desc
