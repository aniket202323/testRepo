CREATE PROCEDURE dbo.spServer_CmnDeleteOrder
@Order_Id int
 AS
Delete From Complaint_Details Where Order_Id = @Order_Id
Delete From Complaints Where Order_Id = @Order_Id
Delete From Shipment_Line_Items Where Order_Id = @Order_Id
Update Event_Details Set Order_Id = NULL,Order_Line_Id = NULL Where Order_Id = @Order_Id
Update Event_Details Set Order_Id = NULL,Order_Line_Id = NULL Where Order_Line_Id = @Order_Id
Delete From Customer_Order_Line_Items Where Order_Id = @Order_Id
Delete From Customer_Orders Where Order_Id = @Order_Id
