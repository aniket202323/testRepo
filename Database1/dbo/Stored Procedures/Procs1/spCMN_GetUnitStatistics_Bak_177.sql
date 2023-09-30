CREATE Procedure dbo.[spCMN_GetUnitStatistics_Bak_177]
@Unit int,
@StartTime datetime, 
@EndTime datetime,
@IdealProduction FLOAT OUTPUT,   	  	  	  	  	 -- TOTAL Production under 100% ideal conditions
@IdealYield FLOAT OUTPUT,   	  	  	  	  	  	 -- Theoretical TOTAL Production if 100% Raw material were converted 
@ActualProduction FLOAT OUTPUT, 	  	  	  	  	 -- NET Production
@ActualQualityLoss FLOAT OUTPUT, 	  	  	  	  	 -- Waste Production
@ActualYieldLoss FLOAT OUTPUT, 	  	  	  	  	  	 -- Loss Of Production from raw material conversion efficiency
@ActualSpeedLoss FLOAT OUTPUT, 	  	  	  	  	  	 -- Loss Of Production from production rate / speed
@ActualDowntimeLoss FLOAT OUTPUT, 	  	  	  	  	 -- Loss of Production from UNPLANNED downtime
@ActualDowntimeMinutes FLOAT OUTPUT, 	  	  	  	 -- TOTAL unplanned downtime
@ActualRuntimeMinutes FLOAT OUTPUT, 	  	  	  	  	 -- TOTAL run time
@ActualUnavailableMinutes FLOAT OUTPUT, 	  	  	  	 -- TOTAL planned downtime
@ActualSpeed FLOAT OUTPUT, 	  	  	  	  	  	 -- TOTAL production / running time
@ActualPercentOEE FLOAT OUTPUT, 	  	  	  	  	 -- OEE
@ActualTotalItems int OUTPUT, 	  	  	  	  	  	 -- TOTAL production events produced
@ActualGoodItems int OUTPUT, 	  	  	  	  	  	 -- Number Of Good production events produced
@ActualBadItems int OUTPUT, 	  	  	  	  	  	 -- Number Of Bad production events produced
@ActualConformanceItems int OUTPUT, 	  	  	  	 -- Number of Conforming production events produced
@TargetProduction FLOAT OUTPUT, 	  	  	  	  	 -- Target NET Production
@WarningProduction FLOAT OUTPUT,   	  	  	  	  	 -- Warning NET Production
@RejectProduction FLOAT OUTPUT,   	  	  	  	  	 -- Reject NET Production
@TargetQualityLoss FLOAT OUTPUT, 	  	  	  	  	 -- Target Production Loss From Waste
@WarningQualityLoss FLOAT OUTPUT, 	  	  	  	  	 -- Warning Production Loss From Waste
@RejectQualityLoss FLOAT OUTPUT, 	  	  	  	  	 -- Reject Production Loss From Waste
@TargetDowntimeLoss FLOAT OUTPUT, 	  	  	  	  	 -- Target Production Loss From Downtime
@WarningDowntimeLoss FLOAT OUTPUT, 	  	  	  	  	 -- Warning Production Loss From Downtime 
@RejectDowntimeLoss FLOAT OUTPUT, 	  	  	  	  	 -- Reject Production Loss From Downtime
@TargetSpeed FLOAT OUTPUT, 	  	  	  	  	  	 -- Target TOTAL Production / Target Run Time
@TargetDowntimeMinutes FLOAT OUTPUT, 	  	  	  	 -- Target Downtime Minutes
@WarningDowntimeMinutes FLOAT OUTPUT, 	  	  	  	 -- Warning Downtime Minutes
@RejectDowntimeMinutes FLOAT OUTPUT, 	  	  	  	 -- Reject Downtime Minutes
@TargetPercentOEE FLOAT OUTPUT, 	  	  	  	  	 -- Target OEE Percent
@WarningPercentOEE FLOAT OUTPUT, 	  	  	  	  	 -- Warning OEE Percent
@RejectPercentOEE FLOAT OUTPUT, 	  	  	  	  	 -- Reject OEE Percent
@AmountEngineeringUnits varchar(25) OUTPUT, 	  	  	 -- Engineering Units For Production 	 
@ItemEngineeringUnits varchar(25) OUTPUT, 	  	  	 -- Engineering Units For Production Events (count)
@TimeEngineeringUnits int OUTPUT, 	  	  	  	  	 -- Engineering Units For Production RATE (time units, default = minutes)
@Status int OUTPUT, 	  	  	  	  	  	  	  	 -- 0 if currently down, 1 if currently up (at end time)
@ActualDowntimeCount int OUTPUT, 	  	  	  	  	 -- Total count of downtime events in time period
@FilterNonProductiveTime int = 0,
@TotalLoadingTimeMinutes FLOAT = NULL OUTPUT,
@TotalPerformanceDTMinutes FLOAT = NULL OUTPUT
AS
--*****************************************************/
set arithignore on -- does not cause recompile, only suppresses the 'divide by zero' message, doesn't stop the error and the value is not null 
-- see SQL BOL: Behavior if Both ARITHABORT and ARITHIGNORE Are Set ON
--set arithabort off -- causes recompile, value is not null 
--set ansi_warnings off -- causes recompile, null is returned
Declare @OEEProperty int
Declare @OEECharacteristic int
Declare @OEESpecification int
Declare @OEEVariable int
Declare @TargetPercent FLOAT
Declare @WarningPercent FLOAT
Declare @RejectPercent FLOAT
Declare @TotalOEE FLOAT
Declare @TotalTime int
Declare @iTotalTime int
Declare @iTotalTimePerMin FLOAT 
--*****************************************************
-- Look Up Unit, Specification Information
--*****************************************************
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
--*****************************************************
--*****************************************************
-- Get Production Starts For This Time Period
--*****************************************************
Declare @iActualRunMinutes FLOAT,
@iActualUnavailableMinutes FLOAT,
@iActualDownMinutes FLOAT,
@iTargetDownMinutes FLOAT,
@iWarningDownMinutes FLOAT,
@iRejectDownMinutes FLOAT,
@iActualDowntimeCount int,
@iActualLoadtimeMinutes FLOAT,
@iActualPerformanceDTMinutes FLOAT
Declare @iActualProduction FLOAT,
@iActualQualityLoss FLOAT,
@iActualYieldLoss FLOAT,
@iIdealYield FLOAT,
@iIdealRate FLOAT, 
@iIdealProduction FLOAT,  
@iWarningProduction FLOAT,  
@iRejectProduction FLOAT,  
@iTargetQualityLoss FLOAT,
@iWarningQualityLoss FLOAT,
@iRejectQualityLoss FLOAT,
@iActualTotalItems int,
@iActualGoodItems int,
@iActualBadItems int,
@iActualConformanceItems int
Declare @iActualDownLoss FLOAT,
@iTargetDownLoss FLOAT,
@iWarningDownLoss FLOAT,
@iRejectDownLoss FLOAT
Declare @iActualSpeedLoss FLOAT
Declare @iActualOEE FLOAT
Declare @TotalRunMinutes FLOAT,
@TotalUnavailableMinutes FLOAT,
@TotalDownMinutes FLOAT,
@TotalTargetDownMinutes FLOAT,
@TotalWarningDownMinutes FLOAT,
@TotalRejectDownMinutes FLOAT,
@TotalDowntimeCount int
Declare @TotalProduction FLOAT,
@TotalQualityLoss FLOAT,
@TotalYieldLoss FLOAT,
@TotalIdealYield FLOAT,
@TotalIdealProduction FLOAT,  
@TotalWarningProduction FLOAT,  
@TotalRejectProduction FLOAT,  
@TotalTargetQualityLoss FLOAT,
@TotalWarningQualityLoss FLOAT,
@TotalRejectQualityLoss FLOAT,
@TotalActualTotalItems int,
@TotalActualGoodItems int,
@TotalActualBadItems int,
@TotalActualConformanceItems int
Declare @TotalDownLoss FLOAT,
@TotalTargetDownLoss FLOAT,
@TotalWarningDownLoss FLOAT,
@TotalRejectDownLoss FLOAT
Declare @TotalSpeedLoss FLOAT
Declare @TotalActualOEE FLOAT
Declare @TotalTargetOEE FLOAT
Declare @TotalWarningOEE FLOAT
Declare @TotalRejectOEE FLOAT
---------------------------------------------------
-- Begin New Variables For OEE Calculation
---------------------------------------------------
Declare @ActualLoadingTimeMinutes FLOAT
Declare @Downtime_External_Category int
Declare @TotalOutsideAreaMinutes FLOAT
Declare @Performance_Downtime_Category int
Declare @PerformanceDowntimeMinutes FLOAT
Declare @AvailabilityRate FLOAT
Declare @PerformanceRate FLOAT
--Declare @TotalLoadingTimeMinutes FLOAT
Select @TotalLoadingTimeMinutes = 0
Select @ActualLoadingTimeMinutes = 0
Select @TotalOutsideAreaMinutes = 0
Select @PerformanceDowntimeMinutes = 0
Select @TotalPerformanceDTMinutes = 0
---------------------------------------------------
-- Begin New Variables For OEE Calculation
---------------------------------------------------
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
--    StartTime       EndTime       ProductId
Declare @ST datetime, @ET datetime, @PD int
DECLARE @RunTimes TABLE(Id int identity(1,1), Start_Time datetime, End_Time datetime)
--------------------------------------------
-- Get Productive Times
--------------------------------------------
If @FilterNonProductiveTime <> 0 
 	 Begin
 	  	 Insert Into @RunTimes(Start_Time, End_Time)
 	  	  	 Select * from dbo.fnCMN_GetProductiveTimes(@Unit, @StartTime, @EndTime) 	 
 	 End
Else
 	 Insert Into @RunTimes(Start_Time, End_Time)
 	  	 Values(@StartTime, @EndTime)
Declare @UnitTimes Table(StartTime datetime, EndTime datetime, ProductId int)
DECLARE MyCursor  CURSOR
  For ( Select Start_Time, End_Time From @RunTimes )
  For Read Only
  Open MyCursor  
  Fetch Next From MyCursor Into @ST, @ET 
 	   While (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 Insert Into @UnitTimes (StartTime, EndTime, ProductId)
 	  	  	   Select StartTime = Case When Start_Time < @ST Then @ST Else Start_Time End,
 	  	  	          EndTime = Case When End_Time Is Null Then @ET When End_Time > @ET Then @ET Else End_Time End,
 	  	  	          ProductId = Prod_Id
 	  	  	     From Production_Starts 
 	  	  	  	 WHERE PU_Id = @Unit
 	  	  	  	  	 AND Start_Time < @ET 
 	  	  	  	  	 AND ((End_Time > @ST) or (End_Time Is NULL))
 	  	  	 Fetch Next From MyCursor Into @ST, @ET 
 	  	 End 
 	 
 	 Close MyCursor
 	 Deallocate MyCursor
------------------------------------------------------------
-- Need to Check for spec changes within product run
-- Anytime a spec change for a product run is found within
-- the reporting period, divide it up
------------------------------------------------------------
Declare @SpecChangeTable Table(StartTime datetime, EndTime datetime, ProductId int)
Declare @Temp Table(StartTime datetime, EndTime datetime, ProductId int)
Declare @ProductionSpecification int, @ProductionProperty int, @ProductionCharacteristic int
Select @ProductionSpecification = Production_Rate_Specification From Prod_Units Where PU_Id = @Unit
If @ProductionSpecification Is Not Null
  Begin
    Select  @ProductionProperty = prop_id 
      From  Specifications 
      Where Spec_Id = @ProductionSpecification
 	 -- Go through every entry in @UnitTimes & check for a spec change 	 
 	 Declare MyCursor INSENSITIVE CURSOR
 	   For ( Select StartTime, EndTime, ProductId From @UnitTimes )
 	   For Read Only
 	   Open MyCursor  
 	   Fetch Next From MyCursor Into @ST, @ET, @PD 
 	   While (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 -- Get Production Characteristic
 	  	  	 Select  @ProductionCharacteristic = char_id
 	  	  	   From  pu_characteristics 
 	  	  	   Where prop_id = @ProductionProperty and
 	  	  	  	  	 prod_id = @PD and
 	  	  	  	  	 pu_id = @Unit
 	  	  	 Insert Into @Temp(ProductId, StartTime, EndTime)
 	  	  	 Select @PD, Effective_Date, Expiration_Date from Active_Specs           
 	  	  	 Where Spec_Id = @ProductionSpecification and
 	  	  	  	   Char_Id = @ProductionCharacteristic and
 	  	  	  	  	 (
 	  	  	  	  	  	  	 (Expiration_Date < @ET and Effective_Date >= @ST)
 	  	  	  	  	  	  	 or
 	  	  	  	  	  	  	 (Effective_Date <= @ST and Expiration_Date > @ST)
 	  	  	  	  	  	  	 or
 	  	  	  	  	  	  	 (@ST Between Effective_Date and Expiration_Date)
 	  	  	  	  	  	  	 or
 	  	  	  	  	  	  	 (@ET between Effective_Date and Expiration_Date)
 	  	  	  	  	  	  	 or
 	  	  	  	  	  	  	 (Effective_Date between @ST and @ET and Expiration_Date is null)
 	  	  	  	  	 )
 	  	  	 If @@RowCount = 0
 	  	  	  	 Insert Into @Temp(ProductId, StartTime, EndTime)
 	  	  	  	 Select @PD,@ST, @ET
 	  	  	 Update @Temp Set StartTime = @ST where StartTime < @ST
 	  	  	 Update @Temp Set EndTime = @ET where EndTime Is Null
 	  	  	 Update @Temp Set EndTime = @ET where EndTime > @ET
 	  	  	 Insert Into @SpecChangeTable
 	  	  	  	 Select * from @Temp
 	  	  	 Delete from @Temp
 	  	  	 Fetch Next From MyCursor Into @ST, @ET, @PD 
 	  	 End 
 	 Close MyCursor
 	 Deallocate MyCursor
 	 ------------------------------------------------
 	 -- Update @UnitTimes Table With Spec Changes
 	 ------------------------------------------------
 	 If (Select Count(*) From @SpecChangeTable) >0
 	 Begin
 	  	 Delete From @UnitTimes
 	  	 Insert Into @UnitTimes(StartTime, EndTime, ProductId)
 	  	  	 Select StartTime, EndTime, ProductId From @SpecChangeTable order by StartTime
 	 End
 	 
  End -- If @ProductionSpecification Is Not Null
-- End Change
---------------------------------------------
-- Main Loop For Downtime and Production
---------------------------------------------
Declare @@StartTime datetime, @@EndTime datetime, @@ProductId int
Declare Unit_Time_Cursor Insensitive Cursor 
  For Select StartTime, EndTime, ProductId From @UnitTimes 
  For Read Only
Open Unit_Time_Cursor
Fetch Next From Unit_Time_Cursor Into @@StartTime, @@EndTime, @@ProductId
While @@Fetch_Status = 0
 	 Begin
 	  	 If @@StartTime <> @@EndTime
 	  	 Begin
 	  	  	 Select @iTotalTime = datediff(second,@@StartTime, @@EndTime)
 	  	  	 -- Get Downtime Statistics
 	  	  	 execute dbo.spCMN_GetUnitDowntime
 	  	  	  	 @Unit,
 	  	  	  	 @@StartTime, 
 	  	  	  	 @@EndTime,
 	  	  	  	 @@ProductId, 
 	  	  	  	 @iActualRunMinutes OUTPUT,
 	  	  	  	 @iActualUnavailableMinutes OUTPUT,
 	  	  	  	 @iActualDownMinutes OUTPUT,
 	  	  	  	 @iTargetDownMinutes OUTPUT,
 	  	  	  	 @iWarningDownMinutes OUTPUT,
 	  	  	  	 @iRejectDownMinutes OUTPUT,
 	  	  	  	 @Status OUTPUT,
 	  	  	  	 @iActualDowntimeCount OUTPUT, 
 	  	  	  	 0 ,--@FilterNonProductiveTime
 	  	  	  	 @iActualLoadtimeMinutes OUTPUT,
 	  	  	  	 @iActualPerformanceDTMinutes OUTPUT 	  	  	  	 
 	  	  	 -- Totalize Downtime Statistics
 	  	  	 Select @TotalLoadingTimeMinutes = @TotalLoadingTimeMinutes + coalesce(@iActualLoadtimeMinutes, 0)
 	  	  	 Select @TotalRunMinutes = @TotalRunMinutes + coalesce(@iActualRunMinutes,0)
 	  	  	 Select @TotalUnavailableMinutes = @TotalUnavailableMinutes + coalesce(@iActualUnavailableMinutes,0)
 	  	  	 Select @TotalDownMinutes = @TotalDownMinutes + coalesce(@iActualDownMinutes,0)
 	  	  	 Select @TotalTargetDownMinutes = @TotalTargetDownMinutes + coalesce(@iTargetDownMinutes,0)
 	  	  	 Select @TotalWarningDownMinutes = @TotalWarningDownMinutes + coalesce(@iWarningDownMinutes,0)
 	  	  	 Select @TotalRejectDownMinutes = @TotalRejectDownMinutes + coalesce(@iRejectDownMinutes,0)
 	  	  	 Select @TotalDowntimeCount = @TotalDowntimeCount + coalesce(@iActualDowntimeCount,0)
 	  	  	 Select @TotalPerformanceDTMinutes = @TotalPerformanceDTMinutes + coalesce(@iActualPerformanceDTMinutes,0)
 	  	  	 execute dbo.spCMN_GetUnitProduction
 	  	  	  	   @Unit,
 	  	  	  	   @@StartTime, 
 	  	  	  	   @@EndTime,
 	  	  	  	   @@ProductID, 
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
 	  	  	  	   @TimeEngineeringUnits OUTPUT,
 	  	  	  	   0, --@FilterNonProductiveTime
 	  	  	  	   @iActualRunMinutes,
 	  	  	  	   @iActualLoadtimeMinutes,
 	  	  	  	   @iActualPerformanceDTMinutes
 	  	  	 
 	  	  	 -- This value is compensated for 
 	  	  	 -- in spCmn_GetUnitProduction
 	  	  	 -- Adjust Ideal Production By Available Time 	  	 
 	  	  	 -- Select @iIdealProduction = @iIdealProduction * ((convert(FLOAT,@iTotalTime) / 60.0) - coalesce(@iActualUnavailableMinutes,0)) / (convert(FLOAT,@iTotalTime) / 60.0)
 	  	  	 -- Totalize Production Statistics
 	  	  	 Select @TotalProduction = @TotalProduction + coalesce(@iActualProduction,0) -- NOTE: This is Total NET Production
 	  	  	 Select @TotalQualityLoss = @TotalQualityLoss + coalesce(@iActualQualityLoss,0)
 	  	  	 Select @TotalYieldLoss = @TotalYieldLoss + coalesce(@iActualYieldLoss,0)
 	  	  	 Select @TotalIdealYield = @TotalIdealYield + coalesce(@iIdealYield,0)  -- NOTE: This is Total TOTAL Production (theoretical yeild)
 	  	  	 Select @TotalIdealProduction = @TotalIdealProduction + coalesce(@iIdealProduction,0)
 	  	  	 If @iTotalTime > 0
 	  	  	  	 Begin
 	  	  	  	  	 Select @TotalWarningProduction = @TotalWarningProduction + (coalesce(@iWarningProduction,0)  * ((convert(FLOAT,@iTotalTime) / 60.0) - coalesce(@iActualUnavailableMinutes,0)) / (convert(FLOAT,@iTotalTime) / 60.0)) 
 	  	  	  	  	 Select @TotalRejectProduction = @TotalRejectProduction + (coalesce(@iRejectProduction,0) * ((convert(FLOAT,@iTotalTime) / 60.0) - coalesce(@iActualUnavailableMinutes,0)) / (convert(FLOAT,@iTotalTime) / 60.0))
 	  	  	  	 End
 	  	  	 Else
 	  	  	  	 Begin
 	  	  	  	  	 Select @TotalWarningProduction = 0
 	  	  	  	  	 Select @TotalRejectProduction = 0
 	  	  	  	 End
 	  	  	 Select @TotalTargetQualityLoss = @TotalTargetQualityLoss + coalesce(@iTargetQualityLoss,0)
 	  	  	 Select @TotalWarningQualityLoss = @TotalWarningQualityLoss + coalesce(@iWarningQualityLoss,0)
 	  	  	 Select @TotalRejectQualityLoss = @TotalRejectQualityLoss + coalesce(@iRejectQualityLoss,0)
 	  	  	 Select @TotalActualTotalItems = @TotalActualTotalItems + coalesce(@iActualTotalItems,0)
 	  	  	 Select @TotalActualGoodItems = @TotalActualGoodItems + coalesce(@iActualGoodItems,0)
 	  	  	 Select @TotalActualBadItems = @TotalActualBadItems + coalesce(@iActualBadItems,0)
 	  	  	 Select @TotalActualConformanceItems = @TotalActualConformanceItems + coalesce(@iActualConformanceItems,0)
 	  	  	 -- Calculate Downtime Loss Based On Ideal Production Rate
 	  	  	 Select @iActualDownLoss  = @iActualDownMinutes  * @iIdealRate
 	  	  	 Select @iTargetDownLoss  =  @iTargetDownMinutes * @iIdealRate
 	  	  	 Select @iWarningDownLoss = @iWarningDownMinutes * @iIdealRate
 	  	  	 Select @iRejectDownLoss  = @iRejectDownMinutes  * @iIdealRate
 	  	  	 -- Totalize Downtime Loss
 	  	  	 Select @TotalDownLoss        = @TotalDownLoss + coalesce(@iActualDownLoss,0)
 	  	  	 Select @TotalTargetDownLoss  = @TotalTargetDownLoss + coalesce(@iTargetDownLoss,0)
 	  	  	 Select @TotalWarningDownLoss = @TotalWarningDownLoss + coalesce(@iWarningDownLoss,0)
 	  	  	 Select @TotalRejectDownLoss  = @TotalRejectDownLoss + coalesce(@iRejectDownLoss,0)
 	  	  	 -- Calculate Speed Loss
 	  	  	 Select @iActualSpeedLoss = @iIdealProduction - (@iActualProduction + coalesce(@iActualDownLoss,0) + coalesce(@iActualQualityLoss,0) + coalesce(@iActualYieldLoss,0))
 	  	  	 -- Totalize Speed Loss
 	  	  	 Select @TotalSpeedLoss   = @TotalSpeedLoss + coalesce(@iActualSpeedLoss,0)
 	  	  	 -- Fetch OEE Specification
 	  	  	 Select @TargetPercent  = NULL
 	  	  	 Select @WarningPercent = NULL
 	  	  	 Select @RejectPercent  = NULL
 	  	  	 If @OEESpecification Is Not Null
 	  	  	   Begin
 	  	  	  	    Select @OEECharacteristic = char_id
 	  	  	  	    From pu_characteristics 
 	  	  	  	    Where prop_id = @OEEProperty and
 	  	  	  	  	  prod_id = @@ProductId and
 	  	  	  	  	  pu_id = @Unit
 	  	  	   
 	  	  	   
 	  	  	  	    If @OEECharacteristic Is Not NUll
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  Select @TargetPercent = convert(FLOAT,target), 
 	  	  	  	  	  	  	  	   @WarningPercent = convert(FLOAT, l_warning),
 	  	  	  	  	  	  	  	   @RejectPercent = convert(FLOAT, l_reject)
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
 	  	  	  	    -- New Calc Including Pro-Ration
 	  	  	  	    select @iActualOEE = dbo.fnCMN_GetEfficiencyVariableOEE(@Unit, @@StartTime, @@EndTime) 	  	  	  	    
 	  	  	   End
 	  	  	 -- Normalize And Total OEE and OEE Specs
 	  	  	 Select @TotalActualOEE  = @TotalActualOEE  + coalesce(@iActualOEE * @iIdealProduction,0)
 	  	  	 Select @TotalTargetOEE  = @TotalTargetOEE  + coalesce((Case When @TargetPercent Is Null Then @iActualOEE Else @TargetPercent End) * @iIdealProduction,0)
 	  	  	 Select @TotalWarningOEE = @TotalWarningOEE + coalesce((Case When @WarningPercent Is Null Then @iActualOEE Else @WarningPercent End) * @iIdealProduction,0)
 	  	  	 Select @TotalRejectOEE  = @TotalRejectOEE  + coalesce((Case When @RejectPercent Is Null Then @iActualOEE Else @RejectPercent End) * @iIdealProduction,0)
 	  	 End
 	  	 Fetch Next From Unit_Time_Cursor Into @@StartTime, @@EndTime, @@ProductId
  End
Close Unit_Time_Cursor
Deallocate Unit_Time_Cursor  
--Ensure Total Waste Is Not Greater Than Total Production
Select @TotalQualityLoss = Case When @TotalQualityLoss > @TotalProduction Then @TotalProduction Else @TotalQualityLoss End
--*****************************************************
-- Make Final Calculations
--*****************************************************
Select @TotalTime = datediff(second,@StartTime, @EndTime)
Select @IdealProduction          = @TotalIdealProduction
Select @IdealYield               = @TotalIdealYield
Select @ActualProduction         = @TotalProduction
Select @ActualQualityLoss        = @TotalQualityLoss
Select @ActualYieldLoss          = @TotalYieldLoss
Select @ActualSpeedLoss          = @TotalSpeedLoss
Select @ActualDowntimeLoss       = @TotalDownLoss
Select @ActualDowntimeMinutes    = @TotalDownMinutes
Select @ActualRuntimeMinutes     = @TotalRunMinutes
Select @ActualUnavailableMinutes = @TotalUnavailableMinutes
Select @ActualSpeed              = Convert(Decimal(25, 2),case when @TotalRunMinutes > 0 then (@TotalProduction + @TotalQualityLoss) / @TotalRunMinutes else 0.0 end)
Select @ActualPercentOEE         = Case when @TotalIdealProduction > 0 then @TotalActualOEE / @TotalIdealProduction else 100.0 end
Select @TargetProduction         = @TotalIdealProduction - @TotalTargetQualityLoss - @TotalTargetDownLoss
Select @WarningProduction        = @TotalWarningProduction
Select @RejectProduction         = @TotalRejectProduction 
Select @TargetQualityLoss        = @TotalTargetQualityLoss
Select @WarningQualityLoss       = @TotalWarningQualityLoss
Select @RejectQualityLoss        = @TotalRejectQualityLoss
Select @TargetDowntimeLoss       = @TotalTargetDownLoss
Select @WarningDowntimeLoss      = @TotalWarningDownLoss
Select @RejectDowntimeLoss       = @TotalRejectDownLoss
--------------------------------------------------------------------
-- When NO Customer OEE Efficiency Variable Is Defined Then 
-- Calculate OEE AS NORMAL
--
-- Otherwise, Use the Customer Supplied Variable
--------------------------------------------------------------------
If @OEEVariable Is Null
 	 Select @ActualPercentOEE = OEE from dbo.fnCMN_OEERates(@ActualRuntimeMinutes, @TotalLoadingTimeMinutes, @TotalPerformanceDTMinutes, @ActualProduction, @IdealProduction, @ActualQualityLoss)
Else
 	 select @ActualPercentOEE = @iActualOEE 
-- Erik's Original Formula:
--Select @TargetSpeed = (@TotalIdealProduction - @TotalTargetDownLoss) / ((@TotalTime / 60.0) - @TotalTargetDownMinutes) 
/*
=====================  TARGET SPEED CALCULATION   ==========================
GetUnitStatistics is a summary stored procedure and the calculation below 
can be used to derive the original target speed specification.
In procedure spCMN_GetUnitProduction, the TargetSpeed (or Rate) is taken from 
fnCMN_GetUnitSpecsByProduct.  The value is ultimately taken from Active_Specs, pu_characteristics...
With that specification, an IdealProduction amount is calculated and passed back.  
A summary of the IdealProduction from (n) calls to spCMN_GetUnitProduction 
divided by the loading time will reveal what the original Target specification was.
When there is only 1 product, the TargetSpeed will be the original value as described
in the Product Specification.  When there is more than 1 product, it will be a 
weighted average.
============================================================================
*/
Select @TargetSpeed = case when @ActualRuntimeMinutes > 0 then Convert(Decimal(25,2),(@TotalIdealProduction / @ActualRuntimeMinutes)) else 0.0 end
------------------------------------
-- Time Engineering Units KEY
--      When 0 Then 'Hour'
--      When 1 Then 'Minute'
--      When 2 Then 'Second'
--      When 3 Then 'Day'
------------------------------------
Select @ActualSpeed = Case
 	 When @TimeEngineeringUnits = 0 Then @ActualSpeed * 60.0 
 	 When @TimeEngineeringUnits = 2 Then @ActualSpeed / 60.0
 	 When @TimeEngineeringUnits = 3 Then @ActualSpeed * 1440
 	 Else @ActualSpeed End
Select @TargetSpeed = Case
 	 When @TimeEngineeringUnits = 0 Then @TargetSpeed * 60.0 
 	 When @TimeEngineeringUnits = 2 Then @TargetSpeed / 60.0
 	 When @TimeEngineeringUnits = 3 Then @TargetSpeed * 1440
 	 Else @TargetSpeed End
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
--Print ''
--Print '==========================================='
--Print '==         dbo.fnCMN_OEERates            =='
--Print '==========================================='
--Select * from dbo.fnCMN_OEERates(@ActualRuntimeMinutes, @TotalLoadingTimeMinutes, @ActualProduction, @IdealProduction, @ActualQualityLoss)
Print ''
Print '==========================================='
Print '==       spCMN_GetUnitStatistics         =='
Print '==========================================='
Print '-- Input Values --'
Print '@StartTime                  = ' + Convert(Varchar(25), @StartTime, 120)
Print '@EndTime                    = ' + Convert(Varchar(25), @EndTime, 120)
Print '@Unit                       = ' + Convert(Varchar(5), @Unit)
Print ''
Print '@TotalLoadingTimeMinutes    = ' + coalesce(convert(varchar(25), convert(decimal(25,2), @TotalLoadingTimeMinutes)), 'unkn')
Print ''
Print '-- Output Values --'
PRINT '@IdealProduction            = ' + coalesce(convert(varchar(25), convert(decimal(25,2), @IdealProduction)), 'NULL')
PRINT '@IdealYield                 = ' + coalesce(LTrim(Str(@IdealYield, 25, 2)),'NULL')
PRINT '@ActualProduction           = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualProduction)),'NULL')
PRINT '@ActualQualityLoss          = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualQualityLoss)),'NULL')
PRINT '@ActualYieldLoss            = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualYieldLoss)),'NULL')
PRINT '@ActualSpeedLoss            = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualSpeedLoss)),'NULL')
PRINT '@ActualDowntimeLoss         = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@ActualDowntimeLoss)),'NULL')
PRINT '@ActualDowntimeMinutes      = ' + coalesce(convert(varchar(25), @ActualDowntimeMinutes),'NULL')
PRINT '@ActualRuntimeMinutes       = ' + coalesce(convert(varchar(25), @ActualRuntimeMinutes),'NULL')
PRINT '@ActualUnavailableMinutes   = ' + coalesce(convert(varchar(25), @ActualUnavailableMinutes),'NULL')
PRINT '@ActualSpeed                = ' + coalesce(convert(varchar(25), @ActualSpeed),'NULL')
PRINT '@ActualPercentOEE           = ' + coalesce(convert(varchar(25), @ActualPercentOEE),'NULL')
PRINT '@TargetProduction           = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@TargetProduction)),'NULL')
PRINT '@WarningProduction          = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@WarningProduction)),'NULL')
PRINT '@RejectProduction           = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@RejectProduction)),'NULL')
PRINT '@TargetQualityLoss          = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@TargetQualityLoss)),'NULL')
PRINT '@WarningQualityLoss         = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@WarningQualityLoss)),'NULL')
PRINT '@RejectQualityLoss          = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@RejectQualityLoss)),'NULL')
PRINT '@TargetDowntimeLoss         = ' + coalesce(convert(varchar(25), convert(decimal(20,2),@TargetDowntimeLoss)),'NULL')
PRINT '@WarningDowntimeLoss        = ' + coalesce(convert(varchar(25), convert(decimal(15,2),@WarningDowntimeLoss)),'NULL')
PRINT '@RejectDowntimeLoss         = ' + coalesce(convert(varchar(25), convert(decimal(25,2),@RejectDowntimeLoss)),'NULL')
PRINT '@TargetSpeed                = ' + coalesce(convert(varchar(25), @TargetSpeed),'NULL')
PRINT '@TargetDowntimeMinutes      = ' + coalesce(convert(varchar(25), @TargetDowntimeMinutes),'NULL')
PRINT '@WarningDowntimeMinutes     = ' + coalesce(convert(varchar(25), @WarningDowntimeMinutes),'NULL')
PRINT '@RejectDowntimeMinutes      = ' + coalesce(convert(varchar(25), @RejectDowntimeMinutes),'NULL')
PRINT '@TargetPercentOEE           = ' + coalesce(convert(varchar(25), @TargetPercentOEE),'NULL')
PRINT '@WarningPercentOEE          = ' + coalesce(convert(varchar(25), @WarningPercentOEE),'NULL')
PRINT '@RejectPercentOEE           = ' + coalesce(convert(varchar(25), @RejectPercentOEE),'NULL')
PRINT '@ActualTotalItems           = ' + coalesce(convert(varchar(25), @TotalActualTotalItems),'NULL')
PRINT '@ActualGoodItems            = ' + coalesce(convert(varchar(25), @TotalActualGoodItems),'NULL')
PRINT '@ActualBadItems             = ' + coalesce(convert(varchar(25), @TotalActualBadItems),'NULL')
PRINT '@ActualConformanceItems     = ' + coalesce(convert(varchar(25), @TotalActualConformanceItems),'NULL')
PRINT '@DowntimePercent            = ' + coalesce(convert(varchar(25), @ActualDowntimeMinutes / convert(FLOAT,(@ActualDowntimeMinutes + @ActualRuntimeMinutes)) * 100.0),'NULL')
PRINT '@WastePercent               = ' + coalesce(convert(varchar(25), (@ActualQualityLoss + @ActualYieldLoss) /  convert(FLOAT,(@ActualQualityLoss + @ActualProduction + @ActualYieldLoss)) * 100.0),'NULL')
PRINT '@ActualDowntimeCount        = ' + coalesce(convert(varchar(25), @ActualDowntimeCount),'NULL')
PRINT '@TimeEngineeringUnits       = ' + coalesce(convert(varchar(25), @TimeEngineeringUnits),'NULL')
PRINT '@TotalLoadingTimeMinutes    = ' + coalesce(convert(varchar(25), @TotalLoadingTimeMinutes),'NULL')
PRINT '@TotalPerformanceDTMinutes  = ' + coalesce(convert(varchar(25), @TotalPerformanceDTMinutes),'NULL')
--*****************************************************/
