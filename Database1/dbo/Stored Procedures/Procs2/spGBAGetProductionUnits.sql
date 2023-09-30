Create Procedure dbo.spGBAGetProductionUnits @Method integer 
 AS
 If @Method = 1 
   select * from prod_units 
     where pu_id > 0 
     order by pu_desc
 else if @Method = 2
   select * from prod_units 
     where master_unit is NULL and
           pu_id > 0
     order by pu_desc
