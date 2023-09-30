Create Procedure dbo.spWA_GetSignatureLevel
@pPU_Id int,
@pSignatureLevel int OUTPUT
AS
Select @pSignatureLevel = max(coalesce(ESignature_Level, 0))
  from Event_Configuration
  Where PU_Id = @pPU_Id and ET_Id = 3
