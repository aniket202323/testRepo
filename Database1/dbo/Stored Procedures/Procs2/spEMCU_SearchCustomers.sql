Create Procedure dbo.spEMCU_SearchCustomers
@str nVarChar(100),
@User_Id int
AS
select Customer_Id, Customer_Code, Customer_Name, Contact_Name, Contact_Phone
from Customer
where Customer_Name like '%' + @str + '%'
order by Customer_Name
