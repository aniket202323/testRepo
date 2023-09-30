CREATE view SDK_V_PAAlarmType
as
select
Alarm_Types.Alarm_Type_Id as Id,
Alarm_Types.Alarm_Type_Desc as AlarmType
from Alarm_Types
