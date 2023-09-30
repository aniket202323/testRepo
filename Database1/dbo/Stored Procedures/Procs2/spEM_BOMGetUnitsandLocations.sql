CREATE PROCEDURE dbo.spEM_BOMGetUnitsandLocations
 	 @Unit int
AS
if @Unit is null 
 	 select PU_Id as [key], PL_Desc as Line, PU_Desc as Unit from Prod_Units pu inner join Prod_Lines pl on pu.PL_Id=pl.PL_Id where pl.PL_Id>0 order by PL_Desc,PU_Desc
else 	 
 	 select Location_Id as [key], Location_Code as Code from Unit_Locations where PU_Id=@Unit order by Location_Code
