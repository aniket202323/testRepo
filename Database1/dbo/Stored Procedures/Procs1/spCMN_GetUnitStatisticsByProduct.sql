CREATE Procedure dbo.spCMN_GetUnitStatisticsByProduct
@Unit int,
@StartTime datetime, 
@EndTime datetime,
@ProductId int,
@IdealProduction real OUTPUT,   	  	  	  	  	 -- TOTAL Production under 100% ideal conditions
@IdealYield real OUTPUT,   	  	  	  	  	  	 -- Theoretical TOTAL Production if 100% Raw material were converted 
@ActualProduction real OUTPUT, 	  	  	  	  	 -- NET Production
@ActualQualityLoss real OUTPUT, 	  	  	  	  	 -- Waste Production
@ActualYieldLoss real OUTPUT, 	  	  	  	  	  	 -- Loss Of Production from raw material conversion efficiency
@ActualSpeedLoss real OUTPUT, 	  	  	  	  	  	 -- Loss Of Production from production rate / speed
@ActualDowntimeLoss real OUTPUT, 	  	  	  	  	 -- Loss of Production from UNPLANNED downtime
@ActualDowntimeMinutes real OUTPUT, 	  	  	  	 -- TOTAL unplanned downtime
@ActualRuntimeMinutes real OUTPUT, 	  	  	  	  	 -- TOTAL run time
@ActualUnavailableMinutes real OUTPUT, 	  	  	  	 -- TOTAL planned downtime
@ActualSpeed real OUTPUT, 	  	  	  	  	  	 -- TOTAL production / running time
@ActualPercentOEE real OUTPUT, 	  	  	  	  	 -- OEE
@ActualTotalItems int OUTPUT, 	  	  	  	  	  	 -- TOTAL production events produced
@ActualGoodItems int OUTPUT, 	  	  	  	  	  	 -- Number Of Good production events produced
@ActualBadItems int OUTPUT, 	  	  	  	  	  	 -- Number Of Bad production events produced
@ActualConformanceItems int OUTPUT, 	  	  	  	 -- Number of Conforming production events produced
@TargetProduction real OUTPUT, 	  	  	  	  	 -- Target NET Production
@WarningProduction real OUTPUT,   	  	  	  	  	 -- Warning NET Production
@RejectProduction real OUTPUT,   	  	  	  	  	 -- Reject NET Production
@TargetQualityLoss real OUTPUT, 	  	  	  	  	 -- Target Production Loss From Waste
@WarningQualityLoss real OUTPUT, 	  	  	  	  	 -- Warning Production Loss From Waste
@RejectQualityLoss real OUTPUT, 	  	  	  	  	 -- Reject Production Loss From Waste
@TargetDowntimeLoss real OUTPUT, 	  	  	  	  	 -- Target Production Loss From Downtime
@WarningDowntimeLoss real OUTPUT, 	  	  	  	  	 -- Warning Production Loss From Downtime 
@RejectDowntimeLoss real OUTPUT, 	  	  	  	  	 -- Reject Production Loss From Downtime
@TargetSpeed real OUTPUT, 	  	  	  	  	  	 -- Target TOTAL Production / Target Run Time
@TargetDowntimeMinutes real OUTPUT, 	  	  	  	 -- Target Downtime Minutes
@WarningDowntimeMinutes real OUTPUT, 	  	  	  	 -- Warning Downtime Minutes
@RejectDowntimeMinutes real OUTPUT, 	  	  	  	 -- Reject Downtime Minutes
@TargetPercentOEE real OUTPUT, 	  	  	  	  	 -- Target OEE Percent
@WarningPercentOEE real OUTPUT, 	  	  	  	  	 -- Warning OEE Percent
@RejectPercentOEE real OUTPUT, 	  	  	  	  	 -- Reject OEE Percent
@AmountEngineeringUnits varchar(25) OUTPUT, 	  	  	 -- Engineering Units For Production 	 
@ItemEngineeringUnits varchar(25) OUTPUT, 	  	  	 -- Engineering Units For Production Events (count)
@TimeEngineeringUnits int OUTPUT, 	  	  	  	  	 -- Engineering Units For Production RATE (time units, default = minutes)
@Status int OUTPUT, 	  	  	  	  	  	  	  	 -- 0 if currently down, 1 if currently up (at end time)
@ActualDowntimeCount int OUTPUT 	  	  	  	  	 -- Total count of downtime events in time period
AS
set arithignore on
set arithabort off
set ansi_warnings off
Declare @OEEProperty int
Declare @OEECharacteristic int
Declare @OEESpecification int
Declare @OEEVariable int
Declare @TargetPercent real
Declare @WarningPercent real
Declare @RejectPercent real
Declare @TotalOEE real
Declare @TotalTime int
Declare @iTotalTime int
-------------------------------------------------------
-- Look Up Unit, Specification Information
-------------------------------------------------------
Select @OEESpecification = Efficiency_Percent_Specification,
       @OEEVariable = Efficiency_Variable
  From Prod_Units 
  Where PU_Id = @Unit
If @OEESpecification Is Not Null
  Begin
    Select @OEEProperty = prop_id 
      From Specifications 
      Where Spec_Id = @OEESpecification
  End
-------------------------------------------------------
-- Get Production Starts For This Time Period
-------------------------------------------------------
Declare @iActualRunMinutes real,
@iActualUnavailableMinutes real,
@iActualDownMinutes real,
@iTargetDownMinutes real,
@iWarningDownMinutes real,
@iRejectDownMinutes real,
@iActualDowntimeCount int
Declare @iActualProduction real,
@iActualQualityLoss real,
@iActualYieldLoss real,
@iIdealYield real,
@iIdealRate real, 
@iIdealProduction real,  
@iWarningProduction real,  
@iRejectProduction real,  
@iTargetQualityLoss real,
@iWarningQualityLoss real,
@iRejectQualityLoss real,
@iActualTotalItems int,
@iActualGoodItems int,
@iActualBadItems int,
@iActualConformanceItems int
Declare @iActualDownLoss real,
@iTargetDownLoss real,
@iWarningDownLoss real,
@iRejectDownLoss real
Declare @iActualSpeedLoss real
Declare @iActualOEE real
Declare @TotalRunMinutes real,
@TotalUnavailableMinutes real,
@TotalDownMinutes real,
@TotalTargetDownMinutes real,
@TotalWarningDownMinutes real,
@TotalRejectDownMinutes real,
@TotalDowntimeCount int
Declare @TotalProduction real,
@TotalQualityLoss real,
@TotalYieldLoss real,
@TotalIdealYield real,
@TotalIdealProduction real,  
@TotalWarningProduction real,  
@TotalRejectProduction real,  
@TotalTargetQualityLoss real,
@TotalWarningQualityLoss real,
@TotalRejectQualityLoss real,
@TotalActualTotalItems int,
@TotalActualGoodItems int,
@TotalActualBadItems int,
@TotalActualConformanceItems int
Declare @TotalDownLoss real,
@TotalTargetDownLoss real,
@TotalWarningDownLoss real,
@TotalRejectDownLoss real
Declare @TotalSpeedLoss real
Declare @TotalActualOEE real
Declare @TotalTargetOEE real
Declare @TotalWarningOEE real
Declare @TotalRejectOEE real
---------------------------------------------------
-- Begin New Variables For OEE Calculation
---------------------------------------------------
Declare @ActualLoadingTimeMinutes Real
Declare @Downtime_External_Category int
Declare @TotalOutsideAreaMinutes Real
Declare @Performance_Downtime_Category int
Declare @PerformanceDowntimeMinutes Real
Declare @AvailabilityRate Real
Declare @PerformanceRate Real
Declare @TotalLoadingTimeMinutes Real
Select @TotalLoadingTimeMinutes = 0
Select @ActualLoadingTimeMinutes = 0
Select @TotalOutsideAreaMinutes = 0
Select @PerformanceDowntimeMinutes = 0
---------------------------------------------------
-- End New Variables For OEE Calculation
---------------------------------------------------
-------------------------------------------------------
-- Initialize Variables
-------------------------------------------------------
Select @TotalRunMinutes = 0
Select @TotalUnavailableMinutes = 0
Select @TotalDownMinutes = 0
Select @TotalTargetDownMinutes = 0
Select @TotalWarningDownMinutes = 0
Select @TotalRejectDownMinutes = 0
Select @TotalProduction = 0
Select @TotalQualityLoss = 0
Select @TotalYieldLoss = 0
Select @TotalIdealYield = 0
Select @TotalIdealProduction = 0
Select @TotalWarningProduction = 0
Select @TotalRejectProduction = 0
Select @TotalTargetQualityLoss = 0
Select @TotalWarningQualityLoss = 0
Select @TotalRejectQualityLoss = 0
Select @TotalActualTotalItems = 0
Select @TotalActualGoodItems = 0
Select @TotalActualBadItems = 0
Select @TotalActualConformanceItems = 0
Select @TotalDownLoss = 0
Select @TotalTargetDownLoss = 0
Select @TotalWarningDownLoss = 0
Select @TotalRejectDownLoss = 0
Select @TotalSpeedLoss = 0
Select @TotalActualOEE = 0
Select @TotalTargetOEE = 0
Select @TotalWarningOEE = 0
Select @TotalRejectOEE = 0
Select @TotalDowntimeCount = 0
Select @iTotalTime = datediff(second,@StartTime, @EndTime)
 -- Get Downtime Statistics
execute spCMN_GetUnitDowntime
     @Unit,
     @StartTime, 
     @EndTime,
     @ProductId, 
     @iActualRunMinutes OUTPUT,
     @iActualUnavailableMinutes OUTPUT,
     @iActualDownMinutes OUTPUT,
     @iTargetDownMinutes OUTPUT,
     @iWarningDownMinutes OUTPUT,
     @iRejectDownMinutes OUTPUT,
     @Status OUTPUT,
     @iActualDowntimeCount OUTPUT
--------------------------------------------------------
-- Totalize Downtime Statistics
--------------------------------------------------------
Select @TotalRunMinutes = @TotalRunMinutes + coalesce(@iActualRunMinutes,0)
Select @TotalUnavailableMinutes = @TotalUnavailableMinutes + coalesce(@iActualUnavailableMinutes,0)
Select @TotalDownMinutes = @TotalDownMinutes + coalesce(@iActualDownMinutes,0)
Select @TotalTargetDownMinutes = @TotalTargetDownMinutes + coalesce(@iTargetDownMinutes,0)
Select @TotalWarningDownMinutes = @TotalWarningDownMinutes + coalesce(@iWarningDownMinutes,0)
Select @TotalRejectDownMinutes = @TotalRejectDownMinutes + coalesce(@iRejectDownMinutes,0)
Select @TotalDowntimeCount = @TotalDowntimeCount + coalesce(@iActualDowntimeCount,0)
--------------------------------------------------------
-- Begin New OEE Calculations
-- Get Outside Area Category Id and Value
Select @Downtime_External_Category = Coalesce(Downtime_External_Category, 0) From Prod_Units Where PU_Id = @Unit
Select @TotalOutsideAreaMinutes = dbo.fnCMN_GetCategoryTimeByUnit(@StartTime, @EndTime, @Unit, @Downtime_External_Category, NULL) / 60.0
-- Get Performance Downtime Category Id and Value
Select @Performance_Downtime_Category = Coalesce(Performance_Downtime_Category, 0) From Prod_Units Where PU_Id = @Unit
Select @PerformanceDowntimeMinutes = dbo.fnCMN_GetCategoryTimeByUnit(@StartTime, @EndTime, @Unit, @Performance_Downtime_Category, NULL) / 60.0
-- Calculate Loading Time Minutes as (TotalTimeSeconds - TotalUnavailableSeconds - TotalOutsideAreaSeconds) / 60.0
Select @ActualLoadingTimeMinutes = (datediff(second, @StartTime, @EndTime)) / 60.0 - @iActualUnavailableMinutes - @TotalOutsideAreaMinutes
Select @TotalLoadingTimeMinutes = @TotalLoadingTimeMinutes + @ActualLoadingTimeMinutes
-- This might need to be moved to the bottom
-- Calculate Availability Rate as RunTime / LoadingTime
Select @AvailabilityRate = @iActualRunMinutes / @ActualLoadingTimeMinutes
-- Calculate Performance Rate as @ActualRunMinutes / 60 - @SpeedLossTimeEqSeconds / @ActualRunMinutes / 60 + @PerformanceDowntimeMinutes / 60
-- End New OEE Calculations
--------------------------------------------------------
--------------------------------------------------------
-- Get Production Statistics 
--------------------------------------------------------
execute spCMN_GetUnitProduction
     @Unit,
     @StartTime, 
     @EndTime,
     @ProductID, 
     @iActualProduction OUTPUT,
     @iActualQualityLoss OUTPUT,
     @iActualYieldLoss OUTPUT,
     @iActualTotalItems OUTPUT,
     @iActualGoodItems OUTPUT,
     @iActualBadItems OUTPUT,
     @iActualConformanceItems OUTPUT,
     @iIdealYield OUTPUT,  
     @iIdealRate OUTPUT,  
     @iIdealProduction OUTPUT,  
     @iWarningProduction OUTPUT,  
     @iRejectProduction OUTPUT,  
     @iTargetQualityLoss OUTPUT,
     @iWarningQualityLoss OUTPUT,
     @iRejectQualityLoss OUTPUT,
     @AmountEngineeringUnits OUTPUT,
     @ItemEngineeringUnits OUTPUT,
     @TimeEngineeringUnits OUTPUT
-- This value is compensated for 
-- in spCmn_GetUnitProduction
-- Adjust Ideal Production By Available Time 	  	 
-- Select @iIdealProduction = @iIdealProduction * ((convert(real,@iTotalTime) / 60.0) - coalesce(@iActualUnavailableMinutes,0)) / (convert(real,@iTotalTime) / 60.0)
 -- Totalize Production Statistics
Select @TotalProduction = @TotalProduction + coalesce(@iActualProduction,0) -- NOTE: This is Total NET Production
Select @TotalQualityLoss = @TotalQualityLoss + coalesce(@iActualQualityLoss,0)
Select @TotalYieldLoss = @TotalYieldLoss + coalesce(@iActualYieldLoss,0)
Select @TotalIdealYield = @TotalIdealYield + coalesce(@iIdealYield,0)  -- NOTE: This is Total TOTAL Production (theoretical yeild)
Select @TotalIdealProduction = @TotalIdealProduction + coalesce(@iIdealProduction,0)
Select @TotalWarningProduction = @TotalWarningProduction + (coalesce(@iWarningProduction,0)  * ((convert(real,@iTotalTime) / 60.0) - coalesce(@iActualUnavailableMinutes,0)) / (convert(real,@iTotalTime) / 60.0)) 
Select @TotalRejectProduction = @TotalRejectProduction + (coalesce(@iRejectProduction,0) * ((convert(real,@iTotalTime) / 60.0) - coalesce(@iActualUnavailableMinutes,0)) / (convert(real,@iTotalTime) / 60.0))
Select @TotalTargetQualityLoss = @TotalTargetQualityLoss + coalesce(@iTargetQualityLoss,0)
Select @TotalWarningQualityLoss = @TotalWarningQualityLoss + coalesce(@iWarningQualityLoss,0)
Select @TotalRejectQualityLoss = @TotalRejectQualityLoss + coalesce(@iRejectQualityLoss,0)
Select @TotalActualTotalItems = @TotalActualTotalItems + coalesce(@iActualTotalItems,0)
Select @TotalActualGoodItems = @TotalActualGoodItems + coalesce(@iActualGoodItems,0)
Select @TotalActualBadItems = @TotalActualBadItems + coalesce(@iActualBadItems,0)
Select @TotalActualConformanceItems = @TotalActualConformanceItems + coalesce(@iActualConformanceItems,0)
-- Calculate Downtime Loss Based On Ideal Production Rate
Select @iActualDownLoss = @iActualDownMinutes  * @iIdealRate
Select @iTargetDownLoss =  @iTargetDownMinutes * @iIdealRate
Select @iWarningDownLoss = @iWarningDownMinutes  * @iIdealRate
Select @iRejectDownLoss = @iRejectDownMinutes  * @iIdealRate
-- Totalize Downtime Loss
Select @TotalDownLoss = @TotalDownLoss + coalesce(@iActualDownLoss,0)
Select @TotalTargetDownLoss = @TotalTargetDownLoss + coalesce(@iTargetDownLoss,0)
Select @TotalWarningDownLoss = @TotalWarningDownLoss + coalesce(@iWarningDownLoss,0)
Select @TotalRejectDownLoss = @TotalRejectDownLoss + coalesce(@iRejectDownLoss,0)
-- Calculate Speed Loss
Select @iActualSpeedLoss = @iIdealProduction - (@iActualProduction + coalesce(@iActualDownLoss,0) + coalesce(@iActualQualityLoss,0) + coalesce(@iActualYieldLoss,0))
-- Totalize Speed Loss
Select @TotalSpeedLoss = @TotalSpeedLoss + coalesce(@iActualSpeedLoss,0)
-- Fetch OEE Specification
Select @TargetPercent = NULL
Select @WarningPercent = NULL
Select @RejectPercent = NULL
If @OEESpecification Is Not Null
     Begin
          Select @OEECharacteristic = char_id
          From pu_characteristics 
          Where prop_id = @OEEProperty and
            prod_id = @ProductId and
            pu_id = @Unit
          If @OEECharacteristic Is Not NUll
               Begin
                    Select @TargetPercent = convert(real,target), 
                         @WarningPercent = convert(real, l_warning),
                         @RejectPercent = convert(real, l_reject)
                    From Active_Specs
                    Where Spec_Id = @OEESpecification and
                          Char_Id = @OEECharacteristic and
                          Effective_Date <= @StartTime and 
                          ((Expiration_Date > @StartTime) or (Expiration_Date Is Null))
               End 
     End --If @OEESpecification Is Not Null
 -- Calculate OEE
If @OEEVariable Is Null
     Begin
          -- Use The Standard OEE Calculation
          If @iIdealProduction = 0 
             Select @iActualOEE = 100.0
          Else If @iActualProduction > 0
            Select @iActualOEE = (1 - 
                                   (coalesce(@iActualDownLoss,0) + coalesce(@iActualQualityLoss,0) + coalesce(@iActualYieldLoss,0) + coalesce(@iActualSpeedLoss,0)) / @iIdealProduction
                                  ) * 100.0
          Else
             Select @iActualOEE = 0.0
     End
Else
     Begin
          -- Use The Customer's OEE Calculation
          Select @iActualOEE = avg(convert(real,result))
            From Tests t
            Where t.var_id = @OEEVariable and
                  t.result_on >= @StartTime and
                  t.result_On < @EndTime and
                  t.result is not null
     End
-- Normalize And Total OEE and OEE Specs
Select @TotalActualOEE = @TotalActualOEE + coalesce(@iActualOEE * @iIdealProduction,0)
Select @TotalTargetOEE = @TotalTargetOEE + coalesce((Case When @TargetPercent Is Null Then @iActualOEE Else @TargetPercent End) * @iIdealProduction,0)
Select @TotalWarningOEE = @TotalWarningOEE + coalesce((Case When @WarningPercent Is Null Then @iActualOEE Else @WarningPercent End) * @iIdealProduction,0)
Select @TotalRejectOEE = @TotalRejectOEE + coalesce((Case When @RejectPercent Is Null Then @iActualOEE Else @RejectPercent End) * @iIdealProduction,0)
-------------------------------------------------------
-- Make Final Calculations
-------------------------------------------------------
Select @TotalTime = datediff(second,@StartTime, @EndTime)
Select @IdealProduction = @TotalIdealProduction
Select @IdealYield = @TotalIdealYield
Select @ActualProduction = @TotalProduction
Select @ActualQualityLoss = @TotalQualityLoss
Select @ActualYieldLoss = @TotalYieldLoss
Select @ActualSpeedLoss = @TotalSpeedLoss
Select @ActualDowntimeLoss = @TotalDownLoss
Select @ActualDowntimeMinutes = @TotalDownMinutes
Select @ActualRuntimeMinutes = @TotalRunMinutes
Select @ActualUnavailableMinutes = @TotalUnavailableMinutes
Select @ActualSpeed =  case when @TotalRunMinutes > 0 then (@TotalProduction + @TotalQualityLoss) / @TotalRunMinutes else 0.0 end
Select @ActualPercentOEE = case when @TotalIdealProduction > 0 then @TotalActualOEE / @TotalIdealProduction else 100.0 end
Select @TargetProduction = @TotalIdealProduction - @TotalTargetQualityLoss - @TotalTargetDownLoss
Select @WarningProduction = @TotalWarningProduction
Select @RejectProduction = @TotalRejectProduction 
Select @TargetQualityLoss = @TotalTargetQualityLoss
Select @WarningQualityLoss = @TotalWarningQualityLoss
Select @RejectQualityLoss = @TotalRejectQualityLoss
Select @TargetDowntimeLoss = @TotalTargetDownLoss
Select @WarningDowntimeLoss = @TotalWarningDownLoss
Select @RejectDowntimeLoss = @TotalRejectDownLoss
-- Alter this calc to be as follows:
--Select @TargetSpeed = (@TotalIdealProduction - @TotalTargetDownLoss) / ((@TotalTime / 60.0) - @TotalTargetDownMinutes) 
Select @TargetSpeed = (@TotalIdealProduction / @TotalLoadingTimeMinutes)
Select @TargetDowntimeMinutes = @TotalTargetDownMinutes
Select @WarningDowntimeMinutes = @TotalWarningDownMinutes
Select @RejectDowntimeMinutes = @TotalRejectDownMinutes
Select @TargetPercentOEE = case when @TotalIdealProduction > 0 then @TotalTargetOEE / @TotalIdealProduction else 100.0 end 
Select @WarningPercentOEE = case when @TotalIdealProduction > 0 then @TotalWarningOEE / @TotalIdealProduction else 100.0 end  
Select @RejectPercentOEE = case when @TotalIdealProduction > 0 then @TotalRejectOEE / @TotalIdealProduction else 100.0 end    
Select @ActualTotalItems = @TotalActualTotalItems
Select @ActualGoodItems = @TotalActualGoodItems
Select @ActualBadItems = @TotalActualBadItems
Select @ActualConformanceItems = @TotalActualConformanceItems
Select @ActualDowntimeCount = @TotalDowntimeCount
/*****************************************************
-- For Testing
--*****************************************************
Print ''
Print '==========================================='
Print '== spCMN_GetUnitStatistics Return Values =='
Print '==========================================='
PRINT '@IdealProduction            = ' + coalesce(convert(varchar(25), convert(decimal(25,2), @IdealProduction)), 'unkn')
PRINT '@IdealYield                 = ' + coalesce(convert(varchar(25), @IdealYield),'unk')
PRINT '@ActualProduction           = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualProduction)),'unk')
PRINT '@ActualQualityLoss          = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualQualityLoss)),'unk')
PRINT '@ActualYieldLoss            = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualYieldLoss)),'unk')
PRINT '@ActualSpeedLoss            = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualSpeedLoss)),'unk')
PRINT '@ActualDowntimeLoss         = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualDowntimeLoss)),'unk')
PRINT '@ActualDowntimeMinutes      = ' + coalesce(convert(varchar(25), @ActualDowntimeMinutes),'unk')
PRINT '@ActualRuntimeMinutes       = ' + coalesce(convert(varchar(25), @ActualRuntimeMinutes),'unk')
PRINT '@ActualUnavailableMinutes   = ' + coalesce(convert(varchar(25), @ActualUnavailableMinutes),'unk')
PRINT '@ActualSpeed                = ' + coalesce(convert(varchar(25), @ActualSpeed),'unk')
PRINT '@ActualPercentOEE           = ' + coalesce(convert(varchar(25), @ActualPercentOEE),'unk')
PRINT '@TargetProduction           = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@TargetProduction)),'unk')
PRINT '@WarningProduction          = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@WarningProduction)),'unk')
PRINT '@RejectProduction           = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@RejectProduction)),'unk')
PRINT '@TargetQualityLoss          = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@TargetQualityLoss)),'unk')
PRINT '@WarningQualityLoss         = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@WarningQualityLoss)),'unk')
PRINT '@RejectQualityLoss          = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@RejectQualityLoss)),'unk')
PRINT '@TargetDowntimeLoss         = ' + coalesce(convert(varchar(25), convert(decimal(20,2),@TargetDowntimeLoss)),'unk')
PRINT '@WarningDowntimeLoss        = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@WarningDowntimeLoss)),'unk')
PRINT '@RejectDowntimeLoss         = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@RejectDowntimeLoss)),'unk')
PRINT '@TargetSpeed                = ' + coalesce(convert(varchar(25), @TargetSpeed),'unk')
PRINT '@TargetDowntimeMinutes      = ' + coalesce(convert(varchar(25), @TargetDowntimeMinutes),'unk')
PRINT '@WarningDowntimeMinutes     = ' + coalesce(convert(varchar(25), @WarningDowntimeMinutes),'unk')
PRINT '@RejectDowntimeMinutes      = ' + coalesce(convert(varchar(25), @RejectDowntimeMinutes),'unk')
PRINT '@TargetPercentOEE           = ' + coalesce(convert(varchar(25), @TargetPercentOEE),'unk')
PRINT '@WarningPercentOEE          = ' + coalesce(convert(varchar(25), @WarningPercentOEE),'unk')
PRINT '@RejectPercentOEE           = ' + coalesce(convert(varchar(25), @RejectPercentOEE),'unk')
PRINT '@ActualTotalItems           = ' + coalesce(convert(varchar(25), @TotalActualTotalItems),'unk')
PRINT '@ActualGoodItems            = ' + coalesce(convert(varchar(25), @TotalActualGoodItems),'unk')
PRINT '@ActualBadItems             = ' + coalesce(convert(varchar(25), @TotalActualBadItems),'unk')
PRINT '@ActualConformanceItems     = ' + coalesce(convert(varchar(25), @TotalActualConformanceItems),'unk')
PRINT '@DowntimePercent            = ' + coalesce(convert(varchar(25), @ActualDowntimeMinutes / convert(real,(@ActualDowntimeMinutes + @ActualRuntimeMinutes)) * 100.0),'unk')
PRINT '@WastePercent               = ' + coalesce(convert(varchar(25), (@ActualQualityLoss + @ActualYieldLoss) /  convert(real,(@ActualQualityLoss + @ActualProduction + @ActualYieldLoss)) * 100.0),'unk')
PRINT '@ActualDowntimeCount        = ' + coalesce(convert(varchar(25), @ActualDowntimeCount),'unk')
--*****************************************************/
