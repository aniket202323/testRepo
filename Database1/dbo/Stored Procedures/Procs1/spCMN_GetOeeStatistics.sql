CREATE Procedure dbo.spCMN_GetOeeStatistics
@Unit int,
@StartTime datetime, 
@EndTime datetime,
@FilterNonProductiveTime int = 0
AS
--***********************************************/
-------------------------------------------------------
-- Variables Returned From spCMN_GetUnitStatistics
-------------------------------------------------------
Declare @IdealProduction FLOAT,@IdealYield FLOAT,  
@ActualProduction FLOAT,@ActualQualityLoss FLOAT,@ActualYieldLoss FLOAT,@ActualSpeedLoss FLOAT,@ActualDowntimeLoss FLOAT,@ActualDowntimeMinutes FLOAT,
@ActualRuntimeMinutes FLOAT,@ActualUnavailableMinutes FLOAT,@ActualSpeed FLOAT,@ActualPercentOEE FLOAT,@ActualTotalItems int,@ActualGoodItems int,
@ActualBadItems int,@ActualConformanceItems int,@TargetProduction FLOAT,@WarningProduction FLOAT,@RejectProduction FLOAT, @TargetQualityLoss FLOAT,
@WarningQualityLoss FLOAT,@RejectQualityLoss FLOAT,@TargetDowntimeLoss FLOAT,@WarningDowntimeLoss FLOAT,@RejectDowntimeLoss FLOAT,@TargetSpeed FLOAT,
@TargetDowntimeMinutes FLOAT,@WarningDowntimeMinutes FLOAT,@RejectDowntimeMinutes FLOAT,@TargetPercentOEE FLOAT,@WarningPercentOEE FLOAT,@RejectPercentOEE FLOAT,
@AmountEngineeringUnits varchar(25),@ItemEngineeringUnits varchar(25),@TimeEngineeringUnits int,@Status int,@ActualDowntimeCount int, @TotalPerformanceDTMinutes FLOAT
-------------------------------------------------------
-- Variables for calculating OEE Statistics
-------------------------------------------------------
Declare @PerformanceCategory int
Declare @PerformanceDT FLOAT
Declare @SpeedLossTime FLOAT
Declare @NetOperatingTime FLOAT
Declare @PerformanceRate FLOAT
Declare @Downtime_Scheduled_Category int
Declare @Downtime_External_Category int
Declare @TotalUnavailableTimeMinutes FLOAT
Declare @TotalOutsideAreaMinutes FLOAT
Declare @ActualLoadingTimeMinutes FLOAT
Declare @AvailableRate FLOAT
Declare @QualityRate FLOAT
Declare @OEE FLOAT
Declare @VariableOEE FLOAT
---------------------------------
-- Initialize Variable Values
---------------------------------
Select @PerformanceCategory=0, @PerformanceDT=0, @SpeedLossTime=0, @NetOperatingTime=0,@PerformanceRate=0,
       @Downtime_Scheduled_Category=0, @Downtime_External_Category=0, @TotalUnavailableTimeMinutes=0, 
       @TotalOutsideAreaMinutes=0,@ActualLoadingTimeMinutes=0, @AvailableRate=0, @QualityRate=0, @OEE =0
exec spCmn_GetUnitStatistics @Unit,@StartTime, @EndTime,
@IdealProduction OUTPUT,@IdealYield OUTPUT,@ActualProduction OUTPUT,@ActualQualityLoss OUTPUT,@ActualYieldLoss OUTPUT,@ActualSpeedLoss OUTPUT,
@ActualDowntimeLoss OUTPUT,@ActualDowntimeMinutes OUTPUT,@ActualRuntimeMinutes OUTPUT,@ActualUnavailableMinutes OUTPUT,@ActualSpeed OUTPUT,
@ActualPercentOEE OUTPUT,@ActualTotalItems OUTPUT,@ActualGoodItems OUTPUT,@ActualBadItems OUTPUT,@ActualConformanceItems OUTPUT,@TargetProduction OUTPUT,
@WarningProduction OUTPUT,@RejectProduction OUTPUT,@TargetQualityLoss OUTPUT,@WarningQualityLoss OUTPUT,@RejectQualityLoss OUTPUT,
@TargetDowntimeLoss OUTPUT,@WarningDowntimeLoss OUTPUT,@RejectDowntimeLoss OUTPUT,@TargetSpeed OUTPUT,@TargetDowntimeMinutes OUTPUT,
@WarningDowntimeMinutes OUTPUT,@RejectDowntimeMinutes OUTPUT,@TargetPercentOEE OUTPUT,@WarningPercentOEE OUTPUT,@RejectPercentOEE OUTPUT,
@AmountEngineeringUnits OUTPUT,@ItemEngineeringUnits OUTPUT,@TimeEngineeringUnits OUTPUT,@Status OUTPUT,@ActualDowntimeCount OUTPUT, @FilterNonProductiveTime, @ActualLoadingTimeMinutes OUTPUT, @TotalPerformanceDTMinutes OUTPUT
/* 	  --------------------------------------------------------------------
 	  -- Get Outside Area Time
 	  --------------------------------------------------------------------
     Select 
 	  	 @ActualLoadingTimeMinutes = (LoadingSeconds/60.0),
 	  	 @ActualRunTimeMinutes = (RunningSeconds/60.0) 	 
     From dbo.fnCMN_GetOutsideAreaTimeByUnit(@StartTime, @EndTime, @Unit,@FilterNonProductiveTime)
*/
 	  --------------------------------------------------------------------
 	  -- Calculate OEE values based on performance indicators
 	  -- When Efficiency Variable is being used then
 	  -- spCMN_GetUnitStatistics will detect that and use it
 	  -- otherwise spCMN_GetUnitStatistics will call fnCMN_OEERates
 	  --------------------------------------------------------------------
     Select 
 	  	 @ActualSpeed=Actual_Rate,
 	  	 @TargetSpeed=Ideal_Rate,
 	  	 @PerformanceRate=Performance_Rate,
 	  	 @AvailableRate=Available_Rate,
 	  	 @QualityRate=Quality_Rate,
 	  	 @OEE = @ActualPercentOEE
     From dbo.fnCMN_OEERates(@ActualRunTimeMinutes, @ActualLoadingTimeMinutes, @TotalPerformanceDTMinutes, @ActualProduction, @IdealProduction, @ActualQualityLoss)
 	 
 	 ------------------------------------
 	 -- Time Engineering Units KEY
    --      When 0 Then 'Hour'
    --      When 1 Then 'Minute'
    --      When 2 Then 'Second'
    --      When 3 Then 'Day'
 	 -- NOTE: Everything returned from
 	 -- spCMN_GetUnitStatistics is already
 	 -- in minutes
 	 ------------------------------------
 	 
 	 Select @ActualSpeed = Case
 	  	 When @TimeEngineeringUnits = 0 Then @ActualSpeed * 60.0 
 	  	 When @TimeEngineeringUnits = 2 Then @ActualSpeed / 60.0
 	  	 When @TimeEngineeringUnits = 3 Then @ActualSpeed * 1440
 	  	 Else @ActualSpeed End
 	 Select @TargetSpeed = Case
 	  	 When @TimeEngineeringUnits = 0 Then @TargetSpeed * 60.0 
 	  	 When @TimeEngineeringUnits = 2 Then @TargetSpeed / 60.0
 	  	 When @TimeEngineeringUnits = 3 Then @TargetSpeed * 1440
 	  	 Else @TargetSpeed End
 	 --------------------------------------------------------------------
 	 -- Return all the results 
 	 --------------------------------------------------------------------
    Select @ActualSpeed AS [Actual_Speed],
          @TargetSpeed AS [Ideal_Speed],
          @PerformanceRate AS [Performance_Rate],
 	  	 @IdealProduction as [Ideal_Production], 
          @ActualProduction AS [Net_Production],
          @ActualQualityLoss AS [Waste],
          @QualityRate AS [Quality_Rate],
 	  	 @TotalPerformanceDTMinutes AS [Performance_Time],
          @ActualRuntimeMinutes - @TotalPerformanceDTMinutes AS [Run_Time],
          @ActualLoadingTimeMinutes AS [Loading_Time],
          @AvailableRate AS [Available_Rate],
          @OEE  AS [OEE]
