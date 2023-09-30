Create Procedure dbo.spDS_CheckOrderLineItems
 @OrderId int,
 @ProdId int,
 @EventId int
AS
 Declare @DimensionX decimal(8,3),
         @DimensionY decimal(8,3),
         @DimensionZ decimal(8,3),
         @DimensionA decimal(8,3)
-------------------------------------------
-- Get Event Final Dimensions
-------------------------------------------
Select @DimensionX = Coalesce(Final_Dimension_X, 0), @DimensionY = Coalesce(Final_Dimension_Y, 0), @DimensionZ = Coalesce(Final_Dimension_Z, 0), @DimensionA = Coalesce(Final_Dimension_A, 0)
  From Event_Details
    Where Event_Id = @EventId
-------------------------------------------
-- Matching order line items
-------------------------------------------
 Select OL.Line_Item_Number, OL.Complete_Date, OL.Ordered_Quantity, OL.Order_Line_Id, OL.Dimension_X, OL.Dimension_Y, OL.Dimension_Z, OL.Dimension_A, C.Customer_Name, CO.Customer_Order_Number, 0 as PP_Setup_Detail_id
   From Customer_Order_Line_Items OL
     Join Customer_Orders CO on CO.Order_Id = OL.Order_Id
     Join Customer C on C.Customer_Id = CO.Customer_Id
     Where OL.Order_Id = @OrderId
            And @DimensionX between Convert(Decimal(8,3), (Coalesce(OL.Dimension_X, 0.0) - Coalesce(OL.Dimension_X_Tolerance, 0.0))) and Convert(Decimal(8,3), (Coalesce(OL.Dimension_X, 0.0) + Coalesce(OL.Dimension_X_Tolerance, 0.099)))
            And @DimensionY between Convert(Decimal(8,3), (Coalesce(OL.Dimension_Y, 0.0) - Coalesce(OL.Dimension_Y_Tolerance, 0.0))) and Convert(Decimal(8,3), (Coalesce(OL.Dimension_Y, 0.0) + Coalesce(OL.Dimension_Y_Tolerance, 0.099)))
            And @DimensionZ between Convert(Decimal(8,3), (Coalesce(OL.Dimension_Z, 0.0) - Coalesce(OL.Dimension_Z_Tolerance, 0.0))) and Convert(Decimal(8,3), (Coalesce(OL.Dimension_Z, 0.0) + Coalesce(OL.Dimension_Z_Tolerance, 0.099)))
            And @DimensionA between Convert(Decimal(8,3), (Coalesce(OL.Dimension_A, 0.0) - Coalesce(OL.Dimension_A_Tolerance, 0.0))) and Convert(Decimal(8,3), (Coalesce(OL.Dimension_A, 0.0) + Coalesce(OL.Dimension_A_Tolerance, 0.099)))
            And OL.Prod_Id = @ProdId
