CREATE view SDK_V_PADBTableField
as
select
Table_fields.Table_Field_Id as Id,
Table_fields.ED_Field_Type_Id as FieldTypeId,
Table_fields.TableId as DBTableId,
Tables.TableName as DBTable,
Table_fields.Table_Field_Desc as DBTableField
from Table_Fields
join Tables on Tables.TableId = Table_Fields.TableId
