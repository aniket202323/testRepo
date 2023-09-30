Create Procedure dbo.spGBO_ListGrades 
  @pu_id int,
  @grp_id int       AS
  if @pu_id <> 0
    begin
      if @grp_id <> 0 
        select a.prod_id, a.prod_code, a.prod_desc from products a
          join product_group_data b 
            on (b.prod_id = a.prod_id) and 
               (b.product_grp_id = @grp_id)
          join pu_products c 
            on (c.prod_id = a.prod_id) and 
               (c.pu_id = @pu_id) or
               (c.pu_id is null)  
          where a.prod_id <> 1
          order by a.prod_code
      else 
        select a.prod_id, a.prod_code, a.prod_desc from products a
          join pu_products c 
            on (c.prod_id = a.prod_id) and 
               (c.pu_id = @pu_id) or
               (c.pu_id is null)  
          where a.prod_id <> 1
          order by a.prod_code
    end
  else
    begin
      if @grp_id <> 0 
        select a.prod_id, a.prod_code, a.prod_desc from products a
          join product_group_data b 
            on (b.prod_id = a.prod_id) and 
               (b.product_grp_id = @grp_id)
          where a.prod_id <> 1
          order by a.prod_code
      else 
        select a.prod_id, a.prod_code, a.prod_desc from products a
          where a.prod_id <> 1
          order by a.prod_code
    end
  return(100)
