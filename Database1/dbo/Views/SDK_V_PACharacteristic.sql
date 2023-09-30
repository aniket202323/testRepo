CREATE view SDK_V_PACharacteristic
as
select
Characteristics.Char_Id as Id,
Characteristics.Char_Desc as Characteristic,
parent.Char_Desc as ParentCharacteristic,
Product_Properties.Prop_Desc as ProductProperty,
Characteristics.Comment_Id as CommentId,
Characteristics.Derived_From_Parent as ParentCharacteristicId,
Characteristics.Prop_Id as ProductPropertyId,
Characteristics.Extended_Info as ExtendedInfo,
Comments.Comment_Text as CommentText,
characteristics.External_Link as ExternalLink,
characteristics.Group_Id as GroupId
FROM Product_Properties
 JOIN Characteristics  ON Product_Properties.Prop_Id = Characteristics.Prop_Id
 LEFT JOIN Characteristics parent ON parent.Char_Id = Characteristics.Derived_From_Parent
LEFT JOIN Comments Comments on Comments.Comment_Id=characteristics.Comment_Id
