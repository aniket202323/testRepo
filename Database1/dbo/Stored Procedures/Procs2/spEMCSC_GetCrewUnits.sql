Create Procedure dbo.spEMCSC_GetCrewUnits 
@User_Id int
AS
Select Distinct PU_Id, PL_Desc + ' - ' + PU_Desc as PU_Desc
From Prod_Units U
Join Prod_Lines L on L.PL_Id = U.PL_Id
Where PU_Id > 0
Order By PU_Desc ASC
