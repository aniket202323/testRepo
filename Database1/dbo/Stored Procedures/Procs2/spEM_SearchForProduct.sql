CREATE PROCEDURE  dbo.spEM_SearchForProduct
 	 @Family_Id 	 Int,
 	 @ProdDesc   nvarchar(1000)
  AS
  --
If @ProdDesc = ''
  Select @ProdDesc = '%'
else
  Begin
 	 Select @ProdDesc = REPLACE(@ProdDesc,'*','%')
 	 Select @ProdDesc = REPLACE(@ProdDesc,'?','_')
  End
if charindex('%',@ProdDesc) = 0
 	 Select @ProdDesc = '%' + @ProdDesc + '%'
If @Family_Id = -1 
  Select Product_Family_Desc , Prod_Code,Prod_Id,Prod_Desc
 	 From Products p
 	 Join Product_Family pf on pf.Product_Family_Id = p.Product_Family_Id
 	 Where Prod_Code like @ProdDesc and prod_Id > 1
 	 Order by Prod_Code
Else
  Select Product_Family_Desc , Prod_Code,Prod_Id,Prod_Desc
 	 From Products p
 	 Join Product_Family pf on pf.Product_Family_Id = p.Product_Family_Id
 	 Where Prod_Code like @ProdDesc and p.Product_Family_Id =@Family_Id and prod_Id > 1
 	 Order by Prod_Code
