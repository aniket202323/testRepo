CREATE view SDK_V_PADBTableFieldValue
as
select
Table_fields_values.KeyId as KeyId,
Table_fields_values.Table_Field_Id as DBTableFieldId,
Table_fields_values.TableId as DBTableId,
Tables.TableName as DBTable,
Table_fields_values.Value as Value,
Table_Fields.Table_Field_Desc as DBTableField,
Table_Fields.ED_Field_Type_Id as FieldTypeId
from Table_Fields_Values
join Tables on Tables.TableId = Table_Fields_Values.TableId 
join Table_Fields on Table_Fields.Table_Field_Id = Table_Fields_Values.Table_Field_Id
