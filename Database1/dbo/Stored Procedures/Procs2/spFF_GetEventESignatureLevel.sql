Create Procedure dbo.spFF_GetEventESignatureLevel 
@PU_Id int,
@Result_On datetime,
@SignatureLevel int OUTPUT
AS
Select @SignatureLevel = Coalesce(p.Event_ESignature_Level, 0)
  From Products p
    Join Production_Starts ps on ps.PU_Id = @PU_Id and ps.Prod_Id = p.Prod_Id
     Where ps.Start_Time <= @Result_On and (ps.End_Time > @Result_On or ps.End_Time is NULL)
