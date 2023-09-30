Create Procedure dbo.spEMCO_GetAllProducts 
@User_Id int
AS
Select Prod_ID, Prod_Desc
from Products
order by Prod_Desc
