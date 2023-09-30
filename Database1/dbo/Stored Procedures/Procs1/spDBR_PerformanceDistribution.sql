CREATE Procedure dbo.spDBR_PerformanceDistribution
@UnitList text = null,
@StartTime datetime = null,
@EndTime datetime = null,
@FilterNonProductiveTime int = 0,
@ProductFilter int = null,
@CrewFilter varchar(10) = null,
@ShiftFilter varchar(10) = null,
@LocationFilter int = NULL,
@FaultFilter varchar(100) = NULL,
@ReasonFilter1 int = NULL,
@ReasonFilter2 int = NULL,
@ReasonFilter3 int = NULL,
@ReasonFilter4 int = NULL,
@ShowTopNBars int = 20,
@InTimeZone 	  	 varchar(200) = NULL,  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
@TimeOption int = null
AS
--**************************************************/
set arithignore on
set arithabort off
set ansi_warnings off
if (@LocationFilter = -1)
begin
 select @LocationFilter = NULL
end
Declare @@UnitId int, @@UnitDesc varchar(50)
Declare @SQL1 varchar(3000)
Declare @SQL2 varchar(3000)
Declare @SQL3 varchar(3000)
Declare @SQL4 varchar(3000)
Declare @FaultId int
Declare @TreeId int
Declare @Level1Name varchar(100)
Declare @Level2Name varchar(100)
Declare @Level3Name varchar(100)
Declare @Level4Name varchar(100)
declare @PerformanceCategory int, @OutsideAreaCategory int, @UnavailableCategory int
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
Declare @SpeedLossTime real , @PerformanceDT real, @NetOperatingTime real, @DesignTime real
Create Table #Summary (
  Timestamp  	  	 datetime,
  ProductId 	   	 int NULL,
  LocationId  	      	 int NULL,
  Reason1  	  	 int NULL,
  Reason2  	  	 int NULL,
  Reason3  	  	 int NULL,
  Reason4  	  	 int NULL,
  Duration  	  	 real NULL,
  TimeToRepair  	  	 real NULL,
  TimePreviousFailure   real NULL,
  Fault  	  	 varchar(100) NULL,
  Crew 	  	  	 varchar(10) NULL,
 	 Shift 	  	  	 varchar(10) NULL,
) 
Declare @TotalOperatingTime int
Declare @TotalDownTime real
Select @TotalOperatingTime = 0
Select @TotalDownTime = 0.0
--*****************************************************/
--Build List Of Units
--*****************************************************/
create table #Units
(
  LineName varchar(100) NULL, 
  LineId int NULL,
 	 UnitName varchar(100) NULL,
 	 Item int
)
create table #ProductiveTimes
(
  PU_Id     int null,
  StartTime datetime,
  EndTime   datetime
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 /*Time Options are also need to consider */
Create Table  #TimeOptions (Option_Id int, Date_Type_Id int, Description varchar(50), Start_Time datetime, End_Time datetime)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 --SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 --SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
 IF(@StartTime) IS NOT NULL AND (@EndTime) IS NOT NULL
BEGIN
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE IF (@TimeOption) IS NOT NULL
BEGIN
 	 Insert Into #TimeOptions exec spRS_GetTimeOptions @TimeOption,@InTimeZone
 	 Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	  	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END
ELSE
BEGIN
 	 Insert Into #TimeOptions exec spRS_GetTimeOptions 30,@InTimeZone -- Default to Today if no start time and end time is provided
 	 Select @StartTime = Start_Time, @EndTime = End_Time From #TimeOptions 	 
 	 SELECT @StartTime = [dbo].[fnServer_CmnConvertToDbTime](@StartTime,@InTimeZone),
 	 @EndTime = [dbo].[fnServer_CmnConvertToDbTime](@EndTime,@InTimeZone)
END 
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      declare @UnitText nvarchar(4000)
      select @UnitText = N'Item;' + Convert(nvarchar(4000), @UnitList)
      Insert Into #Units (Item) EXECUTE spDBR_Prepare_Table @UnitText
    end
    else
    begin
      Insert Into #Units EXECUTE spDBR_Prepare_Table @UnitList
    end
  end
Else
  Begin
    Insert Into #Units (Item) 
      Select distinct pu_id From prod_events where event_type = 2     
  End
--*****************************************************/
 	 declare @curPU_Id int
 	 Declare PRODUCTIVETIME_CURSOR INSENSITIVE CURSOR
   	 For (
      	 Select Item From #Units
       	 )
  	  For Read Only
if (@FilterNonProductiveTime = 1)
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR1:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @curPU_Id, @StartTime, @EndTime
 	  	 update #ProductiveTimes set PU_Id = @curPU_Id where PU_Id is null
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR1
 	 End
 	 Close PRODUCTIVETIME_CURSOR
 	 Deallocate PRODUCTIVETIME_CURSOR
end
else
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR2:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (PU_Id, StartTime, EndTime) select @curPU_Id, @StartTime, @EndTime
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR2
 	 End
 	 Close PRODUCTIVETIME_CURSOR
 	 Deallocate PRODUCTIVETIME_CURSOR
end
Create Table #OperatingTime (
  ProductId int,
  TotalTime int 
) 
 	 --Prepare Details Table
Create Table #Details (
  Timestamp  	  	 datetime,
  LocationId 	  	 int NULL,
  ProductId 	  	  	 int NULL,
  Reason1  	  	  	 int NULL,
  Reason2  	  	  	 int NULL,
  Reason3  	  	  	 int NULL,
  Reason4  	  	  	 int NULL,
  Duration  	  	  	 real NULL,
  TimeToRepair  	  	 real NULL,
  TimePreviousFailure  	 real NULL,
  FaultId  	  	  	 int NULL,
 	 Crew 	  	  	 varchar(10) null,
  Shift 	  	  	 varchar(10) NULL,
) 
Create Table #ProductChanges (
ProductId int,
StartTime datetime,
EndTime datetime,
) 
Create Table #Shift (
ShiftDesc  	 varchar(10),
ShiftStart  	 DateTime,
ShiftEnd 	   	 DateTime
)
Declare @ProductionShortFall FLOAT
Declare @LocalUnitSummary TABLE 
(
 	 LocationId 	  	 int,
 	 LocationDesc  	  	 varchar(50),
 	 PerformanceLoss 	  	 real,
 	 NormalizedRateLoss 	 real,
 	 TotalTime 	  	 real
) 	  	 
Declare @curStartTime datetime, @curEndTime datetime
Declare Unit_Cursor Insensitive Cursor 
  For Select Item From #Units 
  For Read Only
Open Unit_Cursor
Fetch Next From Unit_Cursor Into @@UnitId
While @@Fetch_Status = 0
 	 Begin
 	  	 SELECT @curStartTime = NULL
 	  	 SELECT @curEndTime = NULL
 	  	 Declare TIME_CURSOR INSENSITIVE CURSOR
 	  	   For ( Select StartTime, EndTime From #ProductiveTimes where PU_Id = @@UnitId )
 	  	   For Read Only
 	  	   Open TIME_CURSOR  
 	  	 BEGIN_TIME_CURSOR:
 	  	 Fetch Next From TIME_CURSOR Into @curStartTime, @curEndTime
 	  	 While @@Fetch_Status = 0
 	  	  	 Begin    
 	  	  	  	 
 	  	  	  	 execute spCMN_GetUnitStatistics @@UnitId,@curStartTime,@curEndTime,@iIdealProduction OUTPUT,@iIdealYield OUTPUT,@iActualProduction OUTPUT,@iActualQualityLoss OUTPUT,@iActualYieldLoss OUTPUT,@iActualSpeedLoss OUTPUT,@iActualDowntimeLoss OUTPUT,@iActualDowntimeMinutes OUTPUT,@iActualRuntimeMinutes OUTPUT,@iActualUnavailableMinutes OUTPUT,@iActualSpeed OUTPUT,@iActualPercentOEE OUTPUT,@iActualTotalItems OUTPUT,@iActualGoodItems OUTPUT,@iActualBadItems OUTPUT,@iActualConformanceItems OUTPUT,@iTargetProduction OUTPUT,@iWarningProduction OUTPUT,@iRejectProduction OUTPUT,@iTargetQualityLoss OUTPUT,@iWarningQualityLoss OUTPUT,@iRejectQualityLoss OUTPUT,@iTargetDowntimeLoss OUTPUT,@iWarningDowntimeLoss OUTPUT,@iRejectDowntimeLoss OUTPUT,@iTargetSpeed OUTPUT,@iTargetDowntimeMinutes OUTPUT,@iWarningDowntimeMinutes OUTPUT,@iRejectDowntimeMinutes OUTPUT,@iTargetPercentOEE OUTPUT,@iWarningPercentOEE OUTPUT,@iRejectPercentOEE OUTPUT,@iAmountEngineeringUnits OUTPUT,@iItemEngineeringUnits OUTPUT,@iTimeEngineeringUnits OUTPUT,@iStatus OUTPUT,@iActualDowntimeCount OUTPUT
 	  	  	  	 select @PerformanceCategory = Coalesce(Performance_Downtime_Category, 0), @@UnitDesc = pu_desc From Prod_Units Where PU_Id = @@UnitId
 	  	  	  	 select @OutsideareaCategory = Coalesce(Downtime_External_Category, 0), @@UnitDesc = pu_desc From Prod_Units Where PU_Id = @@UnitId
 	  	  	  	 select @UnavailableCategory = Coalesce(Downtime_Scheduled_Category, 0), @@UnitDesc = pu_desc From Prod_Units Where PU_Id = @@UnitId
 	  	 
 	  	  	  	 -- Need to make iTargetSpeed in minutes
 	  	  	  	 Select @iTargetSpeed = Case
 	  	  	  	  	 When @iTimeEngineeringUnits = 0 Then @iTargetSpeed / 60.0 -- hours
 	  	  	  	  	 When @iTimeEngineeringUnits = 1 Then @iTargetSpeed 	  	   -- Minutes
 	  	  	  	  	 When @iTimeEngineeringUnits = 2 Then @iTargetSpeed * 60.0 -- Seconds
 	  	  	  	  	 When @iTimeEngineeringUnits = 3 Then @iTargetSpeed / 1440 -- Days
 	  	  	  	  	 End
 	  	  	  	 Select @PerformanceDT = dbo.fnCMN_GetCategoryTimeByUnit(@curStartTime,@curEndTime,@@UnitId, @PerformanceCategory, null)
 	  	  	  	 Select @PerformanceDT = @PerformanceDT / 60
 	  	  	  	 -- This line represents Production Shortfall                                    (Ideal Production)   -    (ActualProduction)   / IdealSpeed
 	  	  	  	 Select @SpeedLossTime = Case When @iTargetSpeed = 0 then 0 else((@iActualRuntimeMinutes * @iTargetSpeed) - @iActualProduction) / @iTargetSpeed end
 	  	  	  	 select @SpeedLossTime = isnull(@SpeedLossTime, 0)
 	  	  	  	 Select @NetOperatingTime = Case When @iActualRuntimeMinutes < @SpeedLossTime then 0 else @iActualRuntimeMinutes - @SpeedLossTime end
 	  	  	  	 Select @DesignTime = Case When @NetOperatingTime < @PerformanceDT then 0 else @NetOperatingTime - @PerformanceDT end
 	  	  	  	 -- new calcs
 	  	  	  	 Select @ProductionShortFall = @iIdealProduction - (@iActualProduction + @iActualQualityLoss)-- [ProductionShortfall]
 	  	  	  	 Select @NetOperatingTime = @iActualRuntimeMinutes - @PerformanceDT --[NetOperatingTime]
 	  	  	  	 Select @SpeedLossTime = Case When @iTargetSpeed = 0 then 0 else @ProductionShortFall / @iTargetSpeed End -- [SpeedLossTime]
 	  	  	  	 Select @DesignTime = @iActualRuntimeMinutes - @SpeedLossTime
 	  	  	  	 --Get Reason Level Header Names
 	  	  	  	 If @Level1Name Is Null
 	  	  	  	  	 Begin
     	  	  	  	  	 Select @TreeId = Name_Id
 	  	  	  	  	  	   From Prod_Events
 	  	  	  	  	  	   Where PU_Id = @@UnitId and
 	  	  	  	  	  	 Event_Type = 2
     	  	  	  	  	 Select @Level1Name = level_name
 	  	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	  	  	  	 Reason_Level = 1
      	  	  	  	  	 If @Level1Name Is Not Null 
 	  	   	  	  	  	  	 Select @Level2Name = level_name
 	  	  	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	  	  	  	  	 Reason_Level = 2
 	  	  	  	 
 	  	  	  	  	  	 If @Level2Name Is Not Null 
 	  	  	  	  	  	  	 Select @Level3Name = level_name
 	  	  	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	  	  	  	  	 Reason_Level = 3
 	  	  	  	  	  	 
 	  	  	  	  	  	 If @Level3Name Is Not Null 
 	  	  	  	  	  	  	 Select @Level4Name = level_name
 	  	  	  	  	  	  	   From event_reason_level_headers 
 	  	  	  	  	  	  	   Where Tree_Name_id = @TreeId and
 	  	  	  	  	  	  	  	  	 Reason_Level = 4
 	  	  	  	  	 End
 	  	  	  	 Select @SQL1 = 'Select d.Start_Time, d.Source_PU_Id, d.Reason_Level1, d.Reason_Level2, d.Reason_Level3, d.Reason_Level4' 	  
 	  	  	  	 Select @SQL1 = @SQL1 + ', Datediff(second, Case When d.Start_Time < ' + '''' + convert(varchar(30),@curStartTime) + '''' + ' Then ' + '''' + convert(varchar(30),@curStartTime) + '''' + ' Else d.Start_Time End, Case When d.End_Time > ' + '''' + convert(varchar(30),@curEndTime) + '''' + ' Then ' + '''' + convert(varchar(30),@curEndTime) + '''' + ' Else coalesce(d.End_Time, ' + '''' + convert(varchar(30),@curEndTime) + '''' + ') End) / 60.0'
 	  	  	  	 Select @SQL1 = @SQL1 + ', Datediff(second, d.Start_Time, coalesce(d.End_Time, dbo.fnServer_CmnGetDate(getutcdate()))) / 60.0'
 	  	  	  	 Select @SQL1 = @SQL1 + ', Case When d.Start_Time < ' + '''' + convert(varchar(30),@curStartTime) + '''' + ' Then Null When d.Uptime <= 0 Then null else d.Uptime End'
 	  	  	  	 Select @SQL1 = @SQL1 + ', d.TEFault_Id'
 	  	  	  	 Select @SQL1 = @SQL1 + ' From Timed_Event_Details d left outer join event_reason_category_data c on c.event_reason_tree_data_id = d.event_reason_tree_data_id'
 	  	  	  	  
 	  	  	  	 select @SQL1 = @SQL1 + ' Where d.PU_Id = ' + convert(varchar(10),@@UnitId)
 	  	  	  	 Select @SQL1 = @SQL1 + ' and c.erc_id in (' 	  + convert(varchar(5),@PerformanceCategory) + ',' + convert(varchar(5),@OutsideareaCategory) + ',' + convert(varchar(5),@UnavailableCategory) + ')'
 	  	  	  	 Select @SQL2 = ' and d.Start_Time >= ' + '''' + convert(varchar(30),@curStartTime) + '''' + ' and d.Start_Time < ' + '''' + convert(varchar(30),@curEndTime) + ''''
 	  	  	     Select @SQL3 = ' '
 	  	  	  	 If @LocationFilter Is Not Null Select @SQL3 = @SQL3 + ' and d.Source_PU_Id = ' + convert(varchar(10), @LocationFilter)
 	  	  	  	 If @ReasonFilter1 Is Not Null Select @SQL3 = @SQL3 + ' and d.Reason_Level1 = ' + convert(varchar(10), @ReasonFilter1)
 	  	  	  	 If @ReasonFilter2 Is Not Null Select @SQL3 = @SQL3 + ' and d.Reason_Level2 = ' + convert(varchar(10), @ReasonFilter2)
 	  	  	  	 If @ReasonFilter3 Is Not Null Select @SQL3 = @SQL3 + ' and d.Reason_Level3 = ' + convert(varchar(10), @ReasonFilter3)
 	  	  	  	 If @ReasonFilter4 Is Not Null Select @SQL3 = @SQL3 + ' and d.Reason_Level4 = ' + convert(varchar(10), @ReasonFilter4)
 	  	  	  	 If @FaultFilter Is Not Null
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Select @FaultId = NULL
 	  	  	  	  	  	 Select @FaultId = TEFault_Id From Timed_Event_Fault Where PU_Id = @@UnitId and TEFault_Name = @FaultFilter
 	  	  	  	  	  	 If @FaultId Is Not Null
 	  	  	  	  	  	  	 Select @SQL3 = @SQL3 + ' and d.TEFault_Id = ' + convert(varchar(10), @FaultId)              
 	  	  	  	  	 End
 	  	 
 	  	  	  	 Select @SQL4 = @SQL1 + @SQL2 + @SQL3
 	  	  	  	 Insert Into #Details (Timestamp, LocationId, Reason1, Reason2, Reason3, Reason4, Duration, TimeToRepair, TimePreviousFailure, FaultId)
 	  	  	  	 Exec (@SQL4)        
 	  	  	  	 Select @SQL2 = ' and d.Start_Time = (Select Max(t.Start_Time) From Timed_Event_Details t Where t.PU_Id = ' + convert(varchar(10),@@UnitId) 
 	  	  	  	 Select @SQL2 = @SQL2 + ' and t.start_time < ' + '''' + convert(varchar(30),@curStartTime) + '''' + ') and ((d.End_Time > ' + '''' + convert(varchar(30),@curStartTime) + '''' + ') or (d.End_Time is Null))'
 	  	  	  	 Select @SQL4 = @SQL1 + @SQL2 + @SQL3
 	  	  	  	 Insert Into #Details (Timestamp, LocationId, Reason1, Reason2, Reason3, Reason4, Duration, TimeToRepair, TimePreviousFailure, FaultId)
 	  	  	  	 Exec (@SQL4)        
 	  	  	  	 -- Join In Product Information    
 	  	  	  	 Update #Details 
 	  	  	  	 Set ProductId = (Select Prod_Id From Production_Starts ps Where ps.PU_Id = @@UnitId and ps.Start_Time <= #Details.Timestamp and ((ps.End_Time > #Details.Timestamp) or (ps.End_Time Is Null)))      	 
 	  	  	  	 Insert Into #ProductChanges (ProductId, StartTime, EndTime)
 	  	  	  	   Select Prod_Id, 
 	  	  	  	  	  	  Case When Start_Time < @curStartTime Then @curStartTime Else Start_Time End,
 	  	  	  	  	  	  Case When coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) > @curEndTime Then @curEndTime Else coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) End
 	  	  	  	  	 From Production_Starts d
 	  	  	  	  	   Where d.PU_id = @@UnitId and
 	   	  	  	  	  	  	  	   d.Start_Time = (Select Max(t.Start_Time) From Production_Starts t Where t.PU_Id = @@UnitId and t.start_time < @curStartTime) and
 	   	  	  	  	  	  	   ((d.End_Time > @curStartTime) or (d.End_Time is Null))
 	  	  	  	    Union
 	  	  	  	  	 Select Prod_Id, 
 	  	  	  	  	  	  Case When Start_Time < @curStartTime Then @curStartTime Else Start_Time End,
 	  	  	  	  	  	  Case When coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) > @curEndTime Then @curEndTime Else coalesce(End_Time, dbo.fnServer_CmnGetDate(getutcdate())) End
 	  	  	  	  	 From Production_Starts d
 	  	  	  	  	  	 Where d.PU_id = @@UnitId and
 	  	  	  	  	  	  	   d.Start_Time >= @curStartTime and 
 	          	  	  	  	  	 d.Start_Time < @curEndTime 
 	  	  	  	 If @ProductFilter Is Not Null
 	  	  	  	  	 Begin                    	  	  	  	  	 
 	  	  	  	  	  	 Delete From #ProductChanges Where ProductId <> @ProductFilter
 	  	  	  	  	  	 Delete From #Details Where ProductId <> @ProductFilter
 	  	  	  	  	 End
 	  	  	  	 -- Update Operating Time From Trimmed Production Starts
 	  	  	  	 Select @TotalOperatingTime = @TotalOperatingTime + coalesce((Select sum(datediff(second, StartTime, EndTime))From #ProductChanges),0)
    	  	  	  	 Insert Into #OperatingTime (ProductId, TotalTime)
 	  	  	  	   Select ProductId, sum(datediff(second, StartTime, EndTime))
 	  	  	  	  	 From #ProductChanges
 	  	  	  	  	 Group By ProductId
 	  	  	        
 	  	  	  	 truncate Table #ProductChanges    
 	  	  	  	 --Update Crew
 	  	  	  	 Update #Details 
 	  	  	  	   Set #Details.Crew = (Select c.Crew_Desc From Crew_Schedule c Where c.PU_Id = @@UnitId and c.Start_Time <= #Details.Timestamp and C.End_Time > #Details.Timestamp)
 	  	  	     
 	  	  	  	 If @CrewFilter Is Not Null
 	  	  	  	   Delete From #Details Where Crew <> @CrewFilter 
 	 
 	  	  	  	 /*
 	  	  	  	 Build the shift information:
 	  	  	  	 */
 	  	  	  	 declare @ShiftInterval int, @ShiftOffset int, @ShiftStart datetime, @ShiftEnd datetime, @ShiftDesc varchar(10), @TimePart varchar(50)
 	  	  	  	 select @ShiftInterval = value from site_parameters where parm_id = 16
 	  	  	  	 select @ShiftOffset = value from site_parameters where parm_id = 17
 	  	  	  	 select @TimePart = convert(varchar(10), DatePart(hh, @curStartTime)) + ':' + convert(varchar(10),DatePart(mi, @curStartTime)) + ':' + convert(varchar(10), DatePart(ss, @curStartTime))
 	  	  	  	 select @ShiftStart = @curStartTime - @TimePart
 	  	  	  	 select @ShiftStart = dateadd(mi, @ShiftOffset, @ShiftStart)
 	  	  	  	 select @ShiftStart = dateadd(mi, @ShiftInterval * -1, @ShiftStart)
 	  	  	  	 select @ShiftEnd = dateadd(mi, @ShiftInterval, @ShiftStart)
 	  	  	  	 declare @ShiftNum int, @DailyShiftTotal int
 	  	  	  	 select @ShiftNum = 1440 / @ShiftInterval
 	  	  	  	 select @DailyShiftTotal = 1440 - @ShiftInterval
 	  	  	  	 while @ShiftStart < @curEndTime
 	  	  	  	 begin
 	  	  	  	  	 insert into #Shift (ShiftDesc, ShiftStart, ShiftEnd) values ('Shift' + convert(varchar(2),@ShiftNum), @ShiftStart, @ShiftEnd)
 	  	  	  	  	 select @DailyShiftTotal = @DailyShiftTotal + @ShiftInterval
 	  	  	  	  	 if (@DailyShiftTotal >= 1440) 
 	  	  	  	  	 begin
 	  	  	  	  	  	 select @DailyShiftTotal = 0
 	  	  	  	  	  	 select @ShiftNum = 0
 	  	  	  	  	 end
 	  	  	  	  	 select @ShiftNum = @ShiftNum + 1
 	  	  	  	  	 select @ShiftStart = @ShiftEnd
 	  	  	  	  	 select @ShiftEnd = dateadd(mi, @ShiftInterval, @ShiftStart)
 	  	  	  	 end
 	  	  	  	 /*
 	  	  	  	 Now use #Shift table to update the details
 	  	  	  	 */
 	  	  	  	 Update #Details 
 	  	  	  	   Set #Details.Shift = (Select ShiftDesc From #Shift Where ShiftStart <= #Details.Timestamp and ShiftEnd > #Details.Timestamp)
 	  	  	  	   If @ShiftFilter is not null
 	  	  	  	  	  	 delete from #Details where Shift <> @ShiftFilter
 	  	  	  	 -- Add Rows To Summary Resultset
 	  	  	  	 Insert Into  #Summary (Timestamp,ProductId,LocationId,Reason1,Reason2,Reason3,Reason4, Duration, TimeToRepair, TimePreviousFailure, Crew,Shift, Fault) 
 	  	  	  	  	 Select Timestamp,
 	  	  	  	  	  	 ProductId,
 	  	  	  	  	  	 LocationId,
 	  	  	  	  	  	 Reason1,
 	  	  	  	  	  	 Reason2,
 	  	  	  	  	  	 Reason3,
 	  	  	  	  	  	 Reason4,
 	  	  	  	  	  	 Duration, 
 	  	  	  	  	  	 TimeToRepair, 
 	  	  	  	  	  	 TimePreviousFailure, 
 	  	  	  	  	  	 Crew, 
 	  	  	  	  	  	 Shift,
 	  	  	  	  	  	 case when tef.TEFault_Id Is Null then dbo.fnDBTranslate(N'0', 38333, 'Unspecified') Else tef.TEFault_Name End 
 	  	  	  	  	 From #Details
 	  	  	  	  	 Left Outer Join Timed_Event_Fault tef on tef.TEFault_Id = #Details.FaultId 
 	  	   	  	 Select @TotalDownTime = @TotalDownTime + coalesce((Select sum(Duration) From #Details),0)
 	  	  	  	 Insert Into @LocalUnitSummary (LocationId, LocationDesc, PerformanceLoss, NormalizedRateLoss, TotalTime) 
 	  	  	  	 values (@@UnitId, @@UnitDesc, @PerformanceDT, @SpeedLossTime, @PerformanceDT + @SpeedLossTime) 
 	  	  	  	 Truncate Table #Details
 	  	  	  	 Truncate Table #Shift
 	  	  	 GOTO BEGIN_TIME_CURSOR
 	  	 End
 	 Close TIME_CURSOR
 	 Deallocate TIME_CURSOR
    Fetch Next From Unit_Cursor Into @@UnitId
End
Close Unit_Cursor
Deallocate Unit_Cursor  
declare @RowCount int
--*********************************************************************************
-- Return Resultset #0 - Resultset Name List
--*********************************************************************************
Create Table #Resultsets (
  ResultSetName varchar(50),
  ResultSetTabName varchar(50),
  ParameterName varchar(50),
  ParameterUnits varchar(50) NULL,
  DataColumns    varchar(50) NULL,
  LabelColumns   varchar(50) NULL,
  IconDesc 	  varchar(1000) NULL,
  Stacked 	  	  	  	 int NULL,
  RS_ID 	  	 int
)
insert into #Resultsets values (null,dbo.fnDBTranslate(N'0', 38474, 'Performance Distribution'), 'green', NULL, NULL, NULL, NULL, NULL, NULL)
If @LocationFilter Is Null
 	 insert into #Resultsets values ('LocationPareto', dbo.fnDBTranslate(N'0', 38335, 'Location'), '38246', dbo.fnDBTranslate(N'0', 38339, 'Minutes') + ';' + dbo.fnDBTranslate(N'0', 38339, 'Minutes'), '2;3','1;1','Minutes;Minutes',1, 1)
If @FaultFilter Is Null
  insert into #Resultsets values ('FaultPareto', dbo.fnDBTranslate(N'0', 38336, 'Fault'), '38247', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), '2','1', NULL,0, 2)
If @ReasonFilter1 Is Null and @Level1Name Is Not Null
  insert into #Resultsets values ('Reason1Pareto', @Level1Name, '38248', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), '2','1',NULL, 0,3)
If @ReasonFilter2 Is Null and @Level2Name Is Not Null
  insert into #Resultsets values ('Reason2Pareto', @Level2Name, '38249', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,4)
If @ReasonFilter3 Is Null and @Level3Name Is Not Null
  insert into #Resultsets values ('Reason3Pareto', @Level3Name, '38250', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,5)
If @ReasonFilter4 Is Null and @Level4Name Is Not Null
  insert into #Resultsets values ('Reason4Pareto', @Level4Name, '38251', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,6)
If @ProductFilter Is Null
  insert into #Resultsets values ('ProductPareto', dbo.fnDBTranslate(N'0', 38337, 'Product'), '38244', dbo.fnDBTranslate(N'0', 38339, 'Minutes'),'2','1',NULL,0, 7)
If @CrewFilter Is Null
  insert into #Resultsets values ('CrewPareto', dbo.fnDBTranslate(N'0', 38338, 'Crew'), '38245', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,8)
IF @ShiftFilter Is NULL
  insert into #Resultsets values ('ShiftPareto', dbo.fnDBTranslate(N'0', 38479, 'Shift'), '38477', dbo.fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,0,9)
/*********************************************************************************
Results
********************************************************************************/
 	 Create Table #Results 
 	 (
 	   Id int NULL,
 	   Name varchar(100) NULL,
 	   Total float NULL,
 	   MTTR float NULL,
 	   MTBF float NULL,
 	   PercentTotal float NULL,
 	   NumberOfEvents int NULL 
 	 )
/**********************************************************
ResultSet1
*********************************************************/
 	 create table #ResultSet1 
 	 (
 	  	 LocationId 	  	  	  	  	 int NULL,
 	  	 LocationDesc  	  	  	  	 varchar(50),
 	  	 PerformanceLoss 	  	  	 real,
 	  	 NormalizedRateLoss 	 real,
 	  	 TotalTime 	  	  	  	  	  	 real,
 	  	 rs_id 	  	  	  	  	  	  	  	 int
 	 ) 	  	 
 	 insert into #ResultSet1 (LocationId, LocationDesc, PerformanceLoss, NormalizedRateLoss, TotalTime, rs_id) 
 	 Select LocationId, LocationDesc, PerformanceLoss, NormalizedRateLoss, TotalTime, 1
 	 From @LocalUnitSummary
--values (@@UnitId, @@UnitDesc, @PerformanceDT, @SpeedLossTime, @PerformanceDT + @SpeedLossTime, 1) 
/**********************************************************
ResultSet2
*********************************************************/
create table #ResultSet2 
 	 (
 	  	 FaultId 	  	  	  	  	  	  	 int NULL,
 	  	 FaultDesc 	  	  	  	  	  	 varchar(50),
 	  	 Total 	  	  	  	  	  	  	  	 real NULL,
 	  	 MTTR 	  	  	  	  	  	  	  	 varchar(50),
 	  	 MTBF 	  	  	  	  	  	  	  	 varchar(50),
 	  	 [% Total] 	  	  	  	  	  	 real NULL,
 	  	 [# Events] 	  	  	  	  	 real NULL,
 	  	 rs_id 	  	  	  	  	  	  	  	 int
 	 )
 	 If @FaultFilter Is Null
 	   Begin
 	     Truncate Table #Results
 	 
 	     Insert Into #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	       Select Fault, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
 	         From #Summary
 	         Group By Fault
 	 
 	 
 	  	  	 insert into #ResultSet2 (FaultId, FaultDesc, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	  	 select NULL, coalesce(r.Name, dbo.fnDBTranslate(N'0', 38333, 'Unspecified')),
 	   	  	  	 convert(decimal(10,2),Total), dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF), convert(decimal(10,1),r.PercentTotal*100.0), r.NumberOfEvents, 2
 	  	  	  	 from #Results r
 	  	  	 insert into #ResultSet2 (FaultId, FaultDesc, Total, MTTR, MTBF, [% Total], [# Events], rs_id)
 	  	  	  	 values (0, dbo.fnDBTranslate(N'0', 38478, 'Duration at Design Speed'), @DesignTime, null, null, null, null, 2)
 	  	 
 	   End
 	 select @RowCount = (select count(rs_id) from #ResultSet2)
 	 if @RowCount = 0
 	 begin
 	  	 delete from #ResultSets where ResultSetName = 'FaultPareto'
 	 end
/**********************************************************
ResultSet3
*********************************************************/
 	 create table #ResultSet3
 	 (
 	  	 Id 	  	  	  	  	  	 int NULL,
 	  	 Level1Name 	  	  	 varchar(50),
 	  	 Total 	  	  	  	  	 real,
 	  	 MTTR 	  	  	  	  	 varchar(50),
 	  	 MTBF 	  	  	  	  	 varchar(50),
 	  	 [% Total] 	  	  	 real,
 	  	 [# Events] 	  	 real,    
 	  	 rs_id 	  	  	  	  	 int
 	 )
 	 If @ReasonFilter1 Is Null and @Level1Name Is Not Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select Reason1, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From #Summary
        Group By Reason1
 	  	  	 insert into #ResultSet3 (Id, Level1Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select r.id, coalesce(n.event_reason_name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), convert(decimal(10,2),Total), dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),convert(decimal(10,1),r.PercentTotal*100.0), r.NumberOfEvents, 3
 	  	  	 From #Results r left outer join Event_Reasons n on n.event_reason_id = r.Id  	  	  	 
 	  	  	 insert into #ResultSet3 (Id, Level1Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id)
 	  	  	  	 values (0, dbo.fnDBTranslate(N'0', 38478, 'Duration at Design Speed'), @DesignTime, null, null, null, null, 3)
End
 	 select @RowCount = (select count(rs_id) from #ResultSet3)
 	 if @RowCount = 0
 	 begin
 	  	 delete from #ResultSets where ResultSetName = 'Reason1Pareto'
 	 end
/**********************************************************
ResultSet4
*********************************************************/
 	 create table #ResultSet4
 	 (
 	  	 Id 	  	  	  	  	  	 int NULL,
 	  	 Level2Name 	  	  	 varchar(50),
 	  	 Total 	  	  	  	  	 real,
 	  	 MTTR 	  	  	  	  	 varchar(50),
 	  	 MTBF 	  	  	  	  	 varchar(50),
 	  	 [% Total] 	  	  	 real,
 	  	 [# Events] 	  	 real,    
 	  	 rs_id 	  	  	  	  	 int
 	 )
If @ReasonFilter2 Is Null and @Level2Name Is Not Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select Reason2, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From #Summary
        Group By Reason2
 	  	  	 insert into #ResultSet4 (Id, Level2Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select r.id, coalesce(n.event_reason_name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), convert(decimal(10,2),Total), dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),convert(decimal(10,1),r.PercentTotal*100.0), r.NumberOfEvents, 4
 	  	  	 From #Results r left outer join Event_Reasons n on n.event_reason_id = r.Id  	  	  	 
 	  	  	 insert into #ResultSet4 (Id, Level2Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id)
 	  	  	  	 values (0, dbo.fnDBTranslate(N'0', 38478, 'Duration at Design Speed'), @DesignTime, null, null, null, null, 4)
  End
 	 select @RowCount = (select count(rs_id) from #ResultSet4)
 	 if @RowCount = 0
 	 begin
 	  	 delete from #ResultSets where ResultSetName = 'Reason2Pareto'
 	 end
/**********************************************************
ResultSet5
*********************************************************/
 	 create table #ResultSet5
 	 (
 	  	 Id 	  	  	  	  	  	 int NULL,
 	  	 Level3Name 	  	  	 varchar(50),
 	  	 Total 	  	  	  	  	 real,
 	  	 MTTR 	  	  	  	  	 varchar(50),
 	  	 MTBF 	  	  	  	  	 varchar(50),
 	  	 [% Total] 	  	  	 real,
 	  	 [# Events] 	  	 real,    
 	  	 rs_id 	  	  	  	  	 int
 	 )
If @ReasonFilter3 Is Null and @Level3Name Is Not Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select Reason3, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From #Summary
        Group By Reason3
 	  	  	 insert into #ResultSet5 (Id, Level3Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select r.id, coalesce(n.event_reason_name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), convert(decimal(10,2),Total), dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),convert(decimal(10,1),r.PercentTotal*100.0), r.NumberOfEvents, 5
 	  	  	 From #Results r left outer join Event_Reasons n on n.event_reason_id = r.Id  	  	  	 
 	  	  	 insert into #ResultSet5 (Id, Level3Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id)
 	  	  	  	 values (0, dbo.fnDBTranslate(N'0', 38478, 'Duration at Design Speed'), @DesignTime, null, null, null, null, 5)
  End
 	 select @RowCount = (select count(rs_id) from #ResultSet5)
 	 if @RowCount = 0
 	 begin
 	  	 delete from #ResultSets where ResultSetName = 'Reason3Pareto'
 	 end
/**********************************************************
ResultSet6
*********************************************************/
 	 create table #ResultSet6
 	 (
 	  	 Id 	  	  	  	  	  	 int NULL,
 	  	 Level4Name 	  	  	 varchar(50),
 	  	 Total 	  	  	  	  	 real,
 	  	 MTTR 	  	  	  	  	 varchar(50),
 	  	 MTBF 	  	  	  	  	 varchar(50),
 	  	 [% Total] 	  	  	 real,
 	  	 [# Events] 	  	 real,    
 	  	 rs_id 	  	  	  	  	 int
 	 )
If @ReasonFilter4 Is Null and @Level4Name Is Not Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select Reason4, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From #Summary
        Group By Reason4
 	  	  	 insert into #ResultSet6 (Id, Level4Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select r.id, coalesce(n.event_reason_name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), convert(decimal(10,2),Total), dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),convert(decimal(10,1),r.PercentTotal*100.0), r.NumberOfEvents, 6
 	  	  	 From #Results r left outer join Event_Reasons n on n.event_reason_id = r.Id  	  	  	 
 	  	  	 insert into #ResultSet6 (Id, Level4Name, Total, MTTR, MTBF, [% Total], [# Events], rs_id)
 	  	  	  	 values (0, dbo.fnDBTranslate(N'0', 38478, 'Duration at Design Speed'), @DesignTime, null, null, null, null, 6)
  End
 	 select @RowCount = (select count(rs_id) from #ResultSet6)
 	 if @RowCount = 0
 	 begin
 	  	 delete from #ResultSets where ResultSetName = 'Reason4Pareto'
 	 end
/**********************************************************
ResultSet7
*********************************************************/
 	 create table #ResultSet7
 	 (
 	  	 Id 	  	  	  	  	 int,
 	  	 Product 	  	  	 varchar(50),
 	  	 Total 	  	  	  	  	 real,
 	  	 MTTR 	  	  	  	  	 varchar(50),
 	  	 MTBF 	  	  	  	  	 varchar(50),
 	  	 [% Fault] 	  	  	 real,
 	  	 [% Total] 	  	  	 real,
 	  	 [# Events] 	  	 real,    
 	  	 rs_id 	  	  	  	  	 int 	  	 
 	 )
If @ProductFilter Is Null
  Begin
    Truncate Table #Results
 	  	 -- Return % Operating Time By Product
    Create Table #IntegerResults (
      ID    int NULL,
      Value int NULL
    )
 	  	 
 	  	 Insert Into #IntegerResults (Id, Value)
 	  	   Select ProductId, sum(TotalTime)
        From #OperatingTime
 	  	     Group By ProductId 
 	  	 
    Insert Into #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select ProductId, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),  sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From #Summary
        Group By ProductId
 	  	  	 insert into #ResultSet7 (Id, Product, Total, MTTR, MTBF, [% Fault], [% Total],[# Events], rs_id) 
 	  	  	 select r.id, p.prod_code, convert(decimal(10,2),Total), dbo.fnMinutesToTime(r.MTTR),dbo.fnMinutesToTime(((i.value/60.0) - r.Total) / r.NumberOfEvents),convert(decimal(10,2),(r.Total / (i.value/60.0) * 100.0)), convert(decimal(10,1),r.PercentTotal*100.0), r.NumberOfEvents, 7
 	  	  	 From #Results r join Products p on p.prod_id = r.Id left outer join #IntegerResults i on i.Id = r.Id  	  	  	 
  End
 	 select @RowCount = (select count(rs_id) from #ResultSet7)
 	 if @RowCount = 0
 	 begin
 	  	 delete from #ResultSets where ResultSetName = 'ProductPareto'
 	 end
/**********************************************************
ResultSet8 - Crew
*********************************************************/
 	 create table #ResultSet8
 	 (
 	  	 Id 	  	  	  	  	  	 int,
 	  	 Crew 	  	  	  	  	 varchar(50),
 	  	 Total 	  	  	  	  	 real,
 	  	 MTTR 	  	  	  	  	 varchar(50),
 	  	 MTBF 	  	  	  	  	 varchar(50),
 	  	 [% Total] 	  	  	 real,
 	  	 [# Events] 	  	 real,    
 	  	 rs_id 	  	  	  	  	 int 	  	 
 	 )
If @CrewFilter Is Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select Crew, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From #Summary
        Group By Crew
 	  	  	 insert into #ResultSet8 (Id, Crew, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select NULL, coalesce(r.name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), convert(decimal(10,2),Total), dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),convert(decimal(10,1),r.PercentTotal*100.0), r.NumberOfEvents, 8
 	  	  	 From #Results r  	  	  	 
  End
 	 select @RowCount = (select count(rs_id) from #ResultSet8)
 	 if @RowCount = 0
 	 begin
 	  	 delete from #ResultSets where ResultSetName = 'CrewPareto'
 	 end
/**********************************************************
ResultSet9 - Shift
*********************************************************/
 	 create table #ResultSet9
 	 (
 	  	 Id 	  	  	  	  	  	 int,
 	  	 Shift 	  	  	  	  	 varchar(50),
 	  	 Total 	  	  	  	  	 real,
 	  	 MTTR 	  	  	  	  	 varchar(50),
 	  	 MTBF 	  	  	  	  	 varchar(50),
 	  	 [% Total] 	  	  	 real,
 	  	 [# Events] 	  	 real,    
 	  	 rs_id 	  	  	  	  	 int 	  	 
 	 )
If @ShiftFilter Is Null
  Begin
    Truncate Table #Results
    Insert Into #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      Select Shift, sum(Duration), Avg(TimeToRepair), avg(TimePreviousFailure),sum(Duration) / convert(real,@TotalDowntime), Count(Duration)
        From #Summary
        Group By Shift
 	  	  	 insert into #ResultSet9 (Id, Shift, Total, MTTR, MTBF, [% Total], [# Events], rs_id) 
 	  	  	 select NULL, coalesce(r.name,dbo.fnDBTranslate(N'0', 38333, 'Unspecified')), convert(decimal(10,2),Total), dbo.fnMinutesToTime(r.MTTR), dbo.fnMinutesToTime(r.MTBF),convert(decimal(10,1),r.PercentTotal*100.0), r.NumberOfEvents, 9
 	  	  	 From #Results r  	  	  	 
  End
 	 select @RowCount = (select count(rs_id) from #ResultSet9)
 	 if @RowCount = 0
 	 begin
 	  	 delete from #ResultSets where ResultSetName = 'ShiftPareto'
 	 end
declare @total int
select @total = max(totaltime) from #resultset1
if @total > 120
begin
  update #resultset1 set totaltime = totaltime / 60, NormalizedRateLoss = NormalizedRateLoss / 60, PerformanceLoss = PerformanceLoss / 60
  update #resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 1
end
select @total = max(total) from #resultset2
if @total > 120
begin
  update #resultset2 set total = total / 60
  update #resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 2
end
select @total = max(total) from #resultset3
if @total > 120
begin
  update #resultset3 set total = total / 60
  update #resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 3
end
select @total = max(total) from #resultset4
if @total > 120
begin
  update #resultset4 set total = total / 60
  update #resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 4
end
select @total = max(total) from #resultset5
if @total > 120
begin
  update #resultset5 set total = total / 60
  update #resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 5
end
select @total = max(total) from #resultset6
if @total > 120
begin
  update #resultset6 set total = total / 60
  update #resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 6
end
select @total = max(total) from #resultset7
if @total > 120
begin
  update #resultset7 set total = total / 60
  update #resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 7
end
select @total = max(total) from #resultset8
if @total > 120
begin
  update #resultset8 set total = total / 60
  update #resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 8
end
select @total = max(total) from #resultset9
if @total > 120
begin
  update #resultset9 set total = total / 60
  update #resultsets set parameterunits = dbo.fnDBTranslate(N'0', 38388, 'Hours') where rs_id = 9
end
Select * From #Resultsets
select * from #ResultSet1 order by TotalTime asc
declare @SQL varchar(7000)
select @SQL = 'select LocationId as Id, LocationDesc as [\@' + dbo.fnDBTranslate(N'0', 38345, 'Location') + '], PerformanceLoss as [' + dbo.fnDBTranslate(N'0', 38482, 'Performance Loss') + '], NormalizedRateLoss as [' + dbo.fnDBTranslate(N'0', 38483, 'Normalized Rate Loss') + '], TotalTime as [' + dbo.fnDBTranslate(N'0', 38484, 'Total Time') + '], rs_id as rs_id 	 from #ResultSet1 order by TotalTime asc'
exec (@SQL)
select @SQL = 'select FaultId as Id, FaultDesc as [\@' + dbo.fnDBTranslate(N'0', 38336, 'Fault') + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet2 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Level1Name as [\@' +   @Level1Name  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet3 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Level2Name as [\@' +  @Level2Name  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet4 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Level3Name as [\@' +   @Level3Name  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet5 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Level4Name as [\@' +  @Level4Name  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet6 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Product as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product')  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Fault] as [' + dbo.fnDBTranslate(N'0', 38346, '% Fault') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet7 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Crew as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew')  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet8 order by Total asc'
exec (@SQL)
select @SQL = 'select Id as Id, Shift as [\@' + dbo.fnDBTranslate(N'0', 38479, 'Shift')  + '], Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') + '], MTTR as [' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + '], MTBF as [' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') + '], [% Total] as [' + dbo.fnDBTranslate(N'0', 38343, '% Total') + '], [# Events] as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], rs_id as rs_id 	 from #ResultSet9 order by Total asc'
exec (@SQL)
Drop table #Summary
Drop Table #Units
Drop Table #ProductiveTimes
Drop Table #OperatingTime
Drop Table #Details
Drop Table #ProductChanges
Drop Table #Shift
Drop Table #ResultSets
Drop Table #Results
Drop Table #ResultSet1
Drop Table #ResultSet2
Drop Table #ResultSet3
Drop Table #ResultSet4
Drop Table #ResultSet5
Drop Table #ResultSet6
Drop Table #ResultSet7
Drop Table #ResultSet8
Drop Table #ResultSet9
Drop Table #IntegerResults
--todo:select results as LocalLanguage!!!!
--Add Runtime minutes like charts show!!!!!
--overlay production tab!!!!!
--group shift data
