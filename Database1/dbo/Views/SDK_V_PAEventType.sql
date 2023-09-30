CREATE view SDK_V_PAEventType
as
select
Event_Types.ET_Id as Id,
Event_Types.ET_Desc as EventType,
Event_Types.Subtypes_Apply as HasSubtypes,
Event_Types.Variables_Assoc as IsVariableEventType,
event_types.AllowDataView as AllowDataView,
event_types.Allow_Multiple_Active as AllowMultipleActive,
event_types.Comment_Text as CommentText,
event_types.Event_Models as EventModels,
event_types.IncludeOnSoe as IncludeOnSoe,
event_types.IsTimeBased as IsTimeBased,
event_types.parent_et_id as parentetid,
event_types.Single_Event_Configuration as SingleEventConfiguration,
event_types.User_Configured as UserConfigured,
event_types.ValidateTestData as ValidateTestData
FROM Event_Types
