CREATE Procedure dbo.spCMN_GetPathStatistics
@Path int,
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
set arithignore on
set arithabort off
set ansi_warnings off
/*****************************************************
-- For Testing
--*****************************************************
Declare @Path int,
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
Select @Path = 1
Select @StartTime = '1/1/2000'
Select @EndTime = '1/1/2003'
--*****************************************************/
Declare @TotalTime int
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
@tActualDowntimeCount int
Declare @OrderId int
Declare @PlannedEndTime datetime
Declare @ActualEndTime datetime
Declare @RemainingDuration real
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
Select @TotalTime = 0
Select @tStatus = 3 -- unavailable
Select @ScheduleDeviationMinutes = 0
Select @tActualDowntimeCount = 0
--*****************************************************
-- Get Production, Scheduling Units On This Path 
--*****************************************************
Create Table #PathTimes (
  StartTime datetime,
  EndTime datetime
)
Declare @@StartTime datetime
Declare @@EndTime datetime
Declare @@UnitId int
Declare @@IsProduction int
Declare @@IsScheduling int
Declare Unit_Cursor Insensitive Cursor 
  For Select pu_id, is_schedule_point, is_production_point 
    From prdexec_path_units 
    Where  Path_Id = @Path and
          (is_schedule_point = 1 or is_production_point = 1)
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId, @@IsScheduling, @@IsProduction
While @@Fetch_Status = 0
  Begin
    -- Get Times Where This Execution Path Ran On This Unit
    Truncate table #PathTimes
 	  	 Insert Into #PathTimes (StartTime, EndTime)
 	  	   Select StartTime = Case When Start_Time < @StartTime Then @StartTime Else Start_Time End,
 	  	          EndTime = Case When End_Time Is Null Then @EndTime When End_Time > @EndTime Then @EndTime Else End_Time End
 	  	     From PrdExec_Path_Unit_Starts
 	  	     Where PU_Id = @@UnitId and
              Path_Id = @Path and 
 	  	           Start_Time >= @StartTime and 
 	  	           Start_Time < @EndTime
 	  	 
 	  	 Insert Into #PathTimes (StartTime, EndTime)
 	  	   Select StartTime = Case When Start_Time < @StartTime Then @StartTime Else Start_Time End,
 	  	          EndTime = Case When End_Time Is Null Then @EndTime When End_Time > @EndTime Then @EndTime Else End_Time End
 	  	     From PrdExec_Path_Unit_Starts
 	  	     Where PU_Id = @@UnitId and
              Path_Id = @Path and 
 	  	           Start_Time = (Select max(Start_Time) From PrdExec_Path_Unit_Starts Where PU_id = @@UnitId and Path_Id = @Path and Start_Time < @StartTime) and 
 	  	           ((End_Time > @StartTime) or (End_Time Is Null))
    -- Gather Statistics For Each Time
 	  	 Declare Path_Time_Cursor Insensitive Cursor 
 	  	   For Select StartTime, EndTime From #PathTimes 
 	  	   For Read Only
 	  	 
 	  	 Open Path_Time_Cursor
 	  	 
 	  	 Fetch Next From Path_Time_Cursor Into @@StartTime, @@EndTime
 	  	 
 	  	 While @@Fetch_Status = 0
 	  	   Begin
 	  	  	  	 execute spCMN_GetUnitStatistics
 	  	  	  	  	  	 @@UnitId,
 	  	  	  	  	  	 @@StartTime,
 	  	  	  	  	  	 @@EndTime,
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
            @iActualDowntimeCount OUTPUT
        If @@IsProduction = 1 
          Begin
            Select @TotalTime = @TotalTime + datediff(second,@@StartTime, @@EndTime)
 	  	  	  	  	  	 Select @tIdealProduction = @tIdealProduction + coalesce(@iIdealProduction,0)  
 	  	  	  	  	  	 Select @tActualProduction = @tActualProduction + coalesce(@iActualProduction,0)
 	  	  	  	  	  	 Select @tActualQualityLoss = @tActualQualityLoss + coalesce(@iActualQualityLoss,0)
 	  	  	  	  	  	 Select @tActualYieldLoss  = @tActualYieldLoss + coalesce(@iActualYieldLoss,0)
 	  	  	  	  	  	 Select @tActualSpeedLoss = @tActualSpeedLoss  + coalesce(@iActualSpeedLoss,0) 
 	  	  	  	  	  	 Select @tActualDowntimeLoss = @tActualDowntimeLoss  + coalesce(@iActualDowntimeLoss,0) 
 	  	  	  	  	  	 Select @tActualDowntimeMinutes = @tActualDowntimeMinutes + coalesce(@iActualDowntimeMinutes,0)
 	  	  	  	  	  	 Select @tActualRuntimeMinutes = @tActualRuntimeMinutes + coalesce(@iActualRuntimeMinutes,0)
 	  	  	  	  	  	 Select @tActualUnavailableMinutes = @tActualUnavailableMinutes + coalesce(@iActualUnavailableMinutes,0)
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
 	  	  	  	  	  	 Select @tActualDowntimeCount = @tActualDowntimeCount + coalesce(@iActualDowntimeCount,0)
 	  	  	  	  	  	 Select @AmountEngineeringUnits = Case When @iAmountEngineeringUnits Is Not Null Then @iAmountEngineeringUnits Else @AmountEngineeringUnits End
 	  	  	  	  	  	 Select @ItemEngineeringUnits = Case When @iItemEngineeringUnits Is Not Null Then @iItemEngineeringUnits Else @ItemEngineeringUnits End
 	  	  	  	  	  	 Select @TimeEngineeringUnits = Case When @iTimeEngineeringUnits Is Not Null Then @iTimeEngineeringUnits Else @TimeEngineeringUnits End
            if @@EndTime = @EndTime
              Begin
                -- Update Path Status
                If @tStatus = 3 and @iStatus = 1
                  Select @tStatus = 1
                Else If @tStatus = 2 and @iStatus = 1 
                  Select @tStatus = 4
                Else If @tStatus = 1 and @iStatus = 0
                  Select @tStatus = 4
                Else If @tStatus = 3 and @iStatus = 0 
                  Select @tStatus = 2 
              End 
          End
        If @@IsScheduling = 1
          Begin
 	  	  	  	  	   Select @tIdealYield = @tIdealYield + coalesce(@iIdealYield,0)
            if @@EndTime = @EndTime
              Begin
                -- Get Schedule Deviation For Active Order At End Time On Scheduling Unit
                Select @OrderId = NULL
                Select @OrderId = pp_id
                  From production_plan_starts
                  Where pu_id = @@UnitId and
                        start_time <= @EndTime and
                        ((end_time > @EndTime) or (end_time is null))
                If @OrderId Is Not Null
                  Begin 
 	  	  	  	  	  	  	  	  	  	 Select @PlannedEndTime = pp.forecast_end_date,
 	  	  	  	  	  	                @ActualEndTime = pp.actual_end_time,
 	  	  	  	  	  	                @RemainingDuration = coalesce(pp.Predicted_Remaining_Duration,0)
 	  	  	  	  	  	  	  	       From Production_Plan pp
 	  	  	  	  	  	  	  	       Where pp.pp_id = @OrderId
                    Select @ScheduleDeviationMinutes = datediff(second,dateadd(second,@RemainingDuration * 60,coalesce(@ActualEndTime,dbo.fnServer_CmnGetDate(getUTCdate()))),@PlannedEndTime) / 60.0                      
                  End
              End 
          End 
 	  	       
 	  	 
 	  	  	  	 Fetch Next From Path_Time_Cursor Into @@StartTime, @@EndTime
 	  	   End
 	  	 
 	  	 Close Path_Time_Cursor
 	  	 Deallocate Path_Time_Cursor
 	  	 Fetch Next From Unit_Cursor Into @@UnitId, @@IsScheduling, @@IsProduction
  End
Close Unit_Cursor
Deallocate Unit_Cursor  
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
Select @ActualTotalMinutes  = @TotalTime / 60.0
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
Select @TargetSpeed = (@tIdealProduction - @tTargetDowntimeLoss) / ((@TotalTime / 60.0) - @tTargetDowntimeMinutes) 
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
Select @ActualDowntimeCount = @tActualDowntimeCount
--*****************************************************
Drop Table #PathTimes
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
Select '@ActualTotalItems =' + convert(varchar(25), @tActualTotalItems)
Select '@ActualGoodItems =' + convert(varchar(25), @tActualGoodItems)
Select '@ActualBadItems =' + convert(varchar(25), @tActualBadItems)
Select '@ActualConformanceItems =' + convert(varchar(25), @iActualConformanceItems)
Select '@Status =' + convert(varchar(25), @tStatus)
Select '@AmountEngineeringUnits =' + @AmountEngineeringUnits
Select '@ItemEngineeringUnits  =' + @ItemEngineeringUnits
Select '@TimeEngineeringUnits  =' + convert(varchar(25), @TimeEngineeringUnits)
Select '@ScheduleDeviationMinutes  =' + convert(varchar(25), @ScheduleDeviationMinutes)
Select '@ActualDowntimeCount  =' + convert(varchar(25), @ActualDowntimeCount)
--*****************************************************/
