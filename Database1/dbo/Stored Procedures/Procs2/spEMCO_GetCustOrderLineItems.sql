Create Procedure dbo.spEMCO_GetCustOrderLineItems
@ID int,
@User_Id int
AS
Select a.Order_Line_Id, a.Line_Item_Number, p.Prod_Desc, a.Ordered_Quantity, a.Complete_Date
from Customer_Order_Line_Items a
Left Join Products p On a.Prod_Id = p.Prod_Id
where a.Order_Id = @ID
order by a.Line_Item_Number
