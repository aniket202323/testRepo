Create Procedure dbo.spEMEC_GetMasterEventTypes
@User_Id int
as
select event_types.et_id, event_types.et_desc
from event_types
where event_types.subtypes_apply = 1
