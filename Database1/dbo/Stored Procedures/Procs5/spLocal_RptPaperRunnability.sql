  
/*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
--  
-- Version 2.01  2009-09-29  Jeff Jaeger  
--  
  
2008-02-18 Jeff Jaeger Rev1.1  
 -  Corrected summary restrictions that include PaperMachine <> 'NoAssignedPRID'  
  
2008-03-05 Jeff Jaeger Rev1.2  
 -  Updated the code so that the sp can handle more than one line at a time:  
 - Changed #DisplayVariables to #DisplayVarsByUnit  
 - Added #DisplayVars and the code to populate it.  
 - Updated the insert to #DisplayResults and #PaperRuns.  this update also addresses some test results that   
  where being avg incorrectly.  
 - Added code to round the StartTime to the nearest second in the #PRsRun insert.  Endtime was already being   
  rounded, but there was an issue of a difference in decimals on the seconds causing NoAssighedPRID records   
  to be created with 0.0 running time.  
  
2008-03-11 Jeff Jaeger Rev1.3  
 - Removed the code change that rounds the StartTime in PRsRun, as well as the rounding on EndTime.  This   
  was done so that when overlap is determined, it can be done more accurately.  
 - Updated the overlap update to EndTime in PRsRun to check the id_num and not the event_id.  event_id was not an   
  adequate check because the same event_id might exist in the record set with different status values.  when   
  the entry_on (called starttime in PRsRun) of the two entries vary by a fraction of a second, the rounding was   
  (removed above) was causing duplicate start times to occur.  
 - Updated the delete of PRsRun records to round the starttime and endtime before checking for a match.  
 - Updated the insertion of NoAssignedPRID records into PRsRun to exclude records where the start and end times   
  match instead of deleting them separately.  Then updated this change so that the NoAssignedPRID entry needs to be   
  more than a minute long.  
 - Added [Unscheduled Stops Exc. Blocked Starved] and [Blocked / Starved Stops] to the result set.  
  
2008-MAR-16 Langdon Davis  
 -  Got rid of tons of commented out and unused/unnecessary code [e.g., all the fresh/storage metrics].  
 - Corrected calculation of ELP%:  Jeff was adding RLDowntime in the numerator instead of RLELPDowntime.  RLDowntime  
  was never populated [it isn't needed in this report] so 0 was being added, understating ELP% when there was ELP   
  rate loss downtime.  
 - Added COALESCE on 'Converter Roll Wraps' and 'Winder Breakouts' to force 0 values when NULL.  
 - Corrcted spelling of 'UnScheduled Stops exc. Blocked / Starved' field.  
 - Corrected 'StopsBlockedStarved' calculation in #Delays.  It was doing a COALESCE on ScheduleID and thereby   
  counting NULL ScheduleID's as blocked/starved events.  
 - Got rid of code related to Pack PUID's.  This report is intended to run on the converting line only.  The Pack  
  PUID stuff was bringing in lots of extra, downstream events.  
 - Got rid of Delay Type List parameter as it is not needed:  Delay types on the converter reliability and rate loss  
  are standard.  
 - Got rid of redundant restriction to the converter reliability unit in the roll wraps and breakouts calculaton.  
 - Modified insert to @ProdUnits to restrict it to the converter reliability and rate loss units for the lines  
  in #ProdLines.  Before, it was pulling in all master production units with a downtime event configured.  This   
  cut the runtime by more than half.  
 - Got rid of initial restricted calculation of Runtime in PRsRun.  It was just getting overwritten with the  
  correct, unrestricted calculation later.  
 - Changed line status to be a later update to PRsRun run and based on the prs.StartTime rather than the time  
  of the parent roll event in converting [time it was stage].  
  
2008-03-31 Jeff Jaeger Rev1.5  
 - Added the variable @NoRunningStatusTime and related code to allow #PRsRun to populate, and then identify   
  rolls that never really ran so that they can be deleted from the table.  
  
2008-04-04 Jeff Jaeger and Langdon Davis Rev1.6  
 - Removed the left join to tests in the insert for #PRsRun.  This is not used.  
 -  Addressed issues seen when running in Green Bay across multiple facial lines—their UWS names are not   
  unique—they are just numbers or ‘UWS’ plus a number.  Had to add portion of PL_Desc at the front.  
 - Restricted population of @ProdUnits to just Cvtg and Intr Rate Loss units.  
  
2008-04-18 Jeff Jaeger and Langdon Davis Rev1.7  
 -  Updated the assignment of StartTime and StartStatus in the insert to #PRsRun.      
 - Expanded the delete immediately following the insert to #PRsRun to include records where the   
  StartStatus <> 'RUNNING'.  
 - These changes are made to handle cases where the is only one Running status and more than one   
  completion status, or cases where there is no Running status at all.  
 -  Added in the VN and associated code to start populating the Feedroll to Bedroll Draw results.  
  
2008-06-11 Jeff Jaeger  Rev1.8  
 - Added “L2ReasonDesc” to #Delays, along with the code to populate it.  
 - Added “Top ELP Loss Reason”, “2nd ELP Loss Reason”, and “3rd ELP Loss Reason” to #PaperRuns,   
  along with changes in code to populate them.  
 - Added “ELPReasonDesc1”, “ELPReasonDesc2”, and “ELPReasonDesc1” to #PRsRun, along with the   
  code to populate them.  These fields identify the 3 level 2 reasons with the most downtime   
  that associated with the parent roll event.  These downtimes are ELP events that begin during   
  the parent roll event.  
  
2008-JUN-17 Langdon Davis Rev1.9  
 -  AgeOfPR was already in days yet was getting further divided by 24 hours when pulled into  
  the results set for the 'Age Of PR (Days)' field.  Removed the division by 24.  
  
  
2008-07-22 Jeff Jaeger  Rev1.91  
 - Removed #EventHist  
 - Updated the structure of #Events to add start_time and end_time as well as remove Entry_On  
 - Added @RunningStatusID code.  
 - Updated the insert to #Events to use Event_Status_Transitions.  
 - Updated the insert to #PRsRun due to changes in how #Events is populated.  
 - Removed the use of @NoRunningStatusTime and related code.  
 - Commented out the insert to PRsRun that is used to fill gaps between parent rolls with NoAssignedPRID.  
  
2008-08-20 Jeff Jaeger  Rev1.92  
 - updated the index to #Events so it is a clustered index instead of a primary.  
 - added the temp table #EventStatusTransitions and made it the data source for the insert to #PRsRun.  
  
2008-09-23 Jeff Jaeger Rev1.93  
- added an additional update to PEIID for #PRsRun.  This is used for facial line FFF1, which has a different   
 configuration than the other lines.  
  
2008-10-08 Jeff Jaeger Rev1.94  
- updated the assignment of GrandParentPRID to use VarInputRollID and VarInputPRIDID.  
  
2008-10-10 Jeff Jaeger Rev1.95  
- Added an update on #Delays to automatically fill in the Schedule ID as Blocked/Starved if it is null [means  
 the reason level 2 was not filled out or there is no event reason category association to a 'Schedule'    
 event reason category] AND if reason level 1 contains the word 'BLOCK' or 'STARVE'.  
  
2008-10-22 Jeff Jaeger Rev1.96  
- modified the Facial FFF1 special special update to PEIID in #PRsRun so that it only runs if the site   
 executing the code is GB... this will need to be added to all of the reports.  
  
2008-10-29 Jeff Jaeger Rev1.97  
- made the following changes to include Converter Blocked/Starved units while determining Blocked/Starved stops.  
- Added CvtrBlockedStarvedPUId to #ProdLines along with the code to populate it.  
- Changed the update to StopsBlockedStarved in #delays to reflect what is used in   
 DDS Stops.  Effectively, this just removes the restriction to Converter Reliability.  
- Updated the join to #delays while populating @PRDTMetrics.  
  
2008-11-22 Jeff Jaeger Rev1.98  
(comment by Langdon Davis)  
- Added  + ' order by [UWS],[Proll Conv. StartTime]'  to the @SQL string as returned from   
 dbo.fnLocal_RptTableTranslation.  This was necessary because even though the INSERT to #PaperRuns is ordered,   
 it is not guaranteed that the SELECT from it resulting from the result of the translation will be.  Because   
 of this, errors were being encountered because the result set was not ordered by UWS and when we were creating   
 UWS sheets in the workbook, we would attempt to create sheets with the same name.  
(comment by Jeff Jaeger)  
- converted the temp table #ProdLines to a table variable.  this was done for efficiency reasons.  
  
2009-02-16 Jeff Jaeger Rev1.99  
- modified the method for pulling ScheduleID, CategoryID, GroupCauseID, and SubsystemID in #delays.  
  
--2009-03-12 Jeff Jaeger Rev2.00  
--  - added z_obs restriction to the population of @produnits  
  
--2009-09-29 Jeff Jaeger Rev2.01  
--  - added z_obs restriction to the update of pu_id values in @ProdLines.  
  
  
-------------------------------------------------------------------------------------------------------------------------*/  
  
CREATE PROCEDURE [dbo].[spLocal_RptPaperRunnability]  
--DECLARE  
 @StartTime      DATETIME,    -- Beginning period for the data.  
 @EndTime       DATETIME,    -- Ending period for the data.  
 @RptName       VARCHAR(100)   -- Report_Definitions.RP_Name  
  
AS  
  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
-- Testing...  
  
-- SELECT  
-- @StartTime = '2008-10-27 06:30:00',   
-- @EndTime = '2008-10-28 06:30:00',   
-- @RptName = 'Site Puffs ELP Report 0500 0500 Sunday'  
-- @RptName = 'Site Towel ELP Report 0500-0500 Yesterday'     
--  
-- SELECT  
-- @StartTime = '2009-09-16 00:00:00',   
-- @EndTime = '2009-09-17 00:00:00',   
-- @RptName = 'SiteTissuePaperRunnabilityReport_tkt#26543975'  
  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
DECLARE   
 -------------------------------------------------------------------------  
 -- Report Parameters  
 -------------------------------------------------------------------------  
 @ProdLineList     VARCHAR(4000),  -- Collection of Prod_Lines.PL_Id for CONVERTing lines delimited by "|".  
 @CatELPId      INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
 @SchedPRPolyId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
 @SchedUnscheduledId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
 @SchedSpecialCausesId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Special Causes.  
 @SchedEOProjectsId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:E.O./Projects.  
 @SchedBlockedStarvedId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
 @ScheduleStr     VARCHAR(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CategoryStr     VARCHAR(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @DelayTypeRateLossStr  VARCHAR(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
 @UserName      VARCHAR(30),  -- User calling this report  
 @RptTitle      VARCHAR(300),  -- Report title from Web Report.  
 @RptPageOrientation   VARCHAR(50),  -- Report Page Orientation from Web Report.  
 @RptPageSize     VARCHAR(50),   -- Report page Size from Web Report.  
 @RptPercentZoom    INTEGER,    -- Percent Zoom from Web Report.  
 @RptTimeout      VARCHAR(100),  -- Report Time from Web Report.  
 @RptFileLocation    VARCHAR(300),  -- Report file location from WEb Report.  
 @RptConnectionString   VARCHAR(300),  -- Connection String from Web Report.  
 @RptWindowMaxDays    INTEGER,    -- Maximum number of days allowed in the date range specified for a given report.   
 @LineStatusList    VARCHAR(4000),  
  
 -------------------------------------------------------------------------------  
 -- Program Variables  
 -------------------------------------------------------------------------------  
 @SearchString      VARCHAR(4000),  
 @Position       INTEGER,  
 @PartialString      VARCHAR(4000),  
 @Now         DATETIME,  
 @@ExtendedInfo      VARCHAR(255),  
 @PUDelayTypeStr     VARCHAR(100),  
 @PULineStatusUnitStr    VARCHAR(100),  
 @@PUId        INTEGER,  
 @@PLId        INTEGER,  
 @VarEffDowntimeVN     VARCHAR(50),  
 @VarBedrollSpeedVN    VARCHAR(50),  
 @VarFeedrollBedrollDrawVN  VARCHAR(50),  
 @VarBottomUWSTensionSetPntVN VARCHAR(50),  
 @VarTopUWSTensionSetPntVN  VARCHAR(50),  
 @VarWndrTensionSetPntVN   VARCHAR(50),  
 @VarLogCompDSPRTopVN    VARCHAR(50),  
 @VarLogCompCntrPRTopVN   VARCHAR(50),  
 @VarLogCompOSPRTopVN    VARCHAR(50),  
 @VarLogCompDSPRBottomVN   VARCHAR(50),  
 @VarLogCompCntrPRBottomVN  VARCHAR(50),  
 @VarLogCompOSPRBottomVN   VARCHAR(50),  
 @PMPerfectPRStatusVN    VARCHAR(50),    
 @SQL         nVARCHAR(4000),  
 @VarPRIDVN       VARCHAR(50),  
 @VarInputRollVN     VARCHAR(50),  
 @VarInputPRIDVN     VARCHAR(50),  
 @VarParentPRIDVN     VARCHAR(50),  
 @VarUnwindStandVN     VARCHAR(50),  
 @VarPRIDId       INTEGER,  
 @LinkStr        varchar(100),  
 @VarUnwindStandId     INTEGER,  
 @RangeStartTime     DATETIME,  
 @RangeEndTime      DATETIME,  
 @Max_TEDet_Id      INTEGER,  
 @Min_TEDet_Id      INTEGER,  
 @LanguageId       INTEGER,  
 @UserId        INTEGER,  
 @LanguageParmId     INTEGER,  
 @NoDataMsg       VARCHAR(100),  
 @TooMuchDataMsg     VARCHAR(100),  
 @blnDupPRIDErrors     INTEGER,    
 @ReportStartTime     DATETIME,  
 @ReportEndTime      DATETIME,  
  
 @RunningStatusID      int  
  
  
 -------------------------------------------------------------------------------  
 -- Constants  
 -------------------------------------------------------------------------------  
 SELECT  
  @ScheduleStr     = 'Schedule',  
  @CategoryStr     = 'Category',  
  @DelayTypeRateLossStr  = 'RateLoss',  
  @CatELPId     = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Category:Paper (ELP)'),  
  @SchedPRPolyId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:PR/Poly Change'),  
  @SchedUnscheduledId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:Unscheduled'),  
  @SchedSpecialCausesId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:Special Causes'),  
  @SchedEOProjectsId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:E.O./Projects'),  
  @SchedBlockedStarvedId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:Blocked/Starved')  
  
-------------------------------------------------------------------------------  
-- Create temp tables  
-------------------------------------------------------------------------------  
CREATE TABLE #Delays (  
 TEDetId          INTEGER PRIMARY KEY NONCLUSTERED,  
 PrimaryId         INTEGER,  
 PUId           INTEGER,  
 PLId           INTEGER,        
 PUDesc          VARCHAR(100),  
 StartTime         DATETIME,  
 EndTime          DATETIME,  
 LocationId         INTEGER,  
 L1ReasonId         INTEGER,  
 L2ReasonId         INTEGER,  
 L2ReasonDesc        varchar(100),  
 ERTD_ID          integer,  
 LineStatus         VARCHAR(50),   
 ScheduleId         INTEGER,  
 CategoryId         INTEGER,  
 DownTime          float,   
 ReportDownTime        float,   
 Stops           INTEGER,  
 StopsUnscheduledExcBlockedStarved INTEGER,  
 StopsELP          INTEGER,  
 StopsBlockedStarved      INTEGER,  
 StopsRateLoss        INTEGER,  
 ReportRLDowntime       FLOAT,  
 InRptWindow         INTEGER  
 )  
  
CREATE TABLE dbo.#Events   
 (  
 event_id            INTEGER,    
 source_event          INTEGER,           
 pu_id             INTEGER,  
 start_time           datetime,  
 end_time           datetime,  
 timestamp           DATETIME,  
 event_status          INTEGER,  
 status_desc           VARCHAR(50),         
 event_num           VARCHAR(50),  
 DevComment           VARCHAR(300)          
-- primary key (Event_id, Start_Time)  
 )  
  
CREATE CLUSTERED INDEX events_eventid_StartTime  
ON dbo.#events (event_id, start_time)   
  
  
create table dbo.#PaperRuns   
 (  
 [UWS]              varchar(50),  
 [Parent PRID]           varchar(50),  
 [PPR Status]           varchar(50),  
 [Top ELP Loss Reason]        varchar(100),  
 [2nd ELP Loss Reason]        varchar(100),  
 [3rd ELP Loss Reason]        varchar(100),  
 [Proll Conv. StartTime]        datetime,  
 [Proll Conv. EndTime]        datetime,  
 [Total Proll Runtime (Mins)]      float,  
 [Excluded Proll Runtime (Mins)]     float,  
 [ELP Proll Runtime (Mins)]       float,  
 [ELP Stops]            int,  
 [ELP Downtime (Mins)]        float,  
 [ELP Rate Loss Eff. Downtime (Mins)]   float,  
 [ELP %]             float,  
 [UnScheduled Stops exc. Blocked / Starved]  int,  
 [Blocked / Starved Stops]       int,  
 [Bedroll Speed]          int,  
 [Feedroll to Bedroll Draw]       float,  
 [Converter Roll Wraps]        int,  
 [Winder Breakouts]         int,  
 [Bottom UWS Tension Setpoint]      float,  
 [Top UWS Tension Setpoint]       float,  
 [Winder Tension Setpoint]       float,  
 [Log Comp DS PR Top]         float,  
 [Log Comp Center PR Top]       float,  
 [Log Comp OS PR Top]         float,  
 [Log Comp DS PR Bottom]        float,  
 [Log Comp Center PR Bottom]      float,  
 [Log Comp OS PR Bottom]        float,  
 [ParentPM]            varchar(15),  
 [ParentTeam]           varchar(15),  
 [Proll TimeStamp]          datetime,  
 [Age Of PR (Days)]         float,  
 [Fresh or Storage?]         varchar(10),  
 [GrandParentPRID]          varchar(50),  
 [GrandParentPM]          varchar(15),  
 [GrandParentTeam]          varchar(15),  
 [LineStatus]           varchar(50),  
 [Numeric StartTime]         float  
 )  
  
create table dbo.#DisplayVarsByUnit  
 (  
 PRPUID   int,  
 Var_ID   int,  
 Var_Desc   varchar(100),  
 Var_Order  int,  
 Data_Type  varchar(50)  
 )  
  
create table dbo.#DisplayVars  
 (  
 Var_Desc   varchar(100),  
 Var_Order  int,  
 Data_Type  varchar(50)  
 )  
  
  
create table dbo.#DisplayResults  
 (  
 Place_Holder int  
 )  
  
  
create table dbo.#PRsRun   
 (  
 Id_Num          INTEGER IDENTITY(1,1),     
 EventId          INTEGER,  
 PLID           int,  
 PUId           INTEGER,  
 PEIId           INTEGER,  
 StartTime         DATETIME,  
 EndTime          DATETIME,  
 InitEndTime         DATETIME,  
 RunTime          FLOAT,  
 AgeOfPR          FLOAT,  
 PRTimeStamp         DATETIME,  
 StartStatus         VARCHAR(50),       
 EndStatus         VARCHAR(50),  
 ParentPRID         VARCHAR(50),   
 GrandParentPRID       VARCHAR(50),   
 ParentPM          VARCHAR(15),    
 GrandParentPM        VARCHAR(15),    
 PaperMachine        varchar(15),  
 PRPLId          INTEGER,    
 PRPUId          INTEGER,    
 PRPUDesc          VARCHAR(100),   
 ParentTeam         VARCHAR(15),  
 GrandParentTeam       VARCHAR(15),  
 [ParentType]        int,   --2=intermediate and 1=Papermachine  
 UWS           VARCHAR(25),  
 [PerfectPRStatus]       varchar(50),      
 ELPReasonDesc1        varchar(100),  
 ELPReasonDesc2        varchar(100),  
 ELPReasonDesc3        varchar(100),  
 LineStatus         VARCHAR(50),  
 EventTimestamp        datetime,  
 PaperRuntime        float,   
 ELPDowntime         float,   
 RLELPDowntime        float,   
 ELPScheduledDowntime      float,   
 CvtgPLId          INTEGER,  
 ELPStops          INTEGER,  
 UnscheduledStopsExcBlockedStarved  INTEGER,  
 BlockedStarvedStops       INTEGER,  
 VarPMPerfectPRStatusId      INTEGER,   
 WinderBreakouts       INTEGER,  
 CvtrRollWraps        INTEGER,  
 BedrollSpeed        float,  
 FeedrollBedrollDraw      float,  
 BottomUWSTensionSetPnt     float,  
 TopUWSTensionSetPnt      float,  
 WndrTensionSetPnt       float,  
 LogCompDSPRTop        float,  
 LogCompCntrPRTop       float,  
 LogCompOSPRTop        float,  
 LogCompDSPRBottom       float,  
 LogCompCntrPRBottom      float,  
 LogCompOSPRBottom       float,  
 DevComment         VARCHAR(100),  
 PRIMARY KEY (Id_Num, PUId, StartTime)  
 )  
  
  
create table dbo.#EventStatusTransitions  
 (  
 Event_ID   int,  
 Start_Time  datetime,  
 End_Time   datetime,  
 Event_Status int  
 )  
  
CREATE CLUSTERED INDEX est_eventid_starttime  
ON dbo.#EventStatusTransitions (event_id, start_time)  
  
  
--CREATE TABLE dbo.#ProdLines    
declare @ProdLines table    
 (  
 PLId          INTEGER PRIMARY KEY,  
 PLDesc         VARCHAR(50),  
 DeptID         INTEGER,  
 ProdPUId         INTEGER,   
 ReliabilityPUId      INTEGER,  
 RateLossPUId       INTEGER,  
 RollsPUID        INTEGER,  
 AuditsPUID        INTEGER,  
 CvtrBlockedStarvedPUID    INTEGER,  
 VarEffDowntimeId      INTEGER,  
 VarPRIDId        INTEGER,  
 VarParentPRIDId      INTEGER,  
 VarUnwindStandId      INTEGER,  
-- VarInputRollID       INTEGER,  
-- VarInputPRIDID       INTEGER,  
 VarBedrollSpeedID      INTEGER,  
 VarFeedrollBedrollDrawID   INTEGER,  
 VarBottomUWSTensionSetPntID  INTEGER,  
 VarTopUWSTensionSetPntID   INTEGER,  
 VarWndrTensionSetPntID    INTEGER,  
 VarLogCompDSPRTopID     INTEGER,  
 VarLogCompCntrPRTopID    INTEGER,  
 VarLogCompOSPRTopID     INTEGER,  
 VarLogCompDSPRBottomID    INTEGER,  
 VarLogCompCntrPRBottomID   INTEGER,  
 VarLogCompOSPRBottomID    INTEGER  
 )  
  
  
 declare @PEI table  
  (  
  pu_id   int,  
  pei_id  int,  
  Input_Order int,  
  Input_name varchar(50)  
  primary key (pu_id,input_name)  
  )  
  
  
DECLARE @DelayTypes TABLE (  
    DelayTypeDesc  VARCHAR(100) PRIMARY KEY)  
  
DECLARE @ProdUnits TABLE (  
 PUId     INTEGER PRIMARY KEY,  
 PUDesc    VARCHAR(100),  
 PLId     INTEGER,  
 ExtendedInfo  VARCHAR(255),  
 DelayType   VARCHAR(100),  
 LineStatusUnit  INTEGER)  
  
/* Intermediate Rolls Units Record Set */   
DECLARE @IntUnits TABLE  
 (  
 puid        int primary key  
 )  
  
declare @PRDTMetrics table  
 (  
 id_num             int,  
 ELPStops             int,  
 ELPDowntime            float,  
 RLELPDowntime            float,  
 ELPScheduledDowntime         float,  
 UnscheduledStopsExcBlockedStarved     int,  
 BlockedStarvedStops         int  
 )  
  
  
/*  
------------------------------------------------------------------  
-- This table will hold the category information based on the   
-- values specific specific to each location.  
------------------------------------------------------------------  
  
declare @TECategories table   
 (  
 TEDet_Id            INTEGER,  
 ERC_Id            int  
 primary key (TEDet_ID, ERC_ID)  
 )  
*/  
  
  
DECLARE @DupPRIDs TABLE (  
 ProdUnit  INTEGER,  
 RollConvST DATETIME,  
 PRID   VARCHAR(50),  
 PRIDCOUNT INTEGER,  
 MaxEventId INTEGER,  
 MinEventId INTEGER )  
  
  
-------------------------------------------------------------------------------  
-- Initialization  
-------------------------------------------------------------------------------  
DECLARE @ErrorMessages TABLE (  
 ErrMsg    VARCHAR(255) )  
  
----------------------------------------------------------------------------------  
--  alter the dbo.#PRsRun table to add variables from the   
--  [Perfect Parent Roll Review Cvtg] display  
----------------------------------------------------------------------------------  
  
declare   
@VarList  varchar(4000)  
  
select @Varlist = ''  
  
insert dbo.#DisplayVarsByUnit   
 (  
 PRPUID,  
 Var_ID,  
 Var_Desc,  
 Var_Order,  
 Data_Type  
 )  
select distinct  
 pu.pu_id,  
 v.var_id,  
 v.var_desc,  
 sv.var_order,  
 dt.data_type_desc  
from dbo.sheets s  
join dbo.sheet_variables sv  
on s.sheet_id = sv.sheet_id  
join dbo.variables v  
on sv.var_id = v.var_id  
join dbo.prod_units pu  
on v.pu_id = pu.pu_id  
join dbo.data_type dt  
on v.data_type_id = dt.data_type_id  
where sheet_desc like '%Perfect Parent Roll Review Cvtg'  
and dt.data_type_desc in ('Integer','Float')  
order by pu.pu_id, sv.var_order  
  
insert dbo.#DisplayVars  
 (  
 Var_Desc,  
 Var_Order,  
 Data_Type  
 )  
select distinct  
 var_desc,  
 min(var_order),  
 data_type  
from dbo.#DisplayVarsByUnit dvu  
group by var_desc, data_type  
  
  
select @VarList = @VarList + '[' + Var_desc + ']' + ' ' + Data_Type + ', '  
from dbo.#DisplayVars  
order by var_desc  
  
exec ('alter table dbo.#DisplayResults add ' + @VarList + '[id_num] int  
   alter table dbo.#DisplayResults drop column [place_holder]')  
  
exec ('alter table dbo.#PaperRuns add ' + @VarList   
   + '[id_num] int')  
  
---------------------------------------------------------------------------------------------------  
-- Retrieve parameter values FROM report definition using spCmn_GetReportParameterValue  
---------------------------------------------------------------------------------------------------   
IF Len(@RptName) > 0   
 BEGIN  
   EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPLIdList',     '',  @ProdLineList     OUTPUT  
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'Owner',        '',  @UserName      OUTPUT  
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptTitle',      '',  @RptTitle      OUTPUT  
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageOrientation',  '',  @RptPageOrientation   OUTPUT  
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageSize',     '',  @RptPageSize     OUTPUT  
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPercentZoom',    '',  @RptPercentZoom    OUTPUT  
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ReportTimeOut',     '',  @RptTimeout     OUTPUT  
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ServerFileLocation',   '',  @RptFileLocation    OUTPUT  
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConnectionString',  '',  @RptConnectionString  OUTPUT  
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptWindowMaxDays',  '32', @RptWindowMaxDays   OUTPUT   
  EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptLineStatusList',  '', @LineStatusList   OUTPUT   
 END  
ELSE  
 BEGIN  
  INSERT INTO @ErrorMessages (ErrMsg)  
   VALUES ('No Report Name specified.')  
   GOTO ReturnResultSets  
 END    
  
if (@LineStatusList IS NULL) or (@LineStatusList='')  
SELECT @LineStatusList='All'  
  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
  
IF isDate(@StartTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
IF isDate(@EndTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@EndTime is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
-- If the endtime is in the future, set it to current day.  This prevent zero records from being   
-- printed on report.  
IF @EndTime > GetDate()  
 SELECT @EndTime = CONVERT(VARCHAR(4),YEAR(GetDate())) + '-' + CONVERT(VARCHAR(2),MONTH(GetDate())) + '-' +   
     CONVERT(VARCHAR(2),DAY(GetDate())) + ' ' + CONVERT(VARCHAR(2),DATEPART(hh,@EndTime)) + ':' +   
     CONVERT(VARCHAR(2),DATEPART(mi,@EndTime))+ ':' + CONVERT(VARCHAR(2),DATEPART(ss,@EndTime))  
  
-- Check RptWindowMaxDays, if NULL assign to 32.  If Date Range exceeds RptWindowMaxDays, then return error msg.  
IF @RptWindowMaxDays IS NULL   
        BEGIN   
        SELECT @RptWindowMaxDays = 32   
        END   
  
IF DATEDIFF(d, @StartTime,@EndTime) > @RptWindowMaxDays   
        BEGIN   
        INSERT        @ErrorMessages (ErrMsg)   
                VALUES        ('The date range selected exceeds the maximum allowed for this report: ' +                           
                        CONVERT(VARCHAR(50),@RptWindowMaxDays) +   
                        '.  Decrease the date range or see your Proficy SSO for help.')   
        GOTO        ReturnResultSets   
        END   
  
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
   @LanguageId    = NULL  
  
SELECT  @UserId = User_Id  
FROM   dbo.Users WITH(NOLOCK)   
WHERE  UserName = @UserName  
  
SELECT  @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN CONVERT(FLOAT, ltrim(rtrim(Value)))  
          ELSE NULL  
          END  
FROM dbo.User_Parameters WITH(NOLOCK)  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 BEGIN  
 SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN CONVERT(FLOAT, ltrim(rtrim(Value)))  
          ELSE NULL  
          END  
 FROM dbo.Site_Parameters WITH(NOLOCK)  
 WHERE Parm_Id = @LanguageParmId  
  
 IF @LanguageId IS NULL  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
   
-------------------------------------------------------------------------------  
-- Constants  
-------------------------------------------------------------------------------  
SELECT @Now          = GetDate(),  
   @PUDelayTypeStr      = 'DelayType=',  
   @PULineStatusUnitStr    = 'LineStatusUnit=',  
   @VarEffDowntimeVN     = 'Effective Downtime',  
   @VarPRIDVN       = 'PRID',  
   @LinkStr        = 'RollsUnit=',  
   @VarParentPRIDVN     = 'Parent PRID',  
   @VarUnwindStandVN     = 'Unwind Stand',  
   @VarInputRollVN     = 'Input Roll ID',  
   @VarInputPRIDVN     = 'Input PRID',  
   @VarBedrollSpeedVN    = 'Bedroll Speed - Glbl',   
   @VarFeedrollBedrollDrawVN  = 'Draw Roll-Bedroll Draw - Glbl',   
   @VarBottomUWSTensionSetPntVN = 'Bottom UWS Tension Setpoint - Glbl',   
   @VarTopUWSTensionSetPntVN  = 'Top UWS Tension Setpoint - Glbl',   
   @VarWndrTensionSetPntVN   = 'Winder Tension Setpoint - Glbl',   
   @VarLogCompDSPRTopVN    = 'Log Comp DS PR Top',   
   @VarLogCompCntrPRTopVN   = 'Log Comp Center PR Top',   
   @VarLogCompOSPRTopVN    = 'Log Comp OS PR Top',   
   @VarLogCompDSPRBottomVN   = 'Log Comp DS PR Bottom',   
   @VarLogCompCntrPRBottomVN  = 'Log Comp Center PR Bottom',   
   @VarLogCompOSPRBottomVN   = 'Log Comp OS PR Bottom',   
   @PMPerfectPRStatusVN    = 'Perfect Parent Roll Status'  
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
-- --print 'Parse passed lists: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Parse the passed lists into temporary tables.  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
-- ProdLineList  
-------------------------------------------------------------------------------  
  
INSERT @ProdLines   
 (  
 PLID,  
 PLDesc,  
 DeptID)  
SELECT   
 PL_ID,  
 PL_Desc,  
 Dept_ID  
FROM dbo.prod_lines pl WITH(NOLOCK)  
WHERE CHARINDEX('|' + CONVERT(VARCHAR,pl_id) + '|','|' + @ProdLineList + '|') > 0  
OPTION (KEEP PLAN)  
  
UPDATE pl SET   
 ProdPUId =    
  (  
  SELECT PU_Id   
  FROM dbo.Prod_Units pu WITH(NOLOCK)  
  WHERE pl.PLId = pu.PL_Id  
  AND (PU_Desc LIKE '%Converter Production'  
   OR  PU_Desc LIKE '%UWS Production')  
  and pu.pu_desc not like '%z_obs%'  
  ),  
 ReliabilityPUId =   
  (  
  SELECT PU_Id  
  FROM dbo.Prod_Units pu WITH(NOLOCK)  
  WHERE pl.PLId = pu.PL_Id  
  AND (PU_Desc LIKE '%Converter Reliability%'  
   OR  PU_Desc LIKE '%INTR Reliability')  
  and pu.pu_desc not like '%z_obs%'  
  ),  
 RateLossPUId =   
  (  
  SELECT PU_Id  
  FROM dbo.Prod_Units pu WITH(NOLOCK)  
  WHERE pl.PLId = pu.PL_Id  
  AND PU_Desc LIKE '%Rate Loss%'  
  and pu.pu_desc not like '%z_obs%'  
  ),  
 AuditsPUId =  
  (  
  SELECT PU_Id  
  FROM dbo.Prod_Units pu WITH(NOLOCK)  
  WHERE pl.PLId = pu.PL_Id  
  AND PU_Desc LIKE '% Converter Audits%'  
  and pu.pu_desc not like '%z_obs%'  
  ),   
 CvtrBlockedStarvedPUId =  
  (  
  SELECT PU_Id  
  FROM dbo.Prod_Units pu WITH(NOLOCK)  
  WHERE pl.PLId = pu.PL_Id  
  AND PU_Desc LIKE '% Converter Blocked/Starved%'  
  and pu.pu_desc not like '%z_obs%'  
  )   
  
FROM @ProdLines pl   
         
UPDATE pl SET   
  
 VarEffDowntimeId      = GBDB.dbo.fnLocal_GlblGetVarId(RateLossPUId,  @VarEffDowntimeVN),  
 VarPRIDId        = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarPRIDVN),  
 VarParentPRIDId      = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarParentPRIDVN),  
 VarUnwindStandId      = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarUnwindStandVN),  
-- VarInputRollID      = GBDB.dbo.fnLocal_GlblGetVarId(RollsPUID,   @VarInputRollVN),  
-- VarInputPRIDID      = GBDB.dbo.fnLocal_GlblGetVarId(RollsPUID,   @VarInputPRIDVN),  
 VarBedrollSpeedID     = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarBedrollSpeedVN),  
 VarFeedrollBedrollDrawID  = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarFeedrollBedrollDrawVN),  
 VarBottomUWSTensionSetPntID = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarBottomUWSTensionSetPntVN),  
 VarTopUWSTensionSetPntID  = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarTopUWSTensionSetPntVN),  
 VarWndrTensionSetPntID   = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarWndrTensionSetPntVN),  
 VarLogCompDSPRTopID    = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarLogCompDSPRTopVN),  
 VarLogCompCntrPRTopID   = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarLogCompCntrPRTopVN),  
 VarLogCompOSPRTopID    = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarLogCompOSPRTopVN),  
 VarLogCompDSPRBottomID   = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarLogCompDSPRBottomVN),  
 VarLogCompCntrPRBottomID  = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarLogCompCntrPRBottomVN),  
 VarLogCompOSPRBottomID   = GBDB.dbo.fnLocal_GlblGetVarId(AuditsPUId,   @VarLogCompOSPRBottomVN)--,  
  
FROM @ProdLines pl   
  
-- --print '@ProdUnits: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- ProdUnitList  
-------------------------------------------------------------------------------  
INSERT @ProdUnits ( PUId,  
       PUDesc,  
       PLId,  
       ExtendedInfo,  
       DelayType,  
       LineStatusUnit)  
SELECT     pu.PU_Id,  
       pu.PU_Desc,  
       pu.PL_Id,  
       pu.Extended_Info,  
       GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr),  
       GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PULineStatusUnitStr)  
FROM dbo.Prod_Units pu WITH(NOLOCK)  
JOIN @ProdLines pl on pl.PLId = pu.PL_Id  
JOIN dbo.departments d WITH (NOLOCK) on d.dept_id = pl.DeptID  
WHERE (PU_desc like '%Converter Reliability%'   
or  (pu_desc like '%Converter Blocked/Starved%' AND (d.dept_desc LIKE 'Cvtg %' OR d.dept_desc = 'Intr'))--)  
or  (pu_desc like '%Rate Loss%' AND (d.dept_desc LIKE 'Cvtg %' OR d.dept_desc = 'Intr')))  
and pu_desc not like '%z_obs%'  
OPTION (KEEP PLAN)  
  
INSERT INTO @IntUnits  
 (  
 puid  
 )  
SELECT    
 pu.pu_id  
FROM dbo.prod_units pu with (nolock)  
WHERE pu.pu_id > 0   
and GBDB.dbo.fnlocal_GlblParseInfo(pu.extended_info,@LinkStr) is not null  
  
  
------------------------------------------  
-- Populate the #Events table  
------------------------------------------  
  
select @RunningStatusID = ps.prodstatus_id   
from dbo.Production_Status ps WITH(NOLOCK)   
where UPPER(ps.prodstatus_desc) = 'RUNNING'   
  
insert dbo.#EventStatusTransitions  
 (  
 Event_ID,  
 Start_Time,  
 End_Time,  
 Event_Status  
 )  
select  
 Event_ID,  
 Start_Time,  
 End_Time,  
 Event_Status  
from dbo.event_status_transitions est with(nolock)  
where est.event_status = @RunningStatusID  
--and est.start_time < @endtime  
--and (est.start_time < est.end_time or est.end_time is null)  
--and (est.end_time > @starttime or est.end_time is null)  
and (est.start_time < est.end_time or est.end_time is null)  
and est.end_time <= @endtime  
and (est.end_time > @starttime or est.end_time is null)  
  
  
INSERT dbo.#Events  
 (  
 event_id,  
 pu_id,  
 start_time,  
 end_time,  
 timestamp,       
 event_num,  
 DevComment  
 )  
select distinct  
 est.event_id,  
 e.pu_id,  
 est.start_time,  
 coalesce(est.end_time,@endtime),  
 e.timestamp,  
 e.event_num,  
 'Initial Load'  
--from dbo.event_status_transitions est  
from dbo.#EventStatusTransitions est  
join dbo.events e with(nolock)  
on est.event_id = e.event_id  
  
  
/*  
INSERT dbo.#Events  
 (  
 event_id,  
 pu_id,  
 start_time,  
 end_time,  
 timestamp,       
 event_num,  
 DevComment  
 )  
select distinct  
 est.event_id,  
 e.pu_id,  
 est.start_time,  
 coalesce(est.end_time,@endtime),  
 e.timestamp,  
 e.event_num,  
 'Initial Load'  
from dbo.event_status_transitions est  
join dbo.events e  
on est.event_id = e.event_id  
where   
 (  
 est.event_status = @RunningStatusID  
 and est.end_time < @endtime  
 and (est.end_time > @starttime)  
 )  
*/  
  
update e set  
 source_event = coalesce(ec.source_event_id,e.event_id)  
from dbo.#events e with (nolock)  
LEFT JOIN dbo.event_components ec with (nolock)  
ON e.event_id = ec.event_id  
  
  
INSERT INTO dbo.#prsrun  
 (   
 [EventID],  
 [PLID],  
 [puid],  
 [StartTime],  
 [InitEndTime],  
 [PRTimeStamp],  
 [PRPUID],  
 EventTimestamp,  
 [LineStatus],  
 DevComment    
 )  
SELECT distinct  
 e.event_id,  
 pu.pl_id,  
 pu.pu_id,  
  
 e.start_time [StartTime],  
 e.end_time [EndTime],  
  
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e1.timestamp, 120)) [PRIDTimeStamp],   
 e1.pu_id [PRPUID],  
 e.timestamp,  
 'Rel Unknown:Qual Unknown' [LineStatus],  
 'Initial Running Insert'    
-- events with Running status  
from dbo.#events e   
JOIN @ProdLines pl   
ON (e.PU_Id = pl.ProdPUId or e.pu_id = pl.ratelosspuid)  
JOIN dbo.prod_units pu with (nolock)   
ON pu.pu_id = e.pu_id   
-- source events  
JOIN dbo.events e1 with (nolock)  
ON e1.event_id = e.source_event  
  
update prs set  
 [ParentPRID] = UPPER(RTRIM(LTRIM(tprid.result))),  
 [ParentPM] =  UPPER(RTRIM(LTRIM(LEFT(COALESCE(tprid.Result, 'NoAssignedPRID'), 2)))),  
 [UWS] = coalesce(tuws.result,'No UWS Assigned')  
from dbo.#prsrun prs  
join @prodlines pl  
on prs.puid = pl.prodpuid  
-- ParentPRID  
left JOIN dbo.Tests tprid with (nolock)  
on (tprid.Var_Id = pl.VarPRIDId and tprid.result_on = prs.EventTimeStamp)  
or (tprid.var_id = pl.VarParentPRIDId and tprid.result_on = prs.EventTimeStamp)  
-- Unwind Stands   
left JOIN dbo.Tests tuws with (nolock)  
on tuws.Var_Id = pl.VarUnwindStandID   
and tuws.result_on = prs.EventTimeStamp  
  
  
UPDATE prs SET   
 PEIId   = pei_id  
FROM dbo.#PRsRun     prs   
JOIN dbo.PrdExec_Inputs pei WITH (NOLOCK)   
ON pei.pu_id = prs.puid   
AND pei.input_name = prs.UWS  
  
-- Line FFF1 in Facial has a different configuration than other lines.  
-- This code will pull the correct PEIID and determine a unique   
-- input_order for parent rolls on this line.  
  
if (select value from site_parameters where parm_id = 12) = 'Green Bay'  
begin   
  
if (  
 select count(*)  
 from @prodlines pl  
 where prodpuid = 1464  
 ) > 0  
  
begin  
  
 insert @PEI  
  (  
  pu_id,  
  pei_id,  
  Input_Order,  
  Input_name  
  )  
 select distinct  
  1464, --pu_id,  
  pei_id,  
  convert(int,ltrim(replace(input_name, 'UWS', ''))),  
  input_name    
 from dbo.PrdExec_Inputs pei  
 where (  
    pei.pu_id = 1465  
   or pei.pu_id = 1466  
   or pei.pu_id = 1467  
   or pei.pu_id = 1468  
   )  
  
 UPDATE prs SET   
  PEIId   = pei.pei_id--,  
--  Input_Order  = pei.input_order  
 FROM dbo.#prsrun prs   
 JOIN @pei pei  
 ON prs.puid = pei.pu_id  
 and pei.input_name = prs.UWS  
 where prs.puid = 1464  
   
end  
end  
  
  
DELETE dbo.#PRsRun  
WHERE PEIId IS NULL  
  
update prs SET   
 [ParentPRID] = coalesce(t.result,'NoAssignedPRID'),   
 [PRTimeStamp] = e.timestamp,  
 [PRPUID] = e.pu_id  
FROM dbo.#PRsRun prs   
join @prodlines pl   
on prs.plid = pl.plid  
LEFT JOIN dbo.events e with (nolock)   
ON e.event_id = prs.eventid  
LEFT JOIN dbo.variables v with (nolock)   
ON v.pu_id = e.pu_id   
and v.var_id = pl.VarPRIDID  
LEFT JOIN dbo.tests t with (nolock)   
ON t.var_id = v.var_id   
and t.result_on = e.timestamp   
LEFT JOIN dbo.prod_units pu with (nolock)   
ON pu.pu_id = e.pu_id  
WHERE pu.pu_desc LIKE '% Rolls'   
and [ParentPRID] = 'NoAssignedPRID'  
  
--print 'parent type' + ' ' + convert(varchar(25),current_timestamp,108)  
  
UPDATE prs SET   
 [ParentType] =   
  CASE   
  WHEN prs.[PRPUID] = iu.puid   
  THEN 2  
      ELSE 1  
      END  
FROM dbo.#PRsRun prs   
LEFT JOIN @IntUnits iu   
ON iu.puid = prs.[PRPUID]  
  
--print 'grand prid' + ' ' + convert(varchar(25),current_timestamp,108)  
/*  
UPDATE prs SET   
 [GrandParentPRID] = t.result,  
 [GrandParentPM] = UPPER(RTRIM(LTRIM(LEFT(t.Result, 2))))--,  
FROM dbo.#PRsRun prs   
join dbo.#ProdLines pl   
on prs.plid = pl.plid  
LEFT JOIN dbo.tests t with (nolock)   
ON t.result_on = prs.[PRTimestamp]   
and prs.[ParentType] = 2  
LEFT JOIN dbo.variables v with (nolock)   
ON v.var_id = t.var_id   
and v.pu_id = prs.[PRPUID]   
where v.var_id = pl.VarInputRollID  
or v.var_id = pl.VarInputPRIDID  
*/  
  
UPDATE prs SET   
 [GrandParentPRID] = t.result,  
 [GrandParentPM] = UPPER(RTRIM(LTRIM(LEFT(t.Result, 2))))--,  
FROM dbo.#prsrun prs   
--join dbo.#ProdLines pl   
--on prs.plid = pl.plid  
LEFT JOIN dbo.tests t with (nolock)   
ON t.result_on = prs.[PRTimestamp]   
and prs.[ParentType] = 2  
LEFT JOIN dbo.variables v with (nolock)   
ON v.var_id = t.var_id   
and v.pu_id = prs.[PRPUID]   
--Rev7.67  
--where v.var_id = pl.VarInputRollID  
--or v.var_id = pl.VarInputPRIDID  
where v.var_desc_global = @VarInputRollVN --pl.VarInputRollID  
or v.var_desc_global = @VarInputPRIDVN --pl.VarInputPRIDID  
  
--print 'PMTeams' + ' ' + convert(varchar(25),current_timestamp,108)  
update prs set  
 ParentTeam =   
 SUBSTRING(UPPER(RTRIM(LTRIM(coalesce(ParentPRID, '')))), 3, 1),  
 GrandparentTeam =   
 SUBSTRING(UPPER(RTRIM(LTRIM(coalesce(GrandParentPRID, '')))), 3, 1)  
from dbo.#PRsRun prs --with (nolock)  
where ParentPRID <> 'NoAssignedPRID'  
  
  
  ------------------------------------------------------------------------------------------------  
  -- If duplicate PRIDs Exist, INSERT Contents of @Events into the @ErrorMessages table, then  
  -- GOTO ReturnResultSets  
  ------------------------------------------------------------------------------------------------  
  SELECT @blnDupPRIDErrors = 0  
  
  INSERT @DupPRIDs (ProdUnit, RollConvST, PRID, PRIDCount, MaxEventId, MinEventId)  
   SELECT  PUId,  
      MAX(StartTime),  
      ParentPRID,  
      COUNT(ParentPRID),  
      MAX(EventId),  
      MIN(EventId)  
   FROM dbo.#PRsRun pr   
   GROUP BY PUId, ParentPRID, StartTime    -- 2005-SEP-12 VMK Rev6.97 Added StartTime  
   OPTION (KEEP PLAN)  
  
  IF (SELECT COUNT(PRID) FROM @DupPRIDs WHERE PRIDCOUNT > 1) > 0  
   BEGIN  
    SELECT @blnDupPRIDErrors = 1  
    INSERT @ErrorMessages (ErrMsg)  
     SELECT  'Duplicate PRID error.  ProdUnit: ' + pu.PUDesc   +   
        '; Roll Conv ST: ' + CONVERT(VARCHAR(20), RollConvST) +  
        '; Parent PRID: ' + PRID  +  
        '; Count: ' + CONVERT(VARCHAR(5), PRIDCount) +   
        '; Max EventId: ' + CONVERT(VARCHAR(20), MaxEventId) +  
        '; Min EventId: ' + CONVERT(VARCHAR(20), MinEventId)  
     FROM @DupPRIDs dp  
       JOIN @ProdUnits pu ON dp.ProdUnit = pu.PUId  
     WHERE PRIDCount > 1  
     OPTION (KEEP PLAN)  
   END  
  
  
-- to identify overlap adjustments, query the temp table for InitEndtime <> Endtime  
UPDATE prs1 SET   
 prs1.Endtime =   
  coalesce((  
  select top 1 prs2.Starttime  
  from dbo.#PRsRun prs2   
  where prs1.PUId = prs2.PUId  
  and prs1.StartTime <= prs2.StartTime   
  and prs1.InitEndTime > prs2.StartTime  
  AND prs1.PEIId = prs2.PEIId  
  and prs1.id_num < prs2.id_num  
  order by puid, starttime  
  ), prs1.InitEndtime)  
FROM dbo.#PRsRun prs1   
  
-- Rev1.3  
delete dbo.#PRsRun  
where CONVERT(DATETIME, CONVERT(VARCHAR(20), starttime, 120)) = CONVERT(DATETIME, CONVERT(VARCHAR(20), endtime, 120))  
  
select   
@ReportStartTime = min(starttime),  
@ReportEndTime = max(endtime)  
from dbo.#PRsRun  
  
  
  
/*   -- this insert is commented out because it is not needed  
  -- however, the code is left in place to be consistant with other reports.  
-------------------------------------------------------------------------------------------  
-- #PRsRun includes PRs run for the converting lines included in the report.  However, it   
-- does not include time slices where there is no PR loaded on the UWS.    
-- Now add the records that fill in that time and assign them to 'NoAssignedPRID'.  
-------------------------------------------------------------------------------------------  
INSERT dbo.#PRsRun (  
   EventId,  
   PLID,  
   PUId,  
   PEIId,  
   StartTime,  
   EndTime,  
   Runtime,  
   AgeOfPR,  
   PRTimeStamp,  
   ParentPRID,   
   GrandParentPRID,   
   ParentPM,  
   GrandParentPM,  
   PRPLId,    
   PRPUId,    
   PRPUDesc,   
   ParentTeam,  
   GrandParentTeam,  
   UWS,  
   LineStatus,  
   DevComment )  
SELECT  NULL,     
   prs1.PLID,  
   prs1.PUId,  
   prs1.PEIId,  
   prs1.EndTime,  
   prs2.StartTime,  
   DATEDIFF(ss, prs1.EndTime, prs2.StartTime),  
   NULL,  
   NULL,  
   'NoAssignedPRID',  
   'NoAssignedPRID',  
   'NoAssignedPRID',  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   prs1.UWS,      
   prs1.LineStatus,  
   'Fill Gaps'     
FROM dbo.#PRsRun prs1  
JOIN dbo.#PRsRun prs2 ON prs1.PUId = prs2.PUId  
        AND prs1.PEIId = prs2.PEIId                  
        AND prs2.StartTime = (SELECT TOP 1 prs.StartTime FROM dbo.#PRsRun prs  
               WHERE prs.StartTime > prs1.StartTime         
               AND prs.PUId = prs1.PUId  
               AND prs.PEIId = prs1.PEIId   
               ORDER BY prs.StartTime ASC)    
where datediff (  
     ss,  
     CONVERT(DATETIME, CONVERT(VARCHAR(20), prs1.EndTime, 120)),  
     CONVERT(DATETIME, CONVERT(VARCHAR(20), prs2.StartTime, 120))  
     ) > 60.0   
OPTION (KEEP PLAN)      
*/  
  
update prs SET   
 AgeOfPR = datediff(ss, PRTimeStamp, prs.starttime) / 86400.0  
FROM dbo.#PRsRun prs   
  
update prs set  
 [LineStatus] = p.Phrase_Value  
FROM dbo.#PRsRun prs   
LEFT JOIN dbo.Local_PG_Line_Status pgls WITH (NOLOCK)   
ON prs.PUId = pgls.Unit_Id  
AND (prs.Starttime >= pgls.Start_DateTime  
AND (prs.Starttime <  pgls.End_DateTime OR pgls.End_DateTime IS NULL))  
AND pgls.update_status <> 'DELETE'   
LEFT JOIN dbo.Phrase p WITH (NOLOCK)   
ON pgls.line_status_id = p.Phrase_Id  
  
------------------------------------------------------------  
-- Update UWS column based on PEIId when UWS IS NULL.  
------------------------------------------------------------  
-- do we need this ?????  
UPDATE prs  
 SET UWS = pei.Input_Name  
FROM dbo.#PRsRun prs  
JOIN dbo.PrdExec_Inputs pei WITH(NOLOCK) ON prs.PEIId = pei.PEI_Id  
WHERE prs.UWS IS NULL AND prs.PEIId IS NOT NULL  
  
update prs set  
 prpudesc = pu.pu_desc  
from dbo.#PRsRun prs  
join dbo.prod_units pu  
on prs.prpuid = pu.pu_id  
  
UPDATE prs SET  
 [UWS] =   
  CASE   
  WHEN SUBSTRING(UPPER(RTRIM(LTRIM(pl.PlDesc))), 4, 4) IN ('FF7A', 'FFF7','FFFW', 'FPRW', 'FFF1')  
  THEN SUBSTRING(UPPER(RTRIM(LTRIM(pl.PlDesc))), 4, 4) + ' ' + [UWS]  
      ELSE [UWS]  
      END  
FROM dbo.#PRsRun prs   
JOIN @ProdLines pl ON pl.PlId = prs.PlId  
  
-- --print 'Get #Delays: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Collect dataset filtered by report period and Production Units.  
-------------------------------------------------------------------------------  
  
  INSERT INTO dbo.#Delays   
   (   
   TEDetId,  
   PUId,  
   PLId,       
   StartTime,  
   EndTime,  
   LocationId,  
   L1ReasonId,  
   L2ReasonId,  
   ERTD_ID,  
   DownTime,  
   ReportDownTime,  
   PrimaryId,  
   InRptWindow--,  
   )       
  SELECT ted.TEDet_Id,  
   ted.PU_Id,  
   tpu.PLId,       
   ted.Start_Time,  
   COALESCE(ted.End_Time, @Now),  
   ted.Source_PU_Id,  
   ted.Reason_Level1,  
   ted.Reason_Level2,  
   ted.event_reason_tree_data_id,  
   DATEDIFF (second, ted.Start_Time, COALESCE(ted.End_Time, @Now)),  
   DATEDIFF (second, (CASE WHEN ted.Start_Time < @ReportStartTime   
           THEN @ReportStartTime   
           ELSE ted.Start_Time  
           END),  
         (CASE WHEN COALESCE(ted.End_Time, @Now) > @ReportEndTime   
           THEN @ReportEndTime   
           ELSE COALESCE(ted.End_Time, @Now)  
           END)),  
   ted2.TEDet_Id,  
   CASE WHEN ( --Events that started outside the report window but ended within it.  
     ( ted.Start_Time < @ReportStartTime  
      AND ( COALESCE(ted.End_Time, @Now) >= @ReportStartTime  
       AND COALESCE(ted.End_Time, @Now) <= @ReportEndTime))   
     --Events that started and ended within the report window.  
     OR ( ted.Start_Time >= @ReportStartTime  
      AND COALESCE(ted.End_Time, @Now) <= @ReportEndTime)   
     --Events that ended outside the report window but started within it.  
     OR ( COALESCE(ted.End_Time, @Now) > @ReportEndTime  
      AND ( ted.Start_Time >= @ReportStartTime  
       AND ted.Start_Time <= @ReportEndTime))  
     --Events that span the entire report window  
     OR ( ted.Start_Time < @ReportStartTime  
      AND COALESCE(ted.End_Time, @Now) > @ReportEndTime)  
     ) THEN 1  
    ELSE 0  
    END  
  FROM dbo.Timed_Event_Details ted WITH(NOLOCK)  
   JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId AND tpu.PUId > 0   
   LEFT JOIN dbo.Timed_Event_Details ted2 WITH(NOLOCK) ON  ted.PU_Id = ted2.PU_Id  
        AND ted.Start_Time = ted2.End_Time  
        AND ted.TEDet_Id <> ted2.TEDet_Id  
  WHERE ted.Start_Time < @ReportEndTime  
  AND  (ted.End_Time > @ReportStartTime OR ted.End_Time IS NULL)  
  OPTION (KEEP PLAN)  
  
  
UPDATE td       
SET PUDESC =  CASE  WHEN pu.PUDesc LIKE ('%Converter Reliability%') OR pu.PUDesc LIKE ('%Rate Loss%')   
       THEN CASE  WHEN pl.PLDesc LIKE 'TT%'  
              THEN LTRIM(RTRIM(REPLACE(pl.PLDesc,'TT ',''))) + ' Converter Reliability'   
             WHEN pl.PLDesc LIKE 'PP%'  
             THEN LTRIM(RTRIM(REPLACE(pl.PLDesc,'PP ',''))) + ' Converter Reliability'    
             ELSE pu.PUDesc  
             END  
       WHEN pu.PUDesc LIKE ('%INTR Reliability%')                  
       THEN CASE  WHEN pl.PLDesc LIKE 'TT%'                    
              THEN LTRIM(RTRIM(REPLACE(pl.PLDesc,'TT ',''))) + ' INTR Reliability'      
             WHEN pl.PLDesc LIKE 'PP%'                         
             THEN LTRIM(RTRIM(REPLACE(pl.PLDesc,'PP ',''))) + ' INTR Reliability'      
             ELSE pu.PUDesc                        
             END                           
       ELSE pu.PUDesc  
       END  
     
FROM  dbo.#Delays td WITH(NOLOCK)  
 INNER JOIN @ProdUnits pu ON td.PUID = pu.PUId  
 INNER JOIN @ProdLines pl ON pu.PLId = pl.PLId  
WHERE td.PUDESC IS NULL  
  
-- Get the maximum range for later queries  
SELECT TOP 1 @RangeStartTime = StartTime  
FROM dbo.#Delays WITH(NOLOCK)  
WHERE PUId > 0 AND StartTime < @ReportEndTime  -- Was trying to force the use of an index here but didn't seem to work  
ORDER BY StartTime ASC  
OPTION (KEEP PLAN)  
  
SELECT TOP 1 @RangeEndTime = EndTime  
FROM dbo.#Delays WITH(NOLOCK)  
WHERE PUId > 0 AND EndTime > @ReportStartTime  -- Was trying to force the use of an index here but didn't seem to work  
ORDER BY EndTime DESC  
OPTION (KEEP PLAN)  
  
   
-- --print 'PrimaryIds point to actual Primary event: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Cycle through the dataset and ensure that all the PrimaryIds point to the  
-- actual Primary event.  
-------------------------------------------------------------------------------  
WHILE (SELECT Count(td1.TEDetId)  
  FROM dbo.#Delays td1 WITH(NOLOCK)  
  JOIN dbo.#Delays td2 WITH(NOLOCK) ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL) > 0  
 BEGIN  
  UPDATE td1  
   SET PrimaryId = td2.PrimaryId  
  FROM dbo.#Delays td1 WITH(NOLOCK)  
   JOIN dbo.#Delays td2 WITH(NOLOCK) ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL  
 END  
  
UPDATE dbo.#Delays  
 SET PrimaryId = TEDetId  
WHERE PrimaryId IS NULL  
  
  
-- --print 'Add Line Status to #Delays: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Add the Line Status to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET LineStatus = p.Phrase_Value  
FROM dbo.#Delays td WITH(NOLOCK)  
 JOIN @ProdUnits pu ON td.PUId = pu.PUId  
 INNER JOIN dbo.Local_PG_Line_Status ls WITH(NOLOCK) ON  pu.LineStatusUnit = ls.Unit_Id  
     AND td.StartTime >= ls.Start_DateTime  
     AND (td.StartTime < ls.End_DateTime OR ls.End_DateTime IS NULL)  
 INNER JOIN dbo.Phrase p WITH(NOLOCK) ON ls.Line_Status_Id = p.Phrase_Id  
  
  
/*  
-- --print 'Get categories for #Delays: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- dbo.Timed_Event_Details row from the Local_Timed_Event_Categories table using  
-- the TEDet_Id.  
-------------------------------------------------------------------------------  
-- Get the minimum - maximum range for later queries  
SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
 @Min_TEDet_Id = MIN(TEDetId) - 1,  
 @RangeStartTime = MIN(StartTime),  
 @RangeEndTime = MAX(EndTime)  
FROM dbo.#Delays WITH(NOLOCK)  
option (keep plan)  
  
  
INSERT INTO @TECategories   
 (  
 TEDet_Id,  
 ERC_Id  
 )  
SELECT tec.TEDet_Id,  
 tec.ERC_Id  
FROM dbo.#Delays td WITH(NOLOCK)  
JOIN  dbo.Local_Timed_Event_Categories tec WITH(NOLOCK)   
ON td.TEDetId = tec.TEDet_Id  
and tec.TEDet_Id > @Min_TEDet_Id  
AND tec.TEDet_Id < @Max_TEDet_Id  
option (keep plan)  
  
UPDATE td  
SET ScheduleId = tec.ERC_Id  
FROM dbo.#Delays td WITH(NOLOCK)  
JOIN  @TECategories tec   
ON  td.TEDetId = tec.TEDet_Id  
JOIN  dbo.Event_Reason_Catagories erc WITH(NOLOCK)   
ON tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
UPDATE td  
SET ScheduleId = @SchedBlockedStarvedId  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Event_Reasons er with (nolock)  
on Event_Reason_ID = L1ReasonId   
WHERE ScheduleId IS NULL   
AND (Event_Reason_Name LIKE '%BLOCK%' OR Event_Reason_Name LIKE '%STARVE%')  
  
UPDATE td  
SET CategoryId = tec.ERC_Id  
FROM dbo.#Delays td WITH(NOLOCK)  
JOIN  @TECategories tec   
ON  td.TEDetId = tec.TEDet_Id  
JOIN  dbo.Event_Reason_Catagories erc WITH(NOLOCK)   
ON tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @CategoryStr + '%'  
*/  
  
  
UPDATE td SET  
 ScheduleId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
  
UPDATE td  
SET ScheduleId = @SchedBlockedStarvedId  
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
  
  
-- --print 'Update #Delays with #Primaries totals: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Calculate the Statistics on the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET Stops =   CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
            AND (td.StartTime >= @ReportStartTime)  
       THEN 1  
       ELSE 0  
       END,  
     
   StopsUnscheduledExcBlockedStarved =   
    CASE   
    WHEN tpu.pudesc like '%converter reliability%'  
    AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
    AND  (td.StartTime >= @ReportStartTime)  
    THEN 1  
    ELSE 0  
    END,  
  
   StopsELP =  CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
            AND (td.CategoryId = @CatELPId)  
            AND (td.StartTime >= @ReportStartTime)  
        THEN 1  
        ELSE 0  
        END,  
  
   StopsBlockedStarved =   
--Rev1.97  
--    CASE   
--    WHEN tpu.pudesc like '%converter reliability%'  
--    AND td.ScheduleId = @SchedBlockedStarvedId  
--    AND  (td.StartTime >= @ReportStartTime)  
--    THEN 1  
--    ELSE 0  
--    END,  
  CASE   
  --WHEN td.CategoryId = @CatBlockStarvedId     
  WHEN td.ScheduleId = @SchedBlockedStarvedId    
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @ReportStartTime)  
  THEN 1  
  ELSE 0  
  END,  
     
  ReportDowntime =   (CASE WHEN tpu.DelayType = @DelayTypeRateLossStr THEN 0 ELSE td.ReportDowntime END)  
 FROM dbo.#Delays td WITH(NOLOCK)  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
 WHERE  td.TEDetId = td.PrimaryId  
  
-- Update the Rate Loss Event data for both Primary and Secondary events.  
 UPDATE td   
  SET StopsRateLoss = 1,  
    ReportDowntime =  0,  
    ReportRLDowntime =  (SELECT CONVERT(FLOAT, Result) FROM Tests t WITH(NOLOCK) WHERE td.StartTime = t.Result_On  
        AND t.Var_Id = tpl.VarEffDowntimeId) * 60.0  
 FROM dbo.#Delays td WITH(NOLOCK)  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
 JOIN @ProdLines tpl ON tpu.PLId = tpl.PLId  
 WHERE tpu.DelayType = @DelayTypeRateLossStr  
  AND (td.StartTime >= @ReportStartTime AND td.StartTime < @ReportEndTime)  
  
  
-- Rev1.8  
update td set  
 L2ReasonDesc = Event_Reason_Name  
from dbo.#delays td  
join dbo.event_reasons er  
on td.L2ReasonID = er.event_reason_id  
  
-- Rev1.8  
update prs set  
 [ELPReasonDesc1] =  
  (  
  select top 1 td.L2ReasonDesc  
  from dbo.#delays td  
  where (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
  and (td.starttime < prs.endtime or prs.endtime is null)   
  and (td.starttime >= prs.starttime) -- or td.endtime is null)  
  and td.CategoryId = @CatELPId  
  group by td.L2ReasonDesc  
  order by sum((case when ReportDowntime > 0.0 then ReportDowntime else coalesce(Downtime,0.0) end)   
       + coalesce(ReportRLDowntime,0.0)) desc   
  )  
from dbo.#PRsRun prs  
join @prodlines pl  
on prs.puid = pl.prodpuid  
  
-- Rev1.8  
update prs set  
 [ELPReasonDesc2] =  
  (  
  select top 1 td.L2ReasonDesc  
  from dbo.#delays td  
  where (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
  and (td.starttime < prs.endtime or prs.endtime is null)   
  and (td.starttime >= prs.starttime) -- or td.endtime is null)  
  and td.CategoryId = @CatELPId    
  and td.L2ReasonDesc <> prs.ELPReasonDesc1  
  group by td.L2ReasonDesc  
  order by sum((case when ReportDowntime > 0.0 then ReportDowntime else coalesce(Downtime,0.0) end)   
       + coalesce(ReportRLDowntime,0.0)) desc   
  )  
from dbo.#PRsRun prs  
join @prodlines pl  
on prs.puid = pl.prodpuid  
  
-- Rev1.8  
update prs set  
 [ELPReasonDesc3] =  
  (  
  select top 1 td.L2ReasonDesc  
  from dbo.#delays td  
  where (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
  and (td.starttime < prs.endtime or prs.endtime is null)   
  and (td.starttime >= prs.starttime) -- or td.endtime is null)  
  and td.CategoryId = @CatELPId  
  and td.L2ReasonDesc <> prs.ELPReasonDesc1  
  and td.L2ReasonDesc <> prs.ELPReasonDesc2  
  group by td.L2ReasonDesc  
  order by sum((case when ReportDowntime > 0.0 then ReportDowntime else coalesce(Downtime,0.0) end)   
       + coalesce(ReportRLDowntime,0.0)) desc   
  )  
from dbo.#PRsRun prs  
join @prodlines pl  
on prs.puid = pl.prodpuid  
  
  
insert @PRDTMetrics  
 (  
 id_num,  
 ELPStops,  
 ELPDowntime,  
 RLELPDowntime,  
 ELPScheduledDowntime,  
 UnscheduledStopsExcBlockedStarved,  
 BlockedStarvedStops  
 )  
select  
 prs.id_num,  
  
 SUM(  
  CASE   
  when  td.CategoryId = @CatELPId  
  and  td.StopsELP = 1  
  and td.starttime >= prs.starttime  
  and td.starttime < prs.endtime  
  THEN  1   
  ELSE  0   
  END  
  ) ELPStops,  
  
 sum(  
  case  
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.CategoryId = @CatELPId)  
  and td.starttime >= prs.starttime  
  and td.starttime < prs.endtime  
  then Downtime   
  else 0.0  
  end  
  ) ELPDowntime,  
  
 sum(  
  case  
  when (td.CategoryId = @CatELPId)  
--  and  td.StopsRateloss = 1  
  and td.starttime >= prs.starttime  
  and td.starttime < prs.endtime  
  then td.ReportRLDowntime  
  else 0.0  
  end   
  ) RLELPDowntime,  
  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0)   
  then   
   datediff (  
      ss,  
      case when td.StartTime < prs.StartTime  
      then prs.StartTime else td.StartTime end,  
      case when (coalesce(td.EndTime,prs.endtime) >= prs.EndTime)  
      then prs.EndTime else td.EndTime end  
      )   
  else 0.0  
  end  
  ) ELPScheduledDowntime,  
  
 SUM(  
  CASE   
  when  td.StopsUnscheduledExcBlockedStarved = 1  
  and td.starttime >= prs.starttime  
  and td.starttime < prs.endtime  
  THEN  1   
  ELSE  0   
  END  
  ) UnscheduledStopsExcBlockedStarved,  
   
 SUM(  
  CASE   
  when  td.StopsBlockedStarved = 1  
  and td.starttime >= prs.starttime  
  and td.starttime < prs.endtime  
  THEN  1   
  ELSE  0   
  END  
  ) BlockedStarvedStops  
  
FROM dbo.#PRsRun prs   
join @prodlines pl  
on prs.puid = pl.prodpuid  
left join dbo.#delays td  
--Rev1.97  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid or pl.CvtrBlockedStarvedPUID = td.puid)  
and (td.starttime < prs.endtime or prs.endtime is null)   
and (td.endtime > prs.starttime or td.endtime is null)  
left JOIN @ProdUnits tpu   
ON td.PUId = tpu.PUId  
group by prs.id_num   
  
  
update prs set  
 Runtime = datediff(ss,prs.starttime,prs.endtime),   
 ELPStops = pdm.ELPStops,  
 ELPDowntime = pdm.ELPDowntime,  
 RLELPDowntime = pdm.RLELPDowntime,  
 ELPScheduledDowntime = pdm.ELPScheduledDowntime,  
 UnscheduledStopsExcBlockedStarved = pdm.UnscheduledStopsExcBlockedStarved,  
 BlockedStarvedStops = pdm.BlockedStarvedStops  
from dbo.#prsrun prs  
join @prdtmetrics pdm  
on prs.id_num = pdm.id_num  
  
update prs set  
 WinderBreakouts =  
  COALESCE((  
     select  
      sum(td.stops)   
     FROM dbo.#PRsRun tprs   
     join @prodlines pl  
     on tprs.puid = pl.prodpuid  
     join dbo.#delays td  
     on pl.reliabilitypuid = td.puid   
     and (td.starttime < tprs.endtime or tprs.endtime is null)   
     and td.starttime >= tprs.starttime  
     join dbo.event_reasons er1  
     on td.L1ReasonID = er1.event_reason_id  
     join dbo.event_reasons er2  
     on td.L2ReasonID = er2.event_reason_id  
     where tprs.id_num = prs.id_num  
     and er1.event_reason_name = 'WND34 Breakout'  
     and er2.event_reason_name like 'QP%'   
     ),0),      
 CvtrRollWraps =  
  COALESCE((  
     select  
      sum(td.stops)   
     FROM dbo.#PRsRun tprs   
     join @prodlines pl  
     on tprs.puid = pl.prodpuid  
     join dbo.#delays td  
     on pl.reliabilitypuid = td.puid   
     and (td.starttime < tprs.endtime or tprs.endtime is null)   
     and td.starttime >= tprs.starttime  
     join dbo.event_reasons er1  
     on td.L1ReasonID = er1.event_reason_id  
     join dbo.event_reasons er2  
     on td.L2ReasonID = er2.event_reason_id  
     where tprs.id_num = prs.id_num  
     and er1.event_reason_name like '%wrap%'  
     and er2.event_reason_name like 'QP%'   
     ),0)   
from dbo.#prsrun prs  
  
  
update prs set  
 PaperRuntime = Runtime - ELPScheduledDowntime  
from dbo.#PRsRun prs  
  
update dbo.#PRsRun set   
 VarPMPerfectPRStatusId = GBDB.dbo.fnLocal_GlblGetVarId(prs.PRPUID, @PMPerfectPRStatusVN)  
from dbo.#prsrun prs  
  
update prs set  
  
 BedrollSpeed =  
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarBedrollSpeedID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
  
 FeedrollBedrollDraw =  
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarFeedrollBedrollDrawID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
  
 BottomUWSTensionSetPnt =  
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarBottomUWSTensionSetPntID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
   
 TopUWSTensionSetPnt =  
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarTopUWSTensionSetPntID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
   
 WndrTensionSetPnt =   
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarWndrTensionSetPntID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
   
 LogCompDSPRTop =   
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarLogCompDSPRTopID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
   
 LogCompCntrPRTop =   
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarLogCompCntrPRTopID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
   
 LogCompOSPRTop =   
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarLogCompOSPRTopID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
   
 LogCompDSPRBottom =   
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarLogCompDSPRBottomID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
   
 LogCompCntrPRBottom =  
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarLogCompCntrPRBottomID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  ),  
   
 LogCompOSPRBottom =  
  (  
  select avg(convert(float,t.result))  
  from dbo.#prsrun tprs  
  join @prodlines pl  
  on tprs.plid = pl.plid  
  join dbo.tests t  
  on t.var_id = pl.VarLogCompOSPRBottomID  
  and t.result_on > tprs.starttime  
  and t.result_on <= tprs.endtime  
  where tprs.id_num = prs.id_num  
  )  
from dbo.#PRsRun prs  
  
update prs SET   
 PerfectPRStatus = ppr.Result  
FROM dbo.#PRsRun prs   
JOIN dbo.tests ppr with (nolock)  
on ppr.Var_Id = prs.varPMPerfectPRStatusId  
and ppr.Result_On = prs.PRTimestamp   
  
update prs SET   
 PerfectPRStatus = t1.Result  
FROM dbo.#PRsRun prs   
join @prodlines pl  
on prs.plid = pl.plid  
JOIN dbo.Tests t with (nolock)   
ON t.Var_Id = pl.varPRIDId   
AND t.Result = prs.GrandParentPRID  
JOIN dbo.Tests t1 with (nolock)  
ON t1.Var_Id = prs.varPMPerfectPRStatusID   
AND t1.Result_On = t.Result_On  
WHERE prs.PerfectPRStatus IS NULL  
  
declare @SelectList varchar(4000)  
  
select @VarList = ''  
select @SelectList = ''  
  
select @VarList = @VarList + '[' + Var_desc + '],'   
from dbo.#DisplayVars  
order by var_order, var_desc  
  
select @SelectList = @SelectList +   
 'avg(case when dv.var_desc = ''' + dv.var_desc    
   + ''' then convert(float,t.result) else null end), '   
from dbo.#DisplayVars dv  
order by var_order, var_desc  
  
exec   
 (  
 'insert dbo.#DisplayResults(' + @VarList + ' [id_num]) select '   
 +  @SelectList   
 + ' prs.id_num  
  from dbo.#PRsRun prs  
  join dbo.#DisplayVarsByUnit dv  
  on prs.prpuid = dv.prpuid  
  join dbo.tests t  
  on dv.var_id = t.var_id  
  where t.result_on = prs.prtimestamp  
  group by prs.id_num  
  '   
 )  
  
-------------------------------------------------------------------------------  
-- --print 'ReturnResultSets: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
ReturnResultSets:      
  
--select 'pl', * from #prodlines  
--select 'pu', * from @produnits  
  
--select 'td', td.*   
--from #delays td  
--where pudesc like 'FF7A Converter%'  
--and stopsblockedstarved > 0  
--and starttime >= '2008-10-27 06:30:00'  
--and starttime <'2008-10-28 06:30:00'   
  
/*  
select parentprid, count(td.starttime) --'td', td.*   
from #delays td  
join #prodlines pl  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid or pl.CvtrBlockedStarvedPUID = td.puid)  
join #prsrun prs  
on prs.puid = pl.prodpuid  
and td.starttime >= prs.starttime  
and (td.starttime < prs.endtime or prs.endtime is null)  
where pudesc like 'FF7A Converter%'  
and stopsblockedstarved > 0  
--and td.starttime >= '2008-10-27 06:30:00'  
--and td.starttime <'2008-10-28 06:30:00'   
group by parentprid  
*/  
  
--select '@PRsRun', * from #PRsRun pr  
--order by puid, starttime, endtime, eventid  
  
-- if there are errors from the parameter validation, then return them and skip the rest of the results  
  
 if (select count(*) from @ErrorMessages) > 0 AND @blnDupPRIDErrors = 0     
  
 begin  
  
  -------------------------------------------------------------------------------  
  -- Error Messages.  
  -------------------------------------------------------------------------------  
  SELECT ErrMsg  
  FROM @ErrorMessages  
  OPTION (KEEP PLAN)  
  
 end  
  
 else  
  
 begin  
  
  -- --print 'RS1: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 1  
 -------------------------------------------------------------------------------  
 -- Error Messages.  
 -------------------------------------------------------------------------------  
  SELECT ErrMsg  
  FROM @ErrorMessages  
  OPTION (KEEP PLAN)  
  
  
 SELECT  
  @RptName         [@RptName],  
  @RptTitle        [@RptTitle],  
  @ProdLineList        [@ProdLineList],  
  COALESCE(@LineStatusList,'All') [@LineStatusList],   
  @UserName        [@RptUser],  
  @RptPageOrientation     [@RptPageOrientation],    
  @RptPageSize       [@RptPageSize],  
  @RptPercentZoom      [@RptPercentZoom],  
  @RptTimeout        [@RptTimeout],  
  @RptFileLocation      [@RptFileLocation],  
  @RptConnectionString     [@RptConnectionString]  
  
 -- --print 'RS2: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 2    
   
-- dv.id_num creates an error if this insert is executed without dynamic SQL.  
-- Rev1.8  
exec('  
 INSERT INTO dbo.#PaperRuns  
 SELECT   
  prs.uws [UWS],  
  prs.parentprid [Parent PRID],  
  prs.PerfectPRStatus [PPR Status],  
  prs.ELPReasonDesc1 [Top ELP Loss Reason],  
  prs.ELPReasonDesc2 [2nd ELP Loss Reason],  
  prs.ELPReasonDesc3 [3rd ELP Loss Reason],  
  prs.starttime [Proll Conv. StartTime],  
  prs.endtime [Proll Conv. EndTime],  
  prs.runtime / 60.0 [Total Proll Runtime (Mins)],  
  prs.elpscheduleddowntime / 60.0 [Excluded Proll Runtime (Mins)],  
  prs.paperruntime / 60.0 [ELP Proll Runtime (Mins)],  
  prs.elpstops [ELP Stops],  
  prs.ELPDowntime / 60.0 [ELP Downtime (Mins)],  
  prs.RLELPDowntime / 60.0 [ELP Rate Loss Eff. Downtime (Mins)],  
   case  
   when COALESCE(prs.PaperRuntime, 0.0) > 0.0  
   then (COALESCE(prs.ELPDowntime, 0.0) + COALESCE(prs.RLELPDowntime, 0.0))   
     / COALESCE(prs.PaperRuntime, 0.0)  
   else 0.0  
   end [ELP %],  
  prs.UnscheduledStopsExcBlockedStarved,  
  prs.BlockedStarvedStops,  
  prs.BedrollSpeed [Bedroll Speed],  
  prs.FeedrollBedrollDraw [Feedroll to Bedroll Draw],  
  prs.CvtrRollWraps [Converter Roll Wraps],  
  prs.WinderBreakouts [Winder Breakouts],  
  prs.BottomUWSTensionSetPnt [Bottom UWS Tension Setpoint],  
  prs.TopUWSTensionSetPnt [Top UWS Tension Setpoint],  
  prs.WndrTensionSetPnt [Winder Tension Setpoint],  
  prs.LogCompDSPRTop [Log Comp DS PR Top],  
  prs.LogCompCntrPRTop [Log Comp Center PR Top],  
  prs.LogCompOSPRTop [Log Comp OS PR Top],  
  prs.LogCompDSPRBottom [Log Comp DS PR Bottom],  
  prs.LogCompCntrPRBottom [Log Comp Center PR Bottom],  
  prs.LogCompOSPRBottom [Log Comp OS PR Bottom],  
  prs.parentpm [ParentPM],  
  prs.parentteam [ParentTeam],  
  prs.prtimestamp [Proll TimeStamp],  
  prs.ageofpr [Age Of PR (Days)],  
  case  
   when prs.ageofpr <= 1.0  
   then ''Fresh''  
   when prs.ageofpr > 1.0  
   then ''Storage''  
   else null  
   end [Fresh or Storage?],  
  prs.grandparentprid [GrandParentPRID],  
  prs.grandparentpm [GrandParentPM],  
  prs.grandparentteam [GrandParentTeam],  
  prs.linestatus [LineStatus],  
  convert(float,prs.starttime) [Numeric StartTime],  
  dr.*  
 FROM dbo.#PRsRun prs  
 left join dbo.#DisplayResults dr  
 on prs.id_num = dr.id_num  
 order by prs.uws, prs.starttime  
 OPTION (KEEP PLAN)  
')  
     
 select @SQL =   
 case  
 when (select count(*) from dbo.#PaperRuns) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#PaperRuns) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#PaperRuns', @LanguageId)   
   + ' order by [UWS],[Proll Conv. StartTime]' --Rev1.97INT  
 end  
  
 EXECUTE sp_executesql @SQL  
  
  
 END  -- to the if (select count(*) from @ErrorMessages) > 0 ... ELSE BEGIN  
  
  
Finished:  
  
 DROP TABLE dbo.#Delays  
 DROP TABLE dbo.#PaperRuns  
 DROP TABLE dbo.#Events  
-- DROP TABLE dbo.#ProdLines  
 drop table dbo.#prsrun  
 drop table dbo.#DisplayVarsByUnit  
 drop table dbo.#DisplayVars  
 drop table dbo.#DisplayResults  
 drop table dbo.#EventStatusTransitions  
  
  
SET NOCOUNT OFF  
  
