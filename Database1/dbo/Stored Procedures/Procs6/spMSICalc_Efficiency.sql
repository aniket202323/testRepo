/*
-- TESTING
set nocount on
Declare @Output Varchar(25), @Unit Int, @StartTime datetime, @EndTime datetime
Select @Unit=2, @StartTime='2007-02-22 7:00:00 AM', @EndTime='2007-02-22 8:00:00 AM'
Exec spMSICalc_Efficiency @Output output, @Unit, @StartTime, @EndTime
Select @output as [OEE]
Exec spCMN_GetOeeStatistics @Unit, @StartTime, @EndTime
*/
CREATE PROCEDURE dbo.spMSICalc_Efficiency
@Output varchar(25) OUTPUT,
@Unit int,
@StartTime datetime, 
@EndTime datetime
AS
Declare
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
/*
-- This is the old way
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
Select @Output= Convert(varchar(25),@ActualPercentOEE)
*/
Create Table #OEE(
 	 Actual_Speed Real,
 	 Ideal_Speed real,
 	 Performance_Rate real,
 	 Ideal_Production real,
 	 Net_Production real,
 	 Waste real,
 	 Quality_Rate real,
 	 Performance_Time real,
 	 Run_Time real,
 	 Loading_Time real,
 	 Available_Rate real,
 	 OEE real
)
Insert Into #OEE
Exec spCMN_GetOeeStatistics @Unit, @StartTime, @EndTime
select @Output = Convert(Varchar(25), OEE) From #OEE
Drop Table #OEE
