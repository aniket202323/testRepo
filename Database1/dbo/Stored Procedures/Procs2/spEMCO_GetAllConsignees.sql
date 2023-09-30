Create Procedure dbo.spEMCO_GetAllConsignees
@User_Id int
AS
select Consignee_Name, Customer_Id
from Customer
order by Consignee_Name
