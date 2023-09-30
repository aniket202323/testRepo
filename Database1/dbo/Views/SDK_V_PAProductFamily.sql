CREATE view SDK_V_PAProductFamily
as
select
Product_Family.Product_Family_Id as Id,
Product_Family.Product_Family_Desc as ProductFamily,
Product_Family.Comment_Id as CommentId,
Product_Family.External_Link as ExternalInfo,
Comments.Comment_Text as CommentText,
product_family.Group_Id as SecurityGroupId,
SecurityGroup_Src.Group_Desc as SecurityGroup
FROM Product_Family
 Left Join Security_Groups SecurityGroup_Src on SecurityGroup_Src.Group_Id = product_family.Group_Id 
LEFT JOIN Comments Comments on Comments.Comment_Id=product_family.Comment_Id
