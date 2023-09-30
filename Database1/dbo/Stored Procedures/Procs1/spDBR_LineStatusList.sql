CREATE Procedure dbo.spDBR_LineStatusList
@LineList 	  	  	 text =  NULL,
@StartTime 	  	  	 datetime = NULL,
@EndTime 	  	  	 datetime = NULL,
@ColumnVisibility 	 text = NULL,
@InTimeZone 	  	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
AS
SET ANSI_WARNINGS off
/***************************************************
-- For Testing
--*****************************************************
Declare @LineList varchar(1000)
Declare @StartTime datetime
Declare @EndTime datetime
Declare @ColumnVisibility varchar(1000)
Select @StartTime = '8-sep-2003'
Select @EndTime = '8-oct-2003'
Select @LineList = '<Root></Root>'
Select @ColumnVisibility = '<root></root>'
--*****************************************************/
Declare @LineName varchar(100)
Declare @PathCode varchar(100)
Declare @NextProcessOrder   varchar(100)
Declare @NextProduct  	  	  	   varchar(100)
Declare @NextEstimatedStart datetime
Declare @NextDuration  	  	  	 int
Declare @NextProcessOrderID int
Declare @CurrentStatusIcon int
Declare 	 @CurrentProcessOrderId  	 int
Declare 	 @CurrentProcessOrder  	   varchar(100)
Declare 	 @CurrentProduct  	  	  	   varchar(100)
Declare 	 @ScheduledDeviation  	  	 real
Declare @ImpliedSequence int
Declare @ActualDuration real
Declare @PlannedDuration real
Declare @RemainingDuration real
Declare @PlannedEndTime datetime
Declare @ActualEndTime datetime
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
create table #LineStatusList
(
 	 CurrentStatusIcon tinyint,
 	 ResourceName varchar(100) NULL,
 	 ProductionAmount real NULL,
 	 AmountEngineeringUnits varchar(25) NULL,
 	 ProductionItems int NULL,
 	 ItemEngineeringUnits varchar(25) NULL,
 	 PercentOEE real NULL,
 	 PercentRate real NULL,
 	 RunTime varchar(25) NULL,
 	 ScheduledTime varchar(25) NULL,
 	 PercentDowntime real NULL,
 	 PercentWaste real NULL,
 	 CurrentProcessOrder varchar(100) NULL,
 	 CurrentProduct varchar(100) NULL,
 	 ScheduledDeviation varchar(1000) NULL,
 	 NextProcessOrder varchar(100) NULL,
 	 NextProduct varchar(100) NULL,
 	 NextEstimatedStart varchar(50) NULL,
 	 ResourceID int NULL,
 	 CurrentOrderId int NULL,
 	 NextOrderId int NULL,
  ImpliedSequence int NULL,
  UnitList varchar(255) NULL
)
--*****************************************************/
--Build List Of Lines
--*****************************************************/
Create Table #Lines (
  LineName varchar(100) NULL,
  LineId int NULL
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
if (not @LineList like '%<Root></Root>%' and not @LineList is NULL)
  begin
    if (not @LineList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'LineId;' + Convert(nvarchar(4000), @LineList)
      Insert Into #Lines (LineId) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      Insert Into #Lines EXECUTE spDBR_Prepare_Table @LineList
    end
  end
Else
  Begin
    Insert Into #Lines (LineId) 
       Select pl_id From prod_lines
  End
--*****************************************************
-- Loop Through Lines
--*****************************************************
Declare @@LineId int
Declare @@PathId int
Declare @Unit int
Declare @UnitList varchar(255)
Declare Line_Cursor Insensitive Cursor 
  For Select LineId From #Lines
  For Read Only
Open Line_Cursor
Fetch Next From Line_Cursor Into @@LineId
While @@Fetch_Status = 0
  Begin
    -- Look Up Line Name
    Select @LineName = pl_desc from prod_lines where pl_id = @@LineId
 	  	 Declare Path_Cursor Insensitive Cursor
 	  	   For Select Distinct s.Path_Id
 	  	     From PrdExec_Path_Unit_Starts s
 	  	     Join PrdExec_Paths p on p.pl_id = @@LineId and p.is_line_production = 1 and p.pl_id = (select x.pl_id from prod_units x where x.pu_id = s.pu_id)
 	  	     Join PrdExec_Path_Units u on u.pu_id = s.pu_id and u.path_id = s.path_id and (u.is_schedule_point = 1 or u.is_production_point = 1)
 	  	     Where s.start_time >= @StartTime and
 	  	           s.start_time < @EndTime
 	  	   Union   
 	  	   Select Distinct s.Path_Id
 	  	     From PrdExec_Path_Unit_Starts s
 	  	     Join PrdExec_Paths p on p.pl_id = @@LineId and p.is_line_production = 1 and p.pl_id = (select x.pl_id from prod_units x where x.pu_id = s.pu_id)
 	  	     Join PrdExec_Path_Units u on u.pu_id = s.pu_id and u.path_id = s.path_id and (u.is_schedule_point = 1 or u.is_production_point = 1)
 	  	     Where s.start_time < @StartTime and
 	  	           ((s.end_time > @StartTime) or (s.end_time is null))
 	  	 
 	  	   For Read Only
 	  	 
 	  	 Open Path_Cursor
 	  	 
 	  	 Fetch Next From Path_Cursor Into @@PathId
 	  	 
 	  	 While @@Fetch_Status = 0
 	  	   Begin 	  	     
 	  	     Select @PathCode = path_code From prdexec_paths where path_id = @@PathId    
        Select @UnitList = NULL
 	  	  	  	 Declare Unit_Cursor Insensitive Cursor 
 	  	  	  	   For Select PU_Id From PrdExec_Path_Units where Path_Id = @@PathId and Is_Production_Point = 1
 	  	  	  	   For Read Only
 	  	  	  	 
 	  	  	  	 Open Unit_Cursor
 	  	  	  	 
 	  	  	  	 Fetch Next From Unit_Cursor Into @Unit
 	  	  	  	 
 	  	  	  	 While @@Fetch_Status = 0
 	  	  	  	   Begin
            If @UnitList Is Null
              Select @UnitList = convert(varchar(25),@Unit)
            Else
              Select @UnitList = @UnitList + ',' + convert(varchar(25),@Unit)
      	  	  	  	 Fetch Next From Unit_Cursor Into @Unit
          End
        Close unit_cursor
        Deallocate unit_cursor
 	  	  	  	 -- Get Current Order Properties For This Path
 	  	  	  	 Select @CurrentProcessOrder = pp.Process_Order,              
 	  	            @CurrentProduct = p.Prod_Code,
               @PlannedEndTime = pp.forecast_end_date,
               @PlannedDuration = datediff(second, pp.forecast_start_date, pp.forecast_end_date) / 60.0,
               @ActualDuration = datediff(second, pp.actual_start_time, dbo.fnServer_CmnGetDate(getutcdate())) / 60.0,
               @ActualEndTime = pp.actual_end_time,
               @RemainingDuration = coalesce(pp.Predicted_Remaining_Duration,0),
               @ImpliedSequence = pp.Implied_Sequence,
               @CurrentProcessOrderId = pp.pp_id
 	  	       From Production_Plan pp
 	  	       Join Products p on p.prod_id = pp.prod_id
 	  	       Where pp.path_id = @@PathId and
                pp.pp_status_id = 3
 	  	     -- Look Up Next Order Information For This Path
 	  	  	  	 Select @NextProcessOrderID = NULL
 	  	  	  	 Select @NextProcessOrderID = pp.PP_Id, 
 	  	            @NextProcessOrder = pp.Process_Order,              
 	  	            @NextProduct = p.Prod_Code,
 	  	            @NextEstimatedStart = pp.Forecast_Start_Date,
 	  	  	  	  	      @NextDuration = datediff(minute,pp.Forecast_Start_Date, pp.Forecast_End_Date)
 	  	       From Production_Plan pp
 	  	       Join Products p on p.prod_id = pp.prod_id
 	  	       Where pp.Path_Id = @@PathId and
 	  	             pp.pp_status_id = 2
        Select @ScheduledDeviation = datediff(second,dateadd(second,@RemainingDuration * 60,coalesce(@ActualEndTime,dbo.fnServer_CmnGetDate(getutcdate()))),@PlannedEndTime) / 60.0
        If dateadd(second,convert(int,@RemainingDuration * 60.0), dbo.fnServer_CmnGetDate(getutcdate())) > @NextEstimatedStart 
  	         Select @NextEstimatedStart = dateadd(second,convert(int,@RemainingDuration * 60.0), dbo.fnServer_CmnGetDate(getutcdate()))
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
        Select @CurrentStatusIcon = @iStatus
 	  	  	  	 insert into #LineStatusList (CurrentStatusIcon,ResourceName,ProductionAmount, AmountEngineeringUnits,ProductionItems,ItemEngineeringUnits,PercentOEE,PercentRate,RunTime,ScheduledTime,PercentDowntime,PercentWaste,CurrentProcessOrder,CurrentProduct,ScheduledDeviation,NextProcessOrder,NextProduct,NextEstimatedStart,ResourceID,CurrentOrderId,NextOrderId, ImpliedSequence, UnitList)
 	  	  	  	  	 Select CurrentStatusIcon = @CurrentStatusIcon,
 	  	  	  	  	 ResourceName = @LineName + ' (' + @PathCode + ')',
 	  	  	  	  	 ProductionAmount = @iActualProduction,
 	  	  	  	  	 AmountEngineeringUnits = @iAmountEngineeringUnits,
 	  	  	  	  	 ProductionItems = @iActualGoodItems,
 	  	  	  	  	 ItemEngineeringUnits = @iItemEngineeringUnits,
 	  	  	  	  	 PercentOEE = @iActualPercentOEE,
 	  	  	  	  	 PercentRate = case
 	  	  	  	  	  	 when @iTargetSpeed <= 0 then 0
 	  	  	  	  	  	 else @iActualSpeed / @iTargetSpeed * 100.0
 	  	  	  	  	  	 end,
 	  	  	  	  	 RunTime =  convert(varchar(25),floor(coalesce(@iActualRuntimeMinutes / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, @iActualRuntimeMinutes) % 60 ,0)),2),
 	  	  	  	  	 ScheduledTime = convert(varchar(25),floor(coalesce((@iActualTotalMinutes - @iActualUnavailableMinutes) / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, @iActualTotalMinutes - @iActualUnavailableMinutes) % 60 ,0)),2),
 	  	  	  	  	 PercentDowntime = case
 	  	  	  	  	  	  	 when (@iActualDowntimeMinutes +  @iActualRuntimeMinutes) <= 0 then 0
 	  	  	  	  	  	  	 else @iActualDowntimeMinutes / (@iActualDowntimeMinutes +  @iActualRuntimeMinutes) * 100.0
 	  	  	  	  	  	  	 end,
 	  	  	  	  	 PercentWaste = case
 	  	  	  	  	  	  	 when (@iActualQualityLoss + @iActualProduction) <= 0 then 0
 	  	  	  	  	  	  	 else @iActualQualityLoss / (@iActualQualityLoss + @iActualProduction) * 100.0
 	  	  	  	  	  	  	 end,
 	  	  	  	  	 CurrentProcessOrder = @CurrentProcessOrder,
 	  	  	  	  	 CurrentProduct = @CurrentProduct,
 	  	  	  	  	 ScheduledDeviation = Case
                        	  	  	  	  	  When @ScheduledDeviation < 0 Then '<font color=red><b>' + '-' + convert(varchar(25),floor(-1 * coalesce(@ScheduledDeviation / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, @ScheduledDeviation) % 60 ,0)),2) +  '</b></font>'
                       	  	  	  	  	  Else '+' + convert(varchar(25),floor(coalesce(@ScheduledDeviation / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, @ScheduledDeviation) % 60 ,0)),2)
                     	  	  	  	  	  End,  
 	  	  	  	  	 NextProcessOrder = @NextProcessOrder,
 	  	  	  	  	 NextProduct = @NextProduct,
 	  	  	  	  	 NextEstimatedStart = convert(varchar(20), @NextEstimatedStart, 109),
 	  	  	  	  	 ResourceID = @@LineId,
 	  	  	  	  	 CurrentOrderId = @CurrentProcessOrderId,
 	  	  	  	  	 NextOrderId = @NextProcessOrderId,
 	  	  	  	   ImpliedSequence = @ImpliedSequence,
          UnitList = @UnitList
 	  	 
 	  	  	  	 Fetch Next From Path_Cursor Into @@PathId
 	  	   End
 	  	 
 	  	 Close Path_Cursor
 	  	 Deallocate Path_Cursor  
 	  	 
 	  	 Fetch Next From Line_Cursor Into @@LineId
  End
Close Line_Cursor
Deallocate Line_Cursor  
--*****************************************************/
--Return Header and Translation Information
--*****************************************************/
Execute spDBR_GetColumns @ColumnVisibility
--*****************************************************/
--Return Results
--*****************************************************/
select * 
  from #LineStatusList
  order by ResourceName, ImpliedSequence
drop table #LineStatusList
Drop table #Lines
