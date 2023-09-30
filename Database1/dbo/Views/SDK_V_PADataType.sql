CREATE view SDK_V_PADataType
as
select
Data_Type.Data_Type_Id as Id,
Data_Type.Data_Type_Desc as DataType,
Data_Type.User_Defined as IsUserDefined
FROM data_type
