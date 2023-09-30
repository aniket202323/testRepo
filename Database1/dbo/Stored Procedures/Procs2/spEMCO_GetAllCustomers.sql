Create Procedure dbo.spEMCO_GetAllCustomers
@User_id int
as
select Customer_Id, Customer_Name
from Customer
order by Customer_Name
