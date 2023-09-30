Create Procedure dbo.spXLASearchProduct
@SearchString varchar(50),
@ProductGroup int
AS
If @SearchString Is Null
  Begin
    If @ProductGroup Is Null
      Begin
        Select Prod_Id, Prod_Code, Prod_Desc
          From Products
          Where Prod_Id <> 1
          Order By Prod_Code 
      End
    Else
      Begin
        Select p.Prod_Id, p.Prod_Code, p.Prod_Desc
          From Product_Group_Data pg
          Join Products p on p.Prod_Id = pg.Prod_id
          Where pg.Prod_Id <> 1 and
                pg.Product_Grp_Id = @ProductGroup
          Order By p.Prod_Code 
      End
  End
Else
  Begin
    If @ProductGroup Is Null
      Begin
        Select Prod_Id, Prod_Code, Prod_Desc
          From Products
          Where Prod_Id <> 1 and
                Prod_Code Like '%' + ltrim(rtrim(@SearchString)) + '%'
          Order By Prod_Code 
      End
    Else
      Begin
        Select p.Prod_Id, p.Prod_Code, p.Prod_Desc
          From Product_Group_Data pg
          Join Products p on p.Prod_Id = pg.Prod_Id and p.Prod_Code Like '%' + ltrim(rtrim(@SearchString)) + '%'
          Where pg.Prod_Id <> 1 and
                pg.Product_Grp_Id = @ProductGroup
          Order By p.Prod_Code 
      End
  End
