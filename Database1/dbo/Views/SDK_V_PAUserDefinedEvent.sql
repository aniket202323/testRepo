CREATE view SDK_V_PAUserDefinedEvent
as
select
User_Defined_Events.UDE_Id as Id,
User_Defined_Events.UDE_Id as UserDefinedEventId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
User_Defined_Events.UDE_Desc as UserDefinedEventName,
Event_Subtypes.Event_Subtype_Desc as EventSubType,
User_Defined_Events.Start_Time as StartTime,
User_Defined_Events.End_Time as EndTime,
cause1.Event_Reason_Name as Cause1,
cause2.Event_Reason_Name as Cause2,
cause3.Event_Reason_Name as Cause3,
cause4.Event_Reason_Name as Cause4,
action1.Event_Reason_Name as Action1,
action2.Event_Reason_Name as Action2,
action3.Event_Reason_Name as Action3,
action4.Event_Reason_Name as Action4,
User_Defined_Events.Research_Open_Date as ResearchOpenDate,
User_Defined_Events.Research_Close_Date as ResearchCloseDate,
Research_Status.Research_Status_Desc as ResearchStatus,
research.Username as ResearchUserName,
User_Defined_Events.Ack as Ack,
AckUser.Username as AckBy,
User_Defined_Events.Ack_On as AckOn,
User_Defined_Events.Comment_Id as CommentId,
User_Defined_Events.Cause_Comment_Id as CauseCommentId,
User_Defined_Events.Action_Comment_Id as ActionCommentId,
User_Defined_Events.Research_Comment_Id as ResearchCommentId,
User_Defined_Events.Signature_Id as ESignatureId,
User_Defined_Events.Action1 as Action1Id,
User_Defined_Events.Action2 as Action2Id,
User_Defined_Events.Action3 as Action3Id,
User_Defined_Events.Action4 as Action4Id,
User_Defined_Events.Cause1 as Cause1Id,
User_Defined_Events.Cause2 as Cause2Id,
User_Defined_Events.Cause3 as Cause3Id,
User_Defined_Events.Cause4 as Cause4Id,
User_Defined_Events.Event_Subtype_Id as EventSubTypeId,
User_Defined_Events.PU_Id as ProductionUnitId,
User_Defined_Events.Research_User_Id as ResearchUserId,
User_Defined_Events.Ack_By as AckById,
User_Defined_Events.Research_Status_Id as ResearchStatusId,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
Comments.Comment_Text as CommentText,
ac.Comment_Text as ActionCommentText,
rc.Comment_Text as ResearchCommentText,
cc.Comment_Text as CauseCommentText,
User_Defined_Events.Duration as Duration,
User_Defined_Events.Event_Reason_Tree_Data_Id as ReasonTreeDataId,
Users.User_Id as UserId,
Users.Username as Username,
User_Defined_Events.Event_Id as ProductionEventId,
User_Defined_Events.Parent_UDE_Id as ParentUserDefinedEventId,
Parent.UDE_Desc as ParentUserDefinedEventName,
Events.Event_Num as ProductionEventName,
Test_Status.Testing_Status_Desc as TestingStatus,
User_Defined_Events.Testing_Status as TestingStatusId,
User_Defined_Events.Conformance as Conformance,
User_Defined_Events.Testing_Prct_Complete as TestPercentComplete,
User_Defined_Events.Event_Status as EventStatusId,
Production_Status.ProdStatus_Desc as EventStatus
FROM User_Defined_Events
 INNER JOIN Prod_Units_Base ON Prod_Units_Base.PU_Id = User_Defined_Events.PU_Id
 INNER JOIN Prod_Lines_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 INNER JOIN Departments_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 LEFT JOIN Production_Status ON Production_Status.ProdStatus_Id = User_Defined_Events.Event_Status
 LEFT JOIN Test_Status ON test_status.Testing_Status = User_Defined_Events.Testing_Status
 JOIN Event_SubTypes ON User_Defined_Events.Event_SubType_Id = Event_Subtypes.Event_SubType_Id AND Event_Subtypes.event_subtype_id = User_Defined_Events.Event_Subtype_Id
 LEFT JOIN Events On Events.Event_Id = User_Defined_Events.Event_Id
 LEFT JOIN Event_Reasons cause1 ON cause1.Event_Reason_Id = User_Defined_Events.Cause1
 LEFT JOIN Event_Reasons cause2 ON cause2.Event_Reason_Id = User_Defined_Events.Cause2
 LEFT JOIN Event_Reasons cause3 ON cause3.Event_Reason_Id = User_Defined_Events.Cause3
 LEFT JOIN Event_Reasons cause4 ON cause4.Event_Reason_Id = User_Defined_Events.Cause4
 LEFT JOIN Event_Reasons action1 ON action1.Event_Reason_Id = User_Defined_Events.Action1
 LEFT JOIN Event_Reasons action2 ON action2.Event_Reason_Id = User_Defined_Events.Action2
 LEFT JOIN Event_Reasons action3 ON action3.Event_Reason_Id = User_Defined_Events.Action3
 LEFT JOIN Event_Reasons action4 ON action4.Event_Reason_Id = User_Defined_Events.Action4
 LEFT JOIN Research_Status ON Research_Status.Research_Status_Id = User_Defined_Events.Research_Status_Id
 left join User_defined_Events Parent on Parent.UDE_Id = User_Defined_Events.Parent_UDE_Id
 Left Join Users on Users.User_Id = User_Defined_Events.User_Id
 LEFT JOIN Users AckUser ON AckUser.User_Id = User_Defined_Events.Ack_By
 LEFT JOIN Users research ON research.User_Id = User_Defined_Events.Research_User_Id
LEFT JOIN Comments ac on ac.Comment_Id=user_defined_events.Action_Comment_Id
LEFT JOIN Comments cc on cc.Comment_Id=user_defined_events.Cause_Comment_Id
LEFT JOIN Comments rc on rc.Comment_Id=user_defined_events.Research_Comment_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=user_defined_events.Comment_Id
