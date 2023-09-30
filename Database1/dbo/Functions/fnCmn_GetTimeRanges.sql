/*
Stored Procedure: 	 fnCmn_GetTimeRanges
Author: 	  	  	  	 Matthew Wells (GE)
Date Created: 	  	 2009/03/05
Tab Spacing 	  	  	 4
Description:
=========
This function creates a set of time ranges from passed filters
Change Date 	 Who 	 What
=========== 	 ==== 	 =====
*/
CREATE FUNCTION [dbo].[fnCmn_GetTimeRanges] ( 	 @ReportPUId 	  	  	 int,
 	  	  	  	  	  	  	  	  	  	  	  	 @ReportStartTime 	 datetime,
 	  	  	  	  	  	  	  	  	  	  	  	 @ReportEndTime 	  	 datetime,
 	  	  	  	  	  	  	  	  	  	  	  	 @ProductList 	  	 varchar(1000),
 	  	  	  	  	  	  	  	  	  	  	  	 @ShiftList 	  	  	 varchar(1000),
 	  	  	  	  	  	  	  	  	  	  	  	 @CrewList 	  	  	 varchar(1000),
 	  	  	  	  	  	  	  	  	  	  	  	 @POList 	  	  	  	 varchar(1000),
 	  	  	  	  	  	  	  	  	  	  	  	 @FilterNP 	  	  	 bit)
RETURNS @Ranges TABLE ( 	 StartTime 	  	  	 datetime PRIMARY KEY,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 ProdId 	  	  	  	 int)
AS
BEGIN
/*** TESTING
SELECT 	 @ReportPUId 	  	  	 = 6,
 	  	 @ReportStartTime 	 = '2008-01-01',
 	  	 @ReportEndTime 	  	 = '2009-03-01',
-- 	  	 @ProductList 	  	 = '2,3,4',
-- 	  	 @CrewList 	  	  	 = 'A,B,C,D',
-- 	  	 @ShiftList 	  	  	 = 'Day',
 	  	 @FilterNP 	  	  	 = 0
*/
/********************************************************************
* 	  	  	  	  	  	  	 Declarations 	  	  	  	  	  	  	 *
********************************************************************/
DECLARE 	 -- General
 	  	 @Rows 	  	  	  	  	  	  	 int,
 	  	 @NPCategoryId 	  	  	  	  	 int,
 	  	 @ReferenceTableId 	  	  	  	 int,
 	  	 -- Tables
 	  	 @ProductionStartsTableId 	  	 int,
 	  	 @CrewScheduleTableId 	  	  	 int,
 	  	 @ProductionDaysTableId 	  	  	 int,
 	  	 @ProductionPlanStartsTableId 	 int,
 	  	 @NonProductiveTableId 	  	  	 int
-- Data filter tables
DECLARE @Products TABLE (ProdId int PRIMARY KEY)
DECLARE @Crews TABLE (CrewDesc varchar(25) PRIMARY KEY)
DECLARE @Shifts TABLE (ShiftDesc varchar(25) PRIMARY KEY)
DECLARE @Orders TABLE (PPId int PRIMARY KEY)
-- The goal is to build a table with all the start times and then
-- at the end we'll fill in the end times.
DECLARE @Periods TABLE (PeriodId 	  	  	 int IDENTITY(1,1),
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 TableId 	  	  	  	 int,
 	  	  	  	  	  	 ProdId 	  	  	  	 int,
 	  	  	  	  	  	 PRIMARY KEY (TableId, StartTime))
/********************************************************************
* 	  	  	  	  	  	  	 Initialization 	  	  	  	  	  	  	 *
********************************************************************/
SELECT 	 -- Table Ids
 	  	 @ProductionStartsTableId 	  	 = 2,
 	  	 @CrewScheduleTableId 	  	  	 = -1,
 	  	 @ProductionDaysTableId 	  	  	 = -2,
 	  	 @ProductionPlanStartsTableId 	 = 12,
 	  	 @NonProductiveTableId 	  	  	 = -3
SELECT 	 @NPCategoryId 	 = Non_Productive_Category
FROM dbo.Prod_Units WITH (NOLOCK)
WHERE PU_Id = @ReportPUId
-- Clean arguments
SELECT 	 @ProductList 	 = nullif(ltrim(rtrim(@ProductList)), ''),
 	  	 @CrewList 	  	 = nullif(ltrim(rtrim(@CrewList)), ''),
 	  	 @ShiftList 	  	 = nullif(ltrim(rtrim(@ShiftList)), ''),
 	  	 @POList 	  	  	 = nullif(ltrim(rtrim(@POList)), '')
/******************************************************************************
** 	  	  	  	  	  	  	  	 GET FILTER DATA 	  	  	  	  	  	  	  	  **
******************************************************************************/
-- Products
IF @ProductList IS NOT NULL
 	 BEGIN
 	 INSERT @Products (ProdId)
 	 SELECT Id
 	 FROM dbo.fnCmn_IdListToTable('Products',@ProductList, ',')
 	 END
-- Shifts
IF @ShiftList IS NOT NULL
 	 BEGIN
 	 INSERT @Shifts (ShiftDesc)
 	 SELECT Value
 	 FROM dbo.fnLocal_CmnParseList(@ShiftList, ',')
 	 END
-- Crews
IF @CrewList IS NOT NULL
 	 BEGIN
 	 INSERT @Crews (CrewDesc)
 	 SELECT Value
 	 FROM dbo.fnLocal_CmnParseList(@CrewList, ',')
 	 END
-- Process Orders
IF @POList IS NOT NULL
 	 BEGIN
 	 INSERT @Orders (PPId)
 	 SELECT 	 Id
 	 FROM dbo.fnCmn_IdListToTable('Production_Plan', @POList, ',')
 	 END
/******************************************************************************
** 	  	  	  	  	  	  	  	 PRODUCT CHANGES 	  	  	  	  	  	  	  	  **
******************************************************************************/
-- Production starts always has to be contiguous so it's the best place to start
INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	 ProdId)
SELECT 	 @ProductionStartsTableId,
 	  	 CASE 	 WHEN Start_Time < @ReportStartTime THEN @ReportStartTime
 	  	  	  	 ELSE Start_Time
 	  	  	  	 END,
 	  	 CASE  	 WHEN End_Time > @ReportEndTime OR End_Time IS NULL THEN @ReportEndTime
 	  	  	  	 ELSE End_Time
 	  	  	  	 END,
 	  	 Prod_Id
FROM dbo.Production_Starts WITH (NOLOCK)
WHERE 	 PU_Id = @ReportPUId
 	  	 AND Start_Time < @ReportEndTime
 	  	 AND (End_Time > @ReportStartTime
 	  	  	 OR End_Time IS NULL)
 	  	 AND ( 	 Prod_Id IN (SELECT ProdId
 	  	  	  	  	  	  	 FROM @Products)
 	  	  	  	 OR @ProductList IS NULL)
SELECT @ReferenceTableId = @ProductionStartsTableId
/******************************************************************************
** 	  	  	  	  	  	  	  	 CREW SCHEDULE 	  	  	  	  	  	  	  	  **
******************************************************************************/
IF 	 @CrewList IS NOT NULL
 	 OR @ShiftList IS NOT NULL
 	 BEGIN
 	 -- Add records for all crew/shift starts
 	 INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	  	 ProdId)
 	 SELECT 	 @CrewScheduleTableId,
 	  	  	 StartTime 	 = CASE 	 WHEN cs.Start_Time < p.StartTime THEN p.StartTime
 	  	  	  	  	  	  	  	 ELSE cs.Start_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 EndTime 	  	 = CASE 	 WHEN cs.End_Time > p.EndTime THEN p.EndTime
 	  	  	  	  	  	  	  	 ELSE cs.End_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 p.ProdId
 	 FROM dbo.Crew_Schedule cs WITH (NOLOCK)
 	  	 JOIN @Periods p ON 	 p.TableId = @ReferenceTableId
 	  	  	  	  	  	  	 AND cs.Start_Time < p.EndTime
 	  	  	  	  	  	  	 AND cs.End_Time > p.StartTime
 	 WHERE 	 PU_Id = @ReportPUId
 	  	  	 AND End_Time > @ReportStartTime
 	  	  	 AND Start_Time < @ReportEndTime
 	  	  	 AND ( 	 cs.Crew_Desc IN ( 	 SELECT CrewDesc
 	  	  	  	  	  	  	  	  	  	 FROM @Crews)
 	  	  	  	  	 OR @CrewList IS NULL)
 	  	  	 AND ( 	 cs.Shift_Desc IN ( 	 SELECT ShiftDesc
 	  	  	  	  	  	  	  	  	  	 FROM @Shifts)
 	  	  	  	  	 OR @ShiftList IS NULL)
 	 ORDER BY StartTime
 	 SELECT @ReferenceTableId = @CrewScheduleTableId
 	 END
/******************************************************************************
** 	  	  	  	  	  	  	  	 PROCESS ORDER 	  	  	  	  	  	  	  	  **
******************************************************************************/
IF @POList IS NOT NULL
 	 BEGIN
 	 -- Depends on production point?
 	 INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	  	 ProdId)
 	 SELECT 	 @ProductionPlanStartsTableId,
 	  	  	 StartTime 	 = CASE 	 WHEN pps.Start_Time < p.StartTime THEN p.StartTime
 	  	  	  	  	  	  	  	 ELSE pps.Start_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 EndTime 	  	 = CASE 	 WHEN pps.End_Time > p.EndTime THEN p.EndTime
 	  	  	  	  	  	  	  	 ELSE pps.End_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 p.ProdId
 	 FROM dbo.Production_Plan_Starts pps WITH (NOLOCK)
 	  	 JOIN @Periods p ON 	 p.TableId = @ReferenceTableId
 	  	  	  	  	  	  	 AND pps.Start_Time < p.EndTime
 	  	  	  	  	  	  	 AND pps.End_Time > p.StartTime
 	 WHERE 	 pps.PU_Id = @ReportPUId
 	  	  	 AND pps.Start_Time < @ReportEndTime
 	  	  	 AND pps.End_Time > @ReportStartTime
 	  	  	 AND pps.PP_Id IN ( 	 SELECT PPId
 	  	  	  	  	  	  	  	 FROM @Orders)
 	 
 	 SELECT @ReferenceTableId = @ProductionPlanStartsTableId
 	 END
/******************************************************************************
** 	  	  	  	  	  	  	 NON-PRODUCTIVE TIME 	  	  	  	  	  	  	  	  **
******************************************************************************/
IF @FilterNP = 1
 	 BEGIN
 	 INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	  	 ProdId)
 	 SELECT 	 @NonProductiveTableId,
 	  	  	 StartTime 	 = CASE 	 WHEN np.Start_Time < @ReportStartTime THEN @ReportStartTime
 	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > @ReportEndTime THEN @ReportEndTime
 	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 p.ProdId
 	 FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPCategoryId
 	  	 JOIN @Periods p ON 	 p.TableId = @ReferenceTableId
 	  	  	  	  	  	  	 AND np.Start_Time < p.EndTime
 	  	  	  	  	  	  	 AND np.End_Time > p.StartTime
 	 WHERE 	 PU_Id = @ReportPUId
 	  	  	 AND np.Start_Time < @ReportEndTime
 	  	  	 AND np.End_Time > @ReportStartTime
 	 END
/******************************************************************************
** 	  	  	  	  	  	  	  	 RETURN RESULTS 	  	  	  	  	  	  	  	  **
******************************************************************************/
INSERT @Ranges (StartTime,
 	  	  	  	 EndTime,
 	  	  	  	 ProdId)
SELECT 	 StartTime,
 	  	 EndTime,
 	  	 ProdId
FROM @Periods
WHERE TableId = @ReferenceTableId
RETURN
END
