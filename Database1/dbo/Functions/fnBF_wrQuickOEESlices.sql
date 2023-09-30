CREATE FUNCTION [dbo].[fnBF_wrQuickOEESlices](
 	 @PUId                    Int,
 	 @StartTime               datetime = NULL,
 	 @EndTime                 datetime = NULL,
 	 @InTimeZone 	  	  	  	  nvarchar(200) = null,
 	 @FilterNonProductiveTime int = 0,
 	 @ReportType Int = 1,
 	 @IncludeSummary Int = 0
 	 )
/* ##### fnBF_wrQuickOEESlices #####
Description 	 : Returns time slices as per product, crew,shift, order etc  which ever is applicable
Creation Date 	 : if any
Created By 	 : if any
#### Update History ####
DATE 	  	  	  	 Modified By 	  	  	 UserStory/Defect No 	  	  	  	 Comments 	  	 
---- 	  	  	  	 ----------- 	  	  	 ------------------- 	  	  	  	 --------
2018-02-20 	  	  	 Prasad 	  	  	  	 7.0 SP3 	  	  	  	  	  	  	 Added logic to fetch/populate NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL if unit is configured for time based OEE calculation.
2018-05-28 	  	  	 Prasad 	  	  	  	 7.0 SP4 US255630 & US255626 	  	 Passed actual filter for NPT
*/
RETURNS  @Slices TABLE( 	 SliceId 	  	  	  	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 ProdDayProdId 	  	 nvarchar(75) DEFAULT null ,
 	  	  	  	  	  	 ProdIdSubGroupId 	 nvarchar(50) DEFAULT null,
 	  	  	  	  	  	 StartId 	  	  	  	 int DEFAULT null,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 PUId 	  	  	  	 int,
 	  	  	  	  	  	 ProdId 	  	  	  	 int,
 	  	  	  	  	  	 ShiftDesc 	  	  	  	 nvarchar(50),
 	  	  	  	  	  	 CrewDesc 	  	  	  	 nvarchar(50),
 	  	  	  	  	  	 ProductionDay 	  	 datetime,
 	  	  	  	  	  	 PPId 	  	  	  	 int,
 	  	  	  	  	  	 PathId 	  	  	  	 Int,
 	  	  	  	  	  	 EventId 	  	  	  	 int,
 	  	  	  	  	  	 AppliedProdId 	  	 int,
 	  	  	  	  	  	 -- ESignature
 	  	  	  	  	  	 PerformUserId 	  	 int,
 	  	  	  	  	  	 VerifyUserId 	  	 int,
 	  	  	  	  	  	 PerformUserName 	  	 nvarchar(30), 
 	  	  	  	  	  	 VerifyUserName 	  	 nvarchar(30), 
 	  	  	  	  	  	 -- Other
 	  	  	  	  	  	 NP 	  	  	  	  	 bit DEFAULT 0,
 	  	  	  	  	  	 NPLabelRef 	  	  	 bit DEFAULT 0,
 	  	  	  	  	  	 DowntimeTarget 	  	 float,
 	  	  	  	  	  	 ProductionTarget 	 float,
 	  	  	  	  	  	 WasteTarget 	  	  	 float,
 	  	  	  	  	  	 -- Statistics
 	  	  	  	  	  	 CalendarTime 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 AvailableTime 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 LoadingTime 	  	  	 Float DEFAULT 0,
 	  	  	  	  	  	 RunTimeGross 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 ProductiveTime 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimePlanned 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimeExternal 	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimeUnplanned 	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimePerformance 	 Float DEFAULT 0,
 	  	  	  	  	  	 DowntimeTotal 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 ProductionCount 	  	 int DEFAULT 0,
 	  	  	  	  	  	 ProductionTotal 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 ProductionNet 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 ProductionIdeal 	  	 Float DEFAULT 0,
 	  	  	  	  	  	 WasteQuantity 	  	 Float DEFAULT 0
 	  	  	  	  	  	 
 	  	  	  	  	  	 ,NPT Float DEFAULT 0 --NPT for the time slice
 	  	  	  	  	  	 ,DowntimeA Float DEFAULT 0 --Availability downtime for the time slice
 	  	  	  	  	  	 ,DowntimeP Float DEFAULT 0 --Performance downtime for the time slice
 	  	  	  	  	  	 ,DowntimeQ Float DEFAULT 0 --Quality downtime for the time slice
 	  	  	  	  	  	 ,DowntimePL Float DEFAULT 0
 	  	  	  	  	  	 )
AS
BEGIN
/********************************************************************
* 	  	  	  	  	  	  	 Declarations 	  	  	  	  	  	  	 *
********************************************************************/
DECLARE 	 -- General
 	  	 @Rows 	  	  	  	  	  	  	 int,
 	  	 @rptParmOrderSummary 	  	  	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmShiftSummary 	  	  	 int, 	 -- 1 - Summary Selected
 	  	 @rptParmCrewSummary 	  	  	  	 int, 	 -- 1 - Summary Selected
 	  	 -- Tables
 	  	 @EventsTableId 	  	  	  	  	 int,
 	  	 @ProductionStartsTableId 	  	 int,
 	  	 @CrewScheduleTableId 	  	  	 int,
 	  	 @ProductionDaysTableId 	  	  	 int,
 	  	 @ProductionPlanStartsTableId 	 int,
 	  	 @NonProductiveTableId 	  	  	 int,
 	  	 @DowntimeSpecsTableId 	  	  	 int,
 	  	 @ProductionSpecsTableId 	  	  	 int,
 	  	 @WasteSpecsTableId 	  	  	  	 int,
 	  	 -- Unit Configuration
 	  	 @ScheduledCategoryId 	  	  	 int,
 	  	 @ExternalCategoryId 	  	  	  	 int,
 	  	 @DowntimePropId 	  	  	  	  	 int,
 	  	 @DowntimeSpecId 	  	  	  	  	 int,
 	  	 @PerformanceCategoryId 	  	  	 int,
 	  	 @ProductionPropId 	  	  	  	 int,
 	  	 @ProductionSpecId 	  	  	  	 int,
 	  	 @ProductionRateFactor 	  	  	 Float,
 	  	 @ProductionType 	  	  	  	  	 tinyint,
 	  	 @ProductionVarId 	  	  	  	 int,
 	  	 @ProductionStartTime 	  	  	 tinyint,
 	  	 @WastePropId 	  	  	  	  	 int,
 	  	 @WasteSpecId 	  	  	  	  	 int,
 	  	 @NPCategoryId 	  	  	  	  	 int,
 	  	 @EfficiencySpecId 	  	  	  	 int
 	  	 
IF @ReportType = 2 SET  	 @rptParmShiftSummary = 1 ELSE SET @rptParmShiftSummary = 0
IF @ReportType = 3 SET  	 @rptParmCrewSummary = 1 ELSE SET @rptParmCrewSummary = 0
 	 Declare @OEEType nvarchar(10)
 	 Select 
 	  	 @OEEType = EDFTV.Field_desc
 	 From 
 	  	 Table_Fields TF
 	  	 JOIN Table_Fields_Values TFV on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
 	  	 Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
 	  	 LEFT OUTER Join ED_FieldType_ValidValues EDFTV on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
 	 Where 
 	  	 TF.Table_Field_Desc = 'OEE Calculation Type'
 	  	 AND TFV.KeyID = @PUId
 	 
-- The goal is to build a table with all the start times and then
-- at the end we'll fill in the end times.
DECLARE  @Periods TABLE( 	 PeriodId 	  	  	 int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	  	  	  	 StartTime 	  	  	 datetime,
 	  	  	  	  	  	 EndTime 	  	  	  	 datetime,
 	  	  	  	  	  	 TableId 	  	  	  	 int,
 	  	  	  	  	  	 KeyId 	  	  	  	 int)
DECLARE @ProductionDays TABLE ( 	 DayId 	  	  	 int IDENTITY(1,1),
 	  	  	  	  	  	  	  	 StartTime 	  	 datetime PRIMARY KEY,
 	  	  	  	  	  	  	  	 EndTime 	  	  	 datetime,
 	  	  	  	  	  	  	  	 ProductionDay 	 datetime)
DECLARE @ProductionStarts Table(Id Int Identity(1,1),StartTime DateTime,EndTime DateTime,ProdId Int,PUId Int)
DECLARE @SliceUpdate TABLE (
 	  	  	 SliceUpdateId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
 	  	  	 StartTime 	 datetime,
 	  	  	 EventId 	  	 int,
 	  	  	 ProdId 	  	 int
  	  	  	 )
/********************************************************************
* 	  	  	  	  	  	  	 Initialization 	  	  	  	  	  	  	 *
********************************************************************/
SELECT 	 -- Table Ids
 	  	 @EventsTableId 	  	  	  	  	 = 1,
 	  	 @ProductionStartsTableId 	  	 = 2,
 	  	 @CrewScheduleTableId 	  	  	 = -1,
 	  	 @ProductionDaysTableId 	  	  	 = -2,
 	  	 @ProductionPlanStartsTableId 	 = 12,
 	  	 @NonProductiveTableId 	  	  	 = -3,
 	  	 @DowntimeSpecsTableId 	  	  	 = -4,
 	  	 @ProductionSpecsTableId 	  	  	 = -5,
 	  	 @WasteSpecsTableId 	  	  	  	 = -6
/********************************************************************
* 	  	  	  	  	  	  	 Configuration 	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO  @ProductionStarts (ProdId,StartTime ,EndTime)
 	 SELECT ProdId , StartTime , EndTime FROM  dbo.fnBF_GetPSFromEvents(@PUId,@StartTime,@EndTime,16)   
 	 --WHERE ProdId != 1
 	 Order by StartTime 
 	 
UPDATE @ProductionStarts set PUId = @PUId 
SELECT 	 -- Downtime
 	  	 @ScheduledCategoryId 	  	 = Downtime_Scheduled_Category,
 	  	 @ExternalCategoryId 	  	  	 = Downtime_External_Category, 	 -- Currently ignored
 	  	 @DowntimeSpecId 	  	  	  	 = Downtime_Percent_Specification,
 	  	 -- Production
 	  	 @PerformanceCategoryId 	  	 = Performance_Downtime_Category,
 	  	 @ProductionSpecId 	  	  	 = Production_Rate_Specification,
 	  	 @ProductionRateFactor 	  	 = dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits),
 	  	 @ProductionType 	  	  	  	 = Production_Type,
 	  	 @ProductionVarId 	  	  	 = Production_Variable,
 	  	 @ProductionStartTime 	  	 = Uses_Start_Time,
 	  	 -- Waste
 	  	 @WasteSpecId 	  	  	  	 = Waste_Percent_Specification,
 	  	 -- Non-Productive Time
 	  	 @NPCategoryId 	 = Non_Productive_Category,
 	  	 -- Efficiency
 	  	 @EfficiencySpecId 	  	  	 = Efficiency_Percent_Specification
FROM dbo.Prod_Units WITH (NOLOCK)
WHERE PU_Id = @PUId
SELECT 	 @DowntimePropId 	 = Prop_Id
FROM dbo.Specifications WITH (NOLOCK)
WHERE Spec_Id = @DowntimeSpecId
SELECT 	 @ProductionPropId 	 = Prop_Id
FROM dbo.Specifications WITH (NOLOCK)
WHERE Spec_Id = @ProductionSpecId
SELECT 	 @WastePropId 	 = Prop_Id
FROM dbo.Specifications WITH (NOLOCK)
WHERE Spec_Id = @WasteSpecId
/********************************************************************
* 	  	  	  	  	  	  	 Product Changes 	  	  	  	  	  	  	 *
********************************************************************/
-- Production starts always has to be contiguous so it's the best place to start
INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	 EndTime)
SELECT 	 @ProductionStartsTableId,
 	  	 Id,
 	  	 CASE 	 WHEN StartTime < @StartTime THEN @StartTime
 	  	  	  	 ELSE StartTime
 	  	  	  	 END,
 	  	 CASE  	 WHEN EndTime > @EndTime OR EndTime IS NULL THEN @EndTime
 	  	  	  	 ELSE EndTime
 	  	  	  	 END 	  	 
FROM @ProductionStarts 
/********************************************************************
* 	  	  	  	  	  	  	 CrewDesc Schedule 	  	  	  	  	  	 *
********************************************************************/
IF @rptParmCrewSummary =1 or @rptParmShiftSummary = 1 or 1=1
BEGIN
 	 -- Add records for all CrewDesc starts
 	 INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime)
 	 SELECT 	 @CrewScheduleTableId,
 	  	  	 cs.CS_Id,
 	  	  	 StartTime 	 = CASE 	 WHEN cs.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	  	 ELSE cs.Start_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 EndTime 	  	 = CASE 	 WHEN cs.End_Time > @EndTime THEN @EndTime
 	  	  	  	  	  	  	  	 ELSE cs.End_Time
 	  	  	  	  	  	  	  	 END
 	 FROM dbo.Crew_Schedule cs WITH (NOLOCK)
 	 WHERE 	 PU_Id = @PUId
 	  	  	 AND End_Time > @StartTime
 	  	  	 AND Start_Time < @EndTime
END
/********************************************************************
* 	  	  	  	  	  	 Production Day 	  	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO @ProductionDays ( 	 StartTime,
 	  	  	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	  	  	 ProductionDay)
SELECT 	 StartTime,
 	  	 EndTime,
 	  	 ProductionDay
FROM dbo.fnGEPSGetProductionDays(  [dbo].[fnServer_CmnConvertFromDbTime](@StartTime,@InTimeZone),
 	  	  	  	  	  	  	  	  	 [dbo].[fnServer_CmnConvertFromDbTime](@EndTime,@InTimeZone))
Update @ProductionDays 
SET StartTime = [dbo].[fnServer_CmnConvertToDbTime](StartTime,@InTimeZone),
EndTime = [dbo].[fnServer_CmnConvertToDbTime](EndTime,@InTimeZone),
ProductionDay = [dbo].[fnServer_CmnConvertToDbTime](ProductionDay,@InTimeZone)
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @ProductionDaysTableId,
 	  	 DayId,
 	  	 StartTime,
 	  	 EndTime
FROM @ProductionDays
/********************************************************************
* 	  	  	  	  	  	 Production Order 	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @ProductionPlanStartsTableId,
 	  	 pps.PP_Start_Id,
 	  	 StartTime 	 = CASE 	 WHEN pps.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	 ELSE pps.Start_Time
 	  	  	  	  	  	  	 END,
 	  	 EndTime 	  	 = CASE 	 WHEN pps.End_Time > @EndTime THEN @EndTime
 	  	  	  	  	  	  	 ELSE pps.End_Time
 	  	  	  	  	  	  	 END
FROM dbo.Production_Plan_Starts pps WITH (NOLOCK)
WHERE 	 pps.PU_Id = @PUId
 	  	 AND pps.Start_Time < @EndTime
 	  	 AND (pps.End_Time > @StartTime OR pps.End_Time IS NULL)
/********************************************************************
* 	  	  	  	  	  	 Non-Productive Time 	  	  	  	  	  	  	 *
********************************************************************/
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @NonProductiveTableId,
 	  	 np.NPDet_Id,
 	  	 StartTime 	 = CASE 	 WHEN np.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	 END,
 	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > @EndTime THEN @EndTime
 	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	 END
FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPCategoryId
WHERE 	 PU_Id = @PUId
 	  	 AND np.Start_Time < @EndTime
 	  	 AND np.End_Time > @StartTime
 	  	 
/********************************************************************
* 	  	  	  	  	  	 Specifications 	  	  	  	  	  	  	  	 *
********************************************************************/
-- DOWNTIME TARGET
INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	 EndTime)
SELECT 	 @DowntimeSpecsTableId,
 	  	 AS_Id,
 	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.StartTime, @StartTime),
 	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.EndTime, @EndTime)
FROM @ProductionStarts  ps 
 	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PUId = puc.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND puc.Prop_Id = @DowntimePropId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.ProdId = puc.Prod_Id
 	  	 JOIN dbo.Active_Specs s WITH (NOLOCK) ON 	 s.Char_Id = puc.Char_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Spec_Id = @DowntimeSpecId
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Effective_Date < isnull(ps.EndTime, @EndTime)
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @EndTime) > ps.StartTime
-- PRODUCTION TARGET
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @ProductionSpecsTableId,
 	  	 AS_Id,
 	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.StartTime, @StartTime),
 	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.EndTime, @EndTime)
FROM @ProductionStarts ps 
 	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PUId = puc.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND puc.Prop_Id = @ProductionPropId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.ProdId = puc.Prod_Id
 	  	 JOIN dbo.Active_Specs s WITH (NOLOCK) ON 	 s.Char_Id = puc.Char_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Spec_Id = @ProductionSpecId
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Effective_Date < isnull(ps.EndTime, @EndTime)
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @EndTime) > ps.StartTime
-- WASTE TARGET
INSERT INTO @Periods ( 	 TableId,KeyId,StartTime,EndTime)
SELECT 	 @WasteSpecsTableId,
 	  	 AS_Id,
 	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.StartTime, @StartTime),
 	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.EndTime, @EndTime)
FROM @ProductionStarts ps 
 	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PUId = puc.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND puc.Prop_Id = @WastePropId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.ProdId = puc.Prod_Id
 	  	 JOIN dbo.Active_Specs s WITH (NOLOCK) ON 	 s.Char_Id = puc.Char_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Spec_Id = @WasteSpecId
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND s.Effective_Date < isnull(ps.EndTime, @EndTime)
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @EndTime) > ps.StartTime
/********************************************************************
* 	  	  	  	  	  	 Production Events 	  	  	  	  	  	  	 *
********************************************************************/
IF @ProductionType <> 1
BEGIN
 	 INSERT INTO @Periods ( 	 TableId,
 	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime
 	  	  	  	  	  	  	 )
 	 SELECT 	 @EventsTableId,
 	  	  	 e.Event_Id,
 	  	  	 StartTime 	 = e.Timestamp, 
 	  	  	 EndTime 	  	 = e.Timestamp
 	 FROM dbo.Events e WITH (NOLOCK)
 	 WHERE 	 e.PU_Id = @PUId
 	  	  	 AND isnull(e.Start_Time,e.TimeStamp) <= @EndTime
 	  	  	 AND e.Timestamp >= @StartTime
 	  	  	 AND e.Applied_Product IS NOT NULL  	 
 	 -- Set the Start time for the first record.
 	 UPDATE p2
 	 SET p2.StartTime = coalesce(e.Start_Time,@StartTime)
 	 FROM @Periods p2
 	  	 JOIN dbo.Events e WITH (NOLOCK) ON p2.KeyId = e.Event_Id
 	 WHERE p2.PeriodId IN (SELECT min(p1.PeriodId)
 	  	 FROM @Periods p1 WHERE p1.TableId = @EventsTableId)
 	 -- Set the Start time for the other records based on whether Start_Time is configured..
 	 UPDATE p2
 	 SET p2.StartTime = CASE WHEN e.Start_Time IS NULL THEN p1.EndTime ELSE e.Start_Time END
 	 FROM @Periods p1
 	  	 JOIN @Periods p2 ON p2.PeriodId = p1.PeriodId + 1
 	  	 LEFT JOIN dbo.Events e WITH (NOLOCK) ON p2.KeyId = e.Event_Id
 	  	  	 AND p2.TableId = p1.TableId
 	 WHERE p1.TableId = @EventsTableId
END
/********************************************************************
* 	  	  	  	  	  	  	 Gaps 	  	  	  	  	  	  	  	  	 *
********************************************************************/
-- Insert gaps
INSERT INTO @Periods ( 	 StartTime,
 	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	 TableId)
SELECT 	 p1.EndTime,
 	  	 @EndTime,
 	  	 p1.TableId
FROM @Periods p1
 	 LEFT JOIN @Periods p2 ON 	 p1.TableId = p2.TableId
 	  	  	  	  	  	  	  	 AND p1.EndTime = p2.StartTime
WHERE 	 p1.EndTime < @EndTime
 	  	 AND p2.PeriodId IS NULL
/********************************************************************
* 	  	  	  	  	  	  	 Slices 	  	  	  	  	  	  	  	  	 *
********************************************************************/
-- Create slices
INSERT INTO @Slices ( 	 PUId,
 	  	  	  	  	  	 StartTime)
SELECT DISTINCT 	 0,
 	  	  	  	 StartTime
FROM @Periods
ORDER BY StartTime ASC
SELECT @Rows = @@rowcount
-- Correct the end times
UPDATE s1
SET s1.EndTime 	  	 = s2.StartTime,
 	 s1.CalendarTime 	 = datediff(s, s1.StartTime, s2.StartTime)
FROM @Slices s1
 	 JOIN @Slices s2 ON s2.SliceId = s1.SliceId + 1
WHERE s1.SliceId < @Rows
UPDATE @Slices
SET EndTime  	  	 = @EndTime,
 	 CalendarTime 	 = datediff(s, StartTime, @EndTime)
WHERE SliceId = @Rows
-- Update each slice with the relative table information
UPDATE s
SET 	 PUId 	 = ps.PUId,
 	 ProdId 	 = ps.ProdId,
 	 StartId 	 = ps.Id
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @ProductionStartsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN @ProductionStarts ps ON p.KeyId = ps.Id
WHERE 	 s.PUId = 0
 	  	 AND p.KeyId IS NOT NULL
IF @rptParmCrewSummary =1 or @rptParmShiftSummary = 1 or 1=1
BEGIN
UPDATE s
SET CrewDesc 	 = cs.Crew_Desc,
 	 ShiftDesc 	 = cs.Shift_Desc
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @CrewScheduleTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN dbo.Crew_Schedule cs WITH (NOLOCK) ON p.KeyId = cs.CS_Id
WHERE p.KeyId IS NOT NULL
END
UPDATE s
SET ProductionDay 	 = pd.ProductionDay
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @ProductionDaysTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN @ProductionDays pd ON p.KeyId = pd.DayId
WHERE p.KeyId IS NOT NULL
UPDATE s
SET PPId = pps.PP_Id
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @ProductionPlanStartsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND (p.EndTime > s.StartTime OR p.EndTime IS NULL)
 	  	 LEFT JOIN dbo.Production_Plan_Starts pps WITH (NOLOCK) ON p.KeyId = pps.PP_Start_Id
WHERE p.KeyId IS NOT NULL
UPDATE s
SET NP = 1
FROM @Slices s
  	  LEFT JOIN @Periods p ON p.TableId = @NonProductiveTableId
  	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	  AND p.EndTime > s.StartTime
WHERE p.KeyId IS NOT NULL 
UPDATE s
SET DowntimeTarget = sp.Target
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @DowntimeSpecsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
WHERE p.KeyId IS NOT NULL
UPDATE s
SET ProductionTarget = sp.Target
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @ProductionSpecsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
WHERE p.KeyId IS NOT NULL
UPDATE s
SET WasteTarget = sp.Target
FROM @Slices s
 	 LEFT JOIN @Periods p ON p.TableId = @WasteSpecsTableId
 	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
WHERE p.KeyId IS NOT NULL
IF @ProductionType <> 1
BEGIN
 	  	 -- 	 Retrieve events that have an applied product. All other events are not
 	  	 --  needed, since the product information for these events would come from
 	  	 --  Production_starts. Events need to be retrieved only when event summary
 	  	 -- 	 is needed.
 	  	  	 --@Slices may not necessarily correspond to an event
 	  	  	 --Update slices that correspond to an event i.e.@Periods.EndTime = event.Timestamp
 	  	  	 UPDATE s
 	  	  	 SET EventId = e.Event_Id,
 	  	  	  	 AppliedProdId = e.Applied_Product
 	  	  	 FROM @Slices s
 	  	  	  	 LEFT JOIN @Periods p ON p.TableId = @EventsTableId
 	  	  	  	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	  	  	  	 LEFT JOIN dbo.Events e WITH (NOLOCK) ON p.KeyId = e.Event_Id
 	  	  	  	  	  	 AND p.EndTime = e.Timestamp 	  	  	  	 
 	  	  	 WHERE p.KeyId IS NOT NULL AND e.Applied_Product IS NOT NULL
END
/********************************************************************
* 	  	  	  	  	  	  	 Downtime 	  	  	  	  	  	  	  	 *
********************************************************************/
-- Calculate the downtime statistics for each slice
-- Calculate 'Planned Downtime' and 'Available Time'
UPDATE s
SET 	 DowntimePlanned 	 = isnull(dts.Total,0),
 	 AvailableTime 	  	 = CASE 	 WHEN s.CalendarTime >= isnull(dts.Total,0)
 	  	  	  	  	  	  	  	  	 THEN s.CalendarTime - isnull(dts.Total,0)
 	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	 END
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 SliceId 	 AS SliceId,
 	  	  	  	  	 sum(datediff(s, CASE 	 WHEN ted.Start_Time < s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	 THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	 THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	 END)) AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Timed_Event_Details ted WITH (NOLOCK) ON 	 s.PUId = ted.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ted.Start_Time < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (ted.End_Time > s.StartTime or ted.End_Time Is Null)
 	  	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @ScheduledCategoryId
 	  	  	  	 GROUP BY s.SliceId) dts ON s.SliceId = dts.SliceId
-- Calculate 'External Downtime' (i.e. 'Unavailable Time' or 'Line/Unit Restraints') and 'Loading Time'
UPDATE s
SET 	 DowntimeExternal 	 = isnull(dts.Total,0),
 	 LoadingTime 	  	  	 = CASE 	 WHEN s.AvailableTime >= isnull(dts.Total,0)
 	  	  	  	  	  	  	  	  	 THEN s.AvailableTime - isnull(dts.Total, 0)
 	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	 END
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 SliceId 	 AS SliceId,
 	  	  	  	  	 sum(datediff(s, CASE 	 WHEN ted.Start_Time < s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	 THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	 THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	 END)) AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Timed_Event_Details ted WITH (NOLOCK) ON 	 s.PUId = ted.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ted.Start_Time < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (ted.End_Time > s.StartTime or ted.End_Time Is Null)
 	  	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @ExternalCategoryId
 	  	  	  	 GROUP BY s.SliceId) dts ON s.SliceId = dts.SliceId
-- Calculate 'Performance Downtime'
UPDATE s
SET 	 DowntimePerformance 	 = isnull(dts.Total,0)
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 SliceId 	 AS SliceId,
 	  	  	  	  	  	 sum(datediff(s, CASE 	 WHEN ted.Start_Time < s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	 THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	 THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	  	 END)) AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Timed_Event_Details ted WITH (NOLOCK) ON 	 s.PUId = ted.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ted.Start_Time < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (ted.End_Time > s.StartTime OR ted.End_Time is NULL)
 	  	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @PerformanceCategoryId
 	  	  	  	 GROUP BY s.SliceId) dts ON s.SliceId = dts.SliceId
-- Calculate 'Unplanned Downtime' and 'Run Time'
UPDATE s
SET  	  DowntimeTotal  	    	  = isnull(dts.Total,0),
  	  DowntimeUnplanned  	  = isnull(dts.Total, 0) - s.DowntimePlanned - s.DowntimeExternal - s.DowntimePerformance,
  	  RunTimeGross  	    	    	    	  = CASE  	  WHEN s.CalendarTime >= isnull(dts.Total,0)
  	    	    	    	    	    	    	    	    	    	  THEN s.CalendarTime - isnull(dts.Total, 0) + s.DowntimePerformance
  	    	    	    	    	    	    	    	    	  ELSE 0
  	    	    	    	    	    	    	    	    	  END,
  	  ProductiveTime  	    	  = CASE  	  WHEN s.CalendarTime >= isnull(dts.Total,0)
  	    	    	    	    	    	    	    	    	    	  THEN s.CalendarTime - isnull(dts.Total, 0)
  	    	    	    	    	    	    	    	    	  ELSE 0
  	    	    	    	    	    	    	    	    	  END
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 SliceId 	 AS SliceId,
 	  	  	  	  	  	 sum(datediff(s, CASE 	 WHEN ted.Start_Time < s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	 THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	 THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	  	 END)) AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Timed_Event_Details ted WITH (NOLOCK) ON 	 s.PUId = ted.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ted.Start_Time < s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND (ted.End_Time > s.StartTime OR ted.End_Time is NULL)
 	  	  	  	 GROUP BY s.SliceId) dts ON s.SliceId = dts.SliceId
/********************************************************************
* 	  	  	  	  	  	  	  	 Waste 	  	  	  	  	  	  	  	 *
********************************************************************/
-- Collect time-based waste
UPDATE s
SET WasteQuantity = isnull(wt.Total,0)
FROM @Slices s
 	 LEFT JOIN ( 	 SELECT 	 s.SliceId 	  	 AS SliceId,
 	  	  	  	  	  	 sum(wed.Amount) 	 AS Total
 	  	  	  	 FROM @Slices s
 	  	  	  	  	 JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 s.PUId = wed.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND wed.TimeStamp > s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND wed.TimeStamp <= s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND Event_Id IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND Amount IS NOT NULL
 	  	  	  	 GROUP BY s.SliceId) wt ON s.SliceId = wt.SliceId
-- Collect event-based waste
IF @ProductionStartTime = 1 	 -- Uses start time so pro-rate quantity
 	 BEGIN
 	 UPDATE s
 	 SET WasteQuantity = WasteQuantity + isnull(wt.Total,0)
 	 FROM @Slices s
 	  	 LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	 sum(CASE 	 WHEN e.Start_Time IS NOT NULL THEN
 	  	  	  	  	  	  	  	  	 convert(Float, datediff(s, CASE 	 WHEN e.Start_Time < s.StartTime THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	   CASE 	 WHEN e.TimeStamp > s.EndTime THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END))
 	  	  	  	  	  	  	  	 / convert(Float, CASE WHEN datediff(s, e.Start_Time, e.TimeStamp) <= 0 THEN 1 ELSE datediff(s, e.Start_Time, e.TimeStamp) END)
 	  	  	  	  	  	  	  	 * isnull(wed.Amount,0)
 	  	  	  	  	  	  	  	 ELSE isnull(wed.Amount,0)
 	  	  	  	  	  	  	  	 END) AS Total
 	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON 	 s.PUId = e.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND e.TimeStamp > s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  --AND e.Start_Time < s.EndTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND isnull(e.Start_Time, e.TimeStamp) <= s.EndTime 
 	  	  	  	  	  	  	 LEFT JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 s.PUId = wed.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 --AND wed.TimeStamp = e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Amount IS NOT NULL
 	  	  	  	  	 GROUP BY s.SliceId) wt ON s.SliceId = wt.SliceId
 	 END
ELSE 	  	 -- Doesn't use start time so don't pro-rate quantity
 	 BEGIN
 	 UPDATE s
 	 SET WasteQuantity = WasteQuantity + isnull(wt.Total,0)
 	 FROM @Slices s
 	  	 LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	 sum(isnull(wed.Amount,0)) AS Total
 	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON 	 s.PUId = e.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND e.TimeStamp > s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND e.TimeStamp <= s.EndTime
 	  	  	  	  	  	  	 LEFT JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 s.PUId = wed.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 --AND wed.TimeStamp = e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Amount IS NOT NULL
 	  	  	  	  	 GROUP BY s.SliceId) wt ON s.SliceId = wt.SliceId
 	 END
/********************************************************************
* 	  	  	  	  	  	  	 Production 	  	  	  	  	  	  	  	 *
********************************************************************/
IF @ProductionType = 1
 	 BEGIN
 	 UPDATE s
 	 SET  	 ProductionTotal = isnull(pt.Total,0),
 	  	  	 ProductionNet 	 = isnull(pt.Total,0) - s.WasteQuantity,
 	  	  	 ProductionIdeal 	 = dbo.fnGEPSIdealProduction(RunTimeGross,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ProductionTarget,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionRateFactor,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 pt.Total)
 	 FROM @Slices s
 	  	 LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	 sum(convert(Float, t.Result)) AS Total
 	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	 JOIN dbo.Tests t WITH (NOLOCK) ON 	 t.Var_Id = @ProductionVarId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND t.Result_On > s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND t.Result_On <= s.EndTime
 	  	  	  	  	 GROUP BY s.SliceId) pt ON s.SliceId = pt.SliceId
 	 END
ELSE
 	 BEGIN
 	 IF @ProductionStartTime = 1 	 -- Uses start time so pro-rate quantity
 	  	 BEGIN
 	  	 UPDATE s
 	  	 SET 	 ProductionTotal 	 = isnull(pt.Total,0),
 	  	  	 ProductionNet 	 = isnull(pt.Total,0) - s.WasteQuantity,
 	  	  	 ProductionIdeal 	 = dbo.fnGEPSIdealProduction(RunTimeGross,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ProductionTarget,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionRateFactor,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 pt.Total)
 	  	 FROM @Slices s
 	  	  	  LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	  	 sum( CASE 	 WHEN e.Start_Time IS NOT NULL THEN
 	  	  	  	  	  	  	  	  	  	  	  	 convert(Float, datediff(s, CASE 	 WHEN e.Start_Time < s.StartTime THEN s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	   CASE 	 WHEN e.TimeStamp > s.EndTime THEN s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END))
 	  	  	  	  	  	  	  	  	  	  	  	 / convert(Float, CASE WHEN datediff(s, e.Start_Time, e.TimeStamp) <=0 THEN 1 ELSE datediff(s, e.Start_Time, e.TimeStamp) END)
 	  	  	  	  	  	  	  	  	  	  	  	 * isnull(ed.Initial_Dimension_X,0)
 	  	  	  	  	  	  	  	  	  	  	 ELSE isnull(ed.Initial_Dimension_X,0)
 	  	  	  	  	  	  	  	  	  	  	 END) AS Total
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON 	 s.PUId = e.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp > s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(e.Start_Time, e.TimeStamp) <= s.EndTime -- Note: if starttime is null it assumes that starttime = endtime
 	  	  	  	  	  	  	  	 JOIN dbo.Production_Status ps WITH (NOLOCK) ON 	 e.Event_Status = ps.ProdStatus_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.Count_For_Production = 1
 	  	  	  	  	  	  	  	 LEFT JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
 	  	  	  	  	  	 GROUP BY s.SliceId) pt ON s.SliceId = pt.SliceId 
 	  	 END
 	 ELSE -- Doesn't use start time so don't pro-rate quantity
 	  	 BEGIN
 	  	 UPDATE s
 	  	 SET 	 ProductionTotal 	 = isnull(pt.Total,0),
 	  	  	 ProductionNet 	 = isnull(pt.Total,0) - s.WasteQuantity,
 	  	  	 ProductionIdeal 	 = dbo.fnGEPSIdealProduction(RunTimeGross,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ProductionTarget,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionRateFactor,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 pt.Total)
 	  	 FROM @Slices s
 	  	  	 LEFT JOIN ( 	 SELECT 	 s.SliceId AS SliceId,
 	  	  	  	  	  	  	  	 sum(ed.Initial_Dimension_X) AS Total
 	  	  	  	  	  	 FROM @Slices s
 	  	  	  	  	  	  	 JOIN dbo.Events e WITH (NOLOCK) ON 	 s.PUId = e.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp > s.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp <= s.EndTime
 	  	  	  	  	  	  	  	 JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
 	  	  	  	  	  	 GROUP BY s.SliceId) pt ON s.SliceId = pt.SliceId
 	  	 END
 	 END
 -- Populate NPLabelRef ( NP 0-->1 Transition)
UPDATE s1
SET s1.NPLabelRef = 1
FROM @Slices s1
 	 JOIN @Slices s2 ON s2.SliceId = s1.SliceId + 1
WHERE s2.SliceId < (SELECT max(s3.SliceId) FROM @Slices s3)
 	 AND s2.NP = 1 AND (
 	  	 (s1.EventId = s2.EventId) OR (s1.PPId = s2.PPId) OR 
 	  	 ((s1.ProdId = s2.ProdId) AND (s1.CrewDesc = s2.CrewDesc) AND s1.EventId IS NULL AND s1.PPId IS NULL))-- OR
-- Populate NPLabelRef ( NP 1-->0 Transition)
UPDATE s1
SET s1.NPLabelRef = 1
FROM @Slices s2
 	 JOIN @Slices s1 ON s1.SliceId = s2.SliceId + 1
WHERE s1.SliceId < (SELECT max(s3.SliceId) FROM @Slices s3)
 	 AND s2.NP = 1 AND (
 	  	 (s1.EventId = s2.EventId) OR (s1.PPId = s2.PPId) OR 
 	  	 ((s1.ProdId = s2.ProdId) AND (s1.CrewDesc = s2.CrewDesc) AND s1.EventId IS NULL AND s1.PPId IS NULL)) --OR
--When applied product and original product are the same, 
 	 --no need of "Applied Product" which is causing duplicate entries in Product Summary.
 	 UPdate s
 	 SET AppliedProdID = NULL 
 	 FROM @Slices s
 	 WHERE s.ProdId = s.AppliedProdID  
-- Fix Events that have the same event id but differing ProdId, due to slicing 	 
INSERT INTO @SliceUpdate (
 	  	 StartTime,
 	  	 EventId)
 	 SELECT 
 	  	 max(s1.StartTime) AS MaxStartTime,
 	  	 s1.EventId As EventId
 	 FROM @Slices s1
 	  	 JOIN @Slices s2 ON s1.EventId = s2.EventId AND s1.ProdId <> s2.ProdId
 	 GROUP BY s1.EventId
UPDATE su
SET su.ProdId = s.ProdId
FROM @Slices s, @SliceUpdate su
WHERE s.StartTime = su.StartTime AND s.PUId = @PUId
UPDATE s
SET s.ProdId = su.ProdId
FROM @Slices s,@SliceUpdate su
WHERE s.EventId = su.EventId AND s.ProdId <> su.ProdId
-- If the event has an applied product assign the applied Product as the ProdId
UPDATE s
SET s.ProdId = s.AppliedProdId
FROM @Slices s WHERE s.AppliedProdId IS NOT Null
--<TIMED OEE CALCULATION>
DECLARE @AvailabilityName nvarchar(50), @PerformanceName nvarchar(50), @PlannedName nvarchar(50), @QualityName nvarchar(50),@AvailabilityCategoryId Int, @PerformanceTimedCategoryId Int,@PlannedCategoryId Int, @QualityCategoryId Int,@NPTimedCategoryId Int, @NonProductiveSeconds Int,@AvailabilitySeconds Int, @PerformanceSeconds Int,@PlannedSeconds Int, @QualitySeconds Int,@CalendarSeconds Int, @ActivityTime Int = 0,@UtilizationTime Int = 0, @WorkingTime Int = 0,@UsedTime Int = 0, @EffectivelyUsedTime Int = 0
DECLARE @NonProductiveTime TABLE (RowID int IDENTITY, 	 StartTime DateTime,EndTime DateTime)
DECLARe @ProductiveTime TABLE(  	 RowID int IDENTITY, 	 StartTime DateTime, 	 EndTime DateTime)
DECLARE @TimedDetails TABLE(StartTime DateTime,EndTime DateTime,ERCId Int)
Declare @LastProductiveTimeRowID int, @CurrentProductiveRowID int,@CurrentProductiveStartTime Datetime, @CurrentProductiveEndTime datetime,@SliceCnt int,@cnt int
SELECT @AvailabilityName = 'Availability',@PerformanceName = 'Performance',@PlannedName = 'Planned',@QualityName = 'Quality'
SELECT @AvailabilityCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @AvailabilityName
SELECT @PerformanceTimedCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @PerformanceName
SELECT @PlannedCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @PlannedName
SELECT @QualityCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @QualityName
SELECT @NPTimedCategoryId 	 = Non_Productive_Category
 	 FROM dbo.Prod_Units WITH (NOLOCK)
 	 WHERE PU_Id = @PUId
 	 SET @cnt =1
 	 Select @SliceCnt = count(0) from @slices
 	 While @cnt <= @SliceCnt
 	 Begin
 	  	  	 Select @EndTime=EndTime,@StartTime=StartTime  from @Slices where SliceId = @cnt
 	  	  	 DELETE FROM @NonProductiveTime
 	  	  	 INSERT INTO @NonProductiveTime(StartTime,EndTime) 
 	  	  	 SELECT CASE WHEN np.Start_Time < @StartTime THEN @StartTime
 	  	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	  	 END,
 	  	  	  	    CASE WHEN np.End_Time > @EndTime THEN @EndTime
 	  	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	  	 END
 	  	  	 FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPTimedCategoryId
 	  	  	 WHERE 	 PU_Id = @PUId
 	  	  	  	 AND np.Start_Time < @EndTime
 	  	  	  	 AND np.End_Time > @StartTime
 	  	  	 SELECT 	 @NonProductiveSeconds = coalesce(SUM(DATEDIFF(SECOND,StartTime,EndTime)),0)
 	  	  	 FROM @NonProductiveTime
 	  	  	 
 	  	  	 DELETE FROM @ProductiveTime
 	  	  	 INSERT INTO @ProductiveTime(StartTime,EndTime)
 	  	  	 SELECT @StartTime,@EndTime
 	  	  	 /*
 	  	  	 INSERT INTO @ProductiveTime(StartTime)
 	  	  	 SELECT EndTime
 	  	  	 FROM @NonProductiveTime
 	  	  	 WHERE EndTime < @EndTime
 	  	  	 
 	  	  	 UPDATE p
 	  	  	 SET p.EndTime = coalesce(npt.StartTime,@EndTime)
 	  	  	 FROM @ProductiveTime p
 	  	  	 LEFT JOIN @NonProductiveTime npt on npt.RowID = p.RowId
 	  	  	 DELETE @ProductiveTime WHERE StartTime = EndTime
 	  	  	 */
 	 
 	  	  	 SELECT @LastProductiveTimeRowID = MAX(RowID),
 	  	  	  	 @CurrentProductiveRowID = MIN(RowID)
 	  	  	 FROM @ProductiveTime
 	 
 	  	  	 DELETE @TimedDetails
 	  	  	 WHILE @CurrentProductiveRowID <= @LastProductiveTimeRowID
 	  	  	 BEGIN
 	  	  	  	 SELECT @CurrentProductiveStartTime = StartTime,
 	  	  	  	  	 @CurrentProductiveEndTime = EndTime
 	  	  	  	 FROM @ProductiveTime
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
 	  	  	  	 WHERE ted.PU_Id = @PUId
 	  	  	  	  	 AND ted.Start_Time < @CurrentProductiveEndTime
 	  	  	  	  	 AND (ted.End_Time > @CurrentProductiveStartTime or ted.End_Time Is Null)
  	  	  	  	 SELECT @CurrentProductiveRowID = @CurrentProductiveRowID + 1
 	  	  	 END
 	  	  	 ;WITH TimedDetails As ( 	 Select  coalesce(SUM(DATEDIFF(second, StartTime, EndTime)),0) Duration, ERCID, (Select ERC_Desc from Event_Reason_Catagories where ERC_ID = A.ERCID) ERCDesc,@NonProductiveSeconds NPT from @TimedDetails A Group BY ERCID)
 	  	  	 UPDATE A
 	  	  	 set 
 	  	  	  	 NPT =@NonProductiveSeconds,
 	  	  	  	 DowntimeA = (select SUM(Duration) from TimedDetails Where ERCDesc in ('Availability') ),
 	  	  	  	 DowntimeP = (select SUM(Duration)  from TimedDetails Where  ERCDesc   in ('Performance') ),
 	  	  	  	 DowntimeQ = (select SUM(Duration)  from TimedDetails Where  ERCDesc   in ('Quality')),
 	  	  	  	 DowntimePL = (select SUM(Duration)  from TimedDetails Where  ERCDesc   in ('Planned'))
 	  	  	 from @Slices A 	  	   Where A.SliceId = @cnt
 	  	  	 SET @cnt = @cnt+1
 	 end
 	 
 	 --Handled overlapping of NPT and DT
 	 
  	  IF --@IsNPTIncluded = 1 AND 
 	  @OEEType = 'Time Based'
  	  Begin
  	  --  	  UPDATE @slices 
  	  --  	  SET 
 	  	  	 --DowntimeA = 0,DowntimeP = 0,DowntimeQ = 0,DowntimePL = 0  
 	  	  --Where 
 	  	  	 --NPT >0 
 	  	  	 --And (ISNULL(DowntimeA,0)+ISNULL(DownTimeP,0)+ISNULL(DownTimeQ,0)+ISNULL(DownTimePL,0)) >0
  	  --  	  UPDATE @slices Set LoadingTime = LoadingTime - NPT ,RunTimeGross = RunTimeGross - NPT ,ProductiveTime = ProductiveTime - NPT 
  	    	  UPDATE @slices SET RunTimeGross = LoadingTime - (ISNULL(DowntimeA,0)+ISNULL(DownTimeP,0)+ISNULL(DownTimeQ,0)+ISNULL(DownTimePL,0))
  	    	  UPDATE @slices set ProductiveTime = CASE WHEN ProductiveTime < 0 Then 0 ELSE ProductiveTime END
  	  End
  	 -- IF -- @IsNPTIncluded = 1 AND 
 	  --ISNULL(@OEEType,'') <> 'Time Based'
  	 -- Begin
 	  	 
  	 --   	  --UPDATE @slices 
  	 --   	  -- SET 
  	 --   	  -- LoadingTime = LoadingTime +ISNULL(DowntimePlanned,0) - NPT 
  	 --   	  --   Where NPT >0 And ISNULL(DowntimeTotal,0) >0
 	  	 -- --UPDATE @Slices SET LoadingTime = LoadingTime+ISNULL(DowntimePlanned,0)
  	 --   	  UPDATE @slices 
  	 --   	   SET 
  	 --   	   RunTimeGross = CASE WHEN LoadingTime - DowntimeTotal < 0 THEN  0 ELSE LoadingTime - DowntimeTotal END
  	 --   	   ,ProductiveTime = Case WHEN LoadingTime - DowntimeTotal + DowntimePerformance < 0 THEN 0 ELSE LoadingTime - DowntimeTotal + DowntimePerformance END
  	 --   	   Where NPT >0 And ISNULL(DowntimeTotal,0) >0
  	 -- End
  	  
 	  --US255626 --Need changes--comment both the if clauses
  	  
--</TIMED OEE CALCULATION>
 RETURN
END
