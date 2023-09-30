Create Procedure dbo.spEMCU_GetAllCustomers
@User_id int
as
select Customer_Id, Customer_Code, Customer_Name, Contact_Name, Contact_Phone
from Customer
order by Customer_Name
