/*
Get OEE data for a set of production units.
@UnitList                - Comma separated list of production units
@StartTime               - Start time
@EndTime                 - End time
@InTimeZone              - Ex: 'India Standard Time','Central Stardard Time'
@ReportType               -
@FilterNonProductiveTime - controls if NPT is included or not (1 = not)
 	 
 	 EXECUTE spBF_OEEGetDataForProduct '1075', '02/18/2017','02/20/2017','UTC' ,1,1
 	 EXECUTE spBF_OEEGetDataForProduct '1068', '02/18/2017','02/20/2017','UTC' ,2,1
 	 EXECUTE spBF_OEEGetDataForProduct '1068', '02/18/2017','02/20/2017','UTC' ,3,1
 	 EXECUTE spBF_OEEGetDataForProduct '1068', '02/18/2017','02/20/2017','UTC' ,4,1
 	  
 	 EXECUTE spBF_OEEGetDataForProduct '10,6,12', '02/18/2017','02/20/2017','UTC' ,2,1
 	 EXECUTE spBF_OEEGetDataForProduct '10,6,12', '02/18/2017','02/20/2017','UTC' ,2,0
*/
CREATE PROCEDURE [dbo].[spBF_OEEGetDataForProduct_Bak_177]
@UnitList                nvarchar(max), 
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@InTimeZone 	              nVarChar(200) = null,
@ReportType 	  	  	  	 Int,
@ReturnLineData 	  	  	 Int = 0, @Groupby Int =0
,@FilterNonProductiveTime Int = 0
AS
/* ##### spBF_OEEGetDataForProduct #####
Description 	 : Returns data w.r.t. unit(s) 
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Added logic to fetch NPT, DowntimeA, DowntimeP, DowntimeQ, Downtime PL and toggle calculation based on OEE calculation type (Classic or Time Based)
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	 Divide by Zero Issue Fixed 
2018-08-02 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	 Put filter condition for unit while collecting data for units - while loops
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
  	    	  @ConvertedET  	  DateTime
 	  	  ,@OEEType Int
DECLARE @ProductionAmount Float
DECLARE @IdealProductionAmount Float
DECLARE @PerformanceTbl TABLE (ProductionAmount Float,IdealProductionAmount Float)
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @UseAggTable 	 Int = 0
Declare @CapRates Tinyint
SELECT 	 @CapRates = dbo.fnCMN_OEERateIsCapped()
DECLARE @Units TABLE
  ( RowID int IDENTITY,
  	  UnitId int NULL ,
  	  Unit nVarChar(100) NULL,
  	  UnitOrder int null,
  	  LineId int NULL, 
  	  Line nVarChar(100) NULL,
  	  OEEType  	  Int Null
)
DECLARE @SortedUnits TABLE
  ( RowID int IDENTITY,
  	  UnitId int NULL ,
  	  Unit nVarChar(100) NULL,
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
 	  PathCode nvarchar(100),
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
 	  ,NPT Float Default 0
 	  ,DowntimeA Float Default 0
 	  ,DowntimeP Float Default 0
 	  ,DowntimeQ Float Default 0
 	  ,DowntimePL Float Default 0
)
DECLARE  @Results TABLE (DeptId Int,LineId Int,UnitId Int,PathId Int,PathCode nvarchar(100),ProcessOrder nvarchar(100),PPId Int,CrewDesc nvarchar(50),ShiftDesc nvarchar(50),ProdCode nvarchar(100), ProdId Int, Unit  nvarchar(100), UnitOrder Int,ProductionAmount Float, 
  	  	  	  	  	  	 IdealProductionAmount Float, ActualSpeed  Float, IdealSpeed Float, PerformanceRate Float, WasteAmount Float, 
  	  	  	  	  	  	 QualityRate  Float, PerformanceTime Float, RunTime Float,  LoadingTime Float,   AvailableRate  Float,   	   
  	  	  	  	  	  	 PercentOEE Float 	 ,NPT Float Default 0 ,DowntimeA Float Default 0,DowntimeP Float Default 0,DowntimeQ Float Default 0,DowntimePL Float Default 0)
Select @UseAggTable = Coalesce(Value,0) from Site_parameters where parm_Id = 607
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
  	    	  insert into @Units (UnitId)
  	    	  select Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
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
  	  Set u.Unit = u1.PU_Desc,
  	    	  u.LineId = u1.PL_Id, 
  	    	  u.Line = l.PL_Desc,
  	    	  u.UnitOrder = coalesce(u1.PU_Order, 0)
  	  From @Units u
  	  Join dbo.Prod_Units u1 on u1.PU_Id = u.UnitId
  	  Join dbo.Prod_Lines l on l.PL_Id = u1.PL_ID
INSERT INTO @SortedUnits(UnitId ,Unit, UnitOrder, LineId,  Line, OEEType)
 	 SELECT UnitId ,Unit, UnitOrder, LineId,  Line, OEEType
 	 FROM @Units 
 	 ORDER BY UnitOrder,Unit
SELECT @UnitRows = Count(*) from @SortedUnits
Set @Row  	    	  =  	  0  	   
 	 update a
  	  Set OEEType = coalesce(b.Value,1) 
  	  From @SortedUnits a
  	  left Join dbo.Table_Fields_Values  b on b.KeyId = a.UnitId   AND b.Table_Field_Id = -91 AND B.TableId = 43
-------------------------------------------------------------------------------------------------
-- Loop through units and get OEE Data
-------------------------------------------------------------------------------------------------
WHILE @Row <  @UnitRows
BEGIN
  	  SELECT @Row = @Row + 1
  	  SELECT @ReportPUID = UnitId,@OEEType = OEEType FROM @SortedUnits WHERE ROWID = @Row
 	  IF @UseAggTable = 0 
 	  BEGIN
  	  	  Insert Into @UnitSummary (ProdDesc,PPId,PathId,PathCode,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
  	    	    	    	  	  NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
  	    	    	    	  	  LoadingTime,AvailableRate,PercentOEE,UnitId,NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL
  	    	    	  	  )
  	    	  	  select  	  Product,PPId,PathId,PathCode,  ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
  	    	    	    	  	  NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
  	    	    	    	  	  Loadtime,AvaliableRate,OEE,@ReportPUID,NPT, 
 	  	  	  	  	  CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND @OEEType = 4 THEN 0 ELSE DownTimeA END
 	  	  	  	 ,CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND @OEEType = 4 THEN 0 ELSE DownTimeP END
 	  	  	  	 ,CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND @OEEType = 4 THEN 0 ELSE DownTimeQ END
 	  	  	  	 ,CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND @OEEType = 4 THEN 0 ELSE DownTimePL END
  	    	  	    from  	  dbo.fnBF_wrQuickOEEProductSummary  (@ReportPUID,@StartTime,@EndTime,@InTimeZone,1, 1,1)--reporttype is 1 for any case
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
 	  
 	  	 --IF @ReportType = 3 SET @ReportType = 2 /* Crew,shift same agg*/
 	  	 --IF @ReportType = 4 SET @ReportType = 3 /* Order is agg type 3 */
--<Change - Prasad 2018-01-05>
 	  	 Declare @fnreturnType INT = 7
 	  	 
 	  	 SELECT @fnreturnType = CASE 
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN @ReportType = 1 AND @GroupBy = 1 THEN 10--Unit, prod
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN @ReportType = 2 AND @GroupBy = 2 THEN 11
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN @ReportType = 3 AND @GroupBy = 3 THEN 12
 	  	  	  	  	  	  	  	  	  	  	  	 --WHEN @ReportType = 1 AND @GroupBy = 2 THEN 11--unit, prod, shift
 	  	  	  	  	  	  	  	  	  	  	  	 --WHEN @ReportType = 1 AND @GroupBy = 3 THEN 12--unit, prod, crew
 	  	  	  	  	  	  	  	  	  	  	  	 --WHEN @ReportType = 2 AND @GroupBy = 1 THEN 13--unit, ppid
 	  	  	  	  	  	  	  	  	  	  	  	 --WHEN @ReportType = 2 AND @GroupBy = 2 THEN 14--unit, ppid, shift
 	  	  	  	  	  	  	  	  	  	  	  	 --WHEN @ReportType = 2 AND @GroupBy = 3 THEN 15--unit,ppid, crew
 	  	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	  	  
 	  	 
 	  	  Insert Into @UnitSummary (ProdDesc,PPId,PathId,PathCode,ShiftDesc,CrewDesc,ProdId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
  	    	    	    	  	  NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
  	    	    	    	  	  LoadingTime,AvailableRate,PercentOEE,UnitId,NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL
  	    	    	  	  )
  	    	  	  select  	  distinct Product,PPId,PathId,PathCode,  ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
  	    	    	    	  	  CAST(NetProduction as NUMERIC(12,2)),Waste,QualityRate,PerformanceDowntime,RunTime,
  	    	    	    	  	  Loadtime,AvaliableRate,OEE,@ReportPUID,NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL
  	    	  	    from  	  dbo.fnBF_wrQuickOEESummaryAgg  (@ReportPUID,@StartTime,@EndTime,@InTimeZone, 1,@FilterNonProductiveTime) 	  	    
 	  	  	    
 	  	 -- 	  union all 
 	  	 -- 	   SELECT  	  distinct 
 	  	 -- 	   'Total',PPId,PathId,PathCode,  ShiftDesc,CrewDesc,ProductId,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
  	 --   	    	    	  	  NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
  	 --   	    	    	  	  Loadtime,AvaliableRate,OEE,@ReportPUID,NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL
 	  	 -- 	   --@ReportPUID PUID,IdealSpeed,ActualSpeed,IdealProduction,PerformanceRate,
 	  	 --  	  --  	  	  	 NetProduction,Waste,QualityRate,PerformanceDowntime,RunTime,
  	 --   	 -- 	  	 Loadtime,AvaliableRate,OEE,NULL,case when @fnreturnType IN (10,11,12) then 'Total' ELSE NULL END,NULL,NULL,NULL,case when @fnreturnType IN (13,14,15) then 'Total' ELSE NULL END,case when @fnreturnType IN (12,15) then 'Total' ELSE NULL END,case when @fnreturnType IN (11,14) then 'Total' ELSE NULL END
 	  	 --FROM  	  dbo.fnBF_wrQuickOEESummaryAgg  (@ReportPUID,@StartTime,@EndTime,@InTimeZone, 1)
 	  	 --WHERE @fnreturnType <> 7 And @ReturnLineData = 0;
--</Change - Prasad 2018-01-05> 	  	 
 	  	 
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
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFromEvents(@ReportPUID,@ConvertedST, @ConvertedET,1)/60.00 
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
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFromEvents(@ReportPUID,@ConvertedST, @ConvertedET,1)/60.00
  	    	  UPDATE @UnitSummary SET QualityRate = 1 - CASE WHEN @ProductionAmount <= 0 THEN 0 ELSE @ReworkTime/@ProductionAmount *1.00 END,
  	    	  	 ReworkTime = @ReworkTime
  	    	   WHERE UnitId = @ReportPUID
  	  END
END
 	 --If OEE Agg store is turned off , converting classic data to Time based ones for Units with OEE Mode other than Time Based 
 	 --Divide by Zero Issue Fixed (Used "And" instead of "OR")
 	 UPDATE A
 	 SET 
 	  	 A.DownTimeA = LoadingTime - (RunTime+ISNULL(PerformanceTime,0)),
 	  	 A.DownTimeP = Case when NOT (IdealProductionAmount > 0 AND NetProductionAmount+WasteAmount > 0) Then 0 Else ((RunTime+ISNULL(PerformanceTime,0))*(IdealProductionAmount)-(RunTime+ISNULL(PerformanceTime,0))*(NetProductionAmount+WasteAmount))/(IdealProductionAmount) end,
 	  	 A.DownTimeQ = Case when NOT ((IdealProductionAmount) > 0 AND (NetProductionAmount+WasteAmount) > 0 ) Then 0 Else (((RunTime+ISNULL(PerformanceTime,0))*(NetProductionAmount+WasteAmount))-((RunTime+ISNULL(PerformanceTime,0))*(NetProductionAmount)))/(IdealProductionAmount) end
 	 From @UnitSummary A 
 	 Where 
 	 @UseAggTable = 0
 	 AND A.UnitID IN (Select UnitId from @SortedUnits where OEEType <> 4)
 	  	 
 	 --For Classic OEE mode Units if production is 0
 	 UPDATE A 
 	 SET 	  	 
 	  	 A.DownTimeP = LoadingTime - DownTimeA
 	 From @UnitSummary  A
 	 Where 
 	 A.UnitID in (Select UnitId from @SortedUnits where OEEType <> 4)
 	 And (NetProductionAmount+WasteAmount)<=0
 	 
 	 declare @ProductionRateFactor float
 	  	 SELECT 	 @ProductionRateFactor 	  	 = dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits)
 	  	 FROM dbo.Prod_Units WITH (NOLOCK)
 	  	 WHERE PU_Id = @ReportPUID 	 
 	  	  	 UPDATE @UnitSummary 
 	  	  	 SET ActualSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), NetProductionAmount+WasteAmount, @ProductionRateFactor)
 	  	  	 ,IdealSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), IdealProductionAmount, @ProductionRateFactor)
 	 
UPdate @UnitSummary Set LineId = PL_Id 
 	 From Prod_Units_Base a
 	 JOIN @UnitSummary b on b.UnitId = a.PU_Id
UPdate @UnitSummary Set DeptId  = Dept_Id 
 	 From Prod_Lines_Base a
 	 JOIN @UnitSummary b on b.LineId = a.PL_Id
-------------------------------------------------------------------------------------------------
-- Final results
-------------------------------------------------------------------------------------------------
IF @ReturnLineData != 0
BEGIN
 	 INSERT INTO @Results(DeptId,LineId,UnitId,PathId,PathCode,PPId,ProcessOrder, CrewDesc,ShiftDesc,ProdCode ,ProdId,Unit, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate, WasteAmount, 
  	  	  	  	  	  	 QualityRate, PerformanceTime, RunTime,  LoadingTime,   AvailableRate ,   	   
  	  	  	  	  	  	 PercentOEE,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL)
 	  SELECT  DeptId,s.LineId,s.UnitId,PathId,PathCode, 	  
 	   PPId,pp.Process_Order,CrewDesc,ShiftDesc,ProdDesc,s.ProdId ,  Unit = 'All', 
 	   UnitOrder =1 ,
  	   ProductionAmount = sum(s.NetProductionAmount), 
  	   IdealProductionAmount = Sum(s.IdealProductionAmount),
  	   ActualSpeed = Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE (sum(s.NetProductionAmount)+ sum(s.WasteAmount))/Sum(s.RunTime) END,
  	   IdealSpeed = Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE Sum(s.IdealProductionAmount) / Sum(s.RunTime)END,
  	   PerformanceRate = CASE WHEN @ReturnLineData = 3 THEN Case WHEN Sum(s.NetProductionAmount)  = 0 THEN 0 ELSE sum(s.IdealProductionAmount)/Sum(s.NetProductionAmount)  END
  	  	  	  	  	  	  	  WHEN @ReturnLineData = 2 THEN Case WHEN Sum(s.IdealProductionAmount)  = 0 THEN 0 ELSE sum(s.NetProductionAmount) /Sum(s.IdealProductionAmount) END
 	  	  	  	  	  	 ELSE Case WHEN Sum(s.IdealProductionAmount)  = 0 THEN 0 ELSE (sum(s.NetProductionAmount)+ sum(s.WasteAmount))/Sum(s.IdealProductionAmount) END
 	  	  	  	  	  	 END,
  	   
 	   WasteAmount = Sum(s.WasteAmount), 
  	   QualityRate = CASE WHEN @ReturnLineData = 2 THEN 	 (1 - (CASE WHEN sum(s.RunTime) <= 0 THEN 0 ELSE (SUM(ReworkTime)/sum(s.RunTime)) END))
 	  	  	  	  	  	  WHEN @ReturnLineData = 3 THEN 	 (1 - (CASE WHEN SUM(s.NetProductionAmount) <= 0 THEN 0 ELSE (SUM(ReworkTime)/SUM(s.NetProductionAmount)) END))
  	  	  	  	 ELSE CASE WHEN (sum(s.NetProductionAmount) + SUM(s.WasteAmount)) = 0 THEN 0  	 ELSE (sum(s.NetProductionAmount) )/(sum(s.NetProductionAmount)+ Sum(s.WasteAmount)) END
  	  	  	  	 END, 
  	   PerformanceTime = sum(s.PerformanceTime), 
  	   RunTime = sum(s.RunTime), 
  	   LoadingTime = sum(s.LoadingTime), 
  	   AvailableRate =  Case WHEN sum(s.LoadingTime) = 0 THEN 0 Else  (sum(s.RunTime) + SUM(PerformanceTime))/ sum(s.LoadingTime)  END,   	   
  	   PercentOEE = 0
 	   ,SUM(NPT),SUM(DowntimeA),SUM(DowntimeP),SUM(DowntimeQ),SUM(DowntimePL)
  	    FROM @UnitSummary s
  	    join @SortedUnits u on u.UnitId = s.UnitID
 	    Left Join Production_Plan pp On pp.PP_Id = s.PPId 
  	    GROUP BY DeptId,s.LineId,s.UnitId,PathId,ProdId,CrewDesc,ShiftDesc,PPId,Process_Order
 	    ,ProdDesc,PathCode
 	  UPDATE @Results Set PercentOEE = PerformanceRate * AvailableRate * QualityRate
 	  UPDATE  A
 	  	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END ,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END ,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END 
 	  	 From @Results A
 	  	 --UPDATE @Results 
 	  	 --SET 
 	  	 -- 	 AvailableRate = CASE WHEN AvailableRate > 100 AND @CapRates = 1 THEN 100 ELSE  AvailableRate END,
 	  	 -- 	 PerformanceRate = CASE WHEN PerformanceRate > 100 AND @CapRates = 1 THEN 100 ELSE  PerformanceRate END,
 	  	 -- 	 QualityRate = CASE WHEN QualityRate > 100 AND @CapRates = 1 THEN 100 ELSE  QualityRate END
 	  	  UPDATE @Results Set PercentOEE = PerformanceRate * AvailableRate * QualityRate
 	 IF @ReportType = 1
 	 BEGIN
 	  	 SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProdCode ,ProdId,Unit, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00, NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL
 	  	 FROM @Results
 	  	 Order by ProdCode
 	 END
 	 IF @ReportType = 2
 	 BEGIN
 	  	  SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProdCode ,ProdId,Unit, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00, NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL
 	  	  FROM @Results
 	  	  Order by ShiftDesc
 	 END 	 IF @ReportType = 3
 	 BEGIN
 	  	 SELECT DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProdCode ,ProdId,Unit, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00, NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL
 	  	 FROM @Results
 	  	 Order by CrewDesc
 	 END
 	 IF @ReportType = 4
 	 BEGIN
 	  	  SELECT DeptId,LineId,UnitId,PathId,PathCode,
 	  	  ProcessOrder,CrewDesc,ShiftDesc,ProdCode ,ProdId,Unit, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate = PerformanceRate * 100.00, WasteAmount, 
  	  	  	  	  	  	  	 QualityRate = QualityRate * 100.00, PerformanceTime, RunTime,  LoadingTime,   AvailableRate = AvailableRate * 100.00 ,   	   
  	  	  	  	  	  	  	 PercentOEE = PercentOEE  * 100.00, NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL
 	  	  FROM @Results
 	  	  ORDER BY ProcessOrder
 	 END
END
ELSE
BEGIN 
--<Change - Prasad 2018-01-05>
 	  	 UPDATE  	 @UnitSummary SET  	 DowntimePL = ISNULL(DowntimePL,0), DowntimeA = ISNULL(DowntimeA,0), DowntimeP = ISNULL(DowntimeP,0), DowntimeQ = ISNULL(DowntimeQ,0)
 	  	 UPDATE  s
 	  	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100
 	  	 FROM @UnitSummary s
 	  	 --UPDATE @Results 
 	  	 --SET 
 	  	 -- 	 AvailableRate = CASE WHEN AvailableRate > 100 AND @CapRates = 1 THEN 100 ELSE  AvailableRate END,
 	  	 -- 	 PerformanceRate = CASE WHEN PerformanceRate > 100 AND @CapRates = 1 THEN 100 ELSE  PerformanceRate END,
 	  	 -- 	 QualityRate = CASE WHEN QualityRate > 100 AND @CapRates = 1 THEN 100 ELSE  QualityRate END
 	  	 UPDATE @Results Set PercentOEE = (PerformanceRate * AvailableRate * QualityRate)/10000
  	  SELECT   
 	  DeptId,s.LineId,s.UnitId,PathId,PathCode, 	  	  
 	   s.PPId,s.CrewDesc,s.ShiftDesc,s.ProdDesc,s.ProdId , /*s.UnitID,*/ u.Unit, u.UnitOrder, s.NetProductionAmount, s.IdealProductionAmount,
  	    	    	  s.ActualSpeed, s.IdealSpeed, s.PerformanceRate, s.WasteAmount, s.QualityRate,
  	    	    	  s.PerformanceTime, s.RunTime, s.LoadingTime, s.AvailableRate, s.PercentOEE
 	  	  	  , s.NPT, s.DowntimeA, s.DowntimeP, s.DowntimeQ, s.DowntimePL
  	    FROM @UnitSummary s
  	    join @SortedUnits  u on u.UnitId = s.UnitID
  	    --left Join Products p on p.Prod_Id = s.ProdId 
 	     	    ORDER BY u.Line, u.UnitOrder, u.Unit
--</Change - Prasad 2018-01-05> 	  	    
 	  	    
END
