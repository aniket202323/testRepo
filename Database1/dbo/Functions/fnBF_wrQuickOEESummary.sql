﻿/*
    select * from 
 	 dbo.fnBF_wrQuickOEESummary (1,'10/26/2015 9:30','10/26/2015 10:00','Eastern Standard Time',0,4,0)
*/
CREATE FUNCTION [dbo].[fnBF_wrQuickOEESummary](
 	 @PUId                    Int,
 	 @StartTime               datetime = NULL,
 	 @EndTime                 datetime = NULL,
 	 @InTimeZone 	  	  	  	  nvarchar(200) = null,
 	 @FilterNonProductiveTime int = 0,
 	 @ReportType Int = 1,
 	 @IncludeSummary Int = 0)
RETURNS  @unitData Table(ProductId int null,
   	    	    	    	    	    	    	    	  Product nVarchar(100),
   	    	    	    	    	    	    	    	  IdealSpeed Float DEFAULT 0,
   	    	    	    	    	    	    	    	  ActualSpeed Float DEFAULT 0,
   	    	    	    	    	    	    	    	  IdealProduction Float DEFAULT 0,
   	    	    	    	    	    	    	    	  PerformanceRate Float DEFAULT 0,
   	    	    	    	    	    	    	    	  NetProduction Float DEFAULT 0,
   	    	    	    	    	    	    	    	  Waste Float DEFAULT 0,
   	    	    	    	    	    	    	    	  QualityRate Float DEFAULT 0,
   	    	    	    	    	    	    	    	  PerformanceDowntime Float DEFAULT 0,
   	    	    	    	    	    	    	    	  RunTime Float DEFAULT 0,
   	    	    	    	    	    	    	    	  Loadtime Float DEFAULT 0,
   	    	    	    	    	    	    	    	  AvaliableRate Float DEFAULT 0,
   	    	    	    	    	    	    	    	  OEE Float DEFAULT 0)
AS
BEGIN
SELECT @StartTime = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
SELECT @endTime = dbo.fnServer_CmnConvertToDbTime(@endTime,@InTimeZone)
/*
 @ReportType - ***** Only the indicated types have been tested! *****
1 DaySummary
2 ShiftSummary 
3 CrewSummary
4 ProductSummary (Tested)
5 ProcessOrderSummary
6 EventSummary
7 OverallSummary (Tested)
*/
/********************************************************************
* 	  	  	  	  	  	  	 Declarations 	  	  	  	  	  	  	 *
********************************************************************/
DECLARE 	 -- General
 	  	 @Rows 	  	  	  	  	  	  	 int,
 	  	 @rptParmDisplayESignature 	  	 int = 0, 	 -- 1 - ESignature Required
 	  	 @rptParmDisplayProductCode 	  	 int = 0, 	 -- 1 - Product Code, 0 - Product Desc
 	  	 @rptParmProductionDaySummary 	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmProductSummary 	  	  	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmShiftSummary 	  	  	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmCrewSummary 	  	  	  	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmProcessOrderSummary 	  	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmEventSummary 	  	  	 int, 	 -- 1 - Summary Selected
 	  	 -- Tables
 	  	 @EventsTableId 	  	  	  	  	 int,
 	  	 @ProductionStartsTableId 	  	 int,
 	  	 @CrewScheduleTableId 	  	  	 int,
 	  	 @ProductionDaysTableId 	  	  	 int,
 	  	 @ProductionPlanStartsTableId 	 int,
 	  	 @NonProductiveTableId 	  	  	 int,
 	  	 @DowntimeSpecsTableId 	  	  	 int,
 	  	 @ProductionSpecsTableId 	  	  	 int,
 	  	 @WasteSpecsTableId 	  	  	  	 int,
 	  	 -- Unit Configuration
 	  	 @ScheduledCategoryId 	  	  	 int,
 	  	 @ExternalCategoryId 	  	  	  	 int,
 	  	 @DowntimePropId 	  	  	  	  	 int,
 	  	 @DowntimeSpecId 	  	  	  	  	 int,
 	  	 @PerformanceCategoryId 	  	  	 int,
 	  	 @ProductionPropId 	  	  	  	 int,
 	  	 @ProductionSpecId 	  	  	  	 int,
 	  	 @ProductionRateFactor 	  	  	 Float,
 	  	 @ProductionType 	  	  	  	  	 tinyint,
 	  	 @ProductionVarId 	  	  	  	 int,
 	  	 @ProductionStartTime 	  	  	 tinyint,
 	  	 @WastePropId 	  	  	  	  	 int,
 	  	 @WasteSpecId 	  	  	  	  	 int,
 	  	 @NPCategoryId 	  	  	  	  	 int,
 	  	 @EfficiencySpecId 	  	  	  	 int,
 	  	 -- Site Parameters
 	  	 @CapRates 	  	  	  	  	  	 tinyint,
 	  	 -- Engineering Units
 	  	 @AmountEngineeringUnits 	  	  	 nvarchar(25), 
 	  	 @ItemEngineeringUnits 	  	  	 nvarchar(25), 
 	  	 @TimeEngineeringUnits 	  	  	 int, 
 	  	 @TimeUnitDesc 	  	  	  	  	 nvarchar(25),
 	  	 -- Other
 	  	 @ReturnValue 	  	  	  	  	 nvarchar(max),
 	  	 @rsOverall 	  	  	  	  	  	 int,
 	  	 @rsSlices1 	  	  	  	  	  	 int,
 	  	 @ProficyDashBoardPath 	  	  	 nvarchar(50),
 	  	 @Debug 	  	  	  	  	  	  	 int,
 	  	 @RSID 	  	  	  	  	  	  	 int,
 	  	 @CriteriaString 	  	  	  	  	 nvarchar(1000),
 	  	 @NPTLabel 	  	  	  	  	  	 nvarchar(255),
 	  	 @NPTLabelDefault 	  	  	  	 nvarchar(255),
 	  	 @LoopCount 	  	  	  	  	  	 int,
 	  	 @MaxLoops 	  	  	  	  	  	 int,
 	  	 @LastRunStartTime 	  	  	  	 datetime,
 	  	 @CurrentRunStartTime 	  	  	 datetime,
 	  	 @CurrentRunEndTime 	  	  	  	 datetime,
 	  	 @CurrentRunProdId 	  	  	  	 int,
 	  	 @CurrentRunProdCodeDesc 	  	  	 nvarchar(50),
 	  	 @CurrentRunMRPId 	  	  	  	 int,
 	  	 @MaxStartId 	  	  	  	  	  	 int,
 	  	 @InitialDimensionPrecision 	  	 int
 	  	 
    --'SummarizeByDay'
 	  	 IF @ReportType = 1 SET  	 @rptParmProductionDaySummary = 1 ELSE SET @rptParmProductionDaySummary = 0
 	  	 IF @ReportType = 2 SET  	 @rptParmShiftSummary = 1 ELSE SET @rptParmShiftSummary = 0
 	  	 IF @ReportType = 3 SET  	 @rptParmCrewSummary = 1 ELSE SET @rptParmCrewSummary = 0
 	  	 IF @ReportType = 4 SET  	 @rptParmProductSummary = 1 ELSE SET @rptParmProductSummary = 0
 	  	 IF @ReportType = 5 SET  	 @rptParmProcessOrderSummary = 1 ELSE SET @rptParmProcessOrderSummary = 0
 	  	 IF @ReportType = 6 SET  	 @rptParmEventSummary = 1 ELSE SET @rptParmEventSummary = 0
 	  	 IF @ReportType = 7 SET  @rsOverall = 1 ELSE SET @rsOverall = 0
-- The goal is to build a table with all the start times and then
-- at the end we'll fill in the end times.
DECLARE  @Periods TABLE( 	 PeriodId 	  	  	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 TableId 	  	  	  	 int,
 	  	  	  	  	  	 KeyId 	  	  	  	 int)
DECLARE @ProductionDays TABLE ( 	 DayId 	  	  	 int IDENTITY(1,1),
 	  	  	  	  	  	  	  	 StartTime 	  	 datetime PRIMARY KEY,
 	  	  	  	  	  	  	  	 EndTime 	  	  	 datetime,
 	  	  	  	  	  	  	  	 ProductionDay 	 datetime)
DECLARE @ProductionStarts Table(Id Int Identity(1,1),StartTime DateTime,EndTime DateTime,ProdId Int,PUId Int)
 	  	  	  	  	  	  	  	 
DECLARE  @Slices TABLE( 	 SliceId 	  	  	  	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 ProdDayProdId 	  	 nvarchar(75) DEFAULT null ,
 	  	  	  	  	  	 ProdIdSubGroupId 	 nvarchar(50) DEFAULT null,
 	  	  	  	  	  	 StartId 	  	  	  	 int DEFAULT null,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 PUId 	  	  	  	 int,
 	  	  	  	  	  	 ProdId 	  	  	  	 int,
 	  	  	  	  	  	 Shift 	  	  	  	 nvarchar(10),
 	  	  	  	  	  	 Crew 	  	  	  	 nvarchar(10),
 	  	  	  	  	  	 ProductionDay 	  	 datetime,
 	  	  	  	  	  	 PPId 	  	  	  	 int,
 	  	  	  	  	  	 EventId 	  	  	  	 int,
 	  	  	  	  	  	 AppliedProdId 	  	 int,
 	  	  	  	  	  	 -- ESignature
 	  	  	  	  	  	 PerformUserId 	  	 int,
 	  	  	  	  	  	 VerifyUserId 	  	 int,
 	  	  	  	  	  	 PerformUserName 	  	 nvarchar(30), 
 	  	  	  	  	  	 VerifyUserName 	  	 nvarchar(30), 
 	  	  	  	  	  	 -- Other
 	  	  	  	  	  	 NP 	  	  	  	  	 bit DEFAULT 0,
 	  	  	  	  	  	 NPLabelRef 	  	  	 bit DEFAULT 0,
 	  	  	  	  	  	 DowntimeTarget 	  	 float,
 	  	  	  	  	  	 ProductionTarget 	 float,
 	  	  	  	  	  	 WasteTarget 	  	  	 float,
 	  	  	  	  	  	 -- Statistics
 	  	  	  	  	  	 CalendarTime 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 AvailableTime 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 LoadingTime 	  	  	 Float DEFAULT 0,
 	  	  	  	  	  	 RunTimeGross 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 ProductiveTime 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimePlanned 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimeExternal 	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimeUnplanned 	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimePerformance 	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimeTotal 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 ProductionCount 	  	 int DEFAULT 0,
 	  	  	  	  	  	 ProductionTotal 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 ProductionNet 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 ProductionIdeal 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 WasteQuantity 	  	 Float DEFAULT 0)
--CREATE NONCLUSTERED INDEX SNCIXNP ON @Slices (NP)
--CREATE NONCLUSTERED INDEX SNCIXNPLabelRef ON @Slices (NPLabelRef)
--CREATE NONCLUSTERED INDEX SNCIXEventId ON @Slices (EventId)
--CREATE CLUSTERED INDEX SCIX ON @Slices (PUId, NP, StartTime)
DECLARE @SliceUpdate TABLE (
 	  	  	 SliceUpdateId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	 StartTime 	 datetime,
 	  	  	 EventId 	  	 int,
 	  	  	 ProdId 	  	 int
  	  	  	 )
DECLARE @ProcessOrderSubGroup TABLE(
 	  	  	 POSGId 	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	 ProdId 	  	  	 int,
 	  	  	 Counts 	  	  	 int)
DECLARE  @rsSlices TABLE(RSSliceId 	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	 ProdDayProdId 	  	 nvarchar(75) DEFAULT null,
 	  	  	  	 ProdIdSubGroupId 	 nvarchar(50) DEFAULT null,
 	  	  	  	 StartId 	  	  	  	 int 	 DEFAULT null,
 	  	  	  	 RSSubGroup 	  	  	 int,
 	  	  	  	 SortReference 	  	 nvarchar(50) 	 DEFAULT null,
 	  	  	  	 ProductionDay 	  	 nvarchar(50) 	 DEFAULT null,
 	  	  	  	 ShiftDesc 	  	  	 nvarchar(50) 	 DEFAULT null,
 	  	  	  	 CrewDesc 	  	  	 nvarchar(50) 	 DEFAULT null,
 	  	  	  	 PPId 	  	  	  	 int DEFAULT null,
 	  	  	  	 ProdId 	  	  	  	 int DEFAULT null,
 	  	  	  	 EventId 	  	  	  	 int DEFAULT null,
 	  	  	  	 NPLabelRef 	  	  	 int DEFAULT 0,
 	  	  	  	 ProcessOrder 	  	 nvarchar(50) 	 DEFAULT null,
 	  	  	  	 Product 	  	  	  	 nvarchar(50) 	 DEFAULT null,
 	  	  	  	 IdealSpeed 	  	  	 Float DEFAULT 0,
 	  	  	  	 ActualSpeed 	  	  	 Float DEFAULT 0,
 	  	  	  	 IdealProd 	  	  	 Float DEFAULT 0,
 	  	  	  	 PerfRate 	  	  	 Float DEFAULT 0,
 	  	  	  	 NetProd 	  	  	  	 Float DEFAULT 0,
 	  	  	  	 Waste 	  	  	  	 Float DEFAULT 0,
 	  	  	  	 QualRate 	  	  	 Float DEFAULT 0,
 	  	  	  	 PerfDT 	  	  	  	 Float DEFAULT 0,
 	  	  	  	 RunTime 	  	  	  	 Float DEFAULT 0,
 	  	  	  	 LoadTime 	  	  	 Float DEFAULT 0,
 	  	  	  	 AvailRate 	  	  	 Float DEFAULT 0,
 	  	  	  	 OEE 	  	  	  	  	 Float DEFAULT 0
 	  	  	  	 ) 	  	  	 
--CREATE NONCLUSTERED INDEX RSSNCIX ON @rsSlices (RSSubGroup)
DECLARE @ProductRunCounts TABLE( 	 
 	  	  	  	 ProdId int UNIQUE,
 	  	  	  	 Counts int)
DECLARE   @MultipleRunProducts TABLE(
 	  	  	  	 MRPId int IDENTITY (1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	 ProdId int,
 	  	  	  	 ProdCodeDesc nvarchar(50),
 	  	  	  	 StartTime datetime,
 	  	  	  	 EndTime datetime,
 	  	  	  	 ProdIdMRPId nvarchar(50)
 	  	  	  	 )
--CREATE NONCLUSTERED INDEX RPNCIXProdId ON @MultipleRunProducts (ProdId)
--CREATE NONCLUSTERED INDEX RPNCIXStartTime ON @MultipleRunProducts (StartTime)
/*NLS Support Strings*/
Declare @SubTotalLabel nvarchar(20), @GrandTotalLabel nvarchar(20)
/********************************************************************
* 	  	  	  	  	  	  	 Initialization 	  	  	  	  	  	  	 *
********************************************************************/
SELECT 	 -- Table Ids
 	  	 @EventsTableId 	  	  	  	  	 = 1,
 	  	 @ProductionStartsTableId 	  	 = 2,
 	  	 @CrewScheduleTableId 	  	  	 = -1,
 	  	 @ProductionDaysTableId 	  	  	 = -2,
 	  	 @ProductionPlanStartsTableId 	 = 12,
 	  	 @NonProductiveTableId 	  	  	 = -3,
 	  	 @DowntimeSpecsTableId 	  	  	 = -4,
 	  	 @ProductionSpecsTableId 	  	  	 = -5,
 	  	 @WasteSpecsTableId 	  	  	  	 = -6,
 	  	 @InitialDimensionPrecision 	  	 = 2
/********************************************************************
* 	  	  	  	  	  	  	 Configuration 	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO  @ProductionStarts (ProdId,StartTime ,EndTime)
 	 SELECT ProdId , StartTime , EndTime FROM  dbo.fnBF_GetPSFromEvents(@PUId,@StartTime,@EndTime,16)   
 	 WHERE ProdId != 1
 	 Order by StartTime 
UPDATE @ProductionStarts set PUId = @PUId 
SELECT 	 -- Downtime
 	  	 @ScheduledCategoryId 	  	 = Downtime_Scheduled_Category,
 	  	 @ExternalCategoryId 	  	  	 = Downtime_External_Category, 	 -- Currently ignored
 	  	 @DowntimeSpecId 	  	  	  	 = Downtime_Percent_Specification,
 	  	 -- Production
 	  	 @PerformanceCategoryId 	  	 = Performance_Downtime_Category,
 	  	 @ProductionSpecId 	  	  	 = Production_Rate_Specification,
 	  	 @ProductionRateFactor 	  	 = dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits),
 	  	 @ProductionType 	  	  	  	 = Production_Type,
 	  	 @ProductionVarId 	  	  	 = Production_Variable,
 	  	 @ProductionStartTime 	  	 = Uses_Start_Time,
 	  	 -- Waste
 	  	 @WasteSpecId 	  	  	  	 = Waste_Percent_Specification,
 	  	 -- Non-Productive Time
 	  	 @NPCategoryId 	 = Non_Productive_Category,
 	  	 -- Efficiency
 	  	 @EfficiencySpecId 	  	  	 = Efficiency_Percent_Specification
FROM dbo.Prod_Units WITH (NOLOCK)
WHERE PU_Id = @PUId
SELECT 	 @DowntimePropId 	 = Prop_Id
FROM dbo.Specifications WITH (NOLOCK)
WHERE Spec_Id = @DowntimeSpecId
SELECT 	 @ProductionPropId 	 = Prop_Id
FROM dbo.Specifications WITH (NOLOCK)
WHERE Spec_Id = @ProductionSpecId
SELECT 	 @WastePropId 	 = Prop_Id
FROM dbo.Specifications WITH (NOLOCK)
WHERE Spec_Id = @WasteSpecId
SELECT 	 @CapRates = dbo.fnCMN_OEERateIsCapped()
/********************************************************************
* 	  	  	  	  	  	  	 Product Changes 	  	  	  	  	  	  	 *
********************************************************************/
-- Production starts always has to be contiguous so it's the best place to start
INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	 EndTime)
SELECT 	 @ProductionStartsTableId,
 	  	 Id,
 	  	 CASE 	 WHEN StartTime < @StartTime THEN @StartTime
 	  	  	  	 ELSE StartTime
 	  	  	  	 END,
 	  	 CASE  	 WHEN EndTime > @EndTime OR EndTime IS NULL THEN @EndTime
 	  	  	  	 ELSE EndTime
 	  	  	  	 END 	  	 
FROM @ProductionStarts 
/********************************************************************
* 	  	  	  	  	  	  	 Crew Schedule 	  	  	  	  	  	  	 *
********************************************************************/
IF @rptParmCrewSummary =1 or @rptParmShiftSummary = 1
BEGIN
 	 -- Add records for all crew starts
 	 INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime)
 	 SELECT 	 @CrewScheduleTableId,
 	  	  	 cs.CS_Id,
 	  	  	 StartTime 	 = CASE 	 WHEN cs.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	  	 ELSE cs.Start_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 EndTime 	  	 = CASE 	 WHEN cs.End_Time > @EndTime THEN @EndTime
 	  	  	  	  	  	  	  	 ELSE cs.End_Time
 	  	  	  	  	  	  	  	 END
 	 FROM dbo.Crew_Schedule cs WITH (NOLOCK)
 	 WHERE 	 PU_Id = @PUId
 	  	  	 AND End_Time > @StartTime
 	  	  	 AND Start_Time < @EndTime
END
/********************************************************************
* 	  	  	  	  	  	 Production Day 	  	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO @ProductionDays ( 	 StartTime,
 	  	  	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	  	  	 ProductionDay)
SELECT 	 StartTime,
 	  	 EndTime,
 	  	 ProductionDay
FROM dbo.fnGEPSGetProductionDays(  [dbo].[fnServer_CmnConvertFromDbTime](@StartTime,@InTimeZone),
 	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime](@EndTime,@InTimeZone))
Update @ProductionDays 
SET StartTime = [dbo].[fnServer_CmnConvertToDbTime](StartTime,@InTimeZone),
EndTime = [dbo].[fnServer_CmnConvertToDbTime](EndTime,@InTimeZone),
ProductionDay = [dbo].[fnServer_CmnConvertToDbTime](ProductionDay,@InTimeZone)
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @ProductionDaysTableId,
 	  	 DayId,
 	  	 StartTime,
 	  	 EndTime
FROM @ProductionDays
/********************************************************************
* 	  	  	  	  	  	 Production Order 	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @ProductionPlanStartsTableId,
 	  	 pps.PP_Start_Id,
 	  	 StartTime 	 = CASE 	 WHEN pps.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	 ELSE pps.Start_Time
 	  	  	  	  	  	  	 END,
 	  	 EndTime 	  	 = CASE 	 WHEN pps.End_Time > @EndTime THEN @EndTime
 	  	  	  	  	  	  	 ELSE pps.End_Time
 	  	  	  	  	  	  	 END
FROM dbo.Production_Plan_Starts pps WITH (NOLOCK)
WHERE 	 pps.PU_Id = @PUId
 	  	 AND pps.Start_Time < @EndTime
 	  	 AND (pps.End_Time > @StartTime OR pps.End_Time IS NULL)
/********************************************************************
* 	  	  	  	  	  	 Non-Productive Time 	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @NonProductiveTableId,
 	  	 np.NPDet_Id,
 	  	 StartTime 	 = CASE 	 WHEN np.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	 END,
 	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > @EndTime THEN @EndTime
 	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	 END
FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPCategoryId
WHERE 	 PU_Id = @PUId
 	  	 AND np.Start_Time < @EndTime
 	  	 AND np.End_Time > @StartTime
 	  	 
/********************************************************************
* 	  	  	  	  	  	 Specifications 	  	  	  	  	  	  	  	 *
********************************************************************/
-- DOWNTIME TARGET
INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	 EndTime)
SELECT 	 @DowntimeSpecsTableId,
 	  	 AS_Id,
 	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.StartTime, @StartTime),
 	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.EndTime, @EndTime)
FROM @ProductionStarts  ps 
 	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PUId = puc.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND puc.Prop_Id = @DowntimePropId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.ProdId = puc.Prod_Id
 	  	 JOIN dbo.Active_Specs s WITH (NOLOCK) ON 	 s.Char_Id = puc.Char_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Spec_Id = @DowntimeSpecId
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Effective_Date < isnull(ps.EndTime, @EndTime)
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @EndTime) > ps.StartTime
-- PRODUCTION TARGET
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @ProductionSpecsTableId,
 	  	 AS_Id,
 	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.StartTime, @StartTime),
 	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.EndTime, @EndTime)
FROM @ProductionStarts ps 
 	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PUId = puc.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND puc.Prop_Id = @ProductionPropId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.ProdId = puc.Prod_Id
 	  	 JOIN dbo.Active_Specs s WITH (NOLOCK) ON 	 s.Char_Id = puc.Char_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Spec_Id = @ProductionSpecId
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Effective_Date < isnull(ps.EndTime, @EndTime)
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @EndTime) > ps.StartTime
-- WASTE TARGET
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @WasteSpecsTableId,
 	  	 AS_Id,
 	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.StartTime, @StartTime),
 	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.EndTime, @EndTime)
FROM @ProductionStarts ps 
 	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PUId = puc.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND puc.Prop_Id = @WastePropId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.ProdId = puc.Prod_Id
 	  	 JOIN dbo.Active_Specs s WITH (NOLOCK) ON 	 s.Char_Id = puc.Char_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Spec_Id = @WasteSpecId
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Effective_Date < isnull(ps.EndTime, @EndTime)
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @EndTime) > ps.StartTime
/********************************************************************
* 	  	  	  	  	  	 Production Events 	  	  	  	  	  	  	 *
********************************************************************/
IF @ProductionType <> 1
BEGIN
 	 IF @rptParmEventSummary = 1
 	  	 BEGIN
 	  	  	 INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	  	  	 EndTime
 	  	  	  	  	  	  	  	  	 )
 	  	  	 SELECT 	 @EventsTableId,
 	  	  	  	  	 e.Event_Id,
 	  	  	  	  	 
 	  	  	  	  	 StartTime 	 = e.Timestamp, 
 	  	  	  	  	 EndTime 	  	 = e.Timestamp
 	  	  	 FROM dbo.Events e WITH (NOLOCK)
 	  	  	 WHERE 	 e.PU_Id = @PUId
 	  	  	  	  	 AND isnull(e.Start_Time,e.TimeStamp) <= @EndTime
 	  	  	  	  	 AND e.Timestamp >= @StartTime
 	  	  	 
 	  	  	 -- Set the Start time for the first record.
 	  	  	 UPDATE p2
 	  	  	 SET p2.StartTime = coalesce(e.Start_Time,@StartTime)
 	  	  	 FROM @Periods p2
 	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON p2.KeyId = e.Event_Id
 	  	  	 WHERE p2.PeriodId IN (SELECT min(p1.PeriodId)
 	  	  	  	 FROM @Periods p1 WHERE p1.TableId = @EventsTableId)
 	  	  	 -- Set the Start time for the other records based on whether Start_Time is configured..
 	  	  	 UPDATE p2
 	  	  	 SET p2.StartTime = CASE WHEN e.Start_Time IS NULL THEN p1.EndTime ELSE e.Start_Time END
 	  	  	 FROM @Periods p1
 	  	  	  	 JOIN @Periods p2 ON p2.PeriodId = p1.PeriodId + 1
 	  	  	  	 LEFT JOIN dbo.Events e WITH (NOLOCK) ON p2.KeyId = e.Event_Id
 	  	  	  	  	 AND p2.TableId = p1.TableId
 	  	  	 WHERE p1.TableId = @EventsTableId
 	  	 END
 	 ELSE
 	  	 -- 	 Retrieve events that have an applied product. All other events are not
 	  	 --  needed, since the product information for these events would come from
 	  	 --  Production_starts. Events need to be retrieved only when event summary
 	  	 -- 	 is needed.
 	  	 BEGIN
 	  	  	 INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	  	  	 EndTime
 	  	  	  	  	  	  	  	  	 )
 	  	  	 SELECT 	 @EventsTableId,
 	  	  	  	  	 e.Event_Id,
 	  	  	  	  	 StartTime 	 = e.Timestamp, 
 	  	  	  	  	 EndTime 	  	 = e.Timestamp
 	  	  	 FROM dbo.Events e WITH (NOLOCK)
 	  	  	 WHERE 	 e.PU_Id = @PUId
 	  	  	  	  	 AND isnull(e.Start_Time,e.TimeStamp) <= @EndTime
 	  	  	  	  	 AND e.Timestamp >= @StartTime
 	  	  	  	  	 AND e.Applied_Product IS NOT NULL  	 
 	  	  	 -- Set the Start time for the first record.
 	  	  	 UPDATE p2
 	  	  	 SET p2.StartTime = coalesce(e.Start_Time,@StartTime)
 	  	  	 FROM @Periods p2
 	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON p2.KeyId = e.Event_Id
 	  	  	 WHERE p2.PeriodId IN (SELECT min(p1.PeriodId)
 	  	  	  	 FROM @Periods p1 WHERE p1.TableId = @EventsTableId)
 	  	  	 -- Set the Start time for the other records based on whether Start_Time is configured..
 	  	  	 UPDATE p2
 	  	  	 SET p2.StartTime = CASE WHEN e.Start_Time IS NULL THEN p1.EndTime ELSE e.Start_Time END
 	  	  	 FROM @Periods p1
 	  	  	  	 JOIN @Periods p2 ON p2.PeriodId = p1.PeriodId + 1
 	  	  	  	 LEFT JOIN dbo.Events e WITH (NOLOCK) ON p2.KeyId = e.Event_Id
 	  	  	  	  	 AND p2.TableId = p1.TableId
 	  	  	 WHERE p1.TableId = @EventsTableId
 	  	 END
END
/********************************************************************
* 	  	  	  	  	  	  	 Gaps 	  	  	  	  	  	  	  	  	 *
********************************************************************/
-- Insert gaps
INSERT INTO @Periods ( 	 StartTime,
 	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	 TableId)
SELECT 	 p1.EndTime,
 	  	 @EndTime,
 	  	 p1.TableId
FROM @Periods p1
 	 LEFT JOIN @Periods p2 ON 	 p1.TableId = p2.TableId
 	  	  	  	  	  	  	  	 AND p1.EndTime = p2.StartTime
WHERE 	 p1.EndTime < @EndTime
 	  	 AND p2.PeriodId IS NULL
/********************************************************************
* 	  	  	  	  	  	  	 Slices 	  	  	  	  	  	  	  	  	 *
********************************************************************/
-- Create slices
INSERT INTO @Slices ( 	 PUId,
 	  	  	  	  	  	 StartTime)
SELECT DISTINCT 	 0,
 	  	  	  	 StartTime
FROM @Periods
ORDER BY StartTime ASC
SELECT @Rows = @@rowcount
-- Correct the end times
UPDATE s1
SET s1.EndTime 	  	 = s2.StartTime,
 	 s1.CalendarTime 	 = datediff(s, s1.StartTime, s2.StartTime)
FROM @Slices s1
 	 JOIN @Slices s2 ON s2.SliceId = s1.SliceId + 1
WHERE s1.SliceId < @Rows
UPDATE @Slices
SET EndTime  	  	 = @EndTime,
 	 CalendarTime 	 = datediff(s, StartTime, @EndTime)
WHERE SliceId = @Rows
-- Update each slice with the relative table information
UPDATE s
SET 	 PUId 	 = ps.PUId,
 	 ProdId 	 = ps.ProdId,
 	 StartId 	 = ps.Id
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @ProductionStartsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN @ProductionStarts ps ON p.KeyId = ps.Id
WHERE 	 s.PUId = 0
 	  	 AND p.KeyId IS NOT NULL
-- Obtain Maximum value of StartId for use in Production Day Summary
SELECT @MaxStartId = max(StartId) FROM @Slices
IF @rptParmCrewSummary =1 or @rptParmShiftSummary = 1
BEGIN
UPDATE s
SET Crew 	 = cs.Crew_Desc,
 	 Shift 	 = cs.Shift_Desc
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @CrewScheduleTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN dbo.Crew_Schedule cs WITH (NOLOCK) ON p.KeyId = cs.CS_Id
WHERE p.KeyId IS NOT NULL
END
UPDATE s
SET ProductionDay 	 = pd.ProductionDay
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @ProductionDaysTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN @ProductionDays pd ON p.KeyId = pd.DayId
WHERE p.KeyId IS NOT NULL
UPDATE s
SET PPId = pps.PP_Id
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @ProductionPlanStartsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND (p.EndTime > s.StartTime OR p.EndTime IS NULL)
 	  	 LEFT JOIN dbo.Production_Plan_Starts pps WITH (NOLOCK) ON p.KeyId = pps.PP_Start_Id
WHERE p.KeyId IS NOT NULL
UPDATE s
SET NP = 1
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @NonProductiveTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
WHERE p.KeyId IS NOT NULL
UPDATE s
SET DowntimeTarget = sp.Target
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @DowntimeSpecsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
WHERE p.KeyId IS NOT NULL
UPDATE s
SET ProductionTarget = sp.Target
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @ProductionSpecsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
WHERE p.KeyId IS NOT NULL
UPDATE s
SET WasteTarget = sp.Target
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @WasteSpecsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
WHERE p.KeyId IS NOT NULL
IF @ProductionType <> 1
BEGIN
 	 IF @rptParmEventSummary = 1 	 
 	  	 BEGIN
 	  	  	 --@Slices may not necessarily correspond to an event
 	  	  	 --Update slices that correspond to an event i.e.@Periods.EndTime = event.Timestamp
 	  	  	 UPDATE s
 	  	  	 SET EventId = e.Event_Id,
 	  	  	 AppliedProdId = e.Applied_Product
 	  	  	 FROM @Slices s
 	  	  	  	 LEFT JOIN @Periods p ON p.TableId = @EventsTableId
 	  	  	  	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	  	  	  	 LEFT JOIN dbo.Events e WITH (NOLOCK) ON p.KeyId = e.Event_Id
 	  	  	  	  	  	 AND p.EndTime = e.Timestamp
 	  	  	 WHERE p.KeyId IS NOT NULL
 	  	  	 IF @rptParmDisplayESignature = 1 
 	  	  	  	 BEGIN
 	  	  	  	  	 UPDATE s
 	  	  	  	  	 SET PerformUserId 	 = es.Perform_User_Id,
 	  	  	  	  	  	 VerifyUserId 	 = es.Verify_User_Id
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 LEFT JOIN dbo.Events e WITH (NOLOCK) ON e.Event_Id = s.EventId
 	  	  	  	  	  	  	 LEFT JOIN dbo.ESignature es WITH (NOLOCK) ON es.Signature_Id = e.Signature_Id
 	  	  	  	  	  	 WHERE s.EventId IS NOT NULL
 	  	  	  	  	 UPDATE s
 	  	  	  	  	 SET PerformUserName = u.UserName
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 JOIN dbo.Users u WITH (NOLOCK) ON u.[User_Id] = s.PerformUserId
 	  	  	  	  	  	 WHERE s.PerformUserId IS NOT NULL
 	  	  	  	  	 UPDATE s
 	  	  	  	  	 SET VerifyUserName = u.UserName
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 JOIN dbo.Users u WITH (NOLOCK) ON u.[User_Id] = s.VerifyUserId
 	  	  	  	  	  	 WHERE s.VerifyUserId IS NOT NULL
 	  	  	  	 END
 	  	 END
 	 ELSE
 	  	 -- 	 Retrieve events that have an applied product. All other events are not
 	  	 --  needed, since the product information for these events would come from
 	  	 --  Production_starts. Events need to be retrieved only when event summary
 	  	 -- 	 is needed.
 	  	 BEGIN
 	  	  	 --@Slices may not necessarily correspond to an event
 	  	  	 --Update slices that correspond to an event i.e.@Periods.EndTime = event.Timestamp
 	  	  	 UPDATE s
 	  	  	 SET EventId = e.Event_Id,
 	  	  	  	 AppliedProdId = e.Applied_Product
 	  	  	 FROM @Slices s
 	  	  	  	 LEFT JOIN @Periods p ON p.TableId = @EventsTableId
 	  	  	  	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	  	  	  	 LEFT JOIN dbo.Events e WITH (NOLOCK) ON p.KeyId = e.Event_Id
 	  	  	  	  	  	 AND p.EndTime = e.Timestamp 	  	  	  	 
 	  	  	 WHERE p.KeyId IS NOT NULL AND e.Applied_Product IS NOT NULL
 	  	  	 IF @rptParmDisplayESignature = 1 
 	  	  	  	 BEGIN
 	  	  	  	  	 UPDATE s
 	  	  	  	  	 SET PerformUserId 	 = es.Perform_User_Id,
 	  	  	  	  	  	 VerifyUserId 	 = es.Verify_User_Id
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 LEFT JOIN dbo.Events e WITH (NOLOCK) ON e.Event_Id = s.EventId
 	  	  	  	  	  	  	 LEFT JOIN dbo.ESignature es WITH (NOLOCK) ON es.Signature_Id = e.Signature_Id
 	  	  	  	  	  	 WHERE s.EventId IS NOT NULL
 	  	  	  	  	 UPDATE s
 	  	  	  	  	 SET PerformUserName = u.UserName
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 JOIN dbo.Users u WITH (NOLOCK) ON u.[User_Id] = s.PerformUserId
 	  	  	  	  	  	 WHERE s.PerformUserId IS NOT NULL
 	  	  	  	  	 UPDATE s
 	  	  	  	  	 SET VerifyUserName = u.UserName
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 JOIN dbo.Users u WITH (NOLOCK) ON u.[User_Id] = s.VerifyUserId
 	  	  	  	  	  	 WHERE s.VerifyUserId IS NOT NULL
 	  	  	  	 END
 	  	 END
END
/********************************************************************
* 	  	  	  	  	  	  	 Downtime 	  	  	  	  	  	  	  	 *
********************************************************************/
-- Calculate the downtime statistics for each slice
-- Calculate 'Planned Downtime' and 'Available Time'
UPDATE s
SET 	 DowntimePlanned 	 = isnull(dts.Total,0),
 	 AvailableTime 	  	 = CASE 	 WHEN s.CalendarTime >= isnull(dts.Total,0)
 	  	  	  	  	  	  	  	  	 THEN s.CalendarTime - isnull(dts.Total,0)
 	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	 END
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 SliceId 	 AS SliceId,
 	  	  	  	  	 sum(datediff(s, CASE 	 WHEN ted.Start_Time < s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	 THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	 THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	 END)) AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Timed_Event_Details ted WITH (NOLOCK) ON 	 s.PUId = ted.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ted.Start_Time < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (ted.End_Time > s.StartTime or ted.End_Time Is Null)
 	  	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @ScheduledCategoryId
 	  	  	  	 GROUP BY s.SliceId) dts ON s.SliceId = dts.SliceId
-- Calculate 'External Downtime' (i.e. 'Unavailable Time' or 'Line/Unit Restraints') and 'Loading Time'
UPDATE s
SET 	 DowntimeExternal 	 = isnull(dts.Total,0),
 	 LoadingTime 	  	  	 = CASE 	 WHEN s.AvailableTime >= isnull(dts.Total,0)
 	  	  	  	  	  	  	  	  	 THEN s.AvailableTime - isnull(dts.Total, 0)
 	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	 END
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 SliceId 	 AS SliceId,
 	  	  	  	  	 sum(datediff(s, CASE 	 WHEN ted.Start_Time < s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	 THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	 THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	 END)) AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Timed_Event_Details ted WITH (NOLOCK) ON 	 s.PUId = ted.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ted.Start_Time < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (ted.End_Time > s.StartTime or ted.End_Time Is Null)
 	  	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @ExternalCategoryId
 	  	  	  	 GROUP BY s.SliceId) dts ON s.SliceId = dts.SliceId
-- Calculate 'Performance Downtime'
UPDATE s
SET 	 DowntimePerformance 	 = isnull(dts.Total,0)
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 SliceId 	 AS SliceId,
 	  	  	  	  	  	 sum(datediff(s, CASE 	 WHEN ted.Start_Time < s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	 THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	 THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	  	 END)) AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Timed_Event_Details ted WITH (NOLOCK) ON 	 s.PUId = ted.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ted.Start_Time < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (ted.End_Time > s.StartTime OR ted.End_Time is NULL)
 	  	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @PerformanceCategoryId
 	  	  	  	 GROUP BY s.SliceId) dts ON s.SliceId = dts.SliceId
-- Calculate 'Unplanned Downtime' and 'Run Time'
UPDATE s
SET 	 DowntimeTotal 	  	 = isnull(dts.Total,0),
 	 DowntimeUnplanned 	 = isnull(dts.Total, 0) - s.DowntimePlanned - s.DowntimeExternal - s.DowntimePerformance,
 	 RunTimeGross 	  	  	  	 = CASE 	 WHEN s.CalendarTime >= isnull(dts.Total,0)
 	  	  	  	  	  	  	  	  	  	 THEN s.CalendarTime - isnull(dts.Total, 0) + s.DowntimePerformance
 	  	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	  	 END,
 	 ProductiveTime 	  	 = CASE 	 WHEN s.CalendarTime >= isnull(dts.Total,0)
 	  	  	  	  	  	  	  	  	  	 THEN s.CalendarTime - isnull(dts.Total, 0)
 	  	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	  	 END
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 SliceId 	 AS SliceId,
 	  	  	  	  	  	 sum(datediff(s, CASE 	 WHEN ted.Start_Time < s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	 THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	 THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	  	 END)) AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Timed_Event_Details ted WITH (NOLOCK) ON 	 s.PUId = ted.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ted.Start_Time < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (ted.End_Time > s.StartTime OR ted.End_Time is NULL)
 	  	  	  	 GROUP BY s.SliceId) dts ON s.SliceId = dts.SliceId
/********************************************************************
* 	  	  	  	  	  	  	  	 Waste 	  	  	  	  	  	  	  	 *
********************************************************************/
-- Collect time-based waste
UPDATE s
SET WasteQuantity = isnull(wt.Total,0)
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 s.SliceId 	  	 AS SliceId,
 	  	  	  	  	  	 sum(wed.Amount) 	 AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 s.PUId = wed.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.TimeStamp >= s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.TimeStamp < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND Event_Id IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND Amount IS NOT NULL
 	  	  	  	 GROUP BY s.SliceId) wt ON s.SliceId = wt.SliceId
-- Collect event-based waste
IF @ProductionStartTime = 1 	 -- Uses start time so pro-rate quantity
 	 BEGIN
 	 UPDATE s
 	 SET WasteQuantity = WasteQuantity + isnull(wt.Total,0)
 	 FROM @Slices s
 	  	 LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	 sum(CASE 	 WHEN e.Start_Time IS NOT NULL THEN
 	  	  	  	  	  	  	  	  	 convert(Float, datediff(s, CASE 	 WHEN e.Start_Time < s.StartTime THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	   CASE 	 WHEN e.TimeStamp > s.EndTime THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END))
 	  	  	  	  	  	  	  	 / convert(Float, CASE WHEN datediff(s, e.Start_Time, e.TimeStamp) <= 0 THEN 1 ELSE datediff(s, e.Start_Time, e.TimeStamp) END)
 	  	  	  	  	  	  	  	 * isnull(wed.Amount,0)
 	  	  	  	  	  	  	  	 ELSE isnull(wed.Amount,0)
 	  	  	  	  	  	  	  	 END) AS Total
 	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON 	 s.PUId = e.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp >= s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 --AND e.Start_Time < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(e.Start_Time, e.TimeStamp) < s.EndTime 
 	  	  	  	  	  	  	 LEFT JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 s.PUId = wed.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 --AND wed.TimeStamp = e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Amount IS NOT NULL
 	  	  	  	  	 GROUP BY s.SliceId) wt ON s.SliceId = wt.SliceId
 	 END
ELSE 	  	 -- Doesn't use start time so don't pro-rate quantity
 	 BEGIN
 	 UPDATE s
 	 SET WasteQuantity = WasteQuantity + isnull(wt.Total,0)
 	 FROM @Slices s
 	  	 LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	 sum(isnull(wed.Amount,0)) AS Total
 	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON 	 s.PUId = e.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp >= s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp < s.EndTime
 	  	  	  	  	  	  	 LEFT JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 s.PUId = wed.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 --AND wed.TimeStamp = e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Amount IS NOT NULL
 	  	  	  	  	 GROUP BY s.SliceId) wt ON s.SliceId = wt.SliceId
 	 END
/********************************************************************
* 	  	  	  	  	  	  	 Production 	  	  	  	  	  	  	  	 *
********************************************************************/
IF @ProductionType = 1
 	 BEGIN
 	 UPDATE s
 	 SET  	 ProductionTotal = isnull(pt.Total,0),
 	  	  	 ProductionNet 	 = isnull(pt.Total,0) - s.WasteQuantity,
 	  	  	 ProductionIdeal 	 = dbo.fnGEPSIdealProduction(RunTimeGross,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ProductionTarget,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionRateFactor,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 pt.Total)
 	 FROM @Slices s
 	  	 LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	 sum(convert(Float, t.Result)) AS Total
 	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	 JOIN dbo.Tests t WITH (NOLOCK) ON 	 t.Var_Id = @ProductionVarId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND t.Result_On >= s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND t.Result_On < s.EndTime
 	  	  	  	  	 GROUP BY s.SliceId) pt ON s.SliceId = pt.SliceId
 	 END
ELSE
 	 BEGIN
 	 IF @ProductionStartTime = 1 	 -- Uses start time so pro-rate quantity
 	  	 BEGIN
 	  	 UPDATE s
 	  	 SET 	 ProductionTotal 	 = isnull(pt.Total,0),
 	  	  	 ProductionNet 	 = isnull(pt.Total,0) - s.WasteQuantity,
 	  	  	 ProductionIdeal 	 = dbo.fnGEPSIdealProduction(RunTimeGross,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ProductionTarget,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionRateFactor,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 pt.Total)
 	  	 FROM @Slices s
 	  	  	  LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	  	 sum( CASE 	 WHEN e.Start_Time IS NOT NULL THEN
 	  	  	  	  	  	  	  	  	  	  	  	 convert(Float, datediff(s, CASE 	 WHEN e.Start_Time < s.StartTime THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	   CASE 	 WHEN e.TimeStamp > s.EndTime THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END))
 	  	  	  	  	  	  	  	  	  	  	  	 / convert(Float, CASE WHEN datediff(s, e.Start_Time, e.TimeStamp) <=0 THEN 1 ELSE datediff(s, e.Start_Time, e.TimeStamp) END)
 	  	  	  	  	  	  	  	  	  	  	  	 * isnull(ed.Initial_Dimension_X,0)
 	  	  	  	  	  	  	  	  	  	  	 ELSE isnull(ed.Initial_Dimension_X,0)
 	  	  	  	  	  	  	  	  	  	  	 END) AS Total
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON 	 s.PUId = e.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp >= s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(e.Start_Time, e.TimeStamp) < s.EndTime -- Note: if starttime is null it assumes that starttime = endtime
 	  	  	  	  	  	  	  	 JOIN dbo.Production_Status ps WITH (NOLOCK) ON 	 e.Event_Status = ps.ProdStatus_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.Count_For_Production = 1
 	  	  	  	  	  	  	  	 LEFT JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
 	  	  	  	  	  	 GROUP BY s.SliceId) pt ON s.SliceId = pt.SliceId 
 	  	 END
 	 ELSE -- Doesn't use start time so don't pro-rate quantity
 	  	 BEGIN
 	  	 UPDATE s
 	  	 SET 	 ProductionTotal 	 = isnull(pt.Total,0),
 	  	  	 ProductionNet 	 = isnull(pt.Total,0) - s.WasteQuantity,
 	  	  	 ProductionIdeal 	 = dbo.fnGEPSIdealProduction(RunTimeGross,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ProductionTarget,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionRateFactor,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 pt.Total)
 	  	 FROM @Slices s
 	  	  	 LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	  	 sum(ed.Initial_Dimension_X) AS Total
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON 	 s.PUId = e.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp >= s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp < s.EndTime
 	  	  	  	  	  	  	  	 JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
 	  	  	  	  	  	 GROUP BY s.SliceId) pt ON s.SliceId = pt.SliceId
 	  	 END
 	 END
 -- Populate NPLabelRef ( NP 0-->1 Transition)
UPDATE s1
SET s1.NPLabelRef = 1
FROM @Slices s1
 	 JOIN @Slices s2 ON s2.SliceId = s1.SliceId + 1
WHERE s2.SliceId < (SELECT max(s3.SliceId) FROM @Slices s3)
 	 AND s2.NP = 1 AND (
 	  	 (s1.EventId = s2.EventId) OR (s1.PPId = s2.PPId) OR 
 	  	 ((s1.ProdId = s2.ProdId) AND (s1.Crew = s2.Crew) AND s1.EventId IS NULL AND s1.PPId IS NULL))-- OR
 	  	 --((s1.ProdId = s2.ProdId) AND (s1.ProductionDay = s2.Productionday) AND s1.Crew IS NULL AND s1.EventId IS NULL AND s1.PPId IS NULL))
-- Populate NPLabelRef ( NP 1-->0 Transition)
UPDATE s1
SET s1.NPLabelRef = 1
FROM @Slices s2
 	 JOIN @Slices s1 ON s1.SliceId = s2.SliceId + 1
WHERE s1.SliceId < (SELECT max(s3.SliceId) FROM @Slices s3)
 	 AND s2.NP = 1 AND (
 	  	 (s1.EventId = s2.EventId) OR (s1.PPId = s2.PPId) OR 
 	  	 ((s1.ProdId = s2.ProdId) AND (s1.Crew = s2.Crew) AND s1.EventId IS NULL AND s1.PPId IS NULL)) --OR
 	  	 --((s1.ProdId = s2.ProdId) AND (s1.ProductionDay = s2.Productionday) AND s1.Crew IS NULL AND s1.EventId IS NULL AND s1.PPId IS NULL))
--When applied product and original product are the same, 
 	 --no need of "Applied Product" which is causing duplicate entries in Product Summary.
 	 UPdate s
 	 SET AppliedProdID = NULL 
 	 FROM @Slices s
 	 WHERE s.ProdId = s.AppliedProdID  
-- Delete slices that have a PUId = 0 to prevent impact to rolled up
-- values of 'Run Time' and 'Loading Time'. This can occur, when the 
-- event timestamp falls within the report time frame but the event 
-- start time is outside the report time frame.
DELETE FROM @Slices WHERE PUId = 0
/********************************************************************
* 	  	  	  	  	 Overall Summary
********************************************************************/
IF @rsOverall = 1
 	 BEGIN
 	  	 -- Total
 	  	  	 INSERT INTO @unitData(Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	    	  Loadtime,AvaliableRate,OEE ) 	  	 SELECT 	 
  	  	  	 'Total',
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal),
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), 	 @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates)/100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	 END
/********************************************************************
* 	  	  	  	  	 Production Day Summary
********************************************************************/
Update @Slices SET ProductionDay = [dbo].[fnServer_CmnConvertFromDbTime](ProductionDay,@InTimeZone) WHERE ProductionDay IS NOT NULL -- Ramesh
DELETE FROM @rsSlices
IF @rptParmProductionDaySummary = 1
 	 BEGIN
 	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 StartId,
 	  	  	  	 ProductionDay,
 	  	  	  	 ProdId,
 	  	  	  	 IdealSpeed,
 	  	  	  	 ActualSpeed,
 	  	  	  	 IdealProd,
 	  	  	  	 PerfRate,
 	  	  	  	 NetProd,
 	  	  	  	 Waste,
 	  	  	  	 QualRate,
 	  	  	  	 PerfDT,
 	  	  	  	 RunTime,
 	  	  	  	 LoadTime,
 	  	  	  	 AvailRate,
 	  	  	  	 OEE
 	  	  	  	 )
 	  	 -- Group by Production Day, product
 	  	 SELECT 	 
 	  	  	 1 As [rsSubGroup],
 	  	  	 StartId,
 	  	  	 convert(nvarchar(4), datepart(yyyy, ProductionDay)) 
 	  	  	  	 + '-'  + 
 	  	  	  	 CASE WHEN datepart(mm, ProductionDay) < 10 THEN '0' +  convert(varchar(2),datepart(mm, ProductionDay))
 	  	  	  	  	 ELSE convert(varchar(2),datepart(mm, ProductionDay)) END
 	  	  	  	 + '-' + 
 	  	  	  	 CASE WHEN datepart(dd, ProductionDay) < 10 THEN '0' +  convert(varchar(2),datepart(dd, ProductionDay))
 	  	  	  	  	 ELSE convert(varchar(2),datepart(dd, ProductionDay))END AS [ProductionDay],
 	  	  	 coalesce(AppliedProdId,ProdId),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND ProdId IS NOT NULL
 	  	 GROUP BY StartId, ProductionDay, ProdId,AppliedProdId
 	  	 UNION
 	  	 -- Consolidate by production day
 	  	 SELECT 	 
 	  	  	 2 As [rsSubGroup],
 	  	  	 @MaxStartId,
 	  	  	 convert(varchar(4), datepart(yyyy, ProductionDay)) 
 	  	  	  	 + '-'  + 
 	  	  	  	 CASE WHEN datepart(mm, ProductionDay) < 10 THEN '0' +  convert(varchar(2),datepart(mm, ProductionDay))
 	  	  	  	  	 ELSE convert(varchar(2),datepart(mm, ProductionDay)) END
 	  	  	  	 + '-' + 
 	  	  	  	 CASE WHEN datepart(dd, ProductionDay) < 10 THEN '0' +  convert(varchar(2),datepart(dd, ProductionDay))
 	  	  	  	  	 ELSE convert(varchar(2),datepart(dd, ProductionDay))END AS [ProductionDay],
 	  	  	 null,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0) AND ProductionDay IS NOT NULL
 	  	 GROUP BY ProductionDay
 	  	 UNION
 	  	 -- Consolidate overall 	 
 	  	 SELECT 	 
 	  	  	 3 As [rsSubGroup],
 	  	  	 @MaxStartId,
 	  	  	 '',
 	  	  	 null,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	 -- Do the following to get ==Grand Total== to show up as the last record in the group
 	  	 UPDATE rss
 	  	 SET rss.SortReference = rss.ProductionDay
 	  	 FROM @rsSlices rss
 	  	 WHERE rss.ProductionDay IS NOT NULL
-- Joe's Code----
update @rsSlices set proddayprodid = productionday + '-' + convert(varchar(25), prodId ) 
update @Slices set proddayprodid = 
 	  	  	  	  	 convert(varchar(4), datepart(yyyy,ProductionDay)) 
 	  	  	  	  	 + '-'  + 
 	  	  	  	  	 CASE WHEN datepart(mm, ProductionDay) < 10 THEN '0' +  convert(varchar(2),datepart(mm, ProductionDay))
 	  	  	  	  	  	 ELSE convert(varchar(2),datepart(mm, ProductionDay)) END
 	  	  	  	  	 + '-' + 
 	  	  	  	  	 CASE WHEN datepart(dd, ProductionDay) < 10 THEN '0' +  convert(varchar(2),datepart(dd, ProductionDay))
 	  	  	  	  	  	 ELSE convert(varchar(2),datepart(dd, ProductionDay))END  
 + '-' + convert(varchar(25), coalesce(AppliedProdId,ProdId ))
------------
 	  	 UPDATE rss
 	  	  	 SET SortReference = convert(varchar(4), datepart(yyyy, @EndTime)) 
 	  	  	  	 + '-'  + 
 	  	  	  	 CASE WHEN datepart(mm, @EndTime) < 10 THEN '0' +  convert(varchar(2),datepart(mm, @EndTime))
 	  	  	  	  	 ELSE convert(varchar(2),datepart(mm, @EndTime)) END
 	  	  	  	 + '-' + 
 	  	  	  	 CASE WHEN datepart(dd, @EndTime) < 10 THEN '0' +  convert(varchar(2),datepart(dd, @EndTime))
 	  	  	  	  	 ELSE convert(varchar(2),datepart(dd, @EndTime))END
 	  	 FROM @rsSlices rss 	 
 	  	  	 WHERE rss.rsSubGroup = 3
 	  	 -- Update NPLabelRef if applicable
 	  	 UPDATE rss
 	  	 SET rss.NPLabelRef = 1 
 	  	 FROM @rsSlices rss , @Slices s1
 	  	 WHERE s1.NPLabelRef = 1 AND (rss.ProdId = s1.ProdId OR rss.ProdId = s1.AppliedProdId) AND
 	  	  	 rss.ProdDayProdId IN  --- Joe's new Column
 	  	  	  	 (SELECT DISTINCT 
 	  	  	  	  	 s.ProdDayProdId 
 	  	  	  	 FROM @Slices s WHERE s.NPLabelRef = 1)
 	  	  	 INSERT INTO @unitData(Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	    	  Loadtime,AvaliableRate,OEE ) 	  	 SELECT 
 	  	  	 CASE WHEN rss.NPLabelRef = 1 THEN rss.ProductionDay + ' ' + @NPTLabel
 	  	  	  	  	 ELSE rss.ProductionDay
 	  	  	 END + ' ' +
 	  	  	  	 CASE 
 	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode = 1 THEN p.Prod_Code
 	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode <> 1 THEN p.Prod_Desc
 	  	  	  	  	 WHEN rss.rsSubGroup = 2 THEN  @SubTotalLabel
 	  	  	  	  	 ELSE @GrandTotalLabel
 	  	  	  	 END,
 	  	  	 IdealSpeed As Ideal_Speed,
 	  	  	 ActualSpeed As Actual_Speed,
 	  	  	 IdealProd As Ideal_Prod,
 	  	  	 PerfRate As Perf_Rate,
 	  	  	 NetProd As Net_Prod,
 	  	  	 Waste,
 	  	  	 QualRate As Qual_Rate,
 	  	  	 PerfDT As Perf_DT,
 	  	  	 RunTime As Run_Time,
 	  	  	 LoadTime As Load_Time,
 	  	  	 AvailRate As Avail_Rate,
 	  	  	 OEE
 	  	 FROM @rsSlices rss
 	  	  	 LEFT JOIN [dbo].Products p WITH (NOLOCK) ON rss.ProdId = p.Prod_Id
 	  	 ORDER BY rss.SortReference,rss.rsSubGroup,rss.StartId
 	 END
/********************************************************************
* 	  	  	  	  	 Shift Summary
********************************************************************/
DELETE FROM @rsSlices
IF @rptParmShiftSummary = 1
 	 BEGIN
 	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 ShiftDesc,
 	  	  	  	 ProdId,
 	  	  	  	 IdealSpeed,
 	  	  	  	 ActualSpeed,
 	  	  	  	 IdealProd,
 	  	  	  	 PerfRate,
 	  	  	  	 NetProd,
 	  	  	  	 Waste,
 	  	  	  	 QualRate,
 	  	  	  	 PerfDT,
 	  	  	  	 RunTime,
 	  	  	  	 LoadTime,
 	  	  	  	 AvailRate,
 	  	  	  	 OEE
 	  	  	  	 )
 	  	 -- Group by Shift, product.
 	  	 SELECT 	 
 	  	  	 1 AS [rsSubGroup],
 	  	  	 Shift,
 	  	  	 coalesce(AppliedProdId,ProdId),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND Shift IS NOT NULL
 	  	  	 AND ProdId IS NOT NULL
 	  	 GROUP BY Shift, ProdId,AppliedProdId
 	  	 UNION
 	  	 -- Consolidate by shift
 	  	 SELECT 	 
 	  	  	 2 AS [rsSubGroup],
 	  	  	 Shift,
 	  	  	 null,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND Shift IS NOT NULL
 	  	 GROUP BY Shift
 	  	 UNION
 	  	 -- Consolidate Overall
 	  	 SELECT 	 
 	  	  	 3 AS [rsSubGroup],
 	  	  	 '',
 	  	  	 null,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	 -- Do the following to get ==Sub Total, Grand Total== to show up on the correct row.
 	  	 UPDATE rss
 	  	 SET rss.SortReference = rss.ShiftDesc  
 	  	 FROM @rsSlices rss
 	  	  	 LEFT JOIN [dbo].Products p WITH (NOLOCK) ON rss.ProdId = p.Prod_Id
 	  	 UPDATE rss
 	  	 SET rss.SortReference = (SELECT rss1.ShiftDesc FROM @rsSlices rss1
 	  	  	 WHERE rss1.RSSliceId IN (SELECT max(rss2.RSSliceId) FROM @rsSlices rss2 WHERE rss2.rsSubGroup = 2 ))
 	  	 FROM @rsSlices rss
 	  	 WHERE rss.rsSubGroup = 3
 	  	 -- Update NPLabelRef if applicable
 	  	 UPDATE rss
 	  	 SET rss.NPLabelRef = 1 
 	  	 FROM @rsSlices rss , @Slices s1
 	  	 WHERE s1.NPLabelRef = 1 AND (rss.ProdId = s1.ProdId OR rss.ProdId = s1.AppliedProdId) AND
 	  	  	 rss.ShiftDesc = s1.Shift 
 	  	  	 INSERT INTO @unitData(Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	    	  Loadtime,AvaliableRate,OEE ) 	  	 SELECT 
 	  	  	 CASE WHEN rss.NPLabelRef = 1 THEN rss.ShiftDesc + ' ' + @NPTLabel
 	  	  	  	  	 ELSE rss.ShiftDesc
 	  	  	 END + ' ' + 
 	  	  	  	 CASE 
 	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode = 1 THEN p.Prod_Code
 	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode <> 1 THEN p.Prod_Desc
 	  	  	  	  	 WHEN rss.rsSubGroup = 2 THEN  @SubTotalLabel
 	  	  	  	  	 ELSE @GrandTotalLabel
 	  	  	  	 END,
 	  	  	 IdealSpeed As Ideal_Speed,
 	  	  	 ActualSpeed As Actual_Speed,
 	  	  	 IdealProd As Ideal_Prod,
 	  	  	 PerfRate As Perf_Rate,
 	  	  	 NetProd As Net_Prod,
 	  	  	 Waste,
 	  	  	 QualRate As Qual_Rate,
 	  	  	 PerfDT As Perf_DT,
 	  	  	 RunTime As Run_Time,
 	  	  	 LoadTime As Load_Time,
 	  	  	 AvailRate As Avail_Rate,
 	  	  	 OEE
 	  	 FROM @rsSlices rss
 	  	  	 LEFT JOIN [dbo].Products p WITH (NOLOCK) ON rss.ProdId = p.Prod_Id
 	  	 ORDER BY rss.SortReference,rss.Product,rss.rsSubGroup
 	 END
/********************************************************************
* 	  	  	  	  	 Crew Summary
********************************************************************/
DELETE FROM @rsSlices
IF @rptParmCrewSummary = 1
 	 BEGIN
 	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 CrewDesc,
 	  	  	  	 ProdId,
 	  	  	  	 IdealSpeed,
 	  	  	  	 ActualSpeed,
 	  	  	  	 IdealProd,
 	  	  	  	 PerfRate,
 	  	  	  	 NetProd,
 	  	  	  	 Waste,
 	  	  	  	 QualRate,
 	  	  	  	 PerfDT,
 	  	  	  	 RunTime,
 	  	  	  	 LoadTime,
 	  	  	  	 AvailRate,
 	  	  	  	 OEE
 	  	  	  	 )
 	  	 -- Group by Crew, product
 	  	 SELECT 	 
 	  	  	 1 AS [rsSubGroup],
 	  	  	 Crew,
 	  	  	 coalesce(AppliedProdId,ProdId),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND Crew IS NOT NULL
 	  	  	 AND ProdId IS NOT NULL
 	  	 GROUP BY Crew, ProdId,AppliedProdId
 	  	 UNION
 	  	 -- Consolidate by Crew 
 	  	 SELECT 	 
 	  	  	 2 AS [rsSubGroup],
 	  	  	 Crew,
 	  	  	 null,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND Crew IS NOT NULL
 	  	 GROUP BY Crew
 	  	 UNION
 	  	 -- Consolidate Overall 
 	  	 SELECT 	 
 	  	  	 3 AS [rsSubGroup],
 	  	  	 '',
 	  	  	 null,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	 -- Do the following to get ==Sub Total, Grand Total== to show up on the correct row.
 	  	 UPDATE rss
 	  	 SET rss.SortReference = rss.CrewDesc
 	  	 FROM @rsSlices rss
 	  	 UPDATE rss
 	  	 SET rss.SortReference = (SELECT rss1.CrewDesc FROM @rsSlices rss1
 	  	  	 WHERE rss1.RSSliceId IN (SELECT max(rss2.RSSliceId) FROM @rsSlices rss2 WHERE rss2.rsSubGroup = 2 ))
 	  	 FROM @rsSlices rss
 	  	 WHERE rss.rsSubGroup = 3
 	  	 -- Update NPLabelRef if applicable
 	  	 UPDATE rss
 	  	 SET rss.NPLabelRef = 1 
 	  	 FROM @rsSlices rss , @Slices s1
 	  	 WHERE s1.NPLabelRef = 1 AND (rss.ProdId = s1.ProdId OR rss.ProdId = s1.AppliedProdId) AND
 	  	  	 rss.CrewDesc = s1.Crew
 	  	  	 INSERT INTO @unitData(Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	    	  Loadtime,AvaliableRate,OEE ) 	  	 SELECT 
 	  	  	 CASE WHEN rss.NPLabelRef = 1 THEN rss.CrewDesc + ' ' + @NPTLabel
 	  	  	  	  	 ELSE rss.CrewDesc
 	  	  	 END + ' ' + 
 	  	  	  	 CASE 
 	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode = 1 THEN p.Prod_Code
 	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode <> 1 THEN p.Prod_Desc
 	  	  	  	  	 WHEN rss.rsSubGroup = 2 THEN  @SubTotalLabel
 	  	  	  	  	 ELSE @GrandTotalLabel
 	  	  	  	 END,
 	  	  	 IdealSpeed As Ideal_Speed,
 	  	  	 ActualSpeed As Actual_Speed,
 	  	  	 IdealProd As Ideal_Prod,
 	  	  	 PerfRate As Perf_Rate,
 	  	  	 NetProd As Net_Prod,
 	  	  	 Waste,
 	  	  	 QualRate As Qual_Rate,
 	  	  	 PerfDT As Perf_DT,
 	  	  	 RunTime As Run_Time,
 	  	  	 LoadTime As Load_Time,
 	  	  	 AvailRate As Avail_Rate,
 	  	  	 OEE
 	  	 FROM @rsSlices rss
 	  	  	 LEFT JOIN [dbo].Products p ON rss.ProdId = p.Prod_Id
 	  	 ORDER BY rss.SortReference,rss.rsSubGroup,rss.Product
 	 END
/********************************************************************
* 	  	  	  	  	 Product Summary
********************************************************************/
DELETE FROM @rsSlices
IF @rptParmProductSummary = 1
 	 BEGIN
 	  	 --Get all product changes over the reporting time range
 	  	  	 INSERT INTO @MultipleRunProducts (
 	  	  	  	 ProdId,
 	  	  	  	 StartTime,
 	  	  	  	 EndTime)
 	  	  	  	 SELECT ProdId , StartTime , EndTime FROM  dbo.fnBF_GetPSFromEvents(@PUId,@StartTime,@EndTime,16) 
 	  	  	 --END
 	  	 UPDATE mrps
 	  	 SET ProdCodeDesc = CASE WHEN @rptParmDisplayProductCode = 1 THEN Prod_Code 
 	  	  	  	  	  	    ELSE Prod_Desc END
 	  	 FROM @MultipleRunProducts mrps JOIN Products p ON mrps.ProdId = p.Prod_id
 	  	 --Get the product counts for each product, over the reporting time range
 	  	 INSERT INTO @ProductRunCounts (ProdId,Counts)
 	  	 SELECT ProdId, count(ProdId) AS [Counts]
 	  	  	 FROM @MultipleRunProducts 
 	  	  	 GROUP BY ProdId
 	  	 --Retain Products that have more than 1 product run, over the reporting time range.
 	  	 DELETE FROM @MultipleRunProducts
 	  	  	 WHERE ProdId In (SELECT ProdId FROM @ProductRunCounts WHERE Counts < 2)
 	  	 -- Loop through all the products that have more than one run, over the reporting time range.
 	  	 SELECT @LoopCount = 1
 	  	 SELECT @MaxLoops  = count(*) FROM @MultipleRunProducts
 	  	 WHILE @LoopCount <= @MaxLoops
 	  	  	 BEGIN
 	  	  	  	 --Initialize
 	  	  	  	 SELECT 
 	  	  	  	  	 @CurrentRunStartTime 	 = NULL,
 	  	  	  	  	 @CurrentRunEndTime 	  	 = NULL,  	 
 	  	  	  	  	 @CurrentRunProdId 	  	 = NULL,
 	  	  	  	  	 @CurrentRunProdCodeDesc 	 = NULL,
 	  	  	  	  	 @CurrentRunMRPId 	  	 = NULL
 	  	  	  	 IF @LoopCount = 1 
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT TOP 1
 	  	  	  	  	  	  	 @CurrentRunStartTime 	 = StartTime,
 	  	  	  	  	  	  	 @CurrentRunEndTime 	  	 = EndTime,  	 
 	  	  	  	  	  	  	 @CurrentRunProdId 	  	 = ProdId,
 	  	  	  	  	  	  	 @CurrentRunProdCodeDesc 	 = ProdCodeDesc,
 	  	  	  	  	  	  	 @CurrentRunMRPId 	  	 = MRPId
 	  	  	  	  	  	 FROM @MultipleRunProducts
 	  	  	  	  	  	 ORDER BY StartTime
 	  	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT TOP 1
 	  	  	  	  	  	  	 @CurrentRunStartTime 	 = StartTime,
 	  	  	  	  	  	  	 @CurrentRunEndTime 	  	 = EndTime,  	 
 	  	  	  	  	  	  	 @CurrentRunProdId 	  	 = ProdId,
 	  	  	  	  	  	  	 @CurrentRunProdCodeDesc 	 = ProdCodeDesc,
 	  	  	  	  	  	  	 @CurrentRunMRPId 	  	 = MRPId
 	  	  	  	  	  	 FROM @MultipleRunProducts
 	  	  	  	  	  	 WHERE StartTime > @LastRunStartTime
 	  	  	  	  	  	 ORDER BY StartTime
 	  	  	  	  	 END
 	  	  	  	 SELECT @LastRunStartTime =  	 @CurrentRunStartTime
 	  	  	  	 -- Update Slices with ProdId + SubGroupId for use in subsequent sort.
 	  	  	  	 UPDATE s
 	  	  	  	  	 --SET s.ProdIdSubGroupId = convert(varchar(25),@CurrentRunProdId) + '-' + convert(varchar(25),@LoopCount)
 	  	  	  	  	 SET s.ProdIdSubGroupId = @CurrentRunProdCodeDesc + '-' + convert(varchar(25),@LoopCount)
 	  	  	  	  	 FROM @Slices s
 	  	  	  	  	 WHERE  s.PUId = @PUId AND s.StartTime >= @CurrentRunStartTime 
 	  	  	  	  	  	 AND s.ProdId = @CurrentRunProdId
 	  	  	  	 SELECT @LoopCount = @LoopCount + 1
 	  	  	 END 
 	 END
IF @rptParmProductSummary= 1
 	 BEGIN 
 	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 ProdIdSubGroupId,
 	  	  	  	 ProdId,
 	  	  	  	 IdealSpeed,
 	  	  	  	 ActualSpeed,
 	  	  	  	 IdealProd,
 	  	  	  	 PerfRate,
 	  	  	  	 NetProd,
 	  	  	  	 Waste,
 	  	  	  	 QualRate,
 	  	  	  	 PerfDT,
 	  	  	  	 RunTime,
 	  	  	  	 LoadTime,
 	  	  	  	 AvailRate,
 	  	  	  	 OEE
 	  	  	  	 )
 	  	 SELECT -- Group by product for Productiondays that contain more than 1 distinct product
 	  	  	 1 AS [RSSubGroup],
 	  	  	 ProdIdSubGroupId,
 	  	  	 coalesce(AppliedProdId,ProdId),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND ProdId IS NOT NULL
 	  	  	 
 	  	 GROUP BY AppliedProdId,ProdId, ProdIdSubGroupId
 	  	 UNION
 	  	 SELECT -- Group by product
 	  	  	 2 AS [RSSubGroup],
 	  	  	 '',
 	  	  	 coalesce(AppliedProdId,ProdId),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND ProdId IS NOT NULL
 	  	 GROUP BY AppliedProdId,ProdId
 	  	 UNION
 	  	 SELECT -- Consolidate overall
 	  	  	 3 AS [RSSubGroup],
 	  	  	 '',
 	  	  	 null,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND ProdId IS NOT NULL
 	  	 -- Do the following to get Grand Total== to show up on the last row.
 	  	 UPDATE rss
 	  	 SET rss.SortReference = convert(varchar(50),rss.ProdId)
 	  	 FROM @rsSlices rss
 	  	 WHERE rss.ProdId IS NOT NULL
 	  	 UPDATE rss
 	  	 SET --rss.SortReference = (SELECT convert(varchar(50),max(rss2.ProdId)) FROM @rsSlices rss2)
 	  	  	   rss.ProdId 	  	   = (SELECT max(rss2.ProdId) FROM @rsSlices rss2)
 	  	 FROM @rsSlices rss
 	  	 WHERE rss.rsSubGroup = 3
 	  	 -- Update NPLabelRef if applicable
 	  	 UPDATE rss
 	  	 SET rss.NPLabelRef = 1
 	  	 FROM @rsSlices rss
 	  	 JOIN @Slices s ON rss.ProdId = s.ProdId AND rss.ProdIdSubgroupId=s.ProdIdSubgroupId
 	  	 WHERE s.NPLabelRef = 1
 	  	 -- Output results
 	  	 IF @IncludeSummary != 0
 	  	  	 INSERT INTO @unitData(ProductId,Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	    	  Loadtime,AvaliableRate,OEE )
 	  	  	  	 SELECT 
 	  	  	  	  	 rss.ProdId,
 	  	  	  	  	 Product = 
 	  	  	  	  	  	 CASE 
 	  	  	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode = 1 AND rss.NPLabelRef = 0 THEN p.Prod_Code
 	  	  	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode = 1 AND rss.NPLabelRef = 1 THEN p.Prod_Code + ' ' + @NPTLabel
 	  	  	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode <> 1 AND rss.NPLabelRef = 0 THEN p.Prod_Desc
 	  	  	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode <> 1 AND rss.NPLabelRef = 1 THEN p.Prod_Desc + ' ' + @NPTLabel
 	  	  	  	  	  	  	 WHEN rss.rsSubGroup = 2 THEN  @SubTotalLabel
 	  	  	  	  	  	  	 ELSE @GrandTotalLabel
 	  	  	  	  	  	 END,
 	  	  	  	  	 IdealSpeed As Ideal_Speed,
 	  	  	  	  	 ActualSpeed As Actual_Speed,
 	  	  	  	  	 IdealProd As Ideal_Prod,
 	  	  	  	  	 PerfRate As Perf_Rate,
 	  	  	  	  	 NetProd As Net_Prod,
 	  	  	  	  	 Waste,
 	  	  	  	  	 QualRate As Qual_Rate,
 	  	  	  	  	 PerfDT As Perf_DT,
 	  	  	  	  	 RunTime As Run_Time,
 	  	  	  	  	 LoadTime As Load_Time,
 	  	  	  	  	 AvailRate As Avail_Rate,
 	  	  	  	  	 OEE
 	  	  	  	 FROM @rsSlices rss
 	  	  	  	  	 LEFT JOIN dbo.Products p WITH (NOLOCK) ON rss.ProdId = p.Prod_Id
 	  	  	  	 ORDER BY rss.ProdId,rss.rsSubGroup
 	 ELSE
 	  	  	 INSERT INTO @unitData(ProductId,
   	    	    	    	    	    	    	    	  Product,
   	    	    	    	    	    	    	    	  IdealSpeed,
   	    	    	    	    	    	    	    	  ActualSpeed ,
   	    	    	    	    	    	    	    	  IdealProduction,
 	  	  	  	  	  	  	  	  PerformanceRate,
   	    	    	    	    	    	    	    	  NetProduction ,
 	  	  	  	  	  	  	  	  Waste,
   	    	    	    	    	    	    	    	  QualityRate,
   	    	    	    	    	    	    	    	  PerformanceDowntime,
   	    	    	    	    	    	    	    	  RunTime,
   	    	    	    	    	    	    	    	  Loadtime,
   	    	    	    	    	    	    	    	  AvaliableRate,
   	    	    	    	    	    	    	    	  OEE)
 	  	  	  	  	 SELECT 
 	  	  	  	  	 rss.ProdId,
 	  	  	  	  	 Product = p.Prod_Desc,
 	  	  	  	  	 IdealSpeed As Ideal_Speed,
 	  	  	  	  	 ActualSpeed As Actual_Speed,
 	  	  	  	  	 IdealProd As Ideal_Prod,
 	  	  	  	  	 PerfRate As Perf_Rate,
 	  	  	  	  	 NetProd As Net_Prod,
 	  	  	  	  	 Waste,
 	  	  	  	  	 QualRate As Qual_Rate,
 	  	  	  	  	 PerfDT As Perf_DT,
 	  	  	  	  	 RunTime As Run_Time,
 	  	  	  	  	 LoadTime As Load_Time,
 	  	  	  	  	 AvailRate As Avail_Rate,
 	  	  	  	  	 OEE
 	  	  	  	 FROM @rsSlices rss
 	  	  	  	  	 LEFT JOIN dbo.Products p WITH (NOLOCK) ON rss.ProdId = p.Prod_Id
 	  	  	  	 WHERE rss.rsSubGroup = 2
 	  	  	  	 ORDER BY rss.ProdId
 	 END
/********************************************************************
* 	  	  	  	  	 Process Order Summary
********************************************************************/
--Product Code sub-total grouping, required iff more than one 	  	 
--process order has the same product id.
INSERT INTO @ProcessOrderSubGroup (ProdId,Counts)
 	  	 SELECT ProdId, count(DISTINCT(PPId))
 	  	  	 FROM @Slices
 	  	  	 WHERE ProdId IS NOT NULL
 	  	 GROUP BY ProdId 	  	 
-- The same temp table is used for results. Hence delete records.
DELETE FROM @rsSlices
IF @rptParmProcessOrderSummary = 1
 	 BEGIN -- Process Order Summary
 	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 PPId,
 	  	  	  	 ProdId,
 	  	  	  	 IdealSpeed,
 	  	  	  	 ActualSpeed,
 	  	  	  	 IdealProd,
 	  	  	  	 PerfRate,
 	  	  	  	 NetProd,
 	  	  	  	 Waste,
 	  	  	  	 QualRate,
 	  	  	  	 PerfDT,
 	  	  	  	 RunTime,
 	  	  	  	 LoadTime,
 	  	  	  	 AvailRate,
 	  	  	  	 OEE
 	  	  	  	 )
 	  	 -- Group by Process Order, Product. 
 	  	 SELECT 	 
 	  	  	 1 AS [RSSubGroup],
 	  	  	 PPId,
 	  	  	 ProdId,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND PPId IS NOT NULL
 	  	  	 AND ProdId IS NOT NULL
 	  	 GROUP BY ProdId,PPId
 	  	 UNION
 	  	 -- Consolidate by product.
 	  	 SELECT 	 
 	  	  	 2 AS [RSSubGroup],
 	  	  	 '',
 	  	  	 ProdId,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0) AND ProdId IS NOT NULL 
 	  	  	 AND ProdId IN (SELECT ProdId FROM @ProcessOrderSubGroup WHERE Counts > 1)
 	  	 GROUP BY ProdId
 	  	 UNION
 	  	 -- Consolidate overall.
 	  	 SELECT 	 
 	  	  	 3 AS [RSSubGroup],
 	  	  	 '',
 	  	  	 null,
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	 sum(ProductionIdeal), 
 	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	 sum(WasteQuantity),
 	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	 sum(DowntimePerformance) / 60,
 	  	  	 sum(ProductiveTime) / 60,
 	  	  	 sum(LoadingTime) / 60,
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	 FROM @Slices 
 	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	 AND ProdId IS NOT NULL
 	  	 -- Do the following to get SubTotal, Grand Total to show up in the appropriate row
 	  	 UPDATE rss
 	  	 SET rss.SortReference = convert(nvarchar(50),rss.ProdId)
 	  	 FROM @rsSlices rss
 	  	 WHERE rss.ProdId IS NOT NULL
 	  	 UPDATE rss
 	  	 SET rss.SortReference = (SELECT convert(nvarchar(50),max(rss2.ProdId)) FROM @rsSlices rss2)
 	  	 FROM @rsSlices rss
 	  	 WHERE rss.rsSubGroup = 3
 	  	 -- Update NPLabelRef if applicable
 	  	 UPDATE rss
 	  	 SET rss.NPLabelRef = 1
 	  	 FROM @rsSlices rss
 	  	 WHERE rss.PPId IN (SELECT DISTINCT(s.PPId) FROM @Slices s WHERE s.NPLabelRef = 1)
 	 INSERT INTO @unitData(Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	 NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	 Loadtime,AvaliableRate,OEE ) 	 
 	  	 SELECT 
 	  	  	 CASE 
 	  	  	  	 WHEN rss.rsSubGroup = 1 AND rss.NPLabelRef = 1 THEN pp.Process_Order + ' ' + @NPTLabel
 	  	  	  	 WHEN rss.rsSubGroup = 1 AND rss.NPLabelRef = 0 THEN pp.Process_Order
 	  	  	  	 WHEN rss.rsSubGroup = 2 THEN  ''
 	  	  	 ELSE '' END + ' ' + 
 	  	  	  	 CASE 
 	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode = 1 THEN p.Prod_Code
 	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode <> 1 THEN p.Prod_Desc
 	  	  	  	  	 WHEN rss.rsSubGroup = 2 THEN  @SubTotalLabel
 	  	  	  	  	 ELSE '== Grand Total =='
 	  	  	  	 END,
 	  	  	 IdealSpeed As Ideal_Speed,
 	  	  	 ActualSpeed As Actual_Speed,
 	  	  	 IdealProd As Ideal_Prod,
 	  	  	 PerfRate As Perf_Rate,
 	  	  	 NetProd As Net_Prod,
 	  	  	 Waste,
 	  	  	 QualRate As Qual_Rate,
 	  	  	 PerfDT As Perf_DT,
 	  	  	 RunTime As Run_Time,
 	  	  	 LoadTime As Load_Time,
 	  	  	 AvailRate As Avail_Rate,
 	  	  	 OEE
 	  	 FROM @rsSlices rss
 	  	  	 LEFT JOIN dbo.Production_Plan pp WITH (NOLOCK) ON rss.PPId = pp.PP_Id
 	  	  	 LEFT JOIN dbo.Products p WITH (NOLOCK) ON rss.ProdId = p.Prod_Id
 	  	 ORDER BY SortReference, rsSubGroup, ProcessOrder
 	 END -- Process Order Summary
/********************************************************************
* 	  	  	  	  	 Event Summary
********************************************************************/
-- Fix Events that have the same event id but differing ProdId, due to slicing 	 
INSERT INTO @SliceUpdate (
 	  	 StartTime,
 	  	 EventId)
 	 SELECT 
 	  	 max(s1.StartTime) AS MaxStartTime,
 	  	 s1.EventId As EventId
 	 FROM @Slices s1
 	  	 JOIN @Slices s2 ON s1.EventId = s2.EventId AND s1.ProdId <> s2.ProdId
 	 GROUP BY s1.EventId
UPDATE su
SET su.ProdId = s.ProdId
FROM @Slices s, @SliceUpdate su
WHERE s.StartTime = su.StartTime AND s.PUId = @PUId
UPDATE s
SET s.ProdId = su.ProdId
FROM @Slices s,@SliceUpdate su
WHERE s.EventId = su.EventId AND s.ProdId <> su.ProdId
-- If the event has an applied product assign the applied Product as the ProdId
UPDATE s
SET s.ProdId = s.AppliedProdId
FROM @Slices s WHERE s.AppliedProdId IS NOT Null
-- The same temp table is used for results. Hence delete records.
DELETE FROM @rsSlices
IF @rptParmEventSummary = 1 AND (@ProductionType <> 1)
 	 BEGIN
 	  	 IF @rptParmDisplayESignature = 1 
 	  	 BEGIN
 	  	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 EventId,
 	  	  	  	 ProdId,
 	  	  	  	 Idealspeed  ,
 	  	  	  	 Actualspeed  ,
 	  	  	  	 IdealProd  ,
 	  	  	  	 PerfRate ,
 	  	  	  	 NetProd  ,
 	  	  	  	 Waste,
 	  	  	  	 QualRate  ,
 	  	  	  	 PerfDT  ,
 	  	  	  	 RunTime  ,
 	  	  	  	 LoadTime  ,
 	  	  	  	 AvailRate  ,
 	  	  	  	 OEE
 	  	  	  	 )
 	  	  	 SELECT 	 
 	  	  	  	 1,
 	  	  	  	 EventId,
 	  	  	  	 ProdId,
 	  	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	  	 sum(ProductionIdeal), 
 	  	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	  	 sum(WasteQuantity),
 	  	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	  	 sum(DowntimePerformance) / 60,
 	  	  	  	 sum(ProductiveTime) / 60,
 	  	  	  	 sum(LoadingTime) / 60,
 	  	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	  	 FROM @Slices 
 	  	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	  	  	 AND ProdId IS NOT NULL
 	  	  	  	  	 AND EventId IS NOT NULL
 	  	  	 GROUP BY EventId, ProdId,VerifyUserName,PerformUserName
 	  	  	 ORDER BY EventId
 	  	  	 -- Update NPLabelRef if applicable
 	  	  	 UPDATE rss
 	  	  	 SET rss.NPLabelRef = 1
 	  	  	 FROM @rsSlices rss
 	  	  	 WHERE rss.EventId IN (SELECT DISTINCT(s.EventId) FROM @Slices s WHERE s.NPLabelRef = 1)
 	 INSERT INTO @unitData(Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	 NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	 Loadtime,AvaliableRate,OEE )
 	  	  	 SELECT 
 	  	  	  	 --EventId,
 	  	  	  	 (CASE rss.NPLabelRef
 	  	  	  	 WHEN 1 THEN e.Event_Num + ' ' + @NPTLabel ELSE e.Event_Num END) + ' ' +
 	  	  	  	  	 CASE 
 	  	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode = 1 THEN p.Prod_Code
 	  	  	  	  	  	 ELSE p.Prod_Desc
 	  	  	  	  	 END,
 	  	  	  	 IdealSpeed As Ideal_Speed,
 	  	  	  	 ActualSpeed As Actual_Speed,
 	  	  	  	 IdealProd As Ideal_Prod,
 	  	  	  	 PerfRate As Perf_Rate,
 	  	  	  	 NetProd As Net_Prod,
 	  	  	  	 Waste,
 	  	  	  	 QualRate As Qual_Rate,
 	  	  	  	 PerfDT As Perf_DT,
 	  	  	  	 RunTime As Run_Time,
 	  	  	  	 LoadTime As Load_Time,
 	  	  	  	 AvailRate As Avail_Rate,
 	  	  	  	 OEE
 	  	  	 FROM @rsSlices rss
 	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON rss.EventId = e.Event_Id
 	  	  	  	 LEFT JOIN dbo.Products p WITH (NOLOCK) ON rss.ProdId = p.Prod_Id
 	  	  	 ORDER BY Event_Num
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 EventId,
 	  	  	  	 ProdId,
 	  	  	  	 Idealspeed  ,
 	  	  	  	 Actualspeed  ,
 	  	  	  	 IdealProd  ,
 	  	  	  	 PerfRate  ,
 	  	  	  	 NetProd  ,
 	  	  	  	 Waste,
 	  	  	  	 QualRate  ,
 	  	  	  	 PerfDT  ,
 	  	  	  	 RunTime  ,
 	  	  	  	 LoadTime  ,
 	  	  	  	 AvailRate  ,
 	  	  	  	 OEE
 	  	  	  	 )
 	  	  	 SELECT 	 
 	  	  	  	 1,
 	  	  	  	 EventId,
 	  	  	  	 --PerformUserName,
 	  	  	  	 --VerifyUserName,
 	  	  	  	 ProdId,
 	  	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor),
 	  	  	  	 dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor),
 	  	  	  	 sum(ProductionIdeal), 
 	  	  	  	 dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates),
 	  	  	  	 CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE sum(ProductionNet) END,
 	  	  	  	 sum(WasteQuantity),
 	  	  	  	 dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates),
 	  	  	  	 sum(DowntimePerformance) / 60,
 	  	  	  	 sum(ProductiveTime) / 60,
 	  	  	  	 sum(LoadingTime) / 60,
 	  	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates),
 	  	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
 	  	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
 	  	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	  	 FROM @Slices 
 	  	  	 WHERE 	 (NP = 0 OR @FilterNonProductiveTime = 0)
 	  	  	  	  	 AND ProdId IS NOT NULL
 	  	  	  	  	 AND EventId IS NOT NULL
 	  	  	 GROUP BY EventId, ProdId,VerifyUserName,PerformUserName
 	  	  	 ORDER BY EventId
 	  	  	 -- Update NPLabelRef if applicable
 	  	  	 UPDATE rss
 	  	  	 SET rss.NPLabelRef = 1
 	  	  	 FROM @rsSlices rss
 	  	  	 WHERE rss.EventId IN (SELECT DISTINCT(s.EventId) FROM @Slices s WHERE s.NPLabelRef = 1)
 	 INSERT INTO @unitData(Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	 NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	 Loadtime,AvaliableRate,OEE )
 	  	  	  	 SELECT 
 	  	  	  	 --EventId,
 	  	  	  	 (CASE rss.NPLabelRef
 	  	  	  	 WHEN 1 THEN e.Event_Num + ' ' + @NPTLabel ELSE e.Event_Num END) + ' ' +
 	  	  	  	  	 CASE 
 	  	  	  	  	  	 WHEN rss.rsSubGroup = 1 AND @rptParmDisplayProductCode = 1 THEN p.Prod_Code
 	  	  	  	  	  	 ELSE p.Prod_Desc
 	  	  	  	  	 END ,
 	  	  	  	 IdealSpeed As Ideal_Speed,
 	  	  	  	 ActualSpeed As Actual_Speed,
 	  	  	  	 IdealProd As Ideal_Prod,
 	  	  	  	 PerfRate As Perf_Rate,
 	  	  	  	 NetProd As Net_Prod,
 	  	  	  	 Waste,
 	  	  	  	 QualRate As Qual_Rate,
 	  	  	  	 PerfDT As Perf_DT,
 	  	  	  	 RunTime As Run_Time,
 	  	  	  	 LoadTime As Load_Time,
 	  	  	  	 AvailRate As Avail_Rate,
 	  	  	  	 OEE
 	  	  	 FROM @rsSlices rss
 	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON rss.EventId = e.Event_Id
 	  	  	  	 LEFT JOIN dbo.Products p WITH (NOLOCK) ON rss.ProdId = p.Prod_Id
 	  	  	 ORDER BY Event_Num
 	  	 END
 	 END
 RETURN
END
