CREATE PROCEDURE dbo.spServer_CmnReCalcDILF
@MinDensitySpecFactor float,
@MinDensityConvFactor float,
@MaxDensitySpecFactor float,
@MaxDensityConvFactor float,
@MinDiameterSpecFactor float,
@MinDiameterConvFactor float,
@MaxDiameterSpecFactor float,
@MaxDiameterConvFactor float,
@CaliperSpecFactor float,
@CaliperConvFactor float,
@TrimSpecFactor float,
@TrimConvFactor float,
@WeightDiff float,
@OrigDiameter float,
@OrigLinealFt float,
@NewDiameter float OUTPUT,
@NewLinealFt float OUTPUT
 AS
Declare
  @MinDensity float,
  @MaxDensity float,
  @MinDiameter float,
  @MaxDiameter float,
  @Density float,
  @Caliper float,
  @Trim float,
  @DiameterRatio float
Select @NewDiameter = @OrigDiameter
Select @NewLinealFt = @OrigLinealFt
Select @MinDensity = @MinDensitySpecFactor * @MinDensityConvFactor
Select @MaxDensity = @MaxDensitySpecFactor * @MaxDensityConvFactor
Select @MinDiameter = @MinDiameterSpecFactor * @MinDiameterConvFactor
Select @MaxDiameter = @MaxDiameterSpecFactor * @MaxDiameterConvFactor
If ((@MaxDiameter - @MinDiameter) = 0)
  Return
Select @DiameterRatio = (((@OrigDiameter ) - @MinDiameter) / (@MaxDiameter - @MinDiameter))
Select @Density = @MaxDensity + (@MinDensity - @MaxDensity) * (@DiameterRatio / 2.0)
Select @Caliper = @CaliperSpecFactor * @CaliperConvFactor
Select @Trim = @TrimSpecFactor * @TrimConvFactor
Select @NewDiameter = 2.0 * sqrt((power(@OrigDiameter / 2.0,2.0)) - (@WeightDiff / (3.14159 * @Density * @Trim)))
Select @NewLinealFt = @OrigLinealFt - ((@WeightDiff / (@Density * @Trim * @Caliper)) / 12.0)
