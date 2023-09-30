CREATE view SDK_V_PADBTable
as
select
Tables.TableId as Id,
Tables.TableName as DBTable,
Tables.Allow_User_Defined_Property as AllowUserDefinedProperty,
Tables.Allow_X_Ref as AllowXRef
from Tables
