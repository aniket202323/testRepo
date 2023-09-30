CREATE view SDK_V_PADepartment
as
select
Departments_Base.Dept_Id as Id,
Departments_Base.Dept_Desc as Department,
Departments_Base.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
Departments_Base.Extended_Info as ExtendedInfo,
Departments_Base.Time_Zone as TimeZone
FROM Departments_Base
LEFT JOIN Comments Comments on Comments.Comment_Id=Departments_Base.Comment_Id
