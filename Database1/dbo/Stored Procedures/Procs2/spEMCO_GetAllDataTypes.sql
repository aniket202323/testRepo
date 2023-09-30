Create Procedure dbo.spEMCO_GetAllDataTypes
@User_Id int
AS
select Data_Type_Id, Data_Type_Desc
from Data_Type
where Data_Type_Id <> 50
order by Data_Type_Desc
