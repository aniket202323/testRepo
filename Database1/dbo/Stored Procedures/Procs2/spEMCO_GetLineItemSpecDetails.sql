Create Procedure dbo.spEMCO_GetLineItemSpecDetails
@Order_Spec_Id int,
@User_Id int
AS
select a.*, d.Data_Type_Desc
from Customer_Order_Line_Specs a, Data_Type d
where Order_Spec_Id = @Order_Spec_Id
