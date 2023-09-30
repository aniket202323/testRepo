Create Procedure dbo.spEMAC_GetDefaultReasons
@AT_Id int,
@User_Id int
as
select cause_tree_id, action_tree_id, default_cause1, default_cause2, default_cause3, default_cause4, default_action1, default_action2, default_action3, default_action4
from alarm_templates
where at_id = @AT_Id
