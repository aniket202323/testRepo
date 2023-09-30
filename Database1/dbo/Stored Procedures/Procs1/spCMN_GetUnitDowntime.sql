CREATE Procedure dbo.spCMN_GetUnitDowntime
@Unit int,
@StartTime datetime, 
@EndTime datetime,
@ReferenceProduct int, 
@ActualRunMinutes FLOAT OUTPUT, 	  	  	  	  	  	 -- Running Time
@ActualUnavailableMinutes FLOAT OUTPUT, 	  	  	  	 -- Scheduled Downtime
@ActualDownMinutes FLOAT OUTPUT, 	  	  	  	  	  	 -- TOTAL Downtime (unplanned)
@TargetDownMinutes FLOAT OUTPUT, 	  	  	  	  	  	 -- TOTAL Downtime Target
@WarningDownMinutes FLOAT OUTPUT, 	  	  	  	  	 -- TOTAL Downtime Warning
@RejectDownMinutes FLOAT OUTPUT, 	  	  	  	  	  	 -- TOTAL Downtime Reject
@Status int OUTPUT, 	  	  	  	  	  	  	  	  	 
@EventCount int OUTPUT,
@FilterNonProductiveTime int = 0,
@LoadingTimeMinutes FLOAT = null OUTPUT,
@PerformanceDowntimeMinutes FLOAT = null OUTPUT
AS
--***************************************************/
Declare @DowntimeProperty int
Declare @DowntimeCharacteristic int
Declare @DowntimeSpecification int
Declare @UnavailableCategory int
Declare @TargetPercent FLOAT
Declare @WarningPercent FLOAT
Declare @RejectPercent FLOAT
Declare @TotalDowntime int
Declare @TotalTime int
--*****************************************************
-- Look Up Unit, Specification Information
--*****************************************************
Select @TargetPercent=TargetPercent, @WarningPercent=WarningPercent, @RejectPercent=RejectPercent  
From dbo.fnCMN_GetSpecTargetsByProduct(@StartTime, @EndTime, @Unit, @ReferenceProduct)
--*****************************************************
-- Get Status And End Time
--*****************************************************
Select @Status = Tedet_id
  From Timed_Event_Details
  Where PU_Id = @Unit and End_Time Is Null
If @Status Is Null
  Select @Status = 1
Else
  Select @Status = 0
--*****************************************************
-- Calculate Return Stuff
--*****************************************************
--Declare @PerformanceDowntimeMinutes FLOAT  -- Minor Stops
Declare @TotalOutsideAreaMinutes FLOAT     -- Line Restraint
--Declare @LoadingTimeMinutes FLOAT         -- TOTAL Loading Time (minutes)
Declare @TotalTimeMinutes int
/*
-- don't need this call anymore, all required data comes back from fnCMN_GetOutsideAreaTimeByUnit
Select @TotalDowntime=TotalDowntimeSeconds, @EventCount=TotalCount 
From dbo.fnCMN_GetTotalDowntimeByUnit(@StartTime, @EndTime, @Unit, @FilterNonProductiveTime)
*/
-- Correct DowntimeSeconds in function
-- Replaces code from above
Select  
 	 @TotalTimeMinutes = TotalSeconds / 60, 
 	 @TotalDowntime = DowntimeSeconds,
 	 @TotalOutsideAreaMinutes = OutsideAreaSeconds / 60.0,
 	 @PerformanceDowntimeMinutes = PerformanceDowntimeSeconds / 60.0,
 	 @LoadingTimeMinutes = LoadingSeconds / 60.0,
 	 @ActualDownMinutes = DowntimeSeconds / 60.0,
 	 @ActualRunMinutes = RunningSeconds / 60.0,
 	 @ActualUnavailableMinutes =  UnavailableSeconds / 60.0,
 	 @EventCount = DowntimeCount
From dbo.fnCMN_GetOutsideAreaTimeByUnit(@StartTime, @EndTime, @Unit, @FilterNonProductiveTime)
-----------------------------
-- Calculate TARGET PERCENT
-----------------------------
If @TargetPercent Is Null
   	 Select @TargetDownMinutes = @ActualDownMinutes
Else
 	 Select @TargetDownMinutes = (@ActualRunMinutes * @TargetPercent) / 100.0
-----------------------------
-- Calculate WARNING PERCENT
-----------------------------
If @WarningPercent Is Null
 	 Select @WarningDownMinutes = @ActualDownMinutes
Else
 	 Select @WarningDownMinutes = (@ActualRunMinutes * @WarningPercent) / 100.0
-----------------------------
-- Calculate REJECT PERCENT
-----------------------------
If @RejectPercent Is Null
 	 Select @RejectDownMinutes = @ActualDownMinutes
Else
 	 Select @RejectDownMinutes = (@ActualRunMinutes * @RejectPercent) / 100.0
/*****************************************************
-- For Testing
--*****************************************************
Print '@TotalTimeMinutes           = ' + Convert(varchar(20), @TotalTimeMinutes)
Print '@ActualUnavailableMinutes   = ' + Convert(varchar(20), @ActualUnavailableMinutes)
Print '@TotalOutsideAreaMinutes    = ' + Convert(varchar(20), @TotalOutsideAreaMinutes)
Print '@LoadingTimeMinutes         = ' + Convert(varchar(20), @LoadingTimeMinutes)
Print '@ActualDownMinutes          = ' + Convert(varchar(20), @ActualDownMinutes)
Print '@ActualRunMinutes           = ' + Convert(varchar(20), @ActualRunMinutes)
Print '@PerformanceDowntimeMinutes = ' + Convert(varchar(20), @PerformanceDowntimeMinutes / 60)
Print '@TargetDownMinutes          = ' + Convert(varchar(20), @TargetDownMinutes)
Print '@WarningDownMinutes         = ' + Convert(varchar(20), @WarningDownMinutes)
Print '@RejectDownMinutes          = ' + Convert(varchar(20), @RejectDownMinutes)
Print ''
Print '========================================='
Print '== spCMN_GetUnitDowntime Return Values =='
Print '========================================='
Print  '@ActualRunMinutes         = ' + convert(varchar(25), convert(decimal(15,2),@ActualRunMinutes))
Print  '@ActualUnavailableMinutes = ' + convert(varchar(25), convert(decimal(15,2),@ActualUnavailableMinutes))
Print  '@ActualDownMinutes        = ' + convert(varchar(25), convert(decimal(15,2),@ActualDownMinutes))
Print  '@TargetDownMinutes        = ' + convert(varchar(25), convert(decimal(15,2),@TargetDownMinutes))
Print  '@WarningDownMinutes       = ' + convert(varchar(25), convert(decimal(15,2),@WarningDownMinutes))
Print  '@RejectDownMinutes        = ' + convert(varchar(25), convert(decimal(15,2),@RejectDownMinutes))
Print  '@Status                   = ' + convert(varchar(25), @Status)
Print  '@EventCount               = ' + convert(varchar(25), @EventCount)
--*****************************************************/
