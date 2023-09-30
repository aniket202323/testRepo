CREATE view SDK_V_PAFieldType
as
select
ED_FieldTypes.ED_Field_Type_Id as Id,
ED_FieldTypes.Field_Type_Desc as FieldType,
ED_FieldTypes.Extension as Extension,
ED_FieldTypes.Prefix as Prefix,
ED_FieldTypes.SP_Lookup as SPLookup,
ED_FieldTypes.Store_Id as StoreId,
ED_FieldTypes.User_Defined_Property as UserDefinedProperty
from ED_FieldTypes
