CREATE Procedure dbo.spDBR_ProductProduction
@UnitList text = NULL,
@StartTime datetime = NULL,
@EndTime datetime = NULL,
@OnlyMadeNow bit =  0,
@ColumnVisibility text = NULL,
@FilterNonProductiveTime int = 0,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
--****************************/
set arithignore on
set arithabort off
set ansi_warnings off
/*****************************************************
-- For Testing
--*****************************************************
Declare @UnitList varchar(1000),
@StartTime datetime,
@EndTime datetime,
@OnlyMadeNow tinyint,
@ColumnVisibility varchar(1000)
Select @UnitList  = '<root></root>'
Select @StartTime = '1/1/2003'
Select @EndTime = '1/1/2004'
Select @OnlyMadeNow = 0
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
@iActualDowntimeCount int,
@iLoadingTime real,
@iPerformanceRateProduction real,
@iPerformanceDownTime real,
@iActualLoadingTime real
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
@tLoadingTime real,
@tPerformanceRateProduction real,
@tPerformanceDownTime real,
@tActualLoadingTime real
Declare @IsBeingMadeNow int
Declare @AmountEngineeringUnits varchar(100)
Declare @ItemEngineeringUnits varchar(100)
Declare @TimeEngineeringUnits int
Declare @TotalTime int
--*****************************************************/
--Build List Of Units
--*****************************************************/
Create Table #Units (
  LineName varchar(100) NULL,
  LineId int NULL, 
  UnitName varchar(100) NULL, 
  UnitId int NULL,
  EventName varchar(10) NULL
)
create table #ProductiveTimes
(
  PU_Id     int null,
 	 Product_ID int null,
  StartTime datetime,
  EndTime   datetime
)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
if (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
  begin
    if (not @UnitList like '%<Root>%')
    begin
      declare @Text nvarchar(4000)
      select @Text = N'UnitId;' + Convert(nvarchar(4000), @UnitList)
      Insert Into #Units (UnitId) EXECUTE spDBR_Prepare_Table @Text
    end
    else
    begin
      insert into #Units (LineName, LineId, UnitName, UnitId) EXECUTE spDBR_Prepare_Table @UnitList
    end
  end
Else
  Begin
    Insert Into #Units (UnitId, UnitName) 
      Select distinct pu_id, pu_desc From prod_units     
  End
create table #ProductProduction
(
 	 IsBeingMadeNowFlag bit NULL,
 	 ProductCode varchar(200) NULL,
 	 ProductionItems int NULL,
 	 ProductionAmount decimal(10,2) NULL,
 	 ProductionEngineeringUnits varchar(25) NULL,
 	 ConformancePercent real NULL,
 	 RatePercent real NULL,
/* 	 RatePercentOld real null,*/
 	 RunTime varchar(25) NULL,
 	 DowntimePercent real NULL,
 	 WastePercent real NULL,
 	 ProductID int NULL,
  UnitList varchar(255) NULL
)
create table #OEEStats (
   	 Actual_Speed real,
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
 	 OEE 	 real
)
--*****************************************************/
--Build List Of Production Starts We Need
--*****************************************************/
Create Table #ProductionStarts (
  UnitId int,
  ProductId int,
  StartTime datetime,
  EndTime datetime
)
Insert Into #ProductionStarts
  Select UnitId = ps.pu_id,
         ProductId = ps.prod_id,
         StartTime = case when ps.Start_Time < @StartTime Then @StartTime else ps.Start_Time End,
         EndTime = case when ps.end_time is null then @EndTime when ps.end_Time > @EndTime Then @EndTime else ps.End_Time End
    From Production_Starts ps
    Where ps.PU_Id in (Select UnitId From #Units) and
          ps.Start_Time >= @StartTime and
          ps.start_Time < @EndTime
Insert Into #ProductionStarts
  Select UnitId = ps.pu_id,
         ProductId = ps.prod_id,
         StartTime = case when ps.Start_Time < @StartTime Then @StartTime else ps.Start_Time End,
         EndTime = case when ps.end_time is null then @EndTime when ps.end_Time > @EndTime Then @EndTime else ps.End_Time End
    From Production_Starts ps
    Where ps.PU_Id in (Select UnitId From #Units) and
          ps.Start_Time = (Select max(Production_Starts.Start_Time) From Production_Starts Where Production_Starts.PU_Id = ps.PU_Id and Production_Starts.Start_Time < @StartTime) and
          ((ps.End_Time > @StartTime) or (ps.End_Time Is Null))
--*****************************************************/
 	 declare @curPU_Id int, @curProductId int, @curStart datetime, @curEnd datetime
 	 Declare PRODUCTIVETIME_CURSOR INSENSITIVE CURSOR
   	 For (
      	 Select UnitId, ProductId, StartTime, EndTime From #ProductionStarts
       	 )
  	  For Read Only
if (@FilterNonProductiveTime = 1)
begin
   	 Open PRODUCTIVETIME_CURSOR
 	 BEGIN_PRODUCTIVETIME_CURSOR1:
 	 Fetch Next From PRODUCTIVETIME_CURSOR Into @curPU_Id, @curProductId, @curStart, @curEnd
 	 While @@Fetch_Status = 0
 	 Begin    
 	  	 insert into #ProductiveTimes (StartTime, EndTime)  execute spDBR_GetProductiveTimes @curPU_Id, @curStart, @curEnd
 	  	 update #ProductiveTimes set PU_Id = @curPU_Id, Product_Id = @curProductId where PU_Id is null
      	  	 GOTO BEGIN_PRODUCTIVETIME_CURSOR1
 	 End
 	 Close PRODUCTIVETIME_CURSOR
 	 delete from #ProductionStarts
 	 insert into #ProductionStarts select * from #ProductiveTimes
end
 	 Deallocate PRODUCTIVETIME_CURSOR
--*****************************************************/
If @OnlyMadeNow = 1 
  Delete From #ProductionStarts
    Where EndTime <> @EndTime
--*****************************************************/
-- Loop through Each Product
--*****************************************************/
Declare @@ProductId int
Declare @@UnitId int
Declare @@StartTime datetime
Declare @@EndTime datetime
Declare @ProductName varchar(100)
Declare @ProductCode varchar(100)
Declare @OldUnit int
Declare @UnitIds varchar(255)
Declare Product_Cursor Insensitive Cursor 
  For Select Distinct ProductId From #ProductionStarts 
  For Read Only
Open Product_Cursor
Fetch Next From Product_Cursor Into @@ProductId
While @@Fetch_Status = 0
  Begin
    Select @UnitIds = NULL
    Select @OldUnit = 0
    Select @IsBeingMadeNow = 0
 	  	 Select @AmountEngineeringUnits = ''
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
--Perforamnce Rate info
 	  	 Select @tLoadingTime = 0
 	  	 Select @tPerformanceRateProduction = 0
--
 	  	 
 	  	 Select @TotalTime = 0
 	  	 Select @tPerformanceDownTime = 0
 	  	 --*****************************************************/
 	  	 -- Get Product Information
 	  	 --*****************************************************/
    Select @ProductName = prod_desc, @ProductCode = prod_code
      From products
      Where prod_id = @@ProductId
 	  	 --*****************************************************/
 	  	 -- Loop through Each Time For Product
 	  	 --*****************************************************/
 	  	 Declare Product_Time_Cursor Insensitive Cursor 
 	  	   For Select UnitId, StartTime, EndTime From #ProductionStarts Where ProductId = @@ProductId Order By UnitId
 	  	   For Read Only
 	  	 
 	  	 Open Product_Time_Cursor
 	  	 
 	  	 Fetch Next From Product_Time_Cursor Into @@UnitId, @@StartTime, @@EndTime
 	  	 
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
 	  	  	  	  	  	 @iActualDowntimeCount OUTPUT,
 	  	  	  	  	  	 @FilterNonProductiveTime,
 	  	  	  	  	  	 @iActualLoadingTime OUTPUT,
 	  	  	  	  	  	 @iPerformanceDowntime OUTPUT
 	  	  	  	  	  	 -- 2 additional output parameters here
 	  	         Select @TotalTime = @TotalTime + datediff(second,@@StartTime, @@EndTime)
/*
 	  	  	 --This is an unnecessary duplicate call to spCMN_GetUnitStatistics
 	  	  	 delete from #OEEStats
 	  	  	  insert into #OEEStats exec spCMN_GetOEEStatistics @@UnitId, @@StartTime, @@EndTime
 	  	 
 	  	 
 	  	  	 select @iLoadingTime = Loading_Time, @iPerformanceRateProduction = (Net_Production + Waste) from #OEEStats
 	  	  	 select @tLoadingTime = @tLoadingTime + @iLoadingTime
*/
 	  	  	  	 -- Begin New Method
 	  	  	  	 Select @tLoadingTime = @TLoadingTime + @iActualLoadingTime
 	  	  	  	 Select @iPerformanceRateProduction = IsNull(@iActualProduction, 0) + IsNull(@iActualQualityLoss, 0)
 	  	  	  	 -- End New Method
 	  	  	  	 select @tPerformanceRateProduction = @tPerformanceRateProduction + @iPerformanceRateProduction
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
 	  	  	  	 Select @AmountEngineeringUnits = Case When @iAmountEngineeringUnits Is Not Null Then @iAmountEngineeringUnits Else @AmountEngineeringUnits End
 	  	  	  	 Select @ItemEngineeringUnits = Case When @iItemEngineeringUnits Is Not Null Then @iItemEngineeringUnits Else @ItemEngineeringUnits End
 	  	  	  	 Select @TimeEngineeringUnits = Case When @iTimeEngineeringUnits Is Not Null Then @iTimeEngineeringUnits Else @TimeEngineeringUnits End
        If @@EndTime = @EndTime
          Select @IsBeingMadeNow = 1
         	  	     	  	     
        If @OldUnit <> @@UnitId 
          Begin
            If @UnitIds Is NUll
              Select @UnitIds = convert(varchar(25),@@UnitId)
            Else 
              Select @UnitIds = @UnitIds + ',' + convert(varchar(25),@@UnitId)
            Select @OldUnit = @@UnitId
          End 	  	 
 	  	     
 	  	 --get loadingtime and such
 	  	  	  	 Fetch Next From Product_Time_Cursor Into @@UnitId, @@StartTime, @@EndTime
 	  	   End
 	  	 
 	  	 Close Product_Time_Cursor
 	  	 Deallocate Product_Time_Cursor  
 	  	 --*****************************************************/
 	  	 -- Do Final Calculations, Insert Into Results
 	  	 --*****************************************************/
declare @PerformanceRate real, @ActualSpeed real, @targetspeed real, @availrate real, @qualityrate real, @oee real
Select 
@ActualSpeed =Actual_Rate,
@targetspeed =Ideal_Rate,
@PerformanceRate=Performance_Rate,
@availrate=Available_Rate,
@qualityrate=Quality_Rate,
@OEE=OEE
from dbo.fnCMN_OEERates(@tActualRuntimeMinutes, @tLoadingTime, @tPerformanceDownTime, @tActualProduction, @tIdealProduction, @tActualQualityLoss)
/*select @tIdealProduction, @tTargetQualityLoss, @tTargetDowntimeLoss, @tTargetDowntimeMinutes
*/
 	  	 Insert Into #ProductProduction (IsBeingMadeNowFlag,ProductCode,ProductionItems,ProductionAmount,ProductionEngineeringUnits,ConformancePercent,RatePercent/*,RatePercentOld*/,RunTime,DowntimePercent,WastePercent,ProductID,UnitList)
 	  	  	 Select IsBeingMadeNowFlag = @IsBeingMadeNow,
 	  	  	  	  	  	  ProductCode = @ProductName + ' (' + @ProductCode + ')',
 	  	  	  	  	  	  ProductionItems = @tActualTotalItems,
  	  	  	  	  	  	  ProductionAmount = Convert(decimal(10,2), @tActualProduction),
  	  	  	  	  	  	  ProductionEngineeringUnits = @AmountEngineeringUnits,
  	  	  	  	  	  	  ConformancePercent = case when @tActualTotalItems > 0 then Convert(decimal(10,2),Convert(decimal(10,2),@tActualConformanceItems) / Convert(decimal(10,2),@tActualTotalItems) * 100.0) else 0.0 End,
 	  	  	  	  	  	  RatePercent = @PerformanceRate,
 	  	  	  	   	  
 	  	  	  	  	  	  RunTime = dbo.fnRS_MakeTimeDurationString(@tActualRuntimeMinutes),
 	  	  	  	  	  	  DowntimePercent = case when @availrate > 100 then 0.0 else 100.0 - @availrate end,
--case when (@tActualRuntimeMinutes + @tActualDowntimeMinutes) > 0 then @tActualDowntimeMinutes / (@tActualRuntimeMinutes + @tActualDowntimeMinutes) * 100.0 else 0.0 End,
 	  	  	  	  	  	  WastePercent = case when @qualityrate > 100 then 0.0 when @tActualProduction > 0 then 100.0 - @qualityrate else 0.0 end,
--Case when (@tActualQualityLoss + @tActualProduction) > 0 then @tActualQualityLoss / (@tActualQualityLoss + @tActualProduction) * 100.0 Else 0.0 End,
 	  	  	  	  	  	  ProductID = @@ProductId,
 	  	  	  	  	    UnitList = @UnitIds
 	  	 Fetch Next From Product_Cursor Into @@ProductId
  End
Close Product_Cursor
Deallocate Product_Cursor  
--*****************************************************/
--Return Header and Translation Information
--*****************************************************/
 	 EXECUTE spDBR_GetColumns @ColumnVisibility
--*****************************************************/
--Return Results
--*****************************************************/
select * 
  from #ProductProduction
  order by ProductCode
drop table #ProductProduction
drop table #Units
drop table #ProductionStarts
drop table #ProductiveTimes
drop table #OEEStats
