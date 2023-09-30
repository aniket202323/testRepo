Create Procedure dbo.spGBAGetProductionUnitDesc @puid integer 
 AS
 select pu_desc from prod_units where pu_id = @puid
