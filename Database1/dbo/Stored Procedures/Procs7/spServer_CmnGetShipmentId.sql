CREATE PROCEDURE dbo.spServer_CmnGetShipmentId 
@Shipment_Number nVarChar(50),
@Shipment_Date datetime,
@ActualQuantity float,
@Order_Id int,
@Order_Line_Id int,
@AddIfMissing int,
@Shipment_Id int OUTPUT,
@Shipment_Item_Id int OUTPUT
 AS
Declare
  @NewActualQuantity float
Select @Shipment_Id = NULL
Select @Shipment_Id = Shipment_Id From Shipment Where Shipment_Number = @Shipment_Number
If (@Shipment_Id Is NULL)
  Begin
    If (@AddIfMissing = 1)
      Begin
 	 Insert Into Shipment(Shipment_Number,Shipment_Date)
          Values(@Shipment_Number,@Shipment_Date)
        Select @Shipment_Id = Scope_identity()
      End
    Else
      Begin
        Select @Shipment_Id = 0
        Return
      End
  End
Else
  Begin
    Update Shipment
      Set Shipment_Date = @Shipment_Date
      Where Shipment_Id = @Shipment_Id
  End
Select @Shipment_Item_Id = NULL
Select @Shipment_Item_Id = Shipment_Item_Id
 From Shipment_Line_Items 
 Where (Shipment_Id = @Shipment_Id) And 
       (Order_Id = @Order_Id) And 
       (Order_Line_Id = @Order_Line_Id)
If (@Shipment_Item_Id Is NULL)
  Begin
    If (@AddIfMissing = 1)
      Begin
 	 Insert Into Shipment_Line_Items (Shipment_Id,Order_Id,Order_Line_Id,Actual_Quantity)
          Values(@Shipment_Id,@Order_Id,@Order_Line_Id,@ActualQuantity)
        Select @Shipment_Item_Id = Scope_identity()
      End
    Else
      Begin
        Select @Shipment_Item_Id = 0
        Return
      End
  End
Else
  Begin
    Select @NewActualQuantity = Sum(Actual_Quantity) 
      From Shipment_Line_Items
      Where (Shipment_Id = @Shipment_Id) And 
            (Order_Id = @Order_Id) And 
            (Order_Line_Id = @Order_Line_Id)
    Update Shipment_Line_Items Set Actual_Quantity = @NewActualQuantity
      Where Shipment_Item_Id = @Shipment_Item_Id
  End
