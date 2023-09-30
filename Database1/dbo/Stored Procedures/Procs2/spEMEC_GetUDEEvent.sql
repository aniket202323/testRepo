Create Procedure dbo.spEMEC_GetUDEEvent
@Event_Subtype_Id int,
@User_Id int
AS
select event_subtype_id, event_subtype_desc, icon_id, duration_required, cause_required, action_required,
 	 ack_required, comment_id, cause_tree_id, action_tree_id, default_cause1, default_cause2, 
 	 default_cause3, default_cause4, default_action1, default_action2, default_action3, default_action4,
        ESignature_Level = coalesce(eSignature_level,0),Default_Event_Status = Coalesce(Default_Event_Status,0)
from event_subtypes
where event_subtype_id = @Event_Subtype_Id
