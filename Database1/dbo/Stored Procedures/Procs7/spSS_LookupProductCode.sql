Create Procedure dbo.spSS_LookupProductCode
 @ProdId int,
 @ProductCode nVarChar(50) Output,
 @ProductDesc nVarChar(50) Output
AS
 Select @ProductCode = NULL
 Select @ProductDesc = NULL
 Select @ProductCode = Prod_Code, @ProductDesc = Prod_Desc
   From Products
     Where Prod_Id = @ProdId
