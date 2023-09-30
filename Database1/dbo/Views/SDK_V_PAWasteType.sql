CREATE view SDK_V_PAWasteType
as
select
Waste_Event_Type.WET_Id as Id,
Waste_Event_Type.WET_Name as WasteType,
Waste_Event_Type.ReadOnly as ReadOnly
FROM waste_event_type
