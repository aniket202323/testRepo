CREATE view SDK_V_PAParameter
as
select
Parameters.Parm_Id as Id,
Parameters.Parm_Name as Parameter,
Parameters.Parm_Long_Desc as Description,
Parameter_Categories.Parameter_Category_Desc as ParameterCategory,
ED_FieldTypes.Field_Type_Desc as FieldType,
Parameter_Types.Parm_Type_Desc as ParameterType,
Parameters.Parameter_Category_Id as ParameterCategoryId,
Parameters.Field_Type_Id as FieldTypeId,
Parameters.Parm_Type_Id as ParameterTypeId,
parameters.Add_Delete as AddDelete,
parameters.Customize_By_Dept as CustomizeByDept,
parameters.Customize_By_Host as CustomizeByHost,
parameters.IsEncrypted as IsEncrypted,
parameters.Is_Esignature as IsEsignature,
parameters.Parm_Max as ParmMax,
parameters.Parm_Min as ParmMin,
parameters.System as System
FROM Parameters
 LEFT JOIN ED_FieldTypes ON ED_FieldTypes.ED_Field_Type_Id = Parameters.Field_Type_Id
 LEFT JOIN Parameter_Categories ON Parameter_Categories.Parameter_Category_Id = Parameters.Parameter_Category_Id
 LEFT JOIN Parameter_Types ON Parameter_Types.Parm_Type_Id = Parameters.Parm_Type_Id
