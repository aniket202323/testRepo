CREATE PROCEDURE [dbo].[spBF_SerialLineOEE]
 	 @LineId 	  	  	  	  	  	 Int,
 	 @ReportStartTime 	  	  	 DATETIME = NULL,
 	 @ReportEndTime 	  	  	  	 DATETIME = NULL,
 	 @FilterNonProductiveTime 	 int = 0,
 	 @InTimeZone 	  	  	  	  	 nVarChar(200)=null,
 	 @OEEMode 	  	  	  	  	 Int = 4
AS
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
/* @OEEMode 4 = Good Production  (add Waste for total Production) */
/* @OEEMode 5 = Production is Total (subtract waste for good)*/
DECLARE 	 @Rows int,@ProductionStartsTableId int, 	 @NonProductiveTableId int,@ProductionSpecsTableId int, 	 @ScheduledCategoryId int,
 	  	 @ExternalCategoryId int,@PerformanceCategoryId int,@ProductionPropId int,@ProductionSpecId int,@ProductionRateFactor Float,
 	  	 @ProductionType tinyint,@ProductionVarId int,@ProductionStartTime tinyint,@NPCategoryId int,@CapRates tinyint,
 	  	 @AmountEngineeringUnits nvarchar(25),@TimeEngineeringUnits int,@OpenDowntime int,@oeeHighAlarmCount int,@oeeMediumAlarmCount int,
 	  	 @oeeLowAlarmCount int,@HighAlarmCount int,@MediumAlarmCount int,@LowAlarmCount int
DECLARE @LineName nVarChar(100)
DECLARE @Production 	  	 Float
DECLARE @DowntimePlanned float,@AvailableTime float,@DowntimeExternal float,@LoadingTime float,@DowntimePerformance float,
 	  	 @DowntimeTotal float,@DowntimeUnplanned float,@RunTimeGross float,@ProductiveTime float,@WasteQuantity float,
 	  	 @ProductionTotal float,@ProductionNet float,@ProductionIdeal float,@TotalAvailableTime  float, @St datetime,
 	  	 @Et datetime,@ProductionTarget float,@CalendarTime float
DECLARE @DowntimePlannedSum float,@AvailableTimeSum float,@DowntimeExternalSUM float,@LoadingTimeSum float,@DowntimePerformanceSum float,
 	  	 @DowntimeTotalSum float,@DowntimeUnplannedSum float,@RunTimeGrossSum float,@ProductiveTimeSum float,@WasteQuantitySum float,
 	  	 @ProductionTotalSum float,@ProductionNetSum float,@ProductionIdealSum float,@TotalAvailableTimeSum  float,@RunTimeGrossSumIdeal float,
 	  	 @ActualTime float,@ActualLoadingTime float
DECLARE @SlicesRowCount int, @RowId int,@NP int
DECLARE @ProductionStartsUnit 	 Int,@DownTimeUnit Int,@NPTUnit Int, @LoopStart Int,@LoopEnd Int,@LoopPUId Int
-- The goal is to build a table with all the start times and then
-- at the end we'll fill in the end times.
CREATE TABLE #Periods ( 	 PeriodId 	  	  	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 TableId 	  	  	  	 int,
 	  	  	  	  	  	 KeyId 	  	  	  	 int)
CREATE CLUSTERED INDEX PCIX ON #Periods (TableId, StartTime, KeyId)
CREATE TABLE #Slices ( 	 SliceId 	  	  	  	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 PUId 	  	  	  	 int,
 	  	  	  	  	  	 ProdId 	  	  	  	 int,
 	  	  	  	  	  	 NP 	  	  	  	  	 bit DEFAULT 0,
 	  	  	  	  	  	 ProductionTarget 	 float,
 	  	  	  	  	  	 CalendarTime 	  	 Float DEFAULT 0)
CREATE NONCLUSTERED INDEX SNCIXNP ON #Slices (NP)
CREATE CLUSTERED INDEX SCIX ON #Slices (PUId, NP, StartTime)
  	  	  	  	  	 
DECLARE @WasteUnits TABLE  (Id int IDENTITY(1,1),PUId int NULL,ProductionStartTime Int Null)
DECLARE @ProductionUnits TABLE  (Id int IDENTITY(1,1),PUId int NULL,PVarId Int Null,ProductionStartTime Int Null,ProductionType Int Null)
CREATE TABLE #ProductiveTimes (ROWID int IDENTITY(1,1), StartTime datetime,EndTime datetime)
SELECT @LineName = PL_Desc FROM Prod_Lines WHERE pl_Id = @LineId 
SELECT @DowntimeUnit = MIN(a.PU_Id)
 	 FROM Prod_Units_Base a
 	 JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
 	 JOIN Table_Fields_Values c ON c.TableId = 43 and a.PU_Id = c.KeyId and c.Table_Field_Id = -92
 	 WHERE a.pl_Id = @LineId 
SELECT @NPTUnit = MIN(a.PU_Id)
 	 FROM Prod_Units_Base a
 	 JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
 	 JOIN Table_Fields_Values c ON c.TableId = 43 and a.PU_Id = c.KeyId and c.Table_Field_Id = -96
 	 WHERE a.pl_Id = @LineId 
SELECT @ProductionStartsUnit = @NPTUnit 
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
SELECT 	 -- Table Ids
 	  	 @ProductionStartsTableId 	  	 = 2,
 	  	 @NonProductiveTableId 	  	  	 = -3,
 	  	 @ProductionSpecsTableId 	  	  	 = -5
SELECT @ReportStartTime = dbo.fnServer_CmnConvertToDBTime(@ReportStartTime,@InTimeZone)
SELECT @ReportEndTime = dbo.fnServer_CmnConvertToDBTime(@ReportEndTime ,@InTimeZone)
SELECT 	 @CapRates = dbo.fnCMN_OEERateIsCapped()
 	 /********************************************************************
 	 * 	  	  	  	  	  	  	 Configuration 	  	  	  	  	  	  	 *
 	 ********************************************************************/
SELECT 	 @NPCategoryId 	 = Non_Productive_Category
 	 FROM Prod_Units_Base a
 	 WHERE a.PU_Id  = @NPTUnit
SELECT 	 @ProductionSpecId 	  	  	 = Production_Rate_Specification,
 	  	 @ProductionRateFactor 	  	 = dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits)
 	 FROM Prod_Units_Base a
 	 WHERE a.PU_Id  = @ProductionStartsUnit
SELECT 	 @ScheduledCategoryId 	  	 = Downtime_Scheduled_Category,
 	  	  	 @ExternalCategoryId 	  	  	 = Downtime_External_Category,
 	  	  	 @PerformanceCategoryId 	  	 = Performance_Downtime_Category
 	 FROM Prod_Units_Base a
 	 WHERE a.PU_Id  = @DowntimeUnit
SELECT 	 @ProductionPropId 	 = Prop_Id
 	 FROM dbo.Specifications WITH (NOLOCK)
 	 WHERE Spec_Id = @ProductionSpecId
SELECT @OpenDowntime = null
SELECT @OpenDowntime = Tedet_id
 	 FROM Timed_Event_Details WITH (NOLOCK)
 	 WHERE PU_Id = @DowntimeUnit and End_Time Is Null
IF @OpenDowntime Is Null
 	 SELECT @OpenDowntime = 1
ELSE
 	 SELECT @OpenDowntime = 0
SELECT 
 	 @AmountEngineeringUnits 	 = coalesce(AmountEngineeringUnits, 'units'),
 	 @TimeEngineeringUnits 	 = coalesce(TimeEngineeringUnits, 4)
FROM dbo.fnCMN_GetEngineeringUnitsByUnit(@ProductionStartsUnit)
INSERT INTO #Periods (TableId,KeyId,StartTime,EndTime)
 	 SELECT 	 @ProductionStartsTableId,Start_Id,
 	  	  	 CASE 	 WHEN Start_Time < @ReportStartTime THEN @ReportStartTime
 	  	  	  	  	 ELSE Start_Time
 	  	  	  	  	 END,
 	  	  	 CASE  	 WHEN End_Time > @ReportEndTime OR End_Time IS NULL THEN @ReportEndTime
 	  	  	  	  	 ELSE End_Time
 	  	  	  	  	 END 	  	 
 	 FROM dbo.Production_Starts WITH (NOLOCK)
 	 WHERE 	 PU_Id = @ProductionStartsUnit AND Start_Time < @ReportEndTime 	 AND (End_Time > @ReportStartTime OR End_Time IS NULL)
INSERT INTO #Periods ( 	 TableId,KeyId,StartTime,EndTime)
 	 SELECT 	 @NonProductiveTableId,np.NPDet_Id,
 	  	  	 StartTime 	 = CASE 	 WHEN np.Start_Time < @ReportStartTime THEN @ReportStartTime
 	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > @ReportEndTime THEN @ReportEndTime
 	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	 END
 	 FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id AND ercd.ERC_Id = @NPCategoryId
 	 WHERE 	 PU_Id = @NPTUnit AND np.Start_Time < @ReportEndTime 	 AND np.End_Time > @ReportStartTime
 	  	  	 
 	 -- PRODUCTION TARGET
INSERT INTO #Periods ( 	 TableId,KeyId,StartTime,EndTime)
 	 SELECT 	 @ProductionSpecsTableId,AS_Id,
 	  	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.Start_Time, @ReportStartTime),
 	  	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.End_Time, @ReportEndTime)
 	 FROM dbo.Production_Starts ps WITH (NOLOCK)
 	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PU_Id = puc.PU_Id AND puc.Prop_Id = @ProductionPropId AND ps.Prod_Id = puc.Prod_Id 	 
 	 JOIN dbo.Active_Specs s WITH (NOLOCK) ON s.Char_Id = puc.Char_Id AND s.Spec_Id = @ProductionSpecId 	 AND s.Effective_Date < CASE WHEN ps.End_Time > @ReportEndTime OR ps.End_Time IS NULL THEN @ReportEndTime ELSE ps.End_Time END 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @ReportEndTime) > CASE WHEN ps.Start_Time < @ReportStartTime THEN @ReportStartTime ELSE ps.Start_Time END 	 
 	 WHERE  	 ps.PU_Id = @ProductionStartsUnit AND ps.Start_Time < @ReportEndTime
 	  	  	 AND ( 	 ps.End_Time > @ReportStartTime OR ps.End_Time IS NULL)
 	  	  	 AND dbo.fnGEPSMaxDate(s.Effective_Date, ps.Start_Time, @ReportStartTime) <= dbo.fnGEPSMinDate(s.Expiration_Date, ps.End_Time, @ReportEndTime)
/********************************************************************
* 	  	  	  	  	  	  	 Gaps 	  	  	  	  	  	  	  	  	 *
********************************************************************/
-- Insert gaps
INSERT INTO #Periods ( 	 StartTime,EndTime,TableId)
 	 SELECT 	 p1.EndTime,@ReportEndTime,p1.TableId
 	  	 FROM #Periods p1
 	  	 LEFT JOIN #Periods p2 ON 	 p1.TableId = p2.TableId 	 AND p1.EndTime = p2.StartTime
 	  	 WHERE 	 p1.EndTime < @ReportEndTime 	 AND p2.PeriodId IS NULL
/********************************************************************
* 	  	  	  	  	  	  	 Slices 	  	  	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO #Slices ( 	 PUId,StartTime)
 	 SELECT DISTINCT 	 0,StartTime
 	  	 FROM #Periods
 	  	 ORDER BY StartTime ASC
SELECT @Rows = @@rowcount
 	 -- Correct the end times
UPDATE s1
 	 SET s1.EndTime 	  	 = s2.StartTime,s1.CalendarTime 	 = datediff(s, s1.StartTime, s2.StartTime)
 	 FROM #Slices s1
 	 JOIN #Slices s2 ON s2.SliceId = s1.SliceId + 1
 	 WHERE s1.SliceId < @Rows
UPDATE #Slices
 	 SET EndTime  	  	 = @ReportEndTime,CalendarTime 	 = datediff(s, StartTime, @ReportEndTime)
 	 WHERE SliceId = @Rows
UPDATE s SET 	 PUId = ps.PU_Id, ProdId 	 = ps.Prod_Id
 	 FROM #Slices s
 	 LEFT JOIN #Periods p ON p.TableId = @ProductionStartsTableId AND p.StartTime <= s.StartTime 	 AND p.EndTime > s.StartTime
 	 LEFT JOIN dbo.Production_Starts ps WITH (NOLOCK) ON p.KeyId = ps.Start_Id
 	 WHERE s.PUId = 0 	 AND p.KeyId IS NOT NULL
 UPDATE s SET NP = 1
 	 FROM #Slices s
 	 LEFT JOIN #Periods p ON p.TableId = @NonProductiveTableId AND p.StartTime <= s.StartTime AND p.EndTime > s.StartTime
 	 WHERE p.KeyId IS NOT NULL 
UPDATE s SET ProductionTarget = sp.Target
 	 FROM #Slices s
 	 LEFT JOIN #Periods p ON p.TableId = @ProductionSpecsTableId 	 AND p.StartTime <= s.StartTime 	 AND p.EndTime > s.StartTime
 	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
 	 WHERE p.KeyId IS NOT NULL
SELECT @SlicesRowCount = Count(SliceId) FROM #Slices
SET @RowId = 0
 	 -- Calculate the downtime statistics for each slice
 	 -- Calculate 'Planned Downtime' and 'Available Time'
SELECT 	 @DowntimePlannedSum =0,@AvailableTimeSum = 0,@DowntimeExternalSum=0,@LoadingTimeSum=0,@DowntimePerformanceSum=0,
 	  	 @DowntimeTotalSum=0,@DowntimeUnplannedSum 	 =0,@RunTimeGrossSum = 0,@ProductiveTimeSum=0,@WasteQuantitySum =0,
 	  	 @ProductionTotalSum=0,@ProductionIdealSum=0,@TotalAvailableTimeSum=0,@ProductionNetSum=0,@RunTimeGrossSumIdeal = 0,
 	  	 @ActualTime = 0
SELECT @oeeHighAlarmCount=0,@oeeMediumAlarmCount=0,@oeeLowAlarmCount=0,@HighAlarmCount=0,@MediumAlarmCount=0,@LowAlarmCount=0
WHILE @RowId < @SlicesRowCount
BEGIN
SkipSlice:
/********************************************************************
* 	  	  	  	  	  	  	 Downtime 	  	  	  	  	  	  	  	 *
********************************************************************/
 	 SELECT 	 @DowntimePlanned =0,@AvailableTime = 0,@DowntimeExternal=0,@LoadingTime=0,@DowntimePerformance=0,
 	  	 @DowntimeTotal=0,@DowntimeUnplanned 	 =0,@RunTimeGross = 0,@ProductiveTime=0,@WasteQuantity =0,@ProductionTotal=0,@ProductionIdeal=0,
 	  	 @TotalAvailableTime=0,@ProductionNet=0
 	 SELECT @RowId = @RowId + 1
 	 IF (@RowId <= @SlicesRowCount)
 	  	 SELECT @St =StartTime,@Et = EndTime,@ProductionTarget = ProductionTarget,@CalendarTime= CalendarTime,@NP = NP
 	  	  	 FROM #Slices WITH (NOLOCK) 
 	  	  	 WHERE SliceID = @RowId --AND(@FilterNonProductiveTime=0 OR NP=0) 
 	 ELSE
 	  	 BREAK
 	 If Not(@FilterNonProductiveTime=0 OR @NP=0) 	 GOTO SkipSlice
 	 DECLARE @DtRecords TABLE (Start_Time DateTime,End_Time DateTime,ERTDId Int)
 	 DELETE FROM @DtRecords
 	 INSERT INTO @DtRecords(Start_Time,End_Time,ERTDId)
 	  	 SELECT Start_Time,End_Time,Event_Reason_Tree_Data_Id
 	  	 FROM Timed_Event_Details ted WITH (NOLOCK)
 	  	 WHERE ted.PU_Id = @DownTimeUnit 	 AND ted.Start_Time < @Et AND (ted.End_Time > @St or ted.End_Time is Null)
 	 UPDATE @DtRecords SET Start_Time = @St WHERE Start_Time < @St
 	 UPDATE @DtRecords SET End_Time = @Et WHERE End_Time > @Et OR End_Time Is Null
 	 SELECT @DowntimePlanned= isnull(sum(datediff(s,Start_Time,End_Time)),0)
 	  	 FROM @DtRecords ted    
 	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON ted.ERTDId = ercd.Event_Reason_Tree_Data_Id 	 AND ercd.ERC_Id = @ScheduledCategoryId
 	 SET @AvailableTime = CASE WHEN isnull(@CalendarTime,0) >= isnull( @DownTimePlanned,0)
 	  	  	  	  	  	  	  	 THEN @CalendarTime - isnull(@DownTimePlanned,0) 	 ELSE 0 	 END
 	 SELECT 	 @DowntimeExternal = isnull(sum(datediff(s,Start_Time,End_Time)),0)
 	  	 FROM  @DtRecords ted 
 	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.ERTDId = ercd.Event_Reason_Tree_Data_Id 	 AND ercd.ERC_Id = @ExternalCategoryId
 	 SET @LoadingTime = CASE 	 WHEN @AvailableTime >= isnull(@DowntimeExternal,0) 	 
 	  	  	  	  	  	 THEN @AvailableTime - isnull(@DowntimeExternal, 0) 	 ELSE 0 	 END
 	  	  	 -- Calculate 'Performance Downtime'
 	 SELECT @DowntimePerformance = isnull(sum(datediff(s,Start_Time,End_Time)),0)
 	  	 FROM @DtRecords ted 
 	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.ERTDId = ercd.Event_Reason_Tree_Data_Id AND ercd.ERC_Id = @PerformanceCategoryId
 	 SELECT @DowntimeTotal = 	  isnull(sum(datediff(s,Start_Time,End_Time)),0)
 	  	 FROM @DtRecords
 	 SELECT @DowntimeUnplanned 	 = isnull(@DownTimeTotal, 0) - @DowntimePlanned - @DowntimeExternal - @DowntimePerformance,
 	  	  	 @RunTimeGross 	  	 = CASE 	 WHEN isnull(@CalendarTime,0) >= isnull(@DownTimeTotal,0)
 	  	  	  	  	  	  	  	  	  	 THEN @CalendarTime - isnull(@DownTimeTotal, 0) + isnull(@DowntimePerformance,0)
 	  	  	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	  	  	 END,
 	  	  	 @ProductiveTime 	  	 = CASE 	 WHEN Isnull(@CalendarTime,0) >= isnull(@DownTimeTotal,0)
 	  	  	  	  	  	  	  	  	  	 THEN @CalendarTime - isnull(@DownTimeTotal, 0)
 	  	  	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	  	  	 END 	  	  	  	  
 	 /********************************************************************
 	 * 	  	  	  	  	  	 End 	 Downtime 	  	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 SET @LoopStart = 1
 	 SET @LoopEnd = Null
 	 SELECT @LoopEnd =Max(Id) FROM @WasteUnits
 	 IF @LoopEnd Is Null SET @LoopEnd = 0
 	 WHILE @LoopStart <= @LoopEnd
 	 BEGIN
 	  	 SELECT @LoopPUId = PUId,@ProductionStartTime = ProductionStartTime 
 	  	  	 From @WasteUnits 
 	  	  	 WHERE Id = @LoopStart
 	  	  	 SELECT 	 @WasteQuantity 	  	 = ISNULL(sum(wed.Amount),0)
 	  	  	 FROM dbo.Waste_Event_Details wed WITH (NOLOCK) 
 	  	  	 WHERE 	 wed.PU_Id = @LoopPUId
 	  	  	  	  	 AND wed.TimeStamp >= @St
 	  	  	  	  	 AND wed.TimeStamp < @Et
 	  	  	  	  	 AND Event_Id IS NULL
 	  	  	  	  	 AND Amount IS NOT NULL
 	  	  	 IF @ProductionStartTime = 1 	 -- Uses start time so pro-rate quantity
 	  	  	  	 BEGIN
 	  	  	  	 
 	  	  	  	  	 SELECT @WasteQuantity = @WasteQuantity + isnull(sum(CASE WHEN e.start_time IS NOT NULL THEN 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 convert(Float, datediff(s, 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN e.Start_Time < @St  THEN @St
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN e.TimeStamp > @Et THEN @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 / convert(Float, datediff(s,  e.Start_Time  , e.TimeStamp))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 * isnull(wed.Amount,0) 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE ISNULL(wed.amount,0)END),0)
 	  	  	  	  	  	  	  	  	 FROM 	 dbo.Events e WITH (NOLOCK) 
 	  	  	  	  	  	  	  	  	 LEFT JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 wed.PU_Id = @LoopPUId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Amount IS NOT NULL
 	  	  	  	  	  	  	  	  	 WHERE 	 e.PU_Id = @LoopPUId
 	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp >= @St
 	  	  	  	  	  	  	  	  	  	  	 AND isnull(e.Start_Time, e.TimeStamp) < @Et
 	  	  	  	 
 	  	  	  	 END
 	  	  	 ELSE 	  	 -- Doesn't use start time so don't pro-rate quantity
 	  	  	 BEGIN
 	  	  	 
 	  	  	  	 SELECT @WasteQuantity = @WasteQuantity+ isnull(sum(wed.Amount),0)
 	  	  	  	 FROM  dbo.Events e WITH (NOLOCK) 
 	  	  	  	  	   JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 wed.PU_Id = @LoopPUId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Amount IS NOT NULL
 	  	  	  	 WHERE  e.PU_Id = @LoopPUId
 	  	  	  	  	  	 AND e.TimeStamp >= @St
 	  	  	  	  	  	 AND e.TimeStamp <  @Et
 	  	  	 END
 	  	 SELECT @LoopStart = @LoopStart + 1
 	 END
 	 SET @LoopStart = 1
 	 SET @LoopEnd = Null
 	 SELECT @LoopEnd =Max(Id) FROM @ProductionUnits
 	 IF @LoopEnd Is Null SET @LoopEnd = 0
 	 SET @Production = 0
 	 WHILE @LoopStart <= @LoopEnd
 	 BEGIN
 	  	 SELECT @LoopPUId = PUId,@ProductionVarId = pvarId,@ProductionType = ProductionType,@ProductionStartTime =  ProductionStartTime
 	  	  	 FROM @ProductionUnits
 	  	  	 WHERE Id = @LoopStart
 	  	 IF @ProductionType = 1
 	  	 BEGIN
 	  	  	 SELECT 	 @Production = @Production + isnull(sum(convert(Float, t.Result)),0)  
 	  	  	  	 FROM 	 dbo.Tests t WITH (NOLOCK) 
 	  	  	  	 WHERE 	 t.Var_Id = @ProductionVarId 	 AND t.Result_On > @St AND t.Result_On <= @Et
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 IF @ProductionStartTime = 1 	 -- Uses start time so pro-rate quantity
 	  	  	 BEGIN
 	  	  	  	 SELECT @Production = 	 @Production + isnull(sum( CASE 	 WHEN e.Start_Time IS NOT NULL THEN
 	  	  	  	  	  	  	  	  	  	 convert(Float, datediff(s, CASE 	 WHEN e.Start_Time < @St THEN @St
 	  	  	  	  	  	  	  	  	  	 ELSE e.Start_Time
 	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN e.TimeStamp > @Et THEN @Et
 	  	  	  	  	  	  	  	  	  	 ELSE e.TimeStamp
 	  	  	  	  	  	  	  	  	  	 END))/ convert(Float, datediff(s, e.Start_Time, e.TimeStamp)) * isnull(ed.Initial_Dimension_X,0)
 	  	  	  	  	  	  	  	  	  	 ELSE isnull(ed.Initial_Dimension_X,0)
 	  	  	  	  	  	  	  	  	  	 END),0) 
 	  	  	  	 FROM dbo.Events e WITH (NOLOCK) 
 	  	  	  	 JOIN dbo.Production_Status ps WITH (NOLOCK) ON 	 e.Event_Status = ps.ProdStatus_Id 	 AND ps.Count_For_Production = 1
 	  	  	  	 LEFT JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
 	  	  	  	 WHERE  e.PU_Id =@LoopPUId 	 AND e.TimeStamp > @St 	 AND isnull(e.Start_Time, e.TimeStamp) < @Et -- Note: if starttime is null it assumes that starttime = endtime
 	  	  	 END
 	  	  	 ELSE -- Doesn't use start time so don't pro-rate quantity
 	  	  	 BEGIN
 	  	  	  	 SELECT @Production 	 = 	 @Production + isnull(sum(ed.Initial_Dimension_X)  ,0)
 	  	  	  	 FROM dbo.Events e WITH (NOLOCK) 
 	  	  	  	 JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
 	  	  	  	 WHERE  e.PU_Id = @LoopPUId 	 AND e.TimeStamp >= @St 	 AND e.TimeStamp < @Et
 	  	  	 END
 	  	 END
 	  	 SELECT @LoopStart = @LoopStart + 1
 	 END
 	 IF @OEEMode = 4 --@Production = Good Production  (add Waste for total Production)
 	 BEGIN
 	  	 SET @ProductionTotal = @Production + @WasteQuantity
 	  	 SET @ProductionNet = @Production
 	 END
 	 ELSE IF @OEEMode = 5 --@Production = Total Production  (subtract waste for good)
 	 BEGIN
 	  	 SET @ProductionTotal = @Production
 	  	 SET @ProductionNet = @Production - @WasteQuantity
 	 END
 	 SELECT  @ProductionIdeal 	 = dbo.fnGEPSIdealProduction(@RunTimeGross , 	 @ProductionTarget ,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  @ProductionRateFactor,@ProductionTotal)
 	 SET 	 @DowntimePlannedSum =@DowntimePlannedSum + @DowntimePlanned
 	 SET 	 @AvailableTimeSum = @AvailableTimeSum +@AvailableTime
 	 SET 	 @DowntimeExternalSum=@DowntimeExternalSum + @DowntimeExternal
 	 SET 	 @LoadingTimeSum=@LoadingTimeSum + CASE WHEN @LoadingTime > 0 THEN @LoadingTime/60 ELSE 0 END
 	 SET @DowntimePerformanceSum=@DowntimePerformanceSum + CASE WHEN @DowntimePerformance > 0 THEN @DowntimePerformance/60 ELSE 0 END 
 	 SET @DowntimeTotalSum=@DowntimeTotalSum + @DowntimeTotal
 	 SET 	 @DowntimeUnplannedSum 	 = @DowntimeUnplannedSum + @DowntimeUnplanned
 	 SET 	 @RunTimeGrossSum = @RunTimeGrossSum  + CASE WHEN @RunTimeGross > 0 THEN @RunTimeGross/60 ELSE 0 END
 	 SET 	 @ProductiveTimeSum=@ProductiveTimeSum + CASE WHEN @ProductiveTime > 0 THEN @ProductiveTime /60 ELSE 0 END 
 	 SET 	 @WasteQuantitySum =@WasteQuantitySum  + @WasteQuantity
 	 SET 	 @ProductionTotalSum=@ProductionTotalSum + @ProductionTotal
 	 SET 	 @ProductionIdealSum= @ProductionIdealSum + @ProductionIdeal
 	 SET 	 @TotalAvailableTimeSum=@TotalAvailableTimeSum + @TotalAvailableTime
 	 SET 	 @ProductionNetSum=@ProductionNetSum + @ProductionNet
 	 SET @RunTimeGrossSumIdeal = @RunTimeGrossSumIdeal + isnull(@RunTimeGross,0)
 	 SET @ActualTime = @ActualTime + isnull(@ProductiveTime,0)
 	 SET @ActualLoadingTime = @ActualLoadingTime + isnull(@LoadingTime,0)
END
 	 /********************************************************************
 	 * 	  	  	  	  	  	  	 Alarm Info 	  	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 DECLARE @RowsProductive int,@RowProductive int
 	 DECLARE @curStartTime datetime,@curEndTime datetime
 	 SELECT @oeeHighAlarmCount=0,@oeeMediumAlarmCount=0,@oeeLowAlarmCount=0,@HighAlarmCount=0,@MediumAlarmCount=0,@LowAlarmCount=0
 	 IF( @FilterNonProductiveTime = 1)
 	  	 INSERT INTO #ProductiveTimes(StartTime,EndTime) 
 	  	  	 SELECT  StartTime,EndTime FROM dbo.fnBF_GetProductiveTimes(@DownTimeUnit,@ReportStartTime,@ReportEndTime)
 	 ELSE
 	  	 INSERT INTO #ProductiveTimes(StartTime,EndTime) 
 	  	  	 SELECT @ReportStartTime,@ReportEndTime
 	 SET @RowsProductive = @@Rowcount 
 	 SET @RowProductive = 0
 	  	 
 	 WHILE @RowProductive < @RowsProductive
 	 BEGIN 	 
 	  	 SELECT @RowProductive = @RowProductive + 1
 	  	 SELECT @curStartTime= StartTime, @curEndTime = EndTime 
 	  	 FROM #ProductiveTimes 
 	  	 WHERE ROWID = @RowProductive
 	 
  	  	 EXECUTE dbo.spBF_GetUnitAlarmCounts @DownTimeUnit,@curStartTime,@curEndTime,@HighAlarmCount OUTPUT,@MediumAlarmCount OUTPUT,@LowAlarmCount OUTPUT
 	  	 SELECT @oeeHighAlarmCount = @oeeHighAlarmCount + isnull(@HighAlarmCount,0), @oeeMediumAlarmCount = @oeeMediumAlarmCount + isnull(@MediumAlarmCount,0), @oeeLowAlarmCount = @oeeLowAlarmCount + isnull(@LowAlarmCount,0)
 	 END
 	  	  	  	  	  	  	  	 
 	 SELECT 	 
 	  	 LineDesc = @LineName,
 	  	 LineId = @LineId,
 	  	 UnitDesc = 'All',
 	  	 UnitOrder = 1,
 	  	 Production 	  	  	 = @ProductionNetSum,
 	  	 IdealProductionAmount = @ProductionIdealSum,
  	  	 ActualSpeed = dbo.fnGEPSActualSpeed(@RunTimeGrossSumIdeal ,@ProductionTotalSum,@ProductionRateFactor),
 	  	 IdealSpeed = dbo.fnGEPSIdealSpeed( 	 @RunTimeGrossSumIdeal,@ProductionIdealSum,@ProductionRateFactor),
 	  	 PerformanceRate 	  	 =   dbo.fnGEPSPerformance(@ProductionTotalSum,@ProductionIdealSum,@CapRates),
 	  	 WasteQuantity 	  	 = @WasteQuantitySum,
 	  	 QualityRate = dbo.fnGEPSQuality(@ProductionTotalSum,@WasteQuantitySum,@CapRates),
 	  	 PerformanceTime = @DowntimePerformanceSum,
 	  	 RunTime = @ProductiveTimeSum,
 	  	 LoadingTime = @LoadingTimeSum,
 	  	 AvailableRate = dbo.fnGEPSAvailability( 	 @LoadingTimeSum,@RunTimeGrossSum,@CapRates),
 	  	 PercentOEE = dbo.fnGEPSAvailability(@LoadingTimeSum,@RunTimeGrossSum,@CapRates)/100
 	  	  	  	  	  	  	  	  	  	 * dbo.fnGEPSPerformance(@ProductionTotalSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionIdealSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @CapRates)/100
 	  	  	  	  	  	  	  	  	  	 * dbo.fnGEPSQuality( 	 @ProductionTotalSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @WasteQuantitySum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @CapRates)/100
 	  	  	  	  	  	  	  	  	  	 *100 
DROP TABLE #ProductiveTimes
DROP TABLE #Periods
DROP TABLE #Slices
