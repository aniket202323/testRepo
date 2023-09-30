CREATE PROCEDURE [dbo].[spBF_OEEGetDataForOrders_SerialLine]
@LineId                int, 
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@InTimeZone 	              nVarChar(200) = null,
@ReportType 	  	  	  	 Int,
@ReturnLineData 	  	  	 Int = 0
AS
set nocount on
SET @InTimeZone = 'UTC'
SELECT @ReturnLineData = Coalesce(@ReturnLineData,0)
Declare @UnitList  nvarchar(max)
DECLARE
  	    	  @UnitRows  	    	  int,
  	    	  @Row  	    	    	  int,
  	    	  @ReportPUId  	    	  int,
  	    	  @OEECalcType  	  Int,
  	    	  @Performance  	  Float,
  	    	  @ReworkTime  	    	  Float,
  	    	  @ConvertedST  	  DateTime,
  	    	  @ConvertedET  	  DateTime
DECLARE @ProductionAmount Float
DECLARE @IdealProductionAmount Float
DECLARE @PerformanceTbl TABLE (ProductionAmount Float,IdealProductionAmount Float)
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @UseAggTable 	 Int = 0
DECLARE @AGGReportType Int
DECLARE 	  	 @CapRates 	  	  	  	  	  	 tinyint
SELECT 	 @CapRates = dbo.fnCMN_OEERateIsCapped()
DECLARE @Units TABLE
  ( RowID int IDENTITY,
  	  UnitId int NULL ,
  	  UnitDesc nVarChar(100) NULL,
  	  UnitOrder int null,
  	  LineId int NULL, 
  	  Line nVarChar(100) NULL,
  	  OEEType  	  Int Null
)
DECLARE @SortedUnits TABLE
  ( RowID int IDENTITY,
  	  UnitId int NULL ,
  	  UnitDesc nVarChar(100) NULL,
  	  UnitOrder int null,
  	  LineId int NULL, 
  	  Line nVarChar(100) NULL,
  	  OEEType  	  Int Null
)
DECLARE @UnitSummary TABLE
(
  	  ProdId Int,
 	  ProdDesc nvarchar(100),
 	  DeptId 	 Int,
 	  LineId Int,
  	  UnitId Int,
 	  PathId Int,
 	  PPId 	 Int,
 	  ShiftDesc 	 nvarchar(50),
  	  CrewDesc 	 nvarchar(50),
 	  IdealProductionAmount Float,
  	  NetProductionAmount Float,
  	  ActualSpeed Float,
  	  IdealSpeed Float,
  	  PerformanceRate Float,
  	  WasteAmount Float null,
  	  QualityRate Float null,
  	  PerformanceTime Float DEFAULT 0,
  	  RunTime Float DEFAULT 0,
  	  LoadingTime Float DEFAULT 0,
  	  AvailableRate Float null,
  	  PercentOEE  Float DEFAULT 0,
  	  ReworkTime 	  Float 	 DEFAULT 0,
 	  TypeofKPI int Default 0
)
DECLARE  @Results TABLE (DeptId Int,LineId Int,UnitId Int,PathId Int,PathCode nvarchar(100),ProcessOrder nvarchar(100),PPId Int,CrewDesc nvarchar(50),ShiftDesc nvarchar(50),ProductCode nvarchar(100), ProdId Int, UnitDesc  nvarchar(100), UnitOrder Int,ProductionAmount Float, 
  	  	  	  	  	  	 IdealProductionAmount Float, ActualSpeed  Float, IdealSpeed Float, PerformanceRate Float, WasteAmount Float, 
  	  	  	  	  	  	 QualityRate  Float, PerformanceTime Float, RunTime Float,  LoadingTime Float,   AvailableRate  Float,   	   
  	  	  	  	  	  	 PercentOEE Float)
Declare @Availabilitytable TABLE (
  	  ProdId Int,
 	  ProdDesc nvarchar(100),
 	  DeptId 	 Int,
 	  LineId Int,
  	  UnitId Int,
 	  PathId Int,
 	  PPId 	 Int,
 	  ShiftDesc 	 nvarchar(50),
  	  CrewDesc 	 nvarchar(50),
 	  IdealProductionAmount Float,
  	  NetProductionAmount Float,
  	  ActualSpeed Float,
  	  IdealSpeed Float,
  	  PerformanceRate Float,
  	  WasteAmount Float null,
  	  QualityRate Float null,
  	  PerformanceTime Float DEFAULT 0,
  	  RunTime Float DEFAULT 0,
  	  LoadingTime Float DEFAULT 0,
  	  AvailableRate Float null,
  	  PercentOEE  Float DEFAULT 0,
  	  ReworkTime 	  Float 	 DEFAULT 0
)
Declare @DownTimeUnit Int 
DECLARE @WasteUnits TABLE  (Id int IDENTITY(1,1),PUId int NULL,ProductionStartTime Int Null)
DECLARE @ProductionUnits TABLE  (Id int IDENTITY(1,1),PUId int NULL,PVarId Int Null,ProductionStartTime Int Null,ProductionType Int Null)
--get related units 
SELECT @DowntimeUnit = MIN(a.PU_Id)
 	 FROM Prod_Units_Base a
 	 JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
 	 JOIN Table_Fields_Values c ON c.TableId = 43 and a.PU_Id = c.KeyId and c.Table_Field_Id = -92
 	 WHERE a.pl_Id = @LineId 
INSERT INTO @ProductionUnits (PUId,PVarId,ProductionStartTime,ProductionType) 	 
 	 SELECT PU_Id,Production_Variable,Uses_Start_Time,Production_Type
 	  	 FROM Prod_Units_Base a
 	  	 JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
 	  	 JOIN Table_Fields_Values c ON c.TableId = 43 and a.PU_Id = c.KeyId and c.Table_Field_Id = -94
 	  	 WHERE a.pl_Id = @LineId 
INSERT INTO @WasteUnits (PUId,ProductionStartTime) 	 
 	 SELECT PU_Id,Uses_Start_Time
 	  	 FROM Prod_Units_Base a
 	  	 JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
 	  	 JOIN Table_Fields_Values c ON c.TableId = 43 and a.PU_Id = c.KeyId and c.Table_Field_Id = -93
 	  	 WHERE a.pl_Id = @LineId 
SELECT @UseAggTable = Coalesce(Value,0) FROM Site_parameters where parm_Id = 607
SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@EndTime,@InTimeZone)
--get downtimedata 
IF @UseAggTable = 0
 	 BEGIN
  	  	 INSERT INTO @UnitSummary (ProdDesc,PPId,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
  	    	    	    	  	 NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
  	    	    	    	  	 LoadingTime,AvailableRate,PercentOEE,UnitId
  	    	    	  	 )
  	    	  	 SELECT  	  Product,PPId,ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
  	    	    	    	  	 NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
  	    	    	    	  	 Loadtime,AvaliableRate,OEE,@DowntimeUnit
  	    	  	 FROM  	  dbo.fnBF_wrQuickOEEOrderSummary  (@DowntimeUnit,@StartTime,@EndTime,@InTimeZone,1, @ReportType,1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @ReportType = 1 SET @AGGReportType = 4 /* Order*/
 	  	 IF @ReportType In(2,3) SET @AGGReportType = 5 /* Crew,shift */
 	  	 IF @ReportType = 4 SET @AGGReportType = 6 /* Path */
 	  	 INSERT INTO @UnitSummary (ProdDesc,PPId,PathId,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
  	    	  	  	 NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
  	    	  	  	 LoadingTime,AvailableRate,PercentOEE,UnitId
  	  	  	 )
 	  	 SELECT  	  Product,PPId,PathId, ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
  	    	  	  	 NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
  	    	  	  	 Loadtime,AvaliableRate,OEE,@DowntimeUnit
 	  	 FROM  	  dbo.fnBF_wrQuickOEESummaryAgg  (@DowntimeUnit,@StartTime,@EndTime,@InTimeZone, @AGGReportType,0)
 	 END
Update @UnitSummary set IdealProductionAmount = null,PerformanceRate = null,UnitId = @DowntimeUnit,
  	    	  	  	 NetProductionAmount = null,WasteAmount = null,QualityRate = null,PercentOEE = null,TypeofKPI = 1 
UPdate @UnitSummary Set LineId = PL_Id 
 	 FROM Prod_Units_Base a
 	 JOIN @UnitSummary b on b.UnitId = a.PU_Id
UPdate @UnitSummary Set DeptId  = Dept_Id 
 	 FROM Prod_Lines_Base a
 	 JOIN @UnitSummary b on b.LineId = a.PL_Id 
--this is end of downtime data 
--start of Performance data 
SELECT @UnitRows = Count(*) FROM @ProductionUnits
Set @Row  	    	  =  	  0  	   
 --PRINT @UnitRows
-------------------------------------------------------------------------------------------------
-- Loop through units and get OEE Data
-------------------------------------------------------------------------------------------------
WHILE @Row <  @UnitRows
BEGIN
 	 SELECT @Row = @Row + 1
 	 SELECT @ReportPUID = PUId FROM @ProductionUnits WHERE Id = @Row
 	 IF @UseAggTable = 0
 	 BEGIN
  	  	 INSERT INTO @UnitSummary (ProdDesc,PPId,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
  	    	    	    	  	 NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
  	    	    	    	  	 LoadingTime,AvailableRate,PercentOEE,UnitId,TypeofKPI
  	    	    	  	 )
  	    	  	 SELECT  	  Product,PPId,ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
  	    	    	    	  	 NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
  	    	    	    	  	 Loadtime,AvaliableRate,OEE,@ReportPUID,2
  	    	  	 FROM  	  dbo.fnBF_wrQuickOEEOrderSummary  (@ReportPUID,@StartTime,@EndTime,@InTimeZone,1, @ReportType,1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @ReportType = 1 SET @AGGReportType = 4 /* Order*/
 	  	 IF @ReportType In(2,3) SET @AGGReportType = 5 /* Crew,shift */
 	  	 IF @ReportType = 4 SET @AGGReportType = 6 /* Path */
 	  	 INSERT INTO @UnitSummary (ProdDesc,PPId,PathId,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
  	    	  	  	 NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
  	    	  	  	 LoadingTime,AvailableRate,PercentOEE,UnitId,TypeofKPI
  	  	  	 )
 	  	 SELECT  	  Product,PPId,PathId, ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
  	    	  	  	 NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
  	    	  	  	 Loadtime,AvaliableRate,OEE,@ReportPUID,2
 	  	 FROM  	  dbo.fnBF_wrQuickOEESummaryAgg  (@ReportPUID,@StartTime,@EndTime,@InTimeZone, @AGGReportType,0)
 	 END
  	  IF @ReturnLineData = 2 -- Long Running 840D
  	  BEGIN
 	  	 /* 	 Performance = Sum(ET)/Available Time
 	  	  	 Available Time = Calendar Time - Planned DT  	  	  	  	  	 
 	  	  	 ET = Equivalent Time (Variable providing runtime over interval) 	 
 	  	 */ 	 
  	    	  SELECT  @ProductionAmount = ProductionAmount/60.00
 	  	  	 FROM  dbo.fnCMN_Performance840D(@ReportPUID,@ConvertedST, @ConvertedET, 1) 
 	  	  SELECT @IdealProductionAmount = RunTime 
 	  	  	 FROM @UnitSummary
 	  	  	 WHERE UnitId = @ReportPUID
  	    	  UPDATE @UnitSummary SET IdealProductionAmount = @IdealProductionAmount,
  	    	    	    	    	  NetProductionAmount = @ProductionAmount, -- Storing actual in net field
  	    	    	    	    	  PerformanceRate = CASE WHEN @IdealProductionAmount <= 0 THEN 0 ELSE @ProductionAmount/@IdealProductionAmount * 1.00 END
  	    	    	  WHERE UnitId = @ReportPUID
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFROMEvents(@ReportPUID,@ConvertedST, @ConvertedET,1)/60.00 
  	    	  UPDATE @UnitSummary SET QualityRate = 1 - CASE WHEN @IdealProductionAmount <= 0 THEN 0 ELSE @ReworkTime/@IdealProductionAmount*1.00 END,
  	    	  	 ReworkTime = @ReworkTime
   	    	   WHERE UnitId = @ReportPUID
  	  END
  	  IF @ReturnLineData = 3 --  Long Running EDM
  	  BEGIN
   	  	  INSERT INTO @PerformanceTbl(ProductionAmount,IdealProductionAmount)
  	    	    	  SELECT ProductionAmount,IdealProductionAmount 
  	    	    	  FROM dbo.fnCMN_PerformanceEDM(@ReportPUID,@ConvertedST, @ConvertedET,1) 
  	    	  SELECT  @ProductionAmount = ProductionAmount,@IdealProductionAmount = IdealProductionAmount
  	    	    	  FROM @PerformanceTbl
  	    	  UPDATE @UnitSummary SET IdealProductionAmount = @IdealProductionAmount,
  	    	    	    	    	  NetProductionAmount = @ProductionAmount, -- Storing actual in net field
  	    	    	    	    	  PerformanceRate = CASE WHEN @ProductionAmount <= 0 THEN 0 ELSE   @IdealProductionAmount/@ProductionAmount  * 1.00 END
  	    	    	  WHERE UnitId = @ReportPUID  	    	  
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFROMEvents(@ReportPUID,@ConvertedST, @ConvertedET,1)/60.00
  	    	  UPDATE @UnitSummary SET QualityRate = 1 - CASE WHEN @ProductionAmount <= 0 THEN 0 ELSE @ReworkTime/@ProductionAmount *1.00 END,
  	    	  	 ReworkTime = @ReworkTime
  	    	   WHERE UnitId = @ReportPUID
  	  END
END
UPdate @UnitSummary Set LineId = PL_Id 
 	 FROM Prod_Units_Base a
 	 JOIN @UnitSummary b on b.UnitId = a.PU_Id WHERE TypeofKPI = 2
UPdate @UnitSummary Set DeptId  = Dept_Id 
 	 FROM Prod_Lines_Base a
 	 JOIN @UnitSummary b on b.LineId = a.PL_Id  WHERE TypeofKPI = 2
UPdate @UnitSummary set WasteAmount = null,QualityRate = null,PerformanceTime = null,RunTime = null,
  	    	    	    	  	 LoadingTime = null,AvailableRate= null,PercentOEE = null where TypeofKPI = 2
--end of performance data
--start of quality data
SELECT @UnitRows = Count(*) FROM @WasteUnits
Set @Row  	    	  =  	  0  	   
-------------------------------------------------------------------------------------------------
-- Loop through units and get OEE Data
-------------------------------------------------------------------------------------------------
WHILE @Row <  @UnitRows
BEGIN
 	 SELECT @Row = @Row + 1
 	 SELECT @ReportPUID = PUId FROM @WasteUnits WHERE Id = @Row
 	 IF @UseAggTable = 0
 	 BEGIN
  	  	 INSERT INTO @UnitSummary (ProdDesc,PPId,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
  	    	    	    	  	 NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
  	    	    	    	  	 LoadingTime,AvailableRate,PercentOEE,UnitId,TypeofKPI
  	    	    	  	 )
  	    	  	 SELECT  	  Product,PPId,ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
  	    	    	    	  	 NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
  	    	    	    	  	 Loadtime,AvaliableRate,OEE,@ReportPUID,3
  	    	  	 FROM  	  dbo.fnBF_wrQuickOEEOrderSummary  (@ReportPUID,@StartTime,@EndTime,@InTimeZone,1, @ReportType,1)
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @ReportType = 1 SET @AGGReportType = 4 /* Order*/
 	  	 IF @ReportType In(2,3) SET @AGGReportType = 5 /* Crew,shift */
 	  	 IF @ReportType = 4 SET @AGGReportType = 6 /* Path */
 	  	 INSERT INTO @UnitSummary (ProdDesc,PPId,PathId,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
  	    	  	  	 NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
  	    	  	  	 LoadingTime,AvailableRate,PercentOEE,UnitId,TypeofKPI
  	  	  	 )
 	  	 SELECT  	  Product,PPId,PathId, ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
  	    	  	  	 NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
  	    	  	  	 Loadtime,AvaliableRate,OEE,@ReportPUID,3
 	  	 FROM  	  dbo.fnBF_wrQuickOEESummaryAgg  (@ReportPUID,@StartTime,@EndTime,@InTimeZone, @AGGReportType,0)
 	 END
  	  IF @ReturnLineData = 2 -- Long Running 840D
  	  BEGIN
 	  	 /* 	 Performance = Sum(ET)/Available Time
 	  	  	 Available Time = Calendar Time - Planned DT  	  	  	  	  	 
 	  	  	 ET = Equivalent Time (Variable providing runtime over interval) 	 
 	  	 */ 	 
  	    	  SELECT  @ProductionAmount = ProductionAmount/60.00
 	  	  	 FROM  dbo.fnCMN_Performance840D(@ReportPUID,@ConvertedST, @ConvertedET, 1) 
 	  	  SELECT @IdealProductionAmount = RunTime 
 	  	  	 FROM @UnitSummary
 	  	  	 WHERE UnitId = @ReportPUID
  	    	  UPDATE @UnitSummary SET IdealProductionAmount = @IdealProductionAmount,
  	    	    	    	    	  NetProductionAmount = @ProductionAmount, -- Storing actual in net field
  	    	    	    	    	  PerformanceRate = CASE WHEN @IdealProductionAmount <= 0 THEN 0 ELSE @ProductionAmount/@IdealProductionAmount * 1.00 END
  	    	    	  WHERE UnitId = @ReportPUID
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFROMEvents(@ReportPUID,@ConvertedST, @ConvertedET,1)/60.00 
  	    	  UPDATE @UnitSummary SET QualityRate = 1 - CASE WHEN @IdealProductionAmount <= 0 THEN 0 ELSE @ReworkTime/@IdealProductionAmount*1.00 END,
  	    	  	 ReworkTime = @ReworkTime
   	    	   WHERE UnitId = @ReportPUID
  	  END
  	  IF @ReturnLineData = 3 --  Long Running EDM
  	  BEGIN
   	  	  INSERT INTO @PerformanceTbl(ProductionAmount,IdealProductionAmount)
  	    	    	  SELECT ProductionAmount,IdealProductionAmount 
  	    	    	  FROM dbo.fnCMN_PerformanceEDM(@ReportPUID,@ConvertedST, @ConvertedET,1) 
  	    	  SELECT  @ProductionAmount = ProductionAmount,@IdealProductionAmount = IdealProductionAmount
  	    	    	  FROM @PerformanceTbl
  	    	  UPDATE @UnitSummary SET IdealProductionAmount = @IdealProductionAmount,
  	    	    	    	    	  NetProductionAmount = @ProductionAmount, -- Storing actual in net field
  	    	    	    	    	  PerformanceRate = CASE WHEN @ProductionAmount <= 0 THEN 0 ELSE   @IdealProductionAmount/@ProductionAmount  * 1.00 END
  	    	    	  WHERE UnitId = @ReportPUID  	    	  
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFROMEvents(@ReportPUID,@ConvertedST, @ConvertedET,1)/60.00
  	    	  UPDATE @UnitSummary SET QualityRate = 1 - CASE WHEN @ProductionAmount <= 0 THEN 0 ELSE @ReworkTime/@ProductionAmount *1.00 END,
  	    	  	 ReworkTime = @ReworkTime
  	    	   WHERE UnitId = @ReportPUID
  	  END
END
UPdate @UnitSummary Set LineId = PL_Id 
 	 FROM Prod_Units_Base a
 	 JOIN @UnitSummary b on b.UnitId = a.PU_Id WHERE TypeofKPI = 3
UPdate @UnitSummary Set DeptId  = Dept_Id 
 	 FROM Prod_Lines_Base a
 	 JOIN @UnitSummary b on b.LineId = a.PL_Id  WHERE TypeofKPI = 3
UPdate @UnitSummary set IdealProductionAmount =  null,PerformanceRate = null,
  	    	    	    	  	 NetProductionAmount=null,PerformanceTime=null,RunTime=null,
  	    	    	    	  	 LoadingTime=null,AvailableRate=null,PercentOEE=null where TypeofKPI = 3
--end of Quality data
-------------------------------------------------------------------------------------------------
-- Final results
-------------------------------------------------------------------------------------------------
IF @ReturnLineData != 0
BEGIN
 	 INSERT INTO @Results(DeptId,LineId,UnitId,PathId,PathCode,PPId,ProcessOrder, CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate, WasteAmount, 
  	  	  	  	  	  	 QualityRate, PerformanceTime, RunTime,  LoadingTime,   AvailableRate ,   	   
  	  	  	  	  	  	 PercentOEE)
 	  SELECT  DeptId,s.LineId,s.UnitId,pp.Path_Id,pep.Path_Code, 	  
 	   PPId,pp.Process_Order,CrewDesc,ShiftDesc,ProdDesc,s.ProdId ,  UnitDesc = 'All', 
 	   UnitOrder =1 ,
  	   ProductionAmount = sum(s.NetProductionAmount), 
  	   IdealProductionAmount = Sum(s.IdealProductionAmount),
  	   ActualSpeed = Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE sum(s.NetProductionAmount)/Sum(s.RunTime) END,
  	   IdealSpeed = Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE Sum(s.IdealProductionAmount) / Sum(s.RunTime)END,
  	   PerformanceRate = CASE WHEN @ReturnLineData = 3 THEN Case WHEN Sum(s.NetProductionAmount)  = 0 THEN 0 ELSE sum(s.IdealProductionAmount)/Sum(s.NetProductionAmount)  END
  	  	  	  	  	  	  	  WHEN @ReturnLineData = 2 THEN Case WHEN Sum(s.IdealProductionAmount)  = 0 THEN 0 ELSE sum(s.NetProductionAmount) /Sum(s.IdealProductionAmount) END
 	  	  	  	  	  	 ELSE dbo.fnGEPSPerformance(sum(s.NetProductionAmount), sum(IdealProductionAmount), @CapRates)
 	  	  	  	  	  	 END,
 	   WasteAmount = Sum(s.WasteAmount), 
  	   QualityRate = CASE WHEN @ReturnLineData = 2 THEN 	 (1 - (CASE WHEN sum(s.RunTime) <= 0 THEN 0 ELSE (SUM(ReworkTime)/sum(s.RunTime)) END))
 	  	  	  	  	  	  WHEN @ReturnLineData = 3 THEN 	 (1 - (CASE WHEN SUM(s.NetProductionAmount) <= 0 THEN 0 ELSE (SUM(ReworkTime)/SUM(s.NetProductionAmount)) END))
 	  	  	  	  	  	  ELSE dbo.fnGEPSQuality(sum(s.NetProductionAmount), sum(s.WasteAmount), @CapRates)
 	  	  	  	  	  	  END, 
  	   PerformanceTime = sum(s.PerformanceTime), 
  	   RunTime = sum(s.RunTime), 
  	   LoadingTime = sum(s.LoadingTime), 
  	   AvailableRate =  dbo.fnGEPSAvailability(sum(s.LoadingTime), sum(s.RunTime), @CapRates),   	   
  	   PercentOEE = 0
  	    FROM @UnitSummary s
 	    Left Join Production_Plan pp On pp.PP_Id = s.PPId 
 	    Left Join Prdexec_Paths pep on pep.Path_Id = pp.Path_Id 
  	    GROUP BY DeptId,s.LineId,s.UnitId,pp.Path_Id,ProdId,CrewDesc,ShiftDesc,PPId,Process_Order,ProdDesc,pep.Path_Code
 	  UPDATE @Results Set PercentOEE = PerformanceRate/100 * AvailableRate/100 * QualityRate/100 * 100
 	 IF @ReportType = 1
 	 BEGIN
 	  	 SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate , PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate  ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE 
 	  	 FROM @Results
 	  	 Order by ProcessOrder
 	 END
 	 IF @ReportType = 2
 	 BEGIN
 	  	  SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00
 	  	  FROM @Results
 	  	  Order by ShiftDesc,ProcessOrder
 	 END 	 IF @ReportType = 3
 	 BEGIN
 	  	 SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00
 	  	 FROM @Results
 	  	 Order by CrewDesc,ProcessOrder
 	 END
 	 IF @ReportType = 4
 	 BEGIN
 	  	  SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00
 	  	  FROM @Results
 	  	  ORDER BY PathId,ProcessOrder
 	  	  --Select * from @Results --test
 	 END
END
ELSE
BEGIN
  	  SELECT  s.PPId,s.CrewDesc,s.ShiftDesc,p.Prod_Code,s.ProdId , s.UnitID, u.PU_Desc, u.PU_Order, s.NetProductionAmount, s.IdealProductionAmount,
  	    	    	  s.ActualSpeed, s.IdealSpeed, s.PerformanceRate, s.WasteAmount, s.QualityRate,
  	    	    	  s.PerformanceTime, s.RunTime, s.LoadingTime, s.AvailableRate, s.PercentOEE
  	    FROM @UnitSummary s
  	  join Prod_Units_Base  u on u.PU_Id = s.UnitID
  	    Join Products p on p.Prod_Id = s.ProdId 
 	  	   ORDER BY s.LineId,s.UnitId
END
