Create Procedure dbo.spEMCO_GetOrderDetails
@Order_Id int,
@User_Id int
AS
select * from Customer_Orders
where Order_Id = @Order_Id
