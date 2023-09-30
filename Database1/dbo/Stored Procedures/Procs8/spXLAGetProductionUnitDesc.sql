Create Procedure dbo.spXLAGetProductionUnitDesc
@puid integer = Null
AS
  if @puid is null
   select * from prod_units  order by pu_desc
  else
   select * from prod_units  where pu_id = @puid
