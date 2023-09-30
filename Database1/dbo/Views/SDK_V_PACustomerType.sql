CREATE view SDK_V_PACustomerType
as
select
Customer_Types.Customer_Type_Id as Id,
Customer_Types.Customer_Type_Desc as CustomerType
from Customer_Types
