  
/*    
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
This procedure will return data for global benchmarking of key Family Care MES data items.  
  
CALLED BY:  The Access Database known as the "Data Extraction Tool".  
  
CALLS: dbo.fnLocal_GlblParseInfo  
------------------------------------------------------------------------------------------------------------------  
  
LAST REVISION: 2009-08-11 Jeff Jaeger Rev3.37  
  
------------------------------------------------------------------------------------------------------------------  
--  Revision History:  
------------------------------------------------------------------------------------------------------------------  
2005-MAR-04 Fran Osorno  Rev1.00  
  Created.  
  
2005-MAY-03 Fran Osorno  Rev1.10  
  Updated the query to support the date ranging ability of the extraction tool  
  
2005-MAY-03 Fran Osorno  Rev1.20  
  Added Rate Loss and Blocked/Starved to the query.  
  
2005-MAY-12 Fran Osorno  Rev1.30  
  Added code to pull in additional items requested by the business  
  
2005-JUL-15 Langdon Davis Rev2.00  
  Re-created by modifying code from spLocal_RptCvtgDDSStops in order to meet new   
  business requirements and apply our latest knowledge re tuning.  
  
2005-JUL-26 Langdon Davis Rev2.01  
  Finalized some results set field and ordering changes to support the ELP benchmarking.  
  
2005-JUL-29 Langdon Davis Rev2.02  
  -  Eliminated some unnecessary variables/code and narrowed down to just the converter  
   reliability and rate loss MU's.  
  - Moved the ProdLineList from coming in as a parameter coming in from a SELECT in a  
   separate sp, to just being built into this sp.  Enables us to get rid of the   
   separate sp [spLocal_ReportGBUReliabilityLines.sql].  
  
2005-AUG-15 Langdon Davis Rev2.03  
  -  Removed the ProdUnitsEG [Equipment Group] from population/use.  
  -  Eliminated 'Downtime' from @DelayTypeList.  
  -  Changed method of populating @UWS to eliminate issues with a NULL UWSPUId when  
   'UWSORDER='has not been configured in the Extended_Info field of the UWS Prod_Units.  
  -  Modified JOIN in the population of @UWS to be robust against there being more than 1   
   digit in the UWSOrder specification.  
  - Added a DELETE statement to bring @ProdLines down to just converting line prod lines.  
  - Removed BSPUId from @ProdLines.  
  
2005-AUG-17 Langdon Davis Rev2.04  
  - Added a conversion of 'ELP Downtime' and the 'Time to Exclude...' results set fields to minutes  
   so that their UOM would be consistent with the other time data.  
  
2005-AUG-22 Langdon Davis Rev2.05  
  - Modified the indices on @Primaries in line with the learnings reflected in the DDS-Stops report's  
   Rev10.15 and Rev10.16 in order to make the report more efficient with large datasets.  
  
2006-APR-03 Vince King  Rev2.06  
  - Added code from CvtgELP changes to adjust EndTimes for PRs in @PRsRun table to eliminate  
   overlap of times.  
  -  Added Id_Num IDENTITY column to @PRsRun table and change PRIMARY KEY from (PUId, StartTime, EventId)  
   to (Id_Num, PUId, StartTime).  
  - Added PEIId column to @UWS table and modified code to populate.  PEIId is used in code to  
   adjust EndTimes for overlap as described above.  
  - Added SET NOCOUNT ON to beginning of sp and SET NOCOUNT OFF to end of sp for tuning.  
  
2006-APR-10 Langdon Davis Rev2.07  
  When specs are deleted via the Proficy Admin, the phrase '<Deleted>' shows up preceding the value.  Modified  
  the code to screen these deleted records out when selecting from Active_Specs by checking to see if the  
  value ISNUMERIC.  
  
2006-JUL-10 Langdon Davis Rev2.08  
  Added a data integrity step to delete all 0 values for Reports Line Speed from #Tests  
  immediately after it is populated.  
  
2006-NOV-27 Vince King  Rev2.09  
  Added events code from CvtgELP (that came from PmkgDDSELP).  Commented out several sections of code  
  that is no longer needed.  Added the #Events table that is used to populate events and then to  
  used for the INSERT into @PRsRun.  Added some additional columns to the @PRsRun table that are required  
  for the events code.    
  Made some minor performance changes that were missed earlier (dbo.).  
  
2006-DEC-11 Vince King  Rev2.10  
  Modified JOIN for dbo.Tests table in SELECT for INSERT into PRsRun due to duplicate rows.  Code pulled  
  from spLocal_RptPmkgDDSELP.  
  
  
2008-10-13 Jeff Jaeger  Rev3.0  
- overhauled the entire sp using DDS Stops as a baseline.    
  
2008-10-22 Jeff Jaeger  Rev3.0.1  
- updated the formatting of start time and end time in the result set to match what was originally   
 in this report.  the formatting for those fields of #Stops was apparently different in DDS Stops.  
- modified the Facial FFF1 special special update to PEIID in #PRsRun so that it only runs if the site   
 executing the code is GB... this will need to be added to all of the reports.  
  
2008-10-23 Jeff Jaeger  Rev3.0.2  
 - corrected the permissions to be granted to this sp.  
  
2008-10-23 Jeff Jaeger  Rev3.0.3  
- added a LEFT funtion to the comment field in the result set.  this is done because access  
  
2008-11-12 Jeff Jaeger Rev3.1  
- Changed the update to GrandParentPRID in @PRDTOutsideWindow to include a Timestamp check against the   
 test result_on.  
- Removed the IF clause around the use of @PRDTOutsideWindow.  the check to see if there are any UWS1Parent   
 or UWS2Parent values that are NULL before actually running that section of code was taking (much) longer   
 than is actually needed to just run the code.  
- added @DelaysOutsideWindow and the code to populate this.  this was done to reduce the size of the data set  
 being joined to in the population of @PRDTOutsideWindow.  the effect is to noticably reduce the runtime of   
 the sp.  
  
2008-12-31 Jeff Jaeger Rev3.2  
- added "with (nolock)" to the use of temp tables in select statements.  
- converted ProdLines from temp table to table variable.  
  
2009-01-22 Jeff Jaeger Rev3.3  
- added the @LineResults parameter, with a default value of 1, and the related code.    
 if the value is 1, then Line results are returned by the procedure.    
 if the value is 0, then Pack results are returns.  
  
2009-02-05 Jeff Jaeger Rev3.31  
- modified the definition of StopsUnscheduled, StopsMinor, StopsEquipFails, and   
 StopsProcessFailures in #Delays  
  
2009-02-16 Jeff Jaeger Rev3.32  
- modified the method for pulling ScheduleID, CategoryID, GroupCauseID, and SubsystemID in #delays.  
  
2009-03-02 Jeff Jaeger Rev3.33  
- modified the definition of SplitUnscheduledDT  
- restricted the population of @prodlines and @produnits to exclude "z_obs"  
  
2009-03-17 Jeff Jaeger Rev3.34  
- modified the definitions of various flavors of stops in #Delays  
- modified the definition of SplitUnscheduledDT in #SplitDowntimes  
  
--2009-04-09 Jeff Jaeger Rev3.35  
-- added a restriction on pu_desc not like '%rate%loss%' in the definition of SplitELPSchedDT.  
  
--2009-05-06 Jeff Jaeger Rev3.36  
-- changed the assignment of NextStartTime in #SplitDowntimes to use a EndTime <= StartTime   
 comparison.  It seems that comparing the record ID values is not robust enough in the   
 latest version of SQL.  
  
--2009-08-11 Jeff Jaeger Rev3.37  
- modified the update to ShiftStart in @runs.  
  
  
----------------------------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------------------------  
*/  
  
CREATE PROCEDURE dbo.spLocal_ReportGBUReliability  
--declare  
  
  @StartTime  DATETIME,  -- Beginning period for the data.  
 @EndTime   DATETIME,  -- Ending period for the data.  
 @LineResults int  = 1  -- Determines whether the result set will be for Lines or Pack  
  
  -- 1 = Lines, 0 = Pack    
  
AS  
  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
  
-------------------------------------------------------------------------------  
-- Declare testing parameters.  
-------------------------------------------------------------------------------  
  
--SELECT    
-- @StartTime = '2009-08-01 00:00:00', --'2005-09-06 0:00:00',   
-- @EndTime = '2009-08-03 00:00:00', --'2005-09-07 00:00:00',   
-- @LineResults = 1  
  
----------------------------------------------------------  
-- Section 1:  Define variables for this procedure.  
----------------------------------------------------------  
  
DECLARE   
--@ProdLineList     VARCHAR(4000),  -- Collection of Prod_Lines.PL_Id for converting lines delimited by "|".  
@DelayTypeList     VARCHAR(4000),  -- Collection of "DelayType=..." FROM Prod_Units.Extended_Info delimited by "|".  
@CatMechEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
@CatElectEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
@CatProcFailId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
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
@BusinessType     INTEGER,    -- 1=Tissue/Towel, 2=Napkins, 3=Facial  
  
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
@ShipUnitSpecDesc    VARCHAR(100),  
@StatFactorSpecDesc   VARCHAR(100),  
@SheetWidthSpecDesc   VARCHAR(100),  
@SheetLengthSpecDesc   VARCHAR(100),  
@SheetCountSpecId    INTEGER,  
@ShipUnitSpecId    INTEGER,  
@StatFactorSpecId    INTEGER,  
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
          
@RunningStatusID     int,  
  
@VarInputRollVN    varchar(50),  
@VarInputPRIDVN    varchar(50)  
  
  
----------------------------------------------------------  
-- Section 2:  Declare the error messages table  
----------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Error Messages  
-------------------------------------------------------------------------------  
--DECLARE @ErrorMessages TABLE ( ErrMsg VARCHAR(255) )  
  
--------------------------------------------------------------  
-- Section 4: Assign constant values  
--------------------------------------------------------------  
  
select  
@ScheduleStr    = 'Schedule',  
@CategoryStr    = 'Category',  
@GroupCauseStr    = 'GroupCause',  
@SubSystemStr    = 'Subsystem',  
@DelayTypeRateLossStr = 'RateLoss',  
--@CatBlockStarvedId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Blocked/Starved'),  --FLD 07-NOV-2007 Rev11.54  
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
--@VarGrandParentPRIDVN = 'Grand Parent PRID',  
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
  
@ShipUnitSpecDesc   = 'Ship Unit',  
  
@LineSpeedTargetSpecDesc  = 'Line Speed Target',  
@LineSpeedIdealSpecDesc  = 'Line Speed Ideal',  
  
@VarInputRollVN   = 'Input Roll ID',  
@VarInputPRIDVN   = 'Input PRID',  
  
@DelayTypeList    = 'CvtrDowntime|RateLoss|BlockedStarved'  
  
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
  
declare @EventReasons table   
 (  
 Event_Reason_ID         int PRIMARY KEY NONCLUSTERED,  
 Event_Reason_Name         varchar(100)  
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
  
  
 declare @PEI table  
  (  
  pu_id   int,  
  pei_id  int,  
  Input_Order int,  
  Input_name varchar(50)  
  primary key (pu_id,input_name)  
  )  
  
  
declare @PRDTOutsideWindow table  
 (  
 TEDetID    int,  
 EventID    int,  
 SourceEventID  int,  
 PLID     int,  
 CvtgPUID    int,  
 ProdPUID    int,  
 PRPUID    int,  
 EventTimestamp  datetime,  
 SourceTimestamp datetime,  
 ParentPRID   varchar(50),  
 GrandParentPRID varchar(50),  
 PMTeam    varchar(5),  
 UWS     varchar(50),  
 Input_Order   int,  
 ParentType   int,  
 INTR     int  
 primary key (EventID,TEDetID)  
 )  
  
declare @DelaysOutsideWindow table  
 (  
 TEDetID  int,  
 PLID   int,  
 PUID   int,  
 StartTime datetime  
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
 RollsPUID           int,  
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
-- VarGrandParentPRIDId        INTEGER,  
 VarUnwindStandId         INTEGER,   
 VarLineSpeedId          INTEGER,  
-- VarInputRollID          int,  
-- VarInputPRIDID          int,  
 Extended_Info          varchar(225),  
 ProductionRuntime         FLOAT,     -- 2007-04-11 VMK Rev11.37, Added.  
 PaperRuntime          FLOAT     -- 2007-04-11 VMK Rev11.37, Added.  
 )   
  
  
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
 UWS1Parent           VARCHAR(50),  
 UWS1GrandParent         VARCHAR(50),  
 UWS2Parent           VARCHAR(50),  
 UWS2GrandParent         VARCHAR(50),  
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
 UWS1Parent           VARCHAR(50),  
 UWS1GrandParent         VARCHAR(50),  
 UWS2Parent           VARCHAR(50),  
 UWS2GrandParent         VARCHAR(50),  
 LineIdealSpeed          FLOAT,  
 Runtime            float,  
 DelayType           VARCHAR(100)  
-- primary key (puid, starttime, endtime)  
 )  
  
CREATE CLUSTERED INDEX se_puid_starttime_endtime  
 ON dbo.#SplitDowntimes (puid, starttime, endtime)  
  
CREATE nonCLUSTERED INDEX se_seid  
 ON dbo.#SplitDowntimes (seid)  
  
  
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
 event_num           VARCHAR(50),  
 DevComment           varchar(300) -- Rev11.33  
-- primary key (Event_id, start_time)  
 )  
  
CREATE CLUSTERED INDEX events_eventid_StartTime  
ON dbo.#events (event_id, start_time)   
  
  
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
  
  
--print 'Section 10 Get info about Prod Lines: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------  
-- Section 10: Get information about the production lines  
------------------------------------------------------------  
  
-- pull in prod lines that have an ID in the list  
  
if @LineResults = 1  
begin -- Line Results  
 insert @ProdLines  
  (  
  PLID,   
  PLDesc,  
  Extended_Info)  
 select   
  pl.PL_ID,   
  pl.PL_Desc,  
  pl.Extended_Info  
 from dbo.prod_lines pl with (nolock)  
 join dbo.departments d with (nolock)  
 on d.dept_id = pl.dept_id  
 WHERE  GBDB.dbo.fnLocal_GlblParseInfo(pl.Extended_Info, 'PackOrLine=') = 'Line'  
 and d.dept_desc like 'Cvtg%' or d.dept_desc = 'Intr'  
 option (keep plan)  
end  
else  
begin -- Pack Results  
insert @ProdLines   
 (  
 PLID,   
 PLDesc,  
 Extended_Info)  
select   
 pl.PL_ID,   
 pl.PL_Desc,  
 pl.Extended_Info  
from dbo.prod_lines pl with (nolock)  
join dbo.departments d with (nolock)  
on d.dept_id = pl.dept_id  
WHERE  GBDB.dbo.fnLocal_GlblParseInfo(pl.Extended_Info, 'PackOrLine=') = 'Pack'  
and d.dept_desc like 'Cvtg%' or d.dept_desc = 'Intr'  
and pl.PL_Desc not like '%z_obs%'  
option (keep plan)  
end  
  
  
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
-- VarGrandParentPRIDId  = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarGrandParentPRIDVN),  
 VarUnwindStandId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarUnwindStandVN),  
-- VarInputRollID    = GBDB.dbo.fnLocal_GlblGetVarId(RollsPUID,   @VarInputRollVN),  
-- VarInputPRIDID    = GBDB.dbo.fnLocal_GlblGetVarId(RollsPUID,   @VarInputPRIDVN),  
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
   
--/*  
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
--*/  
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
  
  
--print 'Section 14 @ProdUnits UWS Columns: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--------------------------------------------------------------------------------------------  
--- Section 14: Update @ProdUnits UWS columns with the appropriate prod Unit desc.  
--------------------------------------------------------------------------------------------  
--IF @IncludeStops = 1  
  
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
from dbo.#EventStatusTransitions est with (nolock)  
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
from dbo.#events e with (nolock)   
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
from dbo.#prsrun prs with (nolock)  
where starttime < @starttime  
  
--20080721  
update prs set  
 endtime = @endtime  
from dbo.#PRsRun prs with (nolock)  
where endtime > @endtime  
  
  
update prs set  
 [ParentPRID] = UPPER(RTRIM(LTRIM(tprid.result))),  
-- [ParentPM] =  UPPER(RTRIM(LTRIM(LEFT(COALESCE(tprid.Result, 'NoAssignedPRID'), 2)))),  
 [UWS] = coalesce(tuws.result,'No UWS Assigned')  
from dbo.#prsrun prs with (nolock)  
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
FROM dbo.#prsrun prs with (nolock)   
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
 FROM dbo.#prsrun prs with (nolock)   
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
FROM dbo.#prsrun prs with (nolock)   
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
  
  
--print 'grand prid ' + ' ' + convert(varchar(25),current_timestamp,108)  
  
UPDATE prs SET   
 [GrandParentPRID] = t.result--,  
FROM dbo.#prsrun prs with (nolock)   
JOIN dbo.variables v with (nolock)   
on v.pu_id = prs.[PRPUID]   
and v.var_desc_global = 'Input PRID'  
JOIN dbo.tests t with (nolock)   
ON t.var_id = v.var_id  
and t.result_on = prs.[PRTimestamp]   
--where v.var_desc_global = 'Input PRID'  
  
UPDATE prs SET   
 [GrandParentPRID] = t.result--,  
FROM dbo.#prsrun prs with (nolock)   
JOIN dbo.variables v with (nolock)   
on v.pu_id = prs.[PRPUID]   
and v.var_desc_global = 'Input Roll ID'  
JOIN dbo.tests t with (nolock)   
ON t.var_id = v.var_id  
and t.result_on = prs.[PRTimestamp]   
--where v.var_desc_global = 'Input Roll ID'  
where GrandParentPRID is null  
  
  
--Rev11.55  
-- to identify overlap adjustments, query the temp table for InitEndtime <> Endtime  
UPDATE prs1 SET   
 prs1.Endtime =   
  coalesce((  
  select top 1 prs2.Starttime  
  from dbo.#prsrun prs2 with (nolock)   
  where prs1.PUId = prs2.PUId  
  and prs1.StartTime <= prs2.StartTime   
  and prs1.InitEndTime > prs2.StartTime  
  AND prs1.PEIId = prs2.PEIId  
  and prs1.eventid <> prs2.eventid  
  order by puid, starttime  
  ), prs1.InitEndtime)  
FROM dbo.#prsrun prs1 with (nolock)   
  
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
 FROM dbo.#prsrun prs with (nolock)   
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
 FROM dbo.#prsrun prs with (nolock)   
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
 pu.PLID,   pu.puid  
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
from dbo.#Dimensions with (nolock)  
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
  from dbo.#Dimensions d with (nolock)  
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
  from dbo.#Dimensions d with (nolock)  
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
  from dbo.#Dimensions d with (nolock)  
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
  from dbo.#Dimensions d with (nolock)   
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
  from dbo.#Dimensions d with (nolock)  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'LineStatus'  
  )  
from @Runs r  
  
  
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
  Uptime,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ERTD_ID,  
  Cause_Comment_Id--,  
  )  
 select  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
  Uptime * 60.0,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  event_reason_tree_data_id,  
  ted.Cause_Comment_ID --Co.Comment_Id--,  
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
  Uptime,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ERTD_ID,  
  Cause_Comment_Id--,  
  )  
 select  
  ted2.TEDet_ID,  
  ted2.Start_Time,  
  ted2.End_Time,  
  ted2.PU_ID,  
  ted2.Source_PU_Id,  
  ted2.Uptime,  
  ted2.Reason_Level1,  
  ted2.Reason_Level2,  
  ted2.Reason_Level3,  
  ted2.Reason_Level4,  
  ted2.TEFault_Id,  
  ted2.event_reason_tree_data_id,  
  ted2.Cause_Comment_ID --Co.Comment_Id--,  
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
 option (keep plan)  
  
  -- get the secondary events that span before the report window  
    
 insert dbo.#TimedEventDetails  
   (  
   TEDet_ID,  
   Start_Time,  
   End_Time,  
   PU_ID,  
   Source_PU_Id,  
  Uptime,  
   Reason_Level1,  
   Reason_Level2,  
   Reason_Level3,  
   Reason_Level4,  
   TEFault_Id,  
  ERTD_ID,  
   Cause_Comment_Id--,  
   )  
  select  
  ted1.TEDet_ID,  
  ted1.Start_Time,  
  ted1.End_Time,  
  ted1.PU_ID,  
  ted1.Source_PU_Id,  
  ted1.Uptime,  
  ted1.Reason_Level1,  
  ted1.Reason_Level2,  
  ted1.Reason_Level3,  
  ted1.Reason_Level4,  
  ted1.TEFault_Id,  
  ted1.event_reason_tree_data_id,  
   ted1.Cause_Comment_ID --Co.Comment_Id--,  
  from dbo.#TimedEventDetails ted2 with (nolock)  
  join  (  
   select   
   tted.TEDet_ID,  
   tted.Start_Time,  
   tted.End_Time,  
   tted.PU_ID,  
   tted.Source_PU_Id,  
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
  option (keep plan)  
  
  
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
  
  
--print 'Section 29 TE_Categories: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- Timed_Event_Details row FROM the Local_Timed_Event_Categories table using  
-- the TEDet_Id.  
-------------------------------------------------------------------------------  
/*  
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
  WHEN (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
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
  and (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
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
  and (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
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
  and (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
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
 var_desc   = v.var_desc,  
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
 and convert(float,value) = 0.0    
  
  
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
  
SELECT @SheetCountSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc =  @SheetCountSpecDesc  
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
  
--print 'PRID' + ' ' + convert(varchar(25),current_timestamp,108)  
  
 --------------------------------------------------------------------------------------------  
 --- Update the UWS Columns with the appropriate PRID results.  
 --------------------------------------------------------------------------------------------  
  
 UPDATE td SET   
  [UWS1Parent] = prs.ParentPRID,  
  [UWS1GrandParent] = prs.GrandParentPRID  
 FROM dbo.#prsrun prs with (nolock)   
 join @prodlines pl  
 on prs.puid = pl.prodpuid  
 join dbo.#delays td with (nolock)  
 on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
 and ((td.starttime >= prs.starttime and td.starttime < prs.endtime)   
  or (td.starttime < @starttime and td.endtime > @starttime))  
 AND prs.InputOrder = 1  
  
 UPDATE td SET   
  [UWS2Parent] = prs.ParentPRID,   
  [UWS2GrandParent] = prs.GrandParentPRID   
 FROM dbo.#prsrun prs with (nolock)   
 join @prodlines pl  
 on prs.puid = pl.prodpuid  
 join dbo.#delays td with (nolock)  
 on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
 and ((td.starttime >= prs.starttime and td.starttime < prs.endtime)   
  or (td.starttime < @starttime and td.endtime > @starttime))  
 AND prs.InputOrder = 2  
  
  
  
-- most of the UWS1 and UWS2 values in #Delays will be populated at this   
-- point, but some downtime events will start earlier than any of the parent rolls   
-- within the report window.  to handle these, we have the following code.  it may   
-- seem like a lot of work, but it shouldn't be too bad because it's only applied   
-- to a handful of records.  
  
--if (select count(*) from dbo.#Delays where UWS1Parent is null or UWS2Parent is null) > 0  
--begin   
  
insert @DelaysOutsideWindow  
 (  
 TEDetID,  
 PLID,  
 PUID,  
 StartTime  
 )  
select   
 td.TEDetID,  
 td.PLID,  
 td.PUID,  
 td.StartTime  
from dbo.#delays td with (nolock)  
where (td.UWS1Parent is null or td.UWS2Parent is null)  
  
  
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
FROM dbo.event_status_transitions est with (nolock)  
join dbo.events e with (nolock)  
on est.event_id = e.event_id  
join @prodlines pl  
on e.pu_id = pl.prodpuid  
join @DelaysOutsideWindow td  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
and td.starttime >= est.start_time  
and td.starttime < est.end_time  
where est.event_status = @RunningStatusID  
  
  
--print '@PRDTOutsideWindow 2 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [ParentPRID] = UPPER(RTRIM(LTRIM(tprid.result)))  
from @PRDTOutsideWindow pdow  
join @prodlines pl  
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
JOIN dbo.Tests tprid with (nolock)  
on tprid.var_id = v.var_id and tprid.result_on = pdow.SourceTimeStamp  
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
join @prodlines pl  
on pdow.plid = pl.plid  
JOIN dbo.Tests tuws with (nolock)  
on tuws.Var_Id = pl.VarUnwindStandID   
and tuws.result_on = pdow.EventTimeStamp  
  
--print '@PRDTOutsideWindow 8 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [Input_Order] = pei.input_order  
from @PRDTOutsideWindow pdow  
join @prodlines pl  
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
 [UWS1GrandParent]  = pdow.GrandParentPRID--,  
from @PRDTOutsideWindow pdow  
join dbo.#delays td with (nolock)  
on td.tedetid = pdow.tedetid  
where pdow.input_order = 1  
  
--print '@PRDTOutsideWindow 11 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
UPDATE td SET   
 [UWS2Parent]   = pdow.ParentPRID,    
 [UWS2GrandParent]  = pdow.GrandParentPRID--,  
from @PRDTOutsideWindow pdow  
join dbo.#delays td with (nolock)  
on td.tedetid = pdow.tedetid  
where pdow.input_order = 2  
  
  
 UPDATE td SET   
  [UWS1Parent] = 'NoAssignedPRID'  
 FROM dbo.#Delays td with (nolock)  
 WHERE UWS1Parent IS NULL  
  
  
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
 UWS1Parent  = (  
       SELECT result  
       FROM dbo.Tests t   
       WHERE Var_Id = pu.PRIDRLVarId   
       AND td.StartTime = t.result_on  
       ),   
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
  
  
--------------------------------------------------------------------------------  
-- Section 38: Get Event_Reason and Event_Reason_Category info  
--------------------------------------------------------------------------------  
  
--IF @IncludeStops = 1  
  
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
 Comment,  
 LineTargetSpeed,  
 LineActualSpeed,  
 UWS1Parent,  
 UWS1GrandParent,  
 UWS2Parent,  
 UWS2GrandParent,  
 LineIdealSpeed,  
 Runtime             -- 2007-03-15 VMK Rev11.37, added.  
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
 Comment,  
 TargetSpeed,   
 LineActualSpeed,  
 UWS1Parent,  
 UWS1GrandParent,  
 UWS2Parent,  
 UWS2GrandParent,  
 IdealSpeed,  
 DATEDIFF(ss, (CASE WHEN rls.StartTime < td.StartTime THEN   -- 2007-03-15 VMK Rev11.37, added.  
         td.StartTime ELSE rls.StartTime END),  
     (CASE WHEN rls.EndTime > td.EndTime THEN   
         td.EndTime ELSE rls.EndTime END))  
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
  
update se1 set  
 se1.NextStartTime =   
  (  
  select top 1 se2.starttime   
  from dbo.#SplitDowntimes se2 with (nolock)  
  where se1.puid = se2.puid  
--  and se1.seid < se2.seid  
  and se1.Endtime <= se2.StartTime  
--  order by se2.seid asc  
  order by se2.StartTime asc  
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
  
update td set  
 PUID = tpu.pu_id,  
 pudesc = tpu.pu_desc  
--from dbo.#delays td with (nolock)  
from dbo.#splitdowntimes td with (nolock)  
join dbo.prod_units pu  
on td.puid = pu.pu_id  
join dbo.prod_units tpu  
on tpu.pu_desc = replace(pu.pu_desc,'Converter Blocked/Starved', 'Converter Reliability')  
where pu.pu_desc like '%Converter Blocked/Starved'  
  
  
--print 'ResturnResultSets: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------  
ReturnResultSets:  
-----------------------------------------------------------  
  
--select * from #delays  
  
--select 'dim', * from #dimensions  
--select 'runs', * from @runs  
--order by puid, starttime  
--select 'ted', * from #TimedEventDetails  
--select 'sd', * from dbo.#splitdowntimes sd   
--order by puid, starttime  
  
--select 'su', * from dbo.#SplitUptime  
--order by puid, starttime  
  
--select 'se', * from dbo.#SplitDowntimes se   
  
--select 'pu', * from @ProdUnits pu    
--select 'pl', * from @ProdLines pl   
--select 'p', * from @Products ps  
--select 'er', * from @EventReasons er1   
  
  
  --print 'Result set 18' + CONVERT(VARCHAR(20), GetDate(), 120)  
 -----------------------------------------------------------------------------------------  
 -- Section 61: Results Set #12 - Return the stops detail result set for the pivot table.  
 -----------------------------------------------------------------------------------------  
  
--   INSERT INTO dbo.#Stops  
   SELECT   
    --Basic Info Section  
--    se.tedetid,  
    pl.PLDesc [Production Line],  
    pu.PUDesc [Master Unit],  
    CONVERT(VARCHAR(25), se.StartTime, 101) [Start Date],  
    CONVERT(VARCHAR(25), se.StartTime, 108) [Start Time],  
    CONVERT(VARCHAR(25), se.EndTime, 101) [End Date],  
    CONVERT(VARCHAR(25), se.EndTime, 108) [End Time],  
    ps.Prod_Code [Product],  
    ps.Prod_Desc [Product Desc],  
    pu.DelayType [Event Location Type],  
    se.team [Team],  
    se.Shift [Shift],  
    se.LineStatus [Line Status],  
    loc.PU_Desc [Location],  
    tef.TEFault_Name [Fault Desc],  
    er1.Event_Reason_Name [Failure Mode],  
    case  
     when lower(er2.event_reason_name) in ('unknown','other','troubleshooting')  
     then er1.event_reason_name + ' - ' + er2.event_reason_name     
     when LTRIM(RTRIM(isnull(er2.event_reason_name, ' '))) = ''  
     and loc.PU_Desc not like '%rate loss%'  
     then isnull(er1.event_reason_name, '**UNCODED** - ' + tef.TEFault_Name)  
     when LTRIM(RTRIM(isnull(er2.event_reason_name, ' '))) = ''  
     and loc.PU_Desc like '%rate loss%'  
     then isnull(er1.event_reason_name, '**UNCODED** - RATE LOSS')  
     else er2.Event_Reason_Name end [Failure Mode Cause],  
    substring(erc1.ERC_Desc, CharIndex(Char(58), erc1.ERC_Desc) + 1, 50) [Schedule],  
    substring(erc2.ERC_Desc, CharIndex(Char(58), erc2.ERC_Desc) + 1, 50) [Category],  
    substring(erc3.ERC_Desc, CharIndex(Char(58), erc3.ERC_Desc) + 1, 50) [SubSystem],  
    substring(erc4.ERC_Desc, CharIndex(Char(58), erc4.ERC_Desc) + 1, 50) [GroupCause],  
    left(Comment, 254) [Comment],  
  
    --Event Basic Data  
    CASE  WHEN se.TEDetId = se.PrimaryId THEN 'Primary'   
     when coalesce(se.PrimaryID,0)=0 then 'Reporting'  
     ELSE 'Secondary' END [Event Type],  
    COALESCE(se.Stops, 0) [Stop Event], --[Total Stops],  
  
    COALESCE(se.stopsrateloss,0) [Rate Loss Event],  
    CONVERT(FLOAT, COALESCE(se.Downtime,0)) / 60.0 [Event Downtime],  
    COALESCE(se.SplitDowntime,0)/60.0 [Split Downtime],  
    COALESCE(se.Uptime,0)/60.0 [Event Uptime],  
    COALESCE(se.SplitUptime,0)/60.0 [Split UpTime],  
  
    --Rate Loss Details  
    COALESCE(se.SplitRLDowntime,0)/60.0 [Rate Loss Eff. Downtime],  
    se.LineTargetSpeed [Target Line Speed],  
    se.LineActualSpeed [Actual Line Speed],  
    se.LineIdealSpeed [Ideal Line Speed],      
  
    --ELP Details  
    COALESCE(se.stopsELP,0) [ELP Event],  
    COALESCE(se.SplitELPDowntime,0)/60.0 [ELP Downtime],  
    se.SplitRLELPDowntime/60.0 [ELP Rate Loss Eff. Downtime],  
    COALESCE(se.SplitELPSchedDT,0)/60.0 [Time to Exclude from ELP% Denominator],  
    UPPER(se.UWS1GrandParent) [UWS1GrandParent],     
    UPPER(LTRIM(LEFT(se.UWS1GrandParent,2))) [UWS1GrandParent PM],  
    UPPER(se.UWS1Parent) [UWS1Parent],      
    UPPER(LTRIM(LEFT(se.UWS1Parent,2))) [UWS1Parent PM],  
    UPPER(se.UWS2GrandParent) [UWS2GrandParent],     
    UPPER(LTRIM(LEFT(se.UWS2GrandParent,2))) [UWS2GrandParent PM],  
    UPPER(se.UWS2Parent) [UWS2Parent],      
    UPPER(LTRIM(LEFT(se.UWS2Parent,2))) [UWS2Parent PM],  
  
    --More Detailed Classifications of the Stop  
    COALESCE(se.StopsMinor, 0) [Minor Stop],  
    COALESCE(se.StopsBlockedStarved, 0) [Blocked/Starved Event],   
    COALESCE(se.UpTime2m, 0) [Stops with Uptime <2 Min],     
  
    --Equipment Failures  
    COALESCE(se.StopsEquipFails, 0) [Equipment Failure],   
    CASE  WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
      AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
      THEN 1  
      ELSE 0   
      END [Minor Equipment Failure],   
    CASE  WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
      AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
      THEN 1  
      ELSE 0   
      END [Moderate Equipment Failure],   
    CASE  WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
      THEN 1  
      ELSE 0   
      END [Major Equipment Failure],   
  
    --Process Failures  
    COALESCE(se.StopsProcessFailures, 0) [Process Failure],  
    CASE  WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
      AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
      THEN 1  
      ELSE 0   
      END [Minor Process Failure],   
    CASE  WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
      AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
      THEN 1  
      ELSE 0   
      END [Moderate Process Failure],  
    CASE  WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
      THEN 1  
      ELSE 0   
      END [Major Process Failure],  
  
    --More Detailed Event Why's and What's  
    er3.Event_Reason_Name [Reason Level 3],   
    er4.Event_Reason_Name [Reason Level 4]  
  
   FROM dbo.#SplitDowntimes se with (nolock)  
   JOIN @ProdUnits pu    
   ON  se.PUId = pu.PUId  
   JOIN @ProdLines pl   
   ON pu.PLId = pl.PLId  
   JOIN @Products ps  
   ON se.ProdId = ps.Prod_Id  
--   left  JOIN @ProdUnitsEG pueg ON se.LocationId = pueg.Source_PUId  
   LEFT JOIN dbo.Event_Reason_Catagories erc1 with (nolock)  
   ON se.ScheduleId   = erc1.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc2 with (nolock)  
   ON se.CategoryId   = erc2.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc3 with (nolock)  
   ON se.SubSystemId  = erc3.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc4 with (nolock)  
   ON se.GroupCauseId  = erc4.ERC_Id  
   LEFT JOIN dbo.Prod_Units loc with (nolock) ON se.LocationId = loc.PU_Id  
   LEFT JOIN @EventReasons er1  ON se.L1ReasonId   = er1.Event_Reason_Id  
   LEFT JOIN @EventReasons     er2  ON se.L2ReasonId   = er2.Event_Reason_Id  
   LEFT JOIN @EventReasons     er3  ON se.L3ReasonId   = er3.Event_Reason_Id  
   LEFT JOIN @EventReasons     er4  ON se.L4ReasonId   = er4.Event_Reason_Id  
   LEFT  JOIN  dbo.Timed_Event_Fault    tef  with (nolock) ON (se.TEFaultID   = TEF.TEFault_ID)  
   where pu.pudesc not like '%block%starv%'  
  
   ORDER BY pl.PackOrLine, pl.PLDesc, se.Starttime  
   option (keep plan)  
  
   
-------------------------------------------------------------------------  
-- Drop temp tables  
-------------------------------------------------------------------------  
  
Finished:  
  
drop table dbo.#delays  
drop table dbo.#TimedEventDetails  
drop table dbo.#tests  
drop table dbo.#SplitDowntimes  
drop table dbo.#SplitUptime  
DROP TABLE dbo.#Events     -- 2007-01-11 VMK Rev11.29  
drop table dbo.#prsrun     -- Rev11.33  
drop table dbo.#dimensions  
drop table dbo.#EventStatusTransitions  
  
  
--print 'End of Result Sets: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
RETURN  
  
