Create Procedure dbo.spGBAGetProductionUnitID @pudesc nVarChar(50) 
 AS
 select pu_id from prod_units where pu_desc = @pudesc
