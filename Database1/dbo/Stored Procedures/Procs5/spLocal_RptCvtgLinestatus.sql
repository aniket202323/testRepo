  
  
/*    
  
--------------------------------------------------------------------------------------------------------------------------------------------------------  
--  
--  Version 7.04 2009-11-16 Jeff Jaeger  
--  
  
--  This SP replaced 'spLocal_ViewCvtgDDS' it will gather data for the specified date/time range for a program to display Line Status  
--  data for Proficy Client computers. The data provided is:  
-- 1.  Stops data by line.    
-- 2.  Production data by line.  
--  This SP is from spLocal_RptCvtgDDSStop 8.68 and cut down.  
--  
--  Key changes from the version this sp replaces are:  
--  1. Replaced all temporary tables with table variables.  
--  2. Eliminated as many ursors as possibble.  
-- 3. Modifications to correctly account for handpack production in Neuss Hankies.  
-- 4. Alignment fo various measures with changes/corrections made in the DDS-Stops report over the past 12 months, e.g., Unplanned MTBF.  
-- 5. SP name is changed (spLocal_ViewCvtgDDS to spLocal_RptCvtgLinestatus).  
  
--  Average speed and Target speed data is added.  
--  Parameter is modified for AZ in .xls file.  
--  Add Trim in 'strServerName = Trim(Sheets(shtParameter).Cells(1, 2))'  
--  Changed error handling to save error file in C:drive.  
--  
-- Version 6.1 2004-11-30 Namho Kim  
--  Change 'Create table' to 'Declare table'  
--  
-- Version 6.2 2004-12-06 Namho Kim   
-- Delete useless variables in Delays table.  
--  
-- Version 6.3 2004-12-07 Namho Kim  
-- Change Taget speed return result set to get correct average speed, using time weight Average.  
-- Declare new variable 'Duration', 'TgtSpeedxDuration'  
--  
--Version 6.4 2005-03-25 Namho Kim  
--Added Report Downtime data in Stop data  
--  
--Version 6.5 2005-03-31 Namho Kim  
--Added "Overall Availability" data in Stop data.  
  
--2007-06-22 Jeff Jaeger Rev6.6  
--  - added @VarLinespeedMMinVN related code.  
  
--2007-JUL-02 Langdon Davis Rev6.7  
--  -  Corrected a typo where Jeff had left out an '@' in the code added for the above change.  
  
--2007-OCT-05 Langdon Davis Rev6.8  
--  -  Added a restriction of matching on product ID to the JOIN for the production result  
--   set.  Without it, production values were getting multiplied by the number of products  
--   run in the shift.  
  
2008-09-24 Jeff Jaeger  Rev6.9  
 - brought this sp up to date with the current methods used in DDS Stops.    
  this work was done by starting with DDS Stops as a base line.  
  
2008-10-17 Jeff Jaeger  Rev6.91  
 - changed the definition of StartTime_Line and EndTime_Line in #SplitPRsRun so they are based on PUID and   
  not PLID.  This is done because the final summaries are restricted to just the Converter   
  Reliability unit.  
 -  renamed tables and fields with _Line designation to use a _Unit designation to match the change in grouping  
  criteria.  
  
2008-10-20 Jeff Jaeger  Rev6.92  
 - added an "or pdm.puid = pl.ratelosspuid" clause to the first result set... this will allow rateloss values   
  to be included in the results.  
  
2008-10-22 Jeff Jaeger Rev6.93  
- modified the Facial FFF1 special special update to PEIID in #PRsRun so that it only runs if the site   
 executing the code is GB... this will need to be added to all of the reports.  
  
2008-10-28 Jeff Jaeger Rev6.94  
- changed the way that Converter Reliability and Converter Blocked/Starved data are combined to better reflect   
 approach used in DDS Stops.  this required changes to the Report Uptime calculation in the first result set   
 and the inclusion of 'Convert Blocked/Starved' in determining types of stops in #delays.  note that this report   
 only requires Converter Reliability and the matching Blocked/Starved unit, where DDS Stops handles multiple unit  
 pairs.  this allowed a more simplified code in this sp.  
- made changes to the second result set to match how this production data is returned in DDS Stops.  
  
2008-12-03 Jeff Jaeger Rev6.95  
- converted ELPMetrics_Unit and ProdLines to table variables.  
  
2008-12-31 Jeff Jaeger Rev6.96  
- updated the way HolidayCurtailDT is compiled for the result sets.  
- modified updates to group by start and end times to make them more efficient.  
- added "with (nolock)" to the use of temp tables in select statements.  
- updated the aliases used in correlated updates.  
  
2009-02-05 Jeff Jaeger Rev6.97  
- modified the definition of StopsUnscheduled, StopsMinor, StopsEquipFails, and   
 StopsProcessFailures in #Delays  
  
2009-02-16 Jeff Jaeger Rev6.98  
- modified the method for pulling ScheduleID, CategoryID, GroupCauseID, and SubsystemID in #delays.  
  
2009-03-02 Jeff Jaeger Rev6.99  
- modified the definition of SplitUnscheduledDT  
- restricted the population of @produnits to exclude "z_obs"  
  
2009-03-17 Jeff Jaeger Rev7.00  
- modified the definitions of various flavors of stops in #Delays  
- modified the definition of SplitUnscheduledDT in #SplitDowntimes  
  
2009-04-09 Jeff Jaeger Rev7.01  
 - added a restriction on pu_desc not like '%rate%loss%' in the definition of SplitELPSchedDT.  
  
2009-04-21 Jeff Jaeger Rev7.02  
 - modified the WHERE clause of the delete from #Tests that immediately follows the insert to that temp table.  
  the original clause appears to be no longer working under SQL Server 2005.  
  
2009-08-11 Jeff Jaeger Rev7.03  
- Modified the update to ShiftStart in @runs.  
  
2009-11-16 Jeff Jaeger Rev7.04  
- modified the assignment of LineSpeedAvg in #SplitUptime.  
  
  
---------------------------------------------------------------------------------------------------------------------------------------------------------    
  
*/  
  
CREATE PROCEDURE dbo.spLocal_RptCvtgLinestatus  
--declare  
  @StartTime     datetime,    
 @EndTime      datetime,    
 @ProdLineList    varchar(4000), -- Collection of Prod_Lines.PL_Id for converting lines delimited by "|".  
 @DelayTypeList    varchar(4000), -- Collection of "DelayType=..." from Prod_Units.Extended_Info delimited by "|".  
 @ScheduleStr    varchar(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CategoryStr    varchar(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @GroupCauseStr    varchar(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @SubSystemStr    varchar(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CatMechEquipId   int,    -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
 @CatElectEquipId   int,    -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
 @CatProcFailId    int,    -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
 @CatBlockStarvedId  int,    -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved.  
 @CatELPId     int,    -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
 @SchedPRPolyId    int,    -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
 @SchedUnscheduledId  int,    -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
 @SchedSpecialCausesId int,    -- Event_Reason_Categories.ERC_Id for Schedule:Special Causes.  
 @SchedEOProjectsId  int,    -- Event_Reason_Categories.ERC_Id for Schedule:E.O./Projects.  
 @SchedBlockedStarvedId int,    -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
 @SchedHolidayCurtailId int,    -- Event_Reason_Categories.ERC_Id for Schedule:Holiday/Curtail.  
 @DelayTypeRateLossStr varchar(100), -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
 @PropCvtgProdFactorId int,    -- Product_Properties.Prop_Id for Property containing Stat Factor         -- Spec variable for the business.  
 @DefaultPMRollWidth  float,   -- Default PM Roll Width.  Used when actual PM Roll  
              -- Width's are not available through genealogy.  
 @ConvertFtToMM    float,   -- Conversion to change feet to mm., i.e. value is 304.8   
              -- (12 in/ft * 2.54 cm/in * 10 mm/cm) 1 is already using metric.  
 @ConvertInchesToMM  float,   -- Conversion to change inches to millimeters. Value is 25.4 to  
              -- to convert or 1 if already using metric.  
 @BusinessType    int        -- 1=Tissue/Towel, 2=Napkins, 3=Facial  
   
AS  
  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
/*  
--OX  
Select    
@StartTime         = '2009-08-07 00:00:00', --05:00:00',  
@EndTime         = '2009-08-08 00:00:00', --05:00:00',  
@ProdLineList        = '17', --'17|18|26|30', --'2|4',  
@DelayTypeList       = 'CvtrDowntime|Downtime|RateLoss',  
@ScheduleStr        = 'Schedule',  
@CategoryStr        = 'Category',  
@GroupCauseStr       = 'GroupCause',  
@SubSystemStr        = 'Subsystem',  
@CatMechEquipId      = 182,  
@CatElectEquipId       = 184,  
@CatProcFailId       = 185, -----  
@CatBlockStarvedId      = 250,  
@CatELPId         = 257,  
@SchedPRPolyId       = 260,  
@SchedUnscheduledId      = 190,  
@SchedSpecialCausesId     = 258,  
@SchedEOProjectsId      = 194,  
@SchedBlockedStarvedId     = 251,  
@SchedHolidayCurtailId    = 193,  
@DelayTypeRateLossStr     = 'RateLoss',  
@PropCvtgProdFactorId     = 22, --3,  
@DefaultPMRollWidth      = 101.3, --840,  
@ConvertFtToMM       = 304.80000000000001, --1,  
@ConvertInchesToMM      = 25.399999999999999, --1,  
@BusinessType        = 1 --4  
*/  
  
/*  
--GB  
Select    
@StartTime         = '2008-11-01 06:30:00',  
@EndTime         = '2008-11-02 06:30:00',  
@ProdLineList        = '44', -- '21', --   
@DelayTypeList       = 'Downtime|CvtrDowntime|RateLoss|BlockedStarved',  
@ScheduleStr        = 'Schedule',  
@CategoryStr        = 'Category',  
@GroupCauseStr       = 'GroupCause',  
@SubSystemStr        = 'Subsystem',  
@CatMechEquipId      = 106,  
@CatElectEquipId       = 110,  
@CatProcFailId       = 111, -----  
@CatBlockStarvedId      = 101,  
@CatELPId         = 167,  
@SchedPRPolyId       = 116,  
@SchedUnscheduledId      = 108,  
@SchedSpecialCausesId     = 187,  
@SchedEOProjectsId      = 123,  
@SchedBlockedStarvedId     = 103,  
@SchedHolidayCurtailId    = 124,  
@DelayTypeRateLossStr     = 'RateLoss',  
@PropCvtgProdFactorId     = 14, --3,  
@DefaultPMRollWidth      = 101.3, --840,  
@ConvertFtToMM       = 304.80000000000001, --1,  
@ConvertInchesToMM      = 25.399999999999999, --1,  
@BusinessType        = 3 --4  
*/  
  
/*  
--MP  
Select    
@StartTime         = '2008-10-17 07:00:00',  
@EndTime         = '2008-10-20 07:00:00',  
@ProdLineList        = '184', --'17|18|26|30', --'2|4',  
@DelayTypeList       = 'CvtrDowntime|Downtime|RateLoss',  
@ScheduleStr        = 'Schedule',  
@CategoryStr        = 'Category',  
@GroupCauseStr       = 'GroupCause',  
@SubSystemStr        = 'Subsystem',  
@CatMechEquipId      = 101,  
@CatElectEquipId       = 105,  
@CatProcFailId       = 106, -----  
@CatBlockStarvedId      = 260,  
@CatELPId         = 181,  
@SchedPRPolyId       = 193,  
@SchedUnscheduledId      = 103,  
@SchedSpecialCausesId     = 222,  
@SchedEOProjectsId      = 261,  
@SchedBlockedStarvedId     = 179,  
@SchedHolidayCurtailId    = 120,  
@DelayTypeRateLossStr     = 'RateLoss',  
@PropCvtgProdFactorId     = 528, --3,  
@DefaultPMRollWidth      = 101.3, --840,  
@ConvertFtToMM       = 304.80000000000001, --1,  
@ConvertInchesToMM      = 25.399999999999999, --1,  
@BusinessType        = 1 --4  
*/  
  
----------------------------------------------------------  
-- Section 1:  Define variables for this procedure.  
----------------------------------------------------------  
  
-------------------------------------------------------------------------  
-- Report Parameters. 2005-03-16 VMK Rev8.81  
-------------------------------------------------------------------------  
DECLARE   
--@ProdLineList     VARCHAR(4000),  -- Collection of Prod_Lines.PL_Id for converting lines delimited by "|".  --@DelayTypeList     VARCHAR(4000),  -- Collection of "DelayType=..." FROM Prod_Units.Extended_Info delimited by "|".  
--@CatMechEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
--@CatElectEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
--@CatProcFailId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
--@CatBlockStarvedId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved. --FLD 07-NOV-2007 Rev11.54  
--@CatELPId      INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
--@SchedPRPolyId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
--@SchedUnscheduledId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
--@SchedSpecialCausesId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Special Causes.  
--@SchedEOProjectsId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:E.O./Projects.  
--@SchedBlockedStarvedId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
@SchedChangeOverId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Changeover.  
@SchedPlnInterventionId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Planned Intervention.  
--@SchedHolidayCurtailId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Holiday/Curtail.  
@SchedHygCleaningId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Planned Hygiene/Cleaning.  
@SchedCLAuditsId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Centerline Checks/Audits.  
--@PropCvtgProdFactorId  INTEGER,    -- Product_Properties.Prop_Id for Property containing Stat Factor           
--@DefaultPMRollWidth   FLOAT,    -- Default PM Roll Width.  Used when actual PM Roll  
               -- Width's are not available through genealogy.  
--@ConvertFtToMM     FLOAT,    -- Conversion to change feet to mm., i.e. value is 304.8   
               -- (12 in/ft * 2.54 cm/in * 10 mm/cm) 1 is already using metric.  
--@ConvertInchesToMM   FLOAT,    -- Conversion to change inches to millimeters. Value is 25.4 to  
               -- to convert or 1 if already using metric.  
--@BusinessType     INTEGER,    -- 1=Tissue/Towel, 2=Napkins, 3=Facial  
--@IncludeTeam     INTEGER,    -- 1=Report Team Breakdown; 0=No Team Breakdown.  
--@IncludeStops     INTEGER,    -- 0 = Do not include Stops Pivottable; 1 = Include Stops Pivottable.  
--@BySummary      INTEGER,    -- 0 = Do not include additional Stops sheets; 1 = Include additional Stops sheets.  
--@RL1Title      VARCHAR(100),  -- Title to be used for Reason Level 1  
--@RL2Title      VARCHAR(100),  -- Title to be used for Reason Level 2  
--@RL3Title      VARCHAR(100),  -- Title to be used for Reason Level 3  
--@RL4Title      VARCHAR(100),  -- Title to be used for Reason Level 4  
--@PackPUIdList     VARCHAR(4000),  -- List of Prod_Units.PU_Ids, FROM a 'Pack' Prod Line, to be included in the Pack Prod sheet.  
@UserName      VARCHAR(30),  -- User calling this report  
--@RptTitle      VARCHAR(300),  -- Report title from Web Report.  
--@RptPageOrientation   VARCHAR(50),  -- Report Page Orientation from Web Report.  
--@RptPageSize     VARCHAR(50),   -- Report page Size from Web Report.  
--@RptPercentZoom    INTEGER,    -- Percent Zoom from Web Report.  
--@RptTimeout      VARCHAR(100),  -- Report Time from Web Report.  
--@RptFileLocation    VARCHAR(300),  -- Report file location from WEb Report.  
--@RptConnectionString   VARCHAR(300),  -- Connection String from Web Report.  
--@RptGroupBy      INTEGER,    -- Group By parameter from Web Report.  
--@LineStatusList    VARCHAR(4000),  -- List of valid Line Status values.  If NULL, use all values.  
--@RptWindowMaxDays    INTEGER,    -- Maximum number of days allowed in the date range specified for a given report.  
------------------------------------------  
-- declare program variables  
------------------------------------------  
--@ScheduleStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
--@CategoryStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
--@GroupCauseStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
--@SubSystemStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
--@DelayTypeRateLossStr  VARCHAR(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
  
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
@VarLineSpeedMMinVN   varchar(50), -- Rev11.45  
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
@TPUnitsFlag     VARCHAR(50), --Namho  
  
@Row        int,  
@Rows        int,  
@@PUID       int,  
@@StartTime      datetime,  
@Max_TEDet_Id      int,  
@Min_TEDet_Id     int,   
@RangeStartTime    datetime,   
@RangeEndTime     datetime,  
  
@ScheduleUnit      int,  
  
@LineSpeedTargetSpecDesc  varchar(50),  
@LineSpeedIdealSpecDesc  varchar(50),  
  
@PUEquipGroupStr    VARCHAR(100),  
          
@NoDataMsg       VARCHAR(100),  
@TooMuchDataMsg     VARCHAR(100),  
@NoTeamInfoMsg     varchar(100),  
  
--Rev11.55  
@RunningStatusID     int,  
  
@VarInputRollVN    varchar(50),  
@VarInputPRIDVN    varchar(50)  
  
  
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
  
--IF Len(@RptName) > 0   
-- BEGIN  
-- --print 'Get Report Parameters.'  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPLIdList','',      @ProdLineList OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptDlyTypeList', '',     @DelayTypeList OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPropCvtgProdFactorId','',  @PropCvtgProdFactorId OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptDefaultPMRollWidth','',   @DefaultPMRollWidth OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConvertFtToMM', '',    @ConvertFtToMM OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConvertInchesToMM', '',   @ConvertInchesToMM OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptBusinessType', '',    @BusinessType OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptIncludeTeam', '',     @IncludeTeam OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptIncludeStops', '',    @IncludeStops OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptSummary', '',      @BySummary OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL1Title', '',      @RL1Title OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL2Title', '',      @RL2Title OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL3Title', '',      @RL3Title OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL4Title', '',      @RL4Title OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPackPUIdList', '',    @PackPUIdList OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'Owner', '',         @UserName OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptTitle', '',       @RptTitle OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageOrientation', '',   @RptPageOrientation OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageSize', '',      @RptPageSize OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPercentZoom', '',     @RptPercentZoom OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ReportTimeOut', '',      @RptTimeout OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ServerFileLocation', '',    @RptFileLocation OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConnectionString', '',   @RptConnectionString OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptGroupBy', '',      @RptGroupBy OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptLineStatusList', '',    @LineStatusList OUTPUT  
-- EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptWindowMaxDays', '',    @RptWindowMaxDays OUTPUT  
-- END  
--ELSE     
-- BEGIN  
-- INSERT  @ErrorMessages (ErrMsg)  
--  VALUES ('No Report Name specified.')  
-- GOTO ReturnResultSets  
-- END   
  
--if (@LineStatusList IS NULL) or (@LineStatusList='')  
--SELECT @LineStatusList='All'  
  
/* this is only for testing  
select  
@IncludeTeam = 1,  
@IncludeStops = 1,  
@BySummary = 1  
*/  
  
--select @ProdLineList = '28'  --|156|157'  
  
--------------------------------------------------------------  
-- Section 4: Assign constant values  
--------------------------------------------------------------  
  
select  
--@ScheduleStr    = 'Schedule',  
--@CategoryStr    = 'Category',  
--@GroupCauseStr    = 'GroupCause',  
--@SubSystemStr    = 'Subsystem',  
--@DelayTypeRateLossStr = 'RateLoss',  
--@CatBlockStarvedId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Blocked/Starved'),  --FLD 07-NOV-2007 Rev11.54  
--@CatELPId     = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Paper (ELP)'),  
--@CatMechEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Mechanical Equipment'),  
--@CatElectEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Electrical Equipment'),  
--@CatProcFailId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Process/Operational'),  
--@SchedPRPolyId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:PR/Poly Change'),  
--@SchedUnscheduledId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Unscheduled'),  
--@SchedSpecialCausesId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Special Causes'),  
--@SchedEOProjectsId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:E.O./Projects'),  
--@SchedBlockedStarvedId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Blocked/Starved'),  
@SchedChangeOverId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Changeover'),  
@SchedPlnInterventionId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Planned Intervention'),  
--@SchedHolidayCurtailId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Holiday/Curtail'),  
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
@VarLineSpeedMMinVN  = 'Reports Line Speed (m/min)',  -- Rev11.45  
@LineProdFactorDesc   = 'Production Factors',  
  
@PUDelayTypeStr    = 'DelayType=',  
@PUScheduleUnitStr  = 'ScheduleUnit=',  
@PULineStatusUnitStr  = 'LineStatusUnit=',  
@PRIDRLVarStr     = 'Rate Loss PRID',  
    
@VarTypeStr     = 'VarType=',  
@ACPUnitsFlag    = 'ACPUnits',  
@HPUnitsFlag    = 'HPUnits',  
@TPUnitsFlag    = 'TPUnits', --Namho Kim Rev11.16  
  
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
@TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId),  
@NoTeamInfoMsg = GBDB.dbo.fnLocal_GlblTranslation('Insufficient Crew_Schedule information to generate this report...', @LanguageId),  
  
@VarInputRollVN   = 'Input Roll ID',  
@VarInputPRIDVN   = 'Input PRID'  
  
--Rev11.55  
--@DBVersion     = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')  
  
IF @BusinessType = 3  
  
 select @PPTT = 'PP '  
else  
 select @PPTT = 'TT '  
  
  
----------------------------------------------------------------------------------  
----------------------------------------------------------------------------------  
-- Section 6: Create temp tables and table variables  
----------------------------------------------------------------------------------  
----------------------------------------------------------------------------------  
  
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
 CombinedPUDesc          VARCHAR(100),  
 PLId             INTEGER,  
 ExtendedInfo          VARCHAR(255),  
 DelayType           VARCHAR(100),  
 ScheduleUnit          INTEGER,  
 LineStatusUnit          INTEGER,  
 UWSVarId            INTEGER,  
 UWS1             VARCHAR(50),  
 UWS2             VARCHAR(50),  
 PRIDRLVarId           INTEGER,  
 RowId             INTEGER IDENTITY  
 )  
  
  
---------------------------------------------------------------  
-- this table will hold Prod Unit data for Pack lines  
--------------------------------------------------------------  
/*  
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
*/  
  
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
  
  
-----------------------------------------------------------------------  
-- this table will hold data about the unwind stands  
-----------------------------------------------------------------------  
  
DECLARE @UWS TABLE   
 (   
 InputName           VARCHAR(50),  
 InputOrder           INTEGER,  
 PLId             INTEGER,  
 PEIId             INTEGER,        -- 2007-01-11 VMK Rev11.30, added  
 UWSPUId            INTEGER primary key   
 )  
  
  
----------------------------------------------------------------------------------  
-- @Runs will be the final production runs, as split by the dimensions  
----------------------------------------------------------------------------------  
  
--Rev11.55  
declare @Runs table  
(  
 PLID             integer,  
 PUID             integer,  
 Shift             varchar(10),   
 Team             varchar(10),   
 ShiftStart           datetime,  
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
 PUId             INTEGER,  
 Shift             INTEGER,  
 Team             VARCHAR(10),  
 ProdId            INTEGER,  
 TargetSpeed           float,  
 IdealSpeed           float,  
 LineStatus           varchar(50),  
 -- add any additional dimensions that are required  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 Runtime            FLOAT     -- 2007-03-22 VMK Rev11.37, Added.  
 primary key (puid, starttime)  
 )  
  
  
-------------------------------------------------------------------------------  
--  this table will hold production summaries by shift, team, and product.  
-- this information will later be used to split the downtime events.  
-------------------------------------------------------------------------------  
  
DECLARE @ProdRecords TABLE   
 (  
 PLId             INTEGER,  
 puid             integer,  
 ReliabilityPUID         int,  
 Shift             VARCHAR(50),  
 Team             VARCHAR(50),  
 ProdId            INTEGER,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 TotalUnits           float, --INTEGER, -- Rev11.31  
 GoodUnits           float, --INTEGER, -- Rev11.31  
 RejectUnits           float, --INTEGER, -- Rev11.31  
 WebWidth            FLOAT,  
 SheetWidth           FLOAT,  
 LineSpeedIdeal          FLOAT,  
 LineSpeedTarget         FLOAT,  
 LineSpeedAvg          FLOAT,  
 TargetLineSpeed         FLOAT,    
 LineStatus           varchar(50),  
 RollsPerLog           float, --INTEGER, -- Rev11.31  
 RollsInPack           float, --INTEGER, -- Rev11.31  
 PacksInBundle          float, --INTEGER, -- Rev11.31  
 CartonsInCase          float, --INTEGER, -- Rev11.31  
 SheetCount           float, --INTEGER, -- Rev11.31  
 ShipUnit            INTEGER,  
 CalendarRuntime         FLOAT,  
 ProductionRuntime         FLOAT,  
 PlanningRuntime         FLOAT,  
 OperationsRuntime         FLOAT,  
 SheetLength           FLOAT,  
 StatFactor           FLOAT,  
 TargetUnits           float, --INTEGER, -- Rev11.31  
 ActualUnits           float, --INTEGER, -- Rev11.31  
 OperationsTargetUnits       float, --INTEGER, -- Rev11.31  
 HolidayCurtailDT         FLOAT,  
 PlninterventionDT         FLOAT,  
 ChangeOverDT          FLOAT,  
 HygCleaningDT          FLOAT,  
 EOProjectsDT          FLOAT,  
 UnscheduledDT          FLOAT,  
 CLAuditsDT           FLOAT,  
 IdealUnits           float, --INTEGER, -- Rev11.31   
 RollWidth2Stage         float,  
 RollWidth3Stage         float,  
 SplitUptime           float, -- Rev11.31  
 Runtime            FLOAT  -- 2007-03-22 VMK Rev11.37, Added  
 primary key (puid, starttime) --team, shift, prodid, starttime)  
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
  
  
--------------------------------------------------------------------------  
-- this table holds information about the Event Reasons.  
--------------------------------------------------------------------------  
  
--declare @EventReasons table   
-- (  
-- Event_Reason_ID         int PRIMARY KEY NONCLUSTERED,  
-- Event_Reason_Name         varchar(100)  
-- )  
  
  
-----------------------------------------------------------------------------  
-- this table will hold the Equipment Group information for prod units  
----------------------------------------------------------------------------  
  
DECLARE @ProdUnitsEG TABLE   
 (   
 RowId             int PRIMARY KEY IDENTITY,  
 PLId             INTEGER,  
 Source_PUId           INTEGER,  
 EquipGroup           VARCHAR(100)   
 )  
  
  
-----------------------------------------------------------------------  
-- this table will hold comments associated with #delays  
-----------------------------------------------------------------------  
  
 declare @WasteNTimedComments table  
  (  
  timestamp           datetime,  
  comment_text          varchar(5000),  
  wtc_type            int,  
  wtc_source_id          int  
  primary key (wtc_source_id, timestamp,wtc_type)  
  )  
  
  
-- Rev11.31  
declare @VariableList table   
 (  
 Var_Id           int primary key,  
 var_desc     varchar(50),  
 pl_id      int,  
 pu_id      int,  
 eng_units    varchar(50),  
 extended_info   varchar(200)   
 )  
  
  
declare @SplitDT_Unit table  
 (  
 [PuID]      int primary key,  
 plid       int,  
 [Stops]      int,  
 [StopsUnscheduled]  int,  
 [StopsMinor]    int,  
 [StopsEquipFails]   int,  
 [StopsProcessFailures] int,  
 [SplitDowntime]   float,  
 [UnschedSplitDT]   float,  
 [RawUptime]     float,  
 [SplitUptime]    float,  
 [Uptime2Min]     int,  
 [R2Numerator]     float,  
 [R2Denominator]    float,  
 [HolidayCurtailDT]  float,  
 [StopsELP]     int,  
 [ELPDowntime]     float,  
 [RLELPDowntime]    float,  
 [StopsRateLoss]    int,  
 [SplitRLDowntime]   float,  
 [PRPolyChangeEvents]  int,  
 [PRPolyChangeDowntime]  float  
 )  
  
  
  
declare @PRDTSums_Unit table   
 (   
 [PuID]       int, --primary key,  
 [PLID]       int,   
----- Metics by Line  
 [Stops]       INTEGER,  
 [StopsUnscheduled]   INTEGER,  
 [StopsMinor]     INTEGER,  
 [StopsEquipFails]    INTEGER,  
 [StopsProcessFailures]  INTEGER,  
 [SplitDowntime]    FLOAT,  
 [UnschedSplitDT]    FLOAT,  
 [RawUptime]      FLOAT,  
 [SplitUptime]     FLOAT,  
 [Uptime2Min]     INTEGER,  
 [R2Numerator]     float,  
 [R2Denominator]    float,  
 [StopsELP]      INTEGER,  
 [ELPDowntime]     float,  
 [RLELPDowntime]    float,  
 [ELPMins]      FLOAT,  
 [PaperRuntimeRaw]    float,  
 [Runtime]      float,  
 [ELPSchedDT]     float,  
   [PaperRuntime]             FLOAT,    
 [HolidayCurtailDT]   float,  
   [ProductionRuntime]        FLOAT,  
 [StopsRateLoss]    INTEGER,  
 [SplitRLDowntime]    FLOAT,  
 [PRPolyChangeEvents]   int,   
 [PRPolyChangeDowntime]  float  
 )    
  
  
 declare @PEI table  
  (  
  pu_id   int,  
  pei_id  int,  
  Input_Order int,  
  Input_name varchar(50)  
  primary key (pu_id,input_name)  
  )  
  
  
 declare @DTResults table  
  (  
  [Production Line]         varchar(50),  
  [Production Runtime]        float,  
  [Reporting Downtime]        float,   
  [Unscheduled Rpt DT]        float,        
  [Reporting Uptime]         float,   
  [Overall Availability]        float,   
  [Planned Availability]        float,  
  [Total Stops]           int,  
  [Unscheduled Stops]         int,  
  [Minor Stops]           int,  
  [Equipment Failures]        int,  
  [Process Failures]         int,  
  [ELP Stops]           int,  
  [ELP Losses (Mins)]         float,  
  [ELP %]             float,  
  [R(2)]             float,     
  [Unplanned MTBF]          float,  
  [Unplanned MTTR]          float,  
  [Rate Loss Events]         int,  
  [Rate Loss Effective Downtime]    float,  
  [Rate Loss %]           float,    
  [Planned Availability minus Rate Loss]  float   
  )     
  
  
-- Rev11.33  
--create table #ProdLines  
declare @ProdLines table  
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
 VarStartTimeId          INTEGER,   
 VarEndTimeId          INTEGER,   
 VarPRIDId           INTEGER,  
 VarParentPRIDId         INTEGER,  
 VarGrandParentPRIDId        INTEGER,  
 VarUnwindStandId         INTEGER,   
 VarLineSpeedId          INTEGER,  
 Extended_Info          varchar(225),  
 ProductionRuntime         FLOAT,     -- 2007-04-11 VMK Rev11.37, Added.  
 PaperRuntime          FLOAT     -- 2007-04-11 VMK Rev11.37, Added.  
 )   
  
  
--create table dbo.#ELPMetrics_Unit   
declare @ELPMetrics_Unit table   
 (   
 id_num       int,  
 [PuID]       int,  
 [PLID]       int,  
 LineStatus      varchar(50),  
 StartTime      DATETIME,  
 EndTime       DATETIME,  
----- Metics by Line  
 [PaperRuntimeRaw]    float,  
 [ELPSchedDT]     float--,  
-- [HolidayCurtailDT]   float  
-- primary key (puid,starttime)  
 )    
  
--CREATE CLUSTERED INDEX prs_PLID_StartTime  
--ON dbo.#ELPMetrics_Unit (puid, starttime)  
  
  
-- Rev11.55  
create table #PRsRun  
 (  
 Id_Num            INTEGER IDENTITY(1,1),   
 SourceID            int,  
 EventId            INTEGER,  
 PLID             int,  
 PUId             INTEGER,  
 PEIId             INTEGER,    
 [EventNum]           varchar(50),  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 InitEndTime           DATETIME, -- Rev11.33  
 PRPUId            INTEGER,   -- 2007-04-06 VMK Rev11.37, added  
 [PRPLID]            int,  
 PRTimeStamp           DATETIME,  -- 2007-04-06 VMK Rev11.37, added  
 ParentPRID           VARCHAR(50),   
 GrandParentPRID         VARCHAR(50),   
 UWS             VARCHAR(25),  
 InputOrder           INTEGER,  
 [LineStatus]          varchar(100),  
 EventTimestamp          datetime,  
 DevComment           varchar(100)--, --Rev11.33  
 PRIMARY KEY (Id_Num, PUId, StartTime)   
  )  
  
CREATE NONCLUSTERED INDEX prs_PUId_StartTime_initendtime  
ON dbo.#PRsRun (puid, starttime, initendtime, peiid)  
  
CREATE NONCLUSTERED INDEX prs_PUId_StartTime_endtime  
ON dbo.#PRsRun (puid, starttime, endtime, peiid)  
  
  
------------------------------------------------------------  
-- #LimitTests is an intermediary table that will be used   
-- to load @PackTests  
-----------------------------------------------------------  
  
create table #LimitTests  
 (  
 result_on           datetime,  
 result            varchar(25),  
 var_id            int--,  
 primary key (var_id, result_on)  
 )  
  
  
------------------------------------------------------------  
-- This table will hold test information for the Pack lines  
------------------------------------------------------------  
  
create table #PackTests  
 (  
 TestId            int IDENTITY,  
 VarId             INTEGER,  
 PLId             INTEGER,  
 PUId             INTEGER,  
 Value             FLOAT,  
 SampleTime           DATETIME,  
 ProdId            INTEGER,  
 UOM             VARCHAR(50)--,  
 primary key (puid, varid, sampletime)  
 )  
  
  
----------------------------------------------------------------------------------  
-- #delays are the downtime events that need to be tracked for the report.  
---------------------------------------------------------------------------------  
  
CREATE TABLE dbo.#Delays   
 (  
 TEDetId            int PRIMARY KEY CLUSTERED,  
 PrimaryId           INTEGER,  
 SecondaryId           INTEGER,  
 PUId             INTEGER,  
 PLID             INTEGER,  
 PUDesc            VARCHAR(100),  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 LocationId           INTEGER,  
 L1ReasonId           INTEGER,  
 L2ReasonId           INTEGER,  
 L3ReasonId           INTEGER,  
 L4ReasonId           INTEGER,  
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
--Rev11.55  
 RawRateloss           float,  
 Stops             INTEGER,  
 StopsUnscheduled         INTEGER,  
 StopsMinor           INTEGER,  
 StopsEquipFails         INTEGER,  
 StopsProcessFailures        INTEGER,  
 StopsELP            INTEGER,  
 SplitELPDowntime         float,  
 StopsBlockedStarved        INTEGER,  
 SplitELPSchedDT         float,  
 UpTime2m            INTEGER,  
 StopsRateLoss          INTEGER,  
 RateLossInWindow         FLOAT,  
 RateLossRatio          FLOAT,  
 RateLossPRID          VARCHAR(50),  
 LineTargetSpeed         FLOAT,  
 LineActualSpeed         FLOAT,  
-- UWS1Parent           VARCHAR(50),  
-- UWS1GrandParent         VARCHAR(50),  
-- UWS2Parent           VARCHAR(50),  
-- UWS2GrandParent         VARCHAR(50),  
 Comment            VARCHAR(5000),  
 InRptWindow           int  
 )  
  
CREATE NONCLUSTERED INDEX td_PUId_StartTime  
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
 --Rev11.55  
 Uptime            float,  
 Reason_Level1          int,  
 Reason_Level2          int,  
 Reason_Level3          int,  
 Reason_Level4          int,  
 TEFault_Id           int,  
 ERTD_ID            int,  
 Cause_Comment_Id         int,     --Used only by the 4.x code.  
 Cause_Comment          VARCHAR(5000) --Used only by the 4.x code.  
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
 Value             varchar(50),  
 SheetValue           varchar(100),  
 SampleTime           DATETIME,  
 UOM             varchar(50)--,  
 primary key (varid, sampletime)  
 )  
  
  
---------------------------------------------------------------  
  
--  #SplitDowntimes will split the #delays information according   
-- to changes in @ProductionRunsShift  
---------------------------------------------------------------  
  
CREATE TABLE  dbo.#SplitDowntimes   
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
 PrimaryId           INTEGER,  
 TEDetId            INTEGER,   
 TEFaultId           INTEGER,  
 ScheduleId           INTEGER,  
 CategoryId           INTEGER,  
 SubSystemId           INTEGER,  
 GroupCauseId          INTEGER,  
 LocationId           INTEGER,  
 L1ReasonId           INTEGER,  
 L2ReasonId           INTEGER,  
 L3ReasonId           INTEGER,  
 L4ReasonId           INTEGER,  
 LineStatus           VARCHAR(50),  
 Downtime            FLOAT,  
 SplitDowntime          FLOAT,  
 SplitRLDowntime         FLOAT,  
 RateLossInWindow         FLOAT,  
 Uptime            FLOAT,  
--Rev11.55  
 RawRateloss           float,  
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
 UpTime2m            INTEGER,  
 MinorEF            INTEGER,  
 ModerateEF           INTEGER,  
 MajorEF            INTEGER,  
 MinorPF            INTEGER,  
 ModeratePF           INTEGER,  
 MajorPF            INTEGER,  
 Causes            INTEGER,  
 Comment            VARCHAR(5000),  
 SplitELPDowntime         FLOAT,  
 SplitELPSchedDT         FLOAT,  
 SplitRLELPDowntime        FLOAT,  
 SplitUnscheduledDT        float, -- ???????????????????  
 LineTargetSpeed         FLOAT,  
 LineActualSpeed         FLOAT,  
-- UWS1Parent           VARCHAR(50),  
-- UWS1GrandParent         VARCHAR(50),  
-- UWS2Parent           VARCHAR(50),  
-- UWS2GrandParent         VARCHAR(50),  
 LineIdealSpeed          FLOAT,  
 Runtime            float,  
 DelayType           VARCHAR(100)  
-- primary key (puid, starttime, endtime)  
 )  
  
CREATE CLUSTERED INDEX puid_StartTime  
ON dbo.#SplitDowntimes (puid, starttime, endtime) --, peiid)  
  
  
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
 LineSpeedAvg          float, --int, -- Rev11.35  
 LineTargetSpeed         float, --int, -- Rev11.35  
 LineIdealSpeed          float, --int, -- Rev11.35  
 SplitUptime           FLOAT,    
 LineStatus           VARCHAR(50),  
 Comment            varchar(100)  
 primary key (puid, starttime, endtime)  
 )  
  
CREATE nonCLUSTERED INDEX su_suid  
 ON dbo.#SplitUptime (suid)  
  
  
---------------------------------------------------------------------------------  
-- 2007-Jan-11 VMK Rev11.30, added table #Events  
--Rev11.55  
CREATE TABLE dbo.#Events   
 (  
 event_id            INTEGER, -- PRIMARY KEY,  
 source_event          INTEGER,  
 pu_id             INTEGER,  
 start_time           datetime,  
 end_time            datetime,  
 timestamp           DATETIME,  
 entry_on            DATETIME,  
-- event_status          INTEGER,  
-- status_desc           varchar(50), -- Rev11.33  
 event_num           VARCHAR(50),  
 DevComment           varchar(300) -- Rev11.33  
-- primary key (Event_id, start_time)  
 )  
  
CREATE CLUSTERED INDEX events_eventid_StartTime  
ON dbo.#events (event_id, start_time)   
  
  
---------------------------------------------------------------------------------  
  
--Rev11.55  
create table dbo.#SplitPRsRun  
 (   
 [sprs_id]     int primary key identity,  
 [ID_num]                  int, --primary key identity ,  
-- CalDay      varchar(10),  
 ShiftStart     datetime,  
 [PLID]      int,  
 [PUID]      int,      
 [Team]      varchar(5),  
 [ProdID]      int,  
   [PRPLID]      int,  
   [PRPUID]      int,  
 LineStatus     varchar(50),  
   [StartTime]     datetime,  
   [EndTime]     datetime,  
 StartTime_Unit    datetime,  
 EndTime_Unit    datetime,  
 DevComment     varchar(100)  
 )  
  
--CREATE CLUSTERED INDEX sprs_PUId_StartTime_endtime  
--ON dbo.#SplitPRsRun (puid, starttime, endtime) --, peiid)  
  
--Rev11.63  
CREATE nonCLUSTERED INDEX sprs_PUId_StartTime_endtime  
ON dbo.#SplitPRsRun (puid, starttime, endtime)  
  
--Rev11.63  
CREATE nonCLUSTERED INDEX sprs_PlId_StartTime_endtime  
ON dbo.#SplitPRsRun (plid, starttime, endtime)  
  
  
--Rev11.55  
create table dbo.#Dimensions   
 (  
 Dimension     varchar(50),  
 Value       varchar(50),  
 StartTime     datetime,  
 EndTime      datetime,  
 PLID       int,  
 PUID       int  
 )  
  
CREATE CLUSTERED INDEX dim_PUId_EndTime  
ON dbo.#dimensions (puid, starttime)  
  
  
--Rev11.55  
create table dbo.#EventStatusTransitions  
 (  
 Event_ID   int,  
 Start_Time  datetime,  
 End_Time   datetime,  
 Event_Status int  
 )  
  
CREATE CLUSTERED INDEX est_eventid_starttime  
ON dbo.#EventStatusTransitions (event_id, start_time)  
  
  
--print 'Get local language ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 8: Get local language ID  
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
  
  
--print 'Section 10 Get info about Prod Lines: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------  
-- Section 10: Get information about the production lines  
------------------------------------------------------------  
  
-- pull in prod lines that have an ID in the list  
insert @ProdLines -- Rev11.33   
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
IF (SELECT count(PLId) FROM @ProdLines) = 0  -- Rev11.33  
 BEGIN  
  INSERT @ProdLines (PLId,PLDesc, Extended_Info) -- Rev11.33  
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
 VarStartTimeId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarStartTimeVN),  
 VarEndTimeId     = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarEndTimeVN),  
 VarPRIDId      = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarPRIDVN),  
 VarParentPRIDId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarParentPRIDVN),  
 VarGrandParentPRIDId  = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarGrandParentPRIDVN),  
 VarUnwindStandId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarUnwindStandVN),  
 -- Rev11.45  
 VarLineSpeedId    =   
         coalesce(  
            GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,@VarLinespeedMMinVN),  
            GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,@VarLinespeedVN)  
            )  
from @ProdLines pl   
where PackOrLine = 'Line'  
  
  
-- get the Line Prod Factor  
update @ProdLines set -- Rev11.33   
 PropLineProdFactorId = Prop_Id  
FROM dbo.Product_Properties with (nolock)  
WHERE Prop_Desc = ltrim(rtrim(replace(PLDesc,@PPTT,''))) + ' ' + @LineProdFactorDesc  
   
  
--print 'Section 11 @DelayTypeList: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 11: Parse the DelayTypeList  
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
  
  
--print 'Section 12 @ProdUnits: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 12: Get information for ProdUnitList  
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
--20081202   
AND rlv.Var_Desc_Global = @PRIDRLVarStr  
where pu.PU_Desc not like '%z_obs%'  
option (keep plan)  
  
  
--print 'Section 13 @UWS: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 13: Populate the @UWS table.  
-------------------------------------------------------------------------------  
  
INSERT INTO @UWS   
 (   
 InputName,  
 InputOrder,  
 PLId,  
 PEIId,         -- 2007-01-11 VMK Rev11.30, added  
 UWSPUId   
 )  
SELECT pei.Input_Name,  
 pei.Input_Order,  
 pl.PLId,  
 pei.PEI_Id,        -- 2007-01-11 VMK Rev11.29, added  
 COALESCE(pu.PU_Id,0-pei.PEI_Id)  
FROM dbo.PrdExec_Inputs pei with (nolock)  
JOIN @ProdLines pl   
ON pl.ProdPUId = pei.PU_Id -- Rev11.33  
AND PackOrLine = 'LINE'  
LEFT JOIN dbo.Prod_Units pu with (nolock)  
ON pu.PL_Id = pl.PLId  
AND charindex('UWSORDER='+CONVERT(VARCHAR(5), pei.Input_Order) + ';', upper(REPLACE(pu.Extended_Info, ' ', '') + ';')) > 0  
option (keep plan)  
  
/*  
--print 'Section 14 @ProdUnits UWS Columns: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--------------------------------------------------------------------------------------------  
--- Section 14: Update @ProdUnits UWS columns with the appropriate prod Unit desc.  
--------------------------------------------------------------------------------------------  
IF @IncludeStops = 1  
  
 UPDATE pu SET   
  UWS1 = upu1.PU_Desc,  
  UWS2 = upu2.PU_Desc  
 FROM @ProdUnits pu  
 LEFT JOIN @UWS uws1   
 ON pu.PLId = uws1.PLId  
 AND uws1.InputOrder = 1  
 LEFT JOIN dbo.Prod_Units upu1 with (nolock)  
 ON uws1.UWSPUId = upu1.PU_Id   
 LEFT JOIN @UWS uws2   
 ON pu.PLId = uws2.PLId  
 AND uws2.InputOrder = 2  
 LEFT JOIN dbo.Prod_Units upu2 with (nolock)  
 ON uws2.UWSPUId = upu2.PU_Id  
*/  
  
--print 'Section 15 @ProdUnitsPack: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 15: Populate @ProdUnitsPack  
-------------------------------------------------------------------------------  
/*  
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
JOIN dbo.#ProdLines pl with (nolock)  
ON pu.PL_Id = pl.PLId -- Rev11.33  
LEFT JOIN dbo.Variables v with (nolock)  
ON pu.PU_Id = v.PU_Id  
AND (v.Var_Desc = @VarGoodUnitsVN   
 OR dbo.fnLocal_GlblParseInfo(v.Extended_Info, 'GlblDesc=') LIKE '%' + REPLACE(@VarGoodUnitsVN,' ',''))  
where charindex('|' + convert(varchar,pu.pu_id) + '|','|' + @PackPUIdList + '|') > 0  
option (keep plan)  
*/  
  
--print 'Section 16 @ProdUnitsEG: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------------  
-- Section 16: Populate @ProdUnitsEG  
------------------------------------------------------------------  
/*  
-------------------------------------------------------------------------------  
-- Filter the Production Unit list to only include the passed Delay Type list   
-- for the @ProdUnits and #Runs tables.  
-------------------------------------------------------------------------------  
IF @IncludeStops = 1  
 BEGIN  
 -------------------------------------------------------------------------------  
 -- Create Temporary table to determine Equipment Groups.  
 -------------------------------------------------------------------------------  
 -- Insert Master Production Units INTO @ProdUnitsEG  
 INSERT INTO @ProdUnitsEG   
  (   
  PLId,  
  Source_PUId,  
  EquipGroup  
  )  
 SELECT ppu.PLId,  
  PU_Id,  
  GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, @PUEquipGroupStr)  
 FROM @ProdUnits ppu   
 JOIN dbo.Prod_Units pu with (nolock)  
 ON ppu.PUId = pu.PU_Id  
 option (keep plan)  
  
  
 -- Insert Slave Production Units into #ProdUnitsEG  
 INSERT INTO @ProdUnitsEG   
  (   
  PLId,  
  Source_PUId,  
  EquipGroup  
  )  
 SELECT ppu.PLId,  
  PU_Id,  
  GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, @PUEquipGroupStr)  
 FROM @ProdUnits ppu  
 JOIN dbo.Prod_Units pu with (nolock)  
 ON ppu.PUId = pu.Master_Unit  
 option (keep plan)  
  
 END --@IncludeStops  
*/  
  
--print 'Section 17 @CrewSchedule: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
---------------------------------------------------------------  
-- Section 17: Get Crew Schedule information  
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
  
  
if (select count(*) from @crewschedule) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES (@NoTeamInfoMsg)  
 GOTO ReturnResultSets  
 END  
  
  
--print 'Section 18 @ProductionStarts: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 18: Get Production Starts  
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
  
  
/*  
-- 2006-07-19   
insert @ProductionStarts   
 (  
 Start_Time,  
 End_Time,  
 Prod_ID,  
 Prod_Code,  
 Prod_Desc,  
 PU_ID  
 )  
select   
 ps.start_time,  
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
where pu.puid not in (select puid from @produnits)  
option (keep plan)  
*/  
  
--print 'Section 19 @Products: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------------------------  
-- Section 19: Get Products  
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
  
  
--print 'Section 20 @ActiveSpecs: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------------  
-- Section 20: Get Active Specs  
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
join @products p on   
c.char_desc = prod_code  
where effective_date < @EndTime  
and (expiration_date > @StartTime or expiration_date is null)  
AND ISNUMERIC(asp.target)=1   --When a spec is deleted, Proficy puts '<Deleted>' in front of the value.    
          --We don't wnat those records--or any others that don't have valid numeric values.  
option (keep plan)  
  
  
--print 'Section 21 @LineProdVars: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 21: Get Line Production Variables     
-------------------------------------------------------------------------------  
  
--print '@BusinessType = ' + Convert(VarChar(5), @BusinessType)  
IF @BusinessType IN (3, 4) -- Facial/Hanky  
  
 -- Facial/Hanky bases its production off a dedicated pack line so we're going to find  
 -- the pack line associated with this production line and gather all the necessary info FROM it  
 -- We're also going to filter by the argument pack pu list for consistency  
  
/*  
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
 JOIN dbo.#ProdLines pl with (nolock)  
 ON pl.PackOrLine = 'Line' -- Rev11.33  
 AND LTRIM(RTRIM(REPLACE(pup.PLDesc, ' ', ''))) = LTRIM(RTRIM(REPLACE(pl.PLDesc, ' ', ''))) + 'PACK'  
 WHERE dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr) IN (@ACPUnitsFlag, @HPUnitsFlag, @TPUnitsFlag)  
 option (keep plan)  
*/  
  
 INSERT INTO @LineProdVars  
  (   
  PLId,  
  PUId,  
  VarId,  
  VarType  
  )  
 SELECT    
  lpl.PLId,  
  ppu.PU_Id,  
  v.Var_Id,  
  dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr)  
 FROM Variables v  
 JOIN Prod_Units ppu   
 ON v.PU_Id = ppu.PU_Id  
 JOIN Prod_Lines ppl   
 ON ppu.PL_Id = ppl.PL_Id  
 JOIN @ProdLines lpl   
 ON ltrim(rtrim(replace(ppl.PL_Desc, ' ', ''))) = ltrim(rtrim(replace(lpl.PLDesc, ' ', ''))) + 'PACK'  
 WHERE dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr) IN (@ACPUnitsFlag, @HPUnitsFlag, @TPUnitsFlag)  
  
  
---------------------  
-- Populate #PRsRun  
---------------------  
  
--Rev11.55  
  
--print 'Running Status ID ' + CONVERT(VARCHAR(20), GetDate(), 120)  
select @RunningStatusID = ps.prodstatus_id   
from dbo.Production_Status ps WITH(NOLOCK)   
where UPPER(ps.prodstatus_desc) = 'RUNNING'   
  
--print 'EventStatusTransitions ' + CONVERT(VARCHAR(20), GetDate(), 120)  
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
and est.start_time < @endtime  
and (est.start_time < est.end_time or est.end_time is null)  
and (est.end_time > @starttime or est.end_time is null)  
  
  
--print 'Events ' + CONVERT(VARCHAR(20), GetDate(), 120)  
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
from dbo.#EventStatusTransitions est with(nolock)  
join dbo.events e with(nolock)  
on est.event_id = e.event_id  
  
  
--print 'source event ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- 2007-01-18 VMK Rev7.43, added code from PmkgDDSELP  
update e set  
 source_event = coalesce(ec.source_event_id,e.event_id)  
from dbo.#events e with (nolock)  
LEFT JOIN dbo.event_components ec with (nolock)  
ON e.event_id = ec.event_id  
  
--print 'PRSRun ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
--20080721  
  
--20080721  
INSERT INTO dbo.#prsrun  
 (   
 [EventID],  
 SourceID,  
 [PLID],  
 [puid],  
 [EventNum],  
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
 e.Source_Event,  
 pu.pl_id,  
 pu.pu_id,  
 e.event_num,  
  
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e.start_time, 120)) [StartTime],  
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e.end_time, 120)) [EndTime],  
  
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e1.timestamp, 120)) [PRIDTimeStamp],   
 e1.pu_id [PRPUID],  
 e.timestamp,  
 'Rel Unknown:Qual Unknown' [LineStatus],  
 'Initial Running Insert'    
-- events with Running status  
from dbo.#events e with(nolock)   
JOIN @ProdLines pl   
ON (e.PU_Id = pl.ProdPUId or e.pu_id = pl.ratelosspuid)  
JOIN dbo.prod_units pu with (nolock)   
ON pu.pu_id = e.pu_id   
-- source events  
JOIN dbo.events e1 with (nolock)  
ON e1.event_id = e.source_event  
  
  
--print 'PRSRun Time Updates ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update prs set  
 starttime = @starttime  
from dbo.#prsrun prs with(nolock)  
where starttime < @starttime  
  
--20080721  
update prs set  
 endtime = @endtime  
from dbo.#PRsRun prs with(nolock)  
where endtime > @endtime  
  
  
update prs set  
 [ParentPRID] = UPPER(RTRIM(LTRIM(tprid.result))),  
-- [ParentPM] =  UPPER(RTRIM(LTRIM(LEFT(COALESCE(tprid.Result, 'NoAssignedPRID'), 2)))),  
 [UWS] = coalesce(tuws.result,'No UWS Assigned')  
from dbo.#prsrun prs with(nolock)  
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
 PEIId   = pei_id,  
 InputOrder = pei.Input_Order  
FROM dbo.#prsrun prs with(nolock)   
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
  PEIId   = pei.pei_id,  
  InputOrder  = pei.input_order  
 FROM dbo.#prsrun prs with(nolock)   
 JOIN @pei pei  
 ON prs.puid = pei.pu_id  
 and pei.input_name = prs.UWS  
 where prs.puid = 1464  
   
end  
end  
  
DELETE dbo.#prsrun  
WHERE PEIId IS NULL  
  
update prs SET   
 [ParentPRID] = coalesce(t.result,'NoAssignedPRID'),   
 [PRTimeStamp] = e.timestamp,  
 [PRPUID] = e.pu_id  
FROM dbo.#prsrun prs with(nolock)   
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
  
--print 'grand prid' + ' ' + convert(varchar(25),current_timestamp,108)  
UPDATE prs SET   
 [GrandParentPRID] = t.result--,  
-- [GrandParentPM] = UPPER(RTRIM(LTRIM(LEFT(t.Result, 2))))--,  
FROM dbo.#prsrun prs with(nolock)   
--join dbo.#ProdLines pl with(nolock)   
--on prs.plid = pl.plid  
LEFT JOIN dbo.tests t with (nolock)   
ON t.result_on = prs.[PRTimestamp]   
--and prs.[ParentType] = 2  
LEFT JOIN dbo.variables v with (nolock)   
ON v.var_id = t.var_id   
and v.pu_id = prs.[PRPUID]   
--Rev7.67  
--where v.var_id = pl.VarInputRollID  
--or v.var_id = pl.VarInputPRIDID  
where v.var_desc_global = @VarInputRollVN --pl.VarInputRollID  
or v.var_desc_global = @VarInputPRIDVN --pl.VarInputPRIDID  
  
  
--Rev11.55  
-- to identify overlap adjustments, query the temp table for InitEndtime <> Endtime  
UPDATE prs1 SET   
 prs1.Endtime =   
  coalesce((  
  select top 1 prs2.Starttime  
  from dbo.#prsrun prs2 with(nolock)   
  where prs1.PUId = prs2.PUId  
  and prs1.StartTime <= prs2.StartTime   
  and prs1.InitEndTime > prs2.StartTime  
  AND prs1.PEIId = prs2.PEIId  
  and prs1.eventid <> prs2.eventid  
  order by puid, starttime  
  ), prs1.InitEndtime)  
FROM dbo.#prsrun prs1 with(nolock)   
  
delete dbo.#prsrun  
where StartTime = EndTime   
  
  
--print 'fill gaps ' + CONVERT(VARCHAR(20), GetDate(), 120)  
 -------------------------------------------------------------------------------------------  
 -- 2007-01-16 VMK Rev11.30, moved this code to fill gaps so that it is below the update  
 --          to the EndTime for cases when the EndTime overlaps the  
 --          next StartTime.  
 -- 2006-03-29 VMK Rev11.15  
 -- #PRsRun includes PRs run for the converting lines included in the report.  However, it   
 -- does not include time slices where there is no PR loaded on the UWS.    
 -- Now add the records that fill in that time and assign them to 'NoAssignedPRID'.  
 -------------------------------------------------------------------------------------------  
 INSERT dbo.#PRsRun   
  (   
  EventId,  
  PLID,  
  PUId,  
  PEIId,    
  StartTime,  
  EndTime,  
  ParentPRID,  
  GrandParentPRID,   
  UWS,  
  InputOrder,  
  DevComment   
  )  
 SELECT    
  NULL,  
  prs1.PLID,  
  prs1.PUId,  
  prs1.PEIId,   
  prs1.EndTime,  
  prs2.StartTime,  
  'NoAssignedPRID',  
  'NoAssignedPRID',  
  prs1.UWS,  
  prs1.InputOrder, --NULL,  
  'Fill gaps'  
 FROM dbo.#PRsRun prs1 with (nolock)-- Rev11.33  
 JOIN dbo.#PRsRun prs2 with (nolock)  
   ON prs1.PUId = prs2.PUId -- Rev11.33  
         AND prs1.PEIId  = prs2.PEIId       -- 2007-01-16 VMK Rev11.30, added  
         AND prs2.StartTime = (SELECT TOP 1 prs.StartTime FROM dbo.#PRsRun prs with (nolock)-- Rev11.33  
                WHERE prs.StartTime > prs1.StartTime   
                AND prs.PUId = prs1.PUId  
                AND prs.PEIId = prs1.PEIId  -- 2007-01-16 VMK Rev11.30, added  
                ORDER BY prs.StartTime ASC)  
 WHERE prs1.EndTime <> prs2.StartTime  
  AND prs2.StartTime > prs1.EndTime  
 OPTION (KEEP PLAN)   
  
--print 'PR Start ' + CONVERT(VARCHAR(20), GetDate(), 120)  
 INSERT dbo.#PRsRun   
  ( -- Rev11.33  
  EventId,  
  PLID,  
  PUId,  
  PEIId,   
  StartTime,  
  EndTime,  
  ParentPRID,  
  GrandParentPRID,   
  UWS,  
  InputOrder,  
  DevComment   
  )  
 SELECT    
  NULL,  
  prs1.PLID,  
  prs1.PUId,  
  prs1.PEIId,   
  @StartTime,  
  prs1.StartTime,  
  'NoAssignedPRID',  
  'NoAssignedPRID',  
  prs1.UWS,  
  prs1.InputOrder, --NULL,  
  'Start of Report Window'  
 FROM dbo.#PRsRun prs1 with (nolock)-- Rev11.33  
 where prs1.StartTime > @starttime   
 and (prs1.endtime > @starttime or prs1.endtime is null)  
 and prs1.StartTime =   
 (  
 SELECT TOP 1 prs.StartTime   
 FROM dbo.#prsrun prs with(nolock)   
 WHERE prs.PUId = prs1.PUId  
 AND prs.PEIId = prs1.PEIId  
 ORDER BY prs.StartTime ASC  
 )  
OPTION (KEEP PLAN)  
  
--print 'PR End ' + CONVERT(VARCHAR(20), GetDate(), 120)  
 INSERT dbo.#PRsRun   
  ( -- Rev11.33  
  EventId,  
  PLID,  
  PUId,  
  PEIId,   
  StartTime,  
  EndTime,  
  ParentPRID,  
  GrandParentPRID,   
  UWS,  
  InputOrder,  
  DevComment   
  )  
 SELECT    
  NULL,  
  prs1.PLID,  
  prs1.PUId,  
  prs1.PEIId,   
  prs1.EndTime,  
  @EndTime,  
  'NoAssignedPRID',  
  'NoAssignedPRID',  
  prs1.UWS,  
  prs1.InputOrder, --NULL,  
  'End of Report Window'  
 FROM dbo.#PRsRun prs1 with (nolock)-- Rev11.33  
 where prs1.StartTime < @starttime   
 and (prs1.endtime < @starttime or prs1.endtime is null)  
 and prs1.StartTime =   
 (  
 SELECT TOP 1 prs.StartTime   
 FROM dbo.#prsrun prs with(nolock)   
 WHERE prs.PUId = prs1.PUId  
 AND prs.PEIId = prs1.PEIId  
 ORDER BY prs.StartTime ASC  
 )  
OPTION (KEEP PLAN)  
  
  
------------------------------------------------------------------------------------------------------------  
--print 'Section 22 Dimensions: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--------------------------------------------------------------------  
-- Section 22: Get the dimensions to be used  
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
Also, new dimensions may need to be added to @ProdRecords, #SplitDowntimes, and #SplitUptime.   
  
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
  
insert dbo.#Dimensions   
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
  
-- add the Team dimension  
insert dbo.#Dimensions  
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
insert dbo.#Dimensions  
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
  
  
--Rev11.55  
-- add the ShiftStart dimension  
insert dbo.#Dimensions  
 (  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
select  distinct  
 'ShiftStart',  
 convert(varchar(50),cs.Start_Time),  
 cs.start_time,  
 cs.end_time,  
 pu.PLID,  
 pu.puid  
from @crewschedule cs  
join @produnits pu   
on cs.pu_id = pu.scheduleunit -- pu.puid --   
option (keep plan)  
  
  
-- add target speed  
insert dbo.#Dimensions  
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
  
  
-- add Line Status  
  
insert dbo.#Dimensions  
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
 coalesce(ls.End_Datetime,@Endtime),  
 pu.plid,  
 pu.PUId  
FROM dbo.Local_PG_Line_Status ls with (nolock)  
JOIN @ProdUnits pu   
ON ls.Unit_Id = pu.LineStatusUnit   
AND pu.PUId > 0  
JOIN dbo.Phrase p with (nolock)  
ON line_status_id = p.Phrase_Id  
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
  
update dbo.#Dimensions set  
 starttime = @StartTime  
where starttime < @StartTime  
  
update dbo.#Dimensions set  
 endtime = @EndTime  
where endtime > @EndTime  
or endtime is null  
  
--print 'Section 23 run times, values for dimensions: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------  
-- Section 23: Get the run times and values for each dimension  
-------------------------------------------------------------  
  
-------------------------------------------------------------  
-- create the intial time periods of the production runs.  
-- the runtime needs to be laid out as a series of changes...  
-- initially, we don't care WHY the change takes place (meaning   
-- which dimension is undergoing the change).  We just need   
-- to lay the times of these changes out into a straight line.  
-- for this purpose, we only care about the start times.  
-------------------------------------------------------------  
  
-- 2007-04-11 VMK Rev11.37, Insert PEIId with PLId and PUId.  
insert @Runs  
 (  
 PLID,  
 PUID,  
 StartTime )  
select  distinct  
 PLID,  
 puid,  
 starttime  
from dbo.#Dimensions with(nolock)  
group by plid, puid, starttime  
order by puid, StartTime      
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
  from dbo.#Dimensions d with(nolock)  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'ProdID'  
  )  
from @Runs r  
  
  
-- get the Team  
  
update r set   
 Team =   
  (  
  select value  
  from dbo.#Dimensions d with(nolock)  
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
  from dbo.#Dimensions d with(nolock)  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'Shift'  
  )   
from @Runs r  
  
-- Rev11.55  
update r set   
 ShiftStart =   
  (  
--  select distinct convert(datetime,value)  
  select distinct value  
  from dbo.#Dimensions d with(nolock)   
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'ShiftStart'  
  )   
from @runs r   
  
  
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
-- 2007-03-13 VMK Rev11.37, and get PRSIdNum  
  
update r set   
 LineStatus =   
  (  
  select value  
  from dbo.#Dimensions d with(nolock)  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'LineStatus'  
  )  
from @Runs r  
  
  
--print 'Section 24 @RunSummary: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------------------------------  
-- Section 24: Populate @RunSummary  
-----------------------------------------------------------------------------------  
  
-- @RunSummary simply summarizes data from @Runs.  
-- For Hanky lines, the production is captured FROM the pack units.  Added IF  
-- statement to SELECT ONLY Converter Reliability unit(s) for Tissue/Towel.  
  
IF @BusinessType = 3  
 BEGIN  
  INSERT INTO @RunSummary   
   (   
   PLId,  
   PUId,  
   Shift,  
   Team,  
   ProdId,  
   StartTime,  
   EndTime,  
   TargetSpeed,  
   IdealSpeed,   
   LineStatus,  
   Runtime      -- 2007-03-22 VMK Rev11.37, Added.  
   )  
   
  SELECT distinct   
   PLId,  
   PUId,  
   Shift,  
   Team,  
   ProdId,  
   StartTime,  
   EndTime,  
   TargetSpeed,  
   IdealSpeed,  
   LineStatus,  
   SUM(DATEDIFF(ss, rls.StartTime, rls.EndTime) / 60.0)  -- 2007-03-22 VMK Rev11.37, Added.  
  FROM @Runs rls  
  GROUP BY PLId, PuId, Team, Shift, ProdId, LineStatus, StartTime, EndTime, TargetSpeed, IdealSpeed  
  option (keep plan)  
 END  
ELSE  
 BEGIN  
  INSERT INTO @RunSummary   
   (   
   PLId,  
   PUId,  
   Shift,  
   Team,  
   ProdId,  
   StartTime,  
   EndTime,  
   TargetSpeed,  
   IdealSpeed,  
   LineStatus,  
   Runtime     -- 2007-03-22 VMK Rev11.37, Added  
   )  
   
  SELECT distinct   
   rls.PLId,  
   rls.PUId,  
   Shift,  
   Team,  
   ProdId,  
   StartTime,  
   EndTime,  
   TargetSpeed,  
   IdealSpeed,  
   LineStatus,  
   SUM(DATEDIFF(ss, rls.StartTime, rls.EndTime) / 60.0)  -- 2007-03-22 VMK Rev11.37, Added.  
  FROM @Runs rls  
  JOIN @ProdUnits pu ON rls.PUId = pu.PUId  
  WHERE PUDesc LIKE '%Converter Reliability%'   
  GROUP BY rls.PLId, rls.PuId, Team, Shift, ProdId, LineStatus, StartTime, EndTime, TargetSpeed, IdealSpeed  
  option (keep plan)  
 END  
  
--print 'Section 25 Timed Event Details: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 25: Get the Time Event Details  
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
--Rev11.55  
  Uptime,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ERTD_ID,  
  Cause_Comment_Id--,  
--Rev11.55  
--  Cause_Comment  
  )  
 select  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
--Rev11.55  
  Uptime * 60.0,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ted.event_reason_tree_data_id,  
  ted.Cause_Comment_ID --Co.Comment_Id--,  
--Rev11.55  
--  REPLACE(coalesce(convert(varchar(5000),co.comment_text),''), char(13)+char(10), ' ')  
 from dbo.timed_event_details ted with (nolock)  
 join @produnits pu  
 on ted.pu_id = pu.puid  
--Rev11.55  
-- LEFT JOIN dbo.Comments Co with (nolock) ON Co.Comment_Id = ted.Cause_Comment_Id  
 where Start_Time < @EndTime  
 AND (End_Time > @StartTime or end_time is null)  
--Rev11.55  
-- order by ted.pu_id, ted.start_time, ted.end_time  
 option (keep plan)  
  
 -- get the secondary events that span after the report window  
 insert dbo.#TimedEventDetails  
  (  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
--Rev11.55  
  Uptime,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ERTD_ID,  
  Cause_Comment_Id--,  
--Rev11.55  
--  Cause_Comment  
  )  
 select  
  ted2.TEDet_ID,  
  ted2.Start_Time,  
  ted2.End_Time,  
  ted2.PU_ID,  
  ted2.Source_PU_Id,  
--Rev11.55  
  ted2.Uptime,  
  ted2.Reason_Level1,  
  ted2.Reason_Level2,  
  ted2.Reason_Level3,  
  ted2.Reason_Level4,  
  ted2.TEFault_Id,  
  ted2.event_reason_tree_data_id,  
  ted2.Cause_Comment_ID --Co.Comment_Id--,  
--Rev11.55  
--   Co.Comment_Text  
 from  dbo.#TimedEventDetails ted1 with (nolock)  
 join  (  
  select   
   tted.TEDet_ID,  
   tted.Start_Time,  
   tted.End_Time,  
   tted.PU_ID,  
   tted.Source_PU_Id,  
   -- Rev11.55  
   tted.Uptime * 60.0 Uptime,  
   tted.Reason_Level1,  
   tted.Reason_Level2,  
   tted.Reason_Level3,  
   tted.Reason_Level4,  
   tted.TEFault_Id,  
   tted.event_reason_tree_data_id,  
   tted.Cause_Comment_Id  
  from dbo.timed_event_details tted with (nolock)  
  join @produnits tpu  
  on tted.pu_id = tpu.puid   
  and tted.start_time >= @Endtime   
  ) ted2  
 on ted1.PU_Id = ted2.PU_Id  
 AND ted1.End_Time = ted2.Start_Time  
 and ted2.start_time >= @endtime  
 AND ted1.TEDet_Id <> ted2.TEDet_Id  
--Rev11.55  
-- LEFT JOIN dbo.Comments Co with (nolock) ON Co.Comment_Id = ted2.Cause_Comment_Id  
 option (keep plan)  
  
  -- get the secondary events that span before the report window  
    
 insert dbo.#TimedEventDetails  
   (  
   TEDet_ID,  
   Start_Time,  
   End_Time,  
   PU_ID,  
   Source_PU_Id,  
  --Rev11.5  
  Uptime,  
   Reason_Level1,  
   Reason_Level2,  
   Reason_Level3,  
   Reason_Level4,  
   TEFault_Id,  
  ERTD_ID,  
   Cause_Comment_Id--,  
--Rev11.55  
--   Cause_Comment  
   )  
  select  
  ted1.TEDet_ID,  
  ted1.Start_Time,  
  ted1.End_Time,  
  ted1.PU_ID,  
  ted1.Source_PU_Id,  
  --Rev11.55  
  ted1.Uptime,  
  ted1.Reason_Level1,  
  ted1.Reason_Level2,  
  ted1.Reason_Level3,  
  ted1.Reason_Level4,  
  ted1.TEFault_Id,  
  ted1.event_reason_tree_data_id,  
   ted1.Cause_Comment_ID --Co.Comment_Id--,  
--Rev11.55  
--    Co.Comment_Text  
  from dbo.#TimedEventDetails ted2 with (nolock)  
  join  (  
   select   
   tted.TEDet_ID,  
   tted.Start_Time,  
   tted.End_Time,  
   tted.PU_ID,  
   tted.Source_PU_Id,  
   --Rev11.55  
   tted.Uptime * 60.0 Uptime,  
   tted.Reason_Level1,  
   tted.Reason_Level2,  
   tted.Reason_Level3,  
   tted.Reason_Level4,  
   tted.TEFault_Id,  
   tted.event_reason_tree_data_id,  
   tted.Cause_Comment_Id  
   from dbo.timed_event_details tted with (nolock)  
   join @produnits tpu  
   on tted.pu_id = tpu.puid   
   and tted.start_time < @starttime   
   and tted.end_time <= @Starttime   
   ) ted1  
  on ted1.PU_Id = ted2.PU_Id  
  AND ted1.End_Time = ted2.Start_Time  
  and ted1.end_time <= @starttime  
 and ted2.end_time <= @endtime  -- added to address OX issue  
  AND ted1.TEDet_Id <> ted2.TEDet_Id  
--Rev11.55  
--  LEFT JOIN dbo.Comments Co with (nolock) ON Co.Comment_Id = ted2.Cause_Comment_Id  
  option (keep plan)  
  
--Rev11.55  
-- END  
  
--Rev11.55  
update ted set  
 cause_comment = REPLACE(coalesce(convert(varchar(5000),co.comment_text),''), char(13)+char(10), ' ')  
from dbo.#TimedEventDetails ted with (nolock)  
left join dbo.Comments co with (nolock)  
on ted.cause_comment_id = co.comment_id  
  
  
--print 'Section 26 #Delays: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------------------  
-- Section 26: Get the initial set of delays for the report period  
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
  LocationId,  
  --Rev11.55  
  Uptime,  
  L1ReasonId,  
  L2ReasonId,  
  L3ReasonId,  
  L4ReasonId,  
  TEFaultId,  
  ERTD_ID,  
  DownTime,  
  SplitDowntime,  
  PrimaryId,  
  SecondaryId,  
  InRptWindow,  
  Comment)  
SELECT ted.TEDet_Id,  
 tpu.plid,  
 ted.PU_Id,  
 ted.Start_Time,  
 COALESCE(ted.End_Time, @EndTime),  
 ted.Source_PU_Id,  
 --Rev11.55  
 ted.Uptime,  
 ted.Reason_Level1,  
 ted.Reason_Level2,  
 ted.Reason_Level3,  
 ted.Reason_Level4,  
 ted.TEFault_Id,  
 ted.ERTD_ID,  
 DATEDIFF(ss, ted.Start_Time,COALESCE(ted.End_Time, @EndTime)),  
 COALESCE(DATEDIFF(ss, CASE WHEN ted.Start_Time <= @StartTime   
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
   END,  
 ted.Cause_Comment  
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
  
/*  
update td set  
 PUID = tpu.pu_id,  
 pudesc = tpu.pu_desc  
from dbo.#delays td with(nolock)  
join dbo.prod_units pu  
on td.puid = pu.pu_id  
join dbo.prod_units tpu  
on tpu.pu_desc = replace(pu.pu_desc,'Converter Blocked/Starved', 'Converter Reliability')  
where pu.pu_desc like '%Converter Blocked/Starved'  
*/  
  
--print 'Section 28 Addl updates to #Delays: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
---------------------------------------------------------------------------  
-- Section 28: Additional updates to #Delays  
---------------------------------------------------------------------------  
  
Update td set  
 Plid = pu.plid   
from dbo.#delays td with (nolock)  
join @produnits pu  
on td.puid = pu.puid  
where td.plid is null   
  
  
-- Add PUDesc Rev11.50  
--/*  
UPDATE td  
SET PUDESC =    
 CASE   
 WHEN pu.PU_Desc NOT LIKE '%Converter Reliability%'  
 AND pu.PU_Desc NOT LIKE '%Rate Loss%'  
 THEN pu.PU_Desc    
 ELSE pu1.pu_desc   
 END  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Prod_units pu ON td.PUID = pu.PU_Id  
JOIN @ProdLines pl   
ON pu.PL_Id = pl.PLId -- Rev11.33  
left join dbo.prod_units pu1  
on pl.reliabilitypuid = pu1.pu_id  
--WHERE td.pudesc is null   
--*/  
  
  
-------------------------------------------------------------------------------  
-- Ensure that all the PrimaryIds point to the actual Primary event.  
-------------------------------------------------------------------------------  
  
WHILE (   
 SELECT count(td1.TEDetId)  
 FROM dbo.#Delays td1 with (nolock)  
  JOIN dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
 WHERE td2.PrimaryId IS NOT NULL  
 ) > 0  
 BEGIN  
 UPDATE td1  
 SET PrimaryId = td2.PrimaryId  
 FROM dbo.#Delays td1 with (nolock)  
  INNER JOIN dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
 WHERE td2.PrimaryId IS NOT NULL  
 END  
  
UPDATE dbo.#Delays  
SET PrimaryId = TEDetId  
WHERE PrimaryId IS NULL  
  
  
/*  
--print 'Section 29 TE_Categories: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 29: Get the Timed Event Categories for #Delays  
-------------------------------------------------------------------------------  
  
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
FROM dbo.#Delays with (nolock)  
option (keep plan)  
  
  
INSERT INTO @TECategories   
 (  
 TEDet_Id,  
 ERC_Id  
 )  
SELECT tec.TEDet_Id,  
 tec.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN  dbo.Local_Timed_Event_Categories tec with (nolock)  
ON td.TEDetId = tec.TEDet_Id  
and tec.TEDet_Id > @Min_TEDet_Id  
AND tec.TEDet_Id < @Max_TEDet_Id  
option (keep plan)  
  
UPDATE td  
SET ScheduleId = tec.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN  @TECategories tec   
ON  td.TEDetId = tec.TEDet_Id  
JOIN  dbo.Event_Reason_Catagories erc with (nolock)  
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
FROM dbo.#Delays td with (nolock)  
JOIN  @TECategories tec   
ON  td.TEDetId = tec.TEDet_Id  
JOIN  dbo.Event_Reason_Catagories erc with (nolock)  
ON tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @CategoryStr + '%'  
*/  
/*  
IF @IncludeStops = 1  
 BEGIN  
  UPDATE td  
  SET GroupCauseId = tec.ERC_Id  
  FROM dbo.#Delays td with (nolock)  
  JOIN @TECategories tec   
  ON td.TEDetId = tec.TEDet_Id  
  JOIN dbo.Event_Reason_Catagories erc with (nolock)  
  ON tec.ERC_Id = erc.ERC_Id                     
  AND erc.ERC_Desc LIKE @GroupCauseStr + '%'  
  
  UPDATE td  
  SET SubSystemId = tec.ERC_Id  
  FROM dbo.#Delays td with (nolock)  
  JOIN @TECategories tec   
  ON td.TEDetId = tec.TEDet_Id  
  JOIN dbo.Event_Reason_Catagories erc with (nolock)  
  ON tec.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @SubSystemStr + '%'  
 END  
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
  
  
--print 'Section 31 Calc Stats: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------  
-- Section 31: Calculate the Statistics for stops information in the #Delays dataset   
-------------------------------------------------------------------------  
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
--  WHEN tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  and  tpu.pudesc not like '%Converter Blocked/Starved'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsMinor =    
  CASE   
--  WHEN td.DownTime < 600  
--  and tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  and  tpu.pudesc not like '%Converter Blocked/Starved'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN td.DownTime < 600  
  and (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsEquipFails =   --FLD 01-NOV-2007 Rev11.53  
  CASE   
--  WHEN td.DownTime >= 600  
--  and tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  and  tpu.pudesc not like '%Converter Blocked/Starved'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved%')  
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
--  WHEN td.DownTime >= 600  
--  and tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  and  tpu.pudesc not like '%Converter Blocked/Starved'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId)   
--   OR coalesce(td.CategoryId,0)=0)  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved%')  
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
  
  
-- Rev11.31  
-------------------------------------------------------------------------------------  
-- Section 11: Populate @VariableList  
-------------------------------------------------------------------------------------  
--print 'variablelist' + ' ' + convert(varchar(25),current_timestamp,108)  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarStartTimeId, PLID  
From @ProdLines   
where VarStartTimeId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarEndTimeId, PLID  
From @ProdLines   
where VarEndTimeId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarPRIDId, PLID  
From @ProdLines   
where VarPRIDId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarParentPRIDId, PLID  
From @ProdLines   
where VarParentPRIDId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarGrandParentPRIDId, PLID  
From @ProdLines   
where VarGrandParentPRIDId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarUnwindStandId, PLID  
From @ProdLines   
where VarUnwindStandId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarGoodUnitsId, PLID  
From @ProdLines   
where VarGoodUnitsId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarTotalUnitsId, PLID  
From @ProdLines   
where VarTotalUnitsId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarPMRollWidthId, PLID  
From @ProdLines   
where VarPMRollWidthId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarParentRollWidthId, PLID  
From @ProdLines   
where VarParentRollWidthId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarEffDowntimeId, PLID  
From @ProdLines   
where VarEffDowntimeId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarActualLineSpeedId, PLID  
From @ProdLines   
where VarActualLineSpeedId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarLineSpeedId, PLID  
From @ProdLines   
where VarLineSpeedId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarId, PLID  
From @LineProdVars  
where VarID is not null  
  
  
-- Rev11.31  
update vl set  
--20081202  
 var_desc   = v.var_desc_global,  
 pu_id    = v.pu_id,  
 eng_units  = upper(v.eng_units),  
 extended_info = v.extended_info  
from @variablelist vl  
join dbo.variables v with (nolock)  
on vl.var_id = v.var_id  
join dbo.prod_units pu with (nolock)  
on v.pu_id = pu.pu_id    
  
  
--print 'Get Tests: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------  
-- Section 32: Get Tests  
-------------------------------------------------------------  
  
-- Certain test results need to be compiled for this report.  Originally,  
-- there were multiple queries against the test table in the database to do this.    
-- But, its more efficient to only hit the table one time, and get all the data   
-- needed and put it into a temporary table.  This insert statement is   
-- designed to get all the test results needed for #PRsRun, @ProdRecords,  
-- and to determine the Actual Line Speed for #Delays.  
-- Note that the population of #PRsRun originally joined to the Tests table   
-- FIVE times... adding this intermediary table leads to a big improvement in   
-- efficiency.  
  
-- NOTE:  Later in the procedure there are two other test related intermediary tables.    
-- (LimitTests, which is then used to load PackTests).  I attempted to remove those   
-- tables and pull the results for PackTests into this table, but I had a lot of trouble   
-- with it.  If this could be done, it would further reduce the hits to the database,  
-- and remove two tables from this procedure.   
  
 -- Rev11.31  
 INSERT dbo.#Tests   
  (  
  VarId,  
  PLId,  
  PUID,  
  Value,  
  SampleTime--,  
  )  
 SELECT  
  distinct   
  t.Var_Id,  
  v1.PL_Id,  
  v1.pu_id,  
  t.Result,     
  t.Result_On  
 from dbo.tests t with (nolock)  
 join @variablelist v1  
 on t.var_id = v1.var_id   
 and t.result_on <= @EndTime  
 AND t.result_on >= dateadd(d, -1, @StartTime)  
 and t.result is not null  
 join @ProdLines pl   
 on pl.plid = v1.pl_id  
  
 delete dbo.#tests  
 where VarId in (select VarLineSpeedId from @prodlines) -- Rev11.33   
-- and convert(float,value) = 0.0    
 and (value = '0.0' or value = '0')  
  
  
 -- Rev11.31  
 update t set  
  puid   = ps.pu_id,  
  prodid  = ps.Prod_Id,  
  prodcode = p.Prod_Code  
 from dbo.production_starts ps with (nolock)  
 JOIN dbo.#tests t with (nolock)  
 ON ps.pu_id = t.puid   
 AND ps.Start_Time <= t.SampleTime  
 AND (ps.End_Time > t.SampleTime or ps.end_time is null)  
 JOIN dbo.Products p with (nolock)  
 on ps.prod_id = p.prod_id  
 option (keep plan)  
  
  
--print 'Section 35 @ProdRecords: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
----------------------------------------------------------  
-- Section 35: Populate @ProdRecords  
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
  
  
--print 'Section 33 #PRsRun: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
---------------------------------------------------------------------------------  
-- Section 33: Populate #PRsRun and update #Delays accordingly  
---------------------------------------------------------------------------------  
--  #PRsRun is used to track the Parent Rolls that ran during a report period.  
  
--------------------------------------------------------------------------------------------  
--- Insert Start_Times, UWS and PRIDs INTO temporary table.  
--------------------------------------------------------------------------------------------  
  
--IF @IncludeStops = 1  
  
-- begin  
  
--print 'PRID' + ' ' + convert(varchar(25),current_timestamp,108)  
  
 --------------------------------------------------------------------------------------------  
 --- Update the UWS Columns with the appropriate PRID results.  
 --------------------------------------------------------------------------------------------  
/*  
 UPDATE td SET   
  [UWS1Parent] = prs.ParentPRID,  
  [UWS1GrandParent] = prs.GrandParentPRID  
 FROM dbo.#prsrun prs with(nolock)   
 join dbo.#prodlines pl  
 on prs.puid = pl.prodpuid  
 join dbo.#delays td with(nolock)  
 on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
 and ((td.starttime >= prs.starttime and td.starttime < prs.endtime)   
  or (td.starttime < @starttime and td.endtime > @starttime))  
 AND prs.InputOrder = 1  
  
 UPDATE td SET   
  [UWS2Parent] = prs.ParentPRID,   
  [UWS2GrandParent] = prs.GrandParentPRID   
 FROM dbo.#prsrun prs with(nolock)   
 join dbo.#prodlines pl with(nolock)  
 on prs.puid = pl.prodpuid  
 join dbo.#delays td with(nolock)  
 on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
 and ((td.starttime >= prs.starttime and td.starttime < prs.endtime)   
  or (td.starttime < @starttime and td.endtime > @starttime))  
 AND prs.InputOrder = 2  
*/  
  
-- most of the UWS1 and UWS2 values in #Delays will be populated at this   
-- point, but some downtime events will start earlier than any of the parent rolls   
-- within the report window.  to handle these, we have the following code.  it may   
-- seem like a lot of work, but it shouldn't be too bad because it's only applied   
-- to a handful of records.  
  
/*  
if (select count(*) from dbo.#Delays with(nolock) where UWS1Parent is null or UWS2Parent is null) > 0  
begin   
  
--print '@PRDTOutsideWindow 1 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
insert @PRDTOutsideWindow  
 (  
 TEDetID,  
 EventID,  
 SourceEventID,  
 PLID,  
 CvtgPUID,  
 ProdPUID,  
-- StartTime,  
 EventTimestamp  
 )  
select  
 td.TEDetID,  
 e.Event_ID,  
 e.Source_Event,  
 td.PLID,  
 td.PUID,  
 e.pu_id,  
-- td.StartTime,  
 e.[Timestamp]  
FROM dbo.event_status_transitions est  
join dbo.events e  
on est.event_id = e.event_id  
join dbo.#prodlines pl with(nolock)  
on e.pu_id = pl.prodpuid  
join dbo.#delays td with(nolock)  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
and td.starttime >= est.start_time  
and td.starttime < est.end_time  
where est.event_status = @RunningStatusID  
AND (td.UWS1Parent is null or td.UWS2Parent is null)  
  
  
--print '@PRDTOutsideWindow 2 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [ParentPRID] = UPPER(RTRIM(LTRIM(tprid.result)))  
from @PRDTOutsideWindow pdow  
join dbo.#prodlines pl with(nolock)  
on pdow.plid = pl.plid  
JOIN dbo.Tests tprid with (nolock)  
on (tprid.Var_Id = pl.VarPRIDId and tprid.result_on = pdow.EventTimeStamp)  
or (tprid.var_id = pl.VarParentPRIDId and tprid.result_on = pdow.EventTimeStamp)  
  
--print '@PRDTOutsideWindow 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 PRPUID = e1.PU_ID,  
 SourceTimestamp = e1.[Timestamp]  
from @PRDTOutsideWindow pdow  
join dbo.Events e1  
on pdow.SourceEventID = e1.event_id  
  
--print '@PRDTOutsideWindow 5 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [GrandparentPRID] = UPPER(RTRIM(LTRIM(tprid.result)))  
from @PRDTOutsideWindow pdow  
join dbo.variables v  
on pdow.prpuid = v.pu_id  
--join dbo.#prodlines pl with(nolock)  
--on pdow.plid = pl.plid  
JOIN dbo.Tests tprid with (nolock)  
--Rev7.67  
--on (tprid.Var_Id = pl.VarInputRollID and tprid.result_on = pdow.SourceTimeStamp)  
--or (tprid.var_id = pl.VarInputPRIDID and tprid.result_on = pdow.SourceTimeStamp)  
on tprid.var_id = v.var_id  
where pdow.[ParentType] = 2  
and (v.var_desc_global = @VarInputRollVN or v.var_desc_global = @VarInputPRIDVN)  
  
  
--print '@PRDTOutsideWindow 6 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 PMTeam = SUBSTRING(UPPER(RTRIM(LTRIM(coalesce(GrandParentPRID, ParentPRID, '')))), 3, 1)  
from @PRDTOutsideWindow pdow  
  
--print '@PRDTOutsideWindow 7 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [UWS] = tuws.result  
from @PRDTOutsideWindow pdow  
join dbo.#prodlines pl with(nolock)  
on pdow.plid = pl.plid  
JOIN dbo.Tests tuws with (nolock)  
on tuws.Var_Id = pl.VarUnwindStandID   
and tuws.result_on = pdow.EventTimeStamp  
  
--print '@PRDTOutsideWindow 8 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [Input_Order] = pei.input_order  
from @PRDTOutsideWindow pdow  
join dbo.#prodlines pl with (nolock)  
on pdow.plid = pl.plid  
JOIN dbo.PrdExec_Inputs pei WITH (NOLOCK)   
ON pei.pu_id = pdow.prodpuid   
AND pei.input_name = pdow.uws  
  
--print '@PRDTOutsideWindow 9 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [INTR] = pu.pl_id  
from @PRDTOutsideWindow pdow  
join dbo.Events e1  
on pdow.SourceEventID = e1.event_id  
join dbo.prod_units pu  
on pu.pu_id = e1.pu_id  
where   
 (  
 select count(*)   
 from dbo.prod_units pu1  
 where pu1.pl_id = pu.pl_id  
 and pu1.pu_desc like '%INTR%'  
 ) > 0  
  
  
--print '@PRDTOutsideWindow 10 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
UPDATE td SET   
 [UWS1Parent]   = pdow.ParentPRID,    
-- [UWS1ParentPM]   = RTRIM(LTRIM(COALESCE(LEFT(pdow.ParentPRID, 2), 'NoAssignedPRID'))),  
 [UWS1GrandParent]  = pdow.GrandParentPRID--,  
-- [UWS1GrandParentPM] = LEFT(pdow.GrandparentPRID, 2),  
-- [UWS1PMTeam]   = pdow.PMTeam,  
-- [INTR]     = pdow.INTR      
from @PRDTOutsideWindow pdow  
join dbo.#delays td with (nolock)  
on td.tedetid = pdow.tedetid  
where pdow.input_order = 1  
  
--print '@PRDTOutsideWindow 11 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
UPDATE td SET   
 [UWS2Parent]   = pdow.ParentPRID,    
-- [UWS2ParentPM]   = RTRIM(LTRIM(COALESCE(LEFT(pdow.ParentPRID, 2), 'NoAssignedPRID'))),  
 [UWS2GrandParent]  = pdow.GrandParentPRID--,  
-- [UWS2GrandParentPM] = LEFT(pdow.GrandparentPRID, 2),  
-- [UWS2PMTeam]   = pdow.PMTeam,  
-- [INTR]     = pdow.INTR      
from @PRDTOutsideWindow pdow  
join dbo.#delays td with (nolock)  
on td.tedetid = pdow.tedetid  
where pdow.input_order = 2  
  
  
 UPDATE td SET   
  [UWS1Parent] = 'NoAssignedPRID'  
 FROM dbo.#Delays td with (nolock)  
 WHERE UWS1Parent IS NULL  
  
  
end  
*/  
  
-- This update to #Tests replaces a lot of the initial work that used to be done in the old   
-- ProdRecordsShift cursor.  The rest of that work will be done in the insert and updates   
-- to @ProdRecords.  Note that there are FOUR joins to the @ActiveSpecs table.  
-- This is another case of an intermediary table saving us overhead compared to multiple   
-- hits to the database.  However, in this case, there is even more benefit in this regard,  
-- because the table compiles related data from multiple source tables.  
  
IF @BusinessType = 4  
 BEGIN  
  
  UPDATE t set  
   t.SheetValue =   
    case lpv.vartype  
    when @ACPUnitsFlag  
    then  convert(float,t.Value)  
      * CONVERT(FLOAT, asp1.Target)  
      * CONVERT(FLOAT, asp2.Target)  
      * CONVERT(FLOAT, asp4.Target)  
    when @HPUnitsFlag  
    then convert(float,t.Value)  
      * CONVERT(FLOAT, asp1.Target)  
      * CONVERT(FLOAT, asp2.Target)  
      * CONVERT(FLOAT, asp3.Target)  
      * CONVERT(FLOAT, asp4.Target)  
    when @TPUnitsFlag  
    then convert(float,t.Value)  
      * CONVERT(FLOAT, asp1.Target)  
      * CONVERT(FLOAT, asp2.Target)  
    else null  
    end  
  FROM dbo.#Tests t with (nolock)  
  JOIN @LineProdVars lpv   
  ON t.VarId = lpv.VarId  
  LEFT JOIN @ActiveSpecs asp1   
  on asp1.Prop_Id = @PropCvtgProdFactorId  
  AND asp1.Char_Desc = t.ProdCode  
  AND asp1.Spec_Id = @PacksInBundleSpecId  
  AND asp1.Effective_Date < t.SampleTime  
  AND (asp1.Expiration_Date >= t.SampleTime   
   or asp1.expiration_date is null)  
  LEFT JOIN @ActiveSpecs asp2  
  on asp2.Effective_Date < t.SampleTime  
  AND (asp2.Expiration_Date >= t.SampleTime   
   or asp2.Expiration_Date is null)  
  and asp2.Char_Id = asp1.Char_Id  
  AND asp2.Spec_Id = @SheetCountSpecId  
  LEFT JOIN @ActiveSpecs asp3  
  on asp3.Effective_Date < t.SampleTime  
  AND (asp3.Expiration_Date >= t.SampleTime  
   or asp3.Expiration_Date is null)  
  and asp3.Char_Id = asp1.Char_Id  
  AND asp3.Spec_Id = @ShipUnitSpecId  
  LEFT JOIN @ActiveSpecs asp4   
  on asp4.Effective_Date < t.SampleTime  
  AND (asp4.Expiration_Date >= t.SampleTime  
   or asp4.Expiration_Date is null)  
  and asp4.Char_Id = asp1.Char_Id  
  AND asp4.Spec_Id = @CartonsInCaseSpecId  
  
  
 END  
  
-- end  -- end if  
  
  
--print 'Section 34 Rateloss: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
----------------------------------------------------------------------------------  
-- Section 34: Update the Rateloss information for #Delays  
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
 uptime    = null,  
 downtime    = null,  
-- UWS1Parent  = (  
--       SELECT result  
--       FROM dbo.Tests t   
--       WHERE Var_Id = pu.PRIDRLVarId   
--       AND td.StartTime = t.result_on  
--       ),   
 RateLossRatio  = (CONVERT(FLOAT,t1.Value) * 60.0) / Downtime,  
--Rev11.55  
 RawRateloss  = (CONVERT(FLOAT,t1.Value) * 60.0)   
FROM dbo.#Delays td with (nolock)  
JOIN @ProdUnits pu   
ON td.PUID = pu.PUID  
JOIN @ProdLines pl   
ON pu.PLID = pl.PLID  
LEFT JOIN dbo.#Tests t1 with (nolock)  
ON (td.StartTime = t1.SampleTime)   
AND (pl.VarEffDowntimeId = t1.VarId)  
LEFT JOIN dbo.#Tests t2 with (nolock)  
ON (td.StartTime = t2.SampleTime)  
AND (pl.VarActualLineSpeedId = t2.VarId)  
WHERE pu.DelayType = @DelayTypeRateLossStr  
AND Downtime <> 0  
  
  
--print 'Insert Prod Records ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- this table compiles production values so that they can be grouped   
-- as needed in the result sets later.  
  
INSERT @ProdRecords   
 (  
 PLId,   
 puid,  
 ReliabilityPUID,  
 Shift,  
 Team,  
 ProdId,  
 StartTime,   
 EndTime,   
 LineSpeedTarget,  
 LineSpeedIdeal,  
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
 pl.PLId,  
 puid,  
 ReliabilityPUID,  
 Shift,  
 Team,  
 ProdId,  
 rs.StartTime,  
 rs.EndTime,  
 TargetSpeed,  
 IdealSpeed,  
   
 CONVERT(FLOAT,DATEDIFF(ss,rs.StartTime, rs.EndTime)) / 60.0,  
  
 --StatFactor =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp1  
 where asp1.prod_id = rs.prodid  
 AND asp1.Effective_Date <= rs.startTime  
 and asp1.Spec_Id = @StatFactorSpecId  
 AND asp1.Prop_Id = @PropCvtgProdFactorId  
 ORDER BY asp1.Effective_Date DESC  
 ),  
  
 --RollsInPack =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp2  
 where asp2.prod_id = rs.prodid  
 AND asp2.Effective_Date <= rs.StartTime  
 and asp2.Spec_Id = @RollsInPackSpecId  
 ORDER BY asp2.Effective_Date DESC  
 ),  
  
 --PacksInBundle =  
 (  
 SELECT TOP 1 CONVERT(FLOAT,Target)  
 FROM @ActiveSpecs asp3  
 where asp3.prod_id = rs.prodid  
 AND asp3.Effective_Date <= rs.StartTime  
 and asp3.Spec_Id = @PacksInBundleSpecId  
 ORDER BY asp3.Effective_Date DESC  
 ),  
  
 --SheetCount =  
 (   
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp4  
 where asp4.prod_id = rs.prodid  
 AND asp4.Effective_Date <= rs.StartTime  
 and asp4.Spec_Id = @SheetCountSpecId  
 ORDER BY asp4.Effective_Date DESC  
 ),  
  
 --ShipUnit =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp5  
 where asp5.prod_id = rs.prodid  
 AND asp5.Effective_Date <= rs.StartTime  
 and asp5.Spec_Id = @ShipUnitSpecId  
 ORDER BY asp5.Effective_Date DESC  
 ),  
  
 --SheetWidth =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp6  
 where asp6.prod_id = rs.prodid  
 AND asp6.Effective_Date <= rs.StartTime  
 and asp6.Spec_Id = @SheetWidthSpecId  
 ORDER BY asp6.Effective_Date DESC  
 ),  
  
 --SheetLength =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp7  
 where asp7.prod_id = rs.prodid  
 AND asp7.Effective_Date <= rs.StartTime  
 and asp7.Spec_Id = @SheetLengthSpecId  
 ORDER BY asp7.Effective_Date DESC  
 ),  
  
 --CartonsInCase =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp8  
 where asp8.prod_id = rs.prodid  
 AND asp8.Effective_Date <= rs.StartTime  
 and asp8.Spec_Id = @CartonsInCaseSpecId  
 ORDER BY asp8.Effective_Date DESC  
 ),  
  
 LineStatus  
  
FROM @ProdLines pl   
JOIN @RunSummary rs  
ON rs.PLId = pl.PLId  
and pl.PackOrLine <> 'Pack'  
where puid = reliabilitypuid  
option (keep plan)  
  
  
--print 'Update Prod Records ' + CONVERT(VARCHAR(20), GetDate(), 120)-- the following series of updates replaces a lot of work that used to be done  
-- in the ProdRecordsShift cursor.  NOTE that there are sequential updates   
-- because in many cases, base values must be calculated before others can   
-- be done.  
  
update prs set  
  
 HolidayCurtailDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td1.ScheduleId = @SchedHolidayCurtailId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td1.StartTime <= rs1.StartTime   
    THEN rs1.StartTime   
    ELSE td1.StartTime END  
    ),   
    (  
    CASE   
    WHEN td1.EndTime >= rs1.EndTime   
    THEN rs1.EndTime   
    ELSE td1.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs1  
  left join dbo.#Delays td1 with (nolock)  
  on  td1.PUId = prs.ReliabilityPUId   
  and td1.starttime < rs1.endtime  
  and td1.endtime > rs1.starttime   
  where rs1.PuId = prs.PuId  
  and (rs1.team = prs.team) --or (rs.team is null and prs.team is null))  
  and (rs1.shift = prs.shift) --or (rs.shift is null and prs.shift is null))  
  and rs1.prodid = prs.prodid  
  and rs1.starttime = prs.starttime  
  and rs1.endtime = prs.endtime  
  ),  
  
 PlninterventionDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td2.ScheduleId = @SchedPlninterventionId  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td2.StartTime <= rs2.StartTime   
    THEN rs2.StartTime   
    ELSE td2.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td2.EndTime >= rs2.EndTime   
    THEN rs2.EndTime   
    ELSE td2.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs2  
  left join dbo.#Delays td2 with (nolock)  
  on  td2.PUId = prs.ReliabilityPUId   
  and td2.starttime < rs2.endtime  
  and td2.endtime > rs2.starttime   
  where rs2.PuId = prs.PuId  
  and rs2.team = prs.team  
  and rs2.shift = prs.shift  
  and rs2.prodid = prs.prodid  
  and rs2.starttime = prs.starttime  
  and rs2.endtime = prs.endtime  
  ),  
  
  
 ChangeOverDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td3.ScheduleId = @SchedChangeOverId  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td3.StartTime <= rs3.StartTime   
    THEN rs3.StartTime   
    ELSE td3.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td3.EndTime >= rs3.EndTime   
    THEN rs3.EndTime   
    ELSE td3.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs3  
  left join dbo.#Delays td3 with (nolock)  
  on  td3.PUId = prs.ReliabilityPUId   
  and td3.starttime < rs3.endtime  
  and td3.endtime > rs3.starttime   
  where rs3.PuId = prs.PuId  
  and rs3.team = prs.team  
  and rs3.shift = prs.shift  
  and rs3.prodid = prs.prodid  
  and rs3.starttime = prs.starttime  
  and rs3.endtime = prs.endtime  
  ),  
  
 HygCleaningDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td4.ScheduleId = @SchedHygCleaningId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td4.StartTime <= rs4.StartTime   
    THEN rs4.StartTime   
    ELSE td4.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td4.EndTime >= rs4.EndTime   
    THEN rs4.EndTime   
    ELSE td4.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs4  
  left join dbo.#Delays td4 with (nolock)  
  on  td4.PUId = prs.ReliabilityPUId   
  and td4.starttime < rs4.endtime  
  and td4.endtime > rs4.starttime   
  where rs4.PuId = prs.PuId  
  and rs4.team = prs.team  
  and rs4.shift = prs.shift  
  and rs4.prodid = prs.prodid  
  and rs4.starttime = prs.starttime  
  and rs4.endtime = prs.endtime  
  ),  
  
 EOProjectsDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td5.ScheduleId = @SchedEOProjectsId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td5.StartTime <= rs5.StartTime   
    THEN rs5.StartTime   
    ELSE td5.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td5.EndTime >= rs5.EndTime   
    THEN rs5.EndTime   
    ELSE td5.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs5  
  left join dbo.#Delays td5 with (nolock)  
  on  td5.PUId = prs.ReliabilityPUId   
  and td5.starttime < rs5.endtime  
  and td5.endtime > rs5.starttime   
  where rs5.PuId = prs.PuId  
  and rs5.team = prs.team  
  and rs5.shift = prs.shift  
  and rs5.prodid = prs.prodid  
  and rs5.starttime = prs.starttime  
  and rs5.endtime = prs.endtime  
  ),  
  
 UnscheduledDT =  
  (  
  select COALESCE(SUM(  
   case  
   --when td.ScheduleId = @SchedUnscheduledId   
   when td6.StopsUnscheduled = 1  --FLD 01-NOV-2007 Rev11.53  ---SHPULD BE OK...VERIFY   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td6.StartTime <= rs6.StartTime   
    THEN rs6.StartTime   
    ELSE td6.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td6.EndTime >= rs6.EndTime   
    THEN rs6.EndTime   
    ELSE td6.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs6  
  left join dbo.#Delays td6 with (nolock)  
  on  td6.PUId = prs.ReliabilityPUId   
  and td6.starttime < rs6.endtime  
  and td6.endtime > rs6.starttime   
  where rs6.PuId = prs.PuId  
  and rs6.team = prs.team  
  and rs6.shift = prs.shift  
  and rs6.prodid = prs.prodid  
  and rs6.starttime = prs.starttime  
  and rs6.endtime = prs.endtime  
  ),  
  
 CLAuditsDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td7.ScheduleId = @SchedCLAuditsId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td7.StartTime <= rs7.StartTime   
    THEN rs7.StartTime   
    ELSE td7.StartTime   
    END  
    ),   
    (  
    CASE WHEN td7.EndTime >= rs7.EndTime   
    THEN rs7.EndTime   
    ELSE td7.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
         ), 0.0)  
  from @RunSummary rs7  
  left join dbo.#Delays td7 with (nolock)  
  on  td7.PUId = prs.ReliabilityPUId   
  and td7.starttime < rs7.endtime  
  and td7.endtime > rs7.starttime   
  where rs7.PuId = prs.PuId  
  and rs7.team = prs.team  
  and rs7.shift = prs.shift  
  and rs7.prodid = prs.prodid  
  and rs7.starttime = prs.starttime  
  and rs7.endtime = prs.endtime  
  ),  
  
  
 OperationsRuntime =  
  CalendarRuntime -   
  (  
  select COALESCE(SUM(  
   case  
   --when td.ScheduleId NOT IN (@SchedPRPolyId, @SchedUnscheduledId)  
   when coalesce(td8.ScheduleId,0) NOT IN (@SchedPRPolyId, @SchedUnscheduledId, @SchedBlockedStarvedId, 0)  --FLD 01-NOV-2007 Rev11.53  
   --AND coalesce(td.ScheduleId,0)>0  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td8.StartTime <= rs8.StartTime   
    THEN rs8.StartTime   
    ELSE td8.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td8.EndTime >= rs8.EndTime   
    THEN rs8.EndTime   
    ELSE td8.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from  @RunSummary rs8  
  left join dbo.#Delays td8 with (nolock)  
  on  td8.PUId = prs.ReliabilityPUId   
  and td8.starttime < rs8.endtime  
  and td8.endtime > rs8.starttime   
  where rs8.PuId = prs.PuId  
  and rs8.team = prs.team  
  and rs8.shift = prs.shift  
  and rs8.prodid = prs.prodid  
  and rs8.starttime = prs.starttime  
  and rs8.endtime = prs.endtime  
  ),  
  
  
 TotalUnits =  
  CASE   
  WHEN @BusinessType in (1,2,4)  
  THEN  (  
   SELECT sum(convert(float,t9a.value))   
   FROM dbo.#Tests t9a with (nolock)  
   JOIN @ProdLines pl9a   
   ON t9a.VarId = pl9a.VarTotalUnitsId  
   and t9a.SampleTime > prs.StartTime   
   AND t9a.SampleTime <= prs.EndTime  
   and t9a.PLId = pl9a.PLId  
   and t9a.plid = prs.plid  
   )  
  WHEN @BusinessType = 3  
  THEN (  
   SELECT sum(convert(float,t9b.value))   
   FROM dbo.#Tests t9b with (nolock)  
   JOIN @LineProdVars lpv9b   
   ON t9b.VarId = lpv9b.VarId  
   AND t9b.SampleTime > prs.StartTime   
   AND t9b.SampleTime <= prs.EndTime  
   AND lpv9b.PLId = t9b.PLId  
   and t9b.plid = prs.plid  
   )  
  ELSE  NULL  
    END,  
  
  
 GoodUnits =   
  
  CASE    
  
  WHEN @BusinessType in (1,2)  
  THEN  (  
   SELECT sum(convert(float,t10a.value))   
   FROM dbo.#Tests t10a with (nolock)  
   JOIN @ProdLines pl10a   
   ON t10a.VarId = pl10a.VarGoodUnitsId  
   AND t10a.SampleTime > prs.StartTime   
   AND t10a.SampleTime <= prs.EndTime  
   and t10a.PLId = pl10a.PLId  
   and t10a.plid = prs.plid  
   )  
  
      WHEN @BusinessType = 3   
  THEN  (  
   SELECT sum(convert(float,t10b.value))   
   FROM dbo.#Tests t10b with (nolock)  
   JOIN @LineProdVars lpv10b   
   ON t10b.VarId = lpv10b.VarID  
   AND t10b.SampleTime > prs.StartTime   
   AND t10b.SampleTime <= prs.EndTime  
   and t10b.PLId = lpv10b.PLId  
   and t10b.plid = prs.plid  
   )  
  
  WHEN @BusinessType = 4  
  THEN  (  
   SELECT   
    Sum(coalesce(convert(float,t10c.SheetValue), 0.0))  
   FROM dbo.#Tests t10c with (nolock)  
   JOIN @LineProdVars lpv10c   
   ON t10c.VarId = lpv10c.VarId  
   where t10c.SampleTime > prs.StartTime   
   AND t10c.SampleTime <= prs.EndTime  
   and t10c.PLId = lpv10c.PLId  
   and t10c.plid = prs.plid  
   )  
  
  ELSE  NULL  
  
  END,  
  
 RollWidth2Stage =  
  
  (  
  SELECT  avg(  
   case  
   when t11.VarId = pl11.VarPMRollWidthId    
   AND convert(float,t11.Value,0) < (@DefaultPMRollWidth*1.1)  
   then convert(float,t11.value)  
   else null  -- avg() should throw out any nulls from the count  
   end  
   )  
  FROM dbo.#Tests t11 with (nolock)  
  JOIN @ProdLines pl11   
  on t11.SampleTime > prs.StartTime   
  AND t11.SampleTime <= prs.EndTime  
  and t11.plid = prs.plid  
  and t11.Plid = pl11.PlId  
  ),  
  
 RollWidth3Stage =  
  
  (  
  SELECT  avg(  
   case  
   when t12.VarId = pl12.VarParentRollWidthId   
   AND convert(float,t12.Value) < (@DefaultPMRollWidth*1.1)  
   then convert(float,t12.value)  
   else null  -- avg() should throw out any nulls from the count  
   end  
   )  
  FROM dbo.#Tests t12 with (nolock)  
  JOIN @ProdLines pl12   
  on t12.SampleTime > prs.StartTime   
  AND t12.SampleTime <= prs.EndTime  
  and t12.plid = prs.plid  
  and t12.PlId = pl12.PlId  
  )--,  
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
  and rs.team = prs.team  
  and rs.shift = prs.shift  
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
--   round(LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--   ProductionRuntime * StatFactor,0)  
   LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
   ProductionRuntime * StatFactor  
  WHEN 4   
  THEN --Hanky lines in Neuss  
--   round((LineSpeedTarget / StatFactor) * ProductionRuntime,0)   
   (LineSpeedTarget / StatFactor) * ProductionRuntime   
   --@StatFactor is really StatUnit in Neuss!!!  
       ELSE        --Tissue/Towel/Napkins  
--       round(LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
--       (1/convert(float,SheetLength)) * RollsPerLog *   
--       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--       StatFactor,0)   
       LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
       (1/convert(float,SheetLength)) * RollsPerLog *   
       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       StatFactor   
       END,  
  
 ActualUnits =   
  CASE @BusinessType  
  WHEN 1    
  THEN --Tissue/Towel  
--   round(GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
--   (1/convert(float,PacksInBundle)) * StatFactor,0)  
   (GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor)  
  WHEN 2   
  THEN --Napkins  GoodUnits = Stacks, no conversion needed.  
--   round(GoodUnits * (1/convert(float,RollsInPack)) *  
--   (1/convert(float,PacksInBundle)) * StatFactor,0)  
   GoodUnits * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor  
  WHEN 3   
  THEN --Facial (Convert Good Units on ACP to Stat)  
--   round(GoodUnits * StatFactor,0)  
   GoodUnits * StatFactor  
  WHEN 4    
  THEN  --Hanky Lines in Neuss.  Good Units = Sheets.  
    case   
    when StatFactor > 0.0  
    then GoodUnits/StatFactor  
    else null  
    end  
       --@StatFactor is really StatUnit [sheets per stat] in Neuss!!!  
  ELSE     --Else default to the Tissue/Towel Calc.  
--   round(GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
--   (1/convert(float,PacksInBundle)) * StatFactor,0)  
   GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor  
  END,  
  
 OperationsTargetUnits =   
  CASE @BusinessType  
      WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
--      round(LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--       OperationsRuntime * StatFactor,0)  
      LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       OperationsRuntime * StatFactor  
       WHEN 4   
  THEN --Hanky lines in Neuss  
--      round((LineSpeedTarget / StatFactor) * OperationsRuntime,0)   
      (LineSpeedTarget / StatFactor) * OperationsRuntime   
          --@StatFactor is really StatUnit in Neuss!!!  
       ELSE  --Tissue/Towel/Napkins  
--      round(LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
--     (1/convert(float,SheetLength)) * RollsPerLog *   
--      OperationsRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--     StatFactor,0)   
     LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
     (1/convert(float,SheetLength)) * RollsPerLog *   
     OperationsRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
     StatFactor   
       END,  
  
 IdealUnits =   
  CASE @BusinessType  
      WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
--   round(LineSpeedIdeal * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--   ProductionRuntime * StatFactor,0)  
   LineSpeedIdeal * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
   ProductionRuntime * StatFactor  
  WHEN 4   
  THEN --Hanky lines in Neuss  
--      round((LineSpeedIdeal / StatFactor) * ProductionRuntime,0)   
      (LineSpeedIdeal / StatFactor) * ProductionRuntime   
                  --@StatFactor is really StatUnit in Neuss!!!  
  ELSE        --Tissue/Towel/Napkins  
--       round(LineSpeedIdeal * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
--       (1/convert(float,SheetLength)) * RollsPerLog *   
--       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--       StatFactor,0)   
       LineSpeedIdeal * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
       (1/convert(float,SheetLength)) * RollsPerLog *   
       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       StatFactor   
  END     
   
from @ProdRecords prs  
  
/*  
--print 'Section 37 Get Pack Tests: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
----------------------------------------------------------------------------  
-- Section 37: Get Pack Test values  
----------------------------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- @PackTests is used to sum up production values for Pack Lines in the result sets.  
-- If the data for #PackTests could be efficiently integrated with #Tests,   
-- then these two tables could be eliminated.    
-------------------------------------------------------------------------------  
  
insert #LimitTests  
 (  
 result_on,  
 result,  
 var_id  
 )  
select   
 result_on,  
 result,  
 var_id  
from dbo.tests t with (nolock)  
join @ProdUnitsPack pup  
on var_id = GoodUnitsVarID  
and result_on between @StartTime and @Endtime  
option (keep plan)  
  
  
INSERT #PackTests   
   (   
   VarId,  
   PLId,  
   PUId,  
   Value,  
   SampleTime,  
   ProdId,  
   UOM  
   )  
SELECT t.Var_Id,  
   pup.PLId,  
   pup.PUId,  
   CONVERT(FLOAT, t.Result),  
   t.Result_On,  
   ps.Prod_Id,  
   pup.UOM  
FROM #LimitTests t with (nolock)  
INNER JOIN @ProdUnitsPack pup   
ON t.Var_Id = pup.GoodUnitsVarId  
and (t.Result_On > @StartTime  
AND t.Result_On <= @EndTime)  
JOIN dbo.Production_Starts ps with (nolock)  
ON pup.PUId = ps.PU_Id  
AND t.Result_On >= ps.Start_Time  
AND (t.Result_On < ps.End_Time OR ps.End_Time IS NULL)  
ORDER BY t.Var_Id,t.Result_On DESC  
option (keep plan)  
  
*/  
  
/*  
--------------------------------------------------------------------------------  
-- Section 38: Get Event_Reason and Event_Reason_Category info  
--------------------------------------------------------------------------------  
  
IF @IncludeStops = 1  
  
 insert @EventReasons  
  (  
  Event_Reason_ID,  
  Event_Reason_Name  
  )  
 select    
  distinct  
  Event_Reason_ID,  
  Event_Reason_Name  
 from dbo.Event_Reasons er with (nolock)  
 join dbo.#delays td with (nolock)  
 on Event_Reason_ID = L1ReasonId   
 or Event_Reason_ID = L2ReasonId   
 or Event_Reason_ID = L3ReasonId   
 or Event_Reason_ID = L4ReasonId   
 option (keep plan)  
*/  
  
  
--print 'Section 39 Split: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--------------------------------------------------------------------------  
-- Section 39: Split the delays and calculate Split Uptime.  
--------------------------------------------------------------------------  
  
------------------------------------------------------------------------------------------  
--  Added #SplitDowntimes and #SplitUptime for   
--  Splitting Downtime 062904  JSJ  
-------------------------------------------------------------------------------------------  
-- insert records into #SplitDowntimes for each shift period in the report window.  
-- then update the rest of the table with summary data.  
-------------------------------------------------------------------------------------------  
  
insert into dbo.#SplitDowntimes   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
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
--Rev11.55  
 RawRateloss,  
 Stops,  
 StopsUnscheduled,  
 StopsMinor,  
 StopsEquipFails,  
 StopsProcessFailures,  
 StopsBlockedStarved,  
 UpTime2m,  
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
-- UWS1Parent,  
-- UWS1GrandParent,  
-- UWS2Parent,  
-- UWS2GrandParent,  
 LineIdealSpeed,  
 Runtime,             -- 2007-03-15 VMK Rev11.37, added.  
 Comment  
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
 rls.LineStatus,  
 Downtime,  
 Uptime,  
--Rev11.55  
 RawRateloss,  
 Stops,  
 COALESCE(td.StopsUnscheduled,0),  
 StopsMinor,  
 StopsEquipFails,  
 StopsProcessFailures,  
 StopsBlockedStarved,  
 UpTime2m,  
 StopsRateLoss,  
 StopsELP,   
 CASE    
 WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
 AND (td.Downtime/60.0 >= 10.0)  
 and (td.Downtime/60.0 <= 60.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
 AND (td.Downtime/60.0 > 60.0)  
 and (td.Downtime/60.0 <= 360.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
 AND (td.Downtime/60.0 > 360.0)  
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
 AND (td.Downtime/60.0 >= 10.0)  
 and (td.Downtime/60.0 <= 60.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
 AND (td.Downtime/60.0 > 60.0)  
 and (td.Downtime/60.0 <= 360.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
 AND (td.Downtime/60.0 > 360.0)  
 THEN 1  
 ELSE 0   
 END,  
 RateLossRatio,  
 1,  
 TargetSpeed,   
 LineActualSpeed,  
-- UWS1Parent,  
-- UWS1GrandParent,  
-- UWS2Parent,  
-- UWS2GrandParent,  
 IdealSpeed,  
 DATEDIFF(ss, (CASE WHEN rls.StartTime < td.StartTime THEN   -- 2007-03-15 VMK Rev11.37, added.  
         td.StartTime ELSE rls.StartTime END),  
     (CASE WHEN rls.EndTime > td.EndTime THEN   
         td.EndTime ELSE rls.EndTime END)),  
 Comment  
-- 'Initial insert'  
FROM  @Runs rls   
JOIN  dbo.#delays td with (nolock)  
on rls.puid = td.puid   
and (((rls.starttime < td.endtime or td.endtime is null)   
and rls.endtime > td.starttime) or inRptWindow = 0)  
WHERE inRptWindow = 1  
option (keep plan)  
  
  
update dbo.#SplitDowntimes set  
 SplitDowntime = DATEDIFF(ss,StartTime,EndTime)--,  
WHERE stopsRateloss is null  
  
update td set  
  DelayType = pu.DelayType  
from dbo.#SplitDowntimes td with (nolock)  
join @produnits pu  
on td.puid = pu.puid  
  
update se set  
 SplitRLDowntime = DATEDIFF(ss,StartTime,EndTime) * RateLossRatio,  
 SplitRLELPDowntime =   
 case  
 WHEN (se.CategoryId = @CatELPId) --FLD 01-NOV-2007 Rev11.53  
--Rev11.55  
 then coalesce(RawRateloss,0.0)  
 else 0.0   
 end  
FROM dbo.#SplitDowntimes se with (nolock)  
where se.DelayType = 'RATELOSS' --@DelayTypeRateLossStr  
  
  
Update se SET   
 SplitELPDowntime =   
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (se.CategoryId = @CatELPId)  
  THEN se.Downtime  
  ELSE 0.0   
  END  
FROM dbo.#SplitDowntimes se with (nolock)  
JOIN @ProdUnits tpu   
ON se.PUId = tpu.PUId  
  
  
UPDATE se SET    
 SplitELPSchedDT =    
  CASE   
  WHEN COALESCE(se.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
          --AND se.ScheduleId IS NOT NULL    -- 2007-04-17 VMK Rev11.37, added.  
  THEN se.SplitDowntime  
  ELSE 0   
  END  
FROM dbo.#SplitDowntimes se with (nolock)  
JOIN @ProdUnits tpu   
ON se.PUId = tpu.PUId  
WHERE tpu.PUDesc LIKE '%Converter%'  
and tpu.PUDesc NOT LIKE '%rate%loss%'  
  
/*  
update se set  
 SplitUnscheduledDT =   
  case  
--20090302  
--  WHEN se.pudesc not like '%rate%loss%'  
--  and  se.pudesc not like '%converter reliability%'  
--  AND coalesce(se.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  THEN se.SplitDowntime  
--  WHEN se.pudesc like '%converter reliability%'  
--  AND coalesce(se.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
--  THEN se.SplitDowntime  
  WHEN (se.pudesc like '%reliability%' or se.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(se.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  THEN se.SplitDowntime  
  else 0.0   
  end  
from dbo.#SplitDowntimes se with (nolock)  
*/  
  
update se set  
 SplitUnscheduledDT =   
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
from dbo.#SplitDowntimes se with (nolock)    
  
  
-- after splitting events, there are some values that will   
-- no longer have any meaning and should not be included   
-- when summations are done...  
  
--Rev11.55  
update dbo.#SplitDowntimes set  
 Downtime = null,  
 Uptime = null,  
 Stops = null,  
 StopsMinor = null,  
 StopsEquipFails = null,  
 StopsProcessFailures = null,  
 StopsELP = null,  
 StopsRateLoss = null,  
 StopsUnscheduled = null,  
 RawRateloss = null,  
 SplitELPDowntime = null,  
 SplitRLELPDowntime = null,  
 UpTime2m = null,  
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
 WHERE td.puid = dbo.#SplitDowntimes.puid   
 and td.starttime = dbo.#SplitDowntimes.starttime  
 ) = 0  
  
  
-- this field is used to simplify the initial insert to   
-- #splituptime, and to make that insert more efficient.  
-- the original version of that insert required a nested   
-- subquery, and adding this field allows us to eliminate   
-- that.  
  
--update se1 set  
-- se1.NextStartTime =   
--  (  
--  select top 1 starttime   
--  from dbo.#SplitDowntimes se2 with (nolock)  
--  where se1.puid = se2.puid  
--  and se1.seid < se2.seid  
--  order by se2.seid asc  
--  )  
--from dbo.#SplitDowntimes se1 with (nolock)  
  
update se1 set  
 se1.NextStartTime =   
  (  
  select top 1 se2.starttime   
  from dbo.#SplitDowntimes se2 with (nolock)  
  where se1.puid = se2.puid  
  and se1.endtime <= se2.starttime  
  and se1.seid < se2.seid  
  order by se2.puid, se2.starttime  
  )  
from dbo.#SplitDowntimes se1 with (nolock)  
  
  
--print 'Split Uptime ' + CONVERT(VARCHAR(20), GetDate(), 120)  
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
 LineTargetSpeed,  
 LineIdealSpeed,  
 SplitUptime,  
 LineStatus,  
 Comment  
 )  
SELECT distinct  
 case   
 when se1.endtime > rls.starttime and se1.endtime <= rls.endtime  
 then se1.EndTime  
 else rls.StartTime end,  
 case   
 when NextStartTime >= rls.starttime and NextStartTime < rls.endtime  
 then NextStartTime   
 else rls.EndTime end,  
 rls.prodid,   
 rls.PLID,  
 rls.puid,  
 se1.pudesc,  
 rls.Team,  
 rls.Shift,  
 rls.TargetSpeed,  
 rls.IdealSpeed,  
 0,  
 rls.LineStatus, --NULL,  
 'Split Uptime: Initial Load'   
FROM @Runs rls   
join dbo.#SplitDowntimes se1 with (nolock)  
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
 LineTargetSpeed,  
 LineIdealSpeed,  
 SplitUptime,  
 LineStatus,  
 Comment  
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
 rls.TargetSpeed,  
 rls.IdealSpeed,  
 0,  
 rls.LineStatus, --NULL,  
 'Split Uptime: Start of Window'  
FROM  @Runs rls   
join  dbo.#SplitDowntimes se with (nolock)  
on  rls.puid = se.puid  
and (rls.starttime < se.starttime   
and  rls.endtime > se.starttime)  
and  se.StartTime =   
 (  
 SELECT min(StartTime)  
 FROM dbo.#SplitDowntimes se1 with (nolock)  
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
 pudesc,  
 Team,   
 Shift,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 SplitUptime,  
 LineStatus,  
 Comment   
 )  
SELECT distinct  
 rls.starttime,  
 rls.endtime,  
 rls.prodid,  
 rls.PLID,  
 rls.puid,  
 pu.pudesc,  
 rls.Team,  
 rls.Shift,  
 rls.TargetSpeed,  
 rls.IdealSpeed,  
 0,  
 rls.LineStatus,  
 'Split Uptime: No Events'  
FROM  @Runs rls    
join @produnits pu  
on rls.puid = pu.puid  
WHERE    
 (  
 SELECT count(*)   
 FROM dbo.#SplitDowntimes se with (nolock)  
 where rls.puid = se.puid  
 and rls.starttime < se.endtime   
 and rls.endtime > se.starttime  
 and rls.prodid = se.prodid  
 and (rls.team = se.team) --or (rls.team is null and se.team is null))  
 and (rls.shift = se.shift) --or (rls.shift is null and se.shift is null))    
 ) = 0  
 and  (  
   pu.pudesc like '%reliability%'  
   or pu.pudesc like '%rate%loss%'  
   --or pudesc like '%sheet%break%'  
   )  
option (keep plan)     
  
  
update dbo.#SplitUptime set  
 pudesc =    
  (  
  SELECT top 1 pudesc   
  FROM @produnits pu --dbo.#SplitDowntimes se  
  WHERE pu.puid = dbo.#SplitUptime.puid  
  ),  
 SplitUptime = DATEDIFF(ss,StartTime,EndTime),  
 suid =  
  (  
  SELECT top 1 seid  
  FROM dbo.#SplitDowntimes se with (nolock)  
  where se.puid = dbo.#SplitUptime.puid   
  and (se.StartTime = dbo.#SplitUptime.EndTime   
    or dbo.#SplitUptime.EndTime is null)  
  )  
  
  
update dbo.#SplitDowntimes set  
 SplitUptime =  
 (  
 SELECT sum(SplitUptime)  
 FROM dbo.#SplitUptime su with (nolock)  
 where su.puid = dbo.#SplitDowntimes.puid  
 and su.EndTime = dbo.#SplitDowntimes.StartTime  
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
  
  
-- add the uptime into the #SplitDowntimes  
--print 'add uptime ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
insert into dbo.#SplitDowntimes   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 Downtime,  
 SplitDowntime,  
 SplitRLDowntime,  
 Uptime,  
 SplitUptime,  
 LineStatus,   
 Comment  
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
 LineTargetSpeed,  
 LineIdealSpeed,  
 0,0,0,0,  
 SplitUptime,  
 LineStatus,   
 --Comment  
 'This record artificially created for the sole purpose of allocating uptime that spans changes in shift/team, product, line status and/or the report end time.'--,  
FROM dbo.#SplitUptime with (nolock)  
WHERE suid is null  
and  (  
 SELECT pu_desc   
 FROM dbo.prod_units with (nolock)  
 WHERE pu_id = dbo.#SplitUptime.puid  
 ) not like '%rate loss%'   
option (keep plan)  
  
/*  
--print 'LineSpeedAvg ' + CONVERT(VARCHAR(20), GetDate(), 120)  
update su set  
 LineSpeedAvg =  
  
  (  
  SELECT   
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t.SampleTime) < su1.starttime   
     and t.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t.SampleTime)  
     end,  
     case   
     when t.SampleTime > su1.endtime   
     and dateadd(mi, -15, t.SampleTime) < su1.endtime  
     then su1.endtime  
     else t.SampleTime   
     end  
     ) * coalesce(convert(float,t.value),0.0)  
   ) /  
   convert(float,  
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t.SampleTime) < su1.starttime   
     and t.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t.SampleTime)  
     end,  
     case   
     when t.SampleTime > su1.endtime   
     and dateadd(mi, -15, t.SampleTime) < su1.endtime  
     then su1.endtime  
     else t.SampleTime   
     end  
     )  
    ))        
  from @ProdLines pl   
  join dbo.#splituptime su1 with (nolock)  
  on su1.puid = pl.reliabilitypuid  
  left join dbo.#Tests t with (nolock)  
  on t.puid = pl.prodpuid  
  and t.VarId = pl.VarLineSpeedId   
  and su1.StartTime < t.SampleTime   
  and su1.EndTime > dateadd(mi, -15, t.SampleTime)  
  where su1.puid = su.puid  
  and su1.starttime = su.starttime  
  )  
from dbo.#splituptime su with (nolock)  
  
  
update pr set  
  
 LineSpeedAvg =  
  (  
  SELECT   
   sum(convert(float,datediff  
     (  
     ss,  
     case   
     when su.starttime < pr1.starttime   
     and su.endtime > pr1.starttime  
     then pr1.starttime  
     else su.starttime  
     end,  
     case   
     when su.endtime > pr1.endtime   
     and su.starttime < pr1.endtime  
     then pr1.endtime  
     else su.endtime  
     end  
     )) * coalesce(su.LineSpeedAvg,0.0)  
   ) /  
   sum(convert(float,datediff  
     (  
     ss,  
     case   
     when su.starttime < pr1.starttime   
     and su.endtime > pr1.starttime  
     then pr1.starttime  
     else su.starttime  
     end,  
     case   
     when su.endtime > pr1.endtime   
     and su.starttime < pr1.endtime  
     then pr1.endtime  
     else su.endtime  
     end  
     )  
   ))  
  from @ProdRecords pr1  
  join dbo.#SplitUptime su with (nolock)  
  on pr1.puid = su.puid  
  and pr1.starttime < su.endtime  
  and pr1.endtime > su.starttime  
  and pr1.team = su.team  
  and pr1.prodid = su.prodid  
  and pr1.linestatus = su.linestatus  
  where pr1.puid = pr.puid  
  and pr1.starttime = pr.starttime  
  and pr1.team = pr.team  
  and pr1.prodid = pr.prodid  
  and pr1.linestatus = pr.linestatus  
  ),  
  
 SplitUptime =  
  (  
  select  
   sum(datediff  
     (  
     ss,  
     case   
     when su.starttime < pr1.starttime   
     and su.endtime > pr1.starttime  
     then pr1.starttime  
     else su.starttime  
     end,  
     case   
     when su.endtime > pr1.endtime   
     and su.starttime < pr1.endtime  
     then pr1.endtime  
     else su.endtime  
     end  
     )  
    )  
  from @ProdRecords pr1  
  join dbo.#SplitUptime su with (nolock)  
  on pr1.puid = su.puid  
  and pr1.starttime < su.endtime  
  and pr1.endtime > su.starttime  
  and pr1.team = su.team  
  and pr1.prodid = su.prodid  
  and pr1.linestatus = su.linestatus  
  where pr1.puid = pr.puid  
  and pr1.starttime = pr.starttime  
  and pr1.team = pr.team  
  and pr1.prodid = pr.prodid    
  and pr1.linestatus = pr.linestatus  
  )  
  
from @ProdRecords pr  
*/  
  
--print 'LineSpeedAvg 1 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--/*  
update su set  
 LineSpeedAvg =  
  
  (  
  SELECT   
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t1.SampleTime) < su1.starttime   
     and t1.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t1.SampleTime)  
     end,  
     case   
     when t1.SampleTime > su1.endtime   
     and dateadd(mi, -15, t1.SampleTime) < su1.endtime  
     then su1.endtime  
     else t1.SampleTime   
     end  
     ) *   
     (  
     case  
     when isnumeric(t1.value) = 1  
     then coalesce(convert(float,t1.value),0.0)  
     else 0.0  
     end  
     )  
   ) /  
   convert(float,  
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t1.SampleTime) < su1.starttime   
     and t1.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t1.SampleTime)  
     end,  
     case   
     when t1.SampleTime > su1.endtime   
     and dateadd(mi, -15, t1.SampleTime) < su1.endtime  
     then su1.endtime  
     else t1.SampleTime   
     end  
     )  
    ))        
  from @ProdLines pl1 --with (nolock)-- Rev11.33  
  join dbo.#splituptime su1 with (nolock)  
  on su1.puid = pl1.reliabilitypuid  
--  left join dbo.#Tests t with (nolock)  
--  on t.puid = pl.prodpuid  
--  and t.VarId = pl.VarLineSpeedId   
--  and su1.StartTime < t.SampleTime   
--  and su1.EndTime > dateadd(mi, -15, t.SampleTime)  
  join dbo.#Tests t1 with (nolock)  
  on t1.VarId = pl1.VarLineSpeedId   
  and t1.SampleTime > su1.StartTime   
  and dateadd(mi, -15, t1.SampleTime) < su1.EndTime  
  where su1.puid = su.puid  
  and su1.starttime = su.starttime  
  )  
from dbo.#splituptime su with (nolock)  
--*/  
/*  
update su set  
 LineSpeedAvg =  
  
  (  
  SELECT   
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t.SampleTime) < su1.starttime   
     and t.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t.SampleTime)  
     end,  
     case   
     when t.SampleTime > su1.endtime   
     and dateadd(mi, -15, t.SampleTime) < su1.endtime  
     then su1.endtime  
     else t.SampleTime   
     end  
     ) * coalesce(convert(float,t.value),0.0)  
   ) /  
   convert(float,  
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t.SampleTime) < su1.starttime   
     and t.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t.SampleTime)  
     end,  
     case   
     when t.SampleTime > su1.endtime   
     and dateadd(mi, -15, t.SampleTime) < su1.endtime  
     then su1.endtime  
     else t.SampleTime   
     end  
     )  
    ))        
  from @prodlines pl --with (nolock)-- Rev11.33  
  join dbo.#splituptime su1 with (nolock)  
  on su1.puid = pl.reliabilitypuid  
  left join dbo.#Tests t with (nolock)  
  on t.puid = pl.prodpuid  
  and t.VarId = pl.VarLineSpeedId   
  and su1.StartTime < t.SampleTime   
  and su1.EndTime > dateadd(mi, -15, t.SampleTime)  
  where su1.puid = su.puid  
  and su1.starttime = su.starttime  
  )  
from dbo.#splituptime su with (nolock)  
*/  
  
--print 'LineSpeedAvg 2 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pr set  
  
 LineSpeedAvg =  
  (  
  SELECT   
   sum(convert(float,datediff  
     (  
     ss,  
     case   
     when su1.starttime < pr1.starttime   
     and su1.endtime > pr1.starttime  
     then pr1.starttime  
     else su1.starttime  
     end,  
     case   
     when su1.endtime > pr1.endtime   
     and su1.starttime < pr1.endtime  
     then pr1.endtime  
     else su1.endtime  
     end  
     )) * coalesce(su1.LineSpeedAvg,0.0)  
   ) /  
   sum(convert(float,datediff  
     (  
     ss,  
     case   
     when su1.starttime < pr1.starttime   
     and su1.endtime > pr1.starttime  
     then pr1.starttime  
     else su1.starttime  
     end,  
     case   
     when su1.endtime > pr1.endtime   
     and su1.starttime < pr1.endtime  
     then pr1.endtime  
     else su1.endtime  
     end  
     )  
   ))  
  from @ProdRecords pr1  
  join dbo.#SplitUptime su1 with (nolock)  
  on pr1.puid = su1.puid  
  and pr1.starttime < su1.endtime  
  and pr1.endtime > su1.starttime  
  and pr1.team = su1.team  
  and pr1.prodid = su1.prodid  
  and pr1.linestatus = su1.linestatus  
  where pr1.puid = pr.puid  
  and pr1.starttime = pr.starttime  
  and pr1.team = pr.team  
  and pr1.prodid = pr.prodid  
  and pr1.linestatus = pr.linestatus  
  ),  
  
 SplitUptime =  
  (  
  select  
   sum(datediff  
     (  
     ss,  
     case   
     when su2.starttime < pr2.starttime   
     and su2.endtime > pr2.starttime  
     then pr2.starttime  
     else su2.starttime  
     end,  
     case   
     when su2.endtime > pr2.endtime   
     and su2.starttime < pr2.endtime  
     then pr2.endtime  
     else su2.endtime  
     end  
     )  
    )  
  from @ProdRecords pr2  
  join dbo.#SplitUptime su2 with (nolock)  
  on pr2.puid = su2.puid  
  and pr2.starttime < su2.endtime  
  and pr2.endtime > su2.starttime  
  and pr2.team = su2.team  
  and pr2.prodid = su2.prodid  
  and pr2.linestatus = su2.linestatus  
  where pr2.puid = pr.puid  
  and pr2.starttime = pr.starttime  
  and pr2.team = pr.team  
  and pr2.prodid = pr.prodid    
  and pr2.linestatus = pr.linestatus  
  )  
  
from @ProdRecords pr  
  
  
----------------------------------  
-- get PRDTMetrics  
----------------------------------  
  
-- Rev11.55  
-----------------  
-- get metrics  
-----------------  
  
--print 'SplitPRsRun ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
-- Rev11.55  
update prs set  
 PRPLID = pu.pl_id  
from dbo.#prsrun prs with (nolock)  
join dbo.prod_units pu  
on prs.prpuid = pu.pu_id  
  
  
-- Rev11.55  
insert dbo.#SplitPRsRun  
 (  
 id_num,  
 ShiftStart,  
 LineStatus,  
   [StartTime],  
   [EndTime],  
 [PLID],  
 [PUID],  
 [Team],  
 [ProdID],  
   [PRPLID],  
   [PRPUID],  
 DevComment   
 )  
select  
 distinct  
 prs.id_num,  
 ts.ShiftStart,  
 ts.LineStatus,  
 case when ts.StartTime < prs.StartTime  
 then prs.StartTime else ts.StartTime end,  
 case when (coalesce(ts.EndTime,prs.endtime) >= prs.EndTime)  
 then prs.EndTime else ts.EndTime end,  
 ts.[PLID],  
 ts.[PUID],  
 ts.[Team],  
 ts.[ProdID],  
   prs.[PRPLID],  
   prs.[PRPUID],  
 'Cvtg Line Team Prod' --DevComment   
from @runs ts   
left join dbo.#PRsRun prs with (nolock)   
on prs.plid = ts.plid  
and (ts.starttime < prs.endtime or prs.endtime is null)   
and ts.endtime > prs.starttime  
option (keep plan)  
  
  
--/*  
-- this update depends on the data being ordered by starttime and endtime within the puid.  
-- changes to the clustered index on the table may cause these id_nums to not be updated correctly.  
  
declare @NewIDNum int  
select @NewIDNum = (select max(id_num) + 1 from dbo.#SplitPRsRun  with (nolock))  
  
update sprs set  
 id_num = @NewIDNum,  
 @NewIDNum = @NewIDNum + 1  
from dbo.#SplitPRsRun sprs with (nolock)  
where id_num is null  
--*/  
  
  
--print 'Time Ranges ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
-- Rev11.55  
update pdr set  
  
 StartTime_Unit =  
  coalesce(  
  (  
  select  
   case   
   when max(pr1.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr1.EndTime)  
   end     
  from dbo.#SplitPRsRun pr1 with (nolock)  
  where pr1.PuID = pdr.PuID  
  and pr1.StartTime < pdr.StartTime   
  and pr1.EndTime > pdr.StartTime   
  ),pdr.StartTime),  
  
 EndTime_Unit =  
  coalesce(  
  (  
  select  
   case   
   when min(pr2.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr2.StartTime)  
   end  
  from dbo.#SplitPRsRun pr2 with (nolock)  
  where pr2.PuID = pdr.PuID  
  and pr2.StartTime < pdr.EndTime   
  and pr2.EndTime > pdr.EndTime   
  ),pdr.EndTime)  
  
from dbo.#SplitPRsRun pdr with (nolock)  
  
  
  
--print 'Time Range Updates 7 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_Unit = pdr.EndTime_Unit  
from dbo.#SplitPRsRun pdr with (nolock)  
where pdr.StartTime_Unit > pdr.EndTime_Unit  
  
/*  
--print 'Time Range Updates 8 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_Unit = pdr.EndTime_Unit  
from dbo.#SplitPRsRun pdr with (nolock)  
join dbo.#SplitPRsRun pr with (nolock)  
on pr.PuID = pdr.PuID  
and (pr.StartTime_Unit = pdr.StartTime_Unit  
    or pr.EndTime_Unit = pdr.EndTime_Unit)  
and datediff(ss,pr.StartTime_Unit, pr.EndTime_Unit)   
    > datediff(ss,pdr.StartTime_Unit, pdr.EndTime_Unit)  
  
  
--print 'Time Range Updates 9 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_Unit = pdr.EndTime_Unit  
from dbo.#SplitPRsRun pdr with (nolock)  
join dbo.#SplitPRsRun pr with (nolock)  
on pr.PuID = pdr.PuID  
and (pr.StartTime_Unit = pdr.StartTime_Unit  
    and pr.EndTime_Unit = pdr.EndTime_Unit)  
and pr.id_num > pdr.id_num  
  
*/  
  
--print 'Time Range Updates 5 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_Unit = pdr.EndTime_Unit  
from dbo.#SplitPRsRun pdr with (nolock)  
join dbo.#SplitPRsRun pr with (nolock)  
on pr.PuID = pdr.PuID  
--Rev11.63  
and pdr.StartTime_Unit < pdr.EndTime_Unit  
and pr.StartTime_Unit < pr.EndTime_Unit  
--Rev11.63  
where (pr.StartTime_Unit = pdr.StartTime_Unit  
    or pr.EndTime_Unit = pdr.EndTime_Unit)  
and datediff(ss,pr.StartTime_Unit, pr.EndTime_Unit)   
    > datediff(ss,pdr.StartTime_Unit, pdr.EndTime_Unit)  
  
  
--print 'Time Range Updates 6 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_Unit = pdr.EndTime_Unit  
from dbo.#SplitPRsRun pdr with (nolock)   
join dbo.#SplitPRsRun pr with (nolock)   
on pr.PuID = pdr.PuID  
--Rev11.63  
and pdr.StartTime_Unit < pdr.EndTime_Unit  
and pr.StartTime_Unit < pr.EndTime_Unit  
--Rev11.63  
where (pr.StartTime_Unit = pdr.StartTime_Unit  
    and pr.EndTime_Unit = pdr.EndTime_Unit)  
and pr.id_num > pdr.id_num  
  
  
----- by Line  
--print 'Line Metrics ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
/*  
-- Rev11.55  
insert @ELPMetrics_Unit  
 (   
 id_num,  
 [PuID],  
 LineStatus,  
 StartTime,  
 EndTime,  
----- Metric by Unit  
 [ELPSchedDT],  
 [HolidayCurtailDT]  
 )    
select --distinct  
 prs.id_num,  
 prs.PuID,  
 prs.LineStatus,  
  
 prs.StartTime_Unit,  
 prs.EndTime_Unit,  
  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0)   
  and td.DelayType <> @DelayTypeRateLossStr  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTime_Unit  
      and td.EndTime > prs.StartTime_Unit  
      then prs.Starttime_Unit  
      when td.StartTime > prs.StartTime_Unit  
      and td.StartTime < prs.EndTime_Unit  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTime_Unit  
      and td.EndTime >= prs.EndTime_Unit  
      then prs.Endtime_Unit  
      when td.EndTime > prs.StartTime_Unit  
      and td.EndTime < prs.EndTime_Unit  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDT,  
  
 SUM(  
  CASE   
  WHEN td.ScheduleId = @SchedHolidayCurtailId   
  and td.starttime >= prs.starttime_Unit  
  and (td.starttime < prs.endtime_Unit or prs.endtime_Unit is null)  
  and td.DelayType <> @DelayTypeRateLossStr  
  then  
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTime_Unit  
      and td.EndTime > prs.StartTime_Unit  
      then prs.Starttime_Unit  
      when td.StartTime > prs.StartTime_Unit  
      and td.StartTime < prs.EndTime_Unit  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTime_Unit  
      and td.EndTime >= prs.EndTime_Unit  
      then prs.Endtime_Unit  
      when td.EndTime > prs.StartTime_Unit  
      and td.EndTime < prs.EndTime_Unit  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0.0   
  END  
  ) [HolidayCurtailDT]  
  
from dbo.#SplitPRsRun prs with (nolock)  
left join dbo.#SplitDowntimes td with (nolock)  
on prs.puid = td.puid   
and td.starttime < prs.endtime --or prs.endtime is null)   
and td.endtime > prs.starttime --or td.endtime is null)   
--and td.pudesc like '%Converter Reliability%'  
where prs.starttime_Unit < prs.endtime_Unit  
group by prs.id_num, prs.PuID, prs.LineStatus,   
prs.starttime_Unit, prs.endtime_Unit  
  
--update pdm set  
-- PaperRuntimeRaw = DATEDIFF(ss,StartTime,EndTime)  
--from dbo.#ELPMetrics_Unit pdm with (nolock)  
  
update pdm set  
 PaperRuntimeRaw =   
  DATEDIFF(ss,    
     CASE   
     WHEN StartTime < @StartTime   
     THEN @StartTime   
     ELSE StartTime  
     END,  
     CASE   
     WHEN EndTime > @EndTime   
     THEN @EndTime   
     ELSE EndTime  
     END  
    )  
from @ELPMetrics_Unit pdm  
join @produnits pu  
on pdm.puid = pu.puid  
where pudesc not like '%rate%loss%'  
and pudesc not like '%block%starv%'  
  
  
--print 'Line Updates ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
insert @PRDTSums_Unit  
 (   
 [PuID],  
----- Metics by Line  
 [PaperRuntimeRaw],  
 [ELPSchedDT],  
 [HolidayCurtailDT]  
 )    
select  
 prs.[PuID],  
----- Metics by Line  
 sum(prs.PaperRuntimeRaw),  
 sum(prs.ELPSchedDT),  
 sum(prs.HolidayCurtailDT)  
from @ELPMetrics_Unit prs  
--where (charindex('|' + prs.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
--or @LineStatusList = 'All')   
group by prs.PuID  
  
  
insert @SplitDT_Unit  
 (  
 [PuID],  
 [Stops],  
 [StopsUnscheduled],  
 [StopsMinor],  
 [StopsEquipFails],  
 [StopsProcessFailures],  
 [SplitDowntime],  
 [UnschedSplitDT],  
 [RawUptime],  
 [SplitUptime],  
 [Uptime2Min],  
 [R2Numerator],  
 [R2Denominator],  
-- [HolidayCurtailDT],  
 [StopsELP],  
 [ELPDowntime],  
 [RLELPDowntime],  
 [StopsRateLoss],  
 [SplitRLDowntime],  
 [PRPolyChangeEvents],  
 [PRPolyChangeDowntime]  
 )  
select  
 td.puid,  
 SUM(td.Stops) [Stops],  
 SUM(td.StopsUnscheduled) [StopsUnscheduled],  
 SUM(td.StopsMinor) [StopsMinor],  
 SUM(td.StopsEquipFails) [StopsEquipFails],  
 SUM(td.StopsProcessFailures) [StopsProcessFailures],  
  
  
 SUM(td.SplitDowntime) [SplitDowntime],  
  
  
 sum(COALESCE(td.SplitUnscheduledDT,0.0)) [UnschedSplitDT],  
  
  
 sum(td.Uptime) [RawUptime],  
  
 SUM(td.SplitUptime) [SplitUptime],  
       
 SUM(  
   (  
   CASE    
   WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
   AND td.Uptime2m = 1   
   THEN (COALESCE(td.Stops,0))  
   ELSE 0   
   END  
   )  
  )  [Uptime2Min],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  AND td.Uptime2m = 1   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Numerator],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Denominator],  
  
 SUM(td.StopsELP) [StopsELP],  
  
 Sum(td.SplitELPDownTime) [ELPDowntime],  
 Sum(td.SplitRLELPDownTime) [RLELPDowntime],  
 SUM(td.StopsRateLoss) [StopsRateLoss],  
 SUM(td.SplitRLDowntime) [SplitRLDowntime],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then coalesce(td.stops,0)   -- 2005-DEC-15 Vince King  Rev11.12  
  else 0   
  end  
  ) [PRPolyChangeEvents],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then td.downtime   
  else 0.0   
  end  
  ) [PRPolyChangeDowntime]--,  
  
from dbo.#SplitDowntimes td with (nolock)  
--where td.pudesc like '%Converter Reliability%'  
--or td.pudesc like '%rate%loss%'  
group by td.plid, td.puid   
  
  
update prs set  
 [Stops] = dm.Stops,  
 [StopsUnscheduled] = dm.StopsUnscheduled,  
 [StopsMinor] = dm.StopsMinor,  
 [StopsEquipFails] = dm.StopsEquipFails,  
 [StopsProcessFailures] = dm.StopsProcessFailures,  
 [SplitDowntime] = dm.SplitDowntime,  
 [UnschedSplitDT] = dm.UnschedSplitDT,  
 [RawUptime] = dm.RawUptime,  
 [SplitUptime] = dm.SplitUptime,  
 [Uptime2Min] = dm.Uptime2Min,  
 [R2Numerator] = dm.R2Numerator,  
 [R2Denominator] = dm.R2Denominator,  
 [Runtime] = coalesce(dm.SplitDowntime,0.0) + coalesce(dm.SplitUptime,0.0), -- datediff(ss,@starttime,@endtime), --   
-- [HolidayCurtailDT] = dm.HolidayCurtailDT,  
 [StopsELP] = dm.StopsELP,  
 [ELPDowntime] = dm.ELPDownTime,  
 [RLELPDowntime] = dm.RLELPDownTime,  
 [StopsRateLoss] = dm.StopsRateLoss,  
 [SplitRLDowntime] = dm.SplitRLDowntime,  
 [PRPolyChangeEvents] = dm.PRPolyChangeEvents,  
 [PRPolyChangeDowntime] = dm.PRPolyChangeDowntime  
from @PRDTSums_Unit prs  
join @SplitDT_Unit dm  
on prs.puid = dm.puid  
  
  
update pdm set  
 [ELPMins] = coalesce(ELPDowntime,0.0) + coalesce(RLELPDowntime,0.0),  
   [PaperRuntime] =   
  case  
  when PaperRuntimeRaw > 0.0  
  then coalesce(PaperRuntimeRaw,0.0) - coalesce(ELPSchedDT,0.0)  
  else 0.0  
  end,  
   [ProductionRuntime] =   
  case  
  when Runtime > 0.0  
  then coalesce(Runtime,0.0) - coalesce(HolidayCurtailDT,0.0)  
  else 0.0  
  end  
from @PRDTSums_Unit pdm  
--join @produnits pu  
--on pu.puid = pdm.puid  
--where pudesc not like '%rate%loss%'  
--and pudesc not like '%block%starv%'  
  
update pdm set   
 puid = pl.reliabilitypuid  
from @PRDTSums_Unit pdm  
join @produnits pu  
on pdm.puid = pu.puid  
join @prodlines pl  
on pu.plid = pl.plid  
where pu.pudesc like '%rate%loss%'   
  
update pdu set  
 plid = pu.plid  
from @PRDTSums_Unit pdu  
join @produnits pu  
on pdu.puid = pu.puid  
*/  
  
-- Rev11.55  
insert @ELPMetrics_Unit  
 (   
 id_num,  
 [PLID],  
 [PUID],  
 LineStatus,  
 StartTime,  
 EndTime,  
----- Metric by Unit  
 [ELPSchedDT]--,  
 )    
select  
 prs.id_num,  
 prs.PLID,  
 prs.puid, --td.PUID,  
 prs.LineStatus,  
 prs.StartTime_Unit,  
 prs.EndTime_Unit,  
----- Metric by Unit  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  and tpu.DelayType <> @DelayTypeRateLossStr  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTime_Unit  
      and td.EndTime > prs.StartTime_Unit  
      then prs.Starttime_Unit  
      when td.StartTime > prs.StartTime_Unit  
      and td.StartTime < prs.EndTime_Unit  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTime_Unit  
      and td.EndTime >= prs.EndTime_Unit  
      then prs.Endtime_Unit  
      when td.EndTime > prs.StartTime_Unit  
      and td.EndTime < prs.EndTime_Unit  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDT--,  
from @ProdUnits tpu   
left join dbo.#SplitPRsRun prs with (nolock)   
ON prs.PUId = tpu.PUId  
left join dbo.#SplitDowntimes td with (nolock)  
on prs.puid = td.puid   
and (td.starttime < prs.endtime)   
and (td.endtime > prs.starttime)   
where prs.starttime_Unit < prs.endtime_Unit  
group by prs.id_num, prs.PLID, prs.puid, --td.PUID, td.team,   
prs.LineStatus, prs.starttime_Unit, prs.endtime_Unit  
  
update pdm set  
 PaperRuntimeRaw =   
  DATEDIFF(ss,    
     CASE   
     WHEN StartTime < @StartTime   
     THEN @StartTime   
     ELSE StartTime  
     END,  
     CASE   
     WHEN EndTime > @EndTime   
     THEN @EndTime   
     ELSE EndTime  
     END  
    )  
from @ELPMetrics_Unit pdm  
join @produnits pu  
on pdm.puid = pu.puid  
where pudesc not like '%rate%loss%'  
and pudesc not like '%block%starv%'  
  
  
--print 'Unit Updates ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
insert @PRDTSums_Unit  
 (   
 [PLID],  
 [PuID],  
----- Metics by Line  
 [PaperRuntimeRaw],  
 [ELPSchedDT]--,  
 )    
select  
 prs.[PLID],  
 prs.[PuID],  
----- Metics by Line  
 sum(prs.PaperRuntimeRaw),  
 sum(prs.ELPSchedDT)--,  
from @ELPMetrics_Unit prs  
--where (charindex('|' + prs.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
--or @LineStatusList = 'All')   
group by prs.PLID, prs.PuID  
  
  
insert @SplitDT_Unit  
 (  
 [PLID],  
 [PuID],  
 [Stops],  
 [StopsUnscheduled],  
 [StopsMinor],  
 [StopsEquipFails],  
 [StopsProcessFailures],  
 [SplitDowntime],  
 [UnschedSplitDT],  
 [RawUptime],  
 [SplitUptime],  
 [Uptime2Min],  
 [R2Numerator],  
 [R2Denominator],  
 [StopsELP],  
 [ELPDowntime],  
 [RLELPDowntime],  
 [StopsRateLoss],  
 [SplitRLDowntime],  
 [PRPolyChangeEvents],  
 [PRPolyChangeDowntime],  
 [HolidayCurtailDT]  
 )  
select  
 td.plid,  
 td.puid,  
-- td.team,  
  
 SUM(td.Stops) [Stops],  
 SUM(td.StopsUnscheduled) [StopsUnscheduled],  
  
 SUM(td.StopsMinor) [StopsMinor],  
 SUM(td.StopsEquipFails) [StopsEquipFails],  
 SUM(td.StopsProcessFailures) [StopsProcessFailures],  
  
 SUM(td.SplitDowntime) [SplitDowntime],  
  
 sum(COALESCE(td.SplitUnscheduledDT,0.0)) [UnschedSplitDT],  
  
 sum(td.Uptime) [RawUptime],  
 SUM(td.SplitUptime) [SplitUptime],  
  
 SUM(--CONVERT(FLOAT,   
   (  
   CASE    
   WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
   AND td.Uptime2m = 1   
   THEN (COALESCE(td.Stops,0))  
   ELSE 0 END)--)  
  )  [Uptime2Min],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  AND td.Uptime2m = 1   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Numerator],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Denominator],  
  
 SUM(td.StopsELP) [StopsELP],  
 Sum(td.SplitELPDownTime) [ELPDowntime],  
 Sum(td.SplitRLELPDownTime) [RLELPDowntime],  
  
 SUM(td.StopsRateLoss) [StopsRateLoss],  
 SUM(td.SplitRLDowntime) [SplitRLDowntime],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then coalesce(stops,0)   -- 2005-DEC-15 Vince King  Rev11.12  
  else 0   
  end  
  ) [PRPolyChangeEvents],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then downtime   
  else 0.0   
  end  
  ) [PRPolyChangeDowntime],  
 sum(  
  CASE   
  WHEN td.ScheduleId = @SchedHolidayCurtailId   
  and td.DelayType <> @DelayTypeRateLossStr  
  then td.SplitDowntime  
  else 0.0  
  end  
  ) [HolidayCurtailDT]  
from dbo.#SplitDowntimes td with (nolock)  
group by td.plid, td.puid --, td.team   
  
  
update prs set  
 [Stops] = dm.Stops,  
 [StopsUnscheduled] = dm.StopsUnscheduled,  
 [StopsMinor] = dm.StopsMinor,  
 [StopsEquipFails] = dm.StopsEquipFails,  
 [StopsProcessFailures] = dm.StopsProcessFailures,  
 [SplitDowntime] = dm.SplitDowntime,  
 [UnschedSplitDT] = dm.UnschedSplitDT,  
 [RawUptime] = dm.RawUptime,  
 [SplitUptime] = dm.SplitUptime,  
 [Uptime2Min] = dm.Uptime2Min,  
 [R2Numerator] = dm.R2Numerator,  
 [R2Denominator] = dm.R2Denominator,  
 [Runtime] = coalesce(dm.SplitDowntime,0.0) + coalesce(dm.SplitUptime,0.0),   
 [StopsELP] = dm.StopsELP,  
 [ELPDowntime] = dm.ELPDownTime,  
 [RLELPDowntime] = dm.RLELPDownTime,  
 [StopsRateLoss] = dm.StopsRateLoss,  
 [SplitRLDowntime] = dm.SplitRLDowntime,  
 [PRPolyChangeEvents] = dm.PRPolyChangeEvents,  
 [PRPolyChangeDowntime] = dm.PRPolyChangeDowntime,  
 [HolidayCurtailDT] = dm.HolidayCurtailDT  
from @PRDTSums_Unit prs  
join @SplitDT_Unit dm  
on prs.puid = dm.puid  
  
  
update pdm set  
 [ELPMins] = coalesce(ELPDowntime,0.0) + coalesce(RLELPDowntime,0.0),  
   [PaperRuntime] =   
  case  
  when PaperRuntimeRaw > 0.0  
  then coalesce(PaperRuntimeRaw,0.0) - coalesce(ELPSchedDT,0.0)  
  else 0.0  
  end,  
   [ProductionRuntime] =   
  case  
  when Runtime > 0.0  
  then coalesce(Runtime,0.0) - coalesce(HolidayCurtailDT,0.0)  
  else 0.0  
  end  
from @PRDTSums_Unit pdm  
  
update pdm set   
 puid = pl.reliabilitypuid  
from @PRDTSums_Unit pdm  
join @prodlines pl  
on pdm.plid = pl.plid  
join @produnits pu  
on pdm.puid = pu.puid  
where pu.pudesc like '%rate%loss%'   
  
update pdu set  
 plid = pu.plid  
from @PRDTSums_Unit pdu  
join @produnits pu  
on pdu.puid = pu.puid  
  
  
--print 'ResturnResultSets: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------  
ReturnResultSets:  
-----------------------------------------------------------  
  
--select * from #delays  
  
--select * from @produnits  
  
--select 'sd', puid, starttime, endtime, splitrldowntime, *   
--from dbo.#splitdowntimes  
--where coalesce(splitrldowntime,0.0) > 0.0  
--and plid = 44   
--order by puid, starttime, endtime  
  
--select 'emu', pu.pu_desc, emu.*   
--from @PRDTSums_Unit emu  
--join prod_units pu  
--on pu.pu_id = emu.puid  
--where plid = 44   
--order by puid, starttime, endtime  
  
--select puid, starttime, endtime, tedetid, SplitDowntime, *  
--from #splitdowntimes  
--order by puid, starttime, endtime, tedetid  
  
--select 'pdu', pu.pu_desc, *   
--from @PRDTSums_Unit prdt  
--join prod_units pu  
--on pu.pu_id = prdt.puid  
  
  
  -----------------------------------------------------------------------------  
  -- Return the stops result set for the Line.  
  -----------------------------------------------------------------------------  
  
  insert @DTResults    
  SELECT  
   pl.PLDesc [Production Line],  
   SUM(pdm.ProductionRuntime) [Production Runtime],  
   SUM(coalesce(pdm.SplitDowntime,0)) / 60.0 [Reporting Downtime],   
   SUM(convert(float,pdm.UnschedSplitDT)/60.0)  [Unscheduled Rpt DT],        
--   SUM(convert(float,coalesce(pdm.SplitUptime,0)))/60.0 [Reporting Uptime],   
  
   case  
   when   
    sum(  
     case  
     when pu.pudesc like '%Converter Reliability%'  
     then pdm.SplitUptime  
     else 0.0  
     end  
     )  
    >  
    sum(  
     case  
     when pu.pudesc like '%Converter Blocked/Starved%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
   then   
    (  
    sum(  
     case  
     when pu.pudesc like '%Converter Reliability%'  
     then pdm.SplitUptime  
     else 0.0  
     end  
     )  
    -  
    sum(  
     case  
     when pu.pudesc like 'Converter Blocked/Starved%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
    )/60.0  
   else 0.0  
   end [Reporting Uptime],  
  
   case   
   when DATEDIFF(ss,@StartTime, @EndTime) > 0.0  
   then (convert(float, DATEDIFF(ss,@StartTime, @EndTime))   
      - SUM(convert(float,coalesce(pdm.SplitDowntime,0))))  
     / convert(float, DATEDIFF(ss,@StartTime, @EndTime))  
   else 0.0  
   end [Overall Availability],   
                     
--   case   
--   when (SUM(convert(float,coalesce(pdm.SplitUptime,0)))  
--     + SUM(convert(float,coalesce(pdm.UnschedSplitDT,0)))) > 0  
--   then SUM(convert(float,coalesce(pdm.SplitUptime,0)))    
--         / (SUM(convert(float,coalesce(pdm.SplitUptime,0)))  
--     + SUM(convert(float,coalesce(pdm.UnschedSplitDT,0))))   
--   else 0.0  
--   end [Planned Availability],  
  
   null [Planned Availability],  
  
   SUM(Coalesce(pdm.Stops, 0)) [Total Stops],  
   SUM(Coalesce(pdm.StopsUnscheduled, 0)) [Unscheduled Stops],  
   SUM(Coalesce(pdm.StopsMinor, 0)) [Minor Stops],  
   SUM(Coalesce(pdm.StopsEquipFails, 0)) [Equipment Failures],  
   SUM(Coalesce(pdm.StopsProcessFailures, 0)) [Process Failures],  
   SUM(Coalesce(pdm.StopsELP, 0)) [ELP Stops],  
   sum(pdm.ELPMins)/60.0  [ELP Losses (Mins)],  
  
   case  
   when sum(pdm.PaperRuntime) > 0  
   then sum(pdm.ELPMins)/sum(pdm.PaperRuntime)   
   else 0.0  
   end [ELP %],  
  
    coalesce(     
    CASE   
    WHEN SUM(pdm.R2Denominator) > 0   
    THEN ROUND(1 - (SUM(pdm.R2Numerator)   
     /SUM(pdm.R2Denominator)), 2)   
      ELSE 0.0   
    END                      
    ,0.0) [R(2)],     
  
--   case  
--   when sum(pdm.StopsUnscheduled) > 0  
--   then sum(pdm.SplitUptime/60.0)/sum(pdm.StopsUnscheduled)   
--   else 0.0  
--   end [Unplanned MTBF],  
  
   null [Unplanned MTBF],  
  
   case  
   when sum(pdm.StopsUnscheduled) > 0  
   then sum(pdm.UnschedSplitDT/60.0)/sum(pdm.StopsUnscheduled)  
   else 0.0  
   end [Unplanned MTTR],  
  
   SUM(Coalesce(pdm.StopsRateLoss, 0)) [Rate Loss Events],  
   SUM(convert(float, Coalesce(pdm.SplitRLDowntime, 0.0)))/60.0 [Rate Loss Effective Downtime],  
    coalesce(  
    CASE    
    WHEN SUM(pdm.ProductionRuntime) > 0.0   
    THEN SUM(pdm.SplitRLDowntime)   
     / SUM(pdm.ProductionRuntime)    
    ELSE 0.0   
    END                      
    ,0.0) [Rate Loss %],    
  
--   (SUM(convert(float,coalesce(pdm.SplitUptime,0)))    
--        / (SUM(convert(float,coalesce(pdm.SplitUptime,0)))  
--     + SUM(convert(float,coalesce(pdm.UnschedSplitDT,0)))))  
--   -  
--    (coalesce(  
--    CASE    
--    WHEN SUM(pdm.ProductionRuntime) > 0.0   
--    THEN SUM(pdm.SplitRLDowntime)   
--      / SUM(pdm.ProductionRuntime)    
--    ELSE 0.0   
--    END                      
--    ,0.0)) [Planned Availability minus Rate Loss]   
     
   null [Planned Availability minus Rate Loss]   
  
  From  @PRDTSums_Unit pdm  
  JOIN @ProdLines pl   
--  ON  pdm.PuId = pl.reliabilityPuId  
--  or  pdm.puid = pl.ratelosspuid  
  on  pdm.plid = pl.plid  
  join @produnits pu  
  on pdm.puid = pu.puid  
  where pudesc like '%converter reliability%'  
  or pudesc like '%converter blocked/starved%'  
  GROUP BY pl.PLDesc  
  ORDER BY pl.PLDesc  
  
  update dtr set  
  
--   [Planned Availability] =   
--    case   
--    when (SUM(convert(float,coalesce(pdm.SplitUptime,0)))  
--      + SUM(convert(float,coalesce(pdm.UnschedSplitDT,0)))) > 0  
--    then SUM(convert(float,coalesce(pdm.SplitUptime,0)))    
--          / (SUM(convert(float,coalesce(pdm.SplitUptime,0)))  
--      + SUM(convert(float,coalesce(pdm.UnschedSplitDT,0))))   
--    else 0.0  
--    end,  
  
   [Planned Availability] =   
    case   
    when [Reporting Uptime] + [Unscheduled Rpt DT] > 0  
    then [Reporting Uptime] / ([Reporting Uptime] + [Unscheduled Rpt DT] )  
    else 0.0  
    end,  
  
--   [Unplanned MTBF] =  
--    case  
--    when sum(pdm.StopsUnscheduled) > 0  
--    then sum(pdm.SplitUptime/60.0)/sum(pdm.StopsUnscheduled)   
--    else 0.0  
--    end,  
  
   [Unplanned MTBF] =  
    case  
    when [Unscheduled Stops] > 0  
    then [Reporting Uptime] / [Unscheduled Stops]  
    else 0.0  
    end,  
  
   [Planned Availability minus Rate Loss] =  
    ([Reporting Uptime] / ([Reporting Uptime] + [Unscheduled Rpt DT]))  
     -  
--    (  
    coalesce (  
       CASE    
       WHEN [Production Runtime] > 0.0   
       THEN [Rate Loss Effective Downtime] / [Production Runtime]   
       ELSE 0.0   
       END                      
       ,0.0  
       )  
--    )  
  
  from @DTResults dtr  
    
  
  select    
   [Production Line],  
   [Reporting Downtime],  
   [Unscheduled Rpt DT],  
   [Reporting Uptime],  
   [Overall Availability],  
   [Planned Availability],  
   [Total Stops],  
   [Unscheduled Stops],  
   [Minor Stops],  
   [Equipment Failures],  
   [Process Failures],  
   [ELP Stops],  
   [ELP Losses (Mins)],  
   [ELP %],  
   [R(2)],  
   [Unplanned MTBF],  
   [Unplanned MTTR],  
   [Rate Loss Events],  
   [Rate Loss Effective Downtime],  
   [Rate Loss %],  
   [Planned Availability minus Rate Loss]  
  from @DTResults  
  ORDER BY [Production Line]  
  
    
  -----------------------------------------------------------------------------  
  -- Return the production result set for Line.  
  -----------------------------------------------------------------------------  
  SELECT    
   pl.PLDesc [Production Line],  
   convert(int,SUM(pr.TotalUnits)) [Total Units],  
   convert(int,SUM(pr.GoodUnits)) [Good Units],  
   convert(int,SUM(pr.RejectUnits)) [Reject Units],  
  
   CASE WHEN convert(float,SUM(pr.TotalUnits)) > 0   
        THEN convert(float,SUM(pr.RejectUnits))   
      / convert(float,SUM(pr.TotalUnits))  
        ELSE 0 END [Unit Broke %],  
  
   convert(int,SUM(pr.ActualUnits)) [Actual Stat Cases],  
   convert(int,SUM(pr.IdealUnits)) [Reliability Ideal Stat Cases],  
   convert(int,SUM(pr.OperationsTargetUnits)) [Operations Target Stat Cases],  
  
--   CASE WHEN SUM(convert(float,pr.IdealUnits)) > 0   
--        THEN SUM(convert(float,pr.ActualUnits))   
--      / SUM(convert(float,pr.IdealUnits))  
--        ELSE 0 END [CVPR %],  
   CASE WHEN SUM(CONVERT(FLOAT,pr.TargetUnits)) > 0   
        THEN SUM(CASE  WHEN pr.TargetUnits IS NOT NULL     
          THEN CONVERT(FLOAT,pr.ActualUnits)   
          ELSE 0            
          END)              
      / SUM(CONVERT(FLOAT,pr.TargetUnits))  
      ELSE NULL END [CVPR %],   
  
--   CASE WHEN SUM(convert(float,pr.OperationsTargetUnits)) > 0   
--        THEN SUM(convert(float,pr.ActualUnits))   
--      / SUM(convert(float,pr.OperationsTargetUnits))  
--        ELSE 0 END [Operations Efficiency %],  
   CASE WHEN SUM(CONVERT(FLOAT,pr.OperationsTargetUnits)) > 0   
        THEN SUM(CASE  WHEN pr.OperationsTargetUnits IS NOT NULL   
          THEN CONVERT(FLOAT,pr.ActualUnits)     
          ELSE 0              
          END)                
      / SUM(CONVERT(FLOAT,pr.OperationsTargetUnits))  
      ELSE NULL END [Operations Efficiency %],   
  
--   CASE WHEN SUM(pr.ProductionRuntime) > 0   
--        THEN convert(int,SUM(pr.ActualUnits)   
--              * ((24 * 60) / SUM(pr.ProductionRuntime)))  
--        ELSE 0 END [Avg Stat CLD],  
   CASE WHEN SUM(pr.ProductionRuntime) > 0   
        THEN convert(integer,round(SUM(pr.ActualUnits)   
              * ((24.0 * 60.0) / SUM(pr.ProductionRuntime)),0))  
        ELSE 0 END [Avg Stat CLD],  
     
     
--    convert(int,AVG(pr.LineSpeedAvg)) [Line Speed Avg],   
--    convert(int,avg(TargetLineSpeed)) [Target Line Speed]  
  
   -- Rev11.36  
   case  
   when  SUM(pr.LineSpeedAvg * pr.SplitUptime) > 0.0  
   then  Convert(Float, SUM(pr.LineSpeedAvg * pr.SplitUptime))   
     / SUM (  
       case  
       when pr.LineSpeedAvg > 0.0  
       then convert(float,pr.SplitUptime)  
       else 0.0  
       end  
       )  
   else null  
   end [Line Speed Avg],  
  
   -- Rev11.36  
   case  
   when  SUM(pr.LineSpeedTarget * pr.ProductionRuntime) > 0.0   
   then  Convert(Float, SUM(pr.LineSpeedTarget * pr.ProductionRuntime))   
     / SUM (  
       case   
       when LineSpeedTarget > 0.0  
       then convert(float,pr.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Target Line Speed]  
  
  FROM @ProdRecords pr  
  LEFT JOIN @Prodlines pl ON pr.PLId = pl.PLId  
  GROUP BY pl.PLDesc, pl.PackOrLine  
  ORDER BY pl.PLDesc, pl.PackOrLine  
  
  
-------------------------------------------------------------------------  
-- Drop temp tables  
-------------------------------------------------------------------------  
  
Finished:  
  
drop table dbo.#delays  
drop table dbo.#TimedEventDetails  
drop table dbo.#tests  
drop table dbo.#limittests  
drop table dbo.#packtests  
drop table dbo.#SplitDowntimes  
drop table dbo.#SplitUptime  
DROP TABLE dbo.#Events     -- 2007-01-11 VMK Rev11.29  
drop table dbo.#prsrun     -- Rev11.33  
--drop table dbo.#prodlines     -- Rev11.33  
drop table dbo.#splitprsrun  
drop table dbo.#dimensions  
--drop table dbo.#ELPMetrics_Unit  
drop table dbo.#EventStatusTransitions  
  
  
--print 'End of Result Sets: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
RETURN  
  
