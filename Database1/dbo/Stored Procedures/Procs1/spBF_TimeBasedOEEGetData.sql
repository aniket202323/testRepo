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
CREATE PROCEDURE [dbo].[spBF_TimeBasedOEEGetData]
@UnitList                nvarchar(max),
@StartTime               datetime = NULL,
@EndTime                 datetime = NULL,
@FilterNonProductiveTime int = 0,
@InTimeZone 	              nVarChar(200) = null,
@ReturnLineData 	  	  	 Int = 0,
@pageSize 	  	  	  	  	 Int = Null,
@pageNum 	  	  	  	  	 Int = Null
AS
set nocount on
IF rtrim(ltrim(@InTimeZone)) = '' SET @InTimeZone = Null
SET @InTimeZone = coalesce(@InTimeZone,'UTC')
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
DECLARE @ProductionAmount Float
DECLARE @IdealProductionAmount Float
DECLARE @PerformanceTbl TABLE (ProductionAmount Float,IdealProductionAmount Float)
DECLARE @startRow 	 Int
DECLARE @endRow 	  	 Int
DECLARE @UseAggTable 	 Int = 0
DECLARE @LastProductiveTimeRowID Int, @CurrentProductiveRowID Int
DECLARE @CurrentProductiveStartTime DateTime, @CurrentProductiveEndTime DateTime
SET @pageNum = coalesce(@pageNum,1)
SET @pageSize = coalesce(@pageSize,10000)
SET @pageNum = @pageNum -1
SET @startRow = coalesce(@pageNum * @pageSize,0) + 1
SET @endRow = @startRow + @pageSize - 1
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
  	  UnitID nvarchar(4000) null,
  	  UtilizationTime Float DEFAULT 0,
  	  EffectivelyUsedTime Float DEFAULT 0,
  	  PerformanceRate Float null,
  	  UsedTime Float null,
  	  QualityRate Float null,
  	  WorkingTime Float DEFAULT 0,
  	  ActivityTime Float DEFAULT 0,
  	  AvailableRate Float null,
  	  PercentOEE  Float DEFAULT 0,
  	  ReworkTime 	  Float 	 DEFAULT 0,
 	  PerformanceSeconds Int,
 	  QualitySeconds Int,
 	  AvailabilitySeconds Int
)
DECLARE @TimedDetails TABLE 
(
 	 StartTime DateTime,
 	 EndTime DateTime,
 	 ERCId Int
)
CREATE TABLE #NonProductiveTime
( 
 	 RowID int IDENTITY,
 	 StartTime DateTime,
 	 EndTime DateTime
)
CREATE TABLE #ProductiveTime 
( 
 	 RowID int IDENTITY,
 	 StartTime DateTime,
 	 EndTime DateTime
)
DECLARE  @Results TABLE (Line nvarchar(100), LineId Int, Unit  nvarchar(100), UnitOrder Int, UtilizationTime Float,PerformanceRate Float,
  	  	  	  	  	 EffectivelyUsedTime Float,UsedTime Float,QualityRate Float, WorkingTime Float,
  	  	  	  	  	 ActivityTime Float,AvailableRate Float,PercentOEE Float,PerformanceSeconds Int,
 	  	  	  	  	 QualitySeconds Int,AvailabilitySeconds Int)
 	  	  	  	  	  	 
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
  	    	  insert into @Units (UnitId)
  	    	  select Id from [dbo].[fnCmn_IdListToTable]('Prod_Units',@UnitList,',')
  	  end
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
INSERT INTO @PageUnits (UnitId ,Unit, UnitOrder, LineId,  Line, OEEType)
 	 SELECT UnitId ,Unit, UnitOrder, LineId,  Line, OEEType
 	 FROM @SortedUnits 
 	 WHERE RowID Between @startRow and @endRow
 	 ORDER BY UnitOrder,Unit
SELECT @UnitRows = Count(*) from @PageUnits
Set @Row  	    	  =  	  0  	   
 --PRINT @UnitRows
DECLARE @AvailabilityName nvarchar(50), @PerformanceName nvarchar(50), 
 	 @PlannedName nvarchar(50), @QualityName nvarchar(50),
 	 @AvailabilityCategoryId Int, @PerformanceCategoryId Int,
 	 @PlannedCategoryId Int, @QualityCategoryId Int
SELECT @AvailabilityName = 'Availability',
 	 @PerformanceName = 'Performance',
 	 @PlannedName = 'Planned',
 	 @QualityName = 'Quality'
SELECT @AvailabilityCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @AvailabilityName
SELECT @PerformanceCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @PerformanceName
SELECT @PlannedCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @PlannedName
SELECT @QualityCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @QualityName
-------------------------------------------------------------------------------------------------
-- Loop through units and get OEE Data
-------------------------------------------------------------------------------------------------
WHILE @Row <  @UnitRows
BEGIN
  	  SELECT @Row = @Row + 1
  	  SELECT @ReportPUID = UnitId FROM @PageUnits WHERE ROWID = @Row
 	  DECLARE @NPCategoryId Int, @NonProductiveSeconds Int,
 	  	 @AvailabilitySeconds Int, @PerformanceSeconds Int,
 	  	 @PlannedSeconds Int, @QualitySeconds Int,
 	  	 @CalendarSeconds Int, @ActivityTime Int = 0,
 	  	 @UtilizationTime Int = 0, @WorkingTime Int = 0,
 	  	 @UsedTime Int = 0, @EffectivelyUsedTime Int = 0
 	 SET @CalendarSeconds = DATEDIFF(SECOND,@StartTime,@EndTime)
 	 SELECT @NPCategoryId 	 = Non_Productive_Category
 	 FROM dbo.Prod_Units WITH (NOLOCK)
 	 WHERE PU_Id = @ReportPUID
 	 /********************************************************************
 	 * 	  	  	  	  	  	 Non-Productive Time 	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 TRUNCATE TABLE #NonProductiveTime
 	 INSERT INTO #NonProductiveTime(StartTime,EndTime) 
 	 SELECT CASE WHEN np.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	 END,
 	  	    CASE WHEN np.End_Time > @EndTime THEN @EndTime
 	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	 END
 	 FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPCategoryId
 	 WHERE 	 PU_Id = @ReportPUID
 	  	 AND np.Start_Time < @EndTime
 	  	 AND np.End_Time > @StartTime
 	 SELECT 	 @NonProductiveSeconds = coalesce(SUM(DATEDIFF(SECOND,StartTime,EndTime)),0)
 	 FROM #NonProductiveTime
 	 
 	 /********************************************************************
 	 * 	  	  	  	  	  	 Productive Time 	  	  	  	  	  	  	     *
 	 ********************************************************************/
 	 TRUNCATE TABLE #ProductiveTime
 	 INSERT INTO #ProductiveTime(StartTime)
 	 SELECT @StartTime
 	 INSERT INTO #ProductiveTime(StartTime)
 	 SELECT EndTime
 	 FROM #NonProductiveTime
 	 WHERE EndTime < @EndTime
 	 UPDATE p
 	 SET p.EndTime = coalesce(npt.StartTime,@EndTime)
 	 FROM #ProductiveTime p
 	 LEFT JOIN #NonProductiveTime npt on npt.RowID = p.RowId
 	 DELETE #ProductiveTime WHERE StartTime = EndTime
 	 /********************************************************************
 	 * 	  	  	  	  	  	 Timed Event Details 	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 
 	 SELECT @LastProductiveTimeRowID = MAX(RowID),
 	  	 @CurrentProductiveRowID = MIN(RowID)
 	 FROM #ProductiveTime
 	 DELETE @TimedDetails
 	 WHILE @CurrentProductiveRowID <= @LastProductiveTimeRowID
 	 BEGIN
 	  	 SELECT @CurrentProductiveStartTime = StartTime,
 	  	  	 @CurrentProductiveEndTime = EndTime
 	  	 FROM #ProductiveTime
 	  	 WHERE RowID = @CurrentProductiveRowID
 	  	 INSERT INTO @TimedDetails(StartTime,EndTime,ERCId)
 	  	 SELECT 	 CASE WHEN Start_Time < @CurrentProductiveStartTime THEN @CurrentProductiveStartTime
 	  	  	  	  	  	  	 ELSE Start_Time
 	  	  	  	  	  	  	 END, 
 	  	  	  	 CASE WHEN End_Time > @CurrentProductiveEndTime THEN @CurrentProductiveEndTime
 	  	  	  	  	  	  	 ELSE End_Time
 	  	  	  	  	  	  	 END,
 	  	  	  	 ercd.ERC_Id
 	  	 FROM dbo.Timed_Event_Details ted 
 	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = ted.Event_Reason_Tree_Data_Id
 	  	 WHERE ted.PU_Id = @ReportPUID
 	  	  	 AND ted.Start_Time < @CurrentProductiveEndTime
 	  	  	 AND (ted.End_Time > @CurrentProductiveStartTime or ted.End_Time Is Null)
  	  	 SELECT @CurrentProductiveRowID = @CurrentProductiveRowID + 1
 	 END
 	 /********************************************************************
 	 * 	  	  	  	  	  	 Availability 	  	  	  	  	           	 *
 	 ********************************************************************/
 	 SELECT 	 @AvailabilitySeconds = coalesce(SUM(DATEDIFF(second, StartTime, EndTime)),0)
 	 FROM @TimedDetails
 	 WHERE ERCId = @AvailabilityCategoryId
 	 /********************************************************************
 	 * 	  	  	  	  	  	 Performance 	  	  	  	  	  	             *
 	 ********************************************************************/
 	 SELECT 	 @PerformanceSeconds = coalesce(SUM(DATEDIFF(second, StartTime, EndTime)),0)
 	 FROM @TimedDetails
 	 WHERE ERCId = @PerformanceCategoryId
 	 
 	 /********************************************************************
 	 * 	  	  	  	  	  	 Planned 	  	  	  	  	  	                 *
 	 ********************************************************************/
 	 SELECT 	 @PlannedSeconds = coalesce(SUM(DATEDIFF(second, StartTime, EndTime)),0)
 	 FROM @TimedDetails
 	 WHERE ERCId = @PlannedCategoryId
 	 /********************************************************************
 	 * 	  	  	  	  	  	 Quality 	  	  	  	  	  	                 *
 	 ********************************************************************/
 	 SELECT 	 @QualitySeconds = coalesce(SUM(DATEDIFF(second, StartTime, EndTime)),0)
 	 FROM @TimedDetails
 	 WHERE ERCId = @QualityCategoryId
 	 SET @ActivityTime = @CalendarSeconds - @NonProductiveSeconds
 	 SET @UtilizationTime = @ActivityTime - @PlannedSeconds
 	 SET @WorkingTime = @UtilizationTime - @AvailabilitySeconds
 	 SET @UsedTime = @WorkingTime - @PerformanceSeconds
 	 SET @EffectivelyUsedTime = @UsedTime - @QualitySeconds
 	 INSERT INTO @UnitSummary (UnitId,UtilizationTime,PerformanceRate,
  	  	  	 EffectivelyUsedTime,UsedTime,QualityRate,WorkingTime,
  	  	  	 ActivityTime,AvailableRate,PercentOEE,PerformanceSeconds,
 	  	  	 QualitySeconds,AvailabilitySeconds)
 	 SELECT @ReportPUID,
 	  	 @UtilizationTime,
 	  	 CASE WHEN @ActivityTime = 0 THEN 0 ELSE (cast(@ActivityTime as float) - cast(@PerformanceSeconds as float)) / cast(@ActivityTime as float) END,
  	  	 @EffectivelyUsedTime,
 	  	 @UsedTime,
 	  	 CASE WHEN @ActivityTime = 0 THEN 0 ELSE (cast(@ActivityTime as float) - cast(@QualitySeconds as float)) / cast(@ActivityTime as float) END,
 	  	 @WorkingTime,
 	  	 @ActivityTime,
 	  	 CASE WHEN @ActivityTime = 0 THEN 0 ELSE (cast(@ActivityTime as float) - cast(@AvailabilitySeconds as float)) / cast(@ActivityTime as float) END,
 	  	 CASE WHEN @ActivityTime = 0 THEN 0 ELSE cast(@EffectivelyUsedTime as float) / cast(@ActivityTime as float) END,
 	  	 @PerformanceSeconds,
 	  	 @QualitySeconds,
 	  	 @AvailabilitySeconds
END
-------------------------------------------------------------------------------------------------
-- Final results
-------------------------------------------------------------------------------------------------
IF @ReturnLineData != 0
BEGIN
 	 INSERT INTO @Results(Line,LineId,Unit, UnitOrder,UtilizationTime,PerformanceRate,
  	  	  	  	  	 EffectivelyUsedTime,UsedTime,QualityRate,WorkingTime,
  	  	  	  	  	 ActivityTime,AvailableRate,PercentOEE,
 	  	  	  	  	 PerformanceSeconds,QualitySeconds,AvailabilitySeconds)
 	  SELECT  	  u.Line, UnitID = LineId, Unit = 'All', UnitOrder = 1 ,
  	  	   UtilizationTime = SUM(s.UtilizationTime), 
  	  	   PerformanceRate = CASE WHEN SUM(s.ActivityTime) = 0 THEN 0 ELSE (SUM(s.ActivityTime) - SUM(s.PerformanceSeconds))/SUM(s.ActivityTime) END,
  	  	   EffectivelyUsedTime = SUM(s.EffectivelyUsedTime),
  	  	   UsedTime = SUM(s.UsedTime), 
  	  	   QualityRate = CASE WHEN SUM(s.ActivityTime) = 0 THEN 0 ELSE (SUM(s.ActivityTime) - SUM(s.QualitySeconds))/SUM(s.ActivityTime) END, 
 	  	   WorkingTime = SUM(s.WorkingTime), 
 	  	   ActivityTime = SUM(s.ActivityTime), 
  	  	   AvaliableRate = CASE WHEN SUM(s.ActivityTime) = 0 THEN 0 ELSE (SUM(s.ActivityTime) - SUM(s.AvailabilitySeconds))/SUM(s.ActivityTime) END, 
  	  	   PercentOEE = CASE WHEN SUM(s.ActivityTime) = 0 THEN 0 ELSE SUM(s.EffectivelyUsedTime)/SUM(s.ActivityTime) END,
 	  	   PerformanceSeconds = SUM(s.PerformanceSeconds),
 	  	   QualitySeconds = SUM(s.QualitySeconds),
 	  	   AvailabilitySeconds = SUM(s.AvailabilitySeconds)
  	  FROM @UnitSummary s
  	  JOIN @PageUnits u on u.UnitId = s.UnitID
  	  GROUP BY u.Line,LineId
 	  SELECT Line,LineId,Unit, UnitOrder,UtilizationTime, PerformanceRate * 100.00, EffectivelyUsedTime, UsedTime, 
  	  	  	  	  	  	 QualityRate * 100.00, WorkingTime, ActivityTime, AvailableRate * 100.00, PercentOEE  * 100.00,
 	  	  	  	  	  	 PerformanceSeconds,QualitySeconds,AvailabilitySeconds
 	  FROM @Results
END
ELSE
BEGIN
 	 SELECT  	  u.Line, s.UnitID, u.Unit, u.UnitOrder,  s.UtilizationTime, PerformanceRate = s.PerformanceRate * 100.00, s.EffectivelyUsedTime,
 	  	 s.UsedTime, QualityRate = s.QualityRate * 100.00, s.WorkingTime, s.ActivityTime, 
 	  	 AvailableRate = s.AvailableRate * 100.00, PercentOEE = s.PercentOEE * 100.00,
 	  	 PerformanceSeconds,QualitySeconds,AvailabilitySeconds
 	 FROM @UnitSummary s
 	 join @PageUnits u on u.UnitId = s.UnitID
 	 ORDER BY u.Line, u.UnitOrder, u.Unit
END
