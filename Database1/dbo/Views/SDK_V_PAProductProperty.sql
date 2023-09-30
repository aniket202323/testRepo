CREATE view SDK_V_PAProductProperty
as
select
Product_Properties.Prop_Id as Id,
Product_Properties.Prop_Desc as ProductProperty,
Product_Properties.Comment_Id as CommentId,
Product_Family.Product_Family_Desc as ProductFamily,
Product_Properties.Product_Family_Id as ProductFamilyId,
Comments.Comment_Text as CommentText,
Product_Properties.Property_Type_Id as PropertyTypeId,
Property_Types.Property_Type_Name as PropertyType,
Product_Properties.Auto_Sync_Chars as AutoSyncCharacteristics,
product_properties.External_Link as ExternalLink,
product_properties.Property_Order as PropertyOrder,
product_properties.Group_Id as SecurityGroupId,
SecurityGroup_Src.Group_Desc as SecurityGroup
FROM Product_Properties
 LEFT OUTER JOIN Property_Types on Property_Types.Property_Type_Id = Product_Properties.Property_Type_Id
 LEFT OUTER JOIN Product_Family ON Product_Properties.Product_Family_Id = product_family.Product_Family_Id
 Left Join Security_Groups SecurityGroup_Src on SecurityGroup_Src.Group_Id = product_properties.Group_Id 
LEFT JOIN Comments Comments on Comments.Comment_Id=product_properties.Comment_Id
