 --------------------------------------------------------------------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
-- Revision 6.15 Last Update: 2009-04-09 Jeff Jaeger  
--  
--  This SP works with the template RptCvtgRE.xlt. The SP provides 10   
-- different result sets, depending on the value of the @BySummary parameter.    
-- Configuration report parameters are:  
  
-- @StartTime  DateTime, -- Beginning period for the data.  
-- @EndTime  DateTime, -- Ending period for the data.  
-- @ProdLineList    nVarChar(4000), -- List of production lines from which the data will be drawn   
-- @DelayTypeList  nVarChar(4000), -- Collection of "DelayType=..." from Prod_Units.Extended_Info delimited by "|".  
-- @CategoryStr  nVarChar(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
-- @SubSystemStr  nVarChar(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
-- @CatBlockStarvedId Int,  -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved.  
-- @DelayTypeRateLossStr nVarChar(100), -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
   
-- 2003-02-04 Jeff Jaeger  
-- Removed mu and line summary info to a separate result set  
  
-- 2002-02-05 Jeff Jaeger  
-- Added stored proc to AY server.  previous testing was done on MP  
  
-- 2003-02-13 Jeff Jaeger  
-- - Updated the by Location result set to use #delay.LocationID instead of Event Location  
-- - Updated formulas for MTBF and R(2) according to feedback given to Langdon Davis by Eric Zahn  
-- - Removed Total Uptime field from location, category, subsystem, failure mode, failure mode cause, fault desc  
--    result sets   
  
-- 2003-02-18 Jeff Jaeger  
--  - updated names according to standards  
  
-- 2003-02-21 Jeff Jaeger  
--  - created burn copy of sp, per request of Vince King  
  
-- 2003-02-25 Jeff Jaeger  
--  - added setting of permissions to the burn script  
  
-- 2003-03-07 Jeff Jaeger  
--  - removed the unused parameter @CvtgDTPUStr  
--  - re-added order by clauses to result sets.  they appear to have gotten dropped at some point.  
  
-- 2003-10-10 Jeff Jaeger  
--  - Moved the input validations to before any temp tables are created.  
--    This prevents tables from being created before the parameters are validated.  
--    If an error occurs, no tables need to be dropped.  
  
-- 2003-10-14 Jeff Jaeger  
--  - updated the parameter validations to display better error messages.  
  
-- 2003-10-23 Jeff Jaeger  
--  - Added a variable to store the local language, and the query to get that value.  
--  - Added addition flow control to the result sets.  If the local language is German,   
--    results will have German headers.  Else, the results will have English headers.  
--    This format can be expanded for other languages, but the header values will be   
--    determined on the fly, once the language translation table is put into place.  
--  - Modified the varchar lengths of names for displays, products, variables, and units to be  
--    100 instead of 50, because some of the German names are pretty long, and end up truncated.  
  
-- 2004-MAY-04 Langdon Davis Rev4.0  
--  - Added InRptWindow field to the #Delays table.  This field has a value of 1 if the event   
--    started, ended, or both started and ended within the report window, OR if the event  
--    totally spanned the report window.  It is used in selecting the final results sets to   
--    insure exclusion of events which are outside of the report window, but were pulled into   
--    the data set via a primary to secondary association.    
--  - Commented out production vars and other stuff not used in this report.  
--  - Changed If local_language = 'US English' to If local_language <> 'German' so that English will  
--    default for all non-German sites.  
--  - Reapplied numerous sections of the [old] Cvtg DDS-Stops code, e.g., using the   
--    Local_Timed_Event_Categories table instead of the Event_Reason_Categories table, etcetera.  
  
-- 2004-05-12 Kim Hobbs Rev4.1  
--  - Removed/commented out any reference to PM Roll Width to accommodate new   
--    genealogy model.  
  
-- 2004-10-06 Jeff Jaeger Rev5.0  
--  -  added parameters @SchedUnscheduledId, @ScheduleStr, @GroupCauseStr,   
--  @BusinessType, @IncludeStops, @UserName and related code and error checking.  
--  -  added code to split downtime events.  
--  -  added some additional fields to temporary tables to be used in splitting downtime.  
--  -  added temporary tables #EventsByShiftProduct, #UptimeByShiftProduct, #UnitSummary, #TeamSummary,   
--  #ProductSummary, #LocationSummary, #CategorySummary, #SubsytemSummary, #FailureModeSummary,   
--  #FailureModeCauseSummary, #FaultSummary, #TECategories, @RunsByTgtSpeed, @RunsLineShift, @FirstEvents   
--  along with related code.  
--  -  converted temporary tables to table variables where appropriate  
--  -  removed unused code, including the #tests temporary table   
--  -  added additional code for language translation  
--  -  added additional program variables for use in new code  
--  -  updated the inserts to temporary tables such as #delays, @ProdLines, @ProdUnits, and #Primaries to   
--  better reflect what is done in DDS Stops  
--  -  updated the result sets by adding Unscheduled Stops and Unscheduled Rpt Downtime, and changing   
--  Total Downtime to Reporting Downtime, Total Uptime to Reporting Uptime, and MTTR to Unplanned MTTR   
--  and MTBF to Unplanned MTBF.  
  
-- 2004-10-07 Jeff Jaeger  Rev5.1  
--  - modified the calc for R(2) in all the result sets.  
--  - restored some of the original code from DDS Stops, including temp tables and parameters, to   
--  more fully populate the #delays temp table.  this will be needed when the pivot table is added.  
  
  
-- 2004-10 Jeff Jaeger Rev5.2  
--  - added #Stops and the code to populate it.  
  
-- 2004-10-20 Jeff Jaeger Rev5.3  
--  - Added an update to the Comment field in #Stops to remove carriage returns from the field.  
--  - updated the inserts to #Primaries, @LineStatus, and @LineStatusRaw.  
--  - added the LineStatus field to #UptimeByShiftProduct.  
--  - added the update to LineStatus in #UptimeByShiftProduct.  
--  - Removed updates to ReportUptime in #Primaries and #Delays.  
  
-- 2004-11-04 Jeff Jaeger Rev5.4  
--  - added EquipDesc to #delays, #eventsbyshiftproduct, #uptimebyshiftproduct,   
--  and the result sets, along with the code to populate the fields.  
--  - added ScheduleID, CategoryID, SubsystemID, LocationID, teFaultID,   
--  L1ReasonID, L2ReasonID to the temp table #UptimeByShiftProduct,  
--  along with the related code to populate the fields.  
--  - rewrote the result sets and the temp tables associated with them.  the   
--  main purpose of this was to update calculations of Availability, MTTR, and  
--  MTBF.  Also removed some unrequired measurements of "unscheduled" values.  
--  - added an additional insert to #delays, in order to get the first downtime   
--  event after the report window for each puid.  
--  - removed "Blocked/Starved" related restrictions in #delays when calculating   
--  counts of stops, StopsUnscheduled, Stops2m, StopsMinor, UpTime2m,   
--  StopsProcessFailures.  
--  - updated the 3rd insert to #uptimebyshiftproduct, according to changes in   
--  the DDS Stops sp.  
--  - added Blocked/Starved to the delay type list.  
--  - added additional result sets for totalling results by line.   
--  - added result sets for Production Line and Equipment  
  
-- 2004-12-17 Jeff Jaeger Rev5.5  
--  - removed some unused code  
--  - brought this sp up to date with Checklist 110804.  
--  - removed the temp table #DelayTypes because it doesn't appear to be used.  @Delaytypes already exists.  
--  - added checks for parameter IDs.  
  
-- 2005-03-28 Jeff Jaeger Rev6.0  
--  - updated the final insert to #delays, to exclude records where the TEDetID already exits.  
--  - removed Line Speed related code.  
--  - added owner identification to object references.  for example, dbo.tablename  
--  - updated the first 4 result sets (specifically Total Stops, Report Downtime, and Report Uptime)  
--  to better reflect the requirements surrounding System and Machine level calculations for Availability,  
--  MTBF, and MTTR.  
--  - added additional coalesce statements to the result sets, as needed.  
  
-- 2005-04-25 Jeff Jaeger Rev6.1  
--  - in the update to ReportUptime in #EventsByShiftProduct, modified the where clause in the subquery  
--  to use StopsRateLoss instead of ReportRLDowntime.  If ReportRLDowntime happens to be 0, the update   
--  will pull in RateLoss ReportUptime that should not be included in the sum.  
--  - removed some dead code  
  
-- 2007-JUN-01 Langdon Davis Rev6.11  
--  - Added a parameter check for start and end time being the same.  This avoids a bunch of processing and   
--  errors on the VB side from empty/NULL results sets.  
  
--2009-02-18 Jeff Jaeger Rev6.12  
--  - note that this sp is not up to date with current methods.  this may have an impact on efficiency.   
--  - modified the method for pulling ScheduleID, CategoryID, GroupCauseID, and SubsystemID in #delays.  
--  - added "with (nolock)" to the use of tables and temp tables.  
  
--2009-03-12 Jeff Jaeger Rev6.13  
--  - added z_obs restriction to the population of @produnits  
  
--2009-03-17 Jeff Jaeger Rev6.14  
--  - modified the definition of the various flavors of stops in #Delays  
  
--2009-04-09 Jeff Jaeger Rev6.15  
--  - added a restriction on pu_desc not like '%rate%loss%' in the definition of ReportELPSchedDT.  
  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
CREATE  PROCEDURE dbo.spLocal_RptCvtgRE  
--Declare  
  @StartTime   DateTime,  -- Beginning period for the data.  
 @EndTime   DateTime,  -- Ending period for the data.  
 @ProdLineList     nVarChar(4000),  
 @DelayTypeList   nVarChar(4000),  -- Collection of "DelayType=..." from Prod_Units.Extended_Info delimited by "|".  
 @CategoryStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @SubSystemStr   nVarChar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CatMechEquipId   int,   -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
 @CatElectEquipId  int,   -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
 @CatBlockStarvedId  Int,   -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved.  
 @CatELPId   int,   -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
 @SchedPRPolyId   int,   -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
 @SchedUnscheduledId  int,   -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
 @SchedSpecialCausesId  int,   -- Event_Reason_Categories.ERC_Id for Schedule:Special Causes.  
 @SchedEOProjectsId  int,   -- Event_Reason_Categories.ERC_Id for Schedule:E.O./Projects.  
 @SchedBlockedStarvedId  int,   -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
 @SchedHolidayCurtailId  int,   -- Event_Reason_Categories.ERC_Id for Schedule:Holiday/Curtail.  
 @DelayTypeRateLossStr  nVarChar(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
 @ScheduleStr   varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @GroupCauseStr   varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @BusinessType   int,   -- 1=Tissue/Towel, 2=Napkins, 3=Facial  
 @IncludeStops   int,   -- 0 = Do not include Stops Pivottable; 1 = Include Stops Pivottable.  
 @RL1Title   varchar(100),  -- Title to be used for Reason Level 1  
 @RL2Title   varchar(100),  -- Title to be used for Reason Level 2  
 @RL3Title   varchar(100),  -- Title to be used for Reason Level 3  
 @RL4Title   varchar(100),  -- Title to be used for Reason Level 4  
 @UserName   varchar(30)  -- User calling this report  
  
AS  
  
  
/*  
--  AY  
  
Select  @StartTime = '2004-10-25 07:00:00',   
 @EndTime = '2004-10-26 07:00:00',   
 @ProdLineList = '3', --'32|33',       
 @DelayTypeList = 'Downtime|CvtrDowntime|RateLoss|BlockedStarved',   
 @CategoryStr = 'Category',   
 @SubSystemStr = 'Subsystem',   
 @CatMechEquipId = 106,--  
 @CatElectEquipId = 110,--  
 @CatBlockStarvedId = 101,   
 @CatELPId = 186,--  
 @SchedPRPolyId = 121,--  
 @SchedUnscheduledId = 208,    
 @SchedSpecialCausesId = 209,--  
 @SchedEOProjectsId = 127,--  
 @SchedBlockedStarvedId = 103,  
 @SchedHolidayCurtailId = 128,--  
 @DelayTypeRateLossStr = 'RateLoss',   
 @ScheduleStr = 'Schedule',  
 @GroupCauseStr = 'GroupCause',  
 @BusinessType = 1,  
 @IncludeStops = 0,  
 @RL1Title = 'Failure Mode',  
 @RL2Title = 'Failure Mode Cause',  
 @RL3Title = 'Reason Level 3',  
 @RL4Title = 'Reason Level 4',  
 @UserName = 'ComXClient'   
  
*/  
  
/* Cape  
  
Select  @StartTime = '2004-10-25 07:00:00',   
 @EndTime = '2004-10-26 07:00:00',   
 --@ProdLineList = '3|5|6|139|140|141|142|143|178|179|188|180|181',   
 @ProdLineList = '140',   
 @DelayTypeList = 'Downtime|CvtrDowntime',   
 @CategoryStr = 'Category',   
 @SubSystemStr = 'Subsystem',   
 @CatMechEquipId = 103,--  
 @CatElectEquipId = 104,--  
 @CatBlockStarvedId = 157,   
 @CatELPId = 118,--  
 @SchedPRPolyId = 116,--  
 @SchedUnscheduledId = 101,    
 @SchedSpecialCausesId = 132,--  
 @SchedEOProjectsId = 222,--  
 @SchedBlockedStarvedId = 158,  
 @SchedHolidayCurtailId = 109,--  
 @DelayTypeRateLossStr = 'RateLoss',   
 @ScheduleStr = 'Schedule',  
 @GroupCauseStr = 'GroupCause',  
 @BusinessType = 1,  
 @IncludeStops = 0,  
 @RL1Title = 'Failure Mode',  
 @RL2Title = 'Failure Mode Cause',  
 @RL3Title = 'Reason Level 3',  
 @RL4Title = 'Reason Level 4',  
 @UserName = 'ComXClient'   
  
*/  
  
  
/*  
--  OX  
  
Select  @StartTime = '2009-03-25 05:00:00',   
 @EndTime = '2009-03-26 05:00:00',   
 @ProdLineList = '17', --'32|33',       
 @DelayTypeList = 'Downtime|CvtrDowntime|RateLoss|BlockedStarved',   
 @CategoryStr = 'Category',   
 @SubSystemStr = 'Subsystem',   
 @CatMechEquipId = 182,--  
 @CatElectEquipId = 184,--  
 @CatBlockStarvedId = 250,   
 @CatELPId = 257,--  
 @SchedPRPolyId = 260,--  
 @SchedUnscheduledId = 190,    
 @SchedSpecialCausesId = 258,--  
 @SchedEOProjectsId = 194,--  
 @SchedBlockedStarvedId = 251,  
 @SchedHolidayCurtailId = 193,--  
 @DelayTypeRateLossStr = 'RateLoss',   
 @ScheduleStr = 'Schedule',  
 @GroupCauseStr = 'GroupCause',  
 @BusinessType = 1,  
 @IncludeStops = 1,  
 @RL1Title = 'Failure Mode',  
 @RL2Title = 'Failure Mode Cause',  
 @RL3Title = 'Reason Level 3',  
 @RL4Title = 'Reason Level 4',  
 @UserName = 'ComXClient'   
  
*/  
  
  
-------------------------------------------------------------------------------  
-- Create temporary Error Messages and ResultSet tables.  
-------------------------------------------------------------------------------  
  
CREATE TABLE dbo.#Delays (  
 TEDetId    Int Primary Key,  
 PrimaryId   Int,  
 SecondaryId   Int,  
 PLID    int,  
 PUId    Int,  
 PUDesc    nVarChar(100),  
 EquipDesc   varchar(100),  -- Rev5.4  
 StartTime   DateTime,  
 EndTime    DateTime,  
 ShiftStartTime   DateTime,  
 LocationId   Int,  
 L1ReasonId   Int,  
 L2ReasonId   Int,  
 L3ReasonId   Int,  
 L4ReasonId   Int,  
 TEFaultId   Int,  
 ERTD_ID     int,  
 L1TreeNodeId   Int,  
 L2TreeNodeId   Int,  
 L3TreeNodeId   Int,  
 L4TreeNodeId   Int,  
 ProdId    Int,  
 LineStatus   nVarChar(100),  
 Shift    nVarChar(10),  
 Crew    nVarChar(10),  
 ScheduleId   Int,  
 CategoryId   Int,  
 GroupCauseId   Int,  
 SubSystemId   Int,  
 DownTime   Int,  
 ReportDownTime   Int,  
 UpTime    Int,  
 Stops    Int,  
 StopsUnscheduled  Int,  
 Stops2m    Int,  
 StopsMinor   Int,  
 StopsEquipFails   Int,  
 StopsProcessFailures  Int,  
 StopsBlockedStarved  Int,  
 StopsELP   int,  
 StopsRateLoss   Int,  
 UpTime2m   Int,  
 ReportRLDowntime  Int,  
 ReportELPDowntime  float,  
 ReportELPSchedDT  float,  
 ReportRLELPDowntime  float,  
 RateLossRatio   float,  
 RateLossInWindow  float,  
 UWS1    nVarChar(100),  
 UWS2    nVarChar(100),  
 UWS1Parent   varchar(50),  
 UWS2Parent   varchar(50),  
 UWS1GrandParent   varchar(50),  
 UWS2GrandParent   varchar(50),  
 Comment    VarChar(5000),  
 InRptWindow   Int )  
  
  
CREATE INDEX td_PUId_StartTime  
 ON dbo.#Delays (PUId, StartTime)  
  
  
CREATE INDEX td_PUId_EndTime  
 ON dbo.#Delays (PUId, EndTime)  
  
  
CREATE TABLE dbo.#Primaries (  
 TEDetId    Int Primary Key,  
 PUId    Int,  
 StartTime   DateTime,  
 EndTime    DateTime,  
 LastEndTime   DateTime,  
 UpTime    Int,  
 TEPrimaryID   int identity)  
  
  
create table dbo.#Runs(   
 RowId    int IDENTITY,  
 PLId    int,  
 PUId    int,  
 ProdId    int,  
 ProdCode   varchar(25),  
 StartTime   datetime,  
 EndTime    datetime--,  
 )  
  
  
/*  
CREATE TABLE dbo.#TECategories ( TEC_Id  int PRIMARY KEY NONCLUSTERED IDENTITY,  
    TEDet_Id int,  
    ERC_Id  int)  
  
CREATE CLUSTERED INDEX tec_TEDetId_ERCId  
 ON dbo.#TECategories (TEDet_Id, ERC_Id)  
*/  
  
  
CREATE TABLE  dbo.#EventsByShiftProduct (  
 ebspID    int IDENTITY,  
 dbspID    int,   
 StartTime   datetime,  
 EndTime    datetime,  
 ProdId    int,  
 PLID    int,  
 PUId    int,  
 pudesc    varchar(100),  
 EquipDesc   varchar(100),  -- Rev5.4  
 Shift    varchar(10),  
 Team    varchar(10),  
 PrimaryId   int,  
 TEDetId    int,   
 TEFaultId   int,  
 ScheduleId   int,  
 CategoryId   int,  
 SubSystemId   int,  
 GroupCauseId   int,  
 LocationId   int,  
 L1ReasonId   int,  
 L2ReasonId   int,  
 L3ReasonId   int,  
 L4ReasonId   int,  
 LineStatus   varchar(50),  
 Downtime   float,  
 ReportDownTime   float,  
 ReportRLDowntime  float,  
 ReportELPSchedDT  float,  
 RateLossInWindow  float,  
 ReportRLELPDowntime  float,  
 ReportELPDowntime  float,  
 Uptime    float,  
 ReportUptime   float,  
 RateLossRatio   float,  
 PartialStops   float,  
 Stops    int,  
 StopsUnscheduled  int,  
 StopsMinor   int,  
 StopsEquipFails   int,  
 StopsProcessFailures  int,  
 StopsBlockedStarved  int,  
 StopsELP   int,  
 StopsRateLoss   int,  
 UpTime2m   int,  
 MinorEF    int,  
 ModerateEF   int,  
 MajorEF    int,  
 MinorPF    int,  
 ModeratePF   int,  
 MajorPF    int,  
 Causes    int,  
 UWS1Parent   varchar(50),  
 UWS2Parent   varchar(50),  
 UWS1GrandParent   varchar(50),  
 UWS2GrandParent   varchar(50),  
 Comment    varchar(5000)  
)  
  
  
CREATE CLUSTERED INDEX dbsp_PUId_StartTime  
 ON dbo.#EventsByShiftProduct (PUId, StartTime, EndTime)  
  
  
CREATE TABLE  dbo.#UptimeByShiftProduct (  
 dbspID    int,  
 InsertID   int,  
 StartTime   datetime,  
 EndTime    datetime,  
 ProdId    int,  
 PLID    int,  
 PUId    int,  
 pudesc    varchar(100),  
 EquipDesc   varchar(100),  -- Rev5.4  
 Shift    varchar(10),  
 Team    varchar(10),  
 ReportUptime   float,  
 LineStatus   varchar(50),  
-- following fields added so that final results can be grouped by them.  
 ScheduleID   int,  
 CategoryID   int,  
 SubsystemID   int,  
 LocationID   int,  
 teFaultID   int,  
 L1ReasonID   int,  
 L2ReasonID   int  
)  
  
  
CREATE CLUSTERED INDEX ubsp_PUId_StartTime  
 ON dbo.#UptimeByShiftProduct (PUId, StartTime, EndTime)  
  
  
create table dbo.#LineSummary (  
 [Production Line]  varchar(100),  
 [System Total Stops]  int,  
 [Total Causes]   int,  
 [System Reporting Downtime] float,  
 [System Reporting Uptime] float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [System Availability]   float,  
 [System MTBF]   float,  
 [System MTTR]   float  
)  
  
  
create table dbo.#EquipmentSummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Machine Total Stops]  int,  
 [Total Causes]   int,  
 [Machine Reporting Downtime] float,  
 [System Reporting Uptime] float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Machine Availability]  float,  
 [Machine MTBF]   float,  
 [Machine MTTR]   float  
)  
  
  
create table dbo.#UnitSummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Master Unit]   varchar(100),  --Rev5.4  
 [Total Stops]   int,  
 [Total Causes]   int,  
 [Reporting Downtime]  float,  
 [Reporting Uptime]  float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Availability]   float,  
 [MTBF]    float,  
 [MTTR]    float  
)  
  
  
create table dbo.#TeamSummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Team]    varchar(10),  
 [Machine Total Stops]  int,  
 [Total Causes]   int,  
 [Machine Reporting Downtime] float,  
 [System Reporting Uptime] float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Machine Availability]  float,  
 [Machine MTBF]   float,  
 [Machine MTTR]   float  
)  
  
  
create table dbo.#ProductSummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Product]   varchar(100),  
 [Machine Total Stops]  int,  
 [Total Causes]   int,  
 [Machine Reporting Downtime] float,  
 [System Reporting Uptime] float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Machine Availability]  float,  
 [Machine MTBF]   float,  
 [Machine MTTR]   float  
)  
  
  
create table dbo.#LocationSummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Master Unit]   varchar(100),  --Rev5.4  
 [Location]   varchar(50),  
 [Total Stops]   int,  
 [Total Causes]   int,  
 [Reporting Downtime]  float,  
 [Reporting Uptime]  float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Availability]   float,  
 [MTBF]    float,  
 [MTTR]    float  
)  
  
  
create table dbo.#CategorySummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Master Unit]   varchar(100), --Rev5.4  
 [Category]   varchar(50),  
 [Total Stops]   int,  
 [Total Causes]   int,  
 [Reporting Downtime]  float,  
 [Reporting Uptime]  float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Availability]   float,  
 [MTBF]    float,  
 [MTTR]    float  
)  
  
  
create table dbo.#SubsystemSummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Master Unit]   varchar(100),  --Rev5.4  
 [Subsystem]   varchar(50),  
 [Total Stops]   int,  
 [Total Causes]   int,  
 [Reporting Downtime]  float,  
 [Reporting Uptime]  float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Availability]   float,  
 [MTBF]    float,  
 [MTTR]    float  
)  
  
  
create table dbo.#FailureModeSummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Master Unit]   varchar(100),  --Rev5.4  
 [Failure Mode]   varchar(100),  
 [Total Stops]   int,  
 [Total Causes]   int,  
 [Reporting Downtime]  float,  
 [Reporting Uptime]  float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Availability]   float,  
 [MTBF]    float,  
 [MTTR]    float  
)  
  
  
create table dbo.#FailureModeCauseSummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Master Unit]   varchar(100),  --Rev5.4  
 [Failure Mode Cause]  varchar(100),  
 [Total Stops]   int,  
 [Total Causes]   int,  
 [Reporting Downtime]  float,  
 [Reporting Uptime]  float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Availability]   float,  
 [MTBF]    float,  
 [MTTR]    float  
)  
  
  
create table dbo.#FaultSummary (  
 [Production Line]  varchar(100),  
 [Equipment Desc]  varchar(100),  
 [Master Unit]   varchar(100),  --Rev5.4  
 [Fault Desc]   varchar(100),  
 [Total Stops]   int,  
 [Total Causes]   int,  
 [Reporting Downtime]  float,  
 [Reporting Uptime]  float,  
 [Total Uptime < 2 Min]  int,  
 [R(2)]    float,  
 [Availability]   float,  
 [MTBF]    float,  
 [MTTR]    float  
)  
  
  
CREATE TABLE dbo.#Stops ( [Production Line]  varchar(50),  
   [Master Unit]   varchar(50),  
   [Equipment Desc]  varchar(50),  --Rev5.4  
   [Start Date]   varchar(25),  
   [Start Time]   varchar(25),  
   [End Date]   varchar(25),  
   [End Time]   varchar(25),  
   [Total Stops]   int,  
   [Minor Stops]   int,  
   [Equipment Failures]  int,   
   [Process Failures]  int,  
   [Total Causes]   int,  
   [Event Downtime]  float,  
   [Reporting Downtime]  float,  
   [Uptime]   float,  
   [Reporting Uptime]  float,  
   [Total Uptime < 2 Min]  float,   
   [Rate Loss Events]  int,        
   [Rate Loss Effective Downtime] float,  
   [Total Blocked Starved]  int,  
   [Minor Equipment Failures] int,   
   [Moderate Equipment Failures] int,  
   [Major Equipment Failures] int,  
   [Minor Process Failures] int,  
   [Moderate Process Failures] int,  
   [Major Process Failures] int,  
   [Product]   varchar(25),  
   [Product Desc]   varchar(50),  
   [Event Location Type]  varchar(50),  
   [Event Type]   varchar(10),  
   [Team]    varchar(10),  
   [Shift]    varchar(10),  
   [Schedule]   varchar(50),  
   [Category]   varchar(50),  
   [SubSystem]   varchar(50),  
   [GroupCause]   varchar(50),  
   [Location]   varchar(50),  
   [RL1Title]   varchar(100),  
   [RL2Title]   varchar(100),  
   [RL3Title]   varchar(100),  
   [RL4Title]   varchar(100),  
   [Fault Desc]   varchar(100),  
   [Line Status]   varchar(25),  
   [Equipment Group]  varchar(50),  
   [UWS1GrandParent]  varchar(50),   
   [UWS1Parent]   varchar(50),   
   [UWS2GrandParent]  varchar(50),   
   [UWS2Parent]   varchar(50),   
   [Comment]   varchar(5000)  
   )  
  
  
CREATE TABLE dbo.#Tests (  
 TestId   int PRIMARY KEY NONCLUSTERED IDENTITY,  
 VarId   int,  
 PLId   int,  
 PUId   int,  
 Value   float,  
 StartTime  datetime,  
 EndTime   datetime )  
  
CREATE CLUSTERED INDEX tt_VarId_StartTime  
 ON dbo.#Tests (VarId, StartTime)  
  
  
DECLARE @ProdLines TABLE (  
 PLId    int PRIMARY KEY,  
 PLDesc    varchar(50), -- MKW - Rev 7.3  
 VarGoodUnitsId   int,  
 VarTotalUnitsId   int,  
 VarPMRollWidthId  int,  
 VarParentRollWidthId  int,  
 PropLineProdFactorId  int,  
 VarEffDowntimeId  int,  
 TotalStops   int,  
 TotalUptime   int,  
 TotalDowntime   int,  
 TotalStopsUTGT2Min  int,  
 PackOrLine   varchar(100),  
 ProdPUId   int, -- MKW  
 VarStartTimeId   int, -- MKW  
 VarEndTimeId   int, -- MKW  
 VarPRIDId   int,  
 VarParentPRIDId   int,  
 VarGrandParentPRIDId   int,  
 VarUnwindStandId  int )--, -- MKW  
  
  
DECLARE @ProdUnits TABLE (  
 PUId    int PRIMARY KEY,  
 PUDesc    varchar(100),  
 PLId    int,  
 ExtendedInfo   varchar(255),  
 DelayType   varchar(100),  
 ScheduleUnit   int,  
 LineStatusUnit   int,  
 UWSVarId   int,  
 UWS1    varchar(50),  
 UWS2    varchar(50),  
 PRIDRLVarId    int,  
 RowId    int IDENTITY )  
  
  
DECLARE @DelayTypes TABLE (  
 DelayTypeDesc   varchar(100) PRIMARY KEY)  
  
  
DECLARE @FirstEvents TABLE ( FirstEventId int IDENTITY,  
    PUId  int,  
    StartTime datetime)  
  
  
  
DECLARE @RunsLineShift TABLE (  
 PLId    int,   
 PUID    int,    
 Shift    varchar(50),  
 Team    varchar(50),  
 ProdId    int,  
 Prod_StartTime   datetime,  
 Prod_EndTime   datetime,  
 Shift_StartTime   datetime,  
 Shift_EndTime   datetime)  
  
  
DECLARE @LineStatusRaw TABLE ( PUId  int,  
    StartTime datetime,  
    PhraseId int)  
  
  
DECLARE @LineStatus TABLE ( LSId  int IDENTITY,  
    PUId  int,  
    StartTime datetime,  
    EndTime  datetime,  
    PhraseId int  
    PRIMARY KEY (PUId, StartTime))  
  
  
DECLARE @UWS TABLE ( PEIId  int PRIMARY KEY, -- MKW  
   InputName varchar(50),  -- MKW  
   InputOrder int,   -- MKW  
   PLId  int,  
   MasterPUId int,  
   UWSPUId  int )  
  
  
 DECLARE @PRsRun TABLE (  
  EventId  int,  
  PUId  int,  
  StartTime datetime,  
  EndTime  datetime,  
  ParentPRID varchar(50),   
  GrandParentPRID varchar(50),   
  UWS  varchar(25),  
  InputOrder int  --????????????????  
   )  
  
--/*  
DECLARE @LineProdVars TABLE (  
 PLId    int,  
 PUId    int,  
 VarId    int,  
 VarType    varchar(25),  
 PRIMARY KEY (PLId, VarId))  
  
  
DECLARE @ProdUnitsPack TABLE (  
 PUId    int,   
 PLId    int,  
 PLDesc    varchar(50),    
 GoodUnitsVarId   int,  
 ExtendedInfo   varchar(255),  
 ScheduleUnit   int,  
 UOM    varchar(25))  
--*/  
  
DECLARE @ProdUnitsEG TABLE (   
 RowId  int PRIMARY KEY IDENTITY,  
 PLId  int,  
 Master_PUId int,  
 Source_PUId int,  
 Source_PUDesc varchar(100),  
 ExtendedInfo varchar(255),  
 EquipGroup varchar(100)   
)  
  
DECLARE @ErrorMessages TABLE ( ErrMsg varchar(255) )  
  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
DECLARE @SearchString   nVarChar(4000),  
 @Position   Int,  
 @PartialString   nVarChar(4000),  
 @Now    DateTime,  
 @@Id    Int,  
 @@ExtendedInfo   nVarChar(255),  
 @PUDelayTypeStr   nVarChar(100),  
 @PUScheduleUnitStr  nVarChar(100),  
 @PULineStatusUnitStr  nVarChar(100),  
 @@PUId    Int,  
 @@TimeStamp   DateTime,  
 @@LastEndTime   DateTime,  
 @VarGoodUnitsId   Int,  
 @VarGoodUnitsVN   nVarChar(100),  
 @VarTotalUnitsId  Int,  
 @VarTotalUnitsVN  nVarChar(100),  
 @@PLId    Int,  
 @@VarGoodUnitsId  Int,  
 @@VarTotalUnitsId  Int,  
 @@VarEffDowntimeId  Int,  
 @LineProdFactorDesc  nVarChar(50),  
 @PropLineProdFactorId  Int,  
 @PLDesc    nVarChar(100),  
 @DelayTypeDesc   nVarChar(100),  
 @MaxNoOfUWS   Int,  
 @VarEffDowntimeId  Int,  
 @VarEffDowntimeVN  nVarChar(50),  
 @@VarId    Int,  
 @@NextStartTime   datetime,  
 @LoopCtr   Int,  
 @strSQL    nVarChar(4000),  
 @@PUDesc   nVarChar(100),  
 @@UWSVarId   nVarChar(100),  
 @@PRIDVarId   Int,  
    
 @NoDataMsg    varchar(50),  
 @TooMuchDataMsg   varchar(50),  
 @SQL    varchar(8000),  
 @LanguageId   int,  
 @UserId    int,  
 @LanguageParmId   int,  
  
 @@VarPMRollWidthId  int,  
 @@StartTime   datetime,  
 @@EndTime   datetime,  
 @LinePropCharId   int,  
 @PUEquipGroupStr  varchar(100),  
 @PRIDRLVarStr   varchar(100),  
 @@ProdCode   varchar(100),  
 @Rows    int,  
 @Row    int,  
 @RangeStartTime   datetime,  
 @RangeEndTime   datetime,  
 @Max_TEDet_Id   int,  
 @Min_TEDet_Id   int,  
 @ProdPUId   int,  
 @ReliabilityPUId  int,  
 @RateLossPUId   int,  
 @LineName   varchar(50),  
 @VarPMRollWidthId  int,  
 @VarPMRollWidthVN  varchar(100),  
 @@ProdId   int,  
 @PackOrLine   varchar(100),  
 @VarStartTimeVN   varchar(50),  
 @VarEndTimeVN   varchar(50),  
 @VarPRIDVN   varchar(50),  
 @VarUnwindStandVN  varchar(50),  
 @VarStartTimeId   int,  
 @VarEndTimeId   int,  
 @VarPRIDId   int,  
 @VarUnwindStandId  int,  
 @VarParentPRIDVN  varchar(50),  
 @VarGrandParentPRIDVN  varchar(50),  
 @VarParentRollWidthVN  varchar(50),  
 @VarParentPRIDId  int,  
 @VarGrandParentPRIDId  int,  
 @VarParentRollWidthId  Int,  
  
 @StagedStatusId   int,  
 @VarTypeStr   varchar(50)  
   
  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
  
  
IF IsDate(@StartTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
END  
IF IsDate(@EndTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@EndTime is not a Date.')  
 GOTO ReturnResultSets  
END  
IF @ProdLineList IS NULL  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@ProdLineList is not valid.')  
 GOTO ReturnResultSets  
END  
IF @DelayTypeList IS NULL  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@DelayTypeList is not valid.')  
 GOTO ReturnResultSets  
END  
IF @CategoryStr IS NULL  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CategoryStr is not valid.')  
 GOTO ReturnResultSets  
END  
IF @SubSystemStr IS NULL  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SubSystemStr is not valid.')  
 GOTO ReturnResultSets  
END  
IF @DelayTypeRateLossStr IS NULL  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@DelayTypeRateLossStr is not valid.')  
 GOTO ReturnResultSets  
END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @SchedUnscheduledId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedUnscheduledId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF @UserName not in (select username from dbo.users with (nolock))    
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@UserName is not valid.')  
 GOTO ReturnResultSets  
END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @CatMechEquipId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatMechEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @CatElectEquipId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatElectEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @CatBlockStarvedId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatBlockStarvedId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @SchedPRPolyId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedPRPolyId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @SchedSpecialCausesId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedSpecialCausesId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @SchedEOProjectsId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedEOProjectsId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @SchedBlockedStarvedId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedBlockedStarvedId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @SchedUnscheduledId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedUnscheduledId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories  with (nolock) WHERE ERC_Id = @CatELPId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatELPId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
  
  
-- If the endtime is in the future, set it to current day.  This prevent zero records from being printed on report.  
IF @EndTime > GetDate()  
 SELECT @EndTime = CONVERT(VarChar(4),YEAR(GetDate())) + '-' + CONVERT(VarChar(2),MONTH(GetDate())) + '-' +   
     CONVERT(VarChar(2),DAY(GetDate())) + ' ' + CONVERT(VarChar(2),DATEPART(hh,@EndTime)) + ':' +   
     CONVERT(VarChar(2),DATEPART(mi,@EndTime))+ ':' + CONVERT(VarChar(2),DATEPART(ss,@EndTime))  
  
IF @StartTime = @EndTime  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('The date range selected for this report has the same start and end date: ' + convert(varchar(25),@StartTime,107) +  
      ' through ' + convert(varchar(25),@EndTime,107))  
 GOTO ReturnResultSets  
 END  
  
-------------------------------------------------------------------------------  
-- Get local language  
-------------------------------------------------------------------------------  
  
SELECT @LanguageParmId  = 8,  
 @LanguageId   = NULL  
  
SELECT @UserId = User_Id  
FROM dbo.Users with (nolock)  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
    ELSE NULL  
    END  
FROM dbo.User_Parameters with (nolock)  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 BEGIN  
 SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
     ELSE NULL  
     END  
 FROM dbo.Site_Parameters with (nolock)  
 WHERE Parm_Id = @LanguageParmId  
  
 IF @LanguageId IS NULL  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
  
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
SELECT @Now = GetDate(),  
 @PUDelayTypeStr = 'DelayType=',  
 @PUScheduleUnitStr = 'ScheduleUnit=',  
 @PULineStatusUnitStr = 'LineStatusUnit=',  
 @VarGoodUnitsVN = 'Good Units',  
 @VarTotalUnitsVN = 'Total Units',  
 @MaxNoOfUWS = 2,  
 @VarEffDowntimeVN = 'Effective Downtime',  
 @LineProdFactorDesc = 'Production Factors',  
 @VarTypeStr   = 'VarType='  
  
  
-------------------------------------------------------------------------------  
-- Parse the passed lists into temporary tables.  
-------------------------------------------------------------------------------  
  
  
SELECT @SearchString = LTrim(RTrim(@ProdLineList))  
WHILE Len(@SearchString) > 0  
 BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  SELECT @PartialString = RTrim(@SearchString),  
   @SearchString = ''  
 ELSE  
  SELECT @PartialString = RTrim(SubString(@SearchString, 1, @Position - 1)),  
   @SearchString = LTrim(RTrim(Substring(@SearchString, (@Position + 1), Len(@SearchString))))  
 IF Len(@PartialString) > 0  
  BEGIN  
  IF IsNumeric(@PartialString) <> 1  
  BEGIN  
   INSERT @ErrorMessages (ErrMsg)  
    VALUES ('Parameter @ProdLineList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
  END  
  IF (SELECT Count(PLId) FROM @ProdLines WHERE PLId = Convert(Int, @PartialString)) = 0  
   BEGIN  
  
   SELECT  @VarGoodUnitsId   = NULL,  
    @VarTotalUnitsId  = NULL,  
    @VarPMRollWidthId  = NULL,  
    @VarParentRollWidthId  = NULL,  
    @PropLineProdFactorId  = NULL,  
    @VarEffDowntimeId  = NULL,  
    @PackOrLine   = NULL,  
    @VarPRIDId    = NULL,  
    @VarParentPRIDId  = NULL,    
    @VarGrandParentPRIDId  = NULL --,  
  
  
   SELECT @PLDesc  = PL_Desc,  
    @@ExtendedInfo = Extended_Info--,  
   FROM dbo.Prod_Lines with (nolock)  
   WHERE PL_Id = @@PLId  
  
   -- MKW Get PU ids  
   SELECT @ProdPUId = PU_Id  
   FROM dbo.Prod_Units with (nolock)  
   WHERE PL_Id = @@PLId  
    AND PU_Desc LIKE '%Converter Production'  
  
   SELECT @ReliabilityPUId = PU_Id  
   FROM dbo.Prod_Units with (nolock)  
   WHERE PL_Id = @@PLId  
    AND PU_Desc LIKE '%Converter Reliability'  
  
   SELECT @RateLossPUId = PU_Id  
   FROM dbo.Prod_Units with (nolock)  
   WHERE PL_Id = @@PLId  
    AND PU_Desc LIKE '%Rate Loss'  
  
  
   SELECT @VarGoodUnitsId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarGoodUnitsVN)  
   SELECT @VarTotalUnitsId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarTotalUnitsVN)  
   SELECT @VarEffDowntimeId = GBDB.dbo.fnLocal_GlblGetVarId(@RateLossPUId, @VarEffDowntimeVN)  
   SELECT @VarStartTimeId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarStartTimeVN)  
   SELECT @VarEndTimeId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarEndTimeVN)  
   SELECT @VarUnwindStandId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarUnwindStandVN)  
      
   SELECT @VarPMRollWidthId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarPMRollWidthVN)  
   SELECT @VarPRIDId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarPRIDVN)  
      
   -- JSJ Rev7.4  added for new genealogy model  
   SELECT @VarParentRollWidthId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarParentRollWidthVN)  
   SELECT @VarParentPRIDId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarParentPRIDVN)  
   SELECT @VarGrandParentPRIDId = GBDB.dbo.fnLocal_GlblGetVarId(@ProdPUId, @VarGrandParentPRIDVN)  
  
  
   IF @BusinessType = 3  
    BEGIN  
    SELECT @LineName = ltrim(rtrim(replace(@PLDesc,'PP ','')))  
  
    -- Production Factor property  
    SELECT @PropLineProdFactorId = Prop_Id  
    FROM dbo.Product_Properties with (nolock)  
    Where Prop_Desc = @LineName + ' ' + @LineProdFactorDesc  
    END  
   ELSE  
    BEGIN  
    SELECT @LineName = ltrim(rtrim(replace(@PLDesc,'TT ','')))  
  
    -- Production Factor property  
    SELECT @PropLineProdFactorId = Prop_Id  
    FROM dbo.Product_Properties with (nolock)  
    Where Prop_Desc = @LineName + ' ' + @LineProdFactorDesc  
  
    END  
  
      
   INSERT @ProdLines ( PLId,  
      PLDesc,    -- MKW - Rev 7.3  
      VarGoodUnitsId,  
      VarTotalUnitsId,   
      VarPMRollWidthId,  
      VarParentRollWidthId,  
      PropLineProdFactorId,  
      VarEffDowntimeId,  
      PackOrLine,  
      ProdPUId,  
      VarStartTimeId,  
      VarEndTimeId,  
      VarPRIDId,  
      VarParentPRIDId,  
      VarGrandParentPRIDId,   
      VarUnwindStandId) --,  
  
   VALUES ( convert(int, @PartialString),  
     @PLDesc,   -- MKW - Rev 7.3  
     @VarGoodUnitsId,  
     @VarTotalUnitsId,  
     @VarPMRollWidthId,  
     @VarParentRollWidthId,  
     @PropLineProdFactorId,  
     @VarEffDowntimeId,  
     @PackOrLine,  
     @ProdPUId,  
     @VarStartTimeId,  
     @VarEndTimeId,  
     @VarPRIDId,  
     @VarParentPRIDId,  
     @VarGrandParentPRIDId,   
     @VarUnwindStandId) --,  
  
   END  
 END  
END  
  
IF (SELECT count(PLId) FROM @ProdLines) = 0  
 BEGIN  
 INSERT @ProdLines (PLId)  
 SELECT PL_Id  
 FROM dbo.Prod_Lines with (nolock)  
 END  
  
-------------------------------------------------------------------------------  
-- DelayTypeList  
-------------------------------------------------------------------------------  
  
SELECT @SearchString = ltrim(rtrim(@DelayTypeList))  
WHILE len(@SearchString) > 0  
 BEGIN  
 SELECT @Position = CharIndex('|', @SearchString)  
 IF  @Position = 0  
  BEGIN  
  SELECT @PartialString = rtrim(@SearchString),  
   @SearchString = ''  
  END  
 ELSE  
  BEGIN  
  SELECT @PartialString = rtrim(substring(@SearchString, 1, @Position - 1)),  
   @SearchString = ltrim(rtrim(substring(@SearchString, (@Position + 1), len(@SearchString))))  
  END  
 IF len(@PartialString) > 0  
  AND (SELECT count(DelayTypeDesc) FROM @DelayTypes WHERE DelayTypeDesc = @PartialString) = 0  
  BEGIN  
  INSERT @DelayTypes (DelayTypeDesc)   
  VALUES (@PartialString)  
  END  
 END  
  
-------------------------------------------------------------------------------  
-- Fill out #UWS table.  
-------------------------------------------------------------------------------  
  
INSERT INTO @UWS ( PEIId,  
   InputName,  
   InputOrder,  
   PLId,  
   MasterPUId,  
   UWSPUId )  
SELECT pei.PEI_Id,  
 pei.Input_Name,  
 pei.Input_Order,  
 pl.PLId,  
 pu.Master_Unit,  
 pu.PU_Id  
FROM dbo.PrdExec_Inputs pei with (nolock)  
 INNER JOIN @ProdLines pl ON pl.ProdPUId = pei.PU_Id  
     AND PackOrLine = 'LINE'  
 LEFT JOIN dbo.Prod_Units pu with (nolock) ON pu.PL_Id = pl.PLId  
  
     AND charindex('UWSORDER='+convert(varchar(5), pei.Input_Order), upper(replace(pu.Extended_Info, ' ', ''))) > 0  
-------------------------------------------------------------------------------  
-- ProdUnitList  
-------------------------------------------------------------------------------  
  
INSERT @ProdUnits ( PUId,  
   PUDesc,  
   PLId,  
   ExtendedInfo,  
   DelayType,  
   ScheduleUnit,  
   LineStatusUnit,  
   UWSVarId,    
   PRIDRLVarId)  
SELECT pu.PU_Id,  
 pu.PU_Desc,  
 pu.PL_Id,  
 pu.Extended_Info,  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr),  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUScheduleUnitStr),  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PULineStatusUnitStr),  
 tpl.VarUnwindStandId,  
 rlv.Var_Id  
FROM dbo.Prod_Units pu with (nolock)  
 INNER JOIN @ProdLines tpl ON pu.PL_Id = tpl.PLId  
 JOIN dbo.Event_Configuration ec with (nolock) ON pu.PU_Id = ec.PU_Id  
 JOIN @DelayTypes dt ON dt.DelayTypeDesc = GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr) -- This removes unwanted delay types  
 LEFT JOIN dbo.Variables rlv  with (nolock) ON rlv.PU_Id = pu.PU_Id AND rlv.Var_Desc = @PRIDRLVarStr  
WHERE pu.Master_Unit IS NULL  
 AND ec.ET_Id = 2  
AND pu_desc not like '%z_obs%'  
  
  
------------------------------------------------------------------------------  
-- Collect all the Production Run records for the reporting period for the  
-- converter reliability unit.  Only include units with the correct DelayType.  
-------------------------------------------------------------------------------  
  
INSERT dbo.#Runs ( PLId,  
  PUId,  
  ProdId,  
  ProdCode,  
  StartTime,  
  EndTime)  
SELECT distinct pu.PLId,  
 ps.PU_Id,  
 ps.Prod_Id,  
 p.Prod_Code,  
 ps.Start_Time,  
 coalesce(ps.End_Time, @Now)  
FROM dbo.Production_Starts ps with (nolock)  
 INNER JOIN @ProdUnits pu ON ps.PU_Id = pu.PUId  
     AND pu.PUId > 0  
 INNER JOIN @DelayTypes dt ON pu.DelayType = dt.DelayTypeDesc  
 INNER JOIN dbo.Products p with (nolock) ON ps.Prod_Id = p.Prod_Id  
WHERE ps.Prod_Id > 0  
 AND ps.Start_Time < @EndTime  
 AND (ps.End_Time > @StartTime OR ps.End_Time IS NULL)  
 and pu.plid in (select plid from @prodlines)  
ORDER BY ps.start_time, ps.PU_Id  
  
  
SELECT  @Rows = @@ROWCOUNT,  
 @Row = 0  
  
  
-------------------------------------------------------------------------------  
-- Collect dataset filtered by report period and Production Units.  
-------------------------------------------------------------------------------  
--print '#Delays insert 1'  
  
INSERT dbo.#Delays ( TEDetId,   
   PUId,   
   EquipDesc,  -- Rev5.4  
   StartTime,   
   EndTime,   
   LocationId,  
   L1ReasonId,  
   L2ReasonId,   
   L3ReasonId,   
   L4ReasonId,   
   TEFaultId,  
   ERTD_ID,  
   DownTime,  
   ReportDownTime,  
   PrimaryId,   
   SecondaryId,   
   InRptWindow)  
SELECT   ted.TEDet_Id,   
   ted.PU_Id,  
   GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, 'DelayType='),  -- Rev5.4  
   ted.Start_Time,   
   Coalesce(ted.End_Time, @Now),   
   ted.Source_PU_Id,  
   ted.Reason_Level1,   
   ted.Reason_Level2,   
   ted.Reason_Level3,   
   ted.Reason_Level4,   
   ted.TEFault_Id,  
   ted.event_reason_tree_data_id,  
   DateDiff(Second, ted.Start_Time, Coalesce(ted.End_Time, @Now)),  
   Coalesce(DATEDIFF(ss, (CASE  WHEN ted.Start_Time <= @StartTime   
           THEN @StartTime   
           ELSE ted.Start_Time   
       END),   
                 (CASE  WHEN Coalesce(ted.End_Time, @Now) >= @EndTime   
           THEN @EndTime   
           ELSE Coalesce(ted.End_Time, @Now)   
       END)), 0.0),    
   ted2.TEDet_Id,   
   ted3.TEDet_Id,  
  CASE WHEN (   --Events that started outside the report window but ended within it.  
        (ted.Start_Time < @StartTime AND (Coalesce(ted.End_Time, @Now) >= @StartTime AND Coalesce(ted.End_Time, @Now) <= @EndTime))   
                 OR --Events that started and ended within the report window.  
           (ted.Start_Time >= @StartTime AND Coalesce(ted.End_Time, @Now) <= @EndTime)   
                 OR --Events that ended outside the report window but started within it.  
        (Coalesce(ted.End_Time, @Now) > @EndTime AND (ted.Start_Time >= @StartTime AND ted.Start_Time <= @EndTime))  
     OR --Events that span the entire report window  
        (ted.Start_Time < @StartTime and Coalesce(ted.End_Time, @Now) > @EndTime)  
    )  
   THEN  1  
   ELSE 0 END  
  FROM  dbo.Timed_Event_Details ted with (nolock)  
   JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
  LEFT JOIN dbo.Prod_Units pu  with (nolock) ON tpu.PUId = pu.PU_Id  
  LEFT JOIN dbo.Prod_Lines pl  with (nolock) ON pu.PL_Id = pl.PL_Id  
  LEFT JOIN dbo.Timed_Event_Details ted2 with (nolock) ON ted.PU_Id = ted2.PU_Id  
    AND ted.Start_Time = ted2.End_Time  
    AND ted.TEDet_Id <> ted2.TEDet_Id  
  LEFT JOIN dbo.Timed_Event_Details ted3 with (nolock) ON ted.PU_Id = ted3.PU_Id  
    AND ted.End_Time = ted3.Start_Time  
    AND ted.TEDet_Id <> ted3.TEDet_Id  
  WHERE  ted.Start_Time < @EndTime  
  AND  (ted.End_Time >= @StartTime  
    OR ted.End_Time IS NULL)  
  
  
-------------------------------------------------------------------------------  
-- Add the detail records that span either end of this collection but may not be  
-- in the data set.  These are records related to multi-downtime events where only  
-- one of the set is within the Report Period.  
-------------------------------------------------------------------------------  
  
-- Multi-event downtime records that span prior to the Report Period.  
--print '#Delays insert 2'  
  
WHILE (SELECT Count(td1.TEDetId)  
  FROM dbo.#Delays td1 with (nolock)  
  LEFT JOIN dbo.#Delays td2  with (nolock)  
  ON td1.PrimaryId = td2.TEDetId  
  WHERE  td2.TEDetId IS NULL  
  AND  td1.PrimaryId IS NOT NULL) > 0  
 INSERT dbo.#Delays ( TEDetId,   
    PUId,   
    EquipDesc,  -- Rev5.4  
    StartTime,   
    EndTime,   
    LocationId,  
    L1ReasonId,   
    L2ReasonId,   
    L3ReasonId,   
    L4ReasonId,   
    TEFaultId,  
    ERTD_ID,  
    DownTime,   
    ReportDownTime,  
    PrimaryId,   
    InRptWindow)  
 SELECT   ted.TEDet_Id,   
    ted.PU_Id,  
    GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, 'DelayType='),  -- Rev5.4  
    ted.Start_Time,   
    Coalesce(ted.End_Time, @Now),   
    ted.Source_PU_Id,  
    ted.Reason_Level1,   
    ted.Reason_Level2,   
    ted.Reason_Level3,   
    ted.Reason_Level4,   
    ted.TEFault_Id,  
    ted.event_reason_tree_data_id,  
    DateDiff(Second, ted.Start_Time, Coalesce(ted.End_Time, @Now)),   
    0,  
    ted2.TEDet_Id,  
          CASE WHEN (   --Events that started outside the report window but ended within it.  
               (ted.Start_Time < @StartTime AND (ted.End_Time >= @StartTime AND ted.End_Time <= @EndTime))   
                         OR --Events that started and ended within the report window.  
                  (ted.Start_Time >= @StartTime AND ted.End_Time <= @EndTime)   
                         OR --Events that ended outside the report window but started within it.  
               (ted.End_Time > @EndTime AND (ted.Start_Time >= @StartTime AND ted.Start_Time <= @EndTime))  
             OR --Events that span the entire report window  
               (ted.Start_Time < @StartTime and ted.End_Time > @EndTime)  
     )  
    THEN  1  
    ELSE 0 END  
   FROM  dbo.Timed_Event_Details ted with (nolock)  
    JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
   LEFT JOIN dbo.Prod_Units pu with (nolock) ON tpu.PUId = pu.PU_Id  
   LEFT JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
   LEFT JOIN dbo.Timed_Event_Details ted2 with (nolock) ON ted.PU_Id = ted2.PU_Id  
     AND ted.Start_Time = ted2.End_Time  
     AND ted.TEDet_Id <> ted2.TEDet_Id  
   WHERE  ted.TEDet_Id IN (SELECT td1.PrimaryId  
        FROM dbo.#Delays td1  with (nolock)  
        LEFT JOIN dbo.#Delays td2 with (nolock)  
        ON td1.PrimaryId = td2.TEDetId  
        WHERE  td2.TEDetId IS NULL  
        AND  td1.PrimaryId IS NOT NULL)  
  
  
--print '#Delays insert 3'  
  
WHILE (SELECT Count(td1.TEDetId)  
  FROM dbo.#Delays td1 with (nolock)  
  LEFT JOIN dbo.#Delays td2 with (nolock)   
  ON td1.SecondaryId = td2.TEDetId  
  WHERE  td2.TEDetId IS NULL  
  AND  td1.SecondaryId IS NOT NULL) > 0  
 INSERT dbo.#Delays ( TEDetId,   
    PUId,   
    EquipDesc,  -- Rev5.4  
    StartTime,   
    EndTime,   
    LocationId,  
    L1ReasonId,   
    L2ReasonId,   
    L3ReasonId,  
    L4ReasonId,   
    TEFaultId,  
    ERTD_ID,  
    DownTime,   
    ReportDownTime,  
    SecondaryId,   
    InRptWindow)  
 SELECT   ted.TEDet_Id,   
    ted.PU_Id,  
    GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, 'DelayType='),  -- Rev5.4  
    ted.Start_Time,   
    Coalesce(ted.End_Time, @Now),   
    ted.Source_PU_Id,  
    ted.Reason_Level1,   
    ted.Reason_Level2,   
    ted.Reason_Level3,   
    ted.Reason_Level4,   
    ted.TEFault_Id,  
    ted.event_reason_tree_data_id,  
    DateDiff(Second, ted.Start_Time, Coalesce(ted.End_Time, @Now)),  
    0,  
    ted3.TEDet_Id,  
          CASE WHEN (   --Events that started outside the report window but ended within it.  
               (ted.Start_Time < @StartTime AND (ted.End_Time >= @StartTime AND ted.End_Time <= @EndTime))   
                         OR --Events that started and ended within the report window.  
                  (ted.Start_Time >= @StartTime AND ted.End_Time <= @EndTime)   
                         OR --Events that ended outside the report window but started within it.  
               (ted.End_Time > @EndTime AND (ted.Start_Time >= @StartTime AND ted.Start_Time <= @EndTime))  
             OR --Events that span the entire report window  
               (ted.Start_Time < @StartTime and ted.End_Time > @EndTime)  
     )  
    THEN  1  
    ELSE 0 END  
   FROM  dbo.Timed_Event_Details ted with (nolock)  
   JOIN  @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
   LEFT JOIN dbo.Prod_Units pu with (nolock) ON tpu.PUId = pu.PU_Id  
   LEFT JOIN dbo.Timed_Event_Details ted3 with (nolock) ON ted.PU_Id = ted3.PU_Id  
     AND ted.End_Time = ted3.Start_Time  
     AND ted.TEDet_Id <> ted3.TEDet_Id  
   WHERE  ted.TEDet_Id IN (SELECT td1.SecondaryId  
        FROM dbo.#Delays td1 with (nolock)  
        LEFT JOIN dbo.#Delays td2  with (nolock)   
        ON td1.SecondaryId = td2.TEDetId  
        WHERE  td2.TEDetId IS NULL  
        AND  td1.SecondaryId IS NOT NULL)  
  
  
-------------------------------------------------------------------------------  
-- Collect last downtime before the first primary record of each unit to calculate  
-- uptime for those records  
-------------------------------------------------------------------------------  
  
--print '#Delays insert First Events'  
  
INSERT INTO @FirstEvents ( PUId,  
    StartTime )  
SELECT PUId,  
 MIN(StartTime)  
FROM dbo.#Delays with (nolock)  
GROUP BY PUId  
  
SELECT  @Rows = @@ROWCOUNT,  
 @Row = 0  
  
WHILE @Row < @Rows  
 BEGIN  
 SELECT @Row = @Row + 1  
   
 SELECT @@PUId  = PUId,  
  @@StartTime = StartTime  
 FROM @FirstEvents  
 WHERE FirstEventId = @Row  
  
 INSERT dbo.#Delays (TEDetId,  
   PUId,  
   EquipDesc,  -- Rev5.4  
   StartTime,  
   EndTime,  
   LocationId,  
   L1ReasonId,  
   L2ReasonId,  
   L3ReasonId,  
   L4ReasonId,  
   TEFaultId,  
   ERTD_ID,  
   DownTime,  
   ReportDownTime,  
   InRptWindow)  
 SELECT TOP 1 ted.TEDet_Id,  
   ted.PU_Id,  
   GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, 'DelayType='),  -- Rev5.4  
   ted.Start_Time,  
   coalesce(ted.End_Time, @Now),  
   ted.Source_PU_Id,  
   ted.Reason_Level1,  
   ted.Reason_Level2,  
   ted.Reason_Level3,  
   ted.Reason_Level4,  
   ted.TEFault_Id,  
   ted.event_reason_tree_data_id,  
   datediff(s, ted.Start_Time,  
   coalesce(ted.End_Time, @Now)),  
   coalesce(datediff(s, CASE WHEN ted.Start_Time <= @StartTime THEN @StartTime   
       ELSE ted.Start_Time  
       END,   
      CASE WHEN coalesce(ted.End_Time, @Now) >= @EndTime THEN @EndTime   
       ELSE coalesce(ted.End_Time, @Now)  
       END), 0.0),    
   CASE WHEN ( --Events that started outside the report window but ended within it.  
     ( ted.Start_Time < @StartTime  
      AND ( coalesce(ted.End_Time, @Now) >= @StartTime  
       AND coalesce(ted.End_Time, @Now) <= @EndTime))   
     --Events that started and ended within the report window.  
     OR ( ted.Start_Time >= @StartTime  
      AND Coalesce(ted.End_Time, @Now) <= @EndTime)   
     --Events that ended outside the report window but started within it.  
     OR ( coalesce(ted.End_Time, @Now) > @EndTime  
      AND ( ted.Start_Time >= @StartTime  
       AND ted.Start_Time <= @EndTime))  
     --Events that span the entire report window  
     OR ( ted.Start_Time < @StartTime  
      AND Coalesce(ted.End_Time, @Now) > @EndTime)  
     ) THEN 1  
    ELSE 0  
    END  
   FROM  dbo.Timed_Event_Details ted with (nolock)  
   JOIN  @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
   JOIN dbo.Prod_Units pu with (nolock) ON tpu.PUId = pu.PU_Id  
 WHERE ted.PU_Id = @@PUId  
  AND ted.Start_Time < @@StartTime  
 ORDER BY Start_Time DESC   
  
  
--print '#Delays First Record'  
  
 INSERT dbo.#Delays (TEDetId,  
   PUId,  
   EquipDesc,  -- Rev5.4  
   StartTime,  
   EndTime,  
   LocationId,  
   L1ReasonId,  
   L2ReasonId,  
   L3ReasonId,  
   L4ReasonId,  
   TEFaultId,  
   ERTD_ID,  
   DownTime,  
   ReportDownTime,  
   InRptWindow)  
 SELECT TOP 1 ted.TEDet_Id,  
   ted.PU_Id,  
   GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, 'DelayType='),  -- Rev5.4  
   ted.Start_Time,  
   coalesce(ted.End_Time, @Now),  
   ted.Source_PU_Id,  
   ted.Reason_Level1,  
   ted.Reason_Level2,  
   ted.Reason_Level3,  
   ted.Reason_Level4,  
   ted.TEFault_Id,  
   ted.event_reason_tree_data_id,  
   datediff(s, ted.Start_Time,  
   coalesce(ted.End_Time, @Now)),  
   coalesce(datediff(s, CASE WHEN ted.Start_Time <= @StartTime THEN @StartTime   
       ELSE ted.Start_Time  
       END,   
      CASE WHEN coalesce(ted.End_Time, @Now) >= @EndTime THEN @EndTime   
       ELSE coalesce(ted.End_Time, @Now)  
       END), 0.0),    
   0  
     
 FROM  dbo.Timed_Event_Details ted with (nolock)  
 JOIN  @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON tpu.PUId = pu.PU_Id  
 WHERE ted.PU_Id = @@PUId  
  AND ted.Start_Time > @EndTime  
  and TEDet_ID not in(select td.TEDetID from dbo.#delays td with (nolock))  
 ORDER BY Start_Time ASC   
  
 END  
  
  
Update dbo.#Delays set  
 Plid = (select pl_id from dbo.prod_units with (nolock) where pu_id = puid)  
  
  
  
UPDATE td SET   
 PUDESC =   
    (CASE WHEN pu.PU_Desc NOT LIKE ('%Converter Reliability%') AND (pu.PU_Desc NOT LIKE '%Rate Loss%')  
     THEN pu.PU_Desc  
     ELSE LTRIM(RTRIM(REPLACE(pl.PL_Desc,'TT ',''))) + ' Converter Reliability' END)  
 FROM  dbo.#Delays td with (nolock)  
 JOIN  dbo.Prod_Units pu with (nolock) ON td.PUID = pu.PU_Id  
 JOIN dbo.Prod_Lines pl  with (nolock) ON pu.PL_Id = pl.PL_Id  
 WHERE PUDESC IS NULL  
  
  
-- Rev5.4  
update dbo.#delays set  
  EquipDesc =  
  case -- need to account for each delaytype in @DelayTypeList  
  when upper(equipdesc) in ('DOWNTIME','CVTRDOWNTIME','RATELOSS')  
  then ltrim(rtrim(replace(pudesc,'Reliability','')))   
  when upper(equipdesc) = 'BLOCKEDSTARVED'  
  then ltrim(rtrim(replace(pudesc,'Blocked/Starved','')))   
  else '' end    
  
  
update dbo.#Runs set  
 starttime = @starttime  
where starttime < @starttime  
  
update dbo.#Runs set  
 endtime = @endtime  
where endtime > @endtime  
  
  
-- MKW - Get the maximum range for later queries  
SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
 @Min_TEDet_Id = MIN(TEDetId) - 1,  
 @RangeStartTime = MIN(StartTime),  
 @RangeEndTime = MAX(EndTime)  
FROM dbo.#Delays with (nolock)  
  
  
-------------------------------------------------------------------------------  
-- Filter the Production Unit list to only include the passed Delay Type list   
-- for the @ProdUnits and #Runs tables.  
-------------------------------------------------------------------------------  
IF @IncludeStops = 1  
BEGIN  
  
INSERT INTO @ProdUnitsEG ( PLId,  
    Master_PUId,  
    Source_PUId,  
    Source_PUDesc,  
    ExtendedInfo,  
    EquipGroup)  
SELECT ppu.PLId,  
 Master_Unit,  
 PU_Id,  
 PU_Desc,  
 Extended_Info,  
 GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, @PUEquipGroupStr)  
FROM @ProdUnits ppu  
 JOIN dbo.Prod_Units pu with (nolock) ON ppu.PUId = pu.PU_Id  
  
-- Insert Slave Production Units into #ProdUnitsEG  
INSERT INTO @ProdUnitsEG ( PLId,  
    Master_PUId,  
    Source_PUId,  
    Source_PUDesc,  
    ExtendedInfo,  
    EquipGroup)  
SELECT ppu.PLId,  
 Master_Unit,  
 PU_Id,  
 PU_Desc,  
 Extended_Info,  
 GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, @PUEquipGroupStr)  
FROM @ProdUnits ppu  
 JOIN dbo.Prod_Units pu with (nolock) ON ppu.PUId = pu.Master_Unit  
  
end  
  
  
--  Moved @RunsLineShift and @RunsLineShiftSum for Splitting Downtime 062904  JSJ  
-------------------------------------------------------------------------------  
-- Collect all the Production Run records for the reporting period for each  
-- production line by Shift/Team.  
-------------------------------------------------------------------------------  
  
INSERT @RunsLineShift ( PLId,  
   PUID,  
   ProdId,  
   Shift,  
   Team,  
   Prod_StartTime,  
   Prod_EndTime,  
   Shift_StartTime,  
   Shift_EndTime)  
SELECT pl.PL_Id,  
 pu.puid,  
 ProdId,  
 Shift_Desc,  
 Crew_Desc,  
 StartTime,  
 EndTime,   
 (CASE WHEN StartTime > cs.Start_Time THEN StartTime ELSE cs.Start_Time END),   
 (CASE WHEN EndTime < cs.End_Time THEN EndTime ELSE cs.End_Time END)  
FROM dbo.#runs rts  with (nolock)--@RunsByTgtSpeed rts  
 LEFT JOIN @ProdUnits pu  ON rts.PUId = pu.PUId  
 LEFT JOIN dbo.Crew_Schedule cs  with (nolock) ON pu.ScheduleUnit = cs.PU_Id  
 LEFT JOIN dbo.Prod_Lines pl  with (nolock) ON rts.PLId = pl.PL_Id  
WHERE  cs.Start_Time < @EndTime  
 AND cs.Start_Time < EndTime  
 AND (cs.End_Time > @StartTime OR cs.End_Time IS NULL)  
 AND ( (cs.Start_Time >= StartTime AND cs.Start_Time <= EndTime)   
  OR (cs.End_Time >= StartTime AND cs.End_Time <= EndTime)  
  OR (cs.Start_Time <= StartTime AND cs.End_Time >= EndTime))  
--Why is there grouping?????????????????????/  
GROUP BY pl.PL_Id,  
  ProdId,  
  Shift_Desc,  
  Crew_Desc,  
  StartTime,  
  EndTime,   
  (CASE WHEN StartTime > cs.Start_Time THEN StartTime ELSE cs.Start_Time END),   
  (CASE WHEN EndTime < cs.End_Time THEN EndTime ELSE cs.End_Time END),  
  pu.puid  
  
UPDATE @RunsLineShift  
SET  Shift_StartTime = CASE WHEN Shift_StartTime < @StartTime THEN @StartTime  
    ELSE Shift_StartTime  
    END,  
 Shift_EndTime = CASE WHEN Shift_EndTime > @EndTime THEN @EndTime  
    ELSE Shift_EndTime  
    END  
  
  
-------------------------------------------------------------------------------  
-- Cycle through the dataset and ensure that all the PrimaryIds point to the  
-- actual Primary event.  
-------------------------------------------------------------------------------  
WHILE (SELECT Count(td1.TEDetId)  
  FROM dbo.#Delays td1 with (nolock)  
  JOIN dbo.#Delays td2  with (nolock) ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL) > 0  
 UPDATE td1  
  SET PrimaryId = td2.PrimaryId  
  FROM dbo.#Delays td1 with (nolock)  
  JOIN dbo.#Delays td2  with (nolock) ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL  
UPDATE dbo.#Delays   
 SET PrimaryId = TEDetId  
 WHERE PrimaryId IS NULL  
  
-------------------------------------------------------------------------------  
-- Add the Products to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET ProdId = ps.Prod_Id  
 FROM dbo.#Delays td with (nolock)  
 JOIN dbo.Production_Starts ps  with (nolock) ON td.PUId = ps.PU_Id  
  AND td.StartTime >= ps.Start_Time  
  AND (td.StartTime < ps.End_Time  
   OR ps.End_Time IS NULL)  
WHERE ps.Start_Time < @RangeEndTime  
 AND (ps.End_Time > @RangeStartTime OR ps.End_Time IS NULL)  -- MKW  
  
  
-------------------------------------------------------------------------------  
-- Add the Shift and Crew to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET Shift = cs.Shift_Desc,  
  Crew = cs.Crew_Desc  
 FROM dbo.#Delays td with (nolock)  
 JOIN @ProdUnits tpu  ON td.PUId = tpu.PUId  
 JOIN dbo.Crew_Schedule cs  with (nolock) ON tpu.ScheduleUnit = cs.PU_Id  
  AND td.StartTime >= cs.Start_Time  
  AND td.StartTime < cs.End_Time  
WHERE td.StartTime >= @StartTime      -- MKW - 7.34  
  
-- Set the Crew for events that started prior to the Report StartTime.  
UPDATE  td  
 SET Shift = cs.Shift_Desc,  
  Crew = cs.Crew_Desc  
 FROM dbo.#Delays td with (nolock)  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
 JOIN dbo.Crew_Schedule cs  with (nolock) ON tpu.ScheduleUnit = cs.PU_Id  
  AND @StartTime >= cs.Start_Time  
  AND @StartTime < cs.End_Time  
 WHERE  td.StartTime < @StartTime  
  
  
INSERT INTO @LineStatusRaw ( PUId,  
    PhraseId,  
    StartTime)  
SELECT pu.PUId,  
 ls.Line_Status_Id,  
 ls.Start_DateTime  
FROM dbo.Local_PG_Line_Status ls with (nolock)  
 INNER JOIN @ProdUnits pu ON ls.Unit_Id = pu.LineStatusUnit AND pu.PUId > 0  
WHERE ls.Start_DateTime <    (CASE  WHEN @endtime >   @RangeEndTime   THEN @endtime   ELSE @RangeEndTime   END)  
 AND (ls.end_DateTime > (CASE  WHEN @starttime < @RangeStartTime THEN @starttime ELSE @RangeStartTime END)   
      OR ls.End_DateTime IS NULL)  
 AND ls.update_status <> 'DELETE'    
  
  
INSERT INTO @LineStatus ( PUId,  
    PhraseId,  
    StartTime)  
SELECT PUId,  
 PhraseId,  
 StartTime  
FROM @LineStatusRaw  
ORDER BY PUId, StartTime DESC  
  
UPDATE ls1  
SET EndTime = CASE  WHEN ls1.PUId = ls2.PUId THEN ls2.StartTime  
   ELSE NULL  
   END  
FROM @LineStatus ls1  
    INNER JOIN @LineStatus ls2 ON ls2.LSId = (ls1.LSId - 1)   
WHERE ls1.LSId > 1  
  
UPDATE td  
SET LineStatus = p.Phrase_Value  
FROM dbo.#Delays td with (nolock)  
 INNER JOIN @LineStatus ls ON td.PUId = ls.PUId  
 AND td.StartTime >= ls.StartTime  
 AND (td.StartTime < ls.EndTime OR ls.EndTime IS NULL)  
 INNER JOIN dbo.Phrase p  with (nolock) ON ls.PhraseId = p.Phrase_Id  
  
  
/*  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- Timed_Event_Details row from the Local_Timed_Event_Categories table using  
-- the TEDet_Id.  
-------------------------------------------------------------------------------  
-- Following adds 5-10 seconds for 1 day  
  
SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
 @Min_TEDet_Id = MIN(TEDetId) - 1  
FROM dbo.#Delays  
  
-- Going to only do this once b/c its really expensive (??) to query from Local_Timed_Event_Categories  
INSERT INTO dbo.#TECategories ( TEDet_Id,  
    ERC_Id)  
SELECT tec.TEDet_Id,  
 tec.ERC_Id  
FROM dbo.#Delays td  
 INNER JOIN dbo.Local_Timed_Event_Categories tec ON td.TEDetId = tec.TEDet_Id  
       AND tec.TEDet_Id > @Min_TEDet_Id  
       AND tec.TEDet_Id < @Max_TEDet_Id  
  
UPDATE td  
 SET UpTime = tp.UpTime--,  
 FROM dbo.#Delays td  
 JOIN dbo.#Primaries tp ON td.TEDetId = tp.TEDetId  
  
  
 UPDATE td  
 SET ScheduleId = tec.ERC_Id  
 FROM dbo.#Delays td  
 INNER JOIN dbo.#TECategories tec ON td.TEDetId = tec.TEDet_Id  
 INNER JOIN dbo.Event_Reason_Catagories erc ON tec.ERC_Id = erc.ERC_Id  
       AND erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
 UPDATE td  
 SET CategoryId = tec.ERC_Id  
 FROM dbo.#Delays td  
 INNER JOIN dbo.#TECategories tec ON td.TEDetId = tec.TEDet_Id  
 INNER JOIN dbo.Event_Reason_Catagories erc ON tec.ERC_Id = erc.ERC_Id  
        AND erc.ERC_Desc LIKE @CategoryStr + '%'  
  
 UPDATE td  
 SET GroupCauseId = tec.ERC_Id  
 FROM dbo.#Delays td  
  INNER JOIN dbo.#TECategories tec ON td.TEDetId = tec.TEDet_Id  
  INNER JOIN dbo.Event_Reason_Catagories erc ON tec.ERC_Id = erc.ERC_Id  
        AND erc.ERC_Desc LIKE @GroupCauseStr + '%'  
 UPDATE td  
 SET SubSystemId = tec.ERC_Id  
 FROM dbo.#Delays td  
  INNER JOIN dbo.#TECategories tec ON td.TEDetId = tec.TEDet_Id  
  INNER JOIN dbo.Event_Reason_Catagories erc ON tec.ERC_Id = erc.ERC_Id  
        AND erc.ERC_Desc LIKE @SubSystemStr + '%'  
*/  
  
  
UPDATE td SET  
 ScheduleId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
  
UPDATE td SET   
 ScheduleId = @SchedBlockedStarvedId  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Event_Reasons er with (nolock)  
on Event_Reason_ID = L1ReasonId   
WHERE ScheduleId IS NULL   
AND (Event_Reason_Name LIKE '%BLOCK%' OR Event_Reason_Name LIKE '%STARVE%')  
  
  
UPDATE td SET  
 CategoryId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CategoryStr + '%'  
  
  
UPDATE td SET  
 GroupCauseId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @GroupCauseStr + '%'  
  
  
UPDATE td SET  
 SubSystemId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @SubSystemStr + '%'  
  
  
INSERT dbo.#Primaries (TEDetId,  
   PUId,  
   StartTime,  
   EndTime)  
SELECT td1.TEDetId,  
 td1.PUId,  
 MIN(td2.StartTime),  
 MAX(td2.EndTime)  
-- updated the From clause for 092704  
FROM dbo.#Delays td1 with (nolock)  
JOIN dbo.#Delays td2  with (nolock) ON td1.TEDetId = td2.PrimaryId  
JOIN @ProdUnits pu ON td1.PUID = pu.PUID --FLD Rev8.52  
WHERE td1.TEDetId = td1.PrimaryId  
AND   pu.DelayType <> @DelayTypeRateLossStr --FLD Rev8.52  
GROUP BY td1.TEDetId, td1.PUId  
ORDER BY td1.PUId, MIN(td2.StartTime) ASC  
  
-- MKW - 7.32 - Rewrote this update  
UPDATE p1  
SET Uptime  = CASE  WHEN p1.PUId = p2.PUId  
      THEN datediff(s, p2.EndTime, p1.StartTime)  
    ELSE  NULL  
    END--,  
FROM dbo.#Primaries p1 with (nolock)  
INNER JOIN dbo.#Primaries p2  with (nolock)   
ON p2.TEPrimaryId = (p1.TEPrimaryId - 1)   
WHERE p1.TEPrimaryId > 1  
  
UPDATE td  
 SET UpTime = tp.UpTime--,  
 FROM dbo.#Delays td with (nolock)  
 JOIN dbo.#Primaries tp  with (nolock) ON td.TEDetId = tp.TEDetId  
  
  
  
-------------------------------------------------------------------------------  
-- Calculate the Statistics on the dataset and set NULL Uptimes to zero.  
-------------------------------------------------------------------------------  
/*  
UPDATE td SET   
 Stops =    
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsUnscheduled =   
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 Stops2m =  
  CASE   
  WHEN td.DownTime < 120  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
   END,  
 StopsMinor =  
  CASE   
  WHEN td.DownTime < 600  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsEquipFails =   
  CASE   
  WHEN td.DownTime >= 600  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
  AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsELP =   
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.CategoryId = @CatELPId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsBlockedStarved =   
  CASE   
--  WHEN td.CategoryId = @CatBlockStarvedId  
  WHEN td.ScheduleId = @SchedBlockedStarvedId    
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 UpTime2m =  
  CASE   
  WHEN td.UpTime < 120  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsProcessFailures =   
  CASE   
  WHEN td.DownTime >= 600  
  AND  tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.ScheduleId = @SchedUnScheduledId OR td.ScheduleId IS NULL)  
  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId) OR td.CategoryId IS NULL)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END--,  
FROM dbo.#Delays td with (nolock)  
JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
WHERE  td.TEDetId = td.PrimaryId  
*/  
  
UPDATE td SET   
 Stops =     
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsUnscheduled = -- Rev2.50  
  CASE   
  WHEN (tpu.pudesc like '%reliability%' and tpu.pudesc not like '%converter reliability%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  WHEN (tpu.pudesc like '%converter reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 Stops2m =  
  CASE   
  WHEN td.DownTime < 120  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsMinor =    
  CASE   
  WHEN td.DownTime < 600  
  and (tpu.pudesc like '%reliability%' and tpu.pudesc not like '%converter reliability%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  WHEN td.DownTime < 600  
  and (tpu.pudesc like '%converter reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsEquipFails =   --FLD 01-NOV-2007 Rev11.53  
  CASE   
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%reliability%' and tpu.pudesc not like '%converter reliability%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%converter reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
  
 StopsELP =    
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.CategoryId = @CatELPId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsBlockedStarved =   
  CASE   
  --WHEN td.CategoryId = @CatBlockStarvedId     
  WHEN td.ScheduleId = @SchedBlockedStarvedId  --FLD 01-NOV-2007 Rev11.53  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 UpTime2m =    
  CASE   
  WHEN td.UpTime < 120  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsProcessFailures =   
  CASE   
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%reliability%' and tpu.pudesc not like '%converter reliability%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId)   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%converter reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId)   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END  
  
FROM dbo.#Delays td with (nolock)  
JOIN @ProdUnits tpu   
ON  td.PUId = tpu.PUId  
WHERE  td.TEDetId = td.PrimaryId  
  
  
 --SP Rev7.9  
 Update td  
 SET ReportELPDowntime = CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.CategoryId = @CatELPId)  
      THEN coalesce(td.ReportDowntime,0)  
      ELSE 0  
      END  
 FROM dbo.#Delays td with (nolock)  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
  
  
 UPDATE td  
  SET  ReportELPSchedDT =  (CASE WHEN td.ScheduleId NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
        @SchedEOProjectsId, @SchedBlockedStarvedId)   
      THEN coalesce(td.ReportDowntime,0)  
     ELSE 0  
     END)  
 FROM dbo.#Delays td with (nolock)  
 WHERE td.PUDesc LIKE '%Converter%'  
 and td.PUDesc NOT LIKE '%rate%loss%'  
  
  
--*******************************************************************************************************************--  
-- Process all the Test requirements.  
--*******************************************************************************************************************--  
-------------------------------------------------------------------------------  
-- Collect all the Test records for the reporting period.  
-------------------------------------------------------------------------------  
--SELECT 'ProdLines', * FROM @ProdLines  
INSERT dbo.#Tests ( VarId,  
  PLId,  
  Value,  
  StartTime, -- MKW - I think this should be EndTime  
  EndTime)  
SELECT t.Var_Id,  
 pl.PLId,  
 convert(float, t.Result),  
 t.Result_On,  
 @Now  
FROM dbo.Tests t with (nolock)  
 INNER JOIN @ProdLines pl ON pl.VarGoodUnitsId = t.Var_Id  
      OR pl.VarTotalUnitsId = t.Var_Id  
     OR pl.VarPMRollWidthId = t.Var_Id  
     OR pl.VarParentRollWidthId = t.Var_Id  
     OR pl.VarEffDowntimeId = t.Var_Id  
--     OR pl.VarTargetLineSpeedId = t.Var_Id  
--     OR pl.VarActualLineSpeedId = t.Var_Id   
--     OR pl.VarLineSpeedId = t.Var_Id   -- SP - Rev 7.7  
WHERE t.Result_On > @StartTime  
 AND t.Result_On <= @EndTime  
ORDER BY t.Var_Id, t.Result_On DESC  
  
-- MKW - Rev 7.3  
INSERT dbo.#Tests ( VarId,  
  PLId,  
  Value,  
  StartTime,   
  EndTime)  
SELECT t.Var_Id,  
 lpv.PLId,  
 convert(float, t.Result),  
 t.Result_On,  
 @Now  
FROM dbo.Tests t with (nolock)  
 INNER JOIN @LineProdVars lpv ON t.Var_Id = lpv.VarId  
WHERE t.Result_On > @StartTime  
 AND t.Result_On <= @EndTime  
ORDER BY t.Var_Id, t.Result_On DESC  
  
UPDATE t1  
SET EndTime = CASE WHEN t1.VarId = t2.VarId THEN t2.StartTime  
   ELSE @EndTime  
   END  
FROM dbo.#Tests t1  with (nolock)  
INNER JOIN dbo.#Tests t2  with (nolock)   
ON t2.TestId = (t1.TestId - 1)   
WHERE t1.TestId > 1  
  
  
 --------------------------------------------------------------------------------------------  
 --- Update the UWS Columns with the appropriate PRID results.  
 --------------------------------------------------------------------------------------------  
 UPDATE td  
 SET [UWS1Parent]  = COALESCE(prs.ParentPRID, NULL), --SP - Rev7.8  
  [UWS1GrandParent] = COALESCE(prs.GrandParentPRID, NULL) --SP - Rev7.8  
 FROM dbo.#Delays td with (nolock)  
         INNER JOIN @ProdUnits tpu ON tpu.PUId = td.PUId  
         INNER JOIN @ProdLines pl ON pl.PLId = tpu.PLId  
         INNER JOIN @PRsRun prs ON prs.PUId = pl.ProdPUId  
      AND prs.StartTime < td.StartTime  
      AND prs.EndTime > td.StartTime  
      AND prs.InputOrder = 1  
  
 UPDATE td  
 SET [UWS2Parent]  = COALESCE(prs.ParentPRID, NULL), --SP - Rev7.8  
  [UWS2GrandParent] = COALESCE(prs.GrandParentPRID, NULL) --SP - Rev7.8  
 FROM dbo.#Delays td with (nolock)  
         INNER JOIN @ProdUnits tpu ON tpu.PUId = td.PUId  
         INNER JOIN @ProdLines pl ON pl.PLId = tpu.PLId  
         INNER JOIN @PRsRun prs ON prs.PUId = pl.ProdPUId  
      AND prs.StartTime < td.StartTime  
      AND prs.EndTime > td.StartTime  
      AND prs.InputOrder = 2  
  
  
--------------------------------------------------------------------------------------------  
--- Update @ProdUnits UWS columns with the appropriate prod Unit desc.  
--------------------------------------------------------------------------------------------  
IF @IncludeStops = 1  
 BEGIN  
  
 UPDATE pu  
 SET UWS1 = upu1.PU_Desc,  
  UWS2 = upu2.PU_Desc  
 FROM @ProdUnits pu  
  LEFT JOIN @UWS uws1 ON pu.PLId = uws1.PLId  
     AND uws1.InputOrder = 1  
  LEFT JOIN dbo.Prod_Units upu1 with (nolock) ON uws1.UWSPUId = upu1.PU_Id   
  LEFT JOIN @UWS uws2 ON pu.PLId = uws2.PLId  
     AND uws2.InputOrder = 2  
  LEFT JOIN dbo.Prod_Units upu2 with (nolock) ON uws2.UWSPUId = upu2.PU_Id  
  
 --------------------------------------------------------------------------------------------  
 --- Insert Start_Times, UWS and PRIDs INTO temporary table.  
 --------------------------------------------------------------------------------------------  
 -- Select all Parent Rolls ran between the report period.  
  
 SELECT @StagedStatusId = ProdStatus_Id  
 FROM dbo.Production_Status with (nolock)  
 WHERE ProdStatus_Desc = 'Staged'  
  
 INSERT INTO @PRsRun ( EventId,  
    PUId,  
    StartTime,  
    EndTime,  
    ParentPRID,  
    GrandParentPRID,   
    UWS,  
    InputOrder) --???????????  
 SELECT e.Event_Id,  
  e.pu_id,  
  CASE WHEN convert(datetime, st.Result) < @StartTime THEN @StartTime   
   ELSE convert(datetime, st.Result)  
   END,  
  CASE WHEN convert(datetime, et.Result) > @EndTime THEN @EndTime   
   ELSE convert(datetime, et.Result)  
   END,  
  UPPER(RTRIM(LTRIM(pt.Result))),  
  UPPER(RTRIM(LTRIM(qt.Result))),  
  ut.Result,  
  uws.InputOrder  
 FROM dbo.Events e with (nolock)  
  INNER JOIN @ProdLines pl ON e.PU_Id = pl.ProdPUId  
      AND pl.ProdPUId > 0 --< Forces the index to be used  
      AND PackOrLine = 'LINE'  
  INNER JOIN dbo.tests st with (nolock) ON st.Result_On = e.TimeStamp  
     AND st.Var_Id = pl.VarStartTimeId  
     AND st.Result IS NOT NULL  
  INNER JOIN dbo.tests et with (nolock) ON et.Result_On = e.TimeStamp  
     AND et.Var_Id = pl.VarEndTimeId  
     AND et.Result IS NOT NULL  
  LEFT JOIN dbo.tests pt with (nolock) ON pt.Result_On = e.TimeStamp  
     AND pt.Var_Id IN (pl.VarPRIDId, pl.VarParentPRIDId)  
  LEFT JOIN dbo.tests qt with (nolock) ON qt.Result_On = e.TimeStamp  
     AND qt.Var_Id IN (pl.VarGrandParentPRIDId)  
  LEFT JOIN dbo.tests ut with (nolock) ON ut.Result_On = e.TimeStamp  
     AND ut.Var_Id = pl.VarUnwindStandId  
  LEFT JOIN @UWS uws ON uws.PLId = pl.PLId  
     AND uws.InputName = ut.Result  
 WHERE e.TimeStamp < @EndTime  
  AND e.TimeStamp > dateadd(d, -1, @StartTime)  
  AND e.Event_Status <> @StagedStatusId  
  AND convert(datetime, st.Result) < @EndTime -- @RangeEndTime  
  AND convert(datetime, et.Result) > @StartTime -- @RangeStartTime  
  
 --------------------------------------------------------------------------------------------  
 --- Update the UWS Columns with the appropriate PRID results.  
 --------------------------------------------------------------------------------------------  
 UPDATE td  
 SET [UWS1Parent]  = COALESCE(prs.ParentPRID, NULL), --SP - Rev7.8  
  [UWS1GrandParent] = COALESCE(prs.GrandParentPRID, NULL) --SP - Rev7.8  
 FROM dbo.#Delays td with (nolock)  
         INNER JOIN @ProdUnits tpu ON tpu.PUId = td.PUId  
         INNER JOIN @ProdLines pl ON pl.PLId = tpu.PLId  
         INNER JOIN @PRsRun prs ON prs.PUId = pl.ProdPUId  
      AND prs.StartTime < td.StartTime  
      AND prs.EndTime > td.StartTime  
      AND prs.InputOrder = 1  
  
 UPDATE td  
 SET [UWS2Parent]  = COALESCE(prs.ParentPRID, NULL), --SP - Rev7.8  
  [UWS2GrandParent] = COALESCE(prs.GrandParentPRID, NULL) --SP - Rev7.8  
 FROM dbo.#Delays td with (nolock)  
         INNER JOIN @ProdUnits tpu ON tpu.PUId = td.PUId  
         INNER JOIN @ProdLines pl ON pl.PLId = tpu.PLId  
         INNER JOIN @PRsRun prs ON prs.PUId = pl.ProdPUId  
      AND prs.StartTime < td.StartTime  
      AND prs.EndTime > td.StartTime  
      AND prs.InputOrder = 2  
  
  
 end  
  
-------------------------------------------------------------------------------  
-- Update the RateLoss ReportDowntime to be equal to the Effective Downtime  
-- from the #Tests table.  Note: Effective Downtime is already in minutes!  
-- Set ReportDowntime and ReportUptime = 0 so that they will not be  
-- included in Total Report Time.  
-------------------------------------------------------------------------------  
 UPDATE td   
  SET  ReportRLDowntime  = coalesce(t1.Value,0),  
--   LineTargetSpeed  = coalesce(t2.Value,0),  
--   LineActualSpeed  = coalesce(t3.Value,0),  
       ReportDowntime    = 0,  
   StopsRateLoss   = 1,  
   ReportRLELPDowntime  = CASE WHEN td.CategoryId = @CatELPId THEN t1.Value ELSE 0 END,  
   UWS1Parent  = (SELECT Result FROM dbo.Tests t with (nolock) WHERE Var_Id = pu.PRIDRLVarId AND   
       td.StartTime = t.Result_On),  
  
   -- used only for tracking in #delays... could be removed from #Delays  
   RateLossInWindow = (Convert(float,t1.Value) * 60.0) * (ReportDowntime   
     / Downtime),  
  
   -- used to determine actual rateloss for each timespan in the #EventsByShiftProduct table  
   RateLossRatio  = (convert(float,t1.Value) * 60.0) / Downtime  
  
 FROM dbo.#Delays td with (nolock)  
   JOIN @ProdUnits pu ON td.PUID = pu.PUID  
   JOIN @ProdLines pl ON pu.PLID = pl.PLID  
  LEFT  JOIN dbo.#Tests t1  with (nolock) ON (td.StartTime = t1.StartTime)   
     AND (pl.VarEffDowntimeId = t1.VarId)  
 WHERE pu.DelayType = @DelayTypeRateLossStr  
 and Downtime <> 0  
  
  
------------------------------------------------------------------------------------------  
--  Added #EventsByShiftProduct and #UptimeByShiftProduct for   
--  Splitting Downtime 062904  JSJ  
-------------------------------------------------------------------------------------------  
-- insert records into #EventsByShiftProduct for each shift period in the report window.  
-- then update the rest of the table with summary data.  
-------------------------------------------------------------------------------------------  
  
  
  -- updated for 060804  
  insert into dbo.#EventsByShiftProduct   
     (  
     StartTime,   
     EndTime,   
     prodid,   
     PLID,   
     puid,  
     pudesc,  
     EquipDesc,  -- Rev5.4  
     Team,   
     Shift,  
     PrimaryId,  
     TEDetID,  
     TEFaultID,  
     ScheduleID,  
     CategoryID,  
     SubSystemId,  
     GroupCauseId,  
     LocationId,     
     L1ReasonId,     
     L2ReasonId,     
     L3ReasonId,     
     L4ReasonId,     
     LineStatus,  
     Downtime,  
     Uptime,  
     Stops,  
     StopsUnscheduled,  
     StopsMinor,  
     StopsEquipFails,  
     StopsProcessFailures,  
     StopsBlockedStarved,  
     UpTime2m,  
     StopsRateLoss,  
     StopsELP,  -- added for 061104  
     MinorEF,  
     ModerateEF,  
     MajorEF,  
     MinorPF,  
     ModeratePF,  
     MajorPF,  
     RateLossRatio,  
     Causes,  
     Comment,  
     UWS1Parent,  
     UWS1GrandParent,  
     UWS2Parent,  
     UWS2GrandParent,  
     ReportRLELPDowntime,  
     ReportELPDowntime,  
     ReportELPSchedDT  
     )  
  select    distinct  
     case when td.StartTime < rls.shift_StartTime  
     then rls.shift_StartTime else td.StartTime end,  
     case when (td.EndTime > rls.shift_EndTime or td.EndTime is null)  
     then rls.shift_EndTime else td.EndTime end,  
     rls.prodid,  
     td.plid, -- updated 060804  
     td.puid, -- updated 060804  
     td.pudesc,  
     td.EquipDesc,  -- Rev5.4  
     rls.Team,  
     rls.Shift,  
     td.PrimaryId,  
     td.TEDetID,  
     TEFaultID,  
     ScheduleID,  
     CategoryID,  
     SubSystemId,  
     GroupCauseId,  
     LocationId,     
     L1ReasonId,     
     L2ReasonId,     
     L3ReasonId,     
     L4ReasonId,     
     LineStatus,  
     Downtime,  
     Uptime,  
     Stops,  
     coalesce(StopsUnscheduled,0),  
     StopsMinor,  
     StopsEquipFails,  
     StopsProcessFailures,  
     StopsBlockedStarved,  
     UpTime2m,  
     StopsRateLoss,  
     StopsELP, -- added for 061104  
     CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1)   
      AND (td.Downtime/60.0 >= 10.0)  
      and (td.Downtime/60.0 <= 60.0)   
      THEN 1  
      ELSE 0   
      END,  
     CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1)   
      AND (td.Downtime/60.0 > 60.0)  
      and (td.Downtime/60.0 <= 360.0)   
      THEN 1  
      ELSE 0   
      END,  
     CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1)   
      AND (td.Downtime/60.0 > 360.0)  
      THEN 1  
      ELSE 0   
      END,  
     CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1)   
      AND (td.Downtime/60.0 >= 10.0)  
      and (td.Downtime/60.0 <= 60.0)   
      THEN 1  
      ELSE 0   
      END,  
     CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1)   
      AND (td.Downtime/60.0 > 60.0)  
      and (td.Downtime/60.0 <= 360.0)   
      THEN 1  
      ELSE 0   
      END,  
     CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1)   
      AND (td.Downtime/60.0 > 360.0)  
      THEN 1  
      ELSE 0   
      END,  
     RateLossRatio,  
     0,  
     Comment,  
     UWS1Parent,  
     UWS1GrandParent,  
     UWS2Parent,  
     UWS2GrandParent,  
     ReportRLELPDowntime,  
     ReportELPDowntime,  
     ReportELPSchedDT  
       
  from  @RunsLineShift rls   
  join  dbo.#delays td  with (nolock) on rls.puid = td.puid -- changed 060804 by JSJ  
   and (((rls.shift_starttime < td.endtime or td.endtime is null)   
   and rls.shift_endtime > td.starttime) or inRptWindow = 0)  
  where inRptWindow = 1  
  
  update dbo.#EventsByShiftProduct set  
   ReportDowntime = datediff(ss,StartTime,EndTime),  
   PartialStops = case  
   when  datediff(ss,StartTime,EndTime) = 0 then coalesce(Stops,0)  
   else  convert(float,(convert(float,datediff(ss,StartTime,EndTime))/Downtime))    
   end  
  where coalesce(stopsRateloss,0) = 0  
  
  update td set  
   ReportRLDowntime = datediff(ss,StartTime,EndTime) * RateLossRatio,  
   ReportRLELPDowntime =   
    case WHEN (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
     AND (td.CategoryId = @CatELPId)  
     then (datediff(ss,StartTime,EndTime) / 60.0) * RateLossRatio  
     else 0.0 end  
  FROM dbo.#EventsByShiftProduct td with (nolock)  
  JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
  where coalesce(stopsRateloss,0) = 1  
  
  
  Update td SET   
   ReportELPDowntime =   
   CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
     AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
     AND (td.CategoryId = @CatELPId)  
    THEN td.ReportDownTime  
    ELSE 0 END  
  FROM dbo.#EventsByShiftProduct td with (nolock)  
  JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
  
  
  UPDATE td SET    
   ReportELPSchedDT =    
   CASE WHEN td.ScheduleId NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
        @SchedEOProjectsId, @SchedBlockedStarvedId)   
    THEN td.ReportDowntime  
    ELSE 0 END  
  FROM dbo.#EventsByShiftProduct td with (nolock)  
  JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
  WHERE tpu.PUDesc LIKE '%Converter%'  
  and tpu.PUDesc NOT LIKE '%rate%loss%'  
  
  
  update dbo.#EventsByShiftProduct set  
   dbspID = ebspID  
  
    
  update dbo.#EventsByShiftProduct set  
   causes = (  
     select  count(*)   
     from  dbo.#delays td with (nolock)   
     where  td.starttime < dbo.#EventsByShiftProduct.endtime  
     and td.starttime >= dbo.#EventsByShiftProduct.starttime  
     and td.puid = dbo.#EventsByShiftProduct.puid  
     and  coalesce(stops,0) > 0  
     ) +   
     (  
     select  count(*)   
     from  dbo.#delays td with (nolock)   
     where  td.starttime < dbo.#EventsByShiftProduct.endtime  
     and td.starttime >= dbo.#EventsByShiftProduct.starttime  
     and td.puid = dbo.#EventsByShiftProduct.puid  
     and  coalesce(secondaryid,0) > 0  
     )  
  
  
  update dbo.#EventsByShiftProduct set  
   Downtime = null,  
   Uptime = null,  
   Stops = null,  
   StopsMinor = null,  
   StopsEquipFails = null,  
   StopsProcessFailures = null,  
   StopsELP = null,  
   StopsRateLoss = null,  
   StopsUnscheduled = null,  
   UpTime2m = null,  
   MinorEF = null,  
   ModerateEF = null,  
   MajorEF = null,  
   MinorPF = null,  
   ModeratePF = null,  
   MajorPF = null--,  
  where  (  
   select count(*)   
   from dbo.#delays td with (nolock)  
   where td.starttime = dbo.#EventsByShiftProduct.starttime  
   ) = 0  
    
  
  -----------------------------------------------------------------  
  -- get Uptime data  
  -----------------------------------------------------------------  
  
  -- get the basic data for uptime between downtime events.  
  insert into dbo.#UptimeByShiftProduct   
   (  
   InsertID,  
   StartTime,   
   EndTime,   
   prodid,   
   PLID,   
   puid,  
   pudesc,  
   EquipDesc,  -- Rev5.4  
   Team,   
   Shift,  
   ReportUptime,  
   ScheduleID,  
   CategoryID,  
   SubsystemID,  
   LocationID,  
   teFaultID,  
   L1ReasonID,  
   L2ReasonID  
   )  
  select distinct  
   1,  
   case   
   when td1.endtime >= rls.shift_starttime   
   and (td1.endtime < rls.shift_endtime or rls.shift_endtime is null)  
   then td1.EndTime  
   else rls.shift_StartTime end,  
   case   
   when td2.starttime >= rls.shift_starttime   
   and (td2.starttime < rls.shift_endtime or rls.shift_endtime is null)  
   then td2.StartTime   
   else rls.shift_EndTime end,  
   rls.prodid,   
   rls.PLID,  
   td1.puid,  -- 102504  
   td1.pudesc,  
   td1.EquipDesc,  -- Rev5.4  
   rls.Team,  
   rls.Shift,  
   0,  
   td1.ScheduleID,  
   td1.CategoryID,  
   td1.SubsystemID,  
   td1.LocationID,  
   td1.teFaultID,  
   td1.L1ReasonID,  
   td1.L2ReasonID  
  from  @RunsLineShift rls   
  join  dbo.#EventsByShiftProduct td1  with (nolock) on rls.puid = td1.puid  
  and ((rls.shift_starttime < td1.endtime or td1.endtime is null)   
   and rls.shift_endtime > td1.starttime)  
  left join  dbo.#EventsByShiftProduct td2  with (nolock)  
  on td1.puid = td2.puid  
  and td2.dbspId =   
   (  
   select  min(dbspId)  
   from  dbo.#EventsByShiftProduct dbsp with (nolock)  
   where   td1.dbspId < dbsp.dbspId  
   and td1.puid = dbsp.puid  
   )   
  
  
  -- get the uptime from the start of a shift/product to the first downtime event.  
  insert into dbo.#UptimeByShiftProduct   
   (  
   InsertID,  
   StartTime,   
   EndTime,   
   prodid,   
   PLID,   
   puid,  
   pudesc,  
   EquipDesc,  -- Rev5.4  
   Team,   
   Shift,  
   ReportUptime,  
   ScheduleID,  
   CategoryID,  
   SubsystemID,  
   LocationID,  
   teFaultID,  
   L1ReasonID,  
   L2ReasonID  
   )  
  (select distinct  
   2,  
   rls.shift_starttime,  
   td.starttime,  
   rls.prodid,  
   rls.PLID,  
   rls.puid,  
   td.pudesc,  
   td.EquipDesc,  -- Rev5.4  
   rls.Team,  
   rls.Shift,  
   0,  
   ScheduleID,  
   CategoryID,  
   SubsystemID,  
   LocationID,  
   teFaultID,  
   L1ReasonID,  
   L2ReasonID  
  from  @RunsLineShift rls   
  join  dbo.#EventsByShiftProduct td with (nolock)  
  on  rls.puid = td.puid  
  and (rls.shift_starttime < td.starttime   
   and rls.shift_endtime > td.starttime)  
  and  td.StartTime =   
   (  
   select min(StartTime)  
   from dbo.#EventsByShiftProduct td1 with (nolock)  
   where rls.shift_starttime <= td1.StartTime   
   and rls.shift_endtime > td1.starttime  
   and rls.puid = td1.puid  
   )  
  )  
  
  -- get the uptime from the timespans where no downtime occurred   
  
  insert into dbo.#UptimeByShiftProduct   
   (  
   InsertID,  
   StartTime,   
   EndTime,   
   prodid,   
   PLID,   
   puid,  
   Team,   
   Shift,  
   ReportUptime   
   )  
  select distinct  
   3,  
   rls.shift_starttime,  
   rls.shift_endtime,  
   rls.prodid,  
   rls.PLID,  
   rls.puid,  
   rls.Team,  
   rls.Shift,  
   0  
  from  @RunsLineShift rls    
  where   puid NOT IN (  
     select distinct puid from dbo.#EventsByShiftProduct td with (nolock)   
     where  rls.puid = td.puid  
     and rls.shift_starttime < td.endtime   
     and  rls.shift_endtime > td.starttime  
     )    
  
  
  
  update dbo.#UptimeByShiftProduct set  
   pudesc =  (  
     select pudesc  
     from @produnits pu   
     where pu.puid = dbo.#UptimeByShiftProduct.puid   
     ),  
     -- Rev5.4  
   EquipDesc =  (  
     select top 1 EquipDesc  
     from dbo.#EventsByShiftProduct td with (nolock)  
     where td.puid = dbo.#UptimeByShiftProduct.puid  
     )  
  
  
  update dbo.#UptimeByShiftProduct set  
   ReportUptime = datediff(ss,StartTime,EndTime)  
  
  
  ----------------------------------------------------------  
  -- put Uptime into the #EventsByShiftProduct  
  ---------------------------------------------------------  
  
  update dbo.#UptimeByShiftProduct set  
   dbspID =  
   (  
   select dbspID  
   from dbo.#EventsByShiftProduct ebsp with (nolock)  
   where ebsp.StartTime = dbo.#UptimeByShiftProduct.EndTime  
   and ebsp.puid = dbo.#UptimeByShiftProduct.puid   
   and ebsp.prodid = dbo.#UptimeByShiftProduct.prodid  
   )  
  
  
  update ubsp set  
   ScheduleID = td.ScheduleID,  
   CategoryID = td.CategoryID,  
   SubsystemID = td.SubsystemID,  
   LocationID = td.LocationID,  
   teFaultID = td.teFaultID,  
   L1ReasonID = td.L1ReasonID,  
   L2ReasonID = td.L2ReasonID  
  from dbo.#UptimeByShiftProduct ubsp with (nolock)   
  join dbo.#delays td  with (nolock) on td.puid = ubsp.puid  
  and td.starttime =   
   (  
   select min(starttime)  
   from dbo.#delays td1 with (nolock)  
   where td1.puid = ubsp.puid  
   and td1.starttime >= ubsp.endtime  
   )  
  where dbspID is null       
  
  
  update dbo.#EventsByShiftProduct set  
   ReportUptime =  
   (  
   select sum(ReportUptime)  
   from dbo.#UptimeByShiftProduct ubsp with (nolock)  
   where ubsp.EndTime = dbo.#EventsByShiftProduct.StartTime  
   and ubsp.puid = dbo.#EventsByShiftProduct.puid  
   and coalesce(StopsRateLoss,0) = 0    
   --  JSJ Rev6.1  
   )  
  
  -- added for 060804  
  delete from dbo.#UptimeByShiftProduct where starttime = endtime   
  
  
  UPDATE dbo.#UptimeByShiftProduct SET  
   LineStatus =  (  
     SELECT p.Phrase_Value   
     FROM @LineStatus ls  
     JOIN dbo.Phrase p with (nolock) ON ls.PhraseId = p.Phrase_Id  
     WHERE ls.puid = dbo.#UptimeByShiftProduct.puid  
     AND dbo.#UptimeByShiftProduct.endtime >= ls.starttime  --FLD Rev8.67  
     AND (dbo.#UptimeByShiftProduct.endtime < ls.endtime or ls.endtime IS NULL)  --FLD Rev8.67  
     )  
  WHERE dbspID is NULL   
  
  
  insert into dbo.#EventsByShiftProduct   
   (  
   StartTime,   
   EndTime,   
   prodid,   
   PLID,   
   puid,  
   pudesc,  
   EquipDesc,  -- Rev5.4  
   Team,   
   Shift,  
   Downtime,  
   ReportDowntime,  
   ReportRLDowntime,  
   Uptime,  
   ReportUptime,  
   Comment,  
   ScheduleID,  
   CategoryID,  
   SubsystemID,  
   LocationID,  
   teFaultID,  
   L1ReasonID,  
   L2ReasonID  
   )  
  select  
   StartTime,   
   EndTime,   
   prodid,   
   PLID,   
   puid,  
   pudesc,  
   EquipDesc,  -- Rev5.4  
   Team,   
   Shift,  
   0,0,0,0,  
   ReportUptime,  
   GBDB.dbo.fnLocal_GlblTranslation('This record artificially created for the sole purpose of allocating uptime that spans shift changes, product changes, and/or the report end time.',@LanguageID),  
   ScheduleID,  
   CategoryID,  
   SubsystemID,  
   LocationID,  
   teFaultID,  
   L1ReasonID,  
   L2ReasonID  
  from dbo.#UptimeByShiftProduct with (nolock)  
  where dbspID is null  
  and (select pu_desc from dbo.prod_units  with (nolock)   
     where pu_id = dbo.#UptimeByShiftProduct.puid) not like '%rate loss%'   
  
  
  
ReturnResultSets:  
  
  
--select 'td', * from #delays  
--order by puid, starttime, tedetid  
  
  
 ----------------------------------------------------------------------------------------------------  
 -- Error Messages.  
 ----------------------------------------------------------------------------------------------------  
  
 -- if there are errors from the parameter validation, then return them and skip the rest of the results  
  
 if (select count(*) from @ErrorMessages) > 0  
  
 begin  
  
  SELECT ErrMsg  
  FROM @ErrorMessages  
  
  
 end  
  
 else  
  
 begin  
  
 -------------------------------------------------------------------------------  
 -- Error Messages.  
 -------------------------------------------------------------------------------  
 -- resultset 1  
  
 SELECT ErrMsg  
 FROM @ErrorMessages  
  
  
 -----------------------------------------------------------------------------  
 -- Return multiple resultsets for the Summary version of the report.  There are  
 -- a total of eight that have the data organized in various arrangements.  
 -----------------------------------------------------------------------------  
  
-- line summary result set 2  
--print 'main insert'  
  insert dbo.#LineSummary  
  select  distinct   
  pl.pl_desc [Production Line],  
  sum(  
   case  
   when  (coalesce(td.scheduleid,0) not in (@SchedEOProjectsID,@SchedHolidayCurtailID))  
   and (td.pudesc like '%reliability%' or td.pudesc like '%block%starv%')  
   then  coalesce(stops,0)  
   else  0 end  
  ) [System Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(  
   case  
   when  coalesce(td.scheduleid,0) not in (@SchedEOProjectsID,@SchedHolidayCurtailID)  
   then coalesce(td.reportdowntime,0)  
   else 0 end  
  ) / 60.00 [System Reporting Downtime],  
  
  
  sum(  
   case  
   when  coalesce(td.scheduleid,0) <> @SchedEOProjectsID  
   then coalesce(td.reportuptime,0)  
   else 0 end  
  ) / 60.00 [System Reporting Uptime],  
  
  
  sum(  
   case  
   when coalesce(td.scheduleid,0) <> @SchedEOProjectsID  
   then  coalesce(td.uptime2m,0)  
   else 0 end  
  ) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) not in   
        (  
        @SchedEOProjectsID,  
        @SchedHolidayCurtailID  
        )   
       THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedEOProjectsID   
            AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) not in   
         (  
         @SchedEOProjectsID,  
         @SchedHolidayCurtailID  
         )   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 GROUP BY pl.pl_desc  
 order BY pl.pl_desc  
--print 'updates'  
 update dbo.#LineSummary set  
  [System Availability] =   
   case   
   when  ([System Reporting Uptime] + [System Reporting Downtime]) = 0  
   then 0  
   else [System Reporting Uptime]/([System Reporting Uptime] + [System Reporting Downtime])  
   end,  
  [System MTBF] =   
   case  
   when [System Total Stops] = 0  
   then 0  
   else [System Reporting Uptime]/[System Total Stops]  
   end,  
  [System MTTR] =   
   case  
   when [System Total Stops] = 0  
   then 0  
   else [System Reporting Downtime]/[System Total Stops]  
   end  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#LineSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary  result set 3  
  
 insert dbo.#EquipmentSummary  
 select  distinct   
  pl.pl_desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  sum(  
   case  
   when  (coalesce(td.scheduleid,0) not in (@SchedEOProjectsID,@SchedHolidayCurtailID))  
   then  coalesce(stops,0)  
   else  0 end  
  ) [Machine Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(  
   case  
   when  coalesce(td.scheduleid,0) not in (@SchedBlockedStarvedID,@SchedEOProjectsID,@SchedHolidayCurtailID)     
   and td.pudesc not like '%block%starv%'  
   then coalesce(td.reportdowntime,0)  
   else 0 end  
  ) / 60.00 [Machine Reporting Downtime],  
  
  
  sum(  
   case  
   when  coalesce(td.scheduleid,0) <> @SchedEOProjectsID  
   then coalesce(td.reportuptime,0)  
   else 0 end  
  ) / 60.00 [System Reporting Uptime],  
  
  
  sum(  
   case  
   when coalesce(td.scheduleid,0) <> @SchedEOProjectsID  
   then  coalesce(td.uptime2m,0)  
   else 0 end  
  ) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) not in   
        (  
        @SchedBlockedStarvedID,  
        @SchedEOProjectsID,  
        @SchedHolidayCurtailID  
        )   
       THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedEOProjectsID   
            AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) not in   
         (  
         @SchedBlockedStarvedID,  
         @SchedEOProjectsID,  
         @SchedHolidayCurtailID  
         )   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 --where pu.pu_desc not like '%block%starv%'  
 GROUP BY pl.pl_desc, EquipDesc  -- Rev5.4  
 order BY pl.pl_desc, EquipDesc  -- Rev5.4  
  
  
 update dbo.#EquipmentSummary set  
  [Machine Availability] =   
   case   
   when  ([System Reporting Uptime] + [Machine Reporting Downtime]) = 0  
   then 0  
   else [System Reporting Uptime]/([System Reporting Uptime] + [Machine Reporting Downtime])  
   end,  
  [Machine MTBF] =   
   case  
   when [Machine Total Stops] = 0  
   then 0  
   else [System Reporting Uptime]/[Machine Total Stops]  
   end,  
  [Machine MTTR] =   
   case  
   when [Machine Total Stops] = 0  
   then 0  
   else [Machine Reporting Downtime]/[Machine Total Stops]  
   end  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#EquipmentSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#EquipmentSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#EquipmentSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary by Team resultset 4  
  
 insert dbo.#TeamSummary  
 SELECT  pl.PL_Desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  td.team [Team],   
  sum(  
   case  
   when  (coalesce(td.scheduleid,0) not in (@SchedEOProjectsID,@SchedHolidayCurtailID))  
   then  coalesce(stops,0)  
   else  0 end  
  ) [Machine Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(  
   case  
   when  coalesce(td.scheduleid,0) not in (@SchedBlockedStarvedID,@SchedEOProjectsID,@SchedHolidayCurtailID)     
   and td.pudesc not like '%block%starv%'  
   then coalesce(td.reportdowntime,0)  
   else 0 end  
  ) / 60.00 [Machine Reporting Downtime],  
  
  
  sum(  
   case  
   when  coalesce(td.scheduleid,0) <> @SchedEOProjectsID  
   then coalesce(td.reportuptime,0)  
   else 0 end  
  ) / 60.00 [System Reporting Uptime],  
  
  
  sum(  
   case  
   when coalesce(td.scheduleid,0) <> @SchedEOProjectsID  
   then  coalesce(td.uptime2m,0)  
   else 0 end  
  ) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) not in   
        (  
        @SchedBlockedStarvedID,  
        @SchedEOProjectsID,  
        @SchedHolidayCurtailID  
        )   
       THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedEOProjectsID   
            AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) not in   
         (  
         @SchedBlockedStarvedID,  
         @SchedEOProjectsID,  
         @SchedHolidayCurtailID  
         )   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 GROUP BY pl.PL_Desc, EquipDesc, td.team  -- Rev5.4  
 order BY pl.PL_Desc, EquipDesc, td.team  -- Rev5.4  
  
  
 update dbo.#TeamSummary set  
  [Machine Availability] =   
   case   
   when  ([System Reporting Uptime] + [Machine Reporting Downtime]) = 0  
   then 0  
   else [System Reporting Uptime]/([System Reporting Uptime] + [Machine Reporting Downtime])  
   end,  
  [Machine MTBF] =   
   case  
   when [Machine Total Stops] = 0  
   then 0  
   else [System Reporting Uptime]/[Machine Total Stops]  
   end,  
  [Machine MTTR] =   
   case  
   when [Machine Total Stops] = 0  
   then 0  
   else [Machine Reporting Downtime]/[Machine Total Stops]  
   end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#TeamSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#TeamSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#TeamSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary by Product resultset 5  
  
 insert dbo.#ProductSummary  
 SELECT  pl.PL_Desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  isnull((select prod_desc from dbo.products p with (nolock) where p.prod_id = prodid), '') [Product],  
  sum(  
   case  
   when  (coalesce(td.scheduleid,0) not in (@SchedEOProjectsID,@SchedHolidayCurtailID))  
   then  coalesce(stops,0)  
   else  0 end  
  ) [Machine Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(  
   case  
   when  coalesce(td.scheduleid,0) not in (@SchedBlockedStarvedID,@SchedEOProjectsID,@SchedHolidayCurtailID)     
   and td.pudesc not like '%block%starv%'  
   then coalesce(td.reportdowntime,0)  
   else 0 end  
  ) / 60.00 [Machine Reporting Downtime],  
  
  
  sum(  
   case  
   when  coalesce(td.scheduleid,0) <> @SchedEOProjectsID  
   then coalesce(td.reportuptime,0)  
   else 0 end  
  ) / 60.00 [System Reporting Uptime],  
  
  
  sum(  
   case  
   when coalesce(td.scheduleid,0) <> @SchedEOProjectsID  
   then  coalesce(td.uptime2m,0)  
   else 0 end  
  ) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) not in   
        (  
        @SchedBlockedStarvedID,  
        @SchedEOProjectsID,  
        @SchedHolidayCurtailID  
        )   
       THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedEOProjectsID   
            AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) not in   
         (  
         @SchedBlockedStarvedID,  
         @SchedEOProjectsID,  
         @SchedHolidayCurtailID  
         )   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 --where pu.pu_desc not like '%block%starv%'  
 GROUP BY pl.PL_Desc, EquipDesc, prodid  -- Rev5.4  
 order BY pl.PL_Desc, EquipDesc, prodid  -- Rev5.4  
  
  
 update dbo.#ProductSummary set  
  [Machine Availability] =   
   case   
   when  ([System Reporting Uptime] + [Machine Reporting Downtime]) = 0  
   then 0  
   else [System Reporting Uptime]/([System Reporting Uptime] + [Machine Reporting Downtime])  
   end,  
  [Machine MTBF] =   
   case  
   when [Machine Total Stops] = 0  
   then 0  
   else [System Reporting Uptime]/[Machine Total Stops]  
   end,  
  [Machine MTTR] =   
   case  
   when [Machine Total Stops] = 0  
   then 0  
   else [Machine Reporting Downtime]/[Machine Total Stops]  
   end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#ProductSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#ProductSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#ProductSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary by Master Unit  result 6  
  
 insert dbo.#UnitSummary  
 select  distinct   
  pl.pl_desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  pu.pu_desc [Master Unit],  -- Rev5.4  
  sum(coalesce(stops,0)) [Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(coalesce(td.reportdowntime,0)) / 60.00 [Reporting Downtime],  
  sum(coalesce(td.ReportUptime,0)) / 60.0 [Reporting Uptime],  
  sum(coalesce(td.uptime2m,0)) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
                THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
             AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 GROUP BY pl.pl_desc, EquipDesc, pu.pu_desc     
 order BY pl.pl_desc, EquipDesc, pu.pu_desc   
  
  
 update dbo.#UnitSummary set  
  [Availability] =   
   case   
   when  ([Reporting Uptime] + [Reporting Downtime]) = 0  
   then 0  
   else [Reporting Uptime]/([Reporting Uptime] + [Reporting Downtime])  
   end,  
  [MTBF] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Uptime]/[Total Stops]  
   end,  
  [MTTR] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Downtime]/[Total Stops]  
   end  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#UnitSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#UnitSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#UnitSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary by EventLocation resultset 7  
  
 insert dbo.#LocationSummary  
 SELECT  pl.PL_Desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  pu.pu_desc [Master Unit],  -- Rev5.4  
  (   
  select pu_desc  
  from dbo.prod_units with (nolock)   
  where pu_id = locationid  
  )[Location],  
  sum(coalesce(stops,0)) [Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(coalesce(td.reportdowntime,0)) / 60.00 [Reporting Downtime],  
  sum(coalesce(td.ReportUptime,0)) / 60.0 [Reporting Uptime],  
  sum(coalesce(td.uptime2m,0)) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
                THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
             AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 GROUP BY pl.PL_Desc, EquipDesc, pu.pu_desc, locationid  -- Rev5.4  
 order BY pl.PL_Desc, EquipDesc, pu.pu_desc, locationid  -- Rev5.4  
  
  
 update dbo.#LocationSummary set  
  [Availability] =   
   case   
   when  ([Reporting Uptime] + [Reporting Downtime]) = 0  
   then 0  
   else [Reporting Uptime]/([Reporting Uptime] + [Reporting Downtime])  
   end,  
  [MTBF] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Uptime]/[Total Stops]  
   end,  
  [MTTR] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Downtime]/[Total Stops]  
   end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#LocationSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#LocationSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LocationSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary by Category resultset 8  
  
 insert dbo.#CategorySummary  
 SELECT  pl.PL_Desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  pu.pu_desc [Master Unit],  -- Rev5.4  
  REPLACE(erc.ERC_Desc,'Category:','') [Category],  
  sum(coalesce(stops,0)) [Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(coalesce(td.reportdowntime,0)) / 60.00 [Reporting Downtime],  
  sum(coalesce(td.ReportUptime,0)) / 60.0 [Reporting Uptime],  
  sum(coalesce(td.uptime2m,0)) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
                THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
             AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 left JOIN dbo.Event_Reason_Catagories erc with (nolock) ON td.CategoryId = erc.ERC_Id  
 GROUP BY pl.PL_Desc, EquipDesc, pu.pu_desc, erc.ERC_Desc  -- Rev5.4  
 order BY pl.PL_Desc, EquipDesc, pu.pu_desc, erc.ERC_Desc  -- Rev5.4  
  
  
 update dbo.#CategorySummary set  
  [Availability] =   
   case   
   when  ([Reporting Uptime] + [Reporting Downtime]) = 0  
   then 0  
   else [Reporting Uptime]/([Reporting Uptime] + [Reporting Downtime])  
   end,  
  [MTBF] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Uptime]/[Total Stops]  
   end,  
  [MTTR] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Downtime]/[Total Stops]  
   end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#CategorySummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#CategorySummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#CategorySummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary by Subsystem resultset 9  
  
 insert dbo.#SubSystemSummary  
 SELECT  pl.PL_Desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  pu.pu_desc [Master Unit],  -- Rev5.4  
  REPLACE(erc.ERC_Desc,'Subsystem:','') [SubSystem],  
  sum(coalesce(stops,0)) [Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(coalesce(td.reportdowntime,0)) / 60.00 [Reporting Downtime],  
  sum(coalesce(td.ReportUptime,0)) / 60.0 [Reporting Uptime],  
  sum(coalesce(td.uptime2m,0)) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
                THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
             AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 left JOIN dbo.Event_Reason_Catagories erc with (nolock) ON td.SubsystemId = erc.ERC_Id  
 GROUP BY pl.PL_Desc, EquipDesc, pu.pu_desc, erc.ERC_Desc  -- Rev5.4  
 order BY pl.PL_Desc, EquipDesc, pu.pu_desc, erc.ERC_Desc  -- Rev5.4  
  
 update dbo.#SubsystemSummary set  
  [Availability] =   
   case   
   when  ([Reporting Uptime] + [Reporting Downtime]) = 0  
   then 0  
   else [Reporting Uptime]/([Reporting Uptime] + [Reporting Downtime])  
   end,  
  [MTBF] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Uptime]/[Total Stops]  
   end,  
  [MTTR] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Downtime]/[Total Stops]  
   end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#SubsystemSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#SubsystemSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#SubsystemSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary by Failure Mode resultset 10  
  
 insert dbo.#FailureModeSummary  
 SELECT  pl.PL_Desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  pu.pu_desc [Master Unit],  -- Rev5.4  
  event_reason_name [Failure Mode],  
  sum(coalesce(stops,0)) [Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(coalesce(td.reportdowntime,0)) / 60.00 [Reporting Downtime],  
  sum(coalesce(td.ReportUptime,0)) / 60.0 [Reporting Uptime],  
  sum(coalesce(td.uptime2m,0)) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
                THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
             AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 JOIN dbo.Event_Reasons er with (nolock) ON td.L1ReasonID = er.Event_Reason_ID  
 GROUP BY pl.PL_Desc, EquipDesc, pu.pu_desc, event_reason_name  -- Rev5.4  
 order BY pl.PL_Desc, EquipDesc, pu.pu_desc, event_reason_name  -- Rev5.4  
  
 update dbo.#FailureModeSummary set  
  [Availability] =   
   case   
   when  ([Reporting Uptime] + [Reporting Downtime]) = 0  
   then 0  
   else [Reporting Uptime]/([Reporting Uptime] + [Reporting Downtime])  
   end,  
  [MTBF] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Uptime]/[Total Stops]  
   end,  
  [MTTR] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Downtime]/[Total Stops]  
   end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#FailureModeSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#FailureModeSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#FailureModeSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary by Failure Mode Cause resultset 11  
  
 insert dbo.#FailureModeCauseSummary  
 SELECT  pl.PL_Desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  pu.pu_desc [Master Unit],  -- Rev5.4  
  event_reason_name [Failure Mode Cause],  
  sum(coalesce(stops,0)) [Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(coalesce(td.reportdowntime,0)) / 60.00 [Reporting Downtime],  
  sum(coalesce(td.ReportUptime,0)) / 60.0 [Reporting Uptime],  
  sum(coalesce(td.uptime2m,0)) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
                THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
             AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 JOIN dbo.Event_Reasons er with (nolock) ON td.L2ReasonID = er.Event_Reason_ID  
 GROUP BY pl.PL_Desc, EquipDesc, pu.pu_desc, event_reason_name  -- Rev5.4  
 order BY pl.PL_Desc, EquipDesc, pu.pu_desc, event_reason_name  -- Rev5.4  
  
 update dbo.#FailureModeCauseSummary set  
  [Availability] =   
   case   
   when  ([Reporting Uptime] + [Reporting Downtime]) = 0  
   then 0  
   else [Reporting Uptime]/([Reporting Uptime] + [Reporting Downtime])  
   end,  
  [MTBF] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Uptime]/[Total Stops]  
   end,  
  [MTTR] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Downtime]/[Total Stops]  
   end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#FailureModeCauseSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#FailureModeCauseSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#FailureModeCauseSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
-- machine summary by Fault Desc resultset 12  
  
 insert dbo.#FaultSummary  
 SELECT  pl.PL_Desc [Production Line],  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  pu.pu_desc [Master Unit],  -- Rev5.4  
  teFault_Name [Fault Desc],  
  sum(coalesce(stops,0)) [Total Stops],  
  sum(coalesce(causes,0)) [Total Causes],  
  sum(coalesce(td.reportdowntime,0)) / 60.00 [Reporting Downtime],  
  sum(coalesce(td.ReportUptime,0)) / 60.0 [Reporting Uptime],  
  sum(coalesce(td.uptime2m,0)) [Total Uptime < 2 Min],  
  CASE  WHEN (SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
                THEN (Coalesce(td.Stops,0))  
       ELSE 0 END)))) > 0   
   THEN ROUND(1 - ((SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
             AND td.Uptime2m = 1   
         THEN (Coalesce(td.Stops,0))  
         ELSE 0 END))))  
    /(SUM(convert(float, (CASE  WHEN coalesce(td.scheduleid,0) <> @SchedHolidayCurtailId   
        THEN (Coalesce(td.Stops,0))  
        ELSE 0 END))))), 2)   
   ELSE 0.0 END [R(2)],     
  0,0,0  
 FROM dbo.#EventsByShiftProduct td with (nolock)  
 JOIN @ProdUnits ppu ON td.PUID = ppu.PUId  
 JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
 JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
 JOIN dbo.timed_event_fault tef with (nolock) ON td.tefaultid = tef.tefault_id  
 GROUP BY pl.PL_Desc, EquipDesc, pu.pu_desc, tefault_name  -- Rev5.4  
 order BY pl.PL_Desc, EquipDesc, pu.pu_desc, tefault_name  -- Rev5.4  
  
 update dbo.#FaultSummary set  
  [Availability] =   
   case   
   when  ([Reporting Uptime] + [Reporting Downtime]) = 0  
   then 0  
   else [Reporting Uptime]/([Reporting Uptime] + [Reporting Downtime])  
   end,  
  [MTBF] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Uptime]/[Total Stops]  
   end,  
  [MTTR] =   
   case  
   when [Total Stops] = 0  
   then 0  
   else [Reporting Downtime]/[Total Stops]  
   end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#FaultSummary with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#FaultSummary with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#FaultSummary', @LanguageId)  
 end  
  
 EXEC(@SQL)  
  
  
  
-- result set 13  
 -------------------------------------------------------------------------------  
 -- All raw data.  Note that Excel can only handle a maximum of 65536 rows in a  
 -- spreadsheet.  Therefore, we send an error if there are more than that number.  
 -------------------------------------------------------------------------------  
   
 INSERT INTO dbo.#Stops  
 SELECT pl.PL_Desc [Production Line],  
  td.PUDesc [Master Unit],  -- Rev5.4  
  td.EquipDesc [Equipment Desc],  -- Rev5.4  
  convert(varchar(25), td.StartTime, 101) [Start Date],  
  convert(varchar(25), td.StartTime, 108) [Start Time],  
  convert(varchar(25), td.EndTime, 101) [End Date],  
  convert(varchar(25), td.EndTime, 108) [End Time],  
  Coalesce(td.Stops, 0) [Total Stops],  
  Coalesce(td.StopsMinor, 0) [Minor Stops],  
  Coalesce(td.StopsEquipFails, 0) [Equipment Failures],   
  Coalesce(td.StopsProcessFailures, 0) [Process Failures],  
  coalesce(causes,0) [Total Causes],  
  convert(float, coalesce(td.Downtime,0)) / 60.0 [Event Downtime],  
  coalesce(td.ReportDowntime,0)/60.0 [Reporting Downtime],  
  coalesce(td.Uptime,0)/60.0 [Uptime],  
  coalesce(td.ReportUpTime,0)/60.0 [Reporting UpTime],  
  Coalesce(td.UpTime2m, 0) [Total Uptime < 2 Min],   
  coalesce(td.stopsrateloss,0) [Rate Loss Events],  
  coalesce(td.ReportRLDowntime,0)/60.0 [Rate Loss Effective Downtime],  
  Coalesce(td.StopsBlockedStarved, 0) [Total Blocked Starved],  
  CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1) AND (coalesce(td.ReportDowntime,0)/60.0 >= 10.0   
    AND coalesce(td.ReportDowntime,0)/60.0 <= 30.0 )  
   THEN 1  
   ELSE 0   
   END [Minor Equipment Failures],   
  CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1) AND (coalesce(td.ReportDowntime,0)/60.0 > 30.0   
    AND coalesce(td.ReportDowntime,0)/60.0 <= 120.0)   
   THEN 1  
   ELSE 0   
   END [Moderate Equipment Failures],   
  CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1) AND (coalesce(td.ReportDowntime,0)/60.0 > 120.0)  
   THEN 1  
   ELSE 0   
   END [Major Equipment Failures],   
  CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1) AND (coalesce(td.ReportDowntime,0)/60.0 >= 10.0   
    AND coalesce(td.ReportDowntime,0)/60.0 <= 30.0 )  
   THEN 1  
   ELSE 0   
   END [Minor Process Failures],   
  CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1) AND (coalesce(td.ReportDowntime,0)/60.0 > 30.0   
    AND coalesce(td.ReportDowntime,0)/60.0 <= 120.0)   
   THEN 1  
   ELSE 0   
   END [Moderate Process Failures],   
  CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1) AND (coalesce(td.ReportDowntime,0)/60.0 > 120.0)  
   THEN 1  
   ELSE 0   
   END [Major Process Failures],  
  p.Prod_Code [Product],  
  p.Prod_Desc [Product Desc],  
  pu.DelayType [Event Location Type],  
  CASE  WHEN td.TEDetId = td.PrimaryId THEN 'Primary'   
   when td.PrimaryID is null then 'Reporting'  
   ELSE 'Secondary' END [Event Type],  
  td.team [Team],  
  td.Shift [Shift],  
  substring(erc1.ERC_Desc, CharIndex(Char(58), erc1.ERC_Desc) + 1, 50) [Schedule],  
  substring(erc2.ERC_Desc, CharIndex(Char(58), erc2.ERC_Desc) + 1, 50) [Category],  
  substring(erc3.ERC_Desc, CharIndex(Char(58), erc3.ERC_Desc) + 1, 50) [SubSystem],  
  substring(erc4.ERC_Desc, CharIndex(Char(58), erc4.ERC_Desc) + 1, 50) [GroupCause],  
  loc.PU_Desc [Location],  
  er1.Event_Reason_Name,  
  er2.Event_Reason_Name,  
  er3.Event_Reason_Name,    -- RL3Title  
  er4.Event_Reason_Name,    -- RL4Title  
  tef.TEFault_Name [Fault Desc],  
  td.LineStatus [Line Status],  
  pueg.EquipGroup [Equipment Group],  
  UPPER(td.UWS1GrandParent) [UWS1GrandParent],   --SP - Rev7.8  
  UPPER(td.UWS1Parent) [UWS1Parent],    --SP - Rev7.8  
  UPPER(td.UWS2GrandParent) [UWS2GrandParent],   --SP - Rev7.8  
  UPPER(td.UWS2Parent) [UWS2Parent],    --SP - Rev7.8  
  Comment [Comment]  
    
 FROM dbo.#EventsByShiftProduct td with (nolock)  
  JOIN  @ProdUnits pu ON td.PUId = pu.PUId  
  JOIN  dbo.Prod_Lines pl with (nolock) ON pu.PLId = pl.PL_Id  
  JOIN  dbo.Products p with (nolock) ON td.ProdId = p.Prod_Id  
  left  JOIN @ProdUnitsEG pueg ON td.LocationId = pueg.Source_PUId  
  LEFT JOIN dbo.Event_Reason_Catagories erc1 with (nolock) ON td.ScheduleId = erc1.ERC_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc2 with (nolock) ON td.CategoryId = erc2.ERC_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc3 with (nolock) ON td.SubSystemId = erc3.ERC_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc4 with (nolock) ON td.GroupCauseId = erc4.ERC_Id  
  LEFT JOIN dbo.Prod_Units loc with (nolock) ON td.LocationId = loc.PU_Id  
  LEFT JOIN dbo.Event_Reasons er1 with (nolock) ON td.L1ReasonId = er1.Event_Reason_Id  
  LEFT JOIN dbo.Event_Reasons er2 with (nolock) ON td.L2ReasonId = er2.Event_Reason_Id  
  LEFT JOIN dbo.Event_Reasons er3 with (nolock) ON td.L3ReasonId = er3.Event_Reason_Id  
  LEFT JOIN dbo.Event_Reasons er4 with (nolock) ON td.L4ReasonId = er4.Event_Reason_Id  
  LEFT  JOIN  dbo.Timed_Event_Fault tef with (nolock) on (td.TEFaultID = TEF.TEFault_ID)  
 ORDER  BY pl.PL_Desc, td.Starttime  
  
  
 update dbo.#Stops set  
  [Comment] = replace(coalesce([Comment],''), char(13)+char(10), ' ')  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#Stops with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#Stops with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#Stops', @LanguageId)  
 end  
  
 SELECT @SQL = replace(@SQL, char(39) + 'RL1Title' +  char(39), char(39) + @RL1Title + char(39))  
 SELECT @SQL = replace(@SQL, char(39) + 'RL2Title' +  char(39), char(39) + @RL2Title + char(39))  
 SELECT @SQL = replace(@SQL, char(39) + 'RL3Title' +  char(39), char(39) + @RL3Title + char(39))  
 SELECT @SQL = replace(@SQL, char(39) + 'RL4Title' +  char(39), char(39) + @RL4Title + char(39))  
  
  
 EXEC(@SQL)  
  
 end  
  
  
Finished:  
  
DropTables:  
  
  
--/*  
  
 DROP TABLE dbo.#Primaries  
 DROP TABLE dbo.#Delays  
 drop table dbo.#runs  
 drop table dbo.#EventsByShiftProduct  
 drop table dbo.#UptimeByShiftProduct  
 drop table dbo.#LineSummary  
 drop table dbo.#EquipmentSummary  
 drop table dbo.#UnitSummary  
 drop table dbo.#TeamSummary  
 drop table dbo.#ProductSummary  
 drop table dbo.#LocationSummary  
 drop table dbo.#CategorySummary  
 drop table dbo.#SubsystemSummary  
 drop table dbo.#FailureModeSummary  
 drop table dbo.#FailureModeCauseSummary  
 drop table dbo.#FaultSummary  
-- drop table dbo.#TECategories  
 drop  table dbo.#tests  
 drop table dbo.#stops  
  
--*/  
   
  
RETURN  
  
