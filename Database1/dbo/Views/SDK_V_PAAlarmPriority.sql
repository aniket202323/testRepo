CREATE view SDK_V_PAAlarmPriority
as
select
Alarm_Priorities.AP_Id as Id,
Alarm_Priorities.AP_Desc as AlarmPriority
from Alarm_Priorities
