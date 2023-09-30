CREATE view SDK_V_PAEngineeringUnit
as
select
Engineering_Unit.Eng_Unit_Id as Id,
Engineering_Unit.Eng_Unit_Desc as EngineeringUnit,
Engineering_Unit.Eng_Unit_Code as EngineeringUnitCode,
Engineering_Unit.Is_Active as IsActive
From Engineering_Unit
