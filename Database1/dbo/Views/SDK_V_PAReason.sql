CREATE view SDK_V_PAReason
as
select
Event_Reasons.Event_Reason_Id as Id,
Event_Reasons.Event_Reason_Name as Reason,
Event_Reasons.Event_Reason_Code as ReasonCode,
Event_Reasons.Comment_Id as CommentId,
Event_Reasons.External_Link as ExternalInfo,
Comments.Comment_Text as CommentText,
event_reasons.Comment_Required as CommentRequired,
event_reasons.Event_Reason_Order as EventReasonOrder,
event_reasons.Group_Id as GroupId
FROM Event_Reasons
LEFT JOIN Comments Comments on Comments.Comment_Id=event_reasons.Comment_Id
