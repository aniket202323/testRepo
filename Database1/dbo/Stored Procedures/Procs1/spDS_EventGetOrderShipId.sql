Create Procedure dbo.spDS_EventGetOrderShipId
 @PlantOrderNumber nVarChar(25)= NULL,
 @ShipmentNumber nVarChar(25)= NULL
AS
 Declare @OrderId int,
         @ShipmentId int
/*
eclare @x1 int, @x2 int 
exec spDS_EventGetOrderShipId  @PlantOrderNumber='000005', @ShipmentNumber='123a',
 	  	  	        @orderid = @x1 output, @shipmentid = @x2 output
select @x1, @x2
*/
 Select @OrderId=0
 Select @ShipmentId=0
 If @PlantOrderNumber Is Not Null And @PlantOrderNumber<>""
  Begin
   Select @OrderId = -1
   Select @OrderId = Order_Id
    From Customer_Orders 
     Where Plant_Order_Number = @PlantOrderNumber
  End 
 If @ShipmentNumber Is Not Null And @ShipmentNumber<>""
  Begin
   Select @ShipmentId = -1 
   Select @ShipmentId = Shipment_Id
    From Shipment
     Where Shipment_Number = @ShipmentNumber
  End
 Select @OrderId as OrderId, @ShipmentId as ShipmentId
