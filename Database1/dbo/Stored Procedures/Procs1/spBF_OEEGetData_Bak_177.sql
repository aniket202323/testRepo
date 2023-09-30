/*
Get OEE data for a set of production units.
Execute spBF_OEEGetData '1075','02/18/2017','02/20/2017',0,'UTC',1,10000,1
@UnitList                - Comma separated list of production units
@StartTime               - Start time
@EndTime                 - End time
@Summarize               - Adds a summary row which includes all units
@FilterNonProductiveTime - controls if NPT is included or not (1 = not)
@InTimeZone              - Ex: 'India Standard Time','Central Stardard Time'
*/
CREATE PROCEDURE [dbo].[spBF_OEEGetData_Bak_177]
@UnitList                nvarchar(max),
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@FilterNonProductiveTime int = 0,
@InTimeZone 	              nVarChar(200) = null,
@ReturnLineData 	  	  	 Int = 0,
@pageSize 	  	  	  	  	 Int = Null,
@pageNum 	  	  	  	  	 Int = Null,
@SortOrder 	  	  	  	  Int = 0 	  	  	  	  	 --  PercentOEE(!= 1,2,3),1 - PerformanceRate,2 - QualityRate,3 - AvailableRate
,@TotalRowCount Int =0 OUTPUT
AS
/* ##### spBF_OEEGetData #####
Description 	 : fetches data for supervisory screen donut charts
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 modified to fetch NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL, OEEmode
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
2018-05-30 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Exclude Units for which Production event is Inactive
2018-06-07 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Changed logic of excluding Units [Production rate specification is not defined and Oee mode not set]
2018-06-08 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	 Added MachineCount in resultset
2018-06-20 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE77740 	  	  	  	  	 Removed cap for PerformanceRate and PercentOEE
2018-08-02 	  	  	 Prasad 	  	  	  	 7.0 SP4 	  	  	  	  	  	  	 Put filter condition for unit while collecting data for units - while loop
2019-06-06 	  	  	 Prasad 	  	  	  	 8.0 	  	  	  	  	  	  	  	 DE110889 removed while loop as now we will be sending input as table.
*/
set nocount on
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
SELECT @ReturnLineData = Coalesce(@ReturnLineData,0)
SET @TotalRowCount=0
Declare @CapRates 	  	 tinyint
 	 
 	 SELECT 	 @CapRates = dbo.fnCMN_OEERateIsCapped()
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
SET @pageNum = coalesce(@pageNum,1)
SET @pageSize = coalesce(@pageSize,10000)
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
DECLARE @PageUnits TABLE
  ( RowID int NULL,
  	  UnitId int NULL ,
  	  Unit nVarChar(100) NULL,
  	  UnitOrder int null,
  	  LineId int NULL, 
  	  Line nVarChar(100) NULL,
  	  OEEType  	  Int Null
)
CREATE TABLE #UnitSummary
(
  	  UnitID nvarchar(4000) null,
  	  IdealProductionAmount Float null,
  	  NetProductionAmount Float null,
  	  ActualSpeed Float null,
  	  IdealSpeed Float null,
  	  PerformanceRate Float null,
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
 	  ,OEEType Int
 	  ,PuId Int
)
DECLARE  @Results TABLE (Line nvarchar(100), LineId Int, Unit  nvarchar(100), UnitOrder Int,ProductionAmount Float, 
  	  	  	  	  	  	 IdealProductionAmount Float, ActualSpeed  Float, IdealSpeed Float, PerformanceRate Float, WasteAmount Float, 
  	  	  	  	  	  	 QualityRate  Float, PerformanceTime Float, RunTime Float,  LoadingTime Float,   AvailableRate  Float,   	   
  	  	  	  	  	  	 PercentOEE Float
 	  	  	  	  	  	  	 ,NPT Float Default 0 ,DowntimeA Float Default 0,DowntimeP Float Default 0,DowntimeQ Float Default 0,DowntimePL Float Default 0, OEEType int default 0,MachineCount Int Default 0)
SELECT @UseAggTable = Coalesce(Value,0) FROM Site_parameters where parm_Id = 607
SELECT @ConvertedST = dbo.fnServer_CmnConvertToDbTime(@StartTime,@InTimeZone)
SELECT @ConvertedET = dbo.fnServer_CmnConvertToDbTime(@EndTime,@InTimeZone)
 	  	 --<Start: Logic to exclude Units>
 	  	 DECLARE @xml XML
 	  	 DECLARE @ActiveUnits TABLE(Pu_ID int)
 	  	 SET @xml = cast(('<X>'+replace(@UnitList,',','</X><X>')+'</X>') as xml)
 	  	 INSERT INTO @ActiveUnits(Pu_ID)
 	  	 SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
 	  	 SET @UnitList = NULL
 	  	 ;WITH NotConfiguredUnits As
 	  	 (
 	  	  	 Select 
 	  	  	  	 Pu.Pu_Id from Prod_Units_Base Pu
 	  	  	 Where
 	  	  	  	 Not Exists (Select 1 From Table_Fields_Values WITH(NOLOCK) Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	  	 AND Production_Rate_Specification IS NULL
 	  	 )
 	  	 insert into @Units (UnitId)
 	  	 SELECT 
 	  	  	 Au.Pu_ID
 	  	 FROM 
 	  	  	 @ActiveUnits Au
 	  	  	 LEFT OUTER JOIN NotConfiguredUnits Nu ON Nu.PU_Id = Au.Pu_ID
 	  	 WHERE 
 	  	  	 Nu.PU_Id IS NULL 	 
 	  	 --<End: Logic to exclude Units>
-------------------------------------------------------------------------------------------------
-- Unit translation
-------------------------------------------------------------------------------------------------
--If (@UnitList is Not Null)
--  	  Set @UnitList = REPLACE(@UnitList, ' ', '')
--if ((@UnitList is Not Null) and (LEN(@UnitList) = 0))
--  	  Set @UnitList = Null
--if (@UnitList is not null)
--  	  begin
-- 	  	 SET @xml = cast(('<X>'+replace(@UnitList,',','</X><X>')+'</X>') as xml)
-- 	  	 insert into @Units (UnitId)
-- 	  	 SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
--  	  end
update u
  	  Set u.Unit = u1.PU_Desc,
  	    	  u.LineId = u1.PL_Id, 
  	    	  u.Line = l.PL_Desc,
  	    	  u.UnitOrder = coalesce(u1.PU_Order, 0)
  	  From @Units u
  	  Join dbo.Prod_Units_base u1 WITH(NOLOCK) on u1.PU_Id = u.UnitId
  	  Join dbo.Prod_Lines_Base l WITH(NOLOCK) on l.PL_Id = u1.PL_ID
INSERT INTO @SortedUnits(UnitId ,Unit, UnitOrder, LineId,  Line, OEEType)
 	 SELECT UnitId ,Unit, UnitOrder, LineId,  Line, OEEType
 	 FROM @Units 
 	 ORDER BY UnitOrder,Unit
INSERT INTO @PageUnits (UnitId ,Unit, UnitOrder, LineId,  Line, OEEType)
 	 SELECT UnitId ,Unit, UnitOrder, LineId,  Line, OEEType
 	 FROM @SortedUnits 
-- 	 WHERE RowID Between @startRow and @endRow -- Commented to calculate for all the units , so result set can be sorted according to the calculated column 
 	 ORDER BY UnitOrder,Unit
 	 update a
  	  Set OEEType = coalesce(b.Value,1) 
  	  From @PageUnits a
  	  left Join dbo.Table_Fields_Values  b WITH(NOLOCK) on b.KeyId = a.UnitId   AND b.Table_Field_Id = -91 AND B.TableId = 43
--Delete P from @PageUnits p Where NOT Exists (Select 1 From Production_Starts Where Pu_id =p.UnitId and Prod_Id != 1) And OEEType <> 4 
;WITH S AS (SELECT UnitId, Row_NUMBER() OVER (Order by UnitId) rwnd FROM @PageUnits)
UPDATE P
SET P.ROWID = S.rwnd
FROM @PageUnits P JOIN S ON S.UnitId = P.UnitId
SELECT @UnitRows = Count(*) from @PageUnits
Set @Row  	    	  =  	  0  	   
Declare @PuIDTable dbo.UnitsType
Insert Into @PuIDTable
Select UnitId,OEEType,@StartTime,@EndTime,NULL,NULL From @PageUnits
Select @UnitList = COALESCE(@UnitList + ', ', '') + Cast(UnitId as nVarchar) From @PageUnits
ORDER BY UnitId
 --PRINT @UnitRows
-------------------------------------------------------------------------------------------------
-- Loop through units and get OEE Data
-------------------------------------------------------------------------------------------------
DECLARE @OEEType Int
--WHILE @Row <  @UnitRows
IF @UnitRows > 0
BEGIN
 	 SET @OEEType = 0
  	  SELECT @Row = @Row + 1
  	  SELECT @ReportPUID = UnitId,@OEEType = OEEType FROM @PageUnits WHERE ROWID = @Row
 	  IF @UseAggTable = 0
 	  BEGIN
 	  	 Insert Into #UnitSummary (UnitId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,PercentOEE,NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL,OEEType,PuId)
 	  	 SELECT  	  
 	  	  	 @ReportPUID,sum(IdealSpeed),sum(ActualSpeed),sum(IdealProduction),sum(PerformanceRate),
 	  	  	 sum(NetProduction),sum(Waste),sum(QualityRate),sum(PerformanceDowntime),sum(RunTime),
 	  	  	 sum(Loadtime),sum(AvaliableRate),sum(OEE),sum(NPT), 
 	  	  	 sum(CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND OEEType = 4 THEN 0 ELSE DownTimeA END)
 	  	  	 ,sum(CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND OEEType = 4 THEN 0 ELSE DownTimeP END)
 	  	  	 ,sum(CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND OEEType = 4 THEN 0 ELSE DownTimeQ END)
 	  	  	 , sum(CASE WHEN @FilterNonProductiveTime = 1 AND IsNPT =1 AND OEEType = 4 THEN 0 ELSE DownTimePL END)
 	  	  	 ,OEEType,PuId
 	  	 from  	 
 	  	  	 dbo.fnBF_wrQuickOEEProductSummaryTbl (@PuIDTable,@ReportPUID,@StartTime,@EndTime,@InTimeZone,@FilterNonProductiveTime,1,0)
 	  	 WHERE 
 	  	  	 (
 	  	  	  	 (IsNPT = 0 AND OEEType <> 4 AND @FilterNonProductiveTime = 1)
 	  	  	  	 OR
 	  	  	  	 (1=1  AND @FilterNonProductiveTime =0 AND OEEType <> 4 )
 	  	  	  	 OR
 	  	  	  	 (1=1  AND OEEType = 4)
 	  	  	 )
 	  	 Group by OEEType,PuId
 	  	 
 	  	 UPDATE #UnitSummary SET NPT = 0 WHERE OEEType <> 4 AND @FilterNonProductiveTime = 0 --and UnitId = @ReportPUID
 	  	 UPDATE #UnitSummary 
 	  	 SET 
 	  	  	 LoadingTime = CASE WHEN LoadingTime - NPT > 0 THEN LoadingTime - NPT ELSE 0 END, 
 	  	  	 RunTime = CASE WHEN LoadingTime - (DowntimeA+DowntimeP+DowntimePL+DowntimeQ) - NPT > 0 THEN LoadingTime - (DowntimeA+DowntimeP+DowntimePL+DowntimeQ) - NPT ELSE 0 END  
 	  	 WHERE 
 	  	  	 OEEType = 4 AND @FilterNonProductiveTime = 1 --and UnitId = @ReportPUID
 	  	 
 	  	 
 	  	 
  	  END
 	  ELSE
 	 BEGIN
 	  	 INSERT INTO #UnitSummary (UnitId,IdealSpeed,ActualSpeed,IdealProductionAmount,PerformanceRate,
  	  	  	  	 NetProductionAmount,WasteAmount,QualityRate,PerformanceTime,RunTime,
  	  	  	  	 LoadingTime,AvailableRate,PercentOEE,NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL,OEEType,PuId)
 	  	  	 SELECT  	  @ReportPUID,sum(IdealSpeed),sum(ActualSpeed),sum(IdealProduction),sum(PerformanceRate),
 	  	   	    	  	  	  	 sum(NetProduction),sum(Waste),sum(QualityRate),sum(PerformanceDowntime),sum(RunTime),
  	    	  	  	  	 sum(Loadtime),sum(AvaliableRate),sum(OEE),sum(NPT), sum(DowntimeA),sum(DowntimeP),sum(DowntimeQ), sum(DowntimePL)
 	  	  	  	  	 ,OEEType,pu_id
 	  	  	 FROM  	  dbo.fnBF_wrQuickOEESummaryAggTbl  (@UnitList,@StartTime,@EndTime,@InTimeZone, 1,@FilterNonProductiveTime
 	  	  	 )
 	  	  	 Group by OEEType,pu_id
 	  	 
 	 End
 	 UPDATE #UnitSummary SET UnitID = PuId
 	 IF @ReturnLineData = 2 -- Long Running 840D
  	  BEGIN
 	  	 /* 	 Performance = Sum(ET)/Available Time
 	  	  	 Available Time = Calendar Time - Planned DT  	  	  	  	  	 
 	  	  	 ET = Equivalent Time (Variable providing runtime over interval) 	 
 	  	 */ 	 
  	    	 /* SELECT  @ProductionAmount = ProductionAmount/60.00
 	  	  	 FROM  dbo.fnCMN_Performance840D(@ReportPUID,@ConvertedST, @ConvertedET, @FilterNonProductiveTime) 
 	  	  SELECT @IdealProductionAmount = RunTime 
 	  	  	 FROM #UnitSummary
 	  	  	 WHERE UnitId = @ReportPUID
  	    	  UPDATE #UnitSummary SET IdealProductionAmount = @IdealProductionAmount,
  	    	    	    	    	  NetProductionAmount = @ProductionAmount, -- Storing actual in net field
  	    	    	    	    	  PerformanceRate = CASE WHEN @IdealProductionAmount <= 0 THEN 0 ELSE @ProductionAmount/@IdealProductionAmount * 1.00 END
  	    	    	  WHERE UnitId = @ReportPUID
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFromEvents(@ReportPUID,@ConvertedST, @ConvertedET,@FilterNonProductiveTime)/60.00 
  	    	  UPDATE #UnitSummary SET QualityRate = 1 - CASE WHEN @IdealProductionAmount <= 0 THEN 0 ELSE @ReworkTime/@IdealProductionAmount*1.00 END,
  	    	  	 ReworkTime = @ReworkTime
   	    	   WHERE UnitId = @ReportPUID
 	  	   */
 	  	   UPDATE #UnitSummary
 	  	  	 SET 
 	  	  	  	 PerformanceRate = CASE WHEN RunTime <= 0 THEN 0 ELSE (dbo.fnCMN_Performance840D(u.PuId,@ConvertedST, @ConvertedET, @FilterNonProductiveTime)/60.00)/RunTime * 1.00 END,
 	  	  	  	 QualityRate = 1 - CASE WHEN RunTime <= 0 THEN 0 ELSE (dbo.fnCMN_QualityFromEvents(u.PuId,@ConvertedST, @ConvertedET,@FilterNonProductiveTime)/60.00)/RunTime*1.00 END,
 	  	  	  	 ReworkTime = (dbo.fnCMN_QualityFromEvents(u.PuId,@ConvertedST, @ConvertedET,@FilterNonProductiveTime)/60.00),
 	  	  	  	 NetProductionAmount= (dbo.fnCMN_Performance840D(u.PuId,@ConvertedST, @ConvertedET, @FilterNonProductiveTime)/60.00),
 	  	  	  	 IdealProductionAmount = RunTime
 	  	   
  	  END
  	  IF @ReturnLineData = 3 --  Long Running EDM
  	  BEGIN
   	  	  /*
 	  	  INSERT INTO @PerformanceTbl(ProductionAmount,IdealProductionAmount)
  	    	    	  SELECT ProductionAmount,IdealProductionAmount 
  	    	    	  FROM dbo.fnCMN_PerformanceEDM(@ReportPUID,@ConvertedST, @ConvertedET,@FilterNonProductiveTime) 
  	    	  SELECT  @ProductionAmount = ProductionAmount,@IdealProductionAmount = IdealProductionAmount
  	    	    	  FROM @PerformanceTbl
  	    	  UPDATE #UnitSummary SET IdealProductionAmount = @IdealProductionAmount,
  	    	    	    	    	  NetProductionAmount = @ProductionAmount, -- Storing actual in net field
  	    	    	    	    	  PerformanceRate = CASE WHEN @ProductionAmount <= 0 THEN 0 ELSE   @IdealProductionAmount/@ProductionAmount  * 1.00 END
  	    	    	  WHERE UnitId = @ReportPUID  	    	  
  	    	  SELECT @ReworkTime = dbo.fnCMN_QualityFromEvents(@ReportPUID,@ConvertedST, @ConvertedET,@FilterNonProductiveTime)/60.00
  	    	  UPDATE #UnitSummary SET QualityRate = 1 - CASE WHEN @ProductionAmount <= 0 THEN 0 ELSE @ReworkTime/@ProductionAmount *1.00 END,
  	    	  	 ReworkTime = @ReworkTime
  	    	   WHERE UnitId = @ReportPUID
 	  	   
 	  	 */
 	  	 UPDATE u
 	  	 SET
 	  	  	 u.IdealProductionAmount = pu.IdealProductionAmount,
 	  	  	 u.NetProductionAmount = pu.ProductionAmount,
 	  	  	 u.PerformanceRate = CASE WHEN pu.ProductionAmount <= 0 THEN 0 ELSE   pu.IdealProductionAmount/pu.ProductionAmount  * 1.00 END,
 	  	  	 u.QualityRate = 1 - CASE WHEN pu.ProductionAmount <= 0 THEN 0 ELSE (dbo.fnCMN_QualityFromEvents(u.PuId,@ConvertedST, @ConvertedET,@FilterNonProductiveTime)/60.00)/pu.ProductionAmount *1.00 END,
 	  	  	 u.ReworkTime = dbo.fnCMN_QualityFromEvents(u.PuId,@ConvertedST, @ConvertedET,@FilterNonProductiveTime)/60.00
 	  	 from #UnitSummary u cross apply dbo.fnCMN_PerformanceEDM(u.PuId,@ConvertedST, @ConvertedET,@FilterNonProductiveTime) Pu
  	  END
END
 	 
 	 --If OEE Agg store is turned off , converting classic data to Time based ones. 
 	 UPDATE A
 	 SET 
 	  	 A.DownTimeA = LoadingTime - (RunTime +Isnull(PerformanceTime,0)),
 	  	 A.DownTimeP = Case when NOT (IdealProductionAmount > 0 AND NetProductionAmount+WasteAmount > 0) Then 0 Else ((RunTime+Isnull(PerformanceTime,0))*(IdealProductionAmount)-(RunTime+Isnull(PerformanceTime,0))*(NetProductionAmount+WasteAmount))/(IdealProductionAmount) end,
 	  	 A.DownTimeQ = Case when NOT ((IdealProductionAmount) > 0 AND (NetProductionAmount+WasteAmount) > 0 ) Then 0 Else (((RunTime+Isnull(PerformanceTime,0))*(NetProductionAmount+WasteAmount))-((RunTime+Isnull(PerformanceTime,0))*(NetProductionAmount)))/(IdealProductionAmount) end
 	 From #UnitSummary A 
 	 Where @UseAggTable = 0
 	 AND A.UnitID IN (Select UnitId from @PageUnits where OEEType <> 4)
 	  	 
 	 UPDATE A
 	 SET 
 	  	 A.DownTimeA = LoadingTime - (RunTime +Isnull(PerformanceTime,0)),A.DownTimeP = Case when NOT (IdealProductionAmount > 0 AND NetProductionAmount+WasteAmount > 0) Then 0 Else ((RunTime+Isnull(PerformanceTime,0))*(IdealProductionAmount)-(RunTime+Isnull(PerformanceTime,0))*(NetProductionAmount+WasteAmount))/(IdealProductionAmount) end,
 	  	 A.DownTimeQ = Case when NOT ((IdealProductionAmount) > 0 AND (NetProductionAmount+WasteAmount) > 0 ) Then 0 Else (((RunTime+Isnull(PerformanceTime,0))*(NetProductionAmount+WasteAmount))-((RunTime+Isnull(PerformanceTime,0))*(NetProductionAmount)))/(IdealProductionAmount) end
 	 From #UnitSummary A 
 	 Where 1=1
 	 AND A.UnitID IN (Select UnitId from @PageUnits where OEEType <> 4)
 	 
 	 
 	 declare @ProductionRateFactor float
 	  	 SELECT 	 @ProductionRateFactor 	  	 = dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits)
FROM dbo.Prod_Units_base WITH (NOLOCK)
WHERE PU_Id = @ReportPUID 	 
 	 UPDATE #UnitSummary 
 	 SET ActualSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), NetProductionAmount+WasteAmount, @ProductionRateFactor)
 	 ,IdealSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), IdealProductionAmount, @ProductionRateFactor)
 	 
 	 --For Classic OEE mode Units if production is 0
 	 UPDATE A 
 	 SET 	  	 
 	  	 A.DownTimeP = LoadingTime -DownTimePL - DownTimeA
 	 From #UnitSummary  A
 	 Where 
 	 A.UnitID in (Select UnitId from @PageUnits where OEEType <> 4)
 	 And (NetProductionAmount+WasteAmount)<=0
 	 --AND LoadingTime <> RunTime
 	 
-------------------------------------------------------------------------------------------------
-- Final results
-------------------------------------------------------------------------------------------------
IF @ReturnLineData != 0
BEGIN
 	 INSERT INTO @Results(Line,LineId,Unit, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate, WasteAmount, 
  	  	  	  	  	  	 QualityRate, PerformanceTime, RunTime,  LoadingTime,   AvailableRate ,   	   
  	  	  	  	  	  	 PercentOEE,NPT, DowntimeA,DowntimeP,DowntimeQ, DowntimePL,OEEType,MachineCount)
 	  SELECT  	  u.Line, UnitID = LineId, Unit = 'All', UnitOrder = 1 ,
  	   ProductionAmount = sum(s.NetProductionAmount), 
  	   IdealProductionAmount = Sum(s.IdealProductionAmount),
  	   ActualSpeed = Case WHEN Sum(s.RunTime) = 0 THEN 0 ELSE sum(s.NetProductionAmount)/Sum(s.RunTime) END,
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
 	   ,ISNULL(SUM(NPT),0), ISNULL(SUM(DowntimeA),0),ISNULL(SUM(DowntimeP),0),ISNULL(SUM(DowntimeQ),0),ISNULL( SUM(DowntimePL),0)
 	   ,u.OEEType,0 MachineCount
 	 
  	    FROM #UnitSummary s
  	    join @PageUnits u on u.UnitId = s.UnitID
  	    GROUP BY u.Line,LineId,u.OEEType
 	    
 	    ;WITH S AS (
 	  	 Select 
 	  	  	 R.LineId,R.OEEType, Count(Distinct s.UnitID) MachineCount
 	  	 from 
 	  	  	 #UnitSummary s
 	  	  	 join @PageUnits u on u.UnitId = s.UnitID
 	  	  	 Join @Results R on R.LineId = u.LineId  and u.OEEType = R.OEEType
 	  	 Where
 	  	  	 R.LoadingTime IS NOT NULL AND s.LoadingTime is not null
 	  	 Group by R.LineId,R.OEEType
 	  	 )
 	  	 UPDATE R SET MachineCount =S.MachineCount
 	  	 FROM @Results R Join S ON S.LineId = R.LineId AND S.OEEType = R.OEEType
 	  	 UPDATE  A
 	  	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END * 100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END * 100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100
 	  	 From @Results A
 	 
 	  	 UPDATE @Results 
 	  	  	 SET 
 	  	  	  	 AvailableRate = CASE WHEN AvailableRate > 100 and @CapRates = 1 then 100 ELSE AvailableRate END,
 	  	  	  	 PerformanceRate = CASE WHEN PerformanceRate > 100 and @CapRates = 1 then 100 ELSE PerformanceRate END,
 	  	  	  	 QualityRate = CASE WHEN QualityRate > 100 and @CapRates = 1 then 100 ELSE QualityRate END
 	 UPDATE @Results
 	  	 SET 
 	  	  	 AvailableRate = Case when AvailableRate < 0 then 0 Else AvailableRate end
 	  	  	 ,PerformanceRate = Case when PerformanceRate < 0 then 0 Else PerformanceRate end
 	  	  	 ,QualityRate = Case when QualityRate < 0 then 0 Else QualityRate end
 	  UPDATE @Results Set PercentOEE = PerformanceRate * AvailableRate * QualityRate
 	  SELECT Line,LineId,Unit, UnitOrder,ProductionAmount, 
  	  	  	  	  	  	 IdealProductionAmount, ActualSpeed, IdealSpeed, PerformanceRate , WasteAmount, 
  	  	  	  	  	  	 QualityRate , PerformanceTime, RunTime,  LoadingTime,   AvailableRate  ,   	   
  	  	  	  	  	  	 PercentOEE  * 100.00,
 	  	  	  	  	  	 NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL,OEEType OEEMode,MachineCount
 	  FROM @Results
 	  Where LoadingTime IS NOT NULL
 	  ORDER By LineId
 	  OFFSET @pageSize *(@pageNum - 1) ROWS
  FETCH NEXT @pageSize ROWS ONLY; 
  Select @TotalRowCount = count(0) from @Results
END
ELSE
BEGIN
 	 
 	 
 	  	 UPDATE  	 #UnitSummary SET  	 DowntimePL = ISNULL(DowntimePL,0), DowntimeA = ISNULL(DowntimeA,0), DowntimeP = ISNULL(DowntimeP,0), DowntimeQ = ISNULL(DowntimeQ,0)
 	  	 UPDATE  s
 	  	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100
 	  	 FROM #UnitSummary s
 	  	 UPDATE #UnitSummary 
 	  	  	 SET 
 	  	  	  	 AvailableRate = CASE WHEN AvailableRate > 100 and @CapRates = 1 then 100 ELSE AvailableRate END,
 	  	  	  	 PerformanceRate = CASE WHEN PerformanceRate > 100 and @CapRates = 1 then 100 ELSE PerformanceRate END,
 	  	  	  	 QualityRate = CASE WHEN QualityRate > 100 and @CapRates = 1 then 100 ELSE QualityRate END
 	  	 
 	  	 UPDATE #UnitSummary
 	  	 SET 
 	  	  	 AvailableRate = Case when AvailableRate < 0 then 0 Else AvailableRate end
 	  	  	 ,PerformanceRate = Case when PerformanceRate < 0 then 0 Else PerformanceRate end
 	  	  	 ,QualityRate = Case when QualityRate < 0 then 0 Else QualityRate end
 	  	 UPDATE #UnitSummary Set PercentOEE = (PerformanceRate * AvailableRate * QualityRate)/10000
 	 
 	 ;with ResultSet as (
  	  SELECT  u.Line, s.UnitID, u.Unit, u.UnitOrder, s.NetProductionAmount, s.IdealProductionAmount,
  	    	    	  s.ActualSpeed, s.IdealSpeed, s.PerformanceRate, s.WasteAmount, s.QualityRate,
  	    	    	  s.PerformanceTime, s.RunTime, s.LoadingTime, s.AvailableRate, s.PercentOEE
 	  	  	  ,s.NPT, s.DowntimeA,s.DowntimeP,s.DowntimeQ, s.DowntimePL,u.OEEType OEEMode,1 MachineCount
 	  FROM #UnitSummary s
  	  join @PageUnits u on u.UnitId = s.UnitID
 	    Where s.LoadingTime IS NOT NULL)
 	 
-- Pagination and Sorting
 	    
 	  	 SELECT Line, UnitID, Unit, UnitOrder, NetProductionAmount, IdealProductionAmount,
  	    	    	    ActualSpeed, IdealSpeed, PerformanceRate, WasteAmount, QualityRate,
  	    	    	    PerformanceTime, RunTime, LoadingTime, AvailableRate, PercentOEE
 	  	  	    ,NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL, OEEMode, MachineCount FROM ResultSet 
 	  	 ORDER BY CASE 
 	  	  	  	  	  	 WHEN @SortOrder = 1 THEN PerformanceRate
 	  	  	  	  	  	 WHEN @SortOrder = 2 THEN QualityRate
 	  	  	  	  	  	 WHEN @SortOrder = 3 THEN AvailableRate
 	  	  	  	  	  	 ELSE PercentOEE
 	  	  	  	  	 END
 	  	 OFFSET @PageSize * (@pageNum - 1) ROWS
 	  	   FETCH NEXT @pageSize ROWS ONLY; 
 	  	   Select @TotalRowCount = count(Distinct S.UnitID) from   #UnitSummary s
  	  join @PageUnits u on u.UnitId = s.UnitID
 	    Where s.LoadingTime IS NOT NULL
END
