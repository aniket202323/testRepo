CREATE view SDK_V_PAVariableGroup
as
select
PU_Groups.PUG_Id as Id,
PU_Groups.PUG_Desc as VariableGroup,
PU_Groups.PU_Id as ProductionUnitId,
Prod_Units_Base.PU_Desc as ProductionUnit,
Prod_Units_Base.PL_Id as ProductionLineId,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Lines_Base.Dept_Id as DepartmentId,
Departments_Base.Dept_Desc as Department,
PU_Groups.PUG_Order as VarableGroupOrder,
PU_Groups.External_Link as ExternalInfo,
PU_Groups.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
pu_groups.Group_Id as SecurityGroupId,
SecurityGroup_Src.Group_Desc as SecurityGroup
FROM PU_Groups
 join Prod_Units_Base on pu_groups.pu_id = Prod_Units_Base.pu_id
 join Prod_Lines_Base on Prod_Lines_Base.pl_id = Prod_Units_Base.pl_id
 join Departments_Base on Prod_Lines_Base.dept_id = Departments_Base.dept_id
 Left Join Security_Groups SecurityGroup_Src on SecurityGroup_Src.Group_Id = pu_groups.Group_Id 
LEFT JOIN Comments Comments on Comments.Comment_Id=pu_groups.Comment_Id
