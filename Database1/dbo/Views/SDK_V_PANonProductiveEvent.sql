CREATE view SDK_V_PANonProductiveEvent
as
select
NonProductive_Detail.NPDet_Id as Id,
NonProductive_Detail.NPDet_Id as NonProductiveEventId,
NonProductive_Detail.Start_Time as StartTime,
NonProductive_Detail.End_Time as EndTime,
Prod_Units_Base.PU_Desc as ProductionUnit,
NonProductive_Detail.PU_Id as ProductionUnitId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PL_Id as ProductionLineId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
reason1.Event_Reason_Name as Reason1,
NonProductive_Detail.Reason_Level1 as Reason1Id,
reason2.Event_Reason_Name as Reason2,
NonProductive_Detail.Reason_Level2 as Reason2Id,
reason3.Event_Reason_Name as Reason3,
NonProductive_Detail.Reason_Level3 as Reason3Id,
reason4.Event_Reason_Name as Reason4,
NonProductive_Detail.Reason_Level4 as Reason4Id,
NonProductive_Detail.Entry_On as EntryOn,
NonProductive_Detail.User_Id as UserId,
Users.Username as Username,
NonProductive_Detail.Event_Reason_Tree_Data_Id as ReasonTreeDataId,
NonProductive_Detail.Comment_Id as CommentId,
Comments.Comment_Text as CommentText
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 JOIN NonProductive_Detail ON NonProductive_Detail.PU_Id = Prod_Units_Base.PU_Id
 LEFT JOIN Event_Reasons reason1 ON NonProductive_Detail.Reason_Level1 = reason1.Event_Reason_Id
 LEFT JOIN Event_Reasons reason2 ON NonProductive_Detail.Reason_Level2 = reason2.Event_Reason_Id
 LEFT JOIN Event_Reasons reason3 ON NonProductive_Detail.Reason_Level3 = reason3.Event_Reason_Id
 LEFT JOIN Event_Reasons reason4 ON NonProductive_Detail.Reason_Level4 = reason4.Event_Reason_Id
 Left JOIN Users on Users.User_Id = NonProductive_Detail.User_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=NonProductive_Detail.Comment_Id
