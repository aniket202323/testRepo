Create Procedure dbo.spDS_UpdateEventData
 @OrderID int,
 @ShipmentID int,
 @PlantOrderNumber nVarChar(25)= NULL,
 @ShipmentNumber nVarChar(25)= NULL,
 @Success int Output
AS
 Select @Success =1
 If Not (@PlantOrderNumber Is NULL)
  Update Customer_Orders
   Set Plant_Order_Number = @PlantOrderNumber
    Where Order_Id = @OrderId
 If Not (@ShipmentNumber IS NULL) 
   Update Shipment
    Set Shipment_Number = @ShipmentNumber
     Where Shipment_Id = @ShipmentId
