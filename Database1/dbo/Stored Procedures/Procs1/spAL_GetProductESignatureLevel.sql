Create Procedure dbo.spAL_GetProductESignatureLevel
@Prod_Id int,
@ESignatureLevel int OUTPUT
AS
Select @ESignatureLevel = 0
Select @ESignatureLevel = Coalesce(Product_Change_ESignature_Level, 0)
  From Products
  Where Prod_Id = @Prod_Id
return(0)
