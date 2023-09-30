CREATE PROCEDURE dbo.spServer_EMgrAutoWaste300
@EC_PU_Id int,
@Input_Rate float,
@Output_Rate float,
@Input_Spec_Desc nVarChar(100),
@Output_Spec_Desc nVarChar(100),
@Input_ConvFactor float,
@Output_ConvFactor float,
@Start_Time datetime,
@End_Time datetime,
@UnAccounted_Waste float OUTPUT,
@Master_Unit int OUTPUT
 AS
Declare
  @InputSpecFactor float,
  @OutputSpecFactor float,
  @AccountedWaste float,
  @SpecSuccess int
Select @UnAccounted_Waste = 0.0
Select @Master_Unit = Master_Unit From Prod_Units_Base Where (PU_Id = @EC_PU_Id)
If (@Master_Unit Is Null)
  Select @Master_Unit = @EC_PU_Id
Execute spServer_CmnGetSpecValueByDesc @Master_Unit,@End_Time,@Input_Spec_Desc,@SpecSuccess OUTPUT,@InputSpecFactor OUTPUT
If (@SpecSuccess <> 1)
  Return
Execute spServer_CmnGetSpecValueByDesc @Master_Unit,@End_Time,@Output_Spec_Desc,@SpecSuccess OUTPUT,@OutputSpecFactor OUTPUT
If (@SpecSuccess <> 1)
  Return
Select @AccountedWaste = Sum(Amount)
  From Waste_Event_Details
  Where (PU_Id = @Master_Unit) And 
        (Source_PU_Id = @EC_PU_Id) And
        (TimeStamp > @Start_Time) And
        (TimeStamp <= @End_Time)
If @AccountedWaste Is Null
  Select @AccountedWaste = 0.0
Select @UnAccounted_Waste = (@Input_Rate * @InputSpecFactor * @Input_ConvFactor) - 
                            (@Output_Rate * @OutputSpecFactor * @Output_ConvFactor) - 
                            @AccountedWaste
If @UnAccounted_Waste Is Null
  Select @UnAccounted_Waste = 0.0
