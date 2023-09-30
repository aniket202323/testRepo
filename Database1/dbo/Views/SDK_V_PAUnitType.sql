CREATE view SDK_V_PAUnitType
as
select
Unit_Types.Unit_Type_Id as Id,
Unit_Types.UT_Desc as UnitType,
Unit_Types.Uses_Locations as UsesLocations,
Unit_Types.Uses_Production as UsesProduction,
Unit_Types.Icon_Id as IconId,
Icon_Src.Icon_Desc as Icon
From Unit_Types
 Left Join Icons Icon_Src on Icon_Src.Icon_Id = Unit_Types.Icon_Id 
