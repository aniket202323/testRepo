CREATE PROCEDURE dbo.spServer_CmnDeleteOrderItem
@Order_Line_Id int
 AS
Delete From Shipment_Line_Items Where Order_Line_Id = @Order_Line_Id
Update Event_Details Set Order_Id = NULL,Order_Line_Id = NULL Where Order_Line_Id = @Order_Line_Id
Delete From Customer_Order_Line_Specs Where Order_Line_Id = @Order_Line_Id
Delete From Customer_Order_Line_Items Where Order_Line_Id = @Order_Line_Id
