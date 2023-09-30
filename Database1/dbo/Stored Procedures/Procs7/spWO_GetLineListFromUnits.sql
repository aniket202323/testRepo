CREATE PROCEDURE [dbo].[spWO_GetLineListFromUnits]
 	 @Units VarChar(8000)
AS
Declare @UnitsTable Table (
 	 PU_Id Int )
Insert Into @UnitsTable
 	 Select [Id] From fnCMN_IdListToTable('Prod_Units', @Units, ',')
Select Distinct pl.PL_Id, pl.PL_Desc
From Prod_Lines pl
Join Prod_Units pu On pu.PL_Id = pl.PL_Id
Join @UnitsTable ut On ut.PU_Id = pu.PU_Id
Where pl.PL_Id <> 0
Order By pl.PL_Id
