Create Procedure dbo.spEMCO_GetCustOrders
@User_Id int
AS
select a.Order_ID, b.Customer_Name, a.Customer_Order_Number, a.Order_Status, a.Plant_Order_Number, a.Corporate_Order_Number
from Customer_Orders a
Left Join  Customer b ON  a.Customer_ID = b.Customer_ID
order by a.Customer_Order_Number
