/*
    select * from    	   dbo.fnBF_wrQuickOEEProductSummaryTbl (10,'11/13/2016','11/15/2016','UTC',0,1,1)
    select * from    	   dbo.fnBF_wrQuickOEEProductSummaryTbl (10,'11/13/2016','11/15/2016','UTC',0,2,1)
    select * from    	   dbo.fnBF_wrQuickOEEProductSummaryTbl (10,'11/13/2016','11/15/2016','UTC',0,3,1) order by ppId
    select * from    	   dbo.fnBF_wrQuickOEEProductSummaryTbl (10,'11/13/2016','11/15/2016','UTC',0,4,1)
   	   select start_time,end_time,prod_id from production_starts where pu_id = 10
*/
CREATE FUNCTION [dbo].[fnBF_wrQuickOEEProductSummaryTbl](
 	   @PUId_Table dbo.UnitsType READONLY,
   	   @PUId                    Int,
   	   @StartTime               datetime = NULL,
   	   @EndTime                 datetime = NULL,
   	   @InTimeZone   	      	      	      	    nvarchar(200) = null,
   	   @FilterNonProductiveTime int = 0,
   	   @ReportType Int = 1,
   	   @IncludeSummary Int = 0
   	   )
/* ##### fnBF_wrQuickOEEProductSummaryTbl #####
Description   	   : Returns raw data like npt, downtime, production amount & etc at unit level.
Creation Date   	   : if any
Created By   	   : if any
#### Update History ####
DATE   	      	      	      	  Modified By   	    	  UserStory/Defect No   	      	    	  Comments   	      	   
----   	      	      	      	  -----------   	      	  -------------------   	      	      	  --------
2018-02-20   	    	    	  Prasad   	      	      	      	  7.0 SP3   	      	      	      	      	      	  Added logic to get NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL if unit is configured for time based OEE calculation.
2018-05-28  	    	    	  Prasad  	    	    	    	  7.0 SP4 US255630 & US255626  	    	  Passed actual filter for NPT
*/
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
   	      	      	      	      	      	   OEE Float DEFAULT 0
   	      	      	      	      	      	   ,NPT Float DEFAULT 0 --NPT for the time slice
   	      	      	      	      	      	   ,DowntimeA Float DEFAULT 0 --Availability downtime for the time slice
   	      	      	      	      	      	   ,DowntimeP Float DEFAULT 0 --Performance downtime for the time slice
   	      	      	      	      	      	   ,DowntimeQ Float DEFAULT 0 --Quality downtime for the time slice
   	      	      	      	      	      	   ,DowntimePL Float DEFAULT 0
  	    	    	    	    	    	   ,IsNPT BIT DEFAULT 0
 	  	  	  	  	  	   ,PuId Int
 	  	  	  	  	  	   ,OEEType Int
   	      	      	      	      	      	   )
AS
BEGIN
Declare @DBZone varchar(100)
select @DBZone = value from site_parameters where pArm_id = 192
SELECT @StartTime = CAse when @InTimeZone is not null then  @StartTime at time zone @InTimeZone at time zone @DBZone else @StartTime end
SELECT @endTime =CAse when @InTimeZone is not null then  @endTime at time zone @InTimeZone at time zone @DBZone else @endTime end
Declare @tempPU_Table dbo.UnitsType
INSERT INTO @tempPU_Table
Select * from @PUId_Table
UPDATE @tempPU_Table SET --Start_Date1 = dbo.fnServer_CmnConvertToDbTime(Start_Date1,@InTimeZone),End_Date1=dbo.fnServer_CmnConvertToDbTime(End_Date1,@InTimeZone)
Start_Date1 = CAse when @InTimeZone is not null then  Start_Date1 at time zone @InTimeZone at time zone @DBZone else Start_Date1 end,
End_Date1= CAse when @InTimeZone is not null then  End_Date1 at time zone @InTimeZone at time zone @DBZone else End_Date1 end
SET @FilterNonProductiveTime = 1
/*
1 - ProductSummary (none)
2 - ShiftSummary 
3 - CrewSummary
4 - OrderSummary
*/
/********************************************************************
*   	      	      	      	      	      	      	   Declarations   	      	      	      	      	      	      	   *
********************************************************************/
DECLARE   	   -- General
   	      	   @rptParmProductSummary   	      	      	      	   int,   	   -- 1 - Summary Selected
   	      	   @rptParmProcessOrderSummary   	      	      	   int,   	   -- 1 - Summary Selected
   	      	   @rptParmShiftSummary   	      	      	   int,   	   -- 1 - Summary Selected
   	      	   @rptParmCrewSummary   	      	      	      	   int,   	   -- 1 - Summary Selected
   	      	   @LoopCount   	      	      	      	      	      	   int,
   	      	   @MaxLoops   	      	      	      	      	      	   int,
   	      	   @LastRunStartTime   	      	      	      	   datetime,
   	      	   @CurrentRunStartTime   	      	      	   datetime,
   	      	   @CurrentRunEndTime   	      	      	      	   datetime,
   	      	   @CurrentRunProdId   	      	      	      	   int,
   	      	   @CurrentRunProdCodeDesc   	      	      	   nvarchar(50),
   	      	   @CurrentRunMRPId   	      	      	      	   int,
   	      	   @ProductionRateFactor   	      	      	   Float,
   	      	   @CapRates   	      	      	      	      	      	   tinyint
   	      	   IF @ReportType = 1 SET    	   @rptParmProductSummary = 1 ELSE SET @rptParmProductSummary = 0
   	      	   IF @ReportType = 2 SET    	   @rptParmShiftSummary = 1 ELSE SET @rptParmShiftSummary = 0
   	      	   IF @ReportType = 3 SET    	   @rptParmCrewSummary = 1 ELSE SET @rptParmCrewSummary = 0
   	      	   IF @ReportType = 4 SET  @rptParmProcessOrderSummary = 1 ELSE SET @rptParmProcessOrderSummary = 0
SELECT   	   @CapRates = dbo.fnCMN_OEERateIsCapped()
   	      	      	      	      	      	      	      	   
DECLARE  @Slices TABLE(   	   SliceId   	      	      	      	   int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
   	      	      	      	      	      	   ProdDayProdId   	      	   nvarchar(75) DEFAULT null ,
   	      	      	      	      	      	   ProdIdSubGroupId   	   nvarchar(50) DEFAULT null,
   	      	      	      	      	      	   StartId   	      	      	      	   int DEFAULT null,
   	      	      	      	      	      	   StartTime   	      	      	   datetime,
   	      	      	      	      	      	   EndTime   	      	      	      	   datetime,
   	      	      	      	      	      	   PUId   	      	      	      	   int,
   	      	      	      	      	      	   ProdId   	      	      	      	   int,
   	      	      	      	      	      	   ShiftDesc   	      	      	      	   nvarchar(50),
   	      	      	      	      	      	   CrewDesc   	      	      	      	   nvarchar(50),
   	      	      	      	      	      	   ProductionDay   	      	   datetime,
   	      	      	      	      	      	   PPId   	      	      	      	   int,
   	      	      	      	      	      	   PathId   	      	      	      	   Int,
   	      	      	      	      	      	   EventId   	      	      	      	   int,
   	      	      	      	      	      	   AppliedProdId   	      	   int,
   	      	      	      	      	      	   -- ESignature
   	      	      	      	      	      	   PerformUserId   	      	   int,
   	      	      	      	      	      	   VerifyUserId   	      	   int,
   	      	      	      	      	      	   PerformUserName   	      	   nvarchar(30), 
   	      	      	      	      	      	   VerifyUserName   	      	   nvarchar(30), 
   	      	      	      	      	      	   -- Other
   	      	      	      	      	      	   NP   	      	      	      	      	   bit DEFAULT 0,
   	      	      	      	      	      	   NPLabelRef   	      	      	   bit DEFAULT 0,
   	      	      	      	      	      	   DowntimeTarget   	      	   float,
   	      	      	      	      	      	   ProductionTarget   	   float,
   	      	      	      	      	      	   WasteTarget   	      	      	   float,
   	      	      	      	      	      	   -- Statistics
   	      	      	      	      	      	   CalendarTime   	      	   Float DEFAULT 0,
   	      	      	      	      	      	   AvailableTime   	      	   Float DEFAULT 0,
   	      	      	      	      	      	   LoadingTime   	      	      	   Float DEFAULT 0,
   	      	      	      	      	      	   RunTimeGross   	      	   Float DEFAULT 0,
   	      	      	      	      	      	   ProductiveTime   	      	   Float DEFAULT 0,
   	      	      	      	      	      	   DowntimePlanned   	      	   Float DEFAULT 0,
   	      	      	      	      	      	   DowntimeExternal   	   Float DEFAULT 0,
   	      	      	      	      	      	   DowntimeUnplanned   	   Float DEFAULT 0,
   	      	      	      	      	      	   DowntimePerformance   	   Float DEFAULT 0,
   	      	      	      	      	      	   DowntimeTotal   	      	   Float DEFAULT 0,
   	      	      	      	      	      	   ProductionCount   	      	   int DEFAULT 0,
   	      	      	      	      	      	   ProductionTotal   	      	   Float DEFAULT 0,
   	      	      	      	      	      	   ProductionNet   	      	   Float DEFAULT 0,
   	      	      	      	      	      	   ProductionIdeal   	      	   Float DEFAULT 0,
   	      	      	      	      	      	   WasteQuantity   	      	   Float DEFAULT 0
   	      	      	      	      	      	      	      	      	      	      	      	   ,NPT Float DEFAULT 0 --NPT for the time slice
   	      	      	      	      	      	   ,DowntimeA Float DEFAULT 0 --Availability downtime for the time slice
   	      	      	      	      	      	   ,DowntimeP Float DEFAULT 0 --Performance downtime for the time slice
   	      	      	      	      	      	   ,DowntimeQ Float DEFAULT 0 --Quality downtime for the time slice
   	      	      	      	      	      	   ,DowntimePL Float DEFAULT 0
 	  	  	  	  	  	  	  	  	  	  	   ,ProductionRateFactor Float Default 0
   	      	      	      	      	      	   )
INSERT INTO @Slices(ProdDayProdId,ProdIdSubGroupId,StartId,StartTime,EndTime,
   	      	      	      	      	   PUId,ProdId,ShiftDesc,CrewDesc,ProductionDay,
   	      	      	      	      	   PPId,PathId,EventId,AppliedProdId,PerformUserId,
   	      	      	      	      	   VerifyUserId,PerformUserName, VerifyUserName, NP,NPLabelRef,
   	      	      	      	      	   DowntimeTarget,ProductionTarget,WasteTarget,CalendarTime,AvailableTime,
   	      	      	      	      	   LoadingTime,RunTimeGross,ProductiveTime,DowntimePlanned,DowntimeExternal,
   	      	      	      	      	   DowntimeUnplanned,DowntimePerformance,DowntimeTotal,ProductionCount,ProductionTotal,
   	      	      	      	      	   ProductionNet,ProductionIdeal,WasteQuantity,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL)
SELECT ProdDayProdId,ProdIdSubGroupId,StartId,StartTime,EndTime,
   	      	      	      	      	   PUId,ProdId,ShiftDesc,CrewDesc,ProductionDay,
   	      	      	      	      	   PPId,PathId,EventId,AppliedProdId,PerformUserId,
   	      	      	      	      	   VerifyUserId,PerformUserName, VerifyUserName, NP,NPLabelRef,
   	      	      	      	      	   DowntimeTarget,ProductionTarget,WasteTarget,CalendarTime,AvailableTime,
   	      	      	      	      	   LoadingTime,RunTimeGross,ProductiveTime,DowntimePlanned,DowntimeExternal,
   	      	      	      	      	   DowntimeUnplanned,DowntimePerformance,DowntimeTotal,ProductionCount,ProductionTotal,
   	      	      	      	      	   ProductionNet,ProductionIdeal,WasteQuantity,NPT,DowntimeA,DowntimeP,DowntimeQ, DowntimePL
   	      	      	      	      	    FROM  dbo.fnBF_wrQuickOEESlicesTbl(@tempPU_Table,@PUId,@StartTime,@EndTime,NULL,@FilterNonProductiveTime,@ReportType,@IncludeSummary)
Declare @OEEType nvarchar(10)
   	   --Select 
   	   --   	   @OEEType = EDFTV.Field_desc
   	   --From 
   	   --   	   Table_Fields TF
   	   --   	   JOIN Table_Fields_Values TFV on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
   	   --   	   Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
   	   --   	   LEFT OUTER Join ED_FieldType_ValidValues EDFTV on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
   	   --Where 
   	   --   	   TF.Table_Field_Desc = 'OEE Calculation Type'
   	   --   	   AND TFV.KeyID = @PUId
   	      	      	      	      	    
DECLARE @SliceUpdate TABLE (
   	      	      	   SliceUpdateId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
   	      	      	   StartTime   	   datetime,
   	      	      	   EventId   	      	   int,
   	      	      	   ProdId   	      	   int
 	  	  	  	  	   ,PuId Int
    	      	      	   )
DECLARE @ProcessOrderSubGroup TABLE(
   	      	      	   POSGId   	   int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
   	      	      	   ProdId   	      	      	   int,
   	      	      	   Counts   	      	      	   int)
   	      	      	   
DECLARE  @rsSlices TABLE(RSSliceId   	   int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
   	      	      	      	   ProdDayProdId   	      	   nvarchar(75) DEFAULT null,
   	      	      	      	   ProdIdSubGroupId   	   nvarchar(50) DEFAULT null,
   	      	      	      	   StartId   	      	      	      	   int   	   DEFAULT null,
   	      	      	      	   RSSubGroup   	      	      	   int,
   	      	      	      	   SortReference   	      	   nvarchar(50)   	   DEFAULT null,
   	      	      	      	   ProductionDay   	      	   nvarchar(50)   	   DEFAULT null,
   	      	      	      	   ShiftDesc   	      	      	   nvarchar(50)   	   DEFAULT null,
   	      	      	      	   CrewDesc   	      	      	   nvarchar(50)   	   DEFAULT null,
   	      	      	      	   PPId   	      	      	      	   int DEFAULT null,
   	      	      	      	   PathId   	      	      	      	   int DEFAULT null,
   	      	      	      	   ProdId   	      	      	      	   int DEFAULT null,
   	      	      	      	   EventId   	      	      	      	   int DEFAULT null,
   	      	      	      	   NPLabelRef   	      	      	   int DEFAULT 0,
   	      	      	      	   ProcessOrder   	      	   nvarchar(50)   	   DEFAULT null,
   	      	      	      	   Product   	      	      	      	   nvarchar(50)   	   DEFAULT null,
   	      	      	      	   IdealSpeed   	      	      	   Float DEFAULT 0,
   	      	      	      	   ActualSpeed   	      	      	   Float DEFAULT 0,
   	      	      	      	   IdealProd   	      	      	   Float DEFAULT 0,
   	      	      	      	   PerfRate   	      	      	   Float DEFAULT 0,
   	      	      	      	   NetProd   	      	      	      	   Float DEFAULT 0,
   	      	      	      	   Waste   	      	      	      	   Float DEFAULT 0,
   	      	      	      	   QualRate   	      	      	   Float DEFAULT 0,
   	      	      	      	   PerfDT   	      	      	      	   Float DEFAULT 0,
   	      	      	      	   RunTime   	      	      	      	   Float DEFAULT 0,
   	      	      	      	   LoadTime   	      	      	   Float DEFAULT 0,
   	      	      	      	   AvailRate   	      	      	   Float DEFAULT 0,
   	      	      	      	   OEE   	      	      	      	      	   Float DEFAULT 0
   	      	      	      	   ,NPT Float DEFAULT 0 --NPT for the time slice
   	      	      	      	   ,DowntimeA Float DEFAULT 0 --Availability downtime for the time slice
   	      	      	      	   ,DowntimeP Float DEFAULT 0 --Performance downtime for the time slice
   	      	      	      	   ,DowntimeQ Float DEFAULT 0 --Quality downtime for the time slice
   	      	      	      	   ,DowntimePL Float DEFAULT 0
  	    	    	    	   ,IsNPT BIT DEFAULT 0
 	  	  	  	   ,PuId Int
   	      	      	      	   )   	   
   	      	      	      	      	      	   
DECLARE @ProductRunCounts TABLE(   	   
   	      	      	      	   ProdId int,
   	      	      	      	   Counts int
 	  	  	  	  	  	  	   ,PuId Int
 	  	  	  	  	  	  	   ,Unique(ProdId,PuId))
DECLARE   @MultipleRunProducts TABLE(
   	      	      	      	   MRPId int IDENTITY (1,1) PRIMARY KEY NONCLUSTERED,
   	      	      	      	   ProdId int,
   	      	      	      	   ProdCodeDesc nvarchar(50),
   	      	      	      	   StartTime datetime,
   	      	      	      	   EndTime datetime,
   	      	      	      	   ProdIdMRPId nvarchar(50)
 	  	  	  	  	  	  	   ,PuId int
   	      	      	      	   )
Update s
SET s.ProductionRateFactor = dbo.fnGEPSProdRateFactor(pu.Production_Rate_TimeUnits)
From 
@Slices s
Join Prod_Units_base pu on pu.PU_Id = s.PUId
--SET ProductionRateFactor = 
--SELECT   	   @ProductionRateFactor   	      	   = dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits)
--FROM dbo.Prod_Units 
--WHERE PU_Id = @PUId
DELETE FROM @Slices WHERE PUId = 0
Update @Slices SET ProductionDay = 
Case when @InTimeZone is null then ProductionDay else ProductionDay at time zone @DBZone at time zone @InTimeZone end
WHERE ProductionDay IS NOT NULL -- Ramesh
DELETE FROM @rsSlices
/********************************************************************
*   	      	      	      	      	   ShiftDesc Summary
********************************************************************/
DELETE FROM @rsSlices
IF @rptParmShiftSummary = 1
   	   BEGIN
   	      	   INSERT INTO @rsSlices (   	      	   
   	      	      	      	   RSSubGroup,
   	      	      	      	   ShiftDesc,
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
   	      	      	      	   ,NPT
   	      	      	      	   ,DowntimeA
   	      	      	      	   ,DowntimeP
   	      	      	      	   ,DowntimeQ
   	      	      	      	   ,DowntimePL
   	      	      	      	   )
   	      	   -- Group by ShiftDesc, product.
   	      	   SELECT   	   
   	      	      	   1 AS [rsSubGroup],
   	      	      	   ShiftDesc,
   	      	      	   CrewDesc,
   	      	      	   coalesce(AppliedProdId,ProdId),
   	      	      	   --dbo.fnGEPSIdealSpeed(sum(RunTimeGross), sum(ProductionIdeal), @ProductionRateFactor)
 	  	  	  	  	   CASE WHEN @ProductionRateFactor > 0 AND sum(RunTimeGross) > 0 THEN sum(ProductionIdeal)/(sum(RunTimeGross)/@ProductionRateFactor) ELSE 0 END
 	  	  	  	  	   ,
   	      	      	   --dbo.fnGEPSActualSpeed(sum(RunTimeGross), sum(ProductionTotal), @ProductionRateFactor)
 	  	  	  	  	   CASE WHEN @ProductionRateFactor > 0 AND sum(RunTimeGross) > 0 THEN sum(ProductionTotal)/(sum(RunTimeGross)/@ProductionRateFactor) ELSE 0 END
 	  	  	  	  	   ,
   	      	      	   sum(ProductionIdeal), 
   	      	      	   --dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates)
 	  	  	  	  	   case when sum(ProductionIdeal) > 0 THEN case when sum(ProductionTotal)/sum(ProductionIdeal)*100 > 100 and @CapRates = 1 THEN 100 Else sum(ProductionTotal)/sum(ProductionIdeal)*100 END ELSE 0 END
 	  	  	  	  	   ,
   	      	      	   --CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE 
   	      	      	   sum(ProductionNet) 
   	      	      	   --END
   	      	      	   ,
   	      	      	   sum(WasteQuantity),
   	      	      	   --dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates)
 	  	  	  	  	   case when sum(ProductionTotal) > 0 Then Case when (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 > 100 and @CapRates =1 then 100 else (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 End Else 0 End
 	  	  	  	  	   ,
   	      	      	   sum(DowntimePerformance)-- / 60
   	      	      	   ,
   	      	      	   sum(ProductiveTime)-- / 60
   	      	      	   ,
   	      	      	   sum(LoadingTime) --/ 60
   	      	      	   ,
   	      	      	   --dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates)
 	  	  	  	  	   Case when sum(LoadingTime) > 0 then case when (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 > 100 and @CapRates=1 then 100 else (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 end Else 0 End
 	  	  	  	  	   ,
   	      	      	   --dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTimeGross), @CapRates) / 100
   	      	      	   --   	   * dbo.fnGEPSPerformance(sum(ProductionTotal), sum(ProductionIdeal), @CapRates) / 100
   	      	      	   --   	   * dbo.fnGEPSQuality(sum(ProductionTotal), sum(WasteQuantity), @CapRates) / 100 * 100
 	  	  	  	  	   ((case when sum(ProductionIdeal) > 0 THEN case when sum(ProductionTotal)/sum(ProductionIdeal)*100 > 100 and @CapRates = 1 THEN 100 Else sum(ProductionTotal)/sum(ProductionIdeal)*100 END ELSE 0 END)/100*(case when sum(ProductionTotal) > 0 Then Case when (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 > 100 and @CapRates =1 then 100 else (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 End Else 0 End)/100*(Case when sum(LoadingTime) > 0 then case when (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 > 100 and @CapRates=1 then 100 else (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 end Else 0 End)/100)* 100
   	      	      	      	   ,SUM(isnull(NPT,0))
   	      	      	      	   ,SUM(isnull(DowntimeA,0))
   	      	      	      	   ,SUM(isnull(DowntimeP,0))
   	      	      	      	   ,SUM(isnull(DowntimeQ,0))
   	      	      	      	   ,SUM(isnull(DowntimePL,0))
   	      	   FROM @Slices 
   	      	   WHERE   	   (NP = 0 OR @FilterNonProductiveTime = 0)
   	      	      	   AND ShiftDesc IS NOT NULL
   	      	      	   AND ProdId IS NOT NULL
   	      	   GROUP BY ShiftDesc, ProdId,AppliedProdId,CrewDesc
   	      	   INSERT INTO @unitData(ShiftDesc,CrewDesc,Product,ProductId,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
     	        	        	        	        	        	        	        	    NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
     	        	        	        	        	        	        	        	    Loadtime,AvaliableRate,OEE ,NPT,DowntimeA,DowntimeP   	   ,DowntimeQ,DowntimePL)   	      	   
   	      	      	   SELECT 
   	      	      	   rss.ShiftDesc,
   	      	      	   rss.CrewDesc,
   	      	      	   p.Prod_Code,
   	      	      	   rss.ProdId,
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
   	      	      	   ,NPT
   	      	      	      	   ,DowntimeA
   	      	      	      	   ,DowntimeP
   	      	      	      	   ,DowntimeQ
   	      	      	      	   ,DowntimePL
   	      	   FROM @rsSlices rss
   	      	      	   LEFT JOIN [dbo].Products_base p  ON rss.ProdId = p.Prod_Id
   	      	   ORDER BY rss.SortReference,rss.Product,rss.rsSubGroup
   	   END
/********************************************************************
*   	      	      	      	      	   CrewDesc Summary
********************************************************************/
DELETE FROM @rsSlices
IF @rptParmCrewSummary = 1
   	   BEGIN
   	    
   	      	   INSERT INTO @rsSlices (   	      	   
   	      	      	      	   RSSubGroup,
   	      	      	      	   CrewDesc,
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
   	      	      	      	   ,NPT
   	      	      	      	   ,DowntimeA
   	      	      	      	   ,DowntimeP
   	      	      	      	   ,DowntimeQ
   	      	      	      	   ,DowntimePL
   	      	      	      	   )
   	      	   -- Group by CrewDesc, product
   	      	   SELECT   	   
   	      	      	   1 AS [rsSubGroup],
   	      	      	   CrewDesc,
   	      	      	   ShiftDesc,
   	      	      	   coalesce(AppliedProdId,ProdId),
   	      	      	   CASE WHEN @ProductionRateFactor > 0 AND sum(RunTimeGross) > 0 THEN sum(ProductionIdeal)/(sum(RunTimeGross)/@ProductionRateFactor) ELSE 0 END,
   	      	      	   CASE WHEN @ProductionRateFactor > 0 AND sum(RunTimeGross) > 0 THEN sum(ProductionTotal)/(sum(RunTimeGross)/@ProductionRateFactor) ELSE 0 END,
   	      	      	   sum(ProductionIdeal), 
   	      	      	   case when sum(ProductionIdeal) > 0 THEN case when sum(ProductionTotal)/sum(ProductionIdeal)*100 > 100 and @CapRates = 1 THEN 100 Else sum(ProductionTotal)/sum(ProductionIdeal)*100 END ELSE 0 END,
   	      	      	   --CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE 
   	      	      	   sum(ProductionNet) 
   	      	      	   --END
   	      	      	   ,
   	      	      	   sum(WasteQuantity),
   	      	      	   case when sum(ProductionTotal) > 0 Then Case when (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 > 100 and @CapRates =1 then 100 else (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 End Else 0 End,
   	      	      	   sum(DowntimePerformance) --/ 60
   	      	      	   ,
   	      	      	   sum(ProductiveTime) --/ 60
   	      	      	   ,
   	      	      	   sum(LoadingTime) --/ 60
   	      	      	   ,
   	      	      	   Case when sum(LoadingTime) > 0 then case when (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 > 100 and @CapRates=1 then 100 else (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 end Else 0 End,
   	      	      	   ((case when sum(ProductionIdeal) > 0 THEN case when sum(ProductionTotal)/sum(ProductionIdeal)*100 > 100 and @CapRates = 1 THEN 100 Else sum(ProductionTotal)/sum(ProductionIdeal)*100 END ELSE 0 END)/100*(case when sum(ProductionTotal) > 0 Then Case when (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 > 100 and @CapRates =1 then 100 else (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 End Else 0 End)/100*(Case when sum(LoadingTime) > 0 then case when (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 > 100 and @CapRates=1 then 100 else (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 end Else 0 End)/100)* 100
   	      	      	      	   ,SUM(isnull(NPT,0))
   	      	      	      	   ,SUM(isnull(DowntimeA,0))
   	      	      	      	   ,SUM(isnull(DowntimeP,0))
   	      	      	      	   ,SUM(isnull(DowntimeQ,0))
   	      	      	      	   ,SUM(isnull(DowntimePL,0))
   	      	   FROM @Slices 
   	      	   WHERE   	   (NP = 0 OR @FilterNonProductiveTime = 0)
   	      	      	   AND CrewDesc IS NOT NULL
   	      	      	   AND ProdId IS NOT NULL
   	      	   GROUP BY CrewDesc, ProdId,AppliedProdId,ShiftDesc
   	      	   -- Consolidate by CrewDesc 
   	      	   INSERT INTO @unitData(Product,CrewDesc,ShiftDesc,ProductId,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
     	        	        	        	        	        	        	        	    NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
     	        	        	        	        	        	        	        	    Loadtime,AvaliableRate,OEE,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL )
   	      	   SELECT 
   	      	      	   p.Prod_Code,
   	      	      	   rss.CrewDesc,
   	      	      	   rss.ShiftDesc,
   	      	      	   rss.ProdId,
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
   	      	      	   ,NPT
   	      	      	   ,DowntimeA
   	      	      	   ,DowntimeP
   	      	      	   ,DowntimeQ
   	      	      	   ,DowntimePL
   	      	   FROM @rsSlices rss
   	      	      	   LEFT JOIN [dbo].Products_base p  ON rss.ProdId = p.Prod_Id
   	      	   ORDER BY rss.SortReference,rss.rsSubGroup,rss.Product
   	   END
/********************************************************************
*   	      	      	      	      	   Product Summary
********************************************************************/
DELETE FROM @rsSlices
IF @rptParmProductSummary = 1
   	   BEGIN
   	      	   --Get all product changes over the reporting time range
   	      	      	   INSERT INTO @MultipleRunProducts (
   	      	      	      	   ProdId,
   	      	      	      	   StartTime,
   	      	      	      	   EndTime,PuId)
   	      	      	      	   SELECT ProdId , StartTime , EndTime,Pu_id FROM  dbo.fnBF_GetPSFromEventsTbl(@tempPU_Table,@PUId,@StartTime,@EndTime,16) 
   	      	      	   --END
   	      	   UPDATE mrps
   	      	   SET ProdCodeDesc = Prod_Code 
   	      	   FROM @MultipleRunProducts mrps JOIN Products_base p ON mrps.ProdId = p.Prod_id
   	      	   --Get the product counts for each product, over the reporting time range
   	      	   INSERT INTO @ProductRunCounts (ProdId,Counts,PuId)
   	      	   SELECT ProdId, count(ProdId) AS [Counts],PuId
   	      	      	   FROM @MultipleRunProducts 
   	      	      	   GROUP BY ProdId,PuId
   	      	   --Retain Products that have more than 1 product run, over the reporting time range.
   	      	   DELETE FROM @MultipleRunProducts
   	      	      	   WHERE ProdId In (SELECT ProdId FROM @ProductRunCounts WHERE Counts < 2)
   	      	   -- Loop through all the products that have more than one run, over the reporting time range.
 	  	  	   
 	  	  	   --Loop for Units
 	  	  	   Declare @Units Table(Pu_Id int, Id Int Identity(1,1))
 	  	  	   Insert into @Units Select Distinct PuId from @Slices
 	  	  	   Declare @cnt int, @total Int
 	  	  	   Select @total = Max(Id) from @Units
 	  	  	   SELECT @cnt = 1 
 	  	  	   While @cnt <= @total
 	  	  	   Begin
 	  	  	  	 SELECT @PUId = Pu_Id from @Units Where Id  = @cnt 
 	  	  	  	 SELECT @LoopCount = 1
 	  	  	  	 SELECT @MaxLoops  = count(*) FROM @MultipleRunProducts Where PuId = @PUId
 	  	  	  	  WHILE @LoopCount <= @MaxLoops
   	      	      	   BEGIN
   	      	      	      	   --Initialize
   	      	      	      	   SELECT 
   	      	      	      	      	   @CurrentRunStartTime   	   = NULL,
   	      	      	      	      	   @CurrentRunEndTime   	      	   = NULL,    	   
   	      	      	      	      	   @CurrentRunProdId   	      	   = NULL,
   	      	      	      	      	   @CurrentRunProdCodeDesc   	   = NULL,
   	      	      	      	      	   @CurrentRunMRPId   	      	   = NULL,
 	  	  	  	  	  	  	  	  	   @PuId 	  	  	  	  	  	  	  	 = NULL
   	      	      	      	   IF @LoopCount = 1  
   	      	      	      	      	   BEGIN
   	      	      	      	      	      	   SELECT TOP 1
   	      	      	      	      	      	      	   @CurrentRunStartTime   	   = StartTime,
   	      	      	      	      	      	      	   @CurrentRunEndTime   	      	   = EndTime,    	   
   	      	      	      	      	      	      	   @CurrentRunProdId   	      	   = ProdId,
   	      	      	      	      	      	      	   @CurrentRunProdCodeDesc   	   = ProdCodeDesc,
   	      	      	      	      	      	      	   @CurrentRunMRPId   	      	   = MRPId
   	      	      	      	      	      	   FROM @MultipleRunProducts Where PuId = @PUId
   	      	      	      	      	      	   ORDER BY StartTime
   	      	      	      	      	   END
   	      	      	      	   ELSE
   	      	      	      	      	   BEGIN
   	      	      	      	      	      	   SELECT TOP 1
   	      	      	      	      	      	      	   @CurrentRunStartTime   	   = StartTime,
   	      	      	      	      	      	      	   @CurrentRunEndTime   	      	   = EndTime,    	   
   	      	      	      	      	      	      	   @CurrentRunProdId   	      	   = ProdId,
   	      	      	      	      	      	      	   @CurrentRunProdCodeDesc   	   = ProdCodeDesc,
   	      	      	      	      	      	      	   @CurrentRunMRPId   	      	   = MRPId
   	      	      	      	      	      	   FROM @MultipleRunProducts
   	      	      	      	      	      	   WHERE StartTime > @LastRunStartTime and PuId = @PUId
   	      	      	      	      	      	   ORDER BY StartTime
   	      	      	      	      	   END
   	      	      	      	   SELECT @LastRunStartTime =    	   @CurrentRunStartTime
   	      	      	      	   -- Update Slices with ProdId + SubGroupId for use in subsequent sort.
   	      	      	      	   UPDATE s
   	      	      	      	      	   --SET s.ProdIdSubGroupId = convert(varchar(25),@CurrentRunProdId) + '-' + convert(varchar(25),@LoopCount)
   	      	      	      	      	   SET s.ProdIdSubGroupId = @CurrentRunProdCodeDesc + '-' + convert(nvarchar(25),@LoopCount)
   	      	      	      	      	   FROM @Slices s
   	      	      	      	      	   WHERE  s.PUId = @PUId AND s.StartTime >= @CurrentRunStartTime 
   	      	      	      	      	      	   AND s.ProdId = @CurrentRunProdId
   	      	      	      	   SELECT @LoopCount = @LoopCount + 1
   	      	      	   END 
 	  	  	  	 SET @cnt = @cnt + 1
 	  	  	   End
   	      	  
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
   	      	      	      	   ,NPT
   	      	      	      	   ,DowntimeA
   	      	      	      	   ,DowntimeP
   	      	      	      	   ,DowntimeQ
   	      	      	      	   ,DowntimePL
   	      	      	      	   ,ShiftDesc
   	      	      	      	   ,CrewDesc
   	      	      	      	   ,PPId
   	      	      	      	   ,PathId
  	    	    	    	   ,IsNPT
 	  	  	  	   ,PuId
   	      	      	      	   )
   	      	   SELECT -- Group by product for Productiondays that contain more than 1 distinct product
   	      	      	   1 AS [RSSubGroup],
   	      	      	   ProdIdSubGroupId,
   	      	      	   coalesce(AppliedProdId,ProdId),
 	  	  	   CASE WHEN (Select distinct ProductionRateFactor from @slices where PUId = s.puiD) > 0 AND sum(RunTimeGross) > 0 THEN sum(ProductionIdeal)/(sum(RunTimeGross)/(Select distinct ProductionRateFactor from @slices where PUId = s.puiD)) ELSE 0 END,
   	      	      	   CASE WHEN (Select distinct ProductionRateFactor from @slices where PUId = s.puiD) > 0 AND sum(RunTimeGross) > 0 THEN sum(ProductionTotal)/(sum(RunTimeGross)/(Select distinct ProductionRateFactor from @slices where PUId = s.puiD)) ELSE 0 END,
   	      	      	   sum(ProductionIdeal), 
   	      	      	   case when sum(ProductionIdeal) > 0 THEN case when sum(ProductionTotal)/sum(ProductionIdeal)*100 > 100 and @CapRates = 1 THEN 100 Else sum(ProductionTotal)/sum(ProductionIdeal)*100 END ELSE 0 END,
   	      	      	   --CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE 
   	      	      	   sum(ProductionNet) 
   	      	      	   --END
   	      	      	   ,
   	      	      	   sum(WasteQuantity),
   	      	      	   case when sum(ProductionTotal) > 0 Then Case when (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 > 100 and @CapRates =1 then 100 else (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 End Else 0 End,
   	      	      	   sum(DowntimePerformance)-- / 60
   	      	      	   ,
   	      	      	   sum(ProductiveTime) --/ 60
   	      	      	   ,
   	      	      	   sum(LoadingTime) --/ 60
   	      	      	   ,
   	      	      	   Case when sum(LoadingTime) > 0 then case when (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 > 100 and @CapRates=1 then 100 else (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 end Else 0 End,
   	      	      	   ((case when sum(ProductionIdeal) > 0 THEN case when sum(ProductionTotal)/sum(ProductionIdeal)*100 > 100 and @CapRates = 1 THEN 100 Else sum(ProductionTotal)/sum(ProductionIdeal)*100 END ELSE 0 END)/100*(case when sum(ProductionTotal) > 0 Then Case when (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 > 100 and @CapRates =1 then 100 else (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 End Else 0 End)/100*(Case when sum(LoadingTime) > 0 then case when (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 > 100 and @CapRates=1 then 100 else (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 end Else 0 End)/100)* 100
   	      	      	      	   ,SUM(isnull(NPT,0))
   	      	      	      	   --,9999
   	      	      	      	   ,SUM(isnull(DowntimeA,0))
   	      	      	      	   ,SUM(isnull(DowntimeP,0))
   	      	      	      	   ,SUM(isnull(DowntimeQ,0))
   	      	      	      	   ,SUM(isnull(DowntimePL,0))
   	      	      	      	   ,ShiftDesc
   	      	      	      	   ,CrewDesc
   	      	      	      	   ,PPId
   	      	      	      	   ,PathId
  	    	    	    	   ,NP
 	  	  	  	   ,PUId
   	      	   FROM @Slices s
   	      	   WHERE 
  	    	    	  --(NP = 0 OR @FilterNonProductiveTime IN(0) OR @OEEType ='Time Based')
  	    	    	  1=1
   	      	   
   	      	      	   AND ProdId IS NOT NULL
   	      	      	   
   	      	   GROUP BY AppliedProdId,ProdId, ProdIdSubGroupId,ShiftDesc,CrewDesc,PPId,PathId,NP,PUId
   	      	   INSERT INTO @unitData(ProductId,Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
     	        	        	        	        	        	        	        	    NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
     	        	        	        	        	        	        	        	    Loadtime,AvaliableRate,OEE,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL,ShiftDesc,CrewDesc
   	      	      	      	      	      	      	      	    ,PPId,ProcessOrder,PathId,PathCode ,IsNPT, PuId
   	      	      	      	      	      	      	      	     )
   	      	      	      	   SELECT 
   	      	      	      	      	   rss.ProdId,
   	      	      	      	      	   Product = p.Prod_Code,
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
   	      	      	      	      	   ,NPT
   	      	      	      	      	   ,DowntimeA
   	      	      	      	      	   ,DowntimeP
   	      	      	      	      	   ,DowntimeQ
   	      	      	      	      	   ,DowntimePL
   	      	      	      	      	   ,ShiftDesc
   	      	      	      	      	   ,CrewDesc
   	      	      	      	      	   ,rss.ppId
   	      	      	      	      	   ,pp.Process_Order
   	      	      	      	      	   ,pp.Path_Id
   	      	      	      	      	   ,pep.Path_Code
  	    	    	    	    	   ,rss.IsNPT
 	  	  	  	  	   ,rss.PuId
   	      	      	      	   FROM @rsSlices rss
   	      	      	      	      	   LEFT JOIN dbo.Products_base p  ON rss.ProdId = p.Prod_Id
   	      	      	      	      	   LEFT JOIN dbo.Production_Plan pp  ON rss.PPId = pp.PP_Id
   	      	      	      	      	   LEFT JOIN Prdexec_Paths pep  on pep.Path_Id = pp.Path_Id 
   	      	      	      	   ORDER BY rss.ProdId,rss.rsSubGroup,rss.PuId
END
/********************************************************************
*   	      	      	      	      	   Process Order Summary
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
   	      	      	      	   ,NPT
   	      	      	      	   ,DowntimeA
   	      	      	      	   ,DowntimeP
   	      	      	      	   ,DowntimeQ
   	      	      	      	   ,DowntimePL
 	  	  	  	  	  	  	   ,PuId
   	      	      	      	   )
   	      	   -- Group by Process Order, Product. 
   	      	   SELECT   	   
   	      	      	   1 AS [RSSubGroup],
   	      	      	   PPId,
   	      	      	   ProdId,
   	      	      	   CASE WHEN (Select distinct ProductionRateFactor from @slices where PUId = s.puiD) > 0 AND sum(RunTimeGross) > 0 THEN sum(ProductionIdeal)/(sum(RunTimeGross)/(Select distinct ProductionRateFactor from @slices where PUId = s.puiD)) ELSE 0 END,
   	      	      	   CASE WHEN (Select distinct ProductionRateFactor from @slices where PUId = s.puiD) > 0 AND sum(RunTimeGross) > 0 THEN sum(ProductionTotal)/(sum(RunTimeGross)/(Select distinct ProductionRateFactor from @slices where PUId = s.puiD)) ELSE 0 END,
   	      	      	   sum(ProductionIdeal), 
   	      	      	   case when sum(ProductionIdeal) > 0 THEN case when sum(ProductionTotal)/sum(ProductionIdeal)*100 > 100 and @CapRates = 1 THEN 100 Else sum(ProductionTotal)/sum(ProductionIdeal)*100 END ELSE 0 END,
   	      	      	   --CASE WHEN (sum(ProductionNet) < 0.0) THEN 0.0 ELSE 
   	      	      	   sum(ProductionNet) 
   	      	      	   --END
   	      	      	   ,
   	      	      	   sum(WasteQuantity),
   	      	      	   case when sum(ProductionTotal) > 0 Then Case when (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 > 100 and @CapRates =1 then 100 else (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 End Else 0 End,
   	      	      	   sum(DowntimePerformance) --/ 60
   	      	      	   ,
   	      	      	   sum(ProductiveTime) --/ 60
   	      	      	   ,
   	      	      	   sum(LoadingTime) --/ 60
   	      	      	   ,
   	      	      	   Case when sum(LoadingTime) > 0 then case when (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 > 100 and @CapRates=1 then 100 else (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 end Else 0 End,
   	      	      	   ((case when sum(ProductionIdeal) > 0 THEN case when sum(ProductionTotal)/sum(ProductionIdeal)*100 > 100 and @CapRates = 1 THEN 100 Else sum(ProductionTotal)/sum(ProductionIdeal)*100 END ELSE 0 END)/100*(case when sum(ProductionTotal) > 0 Then Case when (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 > 100 and @CapRates =1 then 100 else (sum(ProductionTotal)-sum(WasteQuantity))/sum(ProductionTotal)*100 End Else 0 End)/100*(Case when sum(LoadingTime) > 0 then case when (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 > 100 and @CapRates=1 then 100 else (sum(LoadingTime)-sum(RunTimeGross))/sum(LoadingTime)*100 end Else 0 End)/100)* 100
   	      	      	      	   ,SUM(isnull(NPT,0))
   	      	      	      	   ,SUM(isnull(DowntimeA,0))
   	      	      	      	   ,SUM(isnull(DowntimeP,0))
   	      	      	      	   ,SUM(isnull(DowntimeQ,0))
   	      	      	      	   ,SUM(isnull(DowntimePL,0))
 	  	  	  	  	  	  	   ,PUId
   	      	      	      	   
   	      	   FROM @Slices  s
   	      	   WHERE   	   --(NP = 0 OR @FilterNonProductiveTime = 0 OR @OEEType = 'Time Based')
  	    	    	  1=1
   	      	      	   AND PPId IS NOT NULL
   	      	      	   AND ProdId IS NOT NULL
   	      	   GROUP BY ProdId,PPId,PUId
   	   INSERT INTO @unitData(PPId,ProcessOrder,PathId,PathCode ,ProductId,Product,IdealSpeed,ActualSpeed ,IdealProduction,PerformanceRate,
     	        	        	        	        	        	        	   NetProduction ,Waste,QualityRate,PerformanceDowntime,RunTime,
     	        	        	        	        	        	        	   Loadtime,AvaliableRate,OEE ,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL,PuId)   	   
   	      	   SELECT 
   	      	      	   rss.ppId,
   	      	      	   pp.Process_Order,
   	      	      	   pp.Path_Id,
   	      	      	   pep.Path_Code,
   	      	      	   rss.prodId,
   	      	      	   p.Prod_Code,
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
   	      	      	   ,NPT
   	      	      	   ,DowntimeA
   	      	      	   ,DowntimeP
   	      	      	   ,DowntimeQ
   	      	      	   ,DowntimePL
 	  	  	  	  	   ,PuId
   	      	   FROM @rsSlices rss
   	      	      	   LEFT JOIN dbo.Production_Plan pp  ON rss.PPId = pp.PP_Id
   	      	      	   LEFT JOIN Prdexec_Paths pep  on pep.Path_Id = pp.Path_Id 
   	      	      	   LEFT JOIN dbo.Products_base p  ON rss.ProdId = p.Prod_Id
   	      	   ORDER BY SortReference, rsSubGroup, ProcessOrder,PuId
   	   END -- Process Order Summary
 	  	 
 	  	 UPDATE u
 	  	 SET 
 	  	  	 DowntimeA = Case When pu.OEEType <> 4 Then (Loadtime) - (RunTime+PerformanceDowntime) Else (DowntimeA) End ,
   	      	 DowntimeP = Case When pu.OEEType <> 4 Then 
   	      	 Case when IdealProduction > 0 Then ((RunTime)*(IdealProduction)-(RunTime)*(NetProduction))/(IdealProduction) else 0 end Else (DowntimeP) End,
   	      	 DowntimeQ = Case When pu.OEEType <> 4 Then Case when IdealProduction > 0 Then   	   (((RunTime)*(NetProduction))-((RunTime)*(NetProduction - Waste)))/(IdealProduction) else 0 end   	   Else (DowntimeQ) End ,
   	      	 DowntimePL = isnull((DowntimePL),0),
 	  	  	 u.OEEType = pu.OEEType
 	  	 From @unitData u
 	  	 join @tempPU_Table pu on pu.Pu_Id = u.PuId
   	   --UPDATE @unitData
   	   --SET 
   	   --   	   DowntimeA = Case When @OEEType <>'Time Based' Then (Loadtime) - (RunTime+PerformanceDowntime) Else (DowntimeA) End ,
   	   --   	   DowntimeP = Case When @OEEType <>'Time Based' Then 
   	   --   	   Case when IdealProduction > 0 Then ((RunTime)*(IdealProduction)-(RunTime)*(NetProduction))/(IdealProduction) else 0 end Else (DowntimeP) End,
   	   --   	   DowntimeQ = Case When @OEEType <>'Time Based' Then Case when IdealProduction > 0 Then   	   (((RunTime)*(NetProduction))-((RunTime)*(NetProduction - Waste)))/(IdealProduction) else 0 end   	   Else (DowntimeQ) End ,
   	   --   	   DowntimePL = isnull((DowntimePL),0)
   	    
 RETURN
END
