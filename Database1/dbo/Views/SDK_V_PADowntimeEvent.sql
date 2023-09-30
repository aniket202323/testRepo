CREATE view SDK_V_PADowntimeEvent
as
select
Timed_Event_Details.TEDet_Id as Id,
Timed_Event_Details.TEDet_Id as DowntimeEventId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Timed_Event_Details.Start_Time as StartTime,
Timed_Event_Details.End_Time as EndTime,
Timed_Event_Fault.TEFault_Name as DowntimeFault,
cause1.Event_Reason_Name as Cause1,
cause2.Event_Reason_Name as Cause2,
cause3.Event_Reason_Name as Cause3,
cause4.Event_Reason_Name as Cause4,
action1.Event_Reason_Name as Action1,
action2.Event_Reason_Name as Action2,
action3.Event_Reason_Name as Action3,
action4.Event_Reason_Name as Action4,
Timed_Event_Details.Research_Open_Date as ResearchOpenDate,
Timed_Event_Details.Research_Close_Date as ResearchCloseDate,
Research_Status.Research_Status_Desc as ResearchStatus,
research.Username as ResearchUserName,
sourcepl.PL_Desc as SourceProductionLine,
sourcepu.PU_Desc as SourceProductionUnit,
Timed_Event_Details.Cause_Comment_Id as CauseCommentId,
Timed_Event_Details.Action_Comment_Id as ActionCommentId,
Timed_Event_Details.Research_Comment_Id as ResearchCommentId,
Timed_Event_Status.TEStatus_Name as DowntimeStatus,
Timed_Event_Details.Signature_Id as ESignatureId,
Timed_Event_Details.Action_Level1 as Action1Id,
Timed_Event_Details.Action_Level2 as Action2Id,
Timed_Event_Details.Action_Level3 as Action3Id,
Timed_Event_Details.Action_Level4 as Action4Id,
Timed_Event_Details.PU_Id as ProductionUnitId,
Timed_Event_Details.Reason_Level1 as Cause1Id,
Timed_Event_Details.Reason_Level2 as Cause2Id,
Timed_Event_Details.Reason_Level3 as Cause3Id,
Timed_Event_Details.Reason_Level4 as Cause4Id,
Timed_Event_Details.Research_Status_Id as ResearchStatusId,
Timed_Event_Details.Research_User_Id as ResearchUserId,
Timed_Event_Details.Event_Reason_Tree_Data_Id as ReasonTreeDataId,
Timed_Event_Details.Source_PU_Id as SourceProductionUnitId,
Timed_Event_Details.TEStatus_Id as DowntimeStatusId,
Timed_Event_Details.Duration as Duration,
Departments_Base.Dept_Desc as Department,
sourcedept.Dept_Desc as SourceDepartment,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
cc.Comment_Text as CauseCommentText,
rc.Comment_Text as ResearchCommentText,
ac.Comment_Text as ActionCommentText,
Prod_Units_Base.PL_Id as SourceProductionLineId,
Prod_Lines_Base.Dept_Id as SourceDepartmentId,
Timed_Event_Details.TEFault_Id as DowntimeFaultId,
Users.User_Id as UserId,
Users.Username as Username
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 JOIN Timed_Event_Details ON Timed_Event_Details.PU_Id = Prod_Units_Base.PU_Id
 LEFT JOIN Prod_Units_Base sourcepu ON Timed_Event_Details.Source_PU_Id = sourcepu.PU_Id
 LEFT JOIN Prod_Lines_Base sourcepl ON sourcepu.PL_Id = sourcepl.PL_Id
 LEFT JOIN Departments_Base sourcedept ON sourcepl.Dept_Id = sourcedept.Dept_Id
 LEFT JOIN Timed_Event_Fault ON Timed_Event_Details.TEFault_Id = Timed_Event_Fault.TEFault_Id
 LEFT JOIN Event_Reasons cause1 ON Timed_Event_Details.Reason_Level1 = cause1.Event_Reason_Id
 LEFT JOIN Event_Reasons cause2 ON Timed_Event_Details.Reason_Level2 = cause2.Event_Reason_Id
 LEFT JOIN Event_Reasons cause3 ON Timed_Event_Details.Reason_Level3 = cause3.Event_Reason_Id
 LEFT JOIN Event_Reasons cause4 ON Timed_Event_Details.Reason_Level4 = cause4.Event_Reason_Id
 LEFT JOIN Event_Reasons action1 ON Timed_Event_Details.Action_Level1 = action1.Event_Reason_Id
 LEFT JOIN Event_Reasons action2 ON Timed_Event_Details.Action_Level2 = action2.Event_Reason_Id
 LEFT JOIN Event_Reasons action3 ON Timed_Event_Details.Action_Level3 = action3.Event_Reason_Id
 LEFT JOIN Event_Reasons action4 ON Timed_Event_Details.Action_Level4 = action4.Event_Reason_Id
 LEFT JOIN Research_Status ON Timed_Event_Details.Research_Status_Id = Research_Status.Research_Status_Id
 LEFT JOIN Users research ON Timed_Event_Details.Research_User_Id = research.User_Id
 LEFT JOIN Timed_Event_Status ON Timed_Event_Details.PU_Id = Timed_Event_Status.PU_Id AND Timed_Event_Details.TEStatus_Id = Timed_Event_Status.TEStatus_Id
 Left JOIN Users on Users.User_Id = Timed_Event_Details.User_Id
LEFT JOIN Comments ac on ac.Comment_Id=timed_event_details.Action_Comment_Id
LEFT JOIN Comments cc on cc.Comment_Id=timed_event_details.Cause_Comment_Id
LEFT JOIN Comments rc on rc.Comment_Id=timed_event_details.Research_Comment_Id
