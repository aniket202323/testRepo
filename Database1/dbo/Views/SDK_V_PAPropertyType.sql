CREATE view SDK_V_PAPropertyType
as
select
Property_Types.Property_Type_Id as Id,
Property_Types.Property_Type_Name as PropertyType,
Property_Types.Property_Type_Data as PropertyData
FROM Property_Types
