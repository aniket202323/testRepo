/*
Get OEE data for a set of production units.
@UnitList                - Comma separated list of production units
@StartTime               - Start time
@EndTime                 - End time
@InTimeZone              - Ex: 'India Standard Time','Central Stardard Time'
@ReportType               - Adds a summary row which includes all units  
1 - OrderSummary 
2 - ShiftSummary 
3 - CrewSummary
4 - PathSummary
 	 
 	 EXECUTE spBF_OEEGetDataForOrders '10', '11/13/2016','11/15/2016','UTC' ,1,1
 	 EXECUTE spBF_OEEGetDataForOrders '10', '11/13/2016','11/15/2016','UTC' ,2,1
 	 EXECUTE spBF_OEEGetDataForOrders '10', '11/13/2016','11/15/2016','UTC' ,3,1
 	 EXECUTE spBF_OEEGetDataForOrders '10', '11/13/2016','11/15/2016','UTC' ,4,1
 	 EXECUTE spBF_OEEGetDataForOrders '10,6,12', '11/13/2016','11/15/2016','UTC' ,2,1
 	 EXECUTE spBF_OEEGetDataForOrders '10,6,12', '11/13/2016','11/15/2016','UTC' ,2,0
*/
CREATE PROCEDURE [dbo].[spBF_OEEGetDataForOrders]
@UnitList                nvarchar(max), 
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@InTimeZone 	              nVarChar(200) = null,
@ReportType 	  	  	  	 Int,
@ReturnLineData 	  	  	 Int = 0
,@FilterNonProductiveTime Int = 0
AS
/* ##### spBF_OEEGetDataForOrders #####
Description 	 : Returns data w.r.t. unit(s) 
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Added logic to fetch NPT, DowntimeA, DowntimeP, DowntimeQ, Downtime PL and toggle calculation based on OEE calculation type (Classic or Time Based)
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	 Divide by Zero Issue Fixed 
2018-08-02 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	 Put filter condition for unit while collecting data for units - while loop
*/
set nocount on
SET @InTimeZone = 'UTC'
SELECT @ReturnLineData = Coalesce(@ReturnLineData,0)
DECLARE
  	    	  @UnitRows  	    	  int,
  	    	  @Row  	    	    	  int,
  	    	  @ReportPUId  	    	  int,
  	    	  @OEECalcType  	  Int,
  	    	  @Performance  	  Float,
  	    	  @ReworkTime  	    	  Float,
  	    	  @ConvertedST  	  DateTime,
  	    	  @ConvertedET  	  DateTime,
 	  	  @OEEType Int
  	  declare @ProductionRateFactor float
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
   	   OEEType   	   Int Null,ProductionRateFactor Int null
)
DECLARE @SortedUnits TABLE
  ( RowID int IDENTITY,
   	   UnitId int NULL ,
   	   UnitDesc nVarChar(100) NULL,
   	   UnitOrder int null,
   	   LineId int NULL, 
   	   Line nVarChar(100) NULL,
   	   OEEType   	   Int Null,ProductionRateFactor Int null
)
DECLARE @UnitSummary TABLE
(
   	   ProdId Int,
  	   ProdDesc nvarchar(100),
  	   DeptId  	  Int,
  	   LineId Int,
   	   UnitId Int,
  	   PathId Int,
  	   PPId  	  Int,
  	   ShiftDesc  	  nvarchar(50),
   	   CrewDesc  	  nvarchar(50),
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
   	   ReworkTime  	   Float  	  DEFAULT 0
  	   ,NPT float DEFAULT 0
  	   ,DowntimeA float DEFAULT 0
  	   ,DowntimeP float DEFAULT 0
  	   ,DowntimeQ float DEFAULT 0
  	   ,DowntimePL float DEFAULT 0,ProductionRateFactor Int null
)
DECLARE  @Results TABLE (DeptId Int,LineId Int,UnitId Int,PathId Int,PathCode nvarchar(100),ProcessOrder nvarchar(100),PPId Int,CrewDesc nvarchar(50),ShiftDesc nvarchar(50),ProductCode nvarchar(100), ProdId Int, UnitDesc  nvarchar(100), UnitOrder Int,ProductionAmount Float, 
  	  	  	  	  	  	 IdealProductionAmount Float, ActualSpeed  Float, IdealSpeed Float, PerformanceRate Float, WasteAmount Float, 
  	  	  	  	  	  	 QualityRate  Float, PerformanceTime Float, RunTime Float,  LoadingTime Float,   AvailableRate  Float,   	   
  	  	  	  	  	  	 PercentOEE Float,NPT float, DowntimeA float, DowntimeP float, DowntimeQ float, DowntimePL float )
SELECT @UseAggTable = Coalesce(Value,0) FROM Site_parameters where parm_Id = 607
SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@EndTime,@InTimeZone)
-------------------------------------------------------------------------------------------------
-- Unit translation
-------------------------------------------------------------------------------------------------
If (@UnitList is Not Null)
  	  Set @UnitList = REPLACE(@UnitList, ' ', '')
if ((@UnitList is Not Null) and (LEN(@UnitList) = 0))
  	  Set @UnitList = Null
if (@UnitList is not null)
  	  begin
  	    	  INSERT INTO @Units (UnitId)
  	    	  SELECT Id FROM [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
  	  end
 	  	 ;WITH NotConfiguredUnits As
 	  	 (
 	  	  	 Select 
 	  	  	  	 Pu.Pu_Id from Prod_Units_Base Pu
 	  	  	 Where
 	  	  	  	 Not Exists (Select 1 From Table_Fields_Values Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	  	 AND Production_Rate_Specification IS NULL
 	  	 )
 	  	 Delete u
 	  	 from 
 	  	  	 @Units u 
 	  	  	 join NotConfiguredUnits nu on nu.PU_Id= u.UnitId 	  
 	  
update u
   	   Set u.UnitDesc = u1.PU_Desc,
   	      	   u.LineId = u1.PL_Id, 
   	      	   u.Line = l.PL_Desc,
   	      	   u.UnitOrder = coalesce(u1.PU_Order, 0),
 	  	  	   u.ProductionRateFactor = dbo.fnGEPSProdRateFactor(u1.Production_Rate_TimeUnits)
   	   FROM @Units u
   	   Join dbo.Prod_Units u1 on u1.PU_Id = u.UnitId
   	   Join dbo.Prod_Lines l on l.PL_Id = u1.PL_ID
INSERT INTO @SortedUnits(UnitId ,UnitDesc, UnitOrder, LineId,  Line, OEEType,ProductionRateFactor)
  	  SELECT UnitId ,UnitDesc, UnitOrder, LineId,  Line, OEEType,ProductionRateFactor
  	  FROM @Units 
  	  ORDER BY UnitOrder,UnitDesc
SELECT @UnitRows = Count(*) FROM @SortedUnits
Set @Row  	    	  =  	  0  	   
update a
  	  Set OEEType = coalesce(b.Value,1) 
  	  From @SortedUnits a
  	  left Join dbo.Table_Fields_Values  b on b.KeyId = a.UnitId   AND b.Table_Field_Id = -91 AND B.TableId = 43
 --PRINT @UnitRows
-------------------------------------------------------------------------------------------------
-- Loop through units and get OEE Data
-------------------------------------------------------------------------------------------------
WHILE @Row <  @UnitRows
BEGIN
  	  SELECT @Row = @Row + 1
  	  SELECT @ReportPUID = UnitId,@OEEType = OEEType,@ProductionRateFactor=ProductionRateFactor FROM @SortedUnits WHERE ROWID = @Row
  	  IF @UseAggTable = 0
  	  BEGIN
   	    	  INSERT INTO @UnitSummary (ProdDesc,PPId,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
   	      	      	      	    	  NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
   	      	      	      	    	  LoadingTime,AvailableRate,PercentOEE,UnitId,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL,ProductionRateFactor
   	      	      	    	  )
   	      	    	  SELECT   	   Product,PPId,ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
   	      	      	      	    	  NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
   	      	      	      	    	  Loadtime,AvaliableRate,OEE,@ReportPUID,NPT,CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND @OEEType = 4 THEN 0 ELSE DownTimeA END
  	    	    	    	  ,CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND @OEEType = 4 THEN 0 ELSE DownTimeP END
  	    	    	    	  ,CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND @OEEType = 4 THEN 0 ELSE DownTimeQ END
  	    	    	    	  ,CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND @OEEType = 4 THEN 0 ELSE DownTimePL END,@ProductionRateFactor
   	      	    	  FROM   	   dbo.fnBF_wrQuickOEEProductSummary  (@ReportPUID,@StartTime,@EndTime,@InTimeZone,1, 1,1)
  	    	    	  WHERE 
  	    	    	    	  (
  	    	    	    	    	  (IsNPT = 0 AND @OEEType <> 4 AND @FilterNonProductiveTime = 1)
  	    	    	    	    	  OR
  	    	    	    	    	  (1=1  AND @FilterNonProductiveTime =0 AND @OEEType <> 4 )
  	    	    	    	    	  OR
  	    	    	    	    	  (1=1  AND @OEEType = 4)
  	    	    	    	  )
UPDATE @UnitSummary SET NPT = 0 WHERE @OEEType <> 4 AND @FilterNonProductiveTime = 0  and UnitId = @ReportPUID
UPDATE @UnitSummary SET LoadingTime = CASE WHEN LoadingTime - NPT > 0 THEN LoadingTime - NPT ELSE 0 END, 
RunTime = CASE WHEN LoadingTime - (DowntimeA+DowntimeP+DowntimePL+DowntimeQ) - NPT > 0 THEN LoadingTime - (DowntimeA+DowntimeP+DowntimePL+DowntimeQ) - NPT ELSE 0 END  
WHERE @OEEType = 4 AND @FilterNonProductiveTime = 1  and UnitId = @ReportPUID
  	  END
  	  ELSE
  	  BEGIN
  	    	  IF @ReportType = 1 SET @AGGReportType = 4 /* Order*/
  	    	  IF @ReportType In(2,3) SET @AGGReportType = 5 /* Crew,shift */
  	    	  IF @ReportType = 4 SET @AGGReportType = 6 /* Path */
  	    	  INSERT INTO @UnitSummary (ProdDesc,PPId,PathId,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
   	      	    	    	  NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
   	      	    	    	  LoadingTime,AvailableRate,PercentOEE,UnitId,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL,ProductionRateFactor
   	    	    	  )
  	    	  SELECT   	   Product,PPId,PathId, ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
   	      	    	    	  NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
   	      	    	    	  Loadtime,AvaliableRate,OEE,@ReportPUID,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL,@ProductionRateFactor
  	    	  FROM   	   dbo.fnBF_wrQuickOEESummaryAgg  (@ReportPUID,@StartTime,@EndTime,@InTimeZone, 1,@FilterNonProductiveTime)
  	  END
   	   IF @ReturnLineData = 2 -- Long Running 840D
   	   BEGIN
  	    	  /*  	  Performance = Sum(ET)/Available Time
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
 	 --If OEE Agg store is turned off , converting classic data to Time based ones for Units with OEE Mode other than Time Based 
 	 --Divide by Zero Issue Fixed (Used "And" instead of "OR")
 	 UPDATE A
 	 SET 
 	  	 A.DownTimeA = LoadingTime - (RunTime+Isnull(PerformanceTime,0)),
 	  	 A.DownTimeP = Case when NOT (IdealProductionAmount > 0 AND NetProductionAmount+WasteAmount > 0) Then 0 Else ((RunTime+Isnull(PerformanceTime,0))*(IdealProductionAmount)-(RunTime+Isnull(PerformanceTime,0))*(NetProductionAmount+WasteAmount))/(IdealProductionAmount) end,
 	  	 A.DownTimeQ = Case when NOT ((IdealProductionAmount) > 0 AND (NetProductionAmount+WasteAmount) > 0 ) Then 0 Else (((RunTime+Isnull(PerformanceTime,0))*(NetProductionAmount+WasteAmount))-((RunTime+Isnull(PerformanceTime,0))*(NetProductionAmount)))/(IdealProductionAmount) end
 	 From @UnitSummary A 
 	 Where @UseAggTable = 0
 	 AND A.UnitID IN (Select UnitId from @SortedUnits where OEEType <> 4)
 	 
 	 
 	 --For Classic OEE mode Units if production is 0
 	 UPDATE A 
 	 SET 	  	 
 	  	 A.DownTimeP = LoadingTime - DownTimeA
 	 From @UnitSummary  A
 	 Where 
 	 A.UnitID in (Select UnitId from @SortedUnits where OEEType <> 4)
 	 And (NetProductionAmount+WasteAmount)<=0
 	 
 	 SELECT 	 @ProductionRateFactor 	  	 = dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits)
 	 FROM dbo.Prod_Units WITH (NOLOCK)
 	 WHERE PU_Id = @ReportPUID 	 
 	 UPDATE @UnitSummary 
 	 SET ActualSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), NetProductionAmount+WasteAmount, @ProductionRateFactor)
 	 ,IdealSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), IdealProductionAmount, @ProductionRateFactor)
 	 
UPdate @UnitSummary Set LineId = PL_Id 
 	 FROM Prod_Units_Base a
 	 JOIN @UnitSummary b on b.UnitId = a.PU_Id
UPdate @UnitSummary Set DeptId  = Dept_Id 
 	 FROM Prod_Lines_Base a
 	 JOIN @UnitSummary b on b.LineId = a.PL_Id
-------------------------------------------------------------------------------------------------
-- Final results
-------------------------------------------------------------------------------------------------
IF @ReturnLineData != 0
BEGIN
 	 INSERT INTO @Results(DeptId,LineId,UnitId,PathId,PathCode,PPId,ProcessOrder, CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate, WasteAmount, 
  	  	  	  	  	  	 QualityRate, PerformanceTime, RunTime,  LoadingTime,   AvailableRate ,   	   
  	  	  	  	  	  	 PercentOEE,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL)
 	  SELECT  DeptId,s.LineId,s.UnitId,pp.Path_Id,pep.Path_Code, 	  
 	   PPId,pp.Process_Order,CrewDesc,ShiftDesc,ProdDesc,s.ProdId ,  UnitDesc = 'All', 
 	   UnitOrder =1 ,
  	   ProductionAmount = sum(s.NetProductionAmount), 
  	   IdealProductionAmount = Sum(s.IdealProductionAmount),
   	    --ActualSpeed = Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE sum(s.NetProductionAmount)/Sum(s.RunTime) END,
   	    --IdealSpeed = Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE Sum(s.IdealProductionAmount) / Sum(s.RunTime)END,
 	    Actualspeed=Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE dbo.fnGEPSActualSpeed(sum(Runtime)+sum(PerformanceTime),sum(s.NetProductionAmount)+sum(WasteAmount),MAX(s.ProductionRateFactor)) END,
 	    IdealSpeed=Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE dbo.fnGEPSIdealSpeed(sum(Runtime)+sum(PerformanceTime),sum(s.IdealProductionAmount),MAX(s.ProductionRateFactor)) END,
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
 	   ,SUM(NPT),SUM(DowntimeA),SUM(DowntimeP),SUM(DowntimeQ),SUM(DowntimePL)
  	    FROM @UnitSummary s
  	    join @SortedUnits u on u.UnitId = s.UnitID
 	    Left Join Production_Plan pp On pp.PP_Id = s.PPId 
 	    Left Join Prdexec_Paths pep on pep.Path_Id = pp.Path_Id 
  	    GROUP BY DeptId,s.LineId,s.UnitId,pp.Path_Id,ProdId,CrewDesc,ShiftDesc,PPId,Process_Order,ProdDesc,pep.Path_Code
  	     UPDATE A
 	 SET 
 	  	 A.DownTimeA = LoadingTime - (RunTime+ISNULL(PerformanceTime,0)),
 	  	 A.DownTimeP = Case when NOT (IdealProductionAmount > 0 AND ProductionAmount+WasteAmount > 0) Then 0 Else ((RunTime+ISNULL(PerformanceTime,0))*(IdealProductionAmount)-(RunTime+ISNULL(PerformanceTime,0))*(ProductionAmount+WasteAmount))/(IdealProductionAmount) end,
 	  	 A.DownTimeQ = Case when NOT ((IdealProductionAmount) > 0 AND (ProductionAmount+WasteAmount) > 0 ) Then 0 Else (((RunTime+ISNULL(PerformanceTime,0))*(ProductionAmount+WasteAmount))-((RunTime+ISNULL(PerformanceTime,0))*(ProductionAmount)))/(IdealProductionAmount) end
 	 From @Results A 
 	  UPDATE  A
 	  	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END ,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END ,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END 
 	  	 From @Results A
 	  	  UPDATE @Results Set PercentOEE = PerformanceRate * AvailableRate * QualityRate
 	 IF @ReportType = 1
 	 BEGIN
 	  	 SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate , PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate  ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE ,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL
 	  	 FROM @Results
 	  	 Order by ProcessOrder
 	 END
 	 IF @ReportType = 2
 	 BEGIN
 	  	  SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL
 	  	  FROM @Results
 	  	  Order by ShiftDesc,ProcessOrder
 	 END 	 IF @ReportType = 3
 	 BEGIN
 	  	 SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL
 	  	 FROM @Results
 	  	 Order by CrewDesc,ProcessOrder
 	 END
 	 IF @ReportType = 4
 	 BEGIN
 	  	  SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode ,ProdId,UnitDesc, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL
 	  	  FROM @Results
 	  	  ORDER BY PathId,ProcessOrder
 	 END
END
ELSE
BEGIN
 	  	  	 UPDATE  	 @UnitSummary SET  	 DowntimePL = ISNULL(DowntimePL,0), DowntimeA = ISNULL(DowntimeA,0), DowntimeP = ISNULL(DowntimeP,0), DowntimeQ = ISNULL(DowntimeQ,0)
 	  	 UPDATE  s
 	  	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100
 	  	 FROM @UnitSummary s
 	  	 UPDATE @Results Set PercentOEE = (PerformanceRate * AvailableRate * QualityRate)/10000
  	  SELECT  s.PPId,s.CrewDesc,s.ShiftDesc,p.Prod_Code,s.ProdId , s.UnitID, u.UnitDesc, u.UnitOrder, s.NetProductionAmount, s.IdealProductionAmount,
  	    	    	  s.ActualSpeed, s.IdealSpeed, s.PerformanceRate, s.WasteAmount, s.QualityRate,
  	    	    	  s.PerformanceTime, s.RunTime, s.LoadingTime, s.AvailableRate, s.PercentOEE,s.NPT,s.DowntimeA,s.DowntimeP,s.DowntimeQ,s.DowntimePL
  	    FROM @UnitSummary s
  	    join @SortedUnits  u on u.UnitId = s.UnitID
  	    Join Products p on p.Prod_Id = s.ProdId 
 	     	    ORDER BY u.Line, u.UnitOrder, u.UnitDesc
END
