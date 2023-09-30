Create Procedure dbo.spGBAGetGroupProducts @ID integer 
 AS
  select P.prod_id, P.prod_code from products P, product_group_data PGD 
 	 where PGD.product_grp_id = @ID and PGD.prod_id = P.prod_id order by P.prod_code
