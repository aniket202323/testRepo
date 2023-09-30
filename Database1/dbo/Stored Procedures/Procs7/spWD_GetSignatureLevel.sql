Create Procedure dbo.spWD_GetSignatureLevel
@pPU_Id int,
@pSignatureLevel int OUTPUT
AS
Select @pSignatureLevel = coalesce(ESignature_Level, 0)
  from Event_Configuration
  Where PU_Id = @pPU_Id and ET_Id = 2
