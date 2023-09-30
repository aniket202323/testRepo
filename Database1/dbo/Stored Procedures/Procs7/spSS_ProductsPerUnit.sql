Create Procedure dbo.spSS_ProductsPerUnit
 @PUId int
AS
 If (@PUId = 0)
  Select p.Prod_Id, p.Prod_Code
   From Products p
    Where p.Prod_Id > 1 --Don't want '<None>' product
    Order By p.Prod_Code
 Else
  Select Distinct (pp.Prod_Id), p.Prod_Code
   From Pu_Products pp
   Join Products p on p.Prod_Id = pp.Prod_Id
    Where pp.PU_Id = @PUId
     Order By p.Prod_Code
