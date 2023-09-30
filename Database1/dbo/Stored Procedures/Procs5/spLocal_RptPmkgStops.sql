 /*************************************************************************************************************************************************************  
   Last Update: Rev8.11 Langdon Davis 2005-05-16   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- 2004-MAR-18 Jeff Jaeger  Rev5.0  
--  - This source code taken from spLocal_RptCvtgDDSStopsRev7.3Val  
--    corrected the input parameters and result sets to be accurate for the Pmkg Stops report  
--  - Cleaned up dead code.  I left in RateLoss and ELP related code, since it may be useful in the future.  
--  - corrected the way that Uptime is pulled, so that it will allow for Uptime outside the report window.  
--  - corrected the code for counting the different kinds of stops.  
--  - Updated the limiting of the population of the #ProdUnits relative to the Delay Type List.  
--  - added code to get TreeNode information for #Delays.  
--  - updated the flow control around the first result set.  
--  - added translation code to each result set.  
--  - added checks for zero records and > 65000 records in each result set, with corresponding variables and   
--    translations.  
--  - moved the create statements for all temp tables to the top of the code.  moved the drop statesments   
--    to the end of the code.  Note that this does not apply to temp tables used only for translation.  
--  - updated the parameter validations.   
--  
-- 2004-MAR-23 Jeff Jaeger Rev5.1  
--  - added minor, moderate, and major process failures to all result sets.  added code to populate those   
--    fields.   
--  - added minor, moderate, and major equipment failures to all result sets.  added code to populate those   
--    fields.  
--  - readded #tests, prodlines, and rateloss columns to result sets, along with related code,   
--    in order to track rateloss data.  
--  - simplified the flow-control in the result sets.  
--  - added coalesce funtions to time measurements in the result sets.  
--  
-- 2004-Mar-30  Jeff Jaeger  5.2  
--  - readded @runs related tables, and added #DelaysByShiftProduct, along with related code.    
--    this code is used to manage splitting events across shift changes, product changes,   
--    and boundaries of the report window.  
--  - resequenced blocks of code as I added the @runs related tables and put update code in place.    
--    the sequence now matches MBD/TS more closely.  
--  - Updated the #Delays table so that ALL time measures are defined as floats.  
--  - Removed some unused code.  
--  - Added new fields RateLossInWindow, DowntimeInWindow, RateLossRatio, and DowntimeRatio  
--    to #Delays along with associated code.  
--  - Added new fields RateLossInWindow, DowntimeInWindow, RateLossRatio, and DowntimeRatio  
--    to #Delays along with associated code.  
--  - Added MTBF, MTTR, Availability, and R(2) to all result sets.  MTTR has been calculated   
--    with partial stops in the summary result sets.  Partial stops are a float value, so that   
--    stops can be split across shifts or products, or split due to report boundary.  Note that MTTR   
--    in the various summary results is initially set to the PartialStops value, but is then updated   
--    using the MTTR formula.  
--  - Removed Downtime and Uptime from all result summary sets.  This was done because the values have   
--    no meaning when stops and downtime are split according to shift, product change, or report   
--    boundary.  Instead, ReportDowntime and ReportUptime are now the primary measures for these   
--    values, since they account for the splits.  ReportUptime is still a measure of total production   
--    time minus the ReportDowntime.  
--  - Added code to modify entries in #Runs, so that when a production run ends in the middle of a   
--    downtime event, the end time of the production run is changed to the end time of the downtime   
--    event, while the start of the next production run is also changed to the end time of that   
--    downtime event.  Note that in testing after importing this code from MthByDayTeamShift, I   
--    noticed that a downtime event spanning the start of the report window was not being properly   
--    handled.  I made changes to the code to correct for this, and these changes will need to be   
--    put into MthByDayTeamShift.  
--  - Changed the source data for #Stops to be #DelaysByShiftProduct instead of #Delays.  This   
--    required some additional fields be added to #DelaysByShiftProduct.  
  
-- 2004-04-08 Jeff Jaeger  Rev 5.3Val  
--  - Added Downtime and Uptime back into all result sets.  
--  - Added additional code and parameters back from DDS Stops, especially use of @CatBlockStarvedId  
--    for counting stops and @SchedHolidayCurtailId for calculating production time and Downtime.  
--  - Removed unused variables and constants.  
--  - Removed comments from Cvtg DDS Stops.  If any issues arise, refer to that report for additional   
--    information, as needed.  
--  - Added #UptimeByShiftProduct temp table, and the code to populate it.  This table is used to calc   
--    ReportUptime, and then insert that into #DelaysByShiftProduct  
--  - Possible enhancement:  I wonder if there would be any benefit to loading #Delays with a single   
--    insert that uses UNIONS instead of separtate insert statements?  
--  - Added additional insert to #Delays to add the first timed event detail record after the report   
--    window according to pu_id.  This is used later to assign CategoryID and ScheduleID for Uptime data   
--    at the end of the report window.   
--  - Changed #DelaysByShiftProduct to #EventsByShiftProduct, to more properly reflect the inclusion of   
--    Uptime data in the table.  
--  - Moved remaining Create statements to the top of the script.  Moved the remaining drop statements   
--    to the bottom of the script.  
--  - Adjusted the code for MTBF, MTTR, Availability, and R(2) in the result sets and moved those   
--    definitions into the main insert statement for each result set.  This was done because of the   
--    updates to how ReportUptime is figured.   
--  - Note that the code for MthByDayTeamShift will likely need to be updated to reflect the new   
--    method of splitting downtime events and figuring uptime.  
--  - Added code to the insert to #Delays to include primary events that are initiated prior to the   
--    report window, for more accurate calculation of Uptime.  
--  - Updated the formula for PartialStops.  
--  - Updated the default assignment of PUDesc in #Delays.  
--  - Updated the calculation of PartialStops, which is used in the MTTR calculation.  
--  - Updated the calculation of Rateloss Downtime.  
--  
-- 2004-04-13 Jeff Jaeger  
--  - Added calls to fnLocal_GlblGetVarId for rateloss variables, instead comparing to var_desc.  
--  
-- 2004-04-14 Jeff Jaeger  
--  - Updated the load to #UptimeByShiftProduct, and the subsequent update to CategoryID and ScheduleID.  
--  - Restricted the population of #EventsByShiftProduct to be based only on #Delay records with   
--    inRptWindow = 1.  
  
-- 2004-04-15 Jeff Jaeger  Rev5.6  
--  - Found some additional use of inRptWindow in #EventsByShiftProduct, and removed them.   
  
-- 2004-APR-23  Langdon Davis Rev5.7  
--  - Removed parameters and variables specific to converting.  
  
-- 2004-APR-23  Langdon Davis Rev5.71  
--  - Removed join with the Variables table in the SELECT statement that populates the  
--    @ProdUnits table as it was serving no useful purpose.  
  
-- 2004-APR-23 Langdon Davis Rev5.72  
--  -All the stuff in the sp relative to the LineSpeed is doing nothing--there are no such variables in   
--   Pmkg.  Ditto for the LineProdFactor stuff.  Correspondingly, the @RunsByTgtSpeed table was  
--   unnecesary.  Ditto for 'adjusting Product runs in the #Runs table to account for Target Line Speed   
--   changes within the product run'.  I commented out related code.  
  
-- 2004-Apr-27 Jeff Jaeger  Rev6.0  
--  - Added an update to #EventsByShiftProduct.ReportUptime using values calculated in #UptimeByShiftProduct   
--    and the dbspID.  
--  - Modified the insert to #EventsByShiftProduct from #UptimeByShiftProduct, so that only the uptime   
--    records associated with NO downtime event will be inserted to #EventsByShiftProduct.  
--  - Changed the update to Uptime and ReportUptime in #Primaries to use the new method defined in   
--    RptCvtgDDSStopsRev7.32.    
--  - Deleted unused code.  
--  - Added a "where td.scheduleID <> @schedHolidayCurtailID" clause to the result sets.  
--  - Added an additional "WHEN" to the case statement in the first result set, so that if the Primary ID   
--    is NULL, then the Event Type will be NULL.  
--  - Added a coalesce() within the sum of td.causes in each result set.  
--  - Added puid checks updates to #EventsByShiftProduct, where source data is taken from   
--    #UptimeByShiftProduct.  These were needed because of the use of multiple lines in the parameter lists.  
  
-- 2004-05-05 Jeff Jaeger  Rev6.1  
--  - Restructured the result temp tables.  
--  - Rewrote the population of result temp tables.  
--  - Rewrote the update of ReportUptime in #EventsByShiftProduct.  
--  - Modified the insert to #EventsByShiftProduct from #UptimeByShiftProduct so that not additional   
--    records are created for ReportUptime associated with a downtime event.  
--  - Got rid of unused code.  
--  - Restructured #UptimeByShiftProduct to get rid of unrequired fields.  
--  - Rewrote the inserts and updates to #UptimeByShiftProduct.  
--  - Removed the insert to #Delays that added the first downtime record after the report window.  
--    This was originally put in to get ScheduleID and CategoryID for the uptime record from the last   
--    downtime event within the report window to the end of the report window.  
--  - Removed Stops2m from result sets.  
  
-- 2004-05-25 Jeff Jaeger  Rev6.2  
--  - Added [Master Unit] to the summary temporary tables, and added pu.pu_desc to the group by and order by  
--    clause for the insert statements to each of these tables.  This is intended to address the issue of   
--    ReportDowntime and ReportUptime summarizing to values that are too large.  
  
-- 2004-06-03 Jeff Jaeger  Rev6.3  
--  - Where #EventsByShiftProduct is updated to set some values back to Null, removed dbspID from   
--    from the list of values that are set back.    
  
-- 2004-06-10 Jeff Jaeger  Rev6.4  
--  - Applied the enhancements from version 060804 of the Method for Splitting Downtime document.  
--  - Added PLID to #Delays.  
  
-- 2004-06-23 Jeff Jaeger  Rev6.5  
--  - Added a td.prodid = rls.prodid constraint to the where clause on the initial insert to   
--  #EventsByShiftProduct.  Under some conditions, a downtime event with a product change was getting   
--  inserted into the table twice... once for each product id.  
--  - Added Reason Level descriptions and Category description (as RL1Desc, RL2Desc, RL3Desc, RL4Desc, and   
--  CatDesc) to #EventsByShiftProduct.  This was done because in Pmkg the category information is sometimes    
--  stored in Reason Level 4, and we need to pull that value into the category field.   
--  - Added MU Count to #Stops.  This will be used as a summed denominator in the xlt Pivot table.  
--  - Changed the name of Uptime in #Stops to [Raw Uptime].  This was done so that the template can use   
--  the name 'Uptime' for a calculated field.   
  
2004-06-23 Jeff Jaeger Rev6.6  
  - Added rls.puid = td.puid restriction to the initial insert of #EventsByShiftProduct.  
  - Removed the Holiday curtail restriction from the intitial insert to #EventsByShiftProduct.  
  - Updated the result set calculations to reflect changes in the design of the report.  
   - added the Unscheduled Stops, Unscheduled Downtime, and Unscheduled Rpt DT, CMU, CLoc, CRL1, CRL2,   
   CRL3, CRL4, CFault fields to the #Stops table, with related code.  
   - Updated the definition and population of @LineStatus and @LineStatusRaw.  
  
2004-JUL-29 Langdon Davis Rev6.7  
  - Corrected aliases in the by Team, Shift, Product, etcetera results sets:  Unplanned MTBF and Unplanned  
    MTTR both had 'Planned' instead of 'Unplanned'.  
  
2004-08-26 Jeff Jaeger Rev6.8  
--  - renamed Unscheduled Downtime to Event Downtime.  
--  - Added Reporting Downtime to the summarized result sets.  
--  - Updated time splitting to reflect recent changes in the method.  
  
2004-09-29 Jeff Jaeger Rev6.9  
--  - updated time splitting by removing the shift and team constrainsts when the temp table is populated.    
  this was effecting the results when there are multiple products.  
  
2004-10-15 Jeff Jaeger Rev7.0  
  - added LineStatus to #UptimeByShiftProduct  
  - added LineStatus to inserts into #UptimeByShiftProduct except where there where no downtime events in   
  the timespan.  
  - added update statement for LineStatus in #UptimeByShiftProduct  
  - updated the code that determines LineStatus in the related temp tables  
  - added code to remove carriage returns from the Comment field in #Stops.   
  
2004-10-18 Jeff Jaeger Rev7.1  
--  - NULLified the second item in the Rev7.0 list:  It is not necessary as the uptime assumes the Line  
--    Status of the downtime record it gets associated to in the update of #EventsByShiftProduct.  
--  - Modified the WHERE clause in the UPDATE added as the third item in the Rev7.0 list for two things:  
--     1.) Changed the #UptimeByShiftProduct.starttime's to #UptimeByShiftProduct.endtime's.  This is   
--       because the stated requirement was to set the line status for these artifical uptime events  
--       based on the status in effect as of their EndTime.  This better aligns with what happens with  
--                          all of the real uptime periods:  They get the line status of the downtime events that ended  
--       them, which is based on the status of the StartTime of the downtime event [= EndTime of the  
--                          uptime event].  
--   2.) Instead of updating WHERE LineStatus is NULL--which was updating all of the uptime records  
--       including the ones where we don't need to assign a line status to because they'll get the   
--                          status of the downtime event they are associated with--changed to updating where dbspID is   
--              is NULL.  This limits the update to just the artificial records.  
--  - Removed [commented out] all updates of ReportUptime in #Primaries and #Delays.  These values were  
--                never used anywhere since all ReportUptime now comes out of #EventsByShiftProduct.  
  
2004-10-19 Jeff Jaeger Rev7.2  
  - Removed rate loss elements from the result sets.  
  
2004-12-03 Jeff Jaeger Rev7.3  
  - Brought this sp up to date with Checklist 110804.  
  - Removed some unused code.  
  - Updated the insert and update to #Primaries.  
  
2005-JAN-24 Langdon Davis Rev7.31  
  - Modified ":" to ':' in code pulling category descriptions.  The double quotes were giving an  
    "Invalid column name ':'." error.  
  
2005-01-27 Jeff Jaeger Rev8.0  
  - added the RawData result set.  
  
2005-04-21 Jeff Jaeger Rev8.10  
  - added the database owner to references of database objects.  
  - removed some unused code  
  - added code to initialize temp tables and table variables, in order to reduce recompilation.  
  
2005-MAY-16 Langdon Davis Rev8.11  
  -  Commented out code referring to Timed_Event_Summarys table as this table no longer exists.  
   Some follow-up is still necessary to substitute code that will get the comment in it's  
   new location which, per Matt Wells, is:  
    The summary record comments are still stored in the same place but now they   
    key off the first Timed_Event_Detail record in the sequence.  The WTC_Type   
    is still the same.  
  
  
2005-MAY-16 Namho Kim Rev8.12  
  - Making a Code Flexible to Work with BOTH 3.x and 4.x  
  
------------------------------------------------------------------------------------------------------------------------------------------------------------*/  
  
CREATE PROCEDURE dbo.spLocal_RptPmkgStops  
--declare  
  
 @StartTime   datetime,  -- Beginning period for the data.  
 @EndTime   datetime,  -- Ending period for the data.  
 @BySummary   int,   -- 0 = Do not include additional Stops sheets; 1 = Include additional Stops sheets.  
 @ProdLineList   varchar(4000),  -- Collection of Prod_Lines.PL_Id for converting lines delimited by "|".  
 @DelayTypeList   varchar(4000),  -- Collection of "DelayType=..." from Prod_Units.Extended_Info delimited by "|".  
 @ScheduleStr   varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ':').  
 @CategoryStr   varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ':').  
 @GroupCauseStr   varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ':').  
 @SubSystemStr   varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ':').  
 @CatMechEquipId   int,   -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
 @CatElectEquipId  int,   -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
 @CatProcFailId   int,   -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
 @CatBlockStarvedId  int, --   -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved.  
 @SchedUnscheduledId  int,   -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
 @SchedChangeOverId  int,   -- Event_Reason_Categories.ERC_Id for Schedule:Changeover.  
 @SchedHolidayCurtailId  Int,   -- Event_Reason_Catagories.ERC_Id for Schedule:Holiday/Curtail.  
 @DelayTypeRateLossStr  varchar(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
 @UserName   varchar(30)  -- User calling this report  
  
AS  
  
/* test values MP  
  
SELECT  
@StartTime = '2004-02-01 00:00:00',   
@EndTime = '2004-02-02 00:00:00',   
@BySummary = 1,  
@ProdLineList = '109',   
@DelayTypeList = 'Sheetbreak',   
@ScheduleStr = 'Schedule',   
@CategoryStr = 'Category',   
@GroupCauseStr = 'GroupCause',   
@SubSystemStr = 'Subsystem',   
@CatMechEquipId = 101,   
@CatElectEquipId = 105,   
@CatProcFailId = 106,   
@CatBlockStarvedId = 260,  
@SchedUnScheduledId = 103,   
@SchedChangeOverId = 123,  
@SchedHolidayCurtailId = 120,   
@DelayTypeRateLossStr = 'RateLoss',   
@UserName = 'ComXClient'  
  
*/  
  
/* test values AZ  
  
SELECT  
@StartTime = '2004-06-24 07:00:00',   
@EndTime = '2004-06-25 07:00:00',   
@BySummary = 1,   
@ProdLineList = '3',   
@DelayTypeList = ' ',   
@ScheduleStr = 'Schedule',   
@CategoryStr = 'Category',   
@GroupCauseStr = 'GroupCause',   
@SubSystemStr = 'SubSystem',   
@CatMechEquipId = 109,   
@CatElectEquipId = 108,   
@CatProcFailId = 107,   
@CatBlockStarvedID = 168,   
@SchedUnScheduledId = 101,   
@SchedChangeOverId = 103,   
@SchedHolidayCurtailId = 104,   
@DelayTypeRateLossStr = 'RateLoss',   
@UserName = 'ComXClient'  
  
*/  
  
/* test values AY  
  
SELECT  
@StartTime = '2004-05-01 07:00:00',   
@EndTime = '2004-05-31 07:00:00',   
@BySummary = 1,   
@ProdLineList = '53',   
@DelayTypeList = 'Sheetbreak',   
@ScheduleStr = 'Schedule',   
@CategoryStr = 'Category',   
@GroupCauseStr = 'GroupCause',   
@SubSystemStr = 'SubSystem',   
@CatMechEquipId = 106,   
@CatElectEquipId = 110,   
@CatProcFailId = 111,   
@CatBlockStarvedID = 101,   
@SchedUnScheduledId = 208,   
@SchedChangeOverId = 130,   
@SchedHolidayCurtailId = 128,   
@DelayTypeRateLossStr = 'RateLoss',   
@UserName = 'ComXClient'  
  
*/  
  
/* test values Cape  
  
SELECT  
@StartTime = '2004-06-23 00:00:00',   
@EndTime = '2004-06-26 00:00:00',   
@BySummary = 1,   
@ProdLineList = '38|', --'38',   
@DelayTypeList = 'Downtime|', --Sheetbreak',   
@ScheduleStr = 'Schedule',   
@CategoryStr = 'Category',   
@GroupCauseStr = 'GroupCause',   
@SubSystemStr = 'SubSystem',   
@CatMechEquipId = 103,   
@CatElectEquipId = 104,   
@CatProcFailId = 102,   
@CatBlockStarvedID = 158,   
@SchedUnScheduledId = 101,   
@SchedChangeOverId = 108,   
@SchedHolidayCurtailId = 109,   
@DelayTypeRateLossStr = 'RateLoss',   
--@PivotDataSource = 'Raw',  -- 'Split',  
@UserName = 'ComXClient'  
  
*/  
  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
DECLARE @SearchString   varchar(4000),  
 @Position   int,  
 @PartialString   varchar(4000),  
 @Now    datetime,  
 @@Id    int,  
 @@ExtendedInfo   varchar(255),  
 @PUDelayTypeStr   varchar(100),  
 @PUScheduleUnitStr  varchar(100),  
 @PULineStatusUnitStr  varchar(100),  
 @@PUId    int,  
 @@TimeStamp   datetime,  
 @@LastEndTime   datetime,  
 @@PLId    int,  
 @@VarEffDowntimeId  int,  
 @@ProdId   int,  
 @@StartTime   datetime,  
 @@EndTime   datetime,  
 @ProdCode   varchar(100),  
 @PLDesc    varchar(100),  
 @VarEffDowntimeId  int,  
 @VarEffDowntimeVN  varchar(50),  
 @@VarId    int,  
 @@NextStartTime   datetime,  
 @PUEquipGroupStr  varchar(100),  
 @@ProdCode   varchar(100),  
 @Rows    int,  
 @Row    int,  
 @RangeStartTime   datetime,  
 @RangeEndTime   datetime,  
 @Max_TEDet_Id   int,  
 @Min_TEDet_Id   int,  
 @SQL    varchar(8000),  
 @LanguageId   int,  
 @UserId    int,  
 @LanguageParmId   int,  
 @LineName   varchar(50), -- MKW - 01/13/04  
 @NoDataMsg    varchar(50),  
 @TooMuchDataMsg   varchar(50),  
 @RateLossPUID   int,  
 @r    int,  
 @DBVersion    VARCHAR(10) --NHK Rev8.12  
  
-------------------------------------------------------------------------------  
-- Create temp tables  
-------------------------------------------------------------------------------  
  
create table dbo.#runs   
 (  
 RowID    int IDENTITY,  
 PLId    Int,  
 PUId    Int,  
 ProdId    Int,  
 ProdCode   varchar(25),  
 StartTime   DateTime,  
 EndTime    DateTime   
)  
  
  
create table dbo.#RunsLineShift (  
 PLId    Int,  
 PUID    integer,  
 Shift    nVarChar(50),  
 Team    nVarChar(50),  
 ProdId    Int,  
 Prod_StartTime   DateTime,  
 Prod_EndTime   DateTime,  
 Shift_StartTime   DateTime,  
 Shift_EndTime   DateTime  
)  
  
  
CREATE TABLE dbo.#Delays (  
 TEDetId    int PRIMARY KEY NONCLUSTERED,  
 PrimaryId   int,  
 SecondaryId   int,  
 PLID    int,  
 PUId    int,  
 PUDesc    varchar(100),  
 StartTime   datetime,  
 EndTime    datetime,  
 ShiftStartTime   datetime,  
 LocationId   int,  
 L1ReasonId   int,  
 L2ReasonId   int,  
 L3ReasonId   int,  
 L4ReasonId   int,  
 TEFaultId   int,  
 L1TreeNodeId   int,  
 L2TreeNodeId   int,  
 L3TreeNodeId   int,  
 L4TreeNodeId   int,  
 ProdId    int,  
 LineStatus   varchar(50),  
 Shift    varchar(10),  
 Crew    varchar(10),  
 ScheduleId   int,  
 CategoryId   int,  
 GroupCauseId   int,  
 SubSystemId   int,  
 DownTime   float,  
 ReportDownTime   float,  
 UpTime    float,  
 ReportUptime   float,  
 Stops    int,  
 StopsUnscheduled  int,  
 StopsMinor   int,  
 StopsEquipFails   int,  
 StopsProcessFailures  int,  
 StopsBlockedStarved  int,  
 UpTime2m   int,  
 RateLossRatio   float,  
 RateLossPRID   varchar(50),  
 Comment    varchar(5000),  
 InRptWindow   int  
)  
  
  
CREATE CLUSTERED INDEX td_PUId_StartTime  
 ON dbo.#Delays (PUId, StartTime, EndTime)  
  
  
CREATE TABLE  dbo.#EventsByShiftProduct (  
 ebspID    int IDENTITY,  
 dbspID    int,   
 StartTime   datetime,  
 EndTime    datetime,  
 ProdId    int,  
 PLID    int,  
 PUId    int,  
 pudesc    varchar(50),  
 Shift    varchar(10),  
 Team    varchar(10),  
 PrimaryId   int,  
 TEDetId    int,   
 TEFaultId   int,  
 ScheduleId   int,  
 CategoryId   int,  
 CatDesc    varchar(100),  
 SubSystemId   int,  
 GroupCauseId   int,  
 LocationId   int,  
 L1ReasonId   int,  
 L2ReasonId   int,  
 L3ReasonId   int,  
 L4ReasonId   int,  
 RL1Desc    varchar(100),   RL2Desc    varchar(100),  
 RL3Desc    varchar(100),  
 RL4Desc    varchar(100),  
 LineStatus   varchar(50),  
 Downtime   float,  
 ReportDownTime   float,  
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
 UpTime2m   int,  
 StopsRateLoss   int,  
 MinorEF    int,  
 ModerateEF   int,  
 MajorEF    int,  
 MinorPF    int,  
 ModeratePF   int,  
 MajorPF    int,  
 Causes    int,  
 Comment    varchar(5000)  
)  
  
  
CREATE CLUSTERED INDEX dbsp_PUId_StartTime  
 ON dbo.#EventsByShiftProduct (PUId, StartTime, EndTime)  
  
  
CREATE TABLE  dbo.#UptimeByShiftProduct (  
 dbspID    int,  
 StartTime   datetime,  
 EndTime    datetime,  
 ProdId    int,  
 PLID    int,  
 PUId    int,  
 pudesc    varchar(100),  
 Shift    varchar(10),  
 Team    varchar(10),  
 ReportUptime   float,  
 LineStatus   varchar(50) -- added Rev7.0  
)  
  
CREATE CLUSTERED INDEX ubsp_PUId_StartTime  
 ON dbo.#UptimeByShiftProduct (PUId, StartTime, EndTime)  
  
  
DECLARE @ProdLines TABLE (  
 PLId    Int Primary Key,  
 VarEffDowntimeId  int  
 )   
  
declare @ProdUnits  table  
 (  
 PUId    int PRIMARY KEY,  
 PUDesc    varchar(100),  
 PLId    int,  
 ExtendedInfo   varchar(255),  
 DelayType   varchar(100),  
 ScheduleUnit   int,  
 LineStatusUnit   int,  
 EquipGroup   varchar(100)  
 )  
  
CREATE TABLE dbo.#TECategories   
 (   
 TEC_Id  int PRIMARY KEY NONCLUSTERED IDENTITY,  
 TEDet_Id int,  
 ERC_Id  int  
 )  
  
  
CREATE CLUSTERED INDEX tec_TEDetId_ERCId  
 ON dbo.#TECategories (TEDet_Id, ERC_Id)  
  
  
CREATE TABLE dbo.#Primaries (  
 TEDetId    Int Primary Key,  
 PUId    Int,  
 StartTime   DateTime,  
 EndTime    DateTime,  
 ScheduleId   Int,  
 CategoryId   Int,  
 DownTime   float,  
 ReportDownTime   float,  
 LastEndTime   DateTime,  
 UpTime    float,  
 ReportUptime   float,  
 Stops    Int,  
 StopsMinor   Int,  
 StopsEquipFails   Int,  
 StopsProcessFailures  Int,  
 UpTime2m   Int,  
 TEPrimaryId   int IDENTITY  )  
  
  
CREATE TABLE dbo.#Tests (  
 TestId   Int Primary Key,  
 VarId   Int,  
 PLId   Int,  
 PUId   Int,  
 Value   Float,  
 StartTime  DateTime,  
 EndTime   DateTime   
)  
  
CREATE INDEX tt_VarId_StartTime  
 ON dbo.#Tests (VarId, StartTime)  
  
CREATE INDEX tt_VarId_EndTime  
 ON dbo.#Tests (VarId, EndTime)  
  
  
DECLARE @LineStatusRaw TABLE (  PUId    int,  
        StartTime  datetime,  
        PhraseId  int)  
DECLARE @LineStatus TABLE (  LSId    int IDENTITY,  
        PUId    int,  
        StartTime  datetime,  
        EndTime   datetime,  
        PhraseId  int,  
        PRIMARY KEY (PUId, StartTime))  
  
  
 CREATE TABLE dbo.#Stops  (   
  [Production Line]   varchar(50),  
  [Start Time]    datetime,  
  [End Time]    datetime,  
  [Master Unit]    varchar(50),  
  [Reason Level 1]   varchar(100),  
  [Reason Level 2]   varchar(100),  
  [Reason Level 3]   varchar(100),  
  [Reason Level 4]   varchar(100),  
  [Location]    varchar(50),  
  [Product]    varchar(50),  
  [Fault Desc]    varchar(100),  
  [Line Status]    varchar(50),  
  [Schedule]    varchar(50),  
  [Unscheduled Stops]    int,  
  [Category]    varchar(50),  
  [SubSystem]    varchar(50),  
  [GroupCause]    varchar(50),  
  [Shift]     varchar(10),  
  [Team]     varchar(10),  
  [Event Location Type]   varchar(100),  
  [Event Type]    varchar(10),  
  [Total Stops]    float, --int,  
  [Minor Stops]    int,  
  [Equipment Failures]   int,  
  [Process Failures]   int,  
  [Total Causes]    int,  
  [Event Downtime]   float,  
  [Reporting Downtime]   float,  
  [Unscheduled Rpt DT]   float,  
  [Raw Uptime]    float,  
  [Report Uptime]    float,  
  [Total Stops with Uptime < 2 Min] float, --int,  
  [Minor Equipment Failures]  int,   
  [Moderate Equipment Failures]  int,  
  [Major Equipment Failures]  int,  
  [Minor Process Failures]  int,  
  [Moderate Process Failures]  int,  
  [Major Process Failures]  int,  
  [Comment]    varchar(5000),  
  [CMU]        float        
  )  
  
  
 CREATE TABLE dbo.#TeamSummary (   
  [Production Line]   varchar(50),  
  [Master Unit]    varchar(50),  
  [Team]     varchar(8),  
  [Total Stops]    int,  
  [Minor Stops]    int,  
  [Equipment Failures]   int,  
  [Process Failures]   int,  
  [Total Causes]    int,  
  [Event Downtime]   float,  
  [Reporting Downtime]   float,  
  [Unscheduled Rpt DT]   float,  
  [Uptime]    float,  
  [Reporting Uptime]   float,  
  [Planned Availability]   float,  
  [Total Stops with Uptime < 2 Min] int,  
  [R(2)]     float,  
  [Unplanned MTBF]   float,  
  [Unplanned MTTR]   float,  
  [Minor Equipment Failures]  int,   
  [Moderate Equipment Failures]  int,  
  [Major Equipment Failures]  int,  
  [Minor Process Failures]  int,  
  [Moderate Process Failures]  int,  
  [Major Process Failures]  int  
  )  
  
  
 CREATE TABLE dbo.#ShiftSummary (   
  [Production Line]   varchar(50),  
  [Master Unit]    varchar(50),  
  [Shift]     varchar(10),  
  [Total Stops]    int,  
  [Minor Stops]    int,  
  [Equipment Failures]   int,  
  [Process Failures]   int,  
  [Total Causes]    int,  
  [Event Downtime]   float,  
  [Reporting Downtime]   float,  
  [Unscheduled Rpt DT]   float,  
  [Uptime]    float,  
  [Reporting Uptime]   float,  
  [Planned Availability]   float,  
  [Total Stops with Uptime < 2 Min] int,  
  [R(2)]     float,  
  [Unplanned MTBF]   float,  
  [Unplanned MTTR]   float,  
  [Minor Equipment Failures]  int,   
  [Moderate Equipment Failures]  int,  
  [Major Equipment Failures]  int,  
  [Minor Process Failures]  int,  
  [Moderate Process Failures]  int,  
  [Major Process Failures]  int  
  )  
  
  
 CREATE TABLE dbo.#ProductSummary (   
  [Production Line]   varchar(50),  
  [Master Unit]    varchar(50),  
  [Product]    varchar(50),  
  [Total Stops]    int,  
  [Minor Stops]    int,  
  [Equipment Failures]   int,  
  [Process Failures]   int,  
  [Total Causes]    int,  
  [Event Downtime]   float,  
  [Reporting Downtime]   float,  
  [Unscheduled Rpt DT]   float,  
  [Uptime]    float,  
  [Reporting Uptime]   float,  
  [Planned Availability]   float,  
  [Total Stops with Uptime < 2 Min] int,  
  [R(2)]     float,  
  [Unplanned MTBF]   float,  
  [Unplanned MTTR]   float,  
  [Minor Equipment Failures]  int,   
  [Moderate Equipment Failures]  int,  
  [Major Equipment Failures]  int,  
  [Minor Process Failures]  int,  
  [Moderate Process Failures]  int,  
  [Major Process Failures]  int  
  )  
   
  
 CREATE TABLE dbo.#LocationSummary (   
  [Production Line]   varchar(50),  
  [Master Unit]    varchar(50),  
  [Event Location Type]   varchar(25),  
  [Total Stops]    int,  
  [Minor Stops]    int,  
  [Equipment Failures]   int,  
  [Process Failures]   int,  
  [Total Causes]    int,  
  [Event Downtime]   float,  
  [Reporting Downtime]   float,  
  [Unscheduled Rpt DT]   float,  
  [Uptime]    float,  
  [Reporting Uptime]   float,  
  [Planned Availability]   float,  
  [Total Stops with Uptime < 2 Min] int,  
  [R(2)]     float,  
  [Unplanned MTBF]   float,  
  [Unplanned MTTR]   float,  
  [Minor Equipment Failures]  int,   
  [Moderate Equipment Failures]  int,  
  [Major Equipment Failures]  int,  
  [Minor Process Failures]  int,  
  [Moderate Process Failures]  int,  
  [Major Process Failures]  int  
  )  
  
  
 CREATE TABLE dbo.#CategorySummary (   
  [Production Line]   varchar(50),  
  [Master Unit]    varchar(50),  
  [Category]    varchar(25),  
  [Total Stops]    int,  
  [Minor Stops]    int,  
  [Equipment Failures]   int,  
  [Process Failures]   int,  
  [Total Causes]    int,  
  [Event Downtime]   float,  
  [Reporting Downtime]   float,  
  [Unscheduled Rpt DT]   float,  
  [Uptime]    float,  
  [Reporting Uptime]   float,  
  [Planned Availability]   float,  
  [Total Stops with Uptime < 2 Min] int,  
  [R(2)]     float,  
  [Unplanned MTBF]   float,  
  [Unplanned MTTR]   float,  
  [Minor Equipment Failures]  int,   
  [Moderate Equipment Failures]  int,  
  [Major Equipment Failures]  int,  
  [Minor Process Failures]  int,  
  [Moderate Process Failures]  int,  
  [Major Process Failures]  int  
  )  
  
  
 CREATE TABLE dbo.#ScheduleSummary (   
  [Production Line]   varchar(50),  
  [Master Unit]    varchar(50),  
  [Schedule]    varchar(25),  
  [Total Stops]    int,  
  [Minor Stops]    int,  
  [Equipment Failures]   int,  
  [Process Failures]   int,  
  [Total Causes]    int,  
  [Event Downtime]   float,  
  [Reporting Downtime]   float,  
  [Unscheduled Rpt DT]   float,  
  [Uptime]    float,  
  [Reporting Uptime]   float,  
  [Planned Availability]   float,  
  [Total Stops with Uptime < 2 Min] int,  
  [R(2)]     float,  
  [Unplanned MTBF]   float,  
  [Unplanned MTTR]   float,  
  [Minor Equipment Failures]  int,   
  [Moderate Equipment Failures]  int,  
  [Major Equipment Failures]  int,  
  [Minor Process Failures]  int,  
  [Moderate Process Failures]  int,  
  [Major Process Failures]  int  
  )  
  
  
DECLARE @FirstEvents TABLE ( FirstEventId int IDENTITY,  
    PUId  int,  
    StartTime datetime)  
  
  
DECLARE @ErrorMessages TABLE ( ErrMsg varchar(255) )  
  
  
-------------------------------------------------------------------------------  
-- Initialization  
-------------------------------------------------------------------------------  
  
set @r = (Select Count(*) From dbo.#runs)  
set @r = (Select Count(*) From dbo.#RunsLineShift)  
set @r = (Select Count(*) From dbo.#Delays)  
set @r = (Select Count(*) From dbo.#EventsByShiftProduct)  
set @r = (Select Count(*) From dbo.#UptimeByShiftProduct)  
set @r = (Select Count(*) From @ProdLines)  
set @r = (Select Count(*) From @ProdUnits)  
set @r = (Select Count(*) From dbo.#TECategories)  
set @r = (Select Count(*) From dbo.#Primaries)  
set @r = (Select Count(*) From dbo.#Tests)  
set @r = (Select Count(*) From @LineStatusRaw)  
set @r = (Select Count(*) From @LineStatus)  
set @r = (Select Count(*) From dbo.#Stops)  
set @r = (Select Count(*) From dbo.#TeamSummary)  
set @r = (Select Count(*) From dbo.#ShiftSummary)  
set @r = (Select Count(*) From dbo.#ProductSummary)  
set @r = (Select Count(*) From dbo.#LocationSummary)  
set @r = (Select Count(*) From dbo.#CategorySummary)  
set @r = (Select Count(*) From dbo.#ScheduleSummary)  
set @r = (Select Count(*) From @FirstEvents)  
set @r = (Select Count(*) From @ErrorMessages)  
  
  
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
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories WHERE ERC_Id = @CatProcFailId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatProcFailId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories WHERE ERC_Id = @CatBlockStarvedId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatBlockStarvedId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories WHERE ERC_Id = @CatMechEquipId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatMechEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories WHERE ERC_Id = @CatElectEquipId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatElectEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories WHERE ERC_Id = @SchedUnscheduledId) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedUnscheduledId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(ERC_Id) FROM dbo.Event_Reason_Catagories WHERE ERC_Id = @SchedChangeOverID) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedChangeOverId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
 END  
IF isnumeric(@BySummary) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@BySummary is not valid.')  
 GOTO ReturnResultSets  
 END  
IF (SELECT count(username) FROM dbo.users WHERE username = @username) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@UserName is not valid.')  
 GOTO ReturnResultSets  
 END  
-- If the endtime is in the future, set it to current day.  This prevent zero records from being printed on report.  
IF @EndTime > GetDate()  
 BEGIN  
 SELECT @EndTime = convert(varchar(4),YEAR(GetDate())) + '-' + convert(varchar(2),MONTH(GetDate())) + '-' +   
     convert(varchar(2),DAY(GetDate())) + ' ' + convert(varchar(2),DATEPART(hh,GetDate())) + ':' +   
     convert(varchar(2),DATEPART(mi,GetDate()))+ ':' + convert(varchar(2),DATEPART(ss,GetDate()))  
 END  
  
-------------------------------------------------------------------------------  
-- Get local language  
-------------------------------------------------------------------------------  
SELECT @LanguageParmId  = 8,  
 @LanguageId   = NULL  
  
SELECT @UserId = User_Id  
FROM dbo.Users  
WHERE UserName = @UserName  
  
SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
    ELSE NULL  
    END  
FROM dbo.User_Parameters  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 BEGIN   
 SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN convert(float, ltrim(rtrim(Value)))  
     ELSE NULL  
     END  
 FROM dbo.Site_Parameters  
 WHERE Parm_Id = @LanguageParmId  
  
 IF @LanguageId IS NULL  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END   
   
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
---------  
--Proficy4.X  
---------  
SELECT @DBVersion = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database') --NHK Rev8.12  
  
  
-------------------------------------------------------------------------------  
-- Constants  
-------------------------------------------------------------------------------  
SELECT @Now    = GetDate(),  
 @PUDelayTypeStr   = 'DelayType=',  
 @PUScheduleUnitStr  = 'ScheduleUnit=',  
 @PULineStatusUnitStr  = 'LineStatusUnit=',  
 @VarEffDowntimeVN   = 'Effective Downtime' --,  
  
  
-------------------------------------------------------------------------------  
-- Parse the passed lists INTO temporary tables.  
-------------------------------------------------------------------------------  
-- ProdLineList  
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
  
    SELECT  @VarEffDowntimeId  = NULL --,  
  
    SELECT @PLDesc = PL_Desc FROM dbo.Prod_Lines WHERE PL_Id = Convert(Int, @PartialString)  
  
    SELECT @@ExtendedInfo = (SELECT Extended_Info FROM dbo.Prod_Lines WHERE PL_Id = Convert(Int, @PartialString))  
  
  
    SELECT @LineName = ltrim(rtrim(replace(@PLDesc,'TT ','')))  
  
    SELECT @RateLossPUId = PU_Id  
    FROM dbo.Prod_Units  
    WHERE PL_Id = @@PLId  
    AND PU_Desc LIKE '%Rate Loss'  
  
  
    SELECT @VarEffDowntimeId = GBDB.dbo.fnLocal_GlblGetVarId(@RateLossPUId, @VarEffDowntimeVN)  
      
    INSERT @ProdLines (PLId, VarEffDowntimeId)   
    VALUES (Convert(Int, @PartialString), @VarEffDowntimeId)   
  
   END    
 END   
END   
  
IF (SELECT Count(PLId) FROM @ProdLines) = 0  
 INSERT @ProdLines (PLId)  
  SELECT PL_Id  
   FROM dbo.Prod_Lines  
  
  
-------------------------------------------------------------------------------  
-- ProdUnitList  
-------------------------------------------------------------------------------  
  
INSERT @ProdUnits ( PUId,  
   PUDesc,  
   PLId,  
   ExtendedInfo,  
   DelayType,  
   ScheduleUnit,  
   LineStatusUnit  
   )  
SELECT distinct   
 pu.PU_Id,  
 pu.PU_Desc,  
 pu.PL_Id,  
 pu.Extended_Info,  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr),  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUScheduleUnitStr),  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PULineStatusUnitStr)  
FROM dbo.Prod_Units pu  
 INNER JOIN @ProdLines tpl ON pu.PL_Id = tpl.PLId  
 INNER JOIN dbo.Event_Configuration ec ON pu.PU_Id = ec.PU_Id  
WHERE pu.Master_Unit IS NULL  
 AND ec.ET_Id = 2  
  
delete @ProdUnits  
where DelayType like 'NotUsed'  
  
  
if ltrim(rtrim(coalesce(@DelayTypeList,''))) <> ''  
 delete @ProdUnits  
 where charindex(lower(delaytype),lower(@delaytypelist)) = 0  
  
  
-------------------------------------------------------------------------------  
-- Production Runs List  
-------------------------------------------------------------------------------  
  
INSERT dbo.#Runs (   
  PLId,  
  PUId,  
  ProdID,  
  ProdCode,     
  StartTime,  
  EndTime  
  )  
SELECT distinct pu.PLId,  
 ps.PU_Id,  
 ps.Prod_Id,  
 p.prod_code,  
 ps.Start_Time,  
 coalesce(ps.End_Time, @Now)  
FROM dbo.Production_Starts ps  
 inner JOIN dbo.Products p ON ps.Prod_Id = p.Prod_Id  
 inner JOIN @ProdUnits pu ON ps.PU_Id = pu.PUId  
     AND pu.PUId > 0  
WHERE ps.Prod_Id > 0  
 AND ps.Start_Time < @EndTime  
 AND (ps.End_Time > @StartTime OR ps.End_Time IS NULL)  
 AND (Prod_Desc <> 'No Grade' AND Prod_Code IS NOT NULL)  
 and pu.plid in (select plid from @prodlines)  
ORDER BY ps.PU_Id, ps.Start_Time  
  
  
-------------------------------------------------------------------------------  
-- Collect dataset filtered by report period and Production Units.  
-------------------------------------------------------------------------------  
/* Can probably revert to this once the Timed_Event_Details index is changed to Clustered */  
IF @DBVersion < '400000' -- Use the following code specific to pre-Proficy version 4.x... --NHK Rev8.12  
 BEGIN  
  INSERT dbo.#Delays (TEDetId,  
   PUId,  
   StartTime,  
   EndTime,  
   LocationId,  
   L1ReasonId,  
   L2ReasonId,  
   L3ReasonId,  
   L4ReasonId,  
   TEFaultId,  
   DownTime,  
   ReportDownTime,  
   PrimaryId,  
   SecondaryId,  
   InRptWindow)  
  SELECT ted.TEDet_Id,  
   ted.PU_Id,  
   ted.Start_Time,  
   coalesce(ted.End_Time, @Now),  
   ted.Source_PU_Id,  
   ted.Reason_Level1,  
   ted.Reason_Level2,  
   ted.Reason_Level3,  
   ted.Reason_Level4,  
   ted.TEFault_Id,  
   datediff(s, ted.Start_Time,  
   coalesce(ted.End_Time, @Now)),  
   coalesce(datediff(s, CASE WHEN ted.Start_Time <= @StartTime THEN @StartTime   
       ELSE ted.Start_Time  
       END,   
      CASE WHEN coalesce(ted.End_Time, @Now) >= @EndTime THEN @EndTime   
       ELSE coalesce(ted.End_Time, @Now)  
       END), 0.0),    
   ted2.TEDet_Id,  
   ted3.TEDet_Id,  
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
  FROM dbo.Timed_Event_Details ted  
   INNER JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
        AND tpu.PUId > 0  
   LEFT JOIN dbo.Prod_Units pu ON tpu.PUId = pu.PU_Id  
   LEFT JOIN dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
   LEFT JOIN dbo.Timed_Event_Details ted2 ON ted.PU_Id = ted2.PU_Id  
        AND ted.Start_Time = ted2.End_Time  
        AND ted.TEDet_Id <> ted2.TEDet_Id  
   LEFT JOIN dbo.Timed_Event_Details ted3 ON ted.PU_Id = ted3.PU_Id  
        AND ted.End_Time = ted3.Start_Time  
        AND ted.TEDet_Id <> ted3.TEDet_Id  
  WHERE ted.Start_Time < @EndTime  
   AND (ted.End_Time >= @StartTime OR ted.End_Time IS NULL)  
 End  
ELSE     --Use the following code specific to Proficy version 4.x+...  
 BEGIN  
  INSERT dbo.#Delays (TEDetId,  
  PUId,  
  StartTime,  
  EndTime,  
  LocationId,  
  L1ReasonId,  
  L2ReasonId,  
  L3ReasonId,  
  L4ReasonId,  
  TEFaultId,  
  DownTime,  
  ReportDownTime,  
  PrimaryId,  
  SecondaryId,  
  InRptWindow,  
  -- Modified P4 --check  
  Comment  
  -----------------  
  )  
  SELECT ted.TEDet_Id,  
   ted.PU_Id,  
   ted.Start_Time,  
   coalesce(ted.End_Time, @Now),  
   ted.Source_PU_Id,  
   ted.Reason_Level1,  
   ted.Reason_Level2,  
   ted.Reason_Level3,  
   ted.Reason_Level4,  
   ted.TEFault_Id,  
   datediff(s, ted.Start_Time,  
   coalesce(ted.End_Time, @Now)),  
   coalesce(datediff(s, CASE WHEN ted.Start_Time <= @StartTime THEN @StartTime   
       ELSE ted.Start_Time  
       END,   
      CASE WHEN coalesce(ted.End_Time, @Now) >= @EndTime THEN @EndTime   
       ELSE coalesce(ted.End_Time, @Now)  
       END), 0.0),    
   ted2.TEDet_Id,  
   ted3.TEDet_Id,  
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
    END,  
   -- Modified P4 --  
   C.Comment_Text     
   -----------------  
  FROM dbo.Timed_Event_Details ted  
   INNER JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
        AND tpu.PUId > 0  
   LEFT JOIN dbo.Prod_Units pu ON tpu.PUId = pu.PU_Id  
   LEFT JOIN dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
   LEFT JOIN dbo.Timed_Event_Details ted2 ON ted.PU_Id = ted2.PU_Id  
        AND ted.Start_Time = ted2.End_Time  
        AND ted.TEDet_Id <> ted2.TEDet_Id  
   LEFT JOIN dbo.Timed_Event_Details ted3 ON ted.PU_Id = ted3.PU_Id  
        AND ted.End_Time = ted3.Start_Time  
        AND ted.TEDet_Id <> ted3.TEDet_Id  
   -- Modified P4 --  
   LEFT JOIN Comments C  
   ON ted.Cause_Comment_Id = C.Comment_Id  
   -----------------  
  WHERE ted.Start_Time < @EndTime  
   AND (ted.End_Time >= @StartTime OR ted.End_Time IS NULL)  
  
 END  
-------------------------------------------------------------------------------  
-- Add the detail records that span either end of this collection but may not be  
-- in the data set.  These are records related to multi-downtime events where only  
-- one of the set is within the Report Period.  
-------------------------------------------------------------------------------  
-- Multi-event downtime records that span prior to the Report Period.  
IF @DBVersion < '400000' -- Use the following code specific to pre-Proficy version 4.x... --NHK Rev8.12  
 BEGIN  
  WHILE ( SELECT count(td1.TEDetId)  
   FROM dbo.#Delays td1  
    LEFT JOIN dbo.#Delays td2 ON td1.PrimaryId = td2.TEDetId  
   WHERE td2.TEDetId IS NULL  
    AND td1.PrimaryId IS NOT NULL) > 0  
   BEGIN   
   INSERT INTO dbo.#Delays ( TEDetId,  
      PUId,  
      StartTime,  
      EndTime,  
      LocationId,  
      L1ReasonId,  
      L2ReasonId,  
      L3ReasonId,  
      L4ReasonId,  
      TEFaultId,  
      DownTime,  
      ReportDownTime,  
      PrimaryId,  
      InRptWindow)  
   SELECT ted.TEDet_Id,  
    ted.PU_Id,  
    ted.Start_Time,  
    coalesce(ted.End_Time, @Now),  
    ted.Source_PU_Id,  
    ted.Reason_Level1,  
    ted.Reason_Level2,  
    ted.Reason_Level3,  
    ted.Reason_Level4,  
    ted.TEFault_Id,  
    datediff(s, ted.Start_Time,  
    coalesce(ted.End_Time, @Now)),  
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
   FROM dbo.Timed_Event_Details ted  
    INNER JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
    LEFT JOIN dbo.Timed_Event_Details ted2 ON ted.PU_Id = ted2.PU_Id  
         AND ted.Start_Time = ted2.End_Time  
         AND ted.TEDet_Id <> ted2.TEDet_Id  
   WHERE ted.TEDet_Id IN ( SELECT td1.PrimaryId  
      FROM dbo.#Delays td1  
       LEFT JOIN dbo.#Delays td2 ON td1.PrimaryId = td2.TEDetId  
      WHERE td2.TEDetId IS NULL  
       AND td1.PrimaryId IS NOT NULL)  
   END   
    
  -- Multi-event downtime records that span after the Report Period.  
  WHILE ( SELECT count(td1.TEDetId)--NHK  
   FROM dbo.#Delays td1  
    LEFT JOIN dbo.#Delays td2 ON td1.SecondaryId = td2.TEDetId  
   WHERE td2.TEDetId IS NULL  
    AND td1.SecondaryId IS NOT NULL) > 0  
   BEGIN   
   INSERT dbo.#Delays (TEDetId,  
     PUId,  
     StartTime,  
     EndTime,  
     LocationId,  
     L1ReasonId,  
     L2ReasonId,  
     L3ReasonId,  
     L4ReasonId,  
     TEFaultId,  
     DownTime,  
     ReportDownTime,  
     SecondaryId,  
     InRptWindow)  
   SELECT ted.TEDet_Id,  
    ted.PU_Id,  
    ted.Start_Time,  
    coalesce(ted.End_Time, @Now),  
    ted.Source_PU_Id,  
    ted.Reason_Level1,  
    ted.Reason_Level2,  
    ted.Reason_Level3,  
    ted.Reason_Level4,  
    ted.TEFault_Id,  
    datediff(s, ted.Start_Time, coalesce(ted.End_Time, @Now)),  
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
   FROM dbo.Timed_Event_Details ted  
    INNER JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
    LEFT JOIN dbo.Timed_Event_Details ted3 ON ted.PU_Id = ted3.PU_Id  
         AND ted.End_Time = ted3.Start_Time  
         AND ted.TEDet_Id <> ted3.TEDet_Id  
   WHERE ted.TEDet_Id IN ( SELECT td1.SecondaryId  
      FROM dbo.#Delays td1  
       LEFT JOIN dbo.#Delays td2 ON td1.SecondaryId = td2.TEDetId  
      WHERE td2.TEDetId IS NULL  
       AND td1.SecondaryId IS NOT NULL)  
   END   
    
    
  update dbo.#delays set  
   pudesc = (select pu_desc from dbo.prod_units pu where pu.pu_id = dbo.#delays.puid)  
  where pudesc is null  
 END  
ELSE     --Use the following code specific to Proficy version 4.x+...  
 BEGIN  
  WHILE ( SELECT count(td1.TEDetId)  
   FROM dbo.#Delays td1  
    LEFT JOIN dbo.#Delays td2 ON td1.PrimaryId = td2.TEDetId  
   WHERE td2.TEDetId IS NULL  
    AND td1.PrimaryId IS NOT NULL) > 0  
   BEGIN   
   INSERT INTO dbo.#Delays ( TEDetId,  
      PUId,  
      StartTime,  
      EndTime,  
      LocationId,  
      L1ReasonId,  
      L2ReasonId,  
      L3ReasonId,  
      L4ReasonId,  
      TEFaultId,  
      DownTime,  
      ReportDownTime,  
      PrimaryId,  
      InRptWindow,  
      -- Modified P4 --  
      Comment  
      -----------------  
    )  
   SELECT ted.TEDet_Id,  
    ted.PU_Id,  
    ted.Start_Time,  
    coalesce(ted.End_Time, @Now),  
    ted.Source_PU_Id,  
    ted.Reason_Level1,  
    ted.Reason_Level2,  
    ted.Reason_Level3,  
    ted.Reason_Level4,  
    ted.TEFault_Id,  
    datediff(s, ted.Start_Time,  
    coalesce(ted.End_Time, @Now)),  
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
     ELSE 0 END,  
     -- Modified P4 --  
     C.Comment_Text  
     -----------------  
   FROM dbo.Timed_Event_Details ted  
    INNER JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
    LEFT JOIN dbo.Timed_Event_Details ted2 ON ted.PU_Id = ted2.PU_Id  
         AND ted.Start_Time = ted2.End_Time  
         AND ted.TEDet_Id <> ted2.TEDet_Id  
    -- Modified P4 --  
    LEFT JOIN Comments C  
    ON ted.Cause_Comment_Id = C.Comment_Id  
    -----------------  
   WHERE ted.TEDet_Id IN ( SELECT td1.PrimaryId  
      FROM dbo.#Delays td1  
       LEFT JOIN dbo.#Delays td2 ON td1.PrimaryId = td2.TEDetId  
      WHERE td2.TEDetId IS NULL  
       AND td1.PrimaryId IS NOT NULL)  
   END   
    
  -- Multi-event downtime records that span after the Report Period.  
  WHILE ( SELECT count(td1.TEDetId)--NHK  
   FROM dbo.#Delays td1  
    LEFT JOIN dbo.#Delays td2 ON td1.SecondaryId = td2.TEDetId  
   WHERE td2.TEDetId IS NULL  
    AND td1.SecondaryId IS NOT NULL) > 0  
   BEGIN   
   INSERT dbo.#Delays (TEDetId,  
     PUId,  
     StartTime,  
     EndTime,  
     LocationId,  
     L1ReasonId,  
     L2ReasonId,  
     L3ReasonId,  
     L4ReasonId,  
     TEFaultId,  
     DownTime,  
     ReportDownTime,  
     SecondaryId,  
     InRptWindow,  
     -- Modified P4 --  
     Comment  
     -----------------  
     )  
   SELECT ted.TEDet_Id,  
    ted.PU_Id,  
    ted.Start_Time,  
    coalesce(ted.End_Time, @Now),  
    ted.Source_PU_Id,  
    ted.Reason_Level1,  
    ted.Reason_Level2,  
    ted.Reason_Level3,  
    ted.Reason_Level4,  
    ted.TEFault_Id,  
    datediff(s, ted.Start_Time, coalesce(ted.End_Time, @Now)),  
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
     ELSE 0 END,  
    -- Modified P4 --  
    C.Comment_Text  
    -----------------  
   FROM dbo.Timed_Event_Details ted  
    INNER JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
    LEFT JOIN dbo.Timed_Event_Details ted3 ON ted.PU_Id = ted3.PU_Id  
         AND ted.End_Time = ted3.Start_Time  
         AND ted.TEDet_Id <> ted3.TEDet_Id  
    -- Modified P4 --  
    LEFT JOIN Comments C  
    ON ted.Cause_Comment_Id = C.Comment_Id  
    -----------------  
   WHERE ted.TEDet_Id IN ( SELECT td1.SecondaryId  
      FROM dbo.#Delays td1  
       LEFT JOIN dbo.#Delays td2 ON td1.SecondaryId = td2.TEDetId  
      WHERE td2.TEDetId IS NULL  
       AND td1.SecondaryId IS NOT NULL)  
   END   
    
    
  update dbo.#delays set  
   pudesc = (select pu_desc from dbo.prod_units pu where pu.pu_id = dbo.#delays.puid)  
  where pudesc is null  
 END  
-------------------------------------------------------------------------------  
-- MKW - 7.32  
-- Collect last downtime before the first primary record of each unit to calculate  
-- uptime for those records  
-------------------------------------------------------------------------------  
  
INSERT INTO @FirstEvents ( PUId,  
    StartTime )  
SELECT PUId,  
 MIN(StartTime)  
FROM dbo.#Delays  
GROUP BY PUId  
  
  
SELECT  @Rows = @@ROWCOUNT,  
   @Row = 0  
  
  
IF @DBVersion < '400000' -- Use the following code specific to pre-Proficy version 4.x...  --NHK Rev8.12  
 BEGIN  
    
    
  WHILE @Row < @Rows  
   BEGIN  
   SELECT @Row = @Row + 1  
     
   SELECT @@PUId  = PUId,  
    @@StartTime = StartTime  
   FROM @FirstEvents  
   WHERE FirstEventId = @Row  
    
   INSERT dbo.#Delays (TEDetId,  
     PUId,  
     StartTime,  
     EndTime,  
     LocationId,  
     L1ReasonId,  
     L2ReasonId,  
     L3ReasonId,  
     L4ReasonId,  
     TEFaultId,  
     DownTime,  
     ReportDownTime,  
     InRptWindow)  
   SELECT TOP 1 ted.TEDet_Id,  
     ted.PU_Id,  
     ted.Start_Time,  
     coalesce(ted.End_Time, @Now),  
     ted.Source_PU_Id,  
     ted.Reason_Level1,  
     ted.Reason_Level2,  
     ted.Reason_Level3,  
     ted.Reason_Level4,  
     ted.TEFault_Id,  
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
   FROM dbo.Timed_Event_Details ted  
   WHERE ted.PU_Id = @@PUId  
    AND ted.Start_Time < @@StartTime  
   ORDER BY Start_Time DESC   
   END  
     
   -- MKW - Get the maximum range for later queries  
   SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
    @Min_TEDet_Id = MIN(TEDetId) - 1,  
    @RangeStartTime = MIN(StartTime),  
    @RangeEndTime = MAX(EndTime)  
   FROM dbo.#Delays  
      
  
 -------------------------------------------------------------------------------  
 -- Get the comment for each Timed_Event_Detail record.  
 -------------------------------------------------------------------------------  
         -- Killer query - need better indexes on Waste_n_Timed_Comments  
 UPDATE dbo.#Delays  
 SET Comment = rtrim(ltrim(convert(varchar(5000),WTC.Comment_Text)))  
 FROM dbo.Waste_n_Timed_Comments WTC   
 WHERE (TEDetId = WTC.WTC_Source_Id)   
   
 /* FLD Rev8.11  
 -- Get comments that are attached to the summary events.  
 Update dbo.#Delays    
 set Comment = RTrim(LTrim(Convert(varchar(5000),wtc.Comment_Text)))  
 from dbo.Waste_n_Timed_Comments wtc  
  left outer join dbo.timed_event_summarys tes on TESum_Id = WTC_Source_Id  
 where dbo.#Delays.StartTime = tes.Start_Time and dbo.#Delays.PUId = tes.PU_Id  
  and dbo.#Delays.Comment is null and WTC_Type = 1  
*/  
 END  
ELSE     --Use the following code specific to Proficy version 4.x+...  
 BEGIN  
      
  WHILE @Row < @Rows  
   BEGIN  
   SELECT @Row = @Row + 1  
     
   SELECT @@PUId  = PUId,  
    @@StartTime = StartTime  
   FROM @FirstEvents  
   WHERE FirstEventId = @Row  
    
   INSERT dbo.#Delays (TEDetId,  
     PUId,  
     StartTime,  
     EndTime,  
     LocationId,  
     L1ReasonId,  
     L2ReasonId,  
     L3ReasonId,  
     L4ReasonId,  
     TEFaultId,  
     DownTime,  
     ReportDownTime,  
     InRptWindow,  
     -- Modified P4 --  
     Comment  
     -----------------  
     )  
   SELECT TOP 1 ted.TEDet_Id,  
     ted.PU_Id,  
     ted.Start_Time,  
     coalesce(ted.End_Time, @Now),  
     ted.Source_PU_Id,  
     ted.Reason_Level1,  
     ted.Reason_Level2,  
     ted.Reason_Level3,  
     ted.Reason_Level4,  
     ted.TEFault_Id,  
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
      END,  
     -- Modified P4 --  
     C.Comment_Text  
     -----------------  
   FROM dbo.Timed_Event_Details ted  
   -- Modified P4 --  
   LEFT JOIN Comments C  
   ON ted.Cause_Comment_Id = C.Comment_Id  
   -----------------  
   WHERE ted.PU_Id = @@PUId  
    AND ted.Start_Time < @@StartTime  
   ORDER BY Start_Time DESC   
   END  
     
   -- MKW - Get the maximum range for later queries  
   SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
    @Min_TEDet_Id = MIN(TEDetId) - 1,  
    @RangeStartTime = MIN(StartTime),  
    @RangeEndTime = MAX(EndTime)  
   FROM dbo.#Delays  
      
 End  
  
   
   
  
-------------------------------------------------------------------------------  
-- Cycle through the dataset and ensure that all the PrimaryIds point to the  
-- actual Primary event.  
-------------------------------------------------------------------------------  
WHILE ( SELECT count(td1.TEDetId)  
 FROM dbo.#Delays td1  
  JOIN dbo.#Delays td2 ON td1.PrimaryId = td2.TEDetId  
 WHERE td2.PrimaryId IS NOT NULL) > 0  
 BEGIN   
 UPDATE td1  
 SET PrimaryId = td2.PrimaryId  
 FROM dbo.#Delays td1  
  INNER JOIN dbo.#Delays td2 ON td1.PrimaryId = td2.TEDetId  
 WHERE td2.PrimaryId IS NOT NULL  
 END   
  
UPDATE dbo.#Delays  
SET PrimaryId = TEDetId  
WHERE PrimaryId IS NULL  
  
-------------------------------------------------------------------------------  
-- Add the Products to the dataset.  
-------------------------------------------------------------------------------  
-- We could use @Runs for this instead of requerying Production_Starts again  
UPDATE td  
SET ProdId = ps.Prod_Id  
FROM dbo.#Delays td  
 JOIN dbo.Production_Starts ps ON td.PUId = ps.PU_Id  
     AND td.StartTime >= ps.Start_Time  
     AND (td.StartTime < ps.End_Time OR ps.End_Time IS NULL)  
WHERE ps.Start_Time < @RangeEndTime  
 AND (ps.End_Time > @RangeStartTime OR ps.End_Time IS NULL)  -- MKW  
  
-------------------------------------------------------------------------------  
-- Add the Shift and Crew to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
SET Shift = cs.Shift_Desc,  
 Crew = cs.Crew_Desc  
FROM dbo.#Delays td  
 INNER JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
 INNER JOIN dbo.Crew_Schedule cs ON  tpu.ScheduleUnit = cs.PU_Id  
     AND td.StartTime >= cs.Start_Time  
     AND td.StartTime < cs.End_Time  
WHERE cs.Start_Time < @RangeEndTime  
 AND (cs.End_Time > @RangeStartTime OR cs.End_Time IS NULL)  -- MKW  
  
  
-------------------------------------------------------------------------------  
-- Add the Line Status to the dataset.  
-------------------------------------------------------------------------------  
-- updated Rev7.0  
INSERT INTO @LineStatusRaw ( PUId,  
    PhraseId,  
    StartTime)  
SELECT pu.PUId,  
 ls.Line_Status_Id,  
 ls.Start_DateTime  
FROM dbo.Local_PG_Line_Status ls  
 INNER JOIN @ProdUnits pu ON ls.Unit_Id = pu.LineStatusUnit AND pu.PUId > 0  
WHERE ls.Start_DateTime <    (CASE  WHEN @endtime >   @RangeEndTime   THEN @endtime   ELSE @RangeEndTime   END)  
 AND (ls.end_DateTime > (CASE  WHEN @starttime < @RangeStartTime THEN @starttime ELSE @RangeStartTime END)   
      OR ls.End_DateTime IS NULL)  
 and ls.update_status <> 'DELETE'  
  
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
FROM dbo.#Delays td  
 INNER JOIN @LineStatus ls ON td.PUId = ls.PUId  
 AND td.StartTime >= ls.StartTime  
 AND (td.StartTime < ls.EndTime OR ls.EndTime IS NULL)  
 INNER JOIN dbo.Phrase p ON ls.PhraseId = p.Phrase_Id  
  
  
--------------------------------------------------------------------------------------  
-- change the start and end times of the production run when they extend beyond the   
-- report window  
-------------------------------------------------------------------------------------  
  
update dbo.#runs set  
 starttime = @starttime  
where starttime < @starttime  
  
update dbo.#runs set  
 endtime = @endtime  
where endtime > @endtime  
  
  
-------------------------------------------------------------------------------  
-- Collect all the Production Run records for the reporting period for each  
-- production line by Shift/Team.  
-------------------------------------------------------------------------------  
  
INSERT dbo.#RunsLineShift ( PLId,  
   puid,  
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
FROM dbo.#runs r  
 LEFT JOIN @ProdUnits pu ON r.PUId = pu.PUId  
 LEFT JOIN dbo.Crew_Schedule cs ON pu.ScheduleUnit = cs.PU_Id  
 LEFT JOIN dbo.Prod_Lines pl ON pu.PLId = pl.PL_Id  
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
  
UPDATE dbo.#RunsLineShift  
SET  Shift_StartTime = CASE WHEN Shift_StartTime < @StartTime THEN @StartTime  
    ELSE Shift_StartTime  
    END,  
 Shift_EndTime = CASE WHEN Shift_EndTime > @EndTime THEN @EndTime  
    ELSE Shift_EndTime  
    END  
  
  
-------------------------------------------------------------------------------  
-- Retrieve the Tree Node Ids so we can get the associated categories.  
-------------------------------------------------------------------------------  
-- Level 1.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L1TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM dbo.#Delays td  
 JOIN dbo.Prod_Events pe ON td.LocationId = pe.PU_Id  
  AND pe.Event_Type = 2  
 JOIN dbo.Event_Reason_Tree_Data ertd ON pe.Name_Id = ertd.Tree_Name_Id  
  AND ertd.Event_Reason_Level = 1  
  AND ertd.Event_Reason_Id = td.L1ReasonId  
-------------------------------------------------------------------------------  
-- Level 2.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L2TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM dbo.#Delays td  
 JOIN dbo.Event_Reason_Tree_Data ertd ON td.L1TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 2  
  AND ertd.Event_Reason_Id = td.L2ReasonId  
-------------------------------------------------------------------------------  
-- Level 3.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L3TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM dbo.#Delays td  
 JOIN dbo.Event_Reason_Tree_Data ertd ON td.L2TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 3  
  AND ertd.Event_Reason_Id = td.L3ReasonId  
-------------------------------------------------------------------------------  
-- Level 4.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L4TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM dbo.#Delays td  
 JOIN dbo.Event_Reason_Tree_Data ertd ON td.L3TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 4  
  AND ertd.Event_Reason_Id = td.L4ReasonId  
  
  
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
  
  
---------------------------------------------------------------------------------------  
-- Get ScheduleId and CategoryID information for #Delays.  
---------------------------------------------------------------------------------------  
  
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
  
  
--/*  
INSERT dbo.#Primaries (TEDetId,  
   PUId,  
   StartTime,  
   EndTime)  
SELECT td1.TEDetId,  
 td1.PUId,  
 MIN(td2.StartTime),  
 MAX(td2.EndTime)  
-- updated the From clause for 092704  
FROM dbo.#Delays td1  
JOIN dbo.#Delays td2 ON td1.TEDetId = td2.PrimaryId  
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
    END,  
 ReportUptime = CASE  WHEN p1.PUId = p2.PUId  
     AND p2.EndTime > @StartTime  
      THEN datediff(s, p2.EndTime, p1.StartTime)  
    WHEN p1.PUId = p2.PUId  
     AND p2.EndTime < @StartTime  
     AND p1.StartTime > @StartTime  --Added by FLD 7.33  
      THEN datediff(s, @StartTime, p1.StartTime)  
    ELSE NULL  
    END  
FROM dbo.#Primaries p1  
    INNER JOIN dbo.#Primaries p2 ON p2.TEPrimaryId = (p1.TEPrimaryId - 1)   
WHERE p1.TEPrimaryId > 1  
  
--select * from #primaries  
  
UPDATE td  
 SET UpTime = tp.UpTime,  
  ReportUptime = tp.ReportUptime   
 FROM dbo.#Delays td  
 JOIN dbo.#Primaries tp ON td.TEDetId = tp.TEDetId  
  
  
--*/  
  
  
-------------------------------------------------------------------------------  
-- Calculate the Statistics on the dataset and set NULL Uptimes to zero.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET Stops =   CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  StopsUnscheduled = CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  StopsMinor =  CASE WHEN td.DownTime < 600  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId   
        OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnscheduledId   
        OR td.ScheduleId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  StopsEquipFails = CASE WHEN td.DownTime >= 600  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
       AND (td.ScheduleId = @SchedUnscheduledId   
        OR td.ScheduleId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  StopsBlockedStarved = CASE WHEN td.CategoryId = @CatBlockStarvedId  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END,  
  UpTime2m =  CASE WHEN td.UpTime < 120  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.CategoryId <> @CatBlockStarvedId   
        OR td.CategoryId IS NULL)  
       AND (td.StartTime >= @StartTime)        THEN 1  
      ELSE 0  
      END,  
  StopsProcessFailures = CASE WHEN td.DownTime >= 600  
       AND  tpu.DelayType <> @DelayTypeRateLossStr  
       AND (td.ScheduleId = @SchedUnScheduledId   
        OR td.ScheduleId IS NULL)  
       AND (td.CategoryId NOT IN (@CatMechEquipId,   
        @CatElectEquipId, @CatBlockStarvedId)   
        OR td.CategoryId IS NULL)  
       AND (td.StartTime >= @StartTime)  
      THEN 1  
      ELSE 0  
      END--,  
 FROM dbo.#Delays td  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
 WHERE  td.TEDetId = td.PrimaryId  
  
  
--*******************************************************************************************************************--  
-- Process all the Test requirements.  
--*******************************************************************************************************************--  
-------------------------------------------------------------------------------  
-- Collect all the Test records for the reporting period.  
-------------------------------------------------------------------------------  
  
DECLARE ProdLinesCursor INSENSITIVE CURSOR FOR  
 (SELECT PLId, VarEffDowntimeId FROM @ProdLines)  
 FOR READ ONLY  
OPEN ProdLinesCursor  
FETCH NEXT FROM ProdLinesCursor INTO @@Id, @@VarEffDowntimeId  
  
WHILE @@Fetch_Status = 0  
BEGIN   
 INSERT dbo.#Tests (TestId, VarId, PLId, PUId, Value, StartTime)  
  SELECT Test_Id, t.Var_Id, pl.PL_Id, v.PU_Id, Convert(Float, Result), Result_On  
   FROM dbo.Tests t  
    JOIN dbo.Variables v ON t.Var_Id = v.Var_Id  
    JOIN dbo.Prod_Units pu ON v.PU_Id = pu.PU_Id  
    JOIN dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
   WHERE t.Var_Id IN (@@VarEffDowntimeId)  
   AND Result_On > @StartTime  
   AND Result_On <= @EndTime  
  
 FETCH NEXT FROM ProdLinesCursor INTO @@Id, @@VarEffDowntimeId  
  
END   
CLOSE ProdLinesCursor  
DEALLOCATE ProdLinesCursor  
  
DECLARE TestsCursor INSENSITIVE CURSOR FOR  
 (SELECT TestId, VarId, StartTime  
  FROM dbo.#Tests)  
 FOR READ ONLY  
OPEN TestsCursor  
FETCH NEXT FROM TestsCursor INTO @@Id, @@VarId, @@TimeStamp  
WHILE @@Fetch_Status = 0  
BEGIN   
 SELECT @@NextStartTime = NULL  
 SELECT @@NextStartTime = Min(StartTime)  
  FROM dbo.#Tests  
  WHERE VarId = @@VarId  
  AND StartTime > @@TimeStamp  
  AND StartTime < @Now  
 UPDATE dbo.#Tests  
  SET EndTime = Coalesce(@@NextStartTime, @Now)  
  WHERE TestId = @@Id  
 FETCH NEXT FROM TestsCursor INTO @@Id, @@VarId, @@TimeStamp  
END   
CLOSE TestsCursor  
DEALLOCATE TestsCursor  
  
  
-------------------------------------------------------------------------------  
-- Update the RateLoss ReportDowntime to be equal to the Effective Downtime  
-- from the #Tests table.  Note: Effective Downtime is already in minutes!  
-- Set ReportDowntime and ReportUptime = 0 so that they will not be  
-- included in Total Report Time.  
-------------------------------------------------------------------------------  
  
  
 UPDATE td SET    
  
  RateLossRatio  = (convert(float,t1.Value) * 60.0) / Downtime,  
  ReportDowntime  = 0,  
  ReportUptime = 0  
  
 FROM dbo.#Delays td  
   JOIN @ProdUnits pu ON td.PUID = pu.PUID  
   JOIN @ProdLines pl ON pu.PLID = pl.PLID  
  LEFT  JOIN dbo.#Tests t1 ON (td.StartTime = t1.StartTime)   
     AND (pl.VarEffDowntimeId = t1.VarId)  
 WHERE pu.DelayType = @DelayTypeRateLossStr  
 and Downtime <> 0  
  
  
update dbo.#delays set  
 RateLossRatio = 1.0  
where RateLossRatio is null  
  
  
-- added by JSJ with 060804 enhancements  
update dbo.#delays set  
 PLID = (select pl_id from dbo.prod_units where pu_id = puid)  
  
-------------------------------------------------------------------------------------------  
-- insert records into #EventsByShiftProduct for each shift period in the report window.  
-- then update the rest of the table with summary data.  
-------------------------------------------------------------------------------------------  
  
  insert into dbo.#EventsByShiftProduct   
     (  
     StartTime,   
     EndTime,   
     prodid,   
     PLID,   
     puid,  
     pudesc,  
     Team,   
     Shift,       PrimaryId,  
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
     MinorEF,  
     ModerateEF,  
     MajorEF,  
     MinorPF,  
     ModeratePF,  
     MajorPF,  
     RateLossRatio,  
     Causes,  
     Comment  
     )  
  select    distinct  
     case when td.StartTime < rls.shift_StartTime  
     then rls.shift_StartTime else td.StartTime end,  
     case when (td.EndTime > rls.shift_EndTime or td.EndTime is null)  
     then rls.shift_EndTime else td.EndTime end,  
     rls.prodid,  
     td.plid,  
     td.puid,  
     td.pudesc,  
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
     StopsUnscheduled,  
     StopsMinor,  
     StopsEquipFails,  
     StopsProcessFailures,  
     StopsBlockedStarved,  
     UpTime2m,  
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
     1,  
     Comment  
  from  dbo.#RunsLineShift rls   
  join  dbo.#delays td on rls.plid = td.plid  -- changed 060804 by JSJ  
   and (((rls.shift_starttime < td.endtime or td.endtime is null)   
   and rls.shift_endtime > td.starttime) or inRptWindow = 0)  
   and rls.puid = td.puid  
  where inRptWindow = 1  
  
  
  update td set  
   RL1Desc = er1.Event_Reason_Name,  
   RL2Desc = er2.Event_Reason_Name,  
   RL3Desc = er3.Event_Reason_Name,  
   RL4Desc = er4.Event_Reason_Name,  
   CatDesc = SubString(erc.ERC_Desc, CharIndex(':', erc.ERC_Desc) + 1, 50)  
  FROM dbo.#EventsByShiftProduct td  
  LEFT JOIN dbo.Event_Reason_Catagories erc ON td.CategoryId = erc.ERC_Id  
  LEFT JOIN dbo.Event_Reasons er1 ON td.L1ReasonId = er1.Event_Reason_Id  
  LEFT JOIN dbo.Event_Reasons er2 ON td.L2ReasonId = er2.Event_Reason_Id  
  LEFT JOIN dbo.Event_Reasons er3 ON td.L3ReasonId = er3.Event_Reason_Id  
  LEFT JOIN dbo.Event_Reasons er4 ON td.L4ReasonId = er4.Event_Reason_Id  
  
  
  update dbo.#EventsByShiftProduct set  
   CatDesc = replace(Rl4Desc,'Category:','')  
  where CatDesc is null  
  and left(RL4Desc, 8) like 'Category'  
    
  
  update dbo.#EventsByShiftProduct set  
   ReportDowntime = datediff(ss,StartTime,EndTime) * RateLossRatio,  
   PartialStops = case  
   when  datediff(ss,StartTime,EndTime) = 0 then coalesce(Stops,0)  
   else  convert(float,(convert(float,datediff(ss,StartTime,EndTime))/Downtime))    
   end  
  where coalesce(stopsRateloss,0) = 0  
  
  update dbo.#EventsByShiftProduct set  
   dbspID = ebspID  
  
  update dbo.#EventsByShiftProduct set  
   Downtime = null,  
   Uptime = null,  
   Stops = null,  
   StopsMinor = null,     StopsEquipFails = null,  
   StopsProcessFailures = null,  
   UpTime2m = null,  
   MinorEF = null,  
   ModerateEF = null,  
   MajorEF = null,  
   MinorPF = null,  
   ModeratePF = null,  
   MajorPF = null,  
   Causes = 0  
  where  (  
   select count(*)   
   from dbo.#delays td  
   where td.starttime = dbo.#EventsByShiftProduct.starttime  
   ) = 0  
  
  
  -----------------------------------------------------------------  
  -- get Uptime data  
  -----------------------------------------------------------------  
  
  -- get the basic data for uptime between downtime events.  
  insert into dbo.#UptimeByShiftProduct   
   (  
   StartTime,   
   EndTime,   
   prodid,   
   PLID,   
   puid,  
   pudesc,  
   Team,   
   Shift,  
   ReportUptime--,  
   )  
  select distinct  
   case   
   when td1.endtime between rls.shift_starttime and rls.shift_endtime  
   then td1.EndTime  
   else rls.shift_StartTime end,  
   case   
   when td2.starttime between rls.shift_starttime and rls.shift_endtime  
   then td2.StartTime   
   else rls.shift_EndTime end,  
   rls.prodid,   
   rls.PLID,  
   rls.puid,  
   td1.pudesc,  
   rls.Team,  
   rls.Shift,  
   0--,  
  from  dbo.#RunsLineShift rls   
  join  dbo.#EventsByShiftProduct td1   
  on  rls.puid = td1.puid  
  and ((rls.shift_starttime < td1.endtime or td1.endtime is null)   
   and rls.shift_endtime > td1.starttime)  
   and rls.shift = td1.shift  
   and rls.team = td1.team  
  left join  dbo.#EventsByShiftProduct td2   
  on td1.puid = td2.puid  
  and td2.dbspId =   
   (  
   select  min(dbspId)  
   from  dbo.#EventsByShiftProduct dbsp  
   where   td1.dbspId < dbsp.dbspId  
   and td1.puid = dbsp.puid  
   )   
  
  -- get the uptime from the start of a shift/product to the first downtime event.  
  insert into dbo.#UptimeByShiftProduct   
   (  
   StartTime,   
   EndTime,   
   prodid,   
   PLID,   
   puid,  
   pudesc,  
   Team,   
   Shift,  
   ReportUptime--,  
   )  
  (select distinct  
   rls.shift_starttime,  
   td.starttime,  
   rls.prodid,  
   rls.PLID,  
   rls.puid,  
   td.pudesc,  
   rls.Team,  
   rls.Shift,  
   0--,  
  from  dbo.#RunsLineShift rls   
  join  dbo.#EventsByShiftProduct td   
  on  rls.puid = td.puid  
  and rls.shift = td.shift  
  and rls.team = td.team  
  and (rls.shift_starttime < td.starttime   
   and rls.shift_endtime > td.starttime)  
  and  td.StartTime =   
   (  
   select min(StartTime)  
   from dbo.#EventsByShiftProduct td1  
   where rls.shift_starttime <= td1.StartTime   
   and rls.shift_endtime > td1.starttime  
   and rls.puid = td1.puid  
   )  
  )  
  
  -- get the uptime from the timespans where no downtime occurred   
  
  insert into dbo.#UptimeByShiftProduct   
   (  
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
   rls.shift_starttime,  
   rls.shift_endtime,  
   rls.prodid,  
   rls.PLID,  
   rls.puid,  
   rls.Team,  
   rls.Shift,  
   0  
  from  dbo.#RunsLineShift rls    
  where    
   (  
   select count(*)   
   from dbo.#EventsByShiftProduct td   
   where  rls.puid = td.puid  
   and rls.prodid = td.prodid  
   and rls.team = td.team  
   and rls.shift = td.shift   
   and rls.shift_starttime < td.endtime   
   and  rls.shift_endtime > td.starttime  
   )  
  = 0  
  
  
  update dbo.#UptimeByShiftProduct set  
   pudesc =  (  
     select top 1 pudesc   
     from dbo.#EventsByShiftProduct td  
     where td.puid = dbo.#UptimeByShiftProduct.puid  
     )  
  
  update dbo.#UptimeByShiftProduct set  
   ReportUptime = datediff(ss,StartTime,EndTime)  
  
  
  ----------------------------------------------------------  
  -- put Uptime into the #EventsByShiftProduct  
  ---------------------------------------------------------  
  
  delete from dbo.#UptimeByShiftProduct where starttime = endtime   
  
  -- Added the following update for Rev7.1  
  UPDATE dbo.#UptimeByShiftProduct SET  
   LineStatus =  (  
     SELECT p.Phrase_Value   
     FROM @LineStatus ls  
     JOIN dbo.Phrase p ON ls.PhraseId = p.Phrase_Id  
     WHERE ls.puid = dbo.#UptimeByShiftProduct.puid  
     AND dbo.#UptimeByShiftProduct.endtime >= ls.starttime    
     AND (dbo.#UptimeByShiftProduct.endtime < ls.endtime or ls.endtime IS NULL)    
     )  
  WHERE dbspID is NULL   
     
  
--/*  
  update dbo.#UptimeByShiftProduct set  
   dbspID =  
   (  
   select distinct dbspID  
   from dbo.#EventsByShiftProduct ebsp  
   where ebsp.StartTime = dbo.#UptimeByShiftProduct.EndTime  
   and ebsp.puid = dbo.#UptimeByShiftProduct.puid   
   )  
  
  
  update dbo.#EventsByShiftProduct set  
   ReportUptime =  
   (  
   select sum(ReportUptime)  
   from dbo.#UptimeByShiftProduct ubsp  
   where ubsp.puid = dbo.#EventsByShiftProduct.puid  
   and ubsp.EndTime = dbo.#EventsByShiftProduct.StartTime  
   )  
  
  
  insert into dbo.#EventsByShiftProduct   
   (  
   StartTime,   
   EndTime,   
   prodid,   
   PLID,   
   puid,  
   pudesc,  
   Team,   
   Shift,  
   Downtime,  
   ReportDowntime,  
   Uptime,  
   ReportUptime,  
   LineStatus, -- added Rev7.0  
   Comment  
   )  
  select  
   StartTime,   
   EndTime,   
   prodid,   
   PLID,   
   puid,  
   pudesc,  
   Team,   
   Shift,  
   0,0,0,  
   ReportUptime,  
   LineStatus, -- added Rev7.0  
   'This record artificially created for the sole purpose of allocating uptime that spans shift changes, product changes, and/or the report end time.'--,  
  from dbo.#UptimeByShiftProduct  
  where dbspID is null  
    
  
  
ReturnResultSets:  
  
  
----------------------------------------------------------------------------------------------------  
-- Error Messages.  
----------------------------------------------------------------------------------------------------  
  
  
IF (SELECT count(*) FROM @ErrorMessages) > 0  
 SELECT ErrMsg  
 FROM @ErrorMessages  
   
ELSE  
 BEGIN  
 -------------------------------------------------------------------------------  
 -- Error Messages.  
 -------------------------------------------------------------------------------  
 SELECT ErrMsg  
 FROM @ErrorMessages  
  
 -------------------------------------------------------------------------------  
 -- All Stops result set  
 -------------------------------------------------------------------------------  
  
--/*   
  INSERT dbo.#Stops  
  SELECT pl.PL_Desc,  
   Convert(nVarChar(25), td.StartTime, 120),  
   Convert(nVarChar(25), td.EndTime, 120),  
   pu.PU_Desc,  
   RL1Desc,   
   RL2Desc,   
   RL3Desc,   
   RL4Desc,   
   loc.PU_Desc,  
   p.Prod_Desc,  
   tef.TEFault_Name,  
   td.LineStatus,  
   SubString(erc1.ERC_Desc, CharIndex(':', erc1.ERC_Desc) + 1, 50),  
   0,  
   CatDesc,   
   SubString(erc3.ERC_Desc, CharIndex(':', erc3.ERC_Desc) + 1, 50),  
   SubString(erc4.ERC_Desc, CharIndex(':', erc4.ERC_Desc) + 1, 50),  
   td.Shift,  
   td.team,  
   tpu.DelayType,  
   CASE  WHEN td.TEDetId = td.PrimaryId THEN 'Primary'   
    when td.PrimaryID is null then 'Reporting'  
    ELSE 'Secondary' END,  
   Coalesce(td.Stops, 0),  
   Coalesce(td.StopsMinor, 0),  
   Coalesce(td.StopsEquipFails, 0),  
   Coalesce(td.StopsProcessFailures, 0),  
   coalesce(td.causes,0),   
   coalesce(td.Downtime,0.0)/60.0,  
   coalesce(td.ReportDownTime,0.0)/60.0,  
   0.0,  
   coalesce(td.Uptime,0.0)/60.0,  
   coalesce(td.ReportUpTime,0.0)/60.0,  
   Coalesce(td.UpTime2m, 0),  
   (  
   CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1)   
    AND (td.ReportDowntime/60.0 >= 10.0)  
    and (td.ReportDowntime/60.0 <= 60.0)   
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1)   
    AND (td.ReportDowntime/60.0 > 60.0)  
    and (td.ReportDowntime/60.0 <= 360.0)   
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1)   
    AND (td.ReportDowntime/60.0 > 360.0)  
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1)   
    AND (td.ReportDowntime/60.0 >= 10.0)  
    and (td.ReportDowntime/60.0 <= 60.0)   
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1)   
    AND (td.ReportDowntime/60.0 > 60.0)  
    and (td.ReportDowntime/60.0 <= 360.0)   
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1)   
    AND (td.ReportDowntime/60.0 > 360.0)  
    THEN 1  
    ELSE 0   
    END  
   ),  
   Comment,  
   (  
   select case when count(*) > 0 then 1.0/convert(float,count(*)) else 0 end  
    from dbo.#EventsByShiftProduct ebsp where td.puid = ebsp.puid  
   )  
   --1  
  
   FROM  dbo.#EventsByShiftProduct td  
   JOIN  @ProdUnits tpu ON td.PUId = tpu.PUId  
   JOIN  dbo.Prod_Units pu ON td.PUId = pu.PU_Id  
   JOIN  dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
   JOIN  dbo.Products p ON td.ProdId = p.Prod_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc1 ON td.ScheduleId = erc1.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc3 ON td.SubSystemId = erc3.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc4 ON td.GroupCauseId = erc4.ERC_Id  
   LEFT JOIN dbo.Prod_Units loc ON td.LocationId = loc.PU_Id  
   LEFT  JOIN  dbo.Timed_Event_Fault tef on (td.TEFaultID = TEF.TEFault_ID)  
   ORDER  BY pl.Pl_Desc, td.Starttime, td.Endtime  
  
  update dbo.#Stops set  
   [Unscheduled Stops] = [Total Stops],  
   [Unscheduled Rpt DT] = [Reporting Downtime]  
  where lower(ltrim(rtrim(coalesce(schedule,'')))) in ('unscheduled','')  
    
  
  -- added Rev7.0  
  update dbo.#Stops set  
   [Comment] = replace(coalesce([Comment],''), char(13)+char(10), ' ')  
  
  
  select @SQL =   
  case  
  when (select count(*) from dbo.#Stops) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from dbo.#Stops) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#Stops', @LanguageId)  
  end  
  
 EXEC(@SQL)  
  
  
 IF @BySummary = 1  
    
 BEGIN  
  
  -----------------------------------------------------------------------------  
  -- Return multiple resultsets for the Summary version of the report.  There are  
  -- a total of seven that have the data organized in various arrangements.  
  -----------------------------------------------------------------------------  
  -----------------------------------------------------------------------------  
  -- Return the result set for Line/Team grouping.  
  -----------------------------------------------------------------------------  
  
   
  INSERT dbo.#TeamSummary  
  SELECT pl.PL_Desc,  
   pu.pu_desc,  
   td.team,  
  
   Sum(Coalesce(td.Stops, 0)),  
   Sum(Coalesce(td.StopsMinor, 0)),  
   Sum(Coalesce(td.StopsEquipFails, 0)),  
   Sum(Coalesce(td.StopsProcessFailures, 0)),  
   sum(coalesce(td.causes,0)),  
   SUM(coalesce(td.Downtime,0)/60.0),  
   SUM(coalesce(td.ReportDowntime,0)/60.0),  
   SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
    THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
          ELSE 0 END),  
   Sum(coalesce(td.Uptime,0.0)/60.0),  
   sum(coalesce(td.ReportUpTime,0.0)/60.0),  
   CASE  WHEN  (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     ) > 0   
    THEN   sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0) /    
     (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     )  
    ELSE 0.0 END,  
   Sum(Coalesce(td.UpTime2m, 0)),  
   CASE WHEN SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
         OR td.ScheduleId IS NULL   
        THEN Coalesce(td.Stops,0)  
        ELSE 0.0 END)) > 0   
    THEN ROUND(1 -  SUM(convert(float, CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL)   
          AND td.Uptime2m = 1   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)) /  
      SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)), 2)   
    ELSE 0.0 END,   
   CASE  WHEN SUM(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
       OR td.ScheduleId IS NULL   
       THEN convert(float,coalesce(td.Stops,0))  
      ELSE 0.0 END) > 0   
    THEN ROUND( sum(coalesce(td.ReportUpTime,0.0)/60.0) /  
             SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
        OR td.ScheduleId IS NULL   
         THEN convert(float,coalesce(td.Stops,0))  
        ELSE 0.0 END),2)   
    ELSE 0 END,  
   CASE  WHEN Sum(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
      THEN convert(float,coalesce(td.Stops,0))   
      ELSE 0.0 END) > 0   
    THEN  SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
             ELSE 0 END) /   
     Sum(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
       THEN convert(float,coalesce(td.Stops,0))   
       ELSE 0.0 END)  
    ELSE 0.0 END,  
   sum(coalesce(td.MinorEF,0)),  
   sum(coalesce(td.ModerateEF,0)),  
   sum(coalesce(td.MajorEF,0)),  
   sum(coalesce(td.MinorPF,0)),  
   sum(coalesce(td.ModeratePF,0)),  
   sum(coalesce(td.MajorPF,0))  
  
  
  FROM dbo.#EventsByShiftProduct td  
  JOIN dbo.Prod_Units pu ON td.PUId = pu.PU_Id  
  JOIN dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
  LEFT  JOIN dbo.Timed_Event_Fault tef on td.TEFaultID = TEF.TEFault_ID  
  GROUP BY pl.pl_desc, td.Team, pu.pu_desc  
  ORDER BY pl.pl_desc, td.Team, pu.pu_desc  
  
  
  select @SQL =   
  case  
  when (select count(*) from dbo.#TeamSummary) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from dbo.#TeamSummary) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#TeamSummary', @LanguageId)  
  end  
  
  EXEC(@SQL)  
  
   
  -----------------------------------------------------------------------------  
  -- Return the result set for Line/Shift Type grouping.  
  -----------------------------------------------------------------------------  
   
  INSERT dbo.#ShiftSummary  
  SELECT pl.PL_Desc,  
   pu.pu_desc,  
   td.Shift,  
   Sum(Coalesce(td.Stops, 0)),  
   Sum(Coalesce(td.StopsMinor, 0)),  
   Sum(Coalesce(td.StopsEquipFails, 0)),  
   Sum(Coalesce(td.StopsProcessFailures, 0)),  
   sum(coalesce(td.causes,0)),  
   SUM(coalesce(td.Downtime,0)/60.0),  
   SUM(coalesce(td.ReportDowntime,0)/60.0),  
   SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
    THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
          ELSE 0 END),  
   Sum(coalesce(td.Uptime,0.0)/60.0),  
   sum(coalesce(td.ReportUpTime,0.0)/60.0),  
   CASE  WHEN  (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     ) > 0   
    THEN   sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0) /    
     (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     )  
    ELSE 0.0 END,  
   Sum(Coalesce(td.UpTime2m, 0)),  
   CASE WHEN SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
                OR td.ScheduleId IS NULL   
        THEN Coalesce(td.Stops,0)  
        ELSE 0.0 END)) > 0   
    THEN ROUND(1 -  SUM(convert(float, CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL)   
          AND td.Uptime2m = 1   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)) /  
      SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)), 2)   
    ELSE 0.0 END,   
   CASE  WHEN SUM(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
       OR td.ScheduleId IS NULL   
       THEN convert(float,coalesce(td.Stops,0))  
      ELSE 0.0 END) > 0   
    THEN ROUND( sum(coalesce(td.ReportUpTime,0.0)/60.0) /  
             SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
        OR td.ScheduleId IS NULL   
         THEN convert(float,coalesce(td.Stops,0))  
        ELSE 0.0 END),2)   
    ELSE 0 END,  
   CASE  WHEN Sum(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
      THEN convert(float,coalesce(td.Stops,0))   
      ELSE 0.0 END) > 0   
    THEN  SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
             ELSE 0 END) /   
     Sum(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
       THEN convert(float,coalesce(td.Stops,0))   
       ELSE 0.0 END)  
    ELSE 0.0 END,  
   sum(coalesce(td.MinorEF,0)),  
   sum(coalesce(td.ModerateEF,0)),  
   sum(coalesce(td.MajorEF,0)),  
   sum(coalesce(td.MinorPF,0)),  
   sum(coalesce(td.ModeratePF,0)),  
   sum(coalesce(td.MajorPF,0))  
  FROM dbo.#EventsByShiftProduct td  
  JOIN dbo.Prod_Units pu ON td.PUId = pu.PU_Id  
  JOIN dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
  GROUP BY pl.pl_desc, td.Shift, pu.pu_desc   
  ORDER BY pl.pl_desc, td.Shift, pu.pu_desc  
  
  select @SQL =   
  case  
  when (select count(*) from dbo.#ShiftSummary) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from dbo.#ShiftSummary) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#ShiftSummary', @LanguageId)  
  end  
  
  EXEC(@SQL)  
  
   
  -----------------------------------------------------------------------------  
  -- Return the result set for Line/Product grouping.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#ProductSummary  
  SELECT pl.PL_Desc,  
   pu.pu_desc,  
   p.Prod_Desc,  
   Sum(Coalesce(td.Stops, 0)),  
   Sum(Coalesce(td.StopsMinor, 0)),  
   Sum(Coalesce(td.StopsEquipFails, 0)),  
   Sum(Coalesce(td.StopsProcessFailures, 0)),  
   sum(coalesce(td.causes,0)),  
   SUM(coalesce(td.Downtime,0)/60.0),  
   SUM(coalesce(td.ReportDowntime,0)/60.0),  
   SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
    THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
          ELSE 0 END),  
   Sum(coalesce(td.Uptime,0.0)/60.0),  
   sum(coalesce(td.ReportUpTime,0.0)/60.0),  
   CASE  WHEN  (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     ) > 0   
    THEN   sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0) /    
     (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     )  
    ELSE 0.0 END,  
   Sum(Coalesce(td.UpTime2m, 0)),  
   CASE WHEN SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
                OR td.ScheduleId IS NULL   
        THEN Coalesce(td.Stops,0)  
        ELSE 0.0 END)) > 0   
    THEN ROUND(1 -  SUM(convert(float, CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL)   
          AND td.Uptime2m = 1   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)) /  
      SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)), 2)   
    ELSE 0.0 END,   
   CASE  WHEN SUM(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
       OR td.ScheduleId IS NULL   
       THEN convert(float,coalesce(td.Stops,0))  
      ELSE 0.0 END) > 0   
    THEN ROUND( sum(coalesce(td.ReportUpTime,0.0)/60.0) /  
             SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
        OR td.ScheduleId IS NULL   
         THEN convert(float,coalesce(td.Stops,0))  
        ELSE 0.0 END),2)   
    ELSE 0 END,  
   CASE  WHEN Sum(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
      THEN convert(float,coalesce(td.Stops,0))   
      ELSE 0.0 END) > 0   
    THEN  SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
             ELSE 0 END) /   
     Sum(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
       THEN convert(float,coalesce(td.Stops,0))   
       ELSE 0.0 END)  
    ELSE 0.0 END,  
   sum(coalesce(td.MinorEF,0)),  
   sum(coalesce(td.ModerateEF,0)),  
   sum(coalesce(td.MajorEF,0)),  
   sum(coalesce(td.MinorPF,0)),  
   sum(coalesce(td.ModeratePF,0)),  
   sum(coalesce(td.MajorPF,0))  
  FROM dbo.#EventsByShiftProduct td  
  JOIN dbo.Prod_Units pu ON td.PUId = pu.PU_Id  
  JOIN dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
  JOIN dbo.Products p ON td.ProdId = p.Prod_Id  
  GROUP BY pl.pl_desc, p.Prod_Desc, pu.pu_desc   
  ORDER BY pl.pl_desc, p.Prod_Desc, pu.pu_desc  
  
   
  select @SQL =   
  case  
  when (select count(*) from dbo.#ProductSummary) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from dbo.#ProductSummary) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#ProductSummary', @LanguageId)  
  end  
  
  EXEC(@SQL)  
  
  
  -----------------------------------------------------------------------------  
  -- Return the result set for Line/Location Type grouping.  
  -----------------------------------------------------------------------------  
  
   
  INSERT dbo.#LocationSummary  
  SELECT pl.PL_Desc,  
   pu.pu_desc,  
   tpu.DelayType,  
   Sum(Coalesce(td.Stops, 0)),  
   Sum(Coalesce(td.StopsMinor, 0)),  
   Sum(Coalesce(td.StopsEquipFails, 0)),  
   Sum(Coalesce(td.StopsProcessFailures, 0)),  
   sum(coalesce(td.causes,0)),  
   SUM(coalesce(td.Downtime,0)/60.0),  
   SUM(coalesce(td.ReportDowntime,0)/60.0),  
   SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
    THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
          ELSE 0 END),  
   Sum(coalesce(td.Uptime,0.0)/60.0),  
   sum(coalesce(td.ReportUpTime,0.0)/60.0),  
   CASE  WHEN  (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     ) > 0   
    THEN   sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0) /    
     (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     )  
    ELSE 0.0 END,  
   Sum(Coalesce(td.UpTime2m, 0)),  
   CASE WHEN SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
                OR td.ScheduleId IS NULL   
        THEN Coalesce(td.Stops,0)  
        ELSE 0.0 END)) > 0   
    THEN ROUND(1 -  SUM(convert(float, CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL)   
          AND td.Uptime2m = 1   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)) /  
      SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)), 2)   
    ELSE 0.0 END,   
   CASE  WHEN SUM(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
       OR td.ScheduleId IS NULL   
       THEN convert(float,coalesce(td.Stops,0))  
      ELSE 0.0 END) > 0   
    THEN ROUND( sum(coalesce(td.ReportUpTime,0.0)/60.0) /  
             SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
        OR td.ScheduleId IS NULL   
         THEN convert(float,coalesce(td.Stops,0))  
        ELSE 0.0 END),2)   
    ELSE 0 END,  
   CASE  WHEN Sum(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
      THEN convert(float,coalesce(td.Stops,0))   
      ELSE 0.0 END) > 0   
    THEN  SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
             ELSE 0 END) /   
     Sum(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
       THEN convert(float,coalesce(td.Stops,0))   
       ELSE 0.0 END)  
    ELSE 0.0 END,  
   sum(coalesce(td.MinorEF,0)),  
   sum(coalesce(td.ModerateEF,0)),  
   sum(coalesce(td.MajorEF,0)),  
   sum(coalesce(td.MinorPF,0)),  
   sum(coalesce(td.ModeratePF,0)),  
   sum(coalesce(td.MajorPF,0))  
  FROM dbo.#EventsByShiftProduct td  
  JOIN dbo.Prod_Units pu ON td.PUId = pu.PU_Id  
  JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
  JOIN dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
  GROUP BY pl.pl_desc, tpu.DelayType, pu.pu_desc  
  ORDER BY pl.pl_desc, tpu.DelayType, pu.pu_desc  
  
  
  select @SQL =   
  case  
  when (select count(*) from dbo.#LocationSummary) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from dbo.#LocationSummary) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#LocationSummary', @LanguageId)  
  end  
  
  EXEC(@SQL)  
  
   
  -----------------------------------------------------------------------------  
  -- Return the result set for Line/Category grouping.  
  -----------------------------------------------------------------------------  
  
   
  INSERT dbo.#CategorySummary  
  SELECT pl.PL_Desc,  
   pu.pu_desc,  
   CatDesc, --SubString(erc2.ERC_Desc, CharIndex(':', erc2.ERC_Desc) + 1, 50),  
   Sum(Coalesce(td.Stops, 0)),  
   Sum(Coalesce(td.StopsMinor, 0)),  
   Sum(Coalesce(td.StopsEquipFails, 0)),  
   Sum(Coalesce(td.StopsProcessFailures, 0)),  
   sum(coalesce(td.causes,0)),  
   SUM(coalesce(td.Downtime,0)/60.0),  
   SUM(coalesce(td.ReportDowntime,0)/60.0),  
   SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
    THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
          ELSE 0 END),  
   Sum(coalesce(td.Uptime,0.0)/60.0),  
   sum(coalesce(td.ReportUpTime,0.0)/60.0),  
   CASE  WHEN  (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     ) > 0   
    THEN   sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0) /    
     (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     )  
    ELSE 0.0 END,  
   Sum(Coalesce(td.UpTime2m, 0)),  
   CASE WHEN SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
                OR td.ScheduleId IS NULL   
        THEN Coalesce(td.Stops,0)  
        ELSE 0.0 END)) > 0   
    THEN ROUND(1 -  SUM(convert(float, CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL)   
          AND td.Uptime2m = 1   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)) /  
      SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)), 2)   
    ELSE 0.0 END,   
   CASE  WHEN SUM(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
       OR td.ScheduleId IS NULL   
       THEN convert(float,coalesce(td.Stops,0))  
      ELSE 0.0 END) > 0   
    THEN ROUND( sum(coalesce(td.ReportUpTime,0.0)/60.0) /  
             SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
        OR td.ScheduleId IS NULL   
         THEN convert(float,coalesce(td.Stops,0))  
        ELSE 0.0 END),2)   
    ELSE 0 END,  
   CASE  WHEN Sum(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
      THEN convert(float,coalesce(td.Stops,0))   
      ELSE 0.0 END) > 0   
    THEN  SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
             ELSE 0 END) /   
     Sum(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
       THEN convert(float,coalesce(td.Stops,0))   
       ELSE 0.0 END)  
    ELSE 0.0 END,  
   sum(coalesce(td.MinorEF,0)),  
   sum(coalesce(td.ModerateEF,0)),  
   sum(coalesce(td.MajorEF,0)),  
   sum(coalesce(td.MinorPF,0)),  
   sum(coalesce(td.ModeratePF,0)),  
   sum(coalesce(td.MajorPF,0))  
  FROM dbo.#EventsByShiftProduct td  
  JOIN dbo.Prod_Units pu ON td.PUId = pu.PU_Id  
  JOIN dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
  GROUP BY pl.pl_desc, CatDesc, pu.pu_desc  
  ORDER BY pl.pl_desc, CatDesc, pu.pu_desc  
  
  
  select @SQL =   
  case  
  when (select count(*) from dbo.#CategorySummary) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from dbo.#CategorySummary) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#CategorySummary', @LanguageId)  
  end  
  
  EXEC(@SQL)  
  
   
  -----------------------------------------------------------------------------  
  -- Return the result set for Line/Schedule grouping.  
  -----------------------------------------------------------------------------  
   
  INSERT dbo.#ScheduleSummary  
  SELECT pl.PL_Desc [Production Line],  
   pu.pu_desc,  
   SubString(erc1.ERC_Desc, CharIndex(':', erc1.ERC_Desc) + 1, 50),  
   Sum(Coalesce(td.Stops, 0)),  
   Sum(Coalesce(td.StopsMinor, 0)),  
   Sum(Coalesce(td.StopsEquipFails, 0)),  
   Sum(Coalesce(td.StopsProcessFailures, 0)),  
   sum(coalesce(td.causes,0)),  
   SUM(coalesce(td.Downtime,0)/60.0),  
   SUM(coalesce(td.ReportDowntime,0)/60.0),  
   SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
    THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
          ELSE 0 END),  
   Sum(coalesce(td.Uptime,0.0)/60.0),  
   sum(coalesce(td.ReportUpTime,0.0)/60.0),  
   CASE  WHEN  (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     ) > 0   
    THEN   sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0) /    
     (sum(convert(float,coalesce(td.ReportUpTime,0.0))/60.0)  
     +  
     SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
       ELSE 0.0 END)  
     )  
    ELSE 0.0 END,  
   Sum(Coalesce(td.UpTime2m, 0)),  
   CASE WHEN SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
                OR td.ScheduleId IS NULL   
        THEN Coalesce(td.Stops,0)  
        ELSE 0.0 END)) > 0   
    THEN ROUND(1 -  SUM(convert(float, CASE WHEN (td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL)   
          AND td.Uptime2m = 1   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)) /  
      SUM(convert(float, CASE WHEN td.ScheduleId <> @SchedHolidayCurtailId   
          OR td.ScheduleId IS NULL   
         THEN Coalesce(td.Stops,0)  
         ELSE 0.0 END)), 2)   
    ELSE 0.0 END,   
   CASE  WHEN SUM(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
       OR td.ScheduleId IS NULL   
       THEN convert(float,coalesce(td.Stops,0))  
      ELSE 0.0 END) > 0   
    THEN ROUND( sum(coalesce(td.ReportUpTime,0.0)/60.0) /  
             SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
        OR td.ScheduleId IS NULL   
         THEN convert(float,coalesce(td.Stops,0))  
        ELSE 0.0 END),2)   
    ELSE 0 END,  
   CASE  WHEN Sum(CASE  WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
      THEN convert(float,coalesce(td.Stops,0))   
      ELSE 0.0 END) > 0   
    THEN  SUM(CASE WHEN td.ScheduleId = @SchedUnscheduledID or td.ScheduleID is null  
       THEN convert(float,coalesce(td.ReportDowntime,0))/60.0  
             ELSE 0 END) /   
     Sum(CASE WHEN td.ScheduleId = @SchedUnscheduledId   
         OR td.ScheduleId IS NULL  
       THEN convert(float,coalesce(td.Stops,0))   
       ELSE 0.0 END)  
    ELSE 0.0 END,  
   sum(coalesce(td.MinorEF,0)),  
   sum(coalesce(td.ModerateEF,0)),  
   sum(coalesce(td.MajorEF,0)),  
   sum(coalesce(td.MinorPF,0)),  
   sum(coalesce(td.ModeratePF,0)),  
   sum(coalesce(td.MajorPF,0))  
  FROM dbo.#EventsByShiftProduct td  
  JOIN dbo.Prod_Units pu ON td.PUId = pu.PU_Id  
  JOIN dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc1 ON td.ScheduleId = erc1.ERC_Id  
  GROUP BY pl.pl_desc, erc1.ERC_Desc, pu.pu_desc  
  ORDER BY pl.pl_desc, erc1.ERC_Desc, pu.pu_desc  
  
  select @SQL =   
  case  
  when (select count(*) from dbo.#ScheduleSummary) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from dbo.#ScheduleSummary) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#ScheduleSummary', @LanguageId)  
  end  
  
  EXEC(@SQL)  
  
  
  END  
  
  -- RawData result set  
  
  delete dbo.#Stops  
  INSERT dbo.#Stops  
  SELECT pl.PL_Desc,  
   Convert(nVarChar(25), td.StartTime, 120),  
   Convert(nVarChar(25), td.EndTime, 120),  
   pu.PU_Desc,  
   (select Event_Reason_Name FROM dbo.Event_Reasons where td.L1ReasonId = Event_Reason_Id),  
   (select Event_Reason_Name FROM dbo.Event_Reasons where td.L2ReasonId = Event_Reason_Id),  
   (select Event_Reason_Name FROM dbo.Event_Reasons where td.L3ReasonId = Event_Reason_Id),  
   (select Event_Reason_Name FROM dbo.Event_Reasons where td.L4ReasonId = Event_Reason_Id),   
   loc.PU_Desc,  
   p.Prod_Desc,  
   tef.TEFault_Name,  
   td.LineStatus,  
   SubString(erc1.ERC_Desc, CharIndex(':', erc1.ERC_Desc) + 1, 50),  
   0,  
   SubString(erc2.ERC_Desc, CharIndex(':', erc2.ERC_Desc) + 1, 50),  
   SubString(erc3.ERC_Desc, CharIndex(':', erc3.ERC_Desc) + 1, 50),  
   SubString(erc4.ERC_Desc, CharIndex(':', erc4.ERC_Desc) + 1, 50),  
   td.Shift,  
   td.crew,  
   tpu.DelayType,  
   CASE  WHEN td.TEDetId = td.PrimaryId THEN 'Primary'   
    when td.PrimaryID is null then 'Reporting'  
    ELSE 'Secondary' END,  
   Coalesce(td.Stops, 0),  
   Coalesce(td.StopsMinor, 0),  
   Coalesce(td.StopsEquipFails, 0),  
   Coalesce(td.StopsProcessFailures, 0),  
   1,--coalesce(td.causes,0),   
   coalesce(td.Downtime,0.0)/60.0,  
   coalesce(td.ReportDownTime,0.0)/60.0,  
   0.0,  
   coalesce(td.Uptime,0.0)/60.0,  
   coalesce(td.ReportUpTime,0.0)/60.0,  
   Coalesce(td.UpTime2m, 0),  
   (  
   CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1)   
    AND (td.ReportDowntime/60.0 >= 10.0)  
    and (td.ReportDowntime/60.0 <= 60.0)   
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1)   
    AND (td.ReportDowntime/60.0 > 60.0)  
    and (td.ReportDowntime/60.0 <= 360.0)   
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsEquipFails, 0) = 1)   
    AND (td.ReportDowntime/60.0 > 360.0)  
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1)   
    AND (td.ReportDowntime/60.0 >= 10.0)  
    and (td.ReportDowntime/60.0 <= 60.0)   
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1)   
    AND (td.ReportDowntime/60.0 > 60.0)  
    and (td.ReportDowntime/60.0 <= 360.0)   
    THEN 1  
    ELSE 0   
    END  
   ),  
   (  
   CASE  WHEN (Coalesce(td.StopsProcessFailures, 0) = 1)   
    AND (td.ReportDowntime/60.0 > 360.0)  
    THEN 1  
    ELSE 0   
    END  
   ),  
   Comment,  
   (  
   select case when count(*) > 0 then 1.0/convert(float,count(*)) else 0 end  
    from dbo.#Delays ttd where td.puid = ttd.puid  
   )  
   --1  
  
  FROM  dbo.#Delays td  
  JOIN  @ProdUnits tpu ON td.PUId = tpu.PUId  
  JOIN  dbo.Prod_Units pu ON td.PUId = pu.PU_Id  
  JOIN  dbo.Prod_Lines pl ON pu.PL_Id = pl.PL_Id  
  JOIN  dbo.Products p ON td.ProdId = p.Prod_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc1 ON td.ScheduleId = erc1.ERC_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc2 ON td.CategoryId = erc2.ERC_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc3 ON td.SubSystemId = erc3.ERC_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc4 ON td.GroupCauseId = erc4.ERC_Id  
  LEFT JOIN dbo.Prod_Units loc ON td.LocationId = loc.PU_Id  
  LEFT  JOIN  dbo.Timed_Event_Fault tef on (td.TEFaultID = TEF.TEFault_ID)  
  where td.inRptWindow = 1  
  ORDER  BY pl.Pl_Desc, td.Starttime, td.Endtime  
  
  
  update dbo.#Stops set  
   [Unscheduled Stops] = [Total Stops],  
   [Unscheduled Rpt DT] = [Reporting Downtime]  
  where lower(ltrim(rtrim(coalesce(schedule,'')))) in ('unscheduled','')  
    
  
  -- added Rev7.0  
  update dbo.#Stops set  
   [Comment] = replace(coalesce([Comment],''), char(13)+char(10), ' ')  
  
  update dbo.#Stops set  
   Category = replace([Reason Level 4],'Category:','')  
  where Category is null  
  and left([Reason Level 4], 8) like 'Category'  
  
  
  select @SQL =   
  case  
  when (select count(*) from dbo.#Stops) > 65000 then   
  'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (select count(*) from dbo.#Stops) = 0 then   
  'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#Stops', @LanguageId)  
  end  
  
  EXEC(@SQL)  
  
  end    
  
  
drop table dbo.#runs  
DROP TABLE dbo.#Primaries  
DROP TABLE dbo.#Delays  
drop table dbo.#EventsByShiftProduct  
drop table dbo.#UptimeByShiftProduct  
DROP TABLE dbo.#TECategories  
drop table dbo.#tests  
drop table dbo.#Stops  
DROP TABLE dbo.#TeamSummary  
DROP TABLE dbo.#ShiftSummary  
DROP TABLE dbo.#ProductSummary  
DROP TABLE dbo.#LocationSummary  
DROP TABLE dbo.#CategorySummary  
DROP TABLE dbo.#ScheduleSummary  
drop table dbo.#runslineshift  
  
  
