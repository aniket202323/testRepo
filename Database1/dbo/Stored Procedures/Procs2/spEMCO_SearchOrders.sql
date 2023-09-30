Create Procedure dbo.spEMCO_SearchOrders
@str nVarChar(100),
@User_Id int
AS
select a.Order_ID, b.Customer_Name, a.Customer_Order_Number, a.Order_Status, a.Plant_Order_Number, a.Corporate_Order_Number
from Customer_Orders a, Customer b
where a.Customer_ID = b.Customer_ID
and b.Customer_Name like '%' + @str + '%'
order by b.Customer_Name
