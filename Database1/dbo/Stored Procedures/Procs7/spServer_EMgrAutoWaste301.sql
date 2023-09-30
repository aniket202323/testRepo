CREATE PROCEDURE dbo.spServer_EMgrAutoWaste301
@EC_PU_Id int,
@Input_Rate float,
@Input_Spec_Desc nVarChar(100),
@Input_ConvFactor float,
@Start_Time datetime,
@End_Time datetime,
@Master_Unit int OUTPUT,
@New_Input_Rate float OUTPUT
 AS
Declare
  @InputSpecFactor float,
  @SpecSuccess int
Select @New_Input_Rate = @Input_Rate
Select @Master_Unit = Master_Unit From Prod_Units_Base Where (PU_Id = @EC_PU_Id)
If (@Master_Unit Is Null)
  Select @Master_Unit = @EC_PU_Id
Execute spServer_CmnGetSpecValueByDesc @Master_Unit,@End_Time,@Input_Spec_Desc,@SpecSuccess OUTPUT,@InputSpecFactor OUTPUT
If (@SpecSuccess <> 1)
  Return
Select @New_Input_Rate = @Input_Rate * @InputSpecFactor * @Input_ConvFactor
