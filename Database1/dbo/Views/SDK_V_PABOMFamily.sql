CREATE view SDK_V_PABOMFamily
as
select
Bill_Of_Material_Family.BOM_Family_Id as Id,
Bill_Of_Material_Family.BOM_Family_Desc as BOMFamily,
Bill_Of_Material_Family.Comment_Id as CommentId,
Comments.Comment_Text as CommentText,
Bill_Of_Material_Family.Group_Id as SecurityGroupId,
SecurityGroup_Src.Group_Desc as SecurityGroup
From Bill_Of_Material_Family
 Left Join Security_Groups SecurityGroup_Src on SecurityGroup_Src.Group_Id = Bill_Of_Material_Family.Group_Id 
LEFT JOIN Comments Comments on Comments.Comment_Id=Bill_Of_Material_Family.Comment_Id
