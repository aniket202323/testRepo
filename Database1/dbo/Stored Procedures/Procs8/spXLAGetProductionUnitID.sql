Create Procedure dbo.spXLAGetProductionUnitID @pudesc varchar(50) 
 AS 
 select pu_id from prod_units where pu_desc = @pudesc
