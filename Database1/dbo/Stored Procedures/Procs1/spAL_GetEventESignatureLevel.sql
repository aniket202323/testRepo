Create Procedure dbo.spAL_GetEventESignatureLevel
@PU_Id int,
@ResultOn datetime,
@ESignatureLevel int OUTPUT
AS
Select @ESignatureLevel = 0
Select @ESignatureLevel = Coalesce(p.Event_ESignature_Level, 0)
  From Production_Starts ps
  Join Products p on p.Prod_Id = ps.Prod_Id
  Where (ps.PU_Id = @PU_Id) AND
          (ps.Start_Time <= @ResultOn) AND
          ((ps.End_Time > @ResultOn) OR (ps.End_Time is NULL))
return(0)
