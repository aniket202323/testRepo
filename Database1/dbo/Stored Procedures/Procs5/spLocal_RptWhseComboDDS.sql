  /*  
Stored Procedure: spLocal_RptWhseComboDDS  
Author:   Kim Hobbs  
Date Created:  10/24/03  
  
Last Modified: 2009-03-17  Jeff Jaeger Rev3.31  
  
Description:  
=========  
*** This SP is best viewed with Tabs set to 3 under Tools/Options/Editor. ***  
  
This procedure provides Warehouse DDS data for a Production Lines and Time Period.  
  
Key Configuration Points:  
 - This report uses the extended_info column in the Prod_Units table to determine  
  the Department and the Impact Department.    
 - The Department is used for both Palletizers and Conveyors.  It is configured  
  by placing the prefix Dept= in the extended_info column followed by the desired value.  
  For Example: Dept=Finished Product;  
 - The Impact Department is used for the Conveyors and is configured by placing the prefix  
  ImpactDept= in the extended_info column for the conveyor Prod_Units.  
  For Example: ImpactDept=MULTIFLOW #1 SYSTEM.  This allows the report to 'group' the  
  Impact Departments together for summary results.  
 - The report returns Minor Stops reduction.  This is accomplished by  
  configuring each Palletizer as Characteristics under a Property named Whse Configuration Data.  
  Then a specification variable named Minor Stops Target should be configured for the same  
  Property and specs entered for each Characteristic (Palletizer).  The spec value is the target  
  Minor Stops per day for the specific Palletizer.  
  
INPUTS:  
 From Template:   
  Start Time  
  End Time  
  Report Name  
  
 From Report Definition:  
  PodLineConvList  
  ProdLinePalList  
  DelayTypeList  
  Scheduled Label  
  Category Label  
  GroupCause Label  
  SubSystem Label  
  CatMechEquipId  
  CatElectEquipId  
  CatProcFailId  
  CatBlockedStarvedId  
  SchedUnscheduledId  
  DelayTypeBlockedStarved  
  L1ReasonBlockedId  
  L1ReasonStarvedId  
  DelayTypeRateLoss  
  
CALLED BY:  RptWhseCombo.xlt (Excel/VBA Template)  
  
CALLS: spCmn_GetReportParameterValue  
  
Revision Change Date Who What  
======== =========== ==== =====  
1  11/17/03 KAH Modified Results to use active_specs instead of trans_properties table  
  
0  10/24/03 KAH Original Creation, this is 1st sp of 3 used in the template.  
     We have combined the WHSE DDS, Stops and QualityCLRounds sp's  
     to use a single template and produce a single report.  
  
2  12/20/04 Vince King, King Designs and Consulting  
     -  Modified sp to use Minor Stop variable to summarize month to date minor stops.  
     - Added new result set to return downtime detail event data.  This will replace the  
      the need for a separate stored procedure to return this data.  By using a separate  
      SP the report was collecting the same data twice.  This change should improve the   
      runtime of the report.  
  
2  01/11/05 Vince King, King Designs and Consulting  
     - Added WHERE td.StopsUnscheduled = 1 condition to the INSERT statement for @FM table.  
      This table is used to report Stops and Minor Stops for Top 4 Failure Modes.  The SP  
       was included ALL events, not just stops.  
  
2  01/12/05 Vince King  
     - Modified the Minor Stops Reduction calculation to   
       1 - (Sum(Minor Stops) / ((Minor Stops Target) * (Days Into Month))  
  
2  02/08/05 Vince King  
     - Installed at Albany, Mehoopany, Green Bay and Oxnard plants.  This is basically the  
                  original stored procedure since it was never completed and rolled out.  
  
3  03/07/05 Vince King  
     - Modified result sets to clean up Pal/ATLS/APTS/Conveyor results.  Rev3.0 also includes  
      changes to the xlt template to remove pivottables for Pal/ATLS/APTS/Conveyor summary data.  
  
3.1 03/21/05 Vince King  
     - Modified the Overall Percent Coded calculation to only include Palletizer and Conveyor   
      downtime events.  
  
3.2 11/22/05 Vince King  
     - Added dbo. to all table references for tuning.  
     - Added code to retrieve Event_Reason_Catagories directly using text description.  This  
      will allow them to be removed from the report parameter list.  
     - Added OPTION (KEEP PLAN) to all SELECT statements for tuning.  
     - Removed JOINs in the SELECT statements for result sets where the tables were not being  
      used.  
     -  Modified result sets SELECT statements to use TABLE variables where possible.  
     - Added SET NOCOUNT ON to beginning of sp and SET NOCOUNT OFF to end of sp.  
     - Added additional comments to beginning describing configuration requirements.  
3.21 17/03/06  Namho Kim  
     - Overall Availability changed to percent (%)  
     - Overall down time is changed hour to min.    
  
3.22 09/03/06  Namho Kim - Making a Code Flexible to Work with BOTH 3.x and 4.x  
  
3.23 06/26/06  Vince King  
     - Removed PRINT statements.  
     - Modifications to columns and data reported based on site review final draft of 04-11-06.  
  
3.24 07/10/06  Vince King  
     - Moved MTBF, MTTR and R(2) columns to before Total Uptime in Conveyor results sets.  
  
3.25 01/02/07  Vince King  
     - Some lines were not showing up in the palletizer section although the data was in the pivot  
      table.  Found where a JOIN to characteristics table was eliminating some lines that did  
      not have those chars setup.  Changed JOIN to LEFT JOIN and validated data to ensure  
      no change occured.  Missing lines were included and data for the lines previously in the report  
      was not effected.  
  
3.26 02/13/07  Vince King  
     - The numbers in the Palletizer Summary was not including some of the palletizers.  Found where some  
      of the palletizers were not being included in #SummaryData because they did not have minor stops target  
      specs.  I changed JOIN to LEFT JOIN when joining dbo.Characteristics, dbo.Active_Specs and   
      dbo.Specifications.  
  
3.27  02/14/07  Vince King  
     - Realized that MTD Minor Stops Reduction is not reported anymore.  It was removed per the SSOs.  So I  
      commented out all of the code associated with it.  
  
3.28 03/09/07  Vince King  
     - Modified code that captures comments for a 4.0 Plant Apps site.  
  
3.29 02/18/09  Jeff Jaeger   
  - note that this sp is not up to date with current methods.  this may have an impact on efficiency.   
  - modified the method for pulling ScheduleID and CategoryID in #delays.  
  - added .dbo and "with (nolock)" to the use of all tables and temp tables.  
  
--2009-03-12 Jeff Jaeger Rev3.30  
--  - added z_obs restriction to the population of @produnits  
  
2009-03-17 Jeff Jaeger Rev3.31  
- modified the definition of StopsUnscheduled, StopsMinor, StopsEquipFails, StopsProcessFailures in #Delays  
- modified the definition of SplitUnscheduledDT in #SplitDowntimes  
- there are other flavors of stops that will eventually need to be updated.  
  
*/  
  
CREATE  PROCEDURE dbo.spLocal_RptWhseComboDDS  
-- DECLARE  
 @StartTime       datetime,  -- Beginning period for the data.  
 @EndTime        datetime,  -- Ending period for the data.  
 @RptName        VARCHAR(100) -- Report_Definitions Report Name.  
  
AS  
  
SET NOCOUNT ON  
  
-------------------------------------------------------------------------------  
-- Assign Report Parameters for SP testing locally.  
-------------------------------------------------------------------------------  
-- AY  
-- SELECT  
--     @StartTime       = '2005-11-20 06:15:00',  
--    @EndTime        = '2005-11-21 06:15:00',  
--    @RptName        = ''  
  
-- OX  
-- SELECT  @StartTime       = '2009-03-07 00:00:00',  
--    @EndTime        = '2009-03-08 00:00:00',  
--    @RptName        = 'Apr 2008 Whse Combo'  
  
-- GB  
-- SELECT  
--     @StartTime       = '2007-02-11 06:30:00',  
--    @EndTime        = '2007-02-12 06:30:00',  
--    @RptName        = 'Whse Combo'  
  
-- MP  
-- SELECT  @StartTime       = '2007-02-22 06:00:00',  
--    @EndTime        = '2007-02-23 06:00:00',  
--    @RptName        = 'Whse Combo Bldg 3 0600 1800'  
  
SET ANSI_WARNINGS OFF  
  
-- print 'Before variable declaration: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Create temporary Error Messages and ResultSet tables.  
-------------------------------------------------------------------------------  
DECLARE @ErrorMessages TABLE (  
 ErrMsg    varchar(255) )  
  
DECLARE @Runs TABLE (  
 StartId    int,  
 PUId     int,  
 ProdId    int,  
 StartTime   datetime,  
 EndTime    datetime,  
 PRIMARY KEY (PUId, StartTime))  
  
CREATE TABLE #Delays (  
 TEDetId       Int Primary Key,  
 PrimaryId      int,  
 SecondaryId      int,  
 PUId        int,  
 StartTime      datetime,  
 EndTime       datetime,  
 LocationId      int,  
 L1ReasonId      int,  
 L2ReasonId      int,  
 L3ReasonId      int,  
 L4ReasonId      int,  
 TEFaultId      int,  
 ERTD_ID       int,  
 L1TreeNodeId     int,  
 L2TreeNodeId     int,  
 L3TreeNodeId     int,  
 L4TreeNodeId     int,  
 ProdId       int,  
 LineStatus      varchar(50),  
 Shift        varchar(10),  
 Crew        varchar(10),  
 ScheduleId      int,  
 CategoryId      int,  
 GroupCauseId     int,  
 SubSystemId      int,  
 DownTime       float,  
 ReportDownTime     float,  
 UpTime       float,  
 ReportUpTime     float,  
 Stops        int,  
 StopsUnscheduled    int,  
 StopsBlockedStarved   int,  
 ReportUnSchedDowntime  float,  
 StopsScheduled     int,  
 ReportSchedDowntime   float,  
 Stops2m       int,  
 StopsMinor      int,  
 ReportMSDowntime    float,  
 StopsBreakDowns    int,  
 ReportBDDowntime    float,  
 StopsProcessFailures   int,  
 ReportPFDowntime    float,  
 StopsBlocked     int,  
 ReportBlockedDowntime  float,  
 StopsStarved     int,  
 ReportStarvedDowntime  float,  
 StopsBSUpTime2m    int,  
 UpTime2m       int,  
 Comment       VarChar(5000),  
 Comment_Id      INTEGER )      -- 2007-03-08 VMK Rev3.28, added.  
  
CREATE INDEX td_PUId_StartTime  
 ON #Delays (PUId, StartTime)  
CREATE INDEX td_PUId_EndTime  
 ON #Delays (PUId, EndTime)  
  
DECLARE @ProdUnits TABLE (  
 PUId      int PRIMARY KEY,  
 PUDesc     VARCHAR(50),  
 PLId      int,  
 ExtendedInfo   varchar(255),  
 DelayType    varchar(100),  
 ScheduleUnit   int,  
 LineStatusUnit   int )  
  
DECLARE @ProdUnitsImpDept TABLE (  
 PLId      int,  
 Master_PUId    int,  
 Source_PUId    int,  
 Source_PUDesc   varchar(100),  
 ExtendedInfo   varchar(255),  
 ImpDept     varchar(100),  
 Dept      varchar(100),  
 EquipGroup     varchar(100))  
  
DECLARE @ProdUnitsEG TABLE (  
 PLId      Integer,  
 Master_PUId    Integer,  
 Source_PUId    Integer,  
 Source_PUDesc   VarChar(100),  
 ExtendedInfo   VarChar(255),  
 EquipGroup    VarChar(100),  
 Equip      VarChar(100))  
  
CREATE TABLE #Tests (  
 TestId   int PRIMARY KEY,  
 VarId    int,  
 PLId    int,  
 Value    float,  
 StartTime  datetime,  
 EndTime   datetime )  
CREATE INDEX tt_VarId_StartTime  
 ON #Tests (VarId, StartTime)  
CREATE INDEX tt_VarId_EndTime  
 ON #Tests (VarId, EndTime)  
  
-- print 'After Var Declaration: ' + Convert(VarChar(25),GetDate(),108)  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
DECLARE  @SearchString    varchar(4000),  
    @Position     int,  
    @PartialString    varchar(4000),  
    @Now       datetime,  
    @@Id       int,  
    @@ExtendedInfo    varchar(255),  
    @PUDelayTypeStr   varchar(100),  
    @PUScheduleUnitStr  varchar(100),  
    @PULineStatusUnitStr  varchar(100),  
    @@PUId      int,  
    @@TimeStamp     datetime,  
    @@LastEndTime    datetime,  
    @VarCasesToPalId   int,  
    @VarCasesToPalVN   varchar(100),  
    @VarPalletsExitSWId  int,  
    @VarPalletsExitSWVN  varchar(100),  
    @VarMinorStopId   Integer,      -- VMK 10/7/04  
    @VarMinorStopVN   VarChar(100),    -- VMK 10/7/04  
    @@NextStartTime   datetime,  
    @@VarId      int,  
    @PUImpDeptStr    varchar(100),  
    @PUDeptStr     varchar(100),  
    @@PLId      int,  
    @@VarCasesToPalId   int,  
    @@VarPalletsExitSWId  int,  
    @@ProdId      int,  
    @@StartTime     datetime,  
    @@EndTime     datetime,  
    @@Shift      varchar(50),  
    @@Team      varchar(50),  
    @ProdCode     varchar(100),  
    @CharId      int,  
    @Runtime      Float,  
    @TotalCasesToPal    int,  
    @GoodPalletsExitSW  int,  
    @PLDesc      varchar(100),  
    @MachineTypePal   varchar(50),  
    @MachineTypeConv   varchar(50),  
    @MachineTypeATLS   varchar(50),  
    @MachineTypeAPTS   varchar(50),  
    @MachineTypeConvMP   varchar(50),  
    @TotalReportTime   float,  
    @PUEquipGroupStr   VarChar(100),  
    @PUEquipStr     VarChar(100),  
    
    @TotalPALReportTime  float,  
    @TotalPalletizers   int,  
    @TotalCasesToPalletizer int,  
    @TotalPalletsExitSW  int,  
    @MTDTotalRows    int,  
    @MTDTotRows     int,  
    @Plant      varchar(50),  
    @prop_id      int,  
    @DaysInMonth    int,   -- Number of Days in the Month, Uses MTDEndTime day portion.  
    @DaysIntoMonth    int,   -- Number of Days into the Month, Uses EndTime day portion.  
    @Conversion     float,  
  --Rev2  
    @RangeStartTime   datetime,  
    @RangeEndTime    datetime,  
    @Max_TEDet_Id    int,  
    @Min_TEDet_Id    int,  
    @MTDStartTime    datetime,  
    @MTDEndTime     datetime,  
    @IncludeStopsPivot  Integer,  
  --Rev3.2  
    @UserName       VARCHAR(30),  -- User calling this report  
    @RptTitle       VARCHAR(300),  -- Report title from Web Report.  
    @RptPageOrientation    VARCHAR(50),  -- Report Page Orientation from Web Report.  
    @RptPageSize      VARCHAR(50),   -- Report page Size from Web Report.  
    @RptPercentZoom     INTEGER,    -- Percent Zoom from Web Report.  
    @RptTimeout       VARCHAR(100),  -- Report Time from Web Report.  
    @RptFileLocation     VARCHAR(300),  -- Report file location from WEb Report.  
    @RptConnectionString    VARCHAR(300),  -- Connection String from Web Report.  
    @ProdLinePalList     varchar(4000),  -- Collection of Prod_Lines.PL_Id for palletizer production lines delimited by "|".  
    @ProdLineConvList     varchar(4000),  -- Collection of Prod_Lines.PL_Id for conveyor production lines delimited by "|".  
    @DelayTypeList      varchar(4000),  -- Collection of "DelayType=..." from Prod_Units.Extended_Info delimited by "|".  
    @ScheduleStr      varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
    @CategoryStr      varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
    @GroupCauseStr      varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
    @SubSystemStr      varchar(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
    @CatMechEquipId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
    @CatElectEquipId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
    @CatProcFailId      INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
    @CatBlockStarvedId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved.  
    @SchedPRPolyId      INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
    @SchedChangeOverId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:ChangeOver.  
    @SchedUnscheduledId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
    @L1ReasonBlockedId    INTEGER,    -- Event_Reasons.Event_Reason_Id for Reason Level 1 Blocked.  
    @L1ReasonStarvedId    INTEGER,    -- Event_Reasons.Event_Reason_Id for Reason Level 1 Starved.  
    @DelayTypeBlockedStarvedStr varchar(100),  -- Delay type for Blocked/Starved events (BlockedStarved).  
    @DelayTypeRateLossStr   VarChar(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
  
--Rev3.22   
    @DBVersion     VARCHAR(10),   -- Flag used to control whether to execute Proficy version specific code.  
    @SchedBlockedStarvedId  INTEGER  
  
--------------------------------------------------------------------------------------  
-- 2005-Nov-23 VMK Rev3.2  
-- Assign Constants  
--------------------------------------------------------------------------------------  
SELECT @Now        = GetDate(),  
   @PUDelayTypeStr    = 'DelayType=',  
   @PUScheduleUnitStr   = 'ScheduleUnit=',  
   @PULineStatusUnitStr  = 'LineStatusUnit=',  
   @VarCasesToPalVN    = 'Cases Into Palletizer',  
   @VarPalletsExitSWVN   = 'Pallets Exiting SW',  
   @MachineTypePal   = 'Palletizer',  
   @MachineTypeConv    = 'Conveyor',  
   @MachineTypeConvMP  = 'CaseConv',  
   @MachineTypeATLS    = 'ATLS',  
   @MachineTypeAPTS   = 'APTS',  
   @VarMinorStopVN    = 'Minor Stop',  
   @PUImpDeptStr     = 'ImpactDept=',  
   @PUDeptStr      = 'Dept=',  
   @Conversion     = 60.0,    -- Converts all times from seconds to minutes  
   @PUEquipGroupStr    = 'EquipGroup=',  
   @PUEquipStr     = 'Equip=',  
   @CatBlockStarvedId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Blocked/Starved'),  
   @CatMechEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Mechanical Equipment'),  
   @CatElectEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Electrical Equipment'),  
   @CatProcFailId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Process/Operational'),  
   @SchedPRPolyId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:PR/Poly Change'),  
   @SchedUnscheduledId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Unscheduled'),  
   @SchedChangeoverId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Changeover'),  
   @SchedBlockedStarvedId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Blocked/Starved'),  
--Rev3.22  
   @DBVersion   = (SELECT App_Version FROM dbo.AppVersions with (nolock) WHERE App_Name = 'Database')  
  
---------------------------------------------------------------------------------------------------  
-- 2005-JUN-13 VMK Rev6.89  
-- Retrieve parameter values FROM report definition using spCmn_GetReportParameterValue  
---------------------------------------------------------------------------------------------------   
IF Len(@RptName) > 0   
BEGIN  
  -- print 'Get Report Parameters.'  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPLIdPalList',         '',  @ProdLinePalList     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPLIdConvList',        '',  @ProdLineConvList     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptDlyTypeList',         '',  @DelayTypeList      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'Owner',             '',  @UserName        OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptTitle',           '',  @RptTitle        OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageOrientation',       '',  @RptPageOrientation     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageSize',          '',  @RptPageSize       OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ReportTimeOut',          '',  @RptTimeout       OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ServerFileLocation',        '',  @RptFileLocation      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConnectionString',       '',  @RptConnectionString    OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intL1ReasonBlockedId',        '',  @L1ReasonBlockedId     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intL2ReasonBlockedId',        '',  @L1ReasonStarvedId     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptDelayTypeBlockedStarvedLabel',   '',  @DelayTypeBlockedStarvedStr  OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptDelayTypeRateLossLabel',     '',  @DelayTypeRateLossStr    OUTPUT  
END  
ELSE   -- 2005-MAR-16 VMK Rev8.81, If no Report Name provided, return error.  
BEGIN  
 INSERT INTO @ErrorMessages (ErrMsg)  
  VALUES ('No Report Name specified.')  
  GOTO ReturnResultSets  
  
END  -- IF  
  
--  PRINT 'RptTitle = ' + @RptTitle  
--  PRINT 'StartTime = ' + CONVERT(VARCHAR(50), @StartTime)  
--  PRINT 'EndTime = ' + CONVERT(VARCHAR(50), @EndTime)  
--  PRINT 'ProdLinePalList = ' + @ProdLinePalList  
--  PRINT 'ProdLineConvList = ' + @ProdLineConvList  
--  PRINT 'DelayTypeList = ' + @DelayTypeList  
--  PRINT 'CatBlockStarvedId = ' + CONVERT(VARCHAR(5), @CatBlockStarvedId)  
--  PRINT 'CatMechEquipId = ' + CONVERT(VARCHAR(5), @CatMechEquipId)  
--  PRINT 'CatElectEquipId = ' + CONVERT(VARCHAR(5), @CatElectEquipId)  
--  PRINT 'CatProcFailId = ' + CONVERT(VARCHAR(5), @CatProcFailId)  
--  PRINT 'SchedUnscheduledId = ' + CONVERT(VARCHAR(5), @SchedUnscheduledId)  
--  PRINT 'SchedPRPolyId = ' + CONVERT(VARCHAR(5), @SchedPRPolyId)  
--  PRINT 'SchedChangeoverId = ' + CONVERT(VARCHAR(5), @SchedChangeoverId)  
--  PRINT '@UserName = ' + @UserName  
--  PRINT 'PageOrientation = ' + @RptPageOrientation  
--  PRINT 'PageSize = ' + @RptPageSize  
--  PRINT 'RptTimeout = ' + CONVERT(VARCHAR(5), @RptTimeout)  
  
-- print 'Error Checking: ' + Convert(VarChar(25),GetDate(),108)  
------------------------------------------------------------------------------  
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
IF (SELECT Count(ERC_Id) FROM dbo.Event_Reason_Catagories with (nolock) WHERE ERC_Id = @CatMechEquipId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatMechEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM dbo.Event_Reason_Catagories with (nolock) WHERE ERC_Id = @CatElectEquipId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatElectEquipId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM dbo.Event_Reason_Catagories with (nolock) WHERE ERC_Id = @CatProcFailId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatProcFailId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM dbo.Event_Reason_Catagories with (nolock) WHERE ERC_Id = @CatBlockStarvedId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@CatBlockStarvedId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM dbo.Event_Reason_Catagories with (nolock) WHERE ERC_Id = @SchedPRPolyId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedPRPolyId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM dbo.Event_Reason_Catagories with (nolock) WHERE ERC_Id = @SchedChangeOverId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedChangeOverId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
IF (SELECT Count(ERC_Id) FROM dbo.Event_Reason_Catagories with (nolock) WHERE ERC_Id = @SchedUnscheduledId) = 0  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@SchedUnscheduledId is not a valid Reason Category.')  
 GOTO ReturnResultSets  
END  
  
-------------------------------------------------------------------------------  
-- Calulate the MTD Start DateTime and End DateTime.  
-------------------------------------------------------------------------------  
SELECT @MTDStartTime = CONVERT(DATETIME, CONVERT(VARCHAR(4), DATEPART(yyyy, @StartTime)) + '-' +   
         CONVERT(VARCHAR(2), DATEPART(mm, @StartTime)) + '-01 00:00:00')  
  
SELECT @MTDEndTime = CONVERT(DATETIME, CONVERT(VARCHAR(4), DATEPART(yyyy, @EndTime)) + '-' +   
         CONVERT(VARCHAR(2), DATEPART(mm, @EndTime)) + '-' + CONVERT(VARCHAR(2), DATEPART(dd, @EndTime)) + ' 00:00:00')  
  
-- print 'Parse lists: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Parse the passed lists into temporary tables.  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
-- ProdLineList for Palletizers  
-------------------------------------------------------------------------------  
DECLARE @ProdLines TABLE (  
 PLId       int PRIMARY KEY,  
 PLDesc      VARCHAR(50),      -- 2005-Nov-22 VMK Rev3.2  
 MachineType     varchar(50),  
 VarCasesToPalId   int,  
 VarPalletsExitSWId  int,  
 VarMinorStopId    Integer,   -- VMK 10/7/04  
 TotalStops     int,  
 TotalUptime     int,  
 TotalDowntime    int )  
  
SELECT @SearchString = LTrim(RTrim(@ProdLinePalList))  
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
    VALUES ('Parameter @ProdLinePalList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
  END  
  IF (SELECT Count(PLId) FROM @ProdLines WHERE PLId = Convert(int, @PartialString)) = 0  
   BEGIN  
    SELECT @VarCasesToPalId = Null  
    SELECT @VarCasesToPalId = v.Var_Id  
     FROM  dbo.Variables v with (nolock)  
      JOIN dbo.Prod_Units pu with (nolock) ON v.PU_Id  = pu.PU_Id  
      JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
     WHERE (v.Var_Desc = @VarCasesToPalVN)  
      AND (v.Data_Type_Id IN (1,2))  
      AND (pl.PL_Id = Convert(int,@PartialString))  
    OPTION (KEEP PLAN)  
      
    SELECT @VarPalletsExitSWId = Null  
    SELECT @VarPalletsExitSWId = v.Var_Id  
     FROM  dbo.Variables v with (nolock)  
      JOIN dbo.Prod_Units pu with (nolock) ON v.PU_Id  = pu.PU_Id  
      JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
     WHERE (v.Var_Desc = @VarPalletsExitSWVN)  
      AND (v.Data_Type_Id IN (1,2))  
      AND (pl.PL_Id = Convert(int,@PartialString))  
    OPTION (KEEP PLAN)  
  
    -- VMK 10/7/04 Get the Minor Stop variable Id for each Prod_Line  
    SELECT @VarMinorStopId = Null  
    SELECT @VarMinorStopId = v.Var_Id  
     FROM  dbo.Variables v with (nolock)  
      JOIN dbo.Prod_Units pu with (nolock) ON v.PU_Id  = pu.PU_Id  
      JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
     WHERE (v.Var_Desc = @VarMinorStopVN)  
      AND (v.Data_Type_Id IN (1,2))  
      AND (pl.PL_Id = Convert(int,@PartialString))  
    OPTION (KEEP PLAN)  
  
    SELECT @PLDesc = PL_Desc FROM dbo.Prod_Lines with (nolock) WHERE PL_Id = Convert(int, @PartialString)  
    OPTION (KEEP PLAN)  
  
    INSERT @ProdLines (PLId, PLDesc, MachineType, VarCasesToPalId, VarPalletsExitSWId, VarMinorStopId)   
    VALUES (Convert(int, @PartialString), @PLDesc, @MachineTypePal, @VarCasesToPalId,   
       @VarPalletsExitSWId, @VarMinorStopId)  
   END  
 END  
END  
  
-------------------------------------------------------------------------------  
-- ProdLineList for Conveyors  
-------------------------------------------------------------------------------  
SELECT @SearchString = LTrim(RTrim(@ProdLineConvList))  
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
    VALUES ('Parameter @ProdLineConvList contains non-numeric = ' + @PartialString)  
   GOTO ReturnResultSets  
  END  
  IF (SELECT Count(PLId) FROM @ProdLines WHERE PLId = Convert(int, @PartialString)) = 0  
   BEGIN  
    SELECT @PLDesc = PL_Desc FROM dbo.Prod_Lines with (nolock) WHERE PL_Id = Convert(int, @PartialString)  
    INSERT @ProdLines (PLId, PLDesc, MachineType)   
    VALUES (Convert(int, @PartialString), @PLDesc, @MachineTypeConv)  
   END  
 END  
END  
IF (SELECT Count(PLId) FROM @ProdLines) = 0  
 INSERT @ProdLines (PLId)  
  SELECT PL_Id  
   FROM dbo.Prod_Lines with (nolock)  
  OPTION (KEEP PLAN)  
  
-------------------------------------------------------------------------------  
-- DelayTypeList  
-------------------------------------------------------------------------------  
DECLARE @DelayTypes TABLE (  
 DelayTypeDesc   varchar(100) PRIMARY KEY)  
  
SELECT @SearchString = LTrim(RTrim(@DelayTypeList))  
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
  AND (SELECT Count(DelayTypeDesc) FROM @DelayTypes WHERE DelayTypeDesc = @PartialString) = 0  
  INSERT @DelayTypes (DelayTypeDesc)   
   VALUES (@PartialString)  
END  
  
  
-- select '@ProdLines' [@ProdLines], * from @ProdLines  
-------------------------------------------------------------------------------  
-- ProdUnitList  
-------------------------------------------------------------------------------  
INSERT @ProdUnits (   
   PUId,  
   PUDesc,  
   PLId,     
   ExtendedInfo,  
   DelayType,  
   ScheduleUnit,  
   LineStatusUnit     
   )  
SELECT pu.PU_Id,  
   pu.PU_Desc,  
   pu.PL_Id,  
   pu.Extended_Info,  
   GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr),  
   GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUScheduleUnitStr),  
   GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PULineStatusUnitStr)  
FROM dbo.Prod_Units pu with (nolock)  
 INNER JOIN @ProdLines tpl ON pu.PL_Id = tpl.PLId  
 INNER JOIN dbo.Event_Configuration  ec with (nolock)  ON pu.PU_Id = ec.PU_Id  
 -- 2005-Nov-22 VMK Rev3.2  
 INNER JOIN @DelayTypes dt ON dt.DelayTypeDesc = GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr) -- This removes unwanted delay types  
WHERE pu.Master_Unit IS NULL  
 AND ec.ET_Id = 2  
and pu_desc not like '%z_obs%'  
OPTION (KEEP PLAN)  
  
INSERT @Runs ( StartId,  
  PUId,  
  ProdId,  
  StartTime,  
  EndTime)  
SELECT Start_Id,  
   PU_Id,  
   Prod_Id,  
   Start_Time,  
   COALESCE(End_Time, @Now)  
FROM dbo.Production_Starts ps with (nolock)  
 INNER JOIN @ProdUnits  pu ON ps.PU_Id = pu.PUId  
WHERE ps.Start_Time < @EndTime  
 AND ( ps.End_Time > @StartTime  
  OR ps.End_Time IS NULL)  
OPTION (KEEP PLAN)  
  
-- select '@ProdUnits' [@ProdUnits], * from @ProdUnits  
  
-- print 'Filter Prod Unit list by Delay Type: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Filter the Production Unit list to only include the passed Delay Type list.  
-------------------------------------------------------------------------------  
-- 2005-Nov-22 VMK Rev3.2 Added INNER JOIN in @ProdUnits section above, it replaces this.  
-- IF (SELECT count(DelayTypeDesc) FROM @DelayTypes) > 0  
--  BEGIN  
--  DELETE  
--  FROM @ProdUnits  
--  WHERE DelayType NOT IN (SELECT DelayTypeDesc  
--     FROM @DelayTypes)  
--  END  
  
-- print 'Impacted Departments: ' + Convert(VarChar(25),GetDate(),108)  
------------------------------------------------------------------------------  
-- Create Temporary table to determine Impacted Department and Department.  
-------------------------------------------------------------------------------  
-- Insert Master Production Units into @ProdUnitsImpDept  
INSERT INTO @ProdUnitsImpDept (   
    PLId,  
    Master_PUId,  
    Source_PUId,  
    Source_PUDesc,  
    ExtendedInfo,  
    ImpDept,  
    Dept)  
SELECT ppu.PLId,  
   Master_Unit,  
   PU_Id,  
   PU_Desc,  
   Extended_Info,  
   GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUImpDeptStr),  
   GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDeptStr)  
FROM @ProdUnits ppu  
 JOIN dbo.Prod_Units pu with (nolock) ON ppu.PUId = pu.PU_Id  
    OR ppu.PUId = pu.Master_Unit  
OPTION (KEEP PLAN)  
  
-- print 'Parse DelayTypes: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Collect all the Production Run records for the reporting period for each  
-- production line by Shift/Team.  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
-- Create Temporary table to determine Equipment Groups.  
-------------------------------------------------------------------------------  
  
-- Insert Master Production Units into #ProdUnitsEG  
INSERT INTO @ProdUnitsEG (PLId, Master_PUId, Source_PUId, Source_PUDesc, ExtendedInfo)  
 SELECT ppu.PLId, Master_Unit, PU_Id, PU_Desc, Extended_Info  
  FROM @ProdUnits ppu  
   JOIN dbo.Prod_Units pu with (nolock) ON ppu.PUId = pu.PU_Id  
 OPTION (KEEP PLAN)  
  
-- Insert Slave Production Units into #ProdUnitsEG  
INSERT INTO @ProdUnitsEG (PLId, Master_PUId, Source_PUId, Source_PUDesc, ExtendedInfo)  
 SELECT ppu.PLId, Master_Unit, PU_Id, PU_Desc, Extended_Info  
  FROM @ProdUnits ppu  
   JOIN dbo.Prod_Units pu with (nolock) ON ppu.PUId = pu.Master_Unit  
 OPTION (KEEP PLAN)  
  
-- Update the Equipment Group for each prod unit.  
DECLARE ProdUnitEGCursor INSENSITIVE CURSOR FOR  
 (SELECT Source_PUId, ExtendedInfo  
  FROM @ProdUnitsEG)  
 FOR READ ONLY  
OPEN ProdUnitEGCursor  
FETCH NEXT FROM ProdUnitEGCursor INTO @@Id, @@ExtendedInfo  
WHILE @@Fetch_Status = 0  
BEGIN  
  
 SELECT @Position = CharIndex(@PUEquipGroupStr, @@ExtendedInfo)  
 IF @Position > 0  
 BEGIN  
  SELECT @PartialString = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PUEquipGroupStr), Len(@@ExtendedInfo)))  
  SELECT @Position = CharIndex(';', @PartialString)  
  IF @Position > 0  
   SELECT @PartialString = RTrim(SubString(@PartialString, 1, @Position - 1))  
  UPDATE @ProdUnitsEG  
   SET EquipGroup = @PartialString  
   WHERE Source_PUId = @@Id  
 END  
  
 FETCH NEXT FROM ProdUnitEGCursor INTO @@Id, @@ExtendedInfo  
END  
CLOSE ProdUnitEGCursor  
DEALLOCATE ProdUnitEGCursor  
  
  
-- Update the Equipment for each prod unit.  
DECLARE ProdUnitEQUIPCursor INSENSITIVE CURSOR FOR  
 (SELECT Source_PUId, ExtendedInfo  
  FROM @ProdUnitsEG)  
 FOR READ ONLY  
OPEN ProdUnitEQUIPCursor  
FETCH NEXT FROM ProdUnitEQUIPCursor INTO @@Id, @@ExtendedInfo  
WHILE @@Fetch_Status = 0  
BEGIN  
  
 SELECT @Position = CharIndex(@PUEquipStr, @@ExtendedInfo)  
 IF @Position > 0  
 BEGIN  
  SELECT @PartialString = LTrim(SubString(@@ExtendedInfo, @Position + Len(@PUEquipStr), Len(@@ExtendedInfo)))  
  SELECT @Position = CharIndex(';', @PartialString)  
  IF @Position > 0  
   SELECT @PartialString = RTrim(SubString(@PartialString, 1, @Position - 1))  
  UPDATE @ProdUnitsEG  
   SET Equip = @PartialString  
   WHERE Source_PUId = @@Id  
 END  
  
 FETCH NEXT FROM ProdUnitEQUIPCursor INTO @@Id, @@ExtendedInfo  
END  
CLOSE ProdUnitEQUIPCursor  
DEALLOCATE ProdUnitEQUIPCursor  
  
-- print 'Get DT Data: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Collect dataset filtered by report period and Production Units.  
-------------------------------------------------------------------------------  
--Change @EndTime and @StartTime to MTD times -- VMK 09/20/04  
  
INSERT #Delays ( TEDetId,   
   PUId,   
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
   Comment_Id)         -- 2007-03-08 VMK Rev3.28, added.  
SELECT ted.TEDet_Id,   
  ted.PU_Id,   
  ted.Start_Time,   
  Coalesce(ted.End_Time, @Now),   
  ted.Source_PU_Id,  
  ted.Reason_Level1,   
  ted.Reason_Level2,   
  ted.Reason_Level3,   
  ted.Reason_Level4,   
  ted.TEFault_Id,  
  ted.event_reason_tree_data_id,  
  convert(float, dateDiff(s, ted.Start_Time, Coalesce(ted.End_Time, @Now)))/@Conversion,  
  convert(float, dateDiff(s, CASE WHEN ted.Start_Time < @StartTime THEN @StartTime   
      ELSE ted.Start_Time   
      END,  
     CASE  WHEN Coalesce(ted.End_Time, @Now) > @EndTime THEN @EndTime   
      ELSE Coalesce(ted.End_Time, @Now)   
      END))/@Conversion,  
  ted2.TEDet_Id,   
  ted3.TEDet_Id,  
  ted.Cause_Comment_Id          -- 2007-03-08 VMK Rev3.28, added.  
FROM dbo.Timed_Event_Details ted with (nolock)  
 INNER JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
 LEFT JOIN dbo.Timed_Event_Details ted2 with (nolock) ON  ted.PU_Id = ted2.PU_Id  
      AND ted.Start_Time = ted2.End_Time  
      AND ted.TEDet_Id <> ted2.TEDet_Id  
 LEFT JOIN dbo.Timed_Event_Details ted3 with (nolock) ON  ted.PU_Id = ted3.PU_Id  
      AND ted.End_Time = ted3.Start_Time  
      AND ted.TEDet_Id <> ted3.TEDet_Id  
 WHERE ted.Start_Time < @EndTime  
 AND (ted.End_Time >= @StartTime OR ted.End_Time IS NULL)  
OPTION (KEEP PLAN)  
  
-- WHERE ted.Start_Time < @EndTime    
--  AND ( ted.End_Time >= @StartTime   
--   OR ted.End_Time IS NULL)  
--   
  
-- print 'Add records that span start/end: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Add the detail records that span either end of this collection but may not be  
-- in the data set.  These are records related to multi-downtime events where only  
-- one of the set is within the Report Period.  
-------------------------------------------------------------------------------  
-- Multi-event downtime records that span prior to the Report Period.  
WHILE (SELECT Count(td1.TEDetId)  
  FROM dbo.#Delays td1 with (nolock)  
  LEFT JOIN dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
  WHERE  td2.TEDetId IS NULL  
  AND  td1.PrimaryId IS NOT NULL) > 0  
 INSERT dbo.#Delays ( TEDetId,   
    PUId,   
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
    Comment_Id)          -- 2007-03-08 VMK Rev3.28, added  
 SELECT ted.TEDet_Id,   
   ted.PU_Id,   
   ted.Start_Time,   
   Coalesce(ted.End_Time, @Now),   
   ted.Source_PU_Id,  
   ted.Reason_Level1,   
   ted.Reason_Level2,   
   ted.Reason_Level3,   
   ted.Reason_Level4,   
   ted.TEFault_Id,  
   ted.event_reason_tree_data_id,  
   convert(float, DateDiff(s, ted.Start_Time, Coalesce(ted.End_Time, @Now)))/@Conversion,  
   0,  
   ted2.TEDet_Id,  
   ted.Cause_Comment_Id            -- 2007-03-08 VMK Rev3.28, added.  
   FROM  dbo.Timed_Event_Details ted with (nolock)  
   JOIN  @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
   LEFT JOIN dbo.Timed_Event_Details ted2 with (nolock) ON ted.PU_Id = ted2.PU_Id  
     AND ted.Start_Time = ted2.End_Time  
     AND ted.TEDet_Id <> ted2.TEDet_Id  
   WHERE  ted.TEDet_Id IN (SELECT td1.PrimaryId  
        FROM dbo.#Delays td1 with (nolock)  
        LEFT JOIN dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
        WHERE  td2.TEDetId IS NULL  
        AND  td1.PrimaryId IS NOT NULL)  
   OPTION (KEEP PLAN)  
  
  
-- Multi-event downtime records that span after the Report Period.  
WHILE (SELECT Count(td1.TEDetId)  
  FROM dbo.#Delays td1 with (nolock)  
  LEFT JOIN dbo.#Delays td2 with (nolock) ON td1.SecondaryId = td2.TEDetId  
  WHERE  td2.TEDetId IS NULL  
  AND  td1.SecondaryId IS NOT NULL) > 0  
 INSERT dbo.#Delays ( TEDetId,   
    PUId,   
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
    Comment_Id)          -- 2007-03-08 VMK Rev3.28, added.  
 SELECT ted.TEDet_Id,   
   ted.PU_Id,   
   ted.Start_Time,   
   Coalesce(ted.End_Time, @Now),   
   ted.Source_PU_Id,  
   ted.Reason_Level1,   
   ted.Reason_Level2,   
   ted.Reason_Level3,   
   ted.Reason_Level4,   
   ted.TEFault_Id,  
   ted.event_reason_tree_data_id,  
   convert(float, DateDiff(s, ted.Start_Time, Coalesce(ted.End_Time, @Now)))/@Conversion,   
   0,  
   ted3.TEDet_Id,  
   ted.Cause_Comment_Id            -- 2007-03-08 VMK Rev3.28, added.  
   FROM  dbo.Timed_Event_Details ted with (nolock)  
   JOIN  @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
   LEFT JOIN dbo.Timed_Event_Details ted3 with (nolock) ON ted.PU_Id = ted3.PU_Id  
     AND ted.End_Time = ted3.Start_Time  
     AND ted.TEDet_Id <> ted3.TEDet_Id  
   WHERE  ted.TEDet_Id IN (SELECT td1.SecondaryId  
        FROM #Delays td1  
        LEFT JOIN #Delays td2 ON td1.SecondaryId = td2.TEDetId  
        WHERE  td2.TEDetId IS NULL  
        AND  td1.SecondaryId IS NOT NULL)  
   OPTION (KEEP PLAN)  
  
-- Rev2 - Get the maximum range for later queries  
SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
 @Min_TEDet_Id = MIN(TEDetId) - 1,  
 @RangeStartTime = MIN(StartTime),  
 @RangeEndTime = MAX(EndTime)  
FROM #Delays  
OPTION (KEEP PLAN)  
  
-- print 'Set Primary Ids: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Cycle through the dataset and ensure that all the PrimaryIds point to the  
-- actual Primary event.  
-------------------------------------------------------------------------------  
WHILE (SELECT Count(td1.TEDetId)  
  FROM dbo.#Delays td1 with (nolock)  
  JOIN dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL) > 0  
 UPDATE td1  
  SET PrimaryId = td2.PrimaryId  
  FROM dbo.#Delays td1 with (nolock)  
  JOIN dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL  
UPDATE dbo.#Delays  
 SET PrimaryId = TEDetId  
 WHERE PrimaryId IS NULL  
  
-------------------------------------------------------------------------------  
-- If the dataset has more than 65000 records, then send an error message and  
-- suspend processing.  This is because Excel can not handle more than 65536 rows  
-- in a spreadsheet.  
--  
-- 2005-01-18 VMK Modified to set a variable.  If > 65000 rows, then just return  
--      the DDS Summary data and do not create stops pivot.  
-------------------------------------------------------------------------------  
SELECT @IncludeStopsPivot = 0  
  
IF (SELECT Count(TEDetId)  
  FROM dbo.#Delays with (nolock)) > 65000  
BEGIN  
-- 2005-01-18 Vince King  
--  INSERT #ErrorMessages (ErrMsg)  
--   VALUES ('The dataset contains more than 65000 rows.  This exceeds the Excel limit.')  
--  GOTO DropTables  
 SELECT @IncludeStopsPivot = 1  
END  
  
-- print 'Add Comments to #Delays: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Get the comment for each Timed_Event_Detail and Timed_Event_Summary record.  
-- WTC_Type = 2 (Comment for Detail record)  
-- WTC_Type = 1 (Comment for Summary record)  
-------------------------------------------------------------------------------  
IF @DBVersion < '400000' -- Use the following code specific to pre-Proficy version 4.x... --NHK Rev3.22  
 BEGIN  
 -- Get comments that are attached to the detail events.  
  UPDATE #Delays  
   SET Comment = RTrim(LTrim(Convert(varchar(5000),WTC.Comment_Text)))  
   FROM dbo.Waste_n_Timed_Comments WTC with (nolock)   
   WHERE (TEDetId = WTC.WTC_Source_Id) AND (WTC_Type = 2)  
    
  -- Get comments that are attached to the summary events.  
  Update dbo.#Delays    
   set Comment = RTrim(LTrim(Convert(varchar(5000),wtc.Comment_Text)))  
   from dbo.Waste_n_Timed_Comments wtc with (nolock)  
    left outer join dbo.timed_event_summarys tes with (nolock) on TESum_Id = WTC_Source_Id  
   where #Delays.StartTime = tes.Start_Time and #Delays.PUId = tes.PU_Id  
    and #Delays.Comment is null and WTC_Type = 1  
 End  
Else   -- Use the following code specific to Proficy version 4.x... --NHK Rev3.22  
 BEGIN  
    
  -- Get comments that are attached to the summary events.  
  Update ted                  -- 2007-03-08 VMK Rev3.28, changed #Delays to ted  
   -- 2007-03-08 VMK Rev3.28, changed RTrim(LTrim to code from CvtgStops below.  
   set Comment = REPLACE(coalesce(convert(varchar(5000),c.comment_text),''), char(13)+char(10), ' ')   --RTrim(LTrim(Convert(varchar(5000),C.Comment_Text)))  
   from dbo.#Delays ted with (nolock)                            -- 2007-03-08 VMK Rev3.28, added  
   left join dbo.comments C with (nolock) on ted.Comment_Id = c.Comment_Id                -- 2007-03-08 VMK Rev3.28, changed to left join  
--    where ted.Start_Time < @EndTime AND ted.End_Time >= @StartTime  and #Delays.PUId = ted.PU_Id    -- 2007-03-08 VMK Rev3.28, commented out.  
 End  
  
-- print 'Add Products to #Delays: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Add the Products to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
SET ProdId = ps.Prod_Id  
FROM dbo.#Delays td with (nolock)  
 JOIN dbo.Production_Starts ps with (nolock) ON td.PUId = ps.PU_Id  
     AND td.StartTime >= ps.Start_Time  
     AND ( td.StartTime < ps.End_Time  
      OR ps.End_Time IS NULL)  
--WHERE ps.Start_Time < @RangeEndTime  
-- AND (ps.End_Time > @RangeStartTime OR ps.End_Time IS NULL)  -- Rev2?  
  
-- print 'Add Shift/Crew to #Delays: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Add the Shift and Crew to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
SET  Shift = cs.Shift_Desc,  
 Crew = cs.Crew_Desc  
FROM dbo.#Delays td with (nolock)  
 INNER JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
 INNER JOIN dbo.Crew_Schedule cs with (nolock) ON tpu.ScheduleUnit = cs.PU_Id  
     AND td.StartTime >= cs.Start_Time  
     AND td.StartTime < cs.End_Time  
--WHERE cs.Start_Time < @RangeEndTime  
-- AND (cs.End_Time > @RangeStartTime OR cs.End_Time IS NULL)  -- Rev2?  
  
-- print 'Line Status: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Add the Line Status to the dataset.  
-------------------------------------------------------------------------------  
DECLARE @LineStatusRaw TABLE ( PUId  int,  
    StartTime datetime,  
    PhraseId int)  
DECLARE @LineStatus TABLE ( LSId  int,  
    PUId  int,  
    StartTime datetime,  
    EndTime  datetime,  
    PhraseId int,  
    PRIMARY KEY (PUId, StartTime))  
  
INSERT INTO @LineStatusRaw ( PUId,  
    PhraseId,  
    StartTime)  
SELECT pu.PUId,  
 ls.Line_Status_Id,  
 ls.Start_DateTime  
FROM dbo.Local_PG_Line_Status ls with (nolock)  
 INNER JOIN @ProdUnits pu ON ls.Unit_Id = pu.LineStatusUnit AND pu.PUId > 0  
WHERE ls.Start_DateTime >= @RangeStartTime  
 AND ls.Start_DateTime < @RangeEndTime  
OPTION (KEEP PLAN)  
  
INSERT INTO @LineStatusRaw ( PUId,  
    PhraseId,  
    StartTime)  
SELECT pu.PUId,  
 ls.Line_Status_Id,  
 max(ls.Start_DateTime)  
FROM dbo.Local_PG_Line_Status ls with (nolock)  
 INNER JOIN @ProdUnits pu ON ls.Unit_Id = pu.LineStatusUnit AND pu.PUId > 0  
WHERE ls.Start_DateTime < @RangeStartTime  
GROUP BY  pu.PUId,  
  ls.Line_Status_Id  
OPTION (KEEP PLAN)  
  
INSERT INTO @LineStatus ( PUId,  
    PhraseId,  
    StartTime)  
SELECT PUId,  
 PhraseId,  
 StartTime  
FROM @LineStatusRaw  
ORDER BY PUId, StartTime  
OPTION (KEEP PLAN)  
  
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
 INNER JOIN @LineStatus ls ON  td.PUId = ls.PUId  
     AND td.StartTime >= ls.StartTime  
     AND (td.StartTime < ls.EndTime OR ls.EndTime IS NULL)  
 INNER JOIN dbo.Phrase p with (nolock) ON ls.PhraseId = p.Phrase_Id  
  
  
-- print 'Get Reasons: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Retrieve the Tree Node Ids so we can get the associated categories.  
-------------------------------------------------------------------------------  
-- Level 1.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L1TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM dbo.#Delays td with (nolock)  
 JOIN dbo.Prod_Events pe with (nolock) ON td.LocationId = pe.PU_Id  
  AND pe.Event_Type = 2  
 JOIN dbo.Event_Reason_Tree_Data ertd with (nolock) ON pe.Name_Id = ertd.Tree_Name_Id  
  AND ertd.Event_Reason_Level = 1  
  AND ertd.Event_Reason_Id = td.L1ReasonId  
-------------------------------------------------------------------------------  
-- Level 2.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L2TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM dbo.#Delays td with (nolock)  
 JOIN dbo.Event_Reason_Tree_Data ertd with (nolock) ON td.L1TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 2  
  AND ertd.Event_Reason_Id = td.L2ReasonId  
-------------------------------------------------------------------------------  
-- Level 3.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L3TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM dbo.#Delays td with (nolock)  
 JOIN dbo.Event_Reason_Tree_Data ertd with (nolock) ON td.L2TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 3  
  AND ertd.Event_Reason_Id = td.L3ReasonId  
-------------------------------------------------------------------------------  
-- Level 4.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET L4TreeNodeId = ertd.Event_Reason_Tree_Data_Id  
 FROM dbo.#Delays td with (nolock)  
 JOIN dbo.Event_Reason_Tree_Data ertd with (nolock) ON td.L3TreeNodeId = ertd.Parent_Event_R_Tree_Data_Id  
  AND ertd.Event_Reason_Level = 4  
  AND ertd.Event_Reason_Id = td.L4ReasonId  
  
-- print 'Get reason categories: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- lowest point on the tree.  
-------------------------------------------------------------------------------  
  
/*  
UPDATE td  
SET ScheduleId = tec.ERC_Id  
FROM #Delays td  
 INNER JOIN dbo.Local_Timed_Event_Categories tec ON td.TEDetId = tec.TEDet_Id  
 INNER JOIN dbo.Event_Reason_Catagories erc ON tec.ERC_Id = erc.ERC_Id  
       AND erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
UPDATE td  
SET CategoryId = tec.ERC_Id  
FROM #Delays td  
 INNER JOIN dbo.Local_Timed_Event_Categories tec ON td.TEDetId = tec.TEDet_Id  
 INNER JOIN dbo.Event_Reason_Catagories erc ON tec.ERC_Id = erc.ERC_Id  
       AND erc.ERC_Desc LIKE @CategoryStr + '%'  
*/  
  
  
UPDATE td SET  
 ScheduleId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
/*  
UPDATE td SET   
 ScheduleId = @SchedBlockedStarvedId  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Event_Reasons er with (nolock)  
on Event_Reason_ID = L1ReasonId   
WHERE ScheduleId IS NULL   
AND (Event_Reason_Name LIKE '%BLOCK%' OR Event_Reason_Name LIKE '%STARVE%')  
*/  
  
UPDATE td SET  
 CategoryId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CategoryStr + '%'  
  
  
--goto finished  
  
-- print 'create primaries table: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Populate a separate temporary table that only contains the Primary records.  
-- This allows us to perform aggregates of the DownTime and also to retrieve the  
-- EndTime of the previous downtime event which is used to calculate UpTime.  
-------------------------------------------------------------------------------  
CREATE TABLE #Primaries (  
 TEDetId    int PRIMARY KEY,  
 PUId     int,  
 StartTime   datetime,  
 EndTime    datetime,  
 LastEndTime   datetime,  
 UpTime    float,  
 ReportUpTime   float)  
  
INSERT dbo.#Primaries ( TEDetId,   
   PUId,   
   StartTime,   
   EndTime)  
SELECT td1.TEDetId,   
   td1.PUId,   
   Min(td2.StartTime),   
   Max(td2.EndTime)  
FROM dbo.#Delays td1 with (nolock)  
 JOIN dbo.#Delays td2 with (nolock) ON td1.TEDetId = td2.PrimaryId  
WHERE td1.TEDetId = td1.PrimaryId  
GROUP BY td1.TEDetId, td1.PUId--, td1.ScheduleId, td1.CategoryId  
OPTION (KEEP PLAN)  
  
DECLARE PrimariesCursor INSENSITIVE CURSOR FOR  
 (SELECT TEDetId, PUId, StartTime  
  FROM dbo.#Primaries with (nolock))  
 FOR READ ONLY  
  
OPEN PrimariesCursor  
FETCH NEXT FROM PrimariesCursor INTO @@Id, @@PUId, @@TimeStamp  
WHILE @@Fetch_Status = 0  
BEGIN  
 SELECT @@PLId = PL_Id FROM dbo.Prod_Units WHERE PU_Id = @@PUId  
 SELECT @@LastEndTime = NULL  
 IF (SELECT MachineType FROM @ProdLines WHERE PLId = @@PLId) = @MachineTypePal  
  BEGIN  
   SELECT @@LastEndTime = Max(EndTime)  
    FROM dbo.#Primaries ted with (nolock)  
     LEFT JOIN dbo.Prod_Units pu with (nolock) ON @@PUId = pu.PU_Id  
    WHERE PUId In (SELECT PUId FROM @ProdUnits WHERE PLId = @@PLId)  
    --WHERE pu.PL_Id = @@PLId  
    AND EndTime <= @@TimeStamp  
    AND EndTime > DateAdd(Month, -1, @@TimeStamp)  
    OPTION (KEEP PLAN)  
  END  
 ELSE  
  BEGIN   
   SELECT @@LastEndTime = Max(EndTime)  
    FROM dbo.#Primaries ted with (nolock)  
    WHERE PUId = @@PUId  
    AND EndTime <= @@TimeStamp  
    AND EndTime > DateAdd(Month, -1, @@TimeStamp)  
    OPTION (KEEP PLAN)  
  END  
  
-- MKW 10/16/02  
 SELECT @@LastEndTime = CASE WHEN @@LastEndTime IS NULL THEN @StartTime   
      ELSE @@LastEndTime   
      END  
  
 UPDATE dbo.#Primaries  
 SET LastEndTime  = @@LastEndTime,  
   UpTime    = convert(float, datediff(s, @@LastEndTime, @@TimeStamp))/@Conversion,  
   ReportUpTime  = convert(float, datediff(s, CASE WHEN @@LastEndTime < @StartTime THEN @StartTime   
          ELSE @@LastEndTime   
          END,  
         CASE  WHEN @@TimeStamp < @StartTime THEN @StartTime   
          ELSE @@TimeStamp   
          END))/@Conversion  
 WHERE TEDetId = @@Id  
 FETCH NEXT FROM PrimariesCursor INTO @@Id, @@PUId, @@TimeStamp  
END  
CLOSE PrimariesCursor  
DEALLOCATE PrimariesCursor  
  
UPDATE td  
 SET UpTime  = tp.UpTime,  
  ReportUpTime  = tp.ReportUpTime  
FROM dbo.#Delays td with (nolock)  
 JOIN dbo.#Primaries tp with (nolock) ON td.TEDetId = tp.TEDetId  
  
-- print 'Calc statistics: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Calculate the Statistics on the dataset and set NULL Uptimes to zero.  
  
-------------------------------------------------------------------------------  
/*  
UPDATE td  
 SET Stops =    CASE WHEN tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
-- MKW 10/16/02     AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsUnscheduled = CASE WHEN tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
-- MKW 10/16/02     AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsScheduled = CASE WHEN tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId <> @SchedUnscheduledId AND td.ScheduleId IS NOT NULL)  
-- MKW 10/16/02     AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  Stops2m =  CASE WHEN td.DownTime < (120/@Conversion)  
       AND  tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
-- MKW 10/16/02     AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsMinor =  CASE WHEN td.DownTime < (600/@Conversion)  
       AND  tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
-- MKW 10/16/02     AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsBreakDowns = CASE WHEN td.DownTime >= (600/@Conversion)  
       AND  tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
-- MKW 10/16/02     AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  UpTime2m =  CASE WHEN td.UpTime < (120/@Conversion)  
       AND  tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
-- MKW 10/16/02     AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
  
      END,  
  StopsBSUpTime2m = CASE WHEN td.UpTime < (120/@Conversion)  
       AND  tpu.DelayType = @DelayTypeBlockedStarvedStr  
-- MKW 10/16/02     AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsProcessFailures = CASE WHEN td.DownTime >= (600/@Conversion)  
       AND  tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId, @CatBlockStarvedId) OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnScheduledId OR td.ScheduleId IS NULL)  
-- MKW 10/16/02     AND (tp.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsStarved =  CASE WHEN td.L1ReasonId = @L1ReasonStarvedId  
-- MKW 10/16/02     AND (td.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsBlocked =  CASE WHEN td.L1ReasonId = @L1ReasonBlockedId  
-- MKW 10/16/02     AND (td.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END,  
  StopsBlockedStarved = CASE WHEN td.CategoryId = @CatBlockStarvedId  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
-- VMK 12/20/04     AND (td.StartTime >= @StartTime)  
       THEN 1  
      ELSE 0  
      END  
FROM dbo.#Delays td with (nolock)  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
WHERE td.TEDetId = td.PrimaryId  
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
  StopsScheduled = CASE WHEN tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId <> @SchedUnscheduledId AND td.ScheduleId IS NOT NULL)  
       THEN 1  
      ELSE 0  
      END,  
  Stops2m =  CASE WHEN td.DownTime < (120/@Conversion)  
       AND  tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
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
  StopsBreakDowns = CASE WHEN td.DownTime >= (600/@Conversion)  
       AND  tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
       THEN 1  
      ELSE 0  
      END,  
  UpTime2m =  CASE WHEN td.UpTime < (120/@Conversion)  
       AND  tpu.DelayType <> @DelayTypeBlockedStarvedStr  
       AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
       THEN 1  
      ELSE 0  
  
      END,  
  StopsBSUpTime2m = CASE WHEN td.UpTime < (120/@Conversion)  
       AND  tpu.DelayType = @DelayTypeBlockedStarvedStr  
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
    END,  
  
  StopsStarved =  CASE WHEN td.L1ReasonId = @L1ReasonStarvedId  
       THEN 1  
      ELSE 0  
      END,  
  StopsBlocked =  CASE WHEN td.L1ReasonId = @L1ReasonBlockedId  
       THEN 1  
      ELSE 0  
      END,  
  StopsBlockedStarved = CASE WHEN td.CategoryId = @CatBlockStarvedId  
       AND tpu.DelayType <> @DelayTypeRateLossStr  
       THEN 1  
      ELSE 0  
      END  
FROM dbo.#Delays td with (nolock)  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
WHERE td.TEDetId = td.PrimaryId  
  
  
--select * from #Delays  
  
DropTables:  
 DROP TABLE dbo.#Primaries  
  
-- print 'Set Downtime for type of stop: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Set the downtime for each type of stop.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET ReportMSDowntime = CASE WHEN td.StopsMinor = 1  
       THEN td.ReportDowntime  
      ELSE 0  
      END,  
  ReportBDDowntime = CASE WHEN td.StopsBreakdowns = 1  
       THEN td.ReportDowntime  
      ELSE 0  
      END,  
  ReportPFDowntime = CASE WHEN td.StopsProcessFailures = 1  
       THEN td.ReportDowntime  
      ELSE 0  
      END,  
  ReportBlockedDowntime = CASE WHEN td.StopsBlocked = 1  
       THEN td.ReportDowntime  
      ELSE 0  
      END,  
  ReportStarvedDowntime = CASE WHEN td.StopsStarved = 1  
       THEN td.ReportDowntime  
      ELSE 0  
      END,  
  ReportDowntime = CASE WHEN td.StopsBlocked <> 1  
       AND td.StopsStarved <> 1  
       --AND td.Stops = 1  
       THEN td.ReportDowntime  
      ELSE 0  
      END,  
  ReportUnSchedDowntime = CASE WHEN td.Stops = 1   
       AND td.StopsUnscheduled = 1  
       THEN td.ReportDowntime  
      ELSE 0  
      END,  
  ReportSchedDowntime =  CASE WHEN td.Stops = 1   
       AND td.StopsScheduled = 1  
       THEN td.ReportDowntime  
      ELSE 0  
      END  
FROM dbo.#Delays td with (nolock)  
  
-- print 'Get MTD Minor Stops: ' + Convert(VarChar(25), GetDate(), 108)  
-------------------------------------------------------------------------------  
-- Get MTD Minor Stops by Prod Unit.  
-- 10/7/04 Vince King  
-- modified code to use Minor Stop variable.  
-------------------------------------------------------------------------------  
DECLARE @MTDMinorStops TABLE (  
 PU_ID    Integer,  
 PL_ID    Integer,  
 MinorStops  Integer)  
  
INSERT @MTDMinorStops (PU_Id, PL_ID, MinorStops)  
 SELECT v.PU_Id, pu.PL_Id, SUM(CONVERT(INTEGER, COALESCE(t.Result, 0)))  
 FROM @ProdLines pl  
  LEFT JOIN dbo.Variables  v with (nolock)  ON pl.VarMinorStopId = v.Var_Id  
  LEFT JOIN dbo.Prod_Units  pu with (nolock) ON v.PU_Id     = pu.PU_Id  
  LEFT JOIN dbo.Tests   t with (nolock)  ON pl.VarMinorStopId = t.Var_Id  
     AND (t.Result_On >= @MTDStartTime AND t.Result_On < @MTDEndTime)  
 GROUP BY v.PU_Id, pu.PL_Id  
 OPTION (KEEP PLAN)  
  
-- print 'Correct stop count: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------------------------------------------------  
-- MKW 10/16/02  
-- Correct the stop counts for any events that started outside the report period  
------------------------------------------------------------------------------------------------------------------------  
UPDATE td  
 SET Stops      = 0,  
   StopsUnscheduled   = 0,  
   StopsScheduled   = 0,  
   Stops2m      = 0,  
   StopsMinor     = 0,  
   StopsBreakDowns   = 0,  
   UpTime2m     = 0,  
   StopsBSUpTime2m   = 0,  
   StopsProcessFailures = 0,  
   StopsStarved   = 0,  
   StopsBlocked   = 0  
  FROM dbo.#Delays td with (nolock)  
 WHERE td.StartTime < @StartTime  
  
  
-- print 'Get Tests data: ' + Convert(VarChar(25),GetDate(),108)  
--*******************************************************************************************************************--  
-- Process all the Test requirements.  
--*******************************************************************************************************************--  
-------------------------------------------------------------------------------  
-- Collect all the Test records for the reporting period.  
-------------------------------------------------------------------------------  
DECLARE ProdLinesCursor INSENSITIVE CURSOR FOR  
 (SELECT PLId, VarCasesToPalId, VarPalletsExitSWId  
  FROM @ProdLines WHERE (VarCasesToPalId IS NOT NULL  
      AND VarPalletsExitSWId IS NOT NULL))  
 FOR READ ONLY  
OPEN ProdLinesCursor  
FETCH NEXT FROM ProdLinesCursor INTO @@Id, @@VarCasesToPalId, @@VarPalletsExitSWId  
WHILE @@Fetch_Status = 0  
BEGIN  
  
 INSERT dbo.#Tests (TestId, VarId, PLId, Value, StartTime)  
  SELECT Test_Id, t.Var_Id, pl.PL_Id, Convert(Float, Result), Result_On  
   FROM dbo.Tests t with (nolock)  
    JOIN dbo.Variables  v with (nolock)  ON t.Var_Id = v.Var_Id  
    JOIN dbo.Prod_Units pu with (nolock) ON v.PU_Id  = pu.PU_Id  
    JOIN dbo.Prod_Lines pl with (nolock) ON pu.PL_Id = pl.PL_Id  
   WHERE t.Var_Id IN (@@VarCasesToPalId, @@VarPalletsExitSWId)  
   AND Result_On > @StartTime  
   AND Result_On <= @EndTime  
   OPTION (KEEP PLAN)  
 SELECT @@VarCasesToPalId  = Null  
 SELECT @@VarPalletsExitSWId  = Null  
 FETCH NEXT FROM ProdLinesCursor INTO @@Id, @@VarCasesToPalId, @@VarPalletsExitSWId  
END  
CLOSE ProdLinesCursor  
DEALLOCATE ProdLinesCursor  
  
DECLARE TestsCursor INSENSITIVE CURSOR FOR  
 (SELECT TestId, VarId, StartTime  
  FROM dbo.#Tests with (nolock))  
 FOR READ ONLY  
OPEN TestsCursor  
FETCH NEXT FROM TestsCursor INTO @@Id, @@VarId, @@TimeStamp  
WHILE @@Fetch_Status = 0  
BEGIN  
 SELECT @@NextStartTime = NULL  
 SELECT @@NextStartTime = Min(StartTime)  
  FROM dbo.#Tests with (nolock)  
  WHERE VarId = @@VarId  
  AND StartTime > @@TimeStamp  
  AND StartTime < @Now  
  OPTION (KEEP PLAN)  
 UPDATE dbo.#Tests   
  SET EndTime = Coalesce(@@NextStartTime, @Now)  
  WHERE TestId = @@Id  
 FETCH NEXT FROM TestsCursor INTO @@Id, @@VarId, @@TimeStamp  
END  
CLOSE TestsCursor  
DEALLOCATE TestsCursor  
  
-- print 'Production summary by Line/Shift: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Now summarize the results into the @ProdRecords table for each Line/Shift.  
-------------------------------------------------------------------------------  
DECLARE @ProdRecords TABLE (  
 PLId      int PRIMARY KEY,  
 CasesToPal    int,  
 PalletsExitSW   int )  
  
DECLARE ProdLinesCursor INSENSITIVE CURSOR FOR  
 (Select PLID, VarCasesToPalId, VarPalletsExitSWId  
  FROM @ProdLines)  
 FOR READ ONLY  
OPEN ProdLinesCursor  
FETCH  NEXT FROM ProdLinesCursor INTO @@PLId, @@VarCasesToPalId, @@VarPalletsExitSWId  
WHILE @@Fetch_Status = 0  
BEGIN  
  
 INSERT @ProdRecords (PLId, CasesToPal, PalletsExitSW)  
  SELECT @@PLId, (SELECT Sum(t.Value)  
     FROM dbo.#Tests t with (nolock)  
     WHERE t.VarId = @@VarCasesToPalId),  
          (SELECT Sum(t.Value)  
     FROM dbo.#Tests t with (nolock)  
     WHERE t.VarId = @@VarPalletsExitSWId)  
  OPTION (KEEP PLAN)  
 FETCH  NEXT FROM ProdLinesCursor INTO @@PLId, @@VarCasesToPalId, @@VarPalletsExitSWId  
END  
CLOSE  ProdLinesCursor  
DEALLOCATE ProdLinesCursor  
  
DECLARE @tblProdRecordsSUM TABLE (  
 EquipGroup  VARCHAR(50),  
 CasesToPal  Integer,  
 PalletsExitSW Integer )  
  
INSERT @tblProdRecordsSUM (EquipGroup, CasesToPal, PalletsExitSW)  
 SELECT @MachineTypePal,  
    SUM(COALESCE(pr.CasesToPal, 0)),  
    SUM(COALESCE(pr.PalletsExitSW, 0))  
 FROM @ProdRecords  pr  
 JOIN @ProdLines   pl ON pr.PLId = pl.PLId  
 WHERE pl.MachineType = @MachineTypePal  
 OPTION (KEEP PLAN)  
  
INSERT @tblProdRecordsSUM (EquipGroup, CasesToPal, PalletsExitSW)  
 SELECT 'ATLSAPTS',  
    SUM(COALESCE(pr.CasesToPal, 0)),  
    SUM(COALESCE(pr.PalletsExitSW, 0))  
 FROM @ProdRecords  pr  
 JOIN @ProdLines   pl ON pr.PLId = pl.PLId  
 WHERE pl.MachineType = @MachineTypeATLS OR pl.MachineType = @MachineTypeAPTS  
 OPTION (KEEP PLAN)  
  
  
-- print 'Group stops by FM: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Group the stops by failure mode cause and get Total Stops and Total Minor Stops.  
-------------------------------------------------------------------------------  
DECLARE @FM TABLE (  
 PLId       int,  
 PUId       int,  
 L1ReasonId     int,  
 TotalStops     int,  
 TotalMinorStops   int,  
 Stops       int,  
 ReportDowntime    float,  
 StopsStarved    int,  
 ReportStarvedDowntime float,  
 StopsBlocked    int,  
 ReportBlockedDowntime float )  
  
INSERT @FM (   
  PLId,   
  PUId,   
  L1ReasonId,   
  TotalStops,   
  TotalMinorStops,   
  Stops,   
  ReportDowntime,   
  StopsStarved,   
  ReportStarvedDowntime,  
  StopsBlocked,   
  ReportBlockedDowntime)  
SELECT pl.PL_Id,   
   td.PUId,   
   td.L1ReasonId,  
   CASE WHEN (td.Stops = 1 OR td.StopsStarved = 1 OR td.StopsBlocked = 1) THEN 1   
    ELSE 0   
    END,  
   CASE  WHEN ((td.ReportDowntime > 0 AND td.ReportDowntime < (120/@Conversion))  
       OR (td.ReportBlockedDowntime > 0 AND td.ReportBlockedDowntime < (120/@Conversion))  
       OR (td.ReportStarvedDowntime > 0 AND td.ReportStarvedDowntime < (120/@Conversion))) THEN 1   
     ELSE 0   
     END,  
   td.Stops,   
   td.ReportDowntime,   
   td.StopsStarved,   
   td.ReportStarvedDowntime,   
   td.StopsBlocked,   
   td.ReportBlockedDowntime  
FROM dbo.#Delays td with (nolock)  
   JOIN   dbo.Prod_Units  pu with (nolock) ON td.PUID    = pu.PU_Id  
   JOIN   dbo.Prod_Lines  pl with (nolock) ON pu.PL_Id   = pl.PL_Id  
   LEFT JOIN dbo.Event_Reasons er with (nolock) ON td.L1ReasonId  = er.Event_Reason_Id  
WHERE td.StopsUnscheduled = 1     
OPTION (KEEP PLAN)  
  
-- print 'Summarize by Line/RL1: ' + Convert(VarChar(25),GetDate(),108)  
-------------------------------------------------------------------------------  
-- Summarize Stops/Minor Stops by Line/Reason Level 1 and write only the Top  
-- 3 Reason Level 1 by Stops to the table.  
-------------------------------------------------------------------------------  
DECLARE @FMGROUP TABLE (  
 PLId     int,  
 PLDesc    varchar(100),  
 L1Reason    varchar(100),  
 TotalStops   int,  
 TotalMinorStops Int )  
  
DECLARE ProdLinesCursor INSENSITIVE CURSOR FOR  
 (Select PLID  
  FROM @ProdLines)  
 FOR READ ONLY  
OPEN ProdLinesCursor  
FETCH  NEXT FROM ProdLinesCursor INTO @@PLId  
WHILE @@Fetch_Status = 0  
 BEGIN  
  
 UPDATE @ProdLines SET  TotalStops = (SELECT Sum(Coalesce(Stops, 0))  
      FROM dbo.#Delays td with (nolock)  
       JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
      WHERE pu.PL_Id = @@PLId  
      GROUP BY pu.PL_Id),  
    TotalUptime = (SELECT Sum(td.ReportUptime)  
      FROM dbo.#Delays td with (nolock)  
       JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
      WHERE pu.PL_Id = @@PLId  
      GROUP BY pu.PL_Id),  
    TotalDowntime = (SELECT Sum(td.ReportDowntime)  
      FROM dbo.#Delays td with (nolock)  
       JOIN dbo.Prod_Units pu with (nolock) ON td.PUId = pu.PU_Id  
      WHERE pu.PL_Id = @@PLId  
      GROUP BY pu.PL_Id)  
  WHERE PLId = @@PLId  
  
 INSERT @FMGROUP (PLId, PLDesc, L1Reason, TotalStops, TotalMinorStops)  
  SELECT Top 4 fm.PLId, pl.PL_Desc, er.Event_Reason_Name, Sum(Coalesce(fm.TotalStops, 0)),   
    Sum(Coalesce(fm.TotalMinorStops, 0))  
  FROM @FM fm  
   LEFT JOIN dbo.Prod_Lines  pl with (nolock)  ON fm.PLId    = pl.PL_Id  
   LEFT JOIN @ProdLines    ppl  ON fm.PLId    = ppl.PLId  
   LEFT JOIN @ProdUnits    ppu  ON fm.PUId    = ppu.PUId  
   LEFT JOIN  dbo.Event_Reasons er with (nolock)  ON fm.L1ReasonId  = er.Event_Reason_Id  
  WHERE fm.PLId = @@PLId  
   AND ppl.MachineType = @MachineTypePal  
   AND ppu.DelayType <> @DelayTypeBlockedStarvedStr  
  GROUP BY fm.PLId, pl.PL_Desc, er.Event_Reason_Name  
  ORDER BY Sum(fm.TotalStops) desc, Sum(fm.TotalMinorStops) desc  
  OPTION (KEEP PLAN)  
  
FETCH  NEXT FROM ProdLinesCursor INTO @@PLId  
END  
CLOSE  ProdLinesCursor  
DEALLOCATE ProdLinesCursor  
  
SELECT @TotalReportTime = convert(float, datediff(s, @StartTime, @EndTime))/@Conversion  
SELECT @TotalPalletizers = (SELECT COUNT(PLID) FROM @ProdLines WHERE MachineType = @MachineTypePal)  
SELECT @TotalCasesToPalletizer = (SELECT SUM(CasesToPal)   
     FROM @ProdRecords pr  
      JOIN @ProdLines pl ON pr.PLID = pl.PLID  
     WHERE MachineType = @MachineTypePal)  
SELECT @TotalPalletsExitSW = (SELECT SUM(PalletsExitSW)   
     FROM @ProdRecords pr  
      JOIN @ProdLines pl ON pr.PLID = pl.PLID  
     WHERE MachineType = @MachineTypePal)  
  
  
SELECT @Plant = value   
 from dbo.site_parameters with (nolock)  
 where parm_id = 12  
  
--This is to obtain the MTD Data required for report  
  
-- print 'Month To Date data: ' + Convert(VarChar(25),GetDate(),108)  
  
DECLARE @MTDLineData TABLE (  
 PU_ID   int,  
 PL_ID   int,  
 PL_DESC  varchar(100),  
 VAR_ID  int,  
 VAR_DESC  varchar(100),  
 TOTROWS  Float)  
  
INSERT @MTDLineData (PU_ID, PL_ID, PL_DESC, VAR_ID, VAR_DESC, TOTROWS)  
  
select p.pu_id, p1.pl_id, p1.pl_desc, t.var_id, v.var_desc, sum(convert(float, result))as totrows  
 from dbo.prod_units  p with (nolock)  
 join dbo.prod_lines  p1 with (nolock) on p1.pl_id = p.pl_id  
 join dbo.variables  v with (nolock)  on v.pu_id  = p.pu_id  
 join dbo.tests   t with (nolock)  on t.var_id = v.var_id  
 where v.var_id in (select v1.var_id  
  from dbo.variables v1 with (nolock)  
  where v1.var_desc = @VarCasesToPalVN  
  OR v1.var_desc = @VarPalletsExitSWVN  
  AND v1.Data_Type_Id in (1,2))  
 AND t.result_on >= @MTDStartTime  
 and t.result_on < @MTDEndTime  
 group by p.pu_id, p1.pl_id, v.var_id, t.var_id, p1.pl_desc, v.var_desc  
OPTION (KEEP PLAN)  
  
Select @DaysInMonth = DATEPART(day,@MTDEndTime)  
-- print @DaysInMonth                -- 06/19/06 VMK, commented out  
Select @DaysIntoMonth = DATEPART(day, @EndTime)  
-- print @DaysIntoMonth                -- 06/19/06 VMK, commented out  
  
select @MTDTOTROWS = sum(totrows) from @MTDLineData  
  
CREATE TABLE #SummaryData (  
   Total        VarChar(25),   
   Loc         VarChar(100),  
   PLId        Int,  
   PL_Desc        VarChar(100),  
   MinorStops       Int,  
   DailyStops1000Cases    Float,   
   DailyStops1000UnitLoads  Float,  
--    MTDMinorStopPerReduction  Float,    -- 2007-02-14 VMK Rev3.27, removed - not needed anymore.  
   MinorStopsDowntime    Float,  
   EquipmentFailure     Int,  
   EquipmentFailureDowntime  Float,  
   ProcessFailures     Int,  
   ProcessFailuresDowntime  Float,  
   TotalStops       Int,  
   TotalDowntime      Float,  
   TotalUptime      Float,  
   OverallScheduledTime   Float,  
   OverallAvailability    Float,  
   OverallUtilization    Float,  
   OverallReadiness     Float,  
   OverallMTBF      Float,  
   OverallMTTR      Float,  
   R2         Float,  
   CasesToPalletizer    Float,  
   UnitLoads       Int,  
   MTDCasesToPal      float,  
   MTDMS        float   --,  
--    BaseLineNum      float         -- 2007-02-14 VMK Rev3.27, removed - not needed anymore  
   )  
  
--The is the grand total line for palletizers  
 SELECT @TotalPALReportTime = count(PLId) * @TotalReportTime  
 FROM @ProdLines  
 WHERE MachineType = @MachineTypePal  
  
INSERT #SummaryData (  
   Total,   
   Loc,  
   PLId,  
   PL_Desc,  
   MinorStops,  
   DailyStops1000Cases,   
   DailyStops1000UnitLoads,  
--    MTDMinorStopPerReduction,        -- 2007-02-14 VMK Rev3.27, removed - not needed anymore.  
   MinorStopsDowntime,  
   EquipmentFailure,  
   EquipmentFailureDowntime,  
   ProcessFailures,  
   ProcessFailuresDowntime,  
   TotalStops,  
   TotalDowntime,  
   TotalUptime,  
   OverallScheduledTime,  
   OverallAvailability,  
   OverallUtilization,  
   OverallReadiness,  
   OverallMTBF,  
   OverallMTTR,  
   R2,  
   CasesToPalletizer,  
   UnitLoads,  
   MTDCasesToPal,  
   MTDMS --,  
--    BaseLineNum           -- 2007-02-14 VMK Rev3.27, removed - not needed anymore  
   )  
  
  
 SELECT COALESCE(imp.dept, 'Not Configured'),  
   ' ',  
   pl.PL_Id,  
   pl.PL_Desc,  
   sum(Coalesce(td.StopsMinor, 0)),  
   CASE WHEN (Max(pr.CasesToPal) > 0 AND sum(td.StopsMinor) > 0) THEN  
   convert(float,convert(float,sum(td.StopsMinor))/Max(pr.CasesToPal))*1000        
        ELSE 0.00  
        END ,  
   CASE WHEN (Max(pr.PalletsExitSW) > 0 AND sum(td.StopsMinor) > 0) THEN  
   convert(float,convert(float,sum(td.StopsMinor))/Max(pr.PalletsExitSW))*1000  
        ELSE 0.00  
        END ,  
-- 2007-02-14 VMK Rev3.27, removed - not needed anymore.  
--    CASE WHEN sum(coalesce(td.StopsMinor,0)) > 0 AND cast(a.target as float) > 0 THEN  
--     1 - ((SUM(COALESCE(td.StopsMinor, 0))) / ((CAST(a.Target AS FLOAT)) * @DaysIntoMonth))  -- VMK 2005-01-12 Changed Minor Stops Reduction Calc.  
--    ELSE 0.00  
--    END ,  
   sum(td.ReportMSDowntime) ,  
   sum(Coalesce(td.StopsBreakdowns, 0)),  
   sum(td.ReportBDDowntime),  
   sum(Coalesce(td.StopsProcessFailures, 0)),  
   sum(td.ReportPFDowntime),  
   sum(Coalesce(td.Stops, 0)),  
   sum(td.ReportDownTime),  
   @TotalReportTime - sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime),  
   Sum(td.ReportSchedDowntime),  
   CASE WHEN (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) > 0 THEN   
     (@TotalReportTime -  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /   
     (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime))  
    ELSE 0.00   
    END,  
   CASE WHEN @TotalReportTime > 0 THEN   
     (@TotalReportTime -  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) / @TotalReportTime  
    ELSE 0.00   
    END,  
   CASE  WHEN (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime)) > 0 THEN  
     (@TotalReportTime - Sum(td.ReportDownTime)) /   
          (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime))   
    ELSE 0.00   
    END,  
   CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN   
     (@TotalReportTime -  
  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /  
     sum(coalesce(td.Stops, 0))  
    ELSE 0   
    END,  
   CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN SUM(td.ReportDowntime) / Sum(Coalesce(td.Stops, 0))  
    ELSE 0   
    END,  
   CASE  WHEN SUM(COALESCE(td.StopsBSUpTime2m, 0)) + SUM(COALESCE(td.Stops, 0)) > 0 THEN  
     (1 - (SUM(COALESCE(td.Uptime2m, 0)) / (SUM(COALESCE(td.StopsBSUpTime2m, 0)) +   
     SUM(COALESCE(td.Stops, 0)))))   
    ELSE 0   
    END,  
   Max(pr.CasesToPal),  
   Max(pr.PalletsExitSW),  
   sum(mtd.MinorStops),  
   sum(mtdl.TOTROWS) --,  
--    convert(float,a.target)         -- 2007-02-14 VMK Rev3.27, removed - not needed anymore.  
   FROM  dbo.#Delays td with (nolock)  
   LEFT JOIN dbo.Prod_Units   pu with (nolock)  ON td.PUId    = pu.PU_Id  
   LEFT JOIN dbo.Prod_Lines   pl with (nolock)  ON pu.PL_Id   = pl.PL_Id  
   LEFT JOIN @ProdLines     ppl  ON pl.PL_Id   = ppl.PLId  
   LEFT JOIN @ProdUnitsImpDept  imp  ON td.LocationId  = imp.Source_PUId  
   LEFT JOIN @ProdRecords    pr  ON pl.PL_Id   = pr.PLId            -- 2007-02-13 VMK Rev3.26, added LEFT  
-- 2007-02-14 VMK Rev3.27, removed JOIN to Characteristics, Active_Specs and Specifications, not needed since removing MTD Minor Stops Reduction column.  
--    LEFT  join  dbo.characteristics  c   on pl.pl_desc   = 'TT ' + c.char_desc  
--    LEFT join  dbo.active_specs   a   on a.char_id   = c.char_id            -- 2007-02-13 VMK Rev3.26, added LEFT  
--                   and a.effective_date <= @StartTime  
--                   and (a.expiration_date > @StartTime OR a.expiration_date is NULL)  
--    LEFT  join  dbo.specifications  sp  on sp.spec_id   = a.spec_id            -- 2007-02-13 VMK Rev3.26, added LEFT  
--                   and sp.spec_desc = 'Minor Stops Target'  
   LEFT JOIN @MTDMinorStops   mtd  on td.puid    = mtd.pu_id  
   LEFT JOIN @mtdlinedata    mtdl  on mtdl.pu_id   = td.puid  
                 and mtdl.var_desc = 'Cases Into Palletizer'  
   WHERE ppl.MachineType = @MachineTypePal  
--      AND imp.dept IS NOT NULL  
   GROUP BY pl.PL_Id, pl.PL_Desc, imp.dept   --, a.target  -- 2007-02-14 VMK Rev3.27, removed a.target- not needed anymore.  
 OPTION (KEEP PLAN)  
  
--This is the grand total line for conveyors  
  
 SELECT @TotalPALReportTime = count(PLId) * @TotalReportTime  
 FROM @ProdLines  
 WHERE MachineType = @MachineTypeConv  
  OR MachineType = @MachineTypeConvMP  
  
INSERT #SummaryData (  
   Total,   
   PLId,  
   PL_Desc,  
   MinorStops,  
   DailyStops1000Cases,   
   DailyStops1000UnitLoads,  
--    MTDMinorStopPerReduction,       -- 2007-02-14 VMK Rev3.27, removed - not needed anymore.  
   MinorStopsDowntime,  
   EquipmentFailure,  
   EquipmentFailureDowntime,  
   ProcessFailures,  
   ProcessFailuresDowntime,  
   TotalStops,  
   TotalDowntime,  
   TotalUptime,  
   OverallScheduledTime,  
   OverallAvailability,  
   OverallUtilization,  
   OverallReadiness,  
   OverallMTBF,  
   OverallMTTR,  
   R2,  
   CasesToPalletizer,  
   UnitLoads,  
   MTDCasesToPal,  
   MTDMS  --,  
--    BaseLineNum         -- 2007-02-14 VMK Rev3.27, removed - not needed anymore  
   )  
  
 SELECT COALESCE(imp.dept, 'Not Configured') [Department],  
    pl.PL_Id,  
    pl.PL_Desc              [Line],  
    sum(Coalesce(td.StopsMinor, 0))            [Minor Stops],  
    CASE WHEN (Max(pr.CasesToPal) > 0 AND sum(td.StopsMinor) > 0) THEN  
    convert(float,convert(float,sum(td.StopsMinor))/Max(pr.CasesToPal))*1000        
         ELSE 0.00  
         END                 [Stops/1000 Cases],            -- 2006-06-26 VMK Removed Daily from column name  
    CASE WHEN (Max(pr.PalletsExitSW) > 0 AND sum(td.StopsMinor) > 0) THEN  
    convert(float,convert(float,sum(td.StopsMinor))/Max(pr.PalletsExitSW))*1000  
         ELSE 0.00  
         END                 [Stops/1000 Unit Loads],          -- 2006-06-26 VMK Removed Daily from column name  
--     0.00,                                   -- 2007-02-14 VMK Rev3.27, removed - not needed anymore.  
    sum(td.ReportMSDowntime)            [Minor Stops Downtime],  
    sum(Coalesce(td.StopsBreakdowns, 0))           [Equipment Failure],  
    sum(td.ReportBDDowntime)            [Equipment Failure Downtime],  
    sum(Coalesce(td.StopsProcessFailures, 0))          [Process Failures],  
    sum(td.ReportPFDowntime)            [Process Failures Downtime],  
    sum(Coalesce(td.Stops, 0))            [Total Stops],  
    sum(td.ReportDownTime)           [Total Downtime],  
    @TotalReportTime - sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime) [Total Uptime],  
    Sum(td.ReportSchedDowntime)            [Overall Scheduled Time],  
    CASE WHEN (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) > 0 THEN   
      (@TotalReportTime -  
      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /   
      (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime))  
     ELSE 0.00   
     END              [Overall Availability],  
    CASE WHEN @TotalReportTime > 0 THEN   
      (@TotalReportTime -  
      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) / @TotalReportTime  
     ELSE 0.00   
     END              [Overall Utilization],  
    CASE  WHEN (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime)) > 0 THEN  
      (@TotalReportTime - Sum(td.ReportDownTime)) /   
           (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime))   
     ELSE 0.00   
     END              [Overall Readiness],  
    CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN   
      (@TotalReportTime -  
   
      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /  
      sum(coalesce(td.Stops, 0))  
     ELSE 0   
     END              [Overall MTBF],  
    CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN SUM(td.ReportDowntime) / Sum(Coalesce(td.Stops, 0))  
     ELSE 0   
     END              [Overall MTTR],  
    CASE  WHEN SUM(COALESCE(td.StopsBSUpTime2m, 0)) + SUM(COALESCE(td.Stops, 0)) > 0 THEN  
      (1 - (SUM(COALESCE(td.Uptime2m, 0)) / (SUM(COALESCE(td.StopsBSUpTime2m, 0)) +   
      SUM(COALESCE(td.Stops, 0)))))   
     ELSE 0   
     END              [R(2)],  
    Max(pr.CasesToPal)             [Cases To Palletizer],  
    Max(pr.PalletsExitSW)            [Unit Loads],  
    MAX(mtdl.TOTROWS) [MTD CASES TO PALLETIZER BY LINE],  
    MAX(mtd.MinorStops) [MTD Minor Stops]  --,  
--     0.00 [baselinenum]            -- 2007-02-14 VMK Rev3.27, removed - not needed anymore  
   FROM   dbo.#Delays      td with (nolock)  
   LEFT JOIN dbo.Prod_Units   pu with (nolock)  ON td.PUId    = pu.PU_Id  
   LEFT JOIN dbo.Prod_Lines   pl with (nolock)  ON pu.PL_Id   = pl.PL_Id  
   LEFT JOIN @ProdLines     ppl  ON pl.PL_Id   = ppl.PLId  
   LEFT JOIN @ProdUnitsImpDept  imp  ON td.LocationId  = imp.Source_PUId  
   LEFT JOIN @ProdRecords    pr  ON pl.PL_Id   = pr.PLId  
   LEFT JOIN @MTDMinorStops   mtd  on td.puid    = mtd.pu_id  
   LEFT JOIN @mtdlinedata    mtdl  on mtdl.pu_id   = td.puid  
   WHERE (ppl.MachineType = @MachineTypeConv   
     OR ppl.MachineType = @MachineTypeConvMP )  
--     AND imp.dept IS NOT NULL)  
   GROUP BY imp.dept, pl.PL_Id, pl.PL_Desc  
   ORDER BY imp.dept, pl.PL_Id, pl.PL_Desc  
 OPTION (KEEP PLAN)  
  
-- select '#SummaryData' [#SummaryData], * from #SummaryData  
-- select '@MTDMinorStops' [@MTDMinorStops], * from @MTDMinorStops  
  
--this ends the insert for #SummaryData table  
  
-- select '#Delays', pu.pu_desc, td.* from #Delays td  
--         join prod_units pu on td.puid = pu.pu_id  
-- where pu.pl_Id = 123  
--   
-- select '@ProdLines' [@ProdLines], * from @ProdLines  
-- select '@ProdUnits' [@ProdUnits], * from @ProdUnits  
-- select '@ProdUnitsImpDept' [@ProdUnitsImpDept], * from @ProdUnitsImpDept  
-- select '#SummaryData', sd.*, ppl.*  
--    FROM   #SummaryData  sd  
--    LEFT JOIN Prod_Lines   pl  ON sd.PLId   = pl.PL_Id  
--    LEFT JOIN @ProdLines  ppl ON sd.PLId   = ppl.PLId  
--    LEFT JOIN @MTDMinorStops mtdms ON sd.PLId   = mtdms.PL_Id  
--    WHERE ppl.MachineType = @MachineTypePal  
--       AND sd.Total IS NOT NULL  
-- select '@ProdRecords' [@ProdRecords], * from @ProdRecords  
-- select '@FMGroup' [@FMGroup], * from @FMGroup  
-- select '@FM' [@FM], * from @FM  
  
-- print 'Return Result Sets: ' + Convert(VarChar(25),GetDate(),108)  
  
ReturnResultSets:  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Error Messages. Result Set #1  
 ---------------------------------------------------------------------------------------------------------------------------  
 SELECT ErrMsg  
  FROM @ErrorMessages  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- All raw data.  Note that Excel can only handle a maximum of 65536 rows in a  
 -- spreadsheet.  Therefore, we send an error if there are more than that number.  
 ---------------------------------------------------------------------------------------------------------------------------  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the stops result set for MTD Line Data.  
 -- This is record set #2  
 ---------------------------------------------------------------------------------------------------------------------------  
  
 SELECT    
   CASE WHEN (GROUPING(pl_desc) = 1) THEN 'TOTAL'  
   ELSE ISNULL(pl_desc, 'UNKNOWN')  
   END AS LINE,  
   SUM(TOTROWS) [MTD CASES TO PALLETIZER BY LINE]  
   FROM @MTDLineData mtdl  
   where var_desc = 'Cases Into Palletizer'  
   GROUP BY pl_desc WITH ROLLUP  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the stops result set for MTD Minor Stops.  
 -- This is record set #3  
 ---------------------------------------------------------------------------------------------------------------------------  
  
 SELECT MinorStops [MTD Minor Stops]  
 FROM @MTDMinorStops mtdms  
 JOIN dbo.Prod_Units pu with (nolock) ON mtdms.PU_Id = pu.PU_Id  
 ORDER BY pu.PU_Desc  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the stops result set for Line for Palletizers.  
 -- This is record set #4  
 ---------------------------------------------------------------------------------------------------------------------------  
   
 SELECT COALESCE(imp.dept, 'Not Configured')             [Department],  
   pl.PLDesc                       [Line],         -- 2005-Nov-22 VMK Rev3.2  
   CASE WHEN (Max(pr.CasesToPal) > 0 AND sum(td.Stops) > 0) THEN                -- 2006-06-26 VMK Rev3.23, added  
   convert(float,convert(float,sum(td.Stops))/Max(pr.CasesToPal))*1000        
        ELSE 0.00                                  
        END                       [Total Stops/1000 Cases],  
   sum(Coalesce(td.Stops, 0))                 [Total Stops],       -- 2006-06-26 VMK Rev3.23, moved from below  
   sum(td.ReportDownTime)                  [Total Downtime],      -- 2006-06-26 VMK Rev3.23, moved from below  
   CASE WHEN (Max(pr.CasesToPal) > 0 AND sum(td.StopsMinor) > 0) THEN  
   convert(float,convert(float,sum(td.StopsMinor))/Max(pr.CasesToPal))*1000        
        ELSE 0.00                                -- 2006-06-26 VMK Rev3.23, removed Daily from column name  
        END                       [Minor Stops/1000 Cases],   -- [Daily Minor Stops/1000 Cases],  
   CASE WHEN (Max(pr.PalletsExitSW) > 0 AND sum(td.StopsMinor) > 0) THEN  
   convert(float,convert(float,sum(td.StopsMinor))/Max(pr.PalletsExitSW))*1000  
        ELSE 0.00                                -- 2006-06-26 VMK Rev3.23, removed Daily from column name   
        END                       [Minor Stops/1000 Unit Loads],  -- [Daily Minor Stops/1000 Unit Loads],  
-- 2006-06-27 VMK Rev3.23 removed  
--    CASE WHEN MAX(mtdms.MinorStops) > 0 AND cast(MAX(a.target) as float) > 0 THEN  
--     1 - ((MAX(mtdms.MinorStops)) / ((CAST(MAX(a.Target) AS FLOAT)) * @DaysIntoMonth))        -- VMK 2005-01-12 Changed Minor Stops Reduction Calc.  
--    ELSE 0.00  
--    END                          [MTD Minor Stop % Reduction],  
   sum(Coalesce(td.StopsMinor, 0))                [Minor Stops],  
   sum(td.ReportMSDowntime)                  [Minor Stops Downtime],  
   sum(Coalesce(td.StopsBreakdowns, 0))              [Equipment Failures],  
   sum(td.ReportBDDowntime)                  [Equipment Failure Downtime],  
   sum(Coalesce(td.StopsProcessFailures, 0))            [Process Failures],  
   sum(td.ReportPFDowntime)                  [Process Failures Downtime],  
-- 2006-06-26 VMK Rev3.23, removed  
--    CASE WHEN @TotalReportTime > 0 THEN   
--      (@TotalReportTime -  
--      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) / @TotalReportTime  
--     ELSE 0.00   
--     END                        [Overall Utilization],  
   CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN   
     (@TotalReportTime -  
  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /  
     sum(coalesce(td.Stops, 0))  
    ELSE 0   
    END                        [Overall MTBF],  
   CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN SUM(td.ReportDowntime) / Sum(Coalesce(td.Stops, 0))  
    ELSE 0  
    END                        [Overall MTTR],  
   CASE  WHEN SUM(COALESCE(td.StopsBSUpTime2m, 0)) + SUM(COALESCE(td.Stops, 0)) > 0 THEN  
     (1 - (SUM(COALESCE(td.Uptime2m, 0)) / (SUM(COALESCE(td.StopsBSUpTime2m, 0)) +   
     SUM(COALESCE(td.Stops, 0)))))   
    ELSE 0   
    END                        [R(2)],  
   Max(COALESCE(pr.CasesToPal, 0))                [Cases To Palletizer],  
   Max(COALESCE(pr.PalletsExitSW, 0))              [Unit Loads],  
   -- 2006-06-26 VMK Rev3.23, moved these last fields from above.  
   @TotalReportTime - sum(td.ReportDownTime) -   
    sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)    [Total Uptime],  
   Sum(td.ReportSchedDowntime)                 [Overall Scheduled Time],  
   CASE WHEN (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) > 0 THEN   
     (@TotalReportTime -  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /   
     (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime))  
    ELSE 0.00   
    END                        [Overall Availability],  
   CASE  WHEN (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime)) > 0 THEN  
     (@TotalReportTime - Sum(td.ReportDownTime)) /   
          (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime))   
    ELSE 0.00   
    END                        [Overall Readiness]  
   FROM  dbo.#Delays td with (nolock)  
   LEFT JOIN @ProdUnits    pu  ON td.PUId   = pu.PUId  
--    LEFT JOIN dbo.Prod_Units   pu  ON td.PUId    = pu.PU_Id  -- 2005-Nov-22 VMK Rev3.2  
--    LEFT JOIN dbo.Prod_Lines   pl  ON pu.PL_Id   = pl.PL_Id  -- 2005-Nov-22 VMK Rev3.2  
   LEFT JOIN @ProdLines     pl  ON pl.PLId    =  pu.PLId  
   LEFT JOIN @ProdUnitsImpDept  imp  ON td.LocationId  =  imp.Source_PUId  
   LEFT JOIN @ProdRecords    pr  ON pl.PLId    =  pr.PLId  
   LEFT JOIN @MTDMinorStops   mtdms ON td.PUId    =  mtdms.PU_Id   
-- 2007-02-14 VMK Rev3.27, removed JOIN to Characteristics and Active_Specs, not needed since removing MTD Minor Stops Reduction column.  
--    LEFT JOIN  dbo.characteristics  c   on pl.PLDesc = 'TT ' + c.char_desc      -- 2007-01-02 VMK Rev3.25, added LEFT  
--    LEFT JOIN  dbo.active_specs   a   on a.char_id = c.char_id         -- 2007-01-02 VMK Rev3.25, added LEFT  
--                  and a.effective_date <= @StartTime  
--                  and (a.expiration_date > @StartTime OR a.expiration_date is NULL)  
--      JOIN  dbo.specifications  sp  on (sp.spec_id = a.spec_id        -- 2005-Nov-22 VMK Rev3.2  
--                  and sp.spec_desc = 'Minor Stops Target')  
--    LEFT JOIN @MTDLineData    mtdl  on (mtdl.pu_id = td.puid        -- 2005-Nov-22 VMK Rev3.2  
--                  and mtdl.var_desc = 'Cases Into Palletizer')  
   WHERE pl.MachineType = @MachineTypePal  
--    and imp.dept is not null  
   GROUP BY pl.PLDesc, imp.dept    --, a.target  
   ORDER BY pl.PLDesc                   -- 2007-01-02 VMK Rev3.25, added  
  
-- 2006-06-28 VMK Rev3.15, removed.  This is including Conveyor systems in the PAL section.  
--  UNION  
--   
--  SELECT COALESCE(imp.dept, 'Not Configured')             [Department],  
--    pl.PLDesc                       [Line],         -- 2005-Nov-22 VMK Rev3.2  
--    CASE WHEN (Max(pr.CasesToPal) > 0 AND sum(td.Stops) > 0) THEN                -- 2006-06-26 VMK Rev3.23, added  
--    convert(float,convert(float,sum(td.Stops))/Max(pr.CasesToPal))*1000        
--         ELSE 0.00                                  
--         END                       [Total Stops/1000 Cases],  
--    sum(Coalesce(td.Stops, 0))                 [Total Stops],       -- 2006-06-26 VMK Rev3.23, moved from below  
--    sum(td.ReportDownTime)                  [Total Downtime],      -- 2006-06-26 VMK Rev3.23, moved from below  
--    CASE WHEN (Max(pr.CasesToPal) > 0 AND sum(td.StopsMinor) > 0) THEN  
--    convert(float,convert(float,sum(td.StopsMinor))/Max(pr.CasesToPal))*1000        
--         ELSE 0.00                                -- 2006-06-26 VMK Rev3.23, removed Daily from column  
--         END                       [Minor Stops/1000 Cases],   -- [Daily Minor Stops/1000 Cases],  
--    CASE WHEN (Max(pr.PalletsExitSW) > 0 AND sum(td.StopsMinor) > 0) THEN  
--    convert(float,convert(float,sum(td.StopsMinor))/Max(pr.PalletsExitSW))*1000  
--         ELSE 0.00                                -- 2006-06-26 VMK Rev3.23, removed Daily from column  
--         END                       [Minor Stops/1000 Unit Loads], -- [Daily Minor Stops/1000 Unit Loads],  
-- --    0.00,                                  -- 2006-06-27 VMK Rev3.23, removed  
--    sum(Coalesce(td.StopsMinor, 0))                [Minor Stops],  
--    sum(td.ReportMSDowntime)                  [Minor Stops Downtime],  
--    sum(Coalesce(td.StopsBreakdowns, 0))              [Equipment Failures],  
--    sum(td.ReportBDDowntime)                  [Equipment Failure Downtime],  
--    sum(Coalesce(td.StopsProcessFailures, 0))            [Process Failures],  
--    sum(td.ReportPFDowntime)                  [Process Failures Downtime],  
-- -- 2006-06-26 VMK Rev3.23, removed  
-- --    CASE WHEN @TotalReportTime > 0 THEN   
-- --      (@TotalReportTime -  
-- --      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) / @TotalReportTime  
-- --     ELSE 0.00   
-- --     END                        [Overall Utilization],  
--    CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN   
--      (@TotalReportTime -  
--   
--      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /  
--      sum(coalesce(td.Stops, 0))  
--     ELSE 0   
--     END                        [Overall MTBF],  
--    CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN SUM(td.ReportDowntime) / Sum(Coalesce(td.Stops, 0))  
--     ELSE 0   
--     END                        [Overall MTTR],  
--    CASE  WHEN SUM(COALESCE(td.StopsBSUpTime2m, 0)) + SUM(COALESCE(td.Stops, 0)) > 0 THEN  
--      (1 - (SUM(COALESCE(td.Uptime2m, 0)) / (SUM(COALESCE(td.StopsBSUpTime2m, 0)) +   
--      SUM(COALESCE(td.Stops, 0)))))   
--     ELSE 0   
--     END                        [R(2)],  
--    Max(pr.CasesToPal)                    [Cases To Palletizer],  
--    Max(pr.PalletsExitSW)                  [Unit Loads],  
--    -- 2006-06-26 VMK Rev3.23, moved these columns from above  
--    @TotalReportTime - sum(td.ReportDownTime) -   
--     sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)    [Total Uptime],  
--    Sum(td.ReportSchedDowntime)                 [Overall Scheduled Time],  
--    CASE WHEN (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) > 0 THEN   
--      (@TotalReportTime -  
--      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /   
--      (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime))  
--     ELSE 0.00   
--     END                        [Overall Availability],  
--    CASE  WHEN (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime)) > 0 THEN  
--      (@TotalReportTime - Sum(td.ReportDownTime)) /   
--           (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime))   
--     ELSE 0.00   
--     END                        [Overall Readiness]  
--    FROM  #Delays td  
--    LEFT JOIN @ProdUnits   pu  ON td.PUId   = pu.PUId  
-- --    LEFT JOIN dbo.Prod_Units  pu  ON td.PUId    = pu.PU_Id  
-- --    LEFT JOIN dbo.Prod_Lines  pl  ON pu.PL_Id   = pl.PL_Id  
--    LEFT JOIN @ProdLines    pl  ON pl.PLId    =  pu.PLId      -- 2005-Nov-22 VMK Rev3.2  
--    LEFT JOIN @ProdUnitsImpDept imp  ON td.LocationId  =  imp.Source_PUId  
--    LEFT JOIN @ProdRecords   pr  ON pl.PLId    =  pr.PLId  
-- --    LEFT JOIN @MTDMinorStops  mtd  on td.puid    =  mtd.pu_id  -- 2005-Nov-22 VMK Rev3.2  
--    WHERE pl.MachineType <> @MachineTypePal  
--    GROUP BY pl.PLDesc, imp.dept  
--    ORDER BY Department, pl.PLDesc  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the stops result set for Total for Palletizers.  
 -- This is record set #5  
 ---------------------------------------------------------------------------------------------------------------------------  
 SELECT @TotalPALReportTime = count(PLId) * @TotalReportTime  
 FROM @ProdLines  
 WHERE MachineType = @MachineTypePal  
  
 SELECT 'Total'                       [Total],  
   CASE WHEN (@TotalCasesToPalletizer > 0 AND sum(sd.TotalStops) > 0) THEN  
   convert(float,convert(float,sum(sd.TotalStops))/@TotalCasesToPalletizer)*1000  
        ELSE 0.00  
        END                       [Total Stops/1000 Cases],        -- 2006-06-26 VMK Removed Daily from column name  
   sum(sd.TotalStops)                   [Total Stops],            -- 2006-06-26 VMK Rev3.23, moved from below  
   sum(sd.TotalDowntime)                  [Total Downtime],           -- 2006-06-26 VMK Rev3.23, moved from below  
   CASE WHEN (@TotalCasesToPalletizer > 0 AND sum(sd.MinorStops) > 0) THEN  
   convert(float,convert(float,sum(sd.MinorStops))/@TotalCasesToPalletizer)*1000  
        ELSE 0.00  
        END                       [Minor Stops/1000 Cases],        -- 2006-06-26 VMK Removed Daily from column name  
   CASE WHEN (@TotalPalletsExitSW > 0 AND sum(sd.MinorStops) > 0) THEN  
   convert(float,convert(float,sum(sd.MinorStops))/@TotalPalletsExitSW)*1000  
        ELSE 0.00  
        END                       [Minor Stops/1000 Unit Loads],      -- 2006-06-26 VMK Removed Daily from column name  
-- 2006-06-27 VMK Rev3.23, removed  
--    CASE WHEN MAX(mtdms.MinorStops) > 0 AND sum(cast(sd.baselinenum as float)) > 0 THEN  
--     1 - ((SUM(COALESCE(mtdms.MinorStops, 0))) / (SUM(CAST(sd.baselinenum AS FLOAT)) * @DaysIntoMonth))        -- VMK 2005-01-12 Changed Minor Stops Reduction Calc.  
--    ELSE 0.00  
--    END                          [MTD Minor Stop % Reduction],  
   sum(sd.MinorStops)                   [Minor Stops],  
   sum(sd.MinorStopsDowntime)                 [Minor Stops Downtime],  
   Sum(sd.EquipmentFailure)                  [Equipment Failures],  
   sum(sd.EquipmentFailureDowntime)               [Equipment Failure Downtime],  
   Sum(sd.ProcessFailures)                  [Process Failures],  
   sum(sd.ProcessFailuresDowntime)               [Process Failures Downtime],  
--    AVG(sd.OverallUtilization)                 [Overall Utilization],        -- 2006-06-26 VMK Rev3.23, removed  
   AVG(sd.OverallMTBF)                   [Overall MTBF],  
   AVG(sd.OverallMTTR)                   [Overall MTTR],  
   AVG(r2)                       [R(2)],  
   Max(sd.CasesToPalletizer)                  [Cases To Palletizer],  
   sum(sd.UnitLoads)                    [Unit Loads],  
   -- 2006-06-26 VMK Rev3.23, moved these columns from above.  
   sum(sd.TotalUptime)                   [Total Uptime],  
   Sum(sd.OverallScheduledTime)                 [Overall Scheduled Time],  
   AVG(sd.OverallAvailability)                [Overall Availability],  
   AVG(sd.OverallReadiness)                 [Overall Readiness]  
   FROM   dbo.#SummaryData  sd with (nolock)  
--    LEFT JOIN dbo.Prod_Lines   pl  ON sd.PLId   = pl.PL_Id  -- 2005-Nov-22 VMK Rev3.2  
   LEFT JOIN @ProdLines    pl  ON sd.PLId   = pl.PLId    
   LEFT JOIN @MTDMinorStops   mtdms ON sd.PLId   = mtdms.PL_Id  
   WHERE pl.MachineType = @MachineTypePal  
      AND sd.Total IS NOT NULL  
 OPTION (KEEP PLAN)  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the Result Set for the stops by line by Reason   
 -- Level 1 (Failure Mode) for Palletizers.  
 -- This is record set #6  
 ---------------------------------------------------------------------------------------------------------------------------  
--  DECLARE @FMStops TABLE (  
--   Line        VARCHAR(100),  
--   FailureMode      VARCHAR(100),  
--   TotalStops      INTEGER,  
--   TotalMinorStops    INTEGER,  
--   FMGroup       VARCHAR(20) )  
--   
--  INSERT INTO @FMStops  
 SELECT  fmg.PLDesc               [Line],   
   CASE WHEN fmg.L1Reason IS NULL THEN '<blank>'   
    ELSE fmg.L1Reason   
    END                 [Failure Mode],   
   fmg.TotalStops              [Total Stops],   
   fmg.TotalMinorStops             [Total Minor Stops]  
--    'FMGroup'               [FMGroup]      -- 2006-06-26 VMK Rev3.23, added  
   FROM @FMGroup fmg  
   ORDER BY fmg.PLDesc ASC, fmg.TotalStops DESC, fmg.TotalMinorStops DESC  
 OPTION (KEEP PLAN)  
  
 -- 2006-06-26 VMK Rev3.23, added to include Impacted Department in Failure Mode totals.  
--  INSERT INTO @FMStops  
--  SELECT  'ImpDept'              [Line],  
--     imp.ImpDept               [Failure Mode],  
--     SUM(td.Stops)             [Total Stops],  
--     SUM(td.StopsMinor)           [Total Minor Stops],  
--     'ImpDept'              [FMGroup]      -- 2006-06-26 VMK Rev3.23, added  
--  FROM    dbo.#Delays       td  
--  LEFT JOIN @ProdUnitsImpDept     imp  ON td.LocationId   = imp.Source_PUId  
--  LEFT JOIN @ProdUnits       pu  ON td.PUId    = pu.PUId  
--  LEFT JOIN @ProdLines        pl  ON pu.PLId     =  pl.PLId  
--  WHERE pl.MachineType = @MachineTypeConv  
--    OR pl.MachineType = @MachineTypeConvMP  
--  GROUP BY imp.ImpDept  
--  ORDER BY imp.ImpDept  
  
  
--  SELECT  Line     [Line],   
--     FailureMode   [Failure Mode],   
--     TotalStops   [Total Stops],   
--     TotalMinorStops [Total Minor Stops],   
--     FMGroup    [FMGroup]  
--  FROM @FMStops  
--  OPTION (KEEP PLAN)  
  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the Percent Coded by Team Results.   
 -- This is record set #7  
 ---------------------------------------------------------------------------------------------------------------------------  
 SELECT td.Crew       [Team],  
    CASE WHEN CONVERT(FLOAT, (SUM(CASE WHEN (pueg.EquipGroup = 'Palletizer')  THEN  1  ELSE  0  END))) > 0 THEN   
     CONVERT(FLOAT, (SUM(CASE WHEN (td.L2ReasonId IS NOT NULL AND pueg.EquipGroup = 'Palletizer')  THEN  1  ELSE  0  END))) /  
      CONVERT(FLOAT, (SUM(CASE WHEN (pueg.EquipGroup = 'Palletizer')  THEN  1  ELSE  0  END)))  
    ELSE 0 END [Palletizer Percent Coded],  
    CASE WHEN CONVERT(FLOAT, (SUM(CASE WHEN (pueg.EquipGroup = 'Conveyor')   THEN 1 ELSE 0 END))) > 0 THEN   
     CONVERT(FLOAT, (SUM(CASE WHEN (td.L2ReasonId IS NOT NULL AND pueg.EquipGroup = 'Conveyor')   THEN 1 ELSE 0 END))) /  
      CONVERT(FLOAT, (SUM(CASE WHEN (pueg.EquipGroup = 'Conveyor')   THEN 1 ELSE 0 END)))  
    ELSE 0 END [Conveyor Percent Coded],  
    CASE WHEN SUM(CASE WHEN (pueg.EquipGroup = 'Palletizer' OR pueg.EquipGroup = 'Conveyor') THEN 1 ELSE 0 END) > 0 THEN  
     CONVERT(FLOAT, (SUM(CASE WHEN (td.L2ReasonId IS NOT NULL AND (pueg.EquipGroup = 'Conveyor' OR  
                 pueg.EquipGroup = 'Palletizer')) THEN 1 ELSE 0 END))) /  
      CONVERT(FLOAT, (SUM(CASE WHEN (pueg.EquipGroup = 'Palletizer' OR pueg.EquipGroup = 'Conveyor') THEN 1 ELSE 0 END)))  
    ELSE 0 END [Overall Percent Coded],  
    CASE WHEN SUM(CASE WHEN (pueg.EquipGroup = 'Palletizer' OR pueg.EquipGroup = 'Conveyor') THEN 1 ELSE 0 END) > 0 THEN  
     CONVERT(FLOAT, (SUM(CASE WHEN (er2.Event_Reason_Name = 'Other' AND (pueg.EquipGroup = 'Conveyor' OR  
                 pueg.EquipGroup = 'Palletizer')) THEN 1 ELSE 0 END))) /  
      CONVERT(FLOAT, (SUM(CASE WHEN (pueg.EquipGroup = 'Palletizer' OR pueg.EquipGroup = 'Conveyor') THEN 1 ELSE 0 END)))  
    ELSE 0 END [Percent Coded Other]  
 FROM   dbo.#Delays     td with (nolock)  
 LEFT JOIN @ProdUnitsEG  pueg ON td.LocationId = pueg.Source_PUId  
 LEFT JOIN dbo.Event_Reasons er2 with (nolock)  ON td.L2ReasonId  =  er2.Event_Reason_Id  
 WHERE td.Crew IS NOT NULL  
 GROUP BY td.Crew  
 ORDER BY td.Crew  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the Result Set for DDS by line and location for Conveyors.  
 -- This is record set #8  
 ---------------------------------------------------------------------------------------------------------------------------  
 SELECT COALESCE(imp.dept, 'Not Configured')              [Department],  
   --pl.PL_Desc              [Line],                  -- 2005-02-22 VMK Rev 8.76  
   --loc.PU_Desc              [Location],                 -- 2005-02-22 VMK Rev 8.76  
   Sum(Coalesce(td.Stops, 0))                  [Total Stops],       -- 2006-06-26 VMK Rev3.23, moved from below  
   Sum(td.ReportDownTime)                    [Total Downtime],      -- 2006-06-26 VMK Rev3.23, moved from below  
   Sum(Coalesce(td.StopsMinor, 0))                 [Minor Stops],  
   Sum(td.ReportMSDowntime)                   [Minor Stops Downtime],  
   Sum(Coalesce(td.StopsBreakdowns, 0))               [Equipment Failures],  
   Sum(td.ReportBDDowntime)                   [Equipment Failure Downtime],  
   Sum(Coalesce(td.StopsProcessFailures, 0))             [Process Failures],  
   Sum(td.ReportPFDowntime)                   [Process Failures Downtime],  
  
   CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN   
     (@TotalReportTime -  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /  
     sum(coalesce(td.Stops, 0))  
    ELSE 0   
    END                         [Overall MTBF],      -- 2006-07-10 VMK Rev3.24, moved from below  
   CASE  WHEN Sum(Coalesce(td.Stops, 0)) > 0 THEN SUM(td.ReportDowntime) / Sum(Coalesce(td.Stops, 0))  
    ELSE 0.00   
    END                         [Overall MTTR],      -- 2006-07-10 VMK Rev3.24, moved from below  
   CASE  WHEN (SUM(COALESCE(td.StopsBSUpTime2m, 0)) + SUM(COALESCE(td.Stops, 0))) > 0 THEN  
    (1 - (SUM(COALESCE(td.Uptime2m, 0)) / (SUM(COALESCE(td.StopsBSUpTime2m, 0)) +   
     SUM(COALESCE(td.Stops, 0)))))   
    ELSE 0   
    END                         [R(2)],         -- 2006-07-10 VMK Rev3.24, moved from below  
   @TotalReportTime - Sum(td.ReportDownTime)             [Total Uptime],  
   Sum(td.ReportSchedDowntime)                  [Overall Scheduled Time],  
   CASE WHEN (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) > 0 THEN   
     (@TotalReportTime -  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /   
     (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime))  
    ELSE 0.00   
    END                         [Overall Availability],  
-- 2006-06-26 VMK Rev3.23, removed  
--    CASE WHEN @TotalReportTime > 0 THEN   
--      (@TotalReportTime -  
--      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) / @TotalReportTime  
--     ELSE 0.00   
--     END                         [Overall Utilization],  
   CASE  WHEN (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime)) > 0 THEN  
     (@TotalReportTime - Sum(td.ReportDownTime)) /   
          (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime))   
    ELSE 0.00   
    END                         [Overall Readiness]  
   FROM  dbo.#Delays td with (nolock)  
   LEFT JOIN @ProdUnits   pu  ON td.PUId   = pu.PUId  
--    LEFT JOIN dbo.Prod_Units  pu  ON td.PUId    = pu.PU_Id  -- 2005-Nov-22 VMK Rev3.2  
--    LEFT JOIN dbo.Prod_Lines  pl  ON pu.PL_Id   = pl.PL_Id  -- 2005-Nov-22 VMK Rev3.2  
   LEFT JOIN @ProdRecords   pr  ON pu.PLId    =  pr.PLId  
   LEFT JOIN @ProdUnitsImpDept imp  ON td.LocationId  =  imp.Source_PUId  
--    LEFT JOIN dbo.Prod_Units  loc  ON td.LocationId  =  loc.PU_Id  -- 2005-Nov-22 VMK Rev3.2  
   LEFT JOIN @ProdLines    pl  ON pu.PLId    =  pl.PLId  
   WHERE pl.MachineType = @MachineTypeConv  
     OR pl.MachineType = @MachineTypeConvMP  
   GROUP BY imp.dept        --pl.PL_Desc, loc.PU_Desc, imp.dept  -- 2005-02-22 VMK Rev 8.76  
   ORDER BY imp.dept        --pl.PL_Desc, loc.PU_Desc     -- 2005-02-22 VMK Rev 8.76  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the stops result set for Total for Conveyors.  
 -- This is record set #9  
 ---------------------------------------------------------------------------------------------------------------------------  
 SELECT @TotalPALReportTime = count(PLId) * @TotalReportTime  
 FROM @ProdLines  
 WHERE MachineType = @MachineTypeConv  
   OR MachineType = @MachineTypeConvMP  
  
 SELECT 'Total'                        [Total],  
   ' '                          [Location],  
   Sum(Coalesce(td.Stops, 0))                  [Total Stops],      -- 2006-06-26 VMK Rev3.23, moved from below   
   Sum(td.ReportDownTime)                   [Total Downtime],     -- 2006-06-26 VMK Rev3.23, moved from below  
   Sum(Coalesce(td.StopsMinor, 0))                 [Minor Stops],  
   Sum(td.ReportMSDowntime)                   [Minor Stops Downtime],  
   Sum(Coalesce(td.StopsBreakdowns, 0))               [Equipment Failures],  
   Sum(td.ReportBDDowntime)                   [Equipment Failure Downtime],  
   Sum(Coalesce(td.StopsProcessFailures, 0))             [Process Failures],  
   Sum(td.ReportPFDowntime)                  [Process Failures Downtime],  
-- 2006-06-26 VMK Rev3.23, removed  
--    CASE WHEN @TotalReportTime > 0 THEN   
--      (@TotalPALReportTime -  
--      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) / @TotalPALReportTime  
--     ELSE 0.00   
--     END                         [Overall Utilization],  
   -- 2006-06-26 VMK Rev3.23, moved from above  
   CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN   
     (@TotalPALReportTime -  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /  
     sum(coalesce(td.Stops, 0))  
    ELSE 0   
    END                         [Overall MTBF],       -- 2006-07-10 VMK Rev3.24, moved from below  
   CASE WHEN (SUm(td.ReportDowntime) > 0 AND Sum(td.Stops) > 0) THEN  
   SUM(td.ReportDowntime) / Sum(Coalesce(td.Stops, 0))           
    ELSE 0  
    END                         [Overall MTTR],       -- 2006-07-10 VMK Rev3.24, moved from below  
   CASE WHEN (SUM(COALESCE(td.StopsBSUpTime2m, 0)) + SUM(COALESCE(td.Stops, 0))) > 0 THEN  
     (1 - (SUM(COALESCE(td.Uptime2m, 0)) / (SUM(COALESCE(td.StopsBSUpTime2m, 0)) +   
      SUM(COALESCE(td.Stops, 0)))))   
    ELSE 0   
    END                         [R(2)],          -- 2006-07-10 VMK Rev3.24, moved from below  
   @TotalPALReportTime - (SUM(td.ReportDowntime))            [Total Uptime],  
   Sum(td.ReportSchedDowntime)                  [Overall Scheduled Time],  
   CASE WHEN (@TotalPALReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) > 0 THEN   
     (@TotalPALReportTime -  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /   
     (@TotalPALReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime))  
    ELSE 0.00   
    END                         [Overall Availability],  
   CASE  WHEN (@TotalPALReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime)) > 0 THEN  
     (@TotalPALReportTime - Sum(td.ReportDownTime)) /   
          (@TotalPALReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime))   
    ELSE 0.00   
    END                         [Overall Readiness]  
   FROM  dbo.#Delays td with (nolock)  
    LEFT JOIN @ProdUnits  pu  ON td.PUId   = pu.PUId  
   LEFT JOIN @ProdLines    pl  ON pu.PLId    = pu.PLId  -- 2005-Nov-22 VMK Rev3.2  
   LEFT JOIN @ProdRecords   pr  ON pu.PLId    =  pr.PLId  
   LEFT JOIN @ProdUnitsImpDept imp  ON td.LocationId  = imp.Source_PUId  
   WHERE pl.MachineType = @MachineTypeConv  
     OR pl.MachineType = @MachineTypeConvMP  
   AND imp.ImpDept IS NOT NULL  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the Result Set for DDS by Impacted Department for Conveyors.  
 -- This is record set #10  
 ---------------------------------------------------------------------------------------------------------------------------  
  
 SELECT --COALESCE(imp.Dept, 'Not Configured') [Department],     -- 2005-02-22 VMK Rev 8.76  
   COALESCE(imp.ImpDept, 'Not Configured')              [Department Impacted],  
   Sum(Coalesce(td.Stops, 0))                  [Total Stops],      -- 2006-06-26 VMK Rev3.23, moved from below  
   Sum(td.ReportDownTime)                    [Total Downtime],     -- 2006-06-26 VMK Rev3.23, moved from below  
   Sum(Coalesce(td.StopsMinor, 0))                 [Minor Stops],  
   Sum(td.ReportMSDowntime)                   [Minor Stops Downtime],  
   Sum(Coalesce(td.StopsBreakdowns, 0))               [Equipment Failures],  
   Sum(td.ReportBDDowntime)                   [Equipment Failure Downtime],  
   Sum(Coalesce(td.StopsProcessFailures, 0))             [Process Failures],  
   Sum(td.ReportPFDowntime)                   [Process Failures Downtime],  
-- 2006-06-26 VMK Rev3.23, removed  
--    CASE WHEN @TotalReportTime > 0 THEN   
--      (@TotalReportTime -  
--      sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) / @TotalReportTime  
--     ELSE 0.00   
--     END                         [Overall Utilization],  
   CASE  WHEN sum(coalesce(td.Stops, 0)) > 0 THEN   
     (@TotalReportTime -  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /  
     sum(coalesce(td.Stops, 0))  
    ELSE 0   
    END                         [Overall MTBF],  
   CASE  WHEN Sum(Coalesce(td.Stops, 0)) > 0 THEN SUM(td.ReportDowntime) / Sum(Coalesce(td.Stops, 0))  
    ELSE 0.00   
    END                         [Overall MTTR],  
   CASE  WHEN (SUM(COALESCE(td.StopsBSUpTime2m, 0)) + SUM(COALESCE(td.Stops, 0))) > 0 THEN  
    (1 - (SUM(COALESCE(td.Uptime2m, 0)) / (SUM(COALESCE(td.StopsBSUpTime2m, 0)) +   
     SUM(COALESCE(td.Stops, 0)))))   
    ELSE 0   
    END                         [R(2)],  
   -- 2006-06-26 VMK Rev3.23, moved from above  
   @TotalReportTime - Sum(td.ReportDownTime)             [Total Uptime],  
   Sum(td.ReportSchedDowntime)                  [Overall Scheduled Time],  
   CASE WHEN (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) > 0 THEN   
     (@TotalReportTime -  
     sum(td.ReportDownTime) - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime)) /   
     (@TotalReportTime - sum(td.ReportBlockedDowntime) - sum(td.ReportStarvedDowntime))  
    ELSE 0.00   
    END                         [Overall Availability],  
   CASE  WHEN (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime)) > 0 THEN  
     (@TotalReportTime - Sum(td.ReportDownTime)) /   
          (@TotalReportTime - Sum(td.ReportDownTime) + Sum(td.ReportUnschedDowntime))   
    ELSE 0.00   
    END                         [Overall Readiness]  
   FROM  dbo.#Delays td with (nolock)  
--    LEFT JOIN dbo.Prod_Units  pu  ON td.PUId    = pu.PU_Id  -- 2005-Nov-22 VMK Rev3.2  
--    LEFT JOIN dbo.Prod_Lines  pl  ON pu.PL_Id   = pl.PL_Id  -- 2005-Nov-22 VMK Rev3.2  
   LEFT JOIN @ProdUnits   pu  ON td.PUId   = pu.PUId  
   LEFT JOIN @ProdLines    pl  ON pu.PLId    =  pl.PLId   
   LEFT JOIN @ProdRecords   pr  ON pu.PLId    =  pr.PLId   -- 2005-Nov-22 VMK Rev3.2  
--    LEFT JOIN dbo.Prod_Units  loc  ON td.LocationId  =  loc.PU_Id  -- 2005-Nov-22 VMK Rev3.2  
   LEFT JOIN @ProdUnitsImpDept imp  ON td.LocationId  =  imp.Source_PUId  
   WHERE pl.MachineType = @MachineTypeConv  
     OR pl.MachineType = @MachineTypeConvMP  
--   AND imp.ImpDept IS NOT NULL  
   GROUP BY imp.ImpDept       --imp.dept, imp.ImpDept     -- 2005-02-22 VMK Rev 8.76  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the stops result set for MTD Line Data for Unit Loads.  
 -- This is record set #11  
 ---------------------------------------------------------------------------------------------------------------------------  
  
 SELECT  CASE WHEN (GROUPING(pl_desc) = 1) THEN   
     'TOTAL'  
    ELSE   
     ISNULL(pl_desc, 'UNKNOWN')  
    END AS LINE,  
    SUM(TOTROWS) [MTD UNIT LOAD BY LINE]  
 FROM @MTDLineData mtdl  
 WHERE var_desc = 'Pallets Exiting SW'  
 GROUP BY pl_desc WITH ROLLUP  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the summary result set for Summary Palletizers/ATLS/APTS  
 -- This is record set #12  
 ---------------------------------------------------------------------------------------------------------------------------  
 SELECT ' '                        [Summary Total],  
   sum(sd.MinorStops)                   [Minor Stops],  
   Sum(Coalesce(sd.EquipmentFailure, 0))              [Equipment Failures],  
   Sum(Coalesce(sd.ProcessFailures, 0))             [Process Failures],  
-- 2006-06-26 VMK Rev3.23, removed  
--    CASE WHEN (@TotalCasesToPalletizer > 0 AND sum(sd.MinorStops) > 0) THEN  
--    convert(float,convert(float,sum(sd.MinorStops))/@TotalCasesToPalletizer)*1000  
--         ELSE 0.00  
--         END              [Palletizer/ATLS/APTS Daily Stops/1000 Cases],  
   CASE WHEN (@TotalPalletsExitSW > 0 AND sum(sd.MinorStops) > 0) THEN  
   convert(float,convert(float,sum(sd.MinorStops))/@TotalPalletsExitSW)*1000  
        ELSE 0.00                            -- 2006-06-26 VMK Rev3.23, changed column name.  
        END                       [Total Stops/1000 Unit Loads],    --[Palletizer/ATLS/APTS Daily Stops/1000 Unit Loads],  
-- 2006-06-26 VMK Rev3.23, removed  
--    CASE WHEN MAX(mtdms.MinorStops) > 0 AND sum(cast(sd.baselinenum as float)) > 0 THEN  
--     1 - ((MAX(mtdms.MinorStops)) / (SUM(CAST(sd.baselinenum AS FLOAT)) * @DaysIntoMonth))  -- VMK 2005-01-12 Changed Minor Stops Reduction Calc.  
--    ELSE 0.00  
--    END                [Palletizer/ATLS/APTS Daily Minor Stop % Reduction],  
--    CASE WHEN (@MTDTOTROWS > 0 AND sum(sd.MinorStops) > 0) THEN  
--    convert(float,convert(float,(sum(sd.MinorStops)*1000))/@MTDTOTROWS)*1000  
--         ELSE 0.00  
--         END              [Palletizer/ATLS/APTS MTD Minor Stops/1000 Cases],  
   CASE WHEN (@TotalPalletsExitSW > 0 AND sum(sd.MinorStops) > 0) THEN  
   convert(float,convert(float,sum(sd.MinorStops))/@TotalPalletsExitSW)*1000  
        ELSE 0.00                            -- 2006-06-26 VMK Rev3.23, changed column name.  
        END                       [Total MTD Minor Stops/1000 Unit Loads],   --[Palletizer/ATLS/APTS MTD Minor Stops/1000 Unit Loads],  
-- 2006-06-26 VMK Rev3.23, removed  
--    CASE WHEN @MTDTOTALROWS > 0 AND sum(cast(sd.baselinenum as float)) > 0 THEN  
--     1 - ((@DaysInMonth)/@DaysIntoMonth*(@MTDTOTALROWS/(sum(cast(sd.baselinenum as float)))))  
--    ELSE 0.00  
--    END                [Palletizer/ATLS/APTS MTD Minor Stop % Reduction]  
   SUM(pr.PalletsExitSW)                  [Total Unit Loads]          -- 2006-06-26 VMK Rev3.23, added  
   FROM    dbo.#summarydata   sd with (nolock)  
--    LEFT JOIN dbo.Prod_Lines  pl  ON sd.PLId = pl.PL_Id  -- 2005-Nov-22 VMK Rev3.2  
   LEFT JOIN @ProdLines    pl  ON sd.PLId  =  pl.PLId  
   LEFT JOIN @MTDMinorStops  mtdms ON sd.PLId = mtdms.PL_Id  
   LEFT JOIN @ProdRecords   pr  ON pl.PLId =  pr.PLId  
   WHERE pl.MachineType = @MachineTypePal  
      AND sd.Total IS NOT NULL  
 OPTION (KEEP PLAN)  
  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the downtime event detail data.   
 -- This is record set #13  
 ---------------------------------------------------------------------------------------------------------------------------  
 IF @IncludeStopsPivot = 0  
  SELECT pl.PLDesc                  [Production Line],  -- 2005-Nov-22 VMK Rev3.2  
   Convert(VarChar(25), td.StartTime, 101)          [Start Date],  
   Convert(VarChar(25), td.StartTime, 108)          [Start Time],  
   Convert(VarChar(25), td.EndTime, 101)           [End Date],  
   Convert(VarChar(25), td.EndTime, 108)           [End Time],  
   pu.PUDesc                    [Master Unit],    -- 2005-Nov-22 VMK Rev3.2  
--    pu.PU_Desc [Master Unit],   -- 2005-Nov-22 VMK Rev3.2  
   loc.PU_Desc                   [Location],  
   er1.Event_Reason_Name                [Failure Mode],  
   er2.Event_Reason_Name                [Failure Mode Cause],  
   p.Prod_Code                   [Product],  
   p.Prod_Desc                   [Product Desc],  
   tef.TEFault_Name                  [Fault Desc],  
   td.LineStatus                   [Line Status],  
   SubString(erc1.ERC_Desc, CharIndex(':', erc1.ERC_Desc) + 1, 50)  [Schedule],  
   SubString(erc2.ERC_Desc, CharIndex(':', erc2.ERC_Desc) + 1, 50)  [Category],  
   SubString(erc3.ERC_Desc, CharIndex(':', erc3.ERC_Desc) + 1, 50)  [SubSystem],  
   SubString(erc4.ERC_Desc, CharIndex(':', erc4.ERC_Desc) + 1, 50)  [GroupCause],  
   td.Shift                    [Shift],  
   td.Crew                     [Team],  
   pu.DelayType                   [Event Location Type],  
   CASE WHEN (td.TEDetId = td.PrimaryId)THEN   
    'Primary'   
   ELSE 'Secondary' END                [Event Type],  
   Convert(Int, '1')                 [Total Causes],  
   td.DownTime                   [Total DownTime],  --Changed to min NHK  
   td.ReportDownTime                 [Total Event DownTime],  --Changed to min  
   td.UpTime                    [Total UpTime],  --Changed to min  
   td.ReportUpTime                  [Total Event UpTime], --Changed to min  
   Coalesce(td.Stops, 0)                [Total Stops],  
   Coalesce(td.StopsMinor, 0)              [Minor Stops],  
   Coalesce(td.StopsBreakdowns, 0)             [Equipment Failure],  
   Coalesce(td.StopsProcessFailures, 0)           [Process Failures],  
   Coalesce(td.StopsBlockedStarved, 0)           [Total Blocked Starved],  
   pueg.EquipGroup                  [Equipment Group],   
   ''                      [Zone],  
   pueg.Equip                    [Equipment],  
   Comment  
   FROM   dbo.#Delays td with (nolock)  
   JOIN   @ProdUnits        pu  ON td.PUId     =  pu.PUId  
   LEFT JOIN @ProdLines       pl  ON pu.PLId    = pl.PLId  
   JOIN   @ProdUnitsEG       pueg  ON td.LocationId   =  pueg.Source_PUId  
--    JOIN   dbo.Prod_Units      pu  ON td.PUId     = pu.PU_Id  
--    JOIN   dbo.Prod_Lines      pl  ON pu.PL_Id    = pl.PL_Id  
   JOIN   dbo.Products       p with (nolock)   ON td.ProdId    =  p.Prod_Id  
   LEFT JOIN dbo.Event_Reason_Catagories  erc1 with (nolock)  ON td.ScheduleId   =  erc1.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories  erc2 with (nolock)  ON td.CategoryId   =  erc2.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories  erc3 with (nolock)  ON td.SubSystemId  =  erc3.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories  erc4 with (nolock)  ON td.GroupCauseId  =  erc4.ERC_Id  
   LEFT JOIN dbo.Prod_Units      loc with (nolock)  ON td.LocationId   =  loc.PU_Id  
   LEFT JOIN dbo.Event_Reasons     er1 with (nolock)  ON td.L1ReasonId   =  er1.Event_Reason_Id  
   LEFT JOIN dbo.Event_Reasons     er2 with (nolock)  ON td.L2ReasonId   =  er2.Event_Reason_Id  
   LEFT JOIN dbo.Event_Reasons     er3 with (nolock)  ON td.L3ReasonId   =  er3.Event_Reason_Id  
   LEFT JOIN dbo.Event_Reasons     er4 with (nolock)  ON td.L4ReasonId   =  er4.Event_Reason_Id  
   LEFT  JOIN  dbo.Timed_Event_Fault    tef with (nolock)  on (td.TEFaultID   =  TEF.TEFault_ID)  
   ORDER  BY pl.PLDesc, td.Starttime  
  OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the Result Set for Palletizer Summary Data.  
 -- This is record set #14  
 ---------------------------------------------------------------------------------------------------------------------------  
 SELECT sum(sd.MinorStops)           [Minor Stops],  
    Sum(sd.EquipmentFailure)          [Equipment Failures],  
    Sum(sd.ProcessFailures)          [Process Failures],  
    sum(sd.TotalStops)           [Total Stops],  
    sum(sd.TotalDowntime)          [Total Downtime],  
    Sum(sd.OverallScheduledTime)         [Overall Scheduled Time],  
    Sum(sd.CasesToPalletizer)          [Cases To Palletizer],  
    sum(sd.UnitLoads)            [Unit Loads]  
   FROM   dbo.#SummaryData  sd with (nolock)  
   LEFT JOIN dbo.Prod_Lines pl with (nolock)  ON sd.PLId   = pl.PL_Id  
   LEFT JOIN @ProdLines  ppl ON sd.PLId   = ppl.PLId  
   WHERE ppl.MachineType = @MachineTypePal  
      AND sd.Total IS NOT NULL  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the Result Set for ATLS/APTS Summary Data.  
 -- This is record set #15  
 ---------------------------------------------------------------------------------------------------------------------------  
 SELECT sum(td.StopsMinor)           [Minor Stops],  
    Sum(td.StopsBreakdowns)          [Equipment Failures],  
    Sum(td.StopsProcessFailures)        [Process Failures],  
    sum(td.Stops)             [Total Stops],  
    sum(td.ReportDowntime)          [Total Downtime],  
    Sum(td.ReportSchedDowntime)         [Overall Scheduled Time],  
    Sum(sd.CasesToPalletizer)          [Cases To Palletizer],  
    sum(sd.UnitLoads)            [Unit Loads]  
   FROM   dbo.#Delays   td with (nolock)  
   LEFT JOIN dbo.Prod_Units pu with (nolock)  ON td.PUId   = pu.PU_Id  
   LEFT JOIN dbo.Prod_Lines pl with (nolock)  ON pu.PL_Id   = pl.PL_Id  
   LEFT JOIN @ProdLines  ppl ON pu.PL_Id   = ppl.PLId  
   LEFT JOIN dbo.#SummaryData sd with (nolock)  ON pu.PL_Id   = sd.PLId  
  WHERE pl.PL_Desc LIKE '%ATLS%' OR pl.PL_Desc LIKE '%APTS%'  
 OPTION (KEEP PLAN)  
  
 ---------------------------------------------------------------------------------------------------------------------------  
 -- Return the Result Set for Conveyor Summary Data.  
 -- This is record set #16  
 ---------------------------------------------------------------------------------------------------------------------------  
 SELECT sum(sd.MinorStops)           [Minor Stops],  
    Sum(sd.EquipmentFailure)          [Equipment Failures],  
    Sum(sd.ProcessFailures)          [Process Failures],  
    sum(sd.TotalStops)           [Total Stops],  
    sum(sd.TotalDowntime)          [Total Downtime],  
    Sum(sd.OverallScheduledTime)         [Overall Scheduled Time]     
 FROM   dbo.#SummaryData  sd with (nolock)  
 LEFT JOIN dbo.Prod_Lines pl with (nolock)  ON sd.PLId   = pl.PL_Id  
 LEFT JOIN @ProdLines  ppl ON sd.PLId   = ppl.PLId  
 WHERE (ppl.MachineType = @MachineTypeConv  
    OR ppl.MachineType = @MachineTypeConvMP)  
      AND sd.Total IS NOT NULL  
 OPTION (KEEP PLAN)  
  
 -----------------------------------------------------------------------------  
 -- 2005-Nov-23 Vince King Rev3.2  
 -- Result Set containing Report Parameter Values.  This RS is used when  
 -- Report Parameter values are required within the Excel Template.  
 -- This is record set #17  
 -----------------------------------------------------------------------------  
 SELECT  
  @StartTime        [@StartTime],  
  @EndTime         [@EndTime],  
  @RptName         [@RptName],  
  @RptTitle        [@RptTitle],  
  @ProdLinePalList       [@ProdLinePalList],  
  @ProdLineConvList      [@ProdLineConvList],  
  @DelayTypeList       [@DelayTypeList],  
  @UserName        [@RptUser],  
  @RptPageOrientation     [@RptPageOrientation],    
  @RptPageSize       [@RptPageSize],  
  @RptTimeout        [@RptTimeout],  
  @RptFileLocation      [@RptFileLocation],  
  @RptConnectionString     [@RptConnectionString]  
  
-- print 'End of Result Sets: ' + Convert(VarChar(25),GetDate(),108)  
  
SET NOCOUNT OFF  
  
Finished:  
  
 DROP TABLE dbo.#Delays  
 DROP TABLE dbo.#Tests  
 DROP  TABLE dbo.#SummaryData  
  
Return  
  
  
