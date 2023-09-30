Create Procedure dbo.spSV_PatternCBOs
AS
Select Id = ProdStatus_Id, Description = ProdStatus_Desc
  From Production_Status
Select Id = Order_Id, Description = Plant_Order_Number
  From Customer_Orders
Select Id = Customer_Id, Description = Customer_Code
  From Customer
Select Id = Prod_Id, Description = Prod_Code
  From Products
