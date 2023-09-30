CREATE view SDK_V_PAProduct
as
select
Products.Prod_Id as Id,
Products.Prod_Code as ProductCode,
Products.Prod_Desc as ProductDescription,
Product_Family.Product_Family_Desc as ProductFamily,
Products.Is_Manufacturing_Product as IsManufacturingProduct,
Products.Is_Sales_Product as IsSalesProduct,
Products.Comment_Id as CommentId,
Products.Product_Family_Id as ProductFamilyId,
Comments.Comment_Text as CommentText,
Products.Event_Esignature_Level as EventESignatureLevelId,
Products.Product_Change_Esignature_Level as ProdChgESignatureLevelId,
EventSigDesc.Field_Desc as EventESignatureLevel,
ProdChgSigDesc.Field_Desc as ProdChgESignatureLevel,
products.Extended_Info as ExtendedInfo,
products.External_Link as ExternalLink
FROM products
 left JOIN product_family ON product_family.product_family_id = products.product_family_id
 left join ED_FieldType_ValidValues as EventSigDesc on EventSigDesc.ED_Field_Type_Id = 55 and EventSigDesc.Field_Id = Products.Event_Esignature_Level
 left join ED_FieldType_ValidValues as ProdChgSigDesc on ProdChgSigDesc.ED_Field_Type_Id = 55 and ProdChgSigDesc.Field_Id = Products.Product_Change_Esignature_Level
LEFT JOIN Comments Comments on Comments.Comment_Id=products.Comment_Id
