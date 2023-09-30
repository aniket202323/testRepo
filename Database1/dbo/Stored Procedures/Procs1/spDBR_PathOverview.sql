CREATE Procedure dbo.spDBR_PathOverview 
@Path 	  	  	 int = 1, 
@StartTime 	  	 datetime = null,  
@EndTime 	  	 datetime = null,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS  
SET ANSI_WARNINGS off
/*****************************************************
-- For Testing
--*****************************************************
Declare @Path int,
@StartTime datetime, 
@EndTime datetime 
Select @Path = 1
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
SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
--*****************************************************
-- Get Path Statistics
--*****************************************************
execute spCMN_GetPathStatistics
 	  	 @Path,
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
--*****************************************************
-- Return Results
--*****************************************************
Create Table #Results (   
  ParameterName varchar(30),   
  DecimalParameterValue decimal(20,2) NULL,
  ParameterValue varchar(100) NULL 
)  
Create Table #Prompts (
  [time]              varchar(50),
  [to]                varchar(50),
  PctQuality          varchar(50), 
  ProductionOverview  varchar(50),
  Actual              varchar(50),
  Target              varchar(50)
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 
insert into #Prompts ([time],[to], PctQuality, ProductionOverview,Actual,Target) values (dbo.fnDBTranslate(N'0', 38382, 'Time:'),dbo.fnDBTranslate(N'0', 38383, 'To'),dbo.fnDBTranslate(N'0', 38384, '% Quality'),
  dbo.fnDBTranslate(N'0', 38385, 'Production Overview'), dbo.fnDBTranslate(N'0', 38386, 'Actual'), dbo.fnDBTranslate(N'0', 38387, 'Target'))
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'ProductionAmountActual',
         ParameterValue = coalesce(@iActualProduction, convert(varchar(25),convert(decimal(20,2),@iActualProduction)), 0),
         DecimalParameterValue = coalesce(@iActualProduction, convert(decimal(20,2),@iActualProduction), 0)
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'ProductionAmountTarget',
         ParameterValue = coalesce(@iTargetProduction, convert(varchar(25),convert(decimal(20,2),@iTargetProduction)), 0),
         DecimalParameterValue = coalesce(@iTargetProduction, convert(decimal(20,2),@iTargetProduction), 0)
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'ProductionAmountColor',
         ParameterValue = Case
                            When @iActualProduction < @iRejectProduction Then '3'
                            When @iActualProduction < @iWarningProduction Then '2'
                            Else '1'
                          End
 	 
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'ProductionAmountUnits',
         ParameterValue = coalesce(@iAmountEngineeringUnits,@iAmountEngineeringUnits,'')
--*****************************************************
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'WasteAmountActual',
         ParameterValue = Case
 	  	  	  	 When @iActualQualityLoss + @iActualProduction = 0 then '0.0'
 	  	  	  	 Else convert(varchar(25),convert(decimal(20,1),@iActualQualityLoss / (@iActualQualityLoss + @iActualProduction)*100.0))
 	  	  	  	 End,
 	 DecimalParameterValue = Case
 	  	  	  	 When @iActualQualityLoss + @iActualProduction = 0 then 0.0
 	  	  	  	 Else convert(decimal(20,1),@iActualQualityLoss / (@iActualQualityLoss + @iActualProduction)*100.0)
 	  	  	  	 End
 	  	 
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'WasteAmountTarget',
         ParameterValue = Case
 	  	  	  	 When @iActualQualityLoss + @iActualProduction = 0 then '0.0'
 	  	  	  	 Else convert(varchar(25),convert(decimal(20,1),@iTargetQualityLoss / (@iActualQualityLoss + @iActualProduction)*100.0))
 	  	  	  	 End,
         DecimalParameterValue = Case
 	  	  	  	 When @iActualQualityLoss + @iActualProduction = 0 then 0.0
 	  	  	  	 Else convert(decimal(20,1),@iTargetQualityLoss / (@iActualQualityLoss + @iActualProduction)*100.0)
 	  	  	  	 End
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'WasteAmountColor',
         ParameterValue = Case
                            When @iActualQualityLoss > @iRejectQualityLoss Then '3'
                            When @iActualQualityLoss > @iWarningQualityLoss Then '2'
                            Else '1'
                          End
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'WasteAmountUnits',
         ParameterValue = '%'
--*****************************************************
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'DowntimeAmountActual',
         ParameterValue = Case
 	  	  	  	 When @iActualTotalMinutes - @iActualUnavailableMinutes = 0 then '0.0'
 	  	  	  	 Else convert(varchar(25),convert(decimal(20,1),@iActualDowntimeMinutes / (@iActualTotalMinutes - @iActualUnavailableMinutes) * 100.0))
 	  	  	  	 End,
         DecimalParameterValue = Case
 	  	  	  	 When @iActualTotalMinutes - @iActualUnavailableMinutes = 0 then 0.0
 	  	  	  	 Else convert(decimal(20,1),@iActualDowntimeMinutes / (@iActualTotalMinutes - @iActualUnavailableMinutes) * 100.0)
 	  	  	  	 End
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'DowntimeAmountTarget',
         ParameterValue = Case
 	  	  	  	 When @iActualTotalMinutes - @iActualUnavailableMinutes = 0 then  '0.0'
 	  	  	  	 Else convert(varchar(25),convert(decimal(20,1),@iTargetDowntimeMinutes / (@iActualTotalMinutes - @iActualUnavailableMinutes) * 100.0))
 	  	  	  	 End,
         DecimalParameterValue = Case
 	  	  	  	 When @iActualTotalMinutes - @iActualUnavailableMinutes = 0 then  0.0
 	  	  	  	 Else convert(decimal(20,1),@iTargetDowntimeMinutes / (@iActualTotalMinutes - @iActualUnavailableMinutes) * 100.0)
 	  	  	  	 End
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'DowntimeAmountColor',
         ParameterValue = Case
                            When @iActualDowntimeMinutes > @iRejectDowntimeMinutes Then '3'
                            When @iActualDowntimeMinutes > @iWarningDowntimeMinutes Then '2'
                            Else '1'
                          End
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'DowntimeAmountUnits',
         ParameterValue = '%'
--*****************************************************
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'EfficiencyAmountActual',
         ParameterValue = coalesce(@iActualPercentOEE, convert(varchar(25),convert(decimal(20,1),@iActualPercentOEE)), 0),
         DecimalParameterValue = coalesce(@iActualPercentOEE, convert(decimal(20,1),@iActualPercentOEE), 0)
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'EfficiencyAmountTarget',
         ParameterValue = coalesce(@iTargetPercentOEE, convert(varchar(25),convert(decimal(20,1),@iTargetPercentOEE)), 0),
         DecimalParameterValue = coalesce(@iTargetPercentOEE, convert(decimal(20,1),@iTargetPercentOEE), 0)
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'EfficiencyAmountColor',
         ParameterValue = Case
                            When @iActualPercentOEE < @iRejectPercentOEE Then '3'
                            When @iActualPercentOEE < @iWarningPercentOEE Then '2'
                            Else '1'
                          End
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'EfficiencyAmountUnits',
         ParameterValue = '%'
--*****************************************************
--*****************************************************
Declare @CurrentProcessOrder varchar(100)
Declare @CurrentProduct varchar(100)
Declare @PlannedEndTime datetime
Declare @ActualDuration real
Declare @ActualEndTime datetime
Declare @RemainingDuration real
Declare @NextProcessOrder varchar(100)
Declare @NextProduct varchar(100)
Declare @NextEstimatedStart datetime
Declare @ScheduledDeviation real
-- Get Current Order Properties For This Path
Select @CurrentProcessOrder = NULL
Select @CurrentProcessOrder = pp.Process_Order,              
       @CurrentProduct = p.Prod_Code,
       @PlannedEndTime = pp.forecast_end_date,
       @ActualDuration = datediff(second, pp.actual_start_time, dbo.fnServer_CmnGetDate(getutcdate())) / 60.0,
       @ActualEndTime = pp.actual_end_time,
       @RemainingDuration = coalesce(pp.Predicted_Remaining_Duration,0)
  From Production_Plan pp
  Join Products p on p.prod_id = pp.prod_id
  Where pp.path_id = @Path and
        pp.pp_status_id = 3
-- Look Up Next Order Information For This Path
Select @NextProcessOrder = NULL
Select @NextProcessOrder = pp.Process_Order,              
       @NextProduct = p.Prod_Code,
       @NextEstimatedStart = pp.Forecast_Start_Date
  From Production_Plan pp
  Join Products p on p.prod_id = pp.prod_id
  Where pp.Path_Id = @Path and
        pp.pp_status_id = 2
Select @ScheduledDeviation = datediff(second,dateadd(second,@RemainingDuration * 60,coalesce(@ActualEndTime,dbo.fnServer_CmnGetDate(getutcdate()))),@PlannedEndTime) / 60.0
If dateadd(second,convert(int,@RemainingDuration * 60.0), dbo.fnServer_CmnGetDate(getutcdate())) > @NextEstimatedStart 
    Select @NextEstimatedStart = dateadd(second,convert(int,@RemainingDuration * 60.0), dbo.fnServer_CmnGetDate(getutcdate()))
--*****************************************************
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'CurrentProcessOrder',
         ParameterValue = coalesce(@CurrentProcessOrder,@CurrentProcessOrder,'')
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'CurrentProductCode',
         ParameterValue = coalesce(@CurrentProduct,@CurrentProduct, '')
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'NextProcessOrder',
         ParameterValue = coalesce(@NextProcessOrder,@NextProcessOrder, '')
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'NextProductCode',
         ParameterValue = coalesce(@NextProduct,@NextProduct,'')
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'ScheduleChangeTime',
         ParameterValue = convert(varchar(20),@NextEstimatedStart,109)
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'ScheduleDeviationMessage',
         ParameterValue =  Case
                        	  	    When @ScheduledDeviation < 0 Then '<font color=red><b>' + convert(varchar(25),floor(-1 * coalesce(@ScheduledDeviation / 60.0 ,0))) + ' ' + dbo.fnDBTranslate(N'0', 38388, 'Hours') + ' ' + convert(varchar(25),coalesce(convert(int, -1 * @ScheduledDeviation) % 60 ,0)) + ' ' + dbo.fnDBTranslate(N'0', 38389, 'Minutes Behind')  +  '</b></font>'
                       	  	  	  Else convert(varchar(25),floor(coalesce(@ScheduledDeviation / 60.0 ,0))) + ' ' + dbo.fnDBTranslate(N'0', 38388, 'Hours') + ' ' + convert(varchar(25),coalesce(convert(int, @ScheduledDeviation) % 60 ,0)) + ' ' + dbo.fnDBTranslate(N'0', 38390, 'Minutes Ahead')
                     	  	  	  End
--*****************************************************
--*****************************************************
Declare @TotalInventoryAmount real
Declare @TotalGoodItems int
Declare @TotalItems int
Select @TotalInventoryAmount = 0
Select @TotalGoodItems = 0
Select @TotalItems = 0
Declare @@Unit int
Declare @@Status int
-- Loop Through Units
Declare Unit_Cursor Insensitive Cursor 
  For Select PU_Id From prdexec_path_units Where Path_Id = @Path And is_production_point = 1 
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@Unit
While @@Fetch_Status = 0
  Begin
     -- Loop Through Statuses
 	  	 Declare Status_Cursor Insensitive Cursor 
 	  	   For Select distinct t.from_prodstatus_id
            From prdexec_trans t 
            Join production_status s on s.prodstatus_id = t.from_prodstatus_id and s.count_for_inventory = 1 
            Where PU_Id = @@Unit 
 	  	   For Read Only
 	  	 
 	  	 Open Status_Cursor
 	  	 
 	  	 Fetch Next From Status_Cursor Into @@Status
 	  	 
 	  	 While @@Fetch_Status = 0
 	  	   Begin
 	  	  	 
 	  	  	   	  	 Select @TotalInventoryAmount = @TotalInventoryAmount + coalesce(sum(coalesce(ed.final_dimension_x,0)),0),
 	  	  	                        @TotalItems = @TotalItems + coalesce(sum(case when s.count_for_production = 1 then 1 else 0 end),0),
 	  	  	  	  	        @TotalGoodItems = @TotalGoodItems + coalesce(sum(case when s.status_valid_for_input = 1 and s.count_for_production = 1 then 1 else 0 end),0)
 	  	  	  	  	   From Events e 
 	  	  	  	  	   join event_details ed on ed.event_id = e.event_id
 	  	  	       join production_status s on s.prodstatus_id = e.event_status
 	  	  	  	  	   Where e.pu_id = @@Unit and
                  e.event_status = @@Status
 	  	 
 	  	     Fetch Next From Status_Cursor Into @@Status
 	  	   End
 	  	 
 	  	 Close Status_Cursor
 	  	 Deallocate Status_Cursor  
 	       
    Fetch Next From Unit_Cursor Into @@Unit
  End
Close Unit_Cursor
Deallocate Unit_Cursor  
--*****************************************************
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'InventoryAmountActual',
         ParameterValue = coalesce(@TotalInventoryAmount, convert(varchar(25),convert(decimal(10,1),@TotalInventoryAmount)), 0),
         DecimalParameterValue = coalesce(@TotalInventoryAmount, convert(decimal(10,1),@TotalInventoryAmount), 0)
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'InventoryAmountUnits',
         ParameterValue = coalesce(@iAmountEngineeringUnits, @iAmountEngineeringUnits, '')
Insert Into #Results (ParameterName, ParameterValue, DecimalParameterValue)    
  Select ParameterName = 'InventoryQualityPercent',
         ParameterValue = Case
 	  	  	  	 When @TotalItems = 0 then '0.0'
 	  	  	  	 Else convert(varchar(25),convert(decimal(10,1),@TotalGoodItems / @TotalItems * 100.0))
 	  	  	  	 End,
         DecimalParameterValue = Case
 	  	  	  	 When @TotalItems = 0 then 0.0
 	  	  	  	 Else convert(decimal(10,1),@TotalGoodItems / @TotalItems * 100.0)
 	  	  	  	 End
--*****************************************************
-- Pass Back Unit List For Drill Down
--*****************************************************
Declare @UnitList varchar(255)
Declare @Unit int
Select @UnitList = NULL
Declare Unit_Cursor Insensitive Cursor 
  For Select PU_Id From PrdExec_Path_Units where Path_Id = @Path and Is_Production_Point = 1
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @Unit
While @@Fetch_Status = 0
  Begin
    If @UnitList Is Null
      Select @UnitList = convert(varchar(25),@Unit)
    Else
      Select @UnitList = @UnitList + ';' + convert(varchar(25),@Unit)
 	  	  	 Fetch Next From Unit_Cursor Into @Unit
  End
Close Unit_Cursor
Deallocate Unit_Cursor
Insert Into #Results (ParameterName, ParameterValue)    
  Select ParameterName = 'UnitList',
         ParameterValue = @UnitList
--*****************************************************
Select * From #Results  
select * from #Prompts
