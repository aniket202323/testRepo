  /*    
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
-- Version 1.22 Updated: 2009-05-11 by Jeff Jaeger  
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
  
This report is a rewrite of the existing spLocal_RptCvtgMthByDayTeamShift and spLocal_RptCvtgMthByDay.    
The rewrite is intended to simplify the code and make it more efficient.  See previous versions of this stored   
procedure for outdated comments.  
  
This SP works with the template RptCvtgTimeRangeSummary.xlt. Configuration  
report parameters are:  
  
  
-------------------------------------------------------------------  
--The techniques used to optimize this SP are as follows:  
-------------------------------------------------------------------  
  
1. Note that optimizing stored procedures is more an art than a science.  The information listed here is only a set of   
guidelines, not exact rules.  As different techniques are applied, the developer should test the results to see if   
there are any gains in inefficiency.    
2. Use SQL Profiler in Enterprise Manager (under Tools on the menu bar) to track the number of reads, the number of   
writes, and the duration of stored procedures as efficiency enhancements are tested.  These numbers will be a better   
benchmark then just the execution time alone.  
3. Renamed some tables and variables to make them better reflect what they represent.  
4. Replaced creation of #Runs and related tables with the @Dimensions table and @Runs.  Basically, puid and time ranges   
for the various time dimensions are loaded into @Dimensions (along with a name for the dimension and its specific values).    
Then unique puid and starttime combinations are inserted from there into @Runs (without regard to the Dimensions or their   
values).  After that, the various dimensions in the @Runs table are updated according to the time ranges and values in   
@Dimension.  This approach reduces the number of intermediary tables, and it is flexible enough to allow additional   
dimensions to be added easily.  
5. Removed cursors and loops wherever possible.  There are still a few small loops, but I couldn? see a way around them   
without adding more over-head.  The biggest cursor (for populating #ProdRecordsShift) has been eliminated.  In most   
cases, a correlated subquery or a table joined to itself can replace a cursor or loop, although this was not the case   
with #ProdRecordsShift.  It is better (especially over a large dataset) to have an initial insert followed by some   
general update statements,  rather than to loop through a cursor doing various inserts and/or updates one at a time.  
6. When loading a temporary table or table variable with data from a large table in the database, it is sometimes more   
efficient to create an intermediary table that can be populated with a tight range of data from the database.  This   
approach is useful when the original insert statement uses joins to other tables, or there is processing of data as it   
is loaded, or when an insert will join to the same table multiple times.  
7. Wherever possible, use table variables instead of temporary tables.  
8. Created additional table variables such as @ActiveSpecs, @CrewSchedule, etc.  Basically, anytime a real table in the   
database needed to be accessed multiple times, I created a table variable so that in most cases, the real table only   
needs to be hit once.  
9. Updated the indices on temporary tables and table variables.  Each temporary table and table variable now has at   
least a clustered index on the primary key (except in a few cases).  In some cases, the key is compound.  There are   
also some cases where I defined a nonclustered index on an ID field (when other tables will commonly join with the   
given table based on that ID).  
10. When joining tables, keep the order of where clause elements in the same sequence as the primary key sequence to   
whatever extent is possible.  
11. Where possible, use joined tables instead of subqueries.  The need to use ?op?in the select is one case where a   
subquery will be required.  
12. Remove any unused fields from table structures and the code that populates them.  
13. When populating temporary tables and table variables, restrict the data selected as much as possible.    
14. Eliminate any unused variables.  
15. Where possible, remove functions such as coalesce, subqueries, etc., from where clauses.  Using these will keep   
indexes from being applied.  
16. Apply flow control where required, so that temporary tables and table variables are only created and dropped if   
they are actually used.  
17. Use a statement like ?ET @i = (SELECT COUNT(*) FROM dbo.#table)?on all temporary tables before they are   
populated.  
18. Use ?ption (keep plan)?with all select statements to reduce how often statistics are updated.  
19. When referencing a real table or a temporary table, be sure to define the owner in the reference?i.e. ?bo.?  
20. If an insert or update statement uses a nested subquery, try to find another way to do the update.  
21. Instead of using ?xecute?against a query string, use ?xecute sp_executesql?  
22. Run the stored procedure in query analyzer, using the Show Execution Plan option (under Query on the menu bar) to   
identify which actions in the stored procedure are using the highest percentage of resources.  Also look for any SCANs   
that are occurring (as opposed to SEEKs).  These two tactics will help identify the places where the most efficiency   
could be gained.  
23. Recommendation:  about 35% of the processing time in this stored procedure is spent building and populating the   
#Delays table.  Since this table is used in multiple reports, it might be better to replace it with a local table in   
the database, which could be updated periodically with a scheduled DTS package.    
24. Recommendation:  GBDB.dbo.fnLocal_RptTableTranslation requires the use of a temporary table.  It should be   
possible to write a similar function which will take as inputs the name of a table variable, and the fields that need   
to be returned (this could all be one delimited string), and return a query string to be executed.  Then the result set   
temporary tables could be eliminated, thus reducing the number of recompiles.  (This was not implemented in this   
rewrite of the stored procedure because I? told that other approaches to header translation are being investigated).  
  
  
------------------------------------------------------------------  
-- Calculations used in the result sets of this SP:  
------------------------------------------------------------------  
  
Some of the SQL code used to apply calculations gets a bit murky.  Because of this, it might be difficult   
to determine what certain calculations are intended to do.  This section will hopefully add a little clarity   
to the worst cases.  
  
ELP Losses (Mins) = ReportELPDownTime + ReportRLELPDownTime  
  
  
ELP % = ELP Losses (Mins) / Paper Runtime  
Rate Loss % = ReportRLDowntime / Production Time  
  
  
-- Note that how the Runtimes are derived depends on what level its being summed up at.  
Paper Runtime = RunTime - ReportELPSchedDT  
Production Time = Runtime - Holiday Curtail ReportDowntime  
  
  
-- these calculations are carried out as updates to the result sets.  its done this way  
-- for simplicity's sake  
Planned Availability = Split Uptime / (Split Uptime + Unscheduled Rpt DT)  
Unplanned MTBF = Split Uptime / Unscheduled Stops  
Unplanned MTTR = Unscheduled Rpt DT / Unscheduled Stops  
Avg PRoll Change Time = PRPolyC Downtime / PRPolyC Events  
  
  
Avg Stat CLD = ActualUnits * (1440 / ProductionRuntime)  
CVPR % = ActualUnits / TargetUnits  
Operations Efficiency % = ActualUnits / OperationsTargetUnits  
CVTI % = ActualUnits / IdealUnits  
  
  
-- For certain values in Line Summaries (specifically Unscheduled Rpt DT, Raw Uptime, and Split Uptime),  
-- totals across multiple Master Units within a Converting Line are defined as the values for the   
-- Converter Reliability Master Unit.    
-- For totals across multiple Master Units within a Pack Area, the values are defined as the sum of the values   
-- for the individual Master Units.  
  
  
------------------------------------------------------------------  
-- SP sections:  
------------------------------------------------------------------  
  
Additional comments can be found in each section.  
  
Section 1:  Define variables for this procedure.  
Section 2:  Declare the error messages table  
Section 3: Get the input parameter values out of the database  
Section 4: Assign constant values  
Section 5: Create temp tables and table variables  
Section 6: Check Input Parameters to make sure they are valid.  
Section 7: Get local language ID  
Section 8: Initialize temporary tables.  This minimizes recompiles.  
Section 9: Get information about the production lines  
Section 10: Parse the DelayTypeList  
Section 11: Get information for ProdUnitList  
Section 12: Populate @ProdUnitsPack  
Section 13: Get Crew Schedule information  
Section 14: Get Production Starts  
Section 15: Get Products  
Section 16: Get Active Specs  
Section 17: Get Line Production Variables     
Section 18: Get the dimensions to be used  
Section 19: Get the run times and values for each dimension  
Section 20: Populate @RunSummary  
Section 21: Get the Time Event Details  
Section 22: Get the initial set of delays for the report period  
Section 23: Get the first events for each production unit  
Section 24: Additional updates to #Delays  
Section 25: Get the Timed Event Categories for #Delays  
Section 26: Populate @Primaries  
Section 27: Calculate the Statistics for stops information in the #Delays dataset   
Section 28: Get Tests  
Section 29: Update the Rateloss information for #Delays  
Section 30: Populate @ProdRecords  
Section 31: Split the delays and calculate Split Uptime.  
Section 32: Sum of the Split Events data according to production "buckets"  
Section 33: if there are errors, return the Error Message result set  
Section 34: return the empty Error Message result set  
Section 35: Result set 3 - Team Averages  
Section 36: Result set 4 - Line Averages  
Section 37: Result set 5 - Summary of data, without regard to product  
Section 38: Result set 6 - Summary of data, including by Product  
Section 39: Drop temp tables  
  
  
--------------------------------------------------------  
--  Edit History:  
--------------------------------------------------------  
  
2005-10-25 Jeff Jaeger  Rev1.01  
 - updated the SET options according to our latest thinking.  
  
2005-10-25 Jeff Jaeger  Rev1.02  
 - updated the initial insert to #SplitUptime to not use the between statement  
 - changed the update to LineStatus in #SplitUptime to not use the between statement  
  
2005-Nov-07 Namho Kim  Rev1.03  
  In Section 21, where multiple inserts to #TimedEventDetails are being performed, replaced 'SELECT *' with   
  SELECT <specific column names in the JOIN to the subquery on the 'real' Timed_Event_Details table.  
  
2005-11-21 Jeff Jaeger  Rev1.04  
  Changed the summation of productiontime in @TimeRangeSummary to match on puid instead of prodid.  This   
  corrects an overcalculation of the value.  
  
2005-11-30  Langdon Davis Rev1.05  
  Changed PRCEvents and PRCDowntime to a more generic PRPolyCEvents and PRPolyCDowntime, keying  
  off of the PR/Poly Change Schedule ID to identify them instead of 'GroupCause:Parent   
  Roll Changes'.  This was driven by the GroupCause configuration not being standard  
  whereas the PR/Poly Change Schedule is.  Since this report runs only on the converting  
  lines proper, i.e., no wrappers, the results are still just 'Avg PRoll Change Times'.  
  
2005-12-15 Vince King  Rev1.06   
  Modified the Avg PRoll Change Time = PRPolyC Downtime / PRPolyC Events calculation so that   
  PRPolyC Events includes ALL events and not just Stops.  This is so that we capture the split  
  events that are coded as PR Poly Change.  
  
2006-01-19 Namho Kim  Rev1.07  
  Modified Linestatuslist value when a value of Linestatuslist is null or '', put a 'All' in value for Linestatuslist.  
  
2006-MAR-20 Langdon Davis Rev1.08  
  When specs are deleted via the Proficy Admin, the phrase '<Deleted>' shows up preceding the value.  Modified  
  the code to screen these deleted records out when selecting from Active_Specs by checking to see if the  
  value ISNUMERIC.  
  
2006-Jun-14 Namho Kim  Rev1.10  
  TPUnitsflag is added for Neuss.  
  
2006-07-07 Jeff Jaeger  Rev1.11  
  Added code for TargetSpeedxDuration and IdealSpeedxDuration.  Note that while these are not used  
  (neither is LineSpeedAvg), they keep the code consistent with other reports, and don't really add any  
  overhead.  
  
2006-JUL-10 Langdon Davis Rev1.12  
  Added a data integrity step to delete all 0 values for Reports Line Speed from #Tests  
  immediately after it is populated.  
  
2006-JUL-25 Langdon Davis Rev1.13  
  Except for the one associated with RptWindowMaxDays, changed all DATEDIFF uses to seconds UOM to be   
  more accurate.  
  
2006-JUL-25 Langdon Davis Rev1.14  
  Added insert to @ProductionStarts based on prod_units in the @ProdUnitsPack table.  This is   
  necessary to pick up the production starts for the pack production units that do NOT have  
  a corresponding reliability PU.  
  
2007-JUN-01 Langdon Davis Rev1.15  
 Added a parameter check for start and end time being the same.  This avoids a bunch of processing and   
 errors on the VB side from empty/NULL results sets.  
  
2007-06-21 Jeff Jaeger Rev1.16  
 added code for @VarLinespeedMMinVN.  
  
2009-02-18 Jeff Jaeger Rev1.17  
 - note that this sp is not up to date with current methods.  this may have an impact on efficiency.   
 - modified the method for pulling ScheduleID, CategoryID, GroupCauseID, and SubsystemID in #delays.  
 - added "with (nolock)" to the use of tables and temp tables.  
  
2009-03-12 Jeff Jaeger Rev1.18  
 - added z_obs restriction to the population of @produnits  
  
2009-03-18 Jeff Jaeger Rev1.19  
- modified the definitions of various flavors of stops in #Delays  
- modified the definition of SplitUnscheduledDT in #SplitDowntimes  
  
--2009-04-09 Jeff Jaeger Rev1.20  
--  - added a restriction on pu_desc not like '%rate%loss%' in the definition of ReportELPSchedDT.  
  
11-APR-2009 Langdon Davis Rev1.21  
 - Updated 'Planning Target Cases' to 'Planning Target Stat Cases'.  
  
2009-05-11 Jeff Jaeger Rev1.22  
- changed the assignment of NextStartTime in #SplitDowntimes to use a EndTime <= StartTime   
 comparison.  It seems that comparing the record ID values is not robust enough in the   
 latest version of SQL.  
  
----------------------------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------------------------  
*/  
  
CREATE  PROCEDURE dbo.spLocal_RptCvtgTimeRangeSummary  
-- declare  
 @StartTime  DATETIME,  -- Beginning period for the data.  
 @EndTime   DATETIME,  -- Ending period for the data.  
 @RptName   VARCHAR(100) -- Report_Definitions.RP_Name  
  
AS  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON   
  
  
-------------------------------------------------------------------------------  
-- Declare testing parameters.  
-------------------------------------------------------------------------------  
  
-- Testing  
/*  
 SELECT    
 @StartTime = '2009-04-20 05:00:00',   
 @EndTime  = '2009-04-21 05:00:00',   
 @RptName  = --'Bounty MBD MK70 0700 0700'  
      'MBDTS OTT1 Apr 2007'   
*/  
  
----------------------------------------------------------  
-- Section 1:  Define variables for this procedure.  
----------------------------------------------------------  
  
-------------------------------------------------------------------------  
-- Report Parameters. 2005-03-16 VMK Rev8.81  
-------------------------------------------------------------------------  
  
DECLARE   
@ProdLineList     VARCHAR(4000),  -- Collection of Prod_Lines.PL_Id for converting lines delimited by "|".  
@DelayTypeList     VARCHAR(4000),  -- Collection of "DelayType=..." FROM Prod_Units.Extended_Info delimited by "|".  
@CatMechEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
@CatElectEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
@CatProcFailId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
@CatBlockStarvedId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved.  
@CatELPId      INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
@SchedPRPolyId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
@SchedUnscheduledId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
@SchedSpecialCausesId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Special Causes.  
@SchedEOProjectsId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:E.O./Projects.  
@SchedBlockedStarvedId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
@SchedChangeOverId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Changeover.  
@SchedPlnInterventionId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Planned Intervention.  
@SchedHolidayCurtailId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Holiday/Curtail.  
@SchedHygCleaningId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Planned Hygiene/Cleaning.  
@SchedCLAuditsId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Centerline Checks/Audits.  
@PropCvtgProdFactorId  INTEGER,    -- Product_Properties.Prop_Id for Property containing Stat Factor           
@DefaultPMRollWidth   FLOAT,    -- Default PM Roll Width.  Used when actual PM Roll  
               -- Width's are not available through genealogy.  
@ConvertFtToMM     FLOAT,    -- Conversion to change feet to mm., i.e. value is 304.8   
               -- (12 in/ft * 2.54 cm/in * 10 mm/cm) 1 is already using metric.  
@ConvertInchesToMM   FLOAT,    -- Conversion to change inches to millimeters. Value is 25.4 to  
               -- to convert or 1 if already using metric.  
@BusinessType     INTEGER,    -- 1=Tissue/Towel, 2=Napkins, 3=Facial  
@RL1Title      VARCHAR(100),  -- Title to be used for Reason Level 1  
@RL2Title      VARCHAR(100),  -- Title to be used for Reason Level 2  
@RL3Title      VARCHAR(100),  -- Title to be used for Reason Level 3  
@RL4Title      VARCHAR(100),  -- Title to be used for Reason Level 4  
@PackPUIdList     VARCHAR(4000),  -- List of Prod_Units.PU_Ids, FROM a 'Pack' Prod Line, to be included in the Pack Prod sheet.  
@UserName      VARCHAR(30),  -- User calling this report  
@RptTitle      VARCHAR(300),  -- Report title from Web Report.  
@RptPageOrientation   VARCHAR(50),  -- Report Page Orientation from Web Report.  
@RptPageSize     VARCHAR(50),   -- Report page Size from Web Report.  
@RptPercentZoom    INTEGER,    -- Percent Zoom from Web Report.  
@RptTimeout      VARCHAR(100),  -- Report Time from Web Report.  
@RptFileLocation    VARCHAR(300),  -- Report file location from WEb Report.  
@RptConnectionString   VARCHAR(300),  -- Connection String from Web Report.  
@RptGroupBy      INTEGER,    -- Group By parameter from Web Report.  
@LineStatusList    varchar(4000),  -- List of valid Line Status values.  If NULL, use all values.  
@RptWindowMaxDays    INTEGER,    -- Maximum number of days allowed in the date range specified for a given report.  
@IncludeTeam     integer,  
  
------------------------------------------  
-- declare program variables  
------------------------------------------  
@i         INTEGER,  
@ScheduleStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
@CategoryStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
@GroupCauseStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
@SubSystemStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
@DelayTypeRateLossStr  VARCHAR(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
  
@LanguageId      INTEGER,  
@UserId       INTEGER,  
@LanguageParmId    INTEGER,  
  
@SQL        nVARCHAR(4000),  
  
@PacksInBundleSpecDesc  VARCHAR(100),  
@SheetCountSpecDesc   VARCHAR(100),  
@CartonsInCaseSpecDesc  VARCHAR(100),  
@ShipUnitSpecDesc    VARCHAR(100),  
@StatFactorSpecDesc   VARCHAR(100),  
@RollsInPackSpecDesc   VARCHAR(100),  
@SheetWidthSpecDesc   VARCHAR(100),  
@SheetLengthSpecDesc   VARCHAR(100),  
@PacksInBundleSpecId   INTEGER,  
@SheetCountSpecId    INTEGER,  
@CartonsInCaseSpecId   INTEGER,  
@ShipUnitSpecId    INTEGER,  
@StatFactorSpecId    INTEGER,  
@RollsInPackSpecId   INTEGER,  
@SheetWidthSpecId    INTEGER,  
@SheetLengthSpecId   INTEGER,  
  
@PackOrLineStr     varchar(50),  
@VarGoodUnitsVN    varchar(50),  
@VarTotalUnitsVN    varchar(50),  
@VarPMRollWidthVN    varchar(50),  
@VarParentRollWidthVN   varchar(50),  
@VarEffDowntimeVN    varchar(50),  
@VarActualLineSpeedVN   varchar(50),  
@VarStartTimeVN    varchar(50),  
@VarEndTimeVN     varchar(50),  
@VarPRIDVN      varchar(50),  
@VarParentPRIDVN    varchar(50),  
@VarGrandParentPRIDVN  varchar(50),  
@VarUnwindStandVN    varchar(50),  
@VarLineSpeedVN    varchar(50),  
@VarLineSpeedMMinVN   varchar(50),   
@LineProdFactorDesc    varchar(50),  
  
@PPTT        varchar(5),  
@SearchString     VARCHAR(4000),  
@Position      INTEGER,  
@PartialString     VARCHAR(4000),  
  
@PUDelayTypeStr    VARCHAR(100),  
@PUScheduleUnitStr   VARCHAR(100),  
@PULineStatusUnitStr   VARCHAR(100),  
@PRIDRLVarStr     VARCHAR(100),  
      
@VarTypeStr      VARCHAR(50),  
@ACPUnitsFlag     VARCHAR(50),  
@HPUnitsFlag     VARCHAR(50),  
@TPUnitsFlag     VARCHAR(50),  
  
@Row        int,  
@Rows        int,  
@@PUID       int,  
@@StartTime      datetime,  
@Max_TEDet_Id      int,  
@Min_TEDet_Id     int,   
@RangeStartTime    datetime,   
@RangeEndTime     datetime,  
@StagedStatusId    int,  
  
@ScheduleUnit      int,  
  
@LineSpeedTargetSpecDesc  varchar(50),  
@LineSpeedIdealSpecDesc  varchar(50),  
  
@PUEquipGroupStr    VARCHAR(100),  
  
@NoDataMsg       VARCHAR(100),  
@TooMuchDataMsg     VARCHAR(100)  
  
  
----------------------------------------------------------  
-- Section 2:  Declare the error messages table  
----------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Error Messages  
-------------------------------------------------------------------------------  
DECLARE @ErrorMessages TABLE ( ErrMsg VARCHAR(255) )  
  
  
-------------------------------------------------------------------  
-- Section 3: Get the input parameter values out of the database  
-------------------------------------------------------------------  
  
---------------------------------------------------------------------------------------------------  
-- Retrieve parameter values FROM report definition using spCmn_GetReportParameterValue  
---------------------------------------------------------------------------------------------------   
  
IF Len(@RptName) > 0   
BEGIN  
 --PRINT 'Get Report Parameters.'  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPLIdList','',      @ProdLineList OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptDlyTypeList', '',     @DelayTypeList OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPropCvtgProdFactorId','',  @PropCvtgProdFactorId OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptDefaultPMRollWidth','',   @DefaultPMRollWidth OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConvertFtToMM', '',    @ConvertFtToMM OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConvertInchesToMM', '',   @ConvertInchesToMM OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptBusinessType', '',    @BusinessType OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'Owner', '',         @UserName OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptTitle', '',       @RptTitle OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageOrientation', '',   @RptPageOrientation OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageSize', '',      @RptPageSize OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPercentZoom', '',     @RptPercentZoom OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ReportTimeOut', '',      @RptTimeout OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ServerFileLocation', '',    @RptFileLocation OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConnectionString', '',   @RptConnectionString OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptGroupBy', '',      @RptGroupBy OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptLineStatusList', '',    @LineStatusList OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptWindowMaxDays', '',    @RptWindowMaxDays OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptIncludeTeam', '',     @IncludeTeam OUTPUT  
 end  
ELSE     
 BEGIN  
 INSERT  @ErrorMessages (ErrMsg)  
  VALUES ('No Report Name specified.')  
 GOTO ReturnResultSets  
 END   
  
-- 2006-01-19 Rev1.07 Namho Kim  
if (@LineStatusList IS NULL) or (@LineStatusList='')  
SELECT @LineStatusList='All'  
  
--select   
--@ProdLineList = '178',  
--@DelayTypeList = 'CvtrDowntime|RateLoss'  
  
--select @IncludeTeam = 1  
  
  
--------------------------------------------------------------  
-- Section 4: Assign constant values  
--------------------------------------------------------------  
  
select  
@ScheduleStr    = 'Schedule',  
@CategoryStr    = 'Category',  
@GroupCauseStr    = 'GroupCause',  
@SubSystemStr    = 'Subsystem',  
@DelayTypeRateLossStr = 'RateLoss',  
@CatBlockStarvedId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Blocked/Starved'),  
@CatELPId     = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Paper (ELP)'),  
@CatMechEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Mechanical Equipment'),  
@CatElectEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Electrical Equipment'),  
@CatProcFailId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Process/Operational'),  
@SchedPRPolyId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:PR/Poly Change'),  
@SchedUnscheduledId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Unscheduled'),  
@SchedSpecialCausesId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Special Causes'),  
@SchedEOProjectsId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:E.O./Projects'),  
@SchedBlockedStarvedId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Blocked/Starved'),  
@SchedChangeOverId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Changeover'),  
@SchedPlnInterventionId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Planned Intervention'),  
@SchedHolidayCurtailId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Holiday/Curtail'),  
@SchedHygCleaningId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Planned Hygiene/Cleaning'),  
@SchedCLAuditsId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Centerline Checks/Audits'),  
  
@PackOrLineStr    = 'PackOrLine=',  
@VarGoodUnitsVN   = 'Good Units',  
@VarTotalUnitsVN   = 'Total Units',  
@VarPMRollWidthVN   = 'PM Roll Width',  
@VarParentRollWidthVN  = 'Parent Roll Width',  
@VarEffDowntimeVN   = 'Effective Downtime',  
@VarActualLineSpeedVN  = 'Line Actual Speed',  
@VarStartTimeVN   = 'Roll Conversion Start Date/Time',  
@VarEndTimeVN    = 'Roll Conversion End Date/Time',  
@VarPRIDVN     = 'PRID',  
@VarParentPRIDVN   = 'Parent PRID',  
@VarGrandParentPRIDVN = 'Grand Parent PRID',  
@VarUnwindStandVN   = 'Unwind Stand',  
@VarLineSpeedVN   = 'Reports Line Speed',  
@VarLineSpeedMMinVN  = 'Reports Line Speed (m/min)',   
@LineProdFactorDesc   = 'Production Factors',  
  
@PUDelayTypeStr    = 'DelayType=',  
@PUScheduleUnitStr  = 'ScheduleUnit=',  
@PULineStatusUnitStr  = 'LineStatusUnit=',  
@PRIDRLVarStr     = 'Rate Loss PRID',  
    
@VarTypeStr     = 'VarType=',  
@ACPUnitsFlag    = 'ACPUnits',  
@HPUnitsFlag    = 'HPUnits',  
@TPUnitsFlag    = 'TPUnits',  
  
@StatFactorSpecDesc   = 'Stat Factor',  
@PacksInBundleSpecDesc  = 'Packs In Bundle',   
@SheetCountSpecDesc   = 'Sheet Count',  
@SheetWidthSpecDesc   = 'Sheet Width',  
@SheetLengthSpecDesc  = 'Sheet Length',  
  
@CartonsInCaseSpecDesc  =  CASE @BusinessType  
         WHEN 4   
         THEN 'Bundles In Case'   
         ELSE 'Cartons In Bundle'   
         END,  
  
@RollsInPackSpecDesc  =  CASE @BusinessType  
         WHEN 1   
         THEN 'Rolls In Pack'  
         WHEN 2   
         THEN 'Packs In Pack'  
         WHEN 3   
         THEN 'Rolls In Pack'  
         ELSE 'Rolls In Pack'   
         END,  
  
@ShipUnitSpecDesc   = 'Ship Unit',  
  
@LineSpeedTargetSpecDesc  = 'Line Speed Target',  
@LineSpeedIdealSpecDesc  = 'Line Speed Ideal',  
  
@PUEquipGroupStr   = 'EquipGroup=',  
  
@NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId),  
@TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
IF @BusinessType = 3  
  
 select @PPTT = 'PP '  
else  
 select @PPTT = 'TT '  
  
  
----------------------------------------------------------------------------------  
----------------------------------------------------------------------------------  
-- Section 5: Create temp tables and table variables  
----------------------------------------------------------------------------------  
----------------------------------------------------------------------------------  
  
------------------------------------------------------------------  
-- this table will hold Prod Lines data  
-----------------------------------------------------------------  
  
DECLARE @ProdLines TABLE   
 (  
 PLId             int primary key,  
 PLDesc            VARCHAR(50),  
 ProdPUID            integer,  
 ReliabilityPUID         integer,  
 RatelossPUID          integer,  
 PackOrLine           varchar(5),  
 VarGoodUnitsId          INTEGER,  
 VarTotalUnitsId         INTEGER,  
 VarPMRollWidthId         INTEGER,  
 VarParentRollWidthId        INTEGER,  
 PropLineProdFactorId        INTEGER,  
 VarEffDowntimeId         INTEGER,  
 TotalStops           INTEGER,  
 TotalUptime           INTEGER,  
 TotalDowntime          INTEGER,  
 TotalStopsUTGT2Min        INTEGER,  
 VarActualLineSpeedId        INTEGER,  
 VarLineSpeedId          INTEGER,  
 Extended_Info          varchar(225)--,  
 )   
  
  
DECLARE @DelayTypes TABLE   
 (  
 DelayTypeDesc          VARCHAR(100) PRIMARY KEY  
 )  
  
  
-----------------------------------------------------------------------  
-- this table will hold Prod Units data for Converting lines  
-----------------------------------------------------------------------  
  
DECLARE @ProdUnits TABLE   
 (  
 PUId             INTEGER PRIMARY KEY,  
 PUDesc            VARCHAR(100),  
 PLId             INTEGER,  
 ExtendedInfo          VARCHAR(255),  
 DelayType           VARCHAR(100),  
 ScheduleUnit          INTEGER,  
 LineStatusUnit          INTEGER,  
 UWS1             VARCHAR(50),  
 UWS2             VARCHAR(50),  
 PRIDRLVarId           INTEGER,  
 RowId             INTEGER IDENTITY  
 )  
  
  
---------------------------------------------------------------  
-- this table will hold Prod Unit data for Pack lines  
--------------------------------------------------------------  
  
DECLARE @ProdUnitsPack TABLE   
 (  
 PUId             INTEGER,  
 PUDesc            varchar(100),   
 PLId             INTEGER,  
 PLDesc            VARCHAR(50),    
 GoodUnitsVarId          INTEGER,  
 ScheduleUnit          INTEGER,  
 UOM             VARCHAR(25)  
 primary key (GoodUnitsVarid, puid)  
 )  
  
  
-------------------------------------------------------------------  
-- This table will hold production variable ID data for each Line  
------------------------------------------------------------------  
  
DECLARE @LineProdVars TABLE   
 (  
 PLId             INTEGER,  
 PUId             INTEGER,  
 VarId             INTEGER,  
 VarType            VARCHAR(25)  
 PRIMARY KEY (plid, varid)  
 )  
  
  
----------------------------------------------------------------------------------------------  
-- @Dimensions holds information about the various criteria by which our time will be split  
----------------------------------------------------------------------------------------------  
  
declare @Dimensions table  
 (  
 Dimension           varchar(50),  
 Value             varchar(50),  
 StartTime           datetime,  
 EndTime            datetime,  
 PLID             int,  
 PUID             int  
 )  
  
  
----------------------------------------------------------------------------------  
-- @Runs will be the final production runs, as split by the dimensions  
----------------------------------------------------------------------------------  
  
declare @Runs table  
 (  
 PLID             integer,  
 PUID             integer,  
 Shift             varchar(10),   
 Team             varchar(10),   
 DayStart            varchar(15),  
 ProdId            integer,  
 TargetSpeed           float,  
 IdealSpeed           float,  
 LineStatus           varchar(50),  
 -- add any additional dimensions that are required  
 StartTime           datetime,  
 EndTime            datetime  
 primary key (puid, starttime)  
 )  
  
  
----------------------------------------------------------------------  
-- @RunSummary will summarize the data from @Runs  
-- the dimensions in this table need to be the same as in @Runs  
----------------------------------------------------------------------  
  
DECLARE @RunSummary TABLE   
 (  
 PLId             INTEGER,   
 puid             int,  -- 6/24  
 Shift             INTEGER,  
 Team             VARCHAR(10),  
 DayStart            varchar(15),  
 ProdId            INTEGER,  
 TargetSpeed           float,  
 IdealSpeed           float,  
 LineStatus           varchar(50),  
 -- add any additional dimensions that are required  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 Duration            FLOAT,   
 TgtSpeedxDuration         FLOAT,  
 IdealSpeedxDuration        FLOAT  
 primary key (puid, starttime)   
 )  
  
  
---------------------------------------------------------------------------------  
-- @FirstEvents will hold the delays for each pu that precede the report window  
---------------------------------------------------------------------------------  
  
DECLARE @FirstEvents TABLE   
 (   
 FirstEventId          int IDENTITY,  
 PUId             INTEGER,  
 StartTime           DATETIME  
 primary key (puid, starttime)  
 )  
  
  
-------------------------------------------------------------------------------  
--  this table will hold production summaries by shift, team, and product.  
-- this information will later be used to split the downtime events.  
-------------------------------------------------------------------------------  
  
DECLARE @ProdRecords TABLE   
 (  
 PLId             INTEGER,  
 PUID             int,  
 ReliabilityPUID         int,   
 Shift             VARCHAR(50),  
 Team             VARCHAR(50),  
 DayStart            varchar(15),  
 ProdId           INTEGER,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 TotalUnits           INTEGER,  
 GoodUnits           INTEGER,  
 RejectUnits           INTEGER,  
 WebWidth            FLOAT,  
 SheetWidth           FLOAT,  
 LineSpeedIdeal          FLOAT,  
 LineSpeedTarget         FLOAT,  
 LineSpeedAvg          FLOAT,  
 TargetLineSpeed         FLOAT,    
 LineStatus           varchar(50),  
 RollsPerLog           INTEGER,  
 RollsInPack           INTEGER,  
 PacksInBundle          INTEGER,  
 CartonsInCase          INTEGER,  
 SheetCount           INTEGER,  
 ShipUnit            INTEGER,  
 CalendarRuntime         FLOAT,  
 ProductionRuntime         FLOAT,  
 PlanningRuntime         FLOAT,  
 OperationsRuntime         FLOAT,  
 SheetLength           FLOAT,  
 OperationsTargetUnits       INTEGER,  
 HolidayCurtailDT         FLOAT,  
 PlninterventionDT         FLOAT,  
 ChangeOverDT          FLOAT,  
 HygCleaningDT          FLOAT,  
 EOProjectsDT          FLOAT,  
 UnscheduledDT          FLOAT,  
 CLAuditsDT           FLOAT,  
 ActualUnits           INTEGER,  
 TargetUnits           float,  
 IdealUnits           INTEGER,   
 Duration            FLOAT,   
 TgtSpeedxDuration         FLOAT,   
 IdealSpeedxDuration        FLOAT,  
 StatFactor           FLOAT,  
 RollWidth2Stage         float,  
 RollWidth3Stage         float,  
 PlanningTargetUnits        int  
 primary key (puid, starttime)   
 )  
  
  
---------------------------------------------------------------  
-- @ProductionStarts will hold the Production Starts information  
-- along with related product information  
---------------------------------------------------------------  
  
declare @ProductionStarts table  
 (  
 Start_Time           datetime,  
 End_Time            datetime,  
 Prod_ID            int,  
 Prod_Code           varchar(50),  
 Prod_Desc           varchar(50),  
 PU_ID             int--,  
 primary key (pu_id, prod_id, start_time)  
 )  
  
  
------------------------------------------------------------------  
-- @Products will hold product information, as derived from  
-- @ProductionStarts  
-------------------------------------------------------------------  
  
declare @Products table  
 (  
 Prod_ID            int primary key,  
 Prod_Code           varchar(50),  
 Prod_Desc           varchar(50)--,  
 )  
  
---------------------------------------------------------------------------  
-- this table will hold active specification information, as related to  
-- characteristics, specifications, and properties.  
----------------------------------------------------------------------------  
  
declare @ActiveSpecs table  
 (  
 effective_date          DATETIME,  
 expiration_date         datetime,  
 prod_id            int,   
 char_id            int,  
 char_desc           varchar(50),  
 spec_id            int,  
 spec_desc           varchar(50),  
 prop_id            int,  
 prop_desc           varchar(50),  
 target            varchar(50)--,  
 primary key (prod_id, effective_date, expiration_date, char_id, spec_id, prop_id)  
 )  
  
  
----------------------------------------------------------------------------------  
-- @CrewSchedule will hold information pertaining to the crew and shift schedule  
---------------------------------------------------------------------------------  
  
declare @CrewSchedule table  
 (  
 Start_Time           datetime,  
 End_Time            datetime,  
 pu_id             int,  
 Crew_Desc           varchar(10),  
 Shift_Desc           varchar(10)--,  
 primary key (pu_id, start_time)  
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
  
  
------------------------------------------------------------------  
-- @Primaries will contain the primary events associated with   
-- entries in #delays.  
------------------------------------------------------------------  
  
declare @Primaries table  
 (  
 TEDetId            int, -- PRIMARY KEY clustered,  
 PUId             INTEGER,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 UpTime            INTEGER,  
 TEPrimaryId           INTEGER IDENTITY PRIMARY KEY,  
 UNIQUE (TEDetId))  
  
  
---------------------------------------------------------------------------  
-- this table is used to summarize data according to shift and product  
--------------------------------------------------------------------------  
  
declare @TimeRangeSummary table  
 (  
 PLId             int,  
 puid             int,  
 Prodid            int,  
 ProdCode            varchar(25),  
 ProdDesc            varchar(100),  
 ScheduleUnit          int,  
 StartTime           datetime,  
 EndTime            datetime,  
 shift_starttime         datetime,  
 Team             varchar(50),  
 Shift             varchar(10), --int,  
 DayStart            varchar(15),  
 ProductionRuntime         float,  
 SplitDowntime          float,  
 SplitSchedDowntime        float,  
 RateLossELPDT          float,  
 SplitUptime           float,  
 TotalStops           float,  
 MinorStops           float,  
 EquipFails           float,  
 MinorBD            float,  
 ModerateBD           float,  
 MajorBD            float,  
 ProcessFailures         float,  
 MinorPF            float,  
 ModeratePF           float,  
 MajorPF            float,  
 ELPStops            float,  
 SplitELPDowntime         float,  
 RateLossStops          float,  
 RateLossDT           float,  
 TotalUnits           float,  
 GoodUnits           float,  
 RejectUnits           float,  
 ActualCases           float,  
 TargetCases           float,  
 IdealCases           float,  
 OperationsTargetUnits       float,  
 PlanningTargetUnits        float,  
 PaperRuntime          float,  
 ExtraShift           int,    
 UnscheduledStops         float,  
 UnscheduledSplitDT        float,  
 RawUptime           float,  
 RawDowntime           float,  
 PRPolyCEvents           int,  
 PRPolyCDowntime           float  
 )  
  
  
----------------------------------------------------------------------------------  
-- #delays are the downtime events that need to be tracked for the report.  
---------------------------------------------------------------------------------  
  
CREATE TABLE dbo.#Delays   
 (  
 TEDetId            int PRIMARY KEY nonCLUSTERED,  
 PrimaryId           INTEGER,  
 SecondaryId           INTEGER,  
 PUId             INTEGER,  
 PLID             INTEGER,  
 PUDesc            VARCHAR(100),  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 L1ReasonID           int,  
 LocationId           INTEGER,  
 TEFaultId           INTEGER,  
 ERTD_ID            int,  
 L1TreeNodeId          INTEGER,  
 L2TreeNodeId          INTEGER,  
 L3TreeNodeId          INTEGER,  
 L4TreeNodeId          INTEGER,  
 ScheduleId           INTEGER,  
 CategoryId           INTEGER,  
 GroupCauseId          INTEGER,  
 SubSystemId           INTEGER,  
 DownTime            float,  
 SplitDowntime          float,  
 UpTime            float,  
 Stops             INTEGER,  
 StopsUnscheduled         INTEGER,  
 Stops2m            INTEGER,  
 StopsMinor           INTEGER,  
 StopsEquipFails         INTEGER,  
 StopsProcessFailures        INTEGER,  
 StopsELP            INTEGER,  
 ReportELPDowntime         float,  
 StopsBlockedStarved        INTEGER,  
 ReportELPSchedDT         float,  
 StopsRateLoss          INTEGER,  
 RateLossInWindow         FLOAT,  
 RateLossRatio          FLOAT,  
 RateLossPRID          VARCHAR(50),  
 LineTargetSpeed         FLOAT,  
 LineActualSpeed         FLOAT,  
 InRptWindow           int  
 )  
  
CREATE CLUSTERED INDEX td_PUId_StartTime  
 ON dbo.#Delays (puid, starttime, endtime)  
  
  
--------------------------------------------------------------------  
-- This is an intermediary table that will be used to compile the   
-- basic information in #delays.  
--------------------------------------------------------------------  
  
create table dbo.#TimedEventDetails  
 (  
 TEDet_ID            int PRIMARY KEY NONCLUSTERED,  
 Start_Time           datetime,  
 End_Time            datetime,  
 PU_ID             int,  
 Source_PU_Id          int,  
 Reason_Level1          int,  
 Reason_Level2          int,  
 Reason_Level3          int,  
 Reason_Level4          int,  
 TEFault_Id           int,  
 ERTD_ID            int  
 )  
  
CREATE CLUSTERED INDEX ted_TEDetId_ERCId  
 ON dbo.#TimedEventDetails (pu_id, start_time, end_time)  
  
  
------------------------------------------------------------------------  
-- This table will hold test related information for cvtg and rate loss  
-----------------------------------------------------------------------  
  
CREATE TABLE dbo.#Tests   
 (  
 VarId             INTEGER,  
 PLId             INTEGER,  
 PUId             INTEGER,  
 ProdId            INTEGER,  
 ProdCode            VARCHAR(25),  
 Value             varchar(25),  
 nValue            varchar(25),  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 UOM             varchar(50)--,  
 primary key (varid, starttime)  
 )  
  
  
---------------------------------------------------------------  
--  #SplitEvents will split the #delays information according   
-- to changes in @ProductionRunsShift  
---------------------------------------------------------------  
  
------------------------------------------------------------------  
-- Note:  except for a few additions, this temp table has the same   
-- structure as #SplitEvents in DDS Stops.  This allows the code   
-- to remain consistant.  However, there are fields in this table   
-- that are not needed for this report.  When time permits, these   
-- fields *could* be removed to enhance the efficiency of the stored   
-- procedure by some small degree. Also, the "comment" field has   
-- already been removed because populating it creates a fairly   
-- large hit to efficiency.  
------------------------------------------------------------------  
  
CREATE TABLE  dbo.#SplitEvents   
 (  
 seid             int IDENTITY,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 NextStartTime          datetime,  
 ProdId            INTEGER,  
 PLID             INTEGER,  
 PUId             INTEGER,  
 pudesc            VARCHAR(100),  
 Shift             VARCHAR(10),  
 Team             VARCHAR(10),  
 DayStart            varchar(15),  
 PrimaryId           INTEGER,  
 TEDetId            INTEGER,   
 TEFaultId           INTEGER,  
 ScheduleId           INTEGER,  
 CategoryId           INTEGER,  
 SubSystemId           INTEGER,  
 GroupCauseId          INTEGER,  
 LocationId           INTEGER,  
 LineStatus           VARCHAR(50),  
 Downtime            FLOAT,  
 SplitDowntime          FLOAT,  
 ReportRLDowntime         FLOAT,  
 RateLossInWindow         FLOAT,  
 Uptime            FLOAT,  
 SplitUptime           FLOAT,  
 RateLossRatio          FLOAT,  
 Stops             INTEGER,  
 StopsUnscheduled         INTEGER,  
 StopsMinor           INTEGER,  
 StopsEquipFails         INTEGER,  
 StopsProcessFailures        INTEGER,  
 StopsBlockedStarved        INTEGER,  
 StopsELP            INTEGER,  
 StopsRateLoss          INTEGER,  
 MinorEF            INTEGER,  
 ModerateEF           INTEGER,  
 MajorEF            INTEGER,  
 MinorPF            INTEGER,  
 ModeratePF           INTEGER,  
 MajorPF            INTEGER,  
 Causes            INTEGER,  
 ReportELPDowntime         FLOAT,  
 ReportELPSchedDT         FLOAT,  
 ReportRLELPDowntime        FLOAT,  
 LineTargetSpeed         FLOAT,  
 LineActualSpeed         FLOAT,  
 LineIdealSpeed          FLOAT,  
 ProductionRuntime         float,  
 PaperRuntime          float,  
 OperationsTargetUnits       float, --int,  
 PlanningTargetUnits        float, --int,  
 UnscheduledRptDT         float  
 primary key (puid, starttime, endtime)  
 )  
  
CREATE nonCLUSTERED INDEX se_seid  
 ON dbo.#SplitEvents (seid)  
  
  
---------------------------------------------------------------  
-- Once downtime events have been split, we can account for   
-- periods of uptime.  this table will hold that information.  
--------------------------------------------------------------  
  
CREATE TABLE  dbo.#SplitUptime   
 (  
 suid             INTEGER,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 ProdId            INTEGER,  
 PLID             INTEGER,  
 PUId             INTEGER,  
 pudesc            VARCHAR(100),  
 Shift             VARCHAR(10),  
 Team             VARCHAR(10),  
 DayStart            varchar(15),  
 LineTargetSpeed         int,  
 LineIdealSpeed          int,  
 SplitUptime           FLOAT,  
 LineStatus           VARCHAR(50)  
 primary key (puid, starttime, endtime)  
 )  
  
CREATE nonCLUSTERED INDEX su_suid  
 ON dbo.#SplitUptime (suid)  
  
  
 Create table dbo.#TeamAverages  
  (  
  [Team Averages]         varchar(1),  
  [Team]            varchar(10),  
  [Total Shifts]         int,  
  [Production Time (hrs)]      float,  
  [Total Stops]          int,  
  [Stops Per MSU]         float,  
  [Unscheduled Stops]       int,  
  [Minor Stops]          int,  
  [Equipment Failures]       int,  
  [Process Failures]        int,  
  [Raw Downtime]         float,  
  [Split Downtime]         float,  
  [Unscheduled Split DT]      float,  
  [Raw Uptime]         float,  
  [Split Uptime]         float,  
  [Planned Availability]       float,  
  [Unplanned MTBF]        float,  
  [Unplanned MTTR]        float,  
  [CVPR %]           float,  
  [ELP Stops]          int,  
  [ELP Losses (Min)]       float,  
  [ELP %]            float,  
  [Rate Loss Events]        int,  
  [Rate Loss Effective Downtime]   float,  
  [Rate Loss %]          float,  
  [Total Units]          int,  
  [Good Units]          int,  
  [Reject Units]         int,  
  [Unit Broke %]         float,  
  [Actual Stat Cases]        int,  
  [Reliability Target Stat Cases]    int,  
  [Operations Efficiency %]      float,  
  [Operations Target Stat Cases]    int,  
  [Planning Efficiency %]      float,  
  [Planning Target Stat Cases]     int,  
  [Minor Equipment Failures]     int,  
  [Moderate Equipment Failures]    int,  
  [Major Equipment Failures]     int,  
  [Minor Process Failures]      int,  
  [Moderate Process Failures]     int,  
  [Major Process Failures]      integer,  
  [Avg PRoll Change Time]      float,  
  [CVTI %]           float  
  )  
  
  
 Create table dbo.#LineAverages  
  (  
  [Line Averages]         varchar(15),  
  [Team]            varchar(10),  
  [Total Shifts]         int,  
  [Run Hours]          float,  
  [Total Stops]          int,  
  [Stops Per MSU]         float,  
  [Unscheduled Stops]       int,  
  [Minor Stops]          int,  
  [Equipment Failures]       int,  
  [Process Failures]        int,  
  [Raw Downtime]         float,  
  [Split Downtime]         float,  
  [Unscheduled Split DT]      float,  
  [Raw Uptime]         float,  
  [Split Uptime]         float,  
  [Planned Availability]       float,  
  [Unplanned MTBF]        float,  
  [Unplanned MTTR]        float,  
  [CVPR %]           float,  
  [ELP Stops]          int,  
  [ELP Losses (Mins)]       float,  
  [ELP %]            float,  
  [RateLoss Events]        int,  
  [Rate Loss Effective Downtime]   float,  
  [RateLoss %]          float,  
  [Total Units]          int,  
  [Good Units]          int,  
  [Reject Units]         int,  
  [Unit Broke %]         float,  
  [Actual Stat Cases]        int,  
  [Reliability Target Stat Cases]    int,  
  [Operations Efficiency %]      float,  
  [Operations Target Stat Cases]    int,  
  [Planning Efficiency %]      float,  
  [Planning Target Stat Cases]    int,  
  [Minor Equipment Failures]     int,  
  [Moderate Equipment Failures]    int,  
  [Major Equipment Failures]     int,  
  [Minor Process Failures]      int,  
  [Moderate Process Failures]     int,  
  [Major Process Failures]      integer,      
  [Avg PRoll Change Time]      float,  
  [CVTI %]           float  
  )  
  
  
 Create table dbo.#AllProducts  
  (  
  [Day]            varchar(10),  
  [Team]            varchar(10),  
  [Shift]            varchar(10),  
  [Production Time (hrs)]      float,  
  [Total Stops]          int,  
  [Stops Per MSU]         float,  
  [Unscheduled Stops]       int,  
  [Minor Stops]          int,  
  [Equipment Failures]       int,  
  [Process Failures]        int,  
  [Raw Downtime]         float,  
  [Split Downtime]         float,  
  [Unscheduled Split DT]      float,  
  [Raw Uptime]         float,  
  [Split Uptime]         float,  
  [Planned Availability]      float,  
  [Unplanned MTBF]        float,  
  [Unplanned MTTR]        float,  
  [CVPR %]           float,  
  [ELP Stops]          int,  
  [ELP Losses (Min)]       float,  
  [ELP %]            float,  
  [Rate Loss Events]        int,  
  [Rate Loss Effective Downtime]   float,  
  [Rate Loss %]          float,  
  [Total Units]          int,  
  [Good Units]          int,  
  [Reject Units]         int,  
  [Unit Broke %]         float,  
  [Actual Stat Cases]        int,  
  [Reliability Target Stat Cases]    int,  
  [Operations Efficiency %]      float,  
  [Operations Target Stat Cases]    int,  
  [Planning Efficiency %]      float,  
  [Planning Target Stat Cases]     int,  
  [Minor Equipment Failures]     int,  
  [Moderate Equipment Failures]    int,  
  [Major Equipment Failures]     int,  
  [Minor Process Failures]      int,  
  [Moderate Process Failures]     int,  
  [Major Process Failures]      integer,      
  [Avg PRoll Change Time]      float,  
  [CVTI %]           float  
  )  
  
  
 Create table dbo.#ByProduct  
  (  
  [Product]          varchar(25),  
  [Prod Desc]          varchar(50),  
  [Day]            varchar(10),  
  [Team]            varchar(10),  
  [Shift]            varchar(10),  
  [Production Time (hrs)]      float,  
  [Total Stops]          int,  
  [Stops Per MSU]         float,  
  [Unscheduled Stops]       int,  
  [Minor Stops]          int,  
  [Equipment Failures]       int,  
  [Process Failures]        int,  
  [Raw Downtime]         float,  
  [Split Downtime]         float,  
  [Unscheduled Split DT]      float,  
  [Raw Uptime]         float,  
  [Split Uptime]         float,  
  [Planned Availability]      float,  
  [Unplanned MTBF]        float,  
  [Unplanned MTTR]        float,  
  [CVPR %]           float,  
  [ELP Stops]          int,  
  [ELP Losses (Mins)]       float,  
  [ELP %]            float,  
  [Rate Loss Events]        int,  
  [Rate Loss Effective Downtime]   float,  
  [Rate Loss %]          float,  
  [Total Units]          int,  
  [Good Units]          int,  
  [Reject Units]         int,  
  [Unit Broke %]         float,  
  [Actual Stat Cases]        int,  
  [Reliability Target Stat Cases]    int,  
  [Operations Efficiency %]      float,  
  [Operations Target Stat Cases]    int,  
  [Planning Efficiency %]      float,  
  [Planning Target Stat Cases]     int,  
  [Minor Equipment Failures]     int,  
  [Moderate Equipment Failures]    int,  
  [Major Equipment Failures]     int,  
  [Minor Process Failures]      int,  
  [Moderate Process Failures]     int,  
  [Major Process Failures]      integer,      
  [Avg PRoll Change Time]      float,  
  [CVTI %]           float  
  )  
  
  
-------------------------------------------------------------------------------  
-- Section 6: Check Input Parameters to make sure they are valid.  
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
  
-- If the endtime is in the future, set it to current day.  This prevent zero records FROM being printed on report.  
IF @EndTime > GetDate()  
 BEGIN  
 SELECT @EndTime = CONVERT(VARCHAR(4),YEAR(GetDate())) + '-' + CONVERT(VARCHAR(2),MONTH(GetDate())) + '-' +   
     CONVERT(VARCHAR(2),DAY(GetDate())) + ' ' + CONVERT(VARCHAR(2),DATEPART(hh,GetDate())) + ':' +   
     CONVERT(VARCHAR(2),DATEPART(mi,GetDate()))+ ':' + CONVERT(VARCHAR(2),DATEPART(ss,GetDate()))  
 END  
  
IF coalesce(@RptWindowMaxDays,0) = 0  
 BEGIN  
 SELECT @RptWindowMaxDays = 32  
 END  
  
IF DATEDIFF(d, @StartTime,@EndTime) > @RptWindowMaxDays  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('The date range selected exceeds the maximum allowed for this report: ' + CONVERT(VARCHAR(50),@RptWindowMaxDays) +  
      '.  Decrease the date range or see your Proficy SSO for help.')  
 GOTO ReturnResultSets  
 END  
  
IF @StartTime = @EndTime  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('The date range selected for this report has the same start and end date: ' + convert(varchar(25),@StartTime,107) +  
      ' through ' + convert(varchar(25),@EndTime,107))  
 GOTO ReturnResultSets  
 END  
  
-------------------------------------------------------------------------------  
-- Section 7: Get local language ID  
-------------------------------------------------------------------------------  
  
SELECT   
@LanguageParmId  = 8,  
@LanguageId   = NULL  
  
SELECT @UserId = User_Id  
FROM dbo.Users with (nolock)   
WHERE UserName = @UserName  
  
SELECT @LanguageId =   
  CASE WHEN isnumeric(LTRIM(RTRIM(Value))) = 1   
    THEN CONVERT(FLOAT, LTRIM(RTRIM(Value)))  
    ELSE NULL  
    END  
FROM dbo.User_Parameters with (nolock)   
WHERE User_Id = @UserId  
AND Parm_Id = @LanguageParmId  
  
IF coalesce(@LanguageId,-1) = -1  
 BEGIN  
 SELECT @LanguageId =   
    CASE WHEN isnumeric(LTRIM(RTRIM(Value))) = 1   
      THEN CONVERT(FLOAT, LTRIM(RTRIM(Value)))  
      ELSE NULL  
      END  
 FROM dbo.Site_Parameters with (nolock)   
 WHERE Parm_Id = @LanguageParmId  
  
 IF coalesce(@LanguageId,-1) = -1  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
  
-- 2004-12-20 JSJ assigned values used for > 65000 checks  
SELECT @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
SELECT @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
---------------------------------------------------------------------------------------------------  
-- Section 8: Initialize temporary tables.  This minimizes recompiles.  
---------------------------------------------------------------------------------------------------  
/*  
SET @i = (SELECT COUNT(*) FROM dbo.#delays)  
SET @i = (SELECT COUNT(*) FROM dbo.#TimedEventDetails)  
SET @i = (SELECT COUNT(*) FROM dbo.#tests)  
SET @i = (SELECT COUNT(*) FROM dbo.#SplitEvents)  
SET @i = (SELECT COUNT(*) FROM dbo.#SplitUptime)  
SET @i = (SELECT COUNT(*) FROM dbo.#TeamAverages)  
SET @i = (SELECT COUNT(*) FROM dbo.#LineAverages)  
SET @i = (SELECT COUNT(*) FROM dbo.#AllProducts)  
SET @i = (SELECT COUNT(*) FROM dbo.#ByProduct)  
*/  
  
------------------------------------------------------------  
-- Section 9: Get information about the production lines  
------------------------------------------------------------  
  
-- pull in prod lines that have an ID in the list  
insert @ProdLines   
 (  
 PLID,   
 PLDesc,  
 Extended_Info)  
select   
 PL_ID,   
 PL_Desc,  
 Extended_Info  
from dbo.prod_lines with (nolock)   
where charindex('|' + convert(varchar,pl_id) + '|','|' + @ProdLineList + '|') > 0  
option (keep plan)  
  
  
-- if the list is empty, then get all prod lines  
IF (SELECT count(PLId) FROM @ProdLines) = 0  
 BEGIN  
  INSERT @ProdLines (PLId,PLDesc, Extended_Info)  
  SELECT PL_Id, PL_Desc, Extended_Info  
  FROM  dbo.Prod_Lines with (nolock)   
  option (keep plan)  
 END  
  
-- get the ID of the Converter Production unit associated with each line.  
update pl set  
 ProdPUID = pu_id  
from @ProdLines pl  
join dbo.Prod_Units pu with (nolock)   
on pl.plid = pu.pl_id  
where pu_desc like '%Converter Production%'  
  
-- PackOrLine is used for grouping in the result sets and to restrict data in some where clauses  
update pl set  
 PackOrLine = GBDB.dbo.fnLocal_GlblParseInfo(pl.Extended_Info, @PackOrLineStr)  
from @ProdLines pl  
  
  
-- get the ID of the Converter Reliability unit associated with each line.  
update pl set  
 ReliabilityPUID = pu_id  
from @ProdLines pl  
join dbo.Prod_Units pu with (nolock)   
on pl.plid = pu.pl_id  
where pu_desc like '%Converter Reliability%'  
  
  
-- get the ID of the Rate Loss unit associated with each line.  
update pl set  
 RatelossPUID = pu_id  
from @ProdLines pl  
join dbo.Prod_Units pu with (nolock)   
on pl.plid = pu.pl_id  
where pu_desc like '%Rate Loss%'  
  
  
-- get the following variable IDs associated with the line  
update pl set  
 VarGoodUnitsId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarGoodUnitsVN),  
 VarTotalUnitsId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarTotalUnitsVN),  
 VarPMRollWidthId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarPMRollWidthVN),  
 VarParentRollWidthId  = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarParentRollWidthVN),  
 VarEffDowntimeId    = GBDB.dbo.fnLocal_GlblGetVarId(RateLossPUId,  @VarEffDowntimeVN),  
 VarActualLineSpeedId  = GBDB.dbo.fnLocal_GlblGetVarId(RateLossPUId,  @VarActualLineSpeedVN),  
-- VarLineSpeedId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarLinespeedVN)  
  
 VarLineSpeedId    =   
         coalesce(  
            GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,@VarLinespeedMMinVN),  
            GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,@VarLinespeedVN)  
            )  
  
from @ProdLines pl  
where PackOrLine = 'Line'  
  
  
-- get the Line Prod Factor  
update @ProdLines set   
 PropLineProdFactorId = Prop_Id  
FROM dbo.Product_Properties with (nolock)   
WHERE Prop_Desc = ltrim(rtrim(replace(PLDesc,@PPTT,''))) + ' ' + @LineProdFactorDesc  
   
  
-------------------------------------------------------------------------------  
-- Section 10: Parse the DelayTypeList  
-------------------------------------------------------------------------------  
  
-- this parsing procedure extracts individual delay type values out of @DelayTypeList  
-- and inserts them into @DelayTypes  
-- ideally, we would do this without a while loop, but because this list will be short, this   
-- may be the most efficient way to do it.  
  
SELECT @SearchString = LTRIM(RTRIM(@DelayTypeList))  
WHILE len(@SearchString) > 0  
 BEGIN  
  SELECT @Position = CharIndex('|', @SearchString)  
  IF @Position = 0  
  BEGIN  
   SELECT   
   @PartialString = RTRIM(@SearchString),  
   @SearchString = ''  
  END  
 ELSE  
  BEGIN  
   SELECT   
   @PartialString = RTRIM(substring(@SearchString, 1, @Position - 1)),  
   @SearchString = LTRIM(RTRIM(substring(@SearchString, (@Position + 1), len(@SearchString))))  
  END  
 IF len(@PartialString) > 0  
  AND (  
    SELECT count(DelayTypeDesc)   
    FROM @DelayTypes   
    WHERE DelayTypeDesc = @PartialString  
    ) = 0  
  BEGIN  
   INSERT @DelayTypes (DelayTypeDesc)   
   VALUES (@PartialString)  
  END  
 END  
  
  
-------------------------------------------------------------------------------  
-- Section 11: Get information for ProdUnitList  
-------------------------------------------------------------------------------  
  
-- note that some values are parsed from the extended_info field  
INSERT @ProdUnits   
 (   
 PUId,  
 PUDesc,  
 PLId,  
 ExtendedInfo,  
 DelayType,  
 ScheduleUnit,  
 LineStatusUnit,  
 PRIDRLVarId)  
SELECT pu.PU_Id,  
 pu.PU_Desc,  
 pu.PL_Id,  
 pu.Extended_Info,  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr),  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUScheduleUnitStr),  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PULineStatusUnitStr),  
 rlv.Var_Id  
FROM dbo.Prod_Units pu with (nolock)   
JOIN @ProdLines tpl    
ON pu.PL_Id = tpl.PLId  
and pu.Master_Unit is null  
JOIN dbo.Event_Configuration ec with (nolock)    
ON pu.PU_Id = ec.PU_Id  
AND ec.ET_Id = 2  
JOIN @DelayTypes dt   
ON dt.DelayTypeDesc = GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr)   
LEFT JOIN dbo.Variables rlv with (nolock)   
ON rlv.PU_Id = pu.PU_Id   
AND rlv.Var_Desc = @PRIDRLVarStr  
where pu_desc not like '%z_obs%'  
option (keep plan)  
  
  
-------------------------------------------------------------------------------  
-- Section 12: Populate @ProdUnitsPack  
-------------------------------------------------------------------------------  
  
INSERT @ProdUnitsPack    
 (   
 PUId,  
 PUDesc,  
 PLId,  
 PLDesc,    
 GoodUnitsVarId,  
 ScheduleUnit,  
 UOM  
 )   
SELECT pu.PU_Id,  
 pu.pu_desc,  
 pu.PL_Id,  
 pl.PLDesc,    
 v.Var_Id,  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUScheduleUnitStr),  
 v.Eng_Units  
FROM dbo.Prod_Units pu with (nolock)  
JOIN @ProdLines pl ON pu.PL_Id = pl.PLId  
LEFT JOIN dbo.Variables v with (nolock) ON pu.PU_Id = v.PU_Id  
AND (v.Var_Desc = @VarGoodUnitsVN   
 OR dbo.fnLocal_GlblParseInfo(v.Extended_Info, 'GlblDesc=') LIKE '%' + REPLACE(@VarGoodUnitsVN,' ',''))  
where charindex('|' + convert(varchar,pu.pu_id) + '|','|' + @PackPUIdList + '|') > 0  
option (keep plan)  
  
  
---------------------------------------------------------------  
-- Section 13: Get Crew Schedule information  
---------------------------------------------------------------  
  
insert @CrewSchedule  
 (  
 Start_Time,  
 End_Time,  
 pu_id,  
 Crew_Desc,  
 Shift_Desc  
 )  
select distinct   
 start_time,  
 end_time,  
 pu_id,  
 crew_desc,  
 shift_desc  
from dbo.crew_schedule cs with (nolock)  
join @produnits pu  
on cs.pu_id = pu.scheduleunit  
where cs.start_time < @endtime  
and (cs.end_time > @starttime or cs.end_time is null)  
option (keep plan)  
  
  
-------------------------------------------------------------------------------  
-- Section 14: Get Production Starts  
-------------------------------------------------------------------------------  
  
insert @ProductionStarts   
 (  
 Start_Time,  
 End_Time,  
 Prod_ID,  
 Prod_Code,  
 Prod_Desc,  
 PU_ID  
 )  
select ps.start_time,  
 ps.end_time,  
 ps.prod_id,  
 p.prod_code,  
 p.prod_desc,  
 ps.pu_id  
from dbo.production_starts ps with (nolock)  
join dbo.products p with (nolock)   
on ps.prod_id = p.prod_id  
join @produnits pu  
on start_time < @endtime  
and (ps.end_time > @starttime or ps.end_time is null)  
--AND p.Prod_Desc <> 'No Grade'   
and pu.puid = ps.pu_id   
option (keep plan)  
  
insert @ProductionStarts   
 (  
 Start_Time,  
 End_Time,  
 Prod_ID,  
 Prod_Code,  
 Prod_Desc,  
 PU_ID  
 )  
select ps.start_time,  
 ps.end_time,  
 ps.prod_id,  
 p.prod_code,  
 p.prod_desc,  
 ps.pu_id  
from dbo.production_starts ps with (nolock)  
join dbo.products p with (nolock)   
on ps.prod_id = p.prod_id  
join @ProdUnitsPack pu  
on start_time < @endtime  
and (ps.end_time > @starttime or ps.end_time is null)  
--AND p.Prod_Desc <> 'No Grade'   
and pu.puid = ps.pu_id   
option (keep plan)  
-----------------------------------------------------------------------------  
-- Section 15: Get Products  
-----------------------------------------------------------------------------  
  
insert @products  
 (  
 prod_id,  
 prod_code,  
 prod_desc  
 )  
select distinct  
 prod_id,  
 prod_code,  
 prod_desc  
from @productionstarts   
order by prod_id  
option (keep plan)  
  
  
------------------------------------------------------------------  
-- Section 16: Get Active Specs  
------------------------------------------------------------------  
  
------------------------------------------------------------  
-- now that we have populated the @products table, we   
-- can get the active specifications that we'll need later   
-- in the SP.  This is done by joining Active_Specs with   
-- Specifications, Characteristics, and Product_Properties.  
-- It was by compiling the data in this table variable   
-- that the old @ProdRecords cursor could be eliminated.  
------------------------------------------------------------  
  
insert @activespecs  
 (  
 effective_date,  
 expiration_date,  
 prod_id,  
 spec_id,  
 spec_desc,  
 char_id,  
 char_desc,  
 prop_id,  
 prop_desc,  
 target  
 )  
select distinct  
 asp.effective_date,  
 coalesce(asp.expiration_date,@endtime),  
 p.prod_id,  
 s.spec_id,  
 s.spec_desc,  
 c.char_id,  
 c.char_desc,  
 pp.prop_id,  
 pp.prop_desc,  
 asp.target  
from dbo.active_specs asp with (nolock)  
join dbo.characteristics c with (nolock)  
on asp.char_id = c.char_id   
join dbo.specifications s with (nolock)  
on asp.spec_id = s.spec_id   
join dbo.product_properties pp with (nolock)  
on s.prop_id = pp.prop_id  
join @products p   
on c.char_desc = prod_code  
where effective_date < @EndTime  
and (expiration_date > @StartTime or expiration_date is null)  
AND ISNUMERIC(asp.target)=1   --When a spec is deleted, Proficy puts '<Deleted>' in front of the value.    
          --We don't wnat those records--or any others that don't have valid numeric values.  
option (keep plan)  
  
  
-------------------------------------------------------------------------------  
-- Section 17: Get Line Production Variables     
-------------------------------------------------------------------------------  
  
IF @BusinessType IN (3, 4) -- Facial/Hanky  
  
 -- Facial/Hanky bases its production off a dedicated pack line so we're going to find  
 -- the pack line associated with this production line and gather all the necessary info FROM it  
 -- We're also going to filter by the argument pack pu list for consistency  
 INSERT INTO @LineProdVars   
  (   
  PLId,  
  PUId,  
  VarId,  
  VarType  
  )  
 SELECT  pl.PLId,  
  pup.PUId,  
  v.Var_Id,  
  dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr)  
 FROM dbo.Variables v with (nolock)  
 JOIN @ProdUnitsPack pup ON v.PU_Id = pup.PUId  
 JOIN @ProdLines pl ON pl.PackOrLine = 'Line'  
 AND LTRIM(RTRIM(REPLACE(pup.PLDesc, ' ', ''))) = LTRIM(RTRIM(REPLACE(pl.PLDesc, ' ', ''))) + 'PACK'  
 WHERE dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr) IN (@ACPUnitsFlag, @HPUnitsFlag, @TPUnitsFlag)  
 option (keep plan)  
  
  
--------------------------------------------------------------------  
-- Section 18: Get the dimensions to be used  
--------------------------------------------------------------------  
  
/*--------------------------------------------------------------------------------------  
  
Overview:  
  
Think of the time on a production unit as a constant timeline that is broken up by changes of   
various types (called dimensions).  Examples would be a change in Product being made, the Team   
working, the Shift working, the Target Speed of the line, the Line Status, etc.  Whenever   
the value of ANY dimension changes, there is a break in the timeline.    
  
NOTE that "dimension" is a term taken from data warehousing, and is used in a similar way.  
  
  
@Dimensions:  
  
The @Dimensions table tracks the different dimensions by which we want to split    
the timeline.  The table tracks each type of Dimension (in this case, ProdID, Team,   
Shift, TargetSpeed, and LineStatus, although more can be easily added, as needed),   
along with the different possible values associated with those dimensions (meaning only those   
values that actually occur within the report window), as well as the start and end time that   
each dimensional value comes into affect.    
  
If a new dimension is added to the table, it may need to be added to the indices of some result sets.  
Also, new dimensions may need to be added to @ProdRecords, #SplitEvents, and #SplitUptime.   
  
@Runs:  
  
If the starttimes of ALL the dimensional values for a given prod unit are laid out,   
in chronilogical order,  what we have are different segments of the timeline on that   
prod unit, each having a value for the different dimensions being tracked.  The @Runs   
table will hold the start and end time of each segment, along with information about   
the dimensional values for each segment.    
  
----------------------------------------------------------------------------------*/  
  
------------------------------------------------------------  
-- add the prodid dimension  
------------------------------------------------------------  
  
insert @Dimensions   
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
SELECT distinct   
 'ProdID',  
 ps.Prod_Id,  
 ps.Start_Time,  
 ps.End_Time,  
 pu.PLID,  
 ps.PU_Id  
FROM @ProductionStarts ps  
JOIN @ProdUnits pu ON ps.PU_Id = pu.PUId  
JOIN @DelayTypes dt ON dt.DelayTypeDesc = GBDB.dbo.fnLocal_GlblParseInfo(pu.ExtendedInfo, @PUDelayTypeStr)  
ORDER BY ps.start_time, ps.PU_Id  
option (keep plan)  
  
  
if @IncludeTeam = 1  
begin  
  
-- add the Team dimension  
insert @Dimensions  
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
select  distinct  
 'Team',  
 Crew_Desc,  
 start_time,  
 end_time,  
 pu.PLID,  
 pu.puid  
from @crewschedule cs  
join @produnits pu on cs.pu_id = scheduleunit  
option (keep plan)  
  
  
-- add the shift dimension  
insert @Dimensions  
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
select  distinct  
 'Shift',  
 Shift_Desc,  
 start_time,  
 end_time,  
 pu.PLID,  
 pu.puid  
from @crewschedule cs  
join @produnits pu on cs.pu_id = scheduleunit  
option (keep plan)  
  
end -- @IncludeTeam = 1  
  
else  
  
begin  
  
 DECLARE   
 @LoopCtr int,  
 @DayEndTime datetime,  
 @DayStartTime datetime,  
 @ByDayTeam varchar(50),  
 @ByDayShift varchar(50)  
  
 SELECT  @DayEndTime = @StartTime  
 SELECT @LoopCtr = 1  
 SELECT  @DayStartTime = @DayEndTime  
  
 WHILE @DayEndTime < @EndTime  
  BEGIN  
  
  SELECT @DayEndTime = DATEADD(dd, 1, @DayEndTime)  
  
  -- add the shift dimension  
  insert @Dimensions  
   (  
   Dimension,  
   Value,  
   Starttime,  
   EndTime,  
   PLID,  
   PUID  
   )  
  select  distinct  
   'DayStart',  
   convert(varchar(10),@DayStartTime,101),  
   @DayStartTime,  
   @DayEndTime,  
   pu.PLID,  
   pu.puid  
  from @produnits pu   
  option (keep plan)  
  
  SELECT @LoopCtr = @LoopCtr + 1  
  SELECT @DayStartTime = @DayEndTime  
  
  END  
  
end  
  
  
--/*  
-- add target speed  
insert @Dimensions  
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
select  distinct  
 'TargetSpeed',  
 asp.target,   
 asp.effective_date,  
 asp.expiration_date,  
 pl.plid,  
 ps.pu_id  
from @activespecs asp  
join @productionstarts ps  
on ps.prod_id = asp.prod_id  
join @produnits pu   
on ps.pu_id = pu.puid   
join @prodlines pl   
on pu.plid = pl.plid  
and asp.prop_id = pl.PropLineProdFactorId  
where asp.spec_desc = @LineSpeedTargetSpecDesc --'Line Speed Target'  
and pu.pudesc like  '%Converter Reliability%'  
and asp.prop_desc = ltrim(rtrim(replace(PLDesc,@PPTT,''))) + ' ' + @LineProdFactorDesc  
option (keep plan)  
--*/  
  
-- add Line Status  
  
insert @Dimensions  
 (  
 dimension,   
 value,  
 StartTime,  
 EndTime,  
 PLID,  
 PUId  
 )  
  
SELECT 'LineStatus',  
 phrase_value,  
 ls.Start_DATETIME,  
 coalesce(ls.end_datetime,@endtime),  
 pu.plid,  
 pu.PUId  
FROM dbo.Local_PG_Line_Status ls with (nolock)  
JOIN @ProdUnits pu   
ON ls.Unit_Id = pu.LineStatusUnit   
AND pu.PUId > 0  
JOIN dbo.Phrase p with (nolock) ON line_status_id = p.Phrase_Id  
where ls.update_status <> 'DELETE'    
and ls.start_datetime < @EndTime  
and (ls.end_datetime > @StartTime or ls.end_datetime is null)  
option (keep plan)  
  
--  
-- add code for any additional dimensions  
--  
  
  
-------------------------------------------------------------------------------------------  
-- limit the starttime and endtime of @Dimensions to the report window start and end time  
-------------------------------------------------------------------------------------------  
  
update @Dimensions set  
 starttime = @StartTime  
where starttime < @StartTime  
  
update @Dimensions set  
 endtime = @EndTime  
where endtime > @EndTime  
or endtime is null  
  
  
-------------------------------------------------------------  
-- Section 19: Get the run times and values for each dimension  
-------------------------------------------------------------  
  
-------------------------------------------------------------  
-- create the intial time periods of the production runs.  
-- the runtime needs to be laid out as a series of changes...  
-- initially, we don't care WHY the change takes place (meaning   
-- which dimension is undergoing the change).  We just need   
-- to lay the times of these changes out into a straight line.  
-- for this purpose, we only care about the start times.  
-------------------------------------------------------------  
  
insert @Runs  
 (  
 PLID,  
 PUID,    
 StartTime  
 )  
select  distinct  
 PLID,  
 puid,  
 starttime  
from @Dimensions  
order by puid, starttime  
option (keep plan)  
  
  
--------------------------------------------------------------------  
-- once we know what time each new time split started, we can   
-- determine the endtime by simply looking at the NEXT start time  
-- in the line.  
--------------------------------------------------------------------  
  
update r1 set  
 endtime =   
  (  
  select top 1 starttime  
  from @Runs r2  
  where r1.puid = r2.puid  
  and r1.starttime < r2.starttime  
  )  
from @Runs r1  
  
update @runs set  
 endtime = @endtime  
where endtime is null  
    
  
-------------------------------------------------------  
-- now that we know where the time splits are, we need  
-- to determine what the dimensional values are in   
-- each time segment. this requires an update for each   
-- dimension.  
------------------------------------------------------  
  
-- get the ProdID   
  
update r set  
 ProdID =   
  (  
  select value  
  from @Dimensions d  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'ProdID'  
  )  
from @Runs r  
  
  
if @IncludeTeam = 1  
  
begin  
  
-- get the Team  
  
update r set   
 Team =   
  (  
  select value  
  from @Dimensions d  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'Team'  
  )   
from @Runs r  
  
  
-- get the shift  
  
update r set   
 Shift =   
  (  
  select value  
  from @Dimensions d  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'Shift'  
  )   
from @Runs r  
  
end  
  
else  
  
begin  
  
-- get the DayStart  
  
update r set   
 DayStart =   
  (  
  select value  
  from @Dimensions d  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'DayStart'  
  )   
from @Runs r  
  
end -- @IncludeTeam = 1  
  
  
-- get the target speed  
  
update r set  
 targetspeed =  
 (  
 select top 1   
 target  
 from @activespecs asp  
 WHERE asp.prod_id = r.prodid  
 AND asp.Prop_Id = pl.PropLineProdFactorId  
 and asp.Spec_Desc = @LineSpeedTargetSpecDesc  
 and Effective_Date <= r.starttime  
 order by effective_date desc  
 )  
from @runs r  
join @prodlines pl  
on r.plid = pl.plid  
  
  
-- get the ideal speed  
-- note that this is not actually a dimension by which we have split our runtime.  
-- it is actually associated with product.  
  
update r set  
 idealspeed =  
 (  
 select top 1   
 target  
 from @activespecs asp  
 WHERE asp.prod_id = r.prodid  
 AND asp.Prop_Id = pl.PropLineProdFactorId   
 and asp.Spec_Desc = @LineSpeedIdealSpecDesc  
 and Effective_Date <= r.starttime  
 order by effective_date asc  
 )  
from @runs r  
join @prodlines pl  
on r.plid = pl.plid  
  
  
-- get the line status  
  
update r set   
 LineStatus =   
  (  
  select value  
  from @Dimensions d  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'LineStatus'  
  )   
from @Runs r  
  
  
-----------------------------------------------------------------------------------  
-- Section 20: Populate @RunSummary  
-----------------------------------------------------------------------------------  
  
-- @RunSummary simply summarizes data from @Runs.  
-- For Hanky lines, the production is captured FROM the pack units.  Added IF  
-- statement to SELECT ONLY Converter Reliability unit(s) for Tissue/Towel.  
  
IF @BusinessType = 3  
 BEGIN  
  INSERT INTO @RunSummary   
   (   
   PLId,  
   puid,   
   Shift,  
   Team,  
   DayStart,  
   ProdId,     StartTime,  
   EndTime,  
   Duration,  
   TargetSpeed,  
   IdealSpeed,   
   TgtSpeedxDuration,   
   IdealSpeedxDuration,  
   LineStatus  
   )  
   
  SELECT distinct   
   PLId,  
   puid,   
   Shift,  
   Team,  
   DayStart,  
   ProdId,  
   StartTime,  
   EndTime,  
   CASE  WHEN coalesce(TargetSpeed,-1) = -1  
    THEN CONVERT(FLOAT, DATEDIFF(ss, StartTime,EndTime))  
    ELSE NULL  
    END,  
   TargetSpeed,  
   IdealSpeed,  
   TargetSpeed * CONVERT(FLOAT, DATEDIFF(ss, StartTime,EndTime)),   
   IdealSpeed * CONVERT(FLOAT, DATEDIFF(ss, StartTime,EndTime)),  
   LineStatus  
  FROM @Runs rls  
  GROUP BY PLId, puid, convert(datetime,DayStart), DayStart, Team, Shift, ProdId, LineStatus,   
     StartTime, EndTime, TargetSpeed, idealspeed  
  option (keep plan)  
 END  
ELSE  
 BEGIN  
  INSERT INTO @RunSummary   
   (   
   PLId,  
   puid,   
   Shift,  
   Team,  
   DayStart,  
   ProdId,  
   StartTime,  
   EndTime,  
   Duration,   
   TargetSpeed,  
   IdealSpeed,  
   TgtSpeedxDuration,   
   IdealSpeedxDuration,  
   LineStatus  
   )  
   
  SELECT distinct   
   rls.PLId,  
   rls.puid,   
   Shift,  
   Team,  
   DayStart,  
   ProdId,  
   StartTime,  
   EndTime,  
   CASE  WHEN coalesce(TargetSpeed, -1) > -1  
    THEN CONVERT(FLOAT, DATEDIFF(ss, StartTime,EndTime))  
    ELSE NULL  
    END,  
   TargetSpeed,  
   IdealSpeed,  
   TargetSpeed * CONVERT(FLOAT, DATEDIFF(ss, StartTime,EndTime)),   
   IdealSpeed * CONVERT(FLOAT, DATEDIFF(ss, StartTime,EndTime)),  
   LineStatus   
  FROM @Runs rls  
  JOIN @ProdUnits pu ON rls.PUId = pu.PUId  
  WHERE PUDesc LIKE '%Converter Reliability%'   
  GROUP BY rls.PLId, rls.puid, convert(datetime,DayStart), DayStart, Team, Shift, ProdId, LineStatus,   
     StartTime, EndTime, TargetSpeed, IdealSpeed  
  option (keep plan)  
 END  
  
-------------------------------------------------------------------------------  
-- Section 21: Get the Time Event Details  
-------------------------------------------------------------------------------  
  
-- We get basic delays information from the real table, Timed_Event_Details.  
-- #TimedEventDetails is an intermediary table that is used so that we don't have to   
-- join to the real table 3 times in populating #Delays.  
  
-- Note that after the intermediary table is populated we do still access the real table   
-- a number of times (with multiple inserts to #TimedEventDetails, and to populate @FirstEvents).    
-- This is done to get related records that are outside of our report window.  If we could find   
-- a way to identify these records and include them in the initial insert to #TimedEventDetails,   
-- then we could remove a lot of the code below and reduce the hits to the database.    
  
 -- initial insert  
 insert dbo.#TimedEventDetails  
  (  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ERTD_ID  
  )  
 select  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ted.event_reason_tree_data_id  
 from dbo.timed_event_details ted with (nolock)  
 join @produnits pu  
 on ted.pu_id = pu.puid  
 where Start_Time < @EndTime  
 AND (End_Time > @StartTime or end_time is null)  
 option (keep plan)  
  
  
 -- get the secondary events that span after the report window  
 insert dbo.#TimedEventDetails  
  (  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ERTD_ID  
  )  
 select  
  ted2.TEDet_ID,  
  ted2.Start_Time,  
  ted2.End_Time,  
  ted2.PU_ID,  
  ted2.Source_PU_Id,  
  ted2.Reason_Level1,  
  ted2.Reason_Level2,  
  ted2.Reason_Level3,  
  ted2.Reason_Level4,  
  ted2.TEFault_Id,  
  ted2.event_reason_tree_data_id  
 from  dbo.#TimedEventDetails ted1 with (nolock)  
 join  (  
  -- select *  --Rev1.03 NHK  Nov07 2005  
  select   
   tted.TEDet_ID,  
   tted.Start_Time,  
   tted.End_Time,  
   tted.PU_ID,  
   tted.Source_PU_Id,  
   tted.Reason_Level1,  
   tted.Reason_Level2,  
   tted.Reason_Level3,  
   tted.Reason_Level4,  
   tted.TEFault_Id,  
   tted.event_reason_tree_data_id  
  from dbo.timed_event_details tted with (nolock)  
  join @produnits tpu  
  on tted.pu_id = tpu.puid   
  and tted.start_time >= @Endtime   
  ) ted2  
 on ted1.PU_Id = ted2.PU_Id  
 AND ted1.End_Time = ted2.Start_Time  
 and ted2.start_time >= @endtime  
 AND ted1.TEDet_Id <> ted2.TEDet_Id  
 option (keep plan)  
  
--/*  
 -- get the secondary events that span before the report window  
 insert dbo.#TimedEventDetails  
  (  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ERTD_ID  
  )  
 select  
  ted1.TEDet_ID,  
  ted1.Start_Time,  
  ted1.End_Time,  
  ted1.PU_ID,  
  ted1.Source_PU_Id,  
  ted1.Reason_Level1,  
  ted1.Reason_Level2,  
  ted1.Reason_Level3,  
  ted1.Reason_Level4,  
  ted1.TEFault_Id,  
  ted1.event_reason_tree_data_id  
 from dbo.#TimedEventDetails ted2 with (nolock)  
 join  (  
  --select * --Rev1.03 NHK  Nov07 2005  
  select   
   tted.TEDet_ID,  
   tted.Start_Time,  
   tted.End_Time,  
   tted.PU_ID,  
   tted.Source_PU_Id,  
   tted.Reason_Level1,  
   tted.Reason_Level2,  
   tted.Reason_Level3,  
   tted.Reason_Level4,  
   tted.TEFault_Id,  
   tted.event_reason_tree_data_id  
  from dbo.timed_event_details tted with (nolock)  
  join @produnits tpu  
  on tted.pu_id = tpu.puid   
  and tted.start_time < @starttime   
  and tted.end_time <= @Starttime   
  ) ted1  
 on ted1.PU_Id = ted2.PU_Id  
 AND ted1.End_Time = ted2.Start_Time  
 and ted1.end_time <= @starttime  
 AND ted1.TEDet_Id <> ted2.TEDet_Id  
 option (keep plan)  
--*/  
  
------------------------------------------------------------------------  
-- Section 22: Get the initial set of delays for the report period  
------------------------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Collect dataset filtered by report period and Production Units.  
-------------------------------------------------------------------------------  
/* Can probably revert to this once the Timed_Event_Details index is changed to Clustered */  
INSERT dbo.#Delays (TEDetId,  
  PLID,  
  PUId,  
  StartTime,  
  EndTime,  
  L1ReasonID,  
  LocationId,  
  TEFaultId,  
  ERTD_ID,  
  DownTime,  
  SplitDowntime,  
  PrimaryId,  
  SecondaryId,  
  InRptWindow)  
SELECT ted.TEDet_Id,  
 tpu.plid,  
 ted.PU_Id,  
 ted.Start_Time,  
 COALESCE(ted.End_Time, @EndTime),  
 ted.Reason_Level1,  
 ted.Source_PU_Id,  
 ted.TEFault_Id,  
 ted.ERTD_ID,  
 DATEDIFF(s, ted.Start_Time,COALESCE(ted.End_Time, @EndTime)),  
 COALESCE(DATEDIFF(s, CASE WHEN ted.Start_Time <= @StartTime   
          THEN @StartTime   
          ELSE ted.Start_Time  
          END,   
 CASE WHEN COALESCE(ted.End_Time, @EndTime) >= @EndTime   
   THEN @EndTime   
   ELSE COALESCE(ted.End_Time, @EndTime)  
   END), 0.0),    
 ted2.TEDet_Id,  
 ted3.TEDet_Id,  
 CASE WHEN (ted.start_time < @EndTime and coalesce(ted.end_time,@EndTime) > @StartTime)   
   THEN 1  
   ELSE 0  
   END  
FROM dbo.#TimedEventDetails ted with (nolock)  
JOIN @ProdUnits tpu    
ON ted.PU_Id = tpu.PUId  
AND tpu.PUId > 0  
LEFT JOIN dbo.#TimedEventDetails ted2 with (nolock)   
ON ted.PU_Id = ted2.PU_Id  
AND ted.Start_Time = ted2.End_Time  
AND ted.TEDet_Id <> ted2.TEDet_Id  
LEFT JOIN dbo.#TimedEventDetails ted3 with (nolock)   
ON ted.PU_Id = ted3.PU_Id  
AND ted.End_Time = ted3.Start_Time  
AND ted.TEDet_Id <> ted3.TEDet_Id  
option (keep plan)  
  
  
---------------------------------------------------------------------------------  
-- Section 23: Get the first events for each production unit  
---------------------------------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Collect last downtime before the first primary record of each unit to calculate  
-- raw uptime for those records  
-------------------------------------------------------------------------------  
  
INSERT INTO @FirstEvents   
 (  
 PUId,  
 StartTime   
 )  
SELECT PUId,  
 MIN(StartTime)  
FROM dbo.#Delays with (nolock)  
GROUP BY PUId  
option (keep plan)  
  
SELECT  @Rows = @@ROWCOUNT,  
 @Row = 0  
  
  
-- Generally, we want to remove loops and cursors from the procedure,  
-- and do all work through Insert, Update, and Select statements.  
-- But in this case, because there will be so few records, the loop   
-- seems to be the most efficient way to do this.  
  
--/*  
WHILE @Row < @Rows  
 BEGIN  
 SELECT @Row = @Row + 1  
   
 SELECT @@PUId  = PUId,  
  @@StartTime = StartTime  
 FROM @FirstEvents  
 WHERE FirstEventId = @Row  
 option (keep plan)  
  
 INSERT dbo.#Delays (TEDetId,  
   PUId,  
   StartTime,  
   EndTime,  
   L1ReasonID,  
   LocationId,  
   TEFaultId,  
   ERTD_ID,  
   DownTime,  
   SplitDowntime,  
   InRptWindow)  
 SELECT TOP 1 ted.TEDet_Id,  
   ted.PU_Id,  
   ted.Start_Time,  
   COALESCE(ted.End_Time, @EndTime),  
   ted.Reason_Level1,  
   ted.Source_PU_Id,  
   ted.TEFault_Id,  
   ted.event_reason_tree_data_id,  
   DATEDIFF(s, ted.Start_Time,  
   COALESCE(ted.End_Time, @EndTime)),  
   COALESCE(DATEDIFF(s, CASE WHEN ted.Start_Time <= @StartTime   
            THEN @StartTime   
            ELSE ted.Start_Time  
            END,   
      CASE WHEN COALESCE(ted.End_Time, @EndTime) >= @EndTime   
        THEN @EndTime   
        ELSE COALESCE(ted.End_Time, @EndTime)  
        END), 0.0),    
   CASE WHEN (ted.start_time < @EndTime and coalesce(ted.end_time,@EndTime) > @StartTime)   
     THEN 1  
     ELSE 0  
     END  
 FROM dbo.Timed_Event_Details ted with (nolock)  
 join @FirstEvents fe  
 on ted.PU_Id = @@PUId  
 AND ted.Start_Time < @@StartTime  
 ORDER BY Start_Time DESC   
 option (keep plan)  
  
 END  
--*/  
  
---------------------------------------------------------------------------  
-- Section 24: Additional updates to #Delays  
---------------------------------------------------------------------------  
  
Update td set  
 Plid = pu.plid   
from dbo.#delays td with (nolock)  
join @produnits pu  
on td.puid = pu.puid  
where td.plid is null   
  
  
-- Add PUDesc   
UPDATE td  
SET PUDESC =    
 CASE   
 WHEN pu.PUDesc NOT LIKE '%Converter Reliability%'  
 AND pu.PUDesc NOT LIKE '%Rate Loss%'   
 THEN pu.PUDesc    
 ELSE LTRIM(RTRIM(REPLACE(pl.PLDesc,'TT ',''))) + ' Converter Reliability'   
 END  
FROM dbo.#Delays td with (nolock)  
JOIN @ProdUnits pu ON td.PUID = pu.PUId  
JOIN @ProdLines pl ON pu.PLId = pl.PLId  
WHERE td.pudesc is null   
  
   
-------------------------------------------------------------------------------  
-- Ensure that all the PrimaryIds point to the actual Primary event.  
-------------------------------------------------------------------------------  
  
WHILE (   
 SELECT count(td1.TEDetId)  
 FROM dbo.#Delays td1 with (nolock)  
  JOIN dbo.#Delays td2 with (nolock)  
   ON td1.PrimaryId = td2.TEDetId  
 WHERE td2.PrimaryId IS NOT NULL  
 ) > 0  
 BEGIN  
 UPDATE td1  
 SET PrimaryId = td2.PrimaryId  
 FROM dbo.#Delays td1 with (nolock)  
  INNER JOIN dbo.#Delays td2 with (nolock)  
  ON td1.PrimaryId = td2.TEDetId  
 WHERE td2.PrimaryId IS NOT NULL  
 END  
  
UPDATE dbo.#Delays  
SET PrimaryId = TEDetId  
WHERE PrimaryId IS NULL  
  
  
-------------------------------------------------------------------------------  
-- Section 25: Get the Timed Event Categories for #Delays  
-------------------------------------------------------------------------------  
  
/*  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- Timed_Event_Details row FROM the Local_Timed_Event_Categories table using  
-- the TEDet_Id.  
-------------------------------------------------------------------------------  
  
-- Get the minimum - maximum range for later queries  
SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
 @Min_TEDet_Id = MIN(TEDetId) - 1,  
 @RangeStartTime = MIN(StartTime),  
 @RangeEndTime = MAX(EndTime)  
FROM dbo.#Delays  
option (keep plan)  
  
  
INSERT INTO @TECategories   
 (  
 TEDet_Id,  
 ERC_Id  
 )  
SELECT tec.TEDet_Id,  
 tec.ERC_Id  
FROM dbo.#Delays td  
JOIN  dbo.Local_Timed_Event_Categories tec   
ON td.TEDetId = tec.TEDet_Id  
and tec.TEDet_Id > @Min_TEDet_Id  
AND tec.TEDet_Id < @Max_TEDet_Id  
option (keep plan)  
  
UPDATE td  
SET ScheduleId = tec.ERC_Id  
FROM dbo.#Delays td  
JOIN  @TECategories tec   
ON  td.TEDetId = tec.TEDet_Id  
JOIN  dbo.Event_Reason_Catagories erc   
ON tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
  
UPDATE td  
SET CategoryId = tec.ERC_Id  
FROM dbo.#Delays td  
JOIN  @TECategories tec   
ON  td.TEDetId = tec.TEDet_Id  
JOIN  dbo.Event_Reason_Catagories erc   
ON tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @CategoryStr + '%'  
  
UPDATE td  
SET GroupCauseId = tec.ERC_Id  
FROM dbo.#Delays td  
JOIN @TECategories tec   
ON td.TEDetId = tec.TEDet_Id  
JOIN dbo.Event_Reason_Catagories erc   
ON tec.ERC_Id = erc.ERC_Id                     
AND erc.ERC_Desc LIKE @GroupCauseStr + '%'  
  
UPDATE td  
SET SubSystemId = tec.ERC_Id  
FROM dbo.#Delays td  
JOIN @TECategories tec   
ON td.TEDetId = tec.TEDet_Id  
JOIN dbo.Event_Reason_Catagories erc   
ON tec.ERC_Id = erc.ERC_Id  
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
  
--/*  
UPDATE td SET   
 ScheduleId = @SchedBlockedStarvedId  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Event_Reasons er with (nolock)  
on Event_Reason_ID = L1ReasonId   
WHERE ScheduleId IS NULL   
AND (Event_Reason_Name LIKE '%BLOCK%' OR Event_Reason_Name LIKE '%STARVE%')  
--*/  
  
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
  
  
-------------------------------------------------------------------------------------  
-- Section 26: Populate @Primaries  
-------------------------------------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Populate a separate temporary table that only contains the Primary records.  
-- This allows us to retrieve the EndTime of the previous downtime  
-- event which is used to calculate UpTime.  
-------------------------------------------------------------------------------  
  
INSERT @Primaries   
 (  
 TEDetId,  
 PUId,  
 StartTime,  
 EndTime  
 )  
SELECT td1.TEDetId,  
 td1.PUId,  
 MIN(td2.StartTime),  
 MAX(td2.EndTime)  
FROM dbo.#Delays td1 with (nolock)  
JOIN dbo.#Delays td2 with (nolock)  
ON td1.TEDetId = td2.PrimaryId  
JOIN @ProdUnits pu    
ON td1.PUID = pu.PUID   
WHERE td1.TEDetId = td1.PrimaryId  
AND pu.DelayType <> @DelayTypeRateLossStr --FLD Rev8.52  
GROUP BY td1.TEDetId, td1.PUId  
ORDER BY td1.PUId, MIN(td2.StartTime) ASC  
option (keep plan)  
  
  
UPDATE p1 SET   
 Uptime = CASE    
   WHEN p1.PUId = p2.PUId  
   THEN DATEDIFF(s, p2.EndTime, p1.StartTime)  
   ELSE  NULL  
   END   
FROM @Primaries p1  
JOIN @Primaries p2 ON p2.TEPrimaryId = (p1.TEPrimaryId - 1)   
WHERE p1.TEPrimaryId > 1  
  
  
UPDATE td SET   
 UpTime = tp.UpTime   
FROM dbo.#Delays td with (nolock)  
JOIN @Primaries tp ON td.TEDetId = tp.TEDetId  
  
  
-------------------------------------------------------------------------  
-- Section 27: Calculate the Statistics for stops information in the #Delays dataset   
-------------------------------------------------------------------------  
/*  
UPDATE td SET   
 Stops =     
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.CategoryId <> @CatBlockStarvedId   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsUnscheduled =   
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.CategoryId <> @CatBlockStarvedId   
    OR coalesce(td.CategoryId,0)=0)  
  AND (td.ScheduleId = @SchedUnscheduledId   
    OR coalesce(td.ScheduleId,0)=0)  
  AND td.StartTime >= @StartTime  
  THEN 1  
  ELSE 0  
  END,  
 Stops2m =    
  CASE WHEN td.DownTime < 120  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.CategoryId <> @CatBlockStarvedId   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.ScheduleId = @SchedUnscheduledId   
   OR coalesce(td.ScheduleId,0)=0)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsMinor =    
  CASE WHEN td.DownTime < 600  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.CategoryId <> @CatBlockStarvedId   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.ScheduleId = @SchedUnscheduledId   
   OR coalesce(td.ScheduleId,0)=0)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsEquipFails =   
  CASE   
  WHEN td.DownTime >= 600  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
  AND (td.ScheduleId = @SchedUnscheduledId   
   OR coalesce(td.ScheduleId,0)=0)  
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
  WHEN td.CategoryId = @CatBlockStarvedId  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsProcessFailures =   
  CASE   
  WHEN td.DownTime >= 600  
  AND  tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.ScheduleId = @SchedUnScheduledId   
   OR coalesce(td.ScheduleId,0)=0)  
  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId, @CatBlockStarvedId)   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END--,  
FROM dbo.#Delays td with (nolock)  
JOIN @ProdUnits tpu   
ON  td.PUId = tpu.PUId  
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
  CASE WHEN td.DownTime < 120  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.CategoryId <> @CatBlockStarvedId   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.ScheduleId = @SchedUnscheduledId   
   OR coalesce(td.ScheduleId,0)=0)  
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
  
  
-------------------------------------------------------------  
-- Section 28: Get Tests  
-------------------------------------------------------------  
  
-- Certain test results need to be compiled for this report.  Originally,  
-- there were multiple queries against the test table in the database to do this.    
-- But, its more efficient to only hit the table one time, and get all the data   
-- needed and put it into a temporary table.  This insert statement is   
-- designed to get all the test results needed for @PRsRun, @ProdRecords,  
-- and to determine the Actual Line Speed for #Delays.  
-- Note that the population of @PRsRun originally joined to the Tests table   
-- FIVE times... adding this intermediary table leads to a big improvement in   
-- efficiency.  
  
  
 INSERT dbo.#Tests   
  (   
  VarId,  
  PLId,  
  ProdId,   
  ProdCode,  
  Value,  
  nValue,   
  StartTime,  
  EndTime  
  )  
 SELECT t.Var_Id,  
  pl.PLId,  
  ps.Prod_Id,  
  p.Prod_Code,  
  t.Result,     
  t.Result,  
  t.Result_On,  
  @EndTime  
 FROM  @ProdLines pl  
 join dbo.tests t with (nolock)  
 on t.var_id in   
  (  
  -- for @PRsRun  
  pl.VarGoodUnitsId,  
  pl.VarTotalUnitsId,  
  pl.VarPMRollWidthId,  
  pl.VarParentRollWidthId,  
  pl.VarEffDowntimeId,  
  pl.VarLineSpeedId,  
  -- for Actual Line Speed  
  pl.VarActualLineSpeedId  
  )  
 and result_on <= @EndTime  
 AND result_on >= dateadd(d, -1, @StartTime)  
 and result is not null  
 left JOIN @productionstarts ps    
 ON (ps.pu_id = pl.prodpuid)          -- 2005-07-27 VMK Removed lpv.PUId reference, not required.  
 AND ps.Start_Time < t.Result_On   
 AND (ps.End_Time >= t.Result_On or ps.end_time is null)  
 left JOIN @Products p     
 on ps.prod_id = p.prod_id  
 option (keep plan)  
  
DELETE from dbo.#Tests   
WHERE VarID IN (SELECT VarLineSpeedId FROM @ProdLines)  
AND (Value = '0' or Value LIKE '0.%')   
  
-- 2005-07-26 VMK Added this insert to capture Tests data for Pack Variables.  
--      GoodUnits was not calculating for Hanky lines in Neuss.  
IF @BusinessType IN (3, 4) -- Facial/Hanky  
 INSERT dbo.#Tests   
  (   
  VarId,  
  PLId,  
  --puid,  
  ProdId,   
  ProdCode,  
  Value,  
  nValue,   
  StartTime,  
  EndTime  
  )  
 SELECT t.Var_Id,  
  lpv.PLId,  
  --ps.pu_id,  
  ps.Prod_Id,  
  p.Prod_Code,  
  t.Result,     
  t.Result,  
  t.Result_On,  
  @EndTime  
 FROM  @LineProdVars lpv    
 JOIN dbo.tests t with (nolock)  
 ON lpv.varid = t.Var_ID  
 AND result_on <= @EndTime  
 AND result_on >= dateadd(d, -1, @StartTime)  
 and result is not null  
 left JOIN @productionstarts ps    
   ON (lpv.PUId = ps.PU_Id)   
   AND ps.Start_Time < t.Result_On   
   AND (ps.End_Time >= t.Result_On or ps.end_time is null)  
 left JOIN @Products p     
   on ps.prod_id = p.prod_id  
 option (keep plan)  
  
  
-- This update to #Tests replaces a lot of the initial work that used to be done in the old   
-- ProdRecordsShift cursor.  The rest of that work will be done in the insert and updates   
-- to @ProdRecords.  Note that there are FOUR joins to the @ActiveSpecs table.  
-- This is another case of an intermediary table saving us overhead compared to multiple   
-- hits to the database.  However, in this case, there is even more benefit in this regard,  
-- because the table compiles related data from multiple source tables.  
  
IF @BusinessType = 4  
  
  UPDATE t  
  SET t.nValue = convert(float,t.Value)  
    * CONVERT(FLOAT, asp1.Target)  
    * CONVERT(FLOAT, asp2.Target)  
    * CONVERT(FLOAT, asp3.Target)  
    * CONVERT(FLOAT, asp4.Target)  
  FROM dbo.#Tests t with (nolock)  
  JOIN @LineProdVars lpv   
  ON t.VarId = lpv.VarId  
  LEFT JOIN @ActiveSpecs asp1   
  on asp1.Prop_Id = @PropCvtgProdFactorId  
  AND asp1.Char_Desc = t.ProdCode  
  AND asp1.Spec_Id = @PacksInBundleSpecId  
  AND asp1.Effective_Date < t.StartTime  
  AND (asp1.Expiration_Date > t.StartTime   
   or asp1.expiration_date is null)  
  LEFT JOIN @ActiveSpecs asp2  
  on asp2.Effective_Date < t.StartTime  
  AND (asp2.Expiration_Date > t.StartTime   
   or asp2.Expiration_Date is null)  
  and asp2.Char_Id = asp1.Char_Id  
  AND asp2.Spec_Id = @SheetCountSpecId  
  LEFT JOIN @ActiveSpecs asp3  
  on asp3.Effective_Date < t.StartTime  
  AND (asp3.Expiration_Date > t.StartTime  
   or asp3.Expiration_Date is null)  
  and asp3.Char_Id = asp1.Char_Id  
  AND asp3.Spec_Id = @ShipUnitSpecId  
  LEFT JOIN @ActiveSpecs asp4   
  on asp4.Effective_Date < t.StartTime  
  AND (asp4.Expiration_Date > t.StartTime  
   or asp4.Expiration_Date is null)  
  and asp4.Char_Id = asp1.Char_Id  
  AND asp4.Spec_Id = @CartonsInCaseSpecId  
  WHERE lpv.VarType = @HPUnitsFlag  
  
  
----------------------------------------------------------------------------------  
-- Section 29: Update the Rateloss information for #Delays  
----------------------------------------------------------------------------------  
  
/*-------------------------------------------------------------------------------  
Update the RateLoss SplitDowntime to be equal to the Effective Downtime  
FROM the #Tests table.    
Note: Effective Downtime is already in minutes!  
Set SplitDowntime and SplitUptime = 0 so that they will not be  
included in Total Report Time.  
RateLossRatio is the ratio of EffectiveDowntime / Downtime.  This will later be   
applied to the split events to get the split rateloss.  
-------------------------------------------------------------------------------*/  
UPDATE td SET    
 LineActualSpeed  = t2.Value,  
 SplitDowntime    = 0,  
 StopsRateLoss   = 1,  
 Downtime    = null,  
 Uptime    = null,  
 RateLossRatio  = (CONVERT(FLOAT,t1.Value) * 60.0) / Downtime  
FROM dbo.#Delays td with (nolock)  
JOIN @ProdUnits pu   
ON td.PUID = pu.PUID  
JOIN @ProdLines pl   
ON pu.PLID = pl.PLID  
LEFT JOIN dbo.#Tests t1 with (nolock)   
ON (td.StartTime = t1.StartTime)   
AND (pl.VarEffDowntimeId = t1.VarId)  
LEFT JOIN dbo.#Tests t2 with (nolock)   
ON (td.StartTime = t2.StartTime)  
AND (pl.VarActualLineSpeedId = t2.VarId)  
WHERE pu.DelayType = @DelayTypeRateLossStr  
AND Downtime <> 0  
  
  
----------------------------------------------------------  
-- Section 30: Populate @ProdRecords  
----------------------------------------------------------  
-------------------------------------------------------------------------------  
-- Get cvtg production factor specifications   
-- Again, the @ActiveSpecs table comes in handy...  
-- Saving lots of overhead.  
-------------------------------------------------------------------------------  
SELECT @PacksInBundleSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc =  @PacksInBundleSpecDesc  
option (keep plan)  
  
SELECT @SheetCountSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc =  @SheetCountSpecDesc  
option (keep plan)  
  
SELECT @CartonsInCaseSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc =  @CartonsInCaseSpecDesc  
option (keep plan)  
  
SELECT @ShipUnitSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc =  @ShipUnitSpecDesc  
option (keep plan)  
  
SELECT @StatFactorSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc = @StatFactorSpecDesc  
option (keep plan)  
  
SELECT @RollsInPackSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc = @RollsInPackSpecDesc  
option (keep plan)  
  
SELECT @SheetWidthSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc = @SheetWidthSpecDesc  
option (keep plan)  
  
SELECT @SheetLengthSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc = @SheetLengthSpecDesc  
option (keep plan)  
  
  
-- this table compiles production values so that they can be grouped   
-- as needed in the result sets later.  
  
INSERT @ProdRecords   
 (  
 PLId,   
 PUID,  
 ReliabilityPUID,  
 Shift,  
 Team,  
 DayStart,  
 ProdId,  
 StartTime,   
 EndTime,   
 Duration,  
 LineSpeedTarget,  
 LineSpeedIdeal,  
 TgtSpeedxDuration,   
 IdealSpeedxDuration,  
 CalendarRuntime,  
 StatFactor,  
 RollsInPack,  
 PacksInBundle,  
 SheetCount,  
 ShipUnit,  
 SheetWidth,  
 SheetLength,  
 CartonsInCase,  
 LineStatus  
 )  
SELECT distinct   
 rs.PLId,  
 PUID,  
 ReliabilityPUID,  
 Shift,  
 Team,  
 DayStart,  
 ProdId,  
 rs.StartTime,  
 rs.EndTime,  
 CASE  WHEN TargetSpeed IS NOT NULL   
  THEN CONVERT(FLOAT, DATEDIFF(ss, rs.Starttime,rs.Endtime))  
  ELSE NULL  
  END,  
 TargetSpeed,  
 IdealSpeed,  
 TargetSpeed * CONVERT(FLOAT, DATEDIFF(ss, rs.Starttime,rs.Endtime)),  
 IdealSpeed * CONVERT(FLOAT, DATEDIFF(ss, rs.Starttime,rs.Endtime)),   
   
 CONVERT(FLOAT,DATEDIFF(ss,rs.StartTime, rs.EndTime)) / 60.0,  
  
 --StatFactor =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp  
 where asp.prod_id = rs.prodid  
 AND Effective_Date <= rs.startTime  
 and asp.Spec_Id = @StatFactorSpecId  
 AND asp.Prop_Id = @PropCvtgProdFactorId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --RollsInPack =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp  
 where asp.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp.Spec_Id = @RollsInPackSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --PacksInBundle =  
 (  
 SELECT TOP 1 CONVERT(FLOAT,Target)  
 FROM @ActiveSpecs asp  
 where asp.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and Spec_Id = @PacksInBundleSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --SheetCount =  
 (   
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp  
 where asp.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp.Spec_Id = @SheetCountSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
  
 --ShipUnit =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp  
 where asp.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp.Spec_Id = @ShipUnitSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
  
 --SheetWidth =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp  
 where asp.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp.Spec_Id = @SheetWidthSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
  
 --SheetLength =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp  
 where asp.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp.Spec_Id = @SheetLengthSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
  
 --CartonsInCase =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp  
 where asp.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp.Spec_Id = @CartonsInCaseSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 LineStatus  
  
FROM @ProdLines pl   
JOIN @RunSummary rs  
ON rs.PLId = pl.PLId  
and pl.PackOrLine <> 'Pack'  
where puid = reliabilitypuid  
option (keep plan)  
  
  
-- the following series of updates replaces a lot of work that used to be done  
-- in the ProdRecordsShift cursor.  NOTE that there are sequential updates   
-- because in many cases, base values must be calculated before others can   
-- be done.  
  
update prs set  
  
 HolidayCurtailDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td.ScheduleId = @SchedHolidayCurtailId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td.StartTime <= rs.StartTime   
    THEN rs.StartTime   
    ELSE td.StartTime END  
    ),   
    (  
    CASE   
    WHEN td.EndTime >= rs.EndTime   
    THEN rs.EndTime   
    ELSE td.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs  
  left join dbo.#Delays td with (nolock)  
  on  td.PUId = prs.ReliabilityPUId   
  and td.starttime < rs.endtime  
  and td.endtime > rs.starttime   
  where rs.PuId = prs.PuId  
  and (rs.team = prs.team or (rs.team is null and prs.team is null))  
  and (rs.shift = prs.shift or (rs.shift is null and prs.shift is null))  
  and (rs.Daystart = prs.Daystart or (rs.Daystart is null and prs.Daystart is null))  
  and rs.prodid = prs.prodid  
  and rs.starttime = prs.starttime  
  and rs.endtime = prs.endtime  
  ),  
  
 PlninterventionDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td.ScheduleId = @SchedPlninterventionId  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td.StartTime <= rs.StartTime   
    THEN rs.StartTime   
    ELSE td.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td.EndTime >= rs.EndTime   
    THEN rs.EndTime   
    ELSE td.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs  
  left join dbo.#Delays td with (nolock)  
  on  td.PUId = prs.ReliabilityPUId  
  and td.starttime < rs.endtime  
  and td.endtime > rs.starttime   
  where rs.PuId = prs.PuId  
  and (rs.team = prs.team or (rs.team is null and prs.team is null))  
  and (rs.shift = prs.shift or (rs.shift is null and prs.shift is null))  
  and (rs.Daystart = prs.Daystart or (rs.Daystart is null and prs.Daystart is null))  
  and rs.prodid = prs.prodid  
  and rs.starttime = prs.starttime  
  and rs.endtime = prs.endtime  
  ),  
  
  
 ChangeOverDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td.ScheduleId = @SchedChangeOverId  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td.StartTime <= rs.StartTime   
    THEN rs.StartTime   
    ELSE td.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td.EndTime >= rs.EndTime   
    THEN rs.EndTime   
    ELSE td.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs  
  left join dbo.#Delays td with (nolock)  
  on  td.PUId = prs.ReliabilityPUId   
  and td.starttime < rs.endtime  
  and td.endtime > rs.starttime   
  where rs.PuId = prs.PuId  
  and (rs.team = prs.team or (rs.team is null and prs.team is null))  
  and (rs.shift = prs.shift or (rs.shift is null and prs.shift is null))  
  and (rs.Daystart = prs.Daystart or (rs.Daystart is null and prs.Daystart is null))  
  and rs.prodid = prs.prodid  
  and rs.starttime = prs.starttime  
  and rs.endtime = prs.endtime  
  ),  
  
 HygCleaningDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td.ScheduleId = @SchedHygCleaningId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td.StartTime <= rs.StartTime   
    THEN rs.StartTime   
    ELSE td.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td.EndTime >= rs.EndTime   
    THEN rs.EndTime   
    ELSE td.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs  
  left join dbo.#Delays td with (nolock)  
  on  td.PUId = prs.ReliabilityPUId   
  and td.starttime < rs.endtime  
  and td.endtime > rs.starttime   
  where rs.PuId = prs.PuId  
  and (rs.team = prs.team or (rs.team is null and prs.team is null))  
  and (rs.shift = prs.shift or (rs.shift is null and prs.shift is null))  
  and (rs.Daystart = prs.Daystart or (rs.Daystart is null and prs.Daystart is null))  
  and rs.prodid = prs.prodid  
  and rs.starttime = prs.starttime  
  and rs.endtime = prs.endtime  
  ),  
  
 EOProjectsDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td.ScheduleId = @SchedEOProjectsId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td.StartTime <= rs.StartTime   
    THEN rs.StartTime   
    ELSE td.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td.EndTime >= rs.EndTime   
    THEN rs.EndTime   
    ELSE td.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs  
  left join dbo.#Delays td with (nolock)  
  on  td.PUId = prs.ReliabilityPUId   
  and td.starttime < rs.endtime  
  and td.endtime > rs.starttime   
  where rs.PuId = prs.PuId  
  and (rs.team = prs.team or (rs.team is null and prs.team is null))  
  and (rs.shift = prs.shift or (rs.shift is null and prs.shift is null))  
  and (rs.Daystart = prs.Daystart or (rs.Daystart is null and prs.Daystart is null))  
  and rs.prodid = prs.prodid  
  and rs.starttime = prs.starttime  
  and rs.endtime = prs.endtime  
  ),  
  
 UnscheduledDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td.ScheduleId = @SchedUnscheduledId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td.StartTime <= rs.StartTime   
    THEN rs.StartTime   
    ELSE td.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td.EndTime >= rs.EndTime   
    THEN rs.EndTime   
    ELSE td.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs  
  left join dbo.#Delays td with (nolock)  
  on  td.PUId = prs.ReliabilityPUId    
  and td.starttime < rs.endtime  
  and td.endtime > rs.starttime   
  where rs.PuId = prs.PuId  
  and (rs.team = prs.team or (rs.team is null and prs.team is null))  
  and (rs.shift = prs.shift or (rs.shift is null and prs.shift is null))  
  and (rs.Daystart = prs.Daystart or (rs.Daystart is null and prs.Daystart is null))  
  and rs.prodid = prs.prodid  
  and rs.starttime = prs.starttime  
  and rs.endtime = prs.endtime  
  ),  
  
 CLAuditsDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td.ScheduleId = @SchedCLAuditsId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td.StartTime <= rs.StartTime   
    THEN rs.StartTime   
    ELSE td.StartTime   
    END  
    ),   
    (  
    CASE WHEN td.EndTime >= rs.EndTime   
    THEN rs.EndTime   
    ELSE td.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
         ), 0.0)  
  from @RunSummary rs  
  left join dbo.#Delays td with (nolock)  
  on  td.PUId = prs.ReliabilityPUId   
  and td.starttime < rs.endtime  
  and td.endtime > rs.starttime   
  where rs.PuId = prs.PuId  
  and (rs.team = prs.team or (rs.team is null and prs.team is null))  
  and (rs.shift = prs.shift or (rs.shift is null and prs.shift is null))  
  and (rs.Daystart = prs.Daystart or (rs.Daystart is null and prs.Daystart is null))  
  and rs.prodid = prs.prodid  
  and rs.starttime = prs.starttime  
  and rs.endtime = prs.endtime  
  ),  
  
 OperationsRuntime =  
  CalendarRuntime -   
  (  
  select COALESCE(SUM(  
   case  
   when  td.ScheduleId NOT IN (@SchedPRPolyId, @SchedUnscheduledId)  
     and td.ScheduleID is not null  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td.StartTime <= rs.StartTime   
    THEN rs.StartTime   
    ELSE td.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td.EndTime >= rs.EndTime   
    THEN rs.EndTime   
    ELSE td.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs  
  left join dbo.#Delays td with (nolock)  
  on  td.PUId = prs.ReliabilityPUId    
  and td.starttime < rs.endtime  
  and td.endtime > rs.starttime   
  where rs.PuId = prs.PuId  
  and (rs.team = prs.team or (rs.team is null and prs.team is null))  
  and (rs.shift = prs.shift or (rs.shift is null and prs.shift is null))  
  and (rs.Daystart = prs.Daystart or (rs.Daystart is null and prs.Daystart is null))  
  and rs.prodid = prs.prodid  
  and rs.starttime = prs.starttime  
  and rs.endtime = prs.endtime  
  ),  
  
 TotalUnits =  
  CASE   
  WHEN @BusinessType in (1,2,4)  
  THEN  (  
   SELECT sum(convert(float,t.value))   
   FROM dbo.#Tests t with (nolock)  
   JOIN @ProdLines pl   
   ON VarId = VarTotalUnitsId  
   and t.StartTime > prs.StartTime   
   AND t.StartTime <= prs.EndTime  
   and t.PLId = pl.PLId  
   and t.plid = prs.plid  
   )  
  WHEN @BusinessType = 3  
  THEN (  
   SELECT sum(convert(float,t.value))   
   FROM dbo.#Tests t with (nolock)  
   JOIN @LineProdVars lpv   
   ON t.VarId = lpv.VarId  
   AND t.StartTime > prs.StartTime   
   AND t.StartTime <= prs.EndTime  
   AND lpv.PLId = t.PLId  
   and t.plid = prs.plid  
   )  
  ELSE  NULL  
    END,  
  
 GoodUnits =   
  CASE    
  WHEN @BusinessType in (1,2)  
  THEN  (  
   SELECT sum(convert(float,t.value))   
   FROM dbo.#Tests t with (nolock)  
   JOIN @ProdLines pl   
   ON t.VarId = pl.VarGoodUnitsId  
   AND t.StartTime > prs.StartTime   
   AND t.StartTime <= prs.EndTime  
   and t.PLId = pl.PLId  
   and t.plid = prs.plid  
   )  
  
      WHEN @BusinessType = 3   
  THEN  (  
   SELECT sum(convert(float,t.value))   
   FROM dbo.#Tests t with (nolock)  
   JOIN @LineProdVars lpv   
   ON t.VarId = lpv.VarID  
   AND t.StartTime > prs.StartTime   
   AND t.StartTime <= prs.EndTime  
   and t.PLId = lpv.PLId  
   and t.plid = prs.plid  
   )  
  
  WHEN @BusinessType = 4  
  THEN  (  
   SELECT COALESCE (  
     Sum (coalesce(convert(float,Value), 0.0))  
          * SheetCount   
               * PacksInBundle   
               * CartonsInCase  
     ,0)  
   FROM dbo.#Tests t with (nolock)  
   JOIN @LineProdVars lpv   
   ON t.VarId = lpv.VarId  
   AND lpv.VarType = @ACPUnitsFlag  
   AND t.StartTime > prs.StartTime   
   AND t.StartTime <= prs.EndTime  
   and t.PLId = lpv.PLId  
   and t.plid = prs.plid  
   )  
   +   
   (  
   SELECT COALESCE(sum(convert(float,t.nvalue)), 0.0)  
   FROM dbo.#Tests t with (nolock)  
   JOIN @LineProdVars lpv   
   ON t.VarId = lpv.VarId  
   AND lpv.VarType = @HPUnitsFlag  
   AND t.StartTime > prs.StartTime   
   AND t.StartTime <= prs.EndTime  
   and t.PLId = lpv.PLId  
   and t.plid = prs.plid  
   )  
   +   
   (  
   SELECT COALESCE (  
     Sum (coalesce(convert(float,Value), 0.0))  
          * SheetCount   
                  * PacksInBundle   
                 ,0)  
   FROM dbo.#Tests t with (nolock)  
   JOIN @LineProdVars lpv   
   ON t.VarId = lpv.VarId  
   AND lpv.VarType = @TPUnitsFlag  
   AND t.StartTime > prs.StartTime   
   AND t.StartTime <= prs.EndTime  
   and t.PLId = lpv.PLId  
   and t.plid = prs.plid  
   )  
  ELSE  NULL  
  END,  
  
 RollWidth2Stage =  
  
  (  
  SELECT  avg(  
   case  
   when t.VarId = pl.VarPMRollWidthId    
   AND convert(float,t.Value,0) < (@DefaultPMRollWidth*1.1)  
   then convert(float,t.value)  
   else null  -- avg() should throw out any nulls from the count  
   end  
   )  
  FROM dbo.#Tests t with (nolock)  
  JOIN @ProdLines pl   
  on t.StartTime > prs.StartTime   
  AND t.StartTime <= prs.EndTime  
  and t.plid = prs.plid  
  and t.PLId = pl.PLId  
  ),  
  
 RollWidth3Stage =  
  
  (  
  SELECT  avg(  
   case  
   when t.VarId = pl.VarParentRollWidthId   
   AND convert(float,t.Value) < (@DefaultPMRollWidth*1.1)  
   then convert(float,t.value)  
   else null  -- avg() should throw out any nulls from the count  
   end  
   )  
  FROM dbo.#Tests t with (nolock)  
  JOIN @ProdLines pl   
  on t.StartTime > prs.StartTime   
  AND t.StartTime <= prs.EndTime  
  and t.plid = prs.plid  
  and t.PLId = pl.PLId  
  ),  
  
  
 LineSpeedAvg =  
  
  (  
  SELECT  avg(  
   case  
   when t.VarId = pl.VarLineSpeedId   
   then convert(float,t.value)  
   else null  -- avg() should throw out any nulls from the count  
   end  
   )  
  FROM dbo.#Tests t with (nolock)  
  JOIN @ProdLines pl   
  on t.StartTime > prs.StartTime   
  AND t.StartTime <= prs.EndTime  
  and t.plid = prs.plid  
  and t.PLId = pl.PLId  
  )  
  
   
FROM @ProdRecords prs  
  
  
update prs set  
  
 ProductionRuntime = CalendarRuntime - HolidayCurtailDT,  
 RejectUnits = TotalUnits - GoodUnits,  
  
 WebWidth =    
  CASE    
  WHEN  (   
   COALESCE(RollWidth2Stage,0) +   
   COALESCE(RollWidth3Stage,0) +   
   @DefaultPMRollWidth  
   ) = @DefaultPMRollWidth   
  THEN @DefaultPMRollWidth   
  ELSE COALESCE(RollWidth2Stage,RollWidth3Stage)  
  END  
    
from @ProdRecords prs  
  
  
update prs set  
  
 PlanningRuntime = ProductionRuntime -   
  (  
  select COALESCE(SUM(  
   case  
   when Downtime >= 120.0   
   AND td.ScheduleId IN (@SchedPlninterventionId, @SchedChangeOverId,   
     @SchedHygCleaningId, @SchedEOProjectsId)  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td.StartTime <= rs.StartTime   
    THEN rs.StartTime   
    ELSE td.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td.EndTime >= rs.EndTime   
    THEN rs.EndTime   
    ELSE td.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs  
  join dbo.#Delays td with (nolock)  
  on  td.PUId = prs.ReliabilityPUId   
  and td.starttime < rs.endtime  
  and td.endtime > rs.starttime   
  where rs.PuId = prs.PuId  
  and (rs.team = prs.team or (rs.team is null and prs.team is null))  
  and (rs.shift = prs.shift or (rs.shift is null and prs.shift is null))  
  and (rs.Daystart = prs.Daystart or (rs.Daystart is null and prs.Daystart is null))  
  and rs.prodid = prs.prodid  
  and rs.starttime = prs.starttime  
  and rs.endtime = prs.endtime  
  ),  
  
 RollsPerLog = FLOOR((WebWidth * @ConvertInchesToMM) / SheetWidth)  
  
from @ProdRecords prs  
  
  
update prs set  
 TargetUnits =   
  CASE @BusinessType  
      WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
   round(LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
   ProductionRuntime * StatFactor,0)  
  WHEN 4   
  THEN --Hanky lines in Neuss  
   round((LineSpeedTarget / StatFactor) * ProductionRuntime,0)   
   --@StatFactor is really StatUnit in Neuss!!!  
       ELSE        --Tissue/Towel/Napkins  
       round(LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
       (1/convert(float,SheetLength)) * RollsPerLog *   
       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       StatFactor,0)   
       END,  
  
 ActualUnits =   
  CASE @BusinessType  
  WHEN 1    
  THEN --Tissue/Towel  
   round(GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor,0)  
  WHEN 2   
  THEN --Napkins  GoodUnits = Stacks, no conversion needed.  
   round(GoodUnits * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor,0)  
  WHEN 3   
  THEN --Facial (Convert Good Units on ACP to Stat)  
   round(GoodUnits * StatFactor,0)  
  WHEN 4    
  THEN  --Hanky Lines in Neuss.  Good Units = Sheets.  
   round(GoodUnits / StatFactor,0)   
       --@StatFactor is really StatUnit [sheets per stat] in Neuss!!!  
  ELSE     --Else default to the Tissue/Towel Calc.  
   round(GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor,0)  
  END,  
--/*  
 OperationsTargetUnits =   
  CASE @BusinessType  
      WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
      round(LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       OperationsRuntime * StatFactor,0)  
       WHEN 4   
  THEN --Hanky lines in Neuss  
      round((LineSpeedTarget / StatFactor) * OperationsRuntime,0)   
          --@StatFactor is really StatUnit in Neuss!!!  
       ELSE  --Tissue/Towel/Napkins  
      round(LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
     (1/convert(float,SheetLength)) * RollsPerLog *   
      OperationsRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
     StatFactor,0)   
       END,  
  
 IdealUnits =   
  CASE @BusinessType  
      WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
   round(LineSpeedIdeal * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
   ProductionRuntime * StatFactor,0)  
  WHEN 4   
  THEN --Hanky lines in Neuss  
      round((LineSpeedIdeal / StatFactor) * ProductionRuntime,0)   
                  --@StatFactor is really StatUnit in Neuss!!!  
  ELSE        --Tissue/Towel/Napkins  
       round(LineSpeedIdeal * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
       (1/convert(float,SheetLength)) * RollsPerLog *   
       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       StatFactor,0)   
  END,     
     
 PlanningTargetUnits =   
  CASE @BusinessType  
  WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
  round((LineSpeedTarget  * (1/convert(float,RollsInPack))   
          * (1/convert(float,PacksInBundle))   
          * PlanningRuntime * StatFactor),0)  
  
  WHEN 4   
  THEN --Hanky lines in Neuss  
  round(((LineSpeedTarget / StatFactor) * PlanningRuntime),0)  
  
  ELSE --Tissue/Towel/Napkins  
  round((LineSpeedTarget  * @ConvertFtToMM * (1/convert(float,SheetCount))   
          * (1/convert(float,SheetLength)) * RollsPerLog * PlanningRuntime   
          * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle))   
          * StatFactor),0)  
  END   
  
from @ProdRecords prs  
  
--------------------------------------------------------------------------  
-- Section 31: Split the delays and calculate Split Uptime.  
--------------------------------------------------------------------------  
  
------------------------------------------------------------------------------------------  
--  Added #SplitEvents and #SplitUptime for   
--  Splitting Downtime 062904  JSJ  
-------------------------------------------------------------------------------------------  
-- insert records into #SplitEvents for each shift period in the report window.  
-- then update the rest of the table with summary data.  
-------------------------------------------------------------------------------------------  
  
insert into dbo.#SplitEvents   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 DayStart,  
 PrimaryId,  
 TEDetID,  
 TEFaultID,  
 ScheduleID,  
 CategoryID,  
 SubSystemId,  
 GroupCauseId,  
 LocationId,     
 LineStatus,  
 Downtime,  
 Uptime,  
 Stops,  
 StopsUnscheduled,  
 StopsMinor,  
 StopsEquipFails,  
 StopsProcessFailures,  
 StopsBlockedStarved,  
 StopsRateLoss,  
 StopsELP,   
 MinorEF,  
 ModerateEF,  
 MajorEF,  
 MinorPF,  
 ModeratePF,  
 MajorPF,  
 RateLossRatio,  
 Causes,  
 LineTargetSpeed,  
 LineActualSpeed,  
 LineIdealSpeed  
 )  
SELECT  distinct  
 case when td.StartTime < rls.StartTime  
 then rls.StartTime else td.StartTime end,  
 case when (coalesce(td.EndTime,rls.endtime) >= rls.EndTime)  
 then rls.EndTime else td.EndTime end,  
 rls.prodid,  
 td.plid,   
 td.puid,   
 td.pudesc,  
 rls.Team,  
 rls.Shift,  
 rls.DayStart,  
 td.PrimaryId,  
 td.TEDetID,  
 TEFaultID,  
 ScheduleID,  
 CategoryID,  
 SubSystemId,  
 GroupCauseId,  
 LocationId,     
 rls.LineStatus,  
 Downtime,  
 Uptime,  
 Stops,  
 COALESCE(StopsUnscheduled,0),  
 StopsMinor,  
 StopsEquipFails,  
 StopsProcessFailures,  
 StopsBlockedStarved,  
 StopsRateLoss,  
 StopsELP,   
 CASE    
 WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
 AND (td.Downtime/60.0 >= 10.0)  
 and (td.Downtime/60.0 <= 30.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
 AND (td.Downtime/60.0 > 30.0)  
 and (td.Downtime/60.0 <= 120.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
 AND (td.Downtime/60.0 > 120.0)  
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
 AND (td.Downtime/60.0 >= 10.0)  
 and (td.Downtime/60.0 <= 30.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
 AND (td.Downtime/60.0 > 30.0)  
 and (td.Downtime/60.0 <= 120.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
 AND (td.Downtime/60.0 > 120.0)  
 THEN 1  
 ELSE 0   
 END,  
 RateLossRatio,  
 1,  
 TargetSpeed,   
 LineActualSpeed,  
 IdealSpeed  
FROM  @Runs rls   
JOIN  dbo.#delays td with (nolock)   
on rls.puid = td.puid   
and (((rls.starttime < td.endtime or td.endtime is null)   
and rls.endtime > td.starttime) or inRptWindow = 0)  
WHERE inRptWindow = 1  
option (keep plan)  
  
  
update dbo.#SplitEvents set  
 SplitDowntime = DATEDIFF(ss,StartTime,EndTime)--,  
WHERE stopsRateloss is null  
  
  
update se set  
 ReportRLDowntime = DATEDIFF(ss,StartTime,EndTime) * RateLossRatio,  
 ReportRLELPDowntime =   
 case  
 WHEN (coalesce(se.CategoryId,0) <> @CatBlockStarvedId)  
 AND (se.CategoryId = @CatELPId)  
 then (DATEDIFF(ss,StartTime,EndTime) / 60.0) * RateLossRatio  
 else 0.0   
 end  
FROM dbo.#SplitEvents se with (nolock)  
JOIN @ProdUnits tpu   
ON  se.PUId = tpu.PUId  
WHERE  StopsRateloss = 1  
and StopsRateLoss is not null  
  
  
Update se SET   
 ReportELPDowntime =   
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (coalesce(se.CategoryId,0) <> @CatBlockStarvedId)  
  AND (se.CategoryId = @CatELPId)  
  THEN se.SplitDowntime  
  ELSE 0   
  END  
FROM dbo.#SplitEvents se with (nolock)  
JOIN @ProdUnits tpu   
ON se.PUId = tpu.PUId  
  
  
UPDATE se SET    
 ReportELPSchedDT =    
  CASE   
  WHEN se.ScheduleId NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId)   
  THEN se.SplitDowntime  
  ELSE 0   
  END  
FROM dbo.#SplitEvents se with (nolock)  
JOIN @ProdUnits tpu   
ON se.PUId = tpu.PUId  
WHERE tpu.PUDesc LIKE '%Converter%'  
and tpu.PUDesc NOT LIKE '%rate%loss%'  
  
  
-- after splitting events, there are some values that will   
-- no longer have any meaning and should not be included   
-- when summations are done...  
  
update dbo.#SplitEvents set  
 Downtime = null,  
 Uptime = null,  
 Stops = null,  
 StopsMinor = null,  
 StopsEquipFails = null,  
 StopsProcessFailures = null,  
 StopsELP = null,  
 StopsRateLoss = null,  
 StopsUnscheduled = null,  
 MinorEF = null,  
 ModerateEF = null,  
 MajorEF = null,  
 MinorPF = null,  
 ModeratePF = null,  
 MajorPF = null,  
 Causes = 0  
WHERE  (  
 SELECT count(*)   
 FROM dbo.#delays td with (nolock)  
 WHERE td.puid = dbo.#SplitEvents.puid   
 and td.starttime = dbo.#SplitEvents.starttime  
 ) = 0  
  
  
-- this field is used to simplify the initial insert to   
-- #splituptime, and to make that insert more efficient.  
-- the original version of that insert required a nested   
-- subquery, and adding this field allows us to eliminate   
-- that.  
  
update se1 set  
 se1.NextStartTime =   
  (  
  select top 1 starttime   
  from dbo.#SplitEvents se2 with (nolock)   
  where se1.puid = se2.puid  
--  and se1.seid < se2.seid  
  and se1.Endtime <= se2.StartTime  
--  order by se2.seid asc  
  order by se2.StartTime asc  
  )  
from dbo.#SplitEvents se1 with (nolock)  
  
  
-----------------------------------------------------------------  
-- get Uptime data  
-- NOTE that there are multiple inserts to #SplitUptime.  
-- Since we are not hitting the database for these inserts,   
-- this really isn't too bad.  But if we could figure out how   
-- to do all the work in just one insert, then we could add   
-- some efficiency and reduce the amount of code.  
-- On the other hand, it is easier to read through the code and   
-- see what's going on if the inserts are done separately.  
-----------------------------------------------------------------  
  
-- get the basic data for uptime between downtime events.  
  
insert into dbo.#SplitUptime  
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 DayStart,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 SplitUptime,  
 LineStatus  
 )  
SELECT distinct  
 case   
 when --se1.endtime between rls.starttime and rls.endtime  
   se1.endtime > rls.starttime and se1.endtime <= rls.endtime  
 then se1.EndTime  
 else rls.StartTime end,  
 case   
 when --NextStartTime between rls.starttime and rls.endtime  
   NextStartTime >= rls.starttime and NextStartTime < rls.endtime  
 then NextStartTime   
 else rls.EndTime end,  
 rls.prodid,   
 rls.PLID,  
 rls.puid,  
 se1.pudesc,  
 rls.Team,  
 rls.Shift,  
 rls.DayStart,  
 rls.TargetSpeed,  
 rls.IdealSpeed,  
 0,  
 NULL   
FROM @Runs rls   
join dbo.#SplitEvents se1 with (nolock)   
on rls.puid = se1.puid  
and ((rls.starttime < coalesce(se1.endtime,rls.endtime))   
and rls.endtime > se1.starttime)  
option (keep plan)  
  
  
-- get the uptime FROM the start of a shift/product to the first downtime event.  
insert into dbo.#SplitUptime   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 DayStart,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 SplitUptime,  
 LineStatus  
 )  
SELECT distinct  
 rls.starttime,  
 se.starttime,  
 rls.prodid,  
 rls.PLID,  
 rls.puid,  
 se.pudesc,  
 rls.Team,  
 rls.Shift,  
 rls.DayStart,  
 rls.TargetSpeed,  
 rls.IdealSpeed,  
 0,  
 NULL   
FROM  @Runs rls   
join  dbo.#SplitEvents se with (nolock)   
on  rls.puid = se.puid  
and (rls.starttime < se.starttime   
and  rls.endtime > se.starttime)  
and  se.StartTime =   
 (  
 SELECT min(StartTime)  
 FROM dbo.#SplitEvents se1 with (nolock)  
 where rls.puid = se1.puid  
 and rls.starttime <= se1.StartTime   
 and rls.endtime > se1.starttime  
 )  
option (keep plan)  
  
  
-- get the uptime FROM the timespans where no downtime occurred   
  
insert into dbo.#SplitUptime   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 Team,   
 Shift,  
 DayStart,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 SplitUptime   
 )  
SELECT distinct  
 rls.starttime,  
 rls.endtime,  
 rls.prodid,  
 rls.PLID,  
 rls.puid,  
 rls.Team,  
 rls.Shift,  
 rls.DayStart,  
 rls.TargetSpeed,  
 rls.IdealSpeed,  
 0  
FROM  @Runs rls    
WHERE    
 (  
 SELECT count(*)   
 FROM dbo.#SplitEvents se with (nolock)   
 where rls.puid = se.puid  
 and rls.starttime < se.endtime   
 and rls.endtime > se.starttime  
 and rls.prodid = se.prodid  
 and (rls.team = se.team or (rls.team is null and se.team is null))  
 and (rls.shift = se.shift or (rls.shift is null and se.shift is null))   
 and rls.plid = se.plid  
 ) = 0  
and  (  
 SELECT count(*)   
 FROM dbo.#SplitEvents se with (nolock)   
 WHERE rls.puid = se.puid  
 ) > 0  
option (keep plan)     
  
  
update dbo.#SplitUptime set  
 pudesc =    
  (  
  SELECT top 1 pudesc   
  FROM dbo.#SplitEvents se with (nolock)  
  WHERE se.puid = dbo.#SplitUptime.puid  
  ),  
 SplitUptime = DATEDIFF(ss,StartTime,EndTime),  
 suid =  
  (  
  SELECT seid  
  FROM dbo.#SplitEvents se with (nolock)  
  where se.puid = dbo.#SplitUptime.puid   
  and se.StartTime = dbo.#SplitUptime.EndTime  
  )  
  
  
update dbo.#SplitEvents set  
 SplitUptime =  
 (  
 SELECT sum(SplitUptime)  
 FROM dbo.#SplitUptime su with (nolock)  
 where su.puid = dbo.#SplitEvents.puid  
 and su.EndTime = dbo.#SplitEvents.StartTime  
 and stopsRateloss is null  
   )  
  
  
-- it would be good to find a way to write the above   
-- inserts so that we don't end up with entries that have   
-- startime = endtime.  then we could eliminate this   
-- delete statement.  However, it doesn't seem likely,  
-- since there are start and end times drawn from multiple   
-- sources within case statements.  
  
delete FROM dbo.#SplitUptime WHERE starttime = endtime   
  
  
-- get the LineStatus for "artificial" uptime records  
update su set  
 LineStatus = r.LineStatus  
from #SplitUptime su with (nolock)  
join @Runs r  
on su.puid = r.puid  
and --su.starttime between r.starttime and r.endtime  
 su.starttime >= r.starttime and su.starttime < r.endtime  
where suid is null  
  
  
-- add the uptime into the #SplitEvents  
  
insert into dbo.#SplitEvents   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 DayStart,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 Downtime,  
 SplitDowntime,  
 ReportRLDowntime,  
 Uptime,  
 SplitUptime,  
 LineStatus   
 )  
SELECT  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 DayStart,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 0,0,0,0,  
 SplitUptime,  
 LineStatus  
FROM dbo.#SplitUptime with (nolock)  
WHERE suid is null  
and  (  
 SELECT pu_desc   
 FROM dbo.prod_units with (nolock)   
 WHERE pu_id = dbo.#SplitUptime.puid  
 ) not like '%rate loss%'   
option (keep plan)  
  
  
update se set  
 ProductionRuntime = coalesce(splituptime,0) +  
  case  
  when  coalesce(se.scheduleid,0) <> @schedHolidayCurtailId  
  then  coalesce(se.splitdowntime,0)   
  else  0.0 end,  
 PaperRuntime = coalesce(splituptime,0) +  
  case  
  when  se.scheduleid in (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
          @SchedEOProjectsId, @SchedBlockedStarvedId)  
  or se.scheduleid is null    
  then  coalesce(se.splitdowntime,0)   
  else  0.0 end,  
 UnscheduledRptDT =   
--  case  
--  when (se.CategoryId <> @CatBlockStarvedId OR se.CategoryId IS NULL)  
--  AND  (se.ScheduleId = @SchedUnscheduledId OR se.ScheduleId IS NULL)  
--  then se.SplitDowntime  
--  else 0.0 end  
  case  
--20090316  
  WHEN (se.pudesc like '%reliability%' and se.pudesc not like '%converter reliability%')  
  AND coalesce(se.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  THEN se.SplitDowntime  
  WHEN (se.pudesc like '%converter reliability%' or se.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(se.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  THEN se.SplitDowntime  
  else 0.0   
  end  
from  dbo.#SplitEvents se with (nolock)  
  
  
-----------------------------------------------------------------------------  
-- Section 32: Sum of the Split Events data according to production "buckets"  
-----------------------------------------------------------------------------  
  
-------------------------------------------------------------------------------------------  
-- insert records into @TimeRangeSummary for each period in the report window.  
-- then update the rest of the table with summary data.  
-------------------------------------------------------------------------------------------  
  
  
  insert into @TimeRangeSummary  
   (  
   PLID,   
   puid,  
   StartTime,   
   EndTime,   
   prodid,   
   Team,   
   Shift,  
   DayStart,  
   ScheduleUnit  
   )  
  select distinct    
   prs.PLID,  
   prs.puid,  
   prs.StartTime,  
   prs.EndTime,  
   prs.prodid,  
   prs.Team,  
   prs.Shift,  
   prs.DayStart,  
   pu.ScheduleUnit  
  from @ProdRecords prs  
  join @produnits pu  
  on prs.puid = pu.puid  
  WHERE pu.pudesc like '%Converter Reliability%'   
  option (keep plan)  
  
  
 -- update the table with all summary data  
  
 update TRS set  
  
  TotalUnits  =  (  
       select sum(coalesce(prs.TotalUnits,0))  
       from @ProdRecords prs  
       join @produnits pu  
       on prs.puid = pu.puid  
       where trs.prodid = prs.ProdID   
       and prs.starttime >= trs.starttime   
       and prs.starttime < trs.endtime  
       and pu.scheduleunit = trs.scheduleunit  
       and  pu.pudesc not like '%rate loss%'  
       ),  
  
  GoodUnits  =  (  
       select sum(coalesce(prs.GoodUnits,0))  
       from @ProdRecords prs  
       join @produnits pu  
       on prs.puid = pu.puid  
       where trs.prodid = prs.ProdID   
       and prs.starttime >= trs.starttime   
       and prs.starttime < trs.endtime  
       and pu.scheduleunit = trs.scheduleunit  
       and  pu.pudesc not like '%rate loss%'  
       ),  
  RejectUnits =  (  
       select sum(coalesce(prs.RejectUnits,0))  
       from @ProdRecords prs  
       join @produnits pu  
       on prs.puid = pu.puid  
       where trs.prodid = prs.ProdID   
       and prs.starttime >= trs.starttime   
       and prs.starttime < trs.endtime  
       and pu.scheduleunit = trs.scheduleunit  
       and  pu.pudesc not like '%rate loss%'  
       ),  
  
  ActualCases  =  (  
       select sum(coalesce(prs.ActualUnits,0))  
       from @ProdRecords prs  
       join @produnits pu  
       on prs.puid = pu.puid  
       where trs.prodid = prs.ProdID   
       and prs.starttime >= trs.starttime   
       and prs.starttime < trs.endtime  
       and pu.scheduleunit = trs.scheduleunit  
       and  pu.pudesc not like '%rate loss%'  
       ),  
  
  IdealCases  =  (  
       select sum(prs.IdealUnits)  
       from @ProdRecords prs  
       join @produnits pu  
       on prs.puid = pu.puid  
       where trs.prodid = prs.ProdID   
       and prs.starttime >= trs.starttime   
       and prs.starttime < trs.endtime  
       and pu.scheduleunit = trs.scheduleunit  
       and  pu.pudesc not like '%rate loss%'  
       ),  
  
  TargetCases  =  (  
       select sum(prs.TargetUnits)  
       from @ProdRecords prs  
       join @produnits pu  
       on prs.puid = pu.puid  
       where trs.prodid = prs.ProdID   
       and prs.starttime >= trs.starttime   
       and prs.starttime < trs.endtime  
       and pu.scheduleunit = trs.scheduleunit  
       and  pu.pudesc not like '%rate loss%'  
       ),  
  
  OperationsTargetUnits  =  (  
           select sum(prs.OperationsTargetUnits)  
           from @ProdRecords prs  
           join @produnits pu  
           on prs.puid = pu.puid  
           where prs.prodid = trs.ProdID   
           and prs.starttime >= trs.starttime   
           and prs.starttime < trs.endtime  
           and pu.scheduleunit = trs.scheduleunit  
           and pudesc not like '%rate loss%'  
           ),  
  
  PlanningTargetUnits  =  (  
          select sum(prs.PlanningTargetUnits)  
          from @ProdRecords prs  
          join @produnits pu  
          on prs.puid = pu.puid  
          where trs.prodid = prs.ProdID   
          and prs.starttime >= trs.starttime   
          and prs.starttime < trs.endtime  
          and pu.scheduleunit = trs.scheduleunit  
          and pu.pudesc not like '%rate loss%'  
          ),  
  
  ProductionRuntime  =  (  
          select sum(coalesce(se.ProductionRuntime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.puid = se.puid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  
  SplitDowntime   =  (  
          select sum(coalesce(se.SplitDowntime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  SplitSchedDowntime  =  (  
          select sum(coalesce(se.SplitDowntime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime < trs.endtime   
          and (se.endtime > trs.starttime or se.endtime is null)  
          and UnscheduledRptDT = 0  
          ),  
  SplitUptime    =  (  
          select sum(coalesce(se.SplitUptime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  TotalStops     =  (  
          select sum(coalesce(se.stops,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  MinorStops     =  (  
          select sum(coalesce(se.StopsMinor,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  EquipFails     =  (  
          select sum(coalesce(se.StopsEquipFails,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  MinorBD      =  (  
          select sum(coalesce(se.MinorEF,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  ModerateBD     =  (  
          select sum(coalesce(se.ModerateEF,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  MajorBD      =  (  
          select sum(coalesce(se.MajorEF,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  ProcessFailures   =  (  
          select sum(coalesce(se.StopsProcessFailures,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  MinorPF      =  (  
          select sum(coalesce(se.MinorPF,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  ModeratePF     =  (  
          select sum(coalesce(se.ModeratePF,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  MajorPF      =  (  
          select sum(coalesce(se.MajorPF,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  ELPStops     =  (  
          select sum(coalesce(se.StopsELP,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  SplitELPDowntime  =   (  
          select sum(coalesce(se.ReportELPDowntime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  
-- rate loss related fields need to be compared based on plid.  
-- this is because trs is originally populated from @ProdRecords,  
-- which only has puids for reliability units on a line.  
-- rate loss units are not tracked in @ProdRecords.  
  
  RateLossStops    = (  
          select sum(coalesce(se.StopsRateLoss,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.plid = se.plid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  RateLossDT     = (  
          select sum(coalesce(se.ReportRLDowntime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.plid = se.plid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  RateLossELPDT    =  (  
          select sum(coalesce(se.reportRLELPDowntime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.plid = se.plid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  PaperRuntime    =  (  
          select sum(coalesce(se.PaperRuntime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.puid = se.puid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  UnscheduledStops   =  (  
          select sum(coalesce(se.StopsUnscheduled,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.prodid = se.prodid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  UnscheduledSplitDT   = (  
          select sum(coalesce(se.UnscheduledRptDT,0))  
          from  dbo.#SplitEvents se with (nolock)  
          where trs.puid = se.puid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  RawUptime      =  (  
          select sum(coalesce(se.Uptime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.puid = se.puid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  RawDowntime   =   (  
          select sum(coalesce(se.Downtime,0))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.puid = se.puid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  shift_starttime   = (  
          select start_time  
          from @crewschedule cs  
          where starttime >= cs.start_time  
          and starttime < cs.end_time  
          and team = cs.crew_desc  
          and shift = cs.shift_desc  
          and trs.ScheduleUnit = cs.pu_id  
          ),  
  PRPolyCEvents    =  (  
          select sum((case  
              when ScheduleID = @SchedPRPolyId  
              then 1  -- coalesce(stops,0)  -- 2005-12-15 Vince King Rev1.06  
              else 0   
              end))  
          from dbo.#SplitEvents se with (nolock)  
          where trs.puid = se.puid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          ),  
  PRPolyCDowntime    =  (  
          select sum((case  
              when ScheduleID = @SchedPRPolyId  
              then downtime / 60.0  
              else 0.0   
              end))   
          from dbo.#SplitEvents se with (nolock)  
          where trs.puid = se.puid  
          and se.starttime >= trs.starttime   
          and se.starttime < trs.endtime  
          )  
  
 from @TimeRangeSummary trs  
  
 update trs set  
   ProdCode = p.prod_code,   
   ProdDesc = p.prod_desc  
 from @TimeRangeSummary trs  
 join @products p  
 on trs.prodid = p.prod_id  
  
  
-----------------------------------------------------------  
 ReturnResultSets:  
-----------------------------------------------------------  
  
--select * from @dimensions  
--select * from @Runs  
--select * from @RunSummary  
--select * from @prodrecords  
--select * from #delays  
--where stopsrateloss is not null  
--and starttime < '2005-09-01 09:00:00'  
--select * from #SplitUptime  
--select sum(downtime)   
--from #SplitEvents  
--where team = 'C'  
--and stopsrateloss is not null  
--order by starttime  
--select * from @TimeRangeSummary  
--select * from @produnits  
  
  
 ----------------------------------------------------------------------------------------------------  
 -- Error Messages.  
 ----------------------------------------------------------------------------------------------------  
  
 -- if there are errors from the parameter validation, then return them and skip the rest of the results  
  
 if (select count(*) from @ErrorMessages) > 0  
  
 ----------------------------------------------------------------------------------  
 -- Section 33: if there are errors, return the Error Message result set  
 ----------------------------------------------------------------------------------  
  
 begin  
  
 SELECT ErrMsg  
 FROM @ErrorMessages  
  
 end  
  
 else  
  
 begin  
   
  
 ----------------------------------------------------------------------------------------------------  
 -- Error Messages.  
 ----------------------------------------------------------------------------------------------------  
  
 -- if there are no errors, we still need a resultset as a place holder in the xls template.   
  
 ----------------------------------------------------------------------------------  
 -- Section 34: return the empty Error Message result set  
 ----------------------------------------------------------------------------------  
  
  
 SELECT ErrMsg  
 FROM @ErrorMessages  
  
 -----------------------------------------------------------  
 -- return the parameters used in this sp to the template.  
 -----------------------------------------------------------  
  
 select  
 @ProdLineList     [@ProdLineList],  
 @DelayTypeList    [@DelayTypeList],  
 @PropCvtgProdFactorId  [@PropCvtgProdFactorId],  
 @DefaultPMRollWidth   [@DefaultPMRollWidth],  
 @ConvertFtToMM    [@ConvertFtToMM],  
 @ConvertInchesToMM   [@ConvertInchesToMM],  
 @BusinessType     [@BusinessType],  
 @UserName      [@UserName],  
 @RptTitle      [@RptTitle],  
 @RptPageOrientation   [@RptPageOrientation],  
 @RptPageSize     [@RptPageSize],  
 @RptPercentZoom    [@RptPercentZoom],  
 @RptTimeout     [@RptTimeout],  
 @RptFileLocation    [@RptFileLocation],  
 @RptConnectionString  [@RptConnectionString],  
 @RptGroupBy     [@RptGroupBy],  
 --@LineStatusList    [@LineStatusList],  
 COALESCE(@LineStatusList,'All')  [@LineStatusList],  
 @SchedPRPolyId    [@SchedPRPolyId],  
 @IncludeTeam    [@IncludeTeam]  
  
  
 ----------------------------------------------------------------------------------  
 -- Section 35: Result set 3 - Team Averages  
 ----------------------------------------------------------------------------------  
  
 if @IncludeTeam = 1  
 begin  
  
 ----------------------------------------------------------------------------------------------------  
 -- Team Average for all products.  
 ----------------------------------------------------------------------------------------------------  
 insert into dbo.#TeamAverages  
 SELECT  ' ' [Team Averages],  
  Team [Team], -- Team  
  COUNT(distinct shift_starttime) [Total Shifts],   
  sum(CONVERT(float, Coalesce(ProductionRuntime, 0.0)) / 3600.0) 'Production Time [hrs]',  
  avg(coalesce(TotalStops,0)) [Total Stops],  
  CASE WHEN sum(coalesce(ActualCases,0)) = 0 THEN 0   
   ELSE  (sum(CONVERT(float, coalesce(TotalStops,0)))   
    / sum(CONVERT(float, coalesce(ActualCases,0)))) * 1000 END [Stops Per MSU],  
  avg(coalesce(UnscheduledStops,0)) [Unscheduled Stops],  
  avg(coalesce(MinorStops,0)) [Minor Stops],  
  avg(coalesce(EquipFails,0)) [Equipment Failures],  
  avg(coalesce(ProcessFailures,0)) [Process Failures],  
  avg(CONVERT(float, Coalesce(RawDowntime, 0.0))) / 60.0 [Raw Downtime],   
  avg(CONVERT(float, Coalesce(SplitDowntime, 0.0))) / 60.0 [Split Downtime],  
  avg(CONVERT(float, Coalesce(UnscheduledSplitDT, 0.0))) / 60.0 [Unscheduled Split DT],   
  avg(CONVERT(float, Coalesce(RawUptime, 0.0))) / 60.0 [Raw Uptime],   
  avg(CONVERT(float, Coalesce(SplitUptime, 0.0))) / 60.0 [Split Uptime],  
  0 [Planned Availability],  
  0 [Unplanned MTBF],  
  0 [Unplanned MTTR],  
  case  
  when sum(targetcases) = 0  
  then 0  
  else sum(CONVERT(float, COALESCE(ActualCases, 0))) /   
    round(sum(CONVERT(float, TargetCases)),0)   
  end [CVPR %],  
  AVG(coalesce(ELPStops,0)) [ELP Stops],   
  ROUND(avg(CONVERT(float,Coalesce(SplitELPDownTime, 0)/ 60.0 )),2) [ELP Losses (Min)],   
  
  
  CASE  WHEN  sum(CONVERT(float, Coalesce(PaperRuntime, 0))   
   ) > 0.0   
   THEN  sum(CONVERT(float, Coalesce(SplitELPDowntime, 0))  
    + convert(float, coalesce(RateLossELPDT, 0))  
    )     
    / sum(CONVERT(float, Coalesce(PaperRuntime, 0))  
    )   
   ELSE 0   
  END [ELP %],    
  
  AVG(coalesce(RateLossStops,0)) [Rate Loss Events],  
  AVG(CONVERT(float, coalesce(RateLossDT,0))/ 60.0 ) [Rate Loss Effective Downtime],  
    
  CASE WHEN sum(CONVERT(float, ProductionRuntime)   
   ) > 0   
       THEN sum(CONVERT(float, Coalesce(RateLossDT, 0)))   
      / sum(CONVERT(float, ProductionRuntime)   
   )  
       ELSE 0 END [Rate Loss %],  
  
    
  avg(coalesce(TotalUnits,0)) [Total Units],  
  avg(coalesce(GoodUnits,0)) [Good Units],  
  avg(coalesce(TotalUnits,0) - coalesce(GoodUnits,0)) [Reject Units],  
  CASE WHEN sum(Coalesce(TotalUnits, 0)) = 0 THEN 0  
   ELSE (sum(CONVERT(float, coalesce(TotalUnits,0)) - CONVERT(float, coalesce(GoodUnits,0)))) /   
    sum(CONVERT(float, coalesce(TotalUnits,0))) END [Unit Broke %],  
  AVG(coalesce(ActualCases,0)) [Actual Stat Cases],  
  AVG(TargetCases) [Reliability Target Stat Cases],  
  case  when sum(OperationsTargetUnits) = 0   
    THEN 0.0     
    else (sum(CONVERT(float, coalesce(ActualCases,0))) / sum(CONVERT(float, OperationsTargetUnits)))  
    END [Operations Efficiency %],   
  AVG(OperationsTargetUnits) [Operations Target Stat Cases],  
  CASE  WHEN sum(PlanningTargetUnits) = 0   
    THEN 0.0  
    else (sum(CONVERT(float, ActualCases)) / sum(CONVERT(float, PlanningTargetUnits)))  
    END [Planning Efficiency %],   
  AVG(coalesce(PlanningTargetUnits,0)) [Planning Target Stat Cases],  
  AVG(coalesce(MinorBD,0)) [Minor Equipment Failures],  
  AVG(coalesce(ModerateBD,0)) [Moderate Equipment Failures],  
  AVG(coalesce(MajorBD,0)) [Major Equipment Failures],  
  AVG(coalesce(MinorPF,0)) [Minor Process Failures],  
  AVG(coalesce(ModeratePF,0)) [Moderate Process Failures],  
  AVG(coalesce(MajorPF,0)) [Major Process Failures],  
  case   
  when sum(PRPolyCEvents) > 0  
  then sum(PRPolyCDowntime) / sum(PRPolyCEvents)  
  else null  
  end [Avg PRoll Change Time],  
  CASE WHEN SUM(CONVERT(FLOAT,IdealCases)) > 0       
     THEN SUM(CASE  WHEN IdealCases IS NOT NULL    
         THEN CONVERT(FLOAT,ActualCases)   
         ELSE 0            
         END)              
     / SUM(CONVERT(FLOAT,IdealCases))  
       ELSE NULL END [CVTI %]  
 FROM @TimeRangeSummary  
 group BY Team   
 ORDER BY Team   
 option (keep plan)  
  
 update dbo.#TeamAverages set  
  [Planned Availability] =   
   case  when [Split Uptime] + [Unscheduled Split DT] > 0   
    then [Split Uptime] / ([Split Uptime] + [Unscheduled Split DT])       
    else 0 end,  
  [Unplanned MTBF] =   
   case when [Unscheduled Stops] > 0   
    then [Split Uptime] / [Unscheduled Stops]  
    else 0 end,  
  [Unplanned MTTR] =   
   case when [Unscheduled Stops] > 0   
    then [Unscheduled Split DT]/[Unscheduled Stops]  
    else 0 end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#TeamAverages with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#TeamAverages with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#TeamAverages', @LanguageId)  
 end  
  
 execute sp_executesql @SQL   
  
  
 ----------------------------------------------------------------------------------  
 -- Section 36: Result set 4 - Line Averages  
 ----------------------------------------------------------------------------------  
  
 ----------------------------------------------------------------------------------------------------  
 -- Average of all data for the Line (All Products).  
 ----------------------------------------------------------------------------------------------------  
 insert into dbo.#LineAverages  
 SELECT  'Line Averages' [Line Averages],  
  ' ' [Team], -- Team  
  COUNT(distinct shift_starttime) [Total Shifts],  
  sum(CONVERT(float, ProductionRuntime) / 3600.0  
   ) [Run Hours],  
  avg(coalesce(TotalStops,0)) [Total Stops],  
  CASE WHEN sum(coalesce(ActualCases,0)) = 0 THEN 0   
   ELSE  (sum(CONVERT(float, coalesce(TotalStops,0)))   
    / sum(CONVERT(float, coalesce(ActualCases,0)))) * 1000 END [Stops Per MSU],  
  avg(coalesce(UnscheduledStops,0)) [Unscheduled Stops],  
  avg(coalesce(MinorStops,0)) [Minor Stops],  
  avg(coalesce(EquipFails,0)) [Equipment Failures],  
  avg(coalesce(ProcessFailures,0)) [Process Failures],  
  avg(CONVERT(float, Coalesce(RawDowntime, 0.0))) / 60.0 [Raw Downtime],   
  avg(CONVERT(float, Coalesce(SplitDowntime, 0.0))) / 60.0 [Split Downtime],   
  avg(CONVERT(float, Coalesce(UnscheduledSplitDT, 0.0))) / 60.0 [Unscheduled Split DT],   
  avg(CONVERT(float, Coalesce(RawUptime, 0.0))) / 60.0 [Raw Uptime],   
  avg(CONVERT(float, Coalesce(SplitUptime, 0.0))) / 60.0 [Split Uptime],   
  0 [Planned Availability],  
  0 [Unplanned MTBF],  
  0 [Unplanned MTTR],  
  case  
  when sum(targetcases) = 0  
  then 0  
  else sum(CONVERT(float, COALESCE(ActualCases, 0))) /   
    round(sum(CONVERT(float, targetCases)),0)   
  end [CVPR %],  
  AVG(coalesce(ELPStops,0)) [ELP Stops],   
  ROUND(avg(CONVERT(float,Coalesce(SplitELPDownTime, 0)/ 60.0 )),2) [ELP Losses (Min)],   
  
  CASE  WHEN  sum(CONVERT(float, Coalesce(PaperRuntime, 0))   
   ) > 0.0   
   THEN  sum(CONVERT(float, Coalesce(SplitELPDowntime, 0))  
    + convert(float, coalesce(RateLossELPDT, 0))  
    )     
    / sum(CONVERT(float, Coalesce(PaperRuntime, 0))  
    )   
   ELSE 0   
  END [ELP %],    
  
  AVG(coalesce(RateLossStops,0)) [Rate Loss Events],  
  AVG(CONVERT(float, coalesce(RateLossDT,0))/ 60.0 ) [Rate Loss Effective Downtime],  
    
  CASE WHEN sum(CONVERT(float, ProductionRuntime)   
   ) > 0   
       THEN sum(CONVERT(float, Coalesce(RateLossDT, 0)))   
      / sum(CONVERT(float, ProductionRuntime)   
   )  
       ELSE 0 END [Rate Loss %],  
    
  avg(coalesce(TotalUnits,0)) [Total Units],  
  avg(coalesce(GoodUnits,0)) [Good Units],  
  avg(coalesce(TotalUnits,0) - coalesce(GoodUnits,0)) [Reject Units],  
  CASE WHEN sum(Coalesce(TotalUnits, 0)) = 0 THEN 0  
   ELSE (sum(CONVERT(float, coalesce(TotalUnits,0)) - CONVERT(float, coalesce(GoodUnits,0)))) /   
    sum(CONVERT(float, coalesce(TotalUnits,0))) END [Unit Broke %],  
  AVG(coalesce(ActualCases,0)) [Actual Stat Cases],  
  AVG(targetCases) [Reliability Target Stat Cases],  
  case  when sum(OperationsTargetUnits) = 0   
    THEN 0.0  
    else (sum(CONVERT(float, coalesce(ActualCases,0))) / sum(CONVERT(float,OperationsTargetUnits)))  
    END [Operations Efficiency %],   
  AVG(OperationsTargetUnits) [Operations Target Stat Cases],  
  CASE  WHEN sum(PlanningTargetUnits) = 0   
    THEN 0.0  
    else (sum(CONVERT(float, ActualCases)) / sum(CONVERT(float, PlanningTargetUnits)))  
    END [Planning Efficiency %],   
  AVG(coalesce(PlanningTargetUnits,0)) [Planning Target Stat Cases],  
  AVG(coalesce(MinorBD,0)) [Minor Equipment Failures],  
  AVG(coalesce(ModerateBD,0)) [Moderate Equipment Failures],  
  AVG(coalesce(MajorBD,0)) [Major Equipment Failures],  
  AVG(coalesce(MinorPF,0)) [Minor Process Failures],  
  AVG(coalesce(ModeratePF,0)) [Moderate Process Failures],  
  AVG(coalesce(MajorPF,0)) [Major Process Failures],  
  case   
  when sum(PRPolyCEvents) > 0  
  then sum(PRPolyCDowntime) / sum(PRPolyCEvents)  
  else null  
  end [Avg PRoll Change Time],  
  CASE WHEN SUM(CONVERT(FLOAT,IdealCases)) > 0       
     THEN SUM(CASE  WHEN IdealCases IS NOT NULL    
         THEN CONVERT(FLOAT,ActualCases)   
         ELSE 0            
         END)              
     / SUM(CONVERT(FLOAT,IdealCases))  
       ELSE NULL END [CVTI %]  
 FROM @TimeRangeSummary  
 option (keep plan)  
  
 update dbo.#LineAverages set  
  [Planned Availability] =   
   case  when [Split Uptime] + [Unscheduled Split DT] > 0   
    then [Split Uptime] / ([Split Uptime] + [Unscheduled Split DT])       
    else 0 end,  
  [Unplanned MTBF] =   
   case when [Unscheduled Stops] > 0   
    then [Split Uptime] / [Unscheduled Stops]  
    else 0 end,  
  [Unplanned MTTR] =   
   case when [Unscheduled Stops] > 0   
    then [Unscheduled Split DT]/[Unscheduled Stops]  
    else 0 end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineAverages with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#LineAverages with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineAverages', @LanguageId)  
 end  
  
 execute sp_executesql @SQL   
  
 end  -- @IncludeTeam = 1  
  
 ----------------------------------------------------------------------------------  
 -- Section 37: Result set 5 - Summary of data, without regard to product  
 ----------------------------------------------------------------------------------  
  
 ----------------------------------------------------------------------------------------------------  
 -- All Products.  
 ----------------------------------------------------------------------------------------------------  
  
 insert into dbo.#AllProducts  
 SELECT  
  Daystart [Day],   
  Team [Team], -- Team  
  Shift [Shift], -- Shift  
  sum(CONVERT(float, Coalesce(ProductionRuntime,0.0)) / 3600.0) 'Production Time [hrs]',  
  sum(coalesce(TotalStops,0)) [Total Stops],  
  CASE WHEN sum(coalesce(ActualCases,0)) = 0 THEN 0   
   ELSE  (sum(CONVERT(float, coalesce(TotalStops,0)))   
    / sum(CONVERT(float, coalesce(ActualCases,0)))) * 1000 END [Stops Per MSU],  
  sum(coalesce(UnscheduledStops,0)) [Unscheduled Stops],  
  sum(coalesce(MinorStops,0)) [Minor Stops],  
  sum(coalesce(EquipFails,0)) [Equipment Failures],  
  sum(coalesce(ProcessFailures,0)) [Process Failures],  
  sum(CONVERT(float, Coalesce(RawDowntime, 0.0))) / 60.0 [Raw Downtime],   
  SUM(CONVERT(float, Coalesce(SplitDowntime, 0.0))) / 60.0 [Split Downtime],   
  SUM(CONVERT(float, Coalesce(UnscheduledSplitDT, 0.0))) / 60.0 [Unscheduled Split DT],   
  SUM(CONVERT(float, Coalesce(RawUptime, 0.0))) / 60.0 [Raw Uptime],   
  SUM(CONVERT(float, Coalesce(SplitUptime, 0.0))) / 60.0 [Split Uptime],   
  0 [Planned Availability],  
  0 [Unplanned MTBF],  
  0 [Unplanned MTTR],  
  case  
  when sum(targetcases) = 0  
  then 0  
  else sum(CONVERT(float, COALESCE(ActualCases, 0))) /   
    round(sum(CONVERT(float, targetCases)),0)   
  end [CVPR %],  
  sum(coalesce(ELPStops,0)) [ELP Stops],  
  round(sum(CONVERT(float,Coalesce(SplitELPDownTime, 0)/ 60.0 )),2) [ELP Losses (Mins)],  
  
  CASE  WHEN  sum(CONVERT(float, Coalesce(PaperRuntime, 0))   
   ) > 0.0   
   THEN  sum(CONVERT(float, Coalesce(SplitELPDowntime, 0))  
    + convert(float, coalesce(RateLossELPDT, 0))  
    )     
    / sum(CONVERT(float, Coalesce(PaperRuntime, 0))  
    )   
   ELSE 0   
  END [ELP %],   
  
  sum(coalesce(RateLossStops,0)) [Rate Loss Events],  
  sum(CONVERT(float, coalesce(RateLossDT,0))/ 60.0 )  
   [Rate Loss Effective Downtime],  
  
  CASE WHEN sum(CONVERT(float, coalesce(ProductionRuntime,0))) > 0   
       THEN sum(CONVERT(float, Coalesce(RateLossDT, 0)))   
      /   
   sum(CONVERT(float, coalesce(ProductionRuntime,0)))  
       ELSE 0 END [Rate Loss %],  
  
  sum(coalesce(TotalUnits,0)) [Total Units],  
  sum(coalesce(GoodUnits,0)) [Good Units],  
  sum(coalesce(TotalUnits,0) - coalesce(GoodUnits,0)) [Reject Units],  
  (CASE WHEN sum(coalesce(TotalUnits,0)) = 0 THEN 0  
   ELSE sum(CONVERT(float, coalesce(TotalUnits,0)) - CONVERT(float, coalesce(GoodUnits,0))) /   
    sum(CONVERT(float, coalesce(TotalUnits,0))) END) [Unit Broke %],  
  
  sum(coalesce(ActualCases,0)) [Actual Stat Cases],  
  round(sum(targetCases),0) [Reliability Target Stat Cases],  
  case  when round(sum(OperationsTargetUnits),0) = 0   
    THEN 0.0  
    else (sum(CONVERT(float, coalesce(ActualCases,0))) / round(sum(CONVERT(float, OperationsTargetUnits)),0))  
    END [Operations Efficiency %],  
  round(sum(OperationsTargetUnits),0) [Operations Target Stat Cases],  
  (CASE WHEN round(sum(PlanningTargetUnits),0) = 0   
    THEN 0.0  
    else (sum(CONVERT(float, coalesce(ActualCases,0))) / round(sum(CONVERT(float, PlanningTargetUnits)),0))  
    END) [Planning Efficiency %],  
  round(sum(PlanningTargetUnits),0) [Planning Target Stat Cases],  
  
  sum(coalesce(MinorBD,0)) [Minor Equipment Failures],  
  sum(coalesce(ModerateBD,0)) [Moderate Equipment Failures],  
  sum(coalesce(MajorBD,0)) [Major Equipment Failures],  
  sum(coalesce(MinorPF,0)) [Minor Process Failures],  
  sum(coalesce(ModeratePF,0)) [Moderate Process Failures],  
  sum(coalesce(MajorPF,0)) [Major Process Failures],  
  case   
  when sum(PRPolyCEvents) > 0  
  then sum(PRPolyCDowntime) / sum(PRPolyCEvents)  
  else null  
  end [Avg PRoll Change Time],  
  CASE WHEN SUM(CONVERT(FLOAT,IdealCases)) > 0       
     THEN SUM(CASE  WHEN IdealCases IS NOT NULL    
         THEN CONVERT(FLOAT,ActualCases)   
         ELSE 0            
         END)              
     / SUM(CONVERT(FLOAT,IdealCases))  
       ELSE NULL END [CVTI %]  
 FROM  @TimeRangeSummary trs  
 group BY Daystart, Shift, Team   
 ORDER BY Daystart, Shift, Team  
 option (keep plan)  
  
 update dbo.#AllProducts set  
  [Planned Availability] =   
   case  when [Split Uptime] + [Unscheduled Split DT] > 0   
    then [Split Uptime] / ([Split Uptime] + [Unscheduled Split DT])       
    else 0 end,  
  [Unplanned MTBF] =   
   case when [Unscheduled Stops] > 0   
    then [Split Uptime] / [Unscheduled Stops]  
    else 0 end,  
  [Unplanned MTTR] =   
   case when [Unscheduled Stops] > 0   
    then [Unscheduled Split DT]/[Unscheduled Stops]  
    else 0 end  
  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#AllProducts with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#AllProducts with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#AllProducts', @LanguageId)  
 end  
  
 execute sp_executesql @SQL   
  
 ----------------------------------------------------------------------------------  
 -- Section 38: Result set 6 - Summary of data, including by Product  
 ----------------------------------------------------------------------------------  
  
 ----------------------------------------------------------------------------------------------------  
 -- By Product.  
 ----------------------------------------------------------------------------------------------------  
 insert into dbo.#ByProduct  
 SELECT Prod_Code [Product],   
  (select prod_desc from products with (nolock) where prod_id = prodid)  [Prod Desc],   
  Daystart [Day],   
  Team [Team],   
  Shift [Shift],   
  sum(CONVERT(float, Coalesce(ProductionRuntime,0.0)) / 3600.0) 'Production Time [hrs]',  
  sum(coalesce(TotalStops,0)) [Total Stops],  
  CASE WHEN sum(coalesce(ActualCases,0)) = 0 THEN 0   
   ELSE  (sum(CONVERT(float, coalesce(TotalStops,0)))   
    / sum(CONVERT(float, coalesce(ActualCases,0)))) * 1000 END [Stops Per MSU],  
  sum(coalesce(UnscheduledStops,0)) [Unscheduled Stops],  
  sum(coalesce(MinorStops,0)) [Minor Stops],  
  sum(coalesce(EquipFails,0)) [Equipment Failures],  
  sum(coalesce(ProcessFailures,0)) [Process Failures],  
  sum(CONVERT(float, Coalesce(RawDowntime, 0.0))) / 60.0 [Raw Downtime],   
  SUM(CONVERT(float, Coalesce(SplitDowntime, 0.0))) / 60.0 [Split Downtime],   
  SUM(CONVERT(float, Coalesce(UnscheduledSplitDT, 0.0))) / 60.0 [Unscheduled Split DT],   
  SUM(CONVERT(float, Coalesce(RawUptime, 0.0))) / 60.0 [Raw Uptime],   
  SUM(CONVERT(float, Coalesce(SplitUptime, 0.0))) / 60.0 [Split Uptime],   
  0 [Planned Availability],  
  0 [Unplanned MTBF],  
  0 [Unplanned MTTR],  
  case  
  when sum(targetcases) = 0  
  then 0  
  else sum(CONVERT(float, COALESCE(ActualCases, 0))) /   
    round(sum(CONVERT(float, targetCases)),0)   
  end [CVPR %],  
  sum(coalesce(ELPStops,0)) [ELP Stops],  
  round(sum(CONVERT(float,Coalesce(SplitELPDownTime, 0)/ 60.0 )),2) [ELP Losses (Mins)],  
  
  CASE  WHEN  sum(CONVERT(float, Coalesce(PaperRuntime, 0))   
   ) > 0.0   
   THEN  sum(CONVERT(float, Coalesce(SplitELPDowntime, 0))  
    + convert(float, coalesce(RateLossELPDT, 0))  
    )     
    / sum(CONVERT(float, Coalesce(PaperRuntime, 0))  
    )   
   ELSE 0   
  END [ELP %],   
  
  sum(coalesce(RateLossStops,0)) [Rate Loss Events],  
  sum(CONVERT(float, coalesce(RateLossDT,0))/ 60.0 )  
   [Rate Loss Effective Downtime],  
  
  CASE WHEN sum(CONVERT(float, coalesce(ProductionRuntime,0))) > 0   
       THEN sum(CONVERT(float, Coalesce(RateLossDT, 0)))   
      /   
   sum(CONVERT(float, coalesce(ProductionRuntime,0)))  
       ELSE 0 END [Rate Loss %],  
  
  sum(coalesce(TotalUnits,0)) [Total Units],  
  sum(coalesce(GoodUnits,0)) [Good Units],  
  sum(coalesce(TotalUnits,0) - coalesce(GoodUnits,0)) [Reject Units],  
  (CASE WHEN sum(coalesce(TotalUnits,0)) = 0 THEN 0  
   ELSE sum(CONVERT(float, coalesce(TotalUnits,0)) - CONVERT(float, coalesce(GoodUnits,0))) /   
    sum(CONVERT(float, coalesce(TotalUnits,0))) END) [Unit Broke %],  
  
  sum(coalesce(ActualCases,0)) [Actual Stat Cases],  
  round(sum(targetCases),0) [Reliability Target Stat Cases],  
  case  when round(sum(OperationsTargetUnits),0) = 0   
    THEN 0.0  
    else (sum(CONVERT(float, coalesce(ActualCases,0))) / round(sum(CONVERT(float, OperationsTargetUnits)),0))  
    END [Operations Efficiency %],  
  round(sum(OperationsTargetUnits),0) [Operations Target Stat Cases],  
  (CASE WHEN round(sum(PlanningTargetUnits),0) = 0   
    THEN 0.0  
    else (sum(CONVERT(float, coalesce(ActualCases,0))) / round(sum(CONVERT(float, PlanningTargetUnits)),0))  
    END) [Planning Efficiency %],  
  round(sum(PlanningTargetUnits),0) [Planning Target Stat Cases],  
  
  sum(coalesce(MinorBD,0)) [Minor Equipment Failures],  
  sum(coalesce(ModerateBD,0)) [Moderate Equipment Failures],  
  sum(coalesce(MajorBD,0)) [Major Equipment Failures],  
  sum(coalesce(MinorPF,0)) [Minor Process Failures],  
  sum(coalesce(ModeratePF,0)) [Moderate Process Failures],  
  sum(coalesce(MajorPF,0)) [Major Process Failures],  
  case   
  when sum(PRPolyCEvents) > 0  
  then sum(PRPolyCDowntime) / sum(PRPolyCEvents)  
  else null   
  end [Avg PRoll Change Time],  
  CASE WHEN SUM(CONVERT(FLOAT,IdealCases)) > 0       
     THEN SUM(CASE  WHEN IdealCases IS NOT NULL    
         THEN CONVERT(FLOAT,ActualCases)   
         ELSE 0            
         END)              
     / SUM(CONVERT(FLOAT,IdealCases))  
       ELSE NULL END [CVTI %]  
 FROM  @TimeRangeSummary trs  
 JOIN  Products p with (nolock) ON trs.ProdId = p.Prod_Id  
 group BY p.prod_code, Prodid, Daystart, Shift, Team   
 ORDER BY p.prod_code, Prodid, DayStart, Shift, Team  
 option (keep plan)  
  
 update dbo.#ByProduct set  
  [Planned Availability] =   
   case  when [Split Uptime] + [Unscheduled Split DT] > 0   
    then [Split Uptime] / ([Split Uptime] + [Unscheduled Split DT])       
    else 0 end,  
  [Unplanned MTBF] =   
   case when [Unscheduled Stops] > 0   
    then [Split Uptime] / [Unscheduled Stops]  
    else 0 end,  
  [Unplanned MTTR] =   
   case when [Unscheduled Stops] > 0   
    then [Unscheduled Split DT]/[Unscheduled Stops]  
    else 0 end  
  
   
 select @SQL =   
 case  
 when (select count(*) from dbo.#ByProduct with (nolock)) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#ByProduct with (nolock)) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#ByProduct', @LanguageId)  
 end  
  
 execute sp_executesql @SQL   
  
  
 end  
  
  
----------------------------------  
-- Section 39: Drop temp tables  
----------------------------------  
  
DropTables:  
  
drop table dbo.#delays  
drop table dbo.#TimedEventDetails  
drop table dbo.#tests  
drop table dbo.#SplitEvents  
drop table dbo.#SplitUptime  
drop table dbo.#TeamAverages  
drop table dbo.#LineAverages  
drop table dbo.#AllProducts  
drop table dbo.#ByProduct  
  
  
RETURN  
  
