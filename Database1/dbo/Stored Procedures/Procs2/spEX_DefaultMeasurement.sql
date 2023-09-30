Create Procedure dbo.spEX_DefaultMeasurement 
@pPU_Id int,
@Measurement_Id int OUTPUT,
@Measurement_Name nvarchar(50) OUTPUT
AS
Select @Measurement_Id = null
Select @Measurement_Id = Def_Measurement
  From Prod_Units 
  Where PU_Id = @pPU_Id
If @Measurement_Id Is Null Goto errc
Select @Measurement_Name = WEMT_Name
  From Waste_Event_Meas
  Where WEMT_Id = @Measurement_Id
If @Measurement_Name Is Null Goto errc
Return(100)
errc:
    Select @Measurement_Id = 0
    Select @Measurement_Name = ''
    Return(0)
