CREATE view SDK_V_PAShipment
as
select
Shipment.Shipment_Id as Id,
Shipment.Shipment_Number as Shipment,
Shipment.Shipment_Date as ShipmentDate,
Shipment.Vehicle_Name as VehicleName,
Shipment.Is_Active as IsActive,
Shipment.Complete_Date as CompleteDate,
Shipment.COA_Date as COADate,
Shipment.Carrier_Type as CarrierType,
Shipment.Carrier_Code as CarrierCode,
Shipment.Arrival_Date as ArrivalDate,
Comments.Comment_Text as CommentText,
Shipment.Comment_Id as CommentId
from Shipment
LEFT JOIN Comments Comments on Comments.Comment_Id=Shipment.Comment_Id
