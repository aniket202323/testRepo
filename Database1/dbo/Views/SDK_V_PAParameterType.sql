CREATE view SDK_V_PAParameterType
as
select
Parameter_Types.Parm_Type_Id as Id,
Parameter_Types.Parm_Type_Desc as ParameterType
from Parameter_Types
