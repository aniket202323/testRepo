Create Procedure dbo.spEMCO_GetOrdLineItemDetails
@Order_Line_Id int,
@User_Id int
AS
Select a.*, p.Prod_Desc, c.Consignee_Name
from Customer_Order_Line_Items a
Left Join Products p On a.Prod_Id = p.Prod_Id
Left Join Customer c ON a.Consignee_Id = c.Customer_Id
where  a.Order_Line_Id = @Order_Line_Id
order by a.Line_Item_Number
