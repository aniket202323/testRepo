CREATE PROCEDURE dbo.spServer_CmnReCalcWTLF_A
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
@OrigWgt float,
@OrigDiameter float,
@OrigLinealFt float,
@ActualDiameter float,
@NewWgt float OUTPUT,
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
  @WeightDiff float,
  @DiameterRatio float
Select @NewWgt = @OrigWgt
Select @NewLinealFt = @OrigLinealFt
Select @MinDensity = @MinDensitySpecFactor * @MinDensityConvFactor
Select @MaxDensity = @MaxDensitySpecFactor * @MaxDensityConvFactor
Select @MinDiameter = @MinDiameterSpecFactor * @MinDiameterConvFactor
Select @MaxDiameter = @MaxDiameterSpecFactor * @MaxDiameterConvFactor
If ((@MaxDiameter - @MinDiameter) = 0)
  Return
Select @DiameterRatio = ((@ActualDiameter - @MinDiameter) / (@MaxDiameter - @MinDiameter))
Select @Density = @MaxDensity + (@MinDensity - @MaxDensity) * (@DiameterRatio / 2.0)
Select @Caliper = @CaliperSpecFactor * @CaliperConvFactor
Select @Trim = @TrimSpecFactor * @TrimConvFactor
Select @WeightDiff = (3.14159 * @Density * @Trim) * ((Power(@OrigDiameter / 2.0,2.0)) - (Power(@ActualDiameter / 2.0,2.0)))
Select @NewWgt = @OrigWgt - @WeightDiff
Select @NewLinealFt = @OrigLinealFt - ((@WeightDiff / (@Density * @Trim * @Caliper)) / 12.0)
