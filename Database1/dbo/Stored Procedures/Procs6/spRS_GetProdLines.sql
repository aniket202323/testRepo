CREATE PROCEDURE dbo.spRS_GetProdLines
AS
Select PL_Id, PL_Desc
From Prod_Lines
Where PL_Id > 0
Order By PL_Desc
