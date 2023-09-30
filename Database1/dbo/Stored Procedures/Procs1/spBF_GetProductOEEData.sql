--
/*  
 execute spBF_GetProductOEEData  '10,4',  '11/13/2016','11/15/2016',  0,  null,  1, 1  -- Unit
 execute spBF_GetProductOEEData  '3',  '11/13/2016','11/15/2016',  0,  null,  2, 1  -- Line
 execute spBF_GetProductOEEData  '2',  '11/13/2016','11/15/2016',  0,  null,  3, 1  -- department
 execute spBF_GetProductOEEData  '10,4',  '11/13/2016','11/15/2016',  0,  null,  1, 2  -- Unit
 execute spBF_GetProductOEEData  '3',  '11/13/2016','11/15/2016',  0,  null,  2, 2  -- Line
 execute spBF_GetProductOEEData  '2',  '11/13/2016','11/15/2016',  0,  null,  3, 2  -- department
 execute spBF_GetProductOEEData  '10,4',  '11/13/2016','11/15/2016',  0,  null,  1, 3  -- Unit
 execute spBF_GetProductOEEData  '3',  '11/13/2016','11/15/2016',  0,  null,  2, 3  -- Line
 execute spBF_GetProductOEEData  '2',  '11/13/2016','11/15/2016',  0,  null,  3, 3  -- department
 execute spBF_GetProductOEEData  '10,4',  '11/13/2016','11/15/2016',  0,  null,  1, 4  -- Unit
 execute spBF_GetProductOEEData  '3',  '11/13/2016','11/15/2016',  0,  null,  2, 4  -- Line
 execute spBF_GetProductOEEData  '2',  '11/13/2016','11/15/2016',  0,  null,  3, 4  -- department
*/
/*  
 	  	 @TimeSelection = 1 /* Current Day  */
 	  	 @TimeSelection = 2 /* Prev Day     */
 	  	 @TimeSelection = 3 /* Current Week */
 	  	 @TimeSelection = 4 /* Prev Week    */
 	  	 @TimeSelection = 5 /* Next Week    */
 	  	 @TimeSelection = 6 /* Next Day     */
 	  	 @TimeSelection = 7 /* User Defined  Max 30 days*/
 	  	 @TimeSelection = 8 /* Current Shift    */
 	  	 @TimeSelection = 9 /* Previous Shift   */
 	  	 @TimeSelection = 10 /* Next Shift      */
*/
CREATE PROCEDURE [dbo].[spBF_GetProductOEEData]
@EquipmentList           nvarchar(max), 	  	  	  	 -- Required (Null returns all Lines)
@StartTime               datetime = NULL, 	  	  	 -- Used When @TimeSelection = 0 (user Defined time)
@EndTime                 datetime = NULL, 	  	  	 -- Used When @TimeSelection = 0 (user Defined time)
@TimeSelection 	  	  	  Int = 0, 	  	  	  	  	 
@InTimeZone 	              nVarChar(200) = null, 	  	 -- timeZone to return data in (defaults to department if not supplied)
@EquipmentType 	  	  	  Int = 0, 	  -- 1 Unit,2 Line,3 Department 	  	  	  	 
@ReportType 	  	  	  	  Int = 1,  --1-Products,2-Shift,3-Crew,4-Orders
@GroupBy 	  	  	  	  Int = 1,  --1-None, 2 - Shift , 3 - Crew , 4 - Path
@ReturnTotalRowOnly  	 Int = 0
,@FilterNonProductiveTime Int = 0
AS
/* ##### spBF_GetProductOEEData #####
Description 	 : Returns data for Products in the reports w.r.t. the selection made in the reports screen
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Added logic to fetch NPT, DowntimeA, DowntimeP, DowntimeQ, Downtime PL and toggle calculation based on OEE calculation type (Classic or Time Based)
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	  	 Passed actual filter for NPT
2018-05-30 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Exclude Units for which Production event is Inactive
2018-06-07 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Changed logic of excluding Units [Production rate specification is not defined and Oee mode not set]
2018-06-20 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE77740 	  	  	  	  	 Removed cap for PerformanceRate and PercentOEE
2018-06-26 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE80574 	  	  	  	  	 Divide by zero error occurred for case when Loadtime = 0 and productionamount > 0  	 
*/
set nocount on
Declare @low Int = 50
Declare @Moderate Int = 85
Declare @Good Int = 60
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @NewPageNum INt
SET @EquipmentType  = 1
SELECT @ReturnTotalRowOnly = Coalesce(@ReturnTotalRowOnly,0)
SET @TimeSelection = Coalesce(@TimeSelection,0)
SET @EquipmentType = Coalesce(@EquipmentType,1)
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
IF @InTimeZone <> 'UTC'
BEGIN
 	 IF @StartTime Is Not Null  SELECT @StartTime = dbo.fnServer_CmnConvertTime (@StartTime , @InTimeZone,'UTC') 
 	 IF @EndTime Is Not Null SELECT @EndTime = dbo.fnServer_CmnConvertTime (@EndTime , @InTimeZone,'UTC') 
 	 SET @InTimeZone =  'UTC'
END
DECLARE
 	  	 @LineRows 	  	 int,
 	  	 @Row 	  	  	 int,
 	  	 @LineId 	  	  	 int,
 	  	 @OEECalcType 	 Int,
 	  	 @CapRates 	  	 tinyint
DECLARE @Lines TABLE  ( RowID int IDENTITY, 	 LineId int NULL,LineDesc nvarchar(50),OEEMode Int)
DECLARE @AllLines TABLE  ( RowID int IDENTITY, 	 LineId int NULL,LineDesc nvarchar(50),OEEMode Int)
DECLARE @UnitList 	 nvarchar(max)
DECLARE @RunTimes Table( StartTime datetime, EndTime datetime)
DECLARE @ProductionRateFactor Float
DECLARE @FactorUnits TABLE (PUId Int)
DECLARE @Productsummary TABLE
   (ProcessOrder nvarchar(100),CrewDesc nvarchar(50),ShiftDesc nvarchar(50),
 	 ProductCode nvarchar(50) null,
 	 ProdId 	 Int null,
 	 UnitDesc 	  	  	 nvarchar(100),
 	 UnitOrder 	  	  	 Int,
 	 ProductionAmount Float null,
 	 IdealProductionAmount Float null,
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
 	 StartTime 	 DateTime,
 	 EndTime 	  	 DateTime,
 	 LineStatus 	 Int,
 	 DeptId Int,
 	 LineId Int,
 	 UnitId Int,
 	 PathId Int,
 	 PathCode nVarChar(100)
 	  ,NPT Float Default 0
 	  ,DowntimeA Float Default 0
 	  ,DowntimeP Float Default 0
 	  ,DowntimeQ Float Default 0
 	  ,DowntimePL Float Default 0
 	  ,OEEMode Int default 0
)
--For Grouping New Table --
DECLARE @SummaryDataGrouped TABLE
   (
 	 ProductCode nvarchar(50) null,
 	 ProdId 	 Int null,
 	 ProductionAmount Float null,
 	 IdealProductionAmount Float null,
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
 	 GroupIdentifier nvarchar(50) null
 	 --StartTime 	 DateTime,
 	 --EndTime 	  	 DateTime,
 	 --LineStatus 	 Int,
 	 --DeptId Int,
 	 --LineId Int,
 	 --UnitId Int,
 	 --PathId Int
 	  ,NPT Float Default 0
 	  ,DowntimeA Float Default 0
 	  ,DowntimeP Float Default 0
 	  ,DowntimeQ Float Default 0
 	  ,DowntimePL Float Default 0
 	  ,OEEMode int Default 0
)
--For Grouping New Table --
DECLARE @DistinctProducts TABLE (
ProdId int null,
ProdDesc nvarchar(50) null,
ProductCode nvarchar(50) null )
DECLARE @Units Table (PUId 	 Int,OEEMode Int,UnitStatus Int)
DECLARE @Departments Table (DeptId 	 Int)
SELECT 	 @CapRates = dbo.fnCMN_OEERateIsCapped()
If (@EquipmentList is Not Null)
 	 Set @EquipmentList = REPLACE(@EquipmentList, ' ', '')
if ((@EquipmentList is Not Null) and (LEN(@EquipmentList) = 0))
 	 Set @EquipmentList = Null
if (@EquipmentList is not null)
BEGIN
 	 IF @EquipmentType = 3  -- Department
 	 BEGIN
 	  	 INSERT INTO @Departments(DeptId)
 	  	  	 SELECT Id from [dbo].[fnCmn_IdListToTable]('Departments',@EquipmentList,',')
 	  	 IF Not EXists(Select 1 FROM @Departments) -- Department Not Found
 	  	 BEGIN
 	  	  	 RETURN -999
 	  	 END
 	  	 INSERT INTO @Lines(LineId)
 	  	 SELECT PL_Id
 	  	 FROM Prod_Lines_Base a
 	  	 JOIN @Departments b on b.DeptId = a.Dept_Id
 	  	 SET @EquipmentList = ''
 	  	 SELECT @EquipmentList =  @EquipmentList + CONVERT(nvarchar(10),LineId) + ',' 
 	  	  	  	 FROM @Lines
 	  	 DELETE FROM @Lines  
 	  	 SET @EquipmentType = 2
 	 END
 	 IF @EquipmentType = 1  -- Units
 	 BEGIN
 	  	 INSERT INTO @Units(PUId,OEEMode)
 	  	  	 SELECT Id,0 from [dbo].[fnCmn_IdListToTable]('Prod_Units',@EquipmentList,',')
 	  	 IF Not EXists(Select 1 FROM @Units) -- Unit Not Found
 	  	 BEGIN
 	  	  	 RETURN -999
 	  	 END
 	 END
 	 IF @EquipmentType = 2 -- Lines
 	 BEGIN
 	  	 INSERT into @Lines (LineId)
 	  	  	 SELECT Id from [dbo].[fnCmn_IdListToTable]('Prod_Lines',@EquipmentList,',')
 	  	 IF Not EXists(Select 1 FROM @Lines) -- Line Not Found
 	  	 BEGIN
 	  	  	 RETURN -999
 	  	 END
 	 END
END
IF (@EquipmentList is null)
BEGIN
 	 IF @EquipmentType = 2
 	 BEGIN
 	  	 INSERT into @Lines (LineId)
 	  	  	 SELECT PL_Id
 	  	  	  	 FROM Prod_Lines
 	  	  	  	 WHERE PL_Id > 0
 	 END
END
IF @EquipmentType in (2) --Line OEE Only
BEGIN
 	 DELETE @Lines 
 	 FROM @Lines a
 	 JOIN Prod_Lines_Base b on a.LineId = b.PL_Id and b.LineOEEMode = 99
END
INSERT INTO @AllLines (LineId ,LineDesc,OEEMode)
 	 SELECT LineId ,LineDesc,OEEMode
 	 FROM @Lines 
 	 ORDER BY LineDesc
update a
 	 Set OEEMode = COALESCE(b.LineOEEMode,1),LineDesc = PL_Desc
 	 From @AllLines a
 	 JOIN Prod_Lines  b on b.PL_Id = a.LineId 
IF @EquipmentType = 2
 	 SELECT @LineRows = Count(*) from @AllLines
ELSE
 	 SET @LineRows = 1
Set @Row 	  	 = 	 0 	 
set @LineRows = 1
WHILE @Row <  @LineRows
BEGIN
 	 SELECT @Row = @Row + 1
 	 IF @EquipmentType = 2
 	 BEGIN
 	  	 DELETE FROM @Units
 	  	 SELECT @LineId = LineId,@OEECalcType = OEEMode FROM @AllLines WHERE ROWID = @Row
 	  	 
 	  	 INSERT INTO @Units(PUId,OEEMode)
 	  	  	 SELECT PU_Id,0
 	  	  	 FROM Prod_Units_Base
 	  	  	 WHERE pl_Id = @LineId
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @LineId = Min(PL_Id) 
 	  	  	 FROM Prod_Units_base a
 	  	  	 JOIN @Units b on b.PUId = a.PU_Id 
 	 END  
 	 IF @TimeSelection IN (1,2,3,4,5,6,7,8,9,10) 
 	  	 EXECUTE dbo.spBF_CalculateOEEReportTime @LineId,@TimeSelection ,@StartTime  Output, @EndTime Output
  	 update a
  	  Set OEEMode = coalesce(b.Value,1) 
  	  From @Units a
  	  left Join dbo.Table_Fields_Values  b on b.KeyId = a.PUId   AND b.Table_Field_Id = -91 AND B.TableId = 43
 	 update a
  	  Set UnitStatus = coalesce(b.TEDet_Id,0) 
  	  From @Units a
  	  Left Join Timed_Event_Details  b on b.PU_Id = a.PUId   AND b.End_Time is null
 	 update @Units  	  Set UnitStatus = 1 where UnitStatus > 0
 	 SELECT @UnitList = ''
 	 IF @EquipmentType = 1 -- Not Line OEE
 	 BEGIN
 	  	 SELECT @UnitList =  @UnitList + CONVERT(nvarchar(10),puId) + ',' 
 	  	  	  	 FROM @Units  
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @UnitList =  @UnitList + CONVERT(nvarchar(10),puId) + ',' 
 	  	  	  	 FROM @Units 
 	  	  	  	 WHERE OEEMode = @OEECalcType 
 	 END
 	 INSERT INTO @FactorUnits(PUId)
 	  	  	 SELECT Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
 	 
 	 SET @UnitList = @EquipmentList---Now onwards Preferred Unit list will be passed on...
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
 	  	  	  	 Pu.Pu_Id from Prod_Units Pu
 	  	  	 Where
 	  	  	  	 Not Exists (Select 1 From Table_Fields_Values Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	  	 AND Production_Rate_Specification IS NULL
 	  	 )
 	  	 SELECT 
 	  	  	 @UnitList = COALESCE(@UnitList + ',', '') + Cast(Au.Pu_ID as nvarchar)
 	  	 FROM 
 	  	  	 @ActiveUnits Au
 	  	  	 LEFT OUTER JOIN NotConfiguredUnits Nu ON Nu.PU_Id = Au.Pu_ID
 	  	 WHERE 
 	  	  	 Nu.PU_Id IS NULL 	 
 	 --<End: Logic to exclude Units>
 	 
 	 IF @EquipmentType = 1 -- all units OEE no sum
 	 BEGIN
 	  	 Insert Into @Productsummary (DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode,ProdId ,UnitDesc,UnitOrder,ProductionAmount,
 	  	  	  	 IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,
 	  	  	  	 QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,
 	  	  	  	 PercentOEE
 	  	  	  	 ,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL)
 	  	 EXECUTE spBF_OEEGetDataForProduct @UnitList, @StartTime,@EndTime,@InTimeZone ,@ReportType,0,@GroupBy,@FilterNonProductiveTime
 	  	  
 	  	 goto ReturnData
 	 END
 	 --IF @OEECalcType IN( 1,2,3) /* Parallel */
 	 --BEGIN
 	 -- 	 Insert Into @Productsummary(DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode,ProdId,UnitDesc,UnitOrder,ProductionAmount,
 	 -- 	  	  	 IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,
 	 -- 	  	  	 QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,
 	 -- 	  	  	 PercentOEE)
 	  	  	  	 
 	 -- 	 EXECUTE spBF_OEEGetDataForProduct @UnitList, @StartTime,@EndTime,@InTimeZone,@ReportType ,0,@GroupBy
 	  
 	 --END
 	 IF @EquipmentType <> 1 -- all units OEE no sum
 	 BEGIN
 	  	 Insert Into @Productsummary (DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode,ProdId ,UnitDesc,UnitOrder,ProductionAmount,
 	  	  	  	 IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,
 	  	  	  	 QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,
 	  	  	  	 PercentOEE,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL)
 	  	 EXECUTE spBF_OEEGetDataForProduct @UnitList, @StartTime,@EndTime,@InTimeZone ,@ReportType,1,@GroupBy,@FilterNonProductiveTime
 	  	  
 	  	 --goto ReturnData
 	 END
 	 --Not supported in this release /* Serial */
 	 /*IF @OEECalcType In (4,5) 
 	 BEGIN
 	  	 Insert Into @Productsummary(ProductCode,Prodid,UnitDesc,UnitOrder,ProductionAmount,
 	  	  	  	 IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,
 	  	  	  	 QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,
 	  	  	  	 PercentOEE)
 	  	 EXECUTE spBF_SerialLineOEE 	 @LineId,@StartTime,@EndTime,@FilterNonProductiveTime,@InTimeZone,@OEECalcType 
 	 END*/
LoopContinue:
END
ReturnData:
SELECT @ProductionRateFactor = Min(dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits))
 	 FROM Prod_Units a
 	 JOIN @FactorUnits b on b.puid= a.PU_Id
SELECT @ProductionRateFactor = COALESCE(@ProductionRateFactor,1)
IF @ProductionRateFactor < 1 SET @ProductionRateFactor = 1
UPDATE @Productsummary SET PerformanceRate = Coalesce(PerformanceRate,0),QualityRate = Coalesce(QualityRate,0),
 	  	 AvailableRate = Coalesce(AvailableRate,0)
UPDATE @Productsummary SET
 	  	  	 PerformanceRate = CASE WHEN PerformanceRate > 100 AND @CapRates = 1 THEN 100 ELSE PerformanceRate END
 	  	  	 --PerformanceRate
 	  	  	 , 
 	  	  	 QualityRate = CASE WHEN QualityRate > 100 AND @CapRates = 1 THEN 100 	 ELSE QualityRate END,
 	  	  	 AvailableRate = CASE WHEN AvailableRate > 100 AND @CapRates = 1 THEN 100 ELSE AvailableRate END,
 	  	  	 IdealSpeed = IdealSpeed * @ProductionRateFactor /60,
 	  	  	 ActualSpeed = ActualSpeed * @ProductionRateFactor /60
 	  	  	 
UPDATE @Productsummary SET PercentOEE = PerformanceRate * QualityRate * AvailableRate / 10000
---<New Code>--------------
 	  	 UPDATE @Productsummary 
 	  	 SET  NPT= ISNULL(NPT,0), DowntimeA = ISNULL(DowntimeA,0), DowntimeP = ISNULL(DowntimeP,0), DowntimeQ = ISNULL(DowntimeQ,0), DowntimePL = ISNULL(DowntimePL,0)
 	  	 Delete From @DistinctProducts
 	  	 INSERT INTO @DistinctProducts (ProdId) SELECT DISTINCT (ProdId) FROM @Productsummary
 	  	 Insert into @SummaryDataGrouped
 	  	 (ProductCode,ProdId,ProductionAmount,IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,PercentOEE,GroupIdentifier
 	  	 ,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL)
 	  	 select 
 	  	  	  	 ProductCode , ProdId , isnull(Sum(ProductionAmount),0) ,isnull( Sum (IdealProductionAmount),0) , 
 	  	  	  	 CASE when sum(Runtime) != 0 then sum (ProductionAmount) / sum(Runtime) else 0 END ,CASE when sum(Runtime) != 0 then sum (IdealProductionAmount) / sum(Runtime) else 0 END ,
 	  	  	  	 dbo.fnGEPSPerformance(sum(ProductionAmount), sum(IdealProductionAmount), @CapRates) , 
 	  	  	  	 sum(WasteAmount),dbo.fnGEPSQuality(sum(ProductionAmount), sum(WasteAmount), @CapRates),
 	  	  	  	 sum(PerformanceTime) , sum(RunTime) , sum (LoadingTime) ,
 	  	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTime)+sum(PerformanceTime), @CapRates),
 	  	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTime)+sum(PerformanceTime), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionAmount), sum(IdealProductionAmount), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionAmount), sum(WasteAmount), @CapRates) / 100 * 100 ,
 	  	  	  	 CASE WHEN @GroupBy = 1 THEN '' WHEN @GroupBy = 2 THEN ShiftDesc WHEN @GroupBy = 3 THEN CrewDesc  WHEN @GroupBy = 4 THEN PathCode End
 	  	  	  	 ,SUM(NPT),SUM(DowntimeA),SUM(DowntimeP),SUM(DowntimeQ),SUM(DowntimePL)
 	  	 From @Productsummary 
 	  	 Where 
 	  	  	 ProductCode not like '%total%'
 	  	 group by 
 	  	  	 ProdId,ProductCode, CASE WHEN @GroupBy = 1 THEN '' WHEN @GroupBy = 2 THEN ShiftDesc WHEN @GroupBy = 3 THEN CrewDesc  WHEN @GroupBy = 4 THEN PathCode End
 	  	  	  	 
---</New Code>--------------
declare @RecordCount int 
select @RecordCount = count(*) from @SummaryDataGrouped 
if @RecordCount > 0 
Begin
 	 insert into @SummaryDataGrouped ( 	 ProductCode , 	  	 ProductionAmount  , 	 IdealProductionAmount  , 	 ActualSpeed  ,
 	 IdealSpeed  ,  	 PerformanceRate  , 	 WasteAmount  ,  	 QualityRate  , 	 PerformanceTime  , 	 RunTime  , 	 LoadingTime  , 	 AvailableRate  , 	 PercentOEE ,GroupIdentifier 
 	 ,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL
)
select 'Total' , Sum(ProductionAmount) , Sum (IdealProductionAmount) , CASE when sum(Runtime) != 0 then sum (ProductionAmount) / sum(Runtime) else 0 END ,CASE when sum(Runtime) != 0 then sum (IdealProductionAmount) / sum(Runtime) else 0 END ,
dbo.fnGEPSPerformance(sum(ProductionAmount)+sum(wasteAmount), sum(IdealProductionAmount), @CapRates) , sum(WasteAmount),dbo.fnGEPSQuality(sum(ProductionAmount)+sum(wasteamount), sum(WasteAmount), @CapRates),
sum(PerformanceTime) , sum(RunTime) , sum (LoadingTime) , 
 	  	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTime)+sum(PerformanceTime), @CapRates),
 	  	  	  	 dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTime)+sum(PerformanceTime), @CapRates) / 100 	  	  	 
 	  	  	 * dbo.fnGEPSPerformance(sum(ProductionAmount)+sum(wasteamount), sum(IdealProductionAmount), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionAmount)+sum(wasteamount), sum(WasteAmount), @CapRates) / 100 * 100 --END
 	  	  	  	 , GroupIdentifier
 	  	  	  	 ,SUM(NPT),SUM(DowntimeA),SUM(DowntimeP),SUM(DowntimeQ),SUM(DowntimePL)
 	  	  	 From @SummaryDataGrouped group by GroupIdentifier
 	  	  	 
end 
UPDATE A
  	  SET 
  	    	  A.DownTimeA = LoadingTime - (RunTime +Isnull(PerformanceTime,0)),
  	    	  A.DownTimeP = Case when NOT (IdealProductionAmount > 0 AND ProductionAmount+WasteAmount > 0) Then 0 Else ((RunTime+Isnull(PerformanceTime,0))*(IdealProductionAmount)-(RunTime+Isnull(PerformanceTime,0))*(ProductionAmount+WasteAmount))/(IdealProductionAmount) end,
  	    	  A.DownTimeQ = Case when NOT ((IdealProductionAmount) > 0 AND (ProductionAmount+WasteAmount) > 0 ) Then 0 Else (((RunTime+Isnull(PerformanceTime,0))*(ProductionAmount+WasteAmount))-((RunTime+Isnull(PerformanceTime,0))*(ProductionAmount)))/(IdealProductionAmount) end
  	  From @Productsummary A 
  	  
  	  UPDATE A
  	  SET 
  	    	  A.DownTimeA = LoadingTime - (RunTime +Isnull(PerformanceTime,0)),A.DownTimeP = Case when NOT (IdealProductionAmount > 0 AND ProductionAmount+WasteAmount > 0) Then 0 Else ((RunTime+Isnull(PerformanceTime,0))*(IdealProductionAmount)-(RunTime+Isnull(PerformanceTime,0))*(ProductionAmount+WasteAmount))/(IdealProductionAmount) end,
  	    	  A.DownTimeQ = Case when NOT ((IdealProductionAmount) > 0 AND (ProductionAmount+WasteAmount) > 0 ) Then 0 Else (((RunTime+Isnull(PerformanceTime,0))*(ProductionAmount+WasteAmount))-((RunTime+Isnull(PerformanceTime,0))*(ProductionAmount)))/(IdealProductionAmount) end
  	  From @Productsummary A 
  	   UPDATE A 
  	  SET  	    	  
  	    	  A.DownTimeP = LoadingTime -DownTimePL - DownTimeA
  	  From @Productsummary  A
  	  Where 
  	  1=1
  	  And (ProductionAmount+WasteAmount)<=0 
UPDATE A
  	  SET 
  	    	  A.DownTimeA = LoadingTime - (RunTime +Isnull(PerformanceTime,0)),
  	    	  A.DownTimeP = Case when NOT (IdealProductionAmount > 0 AND ProductionAmount+WasteAmount > 0) Then 0 Else ((RunTime+Isnull(PerformanceTime,0))*(IdealProductionAmount)-(RunTime+Isnull(PerformanceTime,0))*(ProductionAmount+WasteAmount))/(IdealProductionAmount) end,
  	    	  A.DownTimeQ = Case when NOT ((IdealProductionAmount) > 0 AND (ProductionAmount+WasteAmount) > 0 ) Then 0 Else (((RunTime+Isnull(PerformanceTime,0))*(ProductionAmount+WasteAmount))-((RunTime+Isnull(PerformanceTime,0))*(ProductionAmount)))/(IdealProductionAmount) end
  	  From @SummaryDataGrouped A 
  	  
  	  UPDATE A
  	  SET 
  	    	  A.DownTimeA = LoadingTime - (RunTime +Isnull(PerformanceTime,0)),A.DownTimeP = Case when NOT (IdealProductionAmount > 0 AND ProductionAmount+WasteAmount > 0) Then 0 Else ((RunTime+Isnull(PerformanceTime,0))*(IdealProductionAmount)-(RunTime+Isnull(PerformanceTime,0))*(ProductionAmount+WasteAmount))/(IdealProductionAmount) end,
  	    	  A.DownTimeQ = Case when NOT ((IdealProductionAmount) > 0 AND (ProductionAmount+WasteAmount) > 0 ) Then 0 Else (((RunTime+Isnull(PerformanceTime,0))*(ProductionAmount+WasteAmount))-((RunTime+Isnull(PerformanceTime,0))*(ProductionAmount)))/(IdealProductionAmount) end
  	  From @SummaryDataGrouped A 
  	   UPDATE A 
  	  SET  	    	  
  	    	  A.DownTimeP = LoadingTime -DownTimePL - DownTimeA
  	  From @SummaryDataGrouped  A
  	  Where 
  	  1=1
  	  And (ProductionAmount+WasteAmount)<=0
--<New Code>---
 	  	 
 	  	 --<CLASSIC OEE CALCULATION>----
 	  	 UPDATE @SummaryDataGrouped
 	  	 SET
 	  	  	 PerformanceRate =dbo.fnGEPSPerformance(ProductionAmount+WasteAmount, IdealProductionAmount, @CapRates),
 	  	  	 QualityRate=dbo.fnGEPSQuality(ProductionAmount+wasteamount, WasteAmount, @CapRates),
 	  	  	 AvailableRate=dbo.fnGEPSAvailability(LoadingTime,(RunTime+PerformanceTime), @CapRates)  
 	  	 UPDATE @Productsummary
 	  	 SET
 	  	  	 PerformanceRate =dbo.fnGEPSPerformance(ProductionAmount+WasteAmount, IdealProductionAmount, @CapRates),
 	  	  	 QualityRate=dbo.fnGEPSQuality(ProductionAmount+wasteamount, WasteAmount, @CapRates),
 	  	  	 AvailableRate=dbo.fnGEPSAvailability(LoadingTime,(RunTime+PerformanceTime), @CapRates)  
 	  	 
 	  	 --</CLASSIC OEE CALCULATION>----
 	  	 
 	  	  
 	  	 --<TIME BASE OEE CALCULATION>---
 	  	 
 	  	 UPDATE  A
 	  	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100,
 	  	  	 OEEMode = 4 --4 is for time based
 	  	 From @ProductSummary A
 	  	  
 	  	 UPDATE A 
 	  	 SET 
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100,
 	  	  	 OEEMode = 4 --4 is for time based
 	  	 From
 	  	  	 @SummaryDataGrouped A 
 	  	 Where
 	  	  	 --Exists (Select 1 From @TimedProducts Where Prod_Id = A.ProdId)
 	  	  	 1=1
 	  	  	 AND ProductCode <> 'Total'
 	  	 
 	  	 UPDATE A 
 	  	 SET 
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100,
 	  	  	 OEEMode = 4 --4 is for time based
 	  	 From
 	  	  	 @SummaryDataGrouped A 
 	  	 Where
 	  	 -- 	 Exists (Select case when count(0) = Count(distinct Prod_Id) then 1 else 0 end from @TimedProducts)
 	  	 -- 	 AND Exists (Select 1 from @TimedProducts)
 	  	 1=1
 	  	  	 AND ProductCode = 'Total'
-- Defect DE104587 Capping of -ve values to 0
 	  	  UPDATE @SummaryDataGrouped 
 	  	  	 SET
 	  	  	  	 AvailableRate = CASE WHEN AvailableRate < 0 THEN 0 ELSE AvailableRate END,
 	  	  	  	 PerformanceRate = CASE WHEN PerformanceRate < 0 THEN 0 ELSE PerformanceRate END,
 	  	  	  	 QualityRate = CASE WHEN QualityRate < 0 THEN 0 ELSE QualityRate END
 	  	 UPDATE @Productsummary 
 	  	  	 SET
 	  	  	  	 AvailableRate = CASE WHEN AvailableRate < 0 THEN 0 ELSE AvailableRate END,
 	  	  	  	 PerformanceRate = CASE WHEN PerformanceRate < 0 THEN 0 ELSE PerformanceRate END,
 	  	  	  	 QualityRate = CASE WHEN QualityRate < 0 THEN 0 ELSE QualityRate END
 	  	 
 	  	  UPDATE @SummaryDataGrouped 
 	  	  	 SET
 	  	  	  	 AvailableRate = CASE WHEN AvailableRate > 100 and @CapRates = 1 THEN 100 ELSE AvailableRate END,
 	  	  	  	 PerformanceRate = CASE WHEN PerformanceRate > 100  and @CapRates = 1 THEN 100 ELSE PerformanceRate END,
 	  	  	  	 QualityRate = CASE WHEN QualityRate > 100 and @CapRates = 1 THEN 100 ELSE QualityRate END
 	  	 UPDATE @Productsummary 
 	  	  	 SET
 	  	  	  	 AvailableRate = CASE WHEN AvailableRate > 100 and @CapRates = 1 THEN 100 ELSE AvailableRate END,
 	  	  	  	 PerformanceRate = CASE WHEN PerformanceRate > 100 and @CapRates = 1 THEN 100 ELSE PerformanceRate END,
 	  	  	  	 QualityRate = CASE WHEN QualityRate > 100 and @CapRates = 1 THEN 100 ELSE QualityRate END
 	  	 
 	  	 -- 	 UPDATE @Productsummary 
 	  	 --set 
 	  	 -- 	 PerformanceRate =  case  when ProductionAmount+WasteAmount <=0 then 0 else PerformanceRate end,
 	  	 -- 	 QualityRate =  case  when ProductionAmount+WasteAmount <=0 then 0 else QualityRate end
 	  	 --UPDATE @SummaryDataGrouped 
 	  	 --set 
 	  	 -- 	 PerformanceRate =  case  when ProductionAmount+WasteAmount <=0 then 0 else PerformanceRate end,
 	  	 -- 	 QualityRate =  case  when ProductionAmount+WasteAmount <=0 then 0 else QualityRate end
 	  	 
 	  	 
 	  	  	 --Product level oee mode finding and applying 
 	  	 --</TIME BASE OEE CALCULATION>---
 	  	 UPDATE @SummaryDataGrouped SET PercentOEE = ( (PerformanceRate/100)*(QualityRate/100)*(AvailableRate/100)) *100
 	  	 UPDATE @Productsummary SET PercentOEE = PerformanceRate * QualityRate * AvailableRate / 10000
--</New Code>---
--if @ReturnTotalRow =1  and datediff mroe than 7 return only total  row
IF    @ReturnTotalRowOnly =  1 and  DateDiff(Day,@StartTime,@EndTime) > 7
BEGIN
  	  Select   	  
  	    	  ProductCode,ProdId,ProductionAmount,IdealProductionAmount,
 	  	  --ActualSpeed,IdealSpeed,
 	  	  ActualSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), ProductionAmount+WasteAmount, @ProductionRateFactor)
 	  	 ,IdealSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), IdealProductionAmount, @ProductionRateFactor),
 	  	  PerformanceRate = CASE WHEN PerformanceRate < 0  THEN 0 ELSE PerformanceRate END
 	  	  ,WasteAmount
 	  	  ,QualityRate = CASE WHEN QualityRate < 0  THEN 0 ELSE QualityRate END
 	  	  ,PerformanceTime,RunTime,LoadingTime
 	  	  ,AvailableRate = CASE WHEN AvailableRate < 0  THEN 0 ELSE AvailableRate END
 	  	  ,PercentOEE = CASE WHEN PercentOEE < 0  THEN 0 ELSE PercentOEE END
 	  	  ,GroupIdentifier
  	    	  ,OEEMode
  	  from @SummaryDataGrouped Where ProductCode = 'Total'
END
ELSE
BEGIN
  	  Select   	  
  	    	  ProductCode,ProdId,ProductionAmount,IdealProductionAmount,
 	  	  --ActualSpeed,IdealSpeed
 	  	  ActualSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), ProductionAmount+WasteAmount, @ProductionRateFactor)
 	  	 ,IdealSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), IdealProductionAmount, @ProductionRateFactor)
 	  	  ,PerformanceRate = CASE WHEN PerformanceRate < 0  THEN 0 ELSE PerformanceRate END
 	  	  ,WasteAmount
 	  	  ,QualityRate = CASE WHEN QualityRate < 0  THEN 0 ELSE QualityRate END
 	  	  ,PerformanceTime,RunTime,LoadingTime
 	  	  ,AvailableRate = CASE WHEN AvailableRate < 0  THEN 0 ELSE AvailableRate END
 	  	  ,PercentOEE = CASE WHEN PercentOEE < 0  THEN 0 ELSE PercentOEE END
 	  	  ,GroupIdentifier
  	    	  ,OEEMode
  	  from @SummaryDataGrouped
END
  	   select distinct  GroupIdentifier from  @SummaryDataGrouped
  	  
  	  SELECT  	  DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode, ProdId , UnitDesc, UnitOrder , s.ProductionAmount, s.IdealProductionAmount,
  	    	  s.ActualSpeed, s.IdealSpeed,
 	  	  ActualSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), ProductionAmount+WasteAmount, @ProductionRateFactor)
 	  	 ,IdealSpeed = dbo.fnGEPSActualSpeed(RunTime +Isnull(PerformanceTime,0), IdealProductionAmount, @ProductionRateFactor)
  	    	 ,PerformanceRate =  CASE WHEN  s.PerformanceRate < 0  THEN 0 --ELSE  s.PerformanceRate END
  	    	  --CASE
 	  	   WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
  	    	    	  ELSE s.PerformanceRate END
  	    	   
  	    	 ,s.WasteAmount
  	    	 ,QualityRate = CASE WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100 
 	  	  	  	  	  	  	 WHEN s.QualityRate < 0  THEN 0
  	    	    	    	    	    	  ELSE s.QualityRate END,
  	    	  s.PerformanceTime, s.RunTime, s.LoadingTime, 
  	    	  AvailableRate = CASE WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	  	   WHEN s.AvailableRate < 0  THEN 0
  	    	    	    	    	    	  ELSE s.AvailableRate END, 
  	    	  PercentOEE = CASE WHEN s.PercentOEE < 0  THEN 0 --ELSE s.PercentOEE END
  	    	    	    	    	  --CASE 
 	  	  	  	  	  WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100 
  	    	    	    	    	  ELSE s.PercentOEE END
  	    	    	    	    	  
,OEEMode
 	 FROM @Productsummary s
 	 --<Change - Prasad 2018-01-05>
 	 where s.ProductCode<> 'Total'
 	 --</Change - Prasad 2018-01-05>
 	 ORDER BY DeptId,LineId,UnitId,PathId,UnitOrder , PercentOEE
