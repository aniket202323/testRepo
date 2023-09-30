CREATE view SDK_V_PAProductChangeEvent
as
select
Production_Starts.Start_Id as Id,
Production_Starts.Start_Id as ProductChangeEventId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Production_Starts.Start_Time as StartTime,
Production_Starts.End_Time as EndTime,
Products.Prod_Code as ProductCode,
Production_Starts.Confirmed as Confirmed,
Production_Starts.Comment_Id as CommentId,
Production_Starts.Signature_Id as ESignatureId,
Production_Starts.Event_Subtype_Id as EventSubTypeId,
Production_Starts.Prod_Id as ProductId,
Production_Starts.PU_Id as ProductionUnitId,
Production_Starts.Second_User_Id as SecondUserId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
Comments.Comment_Text as CommentText,
Users.User_Id as UserId,
Users.Username as Username
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id AND Prod_Lines_Base.PL_Id > 0
 JOIN Prod_Units_Base ON Prod_Lines_Base.PL_Id = Prod_Units_Base.PL_Id AND Prod_Units_Base.PU_Id > 0
 JOIN Production_Starts ON production_starts.PU_Id = Prod_Units_Base.PU_Id
 JOIN Products ON production_starts.Prod_Id = products.Prod_Id
 Left JOIN Users on Users.User_Id = Production_Starts.User_Id
LEFT JOIN Comments Comments on Comments.Comment_Id=production_starts.Comment_Id
