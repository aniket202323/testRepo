Create Procedure dbo.spEMCO_GetAllCustomerTypes
@User_id int
as
select Customer_Type_Id, Customer_Type_Desc
from Customer_Types
Order By Customer_Type_Desc
