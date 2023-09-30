CREATE Procedure dbo.spCMN_GetLineStatistics
@Line int,
@StartTime datetime, 
@EndTime datetime,
@IdealProduction real OUTPUT,  
@IdealYield real OUTPUT,  
@ActualProduction real OUTPUT,
@ActualQualityLoss real OUTPUT,
@ActualYieldLoss real OUTPUT,
@ActualSpeedLoss real OUTPUT,
@ActualDowntimeLoss real OUTPUT,
@ActualDowntimeMinutes real OUTPUT,
@ActualRuntimeMinutes real OUTPUT,
@ActualUnavailableMinutes real OUTPUT,
@ActualTotalMinutes real OUTPUT,
@ActualSpeed real OUTPUT,
@ActualPercentOEE real OUTPUT,
@ActualTotalItems int OUTPUT,
@ActualGoodItems int OUTPUT,
@ActualBadItems int OUTPUT,
@ActualConformanceItems int OUTPUT,
@TargetProduction real OUTPUT,
@WarningProduction real OUTPUT,  
@RejectProduction real OUTPUT,  
@TargetQualityLoss real OUTPUT,
@WarningQualityLoss real OUTPUT,
@RejectQualityLoss real OUTPUT,
@TargetDowntimeLoss real OUTPUT,
@WarningDowntimeLoss real OUTPUT,
@RejectDowntimeLoss real OUTPUT,
@TargetSpeed real OUTPUT,
@TargetDowntimeMinutes real OUTPUT,
@WarningDowntimeMinutes real OUTPUT,
@RejectDowntimeMinutes real OUTPUT,
@TargetPercentOEE real OUTPUT,
@WarningPercentOEE real OUTPUT,
@RejectPercentOEE real OUTPUT,
@AmountEngineeringUnits varchar(25) OUTPUT,
@ItemEngineeringUnits varchar(25) OUTPUT,
@TimeEngineeringUnits int OUTPUT,
@Status int OUTPUT,
@ScheduleDeviationMinutes real OUTPUT,
@ActualDowntimeCount int OUTPUT
AS
--TODO: Deal With OEE Calculation "Scaling" At Line, Path Level - Use Path Level Theoretical Yeild To Calc Path OEE
set arithignore on
set arithabort off
set ansi_warnings off
/*****************************************************
-- For Testing
--*****************************************************
Declare @Line int,
@StartTime datetime, 
@EndTime datetime,
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
@ActualTotalMinutes real,
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
@ScheduleDeviationMinutes real,
@ActualDowntimeCount int
Select @Line = 2
Select @StartTime = '1/1/2000'
Select @EndTime = '1/1/2003'
--*****************************************************/
Declare @iIdealProduction real,  
@iIdealYield real,  
@iActualProduction real,
@iActualQualityLoss real,
@iActualYieldLoss real,
@iActualSpeedLoss real,
@iActualDowntimeLoss real,
@iActualDowntimeMinutes real,
@iActualRuntimeMinutes real,
@iActualUnavailableMinutes real,
@iActualTotalMinutes real,
@iActualSpeed real,
@iActualPercentOEE real,
@iActualTotalItems int,
@iActualGoodItems int,
@iActualBadItems int,
@iActualConformanceItems int,
@iTargetProduction real,
@iWarningProduction real,  
@iRejectProduction real,  
@iTargetQualityLoss real,
@iWarningQualityLoss real,
@iRejectQualityLoss real,
@iTargetDowntimeLoss real,
@iWarningDowntimeLoss real,
@iRejectDowntimeLoss real,
@iTargetSpeed real,
@iTargetDowntimeMinutes real,
@iWarningDowntimeMinutes real,
@iRejectDowntimeMinutes real,
@iTargetPercentOEE real,
@iWarningPercentOEE real,
@iRejectPercentOEE real,
@iAmountEngineeringUnits varchar(25),
@iItemEngineeringUnits varchar(25),
@iTimeEngineeringUnits int,
@iStatus int,
@iScheduleDeviationMinutes real,
@iActualDowntimeCount int
Declare @tIdealProduction real,  
@tIdealYield real,  
@tActualProduction real,
@tActualQualityLoss real,
@tActualYieldLoss real,
@tActualSpeedLoss real,
@tActualDowntimeLoss real,
@tActualDowntimeMinutes real,
@tActualRuntimeMinutes real,
@tActualUnavailableMinutes real,
@tActualTotalMinutes real,
@tActualSpeed real,
@tActualPercentOEE real,
@tActualTotalItems int,
@tActualGoodItems int,
@tActualBadItems int,
@tActualConformanceItems int,
@tTargetProduction real,
@tWarningProduction real,  
@tRejectProduction real,  
@tTargetQualityLoss real,
@tWarningQualityLoss real,
@tRejectQualityLoss real,
@tTargetDowntimeLoss real,
@tWarningDowntimeLoss real,
@tRejectDowntimeLoss real,
@tTargetSpeed real,
@tTargetDowntimeMinutes real,
@tWarningDowntimeMinutes real,
@tRejectDowntimeMinutes real,
@tTargetPercentOEE real,
@tWarningPercentOEE real,
@tRejectPercentOEE real,
@tStatus int,
@tScheduleDeviationMinutes real,
@tActualDowntimeCount int
Select @tIdealProduction = 0  
Select @tIdealYield = 0
Select @tActualProduction = 0
Select @tActualQualityLoss = 0
Select @tActualYieldLoss  = 0
Select @tActualSpeedLoss = 0
Select @tActualDowntimeLoss = 0
Select @tActualDowntimeMinutes = 0
Select @tActualRuntimeMinutes = 0
Select @tActualUnavailableMinutes = 0
Select @tActualTotalMinutes = 0
Select @tActualSpeed = 0
Select @tActualPercentOEE = 0
Select @tTargetProduction = 0
Select @tWarningProduction = 0
Select @tRejectProduction = 0
Select @tTargetQualityLoss = 0
Select @tWarningQualityLoss = 0
Select @tRejectQualityLoss = 0
Select @tTargetDowntimeLoss = 0
Select @tWarningDowntimeLoss = 0
Select @tRejectDowntimeLoss = 0
Select @tTargetSpeed = 0
Select @tTargetDowntimeMinutes = 0
Select @tWarningDowntimeMinutes = 0
Select @tRejectDowntimeMinutes = 0
Select @tTargetPercentOEE = 0
Select @tWarningPercentOEE = 0
Select @tRejectPercentOEE = 0
Select @tActualTotalItems = 0
Select @tActualGoodItems = 0
Select @tActualBadItems = 0
Select @tActualConformanceItems = 0
Select @tScheduleDeviationMinutes = 0
Select @tActualDowntimeCount = 0
Select @tStatus = 3
--*****************************************************
-- Get Production, Scheduling Units On This Path 
--*****************************************************
Declare @@PathId int
Declare Line_Cursor Insensitive Cursor
  For Select Distinct s.Path_Id
    From PrdExec_Path_Unit_Starts s
    Join PrdExec_Paths p on p.pl_id = @Line and p.is_line_production = 1
    Join PrdExec_Path_Units u on u.pu_id = s.pu_id and u.path_id = s.path_id and (u.is_schedule_point = 1 or u.is_production_point = 1)
    Where s.start_time >= @StartTime and
          s.start_time < @EndTime
  Union   
  Select Distinct s.Path_Id
    From PrdExec_Path_Unit_Starts s
    Join PrdExec_Paths p on p.pl_id = @Line and p.is_line_production = 1
    Join PrdExec_Path_Units u on u.pu_id = s.pu_id and u.path_id = s.path_id and (u.is_schedule_point = 1 or u.is_production_point = 1)
    Where s.start_time < @StartTime and
          ((s.end_time > @StartTime) or (s.end_time is null))
  For Read Only
Open Line_Cursor
Fetch Next From Line_Cursor Into @@PathId
While @@Fetch_Status = 0
  Begin
 	  	 execute spCMN_GetPathStatistics
 	  	  	  	 @@PathId,
 	  	  	  	 @StartTime,
 	  	  	  	 @EndTime,
 	  	  	  	 @iIdealProduction OUTPUT,  
 	  	  	  	 @iIdealYield OUTPUT,  
 	  	  	  	 @iActualProduction OUTPUT,
 	  	  	  	 @iActualQualityLoss OUTPUT,
 	  	  	  	 @iActualYieldLoss OUTPUT,
 	  	  	  	 @iActualSpeedLoss OUTPUT,
 	  	  	  	 @iActualDowntimeLoss OUTPUT,
 	  	  	  	 @iActualDowntimeMinutes OUTPUT,
 	  	  	  	 @iActualRuntimeMinutes OUTPUT,
 	  	  	  	 @iActualUnavailableMinutes OUTPUT,
 	  	  	  	 @iActualTotalMinutes OUTPUT,
 	  	  	  	 @iActualSpeed OUTPUT,
 	  	  	  	 @iActualPercentOEE OUTPUT,
 	  	  	  	 @iActualTotalItems OUTPUT,
 	  	  	  	 @iActualGoodItems OUTPUT,
 	  	  	  	 @iActualBadItems OUTPUT,
 	  	  	  	 @iActualConformanceItems OUTPUT,
 	  	  	  	 @iTargetProduction OUTPUT,
 	  	  	  	 @iWarningProduction OUTPUT,  
 	  	  	  	 @iRejectProduction OUTPUT,  
 	  	  	  	 @iTargetQualityLoss OUTPUT,
 	  	  	  	 @iWarningQualityLoss OUTPUT,
 	  	  	  	 @iRejectQualityLoss OUTPUT,
 	  	  	  	 @iTargetDowntimeLoss OUTPUT,
 	  	  	  	 @iWarningDowntimeLoss OUTPUT,
 	  	  	  	 @iRejectDowntimeLoss OUTPUT,
 	  	  	  	 @iTargetSpeed OUTPUT,
 	  	  	  	 @iTargetDowntimeMinutes OUTPUT,
 	  	  	  	 @iWarningDowntimeMinutes OUTPUT,
 	  	  	  	 @iRejectDowntimeMinutes OUTPUT,
 	  	  	  	 @iTargetPercentOEE OUTPUT,
 	  	  	  	 @iWarningPercentOEE OUTPUT,
 	  	  	  	 @iRejectPercentOEE OUTPUT,
 	  	  	  	 @iAmountEngineeringUnits OUTPUT,
 	  	  	  	 @iItemEngineeringUnits OUTPUT,
 	  	  	  	 @iTimeEngineeringUnits OUTPUT,
 	  	  	  	 @iStatus OUTPUT,
        @iScheduleDeviationMinutes OUTPUT,
        @iActualDowntimeCount OUTPUT
 	  	 Select @tIdealProduction = @tIdealProduction + coalesce(@iIdealProduction,0)  
 	  	 Select @tActualProduction = @tActualProduction + coalesce(@iActualProduction,0)
 	  	 Select @tActualQualityLoss = @tActualQualityLoss + coalesce(@iActualQualityLoss,0)
 	  	 Select @tActualYieldLoss  = @tActualYieldLoss + coalesce(@iActualYieldLoss,0)
 	  	 Select @tActualSpeedLoss = @tActualSpeedLoss  + coalesce(@iActualSpeedLoss,0) 
 	  	 Select @tActualDowntimeLoss = @tActualDowntimeLoss  + coalesce(@iActualDowntimeLoss,0) 
 	  	 Select @tActualDowntimeMinutes = @tActualDowntimeMinutes + coalesce(@iActualDowntimeMinutes,0)
 	  	 Select @tActualRuntimeMinutes = @tActualRuntimeMinutes + coalesce(@iActualRuntimeMinutes,0)
 	  	 Select @tActualUnavailableMinutes = @tActualUnavailableMinutes + coalesce(@iActualUnavailableMinutes,0)
 	  	 Select @tActualTotalMinutes = @tActualTotalMinutes + coalesce(@iActualTotalMinutes,0)
 	  	 Select @tActualPercentOEE = @tActualPercentOEE + coalesce(@iActualPercentOEE * @iIdealProduction,0)
 	  	 Select @tTargetProduction = @tTargetProduction + coalesce(@iTargetProduction,0)
 	  	 Select @tWarningProduction = @tWarningProduction + coalesce(@iWarningProduction,0)
 	  	 Select @tRejectProduction = @tRejectProduction + coalesce(@iRejectProduction,0)
 	  	 Select @tTargetQualityLoss = @tTargetQualityLoss + coalesce(@iTargetQualityLoss,0)
 	  	 Select @tWarningQualityLoss = @tWarningQualityLoss + coalesce(@iWarningQualityLoss,0)
 	  	 Select @tRejectQualityLoss = @tRejectQualityLoss + coalesce(@iRejectQualityLoss,0)
 	  	 Select @tTargetDowntimeLoss = @tTargetDowntimeLoss + coalesce(@iTargetDowntimeLoss,0)
 	  	 Select @tWarningDowntimeLoss = @tWarningDowntimeLoss + coalesce(@iWarningDowntimeLoss,0)
 	  	 Select @tRejectDowntimeLoss = @tRejectDowntimeLoss + coalesce(@iRejectDowntimeLoss,0)
 	  	 Select @tTargetDowntimeMinutes = @tTargetDowntimeMinutes + coalesce(@iTargetDowntimeMinutes,0)
 	  	 Select @tWarningDowntimeMinutes = @tWarningDowntimeMinutes + coalesce(@iWarningDowntimeMinutes,0)
 	  	 Select @tRejectDowntimeMinutes = @tRejectDowntimeMinutes + coalesce(@iRejectDowntimeMinutes,0)
 	  	 Select @tTargetPercentOEE = @tTargetPercentOEE + coalesce(@iTargetPercentOEE * @iIdealProduction,0) 
 	  	 Select @tWarningPercentOEE = @tWarningPercentOEE + coalesce(@iWarningPercentOEE * @iIdealProduction,0)
 	  	 Select @tRejectPercentOEE = @tRejectPercentOEE + coalesce(@iRejectPercentOEE * @iIdealProduction,0)
 	  	 Select @tActualTotalItems = @tActualTotalItems + coalesce(@iActualTotalItems,0)
 	  	 Select @tActualGoodItems = @tActualGoodItems + coalesce(@iActualGoodItems,0)
 	  	 Select @tActualBadItems = @tActualBadItems + coalesce(@iActualBadItems,0)
 	  	 Select @tActualConformanceItems = @tActualConformanceItems + coalesce(@iActualConformanceItems,0)
    Select @tScheduleDeviationMinutes = @tScheduleDeviationMinutes + coalesce(@iScheduleDeviationMinutes,0)
    Select @tActualDowntimeCount = @tActualDowntimeCount + coalesce(@iActualDowntimeCount,0)
 	  	 Select @AmountEngineeringUnits = Case When @iAmountEngineeringUnits Is Not Null Then @iAmountEngineeringUnits Else @AmountEngineeringUnits End
 	  	 Select @ItemEngineeringUnits = Case When @iItemEngineeringUnits Is Not Null Then @iItemEngineeringUnits Else @ItemEngineeringUnits End
 	  	 Select @TimeEngineeringUnits = Case When @iTimeEngineeringUnits Is Not Null Then @iTimeEngineeringUnits Else @TimeEngineeringUnits End
 	   Select @tIdealYield = @tIdealYield + coalesce(@iIdealYield,0)
 	  	       	  	           
    If @tStatus = 3 and @iStatus = 1
      Select @tStatus = 1
    Else If @tStatus = 2 and @iStatus = 1 
      Select @tStatus = 4
    Else If @tStatus = 1 and @iStatus = 0
      Select @tStatus = 4
    Else If @tStatus = 3 and @iStatus = 0 
      Select @tStatus = 2 
 	  	 Fetch Next From Line_Cursor Into @@PathId
  End
Close Line_Cursor
Deallocate Line_Cursor  
--*****************************************************
-- Make Final Calculations
--*****************************************************
Select @IdealProduction = @tIdealProduction
Select @IdealYield = @tIdealYield
Select @ActualProduction = @tActualProduction
Select @ActualQualityLoss = @tActualQualityLoss
Select @ActualYieldLoss = @tActualYieldLoss
Select @ActualSpeedLoss = @tActualSpeedLoss
Select @ActualDowntimeLoss = @tActualDowntimeLoss
Select @ActualDowntimeMinutes = @tActualDowntimeMinutes
Select @ActualRuntimeMinutes = @tActualRuntimeMinutes
Select @ActualUnavailableMinutes = @tActualUnavailableMinutes
Select @ActualTotalMinutes  = @tActualTotalMinutes
Select @ActualSpeed =  case when @tActualRuntimeMinutes > 0 then (@tActualProduction + @tActualQualityLoss) / @tActualRuntimeMinutes else 0.0 end
Select @ActualPercentOEE = @tActualPercentOEE / @tIdealProduction
Select @TargetProduction = @tIdealProduction - @tTargetQualityLoss - @tTargetDowntimeLoss
Select @WarningProduction = @tWarningProduction
Select @RejectProduction = @tRejectProduction 
Select @TargetQualityLoss = @tTargetQualityLoss
Select @WarningQualityLoss = @tWarningQualityLoss
Select @RejectQualityLoss = @tRejectQualityLoss
Select @TargetDowntimeLoss = @tTargetDowntimeLoss
Select @WarningDowntimeLoss = @tWarningDowntimeLoss
Select @RejectDowntimeLoss = @tRejectDowntimeLoss
Select @TargetSpeed = (@tIdealProduction - @tTargetDowntimeLoss) / ((@tActualTotalMinutes) - @tTargetDowntimeMinutes) 
Select @TargetDowntimeMinutes = @tTargetDowntimeMinutes
Select @WarningDowntimeMinutes = @tWarningDowntimeMinutes
Select @RejectDowntimeMinutes = @tRejectDowntimeMinutes
Select @TargetPercentOEE = @tTargetPercentOEE / @tIdealProduction
Select @WarningPercentOEE = @tWarningPercentOEE / @tIdealProduction 
Select @RejectPercentOEE = @tRejectPercentOEE / @tIdealProduction
Select @ActualTotalItems = @tActualTotalItems
Select @ActualGoodItems = @tActualGoodItems
Select @ActualBadItems = @tActualBadItems
Select @ActualConformanceItems = @iActualConformanceItems
Select @Status = @tStatus
Select @ScheduleDeviationMinutes = @tScheduleDeviationMinutes
Select @ActualDowntimeCount = @tActualDowntimeCount
--*****************************************************
/*****************************************************
-- For Testing
--*****************************************************
Select '@IdealProduction=' + convert(varchar(25), @IdealProduction)
Select '@IdealYield=' + convert(varchar(25), @IdealYield)
Select '@ActualProduction=' + convert(varchar(25), @ActualProduction)
Select '@ActualQualityLoss=' + convert(varchar(25), @ActualQualityLoss)
Select '@ActualYieldLoss='  + convert(varchar(25), @ActualYieldLoss)
Select '@ActualSpeedLoss=' + convert(varchar(25), @ActualSpeedLoss)
Select '@ActualDowntimeLoss=' + convert(varchar(25), @ActualDowntimeLoss)
Select '@ActualDowntimeMinutes=' + convert(varchar(25), @ActualDowntimeMinutes)
Select '@ActualRuntimeMinutes=' + convert(varchar(25), @ActualRuntimeMinutes)
Select '@ActualUnavailableMinutes=' + convert(varchar(25), @ActualUnavailableMinutes)
Select '@ActualSpeed=' + convert(varchar(25), @ActualSpeed)
Select '@ActualPercentOEE=' + convert(varchar(25), @ActualPercentOEE)
Select '@TargetProduction=' + convert(varchar(25), @TargetProduction)
Select '@WarningProduction=' + convert(varchar(25), @WarningProduction)
Select '@RejectProduction=' + convert(varchar(25), @RejectProduction)
Select '@TargetQualityLoss=' + convert(varchar(25), @TargetQualityLoss)
Select '@WarningQualityLoss=' + convert(varchar(25), @WarningQualityLoss)
Select '@RejectQualityLoss=' + convert(varchar(25), @RejectQualityLoss)
Select '@TargetDowntimeLoss=' + convert(varchar(25), @TargetDowntimeLoss)
Select '@WarningDowntimeLoss=' + convert(varchar(25), @WarningDowntimeLoss)
Select '@RejectDowntimeLoss=' + convert(varchar(25), @RejectDowntimeLoss)
Select '@TargetSpeed=' + convert(varchar(25), @TargetSpeed)
Select '@TargetDowntimeMinutes=' + convert(varchar(25), @TargetDowntimeMinutes)
Select '@WarningDowntimeMinutes=' + convert(varchar(25), @WarningDowntimeMinutes)
Select '@RejectDowntimeMinutes=' + convert(varchar(25), @RejectDowntimeMinutes)
Select '@TargetPercentOEE=' + convert(varchar(25), @TargetPercentOEE)
Select '@WarningPercentOEE=' + convert(varchar(25), @WarningPercentOEE)
Select '@RejectPercentOEE=' + convert(varchar(25), @RejectPercentOEE)
Select '@Status =' + convert(varchar(25), @tStatus)
Select '@AmountEngineeringUnits =' + @AmountEngineeringUnits
Select '@ItemEngineeringUnits  =' + @ItemEngineeringUnits
Select '@ActualTotalItems = ' + convert(varchar(25),@tActualTotalItems)
Select '@ActualGoodItems = '+ convert(varchar(25),@tActualGoodItems)
Select '@ActualBadItems = '+ convert(varchar(25),@tActualBadItems)
Select '@ActualConformanceItems = '+ convert(varchar(25),@iActualConformanceItems)
Select '@Status = '+ convert(varchar(25),@tStatus)
Select '@ScheduleDeviationMinutes = '+ convert(varchar(25),@tScheduleDeviationMinutes)
Select '@ActualDowntimeCount = '+ convert(varchar(25),@ActualDowntimeCount)
--*****************************************************/
