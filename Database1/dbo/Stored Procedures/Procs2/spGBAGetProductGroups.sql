Create Procedure dbo.spGBAGetProductGroups 
 AS
  select product_grp_id,product_grp_desc from product_groups 
 	 order by product_grp_desc
