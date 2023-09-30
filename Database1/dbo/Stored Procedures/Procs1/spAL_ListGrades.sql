Create Procedure dbo.spAL_ListGrades
  @pu_id int,
  @grp_id int AS
  if @pu_id <> 0
    begin
      if @grp_id <> 0 
        select a.prod_id, a.prod_code, a.prod_desc 
          from product_group_data b WITH (INDEX(Product_Group_Data_By_Group)) 
          join products a on (a.prod_id = b.prod_id) and (a.prod_id <> 1)
          join pu_products c on (c.prod_id = b.prod_id) and (c.pu_id = @pu_id) 
          where (b.product_grp_id = @grp_id)
          order by a.prod_code
      else 
        select a.prod_id, a.prod_code, a.prod_desc 
          from pu_products c WITH (INDEX(PU_Products_By_Pu))
          join products a on c.prod_id = a.prod_id and a.prod_id <> 1 
          where (c.pu_id = @pu_id) 
          order by a.prod_code
    end
  else
    begin
      if @grp_id <> 0 
        select a.prod_id, a.prod_code, a.prod_desc 
          from product_group_data b WITH (INDEX(Product_Group_Data_By_Group)) 
          join products a on (a.prod_id = b.prod_id) and (a.prod_id <> 1)
          where (b.product_grp_id = @grp_id)
          order by a.prod_code
      else 
        select a.prod_id, a.prod_code, a.prod_desc 
          from products a
          where a.prod_id <> 1
          order by a.prod_code
    end
  return(100)
