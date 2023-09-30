CREATE PROCEDURE dbo.spPurge_GetUnits AS
--get all units
select PU_Id,PL_Desc+'\'+PU_Desc as PU_Desc from Prod_Units pu inner join PRod_Lines pl on pu.PL_Id=pl.PL_Id where pl.PL_Id>0 order by PL_Desc+'\'+PU_Desc
