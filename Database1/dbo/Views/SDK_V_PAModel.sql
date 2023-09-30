CREATE view SDK_V_PAModel
as
select
ED_Models.ED_Model_Id as Id,
ED_Models.Model_Desc as Model,
ED_Models.Allow_Derived as AllowDerived,
ED_Models.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
ED_Models.Derived_From as DerivedFrom,
Event_Types.ET_Desc as EventType,
ED_Models.ET_Id as EventTypeId,
ED_Models.Installed_On as InstalledOn,
ED_Models.Interval_Based as IntervalBased,
ED_Models.Is_Active as IsActive,
ED_Models.Locked as Locked,
ED_Models.Model_Num as ModelNumber,
ED_Models.Model_Version as ModelVersion,
ED_Models.Num_Of_Fields as NumFields,
ED_Models.Override_Module_Id as OverrideModuleId,
ED_Models.Server_Version as ServerVersion,
ED_Models.User_Defined as UserDefined
from ED_Models
 join event_types on event_types.et_id = ed_models.et_id
LEFT JOIN Comments Comments on Comments.Comment_Id=ED_Models.Comment_Id
