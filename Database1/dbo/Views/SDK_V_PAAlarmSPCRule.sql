CREATE view SDK_V_PAAlarmSPCRule
as
select
Alarm_SPC_Rules.Alarm_SPC_Rule_Id as Id,
Alarm_SPC_Rules.Alarm_SPC_Rule_Desc as AlarmSPCRule
from Alarm_SPC_Rules
