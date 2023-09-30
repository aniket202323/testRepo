CREATE view SDK_V_PABOM
as
select
Bill_Of_Material.BOM_Id as Id,
Bill_Of_Material.BOM_Desc as BOM,
Family.BOM_Family_Desc as BOMFamily,
Bill_Of_Material.BOM_Family_Id as BOMFamilyId,
Bill_Of_Material.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
Bill_Of_Material.Is_Active as IsActive,
Bill_Of_Material.Group_Id as SecurityGroupId,
SecurityGroup_Src.Group_Desc as SecurityGroup
From Bill_Of_Material 
 JOIN Bill_Of_Material_Family Family on Family.BOM_Family_Id = Bill_Of_Material.BOM_Family_Id
 Left Join Security_Groups SecurityGroup_Src on SecurityGroup_Src.Group_Id = Bill_Of_Material.Group_Id 
LEFT JOIN Comments Comments on Comments.Comment_Id=Bill_Of_Material.Comment_Id
