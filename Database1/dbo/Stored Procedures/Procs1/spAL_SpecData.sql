Create Procedure dbo.spAL_SpecData @ProdId int 
 AS 
  select distinct pp.prop_id, pp.prop_desc, c.char_id, c.char_desc
  from pu_Characteristics pc join product_properties pp on pc.prop_id = pp.prop_id
       join characteristics c on pc.char_id = c.char_id
  where pc.prod_id = @ProdId
