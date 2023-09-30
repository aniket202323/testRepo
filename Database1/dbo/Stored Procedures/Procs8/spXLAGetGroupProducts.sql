Create Procedure dbo.spXLAGetGroupProducts
@ID integer, 
@SearchString varchar(50) = NULL
AS
if @SearchString Is NULL
  begin 
    select P.prod_id, P.prod_code 
      from product_group_data PGD
      join Products P on p.Prod_Id = PGD.Prod_Id
      where PGD.product_grp_id = @ID 
      order by P.prod_code
  end
else
  begin
    select P.prod_id, P.prod_code 
      from product_group_data PGD
      join Products P on p.Prod_Id = PGD.Prod_Id and P.Prod_Code Like '%' + ltrim(rtrim(@SearchString))+ '%'
      where PGD.product_grp_id = @ID  
      order by P.prod_code
  end
