 	 
CREATE FUNCTION [dbo].[fnBF_wrQuickOEESlicesTbl](
 	  @PUId_Table dbo.UnitsType READONLY,
  	  @PUId                    Int,
  	  @StartTime               datetime = NULL,
  	  @EndTime                 datetime = NULL,
  	  @InTimeZone  	    	    	    	   nvarchar(200) = null,
  	  @FilterNonProductiveTime int = 0,
  	  @ReportType Int = 1,
  	  @IncludeSummary Int = 0
  	  )
/* ##### fnBF_wrQuickOEESlicesTbl #####
Description  	  : Returns time slices as per product, crew,shift, order etc  which ever is applicable
Creation Date  	  : if any
Created By  	  : if any
#### Update History ####
DATE  	    	    	    	  Modified By  	    	    	  UserStory/Defect No  	    	    	    	  Comments  	    	  
----  	    	    	    	  -----------  	    	    	  -------------------  	    	    	    	  --------
2018-02-20  	    	    	  Prasad  	    	    	    	  7.0 SP3  	    	    	    	    	    	    	  Added logic to fetch/populate NPT, DowntimeA, DowntimeP, DowntimeQ, DowntimePL if unit is configured for time based OEE calculation.
2018-05-28  	    	    	  Prasad  	    	    	    	  7.0 SP4 US255630 & US255626  	    	  Passed actual filter for NPT
*/
RETURNS  @Slices TABLE(  	  SliceId  	    	    	    	  int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
  	    	    	    	    	    	  ProdDayProdId  	    	  nvarchar(75) DEFAULT null ,
  	    	    	    	    	    	  ProdIdSubGroupId  	  nvarchar(50) DEFAULT null,
  	    	    	    	    	    	  StartId  	    	    	    	  int DEFAULT null,
  	    	    	    	    	    	  StartTime  	    	    	  datetime,
  	    	    	    	    	    	  EndTime  	    	    	    	  datetime,
  	    	    	    	    	    	  PUId  	    	    	    	  int,
  	    	    	    	    	    	  ProdId  	    	    	    	  int,
  	    	    	    	    	    	  ShiftDesc  	    	    	    	  nvarchar(50),
  	    	    	    	    	    	  CrewDesc  	    	    	    	  nvarchar(50),
  	    	    	    	    	    	  ProductionDay  	    	  datetime,
  	    	    	    	    	    	  PPId  	    	    	    	  int,
  	    	    	    	    	    	  PathId  	    	    	    	  Int,
  	    	    	    	    	    	  EventId  	    	    	    	  int,
  	    	    	    	    	    	  AppliedProdId  	    	  int,
  	    	    	    	    	    	  -- ESignature
  	    	    	    	    	    	  PerformUserId  	    	  int,
  	    	    	    	    	    	  VerifyUserId  	    	  int,
  	    	    	    	    	    	  PerformUserName  	    	  nvarchar(30), 
  	    	    	    	    	    	  VerifyUserName  	    	  nvarchar(30), 
  	    	    	    	    	    	  -- Other
  	    	    	    	    	    	  NP  	    	    	    	    	  bit DEFAULT 0,
  	    	    	    	    	    	  NPLabelRef  	    	    	  bit DEFAULT 0,
  	    	    	    	    	    	  DowntimeTarget  	    	  float,
  	    	    	    	    	    	  ProductionTarget  	  float,
  	    	    	    	    	    	  WasteTarget  	    	    	  float,
  	    	    	    	    	    	  -- Statistics
  	    	    	    	    	    	  CalendarTime  	    	  Float DEFAULT 0,
  	    	    	    	    	    	  AvailableTime  	    	  Float DEFAULT 0,
  	    	    	    	    	    	  LoadingTime  	    	    	  Float DEFAULT 0,
  	    	    	    	    	    	  RunTimeGross  	    	  Float DEFAULT 0,
  	    	    	    	    	    	  ProductiveTime  	    	  Float DEFAULT 0,
  	    	    	    	    	    	  DowntimePlanned  	    	  Float DEFAULT 0,
  	    	    	    	    	    	  DowntimeExternal  	  Float DEFAULT 0,
  	    	    	    	    	    	  DowntimeUnplanned  	  Float DEFAULT 0,
  	    	    	    	    	    	  DowntimePerformance  	  Float DEFAULT 0,
  	    	    	    	    	    	  DowntimeTotal  	    	  Float DEFAULT 0,
  	    	    	    	    	    	  ProductionCount  	    	  int DEFAULT 0,
  	    	    	    	    	    	  ProductionTotal  	    	  Float DEFAULT 0,
  	    	    	    	    	    	  ProductionNet  	    	  Float DEFAULT 0,
  	    	    	    	    	    	  ProductionIdeal  	    	  Float DEFAULT 0,
  	    	    	    	    	    	  WasteQuantity  	    	  Float DEFAULT 0
  	    	    	    	    	    	  
  	    	    	    	    	    	  ,NPT Float DEFAULT 0 --NPT for the time slice
  	    	    	    	    	    	  ,DowntimeA Float DEFAULT 0 --Availability downtime for the time slice
  	    	    	    	    	    	  ,DowntimeP Float DEFAULT 0 --Performance downtime for the time slice
  	    	    	    	    	    	  ,DowntimeQ Float DEFAULT 0 --Quality downtime for the time slice
  	    	    	    	    	    	  ,DowntimePL Float DEFAULT 0
 	  	  	  	  	  	  ,Performance_Downtime_Category INT,Downtime_External_Category INT, Downtime_Scheduled_Category INT
  	    	    	    	    	    	  ,ProductionRateFactor float)
AS
BEGIN
/********************************************************************
*  	    	    	    	    	    	    	  Declarations  	    	    	    	    	    	    	  *
********************************************************************/
DECLARE  	  -- General
  	    	  @Rows  	    	    	    	    	    	    	  int,
  	    	  @rptParmOrderSummary  	    	    	  int,  	  -- 1 - Summary Selected
  	    	  @rptParmShiftSummary  	    	    	  int,  	  -- 1 - Summary Selected
  	    	  @rptParmCrewSummary  	    	    	    	  int,  	  -- 1 - Summary Selected
  	    	  -- Tables
  	    	  @EventsTableId  	    	    	    	    	  int,
  	    	  @ProductionStartsTableId  	    	  int,
  	    	  @CrewScheduleTableId  	    	    	  int,
  	    	  @ProductionDaysTableId  	    	    	  int,
  	    	  @ProductionPlanStartsTableId  	  int,
  	    	  @NonProductiveTableId  	    	    	  int,
  	    	  @DowntimeSpecsTableId  	    	    	  int,
  	    	  @ProductionSpecsTableId  	    	    	  int,
  	    	  @WasteSpecsTableId  	    	    	    	  int,
  	    	  -- Unit Configuration
  	    	  @ScheduledCategoryId  	    	    	  int,
  	    	  @ExternalCategoryId  	    	    	    	  int,
  	    	  @DowntimePropId  	    	    	    	    	  int,
  	    	  @DowntimeSpecId  	    	    	    	    	  int,
  	    	  @PerformanceCategoryId  	    	    	  int,
  	    	  @ProductionPropId  	    	    	    	  int,
  	    	  @ProductionSpecId  	    	    	    	  int,
  	    	  @ProductionRateFactor  	    	    	  Float,
  	    	  @ProductionType  	    	    	    	    	  tinyint,
  	    	  @ProductionVarId  	    	    	    	  int,
  	    	  @ProductionStartTime  	    	    	  tinyint,
  	    	  @WastePropId  	    	    	    	    	  int,
  	    	  @WasteSpecId  	    	    	    	    	  int,
  	    	  @NPCategoryId  	    	    	    	    	  int,
  	    	  @EfficiencySpecId  	    	    	    	  int
  	    	  
IF @ReportType = 2 SET   	  @rptParmShiftSummary = 1 ELSE SET @rptParmShiftSummary = 0
IF @ReportType = 3 SET   	  @rptParmCrewSummary = 1 ELSE SET @rptParmCrewSummary = 0
  	  Declare @OEEType nvarchar(10)
  	  --Select 
  	  --  	  @OEEType = EDFTV.Field_desc
  	  --From 
  	  --  	  Table_Fields TF
  	  --  	  JOIN Table_Fields_Values TFV on TFV.Table_Field_Id = TF.Table_Field_Id and TFV.TableId = TF.TableId
  	  --  	  Join ED_FieldTypes EDFT On EDFT.ED_Field_Type_Id = TF.ED_Field_Type_Id
  	  --  	  LEFT OUTER Join ED_FieldType_ValidValues EDFTV on EDFTV.ED_Field_Type_Id = TF.ED_Field_Type_Id AND EDFTV.Field_Id = TFV.Value
  	  --Where 
  	  --  	  TF.Table_Field_Desc = 'OEE Calculation Type'
  	  --  	  AND TFV.KeyID = @PUId
  	  
-- The goal is to build a table with all the start times and then
-- at the end we'll fill in the end times.
DECLARE  @Periods TABLE(  	  PeriodId  	    	    	  int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
  	    	    	    	    	    	  StartTime  	    	    	  datetime,
  	    	    	    	    	    	  EndTime  	    	    	    	  datetime,
  	    	    	    	    	    	  TableId  	    	    	    	  int,
  	    	    	    	    	    	  KeyId  	    	    	    	  int
 	  	  	  	  	  	  ,PuId Int
 	  	  	  	  	  	  )
DECLARE @ProductionDays TABLE (  	  DayId  	    	    	  int IDENTITY(1,1),
  	    	    	    	    	    	    	    	  StartTime  	    	  datetime,-- PRIMARY KEY,
  	    	    	    	    	    	    	    	  EndTime  	    	    	  datetime,
  	    	    	    	    	    	    	    	  ProductionDay  	  datetime,PuId Int
 	  	  	  	  	  	  	  	  ,unique(StartTime,PuId)
 	  	  	  	  	  	  	  	  )
DECLARE @ProductionStarts Table(Id Int Identity(1,1),StartTime DateTime,EndTime DateTime,ProdId Int,PUId Int)
DECLARE @SliceUpdate TABLE (
  	    	    	  SliceUpdateId int IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
  	    	    	  StartTime  	  datetime,
  	    	    	  EventId  	    	  int,
  	    	    	  ProdId  	    	  int
 	  	  	  ,PuId int
   	    	    	  )
/********************************************************************
*  	    	    	    	    	    	    	  Initialization  	    	    	    	    	    	    	  *
********************************************************************/
SELECT  	  -- Table Ids
  	    	  @EventsTableId  	    	    	    	    	  = 1,
  	    	  @ProductionStartsTableId  	    	  = 2,
  	    	  @CrewScheduleTableId  	    	    	  = -1,
  	    	  @ProductionDaysTableId  	    	    	  = -2,
  	    	  @ProductionPlanStartsTableId  	  = 12,
  	    	  @NonProductiveTableId  	    	    	  = -3,
  	    	  @DowntimeSpecsTableId  	    	    	  = -4,
  	    	  @ProductionSpecsTableId  	    	    	  = -5,
  	    	  @WasteSpecsTableId  	    	    	    	  = -6
/********************************************************************
*  	    	    	    	    	    	    	  Configuration  	    	    	    	    	    	    	  *
********************************************************************/
INSERT INTO  @ProductionStarts (ProdId,StartTime ,EndTime,PuId)
  	  SELECT ProdId , StartTime , EndTime,Pu_Id FROM  dbo.fnBF_GetPSFromEventsTbl(@PUId_Table,NULL,@StartTime,@EndTime,16)   
  	  --WHERE ProdId != 1
  	  Order by StartTime  
Declare @tempPU_Table TABLE(Pu_Id int, OEEType Int, Start_Date1 Datetime, End_Date1 Datetime, Start_Date2 Datetime, End_Date2 Datetime
,
Downtime_Scheduled_Category int,
 	 Downtime_External_Category int,
 	 Downtime_Percent_Specification int,
 	 Performance_Downtime_Category int,
 	 Production_Rate_Specification int,
 	 ProductionRateFactor real,
 	 Production_Type int,
 	 Production_Variable int,
 	 Uses_Start_Time int,
 	 Waste_Percent_Specification int,
 	 Non_Productive_Category int,
 	 Efficiency_Percent_Specification int,
 	 DownTimePropId int, 
 	 ProductionPropId int, 
 	 WastePropId int
 	 ,NPT Float
)
Insert Into  @tempPU_Table(Pu_Id,OEEType,Start_Date1,End_Date1,Start_Date2,End_Date2)
Select * from @PUId_Table
UPDATE u
SET
 	 u.Downtime_Scheduled_Category 	    	  = pu.Downtime_Scheduled_Category,
  	    	  u.Downtime_External_Category   	    	  = pu.Downtime_External_Category,  	  -- Currently ignored
  	    	  u.Downtime_Percent_Specification  	    	  = pu.Downtime_Percent_Specification,
  	    	  u.Performance_Downtime_Category 	    	  = pu.Performance_Downtime_Category,
  	    	  u.Production_Rate_Specification  	    	    	  = pu.Production_Rate_Specification,
  	    	  u.ProductionRateFactor  	    	  = dbo.fnGEPSProdRateFactor(pu.Production_Rate_TimeUnits),
  	    	  u.Production_Type  	    	    	    	  = pu.Production_Type,
  	    	  u.Production_Variable 	    	    	  = pu.Production_Variable,
  	    	  u.Uses_Start_Time 	    	  = pu.Uses_Start_Time,
  	    	  u.Waste_Percent_Specification 	    	    	  = pu.Waste_Percent_Specification,
  	    	  u.Non_Productive_Category 	  = pu.Non_Productive_Category,
  	    	  u.Efficiency_Percent_Specification 	  = pu.Efficiency_Percent_Specification
From
 	 @tempPU_Table u
 	 join Prod_Units_Base pu on pu.PU_Id = u.Pu_Id  	  
--UPDATE @ProductionStarts set PUId = @PUId 
--SELECT  	  -- Downtime
--  	    	  @ScheduledCategoryId  	    	  = Downtime_Scheduled_Category,
--  	    	  @ExternalCategoryId  	    	    	  = Downtime_External_Category,  	  -- Currently ignored
--  	    	  @DowntimeSpecId  	    	    	    	  = Downtime_Percent_Specification,
--  	    	  -- Production
--  	    	  @PerformanceCategoryId  	    	  = Performance_Downtime_Category,
--  	    	  @ProductionSpecId  	    	    	  = Production_Rate_Specification,
--  	    	  @ProductionRateFactor  	    	  = dbo.fnGEPSProdRateFactor(Production_Rate_TimeUnits),
--  	    	  @ProductionType  	    	    	    	  = Production_Type,
--  	    	  @ProductionVarId  	    	    	  = Production_Variable,
--  	    	  @ProductionStartTime  	    	  = Uses_Start_Time,
--  	    	  -- Waste
--  	    	  @WasteSpecId  	    	    	    	  = Waste_Percent_Specification,
--  	    	  -- Non-Productive Time
--  	    	  @NPCategoryId  	  = Non_Productive_Category,
--  	    	  -- Efficiency
--  	    	  @EfficiencySpecId  	    	    	  = Efficiency_Percent_Specification
--FROM dbo.Prod_Units 
--WHERE PU_Id = @PUId
UPDATE u SET u.DownTimePropId = s.Prop_Id FROM @tempPU_Table u Join Specifications s on s.Spec_Id = u.Downtime_Percent_Specification
UPDATE u SET u.ProductionPropId = s.Prop_Id FROM @tempPU_Table u Join Specifications s on s.Spec_Id = u.Production_Rate_Specification
UPDATE u SET u.WastePropId = s.Prop_Id FROM @tempPU_Table u Join Specifications s on s.Spec_Id = u.Waste_Percent_Specification
--SELECT  	  @DowntimePropId  	  = Prop_Id
--FROM dbo.Specifications 
--WHERE Spec_Id = @DowntimeSpecId
--SELECT  	  @ProductionPropId  	  = Prop_Id
--FROM dbo.Specifications 
--WHERE Spec_Id = @ProductionSpecId
--SELECT  	  @WastePropId  	  = Prop_Id
--FROM dbo.Specifications 
--WHERE Spec_Id = @WasteSpecId
/********************************************************************
*  	    	    	    	    	    	    	  Product Changes  	    	    	    	    	    	    	  *
********************************************************************/
-- Production starts always has to be contiguous so it's the best place to start
INSERT INTO @Periods (  	  TableId,
  	    	    	    	    	    	  KeyId,
  	    	    	    	    	    	  StartTime,
  	    	    	    	    	    	  EndTime,
 	  	  	  	  	  	  PuId)
SELECT  	  @ProductionStartsTableId,
  	    	  Id,
  	    	  CASE  	  WHEN StartTime < pu.Start_Date1 THEN pu.Start_Date1
  	    	    	    	  ELSE StartTime
  	    	    	    	  END,
  	    	  CASE   	  WHEN EndTime > pu.End_Date1 OR EndTime IS NULL THEN pu.End_Date1
  	    	    	    	  ELSE EndTime
  	    	    	    	  END 
 	  	 ,PuId 	  	   	    	  
FROM @ProductionStarts ps
join @PUId_Table Pu on Pu.Pu_Id = ps.PUId
/********************************************************************
*  	    	    	    	    	    	    	  CrewDesc Schedule  	    	    	    	    	    	  *
********************************************************************/
IF @rptParmCrewSummary =1 or @rptParmShiftSummary = 1 or 1=1
BEGIN
  	  -- Add records for all CrewDesc starts
  	  INSERT INTO @Periods (  	  TableId,
  	    	    	    	    	    	    	  KeyId,
  	    	    	    	    	    	    	  StartTime,
  	    	    	    	    	    	    	  EndTime,puId)
  	  SELECT  	  @CrewScheduleTableId,
  	    	    	  cs.CS_Id,
  	    	    	  StartTime  	  = CASE  	  WHEN cs.Start_Time < ps.Start_Date1 THEN ps.Start_Date1
  	    	    	    	    	    	    	    	  ELSE cs.Start_Time
  	    	    	    	    	    	    	    	  END,
  	    	    	  EndTime  	    	  = CASE  	  WHEN cs.End_Time > ps.End_Date1 THEN ps.End_Date1
  	    	    	    	    	    	    	    	  ELSE cs.End_Time
  	    	    	    	    	    	    	    	  END,ps.Pu_Id
  	  FROM dbo.Crew_Schedule cs 
 	  Join @PUId_Table ps on ps.Pu_Id = cs.PU_Id
  	  WHERE  	  --PU_Id = @PUId
 	  	  	 1=1
  	    	    	  AND cs.End_Time > ps.Start_Date1 
  	    	    	  AND cs.Start_Time < ps.End_Date1
END
/********************************************************************
*  	    	    	    	    	    	  Production Day  	    	    	    	    	    	    	    	  *
********************************************************************/
declare @DBZone varchar(100)
Select @DBZone = value from site_parameters where parm_id = 192;
INSERT INTO @ProductionDays (  	  StartTime,
  	    	    	    	    	    	    	    	  EndTime,
  	    	    	    	    	    	    	    	  ProductionDay,PuId)
SELECT  	  StartTime,
  	    	  EndTime,
  	    	  ProductionDay,
 	  	  u.Pu_Id
FROM 
 	 @tempPU_Table u 
  	  cross apply dbo.fnGEPSGetProductionDays(case when @InTimeZone is null then u.Start_Date1 else u.Start_Date1 at time zone @InTimeZone at time zone @DBZone end,
 	  case when @InTimeZone is null then u.End_Date1 else u.End_Date1 at time zone @InTimeZone at time zone @DBZone end)
Update @ProductionDays 
SET StartTime =  case when @InTimeZone is null then StartTime else StartTime at time zone @InTimeZone at time zone @DBZone end,
EndTime = case when @InTimeZone is null then EndTime else EndTime at time zone @InTimeZone at time zone @DBZone end,
ProductionDay = case when @InTimeZone is null then ProductionDay else ProductionDay at time zone @InTimeZone at time zone @DBZone end
INSERT INTO @Periods (  	  TableId,KeyId,StartTime,EndTime,PuId)
SELECT  	  @ProductionDaysTableId,
  	    	  DayId,
  	    	  StartTime,
  	    	  EndTime,PuId
FROM @ProductionDays
/********************************************************************
*  	    	    	    	    	    	  Production Order  	    	    	    	    	    	    	  *
********************************************************************/
INSERT INTO @Periods (  	  TableId,KeyId,StartTime,EndTime,PuId)
SELECT  	  @ProductionPlanStartsTableId,
  	    	  pps.PP_Start_Id,
  	    	  StartTime  	  = CASE  	  WHEN pps.Start_Time < u.Start_Date1 THEN u.Start_Date1
  	    	    	    	    	    	    	  ELSE pps.Start_Time
  	    	    	    	    	    	    	  END,
  	    	  EndTime  	    	  = CASE  	  WHEN pps.End_Time > u.End_Date1 THEN u.End_Date1
  	    	    	    	    	    	    	  ELSE pps.End_Time
  	    	    	    	    	    	    	  END,u.Pu_Id
FROM dbo.Production_Plan_Starts pps 
Join @tempPU_Table u on u.Pu_Id = pps.PU_Id
WHERE  	  --pps.PU_Id = @PUId
1=1
  	    	  AND pps.Start_Time < u.End_Date1 
  	    	  AND (pps.End_Time > u.Start_Date1 OR pps.End_Time IS NULL)
 	  	  
/********************************************************************
*  	    	    	    	    	    	  Non-Productive Time  	    	    	    	    	    	    	  *
********************************************************************/
INSERT INTO @Periods (  	  TableId,KeyId,StartTime,EndTime,PuId)
SELECT  	  @NonProductiveTableId,
  	    	  np.NPDet_Id,
  	    	  StartTime  	  = CASE  	  WHEN np.Start_Time < u.Start_Date1 THEN u.Start_Date1
  	    	    	    	    	    	    	  ELSE np.Start_Time
  	    	    	    	    	    	    	  END,
  	    	  EndTime  	    	  = CASE  	  WHEN np.End_Time > u.End_Date1 THEN u.End_Date1
  	    	    	    	    	    	    	  ELSE np.End_Time
  	    	    	    	    	    	    	  END,u.Pu_Id
FROM dbo.NonProductive_Detail np 
join @tempPU_Table u on u.Pu_Id = np.PU_Id
  	  JOIN dbo.Event_Reason_Category_Data ercd  ON  	  ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND ercd.ERC_Id = u.Non_Productive_Category
WHERE  	  --PU_Id = @PUId
1=1
  	    	  AND np.Start_Time < u.End_Date1
  	    	  AND np.End_Time > u.Start_Date1
  	    	  
/********************************************************************
*  	    	    	    	    	    	  Specifications  	    	    	    	    	    	    	    	  *
********************************************************************/
-- DOWNTIME TARGET
INSERT INTO @Periods (  	  TableId,
  	    	    	    	    	    	  KeyId,
  	    	    	    	    	    	  StartTime,
  	    	    	    	    	    	  EndTime,PuId)
SELECT  	  @DowntimeSpecsTableId,
   	      	   AS_Id,
   	      	   case when s.Effective_Date >= isnull(ps.StartTime, s.Effective_Date) AND s.Effective_Date >= isnull(u.Start_Date1, s.Effective_Date) Then s.Effective_Date else case when  ps.StartTime >= isnull(u.Start_Date1, ps.StartTime) then ps.StartTime else u.Start_Date1 end end,
   	      	   case when s.Expiration_Date <= isnull(ps.EndTime, s.Expiration_Date) AND s.Expiration_Date <= isnull(u.End_Date1, s.Effective_Date) Then s.Expiration_Date else case when  ps.EndTime <= isnull(u.End_Date1, ps.EndTime) then ps.EndTime else u.End_Date1 end end
 	  	  ,u.Pu_Id
FROM @ProductionStarts  ps 
join @tempPU_Table u on u.Pu_Id = ps.PUId
  	  JOIN dbo.PU_Characteristics puc  ON  	  ps.PUId = puc.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND puc.Prop_Id = u.DownTimePropId 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND ps.ProdId = puc.Prod_Id
  	    	  JOIN dbo.Active_Specs s  ON  	  s.Char_Id = puc.Char_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	  AND s.Spec_Id = u.Downtime_Percent_Specification
  	    	    	    	    	    	    	    	    	    	    	    	    	  AND s.Effective_Date < isnull(ps.EndTime, u.End_Date1)
  	    	    	    	    	    	    	    	    	    	    	    	    	  AND isnull(s.Expiration_Date, u.End_Date1) > ps.StartTime
-- PRODUCTION TARGET
INSERT INTO @Periods (  	  TableId,KeyId,StartTime,EndTime,PuId)
SELECT  	  @ProductionSpecsTableId,
   	      	   AS_Id,
   	      	   case when s.Effective_Date >= isnull(ps.StartTime, s.Effective_Date) AND s.Effective_Date >= isnull(u.Start_Date1, s.Effective_Date) Then s.Effective_Date else case when  ps.StartTime >= isnull(u.Start_Date1, ps.StartTime) then ps.StartTime else u.Start_Date1 end end,
   	      	   case when s.Expiration_Date <= isnull(ps.EndTime, s.Expiration_Date) AND s.Expiration_Date <= isnull(u.End_Date1, s.Effective_Date) Then s.Expiration_Date else case when  ps.EndTime <= isnull(u.End_Date1, ps.EndTime) then ps.EndTime else u.End_Date1 end end
 	  	  ,u.Pu_Id
FROM @ProductionStarts ps 
JOIN @tempPU_Table u on u.Pu_Id = ps.PUId
  	  JOIN dbo.PU_Characteristics puc  ON  	  ps.PUId = puc.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND puc.Prop_Id = u.ProductionPropId 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND ps.ProdId = puc.Prod_Id
  	    	  JOIN dbo.Active_Specs s  ON  	  s.Char_Id = puc.Char_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	  AND s.Spec_Id = u.Production_Rate_Specification 
  	    	    	    	    	    	    	    	    	    	    	    	    	  AND s.Effective_Date < isnull(ps.EndTime, u.End_Date1)
  	    	    	    	    	    	    	    	    	    	    	    	    	  AND isnull(s.Expiration_Date, u.End_Date1) > ps.StartTime
-- WASTE TARGET
INSERT INTO @Periods (  	  TableId,KeyId,StartTime,EndTime,PuId)
SELECT  	  @WasteSpecsTableId,
   	      	   AS_Id,
   	      	   case when s.Effective_Date >= isnull(ps.StartTime, s.Effective_Date) AND s.Effective_Date >= isnull(u.Start_Date1, s.Effective_Date) Then s.Effective_Date else case when  ps.StartTime >= isnull(u.Start_Date1, ps.StartTime) then ps.StartTime else u.Start_Date1 end end,
   	      	   case when s.Expiration_Date <= isnull(ps.EndTime, s.Expiration_Date) AND s.Expiration_Date <= isnull(u.End_Date1, s.Effective_Date) Then s.Expiration_Date else case when  ps.EndTime <= isnull(u.End_Date1, ps.EndTime) then ps.EndTime else u.End_Date1 end end
 	  	  ,u.Pu_Id
FROM @ProductionStarts ps 
join @tempPU_Table u on u.Pu_Id = ps.PUId
  	  JOIN dbo.PU_Characteristics puc  ON  	  ps.PUId = puc.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND puc.Prop_Id = u.WastePropId 
  	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND ps.ProdId = puc.Prod_Id
  	    	  JOIN dbo.Active_Specs s  ON  	  s.Char_Id = puc.Char_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	  AND s.Spec_Id = u.Waste_Percent_Specification 
  	    	    	    	    	    	    	    	    	    	    	    	    	  AND s.Effective_Date < isnull(ps.EndTime, u.End_Date1)
  	    	    	    	    	    	    	    	    	    	    	    	    	  AND isnull(s.Expiration_Date, u.End_Date1) > ps.StartTime
 	  	  	  	  	  	  	  	  	  	  	  	  	   
/********************************************************************
*  	    	    	    	    	    	  Production Events  	    	    	    	    	    	    	  *
********************************************************************/
  	  INSERT INTO @Periods (  	  TableId,
  	    	    	    	    	    	    	  KeyId,
  	    	    	    	    	    	    	  StartTime,
  	    	    	    	    	    	    	  EndTime,PuId
  	    	    	    	    	    	    	  )
  	  SELECT  	  @EventsTableId,
  	    	    	  e.Event_Id,
  	    	    	  StartTime  	  = e.Timestamp, 
  	    	    	  EndTime  	    	  = e.Timestamp,u.Pu_Id
  	  FROM dbo.Events e 
 	  join @tempPU_Table u on u.Pu_Id = e.PU_Id
  	  WHERE  	  --e.PU_Id = @PUId
 	  1=1
 	  and u.Production_Type <> 1
  	    	    	  AND isnull(e.Start_Time,e.TimeStamp) <= u.End_Date1
  	    	    	  AND e.Timestamp >= u.Start_Date1
  	    	    	  AND e.Applied_Product IS NOT NULL   	  
  	  -- Set the Start time for the first record.
 	  
  	  UPDATE p2
  	  SET p2.StartTime = coalesce(e.Start_Time,u.Start_Date1)
  	  FROM @Periods p2
  	    	  JOIN dbo.Events e  ON p2.KeyId = e.Event_Id
 	  	  join @tempPU_Table u on u.Pu_Id = e.PU_Id and u.Pu_Id = p2.PuId
  	  WHERE p2.PeriodId IN (SELECT min(p1.PeriodId)
  	    	  FROM @Periods p1 WHERE p1.TableId = @EventsTableId and p1.PuId = p2.PuId)
 	  	  
  	  -- Set the Start time for the other records based on whether Start_Time is configured..
  	  UPDATE p2
  	  SET p2.StartTime = CASE WHEN e.Start_Time IS NULL THEN p1.EndTime ELSE e.Start_Time END
  	  FROM @Periods p1
  	    	  JOIN @Periods p2 ON p2.PeriodId = p1.PeriodId + 1 and p2.PuId = p1.PuId
  	    	  LEFT JOIN dbo.Events e  ON p2.KeyId = e.Event_Id and p2.PuId = e.PU_Id
  	    	    	  AND p2.TableId = p1.TableId
  	  WHERE p1.TableId = @EventsTableId
/********************************************************************
*  	    	    	    	    	    	    	  Gaps  	    	    	    	    	    	    	    	    	  *
********************************************************************/
-- Insert gaps
INSERT INTO @Periods (  	  StartTime,
  	    	    	    	    	    	  EndTime,
  	    	    	    	    	    	  TableId,PuId)
SELECT  	  p1.EndTime,
  	    	  @EndTime,
  	    	  p1.TableId
 	  	  ,p1.PuId
FROM @Periods p1
  	  LEFT JOIN @Periods p2 ON  	  p1.TableId = p2.TableId
  	    	    	    	    	    	    	    	  AND p1.EndTime = p2.StartTime and p1.PuId = p2.PuId
WHERE  	  --p1.EndTime < @EndTime
EXISTS (Select 1 From @tempPU_Table Where p1.EndTime < End_Date1 and Pu_Id = P1.PuId)
  	    	  AND p2.PeriodId IS NULL
 	  	    
/********************************************************************
*  	    	    	    	    	    	    	  Slices  	    	    	    	    	    	    	    	    	  *
********************************************************************/
-- Create slices
INSERT INTO @Slices (  	  PUId,
  	    	    	    	    	    	  StartTime)
SELECT DISTINCT  	  PuId,
  	    	    	    	  StartTime
FROM @Periods p
Where exists  (Select 1 from @ProductionStarts Where PuId  = p.PuId)
ORDER BY PuId,StartTime ASC
SELECT @Rows = @@rowcount
-- Correct the end times
UPDATE s1
SET s1.EndTime  	    	  = s2.StartTime,
  	  s1.CalendarTime  	  = datediff(s, s1.StartTime, s2.StartTime)
FROM @Slices s1
  	  JOIN @Slices s2 ON s2.SliceId = s1.SliceId + 1 ANd S2.PUId = S1.PUId
WHERE s1.SliceId < (Select Max(SliceId) from @Slices Where PuId = S1.PUId) 
UPDATE s
SET EndTime   	    	  = u.End_Date1,
  	  CalendarTime  	  = datediff(s, StartTime, u.End_Date1)
 	  From @Slices s
 	  Join @tempPU_Table u on u.Pu_Id = s.PUId
WHERE SliceId = (Select Max(SliceId) from @Slices Where PuId = s.PUId)
-- Update each slice with the relative table information
UPDATE s
SET  	  PUId  	  = ps.PUId,
  	  ProdId  	  = ps.ProdId,
  	  StartId  	  = ps.Id
FROM @Slices s
  	  LEFT JOIN @Periods p ON p.TableId = @ProductionStartsTableId
  	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	  AND p.EndTime > s.StartTime and p.PuId = s.PUId
  	    	  LEFT JOIN @ProductionStarts ps ON p.KeyId = ps.Id and ps.PUId = p.PuId
WHERE  	  s.PUId = p.PuId
  	    	  AND p.KeyId IS NOT NULL
 	  	  
 	  	  
;WITH S AS (SELECT S.* FROM @Slices s
  	  LEFT JOIN @Periods p ON p.TableId = @ProductionStartsTableId
  	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	  AND p.EndTime > s.StartTime and p.PuId = s.PUId
  	    	  LEFT JOIN @ProductionStarts ps ON p.KeyId = ps.Id and ps.PUId = p.PuId
WHERE  	  s.PUId = p.PuId
  	    	  AND p.KeyId IS NOT NULL) 	  	  
UPDATE T SET T.PUId =0,T.ProdId= NULL,StartId = NULL FROM @Slices T WHERE NOT EXISTS (SELECT 1 FROM S WHERE SliceId = T.SliceId) 	  	  
 	  	  
IF @rptParmCrewSummary =1 or @rptParmShiftSummary = 1 or 1=1
BEGIN
UPDATE s
SET CrewDesc  	  = cs.Crew_Desc,
  	  ShiftDesc  	  = cs.Shift_Desc
FROM @Slices s
  	  LEFT JOIN @Periods p ON p.TableId = @CrewScheduleTableId
  	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	  AND p.EndTime > s.StartTime and p.PuId = s.PUId
  	    	  LEFT JOIN dbo.Crew_Schedule cs  ON p.KeyId = cs.CS_Id and p.PuId = cs.PU_Id
WHERE p.KeyId IS NOT NULL
END
UPDATE s
SET ProductionDay  	  = pd.ProductionDay
FROM @Slices s
  	  LEFT JOIN @Periods p ON p.TableId = @ProductionDaysTableId
  	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	  AND p.EndTime > s.StartTime and p.PuId = s.PUId
  	    	  LEFT JOIN @ProductionDays pd ON p.KeyId = pd.DayId and p.PuId = pd.PuId
WHERE p.KeyId IS NOT NULL
UPDATE s
SET PPId = pps.PP_Id
FROM @Slices s
  	  LEFT JOIN @Periods p ON p.TableId = @ProductionPlanStartsTableId
  	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	  AND (p.EndTime > s.StartTime OR p.EndTime IS NULL) and p.PuId = s.PUId 
  	    	  LEFT JOIN dbo.Production_Plan_Starts pps  ON p.KeyId = pps.PP_Start_Id and p.PuId = pps.PU_Id
WHERE p.KeyId IS NOT NULL
UPDATE s
SET NP = 1
FROM @Slices s
   	   LEFT JOIN @Periods p ON p.TableId = @NonProductiveTableId
   	      	      	      	      	      	      	   AND p.StartTime <= s.StartTime
   	      	      	      	      	      	      	   AND p.EndTime > s.StartTime and p.PuId =s.PUId
WHERE p.KeyId IS NOT NULL 
UPDATE s
SET DowntimeTarget = sp.Target
FROM @Slices s
  	  LEFT JOIN @Periods p ON p.TableId = @DowntimeSpecsTableId
  	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	  AND p.EndTime > s.StartTime and p.PuId = s.PUId
  	    	  LEFT JOIN dbo.Active_Specs sp  ON p.KeyId = sp.AS_Id  
WHERE p.KeyId IS NOT NULL
UPDATE s
SET ProductionTarget = sp.Target
FROM @Slices s
  	  LEFT JOIN @Periods p ON p.TableId = @ProductionSpecsTableId
  	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	  AND p.EndTime > s.StartTime and p.PuId = s.PUId
  	    	  LEFT JOIN dbo.Active_Specs sp  ON p.KeyId = sp.AS_Id
WHERE p.KeyId IS NOT NULL
UPDATE s
SET WasteTarget = sp.Target
FROM @Slices s
  	  LEFT JOIN @Periods p ON p.TableId = @WasteSpecsTableId
  	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	  AND p.EndTime > s.StartTime and p.PuId = s.PUId
  	    	  LEFT JOIN dbo.Active_Specs sp  ON p.KeyId = sp.AS_Id
WHERE p.KeyId IS NOT NULL
  	    	  --  	  Retrieve events that have an applied product. All other events are not
  	    	  --  needed, since the product information for these events would come from
  	    	  --  Production_starts. Events need to be retrieved only when event summary
  	    	  --  	  is needed.
  	    	    	  --@Slices may not necessarily correspond to an event
  	    	    	  --Update slices that correspond to an event i.e.@Periods.EndTime = event.Timestamp
  	    	    	  UPDATE s
  	    	    	  SET EventId = e.Event_Id,
  	    	    	    	  AppliedProdId = e.Applied_Product
  	    	    	  FROM @Slices s
  	    	    	    	  LEFT JOIN @Periods p ON p.TableId = @EventsTableId
  	    	    	    	    	    	    	    	    	    	  AND p.StartTime <= s.StartTime
  	    	    	    	    	    	    	    	    	    	  AND p.EndTime > s.StartTime And p.PuId = s.PUId
  	    	    	    	    	  LEFT JOIN dbo.Events e  ON p.KeyId = e.Event_Id
  	    	    	    	    	    	  AND p.EndTime = e.Timestamp  	    	    	    	  
  	    	    	  WHERE p.KeyId IS NOT NULL AND e.Applied_Product IS NOT NULL
 	  	  	 AND EXISTS (SELECT 1 FRom @tempPU_Table where Pu_Id =s.PUId and Production_Type <> 1)
/********************************************************************
*  	    	    	    	    	    	    	  Downtime  	    	    	    	    	    	    	    	  *
********************************************************************/
-- Calculate the downtime statistics for each slice
-- Calculate 'Planned Downtime' and 'Available Time'
UPDATE s SET s.Downtime_External_Category = u.Downtime_External_Category,s.Downtime_Scheduled_Category =u.Downtime_Scheduled_Category, s.Performance_Downtime_Category = u.Performance_Downtime_Category
From @slices s 
JOIN @tempPU_Table u on u.Pu_Id= s.PUId
UPDATE s
SET  	  DowntimePlanned  	  = isnull(dts.Total,0),
  	  AvailableTime  	    	  = CASE  	  WHEN s.CalendarTime >= isnull(dts.Total,0)
  	    	    	    	    	    	    	    	    	  THEN s.CalendarTime - isnull(dts.Total,0)
  	    	    	    	    	    	    	    	  ELSE 0
  	    	    	    	    	    	    	    	  END
FROM @Slices s
  	  LEFT JOIN (  	  
 	  Select 
 	  	  	  	  	 SliceId AS SliceId,
 	  	  	  	  	 sum(datediff(s, CASE WHEN T.Start_Time < T.StartTime THEN T.StartTime ELSE T.Start_Time END,CASE WHEN T.End_Time > T.EndTime OR T.End_Time IS NULL THEN T.EndTime ELSE T.End_Time END)) AS Total 
 	  	  	  	 from 
 	  	  	  	  	 (
 	  	  	  	  	  	 Select 
 	  	  	  	  	  	  	 SliceId,ted.Start_Time,s.startTime,s.EndTime,ted.End_time 
 	  	  	  	  	  	 from 
 	  	  	  	  	  	  	 @Slices S 
 	  	  	  	  	  	  	 --JOIN @tempPU_Table u on u.Pu_Id= s.PUId
  	    	    	    	    	    	    	  JOIN dbo.Timed_Event_Details ted  ON   	   s.PUId = ted.PU_Id AND  ted.Start_Time < s.EndTime AND (ted.End_Time > s.StartTime or ted.End_time IS NULL)
  	    	    	    	    	    	    	  JOIN dbo.Event_Reason_Category_Data ercd  ON ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id AND ercd.ERC_Id = s.Downtime_Scheduled_Category
 	  	  	  	  	  	 
 	  	  	  	  	 ) T Group by T.SliceId
 	  	  	  	  ) dts ON s.SliceId = dts.SliceId
-- Calculate 'External Downtime' (i.e. 'Unavailable Time' or 'Line/Unit Restraints') and 'Loading Time'
UPDATE s
SET  	  DowntimeExternal  	  = isnull(dts.Total,0),
  	  LoadingTime  	    	    	  = CASE  	  WHEN s.AvailableTime >= isnull(dts.Total,0)
  	    	    	    	    	    	    	    	    	  THEN s.AvailableTime - isnull(dts.Total, 0)
  	    	    	    	    	    	    	    	  ELSE 0
  	    	    	    	    	    	    	    	  END
FROM @Slices s
  	  LEFT JOIN (  	  
 	  Select 
 	  	  	  	  	 SliceId AS SliceId,
 	  	  	  	  	 sum(datediff(s, CASE WHEN T.Start_Time < T.StartTime THEN T.StartTime ELSE T.Start_Time END,CASE WHEN T.End_Time > T.EndTime OR T.End_Time IS NULL THEN T.EndTime ELSE T.End_Time END)) AS Total 
 	  	  	  	 from 
 	  	  	  	  	 (
 	  	  	  	  	  	 Select 
 	  	  	  	  	  	  	 SliceId,ted.Start_Time,s.startTime,s.EndTime,ted.End_time 
 	  	  	  	  	  	 from 
 	  	  	  	  	  	  	 @Slices S 
 	  	  	  	  	  	  	 --JOIN @tempPU_Table u on u.Pu_Id= s.PUId
  	    	    	    	    	    	    	  JOIN dbo.Timed_Event_Details ted  ON   	   s.PUId = ted.PU_Id AND ted.Start_Time < s.EndTime AND (ted.End_Time > s.StartTime or ted.End_Time Is Null)
  	    	    	    	    	    	    	  JOIN dbo.Event_Reason_Category_Data ercd  ON ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id AND ercd.ERC_Id = s.Downtime_External_Category
 	  	  	  	  	  	 --UNION
 	  	  	  	  	  	 --Select 
 	  	  	  	  	  	 -- 	 SliceId,ted.Start_Time,s.startTime,s.EndTime,ted.End_time 
 	  	  	  	  	  	 --from 
 	  	  	  	  	  	 -- 	 @Slices S 
 	  	  	  	  	  	 -- 	 --JOIN @tempPU_Table u on u.Pu_Id= s.PUId
 	  	  	  	  	  	 -- 	 JOIN dbo.Timed_Event_Details ted  ON  	  s.PUId = ted.PU_Id AND ted.Start_Time < s.EndTime or ted.End_Time Is Null
 	  	  	  	  	  	 -- 	 JOIN dbo.Event_Reason_Category_Data ercd  ON ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id AND ercd.ERC_Id = s.Downtime_External_Category
 	  	  	  	  	 ) T Group by T.SliceId
 	  ) dts ON s.SliceId = dts.SliceId
-- Calculate 'Performance Downtime'
UPDATE s
SET  	  DowntimePerformance  	  = isnull(dts.Total,0)
FROM @Slices s
  	  LEFT JOIN (  	  
 	  Select 
 	  	  	  	  	 SliceId AS SliceId,
 	  	  	  	  	 sum(datediff(s, CASE WHEN T.Start_Time < T.StartTime THEN T.StartTime ELSE T.Start_Time END,CASE WHEN T.End_Time > T.EndTime OR T.End_Time IS NULL THEN T.EndTime ELSE T.End_Time END)) AS Total 
 	  	  	  	 from 
 	  	  	  	  	 (
 	  	  	  	  	  	 Select 
 	  	  	  	  	  	  	 SliceId,ted.Start_Time,s.startTime,s.EndTime,ted.End_time 
 	  	  	  	  	  	 from 
 	  	  	  	  	  	  	 @Slices S 
 	  	  	  	  	  	  	 --JOIN @tempPU_Table u on u.Pu_Id= s.PUId
 	  	  	  	  	  	  	 JOIN dbo.Timed_Event_Details ted  ON  	  s.PUId = ted.PU_Id AND (ted.Start_Time < s.EndTime AND ted.End_Time > s.StartTime OR ted.End_time is null)
 	  	  	  	  	  	  	 JOIN dbo.Event_Reason_Category_Data ercd  ON ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id AND ercd.ERC_Id = s.Performance_Downtime_Category
 	  	  	  	  	  	 --UNION
 	  	  	  	  	  	 --Select 
 	  	  	  	  	  	 -- 	 SliceId,ted.Start_Time,s.startTime,s.EndTime,ted.End_time 
 	  	  	  	  	  	 --from 
 	  	  	  	  	  	 -- 	 @Slices S 
 	  	  	  	  	  	 -- 	 --JOIN @tempPU_Table u on u.Pu_Id= s.PUId
 	  	  	  	  	  	 -- 	 JOIN dbo.Timed_Event_Details ted  ON  	  s.PUId = ted.PU_Id AND ted.Start_Time < s.EndTime AND ted.End_Time Is Null
 	  	  	  	  	  	 -- 	 JOIN dbo.Event_Reason_Category_Data ercd  ON ted.Event_Reason_Tree_Data_Id = ercd.Event_Reason_Tree_Data_Id AND ercd.ERC_Id = s.Performance_Downtime_Category
 	  	  	  	  	 ) T Group by T.SliceId
 	  ) dts ON s.SliceId = dts.SliceId
-- Calculate 'Unplanned Downtime' and 'Run Time'
UPDATE s
SET   	   DowntimeTotal   	      	   = isnull(dts.Total,0),
   	   DowntimeUnplanned   	   = isnull(dts.Total, 0) - s.DowntimePlanned - s.DowntimeExternal - s.DowntimePerformance,
   	   RunTimeGross   	      	      	      	   = CASE   	   WHEN s.CalendarTime >= isnull(dts.Total,0)
   	      	      	      	      	      	      	      	      	      	   THEN s.CalendarTime - isnull(dts.Total, 0) + s.DowntimePerformance
   	      	      	      	      	      	      	      	      	   ELSE 0
   	      	      	      	      	      	      	      	      	   END,
   	   ProductiveTime   	      	   = CASE   	   WHEN s.CalendarTime >= isnull(dts.Total,0)
   	      	      	      	      	      	      	      	      	      	   THEN s.CalendarTime - isnull(dts.Total, 0)
   	      	      	      	      	      	      	      	      	   ELSE 0
   	      	      	      	      	      	      	      	      	   END
FROM @Slices s
  	  LEFT JOIN (  	  SELECT  	  SliceId  	  AS SliceId,
  	    	    	    	    	    	  sum(datediff(s, CASE  	  WHEN ted.Start_Time < s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	  THEN s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	  ELSE ted.Start_Time
  	    	    	    	    	    	    	    	    	    	    	    	  END,
  	    	    	    	    	    	    	    	    	    	  CASE  	  WHEN ted.End_Time > s.EndTime
  	    	    	    	    	    	    	    	    	    	    	    	    	   OR ted.End_Time IS NULL
  	    	    	    	    	    	    	    	    	    	    	    	    	  THEN s.EndTime
  	    	    	    	    	    	    	    	    	    	    	    	  ELSE ted.End_Time
  	    	    	    	    	    	    	    	    	    	    	    	  END)) AS Total
  	    	    	    	  FROM @Slices s
  	    	    	    	    	  JOIN dbo.Timed_Event_Details ted  ON  	  s.PUId = ted.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND ted.Start_Time < s.EndTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND (ted.End_Time > s.StartTime OR ted.End_Time is NULL)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 -- AND (ISNULL(ted.End_Time,'9999-12-31') between s.StartTime and s.EndTime 	 OR ted.Start_Time between s.StartTime and s.EndTime) 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 
  	    	    	    	  GROUP BY s.SliceId) dts ON s.SliceId = dts.SliceId
 	  	  	  	  
/********************************************************************
*  	    	    	    	    	    	    	    	  Waste  	    	    	    	    	    	    	    	  *
********************************************************************/
-- Collect time-based waste
UPDATE s
SET WasteQuantity = isnull(wt.Total,0)
FROM @Slices s
  	  LEFT JOIN (  	  SELECT  	  s.SliceId  	    	  AS SliceId,
  	    	    	    	    	    	  sum(wed.Amount)  	  AS Total
  	    	    	    	  FROM @Slices s
  	    	    	    	    	  JOIN dbo.Waste_Event_Details wed  ON  	  s.PUId = wed.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND wed.TimeStamp > s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND wed.TimeStamp <= s.EndTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND Event_Id IS NULL
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND Amount IS NOT NULL
  	    	    	    	  GROUP BY s.SliceId) wt ON s.SliceId = wt.SliceId
-- Collect event-based waste
  	  UPDATE s
  	  SET WasteQuantity = WasteQuantity + isnull(wt.Total,0)
  	  FROM @Slices s
  	    	  LEFT JOIN (  	  SELECT  	  s.SliceId AS SliceId,
  	    	    	    	    	    	    	  sum(CASE  	  WHEN e.Start_Time IS NOT NULL THEN
  	    	    	    	    	    	    	    	    	  convert(Float, datediff(s, CASE  	  WHEN e.Start_Time < s.StartTime THEN s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  ELSE e.Start_Time
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  END,
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    CASE  	  WHEN e.TimeStamp > s.EndTime THEN s.EndTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  ELSE e.TimeStamp
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  END))
  	    	    	    	    	    	    	    	  / convert(Float, CASE WHEN datediff(s, e.Start_Time, e.TimeStamp) <= 0 THEN 1 ELSE datediff(s, e.Start_Time, e.TimeStamp) END)
  	    	    	    	    	    	    	    	  * isnull(wed.Amount,0)
  	    	    	    	    	    	    	    	  ELSE isnull(wed.Amount,0)
  	    	    	    	    	    	    	    	  END) AS Total
  	    	    	    	    	  FROM @Slices s
 	  	  	  	  	  	 jOIN @tempPU_Table u on u.Pu_Id = s.PUId and u.Uses_Start_Time = 1
  	    	    	    	    	    	  JOIN dbo.Events e  ON  	  s.PUId = e.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND e.TimeStamp > s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  --AND e.Start_Time < s.EndTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND isnull(e.Start_Time, e.TimeStamp) <= s.EndTime 
  	    	    	    	    	    	    	  LEFT JOIN dbo.Waste_Event_Details wed  ON  	  s.PUId = wed.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  --AND wed.TimeStamp = e.TimeStamp
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND wed.Event_Id = e.Event_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND wed.Amount IS NOT NULL
  	    	    	    	    	  GROUP BY s.SliceId) wt ON s.SliceId = wt.SliceId
  	  
  	  UPDATE s
  	  SET WasteQuantity = WasteQuantity + isnull(wt.Total,0)
  	  FROM @Slices s
  	    	  LEFT JOIN (  	  SELECT  	  s.SliceId AS SliceId,
  	    	    	    	    	    	    	  sum(isnull(wed.Amount,0)) AS Total
  	    	    	    	    	  FROM @Slices s
 	  	  	  	  	  join @tempPU_Table u on u.Pu_Id = s.PUId and u.Uses_Start_Time <> 1
  	    	    	    	    	    	  JOIN dbo.Events e  ON  	  s.PUId = e.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND e.TimeStamp > s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND e.TimeStamp <= s.EndTime
  	    	    	    	    	    	    	  LEFT JOIN dbo.Waste_Event_Details wed  ON  	  s.PUId = wed.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  --AND wed.TimeStamp = e.TimeStamp
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND wed.Event_Id = e.Event_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND wed.Amount IS NOT NULL
  	    	    	    	    	  GROUP BY s.SliceId) wt ON s.SliceId = wt.SliceId
  	   
/********************************************************************
*  	    	    	    	    	    	    	  Production  	    	    	    	    	    	    	    	  *
********************************************************************/
--IF EXISTS (Select 1 from @tempPU_Table where Production_Type = 1)
--IF @ProductionType = 1
  	  --BEGIN
 	  UPDATE s set s.ProductionRateFactor = t.ProductionRateFactor
 	  from @slices s join @tempPU_Table t on t.Pu_Id =s.PUId
 	   
  	  UPDATE s
  	  SET   	  ProductionTotal = isnull(pt.Total,0),
  	    	    	  ProductionNet  	  = isnull(pt.Total,0) - s.WasteQuantity,
   	      	      	   ProductionIdeal   	   =  	  	  	  	  	   
 	  	  	  	  	   CASE WHEN ProductionTarget IS NULL THEN pt.Total else case WHEN isnull(u.ProductionRateFactor,0) > 0 
 	  	  	  	  	   AND RunTimeGross >= 0 THEN (RunTimeGross)*(ProductionTarget/u.ProductionRateFactor) ELSE 0 END END
   	   FROM @Slices s
 	  join @tempPU_Table u on u.Pu_Id = s.PUId and u.Production_Type = 1
  	    	  LEFT JOIN (  	  SELECT  	  s.SliceId AS SliceId,
  	    	    	    	    	    	    	  sum(convert(Float, t.Result)) AS Total
  	    	    	    	    	  FROM @Slices s
 	  	  	  	  	  join @tempPU_Table u on u.Pu_Id = s.PUId and u.Production_Type = 1
  	    	    	    	    	    	  JOIN dbo.Tests t  ON  	  t.Var_Id = u.Production_Variable -- @ProductionVarId
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND t.Result_On > s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND t.Result_On <= s.EndTime
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  and u.Production_Type = 1
  	    	    	    	    	  GROUP BY s.SliceId) pt ON s.SliceId = pt.SliceId
 	  	  	  	  	   
--  	  END
--ELSE
--  	  BEGIN
-- 	  IF EXISTS (Select 1 from @tempPU_Table where Uses_Start_Time = 1)
--  	  --IF @ProductionStartTime = 1  	  -- Uses start time so pro-rate quantity
--  	    	  BEGIN
  	    	  UPDATE s
  	    	  SET  	  ProductionTotal  	  = isnull(pt.Total,0),
   	      	      	   ProductionNet   	   = isnull(pt.Total,0) - s.WasteQuantity,
   	      	      	   ProductionIdeal   	   = 
 	  	  	  	  	   
 	  	  	  	  	   CASE WHEN ProductionTarget IS NULL THEN pt.Total else 
 	  	  	  	  	   case WHEN isnull(u.ProductionRateFactor,0) > 0 AND RunTimeGross >= 0 
 	  	  	  	  	   THEN (RunTimeGross)*(ProductionTarget/u.ProductionRateFactor) ELSE 0 END END
  	    	  FROM @Slices s
 	  	  join @tempPU_Table u on u.Pu_Id = s.PUId and u.Uses_Start_Time = 1 and u.Production_Type != 1
 	  	   	    	    	   LEFT JOIN (  	  SELECT  	  s.SliceId AS SliceId,
  	    	    	    	    	    	    	    	  sum( CASE  	  WHEN e.Start_Time IS NOT NULL THEN
  	    	    	    	    	    	    	    	    	    	    	    	  convert(Float, datediff(s, CASE  	  WHEN e.Start_Time < s.StartTime THEN s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  ELSE e.Start_Time
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  END,
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    CASE  	  WHEN e.TimeStamp > s.EndTime THEN s.EndTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  ELSE e.TimeStamp
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  END))
  	    	    	    	    	    	    	    	    	    	    	    	  / convert(Float, CASE WHEN datediff(s, e.Start_Time, e.TimeStamp) <=0 THEN 1 ELSE datediff(s, e.Start_Time, e.TimeStamp) END)
  	    	    	    	    	    	    	    	    	    	    	    	  * isnull(ed.Initial_Dimension_X,0)
  	    	    	    	    	    	    	    	    	    	    	  ELSE isnull(ed.Initial_Dimension_X,0)
  	    	    	    	    	    	    	    	    	    	    	  END) AS Total
  	    	    	    	    	    	  FROM @Slices s
 	  	  	  	  	  	  join @tempPU_Table u on u.Pu_Id = s.PUId and u.Uses_Start_Time = 1 and u.Production_Type != 1
  	    	    	    	    	    	    	  JOIN dbo.Events e  ON  	  s.PUId = e.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND e.TimeStamp > s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND isnull(e.Start_Time, e.TimeStamp) <= s.EndTime -- Note: if starttime is null it assumes that starttime = endtime
  	    	    	    	    	    	    	    	  JOIN dbo.Production_Status ps  ON  	  e.Event_Status = ps.ProdStatus_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND ps.Count_For_Production = 1
  	    	    	    	    	    	    	    	  LEFT JOIN dbo.Event_Details ed  ON ed.Event_Id = e.Event_Id
  	    	    	    	    	    	  GROUP BY s.SliceId) pt ON s.SliceId = pt.SliceId 
 	  	  	  	  	  	   
  	  --  	  END
  	  --ELSE -- Doesn't use start time so don't pro-rate quantity
  	  --  	  BEGIN
 	  
  	    	  UPDATE s
   	      	   SET   	   ProductionTotal   	   = isnull(pt.Total,0),
   	      	      	   ProductionNet   	   = isnull(pt.Total,0) - s.WasteQuantity,
   	      	      	   ProductionIdeal   	   =  	  	  	  	  	   CASE WHEN ProductionTarget IS NULL THEN pt.Total else case WHEN isnull(u.ProductionRateFactor,0) > 0 AND RunTimeGross >= 0 THEN (RunTimeGross)*(ProductionTarget/u.ProductionRateFactor) ELSE 0 END END
   	      	   FROM @Slices s
 	  	  join @tempPU_Table u on u.Pu_Id =s.PUId and u.Uses_Start_Time <> 1 and u.Production_Type <> 1
  	    	    	  LEFT JOIN (  	  SELECT  	  s.SliceId AS SliceId,
  	    	    	    	    	    	    	    	  sum(ed.Initial_Dimension_X) AS Total
  	    	    	    	    	    	  FROM @Slices s
 	  	  	  	  	  	  join @tempPU_Table u on u.Pu_Id =s.PUId and u.Uses_Start_Time <> 1 and u.Production_Type <> 1
  	    	    	    	    	    	    	  JOIN dbo.Events e  ON  	  s.PUId = e.PU_Id
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND e.TimeStamp > s.StartTime
  	    	    	    	    	    	    	    	    	    	    	    	    	    	    	    	  AND e.TimeStamp <= s.EndTime
  	    	    	    	    	    	    	    	  JOIN dbo.Event_Details ed  ON ed.Event_Id = e.Event_Id
  	    	    	    	    	    	  GROUP BY s.SliceId) pt ON s.SliceId = pt.SliceId
  	  --  	  END
  	  --END
 -- Populate NPLabelRef ( NP 0-->1 Transition)
UPDATE s1
SET s1.NPLabelRef = 1
FROM @Slices s1
  	  JOIN @Slices s2 ON s2.SliceId = s1.SliceId + 1 and s2.PUId = s1.PUId
WHERE s2.SliceId < (SELECT max(s3.SliceId) FROM @Slices s3 where PUId = s1.PUId)
  	  AND s2.NP = 1 AND (
  	    	  (s1.EventId = s2.EventId) OR (s1.PPId = s2.PPId) OR 
  	    	  ((s1.ProdId = s2.ProdId) AND (s1.CrewDesc = s2.CrewDesc) AND s1.EventId IS NULL AND s1.PPId IS NULL))-- OR
-- Populate NPLabelRef ( NP 1-->0 Transition)
UPDATE s1
SET s1.NPLabelRef = 1
FROM @Slices s2
  	  JOIN @Slices s1 ON s1.SliceId = s2.SliceId + 1 and s2.PUId = s1.PUId 
WHERE s1.SliceId < (SELECT max(s3.SliceId) FROM @Slices s3 where PUId = s1.PUId)
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
  	    	  EventId,PuId)
  	  SELECT 
  	    	  max(s1.StartTime) AS MaxStartTime,
  	    	  s1.EventId As EventId
 	  	  ,s1.PUId
  	  FROM @Slices s1
  	    	  JOIN @Slices s2 ON s1.EventId = s2.EventId AND s1.ProdId <> s2.ProdId and s1.PuId = s2.PuId
  	  GROUP BY s1.EventId, s1.PUId
UPDATE su
set
 	 su.ProdId = s.ProdId
From 
 	 @Slices s 
 	 join @SliceUpdate su on su.StartTime = s.StartTime and su.PuId = s.PUId  
UPDATE s
set
 	 s.ProdId = su.ProdId
From 
 	 @Slices s 
 	 join @SliceUpdate su on su.EventId = s.EventId and su.PuId = s.PUId and s.ProdId <> su.ProdId
--UPDATE su
--SET su.ProdId = s.ProdId
--FROM @Slices s, @SliceUpdate su
--WHERE s.StartTime = su.StartTime AND s.PUId = @PUId
--UPDATE s
--SET s.ProdId = su.ProdId
--FROM @Slices s,@SliceUpdate su
--WHERE s.EventId = su.EventId AND s.ProdId <> su.ProdId
-- If the event has an applied product assign the applied Product as the ProdId
UPDATE s
SET s.ProdId = s.AppliedProdId
FROM @Slices s WHERE s.AppliedProdId IS NOT Null
--<TIMED OEE CALCULATION>
DECLARE @AvailabilityName nvarchar(50), @PerformanceName nvarchar(50), @PlannedName nvarchar(50), @QualityName nvarchar(50),@AvailabilityCategoryId Int, @PerformanceTimedCategoryId Int,@PlannedCategoryId Int, @QualityCategoryId Int,@NPTimedCategoryId Int, @NonProductiveSeconds Int,@AvailabilitySeconds Int, @PerformanceSeconds Int,@PlannedSeconds Int, @QualitySeconds Int,@CalendarSeconds Int, @ActivityTime Int = 0,@UtilizationTime Int = 0, @WorkingTime Int = 0,@UsedTime Int = 0, @EffectivelyUsedTime Int = 0
DECLARE @NonProductiveTime TABLE (RowID int IDENTITY,  	  StartTime DateTime,EndTime DateTime,PuId int)
DECLARe @ProductiveTime TABLE(   	  RowID int IDENTITY,  	  StartTime DateTime,  	  EndTime DateTime, PuId int)
DECLARE @TimedDetails TABLE(StartTime DateTime,EndTime DateTime,ERCId Int, PuId int)
Declare @LastProductiveTimeRowID int, @CurrentProductiveRowID int,@CurrentProductiveStartTime Datetime, @CurrentProductiveEndTime datetime,@SliceCnt int,@cnt int
SELECT @AvailabilityName = 'Availability',@PerformanceName = 'Performance',@PlannedName = 'Planned',@QualityName = 'Quality'
SELECT @AvailabilityCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @AvailabilityName
SELECT @PerformanceTimedCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @PerformanceName
SELECT @PlannedCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @PlannedName
SELECT @QualityCategoryId = ERC_Id FROM Event_Reason_Catagories WHERE ERC_Desc = @QualityName
SELECT @NPTimedCategoryId  	  = Non_Productive_Category
  	  FROM dbo.Prod_Units_base 
  	  WHERE PU_Id = @PUId
   	   SET @cnt =1
 	   Declare @NPTSlice TABLE (SliceId Int, NPT Float)
 	   INSERT INTO @NPTSlice(NPT, SliceId)
 	   Select SUM(Datediff(second,CASE WHEN np.Start_Time < s.StartTime THEN s.StartTime
   	      	      	      	      	      	      	      	      	   ELSE np.Start_Time
   	      	      	      	      	      	      	      	      	   END,
   	      	      	      	      CASE WHEN np.End_Time > s.EndTime THEN s.EndTime
   	      	      	      	      	      	      	      	      	   ELSE np.End_Time
   	      	      	      	      	      	      	      	      	   END) ),s.SliceId
 	    FROM dbo.NonProductive_Detail np 
  	    	    	   join @tempPU_Table u on u.Pu_Id = np.PU_Id
 	  	  	   Join @Slices s on s.PUId = u.Pu_Id
   	      	      	   JOIN dbo.Event_Reason_Category_Data ercd ON   	   ercd.Event_Reason_Tree_Data_Id = np.Event_Reason_Tree_Data_Id
   	      	      	      	      	      	      	      	      	      	      	      	      	      	      	      	      	      	   AND ercd.ERC_Id = u.Non_Productive_Category
   	      	      	   WHERE   	   np.PU_Id = s.PUId
   	      	      	      	   AND np.Start_Time < s.EndTime
   	      	      	      	   AND np.End_Time > s.StartTime Group by s.SliceId
 	  	 Declare @DTSlice TABLE(SliceId Int, DT_Duration Float, ERC_DEsc varchar(100))
 	  	 INSERT INTO @DTSlice(DT_Duration,SliceId,ERC_DEsc)
 	  	  SELECT   	   SUM(datediff(second,CASE WHEN Start_Time < s.StartTime THEN s.StartTime
   	      	      	      	      	      	      	      	      	   ELSE Start_Time
   	      	      	      	      	      	      	      	      	   END, 
   	      	      	      	      	      	   CASE WHEN End_Time > s.EndTime THEN s.EndTime
   	      	      	      	      	      	      	      	      	   ELSE End_Time
   	      	      	      	      	      	      	      	      	   END) ),
   	      	      	      	      	      	    s.SliceId,EC.ERC_Desc
   	      	 FROM dbo.Timed_Event_Details ted 
   	      	 JOIN dbo.Event_Reason_Category_Data ercd  ON   	   ercd.Event_Reason_Tree_Data_Id = ted.Event_Reason_Tree_Data_Id
 	  	  	 join  Event_Reason_Catagories EC on EC.ERC_ID = ercd.ERC_Id
 	  	  	 join @Slices s on S.PUId = ted.PU_Id
 	  	  	 --join @tempPU_Table u on u.Pu_Id = ted.PU_Id
   	      	 WHERE --ted.PU_Id = @PUId
 	  	  	 1=1
   	      	      	 AND ted.Start_Time < s.EndTime
   	      	      	 AND (ted.End_Time > s.StartTime or ted.End_Time Is Null) Group by S.SliceId, EC.ERC_Desc
 	  	  	  
 	  	  	 Update S
 	  	  	 SET 
 	  	  	  	 DowntimeA = (select SUM(DT_duration) from @DTSlice Where ERC_Desc in ('Availability') and S.SliceId =SliceId),
 	  	  	  	 DowntimeP = (select SUM(DT_duration) from @DTSlice Where ERC_Desc in ('Performance') and S.SliceId =SliceId),
 	  	  	  	 DowntimeQ = (select SUM(DT_duration) from @DTSlice Where ERC_Desc in ('Quality') and S.SliceId =SliceId),
 	  	  	  	 DowntimePL = (select SUM(DT_duration) from @DTSlice Where ERC_Desc in ('Planned') and S.SliceId =SliceId),
 	  	  	  	 NPT =(Select SUM(NPT) from @NPTSlice where SliceId= s.SliceId)
 	  	  	 from @Slices S where s.PUId in (select Pu_Id from @tempPU_Table where OEEType = 4)
   	    UPDATE s
  	    SET 
  	    	  RunTimeGross = LoadingTime - (ISNULL(DowntimeA,0)+ISNULL(DownTimeP,0)+ISNULL(DownTimeQ,0)+ISNULL(DownTimePL,0)),
  	    	  ProductiveTime = CASE WHEN ProductiveTime < 0 Then 0 ELSE ProductiveTime END
  	    From  	  
  	    	  @slices s
  	    	  Join @tempPU_Table u on u.Pu_Id = s.PUId and u.OEEType = 4
    	    
--</TIMED OEE CALCULATION>
 RETURN
END
