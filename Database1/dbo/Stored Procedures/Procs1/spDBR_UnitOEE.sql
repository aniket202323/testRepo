/*
Procedure: 	  	  	 spDBR_UnitOEE
Author: 	  	  	  	 Ramesh Elapakurthi
Date Created: 	  	 2009/08/20
Editor Tab Spacing: 	 4
Description:
============
Generates  OEE Summary By Units.
*/
CREATE PROCEDURE [dbo].[spDBR_UnitOEE]
@UnitList text = NULL,
@ReportStartTime DATETIME = NULL,
@ReportEndTime DATETIME = NULL,
@Summarize int = 1,
@ColumnVisibility text = NULL,
@FilterNonProductiveTime int = 0,
@InTimeZone 	 varchar(200)=null,
@spAPIUnitOEECall Int = 0
AS
/********************************************************************
* 	  	  	  	  	  	  	 Declarations 	  	  	  	  	  	  	 *
********************************************************************/
DECLARE 	 -- General
 	  	 @Rows 	  	  	  	  	  	  	 int,
 	  	 @UnitRows 	  	  	  	  	  	 int,
 	  	 @Row 	  	  	  	  	  	  	 int,
 	  	 -- Tables
 	  	 @ProductionStartsTableId 	  	 int,
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
 	  	 @EfficiencySpecId 	  	  	  	 int,
 	  	 -- Site Parameters
 	  	 @CapRates 	  	  	  	  	  	 tinyint,
 	  	 -- Engineering Units
 	  	 @AmountEngineeringUnits 	  	  	 varchar(25), 
 	  	 @ItemEngineeringUnits 	  	  	 varchar(25), 
 	  	 @TimeEngineeringUnits 	  	  	 int, 
 	  	 @TimeUnitDesc 	  	  	  	  	 varchar(25),
 	  	 -- Other
 	  	 @ReturnValue 	  	  	  	  	 varchar(7000),
 	  	 @ReportPUId 	  	  	  	  	  	 int,
 	  	 @rsOverall 	  	  	  	  	  	 int,
 	  	 @rsSlices 	  	  	  	  	  	 int,
 	  	 @NPTLabel 	  	  	  	  	  	 varchar(255),
 	  	 @NPTLabelDefault 	  	  	  	 varchar(255),
 	  	 @HighCount 	  	  	  	  	  	 int,
 	  	 @MediumCount 	  	  	  	  	 int,
 	  	 @LowCount 	  	  	  	  	  	 int,
 	  	 @oeeStatus 	  	  	  	  	  	 int,
 	  	 
 	  	 --OEE Calculations
 	  	 @AccumAvailability Float,
 	  	 @AccumStatus int, 
 	  	 @AccumNetOperatingTime Float, 
 	  	 @AccumOperatingTime Float, 
 	  	 @AccumProduction Float, 
 	  	 @AccumQualityLoss Float, 
 	  	 @AccumSpeed Float, 
 	  	 @AccumIdealSpeed Float, 
 	  	 @AccumIdealProduction Float, 
 	  	 @AccumWaste Float, 
 	  	 @AccumRunningTime Float, 
 	  	 @AccumLoadingTime Float,
 	  	 @oee Float,
 	  	 --Alarm Info
 	  	 @oeeHighAlarmCount int, 
 	  	 @oeeMediumAlarmCount int,
 	  	 @oeeLowAlarmCount int, 
 	  	 @HighAlarmCount int, 
 	  	 @MediumAlarmCount int, 
 	  	 @LowAlarmCount int, 
 	  	 @oeeAmountEngineeringUnits varchar(25), 
 	  	 @oeeItemEngineeringUnits varchar(25),
 	  	 @oeeTimeEngineeringUnits int, 
 	  	 @SumPerfRate Float, 
 	  	 @SumAvailRate Float, 
 	  	 @SumQualRate Float, 
 	  	 @SumOEERate Float, 
 	  	 @SumActualRate Float, 
 	  	 @SumIdealRate Float,
 	  	 @EfficiencyBased int, 
 	  	 @NotEfficiencyBased int
 	 
Declare @AccumPerformanceTime FLOAT, @oeePerformanceTime FLOAT
IF @spAPIUnitOEECall Is Null SET @spAPIUnitOEECall = 0
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
 	  	  	  	  	  	 PPId 	  	  	  	 int,
 	  	  	  	  	  	 -- Other
 	  	  	  	  	  	 NP 	  	  	  	  	 bit DEFAULT 0,
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
 	  	  	  	  	  	 WasteQuantity 	  	 Float DEFAULT 0)
CREATE NONCLUSTERED INDEX SNCIXNP ON #Slices (NP)
CREATE CLUSTERED INDEX SCIX ON #Slices (PUId, NP, StartTime)
  	  	  	  	  	 
CREATE TABLE #Units (RowID 	  	  	 int IDENTITY,
 	  	  	  	 PUId int NULL ,
 	  	  	  	 LineName varchar(100) NULL,
 	  	  	  	 LineId int NULL, 
 	  	  	  	 PUDesc varchar(100) NULL  
 	  	  	 
)
CREATE TABLE #UnitsDup (
 	  	  	  	 PUId int NULL ,
 	  	  	  	 LineName varchar(100) NULL,
 	  	  	  	 LineId int NULL, 
 	  	  	  	 PUDesc varchar(100) NULL  
 	  	  	 
)
DECLARE @UnitSummary TABLE
(
 	 CurrentStatusIcon tinyint null,
 	 UnitName varchar(100) null,
 	 IdealProductionAmount Float null,
 	 ProductionAmount Float null,
 	 AmountEngineeringUnits varchar(25) null,
 	 ActualSpeed Float null,
 	 IdealSpeed Float null,
 	 SpeedEngineeringUnits varchar(25) null,
 	 PerformanceRate Float null,
 	 WasteAmount Float null,
 	 QualityRate Float null,
 	 PerformanceTime varchar(25) null,
 	 RunTime varchar(25) null,
 	 LoadingTime varchar(25) null,
 	 AvailableRate Float null,
 	 PercentOEE varchar(255) null,
 	 HighAlarmCount int null,
 	 MediumAlarmCount int null,
 	 LowAlarmCount int null,
 	 UnitID varchar(4000) null,
 	 CategoryId int null,
 	 Production_Variable int null,
  	 SummaryRow   int default 0,
 	 DowntimeUnPlanned 	 varchar(25) null,
 	 DowntimePlanned 	 varchar(25) null,
 	 DowntimeExternal 	 varchar(25) null,
 	 DowntimeTotal 	 varchar(25) null
 	 ,NPT Float Default 0
 	 ,DownTimeA Float Default 0
 	 ,DownTimeP Float Default 0
 	 ,DownTimeQ Float Default 0
 	 ,DownTimePL Float Default 0
)
DECLARE @Totals TABLE 
(  AccumProduction Float,
  AccumIdealProduction Float,
  AccumQualityLoss Float,
  AccumRunningTime Float,
  AccumLoadingTime Float,
  AccumWaste Float,
  AccumPerformanceTime Float
  ,AccumDownTimeA Float
  ,AccumDownTimeP Float
  ,AccumDownTimeQ Float
  ,AccumDownTimePL Float
  )
DECLARE @OEEs TABLE
(
   OEE Float
)
CREATE TABLE #ProductiveTimes (ROWID int IDENTITY(1,1),
 	  	  	  	  	  	  	  	  StartTime 	  	  	 datetime,
 	  	  	  	  	  	  	  	  EndTime 	  	  	 datetime)
DECLARE @UnitName varchar(100)
DECLARE @DowntimePlanned float,@AvailableTime float,@DowntimeExternal float,@LoadingTime float,@DowntimePerformance float,@DowntimeTotal float,
 	  	 @DowntimeUnplanned float,@RunTimeGross float,@ProductiveTime float,@WasteQuantity float,@ProductionTotal float,@ProductionNet float,@ProductionIdeal float,
 	  	 @TotalAvailableTime  float, @St datetime,@Et datetime,@ProductionTarget float,@CalendarTime float
DECLARE @DowntimePlannedSum float,@AvailableTimeSum float,@DowntimeExternalSUM float,@LoadingTimeSum float,@DowntimePerformanceSum float,@DowntimeTotalSum float,
 	  	 @DowntimeUnplannedSum float,@RunTimeGrossSum float,@ProductiveTimeSum float,@WasteQuantitySum float,@ProductionTotalSum float,@ProductionNetSum float,@ProductionIdealSum float,
 	  	 @TotalAvailableTimeSum  float,@RunTimeGrossSumIdeal float,@ActualTime float,@ActualLoadingTime float
 	  	 ,@DownTimeA Float,@DownTimeP Float,@DownTimeQ Float,@DownTimePL Float
 	  	 ,@SUMDownTimeA Float,@SUMDownTimeP Float,@SUMDownTimeQ Float,@SUMDownTimePL Float
 	  	  	  	  	  	  	 
IF (NOT @UnitList like '%<Root></Root>%' AND NOT @UnitList IS NULL)
  BEGIN
    IF (NOT @UnitList LIKE '%<Root>%')
    BEGIN 	 
      DECLARE @Text nvarchar(4000)
      SELECT @Text = N'UnitId;' + Convert(nvarchar(4000), @UnitList)
      INSERT INTO #Units (PUId) EXECUTE spDBR_Prepare_Table @Text
 	  END
    ELSE
    BEGIN
      INSERT INTO #Units (LineName, LineId, PUDesc, PUId) EXECUTE spDBR_Prepare_Table @UnitList
    END
  END
ELSE
  BEGIN
    INSERT INTO #Units (PUId, PUDesc) 
      SELECT DISTINCT pu_id, pu_desc 
 	   FROM prod_units WHERE pu_id > 0
  END
SELECT @UnitRows 	 = 	 @@ROWCOUNT,
 	    @Row 	  	 = 	 0 	  
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
WHERE  EXISTS (SELECT 1 FROM NotConfiguredUnits Where PU_Id = U.PUId)
Insert Into #UnitsDup(PUId,LineName,LineId,PUDesc)
Select Distinct PUId,LineName,LineId,PUDesc From #Units
Truncate table #Units
Insert Into #Units(PUId,LineName,LineId,PUDesc)
Select Distinct PUId,LineName,LineId,PUDesc From #UnitsDup
SELECT @UnitRows 	 = 	 @@ROWCOUNT,
 	    @Row 	  	 = 	 0
 --PRINT @UnitRows
 /********************************************************************
* 	  	  	  	  	  	  	 Initialization 	  	  	  	  	  	  	 *
********************************************************************/
SELECT 	 -- Table Ids
 	  	  
 	  	 @ProductionStartsTableId 	  	 = 2,
 	  	 @ProductionPlanStartsTableId 	 = 12,
 	  	 @NonProductiveTableId 	  	  	 = -3,
 	  	 @DowntimeSpecsTableId 	  	  	 = -4,
 	  	 @ProductionSpecsTableId 	  	  	 = -5,
 	  	 @WasteSpecsTableId 	  	  	  	 = -6
SELECT @ReportStartTime = dbo.fnServer_CmnConvertToDBTime(@ReportStartTime,@InTimeZone)
SELECT @ReportEndTime = dbo.fnServer_CmnConvertToDBTime(@ReportEndTime ,@InTimeZone)
WHILE @Row <  @UnitRows
BEGIN
 	 SELECT @Row = @Row + 1
 	 SELECT @ReportPUID = PUId FROM #Units WHERE ROWID = @Row
 	 
 	 --PRINT @ReportPUID
 	 SET @UnitName=NULL
 	 SELECT @UnitName =Coalesce(PU_desc,NULL)
 	 FROM Prod_Units WITH (NOLOCK) 
 	 WHERE PU_Id = @ReportPUID
 	 /********************************************************************
 	 * 	  	  	  	  	  	  	 Configuration 	  	  	  	  	  	  	 *
 	 ********************************************************************/
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
 	 WHERE PU_Id = @ReportPUID
 	 SELECT 	 @DowntimePropId 	 = Prop_Id
 	 FROM dbo.Specifications WITH (NOLOCK)
 	 WHERE Spec_Id = @DowntimeSpecId
 	 SELECT 	 @ProductionPropId 	 = Prop_Id
 	 FROM dbo.Specifications WITH (NOLOCK)
 	 WHERE Spec_Id = @ProductionSpecId
 	 SELECT 	 @WastePropId 	 = Prop_Id
 	 FROM dbo.Specifications WITH (NOLOCK)
 	 WHERE Spec_Id = @WasteSpecId
 	 SELECT 	 @CapRates = dbo.fnCMN_OEERateIsCapped()
 	 --SELECT @CapRates = 0
 	 --*****************************************************
 	 -- Get Status
 	 --*****************************************************
 	 SELECT @oeeStatus = null
 	 SELECT @oeeStatus = Tedet_id
 	 FROM Timed_Event_Details WITH (NOLOCK)
 	 WHERE PU_Id = @ReportPUID and End_Time Is Null
 	 IF @oeeStatus Is Null
 	  	 SELECT @oeeStatus = 1
 	 ELSE
 	  	 SELECT @oeeStatus = 0
 	  	 ------------------------------------------------------
 	  	 -- Get Engineering Units
 	  	 ------------------------------------------------------
 	  	 SELECT 
 	  	  	 @AmountEngineeringUnits 	 = coalesce(AmountEngineeringUnits, 'units'),
 	  	  	 @ItemEngineeringUnits 	 = coalesce(ItemEngineeringUnits, 'units'),
 	  	  	 @TimeEngineeringUnits 	 = coalesce(TimeEngineeringUnits, 4),
 	  	  	 @TimeUnitDesc 	  	  	 = coalesce(TimeUnitDesc, 'min')
 	  	 FROM dbo.fnCMN_GetEngineeringUnitsByUnit(@ReportPUId)
 	 --*****************************************************************
 	 --Keep track of how many of each type of oee we have
 	 --*****************************************************************
 	 if (@ProductionVarId is null)
 	  	 select @NotEfficiencyBased = @NotEfficiencyBased + 1
 	 else
 	  	 select @EfficiencyBased = @EfficiencyBased + 1
 	 /********************************************************************
 	 * 	  	  	  	  	  	  	 Product Changes 	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 -- Production starts always has to be contiguous so it's the best place to start
 	 INSERT INTO #Periods ( 	 TableId,
 	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime)
 	 SELECT 	 @ProductionStartsTableId,
 	  	  	 Start_Id,
 	  	  	 CASE 	 WHEN Start_Time < @ReportStartTime THEN @ReportStartTime
 	  	  	  	  	 ELSE Start_Time
 	  	  	  	  	 END,
 	  	  	 CASE  	 WHEN End_Time > @ReportEndTime OR End_Time IS NULL THEN @ReportEndTime
 	  	  	  	  	 ELSE End_Time
 	  	  	  	  	 END 	  	 
 	 FROM dbo.Production_Starts WITH (NOLOCK)
 	 WHERE 	 PU_Id = @ReportPUId
 	  	  	 AND Start_Time < @ReportEndTime
 	  	  	 AND (End_Time > @ReportStartTime
 	  	  	  	 OR End_Time IS NULL)
 	 /********************************************************************
 	 * 	  	  	  	  	  	 Non-Productive Time 	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 INSERT INTO #Periods ( 	 TableId,
 	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime)
 	 SELECT 	 @NonProductiveTableId,
 	  	  	 np.NPDet_Id,
 	  	  	 StartTime 	 = CASE 	 WHEN np.Start_Time < @ReportStartTime THEN @ReportStartTime
 	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	 END,
 	  	  	 EndTime 	  	 = CASE 	 WHEN np.End_Time > @ReportEndTime THEN @ReportEndTime
 	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	 END
 	 FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPCategoryId
 	 WHERE 	 PU_Id = @ReportPUId
 	  	  	 AND np.Start_Time < @ReportEndTime
 	  	  	 AND np.End_Time > @ReportStartTime
 	  	  	 
 	 /********************************************************************
 	 * 	  	  	  	  	  	 Specifications 	  	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 -- DOWNTIME TARGET
 	 INSERT INTO #Periods ( 	 TableId,
 	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime)
 	 SELECT 	 @DowntimeSpecsTableId,
 	  	  	 AS_Id,
 	  	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.Start_Time, @ReportStartTime),
 	  	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.End_Time, @ReportEndTime)
 	 FROM dbo.Production_Starts ps WITH (NOLOCK)
 	  	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PU_Id = puc.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND puc.Prop_Id = @DowntimePropId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.Prod_Id = puc.Prod_Id
 	  	  JOIN dbo.Active_Specs s WITH (NOLOCK) ON  	  s.Char_Id = puc.Char_Id AND s.Spec_Id = @DowntimeSpecId
   	    	    	    	    	    	    	    	    	    	    	  	  	 AND s.Effective_Date < CASE WHEN ps.End_Time > @ReportEndTime OR ps.End_Time IS NULL THEN @ReportEndTime ELSE ps.End_Time END 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @ReportEndTime) > CASE WHEN ps.Start_Time < @ReportStartTime THEN @ReportStartTime ELSE ps.Start_Time END 	 
 	 WHERE  	 ps.PU_Id = @ReportPUId
 	  	  	 AND ps.Start_Time < @ReportEndTime
 	  	  	 AND ( 	 ps.End_Time > @ReportStartTime
 	  	  	  	  	 OR ps.End_Time IS NULL)
 	  	  	 AND dbo.fnGEPSMaxDate(s.Effective_Date, ps.Start_Time, @ReportStartTime) <= dbo.fnGEPSMinDate(s.Expiration_Date, ps.End_Time, @ReportEndTime) 	  	  	  	  	 
 	 -- PRODUCTION TARGET
 	 INSERT INTO #Periods ( 	 TableId,
 	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime)
 	 SELECT 	 @ProductionSpecsTableId,
 	  	  	 AS_Id,
 	  	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.Start_Time, @ReportStartTime),
 	  	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.End_Time, @ReportEndTime)
 	 FROM dbo.Production_Starts ps WITH (NOLOCK)
 	  	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PU_Id = puc.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND puc.Prop_Id = @ProductionPropId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.Prod_Id = puc.Prod_Id 	 
 	  	  JOIN dbo.Active_Specs s WITH (NOLOCK) ON  	  s.Char_Id = puc.Char_Id AND s.Spec_Id = @ProductionSpecId
   	    	    	    	    	    	    	    	    	    	    	  	  	 AND s.Effective_Date < CASE WHEN ps.End_Time > @ReportEndTime OR ps.End_Time IS NULL THEN @ReportEndTime ELSE ps.End_Time END 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @ReportEndTime) > CASE WHEN ps.Start_Time < @ReportStartTime THEN @ReportStartTime ELSE ps.Start_Time END 	 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
 	 WHERE  	 ps.PU_Id = @ReportPUId
 	  	  	 AND ps.Start_Time < @ReportEndTime
 	  	  	 AND ( 	 ps.End_Time > @ReportStartTime
 	  	  	  	  	 OR ps.End_Time IS NULL)
 	  	  	 AND dbo.fnGEPSMaxDate(s.Effective_Date, ps.Start_Time, @ReportStartTime) <= dbo.fnGEPSMinDate(s.Expiration_Date, ps.End_Time, @ReportEndTime)
 	 -- WASTE TARGET
 	 INSERT INTO #Periods ( 	 TableId,
 	  	  	  	  	  	  	 KeyId,
 	  	  	  	  	  	  	 StartTime,
 	  	  	  	  	  	  	 EndTime)
 	 SELECT 	 @WasteSpecsTableId,
 	  	  	 AS_Id,
 	  	  	 dbo.fnGEPSMaxDate(s.Effective_Date, ps.Start_Time, @ReportStartTime),
 	  	  	 dbo.fnGEPSMinDate(s.Expiration_Date, ps.End_Time, @ReportEndTime)
 	 FROM dbo.Production_Starts ps WITH (NOLOCK)
 	  	 JOIN dbo.PU_Characteristics puc WITH (NOLOCK) ON 	 ps.PU_Id = puc.PU_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND puc.Prop_Id = @WastePropId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.Prod_Id = puc.Prod_Id 	  	  
 	  	  JOIN dbo.Active_Specs s WITH (NOLOCK) ON  	  s.Char_Id = puc.Char_Id AND s.Spec_Id = @WasteSpecId
   	    	    	    	    	    	    	    	    	    	    	  	  	 AND s.Effective_Date < CASE WHEN ps.End_Time > @ReportEndTime OR ps.End_Time IS NULL THEN @ReportEndTime ELSE ps.End_Time END 
 	  	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(s.Expiration_Date, @ReportEndTime) > CASE WHEN ps.Start_Time < @ReportStartTime THEN @ReportStartTime ELSE ps.Start_Time END 	 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
 	 WHERE  	 ps.PU_Id = @ReportPUId
 	  	  	 AND ps.Start_Time < @ReportEndTime
 	  	  	 AND ( 	 ps.End_Time > @ReportStartTime
 	  	  	  	  	 OR ps.End_Time IS NULL)
 	  	  	 AND dbo.fnGEPSMaxDate(s.Effective_Date, ps.Start_Time, @ReportStartTime) <= dbo.fnGEPSMinDate(s.Expiration_Date, ps.End_Time, @ReportEndTime)
 	 /********************************************************************
 	 * 	  	  	  	  	  	  	 Gaps 	  	  	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 -- Insert gaps
 	 INSERT INTO #Periods ( 	 StartTime,
 	  	  	  	  	  	  	 EndTime,
 	  	  	  	  	  	  	 TableId)
 	 SELECT 	 p1.EndTime,
 	  	  	 @ReportEndTime,
 	  	  	 p1.TableId
 	 FROM #Periods p1
 	  	 LEFT JOIN #Periods p2 ON 	 p1.TableId = p2.TableId
 	  	  	  	  	  	  	  	  	 AND p1.EndTime = p2.StartTime
 	 WHERE 	 p1.EndTime < @ReportEndTime
 	  	  	 AND p2.PeriodId IS NULL
 	 /********************************************************************
 	 * 	  	  	  	  	  	  	 Slices 	  	  	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 -- Create slices
 	 INSERT INTO #Slices ( 	 PUId,
 	  	  	  	  	  	  	 StartTime)
 	 SELECT DISTINCT 	 0,
 	  	  	  	  	 StartTime
 	 FROM #Periods
 	 ORDER BY StartTime ASC
 	 SELECT @Rows = @@rowcount
 	 -- Correct the end times
 	 UPDATE s1
 	 SET s1.EndTime 	  	 = s2.StartTime,
 	  	 s1.CalendarTime 	 = datediff(s, s1.StartTime, s2.StartTime)
 	 FROM #Slices s1
 	  	 JOIN #Slices s2 ON s2.SliceId = s1.SliceId + 1
 	 WHERE s1.SliceId < @Rows
 	 UPDATE #Slices
 	 SET EndTime  	  	 = @ReportEndTime,
 	  	 CalendarTime 	 = datediff(s, StartTime, @ReportEndTime)
 	 WHERE SliceId = @Rows
 	 -- Update each slice with the relative table information
 	 UPDATE s
 	 SET 	 PUId 	 = ps.PU_Id,
 	  	 ProdId 	 = ps.Prod_Id
 	 FROM #Slices s
 	  	 LEFT JOIN #Periods p ON p.TableId = @ProductionStartsTableId
 	  	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	  	 LEFT JOIN dbo.Production_Starts ps WITH (NOLOCK) ON p.KeyId = ps.Start_Id
 	 WHERE 	 s.PUId = 0
 	  	  	 AND p.KeyId IS NOT NULL
 	 UPDATE s
 	 SET NP = 1
 	 FROM #Slices s
 	  	 LEFT JOIN #Periods p ON p.TableId = @NonProductiveTableId
 	  	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	 WHERE p.KeyId IS NOT NULL 
 	 
 	 
 	 UPDATE s
 	 SET DowntimeTarget = sp.Target
 	 FROM #Slices s
 	  	 LEFT JOIN #Periods p ON p.TableId = @DowntimeSpecsTableId
 	  	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	  	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
 	 WHERE p.KeyId IS NOT NULL
 	 UPDATE s
 	 SET ProductionTarget = sp.Target
 	 FROM #Slices s
 	  	 LEFT JOIN #Periods p ON p.TableId = @ProductionSpecsTableId
 	  	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	  	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
 	 WHERE p.KeyId IS NOT NULL
 	 UPDATE s
 	 SET WasteTarget = sp.Target
 	 FROM #Slices s
 	  	 LEFT JOIN #Periods p ON p.TableId = @WasteSpecsTableId
 	  	  	  	  	  	  	  	 AND p.StartTime <= s.StartTime
 	  	  	  	  	  	  	  	 AND p.EndTime > s.StartTime
 	  	  	 LEFT JOIN dbo.Active_Specs sp WITH (NOLOCK) ON p.KeyId = sp.AS_Id
 	 WHERE p.KeyId IS NOT NULL
 	 DECLARE @SlicesRowCount int, @RowId int,@NP int
 	 SELECT @SlicesRowCount = Count(SliceId) FROM #Slices
 	 SET @RowId = 0
 	 /********************************************************************
 	 * 	  	  	  	  	  	  	 Downtime 	  	  	  	  	  	  	  	 *
 	 ********************************************************************/
 	 -- Calculate the downtime statistics for each slice
 	 -- Calculate 'Planned Downtime' and 'Available Time'
 	 SELECT 	 @DowntimePlannedSum =0,@AvailableTimeSum = 0,@DowntimeExternalSum=0,@LoadingTimeSum=0,@DowntimePerformanceSum=0,
 	  	  	 @DowntimeTotalSum=0,@DowntimeUnplannedSum 	 =0,@RunTimeGrossSum = 0,@ProductiveTimeSum=0,@WasteQuantitySum =0,@ProductionTotalSum=0,@ProductionIdealSum=0,
 	  	  	 @TotalAvailableTimeSum=0,@ProductionNetSum=0,@RunTimeGrossSumIdeal = 0,@ActualTime = 0
 	 SELECT @oeeHighAlarmCount=0,@oeeMediumAlarmCount=0,@oeeLowAlarmCount=0,@HighAlarmCount=0,@MediumAlarmCount=0,@LowAlarmCount=0
 	 WHILE @RowId <@SlicesRowCount
 	  	 BEGIN
 	  	 Loop_Start:
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
 	  	  	  	  	  
 	  	  	  	  	 If Not(@FilterNonProductiveTime=0 OR @NP=0) 	 GOTO Loop_Start
 	  	  	  	  	 SELECT @DowntimePlanned= isnull(sum(datediff(s,CASE 	 WHEN ted.Start_Time < @St
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 THEN @St
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 THEN @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END)),0)
 	  	  	  	  	 FROM dbo.Timed_Event_Details ted WITH (NOLOCK)   
 	  	  	  	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @ScheduledCategoryId
 	  	  	  	  	 WHERE ted.PU_Id = @ReportPUId
 	  	  	  	  	  	  	  	 AND ted.Start_Time < @Et
 	  	  	  	  	  	  	  	 AND (ted.End_Time > @St or ted.End_Time is Null)
 	  	  	 SET @AvailableTime = CASE WHEN isnull(@CalendarTime,0) >= isnull( @DownTimePlanned,0)
 	  	  	  	  	  	  	  	  	   THEN @CalendarTime - isnull(@DownTimePlanned,0)
 	  	  	  	  	  	  	  	  ELSE 0
 	  	  	  	  	  	  	  	  END
 	  	  	 SELECT 	 @DowntimeExternal = isnull(sum(datediff(s, CASE 	 WHEN ted.Start_Time < @st
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 THEN @St
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 THEN @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 END)),0)
 	  	  	  	  	  	  	  	  	  	  	   
 	  	  	  	  	  	  	 FROM  dbo.Timed_Event_Details ted WITH (NOLOCK) 
 	  	  	  	  	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @ExternalCategoryId
 	  	  	  	  	  	  	 WHERE ted.PU_Id=@ReportPUId
 	  	  	  	  	  	  	  	  	  	  	 AND ted.Start_Time < @Et
 	  	  	  	  	  	  	  	  	  	  	 AND ted.End_Time > @St
 	  	  	 SET @LoadingTime = CASE 	 WHEN @AvailableTime >= isnull(@DowntimeExternal,0)
 	  	  	  	  	  	  	  	  	 THEN @AvailableTime - isnull(@DowntimeExternal, 0)
 	  	  	  	  	  	  	  	 ELSE 0
 	  	  	  	  	  	  	  	 END
 	  	  	 -- Calculate 'Performance Downtime'
 	  	  	 SELECT @DowntimePerformance = 	   isnull(sum(datediff(s, CASE 	 WHEN ted.Start_Time < @St
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 THEN @St
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	   CASE 	 WHEN ted.End_Time > @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 THEN @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	   END)),0) 
 	  	  	 FROM dbo.Timed_Event_Details ted WITH (NOLOCK) 
 	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @PerformanceCategoryId
 	  	  	 WHERE ted.PU_Id = @ReportPUId
 	  	  	  	  	   AND ted.Start_Time < @Et
 	  	  	  	  	   AND (ted.End_Time > @St OR ted.End_Time is NULL)
 	  	  	 -- Calculate 'Unplanned Downtime' and 'Run Time'
 	  	  	 SELECT @DowntimeTotal = 	  isnull(sum(datediff(s, CASE 	 WHEN ted.Start_Time < @St
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 THEN @St
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 CASE 	 WHEN ted.End_Time > @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 OR ted.End_Time IS NULL
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 THEN @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE ted.End_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END) ),0)
 	  	  	 FROM  dbo.Timed_Event_Details ted WITH (NOLOCK) 
 	  	  	 WHERE ted.PU_Id = @ReportPUId
 	  	  	  	  	 AND ted.Start_Time < @Et
 	  	  	  	  	 AND (ted.End_Time > @St OR ted.End_Time is NULL)
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
 	  	 * 	  	  	  	  	  	  	  	 Waste 	  	  	  	  	  	  	  	 *
 	  	 ********************************************************************/
 	  	  	 -- Collect time-based waste
 	  	  	 
 	  	  	 SELECT 	 @WasteQuantity 	  	 = ISNULL(sum(wed.Amount),0)
 	  	  	 FROM dbo.Waste_Event_Details wed WITH (NOLOCK) 
 	  	  	 WHERE 	 wed.PU_Id = @ReportPUId
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
 	  	  	  	  	  	  	  	  	  	  	 LEFT JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 wed.PU_Id = @ReportPUId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Amount IS NOT NULL
 	  	  	  	  	  	  	  	  	 WHERE 	 e.PU_Id = @ReportPUId
 	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp >= @St
 	  	  	  	  	  	  	  	  	  	  	 AND isnull(e.Start_Time, e.TimeStamp) < @Et
 	  	  	  	 
 	  	  	  	 END
 	  	  	 ELSE 	  	 -- Doesn't use start time so don't pro-rate quantity
 	  	  	 BEGIN
 	  	  	 
 	  	  	  	 SELECT @WasteQuantity = @WasteQuantity+ isnull(sum(wed.Amount),0)
 	  	  	  	 FROM  dbo.Events e WITH (NOLOCK) 
 	  	  	  	  	   JOIN dbo.Waste_Event_Details wed WITH (NOLOCK) ON 	 wed.PU_Id = @ReportPUId
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND wed.Amount IS NOT NULL
 	  	  	  	 WHERE  e.PU_Id = @ReportPUId
 	  	  	  	  	  	 AND e.TimeStamp >= @St
 	  	  	  	  	  	 AND e.TimeStamp <  @Et
 	  	  	 END
 	  	 /********************************************************************
 	  	 * 	  	  	  	  	  	  	 Production 	  	  	  	  	  	  	  	 *
 	  	 ********************************************************************/
 	  	  
 	  	  	 IF @ProductionType = 1
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT 	 @ProductionTotal = isnull(sum(convert(Float, t.Result)),0)  
 	  	  	  	  	 FROM 	 dbo.Tests t WITH (NOLOCK) 
 	  	  	  	  	 WHERE 	 t.Var_Id = @ProductionVarId
 	  	  	  	  	  	  	 AND t.Result_On >= @St
 	  	  	  	  	  	  	 AND t.Result_On < @Et
 	  	  	  	  	  	  	  	 
 	  	  	  	  	 SELECT 	 @ProductionNet 	  	 = isnull(@ProductionTotal,0) - @WasteQuantity,
 	  	  	  	  	  	  	 @ProductionIdeal 	 = dbo.fnGEPSIdealProduction(@RunTimeGross,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionTarget,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionRateFactor,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionTotal)
 	  	  	  	 END
 	  	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 IF @ProductionStartTime = 1 	 -- Uses start time so pro-rate quantity
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT @ProductionTotal = 	 isnull(sum( CASE 	 WHEN e.Start_Time IS NOT NULL THEN
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 convert(Float, datediff(s, CASE 	 WHEN e.Start_Time < @St THEN @St
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.Start_Time
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	   CASE 	 WHEN e.TimeStamp > @Et THEN @Et
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE e.TimeStamp
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 / convert(Float, datediff(s, e.Start_Time, e.TimeStamp))
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 * isnull(ed.Initial_Dimension_X,0)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 ELSE isnull(ed.Initial_Dimension_X,0)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 END),0) 
 	  	  	  	  	  	  	  	  	  	 FROM dbo.Events e WITH (NOLOCK) 
 	  	  	  	  	  	  	  	  	  	  	  	 JOIN dbo.Production_Status ps WITH (NOLOCK) ON 	 e.Event_Status = ps.ProdStatus_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ps.Count_For_Production = 1
 	  	  	  	  	  	  	  	  	  	  	  	 LEFT JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	  	 WHERE  e.PU_Id =@ReportPUId
 	  	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp > @St
 	  	  	  	  	  	  	  	  	  	  	  	 AND isnull(e.Start_Time, e.TimeStamp) < @Et -- Note: if starttime is null it assumes that starttime = endtime
 	  	  	  	  	  	  	  	  	  	 
 	  	  	  	  	  	  	 
 	  	  	  	  	  	  	   SELECT @ProductionNet 	  	 = isnull(@ProductionTotal,0) - @WasteQuantity,
 	  	  	  	  	  	  	  	  	  @ProductionIdeal 	 = dbo.fnGEPSIdealProduction(@RunTimeGross,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionTarget,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionRateFactor,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionTotal)
 	  	  	  	  	  	  	  	  	  	 
 	  	  	  	  	  	 END
 	  	  	  	  	 ELSE -- Doesn't use start time so don't pro-rate quantity
 	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 SELECT @ProductionTotal 	 = 	 isnull(sum(ed.Initial_Dimension_X)  ,0)
 	  	  	  	  	  	  	  	  	  	 FROM dbo.Events e WITH (NOLOCK) 
 	  	  	  	  	  	  	  	  	  	  	 JOIN dbo.Event_Details ed WITH (NOLOCK) ON ed.Event_Id = e.Event_Id
 	  	  	  	  	  	  	  	  	 WHERE  e.PU_Id = @ReportPUId
 	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp >= @St
 	  	  	  	  	  	  	  	  	  	  	 AND e.TimeStamp < @Et
 	  	  	  	  	  	  	 SELECT @ProductionNet 	 = isnull(@ProductionTotal,0) - @WasteQuantity,
 	  	  	  	  	  	  	  	    @ProductionIdeal 	 = dbo.fnGEPSIdealProduction(@RunTimeGross,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionTarget,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionRateFactor,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionTotal)
 	  	  	  	  	  	 END
 	  	  	  	 
 	  	  	  	 END
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
        SET @WasteQuantitySum = CASE WHEN @WasteQuantitySum > @ProductionTotalSum THEN @ProductionTotalSum ELSE @WasteQuantitySum END
 	  	 /********************************************************************
 	  	 * 	  	  	  	  	  	  	 Alarm Info 	  	  	  	  	  	  	  	 *
 	  	 ********************************************************************/
 	  	 DECLARE @RowsProductive int,@RowProductive int
 	  	 DECLARE @curStartTime datetime,@curEndTime datetime
 	  	 SELECT @oeeHighAlarmCount=0,@oeeMediumAlarmCount=0,@oeeLowAlarmCount=0,@HighAlarmCount=0,@MediumAlarmCount=0,@LowAlarmCount=0
 	  	 IF( @FilterNonProductiveTime = 1)
 	  	  	 INSERT INTO #ProductiveTimes(StartTime,EndTime) EXEC spDBR_GetProductiveTimes @ReportPUID,@ReportStartTime,@ReportEndTime
 	  	 ELSE
 	  	  	 INSERT INTO #ProductiveTimes(StartTime,EndTime) SELECT @ReportStartTime,@ReportEndTime
 	  	 SET @RowsProductive = @@Rowcount 
 	  	 SET @RowProductive = 0
 	  	 
 	  	 WHILE @RowProductive < @RowsProductive
 	  	 BEGIN 	 
 	  	  	 SELECT @RowProductive = @RowProductive + 1
 	  	  	 SELECT @curStartTime= StartTime, @curEndTime = EndTime 
 	  	  	 FROM #ProductiveTimes 
 	  	  	 WHERE ROWID = @RowProductive
 	 
  	  	  	 EXECUTE spCMN_GetUnitAlarmCounts @ReportPUId,@curStartTime,@curEndTime,@HighAlarmCount OUTPUT,@MediumAlarmCount OUTPUT,@LowAlarmCount OUTPUT
 	  	  	 SELECT @oeeHighAlarmCount = @oeeHighAlarmCount + isnull(@HighAlarmCount,0), @oeeMediumAlarmCount = @oeeMediumAlarmCount + isnull(@MediumAlarmCount,0), @oeeLowAlarmCount = @oeeLowAlarmCount + isnull(@LowAlarmCount,0)
 	  	 END
 	  	 
 	  	 /********************************************************************
 	  	 * 	  	  	  	  	 Overall Summary
 	  	 ********************************************************************/
 	  	  PRINT '----- Summing up---'
 	  	 
 	  	 INSERT INTO @UnitSummary(UnitID,
 	  	  	  	  	  	  	  	  	  	  	 UnitName,
 	  	  	  	  	  	  	  	  	  	  	 ActualSpeed,
 	  	  	  	  	  	  	  	  	  	  	 IdealProductionAmount,
 	  	  	  	  	  	  	  	  	  	  	 IdealSpeed,
 	  	  	  	  	  	  	  	  	  	  	 PerformanceRate,
 	  	  	  	  	  	  	  	  	  	  	 ProductionAmount,
 	  	  	  	  	  	  	  	  	  	  	 WasteAmount,
 	  	  	  	  	  	  	  	  	  	  	 AmountEngineeringUnits,
 	  	  	  	  	  	  	  	  	  	  	 SpeedEngineeringUnits,
 	  	  	  	  	  	  	  	  	  	  	 QualityRate,
 	  	  	  	  	  	  	  	  	  	  	 PerformanceTime,
 	  	  	  	  	  	  	  	  	  	  	 RunTime,
 	  	  	  	  	  	  	  	  	  	  	 LoadingTime,
 	  	  	  	  	  	  	  	  	  	  	 DowntimePlanned,
 	  	  	  	  	  	  	  	  	  	  	 DowntimeExternal,
 	  	  	  	  	  	  	  	  	  	  	 DowntimeUnPlanned,
 	  	  	  	  	  	  	  	  	  	  	 DowntimeTotal,
 	  	  	  	  	  	  	  	  	  	  	 AvailableRate,
 	  	  	  	  	  	  	  	  	  	  	 HighAlarmCount,
 	  	  	  	  	  	  	  	  	  	  	 MediumAlarmCount,
 	  	  	  	  	  	  	  	  	  	  	 LowAlarmCount,
 	  	  	  	  	  	  	  	  	  	  	 PercentOEE)
 	  	  	  	  	 -- Total
 	  	  	  	  	 
 	  	  	  	  	 SELECT 	 
 	  	  	  	  	  	 @ReportPUID,
 	  	  	  	  	  	 @UnitName,
  	  	  	  	  	  	 dbo.fnGEPSActualSpeed( 	 @RunTimeGrossSumIdeal ,@ProductionTotalSum,@ProductionRateFactor),
 	  	  	  	  	  	 @ProductionIdealSum,
 	  	  	  	  	  	 dbo.fnGEPSIdealSpeed( 	 @RunTimeGrossSumIdeal,@ProductionIdealSum,@ProductionRateFactor),
 	  	  	  	  	  	 PerformanceRate 	  	 =   dbo.fnGEPSPerformance(@ProductionTotalSum,@ProductionIdealSum,@CapRates),
 	  	  	  	  	  	 Production 	  	  	 = @ProductionNetSum,
 	  	  	  	  	  	 WasteQuantity 	  	 = @WasteQuantitySum,
 	  	  	  	  	  	 @AmountEngineeringUnits,
 	  	  	  	  	  	 SpeedEngineeringUnits = Case
 	  	  	  	  	  	  	  	  	 When @TimeEngineeringUnits = 0 Then  -- /hour
 	  	  	  	  	  	  	  	  	   @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38364, 'hr') 
 	  	  	  	  	  	  	  	  	 When @TimeEngineeringUnits = 2 Then 	 -- /second
 	  	  	  	  	  	  	  	  	   @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38366, 'sec') 
 	  	  	  	  	  	  	  	  	 When @TimeEngineeringUnits = 3 Then 	 -- /day
 	  	  	  	  	  	  	  	  	   @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38367, 'day') 
 	  	  	  	  	  	  	  	  	 Else 	  	  	  	  	  	  	  	 -- /min
 	  	  	  	  	  	  	  	  	   @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38365, 'min') 
 	  	  	  	  	  	  	  	  	 End,
 	  	  	  	  	  	 dbo.fnGEPSQuality(@ProductionTotalSum,@WasteQuantitySum,@CapRates),
 	  	  	  	  	  	 dbo.fnRS_MakeTimeDurationString(@DowntimePerformanceSum),
 	  	  	  	  	  	 dbo.fnRS_MakeTimeDurationString(@ProductiveTimeSum) AS [RunTime],
 	  	  	  	  	  	 LoadingTime 	  	  	 = dbo.fnRS_MakeTimeDurationString(@LoadingTimeSum),
 	  	  	  	  	  	 dbo.fnRS_MakeTimeDurationString(@DowntimePlannedSum),
 	  	  	  	  	  	 dbo.fnRS_MakeTimeDurationString(@DowntimeExternalSUM),
 	  	  	  	  	  	 dbo.fnRS_MakeTimeDurationString(@DowntimeUnplannedSum),
 	  	  	  	  	  	 dbo.fnRS_MakeTimeDurationString(@DowntimeTotalSum),
 	  	  	  	  	  	 dbo.fnGEPSAvailability( 	 @LoadingTimeSum,@RunTimeGrossSum,@CapRates),
 	  	  	  	  	  	 @oeeHighAlarmCount,
 	  	  	  	  	  	 @oeeMediumAlarmCount,
 	  	  	  	  	  	 @oeeLowAlarmCount,
 	  	  	  	  	  	 dbo.fnGEPSAvailability(@LoadingTimeSum,@RunTimeGrossSum,@CapRates)/100
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 * dbo.fnGEPSPerformance(@ProductionTotalSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionIdealSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @CapRates)/100
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 * dbo.fnGEPSQuality( 	 @ProductionTotalSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @WasteQuantitySum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @CapRates)/100
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 *100 
 	  	  	  	  	 
 	  	  	  	  	 SELECT @oee 	  	  	 = dbo.fnGEPSAvailability(@LoadingTimeSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @RunTimeGrossSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @CapRates)/100
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 * dbo.fnGEPSPerformance(@ProductionTotalSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @ProductionIdealSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @CapRates)/100
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 * dbo.fnGEPSQuality( 	 @ProductionTotalSum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @WasteQuantitySum,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @CapRates)/100
 	  	  	  	  	  	  	  	  	  	  	  	  	  	 *100 
 	  	  
 	  	  	 UPDATE @UnitSummary
 	  	  	 SET CategoryID  = @PerformanceCategoryId,
 	  	  	  	 Production_Variable = 	 @ProductionVarId,
 	  	  	  	 CurrentStatusIcon 	 = 	 @oeeStatus
 	  	  	 WHERE UnitID = @ReportPUID
 	  	  	  	 
 	  	  	 --If Efficiency Based keep track of OEE so I can summarize it in the end 	 
 	  	  	 IF (not @ProductionVarId is null)
 	  	  	  	 INSERT INTO @OEEs VALUES(@oee)
 	  	  	 
 	  	  	 --<Converting to TIME BASED Calculation>
 	  	  	 Declare @OEEType varchar(10), @IsNPTIncluded BIT = 0
 	  	  	 set @OEEType  = ''
 	  	  	 Select 
 	  	  	  	 @OEEType = EDFTV.Field_desc
 	  	  	 From 
 	  	  	  	 Table_Fields TF
 	  	  	  	 JOIN Table_Fields_Values TFV on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
 	  	  	  	 Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
 	  	  	  	 LEFT OUTER Join ED_FieldType_ValidValues EDFTV on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
 	  	  	 Where 
 	  	  	  	 TF.Table_Field_Desc = 'OEE Calculation Type'
 	  	  	  	 AND TFV.KeyID = @ReportPUID
 	  	  	 
 	  	  	 DECLARE @AvailabilityName varchar(50), @PerformanceName varchar(50), @PlannedName varchar(50), @QualityName varchar(50),@AvailabilityCategoryId Int, @PerformanceTimedCategoryId Int,@PlannedCategoryId Int, @QualityCategoryId Int,@NPTimedCategoryId Int, @NonProductiveSeconds Int,@AvailabilitySeconds Int, @PerformanceSeconds Int,@PlannedSeconds Int, @QualitySeconds Int,@CalendarSeconds Int, @ActivityTime Int = 0,@UtilizationTime Int = 0, @WorkingTime Int = 0,@UsedTime Int = 0, @EffectivelyUsedTime Int = 0
 	  	  	 DECLARE @NonProductiveTime TABLE (RowID int IDENTITY, 	 StartTime DateTime,EndTime DateTime)
 	  	  	 DECLARe @ProductiveTime1 TABLE(  	 RowID int IDENTITY, 	 StartTime DateTime, 	 EndTime DateTime)
 	  	  	 DECLARE @TimedDetails TABLE(StartTime DateTime,EndTime DateTime,ERCId Int)
 	  	  	 Declare @LastProductiveTimeRowID int, @CurrentProductiveRowID int,@CurrentProductiveStartTime Datetime, @CurrentProductiveEndTime datetime,@SliceCnt int,@cnt int
 	  	  	 SELECT @AvailabilityName = 'Availability',@PerformanceName = 'Performance',@PlannedName = 'Planned',@QualityName = 'Quality'
 	  	  	 SELECT @AvailabilityCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @AvailabilityName
 	  	  	 SELECT @PerformanceTimedCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @PerformanceName
 	  	  	 SELECT @PlannedCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @PlannedName
 	  	  	 SELECT @QualityCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @QualityName
 	  	  	 SELECT @NPTimedCategoryId 	 = Non_Productive_Category
 	  	  	  	 FROM dbo.Prod_Units WITH (NOLOCK)
 	  	  	  	 WHERE PU_Id = @ReportPUID
 	  	  	 
 	  	  	 DELETE FROM @NonProductiveTime
 	  	  	 INSERT INTO @NonProductiveTime(StartTime,EndTime) 
 	  	  	 SELECT CASE WHEN np.Start_Time < @ReportStartTime THEN @ReportStartTime
 	  	  	  	  	  	  	  	  	 ELSE np.Start_Time
 	  	  	  	  	  	  	  	  	 END,
 	  	  	  	    CASE WHEN np.End_Time > @ReportEndTime THEN @ReportEndTime
 	  	  	  	  	  	  	  	  	 ELSE np.End_Time
 	  	  	  	  	  	  	  	  	 END
 	  	  	 FROM dbo.NonProductive_Detail np WITH (NOLOCK)
 	  	  	 JOIN dbo.Event_Reason_Category_Data ercd WITH (NOLOCK) ON 	 ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 AND ercd.ERC_Id = @NPTimedCategoryId
 	  	  	 WHERE 	 PU_Id = @ReportPUID
 	  	  	  	 AND np.Start_Time < @ReportEndTime
 	  	  	  	 AND np.End_Time > @ReportStartTime
 	  	  	 SELECT 	 @NonProductiveSeconds = coalesce(SUM(DATEDIFF(SECOND,StartTime,EndTime)),0)
 	  	  	 FROM @NonProductiveTime
 	  	  	 
 	  	  	 DELETE FROM @ProductiveTime1
 	  	  	 INSERT INTO @ProductiveTime1(StartTime)
 	  	  	 SELECT @ReportStartTime
 	  	  	 
 	  	  	 INSERT INTO @ProductiveTime1(StartTime)
 	  	  	 SELECT EndTime
 	  	  	 FROM @NonProductiveTime
 	  	  	 WHERE EndTime < @ReportEndTime
 	  	  	 
 	  	  	 UPDATE p
 	  	  	 SET p.EndTime = coalesce(npt.StartTime,@ReportEndTime)
 	  	  	 FROM @ProductiveTime1 p
 	  	  	 LEFT JOIN @NonProductiveTime npt on npt.RowID = p.RowId
 	  	  	 DELETE @ProductiveTime1 WHERE StartTime = EndTime
 	 
 	  	  	 SELECT @LastProductiveTimeRowID = MAX(RowID),
 	  	  	  	 @CurrentProductiveRowID = MIN(RowID)
 	  	  	 FROM @ProductiveTime1
 	 
 	  	  	 DELETE @TimedDetails
 	  	  	 WHILE @CurrentProductiveRowID <= @LastProductiveTimeRowID
 	  	  	 BEGIN
 	  	  	  	 SELECT @CurrentProductiveStartTime = StartTime,
 	  	  	  	  	 @CurrentProductiveEndTime = EndTime
 	  	  	  	 FROM @ProductiveTime1
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
 	  	  	  	 WHERE ted.PU_Id = @ReportPUId
 	  	  	  	  	 AND ted.Start_Time < @CurrentProductiveEndTime
 	  	  	  	  	 AND (ted.End_Time > @CurrentProductiveStartTime or ted.End_Time Is Null)
  	  	  	  	 SELECT @CurrentProductiveRowID = @CurrentProductiveRowID + 1
 	  	  	 END
 	  	  	 ;WITH TimedDetails As ( 	 Select  coalesce(SUM(DATEDIFF(second, StartTime, EndTime)),0) Duration, ERCID, (Select ERC_Desc from Event_Reason_Catagories where ERC_ID = A.ERCID) ERCDesc,@NonProductiveSeconds NPT from @TimedDetails A Group BY ERCID)
 	  	  	 UPDATE A
 	  	  	 SET
 	  	  	  	 A.NPT = @NonProductiveSeconds/60,
 	  	  	  	 A.DowntimeA = (select SUM(Duration)/60 from TimedDetails Where ERCDesc in ('Availability') ),
 	  	  	  	 A.DowntimeP = (select SUM(Duration)/60  from TimedDetails Where  ERCDesc   in ('Performance') ),
 	  	  	  	 A.DowntimeQ = (select SUM(Duration)/60  from TimedDetails Where  ERCDesc   in ('Quality')),
 	  	  	  	 A.DowntimePL = (select SUM(Duration)/60  from TimedDetails Where  ERCDesc   in ('Planned'))
 	  	  	 FROM @UnitSummary A 
 	  	  	 Where A.UnitID = @ReportPUID
 	  	  	 UPDATE A
 	  	  	 SET 
 	  	  	  	 A.DownTimeA = Case When @OEEType <>'Time Based' Then (@LoadingTimeSum) - (@RunTimeGrossSum) Else (DowntimeA) End,
 	  	  	  	 A.DowntimeP = Case When @OEEType <>'Time Based' Then Case when (@ProductionIdealSum) > 0 Then ((@RunTimeGrossSum)*(@ProductionIdealSum)-(@RunTimeGrossSum)*(@ProductionTotalSum))/(@ProductionIdealSum)else 0 end Else (DowntimeP) End,
 	  	  	  	 A.DowntimeQ = Case When @OEEType <>'Time Based' Then Case when (@ProductionIdealSum) > 0 Then (((@RunTimeGrossSum)*(@ProductionTotalSum))-((@RunTimeGrossSum)*(@ProductionNetSum)))/(@ProductionIdealSum) else 0 end Else (DowntimeQ) End,
 	  	  	  	 A.DowntimePL = isnull((DowntimePL),0) 
 	  	  	 FROM @UnitSummary A 
 	  	  	  	 Where A.UnitID = @ReportPUID
 	  	  	 
 	  	  	 UPDATE A 
 	  	  	 SET 
 	  	  	  	 A.DownTimeA  = ISNULL(A.DownTimeA ,0),
 	  	  	  	 A.DownTimeP  = ISNULL(A.DownTimeP ,0),
 	  	  	  	 A.DownTimeQ  = ISNULL(A.DownTimeQ ,0),
 	  	  	  	 A.DownTimePL  = ISNULL(A.DownTimePL ,0)
 	  	  	 FROM @UnitSummary A 
 	  	  	  	 Where A.UnitID = @ReportPUID
 	  	  	 UPDATE A
 	  	  	 SET
 	  	  	  	 AvailableRate = cast(CASE WHEN (@LoadingTimeSum  - DowntimePL) <= 0 THEN 0 ELSE (Cast(@LoadingTimeSum  - DowntimePL - DowntimeA as float)/cast(@LoadingTimeSum  - DowntimePL as float)) END *100 AS VARCHAR),
 	  	  	  	 PerformanceRate = CAST(CASE WHEN (@LoadingTimeSum  - DowntimePL - DowntimeA) <= 0 THEN 0 ELSE (cast(@LoadingTimeSum  - DowntimePL - DowntimeA - DowntimeP as float)/cast(@LoadingTimeSum  - DowntimePL - DowntimeA as float)) END*100 AS vARCHAR),
 	  	  	  	 QualityRate = CAST(CASE WHEN (@LoadingTimeSum  - DowntimePL - DowntimeA -DowntimeP) <= 0 THEN 0 ELSE (cast(@LoadingTimeSum  - DowntimePL - DowntimeA - DowntimeP - DowntimeQ as float)/cast(@LoadingTimeSum  - DowntimePL - DowntimeA - DowntimeP as float))  END * 100 AS VARCHAR)
 	  	  	 FROM @UnitSummary A 
 	  	  	  	 Where A.UnitID = @ReportPUID
 	  	  	 UPDATE A
 	  	  	 SET
 	  	  	  	 AvailableRate = CASE WHEN AvailableRate > 100 THEN 100 ELSE AvailableRate END,
 	  	  	  	 PerformanceRate = CASE WHEN PerformanceRate > 100 and @CapRates = 1 THEN 100 ELSE PerformanceRate END,
 	  	  	  	 QualityRate = CASE WHEN QualityRate > 100 THEN 100 ELSE QualityRate END
 	  	  	 FROM @UnitSummary A 
 	  	  	  	 Where A.UnitID = @ReportPUID
 	  	  	 
 	  	  	 Select 
 	  	  	 @DownTimeA = DownTimeA,
 	  	  	 @DownTimeP = DownTimeP,
 	  	  	 @DownTimeQ = DownTimeQ,
 	  	  	 @DownTimePL = DownTimePL
 	  	  	 FROM @UnitSummary A 
 	  	  	  	 Where A.UnitID = @ReportPUID
 	  	  	  	 UPDATE A
 	  	  	  	 SET A.PercentOEE = (AvailableRate*PerformanceRate*QualityRate)/10000
 	  	  	  	 FROM @UnitSummary A 
 	  	  	  	 Where A.UnitID = @ReportPUID
 	  	  	  	 
 	  	  	 --</Converting to TIME BASED Calculation>
 	  	  	 INSERT INTO @Totals
 	  	  	 Values(@ProductionTotalSum,@ProductionIdealSum,@WasteQuantitySum,@ProductiveTimeSum,@LoadingTimeSum,@WasteQuantitySum,@DowntimePerformanceSUM,@DownTimeA,@DownTimeP,@DownTimeQ,@DownTimePL)
 	 
 	  	  	  	  	  	 
 	  	  	 -- Clean up All temp data for Next Unit 	 
 	  	  	 TRUNCATE TABLE #ProductiveTimes
 	  	  	 TRUNCATE TABLE #Slices
 	  	  	 TRUNCATE TABLE #Periods
END
SELECT @AccumProduction = Sum(AccumProduction) ,
 @AccumIdealProduction = Sum(AccumIdealProduction),
 @AccumQualityLoss = Sum(AccumWaste),
 @AccumRunningTime = Sum(AccumRunningTime),
 @AccumLoadingTime =Sum(AccumLoadingTime),
 @AccumWaste = Sum(AccumWaste),
 @AccumPerformanceTime = Sum(AccumPerformanceTime)
 ,@SUMDownTimeA = Sum(AccumDownTimeA)
 ,@SUMDownTimeP = Sum(AccumDownTimeP)
 ,@SUMDownTimeQ = Sum(AccumDownTimeQ)
 ,@SUMDownTimePL = Sum(AccumDownTimePL)
FROM @Totals
--*****************************************************/
EXECUTE spDBR_GetColumns @ColumnVisibility
--*****************************************************/
IF (@summarize = 1)
 	 IF (@UnitRows = 1)
 	 BEGIN
 	 
 	  	 INSERT INTO @UnitSummary (UnitName, IdealProductionAmount, ProductionAmount, AmountEngineeringUnits, ActualSpeed, IdealSpeed, SpeedEngineeringUnits, PerformanceRate, WasteAmount, QualityRate, RunTime, LoadingTime, AvailableRate,PercentOEE, UnitID, SummaryRow, PerformanceTime,DowntimePlanned,DowntimeExternal,DowntimeUnPlanned,DowntimeTotal )
 	  	  	 SELECT  	 
 	  	  	  	  	 @UnitName,
 	  	  	  	  	 IdealProductionAmount 	 = @ProductionIdealSum, 
 	  	  	  	  	 ProductionAmount 	  	 = @ProductionNetSum,
 	  	  	  	  	 AmountEngineeringUnits 	 = @AmountEngineeringUnits,
 	  	  	  	  	 ActualSpeed 	  	  	 = dbo.fnGEPSActualSpeed(@RunTimeGrossSumIdeal,@ProductionTotalSum,@ProductionRateFactor),
 	  	  	  	  	 IdealSpeed 	  	  	 = dbo.fnGEPSIdealSpeed(@RunTimeGrossSumIdeal,@ProductionIdealSum,@ProductionRateFactor),
 	  	  	  	  	 SpeedEngineeringUnits = Case
 	  	  	  	  	  	 When @TimeEngineeringUnits = 0 Then  -- /hour
 	  	  	  	  	  	   @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38364, 'hr') 
 	  	  	  	  	  	 When @TimeEngineeringUnits = 2 Then 	 -- /second
 	  	  	  	  	  	   @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38366, 'sec') 
 	  	  	  	  	  	 When @TimeEngineeringUnits = 3 Then 	 -- /day
 	  	  	  	  	  	   @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38367, 'day') 
 	  	  	  	  	  	 Else 	  	  	  	  	  	  	  	 -- /min
 	  	  	  	  	  	   @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38365, 'min') 
 	  	  	  	  	  	 End,
 	  	  	  	  	 PerformanceRate 	  	 = --dbo.fnGEPSPerformance(@ProductionTotalSum,@ProductionIdealSum,@CapRates)
 	  	  	  	  	 CASE WHEN (@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA) <= 0 THEN 0 ELSE (cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA - @SUMDownTimeP as float)/cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA as float)) END*100
 	  	  	  	  	 ,
 	  	  	  	  	 WasteAmount 	  	  	 = @WasteQuantitySum,
 	  	  	  	  	 QualityRate 	  	  	 = --dbo.fnGEPSQuality(@ProductionTotalSum,@WasteQuantitySum,@CapRates)
 	  	  	  	  	 CASE WHEN (@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA -@SUMDownTimeP) <= 0 THEN 0 ELSE (cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA - @SUMDownTimeP - @SUMDownTimeQ as float)/cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA - @SUMDownTimeP as float))  END * 100
 	  	  	  	  	 ,
 	  	  	  	  	 RunTime 	  	  	  	 = dbo.fnRS_MakeTimeDurationString(@ProductiveTimeSum),
 	  	  	  	  	 LoadingTime 	  	  	 = dbo.fnRS_MakeTimeDurationString(@LoadingTimeSum),
 	  	  	  	  	 AvailableRate 	  	  	 = 
 	  	  	  	  	 --dbo.fnGEPSAvailability( 	 @LoadingTimeSum,@RunTimeGrossSum,@CapRates)
 	  	  	  	  	 CASE WHEN (@AccumLoadingTime  - @SUMDownTimePL) <= 0 THEN 0 ELSE (Cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA as float)/cast(@AccumLoadingTime  - @SUMDownTimePL as float)) END *100
 	  	  	  	  	 ,
 	  	  	  	  	 PercentOEE 	  	  	 = --@oee
 	  	  	  	  	 (CASE WHEN (@AccumLoadingTime  - @SUMDownTimePL) <= 0 THEN 0 ELSE (Cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA as float)/cast(@AccumLoadingTime  - @SUMDownTimePL as float)) END)
*(CASE WHEN (@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA) <= 0 THEN 0 ELSE (cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA - @SUMDownTimeP as float)/cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA as float)) END)
*(CASE WHEN (@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA -@SUMDownTimeP) <= 0 THEN 0 ELSE (cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA - @SUMDownTimeP - @SUMDownTimeQ as float)/cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA - @SUMDownTimeP as float))  END)*100
 	  	  	  	  	 ,
 	  	  	  	  	 UnitID  	  	  	  	 = @reportPUID, 
 	  	  	  	  	 SummaryRow 	  	  	 = 1,
 	  	  	  	  	 PerformanceTime 	  	 = dbo.fnRS_MakeTimeDurationString(@DowntimePerformanceSum),
 	  	  	  	  	 DowntimePlanned 	  	 = dbo.fnRS_MakeTimeDurationString(@DowntimePlannedSum),
 	  	  	  	  	 DowntimeExternal 	 = dbo.fnRS_MakeTimeDurationString(@DowntimeExternalSUM),
 	  	  	  	  	 DowntimeUnPlanned 	 = dbo.fnRS_MakeTimeDurationString(@DowntimeUnplannedSum),
 	  	  	  	  	 DowntimeTotal 	  	 = 	 dbo.fnRS_MakeTimeDurationString(@DowntimeTotalSum)
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	 
 	  	  	 SELECT  	 @SumPerfRate=Performance_Rate, 	 
 	  	  	  	  	 @SumAvailRate=Available_Rate, 	 
 	  	  	  	  	 @SumQualRate=Quality_Rate, 	 
 	  	  	  	  	 @SumOEERate = OEE, 	 
 	  	  	  	  	 @SumActualRate=Actual_Rate, 	 
 	  	  	  	  	 @SumIdealRate=Ideal_Rate
 	  	  	  	 FROM dbo.fnCMN_OEERates(@AccumRunningTime, @AccumLoadingTime, @AccumPerformanceTime, @AccumProduction, @AccumIdealProduction, @AccumWaste)
 	  	  	 IF (@EfficiencyBased > 0 and @NotEfficiencyBased > 0)
 	  	  	  	 SELECT @SumOEERate = null,
 	  	  	  	 @AmountEngineeringUnits = 'units'
 	  	  	 ELSE IF (@EfficiencyBased > 0)
 	  	  	  	 select @SumOEERate = (@SumPerfRate * @SumQualRate * @SumAvailRate)  -- Ramesh : Not sure about this, got the fix from Support team, Bug #32815: OEE by Units OEE% Summary should be calculated as PerfRate * QualRate * AvailRate, not simple average of Units' OEE%s
 	  	  	  	 SET @SumAvailRate = CASE WHEN (@AccumLoadingTime  - @SUMDownTimePL) <= 0 THEN 0 ELSE (Cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA as float)/cast(@AccumLoadingTime  - @SUMDownTimePL as float)) END*100
 	  	  	  	 SET @SumPerfRate = CASE WHEN (@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA) <= 0 THEN 0 ELSE (cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA - @SUMDownTimeP as float)/cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA as float)) END*100
 	  	  	  	 SET @SumQualRate = CASE WHEN (@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA -@SUMDownTimeP) <= 0 THEN 0 ELSE (cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA - @SUMDownTimeP - @SUMDownTimeQ as float)/cast(@AccumLoadingTime  - @SUMDownTimePL - @SUMDownTimeA - @SUMDownTimeP as float))  END * 100
 	  	  	  	 SET @SumAvailRate = CASE WHEN @SumAvailRate >100 THEN 100 ELSE @SumAvailRate END
 	  	  	  	 SET @SumPerfRate = CASE WHEN @SumPerfRate >100 and @CapRates = 1 THEN 100 ELSE @SumPerfRate END
 	  	  	  	 SET @SumQualRate = CASE WHEN @SumQualRate >100 THEN 100 ELSE @SumQualRate END
 	  	  	  	 select @SumOEERate = (@SumPerfRate * @SumQualRate * @SumAvailRate)/10000
 	  	  	 
 	  	  	 INSERT INTO @UnitSummary ( 	  UnitName, 
 	  	  	  	  	  	  	  	  	  	 IdealProductionAmount, 
 	  	  	  	  	  	  	  	  	  	 ProductionAmount,
 	  	  	  	  	  	  	  	  	  	 AmountEngineeringUnits, 
 	  	  	  	  	  	  	  	  	  	 ActualSpeed, IdealSpeed, 
 	  	  	  	  	  	  	  	  	  	 SpeedEngineeringUnits, 
 	  	  	  	  	  	  	  	  	  	 PerformanceRate, 
 	  	  	  	  	  	  	  	  	  	 WasteAmount, 
 	  	  	  	  	  	  	  	  	  	 QualityRate, RunTime, LoadingTime, AvailableRate, PercentOEE,UnitID, SummaryRow, PerformanceTime)
 	  	  	  	 VALUES ( 'Summary',  @AccumIdealProduction, @AccumProduction,   @AmountEngineeringUnits,  Case
  	    	    	    	    	    	    	  When @TimeEngineeringUnits = 0 Then  -- /hour
 	  	  	  	  	  	  	  	 @SumActualRate * 60
  	    	    	    	    	    	    	  When @TimeEngineeringUnits = 2 Then  	  -- /second
 	  	  	  	  	  	  	  	 @SumActualRate / 60
  	    	    	    	    	    	    	  When @TimeEngineeringUnits = 3 Then  	  -- /day
 	  	  	  	  	  	  	  	 @SumActualRate * 1440
  	    	    	    	    	    	    	  Else  	    	    	    	    	    	    	    	  -- /min
 	  	  	  	  	  	  	  	 @SumActualRate
  	    	    	    	    	    	    	  End, Case
  	    	    	    	    	    	    	  When @TimeEngineeringUnits = 0 Then  -- /hour
 	  	  	  	  	  	  	  	 @SumIdealRate * 60
  	    	    	    	    	    	    	  When @TimeEngineeringUnits = 2 Then  	  -- /second
 	  	  	  	  	  	  	  	 @SumIdealRate / 60
  	    	    	    	    	    	    	  When @TimeEngineeringUnits = 3 Then  	  -- /day
 	  	  	  	  	  	  	  	 @SumIdealRate * 1440
  	    	    	    	    	    	    	  Else  	    	    	    	    	    	    	    	  -- /min
 	  	  	  	  	  	  	  	 @SumIdealRate
  	    	    	    	    	    	    	  End, Case
  	    	    	    	    	    	    	  When @TimeEngineeringUnits = 0 Then  -- /hour
  	    	    	    	    	    	    	    @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38364, 'hr') 
  	    	    	    	    	    	    	  When @TimeEngineeringUnits = 2 Then  	  -- /second
  	    	    	    	    	    	    	    @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38366, 'sec') 
  	    	    	    	    	    	    	  When @TimeEngineeringUnits = 3 Then  	  -- /day
  	    	    	    	    	    	    	    @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38367, 'day') 
  	    	    	    	    	    	    	  Else  	    	    	    	    	    	    	    	  -- /min
  	    	    	    	    	    	    	    @AmountEngineeringUnits + '/' + dbo.fnDBTranslate(N'0', 38365, 'min') 
  	    	    	    	    	    	    	  End,
 	  	  	  	  	  	  	 @SumPerfRate, @AccumWaste, @SumQualRate, dbo.fnRS_MakeTimeDurationString(@AccumRunningTime), dbo.fnRS_MakeTimeDurationString(@AccumLoadingTime), 
 	  	  	  	  	  	  	 @SumAvailRate, @SumOEERate, @unitList, 1, dbo.fnRS_MakeTimeDurationString(@AccumPerformanceTime))
 	  	 END
 	 UPDATE @UnitSummary
 	 SET
 	 AvailableRate = CASE WHEN AvailableRate >100 THEN 100 ELSE AvailableRate END,
 	 PerformanceRate = CASE WHEN PerformanceRate >100 and @CapRates = 1 THEN 100 ELSE PerformanceRate END,
 	 QualityRate = CASE WHEN QualityRate >100 THEN 100 ELSE QualityRate END
 	 WHERE  	 SummaryRow = 1
 	 --Handled -ve
 	 UPDATE @UnitSummary
 	 SET 
 	  	 AvailableRate = Case when AvailableRate <0 then 0 else AvailableRate end
 	  	 ,PerformanceRate = Case when PerformanceRate <0 then 0 else PerformanceRate end
 	  	 ,QualityRate = Case when QualityRate <0 then 0 else QualityRate end
 	 UPDATE @UnitSummary
 	 SET PercentOEE = (AvailableRate* PerformanceRate*QualityRate)/10000
 	 
 	 UPDATE @UnitSummary
 	 SET
 	 PercentOEE = (AvailableRate* PerformanceRate*QualityRate)/10000
 	 WHERE  	 SummaryRow = 1
IF  @spAPIUnitOEECall = 0
SELECT CurrentStatusIcon, UnitName, ProductionAmount, AmountEngineeringUnits, ActualSpeed, IdealProductionAmount, IdealSpeed, SpeedEngineeringUnits,
 	  	 PerformanceRate, WasteAmount, QualityRate, PerformanceTime, RunTime, LoadingTime, AvailableRate, PercentOEE, HighAlarmCount, MediumAlarmCount,
 	  	 LowAlarmCount, UnitId, CategoryId, Production_Variable, SummaryRow
  FROM @UnitSummary
  ORDER BY SummaryRow
ELSE
SELECT CurrentStatusIcon, UnitName, ProductionAmount, AmountEngineeringUnits, ActualSpeed, IdealProductionAmount, IdealSpeed, SpeedEngineeringUnits,
 	  	 PerformanceRate, WasteAmount, QualityRate, PerformanceTime, RunTime, LoadingTime,DowntimeExternal,DowntimePlanned,DowntimeUnPlanned,DowntimeTotal, AvailableRate, PercentOEE, HighAlarmCount, MediumAlarmCount,
 	  	 LowAlarmCount, UnitId, CategoryId, Production_Variable, SummaryRow
  FROM @UnitSummary
  ORDER BY SummaryRow
lblend:
DROP TABLE #ProductiveTimes
DROP TABLE #Periods
DROP TABLE #Slices
