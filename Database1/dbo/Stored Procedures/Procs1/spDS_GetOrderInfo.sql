Create Procedure dbo.spDS_GetOrderInfo
 @OrderId int,
 @OrderLineId int
AS
   Select Distinct OD.Plant_Order_Number, OD.Forecast_Mfg_Date, OD.Forecast_Ship_Date, OD.Actual_Ship_Date, OD.Actual_Mfg_Date,
         PR3.Prod_Code as Ordered_Product, CU.Customer_Code, CU.Customer_Name, SH.Shipment_Number, 
         CU2.Customer_Name as Consignee_Name, SH.Carrier_Type as Shipment_Type, SH.Shipment_Id, 
         OD.Customer_Order_Number as Customer_Order_Number, OD.Order_Type, OD.Order_Status, 
         OI.Complete_Date, OI.Ordered_Quantity, OI.Line_Item_Number, OI.Dimension_X, 
         OI.Dimension_Y, OI.Dimension_Z, OI.Dimension_A, CU2.Customer_Code as Consignee_Code
            From Customer_Orders OD
                  Join Customer_Order_Line_Items OI on OI.Order_Line_Id = @OrderLineId and OI.Order_Id = @OrderId
                  Left Outer Join Event_Details ED on ED.Order_Id = @OrderId and ED.Order_Line_Id = @OrderLineId
                  Left Outer Join Products PR3 on OI.Prod_Id = PR3.Prod_Id
                  Left Outer Join Customer CU on OD.Customer_Id = CU.Customer_Id
                  Left Outer Join Shipment_Line_Items SI On ED.Shipment_Item_Id = SI.Shipment_Item_Id
                  Left Outer Join Shipment SH on SI.Shipment_Id = SH.Shipment_Id
                  Left Outer Join Customer CU2 on OI.Consignee_ID = CU2.Customer_Id
    Where OD.Order_Id = @OrderId
