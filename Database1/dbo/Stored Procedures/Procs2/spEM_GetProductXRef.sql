CREATE PROCEDURE dbo.spEM_GetProductXRef 
   @ProdFamilyId int
AS
  SELECT x.* 
 	 From Products p
 	 Join  Prod_XRef  x on x.Prod_Id = p.Prod_Id
 	 Where p.Product_Family_Id =  @ProdFamilyId
 	 Order by x.prod_Id
