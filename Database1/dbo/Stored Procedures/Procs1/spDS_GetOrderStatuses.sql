Create Procedure dbo.spDS_GetOrderStatuses
AS
  Select Distinct Order_Status
    From Customer_Orders
