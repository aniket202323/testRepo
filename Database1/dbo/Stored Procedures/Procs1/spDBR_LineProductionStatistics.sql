CREATE Procedure dbo.spDBR_LineProductionStatistics
@LineList 	  	 text = NULL,
@StartTime 	  	 datetime = NULL,
@EndTime 	  	 datetime = NULL,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
AS
SET ANSI_WARNINGS off
/*****************************************************
-- For Testing
--*****************************************************
Declare @LineList varchar(1000)
Declare @StartTime datetime
Declare @EndTime datetime
Select @StartTime = '1/1/2000'
Select @EndTime = '1/1/2004'
Select @LineList = '<Root></Root>'
--*****************************************************/
Declare @AmountEngineeringUnits varchar(50)
Declare @ItemEngineeringUnits varchar(50)
DEclare @TimeEngineeringUnits int
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
-- Loop Through Lines, Get Production Statistics
--*****************************************************
Declare @@LineId int
Declare Statistics_Cursor Insensitive Cursor 
  For Select LineId From #Lines
  For Read Only
Open Statistics_Cursor
Fetch Next From Statistics_Cursor Into @@LineId
While @@Fetch_Status = 0
  Begin
 	  	 execute spCMN_GetLineStatistics
 	  	  	  	 @@LineId,
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
 	  	 Select @AmountEngineeringUnits = Case When @iAmountEngineeringUnits Is Not Null Then @iAmountEngineeringUnits Else @AmountEngineeringUnits End
 	  	 Select @ItemEngineeringUnits = Case When @iItemEngineeringUnits Is Not Null Then @iItemEngineeringUnits Else @ItemEngineeringUnits End
 	  	 Select @TimeEngineeringUnits = Case When @iTimeEngineeringUnits Is Not Null Then @iTimeEngineeringUnits Else @TimeEngineeringUnits End
 	   Select @tIdealYield = @tIdealYield + coalesce(@iIdealYield,0)
 	  	       	  	           
 	  	 Fetch Next From Statistics_Cursor Into @@LineId
  End
Close Statistics_Cursor
Deallocate Statistics_Cursor  
--*****************************************************/
-- Insert Results
--*****************************************************/
create table #ProductionStatistics
(
 	 VarName varchar(50) NULL,
 	 Value decimal(10,1) NULL,
 	 Target decimal(10,1) NULL,
 	 UR decimal(10,1) NULL,
 	 UW decimal(10,1) NULL,
 	 LW decimal(10,1) NULL,
 	 LR decimal(10,1) NULL,
 	 TargetColor varchar(25) NULL Default '#8888ff',
 	 WarningColor varchar(25) NULL Default '#ffff88',
 	 RejectColor varchar(25) NULL Default '#ff8888',
 	 BorderColor varchar(25) NULL Default 'black',
 	 TextColor varchar(25) NULL Default 'black',
 	 HREFLink varchar(100) NULL, 
 	 AltText varchar(50) NULL,
 	 Units varchar(25) NULL,
 	 ChartMin decimal(10,1) NULL,
 	 ChartMax decimal(10,1) NULL
)
Insert Into #ProductionStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units, chartmin, chartmax)
  Select VarName = dbo.fnDBTranslate(N'0', 38273, 'Production'),
         Value = @tActualProduction,
         Target = @tTargetProduction,
         UR = NULL,
         UW = NULL,
         LW = @tWarningProduction,
         LR = @tRejectProduction,
         HREFLink = NULL,
         AltText = NULL,
         Units = @AmountEngineeringUnits,
 	  chartmin = 0,
 	  chartmax = @tTargetProduction + .1 * @tTargetProduction
Insert Into #ProductionStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units)
  Select VarName = dbo.fnDBTranslate(N'0', 38363, 'Net Rate'),
         Value = NULL,
         Target = NULL,
         UR = NULL,
         UW = NULL,
         LW = NULL,
         LR = NULL,
         HREFLink = NULL,
         AltText = Case
                      	 When (@tActualTotalMinutes - @tActualUnavailableMinutes) = 0 Then
                        	  	 0.0
 	  	  	 When @iTimeEngineeringUnits = 0 Then -- /hour
                        	  	 @tActualProduction / (@tActualTotalMinutes - @tActualUnavailableMinutes) * 60.0
 	  	  	 When @iTimeEngineeringUnits = 2 Then -- /second
                        	  	 @tActualProduction / (@tActualTotalMinutes - @tActualUnavailableMinutes) / 60.0
 	  	  	 When @iTimeEngineeringUnits = 3 Then -- /day
                        	  	 @tActualProduction / (@tActualTotalMinutes - @tActualUnavailableMinutes) * 1440.0
 	  	  	 Else -- /min
                        	  	 @tActualProduction / (@tActualTotalMinutes - @tActualUnavailableMinutes)
 	  	  	 End,  	  	  	  	 
         Units =   Case
 	  	  	 When @iTimeEngineeringUnits = 0 Then -- /hour
                      	  	 @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38364, 'hr') 
 	  	  	 When @iTimeEngineeringUnits = 2 Then -- /second
                      	  	 @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38366, 'sec') 
 	  	  	 When @iTimeEngineeringUnits = 3 Then -- /day
                      	  	 @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38367, 'day') 
 	  	  	 Else -- /min
                      	  	 @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38365, 'min') 
  	  	  	 End
Insert Into #ProductionStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units)
  Select VarName = dbo.fnDBTranslate(N'0', 38435, 'Schedule Deviation'),
         Value = NULL,
         Target = '0.0',
         UR = NULL,
         UW = NULL,
         LW = NULL,
         LR = NULL,
         HREFLink = NULL,
         AltText =  Case
                       --When @tScheduleDeviationMinutes < 0 Then '<font color=red><b>' + '-' + convert(varchar(25),floor(-1 * coalesce(@tScheduleDeviationMinutes / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, -1 * @tScheduleDeviationMinutes) % 60 ,0)),2) +  '</b></font>'
                       When @tScheduleDeviationMinutes < 0 Then 
 	  	  	  	 '-' + convert(varchar(25),floor(-1 * coalesce(@tScheduleDeviationMinutes / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, -1 * @tScheduleDeviationMinutes) % 60 ,0)),2)
                       Else 
 	  	  	  	 '+' + convert(varchar(25),floor(coalesce(@tScheduleDeviationMinutes / 60.0 ,0))) + ':' + right ('0' + convert(varchar(25),coalesce(convert(int, @tScheduleDeviationMinutes) % 60 ,0)),2)
                     	 End,  
         Units = 'minutes'
Insert Into #ProductionStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units)
  Select VarName = dbo.fnDBTranslate(N'0', 38274, 'Speed'),
         Value = NULL,
         Target = Case
 	  	 When (@tActualTotalMinutes - @tTargetDowntimeMinutes) <= 0 then
 	  	  	 0.0
 	  	 When @iTimeEngineeringUnits = 0 Then -- /hour
 	  	   ((@tIdealProduction - @tTargetQualityLoss - @tTargetDowntimeLoss) / (@tActualTotalMinutes - @tTargetDowntimeMinutes) * 60.0)
 	  	 When @iTimeEngineeringUnits = 2 Then -- /second
 	  	   ((@tIdealProduction - @tTargetQualityLoss - @tTargetDowntimeLoss) / (@tActualTotalMinutes - @tTargetDowntimeMinutes) / 60.0)
 	  	 When @iTimeEngineeringUnits = 3 Then -- /day
 	  	   ((@tIdealProduction - @tTargetQualityLoss - @tTargetDowntimeLoss) / (@tActualTotalMinutes - @tTargetDowntimeMinutes) * 1440.0)
 	  	 Else
 	  	   (@tIdealProduction - @tTargetQualityLoss - @tTargetDowntimeLoss) / (@tActualTotalMinutes - @tTargetDowntimeMinutes)
 	  	 End,
         UR = NULL,
         UW = NULL,
         LW = NULL,
         LR = NULL,
         HREFLink = NULL,
         AltText = Case
                      	 When @tActualRuntimeMinutes = 0 Then
                        	  	 0.0
 	  	  	 When @iTimeEngineeringUnits = 0 Then -- /hour
                        	  	 (@tActualProduction +  @tActualYieldLoss + @tActualQualityLoss) / @tActualRuntimeMinutes * 60.0
 	  	  	 When @iTimeEngineeringUnits = 2 Then -- /second
                        	  	 (@tActualProduction +  @tActualYieldLoss + @tActualQualityLoss) / @tActualRuntimeMinutes / 60.0
 	  	  	 When @iTimeEngineeringUnits = 3 Then -- /day
                        	  	 (@tActualProduction +  @tActualYieldLoss + @tActualQualityLoss) / @tActualRuntimeMinutes * 1440.0
 	  	  	 Else -- /min
                        	  	 (@tActualProduction +  @tActualYieldLoss + @tActualQualityLoss) / @tActualRuntimeMinutes
 	  	  	 End,  	  	  	  	 
         Units =   Case
 	  	  	 When @iTimeEngineeringUnits = 0 Then -- /hour
                      	  	 @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38364, 'hr') 
 	  	  	 When @iTimeEngineeringUnits = 2 Then -- /second
                      	  	 @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38366, 'sec') 
 	  	  	 When @iTimeEngineeringUnits = 3 Then -- /day
                      	  	 @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38367, 'day') 
 	  	  	 Else -- /min
                      	  	 @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38365, 'min') 
  	  	  	 End
--*****************************************************/
--Attempt To Auto Scale
--*****************************************************/
Update #ProductionStatistics
  Set ChartMin = Case
                   When Value < coalesce(LR, LW, Target, UW, UR) Then Value - 0.15 * Value
                   When Value >= coalesce(LR, LW, Target, UW, UR) Then coalesce(LR, LW, Target, UW, UR) - 0.15 * coalesce(LR, LW, Target, UW, UR)
                   Else 0
                 End,
      ChartMax = Case 
                   When Value > coalesce(UR, UW, Target, LW, LR) Then Value + 0.15 * Value
                   When Value <= coalesce(UR, UW, Target, LW, LR) Then coalesce(UR, UW, Target, LW, LR) + 0.15 * coalesce(UR, UW, Target, LW, LR)
                   Else Value + 0.15 * Value
                 End
  Where Value Is Not Null
--*****************************************************/
--Return Results
--*****************************************************/
select * from #ProductionStatistics
drop table #ProductionStatistics
drop table #Lines
