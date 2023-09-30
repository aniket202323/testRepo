/*
Procedure: 	  	  	 spDBR_DowntimeDistribution_WIP
Author: 	  	  	  	 Gopinath K (GE)
Date Created: 	  	 2009/07/23
Editor Tab Spacing: 	 4
Description:
============
Downtime Distribution Web part
Notes:
======
Assumptions: 
This sp assumes the records do not overlap for product changes,production days, 
shifts, non-productive time. 
This SP fixes the following bugs:
1-871806641 - Issue with #Events displayed in the web part tab (other than location), with multiple production units. 
This SP may need changes based on:
1-871806721 - Reason Tree Names on DT Web Part assumes production units selected have the same reason tree.
Use Original End Time and create column TableId to give you indexed key.
Change Date 	 Who 	  	 What
=========== 	 ==== 	 =====
2009-09-23 	 GK 	  	 Original
2013-06-10  ER 	  	 Updated the stored procedure with Non productive time filter logic
2018-07-24 	 Prasad 	 throwing error in case of equal starttime and endtime [defect Id: DE57858]
*/
--/*
CREATE PROCEDURE [dbo].[spDBR_DowntimeDistribution]
@UnitList 	  	  	  	  	 text = NULL,
@StartTime 	  	  	  	  	 datetime,
@EndTime 	  	  	  	  	 datetime,
@FilterNonProductiveTime 	 int = 0,
@ProductFilter 	  	  	  	 int = NULL,
@CrewFilter 	  	  	  	  	 varchar(10) = NULL,
@LocationFilter 	  	  	  	 int = NULL,
@FaultFilter 	  	  	  	 varchar(100) = NULL,
@ReasonFilter1 	  	  	  	 int = NULL,
@ReasonFilter2 	  	  	  	 int = NULL,
@ReasonFilter3 	  	  	  	 int = NULL,
@ReasonFilter4 	  	  	  	 int = NULL,
@ShowTopNBars 	  	  	  	 int = 20,
@InTimeZone 	  	  	  	  	 varchar(200) = NULL,  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
@ShiftFilter 	  	  	  	 varchar(10) = NULL
AS
/********************************************************************
* 	  	  	  	  	  	  	 Declarations 	  	  	  	  	  	  	 *
********************************************************************/
/* 2018-07-24 throwing error when starttime and endtime are equal.*/
IF @StartTime = @EndTime 
Begin
 	 RAISERROR ('Starttime and Endtime can not be same',16,1);
 	 Return
End
DECLARE 	 -- General
 	 @Rows 	  	  	  	  	  	  	 int,
 	 @ReportPUId 	  	  	  	  	  	 int,
 	 @UnitText 	  	  	  	  	  	 nvarchar(4000),
 	 @Debug 	  	  	  	  	  	  	 int,
 	 -- Report Parameters
 	 @rptParmStartTime 	  	  	  	 datetime,
 	 @rptParmEndTime 	  	  	  	  	 datetime,
 	 @rptParmfilterNPT 	  	  	  	 int,
 	 @rptParmProductFilter 	  	  	 int,
 	 @rptParmCrewFilter 	  	  	  	 varchar(10),
 	 @rptParmFaultFilter 	  	  	  	 varchar(100),
 	 @rptParmLocationFilter 	  	  	 int,
 	 @rptParmReasonFilter1 	  	  	 int,
 	 @rptParmReasonFilter2 	  	  	 int,
 	 @rptParmReasonFilter3 	  	  	 int,
 	 @rptParmReasonFilter4 	  	  	 int,
 	 @rptParmShowTopNBars 	  	  	 int,
 	 @rptParmShiftFilter 	  	  	  	 varchar(10),
 	 -- Other
 	 @rsSlices 	  	  	  	  	  	 int,
 	 @SQL1 	  	  	  	  	  	  	 varchar(4000),
 	 @Level1Name 	  	  	  	  	  	 varchar(100),
 	 @Level2Name 	  	  	  	  	  	 varchar(100),
 	 @Level3Name 	  	  	  	  	  	 varchar(100),
 	 @Level4Name 	  	  	  	  	  	 varchar(100),
 	 @CurrentDateTime 	  	  	  	 datetime,
-- 	 @Level1Counts 	  	  	  	  	 int,
-- 	 @Level2Counts 	  	  	  	  	 int,
-- 	 @Level3Counts 	  	  	  	  	 int,
-- 	 @Level4Counts 	  	  	  	  	 int,
 	 -- Tables
 	 @ProductionStartsTableId 	  	 int,
 	 @CrewScheduleTableId 	  	  	 int,
 	 @ProductionDaysTableId 	  	  	 int,
 	 @ProductionPlanStartsTableId 	 int,
 	 @NonProductiveTableId 	  	  	 int,
 	 @DowntimeSpecsTableId 	  	  	 int,
 	 @ProductionSpecsTableId 	  	  	 int,
 	 @WasteSpecsTableId 	  	  	  	 int,
 	 @TimedEventDetailsTableId 	  	 int,
 	 @NPCategoryId 	  	  	  	  	 int
--*****************************************************/
--Build List Of Production units
--*****************************************************/
CREATE TABLE #Units ( 	 UnitId 	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 PLDesc 	 varchar(50) NULL, 
 	  	  	  	  	  	 PLId 	 int NULL,
 	  	  	  	  	  	 PUDesc 	 varchar(50) NULL,
 	  	  	  	  	  	 PUId 	 int,
 	  	  	  	  	  	 TreeId 	 int,
 	  	  	  	  	  	 Level1Name varchar(100) NULL,
 	  	  	  	  	  	 Level2Name varchar(100) NULL,
 	  	  	  	  	  	 Level3Name varchar(100) NULL,
 	  	  	  	  	  	 Level4Name varchar(100) NULL,
 	  	  	  	  	  	 NPId 	 int
 	  	  	  	  	 )
CREATE NONCLUSTERED INDEX UNCIXTreeId ON #Units (TreeId)
--*****************************************************/
-- The goal is to build a table with all the start times and then
-- at the end we'll fill in the end times.
CREATE TABLE #Periods ( 	 PeriodId 	  	  	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 TableId 	  	  	  	 int,
 	  	  	  	  	  	 PUId 	  	  	  	 int,
 	  	  	  	  	  	 KeyId 	  	  	  	 int)
CREATE CLUSTERED INDEX PCIX ON #Periods (TableId, StartTime, KeyId)
DECLARE @ProductionDays TABLE ( 	 DayId 	  	  	 int IDENTITY(1,1),
 	  	  	  	  	  	  	  	 StartTime 	  	 datetime PRIMARY KEY,
 	  	  	  	  	  	  	  	 EndTime 	  	  	 datetime,
 	  	  	  	  	  	  	  	 ProductionDay 	 datetime)
DECLARE @FaultFilterIds TABLE  (PUId 	 int,
 	  	  	  	  	  	  	  	 FaultId 	 int)
CREATE TABLE #ProductOperatingTime (ProdId 	  	 int,
 	  	  	  	  	  	  	  	  	 TotalTime 	 int)
CREATE TABLE #Slices ( 	 SliceId 	  	  	  	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime DEFAULT NULL,
 	  	  	  	  	  	 PUId 	  	  	  	 int,
 	  	  	  	  	  	 ProdId 	  	  	  	 int,
 	  	  	  	  	  	 Shift 	  	  	  	 varchar(10),
 	  	  	  	  	  	 Crew 	  	  	  	 varchar(10),
 	  	  	  	  	  	 ProductionDay 	  	 datetime,
 	  	  	  	  	  	 NP 	  	  	  	  	 bit DEFAULT 0,
 	  	  	  	  	  	 -- Statistics
 	  	  	  	  	  	 CalendarTime 	  	 Float DEFAULT 0)
CREATE CLUSTERED INDEX SCIX ON #Slices (PUId, NP, StartTime)
CREATE TABLE #SliceDetails( 	 SliceDetailId 	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime NULL,
 	  	  	  	  	  	 PUId 	  	  	  	 int,
 	  	  	  	  	  	 ProdId 	  	  	  	 int NULL,
 	  	  	  	  	  	 TEDetId 	  	  	  	 int NULL,
 	  	  	  	  	  	 Shift 	  	  	  	 varchar(10) NULL,
 	  	  	  	  	  	 Crew 	  	  	  	 varchar(10) NULL,
 	  	  	  	  	  	 ProductionDay 	  	 datetime,
 	  	  	  	  	  	 NP 	  	  	  	  	 bit DEFAULT 0,
 	  	  	  	  	  	 LocationId 	  	  	 int NULL,
 	  	  	  	  	  	 Reason1  	  	  	 int NULL,
 	  	  	  	  	  	 Reason2  	  	  	 int NULL,
 	  	  	  	  	  	 Reason3  	  	  	 int NULL,
 	  	  	  	  	  	 Reason4  	  	  	 int NULL,
 	  	  	  	  	  	 Duration  	  	  	 Float NULL,
 	  	  	  	  	  	 TimeToRepair  	  	 Float NULL,
 	  	  	  	  	  	 TimePreviousFailure Float NULL,
 	  	  	  	  	  	 FaultId  	  	  	 int NULL,
 	  	  	  	  	  	 FaultName 	  	  	 varchar(100) NULL
 	  	  	  	  	  	 )
CREATE CLUSTERED INDEX SDCIX ON #SliceDetails(PUId, NP,StartTime)
---23/08/2010 - Conversion of datetime into UTC e.g. India Standard Time','Central Stardard Time'
 	 SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
 	 SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
/********************************************************************
* 	  	  	  	  	  	  	 Report Input Parameters 	  	  	  	  	 *
********************************************************************/
--- !!!!!!!!!!!!! SET DEFAULT VALUE OF DEBUG TO 0 !!!!!!!!!!!!!!!!!!!
SET @Debug = 0--- CHANGE IF REQUIRED TO DEBUG.
IF @Debug = 1 
 	 BEGIN
 	  	 -- Modify @rptParmStartTime, @rptParmEndTime and @ReportPUId
 	  	 -- appropriately.
 	  	 SELECT  	 @UnitList 	  	  	  	 = NULL,
 	  	  	  	 @rptParmStartTime 	  	 = '2008-05-01 07:00:00', 
 	  	  	  	 @rptParmEndTime 	  	  	 = '2008-06-01 07:00:00',
 	  	  	  	 @rptParmfilterNPT 	  	 = 0,
 	  	  	  	 @rptParmProductFilter 	 = NULL,
 	  	  	  	 @rptParmCrewFilter 	  	 = NULL,
 	  	  	  	 @rptParmLocationFilter 	 = NULL,
 	  	  	  	 @rptParmFaultFilter 	  	 = NULL,
 	  	  	  	 @rptParmReasonFilter1 	 = NULL,
 	  	  	  	 @rptParmReasonFilter2 	 = NULL,
 	  	  	  	 @rptParmReasonFilter3 	 = NULL,
 	  	  	  	 @rptParmReasonFilter4 	 = NULL,
 	  	  	  	 @rptParmShowTopNBars 	 = 20,
 	  	  	  	 @rptParmShiftFilter 	  	 = NULL
 	  	 SELECT  	 @rsSlices 	  	  	  	 = 1
 	 END
ELSE
 	 BEGIN
 	  	 SELECT
 	  	  	  	 @rptParmStartTime 	  	 = @StartTime, 
 	  	  	  	 @rptParmEndTime 	  	  	 = @EndTime,
 	  	  	  	 @rptParmfilterNPT 	  	 = @FilterNonProductiveTime,
 	  	  	  	 @rptParmProductFilter 	 = @ProductFilter,
 	  	  	  	 @rptParmCrewFilter 	  	 = @CrewFilter,
 	  	  	  	 @rptParmLocationFilter 	 = @LocationFilter,
 	  	  	  	 @rptParmFaultFilter 	  	 = @FaultFilter,
 	  	  	  	 @rptParmReasonFilter1 	 = @ReasonFilter1,
 	  	  	  	 @rptParmReasonFilter2 	 = @ReasonFilter2,
 	  	  	  	 @rptParmReasonFilter3 	 = @ReasonFilter3,
 	  	  	  	 @rptParmReasonFilter4 	 = @ReasonFilter4,
 	  	  	  	 @rptParmShowTopNBars 	 = @ShowTopNBars,
 	  	  	  	 @rptParmShiftFilter 	  	 = @ShiftFilter
 	  	 SELECT  	 @rsSlices 	  	  	  	 = 0
 	 END
IF (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
 	 BEGIN
 	  	 IF (not @UnitList like '%<Root>%')
 	  	  	 BEGIN
 	  	  	  	 SELECT @UnitText = N'Item;' + convert(nvarchar(4000), @UnitList)
 	  	  	  	 INSERT INTO #Units (PUId) EXECUTE spDBR_Prepare_Table @UnitText
 	  	  	 END
 	  	 ELSE
 	  	  	 BEGIN
 	  	  	  	 INSERT INTO #Units EXECUTE spDBR_Prepare_Table @UnitList
 	  	  	 END
 	 END
ELSE
 	 BEGIN
 	  	 Insert Into #Units (PUId) 
 	  	 SELECT DISTINCT pu_id From [dbo].Prod_Events WITH (NOLOCK) where event_type = 2     
 	 END
UPDATE u
SET TreeId = pe.Name_Id
FROM #Units u
 	 JOIN [dbo].Prod_Events pe WITH (NOLOCK) ON pe.PU_Id = u.PUId AND pe.Event_Type = 2
UPDATE u
SET Level1Name = erlh.Level_Name
FROM #Units u
 	 JOIN [dbo].Event_Reason_Level_Headers erlh WITH (NOLOCK) ON erlh.Tree_Name_Id = u.TreeId
 	 WHERE erlh.Reason_Level = 1 
UPDATE u
SET Level2Name = erlh.Level_Name
FROM #Units u
 	 JOIN [dbo].Event_Reason_Level_Headers erlh WITH (NOLOCK) ON erlh.Tree_Name_Id = u.TreeId
 	 WHERE erlh.Reason_Level = 2 
UPDATE u
SET Level3Name = erlh.Level_Name
FROM #Units u
 	 JOIN [dbo].Event_Reason_Level_Headers erlh WITH (NOLOCK) ON erlh.Tree_Name_Id = u.TreeId
 	 WHERE erlh.Reason_Level = 3 
UPDATE u
SET Level4Name = erlh.Level_Name
FROM #Units u
 	 JOIN [dbo].Event_Reason_Level_Headers erlh WITH (NOLOCK) ON erlh.Tree_Name_Id = u.TreeId
 	 WHERE erlh.Reason_Level = 4 
UPDATE u SET NPId = Non_Productive_Category
FROM #Units u
 	  	 JOIN [dbo].prod_units pu WITH (NOLOCK) ON pu.PU_Id = u.PUId
 	  	  	  	 
/********************************************************************
* 	  	  	  	  	  	  	 Initialization 	  	  	  	  	  	  	 *
********************************************************************/
SELECT 	 -- Table Ids
 	  	 @ProductionStartsTableId 	  	 = 2,
 	  	 @TimedEventDetailsTableId 	  	 = 3,
 	  	 @CrewScheduleTableId 	  	  	 = -1,
 	  	 @ProductionDaysTableId 	  	  	 = -2,
 	  	 @NonProductiveTableId 	  	  	 = -3
/********************************************************************
* 	  	  	  	  	  	  	 Product Changes 	  	  	  	  	  	  	 *
********************************************************************/
-- Production starts always has to be contiguous so it's the best place to start
INSERT INTO #Periods ( 	 TableId,
 	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	 PUId,
 	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	 EndTime)
SELECT 	 @ProductionStartsTableId,
 	  	 Start_Id,
 	  	 PU_Id,
 	  	 CASE 	 WHEN Start_Time < @rptParmStartTime THEN @rptParmStartTime
 	  	  	  	 ELSE Start_Time
 	  	  	  	 END,
 	  	 CASE  	 WHEN End_Time > @rptParmEndTime OR End_Time IS NULL THEN @rptParmEndTime
 	  	  	  	 ELSE End_Time
 	  	  	  	 END 	  	 
FROM [dbo].Production_Starts WITH (NOLOCK)
WHERE 	 PU_ID IN (SELECT DISTINCT(PUId) FROM #Units)
 	  	 AND Start_Time < @rptParmEndTime
 	  	 AND (End_Time > @rptParmStartTime OR End_Time IS NULL)
/********************************************************************
* 	  	  	  	  	  	  	 Crew Schedule 	  	  	  	  	  	  	 *
********************************************************************/
-- Add records for all crew starts
INSERT INTO #Periods ( 	 TableId,
 	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	 PUId,
 	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	 EndTime)
SELECT 	 @CrewScheduleTableId,
 	  	 cs.CS_Id,
 	  	 cs.PU_Id,
 	  	 StartTime 	 = CASE 	 WHEN cs.Start_Time < @rptParmStartTime THEN @rptParmStartTime
 	  	  	  	  	  	  	 ELSE cs.Start_Time
 	  	  	  	  	  	  	 END,
 	  	 EndTime 	  	 = CASE 	 WHEN cs.End_Time > @rptParmEndTime THEN @rptParmEndTime
 	  	  	  	  	  	  	 ELSE cs.End_Time
 	  	  	  	  	  	  	 END
FROM [dbo].Crew_Schedule cs WITH (NOLOCK)
WHERE 	 PU_ID IN (SELECT DISTINCT(PUId) FROM #Units)
 	  	 AND End_Time > @rptParmStartTime
 	  	 AND Start_Time < @rptParmEndTime
/********************************************************************
* 	  	  	  	  	  	 Production Day 	  	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO @ProductionDays ( 	 StartTime,
 	  	  	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	  	  	 ProductionDay)
SELECT 	 StartTime,
 	  	 EndTime,
 	  	 ProductionDay
FROM [dbo].fnGEPSGetProductionDays( 	 @rptParmStartTime,
 	  	  	  	  	  	  	  	  	 @rptParmEndTime)
DECLARE 
 	 @LoopCount int,
 	 @PUId 	 int
SELECT @LoopCount = 1 
WHILE (SELECT max(UnitId) FROM #Units) >= @LoopCount
 	 BEGIN
 	  	 SELECT @PUId = PUId 
 	  	  	 FROM #Units 
 	  	  	 WHERE UnitId = @LoopCount
 	  	 INSERT INTO #Periods ( 	 TableId,
 	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	 PUId,
 	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	 EndTime)
 	  	 SELECT 	 @ProductionDaysTableId,
 	  	  	 DayId,
 	  	  	 @PUId,
 	  	  	 StartTime,
 	  	  	 EndTime
 	  	 FROM @ProductionDays
 	  	 SELECT @LoopCount = @LoopCount + 1
 	 END
/********************************************************************
* 	  	  	  	  	  	 Non-Productive Time 	  	  	  	  	  	  	 *
********************************************************************/
IF @rptParmfilterNPT = 1 
 	 BEGIN
 	  	 INSERT INTO #Periods ( 	 TableId,
 	  	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	  	 PUId,
 	  	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	  	 EndTime)
 	  	 SELECT 	 @NonProductiveTableId,
 	  	  	  	 np.NPDet_Id,
 	  	  	  	 np.PU_Id,
 	  	  	  	 StartTime 	 = CASE 	 WHEN np.Start_Time < @rptParmStartTime THEN @rptParmStartTime
 	  	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	  	 END,
 	  	  	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > @rptParmEndTime THEN @rptParmEndTime
 	  	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	  	 END
 	  	 FROM [dbo].NonProductive_Detail np WITH (NOLOCK)
 	  	  	 JOIN [dbo].Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	 JOIN #Units u ON ercd.ERC_Id = u.NPId
 	  	 WHERE PU_ID IN (SELECT DISTINCT(PU_Id) FROM #Units)
 	  	  	  	 AND np.Start_Time < @rptParmEndTime
 	  	  	  	 AND np.End_Time > @rptParmStartTime
 	 END
/********************************************************************
* 	  	  	  	  	  	  	 Gaps 	  	  	  	  	  	  	  	  	 *
********************************************************************/
-- Insert gaps
INSERT INTO #Periods ( 	 StartTime,
 	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	 TableId,
 	  	  	  	  	  	 PUId)
SELECT 	 p1.EndTime,
 	  	 @rptParmEndTime,
 	  	 p1.TableId,
 	  	 p1.PUId
FROM #Periods p1
 	 LEFT JOIN #Periods p2 ON 	 p1.TableId = p2.TableId
 	  	  	  	  	  	  	  	 AND p1.EndTime = p2.StartTime
 	  	  	  	  	  	  	  	 AND p1.PUId = p2.PUId
WHERE 	 p1.EndTime < @rptParmEndTime
 	  	 AND p2.PeriodId IS NULL
/********************************************************************
* 	  	  	  	  	  	  	 Slices 	  	  	  	  	  	  	  	  	 *
********************************************************************/
-- Create slices
INSERT INTO #Slices ( 	 PUId,
 	  	  	  	  	  	 StartTime)
SELECT 	 DISTINCT PUId,
 	  	 StartTime
FROM #Periods
WHERE PUId > 0
ORDER BY PUId, StartTime ASC
SELECT @Rows = @@rowcount
-- Correct the end times
UPDATE s1
SET s1.EndTime 	  	 = s2.StartTime,
 	 s1.CalendarTime 	 = datediff(s, s1.StartTime, s2.StartTime)
FROM #Slices s1
 	 JOIN #Slices s2 ON s2.SliceId = s1.SliceId + 1
WHERE s2.PUId = s1.PUId AND s1.SliceId < @Rows
UPDATE #Slices
SET EndTime  	  	 = @rptParmEndTime,
 	 CalendarTime 	 = datediff(s, StartTime, @rptParmEndTime)
WHERE SliceId = @Rows OR EndTime IS NULL
-- Update each slice with the relative table information
UPDATE s
SET 	 ProdId 	 = ps.Prod_Id
FROM #Slices s
 	 LEFT JOIN #Periods p ON p.TableId = @ProductionStartsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN [dbo].Production_Starts ps WITH (NOLOCK) ON p.KeyId = ps.Start_Id 
WHERE 	 p.KeyId IS NOT NULL AND s.PUId = ps.PU_Id
UPDATE s
SET Crew 	 = cs.Crew_Desc,
 	 Shift 	 = cs.Shift_Desc
FROM #Slices s
 	 LEFT JOIN #Periods p ON p.TableId = @CrewScheduleTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN [dbo].Crew_Schedule cs WITH (NOLOCK) ON p.KeyId = cs.CS_Id 
WHERE p.KeyId IS NOT NULL AND s.PUId = cs.PU_Id
UPDATE s
SET ProductionDay 	 = pd.ProductionDay
FROM #Slices s
 	 LEFT JOIN #Periods p ON p.TableId = @ProductionDaysTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN @ProductionDays pd ON p.KeyId = pd.DayId 
WHERE p.KeyId IS NOT NULL 
UPDATE s
SET NP = 1
FROM #Slices s
 	 LEFT JOIN #Periods p ON p.TableId = @NonProductiveTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
WHERE p.KeyId IS NOT NULL
-- Obtain FaultIds corresponding to @rptParmFaultFilter
IF @rptParmFaultFilter IS NOT NULL
 	 BEGIN
 	  	 INSERT INTO @FaultFilterIds (PUId,FaultId)
 	  	  	 SELECT 	 u.PUId,
 	  	  	  	  	 isnull(tef.TEFault_Id,0)
 	  	  	 FROM 	 [dbo].Timed_Event_Fault tef
 	  	  	  	 JOIN #Units u ON tef.PU_Id = u.PUId
 	  	  	 WHERE TEFault_Name = @rptParmFaultFilter 	  	 
 	 END
INSERT INTO  #ProductOperatingTime 	 (
 	 ProdId,
 	 TotalTime )
 	 SELECT
 	  	 ProdId,
 	  	 sum(CalendarTime)
 	  	 FROM #Slices
 	  	 WHERE NP = 0
 	  	 GROUP BY ProdId
SELECT @CurrentDateTime =dbo.fnServer_CmnGetDate(getutcdate())
/********************************************************************
* 	  	  	  	  	  	  	 Downtime 	  	  	  	  	  	  	  	 *
********************************************************************/
--/*
INSERT INTO #SliceDetails (
 	 StartTime,
 	 EndTime,
 	 PUId,
 	 ProdId,
 	 TEDETId,
 	 Shift,
 	 Crew,
 	 ProductionDay,
 	 NP,
 	 LocationId,
 	 Reason1,
 	 Reason2,
 	 Reason3,
 	 Reason4,
 	 Duration,
 	 TimeToRepair,
 	 TimePreviousFailure,
 	 FaultId 
 	 )
SELECT
 	 CASE WHEN ted.Start_Time < @rptParmStartTime THEN @rptParmStartTime ELSE ted.Start_Time END,
 	 CASE WHEN ted.End_Time > @rptParmEndTime THEN @rptParmEndTime ELSE isnull(ted.End_Time, @CurrentDateTime) END,
 	 ted.PU_Id,
 	 NULL,
 	 ted.TEDet_Id,
 	 NULL,
 	 NULL,
 	 NULL,
 	 NULL,
 	 isnull(ted.Source_PU_Id,ted.PU_Id),
 	 ted.Reason_Level1,
 	 ted.Reason_Level2, 	  	  	 
 	 ted.Reason_Level3,
 	 ted.Reason_Level4, 	 
 	 datediff(second, CASE WHEN ted.Start_Time < @rptParmStartTime THEN @rptParmStartTime ELSE ted.Start_Time END, 
 	  	  	  	  	  CASE WHEN ted.End_Time > @rptParmEndTime THEN @rptParmEndTime ELSE isnull(ted.End_Time, @rptParmEndTime) END) / 60.0,
 	 Null,
 	 CASE WHEN ted.Start_Time <  @rptParmStartTime THEN NULL
 	  	  WHEN ted.Uptime <= 0 THEN NULL ELSE ted.Uptime End,
 	 ted.TEFault_Id
 	 FROM [dbo].Timed_Event_Details ted WITH (NOLOCK) 
 	  	 WHERE ted.PU_Id IN (SELECT distinct(PUId) FROM #Units) 
 	  	 AND (ted.Start_Time < @rptParmEndTime) AND (ted.End_Time > @rptParmStartTime OR ted.End_Time IS NULL)
 	  	 AND (@rptParmLocationFilter IS NULL OR ted.Source_PU_Id  = @rptParmLocationFilter)
 	  	 AND (@rptParmReasonFilter1 IS NULL OR ted.Reason_Level1 = @rptParmReasonFilter1)
 	  	 AND (@rptParmReasonFilter2 IS NULL OR ted.Reason_Level2 = @rptParmReasonFilter2)
 	  	 AND (@rptParmReasonFilter3 IS NULL OR ted.Reason_Level3 = @rptParmReasonFilter3)
 	  	 AND (@rptParmReasonFilter4 IS NULL OR ted.Reason_Level4 = @rptParmReasonFilter4)
 	  	 AND (@rptParmFaultFilter IS NULL OR (ted.TEFault_Id IS NULL OR ted.TEFault_Id IN (SELECT FaultId FROM @FaultFilterIds)))
-- Update Slice Details : Fault Name
UPDATE sd
SET FaultName = CASE WHEN tef.TEFault_Id IS NULL then [dbo].fnDBTranslate(N'0', 38333, 'Unspecified') ELSE tef.TEFault_Name END 
FROM #SliceDetails sd
   LEFT OUTER JOIN [dbo].Timed_Event_Fault tef WITH (NOLOCK) on tef.TEFault_Id = sd.FaultId 
-- Update Slice Details : Product, Crew, Shift, NP, ProductionDay
UPDATE sd
 	 SET ProdId 	  	  	 = s.ProdId,
 	  	 Crew 	  	  	 = s.Crew,
 	  	 Shift 	  	  	 = s.Shift,
 	  	 --NP 	  	  	  	 = s.NP,
 	  	 ProductionDay 	 = s.ProductionDay
 	 FROM #SliceDetails sd, #Slices s
 	 WHERE sd.PUID = s.PUId AND sd.StartTime > s.StartTime AND sd.StartTime <= s.EndTime
IF @FilterNonProductiveTime = 1 
BEGIN
 	 -- End Time is between NPT
 	 Update sd
 	 SET sd.EndTime = s.StartTime,Duration = datediff(second,s.StartTime,sd.EndTime) /  60.0
 	 FROM #SliceDetails sd , #Slices s 
 	 WHERE s.NP=1 and sd.EndTime between s.StartTime and s.EndTime and sd.StartTime < s.StartTime and s.PUId = sd.PUId
 	 -- Start Time is between NPT
 	 Update sd
 	 SET sd.StartTime = s.EndTime,Duration = datediff(second,sd.StartTime,s.EndTime) /  60.0 
 	 FROM #SliceDetails sd , #Slices s 
 	 WHERE s.NP=1 and sd.StartTime between s.StartTime and s.EndTime and sd.EndTime > s.EndTime and s.PUId = sd.PUId
 	 
 	 -- Both times are between NPT
 	 Update sd
 	 SET sd.NP = 1
 	 FROM #SliceDetails sd, #Slices s
 	 WHERE sd.StartTime between s.StartTime and s.EndTime AND sd.EndTime between s.StartTime and s.EndTime and sd.PUId = s.PUId and s.NP=1
 	 --Duration is between NPT
 	 Delete  FROM #SliceDetails Where NP=1 
 	 -- NPT Within a Downtime
 	 Declare  @DetailsToSplit Table(id Int Identity(1,1),SliceDetailId Int,StartTime DateTime,EndTime DateTime)
 	 DECLARE @End Int, @Start Int,@CurrentDetail Int,@Duration Float
 	 DECLARE @SplitStart DateTime, @SplitEnd DateTime
 	 SET @Start = 1
 	 Insert Into @DetailsToSplit(SliceDetailId,StartTime,EndTime)
 	  	 SELECT sd.SliceDetailId,s.StartTime,s.EndTime
 	  	  	 From #SliceDetails sd
 	  	  	 Join #Slices s on s.StartTime > sd.StartTime and s.EndTime < sd.EndTime and s.NP=1 and s.PUId = sd.PUId
 	 SET @End = @@ROWCOUNT
 	 While @Start <= @End
 	 BEGIN
 	  	 SET @CurrentDetail = Null
 	  	 SET @SplitStart = Null
 	  	 SET @SplitEnd = Null
 	  	 SELECT @CurrentDetail = SliceDetailId,@SplitStart = StartTime,@SplitEnd = EndTime
 	  	   FROM @DetailsToSplit 
 	  	   WHERE id = @Start
 	  	 SELECT @Duration = (datediff(second,StartTime,@SplitStart) + datediff(second,@SplitEnd,EndTime)) /  60.0
 	  	  	  	 FROM #SliceDetails 
 	  	  	  	 WHERE SliceDetailId = @CurrentDetail
 	  	 Update #SliceDetails Set Duration = @Duration WHERE SliceDetailId = @CurrentDetail
 	  	 SET @Start = @Start + 1
 	 END
END 
/********************************************************************
* 	  	  	  	  	  	  	 EXCLUSIONS 	  	  	  	  	  	  	  	 *
********************************************************************/
IF @rptParmCrewFilter IS NOT NULL
 	 BEGIN
 	  	 DELETE FROM #SliceDetails WHERE Crew <> @rptParmCrewFilter
 	 END
IF @rptParmShiftFilter IS NOT NULL
 	 BEGIN
 	  	 DELETE FROM #SliceDetails WHERE Shift <> @rptParmShiftFilter
 	 END
IF @rptParmProductFilter IS NOT NULL
 	 BEGIN
 	  	 DELETE FROM #SliceDetails WHERE ProdId <> @rptParmProductFilter
 	 END
--SELECT * FROM #Periods
DECLARE @DefaultDesc varchar(20)
SELECT 	 @DefaultDesc = '<Unknown>'
/*******************************************************************************
* 	  	  	  	  	 Resultset #0 - Slices, Slice Details 	  	  	  	  	    *
*******************************************************************************/
--SET @rsSlices = 1
IF @rsSlices = 1 
 	 BEGIN
 	 --Sangeeta
 	 ---23/08/2010 - Update datetime formate in UTC into #Periods table
 	 Update #SliceDetails Set StartTime = dbo.fnServer_CmnConvertFromDBTime(StartTime,@InTimeZone),
 	  	  	  	  	  	  	  EndTime = dbo.fnServer_CmnConvertFromDBTime(EndTime,@InTimeZone)
 	  	  	  	  	  	  	  
 	 Update #Slices Set StartTime = dbo.fnServer_CmnConvertFromDBTime(StartTime,@InTimeZone),
 	  	  	  	  	    EndTime = dbo.fnServer_CmnConvertFromDBTime(EndTime,@InTimeZone) 	  	  	  	  	  	  	  
 	 
 	  	 SELECT 
 	  	  	 StartTime,
 	  	  	 EndTime,
 	  	  	 PUId,
 	  	  	 ProdId,
 	  	  	 TEDetId,
 	  	  	 Shift,
 	  	  	 Crew,
 	  	  	 ProductionDay,
 	  	  	 NP,
 	  	  	 LocationId,
 	  	  	 Reason1,
 	  	  	 Reason2,
 	  	  	 Reason3,
 	  	  	 Reason4,
 	  	  	 Duration,
 	  	  	 TimeToRepair,
 	  	  	 TimePreviousFailure,
 	  	  	 FaultId,
 	  	  	 FaultName
 	  	 FROM #SliceDetails 
 	  	  	 ORDER BY PUId, StartTime
 	  	 SELECT 
 	  	  	 StartTime,
 	  	  	 EndTime,
 	  	  	 PUId,
 	  	  	 ProdId,
 	  	  	 Shift,
 	  	  	 Crew,
 	  	  	 ProductionDay,
 	  	  	 NP,
 	  	  	 -- Statistics
 	  	  	 CalendarTime
 	  	 FROM #Slices
 	  	  	 ORDER BY PUId, StartTime
  	 END
/*******************************************************************************
* 	  	  	  	  	 Resultset #1 - Resultset Name List 	  	  	  	  	  	    *
*******************************************************************************/
SELECT TOP 1 @Level1Name = Level1Name FROM #Units WHERE Level1Name IS NOT NULL 
SELECT TOP 1 @Level2Name = Level2Name FROM #Units WHERE Level2Name IS NOT NULL
SELECT TOP 1 @Level3Name = Level3Name FROM #Units WHERE Level3Name IS NOT NULL
SELECT TOP 1 @Level4Name = Level4Name FROM #Units WHERE Level4Name IS NOT NULL
--SELECT 	 @Level1Counts = count(distinct(TEDETId)) FROM #SliceDetails WHERE Reason1 IS NOT NULL
--SELECT 	 @Level2Counts = count(distinct(TEDETId)) FROM #SliceDetails WHERE Reason2 IS NOT NULL
--SELECT 	 @Level3Counts = count(distinct(TEDETId)) FROM #SliceDetails WHERE Reason3 IS NOT NULL
--SELECT 	 @Level4Counts = count(distinct(TEDETId)) FROM #SliceDetails WHERE Reason4 IS NOT NULL
CREATE TABLE #Resultsets (
  ResultSetName 	  	 varchar(50),
  ResultSetTabName 	 varchar(50),
  ParameterName 	  	 varchar(50),
  ParameterUnits 	 varchar(50) NULL,
  DataColumns 	  	 varchar(50) NULL,
  LabelColumns 	  	 varchar(50) NULL,
  IconDesc 	  	  	 varchar(1000) NULL,
  RS_ID 	  	  	  	 int
)
INSERT INTO #Resultsets VALUES (null,[dbo].fnDBTranslate(N'0', 38334, 'Downtime Distribution'), 'blue', NULL, NULL, NULL, NULL, NULL)
IF @rptParmLocationFilter Is Null
  INSERT INTO #Resultsets VALUES ('LocationPareto', [dbo].fnDBTranslate(N'0', 38335, 'Location'), '38246', [dbo].fnDBTranslate(N'0', 38339, 'Minutes'), '2','1',NULL,1)
IF @rptParmFaultFilter Is Null
  INSERT INTO #Resultsets VALUES ('FaultPareto', [dbo].fnDBTranslate(N'0', 38336, 'Fault'), '38247', [dbo].fnDBTranslate(N'0', 38339, 'Minutes'), '2','1', NULL, 2)
IF @rptParmReasonFilter1 Is Null and @Level1Name Is Not Null
--IF @rptParmReasonFilter1 Is Null and (@Level1Counts > 0)
  INSERT INTO #Resultsets VALUES ('Reason1Pareto', @Level1Name, '38248', [dbo].fnDBTranslate(N'0', 38339, 'Minutes'), '2','1',NULL,3)
IF @rptParmReasonFilter2 Is Null and @Level2Name Is Not Null
--IF @rptParmReasonFilter1 Is Null and (@Level2Counts > 0)
  INSERT INTO #Resultsets VALUES ('Reason2Pareto', @Level2Name, '38249', [dbo].fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,4)
IF @rptParmReasonFilter3 Is Null and @Level3Name Is Not Null
--IF @rptParmReasonFilter1 Is Null and (@Level3Counts > 0)
  INSERT INTO #Resultsets VALUES ('Reason3Pareto', @Level3Name, '38250', [dbo].fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,5)
IF @rptParmReasonFilter4 Is Null and @Level4Name Is Not Null
--IF @rptParmReasonFilter1 Is Null and (@Level4Counts > 0)
  INSERT INTO #Resultsets VALUES ('Reason4Pareto', @Level4Name, '38251', [dbo].fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,6)
IF @rptParmProductFilter Is Null
  INSERT INTO #Resultsets VALUES ('ProductPareto', [dbo].fnDBTranslate(N'0', 38337, 'Product'), '38244', [dbo].fnDBTranslate(N'0', 38339, 'Minutes'),2,1,NULL, 7)
IF @rptParmCrewFilter Is Null
  INSERT INTO #Resultsets VALUES ('CrewPareto', [dbo].fnDBTranslate(N'0', 38338, 'Crew'), '38245', [dbo].fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,8)
IF @rptParmShiftFilter Is Null
  INSERT INTO #Resultsets VALUES ('ShiftPareto', [dbo].fnDBTranslate(N'0', 38479, 'Shift'), '38506', [dbo].fnDBTranslate(N'0', 38339, 'Minutes'), 2,1,NULL,9)
SELECT * FROM #Resultsets
DROP TABLE #Resultsets
DECLARE @TotalDownTime 	 Float
SELECT @TotalDownTime = 0.0
SELECT @TotalDownTime = @TotalDownTime + coalesce((SELECT sum(Duration) From #SliceDetails),0)
CREATE TABLE #Results (
  Id 	  	  	  	 int NULL,
  Name 	  	  	  	 varchar(100) NULL,
  Total 	  	  	  	 float NULL,
  MTTR 	  	  	  	 float NULL,
  MTBF 	  	  	  	 float NULL,
  PercentTotal 	  	 float NULL,
  NumberOfEvents 	 int NULL)
/*******************************************************************************
* 	  	  	  	  	  	  	  	 Location Pareto 	  	  	  	  	  	  	        *
*******************************************************************************/
IF @rptParmLocationFilter IS NULL
  BEGIN
    TRUNCATE TABLE #Results
    INSERT INTO #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	 SELECT LocationId, sum(Duration), avg(Duration), avg(TimePreviousFailure),sum(Duration) / convert(Float,@TotalDowntime), count(distinct(TEDetId))
 	  	  	 FROM #SliceDetails
 	  	  	 GROUP BY LocationId
 	  	  	 ORDER BY LocationId
    SELECT @SQL1 = 'Select isnull(r.Id, 0) as Id, coalesce(pu.pu_desc,' + '''' + [dbo].fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + [dbo].fnDBTranslate(N'0', 38345, 'Location') + ']'
    SELECT @SQL1 = @SQL1 + ', Total as [' + [dbo].fnDBTranslate(N'0', 38340, 'Total') +'], '
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTTR) as ' + [dbo].fnDBTranslate(N'0', 38341, 'MTTR') + ','
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTBF) as ' + [dbo].fnDBTranslate(N'0', 38342, 'MTBF')  +','  
    SELECT @SQL1 = @SQL1 + 'convert(decimal(10,2),r.PercentTotal*100.0) as [\@' + [dbo].fnDBTranslate(N'0', 38346, '% Fault') + '], r.NumberOfEvents as [' + [dbo].fnDBTranslate(N'0', 38344, '# Events') + '], 1 as RS_ID From #Results r LEFT OUTER JOIN [dbo].Prod_Units pu WITH (NOLOCK) on pu.pu_id = r.Id ORDER BY ' + [dbo].fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    EXEC (@SQL1)
  END
/*******************************************************************************
* 	  	  	  	  	  	  	  	 Fault Pareto 	  	  	  	  	  	  	  	    *
*******************************************************************************/
IF @rptParmFaultFilter IS NULL
  BEGIN
    TRUNCATE TABLE #Results
    INSERT INTO #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	 SELECT FaultName, sum(Duration), avg(Duration), avg(TimePreviousFailure),sum(Duration) / convert(Float,@TotalDowntime), count(distinct(TEDetId))
 	  	  	 FROM  #SliceDetails
 	  	  	 GROUP BY FaultName
    SELECT @SQL1 = 'Select Id = null, coalesce(r.Name,' + '''' + [dbo].fnDBTranslate(N'0', 38333, 'Unspecified') + ''') as [\@' + [dbo].fnDBTranslate(N'0', 38336, 'Fault') + ']'
    SELECT @SQL1 =   @SQL1 + ', Total as [' + [dbo].fnDBTranslate(N'0', 38340, 'Total') +'], '
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTTR) as ' + [dbo].fnDBTranslate(N'0', 38341, 'MTTR') + ','
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTBF) as ' + [dbo].fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
    SELECT @SQL1 = @SQL1 + 'convert(decimal(10,2),r.PercentTotal*100.0) as [\@' + [dbo].fnDBTranslate(N'0', 38346, '% Fault')  + '], r.NumberOfEvents as [' + [dbo].fnDBTranslate(N'0', 38344, '# Events') + '], 2 as RS_ID From #Results r ORDER BY ' + [dbo].fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    EXEC (@SQL1)
  END
/*******************************************************************************
* 	  	  	  	  	  	  	  	 Reason1 Pareto 	  	  	  	  	  	  	  	    *
*******************************************************************************/
IF @rptParmReasonFilter1 IS NULL and @Level1Name IS NOT NULL
  BEGIN
    TRUNCATE TABLE #Results
    INSERT INTO #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	 SELECT Reason1, sum(Duration), avg(Duration), avg(TimePreviousFailure),sum(Duration) / convert(Float,@TotalDowntime),Count(distinct(TEDetId))
 	  	  	 FROM #SliceDetails
 	  	  	 GROUP BY Reason1
    SELECT @SQL1 = 'SELECT isnull(r.Id, 0) as Id, coalesce(er.event_reason_name,' + '''' + [dbo].fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ')  as [\@' + @Level1Name + ']'
    SELECT @SQL1 = @SQL1 + ', Total as [' + [dbo].fnDBTranslate(N'0', 38340, 'Total') +'], '
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTTR) as ' + [dbo].fnDBTranslate(N'0', 38341, 'MTTR') + ','
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTBF) as ' + [dbo].fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
    SELECT @SQL1 = @SQL1 + 'convert(decimal(10,2),r.PercentTotal*100.0) as [\@' + [dbo].fnDBTranslate(N'0', 38346, '% Fault') +  '], r.NumberOfEvents as [' + [dbo].fnDBTranslate(N'0', 38344, '# Events') + '], 3 as RS_ID From #Results r LEFT OUTER JOIN [dbo].Event_Reasons er WITH (NOLOCK) on er.event_reason_id = r.Id ORDER BY ' + [dbo].fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    EXEC (@SQL1)
  END
/*******************************************************************************
* 	  	  	  	  	  	  	  	 Reason2 Pareto 	  	  	  	  	  	  	  	    *
*******************************************************************************/
IF @rptParmReasonFilter2 IS NULL and @Level2Name IS NOT NULL
  BEGIN
    TRUNCATE TABLE #Results
    INSERT INTO #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	 SELECT Reason2, sum(Duration), avg(Duration), avg(TimePreviousFailure),sum(Duration) / convert(Float,@TotalDowntime),Count(distinct(TEDetId))
 	  	  	 FROM #SliceDetails
 	  	  	 GROUP BY Reason2
    SELECT @SQL1 = 'SELECT isnull(r.Id, 0) as Id, coalesce(er.event_reason_name,' + '''' + [dbo].fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ')  as [\@' + @Level2Name + ']'
    SELECT @SQL1 = @SQL1 + ', Total as [' + [dbo].fnDBTranslate(N'0', 38340, 'Total') +'], '
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTTR) as ' + [dbo].fnDBTranslate(N'0', 38341, 'MTTR') + ','
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTBF) as ' + [dbo].fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
    SELECT @SQL1 = @SQL1 + 'convert(decimal(10,2),r.PercentTotal*100.0) as [\@' + [dbo].fnDBTranslate(N'0', 38346, '% Fault') +  '], r.NumberOfEvents as [' + [dbo].fnDBTranslate(N'0', 38344, '# Events') + '], 4 as RS_ID From #Results r LEFT OUTER JOIN [dbo].Event_Reasons er WITH (NOLOCK) on er.event_reason_id = r.Id ORDER BY ' + [dbo].fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    EXEC (@SQL1)
  END
/*******************************************************************************
* 	  	  	  	  	  	  	  	 Reason3 Pareto 	  	  	  	  	  	  	  	    *
*******************************************************************************/
IF @rptParmReasonFilter3 IS NULL and @Level3Name IS NOT NULL
  BEGIN
    TRUNCATE TABLE #Results
    INSERT INTO #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	 SELECT Reason3, sum(Duration), avg(Duration), avg(TimePreviousFailure),sum(Duration) / convert(Float,@TotalDowntime),Count(distinct(TEDetId))
 	  	  	 FROM #SliceDetails
 	  	  	 GROUP BY Reason3
    SELECT @SQL1 = 'SELECT isnull(r.Id, 0) as Id, coalesce(er.event_reason_name,' + '''' + [dbo].fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ')  as [\@' + @Level3Name + ']'
    SELECT @SQL1 = @SQL1 + ', Total as [' + [dbo].fnDBTranslate(N'0', 38340, 'Total') +'], '
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTTR) as ' + [dbo].fnDBTranslate(N'0', 38341, 'MTTR') + ','
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTBF) as ' + [dbo].fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
    SELECT @SQL1 = @SQL1 + 'convert(decimal(10,2),r.PercentTotal*100.0) as [\@' + [dbo].fnDBTranslate(N'0', 38346, '% Fault') +  '], r.NumberOfEvents as [' + [dbo].fnDBTranslate(N'0', 38344, '# Events') + '], 5 as RS_ID From #Results r LEFT OUTER JOIN [dbo].Event_Reasons er WITH (NOLOCK) on er.event_reason_id = r.Id ORDER BY ' + [dbo].fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    EXEC (@SQL1)
  END
/*******************************************************************************
* 	  	  	  	  	  	  	  	 Reason4 Pareto 	  	  	  	  	  	  	  	    *
*******************************************************************************/
IF @rptParmReasonFilter4 IS NULL and @Level4Name IS NOT NULL
  BEGIN
    TRUNCATE TABLE #Results
    INSERT INTO #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	 SELECT Reason4, sum(Duration), avg(Duration), avg(TimePreviousFailure),sum(Duration) / convert(Float,@TotalDowntime),Count(distinct(TEDetId))
 	  	  	 FROM #SliceDetails
 	  	  	 GROUP BY Reason4
    SELECT @SQL1 = 'SELECT isnull(r.Id, 0) as Id, coalesce(er.event_reason_name,' + '''' + [dbo].fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ')  as [\@' + @Level4Name + ']'
    SELECT @SQL1 = @SQL1 + ', Total as [' + [dbo].fnDBTranslate(N'0', 38340, 'Total') +'], '
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTTR) as ' + [dbo].fnDBTranslate(N'0', 38341, 'MTTR') + ','
    SELECT @SQL1 = @SQL1 + '[dbo].fnMinutesToTime(r.MTBF) as ' + [dbo].fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
    SELECT @SQL1 = @SQL1 + 'convert(decimal(10,2),r.PercentTotal*100.0) as [\@' + [dbo].fnDBTranslate(N'0', 38346, '% Fault') +  '], r.NumberOfEvents as [' + [dbo].fnDBTranslate(N'0', 38344, '# Events') + '], 6 as RS_ID From #Results r LEFT OUTER JOIN [dbo].Event_Reasons er on er.event_reason_id = r.Id Order By ' + [dbo].fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    EXEC (@SQL1)
  END
/*******************************************************************************
* 	  	  	  	  	  	  	  	 Product Pareto 	  	  	  	  	  	  	  	    *
*******************************************************************************/
IF @rptParmProductFilter IS NULL
  BEGIN
    TRUNCATE TABLE #Results
    INSERT INTO #Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
 	  	 SELECT ProdId, sum(Duration), Avg(Duration), avg(TimePreviousFailure),  sum(Duration) / convert(Float,@TotalDowntime), Count(distinct(TEDETId))
 	  	  	 FROM #SliceDetails
 	  	  	 GROUP BY ProdId
  	 SELECT @SQL1 = 'Select r.Id as Id, p.prod_code as [\@' + dbo.fnDBTranslate(N'0', 38337, 'Product') + ']'
    SELECT @SQL1 = @SQL1 + ', Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    SELECT @SQL1 = @SQL1 + 'dbo.fnMinutesToTime(r.MTTR) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    SELECT @SQL1 = @SQL1 + 'dbo.fnMinutesToTime(((pot.TotalTime/60.0) - r.Total) / r.NumberOfEvents) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF') 
    SELECT @SQL1 = @SQL1 + ', convert(decimal(10,2),r.Total / (pot.TotalTime/60.0) * 100.0) as [\@% ' + dbo.fnDBTranslate(N'0', 38504, 'Product Fault') + '], ' 
    SELECT @SQL1 = @SQL1 + 'convert(decimal(10,2),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38346, '% Fault') +  '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 7 as RS_ID From #Results r join Products p on p.prod_id = r.Id left outer join #ProductOperatingTime pot on pot.ProdId = r.Id Order By ' + dbo.fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    EXEC (@SQL1)
  END
/*******************************************************************************
* 	  	  	  	  	  	  	  	 Crew Pareto 	  	  	  	  	  	  	  	  	    *
*******************************************************************************/
IF @rptParmCrewFilter IS NULL
  BEGIN
 	 TRUNCATE TABLE #Results
    INSERT INTO #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      SELECT Crew, sum(Duration), avg(Duration), avg(TimePreviousFailure),sum(Duration) / convert(Float,@TotalDowntime), Count(distinct(TEDETId))
        From #SliceDetails
        GROUP BY Crew 
 	  	 ORDER BY Crew 
    SELECT @SQL1 = 'Select Id = null, coalesce(r.name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38338, 'Crew') + ']'
    SELECT @SQL1 = @SQL1 + ', Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    SELECT @SQL1 = @SQL1 + 'dbo.fnMinutesToTime(r.MTTR) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    SELECT @SQL1 = @SQL1 + 'dbo.fnMinutesToTime(r.MTBF) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
 	 SELECT @SQL1 = @SQL1 + 'convert(decimal(10,2),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38346, '% Fault') +  '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 8 as RS_ID From #Results r ORDER BY ' + dbo.fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    EXEC (@SQL1)
  END
/*******************************************************************************
* 	  	  	  	  	  	  	  	 Shift Pareto 	  	  	  	  	  	  	  	    *
*******************************************************************************/
IF @rptParmShiftFilter Is Null
  BEGIN
 	 TRUNCATE TABLE #Results
    INSERT INTO #Results (Name, Total, MTTR, MTBF, PercentTotal, NumberOfEvents)
      SELECT Shift, sum(Duration), avg(Duration), avg(TimePreviousFailure),sum(Duration) / convert(Float,@TotalDowntime), Count(distinct(TEDETId))
        FROM #SliceDetails
        GROUP BY Shift 
 	  	 ORDER BY Shift
    SELECT @SQL1 = 'Select Id = null, coalesce(r.name,' + '''' + dbo.fnDBTranslate(N'0', 38333, 'Unspecified') + '''' + ') as [\@' + dbo.fnDBTranslate(N'0', 38477, 'Shift') + ']'
    SELECT @SQL1 = @SQL1 + ', Total as [' + dbo.fnDBTranslate(N'0', 38340, 'Total') +'], '
    SELECT @SQL1 = @SQL1 + 'dbo.fnMinutesToTime(r.MTTR) as ' + dbo.fnDBTranslate(N'0', 38341, 'MTTR') + ','
    SELECT @SQL1 = @SQL1 + 'dbo.fnMinutesToTime(r.MTBF) as ' + dbo.fnDBTranslate(N'0', 38342, 'MTBF')  +',' 
 	 SELECT @SQL1 = @SQL1 + 'convert(decimal(10,2),r.PercentTotal*100.0) as [\@' + dbo.fnDBTranslate(N'0', 38346, '% Fault') +  '], r.NumberOfEvents as [' + dbo.fnDBTranslate(N'0', 38344, '# Events') + '], 9 as RS_ID From #Results r ORDER BY ' + dbo.fnDBTranslate(N'0', 38340, 'Total') + ' ASC'
    EXEC (@SQL1)
  END
lblEnd:
DROP TABLE #ProductOperatingTime
DROP TABLE #Units
DROP TABLE #SliceDetails
DROP TABLE #Slices
DROP TABLE #Periods 
