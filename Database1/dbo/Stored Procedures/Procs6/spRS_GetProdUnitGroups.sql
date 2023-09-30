CREATE PROCEDURE dbo.spRS_GetProdUnitGroups
@PU_Id int
 AS
Select PUG_Id, PUG_Desc
From PU_Groups
Where PU_Id = @PU_Id
Order By PUG_Order
