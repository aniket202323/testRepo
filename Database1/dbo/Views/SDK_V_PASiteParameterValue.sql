CREATE view SDK_V_PASiteParameterValue
as
select
Site_Parameters.Parm_Id as ParameterId,
Parameters.Parm_Name as Parameter,
Site_Parameters.Value as Value,
Parameters.Parm_Min as MinValue,
Parameters.Parm_Max as MaxValue,
Site_Parameters.HostName as HostName,
Parameter_Types.Parm_Type_Desc as ParameterType,
Parameters.Parm_Type_Id as ParameterTypeId,
Parameter_Categories.Parameter_Category_Desc as ParameterCategory,
Parameters.Parameter_Category_Id as ParameterCategoryId,
Parameters.Field_Type_Id as FieldTypeId,
Parameters.Parm_Long_Desc as Description,
site_parameters.Parm_Required as ParmRequired
FROM Site_Parameters  
JOIN Parameters ON Parameters.Parm_Id = Site_Parameters.Parm_Id
LEFT
 JOIN Parameter_Categories on Parameter_Categories.Parameter_Category_Id = Parameters.Parameter_Category_Id
LEFT
 JOIN Parameter_Types on Parameter_Types.Parm_Type_Id = Parameters.Parm_Type_Id
