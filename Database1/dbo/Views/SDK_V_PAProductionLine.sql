CREATE view SDK_V_PAProductionLine
as
select
Prod_Lines_Base.PL_Id as Id,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Lines_Base.Dept_Id as DepartmentId,
Departments_Base.Dept_Desc as Department,
Prod_Lines_Base.Comment_Id as CommentId,
Prod_Lines_Base.Extended_Info as ExtendedInfo,
Comments.Comment_Text as CommentText,
Prod_Lines_Base.External_Link as ExternalLink,
Prod_Lines_Base.Tag as Tag,
Prod_Lines_Base.User_Defined1 as UserDefined1,
Prod_Lines_Base.User_Defined2 as UserDefined2,
Prod_Lines_Base.User_Defined3 as UserDefined3,
Prod_Lines_Base.Group_Id as SecurityGroupId,
SecurityGroup_Src.Group_Desc as SecurityGroup
FROM Departments_Base
 JOIN Prod_Lines_Base ON Departments_Base.Dept_Id = Prod_Lines_Base.Dept_Id AND Prod_Lines_Base.PL_Id > 0
 Left Join Security_Groups SecurityGroup_Src on SecurityGroup_Src.Group_Id = Prod_Lines_Base.Group_Id 
LEFT JOIN Comments Comments on Comments.Comment_Id=Prod_Lines_Base.Comment_Id
