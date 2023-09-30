Create Procedure dbo.spGBS_LookupProduct
@ProdCode nvarchar(50),
@ProductId int OUTPUT     
AS
Select @ProductId = null
Select @ProductId = Prod_Id 
  from Products
  Where Prod_Code = @ProdCode
return(100)
