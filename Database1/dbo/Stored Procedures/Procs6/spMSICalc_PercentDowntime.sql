CREATE PROCEDURE dbo.spMSICalc_PercentDowntime
@Output varchar(25) OUTPUT,
@Unit int,
@StartTime datetime, 
@EndTime datetime
AS
Declare
@PercentDowntime real,
@IdealProduction real,  
@IdealYield real,  
@ActualProduction real,
@ActualQualityLoss real,
@ActualYieldLoss real,
@ActualSpeedLoss real,
@ActualDowntimeLoss real,
@ActualDowntimeMinutes real,
@ActualRuntimeMinutes real,
@ActualUnavailableMinutes real,
@ActualSpeed real,
@ActualPercentOEE real,
@ActualTotalItems int,
@ActualGoodItems int,
@ActualBadItems int,
@ActualConformanceItems int,
@TargetProduction real,
@WarningProduction real,  
@RejectProduction real,  
@TargetQualityLoss real,
@WarningQualityLoss real,
@RejectQualityLoss real,
@TargetDowntimeLoss real,
@WarningDowntimeLoss real,
@RejectDowntimeLoss real,
@TargetSpeed real,
@TargetDowntimeMinutes real,
@WarningDowntimeMinutes real,
@RejectDowntimeMinutes real,
@TargetPercentOEE real,
@WarningPercentOEE real,
@RejectPercentOEE real,
@AmountEngineeringUnits varchar(25),
@ItemEngineeringUnits varchar(25),
@TimeEngineeringUnits int,
@Status int,
@ActualDowntimeCount int
Select @Output = 'DoNothing'
Exec spCMN_GetUnitStatistics @Unit, @StartTime, @EndTime, @IdealProduction OUTPUT, @IdealYield OUTPUT, @ActualProduction OUTPUT, 
                             @ActualQualityLoss OUTPUT, @ActualYieldLoss OUTPUT, @ActualSpeedLoss OUTPUT, @ActualDowntimeLoss OUTPUT,
                             @ActualDowntimeMinutes OUTPUT, @ActualRuntimeMinutes OUTPUT, @ActualUnavailableMinutes OUTPUT, 
                             @ActualSpeed OUTPUT, @ActualPercentOEE OUTPUT, @ActualTotalItems OUTPUT, @ActualGoodItems OUTPUT,
                             @ActualBadItems OUTPUT, @ActualConformanceItems OUTPUT, @TargetProduction OUTPUT,
                             @WarningProduction OUTPUT, @RejectProduction OUTPUT, @TargetQualityLoss OUTPUT, @WarningQualityLoss OUTPUT,
                             @RejectQualityLoss OUTPUT, @TargetDowntimeLoss OUTPUT, @WarningDowntimeLoss OUTPUT, @RejectDowntimeLoss OUTPUT,
                             @TargetSpeed OUTPUT, @TargetDowntimeMinutes OUTPUT, @WarningDowntimeMinutes OUTPUT, @RejectDowntimeMinutes OUTPUT,
                             @TargetPercentOEE OUTPUT, @WarningPercentOEE OUTPUT, @RejectPercentOEE OUTPUT, @AmountEngineeringUnits OUTPUT,
                             @ItemEngineeringUnits OUTPUT, @TimeEngineeringUnits OUTPUT, @Status OUTPUT, @ActualDowntimeCount OUTPUT
if (@ActualDowntimeMinutes + @ActualRuntimeMinutes) > 0
  Begin
    Select @PercentDowntime = (@ActualDowntimeMinutes / (@ActualDowntimeMinutes + @ActualRuntimeMinutes)) *  100
  End
if @PercentDowntime is not NULL  Select @Output = Convert(varchar(25), @PercentDowntime)
