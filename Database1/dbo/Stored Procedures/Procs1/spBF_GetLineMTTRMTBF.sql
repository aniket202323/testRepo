CREATE PROCEDURE [dbo].[spBF_GetLineMTTRMTBF]
@LineId 	  	  	  	  	  	 int = NULL, -- this param needs to have value to calcualte OEE at line level
@UnitList 	  	  	  	  	 text = NULL,
@StartTime 	  	  	  	  	 datetime,
@EndTime 	  	  	  	  	 datetime,
@FilterNonProductiveTime 	 int = 0,
@InTimeZone 	  	  	  	  	 nVarChar(200) = NULL  ---23/08/2010 - Ex: 'India Standard Time','Central Stardard Time'
,@OEEParameter nvarchar(50)=NULL
AS
/* ##### spBF_GetLineMTTRMTBF #####
Description 	 : Returns data for MTTRMTBF section:  Availability donut in case of classic OEE and for Availability, Performance & Quality donuts in case of Time based OEE
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	 F28159 	  	  	  	  	 Modified procedure to handle time based downtime calculation.
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
2018-05-30 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Exclude Units for which Production event is Inactive
2018-06-07 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255635 	  	  	  	 Changed logic of excluding Units [Production rate specification is not defined and Oee mode not set]
*/
DECLARE @ReasonIDFilter int
If @OEEParameter IS NOT NULL
Begin
 	 If (@OEEParameter = 'Quality')
 	 Begin
 	  	 Set @OEEParameter = 'Quality losses'
 	  	 Select @ReasonIDFilter = Event_Reason_Id from Event_Reasons Where Event_Reason_Name_Local = @OEEParameter
 	 End
 	 Else
 	 Begin
 	  	 Set @OEEParameter = @OEEParameter + ' loss'
 	  	 Select @ReasonIDFilter = Event_Reason_Id from Event_Reasons Where Event_Reason_Name_Local = @OEEParameter
 	 End
End
/********************************************************************
* 	  	  	  	  	  	  	 Declarations 	  	  	  	  	  	  	 *
********************************************************************/
DECLARE 	 -- General
 	 @Rows 	  	  	  	  	  	  	 int,
 	 @ReportPUId 	  	  	  	  	  	 int,
 	 @UnitText 	  	  	  	  	  	 nVarChar(4000),
 	 @Debug 	  	  	  	  	  	  	 int,
 	 -- Report Parameters
 	 @rptParmStartTime 	  	  	  	 datetime,
 	 @rptParmEndTime 	  	  	  	  	 datetime,
 	 @rptParmfilterNPT 	  	  	  	 int,
 	 -- Other
 	 @rsSlices 	  	  	  	  	  	 int,
 	 @SQL1 	  	  	  	  	  	  	 nvarchar(4000),
 	 @Level1Name 	  	  	  	  	  	 nvarchar(100),
 	 @Level2Name 	  	  	  	  	  	 nvarchar(100),
 	 @Level3Name 	  	  	  	  	  	 nvarchar(100),
 	 @Level4Name 	  	  	  	  	  	 nvarchar(100),
 	 @CurrentDateTime 	  	  	  	 datetime,
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
Declare @Results TABLE(
  Id 	  	  	  	 int NULL,
  Name 	  	  	  	 nVarChar(100) NULL,
  Total 	  	  	  	 float NULL,
  MTTR 	  	  	  	 float NULL,
  MTBF 	  	  	  	 float NULL,
  PercentTotal 	  	 float NULL,
  NumberOfEvents 	 int NULL)
--*****************************************************/
--Build List Of Production units
--*****************************************************/
CREATE TABLE #Units ( 	 UnitId 	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 PLDesc 	 nvarchar(50) NULL, 
 	  	  	  	  	  	 PLId 	 int NULL,
 	  	  	  	  	  	 PUDesc 	 nvarchar(50) NULL,
 	  	  	  	  	  	 PUId 	 int,
 	  	  	  	  	  	 TreeId 	 int,
 	  	  	  	  	  	 Level1Name nVarChar(100) NULL,
 	  	  	  	  	  	 Level2Name nVarChar(100) NULL,
 	  	  	  	  	  	 Level3Name nVarChar(100) NULL,
 	  	  	  	  	  	 Level4Name nVarChar(100) NULL,
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
 	  	  	  	  	  	 Shift 	  	  	  	 nvarchar(10),
 	  	  	  	  	  	 Crew 	  	  	  	 nvarchar(10),
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
 	  	  	  	  	  	 Shift 	  	  	  	 nvarchar(10) NULL,
 	  	  	  	  	  	 Crew 	  	  	  	 nvarchar(10) NULL,
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
 	  	  	  	  	  	 FaultName 	  	  	 nVarChar(100) NULL
 	  	  	  	  	  	 ,OEEMode nvarchar(20)
 	  	  	  	  	  	 )
CREATE CLUSTERED INDEX SDCIX ON #SliceDetails(PUId, NP,StartTime)
 DECLARE 	 @LineOEEMode int ,
 	  	  	 @DowntimeUnit int
SELECT @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime,@InTimeZone)
SELECT @EndTime = dbo.fnServer_CmnConvertToDBTime(@EndTime,@InTimeZone)
SELECT 	  	  	 @rptParmStartTime 	  	 = @StartTime, 
 	  	  	  	 @rptParmEndTime 	  	  	 = @EndTime,
 	  	  	  	 @rptParmfilterNPT 	  	 = @FilterNonProductiveTime
SELECT  	  	  	 @rsSlices 	  	  	  	 = 0
IF (@LineId is not null OR @LineId <> 0)
 	 BEGIN
 	 --check the lineoeemode 
 	 SELECT @LineOEEMode = LineOEEMode from dbo.Prod_Lines_Base WHERE pl_id= @LineId
 	 SET @LineOEEMode = NULL----Not handling any line OEE Mode in order to accept all units
 	  	 IF (@LineOEEMode in (4,5)) --this is serail line
 	  	  	 BEGIN
 	  	  	  --get the constraint unit
 	  	  	  SELECT @DowntimeUnit = MIN(a.PU_Id)
 	  	  	  	 FROM Prod_Units_Base a
 	  	  	  	 JOIN Prod_Lines_Base b On b.PL_Id = a.PL_Id
 	  	  	  	 JOIN Table_Fields_Values c ON c.TableId = 43 and a.PU_Id = c.KeyId and c.Table_Field_Id = -92
 	  	  	  	 WHERE a.pl_Id = @LineId 
 	  	  	 Insert Into #Units (PUId) Values (@DowntimeUnit)
 	  	  	 END
 	  	 ELSE 
 	  	  	 BEGIN
 	  	  	 INSERT INTO #Units (PUId) 
 	  	  	 SELECT DISTINCT pu_id From [dbo].Prod_Units_Base WITH (NOLOCK) where pl_id = @LineId
 	  	  	 END
 	 END 	 
ELSE IF (not @UnitList like '%<Root></Root>%' and not @UnitList is NULL)
 	 BEGIN
 	  	 IF (not @UnitList like '%<Root>%')
 	  	  	 BEGIN
 	  	  	  	 SELECT @UnitText = N'Item;' + convert(nVarChar(4000), @UnitList)
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
--Exclude Units
;WITH NotConfiguredUnits As
 	  	 (
 	  	  	 Select 
 	  	  	  	 Pu.Pu_Id from Prod_Units Pu
 	  	  	 Where
 	  	  	  	 Not Exists (Select 1 From Table_Fields_Values Where Table_Field_Id = -91 And TableId = 43 And KeyId = Pu.Pu_Id)
 	  	  	  	 AND Production_Rate_Specification IS NULL
 	  	 )
Delete U 
FROM 
 	 #Units U 
WHERE EXISTS (SELECT 1 FROM NotConfiguredUnits Where PU_Id = U.PUId)
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
 	 SET sd.EndTime = s.StartTime,Duration = datediff(second,sd.StartTime,s.StartTime) /  60.0
 	 FROM #SliceDetails sd , #Slices s 
 	 WHERE s.NP=1 and sd.EndTime between s.StartTime and s.EndTime and sd.StartTime < s.StartTime and s.PUId = sd.PUId
 	 -- Start Time is between NPT
 	 Update sd
 	 SET sd.StartTime = s.EndTime,Duration = datediff(second,s.endTime,sd.EndTime) /  60.0 
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
DECLARE @TotalDownTime 	 Float
SELECT @TotalDownTime = 0.0
SELECT @TotalDownTime = @TotalDownTime + coalesce((SELECT sum(Duration) From #SliceDetails),0)
--<Update OEEMode for all units>
;WITH S As 
(
Select 
       TFV.KeyID UnitId, EDFTV.Field_desc
From 
       Table_Fields TF
       JOIN Table_Fields_Values TFV on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
       Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
       LEFT OUTER Join ED_FieldType_ValidValues EDFTV on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
Where 
       TF.Table_Field_Desc = 'OEE Calculation Type'
)
Update u
SET
 	 u.OEEMode = Isnull(S.Field_desc,'Classic')
From 
 	 #SliceDetails u
 	 Left Outer Join S on S.UnitId = u.PuId
--</Update OEEMode for all units>
    INSERT INTO @Results (Id, Total, MTTR, MTBF, PercentTotal, NumberOfEvents,Name)
 	  	 SELECT LocationId, sum(Duration), avg(Duration), avg(TimePreviousFailure),sum(Duration) / convert(Float,@TotalDowntime), count(distinct(TEDetId)),'Line'
 	  	  	 FROM #SliceDetails u
 	  	  	 Where 
 	  	  	  	 (
 	  	  	  	  	 (@ReasonIDFilter is null AND u.OEEMode <> 'Time Based')
 	  	  	  	  	 OR 
 	  	  	  	  	 (Reason1 = @ReasonIDFilter AND @ReasonIDFilter is not null)
 	  	  	  	  	 or 
 	  	  	  	  	 (@ReasonIDFilter IS NULL and u.OEEMode = 'Time Based' and Reason1 in (Select Event_Reason_Id from Event_Reasons Where Event_Reason_Name_Local in ('Availability Loss'/*,'Performance Loss','Quality Losses'*/)))
 	  	  	  	 ) 	  	 
 	  	  	 GROUP BY LocationId
 	  	  	 ORDER BY LocationId
 	  	  	 
    SELECT Name,sum(Total) AS 'Total',[dbo].fnMinutesToTime(avg(MTTR)) AS 'MTTR',[dbo].fnMinutesToTime(avg(MTBF)) AS 'MTBF',sum(NumberOfEvents) AS '#Events' FROM @Results GROUP BY Name
lblEnd:
DROP TABLE #ProductOperatingTime
DROP TABLE #Units
DROP TABLE #SliceDetails
DROP TABLE #Slices
DROP TABLE #Periods 
