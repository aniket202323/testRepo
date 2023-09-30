Create Procedure dbo.spAL_GetTimeBasedESignatureLevel
@Sheet_Id int,
@ESignatureLevel int OUTPUT
AS
Select @ESignatureLevel = 0
Select @ESignatureLevel = Coalesce(sdo.Value, 0)
  From Sheet_Display_Options sdo
    Where sdo.Sheet_Id = @Sheet_Id and sdo.Display_Option_Id = 232
return(0)
