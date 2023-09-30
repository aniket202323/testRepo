/*
    select * from  	 dbo.fnBF_wrQuickOEEOrderSummary (10,'11/13/2016','11/15/2016','UTC',0,1,1)
    select * from  	 dbo.fnBF_wrQuickOEEOrderSummary (10,'11/13/2016','11/16/2016','UTC',0,2,1)
    select * from  	 dbo.fnBF_wrQuickOEEOrderSummary (10,'11/13/2016','11/15/2016','UTC',0,3,1)
    select * from  	 dbo.fnBF_wrQuickOEEOrderSummary (10,'11/13/2016','11/15/2016','UTC',0,4,1)
*/
CREATE FUNCTION [dbo].[fnBF_wrQuickOEEOrderSummary](
 	 @PUId                    Int,
 	 @StartTime               datetime = NULL,
 	 @EndTime                 datetime = NULL,
 	 @InTimeZone 	  	  	  	  nvarchar(200) = null,
 	 @FilterNonProductiveTime int = 0,
 	 @ReportType Int = 1,
 	 @IncludeSummary Int = 0)
RETURNS  @unitData Table(ProductId int, 	  	  	  	  	  	  	  	  
  	    	    	    	    	    	    	    	  Product nVarchar(100),
 	  	  	  	  	  	  	  	  PPId Int,
 	  	  	  	  	  	  	  	  PathId Int,
 	  	  	  	  	  	  	  	  PathCode  nVarChar(100),
 	  	  	  	  	  	  	  	  ProcessOrder nVarChar(100),
  	  	  	  	  	  	  	  	  CrewDesc nVarchar(100),
 	  	  	  	  	  	  	  	  ShiftDesc nVarchar(100),
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
1 - OrderSummary 
2 - ShiftSummary 
3 - CrewSummary
4 - PathSummary
*/
/********************************************************************
* 	  	  	  	  	  	  	 Declarations 	  	  	  	  	  	  	 *
********************************************************************/
DECLARE 	 -- General
 	  	 @rptParmPathSummary 	  	  	  	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmOrderSummary 	  	  	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmShiftSummary 	  	  	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmCrewSummary 	  	  	  	 int, 	 -- 1 - Summary Selected
 	  	 @ProductionRateFactor 	  	  	 Float,
 	  	 @CapRates 	  	  	  	  	  	 tinyint
IF @ReportType = 1 SET  @rptParmOrderSummary = 1 ELSE SET @rptParmOrderSummary = 0
IF @ReportType = 2 SET  	 @rptParmShiftSummary = 1 ELSE SET @rptParmShiftSummary = 0
IF @ReportType = 3 SET  	 @rptParmCrewSummary = 1 ELSE SET @rptParmCrewSummary = 0
IF @ReportType = 4 SET  	 @rptParmPathSummary = 1 ELSE SET @rptParmPathSummary = 0
SELECT 	 @CapRates = dbo.fnCMN_OEERateIsCapped() 	  	  	  	  	  	  	 
 	  	  	  	  	  	  	  	 
DECLARE  @Slices TABLE( 	 SliceId 	  	  	  	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 ProdDayProdId 	  	 nvarchar(75) DEFAULT null ,
 	  	  	  	  	  	 ProdIdSubGroupId 	 nvarchar(50) DEFAULT null,
 	  	  	  	  	  	 StartId 	  	  	  	 int DEFAULT null,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 PUId 	  	  	  	 int,
 	  	  	  	  	  	 ProdId 	  	  	  	 int,
 	  	  	  	  	  	 ShiftDesc 	  	  	  	 nvarchar(50),
 	  	  	  	  	  	 CrewDesc 	  	  	  	 nvarchar(50),
 	  	  	  	  	  	 ProductionDay 	  	 datetime,
 	  	  	  	  	  	 PPId 	  	  	  	 int,
 	  	  	  	  	  	 PathId 	  	  	  	 Int,
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
INSERT INTO @Slices(ProdDayProdId,ProdIdSubGroupId,StartId,StartTime,EndTime,
 	  	  	  	  	 PUId,ProdId,ShiftDesc,CrewDesc,ProductionDay,
 	  	  	  	  	 PPId,PathId,EventId,AppliedProdId,PerformUserId,
 	  	  	  	  	 VerifyUserId,PerformUserName, VerifyUserName, NP,NPLabelRef,
 	  	  	  	  	 DowntimeTarget,ProductionTarget,WasteTarget,CalendarTime,AvailableTime,
 	  	  	  	  	 LoadingTime,RunTimeGross,ProductiveTime,DowntimePlanned,DowntimeExternal,
 	  	  	  	  	 DowntimeUnplanned,DowntimePerformance,DowntimeTotal,ProductionCount,ProductionTotal,
 	  	  	  	  	 ProductionNet,ProductionIdeal,WasteQuantity)
SELECT ProdDayProdId,ProdIdSubGroupId,StartId,StartTime,EndTime,
 	  	  	  	  	 PUId,ProdId,ShiftDesc,CrewDesc,ProductionDay,
 	  	  	  	  	 PPId,PathId,EventId,AppliedProdId,PerformUserId,
 	  	  	  	  	 VerifyUserId,PerformUserName, VerifyUserName, NP,NPLabelRef,
 	  	  	  	  	 DowntimeTarget,ProductionTarget,WasteTarget,CalendarTime,AvailableTime,
 	  	  	  	  	 LoadingTime,RunTimeGross,ProductiveTime,DowntimePlanned,DowntimeExternal,
 	  	  	  	  	 DowntimeUnplanned,DowntimePerformance,DowntimeTotal,ProductionCount,ProductionTotal,
 	  	  	  	  	 ProductionNet,ProductionIdeal,WasteQuantity
 	  	  	  	  	  FROM  dbo.fnBF_wrQuickOEESlices(@PUId,@StartTime,@EndTime,@InTimeZone,@FilterNonProductiveTime,@ReportType,@IncludeSummary)
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
 	  	  	  	 PathId 	  	  	  	 int DEFAULT null,
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
SELECT 	 @ProductionRateFactor 	  	 = dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits)
FROM dbo.Prod_Units WITH (NOLOCK)
WHERE PU_Id = @PUId
IF @rptParmShiftSummary = 1
 	 BEGIN
 	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 ShiftDesc,
 	  	  	  	 CrewDesc,
 	  	  	  	 PPId,
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
 	  	 -- Group by ShiftDesc, Order.
 	  	 SELECT 	 
 	  	  	 1 AS [rsSubGroup],
 	  	  	 ShiftDesc,
 	  	  	 CrewDesc,
 	  	  	 ppId,
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
 	  	  	 AND ShiftDesc IS NOT NULL
 	  	  	 AND PPId IS NOT NULL
 	  	 GROUP BY ShiftDesc,PPId, CrewDesc
 	  	 INSERT INTO @unitData(PPId ,ProcessOrder,PathId,PathCode, ShiftDesc,CrewDesc,Product,ProductId,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	    	  Loadtime,AvaliableRate,OEE ) 	  	 
 	  	  	 SELECT 
 	  	  	 rss.PPId,
 	  	  	 pp.Process_Order,
 	  	  	 pp.Path_Id,
 	  	  	 pep.Path_Code,
 	  	  	 rss.ShiftDesc,
 	  	  	 rss.CrewDesc,
 	  	  	 p.Prod_Code,
 	  	  	 p.Prod_Id,
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
 	  	  	 LEFT JOIN [dbo].Production_Plan pp WITH (NOLOCK) ON rss.PPId  = pp.PP_Id
 	  	  	 LEFT JOIN Prdexec_Paths pep on pep.Path_Id = pp.Path_Id 
 	  	  	 LEFT JOIN [dbo].Products p WITH (NOLOCK) ON p.Prod_Id = pp.Prod_Id
 	  	 ORDER BY rss.SortReference,pp.Process_Order,rss.rsSubGroup
 	 END
/********************************************************************
* 	  	  	  	  	 CrewDesc Summary
********************************************************************/
DELETE FROM @rsSlices
IF @rptParmCrewSummary = 1
 	 BEGIN
 	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 CrewDesc,
 	  	  	  	 ShiftDesc,
 	  	  	  	 PPId,
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
 	  	 -- Group by CrewDesc, product
 	  	 SELECT 	 
 	  	  	 1 AS [rsSubGroup],
 	  	  	 CrewDesc,
 	  	  	 ShiftDesc,
 	  	  	 PPId ,
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
 	  	  	 AND CrewDesc IS NOT NULL
 	  	  	 AND PPId IS NOT NULL
 	  	 GROUP BY CrewDesc, PPId,ShiftDesc
 	  	 INSERT INTO @unitData(PPId ,ProcessOrder,PathId,PathCode,ProductId,Product,CrewDesc,ShiftDesc,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	    	  NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	    	  Loadtime,AvaliableRate,OEE ) 	  	 SELECT 
 	  	  	 rss.PPId,
 	  	  	 pp.Process_Order,
 	  	  	 pp.Path_Id,
 	  	  	 pep.Path_Code,
 	  	  	 p.Prod_Id,
 	  	  	 p.Prod_Code,
 	  	  	 rss.CrewDesc,
 	  	  	 rss.ShiftDesc,
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
 	  	  	 LEFT JOIN Production_Plan  pp ON pp.PP_Id  = rss.PPId
 	  	  	 LEFT JOIN PrdExec_paths pep ON pep.Path_Id = pp.Path_Id 
 	  	  	 LEFT JOIN Products p ON pp.Prod_Id = p.Prod_Id
 	  	 ORDER BY rss.SortReference,rss.rsSubGroup,pp.Process_Order 
 	 END
/********************************************************************
* 	  	  	  	  	 Path Summary
********************************************************************/
DELETE FROM @rsSlices
IF @rptParmPathSummary = 1
 	 BEGIN -- Process Order Summary
 	  	 INSERT INTO @rsSlices ( 	  	 
 	  	  	  	 RSSubGroup,
 	  	  	  	 PPId,
 	  	  	  	 PathId,
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
 	  	 -- Group by PathId, PPId. 
 	  	 SELECT 	 
 	  	  	 1 AS [RSSubGroup],
 	  	  	 PPId,
 	  	  	 PathId,
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
 	  	 GROUP BY PathId,PPId,ProdId
 	 INSERT INTO @unitData(PPId,ProcessOrder,PathId,PathCode,ProductId,Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	 NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	 Loadtime,AvaliableRate,OEE ) 	 
 	  	 SELECT 
 	  	  	 rss.ppId,
 	  	  	 pp.Process_Order,
 	  	  	 pp.Path_Id,
 	  	  	 p.Path_Code,
 	  	  	 rss.prodId,
 	  	  	 pr.Prod_Code,
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
 	  	  	 LEFT JOIN dbo.Prdexec_Paths  p WITH (NOLOCK) ON pp.Path_Id  = p.Path_Id
 	  	  	 LEFT JOIN dbo.Products   pr WITH (NOLOCK) ON pr.Prod_Id   = rss.ProdId
 	  	 ORDER BY SortReference, rsSubGroup, Path_Code
 	 END -- Process Order Summary
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
IF @rptParmOrderSummary = 1
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
 	 INSERT INTO @unitData(PPId,ProcessOrder,PathId,PathCode, ProductId,Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
   	    	    	    	    	    	    	 NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
   	    	    	    	    	    	    	 Loadtime,AvaliableRate,OEE ) 	 
 	  	 SELECT 
 	  	  	 rss.ppId,
 	  	  	 pp.Process_Order,
 	  	  	 pp.Path_Id,
 	  	  	 p.Path_Code,
 	  	  	 rss.prodId,
 	  	  	 pr.Prod_Code,
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
 	  	  	 LEFT JOIN Production_Plan pp WITH (NOLOCK) ON rss.PPId = pp.PP_Id
 	  	  	 LEFT JOIN Prdexec_Paths  p WITH (NOLOCK) ON pp.Path_Id  = p.Path_Id
 	  	  	 LEFT JOIN Products   pr WITH (NOLOCK) ON pr.Prod_Id   = rss.ProdId
 	  	 ORDER BY SortReference, rsSubGroup, ProcessOrder
 	 END -- Process Order Summary
 RETURN
END
