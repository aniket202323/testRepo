Create Procedure dbo.spRSQ_GetUnits 
AS
select pu_id, pu_desc 
  from prod_units 
  where pu_id > 0
  order by pu_desc
