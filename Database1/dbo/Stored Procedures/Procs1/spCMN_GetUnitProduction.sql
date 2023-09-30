CREATE Procedure dbo.spCMN_GetUnitProduction
@Unit int,
@StartTime datetime, 
@EndTime datetime,
@ReferenceProduct int, 
@ActualProduction FLOAT OUTPUT,   	  	  	 -- NET "good" production 
@ActualQualityLoss FLOAT OUTPUT, 	  	  	 -- Total of waste (NOTE: TOTAL Production = Net "good" + Waste)
@ActualYieldLoss FLOAT OUTPUT,   	  	  	 -- Theoretical loss of production from material conversion efficiency
@ActualTotalItems int OUTPUT, 	  	  	  	 -- Total number of production events made
@ActualGoodItems int OUTPUT, 	  	  	  	 -- Total number of "good" production events made
@ActualBadItems int OUTPUT, 	  	  	  	 -- Total number of "bad" production events made
@ActualConformanceItems int OUTPUT, 	  	 -- Total number of "nonconforming" production events made
@IdealYield FLOAT OUTPUT,   	  	  	  	 -- Total production if all raw material converted to finished product
@IdealRate FLOAT OUTPUT,   	  	  	  	 -- Design TOTAL production rate under 100% ideal conditions
@IdealProduction FLOAT OUTPUT,   	  	  	 -- TOTAL production  under 100% ideal conditions 
@WarningProduction FLOAT OUTPUT,   	  	  	 -- NET production that triggers warning
@RejectProduction FLOAT OUTPUT,   	  	  	 -- NET production that trigger reject
@TargetQualityLoss FLOAT OUTPUT, 	  	  	 -- Target Waste amount based on TOTAL production
@WarningQualityLoss FLOAT OUTPUT, 	  	  	 -- Warning Waste amount based on TOTAL production
@RejectQualityLoss FLOAT OUTPUT, 	  	  	 -- Reject Waste amount based on TOTAL production
@AmountEngineeringUnits varchar(25) OUTPUT,  -- Engineering Units for production amount
@ItemEngineeringUnits varchar(25) OUTPUT, 	 -- Engineering Units for production count
@TimeEngineeringUnits int OUTPUT, 	  	  	 -- Engineering Units for production RATE (per minute = default) 
@FilterNonProductiveTime int = 0,
@ActualRunningMinutes FLOAT = NULL,
@ActualLoadingTimeMinutes FLOAT = NULL,
@ActualPerformanceDTMinutes FLOAT = NULL
AS
--****************************************************************************************/
----------------------------------------------
-- Local Variables
----------------------------------------------
Declare @ProductionProperty int
Declare @ProductionCharacteristic int
Declare @ProductionSpecification int
Declare @ProductionVariable int
Declare @Ideal FLOAT
Declare @Warning FLOAT
Declare @Reject FLOAT
Declare @BalanceProperty int
Declare @BalanceCharacteristic int
Declare @BalanceVariable int
Declare @BalanceSpecification int
Declare @BalanceFactor FLOAT 
Declare @QualityProperty int
Declare @QualityCharacteristic int
Declare @QualitySpecification int
Declare @TargetPercent FLOAT
Declare @WarningPercent FLOAT
Declare @RejectPercent FLOAT
Declare @TotalProduction FLOAT
Declare @TotalWaste FLOAT
Declare @TotalBalance FLOAT
Declare @TotalTime int
Declare @Case int
Declare @ActualProductionRate FLOAT
DECLARE @TotalOutsideAreaMinutes FLOAT
DECLARE @TotalUnavailableTimeMinutes FLOAT
--DECLARE @ActualRunningMinutes FLOAT
--DECLARE @ActualLoadingTimeMinutes FLOAT
----------------------------------------------
-- Initialize Variables
----------------------------------------------
Select 	 @TotalProduction = 0.0, 
 	  	 @ActualTotalItems = 0, 
 	  	 @ActualGoodItems = 0, 
 	  	 @ActualBadItems = 0, 
 	  	 @ActualConformanceItems = 0, 
 	  	 @TotalWaste = 0,
 	  	 @TotalBalance = 0,
 	  	 @ActualProductionRate = 0.0,
 	  	 @TotalOutsideAreaMinutes = 0.0,
 	  	 @TotalUnavailableTimeMinutes = 0.0,
-- 	  	 @ActualRunningMinutes = 0.0,
-- 	  	 @ActualLoadingTimeMinutes = 0.0,
 	  	 @TotalTime = datediff(second, @StartTime, @EndTime)
-----------------------------------------------
-- Look Up Engineering Units
-----------------------------------------------
select 	 @AmountEngineeringUnits=AmountEngineeringUnits,
 	  	 @ItemEngineeringUnits=ItemEngineeringUnits,
 	  	 @TimeEngineeringUnits=TimeEngineeringUnits
from dbo.fnCMN_GetEngineeringUnitsByUnit(@Unit)
-----------------------------------------------
-- Look Up Unit, Specification Information
-- Always Scale To Per Minute 
-----------------------------------------------
select 	 @Ideal=Ideal, 
 	  	 @Warning=Warning, 
 	  	 @Reject=Reject, 
 	  	 @TargetPercent=TargetPercent, 
 	  	 @WarningPercent=WarningPercent, 
 	  	 @RejectPercent=RejectPercent
from dbo.fnCMN_GetUnitSpecsByProduct(@StartTime, @EndTime, @Unit, @ReferenceProduct)
-----------------------------------------------
-- Production (Prorated within function call)
-----------------------------------------------
Select 	 @TotalProduction=TotalProduction,
 	  	 @ActualTotalItems=ActualTotalItems,
 	  	 @ActualGoodItems=ActualGoodItems,
 	  	 @ActualBadItems=ActualBadItems,
 	  	 @ActualConformanceItems=ActualConformanceItems
From dbo.fnCMN_GetProductionItemTotalsByUnit(@StartTime, @EndTime, @Unit, @FilterNonProductiveTime)
-----------------------------------------------
-- Waste (Prorated within function call)
-----------------------------------------------
Select @TotalWaste = TotalWaste 
From dbo.fnCMN_GetProductionWasteByUnit(@StartTime, @EndTime, @Unit, @FilterNonProductiveTime)
-----------------------------------------------
-- Calculate OutsideArea, Unavailable,
-- LoadingTime and NetOperatingTime (RunningSeconds)
-- Use Running Seconds to Calculate IdealRate
-----------------------------------------------
If (@ActualRunningMinutes Is NULL) or (@ActualLoadingTimeMinutes Is Null) or (@ActualPerformanceDTMinutes Is Null)
 	 Select @TotalOutsideAreaMinutes=OutsideAreaSeconds / 60.0,
 	        @TotalUnavailableTimeMinutes=UnavailableSeconds / 60.0,
 	        @ActualLoadingTimeMinutes=LoadingSeconds / 60.0,
 	        @ActualRunningMinutes=RunningSeconds / 60.0,
 	  	   @ActualPerformanceDTMinutes=PerformanceDowntimeSeconds / 60.0
 	 From dbo.fnCMN_GetOutsideAreaTimeByUnit(@StartTime, @EndTime, @Unit, @FilterNonProductiveTime)
-----------------------------------------------
-- Calculate Return Stuff
-----------------------------------------------
Declare @SQLError varchar(255)
Select @SQLError = 'In Procedure spCMN_GetUnitProduction, In Case [' + convert(varchar(1), @Case) + '] TotalWaste [' + Convert(varchar(30), @TotalWaste) + '] Exceeds TotalProduction [' + Convert(varchar(30), @TotalProduction) + '] For ' + convert(VarChar(25), @StartTime) + ' To ' + convert(VarChar(25), @EndTime)
/*
If @TotalWaste > @TotalProduction
 	 Raiserror(@SQLError,16,1)
*/
-- Fix for ECR# 30662
-- Even though Waste has exceeded Production, the sp must continue and cannot throw an error 
--If @TotalWaste > @TotalProduction
--  Select @TotalWaste = convert(FLOAT, @TotalProduction)
Select @ActualProduction = Convert(FLOAT, @TotalProduction) - Convert(FLOAT, @TotalWaste)
Select @ActualQualityLoss = Convert(FLOAT, @TotalWaste)
If @TotalBalance > 0
  Begin 
    Select @IdealYield = convert(FLOAT, @TotalBalance)
    Select @ActualYieldLoss = convert(FLOAT, @TotalBalance) - Convert(FLOAT, @TotalProduction)
  End
Else
  Begin
    Select @IdealYield = Convert(FLOAT, @TotalProduction)
    Select @ActualYieldLoss = 0.0
  End
-------------------------------------------
-- Calculate Actual Production Rate
-------------------------------------------
If @ActualRunningMinutes > 0
 	 -- Good + Bad / Running Time
 	 Select @ActualProductionRate = (@TotalProduction + @ActualYieldLoss) / @ActualRunningMinutes
Else
 	 Select @ActualProductionRate = 0.0
-------------------------------------------
-- Calculate Ideal Rate & Production
-- If   Ideal is specified then use it
-- Else use Actual Rate
-------------------------------------------
Select @IdealRate = Coalesce(@Ideal, @ActualProductionRate)
/*
-- ECR# 32701 - do not alter ideal rate
-------------------------------------------
-- OEE Max Limit Override 
-- Allow Actual to Exceed Ideal ?
-------------------------------------------
if (select value from Site_Parameters where parm_id = 317) = 'False'
 	 If (@ActualProductionRate > @IdealRate) AND (@ActualProductionRate > 0)
 	   Select @IdealRate = @ActualProductionRate
*/
-------------------------------------------
-- IdealProduction = (IdealRate x RunningTime)
-------------------------------------------
--Select @IdealProduction = @IdealRate * @ActualLoadingTimeMinutes
Select @IdealProduction = @IdealRate * @ActualRunningMinutes
If @Warning Is Null
  Select @WarningProduction = @ActualProduction 
Else
  Select @WarningProduction =  @Warning * @ActualLoadingTimeMinutes
If @Reject Is Null
  Select @RejectProduction = @ActualProduction 
Else
  Select @RejectProduction =  @Reject * @ActualLoadingTimeMinutes
If @TargetPercent Is Null
  Select @TargetQualityLoss = @ActualQualityLoss
Else
  Select @TargetQualityLoss =  @TargetPercent * @TotalProduction / 100.0 
If @WarningPercent Is Null
  Select @WarningQualityLoss = @ActualQualityLoss
Else
  Select @WarningQualityLoss =  @WarningPercent * @TotalProduction / 100.0 
If @RejectPercent Is Null
  Select @RejectQualityLoss = @ActualQualityLoss
Else
  Select @RejectQualityLoss =  @RejectPercent * @TotalProduction / 100.0 
/*****************************************************
-- For Testing
--*****************************************************
Print '==========================================='
Print '==      spCMN_GetUnitProduction          =='
Print '==========================================='
Print '-- Input Values --'
Print '@StartTime                = ' + Convert(Varchar(25), @StartTime, 120)
Print '@EndTime                  = ' + Convert(Varchar(25), @EndTime, 120)
Print '@Unit                     = ' + Convert(Varchar(5), @Unit)
Print '@ReferenceProduct         = ' + Convert(Varchar(5), @ReferenceProduct)
Print ''
Print 'Prorating By Case #       = ' + convert(varchar(2), @Case)
print '@ActualLoadingTimeMinutes = ' + Convert(varchar(25), @ActualLoadingTimeMinutes)
print '@ActualRunningTimeMinutes = ' + Convert(varchar(25), @ActualLoadingTimeMinutes)
Print ''
Print 'Actual Production Rate    = ' + convert(varchar(25), convert(decimal(15,2),@ActualProductionRate))
PRINT '@ActualProduction         = ' + convert(varchar(25), convert(decimal(10,2),@TotalProduction))
Print ''
If @Ideal Is Null
 	 Print 'Ideal Production Rate     = [Calculated Amount] ' + convert(varchar(25), convert(decimal(15,2),@IdealRate))
Else
 	 Print 'Ideal Production Rate     = ' + convert(varchar(25), convert(decimal(15,2),@IdealRate))
PRINT '@IdealProduction          = ' + convert(varchar(25), convert(decimal(10,2),@IdealProduction))
Print ''
Print '-- Output Values --'
PRINT '@ActualProduction         = ' + convert(varchar(25), convert(decimal(15,2),@ActualProduction))
PRINT '@ActualQualityLoss (Waste)= ' + convert(varchar(25), convert(decimal(15,2),@ActualQualityLoss))
PRINT '@ActualYieldLoss          = ' + convert(varchar(25), convert(decimal(15,2),@ActualYieldLoss))
PRINT '@ActualTotalItems         = ' + convert(varchar(25), convert(decimal(15,2),@ActualTotalItems))
PRINT '@ActualGoodItems          = ' + convert(varchar(25), convert(decimal(15,2),@ActualGoodItems))
PRINT '@ActualBadItems           = ' + convert(varchar(25), convert(decimal(15,2),@ActualBadItems))
PRINT '@ActualConformanceItems   = ' + convert(varchar(25), convert(decimal(15,2),@ActualConformanceItems))
PRINT '@IdealYield               = ' + convert(varchar(25), convert(decimal(15,2),@IdealYield))
PRINT '@IdealRate                = ' + convert(varchar(25), convert(decimal(15,2),@IdealRate))
PRINT '@IdealProduction          = ' + convert(varchar(25), convert(decimal(10,2),@IdealProduction))
PRINT '@WarningProduction        = ' + convert(varchar(25), convert(decimal(15,2),@WarningProduction))
PRINT '@RejectProduction         = ' + convert(varchar(25), convert(decimal(15,2),@RejectProduction))
PRINT '@TargetQualityLoss        = ' + convert(varchar(25), convert(decimal(15,2),@TargetQualityLoss))
PRINT '@WarningQualityLoss       = ' + convert(varchar(25), convert(decimal(15,2),@WarningQualityLoss))
PRINT '@RejectQualityLoss        = ' + convert(varchar(25), convert(decimal(15,2),@RejectQualityLoss))
PRINT '@AmountEngineeringUnits   = ' + convert(varchar(25),@AmountEngineeringUnits)
PRINT '@ItemEngineeringUnits     = ' + convert(varchar(25),@ItemEngineeringUnits)
PRINT '@TimeEngineeringUnits     = ' + convert(varchar(25),@TimeEngineeringUnits)
--*****************************************************/
