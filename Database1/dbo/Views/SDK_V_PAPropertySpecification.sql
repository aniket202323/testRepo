CREATE view SDK_V_PAPropertySpecification
as
select
Specifications.Spec_Id as Id,
Product_Properties.Prop_Desc as ProductProperty,
Specifications.Spec_Desc as PropertySpecification,
Data_Type.Data_Type_Desc as DataType,
Specifications.Spec_Precision as SpecPrecision,
Specifications.Eng_Units as EngineeringUnits,
Specifications.Tag as Tag,
Specifications.Extended_Info as ExtendedInfo,
Specifications.Comment_Id as CommentId,
Specifications.Data_Type_Id as DataTypeId,
Specifications.Prop_Id as ProductPropertyId,
Comments.Comment_Text as CommentText,
Specifications.Spec_Order as SpecificationOrder,
specifications.Group_Id as SecurityGroupId,
SecurityGroup_Src.Group_Desc as SecurityGroup,
specifications.Array_Size as ArraySize,
specifications.External_Link as ExternalLink,
specifications.Parent_Id as ParentId
FROM Product_Properties 
 JOIN Specifications  ON Product_Properties.Prop_Id = Specifications.Prop_Id  
 JOIN Data_Type ON Specifications.Data_Type_Id = Data_Type.Data_Type_Id  
 Left Join Security_Groups SecurityGroup_Src on SecurityGroup_Src.Group_Id = specifications.Group_Id 
LEFT JOIN Comments Comments on Comments.Comment_Id=specifications.Comment_Id
