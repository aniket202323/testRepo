Create Procedure dbo.spAL_GetEventESignatureLevelByProdId
@Prod_Id int,
@ESignatureLevel int OUTPUT
AS
Select @ESignatureLevel = 0
Select @ESignatureLevel = Coalesce(Event_ESignature_Level, 0)
  From Products
  Where Prod_Id = @Prod_Id
return(0)
