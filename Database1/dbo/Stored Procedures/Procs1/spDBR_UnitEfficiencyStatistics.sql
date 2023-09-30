CREATE Procedure dbo.spDBR_UnitEfficiencyStatistics
@UnitId int  	  	 = NULL,
@StartTime datetime = NULL,
@EndTime datetime = NULL ,
@FilterNonProductiveTime int = 0,
@InTimeZone 	  	 varchar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time' 
AS
--****************************************************/
set arithignore on
set arithabort off
set ansi_warnings off
-------------------------------------------------
-- Local Variables
-------------------------------------------------
Declare @ProdVar int, @@LineId INT
Declare @HostName varchar(255), @VirtualDirectory1 varchar(255), @VirtualDirectory2 varchar(255)
Declare @iWaste FLOAT, @iIdealProduction FLOAT, @iActualProduction FLOAT, @iActualRuntimeMinutes FLOAT, @ActualLoadingTimeMinutes FLOAT,
@unit_Waste FLOAT, @unit_Ideal_Production FLOAT, @unit_Actual_Production FLOAT, @unit_Run_time FLOAT, @unit_Loading_Time FLOAT, @Hyperlink varchar(2000)
Declare  @ActualRunTimeMinutes int, @PerformanceRate FLOAT, @AvailRate FLOAT, @QualityRate FLOAT, @OEE FLOAT
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
-------------------------------------------------
-- Get Production Line and Efficiency Var
-------------------------------------------------
select 
       @ProdVar = Production_Variable,
       @@LineId = pl_id
from Prod_Units 
where pu_id = @UnitId
-------------------------------------------------
-- Get Virtual Directory and Host Name
-------------------------------------------------
Select @HostName = value from site_parameters where parm_id = 27
Select @VirtualDirectory1 = value from site_parameters where parm_id = 30
Select @VirtualDirectory2 = 'ProficyDashBoard/'
------------------------------------------------------
-- Variables used to call spCMN_GetUnitStatistics
------------------------------------------------------
Declare   
@iIdealYield FLOAT, @iActualQualityLoss FLOAT,  @iActualYieldLoss FLOAT, @iActualSpeedLoss FLOAT,@iActualDowntimeLoss FLOAT,    @iActualDowntimeMinutes FLOAT,@iActualUnavailableMinutes FLOAT,@iActualTotalMinutes FLOAT,    
@iActualPercentOEE FLOAT,@iActualTotalItems int,       @iActualGoodItems int,@iActualBadItems int,@iActualConformanceItems int,
@iTargetProduction FLOAT, @iWarningProduction FLOAT, @iRejectProduction FLOAT, @iTargetQualityLoss FLOAT,     @iWarningQualityLoss FLOAT,  @iRejectQualityLoss FLOAT,    @iTargetDowntimeLoss FLOAT,
@iWarningDowntimeLoss FLOAT, @iRejectDowntimeLoss FLOAT,     @iTargetDowntimeMinutes FLOAT,        @iWarningDowntimeMinutes FLOAT,     @iRejectDowntimeMinutes FLOAT,      @iTargetPercentOEE FLOAT,      @iWarningPercentOEE FLOAT,
@iRejectPercentOEE FLOAT,      @iAmountEngineeringUnits varchar(25),     @iItemEngineeringUnits varchar(25),        @iTimeEngineeringUnits int,  @iStatus int,@iScheduleDeviationMinutes FLOAT,@iActualDowntimeCount int,
@iActualSpeed FLOAT, @iTargetSpeed FLOAT, @TotalPerformanceDTMinutes FLOAT
-----------------------------------------------------------------
-- Call Unit Statistics Directly
-----------------------------------------------------------------
execute spCMN_GetUnitStatistics @UnitId, @StartTime,@EndTime,
        @iIdealProduction OUTPUT,  @iIdealYield OUTPUT, @iActualProduction OUTPUT, @iActualQualityLoss OUTPUT, @iActualYieldLoss OUTPUT, @iActualSpeedLoss OUTPUT,
           @iActualDowntimeLoss OUTPUT, @iActualDowntimeMinutes OUTPUT, @iActualRuntimeMinutes OUTPUT, @iActualUnavailableMinutes OUTPUT, @iActualSpeed OUTPUT,
           @iActualPercentOEE OUTPUT, @iActualTotalItems OUTPUT, @iActualGoodItems OUTPUT, @iActualBadItems OUTPUT, @iActualConformanceItems OUTPUT,
           @iTargetProduction OUTPUT, @iWarningProduction OUTPUT, @iRejectProduction OUTPUT, @iTargetQualityLoss OUTPUT,    @iWarningQualityLoss OUTPUT,@iRejectQualityLoss OUTPUT,
             @iTargetDowntimeLoss OUTPUT,@iWarningDowntimeLoss OUTPUT,@iRejectDowntimeLoss OUTPUT,@iTargetSpeed OUTPUT,@iTargetDowntimeMinutes OUTPUT,
             @iWarningDowntimeMinutes OUTPUT,@iRejectDowntimeMinutes OUTPUT,  @iTargetPercentOEE OUTPUT,     @iWarningPercentOEE OUTPUT,  @iRejectPercentOEE OUTPUT,    
             @iAmountEngineeringUnits OUTPUT,@iItemEngineeringUnits OUTPUT,@iTimeEngineeringUnits OUTPUT,@iStatus OUTPUT,@iActualDowntimeCount OUTPUT
             , @FilterNonProductiveTime, @ActualLoadingTimeMinutes OUTPUT, @TotalPerformanceDTMinutes OUTPUT
--------------------------------------------------------------------
-- Get Loading and Running Time
--------------------------------------------------------------------
/*
Select 
       @ActualLoadingTimeMinutes = (LoadingSeconds/60.0),
       @ActualRunTimeMinutes = (RunningSeconds/60.0)  
From dbo.fnCMN_GetOutsideAreaTimeByUnit(@StartTime, @EndTime, @UnitId, @FilterNonProductiveTime)
*/
Select @ActualRunTimeMinutes = @iActualRuntimeMinutes
--------------------------------------------------------------------
-- Get OEE Data From Key Parameters
-- OEE by Efficiency Variable will be accounted for
--------------------------------------------------------------------
Select 
       @iActualSpeed = Actual_Rate,
       @iTargetSpeed = Ideal_Rate,
       @PerformanceRate = Performance_Rate,
       @AvailRate = Available_Rate,
       @QualityRate = Quality_Rate,
       @OEE = @iActualPercentOEE
from dbo.fnCMN_OEERates(@ActualRuntimeMinutes, @ActualLoadingTimeMinutes, @TotalPerformanceDTMinutes, @iActualProduction, @iIdealProduction, @iActualQualityLoss)
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
Select @iActualSpeed = Case
       When @iTimeEngineeringUnits = 0 Then @iActualSpeed * 60.0 
       When @iTimeEngineeringUnits = 2 Then @iActualSpeed / 60.0
       When @iTimeEngineeringUnits = 3 Then @iActualSpeed * 1440
       Else @iActualSpeed End
Select @iTargetSpeed = Case
       When @iTimeEngineeringUnits = 0 Then @iTargetSpeed * 60.0 
       When @iTimeEngineeringUnits = 2 Then @iTargetSpeed / 60.0
       When @iTimeEngineeringUnits = 3 Then @iTargetSpeed * 1440
       Else @iTargetSpeed End
-------------------------------------------------------
-- Insert Results
-------------------------------------------------------
Declare @EfficiencyStatistics TABLE
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
       HREFLink varchar(1000) NULL, 
       AltText decimal(10,1) NULL,
       Units varchar(25) NULL,
       ChartMin decimal(10,1) NULL,
       ChartMax decimal(10,1) NULL
)
-------------------------------------------------------
-- Percent OEE
-------------------------------------------------------
Select @Hyperlink = 'DB^38481@V^1'
Select @Hyperlink = @Hyperlink + '@38239^' + convert(varchar(100),dbo.fnServer_CmnConvertFromDbTime(@StartTime,@InTimeZone),109)
Select @Hyperlink = @Hyperlink + '@38240^' + convert(varchar(100),dbo.fnServer_CmnConvertFromDbTime(@EndTime,@InTimeZone), 109)
Select @Hyperlink = @Hyperlink + '@38130^' + convert(varchar(100),@UnitId)
Select @Hyperlink = @Hyperlink + '@38517^' + @InTimeZone 
if (@iIdealProduction > 0)
       begin
             Insert Into @EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units, ChartMin, ChartMax)
                   Select VarName = dbo.fnDBTranslate(N'0', 38362, 'Percent OEE'),
                          Value = @OEE,
                          Target = 100.0, --@iTargetPercentOEE,
                          UR = 100.0,
                          UW = 100.0,
                          LW = 0.0 ,  --@iWarningPercentOEE,
                          LR = 0.0,   --@iRejectPercentOEE,
                          HREFLink = @Hyperlink,
                          AltText = NULL,
                          Units = '%',
                          ChartMin = 0,
                          ChartMax = 100
       end
else
       begin
             Insert Into @EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units , ChartMin, ChartMax)
                   Select VarName = dbo.fnDBTranslate(N'0', 38362, 'Percent OEE'),
                          Value = @OEE,
                          Target = 100.0,
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
-------------------------------------------------------
-- Performance Rate
-------------------------------------------------------
Select @Hyperlink = 'DB^38474@V^1'
Select @Hyperlink = @Hyperlink + '@38239^' + convert(varchar(100),dbo.fnServer_CmnConvertFromDbTime(@StartTime,@InTimeZone),109)
Select @Hyperlink = @Hyperlink + '@38240^' + convert(varchar(100),dbo.fnServer_CmnConvertFromDbTime(@EndTime,@InTimeZone), 109)
Select @Hyperlink = @Hyperlink + '@38130^' + convert(varchar(100),@UnitId)
Select @Hyperlink = @Hyperlink + '@38517^' + @InTimeZone 
Insert Into @EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units,Chartmin, chartmax)
  Select VarName = dbo.fnDBTranslate(N'0', 38469, 'Performance Rate'),
         Value = @PerformanceRate,
         Target = 100.0,
 	  	  UR = 100.0,
 	  	  UW = 100.0,
 	  	  LW = 0,
 	  	  LR = 0,
         HREFLink = @Hyperlink,
         AltText = NULL,                   
         Units =   '%',
         chartmin = 0,
         chartmax = 100 
-------------------------------------------------------
-- Availability Rate
-------------------------------------------------------
Select @Hyperlink = 'DB^38480@V^1'
Select @Hyperlink = @Hyperlink + '@38239^' + convert(varchar(100),dbo.fnServer_CmnConvertFromDbTime(@StartTime,@InTimeZone),109)
Select @Hyperlink = @Hyperlink + '@38240^' + convert(varchar(100),dbo.fnServer_CmnConvertFromDbTime(@EndTime,@InTimeZone), 109)
Select @Hyperlink = @Hyperlink + '@38130^' + convert(varchar(100),@UnitId)
Select @Hyperlink = @Hyperlink + '@38517^' + @InTimeZone 
If @iTargetDowntimeMinutes is null 
 	 select @iTargetDowntimeMinutes = 0
if (@iActualDowntimeMinutes + @iActualRuntimeMinutes > 0)
       begin
             Insert Into @EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units, Chartmin, chartmax)
                   Select VarName = dbo.fnDBTranslate(N'0', 38472, 'Availability Rate'),
                          Value = @AvailRate, --case when (@iActualDowntimeMinutes + @iActualRuntimeMinutes) > 0 then convert(decimal(10,1),@iActualDowntimeMinutes / (@iActualDowntimeMinutes + @iActualRuntimeMinutes) * 100.0) else Null end,
                          Target = Case when (@iActualDowntimeMinutes + @iActualRuntimeMinutes) > 0  Then convert(decimal(10,1),(1-(@iTargetDowntimeMinutes / (@iActualDowntimeMinutes + @iActualRuntimeMinutes)))* 100.0) Else Null End,
                          UR = 100,
                          UW = 100,
                          LW = 0,
                          LR = 0,
                          HREFLink = @Hyperlink,
                          AltText = NULL,
                          Units = '%',
                          chartmin = 0,
                          chartmax = 100
       end
else
       begin
             Insert Into @EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units, chartmin, chartmax)
                   Select VarName = dbo.fnDBTranslate(N'0', 38472, 'Availability Rate'),
                          Value = @AvailRate,
                          Target = 100.0,
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
-------------------------------------------------------
-- Quality Rate
-------------------------------------------------------
Select @Hyperlink = 'DB^38134@V^1'
Select @Hyperlink = @Hyperlink + '@38239^' + convert(varchar(100),dbo.fnServer_CmnConvertFromDbTime(@StartTime,@InTimeZone),109)
Select @Hyperlink = @Hyperlink + '@38240^' + convert(varchar(100),dbo.fnServer_CmnConvertFromDbTime(@EndTime,@InTimeZone), 109)
Select @Hyperlink = @Hyperlink + '@38130^' + convert(varchar(100),@UnitId)
Select @Hyperlink = @Hyperlink + '@38517^' + @InTimeZone 
if(@iActualQualityLoss + @iActualProduction > 0)
       begin
             Insert Into @EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units, chartmin, chartmax)
                   Select VarName = dbo.fnDBTranslate(N'0', 38470, 'Quality Rate'),
                          Value = @QualityRate, -- case when (@iActualQualityLoss + @iActualProduction) > 0 then convert(decimal(10,1),@iActualQualityLoss / (@iActualQualityLoss + @iActualProduction)*100.0) else Null end,
                          --Target = Case When (@iActualQualityLoss + @iActualProduction) > 0 Then convert(decimal(10,1),1-(@iTargetQualityLoss / (@iActualQualityLoss + @iActualProduction)) * 5.0) Else 100.0 End,
                          Target = Case When (@iActualQualityLoss + @iActualProduction) > 0 Then (@iActualProduction / @iActualProduction + @iActualQualityLoss) * 100.0 Else 100.0 End,
 	  	  	   UR = 100,
                          UW = 100,
                          LW = 0,
                          LR = 0,
                          HREFLink = @Hyperlink,
                          AltText = Null,
                          Units = '%',
                          chartmin = 0,
                          chartmax = 100
       end
else
       begin
             Insert Into @EfficiencyStatistics (VarName,Value,Target,UR,UW,LW,LR,HREFLink,AltText,Units,chartmin, chartmax)
                   Select VarName = dbo.fnDBTranslate(N'0', 38470, 'Quality Rate'),
                          Value = @QualityRate,
                          Target = 100,
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
-------------------------------------------------------
--Attempt To Auto Scale
-------------------------------------------------------
/*
Update @EfficiencyStatistics
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
*/
-------------------------------------------------------
--Return Results
-------------------------------------------------------
select * from @EfficiencyStatistics
