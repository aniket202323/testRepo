CREATE Procedure dbo.spEMEPC_GetPathUnits
@Path_Id int,
@User_Id int
AS
Select PU.PU_Desc as 'Unit', PPU.Is_Production_Point as 'Is_Production_Point', PPU.Is_Schedule_Point as 'Is Schedule Point', PPU.Unit_Order as 'Unit Order', PPU.PEPU_Id, PU.PU_Id as 'Unit'
From PrdExec_Path_Units PPU
Join Prod_Units PU on PU.PU_Id = PPU.PU_Id
Where PPU.Path_Id = @Path_Id
Order By PPU.Unit_Order ASC
