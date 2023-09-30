﻿CREATE Procedure dbo.spDBR_LineEfficiencyStatistics
@LineList 	  	 text = NULL, --<_x0023_paramvalue Row="1" Col="1" Presentation="1" SPName="spDBR_Get_Line_Name" Value="Production Line #1" Header="38186"/><_x0023_paramvalue Row="1" Col="2" Presentation="0" Value="2" Header="38187"/></Root>', 
@StartTime 	  	 datetime = NULL, --'2004-06-21 07:00:00', --
@EndTime 	  	 datetime = NULL, --'2004-07-21 07:00:00' --
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
AS
SET ANSI_WARNINGS off
/*****************************************************
-- For Testing
--*****************************************************
Declare @LineList varchar(1000)
Declare @StartTime datetime
Declare @EndTime datetime
Select @StartTime = dateadd(day,-3,getdate())
Select @EndTime = getdate()
Select @LineList = '<Root></Root>'
--*****************************************************/
Declare @AmountEngineeringUnits varchar(50)
Declare @ItemEngineeringUnits varchar(50)
DEclare @TimeEngineeringUnits int
Declare @Hyperlink varchar(2000)
Declare @UnitList varchar(2000)
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
Declare @HostName varchar(255)
Declare @VirtualDirectory1 varchar(255)
Declare @VirtualDirectory2 varchar(255)
Select @HostName = value from site_parameters where parm_id = 27
Select @VirtualDirectory1 = value from site_parameters where parm_id = 30
Select @VirtualDirectory2 = 'ProficyDashBoard/'
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
       Select pl_id From prod_lines where pl_id > 0
  End
--*****************************************************
-- Loop Through Lines, Get Production Statistics
--****************************************************
Declare @@LineId int
Declare @Unit int
Select @UnitList = NULL
Declare Statistics_Cursor Insensitive Cursor 
  For Select LineId From #Lines
  For Read Only
Open Statistics_Cursor
Fetch Next From Statistics_Cursor Into @@LineId
While @@Fetch_Status = 0
  Begin
 	  	 Declare Unit_Cursor Insensitive Cursor 
 	  	   For Select distinct u.PU_Id 
            From Prod_Units u
            Join prod_events e on e.pu_id = u.pu_id and e.event_type in (1,2,3)
            where u.PL_Id = @@LineId and 
                  u.Master_Unit Is Null and 
                  u.pl_id > 0
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
    Close unit_cursor
    Deallocate unit_cursor
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
    Select @tActualDowntimeCount = @tActualDowntimeCount + coalesce(@iActualDowntimeCount,0)
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
create table #EfficiencyStatistics
(
 	 VarName varchar(50) NULL,
-- 	 Value varchar(25) NULL,
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
 	 HREFLink varchar(1000) NULL, 
 	 AltText decimal(10,1) NULL,
 	 Units varchar(25) NULL,
 	 ChartMin decimal(10,1) NULL,
 	 ChartMax decimal(10,1) NULL
)
--Select @Hyperlink = 'http://' + @Hostname + '/' + @VirtualDirectory1 + 'MainFrame.aspx?Control=Applications/Line+Time+Accounting/LineTimeAccounting.ascx'
--Select @Hyperlink = @Hyperlink + '&StartTime=' + convert(varchar(17),@StartTime,109)
--Select @Hyperlink = @Hyperlink + '&EndTime=' + convert(varchar(17),@EndTime, 109)
--Select @Hyperlink = @Hyperlink + '&Line=' + convert(varchar(25),@@LineId)
Select @Hyperlink = 'WA^Applications/Line Time Accounting/LineTimeAccounting.ascx' 
Select @Hyperlink = @Hyperlink + '@StartTime^' + convert(varchar(17),@StartTime,109)
Select @Hyperlink = @Hyperlink + '@EndTime^' + convert(varchar(17),@EndTime, 109)
Select @Hyperlink = @Hyperlink + '@Line^' + convert(varchar(25),@@LineId)
if (@tIdealProduction > 0)
begin
declare @Act decimal, @targ decimal, @warn decimal, @reject decimal
if (@tIdealProduction > 0)
begin
 	 select @Act = @tActualPercentOEE / @tIdealProduction
 	 select @targ = @tTargetPercentOEE / @tIdealProduction
 	 select @warn = @tWarningPercentOEE / @tIdealProduction
 	 select @reject = @tRejectPercentOEE / @tIdealProduction
end
else
begin
 	 select @Act = 0;
 	 select @targ = 0;
 	 select @warn = 0;
 	 select @reject = 0;
end
Insert Into #EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units, ChartMin, ChartMax)
  Select VarName = dbo.fnDBTranslate(N'0', 38362, 'Percent OEE'),
         Value = case when @tIdealProduction > 0 then convert(decimal(10,1), @act)else 0 end,
         Target = case when @tIdealProduction > 0 then convert(decimal(10,1),@targ) else 0 end,
         UR = null,
         UW = null,
         LW = case when @tIdealProduction > 0 then convert(decimal(10,1),@warn) else 0.0 end,
         LR = case when @tIdealProduction > 0 then convert(decimal(10,1),@reject) else 0.0 end,
         HREFLink = @Hyperlink,
         AltText = NULL,
         Units = '%',
 	  ChartMin = 0,
 	  ChartMax = 100
end
else
begin
Insert Into #EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units , ChartMin, ChartMax)
  Select VarName = dbo.fnDBTranslate(N'0', 38362, 'Percent OEE'),
         Value = Null,
         Target = Null,
         UR = 100.0,
         UW = 100.0,
         LW = 0.0,
         LR = 0.0,
         HREFLink = Null,
         AltText = 0.0,
         Units = '%',
 	  ChartMin = 0,
 	  ChartMax = 100
end
Insert Into #EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units)
  Select VarName = dbo.fnDBTranslate(N'0', 38363, 'Net Rate'),
         Value = NULL,
         Target = NULL,
         UR = NULL,
         UW = NULL,
         LW = NULL,
         LR = NULL,
         HREFLink = NULL,
         AltText = Case
                     When (@tActualTotalMinutes - @tActualUnavailableMinutes) <= 0 Then
                       0.0 
 	  	  	  	  	  	  	  	  	    When @iTimeEngineeringUnits = 0 Then -- /hour
                       convert(decimal(10,1),(@tActualProduction) / (@tActualTotalMinutes - @tActualUnavailableMinutes) * 60.0)
 	  	  	  	  	  	  	  	  	    When @iTimeEngineeringUnits = 2 Then -- /second
                       convert(decimal(10,1),(@tActualProduction) / (@tActualTotalMinutes - @tActualUnavailableMinutes) / 60.0)
 	  	  	  	  	  	  	  	  	    When @iTimeEngineeringUnits = 3 Then -- /day
                       convert(decimal(10,1),(@tActualProduction) / (@tActualTotalMinutes - @tActualUnavailableMinutes) * 1440.0)
 	  	  	  	  	  	  	  	  	  	  Else -- /min
                       convert(decimal(10,1),(@tActualProduction) / (@tActualTotalMinutes - @tActualUnavailableMinutes))
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
--Select @Hyperlink = 'http://' + @Hostname + '/' + @VirtualDirectory2 + '/MSWebPart.aspx?TemplateName=Downtime+Distribution+Charts+By+Units&TemplateVersion=1'
--Select @Hyperlink = @Hyperlink + '&StartTime=' + convert(varchar(17),@StartTime,109)
--Select @Hyperlink = @Hyperlink + '&EndTime=' + convert(varchar(17),@EndTime, 109)
--Select @Hyperlink = @Hyperlink + '&Units=' + @UnitList
Select @Hyperlink = 'DB^38043@V^1'
Select @Hyperlink = @Hyperlink + '@38239^' + convert(varchar(17),@StartTime,109)
Select @Hyperlink = @Hyperlink + '@38240^' + convert(varchar(17),@EndTime, 109)
Select @Hyperlink = @Hyperlink + '@38130^' + @UnitList
if (@tActualDowntimeMinutes + @tActualRuntimeMinutes > 0)
begin
Insert Into #EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units, Chartmin, chartmax)
  Select VarName = dbo.fnDBTranslate(N'0', 38368, 'Percent Downtime'),
--         Value = case when (@tActualDowntimeMinutes + @tActualRuntimeMinutes) > 0 then convert(varchar(25),convert(decimal(10,1),@tActualDowntimeMinutes / (@tActualDowntimeMinutes + @tActualRuntimeMinutes) * 100.0)) else Null end,
         Value = case when (@tActualDowntimeMinutes + @tActualRuntimeMinutes) > 0 then convert(decimal(10,1),@tActualDowntimeMinutes / (@tActualDowntimeMinutes + @tActualRuntimeMinutes) * 100.0) else Null end,
         Target = Case when @tTargetDowntimeMinutes <= @tWarningDowntimeMinutes Then convert(decimal(10,1),@tTargetDowntimeMinutes / (@tActualDowntimeMinutes + @tActualRuntimeMinutes)* 100.0) Else Null End,
         UR = Case When @tRejectDowntimeMinutes > @tWarningDowntimeMinutes then convert(decimal(10,1),@tRejectDowntimeMinutes / (@tActualDowntimeMinutes + @tActualRuntimeMinutes)* 100.0) Else 100.0 End,
         UW = case when (@tActualDowntimeMinutes + @tActualRuntimeMinutes) > 0 then convert(decimal(10,1),@tWarningDowntimeMinutes / (@tActualDowntimeMinutes + @tActualRuntimeMinutes)* 100.0) else 100.0 end,
         LW = null,
         LR = null,
         HREFLink = @Hyperlink,
         AltText = NULL,
         Units = '%',
         chartmin = 0,
 	  chartmax = 100
end
else
begin
Insert Into #EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units, chartmin, chartmax)
  Select VarName = dbo.fnDBTranslate(N'0', 38368, 'Percent Downtime'),
         Value = Null,
         Target = NULL,
         UR = 100.0,
         UW = 100.0,
         LW = 0.0,
         LR = 0.0,
         HREFLink = Null,
         AltText = NULL,
         Units = '%',
 	  chartmin = 0,
 	  chartmax = 100
end
Select @Hyperlink = 'DB^38134@V^1'
Select @Hyperlink = @Hyperlink + '@38239^' + convert(varchar(17),@StartTime,109)
Select @Hyperlink = @Hyperlink + '@38240^' + convert(varchar(17),@EndTime, 109)
Select @Hyperlink = @Hyperlink + '@38130^' + @UnitList
if(@tActualQualityLoss + @tActualProduction > 0)
begin
Insert Into #EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units, chartmin, chartmax)
  Select VarName = dbo.fnDBTranslate(N'0', 38369, 'Percent Waste'),
         Value = case when (@tActualQualityLoss + @tActualProduction) > 0 then convert(decimal(10,1),@tActualQualityLoss / (@tActualQualityLoss + @tActualProduction)*100.0) else Null end,
         Target = Case When @tTargetQualityLoss <= @tWarningQualityLoss Then convert(decimal(10,1),@tTargetQualityLoss / (@tActualQualityLoss + @tActualProduction)*100.0) Else Null End,
         UR = Case When @tRejectQualityLoss > @tWarningQualityLoss Then convert(decimal(10,1),@tRejectQualityLoss / (@tActualQualityLoss + @tActualProduction)*100.0) Else 100.0 End,
         UW = case when (@tActualQualityLoss + @tActualProduction) > 0 then convert(decimal(10,1),@tWarningQualityLoss / (@tActualQualityLoss + @tActualProduction)*100.0) else 100.0 end,
         LW = null,
         LR = null,
         HREFLink = @Hyperlink,
         AltText = Null,
         Units = '%',
         chartmin = 0,
 	  chartmax = 100
end
else
begin
Insert Into #EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units,chartmin, chartmax)
  Select VarName = dbo.fnDBTranslate(N'0', 38369, 'Percent Waste'),
         Value = Null,
         Target = Null,
         UR = 100.0,
         UW = 100.0,
         LW = 0.0,
         LR = 0.0,
         HREFLink = Null,
         AltText = 0.0,
         Units = '%',
 	  chartmin = 0,
 	  chartmax = 100
end
--*****************************************************/
--Attempt To Auto Scale
--*****************************************************/
Update #EfficiencyStatistics
  Set ChartMin = Case
                   When Value < coalesce(LR, LW, Target, UW, UR) Then Value - 0.15 * Value
                   When Value >= coalesce(LR, LW, Target, UW, UR) Then coalesce(LR, LW, Target, UW, UR) - 0.15 * coalesce(LR, LW, Target, UW, UR)
                   Else 0
                 End,
      ChartMax = Case 
                   When Value > coalesce(UR, UW, Target, LW, LR) Then Value + 0.15 * Value
                   When Value <= coalesce(UR, UW, Target, LW, LR) Then coalesce(UR, UW, Target, LW, LR) + 0.15 * coalesce(UR, UW, Target, LW, LR)
                   Else 100
                 End
  Where Value Is Not Null
--*****************************************************/
--Return Results
--*****************************************************/
select * from #EfficiencyStatistics
drop table #EfficiencyStatistics
drop table #Lines
