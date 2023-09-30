CREATE view SDK_V_PACrew
as
select
Crew_Schedule.CS_Id as Id,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Crew_Schedule.Start_Time as StartTime,
Crew_Schedule.End_Time as EndTime,
Crew_Schedule.Shift_Desc as ShiftDescription,
Crew_Schedule.Crew_Desc as CrewDescription,
Crew_Schedule.Comment_Id as CommentId,
Crew_Schedule.PU_Id as ProductionUnitId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
Comments.Comment_Text as CommentText
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id
 JOIN Crew_Schedule ON Prod_Units_Base.PU_Id = Crew_Schedule.PU_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=crew_schedule.Comment_Id
