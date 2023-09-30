--
/*  
 execute spBF_GetOrderOEEData  '10,4',  '11/13/2016','11/15/2016',  0,  null,  1, 1  -- Unit
 execute spBF_GetOrderOEEData  '3',  '11/13/2016','11/15/2016',  0,  null,  2, 1  -- Line
 execute spBF_GetOrderOEEData  '2',  '11/13/2016','11/15/2016',  0,  null,  3, 1  -- department
 execute spBF_GetOrderOEEData  '10,4',  '11/13/2016','11/15/2016',  0,  null,  1, 2  -- Unit
 execute spBF_GetOrderOEEData  '3',  '11/13/2016','11/15/2016',  0,  null,  2, 2  -- Line
 execute spBF_GetOrderOEEData  '2',  '11/13/2016','11/15/2016',  0,  null,  3, 2  -- department
 execute spBF_GetOrderOEEData  '10,4',  '11/13/2016','11/15/2016',  0,  null,  1, 3  -- Unit
 execute spBF_GetOrderOEEData  '3',  '11/13/2016','11/15/2016',  0,  null,  2, 3  -- Line
 execute spBF_GetOrderOEEData  '2',  '11/13/2016','11/15/2016',  0,  null,  3, 3  -- department
 execute spBF_GetOrderOEEData  '10,4',  '11/13/2016','11/15/2016',  0,  null,  1, 4  -- Unit
 execute spBF_GetOrderOEEData  '3',  '11/13/2016','11/15/2016',  0,  null,  2, 4  -- Line
 execute spBF_GetOrderOEEData  '2',  '11/13/2016','11/15/2016',  0,  null,  3, 4  -- department
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
CREATE PROCEDURE [dbo].[spBF_GetOrderOEEData_Bak_177]
@EquipmentList           nvarchar(max), 	  	  	  	 -- Required (Null returns all Lines)
@StartTime               datetime = NULL, 	  	  	 -- Used When @TimeSelection = 0 (user Defined time)
@EndTime                 datetime = NULL, 	  	  	 -- Used When @TimeSelection = 0 (user Defined time)
@TimeSelection 	  	  	  Int = 0, 	  	  	  	  	 
@InTimeZone 	              nVarChar(200) = null, 	  	 -- timeZone to return data in (defaults to department if not supplied)
@EquipmentType 	  	  	  Int = 0, 	  -- 1 Unit,2 Line,3 Department 	  	  	  	 
@ReportType 	  	  	  	  Int = 1,  --1-Products,2-Shift,3-Crew,4-Orders
@GroupBy 	  	  	  	  Int = 1,  --1-None, 2 - Shift , 3 - Crew , 4 - Path
@ReturnTotalRowOnly 	  	 Int =0
,@FilterNonProductiveTime Int = 0
AS
/* ##### spBF_GetOrderOEEData #####
Description 	 : Returns data for Orders in the reports screen w.r.t. the selection made
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Added logic to fetch NPT, DowntimeA, DowntimeP, DowntimeQ, Downtime PL and toggle calculation based on OEE calculation type (Classic or Time Based)
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
2018-05-30 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Exclude Units for which Production event is Inactive
2018-06-07 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Changed logic of excluding Units [Production rate specification is not defined and Oee mode not set]
2018-06-20 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE77740 	  	  	  	  	 Removed cap for PerformanceRate and PercentOEE
2018-06-26 	  	  	 Prasad 	  	  	  	 7.0 SP4 DE80574 	  	  	  	  	 Divide by zero error occurred for case when Loadtime = 0 and productionamount > 0  	 
2018-08-21 	  	  	 Prasad 	  	  	  	 7.0 SP4 CASE 593732 	  	  	  	 Removed check of <= 7 days for showing data w.r.t. individual orders
*/
set nocount on
Declare @low Int = 50
Declare @Moderate Int = 85
Declare @Good Int = 60
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @NewPageNum INt
SET @EquipmentType = 1
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
 	 ,OEEMode int
)
-- New Table - 24/11/16
DECLARE @SummaryDataGrouped TABLE
   (
 	 OrderCode nvarchar(50) null,
 	 --ProdId 	 Int null,
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
 	 ,OEEMode int
)
-- New Table - 24/11/16
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
 	 ----<Get Preferred Units as per myMachine configuration>
 	 --DECLARE @ouputTable Table (PU_Id Int , PU_Desc nVarChar(max), PL_Id Int, PL_Desc nVarChar(max), Dept_Id Int, Dept_Desc nVarChar(max),  ET_Id Int , ET_Desc nvarchar(1000),Is_Slave int)
 	 --Insert Into @ouputTable(Dept_Id,Dept_Desc,PL_Id,PL_Desc,PU_Id, PU_Desc,ET_Id, ET_Desc,Is_Slave)
 	 --Exec spBF_APIMyMachines_APIGetMyMachines @UserId
 	 --Delete from @units where puId not in (select Pu_Id from @ouputTable)
 	 ----</Get Preferred Units as per myMachine configuration>
 	 IF @EquipmentType = 1 -- Not Line OEE
 	 BEGIN
 	  	 SELECT @UnitList =  @UnitList + CONVERT(nvarchar(10),puId) + ',' 
 	  	  	  	 FROM @Units  
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @UnitList =  @UnitList + CONVERT(nvarchar(10),puId) + ',' 
 	  	  	  	 FROM @Units 
 	  	  	  	 --WHERE OEEMode = @OEECalcType --To list all the units
 	 END
 	 SET @UnitList = @EquipmentList
 	 --<Start: Logic to exclude Units>
 	 DECLARE @xml XML
 	 DECLARE @ActiveUnits TABLE(Pu_ID int)
 	 SET @xml = cast(('<X>'+replace(@UnitList,',','</X><X>')+'</X>') as xml)
 	 INSERT INTO @ActiveUnits(Pu_ID)
 	 SELECT N.value('.', 'int') FROM @xml.nodes('X') AS T(N)
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
 	  	 Insert Into @Productsummary (DeptId,LineId,UnitId,PathId,PathCode,
 	  	  	  	  	  	  	  	  	 ProcessOrder,CrewDesc,ShiftDesc,ProductCode,ProdId ,
 	  	  	  	  	  	  	  	  	 UnitDesc,UnitOrder,ProductionAmount,IdealProductionAmount,ActualSpeed,
 	  	  	  	  	  	  	  	  	 IdealSpeed,PerformanceRate,WasteAmount, 	 QualityRate,PerformanceTime,
 	  	  	  	  	  	  	  	  	 RunTime,LoadingTime,AvailableRate,PercentOEE
 	  	  	  	  	  	  	  	  	 ,NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL)
 	  	 EXECUTE spBF_OEEGetDataForOrders @UnitList, @StartTime,@EndTime,@InTimeZone ,@ReportType,1,@FilterNonProductiveTime
 	  	 goto ReturnData
 	 END
 	 IF @OEECalcType IN( 1,2,3) /* Parallel */
 	 BEGIN
 	  	 Insert Into @Productsummary(DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode,ProdId,UnitDesc,UnitOrder,ProductionAmount,
 	  	  	  	 IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,
 	  	  	  	 QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,
 	  	  	  	 PercentOEE
 	  	  	  	 ,NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL)
 	  	  	  	 
 	  	 EXECUTE spBF_OEEGetDataForOrders @UnitList, @StartTime,@EndTime,@InTimeZone,@ReportType ,1,@FilterNonProductiveTime
 	 END
 	 /*Serial  - not supported
 	 IF @OEECalcType In (4,5) 
 	  	 BEGIN
 	  	 --not supoorted in this release 
 	  	 Insert Into @Productsummary(DeptId,LineId,UnitId,PathId,PathCode,ProcessOrder,CrewDesc,ShiftDesc,ProductCode,ProdId,UnitDesc,UnitOrder,//ProductionAmount,
 	  	  	  	 IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,
 	  	  	  	 QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,
 	  	  	  	 PercentOEE)
 	  	 --EXECUTE spBF_SerialLineOEE 	 @LineId,@StartTime,@EndTime,@FilterNonProductiveTime,@InTimeZone,@OEECalcType
 	  	 EXECUTE spBF_OEEGetDataForOrders_SerialLine 	 @LineId,@StartTime,@EndTime,@InTimeZone,@ReportType ,1
 	 END
 	 */
LoopContinue:
END
ReturnData:
UPDATE @Productsummary SET PerformanceRate = Coalesce(PerformanceRate,0),QualityRate = Coalesce(QualityRate,0),
 	  	 AvailableRate = Coalesce(AvailableRate,0)
UPDATE @Productsummary SET PercentOEE = PerformanceRate * QualityRate * AvailableRate / 10000
INSERT INTO @DistinctProducts (ProdId) SELECT DISTINCT (ProdId) FROM @Productsummary
insert into @SummaryDataGrouped (OrderCode , 	  	 ProductionAmount  , 	 IdealProductionAmount  , 	 ActualSpeed  ,
 	 IdealSpeed  ,  	 PerformanceRate  , 	 WasteAmount  ,  	 QualityRate  , 	 PerformanceTime  , 	 RunTime  , 	 LoadingTime  , 	 AvailableRate  , 	 PercentOEE , GroupIdentifier 
 	 ,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL
)
select ProcessOrder ,  isnull(Sum(ProductionAmount),0) ,isnull( Sum (IdealProductionAmount),0) , CASE when sum(Runtime) != 0 then sum (ProductionAmount) / sum(Runtime) else 0 END ,CASE when sum(Runtime) != 0 then sum (IdealProductionAmount) / sum(Runtime) else 0 END ,
dbo.fnGEPSPerformance(sum(ProductionAmount), sum(IdealProductionAmount), @CapRates) , sum(WasteAmount),dbo.fnGEPSQuality(sum(ProductionAmount), sum(WasteAmount), @CapRates),
sum(PerformanceTime) , sum(RunTime) , sum (LoadingTime) , dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTime)+sum(PerformanceTime), @CapRates),
dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTime)+sum(PerformanceTime), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionAmount), sum(IdealProductionAmount), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionAmount), sum(WasteAmount), @CapRates) / 100 * 100  , 
 	  	  	  	 Case When @GroupBy = 1 then '' When @GroupBy = 2 then ShiftDesc When @GroupBy = 3 then CrewDesc When @GroupBy = 4 then PathCode end 
 	  	  	  	 ,SUM(NPT),SUM(DowntimeA),SUM(DowntimeP),SUM(DowntimeQ),SUM(DowntimePL)  
 	  	  	 From @Productsummary 
 	  	  	 Where ProductCode not like '%total%'
 	  	  	 group by ProcessOrder , Case When @GroupBy = 1 then '' When @GroupBy = 2 then ShiftDesc When @GroupBy = 3 then CrewDesc When @GroupBy = 4 then PathCode end  
 	  	 
--- Adding Total Row in the Grouped Summary Table 
declare @RecordCount int 
select @RecordCount = count(*) from @SummaryDataGrouped 
if @RecordCount > 0 
Begin
 	 insert into @SummaryDataGrouped ( 	 OrderCode  , 	  	 ProductionAmount  , 	 IdealProductionAmount  , 	 ActualSpeed  ,
 	 IdealSpeed  ,  	 PerformanceRate  , 	 WasteAmount  ,  	 QualityRate  , 	 PerformanceTime  , 	 RunTime  , 	 LoadingTime  , 	 AvailableRate  , 	 PercentOEE ,GroupIdentifier 
 	 ,NPT,DowntimeA,DowntimeP,DowntimeQ,DowntimePL
)
select 'Total' , Sum(ProductionAmount) , Sum (IdealProductionAmount) , CASE when sum(Runtime) != 0 then sum (ProductionAmount) / sum(Runtime) else 0 END ,CASE when sum(Runtime) != 0 then sum (IdealProductionAmount) / sum(Runtime) else 0 END ,
dbo.fnGEPSPerformance(sum(ProductionAmount), sum(IdealProductionAmount), @CapRates) , sum(WasteAmount),dbo.fnGEPSQuality(sum(ProductionAmount), sum(WasteAmount), @CapRates),
sum(PerformanceTime) , sum(RunTime) , sum (LoadingTime) , dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTime)+sum(PerformanceTime), @CapRates),
dbo.fnGEPSAvailability(sum(LoadingTime), sum(RunTime)+sum(PerformanceTime), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSPerformance(sum(ProductionAmount), sum(IdealProductionAmount), @CapRates) / 100
 	  	  	  	 * dbo.fnGEPSQuality(sum(ProductionAmount), sum(WasteAmount), @CapRates) / 100 * 100 , GroupIdentifier
 	  	  	  	 ,SUM(NPT),SUM(DowntimeA),SUM(DowntimeP),SUM(DowntimeQ),SUM(DowntimePL)
 	  	  	 From @SummaryDataGrouped group by GroupIdentifier
 	 
end 
 	  	 --<CLASSIC OEE CALCULATION>----
 	  	 --UPDATE @SummaryDataGrouped
 	  	 --SET
 	  	 -- 	 PerformanceRate =dbo.fnGEPSPerformance(ProductionAmount+WasteAmount, IdealProductionAmount, @CapRates),
 	  	 -- 	 QualityRate=dbo.fnGEPSQuality(ProductionAmount+wasteamount, WasteAmount, @CapRates),
 	  	 -- 	 AvailableRate=dbo.fnGEPSAvailability(LoadingTime,(RunTime+PerformanceTime), @CapRates)  
 	  	 --UPDATE @Productsummary
 	  	 --SET
 	  	 -- 	 PerformanceRate =dbo.fnGEPSPerformance(ProductionAmount+WasteAmount, IdealProductionAmount, @CapRates),
 	  	 -- 	 QualityRate=dbo.fnGEPSQuality(ProductionAmount+wasteamount, WasteAmount, @CapRates),
 	  	 -- 	 AvailableRate=dbo.fnGEPSAvailability(LoadingTime,(RunTime+PerformanceTime), @CapRates)  
 	  	 
 	  	 --</CLASSIC OEE CALCULATION>---- 	  	  
 	  	 --<TIME BASE OEE CALCULATION>---
 	  	 UPDATE  A
 	  	 SET
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100,
 	  	  	 OEEMode = 4
 	  	 From @ProductSummary A
 	  	 
 	  	 UPDATE A 
 	  	 SET 
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100,
 	  	  	 OEEMode = 4
 	  	 From
 	  	  	 @SummaryDataGrouped A 
 	  	 Where
 	  	  	 --Exists (Select 1 From @TimedOrders Where pp_id = A.OrderCode)
 	  	  	 1=1
 	  	  	 AND OrderCode <> 'Total'
 	  	 UPDATE A 
 	  	 SET 
 	  	  	 AvailableRate = CASE WHEN (LoadingTime  - DowntimePL) <= 0 THEN 0 ELSE (Cast(LoadingTime  - DowntimePL - DowntimeA as float)/cast(LoadingTime  - DowntimePL as float)) END *100,
 	  	  	 PerformanceRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float)/cast(LoadingTime  - DowntimePL - DowntimeA as float)) END*100,
 	  	  	 QualityRate = CASE WHEN (LoadingTime  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(LoadingTime  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100,
 	  	  	 OEEMode = 4
 	  	 From
 	  	  	 @SummaryDataGrouped A 
 	  	 Where
 	  	  	 --Exists (Select case when count(0) = Count(distinct pp_id) then 1 else 0 end from @TimedOrders)
 	  	  	 1=1
 	  	  	 AND OrderCode = 'Total'
 	  	 --UPDATE @Productsummary 
 	  	 --set 
 	  	 -- 	 PerformanceRate =  case  when ProductionAmount+WasteAmount <=0 then 0 else PerformanceRate end,
 	  	 -- 	 QualityRate =  case  when ProductionAmount+WasteAmount <=0 then 0 else QualityRate end
 	  	 --UPDATE @SummaryDataGrouped 
 	  	 --set 
 	  	 -- 	 PerformanceRate =  case  when ProductionAmount+WasteAmount <=0 then 0 else PerformanceRate end,
 	  	 -- 	 QualityRate =  case  when ProductionAmount+WasteAmount <=0 then 0 else QualityRate end
 	  	 UPDATE @SummaryDataGrouped
 	  	 SET 	 
 	  	  	 AvailableRate= CASE WHEN AvailableRate > 100 AND @CapRates = 1 THEN 100 ELSE AvailableRate END,
 	  	  	 PerformanceRate= CASE WHEN PerformanceRate > 100 AND @CapRates = 1 THEN 100 ELSE PerformanceRate END,
 	  	  	 QualityRate= CASE WHEN QualityRate > 100 AND @CapRates = 1 THEN 100 ELSE QualityRate END
 	  	 UPDATE @Productsummary
 	  	 SET 	 
 	  	  	 AvailableRate= CASE WHEN AvailableRate > 100 AND @CapRates = 1 THEN 100 ELSE AvailableRate END,
 	  	  	 PerformanceRate= CASE WHEN PerformanceRate > 100 AND @CapRates = 1 THEN 100 ELSE PerformanceRate END,
 	  	  	 QualityRate= CASE WHEN QualityRate > 100 AND @CapRates = 1 THEN 100 ELSE QualityRate END
 	  	 UPDATE @SummaryDataGrouped SET PercentOEE = ( (PerformanceRate/100)*(QualityRate/100)*(AvailableRate/100)) *100
 	  	 UPDATE @Productsummary SET PercentOEE = PerformanceRate * QualityRate * AvailableRate / 10000
 	  	 --</TIME BASE OEE CALCULATION>---
--<Change - Prasad 2018-01-05>
 	 Select  	 
 	  	 IsNull(OrderCode,'Unspecified') OrderCode,ProductionAmount,IdealProductionAmount,ActualSpeed,IdealSpeed,PerformanceRate,WasteAmount,QualityRate,PerformanceTime,RunTime,LoadingTime,AvailableRate,PercentOEE,GroupIdentifier
 	  	 ,OEEMode,
 	  	 DowntimeA,DowntimeP,DowntimeQ
 	 from @SummaryDataGrouped
 	 
 	 
 	  select distinct  GroupIdentifier from  @SummaryDataGrouped
 	 
 	 SELECT 	 DeptId,LineId,UnitId,PathId,PathCode,IsNull(ProcessOrder,'Unspecified')  ProcessOrder,CrewDesc,ShiftDesc,ProductCode, ProdId , UnitDesc, UnitOrder , s.ProductionAmount, s.IdealProductionAmount,
 	  	 s.ActualSpeed, s.IdealSpeed, 
 	  	 PerformanceRate = 
 	  	 --CASE WHEN s.PerformanceRate > 100 AND @CapRates = 1 THEN 100
 	  	 -- 	 ELSE s.PerformanceRate END
 	  	  	 s.PerformanceRate
 	  	  	 , 
 	  	 s.WasteAmount, 
 	  	 QualityRate = CASE WHEN s.QualityRate > 100 AND @CapRates = 1 THEN 100 
 	  	  	  	  	  	 ELSE QualityRate END,
 	  	 s.PerformanceTime, s.RunTime, s.LoadingTime, 
 	  	 AvailableRate = CASE WHEN s.AvailableRate > 100 AND @CapRates = 1 THEN 100
 	  	  	  	  	  	 ELSE s.AvailableRate END, 
 	  	 PercentOEE = 
 	  	 --CASE WHEN s.PercentOEE > 100 AND @CapRates = 1 THEN 100 
 	  	 -- 	  	  	 ELSE 
 	  	 -- 	  	  	 PercentOEE
 	  	 -- 	  	  	  END
 	  	 PercentOEE,OEEMode
 	 FROM @Productsummary s
 	 ORDER BY DeptId,LineId,UnitId,PathId,UnitOrder , PercentOEE
