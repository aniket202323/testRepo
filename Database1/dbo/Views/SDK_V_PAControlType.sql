CREATE view SDK_V_PAControlType
as
select
Control_Type.Control_Type_Id as Id,
Control_Type.Control_Type_Desc as ControlType
from Control_Type
