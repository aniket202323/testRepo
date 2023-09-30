CREATE PROCEDURE dbo.spServer_CmnReCalcWTLF_B
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
@ActualDiameter float,
@CoreDiameter float,
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
  @DiameterRatio float
Select @MinDensity = @MinDensitySpecFactor * @MinDensityConvFactor
Select @MaxDensity = @MaxDensitySpecFactor * @MaxDensityConvFactor
Select @MinDiameter = @MinDiameterSpecFactor * @MinDiameterConvFactor
Select @MaxDiameter = @MaxDiameterSpecFactor * @MaxDiameterConvFactor
Select @DiameterRatio = ((@ActualDiameter - @MinDiameter) / (@MaxDiameter - @MinDiameter))
Select @Density = @MaxDensity + (@MinDensity - @MaxDensity) * (@DiameterRatio / 2.0)
Select @Caliper = @CaliperSpecFactor * @CaliperConvFactor
Select @Trim = @TrimSpecFactor * @TrimConvFactor
Select @NewWgt = (3.14159 * @Density * @Trim) * ((Power(@ActualDiameter,2.0)) - (Power(@CoreDiameter,2.0)))
Select @NewLinealFt = (@NewWgt / (@Density * @Trim * @Caliper)) / 12.0
