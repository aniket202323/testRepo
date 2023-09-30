  CREate    PROCEDURE [dbo].[splocal_RptProductionReport_old]  
  
------------------------------------------------------------------------------------------------------------------------------------------  
--                                   --  
--                VERSION 5                  --  
--                                  --  
------------------------------------------------------------------------------------------------------------------------------------------  
-- (29-May-2008) Added NumEditsR1, NumEditsR2, NumEditsR3 to the Equations table. Becaus it is not updating  
--     the AGGREGATE column.  
------------------------------------------------------------------------------------------------------------------------------------------  
-- (15-Apr-2008) Added the following Metrics :  
  
--     SU (Schedule Utilization)  = 100 * Line Status Schedule Time / Calendar Time  
--     RU (Rate Utilization)   = 100 * SUM (Good Product / Ideal Speed) / SUM (Good Product / Target Speed)  
--     CU (Capacity Utilization)  = 100 * SUM (Good Product / Ideal Speed) / Calendar Time  
--      Run Effciency     = 100 * SUM (Good Product / Target Speed) / (Line Status Schedule Time - Planned Downtime)  
--     STNU (Staff Time Not Used) = SUM ( STNU time from production display)    
--     Ideal Speed     = Will be a Specification Variable defined at RE_ProductInformation (Product Property)       
--     Planned Downtime   = Will be defined as the SUM (Duration) of all stops under the Event_Reason_Tree called  
--             'Planned Stops%'  
------------------------------------------------------------------------------------------------------------------------------------------  
-- (25-Oct-2007) NULL Durations are causing updates of Crew, Shift, Product and Line Stauts to be blank.     
-- (3-Oct-2007)  COVERED FO-00188 MES Change Management Request :  
--     1) Fixed rounding with Running and Starting Scrap  
-- (19-Sep-2007) COVERED FO-00168 MES Change Management Request :  
--     1) Fixed issue with NULL values when calculating the Line Stops ERC  
--     2) Fix Total Product, Good product and any other value more than one million that is round up to tens.   
--     3) Fix the AVG calculation on Target Speed when DPR is Grouped By Unit and NULL values are present.  
-- (10-Apr-2007) Long time frames reports are not performing well at BELL due to a big size for   
--     Timed_Event_Details variable table, turned back to Temporary table and add and index.  
-- (19-Feb-2007) Change a bad performance query on BELL Server, split it in two UPDATEs.  
-- (17-10-2006)  Fixed Format for CaseCount metrics.  
-- (9-10-2006)   Fixed Metrics for schedule reports, seems not to be keeping the selected metrics, due  
--     to a step missed on the ColumnVisibility.  
-- (3-Oct-2006)  Fixed bug on Top 5 section WHERE is not filtering by Shift/Crew  
-- (24-Jun-2006) Revised edition to gain speed and decrease the amount of reads to disk.  
-- (13-Jun-2006) Make all the RE_Product Information dynamic, by now it was hard coded and we only take  
--     ProdPerBag and BagsPerCase. Need to check that the RE_Product Info matches exactly what   
--     is on the DPR parameters.  
-- (22-May-2006) Turned the SchedTime calculation in second to avoid loss.  
-- (15-May-2006) Added : Filtering Prop_Id on the Characteristics table, was causing duplicates.  
-- (10-May-2006) Added : When grouping by Product the report has the same issue that raises on Line Status  
-- (8-May-2006)  Added : The fix on (28-Apr-2006) fails should be Start_Time >= lpg.Start_Time and   
--       Start_Time < lpg.End_Time.  
-- (2-May-2006)  Added : Fixed AVG on Line Stops when grouping by Unit; issue raises on BELL/ABN  
-- (28-Apr-2006) Added : Change the way of calculating LineStatus for Uptime, we have a gap that comes when the  
--        Line Status is at the same time of a stop  
-- (19-Apr-2006) Added : Fixed calculation of PR using Availability.  
-- (12-Apr-2006) Added : Fixed the Unplanned calculation working backwards.  
-- (10-Feb-2006) Added : Change back the Downtimes/Line Stops syncro, no they are independant again.  
-- (2-Feb-2006)  Added : New EQN for ProdTime, now it is not more tied to the TotalProduct EQN  
-- (14-Dec-2005) Added : When Schedule Time EQN fails and makes the Schedule Time = Uptime + Downtime  
--                       fail then do not check for the constraint.                           
-- (29-Nov-2005) Added : Fix for stops that belongs in the previous period.  
-- (10-Nov-2005) Added : Minor Group by 'Product_Size' capability  
-- (24-Oct-2005) Added : Line Stops (Unplanned)  
--                       Downtime (Unplanned)  
--                       Edited Stops Reason 1  
--                       Edited Stops Reason 1 %  
--                       Edited Stops Reason 2  
--                       Edited Stops Reason 2 %  
--                       Edited Stops Reason 3  
--                       Edited Stops Reason 3 %  
--                       Temp Table to hold variables.  
-- (18-Oct-2005) Automatically turn Line Stops to SUM if Downtimes is set to SUM, or turn to AVG if   
-- Downtimes is set o AVG  
-- (12-Oct-2005) Fixed the ACPStopsPerDay when ScheduledTime < 1440 (Same as StopsPerDay)  
-- (24-Sep-2005) Exclude NULL values FROM AVG when Lines are included but no value because of Line Status Filter.  
-- (13-Sep-2005) Fixed Split issue on Crew Schedule change.  
-- (8-Sep-2005) Sincronized Target Speed EQN with Prod Time EQN.  
-- (6-Sep-2005) Change StopsPerDay logic, now FROM ProdDay Counting  
-- (18-Aug-2005) Redone UPDATE on Production Day.  
-- (17-Aug-2005) Increase formating for big numbers.  
-- (15-Aug-2005) Avoid NULL values for Uptime, Downtime calculation when no stops during the shift.  
-- (8-Aug-2005)  Only use the latest specification (Expitation_Date Is NULL) for RE_ProductInfo to avoid some  
-- issues with new products that has their specs missed.  
-- (26-Jul-2005) Added Speed get rid of the cursors for Top 5.  
-- (15-Jul-2005) Create ShowTop5Stops and ShowTop5Downtimes in order to enable/disable those sections  
-- (14-Jul-2005) If MajGroup or MinGroup = PU_ID then do not apply the EQN to the Top 5  
-- (14-Jul-2005) Fix Logic for Partial Events.  
-- (8-Jul-2005)  Fixed issue when calculating Target Speed to avoid division by zero  
-- (6-Jul-2005)  Re-Checked Stops per Day logic  
-- (5-Jul-2005)  Re-Checked logic for Line Status split.  
-- (23-Jun-2005) Added @RPTMinorGroupBy <> 'ProdDay' extra checking for Top 5 Rejects.  
-- (16-Jun-2005) DPR_ShowTop5Rejects, DPR_ShowClassProduct now works FROM asp format page.  
-- (12-Jun-2005) Checked Speed on Rejects.  
-- (6-Jun-2005)  Checked PSU Items : 93,98,100,102,103,104,105, also MQZ when all RE_ProdInfo in the Report = 1 then 1.  
-- (3-Jun-2005)  SPEED UP !! Changes on Line Status and Crew/Shift Cursor.  
-- (31-May-2005) Get rid of the Uptime column cursor, replace with a Temp table.  
-- (26-May-2005) Joining the ConvUnit on #Downtime splits.  
-- (23-May-2005) Still Uptime + Downtime Not Greater than ScheduleTime, need to remove.  
-- (20-May-2005) Issue with the /STLS=STLS%/ comment.  
-- (19-May-2005) Converted the Survival Rate calculation 0.xx to xx.  
-- (18-May-2005) Added Class Equation for the calculation of TOP 5 Stops and Top 5 Downtimes  
-- (18-May-2005) Cleaned variables for Flex Calculations.  
-- (17-May-2005) Checked Area 4 Loss calculation.  
-- (12-May-2005) Added Eqn for ACP stops, added Capability to work with TRUE/FALSE params on reverse with Local_PG_strDPRColumnVisibility  
-- (10-May-2005) This version will only work if the Line is flexconfig.  
-- Added translation capabilities for Class products.  
-- Added DPR_Area4Loss_FromToClass parameter to calculate  
--------------------------------------------------------------------------------------------------  
-- (4-May-2005) Turn back to Uptime = ScheduleTime - Downtime, some issues when filtering by LineStatus  
-- fixed the LineStatus splitting routine, it is missing some records.  
-- Increase #RptEqn size for Cells to fit long cell names  
--------------------------------------------------------------------------------------------------  
-- (2-May-2005) Added a Crew_Schedule table to get the Crew and Shift to UPDATE production and downtimes  
-- tables, do not use #Status.  
--------------------------------------------------------------------------------------------------  
-- (26-April-2005) When grouping by multiline then the Aggregate should be the Avergage for Production  
-- time and not greater that 1440 for a single day.  
--------------------------------------------------------------------------------------------------  
-- (19-April-2005) DowntimeEnd stop should have a class  
--------------------------------------------------------------------------------------------------  
-- (18-April-2005) Area 4 Loss should always be calculated if there are cases.  
-----------------------------------------------------------------------------------------------  
-- (12-April-2005) Turn TRUE or FALSE the parameters if they are or not into the @ColumnVisibility table  
--------------------------------------------------------------------------------------------------  
-- (5-April-2005) Correct Repair Time > T, seems not to be correct when getting the report in different ways  
--------------------------------------------------------------------------------------------------  
-- (4-April-2005) ProdTime should not exceed 1440 for a complete day, no matter how many units are involved in the   
-- calculation. Same thing applyes for Production Time.  
--------------------------------------------------------------------------------------------------  
-- (1-April-2005)Major and Minor order by columns  
--------------------------------------------------------------------------------------------------  
-- (31-March-2005) MSU should use the same Equation as the GoodPads  
-- Downtimes, Uptimes should be always the SUM and the aggregate will Average if OP = AVG  
--------------------------------------------------------------------------------------------------  
-- (30-March-2005)Show the 'The report has reach the max ...' when #columns > 50.  
--------------------------------------------------------------------------------------------------  
-- (29-March-2005) Get rid of the 'green columns' when Major = Migrouping   
--------------------------------------------------------------------------------------------------  
-- (28-March-2005) Seems that Line-None has some issues. Reviewed and fixed.  
-- Increase the varchars to hold the Location name.  
-- Unit - None and Product - None and Line - None, leave as it was in the past  
--------------------------------------------------------------------------------------------------  
-- (21-March-2005) Fixed A-Crew = Aggregate column when trying to get the This Month report,   
-- Fixed the Rejected Product count on each column  
-- When MinGroupBy = Location the Uptime = Sum(Uptime)   
--------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------  
-- UPDATEd issues 59,60,61,62,63,64 FROM PSU List (FROM HYG) on 17-March-2005   
--------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------  
-- UPDATEd issues 27 to 51 FROM PSU List (FROM HYG) on 14-March-2005   
--------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------  
-- UPDATEd issues 19 to 21 FROM PSU List on 10-March-2005  
--------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------  
-- UPDATEd issues 8 to 18 FROM PSU List on 7-March-2005   
--------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------  
-- UPDATEd issues 1,2,3,4,5,6,7 FROM PSU List on 2-March-2005  
--------------------------------------------------------------------------------------------------  
-- FRio   Version 2.0.0 Test (23-Feb-2005)  
-- New DPR Report including Major and Minor Grouping features, Equations for Variables and RE_Product  
-- Information parameters for Pad Conversion.  
--------------------------------------------------------------------------------------------------  
-- Report parameters :  
--------------------------------------------------------------------------------------------------  
-- Declare   
  
    @Report_Name    VARCHAR(88)   ,   
    @RPTShiftDESCList   VARCHAR(4000)  ,  
    @RPTCrewDESCList   VARCHAR(4000)  ,  
    @RPTPLStatusDESCList  VARCHAR(4000)  ,  
    @RPTStartDate    VARCHAR(25)   ,  
    @RPTEndDate        VARCHAR(25)     
  
AS   
  
--*********************************************************************************************  
-- THIS SHOULD BE REMOVED  
--*********************************************************************************************  
-- Select * FROM Report_Definitions WHERE report_name like '%renewal%'  
/*  
Select   
  
  @Report_name    = 'RE_DPR_PR_Renewal',   
        @RptShiftDescList   = '!Null',   
        @RptCrewDescList   = '!Null',   
        @RptPLStatusDescList  = '!Null',   
        @RptStartDate    = '2008-09-10 06:20',   
        @RptEndDate    = '2008-09-11 06:20'   
*/  
  
   
--*************************************************************************************************  
-- END  
--*************************************************************************************************  
  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
 SET NOCOUNT ON  
  
--Print convert(varchar(25), getdate(), 120) + ' Starting_Point'   
----------------------------------------------------------------------------------------------------------------------  
-- Declare variables for the stored procedure    
----------------------------------------------------------------------------------------------------------------------  
-- Report Constants :  
  
Declare  
  
 @LineSpec            varchar(4000) ,     
 @RPTDowntimeFieldorder   varchar(500) ,     
 @RPTWasteFieldorder       varchar(500) ,    
 @RPTFilterMinutes       float   ,      
 @RPTDowntimesystemUser   varchar(50)  ,     
 @RPTPadCountTag        varchar(50)  ,     
 @RPTCaseCountTag       varchar(50)  ,     
 @RPTRunCountTag        varchar(50)  ,     
 @RPTStartupCountTag       varchar(50)  ,     
 @RPTConverterSpeedTag   varchar(50)  ,     
 @RPTSpecProperty       varchar(50)  ,     
 @RPTDowntimeTag        varchar(50)  ,     
 @RPTDowntimesurvivalRate  float   ,      
 @RPTDowntimeFilterMinutes  float   ,  
 @RPTIdealSpeed     VARCHAR(50)  ,  
 @PlannedStopTreeName   NVARCHAR(200)  
  
-- DEFAULT VALUES FOR PARAMETER VARIABLES   
set @RPTDowntimesystemUser  = 'ReliabilitySystem'  
set @RPTPadCountTag    = 'ProductionOut'  
set @RPTConverterSpeedTag  = 'TargetSpeed'  
set @RPTCaseCountTag   = 'Cases Produced'  
set @RPTRunCountTag    = 'RunScrap'  
set @RPTStartupCountTag   = 'StartScrap'  
set @RPTSpecProperty   = 'RE_Product Information'  
set @RPTDowntimeTag    = 'DT/Uptime'  
Set @RPTDowntimeFieldorder  = 'Reason1~Reason2'  
Set @RPTWasteFieldorder   = 'Reason1~!Null'  
Set @RPTDowntimesurvivalRate = 230  
SET @RPTIdealSpeed    = 'Ideal Speed'  
SET @PlannedStopTreeName  = 'Planned Stop'  
  
Declare  
  
 @StartDateTime             datetime           ,  
 @EndDateTime             datetime           ,  
 @ErrMsg                  varchar(1000)      ,  
 @CompanyName             varchar(50)        ,  
 @SiteName                 varchar(50)        ,  
 @CrewDESCList             varchar(4000)      ,  
 @ShiftDESCList             varchar(4000)      ,  
 @PLStatusDESCList            varchar(4000)      ,  
 @ProdCodeList             varchar(4000)      ,  
 @PLDESCList                 varchar(4000)      ,  
 @DowntimesystemUserID        int                ,  
 @PLID                  int                ,  
 @EndTime                 datetime           ,  
 @Pu_Id                  int                ,  
 @ID                   int                ,  
 @StartTime                 datetime           ,  
    @ClassNum                                 int                ,  
 @PadsPerStatSpecID            int                ,  
 @IdealSpeedSpecID      INT       ,  
 @SpecPropertyID             int                ,  
 @SQLString                 varchar(4000)      ,  
 @GroupValue              varchar(50)        ,  
 @i                      int                ,  
 @j                      int                ,  
 @ColumnCount             int                ,  
 @TableName                 varchar(50)        ,  
 @ColNum                  varchar(3)         ,  
 @FIELD1                  varchar(50)        ,  
 @FIELD2                  varchar(50)        ,  
 @TEMPValue                 varchar(50)        ,  
 @FieldName                  VarChar(50)        ,  
 @SumGroupBy                 varchar(25)        ,  
 @SumLineStops             varchar(25)        ,  
    @SumLineStopsERC                        varchar(25)     ,  
 @SumACPStops             varchar(25)        ,  
 @SumDowntime             varchar(25)        ,  
    @SumDowntimeERC                         varchar(25)     ,  
 @SumPlannedStops      VARCHAR(25)   ,  
 @SumUptime                 varchar(25)     ,  
 @SumFalseStarts             varchar(25)     ,  
 @SumTotalSplices            varchar(25)     ,  
 @SumSUCSplices             varchar(25)     ,  
 @SumTotalPads             varchar(75)     ,  
 @SumUptimeGreaterT            varchar(25)      ,  
 @SumNumEdits             varchar(25)   ,  
 @SumNumEditsR1             varchar(25)   ,  
 @SumNumEditsR2             varchar(25)   ,  
 @SumNumEditsR3             varchar(25)   ,  
 @SumSurvivalRate            varchar(25)   ,  
 @SumRunningScrap            varchar(25)   ,  
 @SumDowntimeScrap            varchar(25)   ,  
 @SumGoodPads             varchar(25)   ,  
 @SumMSU                  varchar(25)   ,  
 @SumArea4LossPer            varchar(25)   ,  
 @SumRepairTimeT             varchar(25)   ,  
 @Avg_Linespeed_Calc            float    ,  
 @Flex1                  varchar(25)   ,  
 @Flex2                  varchar(25)   ,  
 @Flex3                  varchar(25)   ,  
 @Flex4                  varchar(25)   ,  
 @Flex5                  varchar(25)   ,  
 @Flex6                  varchar(25)   ,  
 @Flex7                  varchar(25)   ,  
 @Flex8                  varchar(25)   ,  
 @Flex9                  varchar(25)   ,  
 @Flex10                  varchar(25)   ,  
 @param                  nvarchar(100)  ,   --  for web parameters  
 @SumStops                 varchar(25)   ,  
 @SumStopsPerDay             varchar(25)   ,  
 @SumFalseStartsT            varchar(25)   ,  
 @sumACPStopsPerDay            varchar(25)   ,  
 @SumTotalScrap             varchar(25)   ,  
 @SumGoodClass1             varchar(25)   ,  
 @SumGoodClass2             varchar(25)   ,  
 @SumGoodClass3             varchar(25)   ,  
 @SumGoodClass4             varchar(25)   ,  
 @SumGoodClass5             varchar(25)   ,  
 @SumGoodClass6             varchar(25)   ,  
 @SumGoodClass7             varchar(25)   ,  
 @SumGoodClass8             varchar(25)   ,  
 @SumGoodClass9             varchar(25)   ,  
 @SumGoodClass10             varchar(25)   ,  
 @SumGoodClass11             varchar(25)   ,  
 @SumGoodClass12             varchar(25)   ,  
 @SumGoodClass13             varchar(25)   ,  
 @SumGoodClass14             varchar(25)   ,  
 @SumGoodClass15             varchar(25)   ,  
 @SumGoodClass16             varchar(25)   ,  
 @SumGoodClass17             varchar(25)   ,  
 @SumGoodClass18             varchar(25)   ,  
 @SumGoodClass19             varchar(25)   ,  
 @SumGoodClass20             varchar(25)   ,    
 @SumTotalClass1             varchar(25)   ,  
 @SumTotalClass2             varchar(25)   ,  
 @SumTotalClass3             varchar(25)   ,  
 @SumTotalClass4             varchar(25)   ,  
 @SumTotalClass5             varchar(25)   ,  
 @SumTotalClass6             varchar(25)   ,  
 @SumTotalClass7             varchar(25)   ,  
 @SumTotalClass8             varchar(25)   ,  
 @SumTotalClass9             varchar(25)   ,  
 @SumTotalClass10            varchar(25)   ,  
 @SumTotalClass11            varchar(25)   ,  
 @SumTotalClass12            varchar(25)   ,  
 @SumTotalClass13            varchar(25)   ,  
 @SumTotalClass14            varchar(25)   ,  
 @SumTotalClass15            varchar(25),  
 @SumTotalClass16            varchar(25),  
 @SumTotalClass17            varchar(25),  
 @SumTotalClass18            varchar(25),  
 @SumTotalClass19            varchar(25),  
 @SumTotalClass20            varchar(25),  
 @maxclass                 int,  
 @minclass                 int,  
 @Scheduled_Time       Float,  
    @TotalScheduled_Time     Float,  
 @STNU         FLOAT,  
 @TotalSTNU        FLOAT,  
 -- @Flexconfig       int,  
 @SumTargetSpeed       FLOAT,  
 @SumIdealSpeed       FLOAT,  
 @SumTotalCases       varchar(25),  
 @Local_PG_strRptDPRColumnVisibility  nvarchar (4000),  
    @Local_PG_StrCategoriesToExclude        nvarchar (1000),  
 @RPTMajorGroupBy               varchar(50),  
 @RPTMinorGroupBy               varchar(50),  
 @GroupMajorFieldName      varchar(50),  
 @GroupMinorFieldName      varchar(50),  
 @LocalRPTLanguage      int,  
 @Owner          varchar(50),  
 @r          int ,  
    @RPT_ShowClassProduct                varchar(10),  
    @RPT_ShowTop5Rejects                 varchar(10),  
    @RPT_ShowSplices                     varchar(10),  
    @RPT_ShowSucSplices                  varchar(10),  
    @RPT_SurvivalRate                    varchar(10),  
    @RPT_SurvivalRatePer                 varchar(10),  
    @RPT_CaseCountClass                  varchar(10),  
    @Rpt_ShowTop5Downtimes               varchar(10),  
    @Rpt_ShowTop5Stops                   varchar(10),  
 @ClassNo        int,  
 @Prod_Id        nvarchar(20),  
 @Value         float  
          
----------------------------------------------------------------------------  
-- Prompts For output on report.  Used in Language trans  
----------------------------------------------------------------------------  
  
Declare  
  
 @lblPlant    varchar(50),  
 @lblStartDate   varchar(50),  
 @lblShift    varchar(50),  
 @lblProductCode   varchar(50),  
 @lblLine    varchar(50),  
 @lblEndDate    varchar(50),  
 @lblCrew    varchar(50),  
 @lblLineStatus   varchar(50),  
 @lblTop5Downtime  varchar(50),  
 @lblTop5DTColmn1  varchar(50),  
 @lblTop5DTColmn2  varchar(50),  
 @lblTop5Stops   varchar(50),  
 @lblTop5Rejects   varchar(50),  
 @lblTop5RJColmn1  varchar(50),  
 @lblTop5RJColmn2  varchar(50),  
 @lblVarDESC    varchar(50),   
 @lblTotal    varchar(50),  
 @lblAll     varchar(50),  
 @lblSecurity   varchar(1000),  
 @lblStops    varchar(50),  
 @lblEvents    varchar(50),  
 @lblDTLevel1   varchar(50),  
 @lblDTLevel2   varchar(50),  
 @lblRJLevel1   varchar(50),  
 @lblRJLevel2   varchar(50),  
 @lblTotalProduct  varchar(50),  
    @lblProductionStatus    varchar(50),  
    @lblDowntime            varchar(50),  
    @lblPads                varchar(50)  
        --  
  
    Set @lblPlant     = 'Plant'  
 Set @lblStartDate   = 'Start Date'  
 Set @lblShift     = 'Shift'  
 Set @lblProductCode   = 'Product Code'  
 Set @lblLine     = 'Line'  
 Set @lblEndDate    = 'End Date'  
 Set @lblCrew     = 'Team'  
 Set @lblProductionStatus  = 'Production Status'  
 Set @lblTop5Downtime   = 'Top 5 Downtime'  
 Set @lblTop5Stops    = 'Top 5 Stops'  
 Set @lblTop5Rejects   = 'Top 5 Rejects'  
 Set @lblAll     = 'All'  
 Set @lblSecurity    = 'For P&G internal use Only'  
 Set @lblStops    = 'Stops'  
 Set @lblEvents    = 'Events'  
 Set @lblDTLevel1   = 'Feature'  
 Set @lblDTLevel2   = 'Component'  
 Set @lblRJLevel1   = 'AutoCause'  
 Set @lblRJLevel2   = ''   
    Set @lblDowntime            = 'Downtime'  
    Set @lblPads                = 'Pads'  
          
    
Declare   
  
 @Operator as nvarchar(5),  
 @ClassList as nvarchar(200),  
 @Variable as nvarchar(100),  
    @Prec as int  
  
--  
--Print convert(varchar(25), getdate(), 120) + ' Create Temp Tables'   
----------------------------------------------------------------------------------------------------------------------  
-- CREATE TEMPORARY TABLES :   
----------------------------------------------------------------------------------------------------------------------  
  
  
Create Table #PLIDList  
( RCDID     int,  
 PLID     int,  
 PLDESC     varchar(50),  
 ConvUnit    int,  
 SpliceUnit    int,  
 Packerunit    int,  
 QualityUnit   int,  
 ScheduleUnit   int,  
 ProductUnit   int,  
 ProcUnit    int,  
 PartPadCountVarID  int,  
 CompPadCountVarID  int,  
 PartCaseCountVarID  int,  
 CompCaseCountVarID  int,  
 PartRunCountVarID  int,  
 CompRunCountVarID  int,  
 PartStartUPCountVarID  int,  
 CompStartUPCountVarID  int,  
 CompSpeedTargetVarID  int,  
 PartSpeedTargetVarID  int,  
 REDowntimeVarID   int,  
 Class    int,  
 CaseCountVarID   varchar(25),  
 Flex1    varchar(25),  
 Flex2    varchar(25),  
 Flex3    varchar(25),  
 Flex4    varchar(25),  
 Flex5    varchar(25),  
 Flex6    varchar(25),  
 Flex7    varchar(25),  
 Flex8    varchar(25),  
 Flex9    varchar(25),  
 Flex10    varchar(25),  
 UseCaseCount   int  
)  
Create Table #ShiftDESCList  
( RCDID     int,  
 ShiftDESC    varchar(50))  
  
Create Table #CrewDESCList  
( RCDID     int,  
 CrewDESC    varchar(50))  
  
Create Table #PLStatusDESCList  
( RCDID     int,  
 PLStatusDESC    varchar(50))  
  
Create Table #Splices   
(  spl_id    int primary key identity,  
  Nrecords   int,  
      SpliceStatus   float,  
      Product    varchar(50),  
        Product_Size        varchar(100),  
      Crew    varchar(25),  
      Shift    varchar(25),  
      LineStatus   varchar(50),  
      PLID    int,  
      pu_id    int,   
  class    int,  
      InRun    int,  
  ProdDay    nvarchar(12),  
  Location   varchar(50),)  
  
  
Create Table #Rejects   
(  nrecords   bigint,  
      PadCount   float,  
        Reason1       varchar(100),  
      Reason2    varchar(100),  
      Product    varchar(50),  
        Product_Size        varchar(100),  
      Crew    varchar(25),  
      Shift    varchar(25),  
      LineStatus   varchar(50),  
      PLID    int,  
      pu_id    int,  
        Location   varchar(50),  
  Schedule_Unit  int)  
  
  
Create Table #Summary  
( Sortorder   int,  
 Label    varchar(60),  
 null01    varchar(60),  
 null02    varchar(25),  
 GroupField   varchar(25),  
 Value1    nvarchar(35),  
 Value2    nvarchar(35),  
 Value3    nvarchar(35),  
 Value4    nvarchar(35),  
 Value5    nvarchar(35),  
 Value6    nvarchar(35),  
 Value7    nvarchar(35),  
 Value8    nvarchar(35),  
 Value9    nvarchar(35),  
 Value10    nvarchar(35),  
 Value11    nvarchar(35),  
 Value12    nvarchar(35),  
 Value13    nvarchar(35),  
 Value14    nvarchar(35),  
 Value15    nvarchar(35),  
 Value16    nvarchar(35),  
 Value17    nvarchar(35),  
 Value18    nvarchar(35),  
 Value19    nvarchar(35),  
 Value20    nvarchar(35),  
 Value21    nvarchar(35),  
 Value22    nvarchar(35),  
 Value23    nvarchar(35),  
 Value24    nvarchar(35),  
 Value25    nvarchar(35),  
 Value26    nvarchar(35),  
 Value27    nvarchar(35),  
 Value28    nvarchar(35),  
 Value29    nvarchar(35),  
 Value30    nvarchar(35),  
 Value31    nvarchar(35),  
 Value32    nvarchar(35),  
 Value33    nvarchar(35),  
 Value34    nvarchar(35),  
 Value35    nvarchar(35),  
 Value36    nvarchar(35),  
 Value37    nvarchar(35),  
 Value38    nvarchar(35),  
 Value39    nvarchar(35),  
 Value40    nvarchar(35),  
 Value41    nvarchar(35),  
 Value42    nvarchar(35),  
 Value43    nvarchar(35),  
 Value44    nvarchar(35),  
 Value45    nvarchar(35),  
 Value46    nvarchar(35),  
 Value47    nvarchar(35),  
 Value48    nvarchar(35),  
 Value49    nvarchar(35),  
 Value50    nvarchar(35),  
 Value51    nvarchar(35),  
 Value52    nvarchar(35),  
 Value53    nvarchar(35),   Value54    nvarchar(35),  
 Value55    nvarchar(35),  
 Value56    nvarchar(35),  
 Value57    nvarchar(35),  
 Value58    nvarchar(35),  
 Value59    nvarchar(35),  
 Value60    nvarchar(35),  
 Value61    nvarchar(35),  
 Value62    nvarchar(35),  
 Value63    nvarchar(35),  
 Value64    nvarchar(35),  
 Value65    nvarchar(35),  
 Value66    nvarchar(35),  
 Value67    nvarchar(35),  
 Value68    nvarchar(35),  
 Value69    nvarchar(35),  
 Value70    nvarchar(35),  
 Value71    nvarchar(35),  
 Value72    nvarchar(35),  
 Value73    nvarchar(35),  
 Value74    nvarchar(35),  
 Value75    nvarchar(35),  
 Value76    nvarchar(35),  
 Value77    nvarchar(35),  
 Value78    nvarchar(35),  
 Value79    nvarchar(35),  
 Value80    nvarchar(35),  
 Value81    nvarchar(35),  
 Value82    nvarchar(35),  
 Value83    nvarchar(35),  
 Value84    nvarchar(35),  
 Value85    nvarchar(35),  
 Value86    nvarchar(35),  
 Value87    nvarchar(35),  
 Value88    nvarchar(35),  
 Value89    nvarchar(35),  
 Value90    nvarchar(35),  
 Value91    nvarchar(35),  
 Value92    nvarchar(35),  
 Value93    nvarchar(35),  
 Value94    nvarchar(35),  
 Value95    nvarchar(35),  
 Value96    nvarchar(35),  
 Value97    nvarchar(35),  
 Value98    nvarchar(35),  
 Value99    nvarchar(35),  
 Value100   nvarchar(35),  
 AGGREGATE   nvarchar(35),  
 EmptyCol   nvarchar(35),  
 ProdDay    nvarchar(12)  
)  
  
Create Table #Top5Downtime  
( Sortorder   int IDENTITY,  
 DESC01    varchar(150),  
 DESC02    varchar(150),  
 Stops    varchar(25),  
 GroupField   varchar(25),  
 Value1    nvarchar(35),  
 Value2    nvarchar(35),  
 Value3    nvarchar(35),  
 Value4    nvarchar(35),  
 Value5    nvarchar(35),  
 Value6    nvarchar(35),  
 Value7    nvarchar(35),  
 Value8    nvarchar(35),  
 Value9    nvarchar(35),  
 Value10    nvarchar(35),  
 Value11    nvarchar(35),  
 Value12    nvarchar(35),  
 Value13    nvarchar(35),  
 Value14    nvarchar(35),  
 Value15    nvarchar(35),  
 Value16    nvarchar(35),  
 Value17    nvarchar(35),  
 Value18    nvarchar(35),  
 Value19    nvarchar(35),  
 Value20    nvarchar(35),  
 Value21    nvarchar(35),  
 Value22    nvarchar(35),  
 Value23    nvarchar(35),  
 Value24    nvarchar(35),  
 Value25    nvarchar(35),  
 Value26    nvarchar(35),  
 Value27    nvarchar(35),  
 Value28    nvarchar(35),  
 Value29    nvarchar(35),  
 Value30    nvarchar(35),  
 Value31    nvarchar(35),  
 Value32    nvarchar(35),  
 Value33    nvarchar(35),  
 Value34    nvarchar(35),  
 Value35    nvarchar(35),  
 Value36    nvarchar(35),  
 Value37    nvarchar(35),  
 Value38    nvarchar(35),  
 Value39    nvarchar(35),  
 Value40    nvarchar(35),  
 Value41    nvarchar(35),  
 Value42    nvarchar(35),  
 Value43    nvarchar(35),  
 Value44    nvarchar(35),  
 Value45    nvarchar(35),  
 Value46    nvarchar(35),  
 Value47    nvarchar(35),  
 Value48    nvarchar(35),  
 Value49    nvarchar(35),  
 Value50    nvarchar(35),  
    Value51    nvarchar(35),  
 Value52    nvarchar(35),  
 Value53    nvarchar(35),  
 Value54    nvarchar(35),  
 Value55    nvarchar(35),  
 Value56    nvarchar(35),  
 Value57    nvarchar(35),  
 Value58    nvarchar(35),  
 Value59    nvarchar(35),  
 Value60    nvarchar(35),  
 Value61    nvarchar(35),  
 Value62    nvarchar(35),  
 Value63    nvarchar(35),  
 Value64    nvarchar(35),  
 Value65    nvarchar(35),  
 Value66    nvarchar(35),  
 Value67    nvarchar(35),  
 Value68    nvarchar(35),  
 Value69    nvarchar(35),  
 Value70    nvarchar(35),  
 Value71    nvarchar(35),  
 Value72    nvarchar(35),  
 Value73    nvarchar(35),  
 Value74    nvarchar(35),  
 Value75    nvarchar(35),  
 Value76    nvarchar(35),  
 Value77    nvarchar(35),  
 Value78    nvarchar(35),  
 Value79    nvarchar(35),  
 Value80    nvarchar(35),  
 Value81    nvarchar(35),  
 Value82    nvarchar(35),  
 Value83    nvarchar(35),  
 Value84    nvarchar(35),  
 Value85    nvarchar(35),  
 Value86    nvarchar(35),  
 Value87    nvarchar(35),  
 Value88    nvarchar(35),  
 Value89    nvarchar(35),  
 Value90    nvarchar(35),  
 Value91    nvarchar(35),  
 Value92    nvarchar(35),  
 Value93    nvarchar(35),  
 Value94    nvarchar(35),  
 Value95    nvarchar(35),  
 Value96    nvarchar(35),  
 Value97    nvarchar(35),  
 Value98    nvarchar(35),  
 Value99    nvarchar(35),  
 Value100   nvarchar(35),  
 Aggregate   nvarchar(35),  
 EmptyCol   varchar(35))  
  
  
Create Table #Top5Stops  
( Sortorder   int Identity,  
 DESC01    varchar(150),  
 DESC02    varchar(150),  
 Downtime   varchar(25),  
 GroupField   varchar(25),  
 Value1    nvarchar(35),  
 Value2    nvarchar(35),  
 Value3    nvarchar(35),  
 Value4    nvarchar(35),  
 Value5    nvarchar(35),  
 Value6    nvarchar(35),  
 Value7    nvarchar(35),  
 Value8    nvarchar(35),  
 Value9    nvarchar(35),  
 Value10    nvarchar(35),  
 Value11    nvarchar(35),  
 Value12    nvarchar(35),  
 Value13    nvarchar(35),  
 Value14    nvarchar(35),  
 Value15    nvarchar(35),  
 Value16    nvarchar(35),  
 Value17    nvarchar(35),  
 Value18    nvarchar(35),  
 Value19    nvarchar(35),  
 Value20    nvarchar(35),  
 Value21    nvarchar(35),  
 Value22    nvarchar(35),  
 Value23    nvarchar(35),  
 Value24    nvarchar(35),  
 Value25    nvarchar(35),  
 Value26    nvarchar(35),  
 Value27    nvarchar(35),  
 Value28    nvarchar(35),  
 Value29    nvarchar(35),  
 Value30    nvarchar(35),  
 Value31    nvarchar(35),  
 Value32    nvarchar(35),  
 Value33    nvarchar(35),  
 Value34    nvarchar(35),  
 Value35    nvarchar(35),  
 Value36    nvarchar(35),  
 Value37    nvarchar(35),  
 Value38    nvarchar(35),  
 Value39    nvarchar(35),  
 Value40    nvarchar(35),  
 Value41    nvarchar(35),  
 Value42    nvarchar(35),  
 Value43    nvarchar(35),  
 Value44    nvarchar(35),  
 Value45    nvarchar(35),  
 Value46    nvarchar(35),  
 Value47    nvarchar(35),  
 Value48    nvarchar(35),  
 Value49    nvarchar(35),  
 Value50    nvarchar(35),  
 Value51    nvarchar(35),  
 Value52    nvarchar(35),  
 Value53    nvarchar(35),  
 Value54    nvarchar(35),  
 Value55    nvarchar(35),  
 Value56    nvarchar(35),  
 Value57    nvarchar(35),  
 Value58    nvarchar(35),  
 Value59    nvarchar(35),  
 Value60    nvarchar(35),  
 Value61    nvarchar(35),  
 Value62    nvarchar(35),  
 Value63    nvarchar(35),  
 Value64    nvarchar(35),  
 Value65    nvarchar(35),  
 Value66    nvarchar(35),  
 Value67    nvarchar(35),  
 Value68    nvarchar(35),  
 Value69    nvarchar(35),  
 Value70    nvarchar(35),  
 Value71    nvarchar(35),  
 Value72    nvarchar(35),  
 Value73    nvarchar(35),  
 Value74    nvarchar(35),  
 Value75    nvarchar(35),  
 Value76    nvarchar(35),  
 Value77    nvarchar(35),  
 Value78    nvarchar(35),  
 Value79    nvarchar(35),  
 Value80    nvarchar(35),  
 Value81    nvarchar(35),  
 Value82    nvarchar(35),  
 Value83    nvarchar(35),  
 Value84    nvarchar(35),  
 Value85    nvarchar(35),  
 Value86    nvarchar(35),  
 Value87    nvarchar(35),  
 Value88    nvarchar(35),  
 Value89    nvarchar(35),  
 Value90    nvarchar(35),  
 Value91    nvarchar(35),  
 Value92    nvarchar(35),  
 Value93    nvarchar(35),  
 Value94    nvarchar(35),  
 Value95    nvarchar(35),  
 Value96    nvarchar(35),  
 Value97    nvarchar(35),  
 Value98    nvarchar(35),  
 Value99    nvarchar(35),  
 Value100   nvarchar(35),  
 Aggregate   varchar(75),  
 EmptyCol   varchar(75))  
  
Create Table #Top5Rejects  
( Sortorder   int IDENTITY,  
 DESC01    varchar(150),  
 DESC02    varchar(150),  
 Events    varchar(25),  
 GroupField   varchar(25),  
 Value1    nvarchar(35),  
 Value2    nvarchar(35),  
 Value3    nvarchar(35),  
 Value4    nvarchar(35),  
 Value5    nvarchar(35),  
 Value6    nvarchar(35),  
 Value7    nvarchar(35),  
 Value8    nvarchar(35),  
 Value9    nvarchar(35),  
 Value10    nvarchar(35),  
 Value11    nvarchar(35),  
 Value12    nvarchar(35),  
 Value13    nvarchar(35),  
 Value14    nvarchar(35),  
 Value15    nvarchar(35),  
 Value16    nvarchar(35),  
 Value17    nvarchar(35),  
 Value18    nvarchar(35),  
 Value19    nvarchar(35),  
 Value20    nvarchar(35),  
 Value21    nvarchar(35),  
 Value22    nvarchar(35),  
 Value23    nvarchar(35),  
 Value24    nvarchar(35),  
 Value25    nvarchar(35),  
 Value26    nvarchar(35),  
 Value27    nvarchar(35),  
 Value28    nvarchar(35),  
 Value29    nvarchar(35),  
 Value30    nvarchar(35),  
 Value31    nvarchar(35),  
 Value32    nvarchar(35),  
 Value33    nvarchar(35),  
 Value34    nvarchar(35),  
 Value35    nvarchar(35),  
 Value36    nvarchar(35),  
 Value37    nvarchar(35),  
 Value38    nvarchar(35),  
 Value39    nvarchar(35),  
 Value40    nvarchar(35),  
 Value41    nvarchar(35),  
 Value42    nvarchar(35),  
 Value43    nvarchar(35),  
 Value44    nvarchar(35),  
 Value45    nvarchar(35),  
 Value46    nvarchar(35),  
 Value47    nvarchar(35),  
 Value48    nvarchar(35),  
 Value49    nvarchar(35),  
 Value50    nvarchar(35),  
 Value51    nvarchar(35),  
 Value52    nvarchar(35),  
 Value53    nvarchar(35),  
 Value54    nvarchar(35),  
 Value55    nvarchar(35),  
 Value56    nvarchar(35),  
 Value57    nvarchar(35),  
 Value58    nvarchar(35),  
 Value59    nvarchar(35),  
 Value60    nvarchar(35),  
 Value61    nvarchar(35),  
 Value62    nvarchar(35),  
 Value63    nvarchar(35),  
 Value64    nvarchar(35),  
 Value65    nvarchar(35),  
 Value66    nvarchar(35),  
 Value67    nvarchar(35),  
 Value68    nvarchar(35),  
 Value69    nvarchar(35),  
 Value70    nvarchar(35),  
 Value71    nvarchar(35),  
 Value72    nvarchar(35),  
 Value73    nvarchar(35),  
 Value74    nvarchar(35),  
 Value75    nvarchar(35),  
 Value76    nvarchar(35),  
 Value77    nvarchar(35),  
 Value78    nvarchar(35),  
 Value79    nvarchar(35),  
 Value80    nvarchar(35),  
 Value81    nvarchar(35),  
 Value82    nvarchar(35),  
 Value83    nvarchar(35),  
 Value84    nvarchar(35),  
 Value85    nvarchar(35),  
 Value86    nvarchar(35),  
 Value87    nvarchar(35),  
 Value88    nvarchar(35),  
 Value89    nvarchar(35),  
 Value90    nvarchar(35),  
 Value91    nvarchar(35),  
 Value92    nvarchar(35),  
 Value93    nvarchar(35),  
 Value94    nvarchar(35),  
 Value95    nvarchar(35),  
 Value96    nvarchar(35),  
 Value97    nvarchar(35),  
 Value98    nvarchar(35),  
 Value99    nvarchar(35),  
 Value100   nvarchar(35),  
 AGGREGATE   varchar(75),  
 EmptyCol   varchar(75))  
  
Create Table #Downtimes  
( TedID     int,  
 PU_ID     int,  
 PLID     int,  
 Start_Time    datetime,  
 End_Time    datetime,  
 Fault     varchar(100),  
 Location_id    int,  
 Location    varchar(50),  
 Tree_Name    NVARCHAR(200),     
 Reason1     varchar(100),  
 Reason1_Code   int,  
 Reason2     varchar(100),  
 Reason2_Code   int,  
 Reason3     varchar(100),  
 Reason3_Code   int,  
 Reason4     varchar(100),  
 Reason4_Code   int,  
 Duration    float,  
 Uptime     float,  
 IsStops     int,  
 Product     varchar(50),  
    Product_Size         varchar(100),  
 Crew     varchar(10),  
 Shift     varchar(10),  
 LineStatus    varchar(25),  
 Uptime_LineStatus  varchar(25),  
 Uptime_Product   varchar(25),  
 SurvEnd_Time   datetime,  
 SurvRateUptime   float,  
 ID      int primary key Identity,  
 Dev_Comment    varchar (50),  
 UserID     int,  
 class      int,  
 Action_Level1   int,  
 ProdDay     nvarchar(12),  
 DowntimeTreeId   Int,  
 DowntimeNodeTreeId  Int,  
 ERC_Id       int,  
 ERC_Desc     nvarchar(50))  
  
CREATE NONCLUSTERED INDEX IDX_Downtimes  
ON #Downtimes(TedId) ON [PRIMARY]  
  
  
Create Table #Production  
( StartTIME   DATETIME,  
 EndTIME    DATETIME,  
 PLID    int,  
 pu_id    int,  
 Product    varchar(50),  
    Product_Size        varchar(100),  
 Crew    varchar(25),  
 Shift    varchar(25),  
 LineStatus   varchar(25),  
 TotalPad   float,  
 RunningScrap  float,  
 Stopscrap   float,  
 IdealSpeed   FLOAT,  
 TargetSpeed   FLOAT,  
 LineSpeedTAR  float,  
 TotalCaseS   float,   
 ProdPerStat   float,  
 ConvFactor   float,  
 ID     int primary key identity,  
 TypeOfEvent   varchar(50),  
 casecount   varchar(25),  
 flex1    varchar(25),  
 flex2    varchar(25),  
 flex3    varchar(25),  
 flex4    varchar(25),  
 flex5    varchar(25),  
 flex6    varchar(25),  
 flex7    varchar(25),  
 flex8    varchar(25),  
 flex9    varchar(25),  
 flex10    varchar(25),  
 class    int,  
 ProdDay    nvarchar(12),  
 Location   varchar(50),  
 SchedTime   int)  -- in seconds  
  
Create Table #TEMPORARY  
( TEMPValue1   varchar(100),  
 TEMPValue2   varchar(100),  
 TEMPValue3   varchar(100),  
 TEMPValue4   varchar(100),  
 TEMPValue5   varchar(100),  
 TEMPValue6   varchar(100),  
 TEMPValue7   varchar(100),  
 TEMPValue8   varchar(100),  
 TEMPValue9   varchar(100),  
 TEMPValue10   varchar(100),  
 TEMPValue11   varchar(100))  
  
Create Table #InvertedSummary  
( ID      int primary key identity,  
 GroupBy     Varchar(25),  
 ColType     varchar(25),  
 Availability   varchar(25),  
 PRAvail     varchar(25),  
 PR      varchar(25),  
 SU      varchar(25),  
 RU      varchar(25),  
 CU      varchar(25),  
 RunEff     varchar(25),  
 LineStops    varchar(25),  
    LineStopsERC         varchar(25),  
 RepairTimeT    varchar(25),  
 ACPStops    varchar(25),  
 Downtime    varchar(25),  
    DowntimeERC          varchar(25),  
 DowntimePlannedStops VARCHAR(25),  
 MTBF     varchar(25),  
    MTBF_ERC             varchar(25),  
 MTTR     varchar(25),  
    MTTR_ERC             Varchar(25),  
 MSU      varchar(25),  
 StopsPerMSU    varchar(25),  
 DownPerMSU    varchar(25),  
 TotalScrap    varchar(25),  
 TotalScrapPer   varchar(25),  
 RunningScrap   varchar(25),  
 RunningScrapPer   varchar(25),  
 DowntimeScrap   varchar(25),  
 DowntimescrapPer   varchar(25),  
 Area4LossPer   varchar(25),  
 Uptime     varchar(25),  
 IdealSpeed    varchar(25),  
 TargetSpeed    varchar(25),  
 LineSpeed    varchar(25),  
 RofT     varchar(25),  
 RofZero     varchar(25),  
 TotalSplices   varchar(25),  
 SucSplices    varchar(25),  
 FailedSplices   varchar(25),  
 SuccessRate    varchar(25),  
 ProdTime    varchar(25),  
 CalendarTime   varchar(25),  
    TotalProdTime           varchar(25),  
 TotalUptime    varchar(25),  
 TotalDowntime   varchar(25),  
 SurvivalRate   varchar(25),  
 SurvivalRatePer   varchar(25),  
 --  
 FalseStarts       varchar(25),   
 FalseStarts0Per   varchar(25),  
 FalseStartsT   varchar(25),  
 FalseStartsTper   varchar(25),  
 STNU     VARCHAR(25),  
 --   
 NumEdits       varchar(25),  
    EditedStopsPer   varchar(25),  
    NumEditsR1              varchar(25),  
    EditedStopsR1Per        varchar(25),  
    NumEditsR2              varchar(25),  
    EditedStopsR2Per        varchar(25),  
    NumEditsR3              varchar(25),  
    EditedStopsR3Per        varchar(25),  
    --  
 CaseCount    varchar(25),  
 StopsPerDay    varchar(25),  
 UptimeGreaterT   varchar(25),  
 ACPStopsPerDay    varchar(25),  
 ConverterStopsPerDay  varchar(25),  
 Class     varchar(25),  
 TotalPads    varchar(75),  
 TotalClass1    varchar(75),     
 TotalClass2    varchar(75),     
 TotalClass3    varchar(75),   
 TotalClass4    varchar(75),     
 TotalClass5    varchar(75),     
 TotalClass6    varchar(75),     
 TotalClass7    varchar(75),     
 TotalClass8    varchar(75),     
 TotalClass9    varchar(75),  
 TotalClass10   varchar(75),     
 TotalClass11   varchar(75),     
 TotalClass12   varchar(75),     
 TotalClass13   varchar(75),     
 TotalClass14   varchar(75),     
 TotalClass15   varchar(75),   
 TotalClass16   varchar(75),     
 TotalClass17   varchar(75),     
 TotalClass18   varchar(75),     
 TotalClass19   varchar(75),     
 TotalClass20   varchar(75),            
 GoodPads    varchar(75),  
 GoodClass1    varchar(75),     
 GoodClass2    varchar(75),     
 GoodClass3    varchar(75),     
 GoodClass4    varchar(75),     
 GoodClass5    varchar(75),     
 GoodClass6    varchar(75),     
 GoodClass7    varchar(75),     
 GoodClass8    varchar(75),  
 GoodClass9    varchar(75),     
 GoodClass10    varchar(75),     
 GoodClass11    varchar(75),     
 GoodClass12    varchar(75),     
 GoodClass13    varchar(75),     
 GoodClass14    varchar(75),     
 GoodClass15    varchar(75),   
 GoodClass16    varchar(75),     
 GoodClass17    varchar(75),     
 GoodClass18    varchar(75),     
 GoodClass19    varchar(75),     
 GoodClass20    varchar(75),       
 Flex1     varchar(25),  
 Flex2    varchar(25),  
 Flex3    varchar(25),  
 Flex4    varchar(25),  
 Flex5    varchar(25),  
 Flex6    varchar(25),  
 Flex7    varchar(25),  
 Flex8    varchar(25),  
 Flex9    varchar(25),  
 Flex10    varchar(25))  
  
  
Create Table #Temp_LinesParam(  
        RecId int,  
        PlDesc nvarchar(200))  
  
Create Table #FlexParam(  
        Temp1 int,  
        Temp2 varchar(100))  
  
Create table #ReasonsToExclude(  
        ERC_id int,  
        ERC_Desc nvarchar(100))  
  
Create Table #Equations(  
        eq_id int primary key identity,  
        Param nvarchar(100),  
        Label nvarchar(350),  
        Variable nvarchar(100),  
        Operator nvarchar(10),  
        Class nvarchar(1000),  
        Prec int)  
  
Create table #ac_Top5Downtimes  
(    SortOrder int,   
    DESC01 nvarchar(200),   
    DESC02 nvarchar(200),  
    WHEREString1 nvarchar(500),  
    WHEREString2 nvarchar(500))  
  
Create table #ac_Top5Stops  
(    SortOrder int,   
    DESC01 nvarchar(200),   
    DESC02 nvarchar(200),  
    WHEREString1 nvarchar(500),  
    WHEREString2 nvarchar(500))  
  
Create table #ac_Top5Rejects  
(    SortOrder int,   
    DESC01 nvarchar(200),   
    DESC02 nvarchar(200),  
    WHEREString1 nvarchar(500),  
    WHEREString2 nvarchar(500))  
  
Create Table #Temp_ColumnVisibility   
(      ColId int,  
    VariableName   varchar(100))  
  
  
Create Table  #Params   
      ( Param varchar(255),  
       Value varchar(2000))  
----------------------------------------------------------------------------------------------------------------------  
--    TABLE VARIABLES  
----------------------------------------------------------------------------------------------------------------------  
  
Declare @Temp_language_data Table  
     ( Prompt_Number varchar(20),   
      Prompt_String varchar(200),  
      language_id int)  
  
Declare @ColumnVisibility Table  
     (   ColId int primary key identity,  
      VariableName   varchar(100),  
         LabelName               varchar(100),  
         TranslatedName          varchar(100),  
         FieldName               varchar(100))  
  
Declare @Class Table  
     ( Line_Desc varchar(255),   
      PLID int,   
      Class_Code varchar(33),   
      Class int,   
      PU_ID int,   
      PuDesc varchar(255))  
  
Declare @Cursor Table  
     (   Cur_Id int primary key identity,  
            Major_id nvarchar(200),  
            Major_desc nvarchar(200),  
            Minor_id nvarchar(200),  
            Minor_desc nvarchar(200),  
            Major_Order_by int,  
            Minor_Order_by int)  
  
Declare @Temp_Uptime Table (  
         id  int,  
         pu_id  int,  
         Start_Time datetime,  
         End_Time  datetime,  
         Uptime  float,  
         LineStatus nvarchar(100),  
         Product  nvarchar(25))  
  
Declare @Make_Complete Table  
   (    pu_id int,  
       start_time datetime,  
       end_time datetime,  
       next_start_time datetime  
    )  
  
Declare @RE_Specs Table  
   (    spec_id   int,  
       spec_desc  varchar(200))  
  
Declare @Product_Specs Table  
   (     prod_code   nvarchar(20),  
        prod_desc      nvarchar(200),  
        spec_id  int,  
        spec_desc  nvarchar(200),  
        target   float)  
  
Declare @Conv_Class_Prod Table (  
       Class   int,  
       Prod_Id   varchar(20),  
       Value   float)  
  
Declare @RptEqns Table  
 (      VariableName    varchar(100),  
       Equation   varchar(1000))  
  
Declare @ClassREInfo Table (  
             Class int,  
             Conversion nvarchar(200))  
  
Create Table #Timed_Event_Detail_History  
       ( Tedet_ID int,  
         User_ID int)  
  
CREATE NONCLUSTERED INDEX IDX_DownHistory  
ON #Timed_Event_Detail_History(Tedet_ID) ON [PRIMARY]  
  
Declare @LineStatus Table  
       (PU_ID  int,  
       Phrase_Value  nvarchar(50),  
       StartTime  datetime,  
       EndTime  datetime)  
  
Declare @Products Table  
         (PU_ID       int,  
          Prod_ID      int,  
          Prod_Code      nvarchar(50),  
          Prod_Desc      nvarchar(100),  
          Product_Size    nvarchar(100),  
          StartTime      datetime,  
          EndTime      datetime  
      )  
  
Declare @Crew_Schedule Table  
       (StartTime        datetime,   
       EndTime           datetime,  
       Pu_id             int,  
       Crew              varchar(20),   
       Shift             varchar(5))  
  
  
----------------------------------------------------------------------------------------------------------------------  
-- END CREATE TEMPORARY TABLES :   
----------------------------------------------------------------------------------------------------------------------  
-- INITIALIZE TEMPORARY TABLES TO MINIMIZE RECOMPILE :  
--Print convert(varchar(25), getdate(), 120) + ' Start Initialization'   
----------------------------------------------------------------------------------------------------------------------  
  
set @r = (Select Count(*) FROM #PLIDList)  
set @r = (Select Count(*) FROM #ShiftDESCList)  
set @r = (Select Count(*) FROM #CrewDESCList)  
set @r = (Select Count(*) FROM #PLStatusDESCList)  
set @r = (Select Count(*) FROM #Splices)  
set @r = (Select Count(*) FROM #Rejects)  
set @r = (Select Count(*) FROM #Summary)  
set @r = (Select Count(*) FROM #Top5Downtime)  
set @r = (Select Count(*) FROM #Top5Stops)  
set @r = (Select Count(*) FROM #Top5Rejects)  
set @r = (Select Count(*) FROM #Downtimes)  
set @r = (Select Count(*) FROM #Production)  
set @r = (Select Count(*) FROM #TEMPORARY)  
set @r = (Select Count(*) FROM #InvertedSummary)  
set @r = (Select Count(*) FROM #FlexParam)  
set @r = (Select Count(*) FROM #ReasonsToExclude)  
set @r = (Select Count(*) FROM #Equations)  
set @r = (Select Count(*) FROM #ac_Top5Stops)  
set @r = (Select Count(*) FROM #ac_Top5Downtimes)  
set @r = (Select Count(*) FROM #ac_Top5Rejects)  
set @r = (Select Count(*) FROM #Params)  
----------------------------------------------------------------------------------------------------------------------  
--  GET Parameters FROM Report Name  
--Print convert(varchar(25), getdate(), 120) + ' End Initialization'   
----------------------------------------------------------------------------------------------------------------------  
DECLARE  
 @fltDBVersion   Float  
---------------------------------------------------------------------------------------------------  
-- Check Parameter: Database version  
---------------------------------------------------------------------------------------------------  
IF ( SELECT  IsNumeric(App_Version)  
   FROM AppVersions  
   WHERE App_Id = 2) = 1  
BEGIN  
 SELECT  @fltDBVersion = Convert(Float, App_Version)  
  FROM AppVersions  
  WHERE App_Id = 2  
END  
ELSE  
BEGIN  
 SELECT @fltDBVersion = 1.0  
END  
---------------------------------------------------------------------------------------------------  
--PRINT ' . DBVersion: ' + RTrim(LTrim(Str(@fltDBVersion, 10, 2))) -- debug  
---------------------------------------------------------------------------------------------------  
Declare   
  @Report_Id    as   Int  
  
Select @Rpt_ShowTop5Rejects  = 'TRUE'  
Select @Rpt_ShowTop5Downtimes  = 'TRUE'  
Select @Rpt_ShowTop5Stops   = 'TRUE'  
  
Select @Report_Id = Report_Id FROM Report_Definitions WHERE Report_Name = @Report_Name  
  
 Insert Into #Params (Param,Value)  
 Select rp.rp_name as param, rdp.value   
   FROM dbo.report_definition_parameters rdp WITH(NOLOCK)  
   JOIN dbo.report_type_parameters rtp WITH(NOLOCK) on rtp.rtp_id = rdp.rtp_id  
   JOIN dbo.report_parameters rp WITH(NOLOCK) on rp.rp_id = rtp.rp_id  
   WHERE rdp.Report_Id = @Report_Id  
  
  Select @RPTDowntimeFieldorder = value FROM #Params WHERE param = 'strRPTDowntimeFieldorder'  
  
     Select @RPTWasteFieldorder = value FROM #Params WHERE param  = 'strRPTWasteFieldorder'  
      
  -- GROUPING : set the two new parameters  
  Select @RPTMajorGroupBy = value FROM #Params WHERE param  = 'StrRptMajorGroupBy'  
  
  Select @RPTMinorGroupBy = value FROM #Params WHERE param  = 'StrRptMinorGroupBy'  
          
     Select @RPTDowntimeFilterMinutes = value FROM #Params WHERE param = 'Local_PG_TDowntime'  
   If @RPTDowntimeFilterMinutes Is Null Select @RPTDowntimeFilterMinutes = @RptFilterMinutes  
  Select @RPTFilterMinutes = value FROM #Params WHERE param = 'Local_PG_T'  
   If @RPTFilterMinutes Is Null Select @RptFilterMinutes = @RPTDowntimeFilterMinutes  
        Set @Local_PG_strRptDPRColumnVisibility = '!Null'  
  Select @Local_PG_strRptDPRColumnVisibility = IsNull(Value,'!Null') FROM #Params WHERE Param = 'Local_PG_StrRptDPRColumnVisibility'  
  Select @Local_PG_StrCategoriesToExclude = '!Null'  
        Select @Local_PG_StrCategoriesToExclude = IsNull(Value,'!Null') FROM #Params WHERE Param = 'Local_PG_StrCategoriesToExclude'  
        Select @RPTPLStatusDESCList = value FROM #Params WHERE Param = 'Local_PG_StrLineStatusName1'  
        Select @RPT_ShowClassProduct = value FROM #Params WHERE Param = 'DPR_ShowClassProduct'  
        Select @RptDowntimeSurvivalRate = value FROM #Params WHERE Param = 'intRptDowntimeSurvivalRate'  
  
        Select @Rpt_ShowTop5Rejects = Value FROM #Params WHERE Param = 'DPR_ShowTop5Rejects'  
        If @RPTMinorGroupBy = 'ProdDay'  
               Select @Rpt_ShowTop5Rejects = 'TRUE'  
          
        Select @Rpt_ShowTop5Stops = Value FROM #Params WHERE Param = 'DPR_ShowTop5Stops'  
        Select @Rpt_ShowTop5Downtimes = Value FROM #Params WHERE Param = 'DPR_ShowTop5Downtimes'  
          
        Select @RPT_ShowSplices = Value FROM #Params WHERE Param = 'DPR_TotalSplices'  
        Select @RPT_ShowSucSplices  = Value FROM #Params WHERE Param = 'DPR_SucSplices'  
  
        Select @RPT_SurvivalRate = Value FROM #Params WHERE Param = 'DPR_SurvivalRate'  
        Select @RPT_SurvivalRatePer = Value FROM #Params WHERE Param = 'DPR_SurvivalRate%'  
        Select @RPT_CaseCountClass = '3'  
        Select @RPT_CaseCountClass = IsNull(Value,'3') FROM #Params WHERE Param = 'DPR_CaseCount_EQN'  
       
  
Select @StartDateTime = @RptStartDate  
Select @EndDateTime = @RptEndDate  
  
--*******************************************************************************************************  
-- GROUPING : Insert into #Summary the labels for Report  
--*******************************************************************************************************  
-- Select * FROM #Status order by pu_id,starttime  
  
    
Insert #Summary   (GroupField,null02) Values ('Major',@RPTMajorGroupBy )  
Insert #Summary   (GroupField,null02) Values ('Minor',@RPTMinorGroupBy )  
If @RPT_ShowTop5Downtimes = 'TRUE'  
Begin  
 Insert #Top5Downtime   (GroupField) Values ('Major')  
 Insert #Top5Downtime   (GroupField) Values ('Minor')  
End  
If @RPT_ShowTop5Stops = 'TRUE'  
Begin  
 Insert #Top5Stops   (GroupField) Values ('Major')  
 Insert #Top5Stops   (GroupField) Values ('Minor')  
End  
If @RPT_ShowTop5Rejects = 'TRUE' and @RPTMinorGroupBy <> 'ProdDay'  
Begin  
 Insert #Top5Rejects   (GroupField) Values ('Major')  
 Insert #Top5Rejects   (GroupField) Values ('Minor')  
End  
--  
If @RPT_ShowTop5Downtimes = 'TRUE'  
        Insert #TOP5Downtime (Desc01, Desc02, Stops) Values (@lblDTLevel1, @lblDTLevel2, @lblStops)  
  
If @RPT_ShowTop5Stops = 'TRUE'  
        Insert #TOP5Stops (Desc01, Desc02, Downtime) Values (@lblDTLevel1, @lblDTLevel2, @lblDowntime)  
  
If @RPT_ShowTop5Rejects = 'TRUE' and @RPTMinorGroupBy <> 'ProdDay'  
        Insert #TOP5REJECTS (Desc01, Desc02, Events) Values (@lblRJLevel1, @lblRJLevel2, @lblEvents)  
  
-----------------------------------------------------------------------------------------------------------------  
-- Insert values in the Column Visibility table to be used for Report Output  
--Print convert(varchar(25), getdate(), 120) + ' Start Building Column Visibility TABLE'  
-----------------------------------------------------------------------------------------------------------------  
  
Declare @NoLabels as int  
  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Availability','Availability','Availability')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('PRusingProductCount','PR using Product Count','PR')  
-- Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('PRusingAvailability','PR using Availability','PRavail')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('SU','Schedule Utilization','SU')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('CU','Capacity Utilization','CU')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('RU','Rate Utilization','RU')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('RunEfficiency','Run Efficiency','RunEff')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Line_Stops','Line Stops','LineStops')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('LineStopsUnplanned','Line Stops (Unplanned)','LineStopsERC')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Stops/Day','Stops/Day','StopsPerDay')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Stops/MSU','Stops/MSU','StopsPerMSU')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Down/MSU','Down/MSU','DownPerMSU')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Downtime','Downtime','Downtime')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('DowntimeUnplanned','Downtime (Unplanned)','DowntimeERC')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Uptime','Uptime','Uptime')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('MTBF','MTBF','MTBF')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('MTBF_Unplanned','MTBF (Unplanned)','MTBF_ERC')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('MTTR','MTTR','MTTR')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('MTTR_Unplanned','MTTR (Unplanned)','MTTR_ERC')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('ACPStops','ACP Stops','ACPStops')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('ACPStops/Day','ACP Stops/Day','ACPSTOpsperday')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Scrap','Rejected Product','TotalScrap')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Scrap%','Scrap %','TotalScrapPer')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('RunningScrap%','Running Scrap %','RunningScrapPer')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('DowntimeScrap%','Downtime Scrap %','DowntimescrapPer')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('RunningScrap','Running Scrap','RunningScrap')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('DowntimeScrap','Downtime Scrap','DowntimeScrap')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Area4Loss%','Area 4 Loss %','Area4LossPer')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('RepairTime>T','Repair Time > 10','RepairTimeT')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('FalseStarts(UT=0)','False Starts (UT=0)','FalseStarts')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('FalseStarts(UT=0)%','False Starts (UT=0)%','FalseStarts0Per')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('FalseStarts(UT=T)','False Starts (UT=T)','FalseStartsT')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('FalseStarts(UT=T)%','False Starts (UT=T)%','FalseStartsTPer')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('R(T=0)','R(0)','Rofzero')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('R(T=T)','R(2)','RofT')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('SurvivalRate','Survival Rate','SurvivalRate')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('SurvivalRate% ','Survival Rate %','SurvivalRatePer')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('TotalSplices','Total Splices','TotalSplices')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('SucSplices','Success Splices','SucSplices')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('FailedSplices','Failed Splices','FailedSplices')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('SuccessRate','Success Rate','SuccessRate')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('MSU','MSU','MSU')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('TotalProduct','Total Product','TotalPads')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass1Product','Total ' + IsNull(value,'Class1') + ' Product' ,'Totalclass1' FROM #Params WHERE param = 'DPR_Class1_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass2Product','Total ' + IsNull(value,'Class2') + ' Product' ,'Totalclass2' FROM #Params WHERE param = 'DPR_Class2_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass3Product','Total ' + IsNull(value,'Class3') + ' Product' ,'Totalclass3' FROM #Params WHERE param = 'DPR_Class3_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass4Product','Total ' + IsNull(value,'Class4') + ' Product' ,'Totalclass4' FROM #Params WHERE param = 'DPR_Class4_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass5Product','Total ' + IsNull(value,'Class5') + ' Product' ,'Totalclass5' FROM #Params WHERE param = 'DPR_Class5_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass6Product','Total ' + IsNull(value,'Class6') + ' Product' ,'Totalclass6' FROM #Params WHERE param = 'DPR_Class6_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass7Product','Total ' + IsNull(value,'Class7') + ' Product' ,'Totalclass8' FROM #Params WHERE param = 'DPR_Class7_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass8Product','Total ' + IsNull(value,'Class8') + ' Product' ,'Totalclass8' FROM #Params WHERE param = 'DPR_Class8_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass9Product','Total ' + IsNull(value,'Class9') + ' Product' ,'Totalclass9' FROM #Params WHERE param = 'DPR_Class9_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass10Product','Total ' + IsNull(value,'Class10') + ' Product' ,'Totalclass10' FROM #Params WHERE param = 'DPR_Class10_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass11Product','Total ' + IsNull(value,'Class11') + ' Product' ,'Totalclass11' FROM #Params WHERE param = 'DPR_Class11_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass12Product','Total ' + IsNull(value,'Class12') + ' Product' ,'Totalclass12' FROM #Params WHERE param = 'DPR_Class12_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass13Product','Total ' + IsNull(value,'Class13') + ' Product' ,'Totalclass13' FROM #Params WHERE param = 'DPR_Class13_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass14Product','Total ' + IsNull(value,'Class14') + ' Product' ,'Totalclass14' FROM #Params WHERE param = 'DPR_Class14_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass15Product','Total ' + IsNull(value,'Class15') + ' Product' ,'Totalclass15' FROM #Params WHERE param = 'DPR_Class15_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass16Product','Total ' + IsNull(value,'Class16') + ' Product' ,'Totalclass16' FROM #Params WHERE param = 'DPR_Class16_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass17Product','Total ' + IsNull(value,'Class17') + ' Product' ,'Totalclass17' FROM #Params WHERE param = 'DPR_Class17_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass18Product','Total ' + IsNull(value,'Class18') + ' Product' ,'Totalclass18' FROM #Params WHERE param = 'DPR_Class18_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass19Product','Total ' + IsNull(value,'Class19') + ' Product' ,'Totalclass19' FROM #Params WHERE param = 'DPR_Class19_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'TotalClass20Product','Total ' + IsNull(value,'Class20') + ' Product' ,'Totalclass20' FROM #Params WHERE param = 'DPR_Class20_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('GoodProduct','Good Product','GoodPads')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass1Product','Good ' + IsNull(value,'Class1') + ' Product','GoodClass1' FROM #Params WHERE param = 'DPR_Class1_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass2Product','Good ' + IsNull(value,'Class2') + ' Product','GoodClass2' FROM #Params WHERE param = 'DPR_Class2_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass3Product','Good ' + IsNull(value,'Class3') + ' Product','GoodClass3' FROM #Params WHERE param = 'DPR_Class3_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass4Product','Good ' + IsNull(value,'Class4') + ' Product','GoodClass4' FROM #Params WHERE param = 'DPR_Class4_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass5Product','Good ' + IsNull(value,'Class5') + ' Product','GoodClass5' FROM #Params WHERE param = 'DPR_Class5_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass6Product','Good ' + IsNull(value,'Class6') + ' Product','GoodClass6' FROM #Params WHERE param = 'DPR_Class6_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass7Product','Good ' + IsNull(value,'Class7') + ' Product','GoodClass7' FROM #Params WHERE param = 'DPR_Class7_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass8Product','Good ' + IsNull(value,'Class8') + ' Product','GoodClass8' FROM #Params WHERE param = 'DPR_Class8_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass9Product','Good ' + IsNull(value,'Class9') + ' Product','GoodClass9' FROM #Params WHERE param = 'DPR_Class9_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass10Product','Good ' + IsNull(value,'Class10') + ' Product','GoodClass10' FROM #Params WHERE param = 'DPR_Class10_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass11Product','Good ' + IsNull(value,'Class11') + ' Product','GoodClass11' FROM #Params WHERE param = 'DPR_Class11_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass12Product','Good ' + IsNull(value,'Class12') + ' Product','GoodClass12' FROM #Params WHERE param = 'DPR_Class12_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass13Product','Good ' + IsNull(value,'Class13') + ' Product','GoodClass13' FROM #Params WHERE param = 'DPR_Class13_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass14Product','Good ' + IsNull(value,'Class14') + ' Product','GoodClass14' FROM #Params WHERE param = 'DPR_Class14_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass15Product','Good ' + IsNull(value,'Class15') + ' Product','GoodClass15' FROM #Params WHERE param = 'DPR_Class15_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass16Product','Good ' + IsNull(value,'Class16') + ' Product','GoodClass16' FROM #Params WHERE param = 'DPR_Class16_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass17Product','Good ' + IsNull(value,'Class17') + ' Product','GoodClass17' FROM #Params WHERE param = 'DPR_Class17_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass18Product','Good ' + IsNull(value,'Class18') + ' Product','GoodClass18' FROM #Params WHERE param = 'DPR_Class18_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass19Product','Good ' + IsNull(value,'Class19') + ' Product','GoodClass19' FROM #Params WHERE param = 'DPR_Class19_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Select 'GoodClass20Product','Good ' + IsNull(value,'Class20') + ' Product','GoodClass20' FROM #Params WHERE param = 'DPR_Class20_Translation'  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('TargetSpeed','Target Speed','TargetSpeed')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('IdealSpeed','Ideal Speed','IdealSpeed')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('AverageLineSpeed','Line Speed','LineSpeed')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('ProductionTime','Line Status Schedule Time','ProdTime')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('STNU','Staff Time Not Used','STNU')  
  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('RealDowntime','Real Downtime','TotalDowntime')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('RealUptime','Real Uptime','TotalUptime')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('EditedStops','Edited Stops','NumEdits')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('EditedStops%','Edited Stops %','EditedStopsPer')  
  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_1','Flexible_Variable_1','Flex1')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_2','Flexible_Variable_2','Flex2')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_3','Flexible_Variable_3','Flex3')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_4','Flexible_Variable_4','Flex4')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_5','Flexible_Variable_5','Flex5')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_6','Flexible_Variable_6','Flex6')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_7','Flexible_Variable_7','Flex7')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_8','Flexible_Variable_8','Flex8')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_9','Flexible_Variable_9','Flex9')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('Flexible_Variable_10','Flexible_Variable_10','Flex10')  
  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('EditedStopsReason1','Edited Stops Reason 1','NumEditsR1')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('EditedStopsReason1%','Edited Stops Reason 1%','EditedStopsR1Per')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('EditedStopsReason2','Edited Stops Reason 2','NumEditsR2')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('EditedStopsReason2%','Edited Stops Reason 2%','EditedStopsR2Per')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('EditedStopsReason3','Edited Stops Reason 3','NumEditsR3')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('EditedStopsReason3%','Edited Stops Reason 3%','EditedStopsR3Per')  
Insert Into @ColumnVisibility(VariableName,LabelName,FieldName) Values('CaseCounter','CaseCounter','CaseCount')  
  
Select @NoLabels = Count(*) FROM @ColumnVisibility  
  
-----------------------------------------------------------------------------------------------------------  
--Print convert(varchar(25), getdate(), 120) + ' END Building Column Visibility TABLE'  
-----------------------------------------------------------------------------------------------------------  
-- FORMAT MAJOR AND MINOR GROUPING   
 Declare   
        @RPTMinorGroupByOld as nvarchar(100),  
        @RPTMajorGroupByOld as nvarchar(100)  
  
 Set  @RPTMajorGroupByOld = @RPTMajorGroupBy   
          
 If @RPTMinorGroupBy = @RPTMajorGroupBy   
        Set @RPTMinorGroupBy = 'None'  
  
 If @RPTMinorGroupBy = 'None'  
 Begin  
 Set @RPTMinorGroupBy = @RPTMajorGroupBy  
        Set @RPTMajorGroupBy = 'Line'  
 End  
  
 Set  @RPTMinorGroupByOld = @RPTMinorGroupBy  
  
-----------------------------------------------------------------------------------------------------------  
  
-- Checking the strRptPageOrientation parameter modify the DPR_HorizontalLayout  
--  if landscape layout, then only one reason column is displayed so the second sort order must be null  
Declare @strRptPageOrientation as nvarchar(20)  
  
Select @strRptPageOrientation = value FROM #Params WHERE param like '%strRptPageOrientation%'  
  
If @strRptPageOrientation = 'Landscape'  
 UPDATE #Params Set value = 'TRUE' WHERE param = 'DPR_HorizontalLayout'  
Else  
 UPDATE #Params Set value = 'FALSE' WHERE param = 'DPR_HorizontalLayout'  
  
If (Select value FROM #Params WHERE param = 'DPR_HorizontalLayout') = 'TRUE'  
 Begin  
  Select @RPTDowntimeFieldOrder=LEFT(@RptDowntimeFieldOrder,CHARINDEX('~',@RptDowntimeFieldOrder))+'!Null'  
  Select @RPTWasteFieldOrder=LEFT(@RptWasteFieldOrder,CHARINDEX('~',@RPTwasteFieldOrder))+'!Null'  
 End   
  
----------------------------------------------------------------------------  
-- Check Parameter: Company and Site Name  
----------------------------------------------------------------------------  
Select @CompanyName = Coalesce(Value, 'Company Name') -- Company Name  
 FROM Site_Parameters  
 WHERE Parm_Id = 11  
  
Select @SiteName = Coalesce(Value, 'Site Name') -- Site Name  
 FROM Site_Parameters  
 WHERE Parm_Id = 12  
----------------------------------------------------------------------------  
-- Check Parameter: Downtime User used For PLCEP, should be ReliablitySystem   
----------------------------------------------------------------------------  
Select @DowntimesystemUserID =   
 User_ID  
 FROM USERS  
 WHERE UserName = @RPTDowntimesystemUser  
  
If @DowntimesystemUserID Is null  
Begin  
 Select @ErrMsg = 'Downtime User ID Is null'  
 --GOTO ErrorCode  
End  
  
----------------------------------------------------------------------------  
-- Check Parameter: Specifications  
----------------------------------------------------------------------------  
-- @RPTPadsPerStat  
  
Select @SpecPropertyID = PROP_ID  
 FROM dbo.Product_Properties WITH(NOLOCK)  
 WHERE Prop_Desc = @RPTSpecProperty  
  
Select @PadsPerStatSpecID = Spec_ID  
 FROM dbo.Specifications ss WITH(NOLOCK)  
 WHERE (Spec_Desc like '%Per Stat%' Or Spec_Desc ='Stat Unit')  
 and Prop_Id = @SpecPropertyID  
  
Select @IdealSpeedSpecID = Spec_ID  
 FROM dbo.Specifications ss WITH(NOLOCK)  
 WHERE Spec_Desc = @RPTIdealSpeed   
 and Prop_Id = @SpecPropertyID  
----------------------------------------------------------------------------------------------------------------------  
-- String Parsing: Parse Line ID, also gets info associated Only to the Line  
-- e.g the Converter Unit ID.  
----------------------------------------------------------------------------------------------------------------------  
  
Select @LineSpec = Value FROM #Params WHERE Param = 'Local_PG_strLinesByName1'  
  
Insert #Temp_LinesParam (RecId,PlDesc)  
   Exec SPCMN_ReportCollectionParsing  
   @PRMCollectionString = @LineSpec, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',   
   @PRMDataType01 = 'nvarchar(200)'  
  
Declare   
  @LS_Prop_Id  as  Int  
  
Select @LS_Prop_Id = Prop_Id FROM Product_Properties WHERE Prop_Desc = 'Line Configuration'  
  
Insert Into @Class  
Select cc.Char_Desc, cc.Char_Id, ss.Spec_Desc,Null, pu.PU_ID, PU_Desc  
FROM dbo.Specifications ss WITH(NOLOCK)   
Join dbo.Characteristics cc WITH(NOLOCK) on cc.prop_id = ss.prop_id   
Join dbo.Active_Specs sa WITH(NOLOCK) on sa.char_id = cc.char_id and sa.spec_id = ss.spec_id and sa.expiration_date is Null  
Join dbo.Prod_Units pu WITH(NOLOCK) on pu.pu_id = cast(cast (sa.target as float)as int)  
WHERE cc.Char_Desc In (Select PLDesc FROM #Temp_LinesParam)  
   and ss.Prop_Id = @LS_Prop_Id  
  
-- Step 2 : GET ALL THE CLASSES  
  
UPDATE @Class Set Class = 1 WHERE charindex( '_I_', Class_Code)>0  
UPDATE @Class Set Class = 2 WHERE charindex( '_II_', Class_Code)>0  
UPDATE @Class Set Class = 3 WHERE charindex( '_III_', Class_Code)>0  
UPDATE @Class Set Class = 4 WHERE charindex( '_IV_', Class_Code)>0  
UPDATE @Class Set Class = 5 WHERE charindex( '_V_', Class_Code)>0  
UPDATE @Class Set Class = 6 WHERE charindex( '_VI_', Class_Code)>0  
UPDATE @Class Set Class = 7 WHERE charindex( '_VII_', Class_Code)>0  
UPDATE @Class Set Class = 8 WHERE charindex( '_VIII_', Class_Code)>0  
UPDATE @Class Set Class = 9 WHERE charindex( '_IX_', Class_Code)>0  
UPDATE @Class Set Class = 10 WHERE charindex( '_X_', Class_Code)>0  
UPDATE @Class Set Class = 11 WHERE charindex( '_XI_', Class_Code)>0  
UPDATE @Class Set Class = 12 WHERE charindex( '_XII_', Class_Code)>0  
UPDATE @Class Set Class = 13 WHERE charindex( '_XIII_', Class_Code)>0  
UPDATE @Class Set Class = 14 WHERE charindex( '_XIV_', Class_Code)>0  
UPDATE @Class Set Class = 15 WHERE charindex( '_XV_', Class_Code)>0  
UPDATE @Class Set Class = 16 WHERE charindex( '_XVI_', Class_Code)>0  
UPDATE @Class Set Class = 17 WHERE charindex( '_XVII_', Class_Code)>0  
UPDATE @Class Set Class = 18 WHERE charindex( '_XVIII_', Class_Code)>0  
UPDATE @Class Set Class = 19 WHERE charindex( '_XIX_', Class_Code)>0  
UPDATE @Class Set Class = 20 WHERE charindex( '_XX_', Class_Code)>0  
  
  
UPDATE @Class   
        Set PLID = PL_Id  
FROM @Class c  
Join Prod_Lines PL WITH(NOLOCK) on c.Line_Desc = pl.pl_desc  
  
Insert #PLIDList (Class, PLID, ConvUnit,PLDESC,UseCaseCount)    
Select Class, PLID, PU_Id, Line_Desc,0 FROM @Class  
  
-- Select * FROM @Class  
-- Select * FROM #PLIDList  
------------------------------------------------------------------------------------------------  
-- Get column visibility parameter  
------------------------------------------------------------------------------------------------  
--Print convert(varchar(25), getdate(), 120) + ' Get Column Visibility Parameters'  
  
If @Local_PG_strRptDPRColumnVisibility <> '!Null'  
Begin  
   --   
   Insert #Temp_ColumnVisibility (ColId,VariableName)  
   Exec SPCMN_ReportCollectionParsing  
   @PRMCollectionString = @Local_PG_strRptDPRColumnVisibility, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',   
   @PRMDataType01 = 'varchar(100)'                                    
   --   
            If exists (select * FROM #Temp_ColumnVisibility WHERE VariableName Like '%ShowClassProduct%')  
                                Select @RPT_ShowClassProduct = 'TRUE'  
         Else  
                                Select @RPT_ShowClassProduct = 'FALSE'       
  
   -- Before deleting all Parameters set them to FALSE  
     
   UPDATE dbo.Report_Definition_Parameters   
           Set Value = 'FALSE'  
   FROM dbo.Report_Definition_Parameters rdp WITH(NOLOCK)  
   Join dbo.Report_Definitions r WITH(NOLOCK) on rdp.report_id=r.report_id  
   Join dbo.Report_Type_Parameters rtp WITH(NOLOCK) on rtp.rtp_id = rdp.rtp_id  
   Join dbo.Report_Parameters rp WITH(NOLOCK) on rp.rp_id = rtp.rp_id  
   WHERE r.report_id = @Report_Id  
   AND rp_name IN (SELECT 'DPR_' + VariableName FROM @ColumnVisibility  
       WHERE VariableName Not Like 'TotalClass%'  
                And VariableName Not Like 'GoodClass%'             
                And VariableName Not Like 'Flexible_Variable_%')  
     
   --  
            Delete FROM @ColumnVisibility WHERE VariableName Not In (Select VariableName FROM #Temp_ColumnVisibility)  
            And VariableName Not Like 'TotalClass%'  
            And VariableName Not Like 'GoodClass%'             
            And VariableName Not Like 'Flexible_Variable_%'  
  
End     
Else  
Begin            
      --  
                        Delete FROM @ColumnVisibility   
                        FROM @ColumnVisibility CV  
                        WHERE VariableName Not In (select CV.VariableName FROM #Params WHERE param = 'DPR_' + CV.VariableName And value = 'TRUE')  
                        And VariableName Not Like 'TotalClass%'  
                        And VariableName Not Like 'GoodClass%'                          
                        And VariableName Not Like 'Flexible_Variable_%'  
      --  
End  
  
Delete FROM @ColumnVisibility   
WHERE   
  (VariableName Like 'TotalClass%' Or VariableName Like 'GoodClass%')  
  And  
  (VariableName Not In  
  (Select Distinct 'TotalClass'+Convert(nvarchar,Class)+'Product' FROM @Class))  
  And   
  (VariableName Not In  
  (Select Distinct 'GoodClass'+Convert(nvarchar,Class)+'Product' FROM @Class))  
  
If @RPT_ShowClassProduct = 'FALSE'   
  Delete FROM @ColumnVisibility WHERE VariableName like 'TotalClass%' or VariableName like 'GoodClass%'  
Else  
     Delete FROM @ColumnVisibility WHERE VariableName like 'TotalProduct' or VariableName like 'GoodProduct'  
  
  
--------------------------------------------------------------------------------------------------  
-- Get the EQN for each 'Defined' variable :  
--------------------------------------------------------------------------------------------------  
  
Insert Into #Equations (Param,Label,Variable,Operator,Class,Prec)  
Select param,NULL,  
(case param When 'DPR_Downtime_EQN'         Then 'Downtime'   
            When 'DPR_GoodProduct_EQN'      Then 'GoodPads'  
            When 'DPR_LineStops_EQN'        Then 'LineStops'  
            When 'DPR_Scrap_EQN'            Then 'TotalScrap'  
            When 'DPR_TargetSpeed_EQN'      Then 'TargetSpeed'  
            When 'DPR_TotalProduct_EQN'     Then 'TotalPads'  
            When 'DPR_TotalSplices_EQN'     Then 'TotalSplices'  
            When 'DPR_ACPStops_EQN'         Then 'ACPStops'  
            When 'DPR_TotalProdTime_EQN'    Then 'ProdTime'  
        end),  
substring(value,charindex('OP=',value)+3,charindex(';CLASS=',value)-(charindex('OP=',value)+3)) as Op,  
substring(value,charindex(';CLASS=',value)+7,Len(value)-(charindex(';CLASS=',value)+6)) as Class,  
1 as Prec  
FROM #Params  
WHERE right(param,4)='_EQN' and param <> 'DPR_CaseCount_EQN'  
  
-- Select * FROM #Equations  
-- LineStops  
Insert Into #Equations Select 'DPR_RepairTime>T_EQN','Label=RepairTimeT;','RepairTimeT',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
Insert Into #Equations Select 'DPR_SurvivalRate_EQN','Label=SurvivalRate;','SurvivalRate',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
Insert Into #Equations Select 'DPR_EditedStops_EQN','Label=NumEdits;','NumEdits',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
Insert Into #Equations Select 'DPR_FalseStarts(UT=0)_EQN','Label=FalseStarts;','FalseStarts',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
Insert Into #Equations Select 'DPR_FalseStarts(UT=T)_EQN','Label=FalseStartsT;','FalseStartsT',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
-- Added  
Insert Into #Equations Select 'DPR_EditedStops_EQN','Label=NumEditsR1;','NumEditsR1',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
Insert Into #Equations Select 'DPR_EditedStops_EQN','Label=NumEditsR2;','NumEditsR2',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
Insert Into #Equations Select 'DPR_EditedStops_EQN','Label=NumEditsR3;','NumEditsR3',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
Insert Into #Equations Select 'DPR_FalseStarts(UT=0)_EQN','Label=FalseStarts;','FalseStarts',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
Insert Into #Equations Select 'DPR_FalseStarts(UT=T)_EQN','Label=FalseStartsT;','FalseStartsT',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
-- TotalSplices  
Insert Into #Equations Select 'DPR_SuccessRate_EQN','Label=SuccessRate;','SuccessRate',Operator,Class,1 FROM #Equations WHERE Variable = 'TotalSplices'  
Insert Into #Equations Select 'DPR_SucSplices_EQN','Label=SucSplices;','SucSplices',Operator,Class,1 FROM #Equations WHERE Variable = 'TotalSplices'  
Insert Into #Equations Select 'DPR_FailedSplices_EQN','Label=FailedSplices;','FailedSplices',Operator,Class,1 FROM #Equations WHERE Variable = 'TotalSplices'  
-- TotalScrap  
Insert Into #Equations Select 'DPR_DowntimeScrap_EQN','Label=DowntimeScrap;','DowntimeScrap',Operator,Class,1 FROM #Equations WHERE Variable = 'TotalScrap'  
Insert Into #Equations Select 'DPR_RunningScrap_EQN','Label=RunningScrap;','RunningScrap',Operator,Class,1 FROM #Equations WHERE Variable = 'TotalScrap'  
-- Downtime  
Insert Into #Equations Select 'DPR_Uptime_EQN','Label=Uptime;','Uptime',Operator,Class,1 FROM #Equations WHERE Variable = 'Downtime'  
-- Production Time  
Insert Into #Equations Select 'DPR_CalendarTime_EQN','Label=CalendarTime;','CalendarTime',Operator,Class,1 FROM #Equations WHERE Variable = 'ProdTime'  
-- Good Product  
Insert Into #Equations Select 'DPR_MSU_EQN','Label=MSU;','MSU',Operator,Class,2 FROM #Equations WHERE Variable = 'GoodPads'  
-- Target Speed  
Insert Into #Equations Select 'DPR_IdealSpeed_EQN','Label=IdealSpeed;','IdealSpeed',Operator,Class,1 FROM #Equations WHERE Variable = 'TargetSpeed'  
-- Total Production Time  
INSERT INTO #Equations SELECT 'DPR_STNU_EQN','Label=STNU;','STNU',Operator,Class,1 FROM #Equations WHERE Variable = 'ProdTime'  
  
-- SELECT * FROM #Equations  
--------------------------------------------------------------------------------------------------  
-- Get the RE Product Info for each Class :  
--------------------------------------------------------------------------------------------------  
  
Insert Into @ClassREInfo (Class,Conversion)  
Select substring(param,charindex('Class',param)+5,charindex('ProductInfo',param)-(charindex('Class',param)+5)),value   
FROM #Params   
WHERE param like '%ProductInfo'  
And (Value Is Not NULL Or Value > '')  
  
------------------------------------------------------------------------------------------------  
-- New logic to get the PU Extended info  
--Print convert(varchar(25), getdate(), 120) + ' New logic to get the PU Extended info'  
------------------------------------------------------------------------------------------------  
UPDATE #PlidList Set ScheduleUnit=Substring(SubString(pu.Extended_Info,6,len(pu.Extended_Info)),1,Charindex(';',pu.Extended_Info)-6)  
   FROM #PlidList PLID  
                        Join Prod_Units pu on PLID.ConvUnit = pu.pu_id --WHERE ConvUnit = @Conv -- and ScheduleUnit>0  
                        WHERE Extended_Info Like '%STLS%'  
  
UPDATE #PLIDList Set ScheduleUnit = ConvUnit WHERE ScheduleUnit Is Null  
UPDATE #PLIDList Set ProductUnit = ConvUnit WHERE ProductUnit Is Null  
  
-- End PU Extended Info  
------------------------------------------------------------------------------------------------------  
  
--****************************************************************************************************  
-- BUILD the #PLIDList Table with units information  
--Print convert(varchar(25), getdate(), 120) + ' BUILD the #PLIDList Table with units information'  
--****************************************************************************************************  
   
UPDATE TPL Set SpliceUnit = PU.PU_ID  
 FROM #PLIDList TPL  
 Join dbo.Prod_Lines pl WITH(NOLOCK) on TPL.PLDesc = pl.PL_Desc  
 Join @Class c on c.pu_id = TPL.convUnit and c.class_code = 'Class_I_1'  
 Join dbo.Prod_Units pu WITH(NOLOCK) on pu.pl_id = pl.pl_id and pu.pu_desc Like '%Splicers%'  
  
UPDATE TPL Set PartPadCountVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Variables V WITH(NOLOCK) on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type IN(0,5)  
  and (V.test_name Like '%'+ @RPTPadCountTag + '%' or V.test_name ='ProductionCNT')  
  and V.DATA_Type_ID IN(1,2)  
   
UPDATE TPL Set CompPadCountVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Variables V WITH(NOLOCK) on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and (V.test_name Like '%'+ @RPTPadCountTag + '%' or V.test_name ='ProductionCNT' )  
  and V.DATA_Type_ID IN(1,2)  
  
-- UPDATE TPL Set Class = 3 FROM #PLIDList TPL WHERE CompPadCountVarID is not null  
  
UPDATE TPL Set PartCaseCountVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Prod_units pu WITH(NOLOCK) on pu.pu_id = tpl.convunit  
 Join dbo.Variables V WITH(NOLOCK) on V.PU_ID = pu.pu_id  
  and V.Event_Type IN(0,5)  
  and (v.extended_info like '%PRCaseCount%' and v.user_defined1 = 'Class'+@RPT_CaseCountClass )  
  and V.DATA_Type_ID IN(1,2)  
  
-- Get Complete Case Counter  
UPDATE TPL Set CompCaseCountVarID = VAR_ID  
 FROM #PLIDList TPL  
 join dbo.Prod_units pu WITH(NOLOCK) on pu.pu_id = tpl.convunit  
 Join dbo.Variables V WITH(NOLOCK) on V.PU_ID = pu.pu_id  
  and V.Event_Type = 1  
  and (v.extended_info like '%PRCaseCount%' and v.user_defined1 = 'Class'+@RPT_CaseCountClass )  
  and V.DATA_Type_ID IN(1,2)  
  
-- Step 3 : Get the partial case counter  
-- If the Partial Case Counter user_defined2 field like 'UseCaseCount' the use CaseCount for GoodPads  
  
UPDATE TPL Set PartRunCountVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Variables V WITH(NOLOCK) on TPL.ConvUnit = V.PU_ID  
  and V.Event_Type IN(0,5)  
  and V.test_name Like '%'+ @RPTRunCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
  
UPDATE TPL Set CompRunCountVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Variables V WITH(NOLOCK) on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and V.test_name Like '%'+ @RPTRunCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
  
UPDATE TPL Set CompStartUPCountVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Variables V WITH(NOLOCK) on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and V.test_name Like '%'+ @RPTStartUPCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
  
UPDATE TPL Set PartStartUPCountVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Variables V WITH(NOLOCK) on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type IN(0,5)  
  and V.test_name Like '%'+ @RPTStartUPCountTag + '%'  
  and V.DATA_Type_ID IN(1,2)  
  
UPDATE TPL Set PartSpeedTargetVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Variables V WITH(NOLOCK) on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type in ( 0,5)  
  and v.test_name = @RPTConvertERSpeedTag  
  and V.DATA_Type_ID IN(1,2)  
  
UPDATE TPL Set CompSpeedTargetVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Variables V WITH(NOLOCK) on TPL.ConVUnit = V.PU_ID  
  and V.Event_Type = 1  
  and v.test_name = @RPTConvertERSpeedTag   
  and V.DATA_Type_ID IN(1,2)  
  
UPDATE TPL Set REDowntimeVarID = VAR_ID  
 FROM #PLIDList TPL  
 Join dbo.Variables V WITH(NOLOCK) on TPL.ConVUnit = V.PU_ID  
  and V.Extended_Info Like '%'+ @RPTDowntimeTag  
  
--****************************************************************************************************  
-- END BUILD the #PLIDList Table  
--****************************************************************************************************  
-- Select * FROM #PLIDList  
------------------------------------------------------------------------------------------------------  
-- FRio New code for Flex Variables  
--Print convert(varchar(25), getdate(), 120) + 'Flex Variables'  
------------------------------------------------------------------------------------------------------  
  
Declare   
 @k as int,  
 @Flex_param as nvarchar(100),  
 @u as varchar(100),  
 @v as varchar(100),   @rows_no as int,  
 @SQLunit as nvarchar(100)   
  
Set @k = 1  
  
While @k < 11  
Begin  
  
 -- Aqui hay que hacer un Split para quedarme con la Unidad del parametro  
 -- Si el | no esta en la variable entonces asumo que es la convertidora   
 Set @Flex_param = null  
  
 Set @Flex_param = (Select value FROM #Params   
  WHERE param = 'dpr_flexible_variable_' + convert(varchar,@k))    
  
 Insert Into #FlexParam (Temp1,Temp2)  
 Exec SPCMN_ReportCollectionParsing  
   @PRMCollectionString = @Flex_param, @PRMFieldDelimiter = null, @PRMRecordDelimiter = '|',   
   @PRMDataType01 = 'varchar(100)'  
   
 Select @rows_no = count(*) FROM #FlexParam  
 If @rows_no = 2    
 Begin  
  Set @u = (Select Temp2 FROM #FlexParam WHERE Temp1 = 1)  
  Set @v = (Select Temp2 FROM #FlexParam WHERE Temp1 = 2)  
 End  
 Else  
  Set @v = (Select Temp2 FROM #FlexParam WHERE Temp1 = 1)  
  
  
 Set @SQLString = ' UPDATE TPL set flex' + convert(varchar,@k)  + ' = v.var_id ' +  
           ' FROM dbo.Variables v WITH(NOLOCK) ' +  
           ' Join #PLIDList TPL on v.pu_id = TPL.ConvUnit ' +  
                 ' Join dbo.Prod_Units pu on pu.pu_id = TPL.ConvUnit ' +  
                 ' WHERE pu.Pu_Desc Like ''' + '%' + @u  + '%' + '''' +  
           ' and v.var_desc = ''' + @v + ''''   
  
 Exec(@SQLString)   
    
 Set @SQLString = ' UPDATE #Params set value = ''' + @v + '''' +  
           ' WHERE param = ''' + 'DPR_flexible_variable_' + convert(varchar,@k) + ''''  
  
 Exec(@SQLString)  
  
 Set @k = @k + 1  
 Truncate Table #FlexParam  
  
End  
  
Delete FROM @ColumnVisibility WHERE VariableName Like 'Flexible_Variable_%' And  
VariableName Not In (  
Select SubString(Param,5,Len(Param)-4) FROM #Params WHERE param like 'DPR_Flexible_Variable_%' and Len(Value) > 1)  
  
------------------------------------------------------------------------------------------------------  
-- End Flex Variables  
------------------------------------------------------------------------------------------------------  
--*******************************************************************************************************  
-- Start building Products Table  
--Print convert(varchar(25), getdate(), 120) + ' Build @Products Table'  
--*******************************************************************************************************  
  
Insert Into @Products(PU_ID ,Prod_ID,Prod_Code,Prod_Desc,Product_Size,StartTime,EndTime)  
Select PU_ID,P.Prod_ID,Prod_Code,Prod_Desc,'',start_Time as StartTime,End_Time as EndTime  
 FROM dbo.Production_Starts Ps WITH(NOLOCK)      
 Join #PLIDList pl on ps.pu_id = pl.convUnit  
    Join dbo.Products P WITH(NOLOCK) on PS.Prod_ID = P.Prod_ID      
        WHERE  
          Ps.Start_Time <= @EndDateTime and  
            (Ps.End_Time > @StartDateTime or PS.End_TIME IS null)  
  
-- This statement avoid same product that belongs to different sizes to cause duplicated entries  
UPDATE @Products   
 Set Product_Size = pg.Product_Grp_Desc  
FROM @Products p  
Join dbo.Product_Group_Data pgd WITH(NOLOCK) on pgd.Prod_Id = P.Prod_Id  
Join dbo.Product_Groups pg WITH(NOLOCK) on pgd.product_grp_id = pg.product_grp_id  
   
Insert Into @RE_Specs (Spec_Id,Spec_Desc)  
Select spec_id,spec_desc  
FROM Specifications   
WHERE Prop_Id = (Select Prop_Id   
    FROM Product_Properties WHERE Prop_Desc = 'RE_Product Information')  
  
INSERT INTO @Product_Specs (Prod_Code,  
       Prod_Desc,  
       Spec_Id,  
       Spec_Desc,  
       Target)  
Select Distinct    p.Prod_Code,  
       p.Prod_Desc,  
       rs.Spec_Id,  
       rs.Spec_Desc,  
       ass.Target   
  
FROM @Products p  
LEFT JOIN dbo.Characteristics c WITH(NOLOCK) On (c.Char_Desc Like '%' + P.Prod_Code + '%'  
             OR c.Char_Desc = P.Prod_Desc)  
        and c.Prop_Id = @SpecPropertyId  
LEFT JOIN Active_Specs ass WITH(NOLOCK) On c.char_id = ass.char_id  
LEFT JOIN @RE_Specs rs On ass.Spec_Id = rs.Spec_Id   
WHERE ass.Expiration_Date Is Null   
--------------------------------------------------------------------------------------------------------  
  
--*******************************************************************************************************  
-- Start building LineStatus Table  
--Print convert(varchar(25), getdate(), 120) + ' Build @LineStatus Table'  
--*******************************************************************************************************  
  
Insert Into @LineStatus (PU_ID,Phrase_Value,StartTime,EndTime)  
Select Unit_ID as PU_ID,Phrase_Value,Start_DateTime as StartTime, End_DateTime as EndTime   
 FROM dbo.Local_PG_Line_Status LPG WITH(NOLOCK)  
        Join #PLIDList plid on LPG.Unit_Id = plid.ScheduleUnit -- plid.ConvUnit  
 LEFT JOIN dbo.Phrase PHR WITH(NOLOCK) on LPG.Line_Status_ID = PHR.Phrase_ID  
 WHERE   LPG.Start_DateTime <= @EndDateTime and  
  (LPG.End_DateTime > @StartDateTime or LPG.End_DateTime IS null)  
        and UPDATE_status <> 'DELETED'  
  
--*******************************************************************************************************  
-- Start building Crew Schedule Table  
--Print convert(varchar(25), getdate(), 120) + ' Building @Crew_Schedule Table'  
--*******************************************************************************************************  
Insert Into @Crew_Schedule (StartTime,EndTime,Pu_id,Crew,Shift)  
Select Start_Time as StartTime, End_Time as EndTime,Pu_id,Crew_Desc as Crew, Shift_Desc as Shift  
FROM dbo.Crew_Schedule cs WITH(NOLOCK)  
Join #PLIDList pl on cs.pu_id = pl.ScheduleUnit -- pl.ConvUnit  
WHERE Start_Time <= @EndDateTime   
and (End_Time > @StartDateTime)  
  
  
------------------------------------------------------------------------------------------------------  
-- String Parsing: Shift DESC, If ALL  
--Print convert(varchar(25), getdate(), 120) + 'String Parsing: Shift DESC'  
------------------------------------------------------------------------------------------------------  
  
If  @RPTShiftDESCList = '!null'  
Begin  
 Set @ShiftDESCList = @lblAll  
 --  
 Insert #ShiftDESCList (ShiftDESC)  
  Select Distinct CS.Shift  
  FROM #PLIDList TPL  
  Join @Crew_Schedule CS on tpl.convunit = CS.PU_ID  
  WHERE Crew <> 'No Team'   
End  
Else  
Begin  
 Insert #ShiftDESCList (RCDID,ShiftDESC)  
  Exec SPCMN_ReportCollectionParsing  
  @PRMCollectionString = @RPTShiftDESCList, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',  
  @PRMDataType01 = 'varchar(50)'  
  
 Select @ShiftDESCList = @RPTShiftDESCList  
End  
   
------------------------------------------------------------------------------------------------------  
-- String Parsing: Crew(Team) DESC, If All  Use the word Crew to map to Prof  
--Print convert(varchar(25), getdate(), 120) + 'String Parsing: Crew DESC'  
------------------------------------------------------------------------------------------------------  
If  @RPTCrewDESCList = '!null'  
Begin  
 Set @CrewDESCList = @lblAll  
 --  
 Insert #CrewDESCList (CrewDESC)  
  Select Distinct CS.Crew  
  FROM #PLIDList TPL  
  Join @Crew_Schedule CS on tpl.convunit = CS.PU_ID and Crew Is Not NULL  
  WHERE Crew <> 'No Team'   
  
End  
Else  
Begin  
  
 Insert #CrewDESCList (RCDID,CrewDESC)  
  Exec SPCMN_ReportCollectionParsing  
  @PRMCollectionString = @RPTCrewDESCList, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',  
  @PRMDataType01 = 'varchar(50)'  
  
 Select @CrewDESCList = @RPTCrewDESCList  
End  
  
  
------------------------------------------------------------------------------------------------------  
-- String Parsing: Line Status DESC, If All   
--Print convert(varchar(25), getdate(), 120) + 'String Parsing: Line Status DESC'  
------------------------------------------------------------------------------------------------------  
  
If  @RPTPLStatusDESCList = 'All' or @RPTPLStatusDESCList = '!Null'  
Begin  
 Set @PLStatusDESCList = @lblAll  
 --  
 Insert #PLStatusDESCList (PLStatusDESC)  
  Select distinct Phrase_Value  
  FROM @LineStatus  
End  
Else  
Begin  
 Insert #PLStatusDESCList (RCDID,PLStatusDESC)  
  Exec SPCMN_ReportCollectionParsing  
  @PRMCollectionString = @RPTPLStatusDESCList, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',   
  @PRMDataType01 = 'varchar(50)'  
  
 Select @PLStatusDESCList = @RPTPLStatusDESCList  
End  
  
-----------------------------------------------------------------------------------------------------  
-- Preparing Output Tables for PIVOT:   
-----------------------------------------------------------------------------------------------------  
  
  
  
  
-- Get Data: Production  
--*****************************************************************************************************  
--Print convert(varchar(25), getdate(), 120) + ' Get Production Data'  
  
-- Insert Into @Events (Timestamp,Pu_id,PLID)  
  
  
Insert #Production  
 (EndTIME, PLID, pu_id, TypeOfEvent)  
Select TimeStamp,TPL.PLID ,pu_id, 'Complete'  
FROM dbo.Events E WITH(NOLOCK)  
Join #PLIDList TPL on TPL.ConvUnit = E.PU_ID  
 and TimeStamp >= @StartDATETIME  
  and TimeStamp <= @EndDATETIME  
  
  
  
Insert #Production (pu_id, PLID, StartTIME, EndTime, TypeOfEvent)  
Select p.pu_id,tpl.PLID,@EndDateTime,@EndDateTime,'Partial' FROM #Production p  
Join #PLIDList TPL on TPL.ConvUnit = p.PU_ID  
Join (Select PU_Id,Max(EndTime) as EndTime FROM #Production group by pu_id)   
 as met on met.pu_id = p.pu_id and met.EndTime = p.EndTime  
WHERE met.EndTime != @EndDateTime  
  
-- 'NoEvent' Scenario  
Insert #Production (pu_id, PLID, StartTIME, EndTime, TypeOfEvent)  
Select TPL.ConvUnit,TPL.PLID,@StartDateTime,@EndDateTime,'Partial' FROM #PLIDList TPL  
LEFT JOIN #Production P on TPL.ConvUnit = P.pu_id  
WHERE P.ID Is Null  
  
  
--Print convert(varchar(25), getdate(), 120) + ' Get Production Start Data '  
  
Declare ProductionStart INSENSITIVE Cursor For  
 (Select ID, EndTIME, pu_id  
    FROM #Production)  
    For Read Only  
  
Open ProductionStart  
  
FETCH NEXT FROM ProductionStart into @Id, @EndTime, @PU_Id  
  
While @@Fetch_Status = 0  
Begin  
 Set @StartTime = null  
 Select @StartTime = Max(EndTime)  
  FROM #Production P WITH(NOLOCK)   
  WHERE P.pu_id = @PU_Id  
   and P.EndTime < @EndTime  
   
  UPDATE #Production  
   Set StartTIME = @StartTime  
  WHERE ID = @Id  
 --  
 Fetch Next FROM ProductionStart into @Id, @EndTime, @PU_Id  
End  
Close ProductionStart  
Deallocate ProductionStart  
  
Delete FROM #Production WHERE NOT (EndTime >= @StartDATETIME  
  and EndTime <= @EndDATETIME)  
  
UPDATE #Production   
  Set StartTime = @StartDATETIME,  
   TypeOfEvent = 'Partial'  
WHERE StartTIme Is NULL  
  
  
--Print convert(varchar(25), getdate(), 120) + ' End Get Production Start Data '  
----------------------------------------------------------------------------------------------------  
-- Compute FLEX VARIABLES  
----------------------------------------------------------------------------------------------------  
  
set @k = 1  
  
while @k < 11  
begin  
 select @param=value FROM #Params WHERE param='DPR_Flexible_variable_' + convert(varchar,@k)  
 if @param<>''  
 begin   
  
 set @SQLString = ' UPDATE #Production Set flex' + convert(varchar,@k) + '= ' +  
      '(select Sum(Convert(float, T.RESULT)) FROM #PLIDList TPL ' +  
                         ' Join Variables v on v.var_id = ' + 'TPL.Flex'+ convert(varchar,@k) + ' and v.pu_id = TPT.PU_id ' +  
    ' LEFT JOIN dbo.TESTS T WITH (INDEX(Test_By_Variable_And_Result_On),NOLOCK) on  T.VAR_ID = ' + 'TPL.Flex'+ convert(varchar,@k) +  
    ' and T.Result_on > TPT.StartTime and T.RESULT_on <= TPT.EndTIME and T.Canceled <> 1) ' +  
     ' FROM #Production tpt ' +  
    ' Join #PLIDList tpl on tpt.pu_id = tpl.ConvUnit '   
  
 exec(@SQLString)  
 end  
 set @k = @k + 1  
end  
  
----------------------------------------------------------------------------------------------------  
UPDATE #Production  
  
 Set  Crew = CS.Crew,   
   Shift = CS.Shift  
   
 FROM #Production TPT  
  
 Join #PLIDList TPL On tpt.Pu_ID = TPL.ConvUnit  
  
 Join @Crew_Schedule cs On tpl.ScheduleUnit = cs.PU_ID  
  and tpt.EndTime > cs.StartTime   
  and (tpt.EndTime <= cs.EndTime or cs.EndTime IS null)  
  
  
UPDATE #Production  
  
 Set Product = PS.Prod_Code   ,   
        Product_Size = PS.Product_Size ,  
  IdealSpeed = spec2.Target  ,  
  -- Crew = CS.Crew,   
  -- Shift = CS.Shift,   
  LineStatus = LPG.Phrase_Value ,   
  ProdPerStat = spec.Target   
   
 FROM #Production TPT  
  
 Join #PLIDList TPL On tpt.Pu_ID = TPL.ConvUnit  
  
 Join @Products PS On ps.pu_id = tpt.pu_id   
  and tpt.EndTime >= ps.StartTime   
  and (tpt.EndTime < ps.EndTime or ps.EndTime IS Null)  
  
 Join @LineStatus LPG On TPL.scheduleUnit = LPG.PU_ID  
  and TPT.EndTime > LPG.StartTime   
  and (TPT.EndTime <= LPG.EndTime or LPG.EndTime IS null)   
  
 LEFT JOIN @Product_Specs spec On PS.prod_code = spec.prod_code and spec.spec_id = @PadsPerStatSpecId  
   
 LEFT JOIN @Product_Specs spec2 On PS.prod_code = spec2.prod_code and spec2.spec_id = @IdealSpeedSpecID  
  
   
UPDATE #Production  
 Set     TotalPad =  cast(Convert(float, TPad.RESULT)as bigint),  
   RunningScrap = Convert(float, TRun.RESULT),  
   Stopscrap = Convert(float, TSTOP.RESULT),  
   LineSpeedTAR = Convert(float, TSpeed.RESULT),  
         TotalCases =  cast(Convert(float, TCases.RESULT)as bigint),  
         CaseCount = cast(Convert(float, TCases.RESULT)as bigint)  
    
 FROM #Production TPT  
  
 Join #PLIDList TPL on tpt.Pu_ID = TPL.ConvUnit  
   
 LEFT JOIN dbo.TESTS TRun WITH(NOLOCK)   
                            on TPL.CompRunCountVarID = TRun.VAR_ID  
  and TRun.RESULT_on = TPT.EndTIME and TRun.Canceled <> 1  
  
  LEFT JOIN dbo.TESTS TSTOP WITH(NOLOCK)  
                            on TPL.CompStartUPCountVarID = TSTOP.VAR_ID  
  and TSTOP.RESULT_on = TPT.EndTIME and TStop.Canceled <> 1  
  
  LEFT JOIN dbo.TESTS TSpeed WITH(NOLOCK)   
                            on TPL.CompSpeedTargetVarID = TSpeed.VAR_ID  
  and TSpeed.RESULT_on = TPT.EndTIME and TSpeed.Canceled <> 1  
  
        LEFT JOIN dbo.TESTS TPad WITH(NOLOCK)  
                            on tpl.comppadcountvarid = TPad.VAR_ID  
  and TPad.RESULT_on = tpt.EndTIME and TPad.Canceled <> 1  
  
        LEFT JOIN dbo.TESTS TCases WITH (NOLOCK) on tpl.CompCaseCountVarID = TCases.VAR_ID  
  and TCases.RESULT_on = tpt.EndTIME and TCases.Canceled <> 1  
  
WHERE TypeOfEvent = 'Complete'  
  
---------------------------------------------------------------------------------------------  
-- FRio, replaced code for make complete events FROM partial events  
---------------------------------------------------------------------------------------------  
  
Insert Into @Make_Complete (pu_id,start_time)  
Select pu_id,MIN(StartTime) FROM #Production  
Group by pu_id  
  
UPDATE @Make_Complete  
        Set end_time = (Select MIN(EndTime) FROM #Production WHERE pu_id = mc.pu_id)  
FROM @Make_Complete mc  
  
UPDATE @Make_Complete  
        Set next_start_time = (Select MIN(EndTime) FROM #Production   
                               WHERE PU_ID = mc.pu_id and EndTime > mc.Start_Time)  
FROM @Make_Complete mc  
  
UPDATE #Production  
        Set TypeofEvent = 'Complete'  
FROM #Production p  
Join @Make_Complete mc on p.pu_id = mc.pu_id and p.StartTime = mc.start_time  
WHERE mc.start_time = mc.next_start_time and mc.next_start_time Is Not NULL  
  
-- Select * FROM @Make_Complete  
---------------------------------------------------------------------------------------------  
-- Avoid cursor below, get rid of Complete events, use only partials  
Select ID, pu_id, TPL.PLID,StartTIME, EndTIME, PartPadCountVarID,PartCaseCountVarID,  
  PartRunCountVarID,PartStartUPCountVarID,PartSpeedTargetVarID  
into #tcur_PartProd  
FROM #Production  P   
Join #PLIDList TPL on TPL.ConvUnit = P.PU_id   
WHERE TypeOfEvent = 'Partial'  
  
--Select * FROM #tcur_PartProd  
  
-- PartPadCountVarID  
Truncate Table #Temporary  
Insert into #Temporary (TEMPValue1,TEMPValue2)  
Select  ID,Sum(Convert(float, RESULT))  
   FROM dbo.TESTS T WITH(NOLOCK) -- WITH (INDEX(Test_By_Variable_And_Result_On),NOLOCK)  
   Join #tcur_PartProd PP on PP.PartPadCountVarID = T.Var_id  
   and T.RESULT_on > PP.StartTIME  
   and T.RESULT_on <= PP.EndTIME  
   WHERE Canceled <> 1  
Group by ID  
  
UPDATE #Production  
 Set TotalPad = t.TEMPValue2  
FROM #Production P Join #Temporary t on p.id = t.TEMPValue1  
  
-- PartCaseCountVarID  
Truncate Table #Temporary  
Insert into #Temporary (TEMPValue1,TEMPValue2)  
Select  ID,Sum(Convert(float, RESULT))  
   FROM dbo.Tests T WITH(NOLOCK) -- WITH (INDEX(Test_By_Variable_And_Result_On),NOLOCK)  
   Join #tcur_PartProd PP on PP.PartCaseCountVarID = T.Var_id  
   and T.RESULT_on > PP.StartTIME  
   and T.RESULT_on <= PP.EndTIME  
   WHERE Canceled <> 1  
Group By ID  
  
UPDATE #Production  
 Set TotalCases = t.TEMPValue2,  
 CaseCount = t.TEMPValue2  
FROM #Production P Join #Temporary t on p.id = t.TEMPValue1  
  
-- PartRunCountVarID  
TRUNCATE table #Temporary  
Insert into #Temporary (TEMPValue1,TEMPValue2)  
Select  ID,Sum(Convert(float, RESULT))  
   FROM dbo.Tests T WITH(NOLOCK) --WITH (INDEX(Test_By_Variable_And_Result_On),NOLOCK)  
   Join #tcur_PartProd PP on PP.PartRunCountVarID = T.Var_id  
   and T.RESULT_on > PP.StartTIME  
   and T.RESULT_on <= PP.EndTIME  
   WHERE Canceled <> 1  
group by ID  
  
UPDATE #Production  
 Set RunningScrap = t.TEMPValue2  
FROM #Production P Join #Temporary t on p.id = t.TEMPValue1  
  
-- PartStartUpCountVarID  
TRUNCATE table #Temporary  
Insert into #Temporary (TEMPValue1,TEMPValue2)  
Select  ID,Sum(Convert(float, RESULT))  
   FROM dbo.Tests T WITH(NOLOCK) -- WITH (INDEX(Test_By_Variable_And_Result_On),NOLOCK)  
   Join #tcur_PartProd PP on PP.PartStartUpCountVarID = T.Var_id  
   and T.RESULT_on > PP.StartTIME  
   and T.RESULT_on <= PP.EndTIME  
   WHERE Canceled <> 1  
Group By Id  
  
UPDATE #Production  
 Set StopScrap = t.TEMPValue2  
FROM #Production P Join #Temporary t on p.id = t.TEMPValue1  
  
-- PartSpeedTargetVarID  
TRUNCATE table #Temporary  
Insert into #Temporary (TEMPValue1,TEMPValue2)  
Select  ID,Avg(convert(float, RESULT))  
   FROM dbo.Tests T WITH(NOLOCK) --WITH (INDEX(Test_By_Variable_And_Result_On),NOLOCK)  
   Join #tcur_PartProd PP on PP.PartSpeedTargetVarID = T.Var_id  
   and T.RESULT_on > PP.StartTIME  
   and T.RESULT_on <= PP.EndTIME  
   WHERE Canceled <> 1  
Group By Id  
  
UPDATE #Production  
 Set LineSpeedTAR = t.TEMPValue2  
FROM #Production P Join #Temporary t on p.id = t.TEMPValue1  
  
---------------------------------------------------------------------------------------------  
-- Calculate the LineSpeedTarget for that intervals with NULL Line Speed  
TRUNCATE table #Temporary  
  
Insert into #Temporary (TEMPValue1,TEMPValue2)  
Select PU_ID,AVG(LineSpeedTAR)  
FROM #Production tpt   
WHERE LineSpeedTAR IS NOT NULL  
Group By PU_ID  
  
  
UPDATE #Production  
 Set LineSpeedTAR = T.TEMPValue2  
FROM #Production P Join #Temporary T on P.PU_ID = T.TEMPValue1  
WHERE P.LineSpeedTAR Is NULL  
  
DROP TABLE #TCur_PartProd  
---------------------------------------------------------------------------------------------  
-- UPDATE Class column on product table.  
UPDATE #Production Set Class = (Select Class FROM @Class WHERE Pu_id = #Production.Pu_id)  
  
-- UPDATE statement for Production Day  
UPDATE #Production  
 Set ProdDay = Convert(nvarchar(12),cs.StartTime)  
FROM #Production p  
Join #PLIDLIst PL on p.pu_id = pl.ConvUnit  
Join @Crew_Schedule cs on pl.ScheduleUnit = cs.pu_id  
and p.StartTime >= cs.StartTime and p.StartTime < cs.EndTime  
  
UPDATE #Production  
 Set SchedTime = DateDiff(ss,StartTime,EndTime),  
  ConvFactor = 1  
  
-- Select SchedTime,DateDiff(ss,StartTime,EndTime),* FROM #Production order by pu_id, starttime  
  
  
-----------------------------------------------------------------------------------------------------  
-- Get Data: Reject Data  
--Print convert(varchar(25), getdate(), 120) + ' Get Reject Data'  
-----------------------------------------------------------------------------------------------------  
  
If @RPT_ShowTop5Rejects = 'TRUE' and @RPTMinorGroupBy <> 'ProdDay'  
Begin  
  
Insert Into #Rejects (NRecords,PadCount, Reason1,Reason2,   
        Product, Product_Size,Crew, Shift, LineStatus, PLID, pu_id,Location)  
Select  
     count(wed.TimeStamp)       ,   
  sum(wed.amount)         ,   
        wedf.wefault_name        ,  
     Null           ,    
        P.Product   As   'Product'  ,  
     P.Product_Size   As   'Product Size' ,  
  P.Crew     As   'Crew'   ,  
  P.Shift     As   'Shift'   ,  
  P.LineStatus  As   'LineStatus' ,  
        PL.PLID           ,   
        WED.PU_ID          ,  
        pu.pu_desc            
From  
  dbo.Waste_Event_Details as wed WITH(NOLOCK) -- WITH (INDEX(WEvent_Details_IDX_PUIdTime),NOLOCK)  
  Join dbo.Waste_Event_Fault wedf  WITH(NOLOCK) on wed.reason_level1 = wedf.reason_level1   
                and wed.pu_id = wedf.pu_id  
     Join #PLIDList PL on PL.ConvUnit = wed.Pu_id  
     Join Prod_Units pu on pu.pu_id = wed.source_pu_id  
  Join #Production P On P.PU_Id = wed.Pu_Id And wed.TimeStamp >= P.StartTime and wed.TimeStamp < P.EndTime  
  
 WHERE  
 (wed.TimeStamp >= @StartDateTime and wed.TimeStamp < @EndDateTime)  
        
Group By  
 wedf.wefault_name,P.Product,P.Product_Size, P.Crew, P.Shift,   
 P.LineStatus,PL.PLID, WED.PU_ID,pu.pu_desc,pl.ScheduleUnit  
  
  
End  
  
--Print convert(varchar(25), getdate(), 120) + ' End Get Reject Data'  
  
--Print convert(varchar(25), getdate(), 120) + ' Get Splice Data'  
-----------------------------------------------------------------------------------------------------  
-- Get Data: Splice Data  
-----------------------------------------------------------------------------------------------------  
--   
If Exists(Select count(*) FROM @ColumnVisibility WHERE VariableName like '%Splice%' Or VariableName like '%SuccessRate%') -- and @RPTMinorGroupBy <> 'ProdDay'  
Begin  
Insert into #Splices (nrecords, SpliceStatus, Product,Product_Size,  
                 Crew, Shift, LineStatus, PLID, pu_id, class,ProdDay)  
Select  
 count(*)         ,  
 sum(wed.amount)  As   'SpliceStatus' ,  
  P.Product   As   'Product'  ,  
     P.Product_Size   As   'Product Size' ,  
  P.Crew     As   'Crew'   ,  
  P.Shift     As   'Shift'   ,  
  P.LineStatus  As   'LineStatus' ,  
 PL.PLID    As   'PLID'   ,  
 WED.PU_ID    As   'pu_id'   ,  
 PL.Class            ,  
    Convert(nvarchar(12),Timestamp)  
  
 From  
  
 dbo.Waste_Event_Details wed WITH(NOLOCK) --WITH (INDEX(WEvent_Details_IDX_PUIdTime),NOLOCK)  
  
 Join dbo.Prod_Units pu WITH(NOLOCK) on (pu.pu_id = wed.source_PU_Id)   
  
 Inner join #PLIDList pl on wed.pu_id = pl.SpliceUnit   
      
 Join #Production P On P.PU_Id = pl.ScheduleUnit And wed.TimeStamp >= P.StartTime and wed.TimeStamp < P.EndTime  
  
 WHERE  
  
  (wed.TimeStamp >= @StartDateTime and wed.TimeStamp < @EndDateTime)  
        -- and wed.pu_id in (Select SpliceUnit FROM #PLIDList)          
   
    Group By  
 wed.Timestamp,pl.Class,P.Product,P.Product_Size, P.Crew, P.Shift,   
 P.LineStatus,PL.PLID, WED.PU_ID,pu.pu_desc,pl.ScheduleUnit  
  
  
 If @RptMajorGroupBy = 'Unit'  
 Begin  
   UPDATE #Splices  
    Set PU_ID = TPLID.ConvUnit  
   FROM #Splices s  
   Join #PLIDList TPLID on s.pu_id = TPLID.SpliceUnit  
 End  
  
End  
  
--**************************************************************************************************  
-- Get Data: Downtime Data  
--Print convert(varchar(25), getdate(), 120) + ' Get Downtime Data'  
--**************************************************************************************************  
Insert #Downtimes  
 (TedID,PU_ID, PLID, Start_Time,End_Time, Fault, Location,Location_id,  
 Reason1, Reason1_Code,Reason2,Reason2_Code, Reason3, Reason3_Code,Reason4,Reason4_Code,  
  IsStops, UserID, Action_Level1)  
Select   
 ted.TEDet_Id, ted.PU_Id, tpl.PLID,     
  Case   
   When ted.Start_Time < @StartDateTime THEN @StartDateTime  
   Else ted.Start_Time  
  End,  
  Case  
   --When ted.End_Time Is null THEN @Now  
   When ted.End_Time Is null THEN @EndDateTime -- JJR 4/24/03  
   When ted.End_Time > @EndDateTime THEN @EndDateTime  
   Else ted.End_Time  
  End,  
  tef.teFault_Name,   
  --  '',  
  pu.pu_DESC,   
  pu.pu_id,  
  er1.Event_Reason_Name,   
  er1.Event_Reason_id,  
  er2.Event_Reason_Name,   
  er2.Event_Reason_id,  
  er3.Event_Reason_Name,  
  er3.Event_Reason_id,  
  er4.Event_Reason_Name,  
  er4.Event_Reason_id,            -- If the stop belongs to a previous period, then count it as IsStops = 0  
  Case   
   When ted.Start_Time < @StartDateTime THEN 0  
   Else 1  
  End,  
  ted.User_ID,  
  ted.Action_Level1  
  From  dbo.Timed_Event_Details ted WITH(NOLOCK)      -- WITH (INDEX(TEvent_Details_IDX_PUIdSTime),NOLOCK)   
  Join  #PLIDList tpl WITH (NOLOCK)  on ted.PU_Id = tpl.convUnit -- or ted.pu_Id = tpl.Packerunit    
  LEFT JOIN dbo.timed_Event_Fault tef WITH(NOLOCK) on ted.teFault_id = tef.teFault_id   
  LEFT JOIN dbo.Prod_Units PU WITH(NOLOCK) on ted.source_pu_id = pu.pu_id  
  LEFT JOIN dbo.Event_Reasons er1 WITH(NOLOCK) on ted.Reason_level1 = er1.Event_Reason_id   
  LEFT JOIN dbo.Event_Reasons er2 WITH(NOLOCK) on ted.Reason_level2 = er2.Event_Reason_id   
  LEFT JOIN dbo.Event_Reasons er3 WITH(NOLOCK) on ted.Reason_level3 = er3.Event_Reason_id   
  LEFT JOIN dbo.Event_Reasons er4 WITH(NOLOCK) on ted.Reason_level4 = er4.Event_Reason_id   
  WHERE ted.Start_Time < @EndDateTime  
   and (ted.End_Time > @StartDateTime or ted.End_Time IS null)   
  
-----------------------------------------------------------------------------------------------------  
-- If the sp is run with endtime = GetDate () and the line is down at  
-- that point in time, set the endtime of the last record (which would otherwise be NULL)  
-- equal to the endtime passed to the sp by the end user  
-----------------------------------------------------------------------------------------------------  
  
IF (Select Top 1 TedID FROM #Downtimes WHERE End_Time IS NULL) IS NOT NULL  
 BEGIN  
 UPDATE #Downtimes  
 SET End_Time = @RPTEndDate  
 WHERE End_Time IS NULL  
 END  
  
UPDATE #Downtimes Set Class = (select cc.class FROM @Class cc WHERE cc.pu_id = #downtimes.pu_id)  
  
-----------------------------------------------------------------------------------------------------  
--*************************************************************************************************  
-- NEW fix for BELL  
--*************************************************************************************************  
-- Saco los LineStatus changes  
  
--**********************************************************************************************************  
--Print convert(varchar(25), getdate(), 120) + ' Production Events Split Cursor'  
  
  
  
Declare LineStatusSplit INSENSITIVE Cursor For (   
  Select PLID,PU_ID,EndTime FROM #Production) Order By PU_Id,EndTime  
  
  For Read Only  
 --  
 Open LineStatusSplit   
 --  
 Fetch Next FROM LineStatusSplit into @PLID, @PU_Id, @EndTime  
 --  
 While @@Fetch_Status = 0  
 --  
 Begin   
  
  Insert #Downtimes  
   (TedID,PU_ID, PLID, Start_Time,End_Time, Fault, Location,  
   Reason1, Reason2, Reason3, Reason4, IsStops, Dev_Comment, UserID, Action_Level1,Class)  
   Select TedID, PU_ID, PLID, @EndTime, End_Time, Fault, Location,  
   Reason1, Reason2, Reason3, Reason4, 0, 'DowntimeSplit',  
   UserID, Action_Level1,Class  
   FROM #Downtimes tdt WITH (NOLOCK)   
   WHERE tdt.PU_ID = @PU_Id  
    and tdt.Start_Time < @EndTime  
    and (tdt.End_Time > @EndTime or End_Time is NULL)  
  
  --  
  BEGIN  
            IF Not Exists (Select * FROM #Downtimes  
      WHERE ISNULL(Dev_Comment, 'Blank') = 'DowntimeSplit'  
      AND PU_ID = @PU_Id And (End_Time = @EndTime Or Start_Time = @EndTime))  
      BEGIN  
              Insert #Downtimes   
              (TedID, PU_ID, PLID, Start_Time, End_Time, IsStops, Dev_Comment,Class)  
              Select 9999, @PU_Id, @PLID, @EndTime, @EndTime, 0, 'DowntimeSplit',  
                    Class FROM @Class WHERE pu_id = @PU_Id  
            END  
  END     
  --  
  UPDATE #Downtimes  
   Set End_Time = @EndTime  
   WHERE PU_ID = @PU_Id  
    and Start_Time < @EndTime  
    and (End_Time > @EndTime or End_Time is NULL)  
  --  
  FETCH NEXT FROM LineStatusSplit into @PLID, @PU_Id, @EndTime  
 End   
   
 Close LineStatusSplit   
 Deallocate LineStatusSplit   
  
  
--*************************************************************************************************  
--Print convert(varchar(25), getdate(), 120) + 'No Event Cursors'  
  
Declare DowntimeNoEvent INSENSITIVE Cursor For (   
  Select distinct tpl.PLID, cs.PU_ID, cs.EndTime  
  FROM #PLIDList tpl  
  Join (Select PU_ID,Crew,Shift,StartTime,EndTime FROM @Crew_Schedule) as cs   
   on tpl.ScheduleUnit = cs.pu_id  
  WHERE cs.StartTime <= @EndDateTime and   
  (cs.EndTime > @StartDateTime or cs.EndTime Is null))  
  
  For Read Only  
 --  
 Open DowntimeNoEvent  
 --  
 Fetch Next FROM DowntimeNoEvent into @PLID, @PU_Id, @EndTime  
 --  
 While @@Fetch_Status = 0  
 --  
 Begin  
  Select @StartTime = MIN(Start_Time)   
         FROM #Downtimes  
         WHERE Start_Time > @EndTime  
         And PU_ID = @PU_Id   
  --  
  IF Not Exists (Select * FROM #Downtimes  
      WHERE ISNULL(Dev_Comment, 'Blank') = 'DowntimeSplit'  
      AND PU_ID = @PU_Id And (End_Time = @EndTime Or Start_Time = @EndTime))  
  --  
  BEGIN  
  --  
  Insert #Downtimes  
   (TedID,PU_ID, PLID, Start_Time,End_Time, Fault, Location,  
   Reason1, Reason2, Reason3, Reason4, IsStops, Dev_Comment, UserID, Action_Level1)  
  Select TedID, PU_ID, PLID, @EndTime, @EndTime, Fault, Location,  
   Reason1, Reason2, Reason3, Reason4, 0, 'DowntimeNoEvent',   
   UserID, Action_Level1  
   FROM #Downtimes tdt  
   WHERE tdt.PU_ID = @PU_Id  
   and tdt.Start_Time = @StartTime  
   and (tdt.End_Time > @EndTime or End_Time is NULL)  
  
   --  
  END -- Insertion Loop   
   
 FETCH NEXT FROM DowntimeNoEvent into @PLID, @PU_Id, @EndTime  
 End -- DowntimeNoEvent Loop  
 --  
 Close DowntimeNoEvent  
 Deallocate DowntimeNoEvent  
-- End  
  
--*************************************************************************************************  
--Print convert(varchar(25), getdate(), 120) + 'Downtime End Cursors'  
  
Declare DowntimeEnd INSENSITIVE Cursor For  
 (Select ConvUnit, PLID.PLID, c.Class  
  FROM #PLIDList PLID  
                Join @Class c On PLID.ConvUnit = c.pu_id)  
 For Read Only  
  
Open DowntimeEnd  
  
FETCH NEXT FROM DowntimeEnd into @PU_Id, @PLID,@ClassNum  
  
While @@Fetch_Status = 0  
Begin  
 Set @EndTime = null  
 Select @EndTime = Max(End_Time)  
  FROM #Downtimes  
  WHERE PU_ID = @PU_Id  
 --  
 If @EndTime < @EndDateTime  
 Insert #Downtimes -- 4/16/03 Added dummy TedID '9999' JJR  
  (TedID, PU_ID, PLID, Start_Time, End_Time, IsStops, Dev_Comment,Class)  
  Values (9999, @PU_Id, @PLID, @EndDateTime, @EndDateTime, 0, 'DowntimeEnd',@ClassNum)  
 --  
 Set @StartTime = null  
  Select @StartTime = Min(Start_Time)  
  FROM #Downtimes  
  WHERE PU_ID = @PU_Id  
 --  
 If @StartTime > @StartDateTime  
 Insert #Downtimes -- 4/16/03 Added dummy TedID '9999' JJR  
  (TedID, PU_ID, PLID, Start_Time, End_Time, IsStops, Dev_Comment,Class)  
  Values (9999, @PU_Id, @PLID, @StartDateTime, @StartDateTime, 0, 'DowntimeEnd',@ClassNum)  
 --  
 Fetch Next FROM DowntimeEnd into @PU_Id, @PLID,@ClassNum  
End  
Close DowntimeEnd  
Deallocate DowntimeEnd  
  
--------------------------------------------------------------------------------------------------  
--10/01/03 JJR  NoStops Cursor added to prevent sp FROM returning an empty record set  
--              when run for a period in which no stops take place.  
--------------------------------------------------------------------------------------------------  
--Print convert(varchar(25), getdate(), 120) + ' NoStops Cursor'   
  
Declare NoStops INSENSITIVE Cursor For  
 (Select ConvUnit, PLID  
  FROM #PLIDList)  
 For Read Only  
--  
Open NoStops  
--  
FETCH NEXT FROM NoStops into @PU_Id, @PLID  
--  
While @@Fetch_Status = 0  
Begin  
 If (Select MAX(PU_ID) FROM #Downtimes WHERE PU_ID = @PU_Id) IS NULL  
 BEGIN  
  
 Insert #Downtimes -- 4/16/03 Added dummy TedID '9999' JJR  
 (TedID, PU_ID, PLID, Start_Time, End_Time, IsStops, Dev_Comment)   
 Values (9999, @PU_Id, @PLID, @StartDateTime, @EndDateTime, 0, 'NoStops') -- JJR 10/01/03  
 --  
 UPDATE #Downtimes  
 Set Uptime = Datediff(ss, Start_Time, End_Time) / 60.0 --,  
  --SurvRateUptime = Datediff(ss, Start_Time, End_Time) / 60.0   
 WHERE PU_ID = @PU_Id  
 --  
  
 END  
--  
FETCH NEXT FROM NoStops into @PU_Id, @PLID  
End -- NoStops Cursor Loop  
Close NoStops  
Deallocate NoStops  
  
  
  
  
---------------------------------------------------------------------------------------  
--Print convert(varchar(25), getdate(), 120) + ' Updating Duration'   
UPDATE TDT  
 Set Duration = Str(DatedIff(ss, tdt.Start_Time, tdt.End_Time) / 60.0,12,1),   
  Product = P.Product,   
        Product_Size = P.Product_Size,  
  Crew = P.Crew,   
  Shift = P.Shift,   
  LineStatus = P.LineStatus  
  
 FROM #Downtimes tdt  
 Join #Production P On (tdt.PU_Id = P.PU_ID and   
     tdt.Start_Time >= p.StartTime   
     and tdt.Start_Time < p.EndTime )  
  
-----------------------------------------------------------------------------------------------  
-- 8/23/02 JJR: New code to UPDATE the shift entry for 'non-event' records  
-- Print convert(varchar(25), getdate(), 120) + ' Updating No-Event records'   
-----------------------------------------------------------------------------------------------  
  
  
UPDATE TDT  
 Set   
  Shift     =     P.Shift,  
  Crew         =     P.Crew,  
  LineStatus   =     P.LineStatus  
  
 FROM #Downtimes tdt  
 Join #Production P   On (tdt.Pu_Id = P.PU_ID and   
     tdt.Start_Time > p.StartTime   
     and tdt.Start_Time <= p.EndTime )  
  
 WHERE tdt.Duration = 0  
  
  
-- End 8/23/02 UPDATE shift for non-event records  
-----------------------------------------------------------------------------------------------  
--Print convert(varchar(25), getdate(), 120) + ' Calculating the Uptime column'  
  
  
  
-- Insert Into @Temp_Uptime (id,pu_id,Start_Time,End_Time)  
  
Select d1.id,d1.pu_id,MAX(d2.End_Time) as Start_Time,d1.Start_Time as End_Time  
Into #Temp_Uptime  
FROM #Downtimes d1  
Join #Downtimes d2 on (d1.pu_id = d2.pu_id) and (d2.End_Time <= d1.Start_Time) and (d1.id <> d2.id)  
Group By d1.id,d1.Start_Time,d1.pu_id  
  
UPDATE #Downtimes   
        Set Uptime = Str(IsNull(DatedIff(ss,t1.Start_Time,t1.End_Time) / 60.0,0),12,1)   
FROM #Downtimes d  
Join #Temp_Uptime t1 on d.id = t1.id   
  
-----------------------------------------------------------------------------------------------   
UPDATE #Downtimes  
 Set Duration = 0 WHERE ISNULL(Dev_Comment, 'Blank') = 'NoStops'  
-----------------------------------------------------------------------------------------------   
  
-----------------------------------------------------------------------------------------------  
--Print convert(varchar(25), getdate(), 120) + ' Start getting the #History table'  
-----------------------------------------------------------------------------------------------  
  
INSERT INTO #Timed_Event_Detail_History   
Select  Tedet_ID, User_ID  
FROM dbo.Timed_Event_Detail_History  ted WITH(NOLOCK)  
Join #Downtimes tdt on ted.TEDET_ID = tdt.TedID AND Modified_On > @RptStartDate  
  
-----------------------------------------------------------------------------------------------   
-- Delete FROM #Downtimes WHERE TedID IS NULL  
-----------------------------------------------------------------------------------------------   
-- select @fltDBVersion   
  
  
IF @fltDBVersion <= 300172.90   
BEGIN  
  UPDATE #Downtimes  
    Set IsStops = 0  
  FROM dbo.#Downtimes tdt  
  Join #Timed_Event_Detail_History ted on tdt.TEDID = ted.TEDET_ID   
  and ted.User_ID = '2'   
  WHERE ted.TEDET_ID IS NOT Null  
     And tdt.IsStops IS Null  
  
  UPDATE #Downtimes  
    Set IsStops = 0  
  FROM #Downtimes tdt  
  WHERE (tdt.Action_Level1 Is Null or tdt.Action_Level1 = 0)  
    
END  
ELSE   
BEGIN      
  
  UPDATE #Downtimes  
    Set IsStops = ISNULL((Select Case WHEN Min(User_Id) < 50  
          THEN 1  
          WHEN Min(User_Id) = @DowntimeSystemUserID  
          THEN 1  
          ELSE 0  
        END  
        FROM #Timed_Event_Detail_History   
        WHERE Tedet_Id = ted.TEDET_ID   
        ),0)  
  FROM #Downtimes tdt  
  LEFT JOIN #Timed_Event_Detail_History ted on tdt.TEDID = ted.TEDET_ID  
  WHERE Dev_Comment Is NULL    
  
  UPDATE #Downtimes  
    Set IsStops = 1  
  FROM #Downtimes tdt  
  Join #Timed_Event_Detail_History tedh on tdt.TEDID = tedh.TEDET_ID  
  WHERE tedh.User_ID = @DowntimeSystemUserID  
     And tdt.Duration <> 0  
     And Dev_Comment Not Like '%DowntimeSplit'  
  
END  
----------------------------------------------------------------------------------------------   
  
----------------------------------------------------------------------------------------------   
-- UPDATE Below addresses instances of the line being down at the start of a report  
UPDATE #Downtimes  
 Set IsStops = 0  
FROM #Downtimes tdt  
WHERE tdt.Start_Time = @StartDateTime And tdt.Uptime = 0  
  
  
----------------------------------------------------------------------------------------------   
-- Get the Tree_Name for the FMECA  
----------------------------------------------------------------------------------------------   
  
UPDATE #Downtimes  
 SET Tree_Name = ert.Tree_Name  
FROM #Downtimes d  
JOIN dbo.Event_Reasons    er  ON  er.Event_Reason_Id = d.Reason1_Code  
JOIN dbo.Event_Reason_Tree_Data ertd ON er.Event_Reason_Id = ertd.Event_Reason_Id  
JOIN dbo.Event_Reason_Tree  ert  ON ert.Tree_Name_Id = ertd.Tree_Name_Id  
  
----------------------------------------------------------------------------------------------   
-- UPDATE Survival Rate FROM Test table  
--Print convert(varchar(25), getdate(), 120) + 'UPDATE SurvRate variable'  
----------------------------------------------------------------------------------------------   
  
/*  
SELECT COUNT(*)   
    FROM #PLIDList TPL   
    JOIN dbo.Tests T WITH(NOLOCK) ON @RptStartDate >= T.Result_on  
          AND @RptEndDate <= T.Result_on AND T.Canceled <> 1  
          AND T.Var_ID = TPL.REDowntimeVarID  
  
*/   
  
If @RPT_SurvivalRate = 'TRUE' Or @RPT_SurvivalRatePer = 'TRUE'  
Begin  
UPDATE TDT  
 Set SurvRateUptime = T.Result  
 FROM #Downtimes TDT  
 JOIN #PLIDList TPL ON TPL.PLId = TDT.PLID  
    JOIN dbo.Tests T WITH(NOLOCK) ON DateAdd(second, 5, TDT.End_Time) >= T.Result_on  
          AND DateAdd(second, -5, TDT.End_Time) <= T.Result_on AND T.Canceled <> 1  
          AND T.Var_ID = TPL.REDowntimeVarID  
WHERE Convert(float,T.REsult) >= @RPTDowntimesurvivalRate  
End  
  
  
--Print convert(varchar(25), getdate(), 120) + 'End UPDATE SurvRate variable'  
  
-- UPDATE for Production Day Grouping  
UPDATE #Downtimes  
 Set ProdDay = Convert(nvarchar(12),cs.StartTime)  
FROM #Downtimes dt  
Join #PLIDLIst PL on dt.pu_id = pl.ConvUnit  
Join @Crew_Schedule cs on pl.ScheduleUnit = cs.pu_id  
and dt.Start_Time >= cs.StartTime and dt.Start_Time < cs.EndTime  
  
--**************************************************************************************************************  
-- EVENT REASON CATEGORIES  
--Print convert(varchar(25), getdate(), 120) + ' Get Event Reason categories'  
--**************************************************************************************************************  
-- UPDATE the Event Reason Categories select * FROM prod_units  
  
----------------------------------------------------------------------------------------------------------------------  
-- Get List of parameters to exclude FROM downtimes  
----------------------------------------------------------------------------------------------------------------------  
  
If @Local_PG_StrCategoriesToExclude <> '!Null'  
Begin   
 Insert #ReasonsToExclude(ERC_Id,ERC_Desc)  
   Exec SPCMN_ReportCollectionParsing  
   @PRMCollectionString = @Local_PG_StrCategoriesToExclude, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ',',   
   @PRMDataType01 = 'nvarchar(100)'  
  
 UPDATE #ReasonsToExclude  
   Set ERC_Id = erc.erc_id  
 FROM dbo.Event_Reason_Catagories  erc WITH(NOLOCK)  
 Join #ReasonsToExclude rte on erc.erc_desc = rte.ERC_Desc       
    
    -- LineStops ERC  
    Insert Into #Equations Select 'DPR_LineStopsERC_EQN','Label=LineStopsERC;','LineStopsERC',Operator,Class,1 FROM #Equations WHERE Variable = 'LineStops'  
    -- Downtime ERC  
    Insert Into #Equations Select 'DPR_DowntimeERC_EQN','Label=DowntimeERC;','DowntimeERC',Operator,Class,1 FROM #Equations WHERE Variable = 'Downtime'  
   
End  
Else  
Begin  
    Delete FROM @ColumnVisibility WHERE VariableName Like '%DowntimeUnplanned%'   
                                     Or VariableName Like '%LineStopsUnplanned%'  
                                     Or VariableName Like '%MTBF_Unplanned%'  
                                     Or VariableName Like '%MTTR_Unplanned%'  
End  
  
-- Select * FROM #ReasonsToExclude  
----------------------------------------------------------------------------------------------------------------------  
-- End Get Parameters  
----------------------------------------------------------------------------------------------------------------------  
  
  
  
If @Local_PG_StrCategoriesToExclude <> '!Null'  
  
Begin  
  
  
UPDATE    dr  
   SET    DowntimeTreeId = pe.Name_Id  
   FROM   #Downtimes dr   
   JOIN    dbo.Prod_Events pe WITH(NOLOCK) ON dr.Location_id = pe.PU_Id   
   WHERE   pe.Event_Type = 2 -- Event_type = 2 (Downtime)  
  
  
---------------------------------------------------------------------------------------------------  
-- Find the node ID associated with Reason Level 4  
---------------------------------------------------------------------------------------------------  
  
UPDATE dr  
 Set dr.DowntimeNodeTreeId = l4.Event_Reason_Tree_Data_Id  
 FROM #Downtimes dr        
 JOIN dbo.Event_Reason_Tree_Data l4 WITH (NOLOCK) ON dr.DowntimeTreeId = l4.Tree_Name_Id AND dr.Reason4_Code = l4.Event_Reason_Id AND l4.Event_Reason_Level = 4  
 JOIN dbo.Event_Reason_Tree_Data l3 WITH (NOLOCK) ON l3.Event_Reason_Tree_Data_Id = l4.Parent_Event_R_Tree_Data_Id And dr.Reason3_Code = l4.Parent_Event_Reason_Id AND l3.Event_Reason_Level = 3  
 JOIN dbo.Event_Reason_Tree_Data l2 WITH (NOLOCK) ON l2.Event_Reason_Tree_Data_Id = l3.Parent_Event_R_Tree_Data_Id And dr.Reason2_Code = l3.Parent_Event_Reason_Id AND l2.Event_Reason_Level = 2  
 JOIN dbo.Event_Reason_Tree_Data l1 WITH (NOLOCK) ON l1.Event_Reason_Tree_Data_Id = l2.Parent_Event_R_Tree_Data_Id And dr.Reason1_Code = l2.Parent_Event_Reason_Id AND l1.Event_Reason_Level = 1  
        WHERE dr.Reason4_Code Is Not NULL  
  
UPDATE dr  
 Set ERC_Id = ed.ERC_Id,  ERC_Desc = ec.ERC_Desc  
FROM #Downtimes dr  
JOIN dbo.Event_Reason_Category_Data ed WITH (NOLOCK) ON dr.DowntimeNodeTreeId = ed.Event_Reason_Tree_Data_Id  
JOIN dbo.Event_Reason_Catagories ec WITH (NOLOCK) ON ec.ERC_Id = ed.ERC_Id    
WHERE ec.ERC_Desc IN (Select ERC_Desc FROM #ReasonsToExclude)   
  
---------------------------------------------------------------------------------------------------  
--   Find the node ID associated with Reason Level 3 when Reason Level 4 is null  
---------------------------------------------------------------------------------------------------  
UPDATE dr  
 SET dr.DowntimeNodeTreeId = l3.Event_Reason_Tree_Data_Id   
 FROM #Downtimes dr        
 JOIN dbo.Event_Reason_Tree_Data l3 WITH (NOLOCK) ON dr.DowntimeTreeId = l3.Tree_Name_Id AND dr.Reason3_Code = l3.Event_Reason_Id AND l3.Event_Reason_Level = 3  
 JOIN dbo.Event_Reason_Tree_Data l2 WITH (NOLOCK) ON l2.Event_Reason_Tree_Data_Id = l3.Parent_Event_R_Tree_Data_Id And dr.Reason2_Code = l3.Parent_Event_Reason_Id AND l2.Event_Reason_Level = 2  
 JOIN dbo.Event_Reason_Tree_Data l1 WITH (NOLOCK) ON l1.Event_Reason_Tree_Data_Id = l2.Parent_Event_R_Tree_Data_Id And dr.Reason1_Code = l2.Parent_Event_Reason_Id AND l1.Event_Reason_Level = 1  
        WHERE dr.Reason3_Code Is Not NULL  
  
UPDATE dr  
 Set ERC_Id = ed.ERC_Id,  ERC_Desc = ec.ERC_Desc  
FROM #Downtimes dr  
JOIN dbo.Event_Reason_Category_Data ed WITH (NOLOCK) ON dr.DowntimeNodeTreeId = ed.Event_Reason_Tree_Data_Id  
JOIN dbo.Event_Reason_Catagories ec WITH (NOLOCK) ON ec.ERC_Id = ed.ERC_Id    
WHERE ec.ERC_Desc IN (Select ERC_Desc FROM #ReasonsToExclude)   
  
---------------------------------------------------------------------------------------------------  
--   Find the node ID associated with Reason Level 2 when Reason Level 3 is null  
---------------------------------------------------------------------------------------------------  
  
UPDATE dr  
  
 SET dr.DowntimeNodeTreeId = l2.Event_Reason_Tree_Data_Id  
FROM #Downtimes dr        
JOIN dbo.Event_Reason_Tree_Data l2 WITH (NOLOCK) ON dr.DowntimeTreeId = l2.Tree_Name_Id AND dr.Reason2_Code = l2.Event_Reason_Id AND l2.Event_Reason_Level = 2  
JOIN dbo.Event_Reason_Tree_Data l1 WITH (NOLOCK) ON l1.Event_Reason_Tree_Data_Id = l2.Parent_Event_R_Tree_Data_Id And dr.Reason1_Code = l2.Parent_Event_Reason_Id AND l1.Event_Reason_Level = 1   
WHERE Reason2_Code Is Not NULL  
  
UPDATE dr  
 Set ERC_Id = ed.ERC_Id,  ERC_Desc = ec.ERC_Desc  
FROM #Downtimes dr  
JOIN dbo.Event_Reason_Category_Data ed WITH (NOLOCK) ON dr.DowntimeNodeTreeId = ed.Event_Reason_Tree_Data_Id  
JOIN dbo.Event_Reason_Catagories ec WITH (NOLOCK) ON ec.ERC_Id = ed.ERC_Id    
WHERE ec.ERC_Desc IN (Select ERC_Desc FROM #ReasonsToExclude)   
  
--------------------------------------------------------------------------------------------------  
--   Find the node ID associated with Reason Level 1 when Reason Level 2 is null  
---------------------------------------------------------------------------------------------------  
  
UPDATE dr  
 Set dr.DowntimeNodeTreeId = l1.Event_Reason_Tree_Data_Id   
FROM #Downtimes dr        
JOIN dbo.Event_Reason_Tree_Data l1 WITH (NOLOCK) ON dr.DowntimeTreeId = l1.Tree_Name_Id AND dr.Reason1_Code = l1.Event_Reason_Id AND l1.Event_Reason_Level = 1  
WHERE Reason1_Code Is Not NULL  
  
UPDATE dr  
 Set ERC_Id = ed.ERC_Id,  ERC_Desc = ec.ERC_Desc  
FROM #Downtimes dr  
JOIN dbo.Event_Reason_Category_Data ed WITH (NOLOCK) ON dr.DowntimeNodeTreeId = ed.Event_Reason_Tree_Data_Id  
JOIN dbo.Event_Reason_Catagories ec WITH (NOLOCK) ON ec.ERC_Id = ed.ERC_Id    
WHERE ec.ERC_Desc IN (Select ERC_Desc FROM #ReasonsToExclude)   
  
--------------------------------------------------------------------------------------------------  
--   Delete FROM #Downtimes all Reason Categories Found  
---------------------------------------------------------------------------------------------------  
-- Not doing this anymore, now counting them as sepparate variable  
-- UPDATE #Downtimes Set IsStops = 0 WHERE ERC_Desc IN (Select ERC_Desc FROM #ReasonsToExclude)   
  
End  
  
--**************************************************************************************************************  
-- END  
--**************************************************************************************************************  
-- Select id,* FROM #Downtimes order by pu_id,start_time  
--*****************************************************************************************************  
--Print convert(varchar(25), getdate(), 120) + ' End Get Event Reason categories'  
-- ******************************************************************************************  
-- START OF GROUPING FEATURE : Check the cursor  
-- MAJOR GROUPING !!  
-- ******************************************************************************************  
----------------------------------------------------------------------------------------------------  
-- Create Major Cursors, must include CLASS  
----------------------------------------------------------------------------------------------------  
-- Select * FROM #Downtimes WHERE IsStops = 1  
-----------------------------------------------------------------------------------------------------------  
-- LINE MAJOR GROUPING  
--Print convert(varchar(25), getdate(), 120) + ' Building Cursors for Grouping'  
------------------------------------------------------------------------------------------------------------  
If @RPTMajorGroupBy = 'Line' and @RPTMinorGroupBy = 'Line'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct PLID.PLID,PLID.PLDesc,PLID.PLID,PLID.PLDesc,0,0 FROM #PLIDList PLID        
    Order By PLID.PLDesc  
End  
If @RPTMajorGroupBy = 'Line' and @RPTMinorGroupBy = 'Unit'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct PLID.PLID,PLID.PLDesc,c.Pu_id,pu.Pu_desc,0,c.Class FROM #PLIDList PLID  
        Join @Class c on PLID.PLID = c.PLID  
        Join dbo.Prod_Units pu WITH(NOLOCK) on pu.pu_id = c.pu_id  
        Order By PLID.PLDesc,c.Class  
End  
If @RPTMajorGroupBy = 'Line' and @RPTMinorGroupBy = 'Crew'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct PLID.PLID,PLID.PLdesc,Crew,Crew,0,0 FROM #PLIDList PLID  
 Join #Production p on p.PLID = PLID.PLID  
        WHERE Crew Is Not Null  
 Order By PLID.PLDesc,Crew        
End  
If @RPTMajorGroupBy = 'Line' and @RPTMinorGroupBy = 'Shift'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct PLID.PLID,PLID.PLdesc,Shift,Shift,0,0 FROM #PLIDList PLID  
 Join #Production p on p.PLID = PLID.PLID  
 WHERE Shift Is Not Null        
        Order by PLID.PLDesc,Shift  
End  
If @RPTMajorGroupBy = 'Line' and @RPTMinorGroupBy = 'Location'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct PLID.PLID,PLID.PLdesc,Location,Location,0,0 FROM #PLIDList PLID  
 Join #Downtimes d on d.PLID = PLID.PLID  
 WHERE Location Is Not Null  
        Order by PLID.PLDesc,Location  
End  
If @RPTMajorGroupBy = 'Line' and @RPTMinorGroupBy = 'ProdDay'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct PLID.PLID,PLID.PLdesc,ProdDay,ProdDay,0,0 FROM #PLIDList PLID  
 Join #Production p on p.PLID = PLID.PLID WHERE p.ProdDay Is Not Null  
        Order by PLDesc,ProdDay  
End  
If @RPTMajorGroupBy = 'Line' and @RPTMinorGroupBy = 'Product'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct PLID.PLID,PLID.PLdesc,Product,Product,0,0 FROM #PLIDList PLID  
 Join #Production p on p.PLID = PLID.PLID  
        WHERE Product Is Not Null  
        Order by PLDesc, Product  
End  
If @RPTMajorGroupBy = 'Line' and @RPTMinorGroupBy = 'Product_Size'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct PLID.PLID,PLID.PLdesc,Product_Size,Product_Size,0,0 FROM #PLIDList PLID  
 Join #Production p on p.PLID = PLID.PLID  
        WHERE Product Is Not Null  
        Order by PLDesc, Product_Size  
End  
------------------------------------------------------------------------------------------------------------  
-- END Line Major Grouping  
------------------------------------------------------------------------------------------------------------  
-- print 'Unit grouping'  
------------------------------------------------------------------------------------------------------------  
-- UNIT MAJOR GROUPING  
------------------------------------------------------------------------------------------------------------  
  
If @RPTMajorGroupBy = 'Unit' and @RPTMinorGroupBy = 'Unit'  
Begin Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct c.pu_id,pu.pu_desc,c.pu_id,pu.pu_desc,c.class,c.class FROM @Class c  
 Join dbo.Prod_Units pu WITH(NOLOCK) on pu.pu_id = c.pu_id  
        Order By c.Class  
End  
If @RPTMajorGroupBy = 'Unit' and @RPTMinorGroupBy = 'Crew'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct p.PU_id,pu.PUDesc,Crew,Crew,pu.Class,0  FROM #Production p  
 Join @Class pu on p.pu_id = pu.pu_id  
 WHERE Crew Is Not NULL   
        Order By pu.Class  
End  
If @RPTMajorGroupBy = 'Unit' and @RPTMinorGroupBy = 'Shift'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct p.PU_id,pu.PUDesc,Shift,Shift,pu.Class,0  FROM #Production p  
 Join @Class pu on p.pu_id = pu.pu_id  
 WHERE Shift Is Not NULL    
        Order By pu.Class  
End  
If @RPTMajorGroupBy = 'Unit' and @RPTMinorGroupBy = 'Location'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct d.pu_id,pu.pudesc,Location,Location,pu.Class,0  FROM #Downtimes d  
 Join @Class pu on d.pu_id = pu.pu_id  
 WHERE Location Is Not NULL  
        Order By pu.Class  
End  
If @RPTMajorGroupBy = 'Unit' and @RPTMinorGroupBy = 'ProdDay'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct p.pu_id,pu.pudesc,ProdDay,ProdDay,pu.Class,0  FROM #Production p   
 Join @Class pu on p.pu_id = pu.pu_id WHERE p.ProdDay Is Not Null  
    Order By pu.Class  
End  
If @RPTMajorGroupBy = 'Unit' and @RPTMinorGroupBy = 'Product'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct p.pu_id,pu.pudesc,Product,Product,pu.Class,0  FROM #Production p  
 Join @Class pu on p.pu_id = pu.pu_id  
    Order By pu.Class  
End  
If @RPTMajorGroupBy = 'Unit' and @RPTMinorGroupBy = 'Product_Size'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct p.pu_id,pu.pudesc,Product_Size,Product_Size,pu.Class,0  FROM #Production p  
 Join @Class pu on p.pu_id = pu.pu_id  
    Order By pu.Class,Product_Size  
End  
------------------------------------------------------------------------------------------------------------  
-- END Line Major Grouping  
------------------------------------------------------------------------------------------------------------  
-- print 'Product grouping'  
------------------------------------------------------------------------------------------------------------  
-- PRODUCT MAJOR GROUPING  
------------------------------------------------------------------------------------------------------------  
If @RPTMajorGroupBy = 'Product' and @RPTMinorGroupBy = 'Product'  
  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct p.Product,p.Product,p.Product,p.Product,0,0 FROM #Production p       
        Order by p.Product  
End  
If @RPTMajorGroupBy = 'Product' and @RPTMinorGroupBy = 'Unit'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct p.Product,p.Product,p.Pu_id,pu.Pu_desc,0,c.Class FROM #Production p   
        Join @Class c on p.pu_id = c.pu_id  
        Join dbo.Prod_Units pu WITH(NOLOCK) on pu.pu_id = c.pu_id  
        Order by p.Product, c.Class  
End  
If @RPTMajorGroupBy = 'Product' and @RPTMinorGroupBy = 'Crew'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct Product,Product,Crew,Crew,0,0 FROM #Production  
        WHERE Crew is Not Null  
 Order by Product,Crew        
End  
If @RPTMajorGroupBy = 'Product' and @RPTMinorGroupBy = 'Shift'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct Product,Product,Shift,Shift,0,0 FROM #Production  
 WHERE Shift Is Not Null      
        Order by Product,Shift  
End  
If @RPTMajorGroupBy = 'Product' and @RPTMinorGroupBy = 'Location'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct Product,Product,Location,Location,0,0 FROM #Downtimes   
 WHERE Location Is Not NULL  
        Order by Product,Location  
End  
If @RPTMajorGroupBy = 'Product' and @RPTMinorGroupBy = 'ProdDay'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct Product,Product,ProdDay,ProdDay,0,0 FROM #Production WHERE ProdDay Is Not Null  
        Order by Product, ProdDay  
End  
If @RPTMajorGroupBy = 'Product' and @RPTMinorGroupBy = 'Product_Size'  
Begin  
 Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
 Select distinct Product,Product,Product_Size,Product_Size,0,0 FROM #Production   
    WHERE Product_Size Is Not Null  
    Order by Product, Product_Size  
End  
  
------------------------------------------------------------------------------------------------------------  
-- END Product Major Grouping  
------------------------------------------------------------------------------------------------------------  
-- Select * FROM @Cursor  
  
----------------------------------------------------------------------------------------------------  
If @RPTMajorGroupBy = 'Line'  
 set @RPTMajorGroupBy = 'PLID'  
  
If @RPTMinorGroupBy = 'Line'  
 set @RPTMinorGroupBy = 'PLID'  
  
If @RPTMajorGroupBy = 'Unit'  
 set @RPTMajorGroupBy = 'PU_ID'  
  
If @RPTMinorGroupBy = 'Unit'  
 set @RPTMinorGroupBy = 'PU_ID'  
  
-- If @RPTMajorGroupBy = @RPTMinorGroupBy  
--        UPDATE @Cursor Set Minor_id = 'ZZZ', Minor_Desc = 'ZZZ'  
  
--  
----------------------------------------------------------------------------  
-- If 1 major grouping column then do not show the ALL column  
--Print convert(varchar(25), getdate(), 120) + ' Building Output Tables'  
----------------------------------------------------------------------------  
Declare   
        @ShowAll as int,  
        @TotalTables as int  
  
Set @TotalTables = 4  
  
Select @ShowAll = Count(Distinct Major_id) FROM @Cursor  
  
----------------------------------------------------------------------------  
  
  
Set @GroupMajorFieldName = @RPTMajorGroupBy   
Set @GroupMinorFieldName = @RPTMinorGroupBy  
  
Declare   
 @MajGroupValue as nvarchar(20),  
 @MajGroupDesc as nvarchar(100),  
 @MinGroupValue as nvarchar(20),  
 @MinGroupDesc as nvarchar(100),  
    @MajOrderby as int,  
    @MinOrderby as int,  
 @Class_var as int  
  
  
Set  @i = 1  
  
Set @j = 1  
While @j <= @TotalTables  
Begin  
                If @j = 1   
          Select @TableName =  '#Summary'  
                If @j = 2 and @RPT_ShowTop5Downtimes = 'TRUE'  
                        Select @TableName =  '#Top5Downtime'  
                If @j = 3 and @RPT_ShowTop5Stops = 'TRUE'  
                        Select @TableName =  '#Top5Stops'  
                If @j = 4 and @RPT_ShowTop5Rejects = 'TRUE' and @RPTMinorGroupBy <> 'ProdDay'  
                        Select @TableName =  '#Top5Rejects'  
    
-- print 'Abro el cursor mayor ...'  
  
Declare RSMjCursor Insensitive Cursor For (Select distinct Major_Order_by,Major_Id, Major_desc FROM @Cursor)  
Order by Major_Order_by,Major_Desc  
Open RSMjCursor  
  
FETCH NEXT FROM RSMjCursor into @Class_Var,@MajGroupValue, @MajGroupDesc  
  
While @@Fetch_Status = 0 and @i < 100  
Begin  
  
    
 Set @ColNum = LTrim(RTrim(Convert(VarChar(3), @i)))  
                  
   
  Select @SQLString = ''  
  Select @SQLString =  ' UPDATE ' + @TableName + ' '   
    + ' Set Value'  + @ColNum + ' = ''' + @MajGroupDesc + '''' +  
    + ' WHERE GroupField = ''' + 'Major' + ''''  
  
  Exec  (@SQLString)  
    
  If @GroupMajorFieldName <> @GroupMinorFieldName  
  Begin  
  
  -- print 'Abro el cursor menor'  
  
  Declare RSMiCursor Insensitive Cursor For (Select Minor_Order_by,Minor_Id, Minor_desc FROM @Cursor  
    WHERE Major_id = @MajGroupValue  
                                UNION Select 99,'ZZZ','ZZZ'  
                                ) Order by Minor_Order_by,Minor_desc  
  Open RSMiCursor  
  FETCH NEXT FROM RSMiCursor into @Class_Var,@MinGroupValue,@MinGroupDesc  
    
  While @@Fetch_Status = 0 and @i < 100  
                Begin  
  
    If @MinGroupValue <> 'ZZZ'  
    Begin  
      Set @ColNum = LTrim(RTrim(Convert(VarChar(3), @i)))  
      Select @SQLString = ''  
      Select @SQLString =  ' UPDATE '  + @TableName + ' '   
       + ' Set Value'  + @ColNum + ' = ''' + @MinGroupDesc + '''' +  
       + ' WHERE GroupField = ''' + 'Minor' + ''''  
  
      Exec  (@SQLString)  
        
      Set @i = @i + 1  
    End   
  
  FETCH NEXT FROM RSMiCursor into @Class_Var,@MinGroupValue, @MinGroupDesc  
  
  
  End  
  
  Close  RSMiCursor  
  Deallocate RSMiCursor    
  
  End    
    
                If @ShowAll > 1                  
                Begin  
  Set @ColNum = LTrim(RTrim(Convert(VarChar(3), @i)))  
   Select @SQLString = ''  
  
                If @RPTMajorGroupBy <> @RPTMinorGroupBy  
  
  Select @SQLString =  ' UPDATE '  + @TableName + ' '   
         + ' Set Value'  + @ColNum + ' = ''' + 'All' + '''' +  
         + ' WHERE GroupField = ''' + 'Minor' + ''''  
  
                Else  
                -- If Line = Line or Line = None  
                Select @SQLString =  ' UPDATE '  + @TableName + ' '   
         + ' Set Value'  + @ColNum + ' = ''' + @MajGroupDesc + '''' +  
         + ' WHERE GroupField = ''' + 'Minor' + ''''  
  
  Exec (@SQLString)  
                  
                End -- End Show All  
  
          
  Set @i = @i + 1  
  
 FETCH NEXT FROM RSMjCursor into @Class_Var,@MajGroupValue, @MajGroupDesc  
  
End  
  
  
Close  RSMjCursor  
Deallocate RSMjCursor  
  
Set @j = @j + 1  
Set @i = 1  
End  
  
  
-- select * FROM #summary  
----------------------------------------------------------------------------  
-- Code below for label insertion based on presence of 'aggregate' column  
--Print convert(varchar(25), getdate(), 120) + ' Inserting data in Top 5 Tables'  
  
If @RPT_ShowTop5Downtimes = 'TRUE'  
Begin  
   Select @SQLString = ''  
   Select @SQLString = 'UPDATE #TOP5DOWNTIME' + ' '   
   + 'Set AGGREGATE = ''' + @lblDowntime + '''' +  
   + 'WHERE Sortorder = 1 or Sortorder is Null'  
   Exec  (@SQLString)  
End  
  
If @RPT_ShowTop5Stops = 'TRUE'  
Begin  
  Select @SQLString = ''  
  Select @SQLString = 'UPDATE #TOP5STOPS' + ' '   
  + 'Set AGGREGATE = ''' + @lblStops + '''' +  
  + 'WHERE Sortorder = 1 or Sortorder is Null'  
  Exec  (@SQLString)  
End  
  
If @RPT_ShowTop5Rejects = 'TRUE' and @RPTMinorGroupBy <> 'ProdDay'  
Begin  
        Select @SQLString = ''  
        Select @SQLString = 'UPDATE #TOP5REJECTS' + ' '   
        + 'Set AGGREGATE = ''' + @lblPads + '''' +  
        + 'WHERE Sortorder = 1 or Sortorder is Null'  
        Exec  (@SQLString)  
End  
  
---------------------------------------------------------------------------------------------  
-- FRio : change datatype to fix the sort order issue  
---------------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------------  
-- LineStops  
Set @Operator = 'SUM'    -- (Select Operator FROM #Equations WHERE Variable = 'LineStops')  
Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'LineStops')  
  
If @RPT_ShowTop5Stops = 'TRUE'  
Begin  
Select @SQLString = ' Insert Into #TOP5Stops (DESC01, DESC02, AGGREGATE, Downtime) '+  
    ' Select Top 5 ' + REPLACE(REPLACE(@RPTDowntimeFieldOrder,'~',','),'!null','null') + ', LTrim(RTrim(str(Sum(Convert(float,isstops)),9,1))), LTrim(RTrim(str(Sum(Convert(float,Duration)),9,1))) ' +  
 ' FROM #Downtimes TDT ' +   
 ' Join #PLIDList TPL on TDT.PU_ID = TPL.ConvUnit ' +   
 ' Join #ShiftDESCList TSD on TDT.Shift = TSD.ShiftDESC ' +  
 ' Join #CrewDESCList CSD on TDT.Crew = CSD.CrewDESC ' +  
 ' Join #PLStatusDESCList TPLSD on TDT.LineStatus = TPLSD.PLStatusDESC '   
  
If NOT (@RPTMinorGroupBy = 'PU_Id' Or @RPTMajorGroupBy = 'PU_Id')   
        Select @SQLString = @SQLString + ' WHERE TDT.Class IN (' + @ClassList + ')'   
  
Select @SQLString = @SQLString + ' GROUP BY ' + REPLACE(REPLACE(REPLACE(@RPTDowntimeFieldOrder,'~',','),'!null,',''), ',!null','') + ' ' +  
 ' Order BY convert(float,sum(isstops)) DESC'  
  
Execute (@SQLString)  
  
Select @SQLString = 'Insert #Top5Stops (Desc01,Downtime, AGGREGATE) ' +  
  ' Select '''+'.'+''', LTrim(RTrim(Convert(varchar(50),Sum(Convert(float,Downtime))))), LTrim(RTrim(Convert(varchar(50),Sum(Convert(Float,AGGREGATE))))) ' +  
  ' FROM #Top5Stops ' +  
  ' WHERE SortOrder > 3'  
  
Execute (@SQLString)  
  
  
End  
  
If @RPT_ShowTop5Downtimes = 'TRUE'  
Begin  
Select @SQLString =  
 ' Insert #TOP5Downtime ' +  
  ' (DESC01, DESC02, AGGREGATE, Stops) ' +  
 ' Select TOP 5 ' + REPLACE(REPLACE(@RPTDowntimeFieldOrder,'~',','),'!null','null') + ', LTrim(RTrim(STR(Sum(Duration),10,1))), Sum(IsStops) ' +  
 ' FROM #Downtimes TDT WITH (NOLOCK)' +  
 ' Join #PLIDList TPL WITH (NOLOCK) on TDT.PU_ID = TPL.ConvUnit ' +   
 ' Join #ShiftDESCList TSD WITH (NOLOCK) on TDT.Shift = TSD.ShiftDESC ' +  
 ' Join #CrewDESCList CSD WITH (NOLOCK) on TDT.Crew = CSD.CrewDESC ' +  
 ' Join #PLStatusDESCList TPLSD WITH (NOLOCK) on TDT.LineStatus = TPLSD.PLStatusDESC '   
  
If NOT (@RPTMinorGroupBy = 'PU_Id' Or @RPTMajorGroupBy = 'PU_Id')   
        Select @SQLString = @SQLString + ' WHERE TDT.Class IN (' + @ClassList + ')'   
  
Select @SQLString = @SQLString + ' GROUP BY ' + REPLACE(REPLACE(REPLACE(@RPTDowntimeFieldOrder,'~',','),'!null,',''), ',!null','') + ' ' +  
 ' Order BY Convert(float,Sum(Duration)) DESC'  
  
Execute (@SQLString)  
  
  
Select @SQLString = ' Insert #TOP5Downtime (Desc01,Stops, AGGREGATE) ' +  
  ' Select '''+'.'+''',LTrim(RTrim(Convert(varchar(50),Sum(Convert(int,Stops))))), LTrim(RTrim(Convert(varchar(50),Sum(Convert(Float,AGGREGATE))))) ' +  
  ' FROM #TOP5Downtime ' +  
  ' WHERE SortOrder > 3'  
  
Execute (@SQLString)  
End  
  
  
If @RPT_ShowTop5Rejects = 'TRUE' and @RPTMinorGroupBy <> 'ProdDay'  
Begin  
  
Select @SQLString =  
 ' Insert #TOP5REJECTS ' +  
 ' (DESC01, DESC02, AGGREGATE, Events) ' +  
 ' Select TOP 5 ' + REPLACE(REPLACE(@RPTWasTEFieldOrder,'~',','),'!null','null') + ', Sum(PadCount), sum(nrecords) ' +  
 ' FROM #REJECTS TR ' +  
 ' Join #ShiftDESCList TSD on TR.Shift = TSD.ShiftDESC ' +  
 ' Join #CrewDESCList CSD on TR.Crew = CSD.CrewDESC ' +  
 ' Join #PLStatusDESCList TPLSD on TR.LineStatus = TPLSD.PLStatusDESC ' +  
       ' GROUP BY ' + REPLACE(REPLACE(REPLACE(@RPTWasTEFieldOrder,'~',','),'!null,',''), ',!null','') + ' ' +  
 ' Order BY Convert(float,Sum(PadCount)) DESC'  
  
Execute (@SQLString)  
  
  
Select @SQLString = ' Insert #TOP5REJECTS (Events, AGGREGATE) ' +  
  ' Select LTrim(RTrim(Convert(varchar(50),Sum(Convert(int,Events))))), LTrim(RTrim(Convert(varchar(50),Sum(Convert(Float,AGGREGATE))))) ' +  
  ' FROM #TOP5REJECTS ' +  
  ' WHERE SortOrder > 3'  
  
Execute (@SQLString)  
End  
  
-- FRio :   
-- Select * FROM #top5downtime  
-- Select * FROM #top5stops  
-- Select * FROM #top5rejects  
-------------------------------------------------------------------------------------------------------  
-- POPULATE OUTPUT Tables:  
-------------------------------------------------------------------------------------------------------  
-- Select pu_id,Sum(datediff(s,starttime,endtime)/60.0) FROM #Status group by pu_id  
-- Select * FROM #Status WHERE pu_id = 968 order by starttime  
-- Select * FROM #Status --WHERE pu_id = 1000 order by starttime  
-- Build Temporary tables to get the Products for calculating #uptimes downtimes  
-------------------------------------------------------------------------------------------------------  
-- POPULATE OUTPUT Tables: Some data For Top 5 Downtime  
-------------------------------------------------------------------------------------------------------  
-- Select * FROM #TempProdSched  
-- Select * FROM @Product_Specs  
  
  
Truncate Table #Temporary  
Declare   
  @ClassCounter as int,  
  @ConvVar as nvarchar(100)  
   
  
 Set @ClassCounter = 1  
  
 While @ClassCounter <= (Select Max(Class) FROM @ClassREInfo)  
  
  Begin  
  
   Select @ConvVar = Conversion FROM @ClassREInfo WHERE Class = @ClassCounter  
     
   Insert #Temporary (TempValue1,TempValue2)  
   Exec SPCMN_ReportCollectionParsing  
   @PRMCollectionString = @ConvVar, @PRMFieldDelimiter = null, @PRMRecordDelimiter = ';',   
   @PRMDataType01 = 'nvarchar(200)'  
  
   Insert Into @Conv_Class_Prod (Class,Prod_Id,Value)  
   Select @ClassCounter as Class,Prod_Code,Target FROM #Temporary t  
   Join @Product_Specs ps On Convert(varchar,t.TempValue2) = Convert(varchar,ps.Spec_Desc)  
     
   -- Select * FROM #Production WHERE Class = @ClassCounter  
     
   Select @ClassCounter = Min(Class) FROM @ClassREInfo WHERE Class > @ClassCounter  
  
   Truncate Table #Temporary  
  
  End  
  
Declare  
  @ConvFactor  as  float  
  
Declare ConvCursor Insensitive Cursor For   
   (Select Class, Prod_Id, Value FROM @Conv_Class_Prod) Order By Class, Prod_Id  
  
Open ConvCursor  
  
FETCH NEXT FROM ConvCursor  into @ClassNo,@Prod_Id, @Value  
  
While @@Fetch_Status = 0   
Begin  
   
 UPDATE #Production  
  Set ConvFactor = ConvFactor * @Value  
 WHERE Class = @ClassNo and Product = @Prod_Id  
  
 FETCH NEXT FROM ConvCursor  into @ClassNo,@Prod_Id,@Value  
  
End  
  
Close ConvCursor  
Deallocate ConvCursor  
  
-- Select LineStatus,datediff(ss,starttime,endtime)/60,* FROM #Production --WHERE pu_id = 118  
-- Select * FROM #Downtimes WHERE class = 2 Order By pu_id, start_time  
-- Select ProdDay,* FROM #Downtimes Order by start_time  
  
If @RPTMajorGroupBy <> @RPTMinorGroupBy  
        Insert Into @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)  
        Select distinct Major_id,Major_Desc,'ZZZ','ZZZ',Major_Order_by,99 FROM @Cursor  
Else  
        UPDATE @Cursor Set Minor_id = 'ZZZ',Minor_Desc = 'ZZZ'   
  
------------------------------------------------------------------------------------------------------------------------  
-- Populate ac_Top5Downtimes cursor  
------------------------------------------------------------------------------------------------------------------------  
Select @FIELD1 = SUBString(@RPTDowntimeFieldOrder, 1,CHARINDEX('~',@RPTDowntimeFieldOrder)-1)  
Select @FIELD2 = SUBString(@RPTDowntimeFieldOrder, CHARINDEX('~',@RPTDowntimeFieldOrder)+1,255)  
  
Insert Into #ac_Top5Downtimes (SortOrder, DESC01, DESC02)  
Select SortOrder, DESC01, DESC02  
  FROM #TOP5Downtime  
  WHERE SortOrder > 3 and SortOrder < 9  
  
If @FIELD1 <> '!null'  
Begin  
UPDATE #ac_Top5Downtimes  
        Set WHEREString1 = (Case IsNull(DESC01,'xyz') When 'xyz' then Convert(nvarchar,@FIELD1 + ' IS null') else Convert(nvarchar(200),@FIELD1 + ' = ''' + DESC01 + '''') end)  
End  
  
If @FIELD2 <> '!null'  
Begin  
UPDATE #ac_Top5Downtimes  
        Set WHEREString2 = (Case IsNull(DESC02,'xyz') When 'xyz' then Convert(nvarchar,@FIELD2 + ' IS null') else Convert(nvarchar(200),@FIELD2 + ' = ''' + DESC02 + '''') end)  
End  
  
------------------------------------------------------------------------------------------------------------------------  
-- Populate ac_Top5Stops cursor  
------------------------------------------------------------------------------------------------------------------------  
  
Insert Into #ac_Top5Stops (SortOrder, DESC01, DESC02)  
Select DISTINCT SortOrder, DESC01, DESC02  
  FROM #TOP5Stops  
  WHERE SortOrder > 3 and SortOrder < 9  
  
  
If @FIELD1 <> '!null'  
Begin  
UPDATE #ac_Top5Stops  
        Set WHEREString1 = (Case IsNull(DESC01,'xyz') When 'xyz' then Convert(nvarchar,@FIELD1 + ' IS Null') else Convert(nvarchar(200),@FIELD1 + ' = ''' + DESC01 + '''') end)  
End  
  
  
If @FIELD2 <> '!null'  
Begin  
UPDATE #ac_Top5Stops  
        Set WHEREString2 = (Case IsNull(DESC02,'xyz') When 'xyz' then Convert(nvarchar,@FIELD2 + ' IS Null') else Convert(nvarchar(200),@FIELD2 + ' = ''' + DESC02 + '''') end)  
End  
  
------------------------------------------------------------------------------------------------------------------------  
-- Populate ac_Top5Rejects cursor  
------------------------------------------------------------------------------------------------------------------------  
Declare   
             @FIELD1Waste as nvarchar(50),  
             @FIELD2Waste as nvarchar(50)  
  
Select @FIELD1Waste = SUBString(@RPTWasTEFieldOrder, 1,CHARINDEX('~',@RPTWasTEFieldOrder)-1)  
Select @FIELD2Waste = SUBString(@RPTWasTEFieldOrder, CHARINDEX('~',@RPTWasTEFieldOrder)+1,255)  
  
Insert Into #ac_Top5Rejects (SortOrder, DESC01, DESC02)  
Select SortOrder, DESC01, DESC02  
  FROM #TOP5Rejects  
  WHERE SortOrder > 3 and SortOrder < 9  
  
If @FIELD1Waste <> '!null'  
Begin  
UPDATE #ac_Top5Rejects  
        Set WHEREString1 = (Case IsNull(DESC01,'xyz') When 'xyz' then Convert(nvarchar,@FIELD1Waste + ' IS null') else Convert(nvarchar(200),@FIELD1Waste + ' = ''' + DESC01 + '''') end)  
End  
  
If @FIELD2Waste <> '!null'  
Begin  
UPDATE #ac_Top5Rejects  
        Set WHEREString2 = (Case IsNull(DESC02,'xyz') When 'xyz' then Convert(nvarchar,@FIELD2Waste + ' IS null') else Convert(nvarchar(200),@FIELD2Waste + ' = ''' + DESC02 + '''') end)  
End  
  
  
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
-- FRio : NOTE , Start of cursor for filling #TEMPORARY TABLES  
--Print convert(varchar(25), getdate(), 120) + 'BEFORE GOING INTO THE CURSOR !!'  
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
     
-- Select * FROM #Summary  
Set @i = (Select Min(Cur_id) FROM @Cursor)  
Declare   
 @WHEREString as nvarchar(1000),  
    @GroupByString as nvarchar(500),  
 @Active_Class as int,  
 @Prev_Value as nvarchar(100)  
  
Set @Prev_Value = ''  
  
        Declare RSMiCursor Insensitive Cursor For ( Select Major_id, Major_desc,Major_Order_by,Minor_id, Minor_desc,Minor_Order_by  FROM @Cursor)   
                ORDER BY Major_Order_by,Major_Desc,Minor_Order_by,Minor_Desc   
            
   
  Open RSMiCursor  
  
  FETCH NEXT FROM RSMiCursor into @MajGroupValue, @MajGroupDesc,@MajOrderby,@MinGroupValue, @MinGroupDesc,@MinOrderby  
  
  WHILE  @@FETCH_Status = 0 and @i <=100  
    -- @i <= (Select Max(cur_id) FROM @Cursor) Or @i > 100  
  BEGIN  
  /*  
  Select  @MajGroupValue = Major_id,   
    @MajGroupDesc = Major_desc,  
    @MajOrderby = Major_Order_by,  
    @MinGroupValue = Minor_id,   
    @MinGroupDesc = Minor_desc,  
    @MinOrderby = Minor_Order_by    
  FROM @Cursor  
  WHERE Cur_Id = @i  
  */  
                
  Set @Active_Class = NULL  
    
  If @RPTMajorGroupBy = 'PU_ID'  
   Select @Active_Class = Class FROM @Class WHERE PU_Id = @MajGroupValue  
  Else   
   If @RPTMinorGroupBy = 'PU_ID' and @MinGroupValue <> 'ZZZ'  
    Select @Active_Class = Class FROM @Class   
                                WHERE PU_Id = @MinGroupValue  
     
  -- Select @MajGroupValue,@MinGroupValue,@Active_Class    
                ----------------------------------------------------------------------------------------------  
  
  ----------------------------------------------------------------------------  
  -- POPULATE OUTPUT Tables: Some data For Top 5 Downtimes  
  ----------------------------------------------------------------------------   
  
          Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'LineStops')  
         Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'LineStops')  
                Set @GROUPBYString = ' Group by DESC01, DESC02'  
                                                       
                        IF @RPTMajorGroupBy = 'PU_ID' or @RPTMinorGroupBy = 'PU_ID'  
   BEGIN  
   Select @SQLString = 'Select ac.desc01,ac.desc02,STR(Sum(Duration),6,1) '+  
     'FROM #Downtimes TDT'  
     + ' Join #PLIDList TPL on TDT.PU_ID = TPL.ConvUnit'          
     + ' Join #ShiftDESCList TSD on TDT.Shift = TSD.ShiftDESC'  
     + ' Join #CrewDESCList CSD on TDT.Crew = CSD.CrewDESC'  
     + ' Join #PLStatusDESCList TPLSD on TDT.LineStatus = TPLSD.PLStatusDESC'  
                                        + ' Join #ac_Top5Downtimes ac on IsNull(ac.desc01,''' +'xyz' +''') = IsNull(tdt.'+@FIELD1+', ''' + 'xyz' + ''')'  
                                        If @FIELD2 <> '!null'  
                                              Select @SQLString = @SQLString + ' and IsNull(ac.desc02,''' +'xyz' +''') = IsNull(tdt.'+@FIELD2+', ''' + 'xyz' + ''')'  
  
  
     Select @SQLString = @SQLString + ' WHERE TDT.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''  
       
     if (@MinGroupValue <> 'ZZZ' and @MinGroupValue <> '999')  
      Select @SQLString = @SQLString + ' and TDT.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
  
     Select @SQLString = @SQLString + @GROUPBYString  
                        END  
                        ELSE  
                        BEGIN  
                        Select @SQLString = 'Select ac.desc01,ac.desc02,STR(Sum(Duration),6,1) '+  
     'FROM #Downtimes TDT'  
     + ' Join #PLIDList TPL on TDT.PU_ID = TPL.ConvUnit'          
     + ' Join #ShiftDESCList TSD on TDT.Shift = TSD.ShiftDESC'  
     + ' Join #CrewDESCList CSD on TDT.Crew = CSD.CrewDESC'  
     + ' Join #PLStatusDESCList TPLSD on TDT.LineStatus = TPLSD.PLStatusDESC'  
                                        + ' Join #ac_Top5Downtimes ac on IsNull(ac.desc01,''' +'xyz' +''') = IsNull(tdt.'+@FIELD1+', ''' + 'xyz' + ''')'  
                                        If @FIELD2 <> '!null'  
                                              Select @SQLString = @SQLString + ' and IsNull(ac.desc02,''' +'xyz' +''') = IsNull(tdt.'+@FIELD2+', ''' + 'xyz' + ''')'  
  
     Select @SQLString = @SQLString + ' WHERE TDT.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''  
                                        + ' and tdt.Class In (' + @ClassList + ')'  
       
     if (@MinGroupValue <> 'ZZZ' and @MinGroupValue <> '999')  
      Select @SQLString = @SQLString + ' and TDT.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
  
                                 Select @SQLString = @SQLString + @GROUPBYString  
  
                        END  
                          
   --  
   TRUNCATE Table #TEMPORARY  
  
            --           print 'Top 5 ' + @SQLString  
  
   Insert #Temporary(TempValue1,TempValue2,TempValue3)  
   Execute (@SQLString)  
  
                        
          Select @SQLString =     ' UPDATE #TOP5Downtime ' +  
             ' Set Value' + Convert(varchar,@i) + ' = Convert(varchar,t.TEMPValue3)' +  
                                                ' FROM #Top5Downtime tdt ' +  
                                                ' Join #Temporary t on IsNull(tdt.desc01,''' + 'xyz' + ''') = IsNull(t.TempValue1,''' + 'xyz' + ''')'    
                                                If @FIELD2 <> '!null'  
                                                    Select @SQLString = @SQLString + ' and IsNull(tdt.desc02,''' + 'xyz' + ''') = IsNull(t.TempValue2,''' + 'xyz' + ''')'    
                                                Select @SQLString = @SQLString + ' WHERE Sortorder > 3 '   
              
   Execute (@SQLString)  
                                                      
          Select @TEMPValue = Sum(Convert(float,TEMPValue3)) FROM #TEMPORARY   
  
          Select @SQLString =  'UPDATE #TOP5Downtime ' +  
           'Set Value' + Convert(varchar,@i) + ' = ''' + Convert(varchar,@TEMPValue) + '''' +  
           'WHERE SortOrder = 9'   
          Execute (@SQLString)  
  
  ----------------------------------------------------------------------------  
  -- POPULATE OUTPUT Tables: Some data For Top 5 Stops  
  ----------------------------------------------------------------------------   
  
         IF @RPTMajorGroupBy = 'PU_ID' or @RPTMinorGroupBy = 'PU_ID'  
   BEGIN  
   Select @SQLString = 'Select ac.desc01,ac.desc02,Count(*) '+  
     'FROM #Downtimes TDT'  
     + ' Join #PLIDList TPL on TDT.PU_ID = TPL.ConvUnit'           
     + ' Join #ShiftDESCList TSD on TDT.Shift = TSD.ShiftDESC'  
     + ' Join #CrewDESCList CSD on TDT.Crew = CSD.CrewDESC'  
     + ' Join #PLStatusDESCList TPLSD on TDT.LineStatus = TPLSD.PLStatusDESC'  
                                         + ' Join #ac_Top5Stops ac on IsNull(ac.desc01,''' +'xyz' +''') = IsNull(tdt.'+@FIELD1+', ''' + 'xyz' + ''')'  
                                        If @FIELD2 <> '!null'  
                                              Select @SQLString = @SQLString + ' and IsNull(ac.desc02,''' +'xyz' +''') = IsNull(tdt.'+@FIELD2+', ''' + 'xyz' + ''')'  
  
  
     Select @SQLString = @SQLString + ' WHERE TDT.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''  
     + ' and IsStops = 1 '  
  
     if (@MinGroupValue <> 'ZZZ' and @MinGroupValue <> '999')  
      Select @SQLString = @SQLString + ' and TDT.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
  
     Select @SQLString = @SQLString + @GROUPBYString  
                        END  
                        ELSE  
                        BEGIN  
                        Select @SQLString = 'Select ac.desc01,ac.desc02,Count(*) '+  
     'FROM #Downtimes TDT'  
     + ' Join #PLIDList TPL on TDT.PU_ID = TPL.ConvUnit'      
     + ' Join #ShiftDESCList TSD on TDT.Shift = TSD.ShiftDESC'  
     + ' Join #CrewDESCList CSD on TDT.Crew = CSD.CrewDESC'  
     + ' Join #PLStatusDESCList TPLSD on TDT.LineStatus = TPLSD.PLStatusDESC'  
                                        + ' Join #ac_Top5Stops ac on IsNull(ac.desc01,''' +'xyz' +''') = IsNull(tdt.'+@FIELD1+', ''' + 'xyz' + ''')'  
                                        If @FIELD2 <> '!null'  
                                              Select @SQLString = @SQLString + ' and IsNull(ac.desc02,''' +'xyz' +''') = IsNull(tdt.'+@FIELD2+', ''' + 'xyz' + ''')'  
  
     Select @SQLString = @SQLString + ' WHERE TDT.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''  
                                        + ' and tdt.Class In (' + @ClassList + ') and IsStops = 1 '  
       
     if (@MinGroupValue <> 'ZZZ' and @MinGroupValue <> '999')  
      Select @SQLString = @SQLString + ' and TDT.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
  
                                 Select @SQLString = @SQLString + @GROUPBYString  
  
                        END  
                          
   --  
   TRUNCATE Table #TEMPORARY  
  
            -- Print @SQLString  
  
   Insert #Temporary(TempValue1,TempValue2,TempValue3)  
   Execute (@SQLString)    
                         
          Select @SQLString =     ' UPDATE #TOP5Stops ' +  
             ' Set Value' + Convert(varchar,@i) + ' = Convert(varchar,t.TEMPValue3)' +  
                                                ' FROM #Top5Stops tdt ' +  
                                                ' Join #Temporary t on IsNull(tdt.desc01,''' + 'xyz' + ''') = IsNull(t.TempValue1,''' + 'xyz' + ''')'    
                                                If @FIELD2 <> '!null'  
                                                    Select @SQLString = @SQLString + ' and IsNull(tdt.desc02,''' + 'xyz' + ''') = IsNull(t.TempValue2,''' + 'xyz' + ''')'    
                                                Select @SQLString = @SQLString + ' WHERE Sortorder > 3 '   
              
   Execute (@SQLString)  
                                                      
          Select @TEMPValue = Sum(Convert(float,TEMPValue3)) FROM #TEMPORARY   
  
          Select @SQLString =  'UPDATE #TOP5Stops ' +  
           'Set Value' + Convert(varchar,@i) + ' = ''' + Convert(varchar,@TEMPValue) + '''' +  
           'WHERE SortOrder = 9'   
          Execute (@SQLString)  
  
  
                 ----------------------------------------------------------------------------  
                 -- POPULATE OUTPUT Tables: Some data For Top 5 Reject  
                 ----------------------------------------------------------------------------   
  
   Select @SQLString = 'Select t.desc01,Sum(Convert(int,PadCount)) '+  
    ' FROM #REJECTS r ' +  
    + ' Join #PLIDList TPL on r.PU_ID = TPL.ConvUnit'      
    + ' Join #ShiftDESCList TSD on r.Shift = TSD.ShiftDESC'  
    + ' Join #CrewDESCList CSD on r.Crew = CSD.CrewDESC'  
    + ' Join #PLStatusDESCList TPLSD on r.LineStatus = TPLSD.PLStatusDESC'  
                +               ' Join #ac_Top5Rejects t on r.Reason1 = t.desc01 ' +  
                                ' WHERE r.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''  
  
   If @MinGroupValue <> 'ZZZ' and @RPTMinorGroupBy <> 'ProdDay'  
      Select @SQLString = @SQLString + ' and r.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
  
   Select @SQLString = @SQLString + ' Group By t.desc01'  
  
   TRUNCATE Table #TEMPORARY  
   Insert #TEMPORARY(TEMPValue1,TempValue2)  
   Execute (@SQLString)  
  
     
   Select @SQLString =     ' UPDATE #TOP5Rejects ' +  
             ' Set Value' + Convert(varchar,@i) + ' = Convert(varchar,t.TEMPValue2)' +  
                                                ' FROM #Top5Rejects tdt ' +  
                                                ' Join #Temporary t on tdt.desc01 = t.TempValue1 '  
  
  Select @SQLString = @SQLString + ' WHERE Sortorder > 3 '   
              
   Execute (@SQLString)  
                                                      
          Select @TEMPValue = Sum(Convert(float,TEMPValue2)) FROM #TEMPORARY   
  
          Select @SQLString =  'UPDATE #TOP5Rejects ' +  
           'Set Value' + Convert(varchar,@i) + ' = ''' + Convert(varchar,@TEMPValue) + '''' +  
           'WHERE SortOrder = 9'   
          Execute (@SQLString)  
         
                ----------------------------------------------------------------------------  
                -- POPULATE OUTPUT Tables: Some data For Summary #InvertedSummary  
                -- using an Inverted Table to help with the work.  will transpose later  
                ----------------------------------------------------------------------------  
  
 Select   
  @SumGroupBy   = 'Value' + Convert(Varchar(25),@i),   
     @SumLineStops   = Null,   
        @SumLineStopsERC    = Null,  
  @SumACPStops   = Null,  
  @SumDowntime   = Null,   
        @SumDowntimeERC     = Null,  
  @SumUptime       = Null,   
  @SumFalseStarts  = Null,  
  @SumTotalSplices  = Null,   
  @SumSUCSplices   = Null,   
  @SumTotalClass1  = Null,  
  @SumTotalPads   = Null,   
  @SumUptimeGreaterT  = Null,    
  @SumNumEdits   = Null,   
       @SumNumEditsR1      = Null,  
        @SumNumEditsR2      = Null,  
        @SumNumEditsR3      = Null,  
  @SumSurvivalRate = Null,   
  @SumGoodClass1   = Null,   
  @SumGoodPads  = Null,  
  @SumTotalCases   = Null  
  
  
 --***************************************************************************************************  
 -- FIRST STEP : CALCULATE ALL DEFINED VARIABLES  
 --***************************************************************************************************  
 -------------------------------------------------------------------------------------------------------------  
 -- ProdTime  
 -- Getting the SCHEDULED TIME -> @defScheduledTime  
 DECLARE   
    @STNUSQLString    NVARCHAR(4000)  
  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'ProdTime')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'ProdTime')  
  
 IF @RPTMinorGroupBy NOT IN ('Product')   
 BEGIN  
  IF @MinGroupValue <> 'ZZZ'  
            IF (@RPTMinorGroupBy = 'PU_ID' OR @RPTMajorGroupBy = 'PU_ID' )  
   BEGIN  
     -- ProdTime  
     Select @SQLString = 'Select Sum(SchedTime),Sum(SchedTime),' +  
                          ' mt.Pu_Id FROM #Production mt ' +  
        ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
        ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
        ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
        ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                          ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''   
     -- STNU  
     SELECT @STNUSQLString = @SQLString + ' AND mt.LineStatus Like ''' + '%STNU%' + ''''   
                 + ' GROUP BY mt.PU_Id'   
     -- ProdTime  
              SELECT @SQLString = @SQLString      +     ' Group by mt.pu_id'   
   END  
      ELSE  
   BEGIN  
     SELECT @SQLString = 'Select Sum(SchedTime),Sum(SchedTime),' +   
                          ' mt.pu_id' +   
        ' FROM #Production mt ' +  
        ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
        ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
        ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
        ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
        ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                          ' and mt.Class IN (' + @ClassList + ')'   
     -- STNU  
     SELECT @STNUSQLString = @SQLString + ' AND mt.LineStatus Like ''' + '%STNU%' + ''''   
                 + ' GROUP BY mt.PU_Id'   
     -- ProdTime  
              SELECT @SQLString = @SQLString     + ' Group by mt.pu_id'   
  
   END  
  ELSE  
      IF @RPTMajorGroupBy = 'PU_ID'  
   BEGIN   
     SELECT @SQLString = 'Select Sum(SchedTime),Sum(SchedTime),' +  
                          ' mt.Pu_Id FROM #Production mt ' +  
        ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
        ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
        ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
        ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''   
     -- STNU  
     SELECT @STNUSQLString = @SQLString + ' AND mt.LineStatus Like ''' + '%STNU%' + ''''   
                 + ' GROUP BY mt.PU_Id'   
     -- ProdTime  
              SELECT @SQLString = @SQLString     + ' Group by mt.pu_id'   
  
   END  
      ELSE  
   BEGIN  
     SELECT @SQLString = 'Select Sum(SchedTime),Sum(SchedTime), ' +  
        ' mt.pu_id ' +   
        ' FROM #Production mt ' +  
        ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
        ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
        ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
        ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
        ' and mt.Class IN (' + @ClassList + ')'   
     -- STNU  
     SELECT @STNUSQLString = @SQLString + ' AND mt.LineStatus Like ''' + '%STNU%' + ''''   
                 + ' GROUP BY mt.PU_Id'   
     -- ProdTime  
              SELECT @SQLString = @SQLString     + ' Group by mt.pu_id'   
  
   END  
 END  
 ELSE  
 BEGIN  
  -- GROUPING BY PRODUCT  
  IF @MinGroupValue <> 'ZZZ'   
                        -- ACA PREGUNTAR POR MAJOR = PU_ID  
                        IF (@RPTMajorGroupBy  = 'PU_ID' or @RPTMinorGroupBy = 'PU_ID')  
      BEGIN  
                           SELECT @SQLString = 'Select Sum(SchedTime),Sum(SchedTime),' +   
                                   ' mt.pu_id ' +  
                                   ' FROM #Production mt ' +  
           ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
           ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
           ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
           ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +   
           ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''   
         -- STNU  
         SELECT @STNUSQLString = @SQLString + ' AND mt.LineStatus Like ''' + '%STNU%' + ''''   
                     + ' GROUP BY mt.PU_Id'   
         -- ProdTime  
                  SELECT @SQLString = @SQLString     + ' Group by mt.pu_id'   
  
      END  
  
      ELSE  
      BEGIN  
               SELECT  @SQLString = 'Select Sum(SchedTime),Sum(SchedTime),' +   
                                   ' mt.pu_id ' +  
                                   ' FROM #Production mt ' +  
           ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
           ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
           ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
           ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +   
           ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                                   ' and mt.Class IN (' + @ClassList + ')'   
  
         -- STNU  
         SELECT @STNUSQLString = @SQLString + ' AND mt.LineStatus Like ''' + '%STNU%' + ''''   
                     + ' GROUP BY mt.PU_Id'   
         -- ProdTime  
                  SELECT @SQLString = @SQLString     + ' Group by mt.pu_id'   
                                   -- ' Group By mt.pu_id '   
      END  
  ELSE  
                    IF  @RPTMajorGroupBy = 'PU_ID'  
     BEGIN  
        -- ProdTime  
                                SELECT @SQLString = 'Select Sum(SchedTime),Sum(SchedTime),'+  
                                ' mt.pu_id ' +   
                                ' FROM #Production mt ' +  
                       ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
                       ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
                       ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
                       ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''   
        -- STNU  
        SELECT @STNUSQLString = @SQLString + ' AND mt.LineStatus Like ''' + '%STNU%' + ''''   
                     + ' GROUP BY mt.PU_Id'   
        -- ProdTime  
              SELECT @SQLString = @SQLString     + ' Group by mt.pu_id'                                   
     END  
                    ELSE  
     BEGIN  
        -- ProdTime  
                       SELECT @SQLString = 'Select Sum(SchedTime),Sum(SchedTime),'+  
                                ' mt.pu_id ' +   
                                ' FROM #Production mt ' +  
                       ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
                       ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
                       ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
                       ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                                ' and mt.Class IN (' + @ClassList + ')'   
        -- STNU  
        SELECT @STNUSQLString = @SQLString + ' AND mt.LineStatus Like ''' + '%STNU%' + ''''   
                     + ' GROUP BY mt.PU_Id'   
        -- ProdTime  
              SELECT @SQLString = @SQLString     + ' Group by mt.pu_id'                                   
  
     END  
 END  
  
 -- print 'ProdTime -> ' + @SQLString  
 -- print 'STNU ->' + @STNUSQLString  
 --------------------------------------------------------------------------------------------------------------------------------  
 -- PRODUCTION TIME CALCULATION   
 --------------------------------------------------------------------------------------------------------------------------------  
 Truncate Table #Temporary  
 Insert #Temporary(TEMPValue1,TempValue2,TempValue3)  
 Execute (@SQLString)  
          
        -- Select @RPTMajorGroupBy,@RPTMinorGroupBy,TempValue1,TempValue2,TempValue3 FROM #Temporary  
  
        Declare @cantUnits as int  
  
        set @cantUnits = (select distinct count(TempValue3) FROM #Temporary)  
  
        If @MinGroupValue = 'ZZZ'  
        Begin  
          Select @Scheduled_Time = Sum(convert(float,TempValue1))/60 FROM #Temporary  
                Select @Scheduled_Time = @Scheduled_Time / @cantUnits  
        End  
        Else  
               Select @Scheduled_Time = Avg(convert(float,TempValue1))/60 FROM #Temporary   
  
        Select @TotalScheduled_Time = Sum(convert(float,TempValue2)) FROM #Temporary   
  
 --------------------------------------------------------------------------------------------------------------------------------  
 -- STAFF TIME NOT USED CALCULATION   
 --------------------------------------------------------------------------------------------------------------------------------  
 TRUNCATE TABLE #Temporary  
 INSERT INTO #Temporary(TEMPValue1,TempValue2,TempValue3)  
 EXECUTE (@STNUSQLString)  
          
        SET @cantUnits = (SELECT DISTINCT COUNT(TempValue3) FROM #Temporary)  
  
        IF @MinGroupValue = 'ZZZ'  
        BEGIN  
          SELECT @STNU = SUM(CONVERT(FLOAT,TempValue1))/60 FROM #Temporary  
                SELECT @STNU = @STNU / @cantUnits  
        END  
        ELSE  
                SELECT @STNU = AVG(CONVERT(FLOAT,TempValue1))/60 FROM #Temporary   
  
        Select @TotalSTNU = SUM(CONVERT(FLOAT,TempValue2)) FROM #Temporary   
  
 -------------------------------------------------------------------------------------------------------------  
 -------------------------------------------------------------------------------------------------------------  
 -- TotalSplices, SucSplices  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'TotalSplices')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'TotalSplices')  
    
 If @MinGroupValue <> 'ZZZ'  
  Select @SQLString = 'Select Sum(nrecords), Sum(SpliceStatus) '+  
  'FROM #Splices mt ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
 Else   
   Select @SQLString = 'Select '+ @Operator + '(nrecords), '+ @Operator + '(SpliceStatus) '+  
   'FROM #Splices mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' -- +   
     
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1, TempValue2)  
 Execute (@SQLString)  
   
 Select @SumTotalSplices = TempValue1, @SumSUCSplices = TempValue2  
 FROM #Temporary  
 -- TotalSplices, SucSplices  
 -------------------------------------------------------------------------------------------------------------  
 -------------------------------------------------------------------------------------------------------------  
 -- Downtime  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'Downtime')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'Downtime')  
    -- Altough the Operator could be 'AVG', will not apply when the report is Major Grouped by Unit  
    If @RPTMajorGroupBy = 'PU_ID'   
                        Set @Operator = 'SUM'  
        --  
 If @MinGroupValue <> 'ZZZ'  
                If (@RPTMinorGroupBy = 'PU_ID' or @RPTMajorGroupBy = 'PU_ID')  
                  Select @SQLString = 'Select SUM(Duration), mt.pu_id' +  
                  ' FROM #Downtimes mt ' +  
                  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
                  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
                  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                        ' Group By mt.pu_id'  
                Else  
                        Select @SQLString = 'Select SUM(Duration), mt.pu_id ' +  
                  ' FROM #Downtimes mt ' +  
                  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
                  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
                  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                        ' and mt.Class IN (' + @ClassList + ')' +  
                        ' Group by mt.pu_id '   
 Else   
  If @RPTMajorGroupBy = 'PU_ID'  
   Select @SQLString = 'Select SUM(Duration), mt.' + @RPTMinorGroupBy +  
   ' FROM #Downtimes mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
            ' Group by mt.' + @RPTMinorGroupBy  
      Else  
   Select @SQLString = 'Select SUM(Duration), mt.pu_id ' +  
   ' FROM #Downtimes mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
   ' and mt.Class IN (' + @ClassList + ')' +  
                        ' Group by mt.pu_id '  
  
 -- Print 'Up, Down -> ' + @SQLString  
  
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1,TempValue2)  
 Execute (@SQLString)  
  
        -- Select @MajGroupValue,@MinGroupValue,@Operator,* FROM #Temporary  
  
       If @Operator = 'SUM'  
         Select  @SumDowntime = IsNull(Sum(Convert(float,TempValue1)),0) FROM #Temporary  
        Else  
            Select  @SumDowntime = IsNull(Avg(Convert(float,TempValue1)),0) FROM #Temporary  
  
 -- Downtime  
 -----------------------------------------------------------------------------------------------------------------  
 -------------------------------------------------------------------------------------------------------------  
 -- Uptime  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'Uptime')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'Uptime')  
    -- Altough the Operator could be 'AVG', will not apply when the report is Major Grouped by Unit  
    If @RPTMajorGroupBy = 'PU_ID'   
                        Set @Operator = 'SUM'  
        --  
 If @MinGroupValue <> 'ZZZ'  
                If (@RPTMinorGroupBy = 'PU_ID' or @RPTMajorGroupBy = 'PU_ID')  
                  Select @SQLString = 'Select Str(Sum(SchedTime),12,1), mt.pu_id' +  
                  ' FROM #Production mt ' +  
                  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
                  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
                  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                        ' Group By mt.pu_id'  
                Else  
                        Select @SQLString = 'Select Str(Sum(SchedTime),12,1), mt.pu_id ' +  
                  ' FROM #Production mt ' +  
                  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
                  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
                  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
      ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
      ' and mt.Class IN (' + @ClassList + ')' + ' Group by mt.pu_id '   
 Else   
  If @RPTMajorGroupBy = 'PU_ID'  
   Select @SQLString = 'Select Str(Sum(SchedTime),12,1), mt.' + @RPTMinorGroupBy +  
   ' FROM #Production mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
            ' Group by mt.' + @RPTMinorGroupBy  
      Else  
   Select @SQLString = 'Select Str(Sum(SchedTime),12,1), mt.pu_id ' +  
   ' FROM #Production mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
   ' and mt.Class IN (' + @ClassList + ')' +  
            ' Group by mt.pu_id '  
  
 -- Print 'Uptime -> ' + @SQLString  
  
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1,TempValue2)  
 Execute (@SQLString)  
  
        -- Select @MajGroupValue,@MinGroupValue,@Operator,* FROM #Temporary  
  
       If @Operator = 'SUM'  
         Select  @SumUptime = IsNull(Sum(Convert(float,TempValue1))/60,0) FROM #Temporary  
        Else  
            Select  @SumUptime = IsNull(Avg(Convert(float,TempValue1))/60,0) FROM #Temporary  
    
  Select @SumUptime = Str(Convert(Float,@SumUptime) - Convert(Float,@SumDowntime),12,1)    
  
 -- Uptime  
 -----------------------------------------------------------------------------------------------------------------  
     
    -------------------------------------------------------------------------------------------------------------  
 -- ERC Downtime  
 -- AND Planned Downtime  
 DECLARE @SQLStrPlanned     NVARCHAR(4000)  
   Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'Downtime')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'Downtime')  
    -- Altough the Operator could be 'AVG', will not apply when the report is Major Grouped by Unit  
    If @RPTMajorGroupBy = 'PU_ID'   
                        Set @Operator = 'SUM'  
        --  
 If @MinGroupValue <> 'ZZZ'  
                If (@RPTMinorGroupBy = 'PU_ID' or @RPTMajorGroupBy = 'PU_ID')  
                  Select @SQLString = 'Select SUM(Duration)' +  
                  ' FROM #Downtimes mt ' +  
                  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
                  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
                  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''   
                Else  
                        Select @SQLString = 'Select SUM(Duration)' +  
                  ' FROM #Downtimes mt ' +  
                  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
                  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
                  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                        ' and mt.Class IN (' + @ClassList + ')'   
         
 Else   
  If @RPTMajorGroupBy = 'PU_ID'  
   Select @SQLString = 'Select SUM(Duration) ' +  
   ' FROM #Downtimes mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''   
     Else  
   Select @SQLString = 'Select SUM(Duration) ' +  
   ' FROM #Downtimes mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
   ' and mt.Class IN (' + @ClassList + ')'   
  
 SET @SQLStrPlanned = @SQLString   
 SET @SQLStrPlanned = @SQLStrPlanned + ' AND Tree_Name LIKE ''' + @PlannedStopTreeName + '%'''  
 PRINT @SQLStrPlanned  
 -- Print 'Up, Down -> ' + @SQLString  
    Set @SQLString = @SQLString + ' and ERC_Desc IN (Select ERC_Desc FROM #ReasonsToExclude) '  
  
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1)  
 Execute (@SQLString)  
  
    Select @SumDowntimeERC = IsNull(Sum(Convert(float,TempValue1)),0) FROM #Temporary  
 Select @SumDowntimeERC = Convert(Float,@SumDowntime) - Convert(Float,@SumDowntimeERC)  
 -- ERC Downtime  
 -- Planned Downtime Duration  
 TRUNCATE TABLE #Temporary  
 INSERT INTO #Temporary (TempValue1)  
 EXECUTE (@SQLStrPlanned)  
  
 Select @SumPlannedStops = IsNull(Sum(Convert(float,TempValue1)),0) FROM #Temporary  
 -- Select @SumPlannedStops = Convert(Float,@SumDowntime) - Convert(Float,@SumPlannedStops)  
 -----------------------------------------------------------------------------------------------------------------  
  
  
  
    -----------------------------------------------------------------------------------------------------------------  
 -- LineStops, SuccessRate, RepairTimeT, FalseStarts0, FalseStartsT, NumEdits  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'LineStops')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'LineStops')  
  
 Select @SQLString = 'Select mt.' + @RPTMinorGroupBy + ',SUM(Case ' +     
      'When ISStops = 1 THEN 1 Else 0 ' +  
      'End),' + -- Line Stops  
  'SUM(Case ' + -- Survival Rate  
   'When SurvRateUptime > ' + Convert(VARCHAR(25),@RPTDowntimesurvivalRate) + ' Then 1 '+  
   'Else 0 ' +  
         'End), ' +  
  'SUM(Case ' +  -- Repair Time   
   'When ISStops = 1 and Duration > ' + Convert(VARCHAR(25),@RPTDowntimeFilterMinutes) +' Then 1 ' +  
   'Else 0 ' +  
      'End), ' +  
  'SUM(Case ' +   -- False Starts  
   'When ISStops = 1 and Uptime = 0 Then 1 ' +  
   'Else 0 '+  
      'End), ' +  
  'SUM(Case ' +   -- Uptime Greater T  
   'When ISStops = 1 and Uptime > ' + Convert(VARCHAR(25),@RPTFilterMinutes) + ' Then 1 '+  
   'Else 0 ' +  
      'End), '+  
  'SUM(Case ' +   -- Num Edits R4  
   'When ISStops = 1 and Reason4 IS NOT null Then 1 ' +  
   ' Else 0 ' +  
      'End), ' +    
        'SUM(Case ' +   -- Num Edits R1  
   'When ISStops = 1 and Reason1 IS NOT null Then 1 ' +  
   ' Else 0 ' +  
      'End), ' +    
        'SUM(Case ' +   -- Num Edits R2  
   'When ISStops = 1 and Reason2 IS NOT null Then 1 ' +  
   ' Else 0 ' +  
      'End), ' +    
        'SUM(Case ' +   -- Num Edits R3  
   'When ISStops = 1 and Reason3 IS NOT null Then 1 ' +  
   ' Else 0 ' +  
      'End), ' +    
  'SUM(Case ' +   -- False Starts T  
   'When ISStops = 1 and Uptime < ' + Convert(VARCHAR(25),@RPTFilterMinutes) + ' Then 1 '+  
   'Else 0 ' +  
         ' End) '+  
  ' FROM #Downtimes mt ' +  
  ' Join #PLIDList TPL on mt.PU_ID = TPL.ConvUnit ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC '   
  
 If @MinGroupValue <> 'ZZZ'  
                If (@RPTMajorGroupBy = 'PU_ID' or @RPTMinorGroupBy = 'PU_ID')  
                   Set @SQLString = @SQLString +   
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
                Else   
                         Set @SQLString = @SQLString +   
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                        ' and mt.Class IN (' + @ClassList + ')'  
 Else   
  If @RPTMajorGroupBy = 'PU_ID'   
    Set @SQLString = @SQLString +   
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''   
  Else  
   Set @SQLString = @SQLString +   
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
   ' and mt.Class IN (' + @ClassList + ')'  
  
 Set @SQLSTring = @SQLString + ' Group By mt.' + @RPTMinorGroupBy  
  
 -- print 'LineStops -> ' + @SQLString   
  
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1,TempValue2,TempValue3,TempValue4,TempValue5,TempValue6,  
                       TempValue7,TempValue8,TempValue9,TempValue10,TempValue11)  
 Execute (@SQLString)  
  
 If @Operator = 'SUM'  
    Select @SumLineStops = Sum(IsNull(Convert(Float,TempValue2),0)),  
    @SumSurvivalRate = Sum(IsNull(Convert(Float,TempValue3),0)),  
    @SumRepairTimeT = Sum(IsNull(Convert(Float,TempValue4),0)),  
    @SumFalseStarts = Sum(IsNull(Convert(Float,TempValue5),0)),  
    @SumUptimeGreaterT = Sum(IsNull(Convert(Float,TempValue6),0)),  
    @SumNumEdits = Sum(IsNull(Convert(Float,TempValue7),0)),  
    @SumNumEditsR1 = Sum(IsNull(Convert(Float,TempValue8),0)),  
    @SumNumEditsR2 = Sum(IsNull(Convert(Float,TempValue9),0)),  
    @SumNumEditsR3 = Sum(IsNull(Convert(Float,TempValue10),0)),  
    @SumFalseStartsT = Sum(IsNull(Convert(Float,TempValue11),0))  
    FROM #Temporary  
 Else  
     Select @SumLineStops = Avg(IsNull(Convert(Float,TempValue2),0)),  
    @SumSurvivalRate = Avg(IsNull(Convert(Float,TempValue3),0)),  
    @SumRepairTimeT = Avg(IsNull(Convert(Float,TempValue4),0)),  
    @SumFalseStarts = Avg(IsNull(Convert(Float,TempValue5),0)),  
    @SumUptimeGreaterT = Avg(IsNull(Convert(Float,TempValue6),0)),  
    @SumNumEdits = Avg(IsNull(Convert(Float,TempValue7),0)),  
    @SumNumEditsR1 = Avg(IsNull(Convert(Float,TempValue8),0)),  
    @SumNumEditsR2 = Avg(IsNull(Convert(Float,TempValue9),0)),  
    @SumNumEditsR3 = Avg(IsNull(Convert(Float,TempValue10),0)),  
    @SumFalseStartsT = Avg(IsNull(Convert(Float,TempValue11),0))  
    FROM #Temporary  
  
 -- LineStops, SurivalRate, RepairTimeT, FalseStarts0, FalseStartsT, NumEdits  
 -------------------------------------------------------------------------------------------------------------  
  
    -----------------------------------------------------------------------------------------------------------------  
 -- ERC LineStops  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'LineStops')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'LineStops')  
   
 Select @SQLString = 'Select mt.' + @RPTMinorGroupBy + ',SUM(Case ' +     
      'When ISStops = 1 THEN 1 Else 0 ' +  
      'End)' + -- Line Stops  
  ' FROM #Downtimes mt ' +  
  ' Join #PLIDList TPL on mt.PU_ID = TPL.ConvUnit ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC '   
  
 If @MinGroupValue <> 'ZZZ'  
                If (@RPTMajorGroupBy = 'PU_ID' or @RPTMinorGroupBy = 'PU_ID')  
                   Set @SQLString = @SQLString +   
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
                Else   
                         Set @SQLString = @SQLString +   
                  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                        ' and mt.Class IN (' + @ClassList + ')'  
 Else   
  If @RPTMajorGroupBy = 'PU_ID'   
    Set @SQLString = @SQLString +   
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''   
  Else  
   Set @SQLString = @SQLString +   
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
   ' and mt.Class IN (' + @ClassList + ')'  
  
   
    Set @SQLString = @SQLString + ' and ERC_Desc IN (Select ERC_Desc FROM #ReasonsToExclude) '  
 Set @SQLSTring = @SQLString + ' Group By mt.' + @RPTMinorGroupBy  
    -- print 'ERC LineStops -> ' + @SQLString   
  
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1,TempValue2)  
 Execute (@SQLString)  
   
 -- select * from #Temporary  
  
 If @Operator = 'SUM'  
  Select @SumLineStopsERC = ISNULL(Sum(Convert(Float,TempValue2)),0) FROM #Temporary   
 Else  
  Select @SumLineStopsERC = ISNULL(Avg(Convert(Float,TempValue2)),0) FROM #Temporary   
  
 Select @SumLineStopsERC = Convert(Float,@SumLineStops) - Convert(Float,@SumLineStopsERC)  
 -- LineStops, SurivalRate, RepairTimeT, FalseStarts0, FalseStartsT, NumEdits  
 -------------------------------------------------------------------------------------------------------------  
  
 -------------------------------------------------------------------------------------------------------------  
 -- ACP stops  
    Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'ACPStops')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'ACPStops')  
  
 Select @SQLString = 'Select '+ @Operator +'(convert(float,ISStops)) '+   
 ' FROM #Downtimes mt ' +  
 ' Join #PLIDList TPL on mt.PU_ID = tpl.convunit '  +   
    -- ' Join @Class c on mt.PU_ID = c.pu_id ' +  
 ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC ' +   
 ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC ' +  
 ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
 ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' + -- 1/13/03 JJR Added to account for Prod_Code vs. Prod_Desc  
    ' and mt.Class IN (' + @ClassList + ')'  
   
 If @MinGroupValue <> 'ZZZ'  
  Select @SQLString = @SQLString + ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
  
  
 TRUNCATE Table #Temporary  
 Insert #Temporary (TempValue1)  
 Execute (@SQLString)  
  
    -- print 'ACPStops ' + @SQLString  
  
 Select @SumACPStops = TempValue1 FROM #Temporary  
 Select @SumACPStopsPerDay = (Convert(Float,@SumACPStops) / (convert(float,@Scheduled_Time) / 1440)) --(Convert(Float,@SumUptime) + Convert(Float,@SumDowntime))  
 -- ACP stops  
 -------------------------------------------------------------------------------------------------------------  
 -------------------------------------------------------------------------------------------------------------  
 -- TotalProduct  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'TotalPads')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'TotalPads')  
  
 If @MinGroupValue <> 'ZZZ'  
          If @RPTMajorGroupBy = 'PU_ID' or @RPTMinorGroupBy = 'PU_ID'  
  Select @SQLString = 'Select Convert(INTEGER,Sum(TotalPad * ConvFactor ))' +  
              ' FROM #Production mt ' +    
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''   
    Else  
  Select @SQLString = 'Select Convert(INTEGER,Sum(TotalPad * ConvFactor )) ' +               
  ' FROM #Production mt ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
  ' and mt.Class IN (' + @ClassList + ')'  
 Else  
    If @RPTMajorGroupBy = 'PU_ID'  
       Select @SQLString = 'Select Convert(INTEGER,Sum(TotalPad * ConvFactor)) ' +  
            ' FROM #Production mt ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''   
     Else   
  Select @SQLString = 'Select Convert(INTEGER,'+ @Operator +'(TotalPad * ConvFactor)) ' +           
  ' FROM #Production mt ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
  ' and mt.Class IN (' + @ClassList + ')'  
   
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1)  
 Execute (@SQLString)  
  
 Select @SumTotalPads = TempValue1  FROM #Temporary  
 -- TotalProduct  
 -------------------------------------------------------------------------------------------------------------  
 -------------------------------------------------------------------------------------------------------------  
 -- GoodProduct  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'GoodPads')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'GoodPads')  
   
 If @MinGroupValue <> 'ZZZ'   
          If @RPTMajorGroupBy = 'PU_ID' Or @RPTMinorGroupBy = 'PU_ID'  
  Select @SQLString = 'Select  Sum( ' +  
  ' Convert(INTEGER,(TotalPad * ConvFactor) - isnull(RunningScrap * ConvFactor,0) - isnull(Stopscrap * ConvFactor,0)) ' +  
  ' ),' +  
                ' Sum(Case ProdPerStat WHEN 0 THEN 0 ' +  
  '  ELSE  ' +            
           ' (IsNull(TotalPad * ConvFactor ,0) - IsNull(RunningScrap * ConvFactor,0) - IsNull(Stopscrap * ConvFactor,0)) / ProdPerStat / 1000  ' +                       
         ' END),' +  
                ' SUM(Convert(INTEGER,(TotalPad)-IsNull(RunningScrap,0)-IsNull(Stopscrap,0)-IsNull(ConvFactor * TotalCases,0)))' +  
  ' FROM #Production mt ' +  
                ' Join #PLIDList PL on PL.ConvUnit = mt.PU_Id ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''   
    Else  
  Select @SQLString = 'Select Sum( ' +  
   'Convert(INTEGER,(TotalPad * ConvFactor) - isnull(RunningScrap * ConvFactor,0) - isnull(Stopscrap * ConvFactor,0)) ' +  
   '),' +  
                ' Sum(CASE ProdPerStat WHEN 0 THEN 0 ' +  
  '  ELSE  ' +  
          ' (IsNull(TotalPad * ConvFactor ,0) - IsNull(RunningScrap * ConvFactor,0) - IsNull(Stopscrap * ConvFactor,0)) / ProdPerStat / 1000  ' +                      
         ' END),' +  
                ' SUM(Convert(INTEGER,(TotalPad)-IsNull(RunningScrap,0)-IsNull(Stopscrap,0)-IsNull(ConvFactor*TotalCases,0)))' +  
  ' FROM #Production mt ' +  
                ' Join #PLIDList PL on PL.ConvUnit = mt.PU_Id ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
  ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
  ' and mt.Class IN (' + @ClassList + ')'  
 Else  
    If @RPTMajorGroupBy = 'PU_ID' -- or @RPTMinorGroupBy = 'PU_ID'  
       Select @SQLString = 'Select Sum( ' +  
   ' Convert(INTEGER,(TotalPad * ConvFactor) - isnull(RunningScrap * ConvFactor,0) - isnull(Stopscrap * ConvFactor,0)) '+  
   '),' +  
                ' Sum(Case ProdPerStat WHEN 0 THEN 0 ' +  
  '  ELSE  ' +  
          ' (IsNull(TotalPad * ConvFactor ,0) - IsNull(RunningScrap * ConvFactor,0) - IsNull(Stopscrap * ConvFactor,0)) / ProdPerStat / 1000  ' +                   
          ' END),' +  
                ' Sum(Convert(INTEGER,(TotalPad)-IsNull(RunningScrap,0)-IsNull(Stopscrap,0)- IsNull(ConvFactor*TotalCases,0)))' +  
  ' FROM #Production mt ' +  
                ' Join #PLIDList PL on PL.ConvUnit = mt.PU_Id ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''   
     Else   
  Select @SQLString = 'Select ' + @Operator + '( ' +  
   ' Convert(INTEGER,(TotalPad * ConvFactor) - isnull(RunningScrap * ConvFactor,0) - isnull(Stopscrap * ConvFactor,0)) '+  
   ' ),' +  
                ' Sum(Case ProdPerStat WHEN 0 THEN 0 ' +  
  '  ELSE  ' +  
          ' (IsNull(TotalPad * ConvFactor ,0) - IsNull(RunningScrap * ConvFactor,0) - IsNull(Stopscrap * ConvFactor,0)) / ProdPerStat / 1000  ' +                      
          ' END),' +  
                ' Sum(Convert(INTEGER,(TotalPad)-IsNull(RunningScrap,0)-IsNull(Stopscrap,0)-IsNull(ConvFactor * TotalCases,0)))' +  
  ' FROM #Production mt ' +  
                ' Join #PLIDList PL on PL.ConvUnit = mt.PU_Id ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
  ' and mt.Class IN (' + @ClassList + ')'  
  
  
 -- Print 'Good Product ->' + @SQLString  
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1,TempValue2,TempValue3)  
 Execute (@SQLString)  
  
 Select @SumGoodPads = TempValue1, @SumMSU = STR(TempValue2,6,2) FROM #Temporary  
 -- GoodProduct  
 -------------------------------------------------------------------------------------------------------------  
 -------------------------------------------------------------------------------------------------------------  
 -- TotalScrap, RunningScrap, DowntimeScrap  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'TotalScrap')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'TotalScrap')   
  
 If @MinGroupValue <> 'ZZZ'  
             If (@RPTMinorGroupBy = 'PU_ID' or @RPTMajorGroupBy = 'PU_ID')  
          Select @SQLString = 'Select Sum(RunningScrap * ConvFactor), Sum(Stopscrap * ConvFactor) ' +  
          ' FROM #Production mt ' +  
          ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
          ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
          ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
          ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
          ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
              Else  
                        Select @SQLString = 'Select Sum(RunningScrap * ConvFactor), Sum(Stopscrap * ConvFactor) ' +  
          ' FROM #Production mt ' +  
          ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
          ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
          ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
          ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
          ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                        ' and mt.Class IN (' + @ClassList+ ')'  
 Else  
     If (@RPTMajorGroupBy = 'PU_ID')  
  Select @SQLString = 'Select Sum(RunningScrap * ConvFactor), Sum(Stopscrap * ConvFactor) ' +  
  ' FROM #Production mt ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''   
     Else  
  Select @SQLString = 'Select Sum(RunningScrap * ConvFactor), Sum(Stopscrap * ConvFactor) ' +  
  ' FROM #Production mt ' +  
  ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
  ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
  ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
  ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +    
  ' and mt.Class IN (' + @ClassList+ ')'   
  
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1, TempValue2)  
 Execute (@SQLString)  
  
        -- Select * FROM #Temporary  
  
 Select @SumRunningScrap = TEMPValue1, @SumDowntimeScrap = TEMPValue2 FROM #Temporary  
  
    Set @SumTotalScrap = Convert(Float,IsNull(@SumRunningScrap,0)) + Convert(Float,IsNull(@SumDowntimeScrap,0))  
  
 -- RejectedProduct, RunningScrap, StarttingScrap  
    -- Set @SumArea4LossPer = convert(float,@SumTotalPads) - convert(float,@SumRunningScrap) - convert(float,@SumDowntimeScrap) - convert(float,@SumGoodPads)  
 -------------------------------------------------------------------------------------------------------------  
 -------------------------------------------------------------------------------------------------------------  
 -- TargetSpeed,IdealSpeed  
 Set @Operator = (Select Operator FROM #Equations WHERE Variable = 'TargetSpeed')  
 Set @ClassList = (Select Class FROM #Equations WHERE Variable = 'TargetSpeed')   
 Set @Operator = 'SUM'  
 If @MinGroupValue <> 'ZZZ'  
              If @RPTMinorGroupBy = 'PU_ID' or @RPTMajorGroupBy = 'PU_ID'   
              -- If Major or Minor is a Unit then Class will not apply  
   Select @SQLString = 'Select Convert(Float, SUM(LineSpeedTar * Convert(float,datediff(mi,StartTime,EndTime))) / (SUM(Convert(float,datediff(ss,StartTime,EndTime)))/60)), ' +  
   'Convert(Float, SUM(IdealSpeed * Convert(float,datediff(mi,StartTime,EndTime))) / (SUM(Convert(float,datediff(ss,StartTime,EndTime)))/60)), ' +  
   ' mt.PU_id ' +  
   ' FROM #Production mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
                        ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                        ' Group by mt.pu_id '   
               Else  
          Select @SQLString = 'Select Convert(Float, SUM(LineSpeedTar * Convert(float,datediff(mi,StartTime,EndTime))) / (SUM(Convert(float,datediff(ss,StartTime,EndTime)))/60)), ' +  
    ' Convert(Float, SUM(IdealSpeed * Convert(float,datediff(mi,StartTime,EndTime))) / (SUM(Convert(float,datediff(ss,StartTime,EndTime)))/60)), ' +  
          ' mt.PU_id ' +  
          ' FROM #Production mt ' +  
          ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
          ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
          ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
          ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
          ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + '''' +  
                        ' and mt.Class IN (' + @ClassList+ ')' +  
                        ' Group by mt.pu_id'  
 Else  
  
  If @RPTMajorGroupBy = 'PU_ID'   
   Select @SQLString = 'Select Convert(Float, SUM(LineSpeedTar * Convert(float,datediff(mi,StartTime,EndTime))) / (SUM(Convert(float,datediff(ss,StartTime,EndTime)))/60)), ' +  
   ' Convert(Float, SUM(IdealSpeed * Convert(float,datediff(mi,StartTime,EndTime))) / (SUM(Convert(float,datediff(ss,StartTime,EndTime)))/60)), ' +  
   ' mt.PU_id ' +  
   ' FROM #Production mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
            ' Group by mt.pu_id'  
  Else  
   Select @SQLString = 'Select Convert(Float, SUM(LineSpeedTar * Convert(float,datediff(mi,StartTime,EndTime))) / (SUM(Convert(float,datediff(ss,StartTime,EndTime)))/60)), ' +  
   ' Convert(Float, SUM(IdealSpeed * Convert(float,datediff(mi,StartTime,EndTime))) / (SUM(Convert(float,datediff(ss,StartTime,EndTime)))/60)), ' +  
            ' mt.PU_id ' +  
   ' FROM #Production mt ' +  
   ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
   ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
   ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
   ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + '''' +  
   ' and mt.Class IN (' + @ClassList+ ')' +                       
            ' Group by mt.pu_id'  
  
 Truncate Table #Temporary  
 Insert #Temporary (TempValue1,TempValue2,TempValue3)  
 Execute (@SQLString)  
  
 -- print 'TargetSpeed '+ @SQLString  
  
    If @Operator = 'SUM'  
                        Select @Sumtargetspeed = Sum(Convert(float,TempValue1)) FROM #Temporary   
    Else  
                        Select @Sumtargetspeed = Avg(Convert(float,TempValue1)) FROM #Temporary  
  
  -- Ideal Speed works tied to Target Speed  
 If @Operator = 'SUM'  
                        Select @SumIdealSpeed = Sum(Convert(float,TempValue2)) FROM #Temporary   
    Else  
                        Select @SumIdealSpeed = Avg(Convert(float,TempValue2)) FROM #Temporary  
        -- TargetSpeed  
 -------------------------------------------------------------------------------------------------------------  
  
 -------------------------------------------------------------------------------------------------------------   
 -- TotalCase          
 Select @SQLString = 'Select ' +    
 ' Convert(Float,Sum(TotalCases)) ' +  
 ' FROM #Production mt ' +  
 ' Join #ShiftDESCList TSD on mt.Shift = TSD.ShiftDESC' +   
 ' Join #CrewDESCList CSD on mt.Crew = CSD.CrewDESC' +  
 ' Join #PLStatusDESCList TPLSD on mt.LineStatus = TPLSD.PLStatusDESC ' +  
 ' WHERE mt.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''    
 --  
 If @MinGroupValue <> 'ZZZ'  
  Select @SQLString =   
                        @SQLString + ' and mt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''   
    --                    
 Truncate Table #Temporary  
  
 Insert #Temporary (TempValue1)  
 Execute (@SQLString)  
  
 Select @SumTotalCases=TempValue1 FROM #Temporary  
 -- TotalCase  
 -------------------------------------------------------------------------------------------------------------   
          
 Select @SQLString = 'Select sum(convert(float,flex1)), sum(convert(float,flex2)), sum(convert(float,flex3)),' +  
 'sum(convert(float,flex4)), sum(convert(float,flex5)), sum(convert(float,flex6)),' +  
 'sum(convert(float,flex7)), sum(convert(float,flex8)), sum(convert(float,flex9)), sum(convert(float,flex10)) ' +  
 'FROM #Production TP ' +  
 'Join #CrewDESCList TCDL on TP.Crew = TCDL.CrewDESC ' +  
 'Join #ShiftDESCList TSDL on TP.Shift = TSDL.ShiftDESC ' +  
 'Join #PLStatusDESCList TPLSL on TP.LineStatus = TPLSL.PLStatusDESC ' +  
 'WHERE TP.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''   
  
 If @MinGroupValue <> 'ZZZ'  
  Select @SQLString = @SQLString + ' and ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
  
  
 TRUNCATE Table #Temporary  
 Insert #Temporary  
 (TempValue1, TempValue2, TempValue3, TempValue4, TempValue5, TempValue6, TempValue7, TempValue8, TempValue9, TempValue10)  
 Execute (@SQLString)  
  
 Select  @Flex1 = TEMPValue1,  @Flex2 = TEMPValue2, @Flex3 = TEMPValue3, @Flex4 = TEMPValue4,  
 @Flex5 = TEMPValue5, @Flex6 = TEMPValue6, @Flex7 = TEMPValue7, @Flex8 = TEMPValue8, @Flex9 = TEMPValue9,  
 @Flex10 = TEMPValue10 FROM #Temporary  
  
          
-- *************************************************************************************************************  
-- Only need to insert at the Inverted Summary THE DEFINED VARIABLES, others as they are Math will be calculated  
-- in the next Stpep  
--**************************************************************************************************************  
  
   Insert #InvertedSummary  
       ( GroupBy,   
        ColType,  
        TotalSplices,   
        SUCSplices,   
        RunningScrap,  
        Downtimescrap,   
        TotalPads,   
        GoodPads,   
        MSU,   
        Area4LossPer,  
        TotalScrap,  
        LineStops,  
        LineStopsERC,   
        RepairTimeT,   
        Downtime,   
        DowntimeERC,  
        DowntimePlannedStops,  
           Uptime,   
        FalseStarts,   
        UptimeGreaterT,   
        FalseStartsT,  
        SurvivalRate,   
        ACPStops,   
        NumEdits,  
        NumEditsR1,  
        NumEditsR2,  
        NumEditsR3,  
           CaseCount,  
        Flex1, Flex2, Flex3, Flex4, Flex5, Flex6, Flex7, Flex8, Flex9, Flex10,   
        ACPStopsPerDay,   
        StopsPerDay,  
        ProdTime,          
        TotalProdTime,  
        STNU   ,  
        CalendarTime,   
        TargetSpeed,  
        IdealSpeed,  
        Class)  
   Values   ( @SumGroupBy,  
        @MinGroupValue,   
        CASE WHEN @SumTotalSplices = '0' THEN NULL   
          ELSE @SumTotalSplices END,  
              @SumSUCSplices,    
        ISNULL(@SumRunningScrap,0),  
        ISNULL(@SumDowntimescrap,0),   
        STR(CONVERT(float,@SumTotalPads),12,0),   
        STR(CONVERT(float,@SumGoodPads),12,0),   
        @SumMSU,  
           CASE When @SumArea4LossPer = '0' THEN NULL   
          ELSE @SumArea4LossPer END,  
        STR(@SumTotalScrap,12,0),  
        @SumLineStops,   
        @SumLineStopsERC,  
        @SumRepairTimeT,   
        STR(@SumDowntime,9,1),   
        STR(@SumDowntimeERC,9,1),   
        STR(@SumPlannedStops,9,1),   
              STR(@SumUptime,9,1),   
              @SumFalseStarts,  
        ISNULL(@SumUptimeGreaterT,0),  
        @SumFalseStartsT,   
        @SumSurvivalRate,   
        @SumACPStops,   
        @SumNumEdits,  
        @SumNumEditsR1,  
        @SumNumEditsR2,  
        @SumNumEditsR3,  
        @SumTotalCases,  
        @Flex1, @Flex2, @Flex3, @Flex4, @Flex5, @Flex6, @Flex7, @Flex8, @Flex9, @Flex10,   
        @sumACPStopsPerDay,   
        Str(@sumStopsPerDay,9,1),  
        @Scheduled_time  ,  
        @TotalScheduled_Time,   
        @STNU   ,  
        @Scheduled_Time  ,  
        @SumTargetspeed  ,  
        @SumIdealSpeed  ,  
        @Active_Class)  
  
  
    
  Declare @lastinsertion as int  
  
  Select @lastinsertion = @@Identity  
  
 -------------------------------------------------------------------------------------------------------------   
 -- UPDATE TotalClassProducts, GoodClassProducts  
 Set @ClassCounter = 1   
   
 While @ClassCounter <= (Select Max(Class) FROM @Class)  
  
  Begin     
     
   Select @SQLString =   
   'Select Sum((IsNull(TotalPad * ConvFactor ,0)) - (IsNull(StopScrap * ConvFactor,0)) - (IsNull(RunningScrap * ConvFactor,0))) , ' +   
   'Sum(IsNull(TotalPad * ConvFactor,0)) ' +  
   'FROM #Production TP ' +  
   'Join #CrewDESCList TCDL on TP.Crew = TCDL.CrewDESC ' +  
   'Join #ShiftDESCList TSDL on TP.Shift = TSDL.ShiftDESC ' +  
            'Join #PLStatusDESCList TPLSD on tp.LineStatus = TPLSD.PLStatusDESC ' +  
   'WHERE Tp.class = ' + Convert(varchar,@ClassCounter)+' and TP.' + @RPTMajorGroupBy + ' = ''' + @MajGroupValue + ''''  
   
   If @MinGroupValue <> 'ZZZ'  
    Select @SQLString = @SQLString + ' And TP.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''  
   
   TRUNCATE Table #Temporary  
   
   Insert #Temporary (TEMPValue1,TEMPValue2)  
   Execute (@SQLString)  
     
   -- Print 'Conversion Class : ' + @SQLString  
                        --Select @ClassCounter,@MajGroupValue,@MinGroupValue,* FROM #Temporary  
  
   Select  @SumGoodClass1 = Str(TEMPValue1,15,0),@SumTotalClass1 = Str(TEMPValue2,15,0) FROM #Temporary  
     
   Set @SQLString = 'UPDATE #InvertedSummary ' +   
    ' Set TotalClass' + Convert(varchar,@ClassCounter) + ' = ''' + @SumTotalClass1 + '''' +  
    ',GoodClass' + Convert(varchar,@ClassCounter) + '= ''' +  @SumGoodClass1 + '''' +  
    ' WHERE id = ' + Convert(varchar,@LastInsertion)  
     
           
   Exec(@SQLString)  
            --            Print 'UPDATEr ' + @SQLString  
   Set @ClassCounter = @ClassCounter + 1  
    
  End   
  
  -- UPDATE TotalClassProducts, GoodClassProducts  
  -------------------------------------------------------------------------------------------------------------   
   
  -- *************************************************************************************************************  
  -- Only need to insert at the Inverted Summary THE DEFINED VARIABLES, others as they are Math will be calculated  
  -- in the next Stpep  
  --**************************************************************************************************************  
  --  
  Select @i = @i + 1    
  
  FETCH NEXT FROM RSMiCursor into @MajGroupValue, @MajGroupDesc,@MajOrderby,@MinGroupValue, @MinGroupDesc,@MinOrderby  
  END  
  
  Close RSMiCursor  
  Deallocate RSMiCursor  
  
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
-- FRio : NOTE , END of cursor for filling #TEMPORARY TABLES  
-- Print convert(varchar(25), getdate(), 120) + 'OUT OF THE CURSOR !!'  
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  
--> AHORA DESDE ACA LOS CALCULOS DEL AGGREGATE  
----------------------------------------------------------------------------------------------------------------  
-- POPULATE OUTPUT Tables: Some Totals data For #InvertedSummary  
----------------------------------------------------------------------------------------------------------------  
-- First insertion for Aggregate Values with variables that are the SUM FROM Partial Values (No special Math or no Def.)  
-- Select LineStops,TotalProdTime,Downtime,Uptime,TotalPads,DowntimeScrap,* FROM #InvertedSummary  
  
UPDATE #InvertedSummary   
        Set StopsPerDay = (Case When Convert(Float,Uptime)+Convert(Float,Downtime) < 1440 Then LineStops  
                                Else Convert(Float,LineStops) * 1440 / (Convert(Float,Uptime)+Convert(Float,Downtime))End),  
            ACPStopsPerDay = (Case When Convert(Float,Uptime)+Convert(Float,Downtime) < 1440 Then ACPStops  
                                Else Convert(Float,ACPStops) * 1440 / (Convert(Float,Uptime)+Convert(Float,Downtime))End)  
  
Insert #InvertedSummary  
(GroupBy, CaseCount,TotalUptime,TotalDowntime,UptimeGreaterT,--Area4LossPer,-- MSU,  
ACPStops,  
Flex1, Flex2, Flex3, Flex4, Flex5, Flex6, Flex7, Flex8, Flex9, Flex10,  
TotalClass1, TotalClass2, TotalClass3, TotalClass4, TotalClass5, TotalClass6, TotalClass7, TotalClass8, TotalClass9, TotalClass10, TotalClass11, TotalClass12, TotalClass13, TotalClass14, TotalClass15,TotalClass16, TotalClass17, TotalClass18,TotalClass19,
 TotalClass20,  
GoodClass1, GoodClass2, GoodClass3, GoodClass4, GoodClass5, GoodClass6, GoodClass7, GoodClass8, GoodClass9, GoodClass10, GoodClass11, GoodClass12, GoodClass13, GoodClass14, GoodClass15, GoodClass16, GoodClass17, GoodClass18, GoodClass19, GoodClass20)  
  
Select 'AGGREGATE',   
STR(SUM(CONVERT(FLOAT,CaseCount)),15,0),  
STR(SUM(CONVERT(float,Uptime)),15,1),  
STR(SUM(convert(float,Downtime)),15,1),  
STR(SUM(CONVERT(FLOAT,UptimeGreaterT)),15,1),  
--sum(convert(float,Area4LossPer)),  
--sum(convert(float,MSU)),  
STR(SUM(CONVERT(FLOAT,ACPStops)),15,0),  
sum(convert(float,Flex1)),   
sum(convert(float,Flex2)),   
sum(convert(float,Flex3)),   
sum(convert(float,Flex4)),   
sum(convert(float,Flex5)),  
sum(convert(float,Flex6)),   
sum(convert(float,Flex7)),   
sum(convert(float,Flex8)),   
sum(convert(float,Flex9)),   
sum(convert(float,Flex10)),  
str(sum(convert(float,isnull(TotalClass1,0))),15,0),   
str(sum(convert(float,isnull(TotalClass2,0))),15,0),   
str(sum(convert(float,isnull(TotalClass3,0))),15,0),   
str(sum(convert(float,isnull(totalClass4,0))),15,0),   
str(sum(convert(float,isnull(TotalClass5,0))),15,0),   
str(sum(convert(float,isnull(TotalClass6,0))),15,0),   
str(sum(convert(float,isnull(totalClass7,0))),15,0),   
str(sum(convert(float,isnull(TotalClass8,0))),15,0),   
str(sum(convert(float,isnull(TotalClass9,0))),15,0),   
str(sum(convert(float,isnull(TotalClass10,0))),15,0),   
str(sum(convert(float,isnull(TotalClass11,0))),15,0),   
str(sum(convert(float,isnull(TotalClass12,0))),15,0),   
str(sum(convert(float,isnull(totalClass13,0))),15,0),   
str(sum(convert(float,isnull(TotalClass14,0))),15,0),   
str(sum(convert(float,isnull(TotalClass15,0))),15,0),   
str(sum(convert(float,isnull(TotalClass16,0))),15,0),   
str(sum(convert(float,isnull(TotalClass17,0))),15,0),   
str(sum(convert(float,isnull(TotalClass18,0))),15,0),   
str(sum(convert(float,isnull(totalClass19,0))),15,0),   
str(sum(convert(float,isnull(TotalClass20,0))),15,0),   
str(sum(convert(float,GoodClass1)),15,0),   
str(sum(convert(float,GoodClass2)),15,0),   
str(sum(convert(float,GoodClass3)),15,0),  
str(sum(convert(float,GoodClass4)),15,0),   
str(sum(convert(float,GoodClass5)),15,0),   
str(sum(convert(float,GoodClass6)),15,0),  
str(sum(convert(float,GoodClass7)),15,0),   
str(sum(convert(float,GoodClass8)),15,0),   
str(sum(convert(float,GoodClass9)),15,0),  
str(sum(convert(float,GoodClass10)),15,0),   
str(sum(convert(float,GoodClass11)),15,0),   
str(sum(convert(float,GoodClass12)),15,0),  
str(sum(convert(float,GoodClass13)),15,0),   
str(sum(convert(float,GoodClass14)),15,0),   
str(sum(convert(float,GoodClass15)),15,0),  
str(sum(convert(float,GoodClass16)),15,0),   
str(sum(convert(float,GoodClass17)),15,0),   
str(sum(convert(float,GoodClass18)),15,0),  
str(sum(convert(float,GoodClass19)),15,0),   
str(sum(convert(float,GoodClass20)),15,0)  
FROM #InvertedSummary  
WHERE ColType = 'ZZZ'  
----------------------------------------------------------------------------  
-- CALCULATE 'DEFINED' VARIABLES FIRST  
--Print convert(varchar(25), getdate(), 120) + 'CALCULATING EQUATIONS'  
----------------------------------------------------------------------------  
-- Select * FROM #InvertedSummary  
-- Select * From #Equations  
  
Declare @eq_id as int  
  
Select @eq_id = Min(eq_id) FROM #Equations  
  
While @eq_id Is Not NULL  
Begin  
      
    Select @Variable = Variable, @Operator = Operator, @ClassList = Class , @Prec = Prec FROM #Equations WHERE eq_id = @eq_id  
  
    If @RPTMajorGroupBy = 'PU_ID' -- Or @RptMinorGroupBy = 'PU_ID'  
    Begin  
        --If (@Variable = 'ProdTime')  
   --                Set @Operator = 'AVG'  
      
     Set @SQLString = 'UPDATE #InvertedSummary ' +  
       ' Set ' + @Variable + ' = Str(IsNull((Select ' + @Operator + '(IsNull(Convert(Float,'+ @Variable+'),0)) ' +  
       ' FROM #InvertedSummary ' +  
       ' WHERE Class IN ( ' + @ClassList + ' ) and ColType = ''' + 'ZZZ' + ''' and ' + @Variable + ' Is Not NULL),0),15,' + convert(varchar,@Prec) + ') ' +  
       ' WHERE GroupBy = ''' + 'Aggregate' + ''''  
    End  
    Else  
    Begin  
        If @RPTMajorGroupBy = 'Product' and ( @Variable = 'TargetSpeed' Or @Variable = 'IdealSpeed')  
                            Set @Operator = 'AVG'  
      
     Set @SQLString = 'UPDATE #InvertedSummary ' +   
       ' Set ' + @Variable + ' = Str(IsNull((Select ' + @Operator + '(IsNull(Convert(Float,'+ @Variable+'),0)) ' +  
       ' FROM #InvertedSummary ' +  
       ' WHERE ColType = ''' + 'ZZZ' + ''' and ' + @Variable + ' Is Not NULL),0),15,' + convert(varchar,@Prec)+ ') ' +  
       ' WHERE GroupBy = ''' + 'Aggregate' + ''''  
    End  
      
    Exec(@SQLString)  
  
 Select @eq_id = Min(eq_id) FROM #Equations WHERE eq_id > @eq_id  
 -- Print 'Testing Operators ' +  @Variable + ' ' + @SQLString  
  
End  
  
--Print convert(varchar(25), getdate(), 120) + 'END CALCULATING EQUATIONS'  
  
------------------------------------------------------------------------------------------------------------------------  
-- UPDATE TotalProdTime, used for PerDay measurements  
--UPDATE #InvertedSummary  
--        Set  TotalProdTime = (Select Sum(Convert(Float,IsNull(TotalProdTime,0))) FROM #InvertedSummary WHERE ColType = 'ZZZ')  
--WHERE GroupBy = 'AGGREGATE'  
------------------------------------------------------------------------------------------------------------------------  
-- UPDATE Calendar Time just for CU purposes  
-- Use class list for these  
  
DECLARE  
        @uptimeClass as nvarchar(50)  
  
Select @uptimeClass = Class FROM #Equations WHERE Variable = 'Uptime'  
Select @Operator = Operator FROM #Equations WHERE Variable = 'Uptime'  
  
If @RPTMajorGroupBy = 'PU_ID' or @RPTMinorGroupBy = 'PU_ID'  
Begin  
    If @Operator = 'SUM'  
        Set @SQLString = 'UPDATE #InvertedSummary ' +   
                         'Set Uptime = Str((Select SUM(Convert(Float,Uptime)) FROM #InvertedSummary ' +   
                         'WHERE ColType <> ''' + 'ZZZ' + ''' and Class in ('+ @uptimeClass +')),15,1) ' +   
                         'WHERE GroupBy = '''+ 'AGGREGATE' + ''''  
    Else  
        Set @SQLString = 'UPDATE #InvertedSummary ' +   
                         'Set Uptime = Str((Select AVG(Convert(Float,Uptime)) FROM #InvertedSummary ' +   
                         'WHERE ColType <> ''' + 'ZZZ' + ''' and Class in ('+ @uptimeClass +')),15,1) ' +   
                         'WHERE GroupBy = '''+ 'AGGREGATE' + ''''  
End  
Else  
Begin  
    If @Operator = 'SUM'  
        Set @SQLString = 'UPDATE #InvertedSummary ' +   
                         'Set Uptime = Str((Select SUM(Convert(Float,Uptime)) FROM #InvertedSummary ' +   
                         'WHERE ColType = ''' + 'ZZZ' + '''),15,1)' +   
                         'WHERE GroupBy = '''+ 'AGGREGATE' + ''''  
    Else  
        Set @SQLString = 'UPDATE #InvertedSummary ' +   
                         'Set Uptime = Str((Select AVG(Convert(Float,Uptime)) FROM #InvertedSummary ' +   
                         'WHERE ColType = ''' + 'ZZZ' + ''' and Class in ('+ @uptimeClass +')),15,1) ' +   
                         'WHERE GroupBy = '''+ 'AGGREGATE' + ''''  
End  
  
Exec (@SQLString)  
  
----------------------------------------------------------------------------------------------------------------------  
-- Calculate Area 4 Loss  
  
declare   
        @startClass as varchar(1),  
        @endClass as varchar(1)  
  
select @startClass = LEFT(Value,1) FROM #Params WHERE param = 'DPR_Area4Loss_FromToClass'  
select @endClass = right(Value,1) FROM #Params WHERE param = 'DPR_Area4Loss_FromToClass'  
  
if (Len(@startClass)>0) or (Len(@endClass)>0)  
begin  
        set @SQLString = 'UPDATE #InvertedSummary ' +  
                ' Set Area4LossPer = Convert(float,TotalClass' + @startClass + ') - Convert(float,RunningScrap) - Convert(float,DowntimeScrap) - Convert(float,GoodClass' + @endClass + ')'  
          
        -- print ' ---> ' + @SQLString  
        exec(@SQLString)  
end  
  
  
-- Print convert(varchar(25), getdate(), 120) + 'CALCULATING PRODTIME'  
-------------------------------------------------------------------------------  
-- Need a trick for Production Time as it should not be > 1440 for a single day  
-------------------------------------------------------------------------------  
/*If @RPTMajorGroupBy = 'PU_ID' or @RPTMajorGroupBy = 'PLID'  
Begin  
  
        If Exists (Select * FROM #Equations WHERE Variable = 'ProdTime' and Operator = 'SUM')  
            UPDATE #InvertedSummary  
          Set ProdTime = (Select Sum(Convert(float,Isnull(ProdTime,0))) FROM #InvertedSummary WHERE ColType = 'ZZZ' and ProdTime Is Not NULL)   
         WHERE GroupBy = 'Aggregate'  
        Else  
            UPDATE #InvertedSummary  
          Set ProdTime = (Select Avg(Convert(float,Isnull(ProdTime,0))) FROM #InvertedSummary WHERE ColType = 'ZZZ' and ProdTime Is Not NULL)   
         WHERE GroupBy = 'Aggregate'  
  
End*/  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
-- MATH VARIABLES  
--Print convert(varchar(25), getdate(), 120) + 'Updating MATH VARIABLES'  
----------------------------------------------------------------------------  
--  
  
UPDATE #InvertedSummary  
 Set   
    -- Availability  
    Availability = Str(   
  Case  
   When (Convert(float,Uptime) + Convert(float,Downtime)) = 0 THEN 0  
   Else Convert(float,Uptime) / (Convert(float,Uptime) + Convert(float,Downtime))  
  End, 6, 2),  
    -- MTBF  
    MTBF = Str(   
  Case  
   When Convert(float,LineStops) = 0 THEN Uptime  
   Else Convert(float,Uptime) / Convert(float,LineStops)  
  End, 6, 1),  
        -- MTBF ERC  
    MTBF_ERC = Str(   
  Case  
   When Convert(float,LineStopsERC) = 0 THEN Uptime  
   Else Convert(float,Uptime) / Convert(float,LineStopsERC)  
  End, 6, 1),  
    -- MTTR  
       MTTR = Str(  
  Case  
   When Convert(float,LineStops)= 0 THEN Downtime  
   Else Convert(float,Downtime) / Convert(float,LineStops)  
  End, 6, 1),  
       -- MTTR  
       MTTR_ERC = Str(  
  Case  
   When Convert(float,LineStopsERC)= 0 THEN DowntimeERC  
   Else Convert(float,DowntimeERC) / Convert(float,LineStopsERC)  
  End, 6, 1),  
    -- Stops/MSU  
    StopsPerMSU = Str(  
  Case  
   When Convert(float,MSU)= 0 THEN 0     
   Else Convert(float,LineStops) / Convert(float,MSU)  
  End, 6, 1),  
    DownPerMSU = Str(  
  Case  
   When Convert(float,MSU)= 0 THEN 0  
   Else Convert(float,Downtime) / Convert(float,MSU)  
  End, 6, 1),  
    -- Total Scrap           
    TotalScrapPer = Str(  
  Case  
   When Convert(float,TotalPads) = 0 THEN 0  
   Else 100.0 * (Convert(float,isnull(TotalScrap,0)) / Convert(float,TotalPads))  
  End, 6, 1) + '%',  
    -- Area4Loss%  
    Area4LossPer = Str(  
     Case  
      When IsNull(Convert(float,TotalPads),0) = 0 THEN 0  
      Else 100.0 * (Convert(float,IsNull(Area4LossPer,0)) / Convert(float,IsNull(TotalPads,0)))  
     End, 6, 1) + '%',  
    RofT = Str(  
  Case  
   When Convert(float,LineStops) = 0 THEN 0  
   Else Convert(float,UptimeGreaterT)  / Convert(float,LineStops)  
   End, 6, 2),  
    RofZero = Str(  
  Case  
   When Convert(float,LineStops) = 0 THEN 0  
   Else  ( Convert(float,linestops) - Convert(float,falsestarts) )/ Convert(float,LineStops)  
   End, 6, 2),  
    -- EditedStops  
    EditedStopsPer =  Str(  
  Case  
   When Convert(float,LineStops) = 0 THEN 0  
   Else 100.0 * (Convert(float,NumEdits) / Convert(float,LineStops))  
  End, 6, 0) + '%',  
       -- EditedStopsR1  
    EditedStopsR1Per =  Str(  
  Case  
   When Convert(float,LineStops) = 0 THEN 0  
   Else 100.0 * (Convert(float,NumEditsR1) / Convert(float,LineStops))  
  End, 6, 0) + '%',  
       -- EditedStopsR2  
    EditedStopsR2Per =  Str(  
  Case  
   When Convert(float,LineStops) = 0 THEN 0  
   Else 100.0 * (Convert(float,NumEditsR2) / Convert(float,LineStops))  
  End, 6, 0) + '%',  
       -- EditedStopsR3  
    EditedStopsR3Per =  Str(  
  Case  
   When Convert(float,LineStops) = 0 THEN 0  
   Else 100.0 * (Convert(float,NumEditsR3) / Convert(float,LineStops))  
  End, 6, 0) + '%',  
    --   
    FailedSplices = Str(Convert(float, TotalSplices) - Convert(float,SUCSplices), 6, 1),  
    SuccessRate = Str(  
  Case  
  
   When Convert(float,TotalSplices) = 0 THEN 0  
   Else 100.0 * Convert(float,SucSplices) / Convert(float,TotalSplices)  
  End, 6, 1) + '%',  
    -- LineSpeed  
    LineSpeed = Str(  
  Case  
   When (Convert(float,Uptime) = 0 Or TotalPads Is NULL)THEN NULL  
   Else FLOOR((isnull(Convert(float,TotalPads),0) - isnull(Convert(float,DowntimeScrap),0)) / Convert(float,Uptime))  
   End, 6, 1),      
    -- PRUsingProductCount  
    PR = STR(  
  Case  
   When (Convert(float,PRODTIME) * CONVERT(FLOAT,TargetSpeed))= 0 THEN 0  
   -- Else  Convert(float,goodpads) / (Convert(float,PRODTIME) * CONVERT(FLOAT,targetSPEED) )*100.0  
   Else (Convert(float,GoodPads) / CONVERT(FLOAT,TargetSPEED)) / Convert(float,PRODTIME) * 100.0  
   End, 6, 2) + '%',  
    -- RunningScrap%  
    RunningScrapPer = STR(  
  Case  
   When Convert(float,TotalPads) = 0 THEN 0  
   Else 100.0 * Convert(float,RunningScrap) / Convert(float,TotalPads)  
   End, 6, 1) + '%',  
       -- DowntimeScrap%  
    DowntimescrapPer = STR(  
  Case  
   When Convert(float,TotalPads) = 0 THEN 0  
   Else 100.0 * Convert(float,DowntimeScrap) / Convert(float,TotalPads)  
   End, 6, 1) + '%',  
    
    -- FalseStart(UT=T)%  
    FalseStartsTPer = STR(  
  Case  
   When cast(linestops as float)=0 THEN 0  
   else cast(falsestartst as float) * 100 / cast(linestops as float)  
   end  
   ) + '%',  
  
        -- FalseStart(UT=0)%  
        FalseStarts0Per = Str(  
   (Case When Cast(LineStops As Float) = 0 Then 0  
   Else Cast(FalseStarts As Float) * 100 / Cast(LineStops As Float)  
   End),6,2  
   ) + '%' ,  
    SurvivalRatePer = Str (  
  (Case When (@RPTDowntimesurvivalRate = 0 or Convert(float,ProdTime) = 0) Then 0  
   Else Convert(float,SurvivalRate) / (Convert(float,ProdTime) / @RPTDowntimesurvivalRate) * 100  
   End),6,2  
  ) + '%'  
  
-- PRUsingAvailability  
UPDATE #InvertedSummary  
 Set   
    PRAvail = STR (  
  Case  
   When ((Convert(float,TotalPads) - Convert(float,isnull(DowntimeScrap,0)))=0 or ( Convert(float,Uptime) + convert(float,Downtime) ) = 0) THEN 0  
   Else 100 * Convert(float,Availability) * (1 - (Convert(float,isnull(RunningScrap,0)) / (Convert(float,TotalPads)-Convert(float,isnull(DowntimeScrap,0)))))  
   End, 6, 2) + '%' ,  
 SU = STR (  
  CASE  WHEN (CONVERT(FLOAT,ISNULL(CalendarTime,'0')) = 0) THEN 0  
   ELSE (CONVERT(FLOAT,ProdTime) / CONVERT(FLOAT,CalendarTime)) * 100   
   END, 6, 2) + '%' ,     
 RU = STR (  
  CASE    
   WHEN (CONVERT(FLOAT,ISNULL(GoodPads,'0')) = 0 OR CONVERT(FLOAT,ISNULL(TargetSpeed,'0')) = 0 OR CONVERT(FLOAT,ISNULL(IdealSpeed,'0')) = 0) THEN 0  
   ELSE (CONVERT(FLOAT,GoodPads) / CONVERT(FLOAT,IdealSpeed))/(CONVERT(FLOAT,GoodPads) / CONVERT(FLOAT,TargetSpeed)) * 100   
   END, 6, 2) + '%',  
 CU = STR (  
  CASE  WHEN (CONVERT(FLOAT,ISNULL(CalendarTime,'0')) = 0 or CONVERT(FLOAT,IdealSpeed)= 0 or CONVERT(FLOAT,IdealSpeed)= 0) THEN  0  
   ELSE (CONVERT(FLOAT,GoodPads) / CONVERT(FLOAT,IdealSpeed))/(CONVERT(FLOAT,CalendarTime)) * 100   
   END, 6, 2) + '%',  
 RunEff = STR (  
  CASE    WHEN (CONVERT(FLOAT,ISNULL(ProdTime,'0')) - CONVERT(FLOAT,ISNULL(DowntimePlannedStops,'0')) = 0 OR (CONVERT(FLOAT,ISNULL(TargetSpeed,'0')) = 0)) THEN 0  
   ELSE (CONVERT(FLOAT,GoodPads) / CONVERT(FLOAT,TargetSpeed)) / (CONVERT(FLOAT,ISNULL(ProdTime,'0')) - CONVERT(FLOAT,ISNULL(DowntimePlannedStops,'0'))) * 100  
   END, 6, 2) + '%'  
  
-- Total Uptime, Total Downtime only UPDATEs the Aggregate column  
UPDATE #InvertedSummary  
        Set    StopsPerDay = Str(Case  When Convert(Float,Uptime) + Convert(Float,Downtime) < 1440 Then LineStops  
                  Else (Convert(Float,LineStops) * 1440 / ((Convert(float,Uptime) + Convert(float,Downtime))    )) End,6,1),           
            ACPStopsPerDay = Str(Case  When Convert(Float,Uptime) + Convert(Float,Downtime) < 1440 Then AcpStops   
                            Else (Convert(Float,AcpStops) * 1440 / ((Convert(float,Uptime) + Convert(float,Downtime))    )) End,6,1)  
WHERE GroupBy = 'AGGREGATE'  
  
  
---------------------------------------------------------------------------------------------------------------  
-- TRANSPOSE #InvertedSummary TO Summary:  
---------------------------------------------------------------------------------------------------------------  
-- Select * FROM @ColumnVisibility  
-- Select * FROM #PLIDList  
-- Select * FROM #Params WHERE param like '%Date%'  
-- Select * FROM #InvertedSummary order by id  
-- Select * FROM @Cursor  
-- Select * FROM #Summary  
  
--Print convert(varchar(25), getdate(), 120) + ' POPULATE OUTPUT Tables Summary'   
  
If Exists (Select * FROM #InvertedSummary) -- < 100  
BEGIN  
  
UPDATE @ColumnVisibility  
    Set LabelName = (select value FROM #Params WHERE param = 'DPR_' + VariableName)  
WHERE Charindex( 'Flexible_Variable_', VariableName)>0   
  
Insert into #Summary (SortOrder, Label)  
Select Convert(Varchar(10),ColId),LabelName FROM @ColumnVisibility   
  
  
--------------------------------------------------------------------------------------------------------------------  
--   
Declare @id_is as int  
  
Select @id_is = Min(id) FROM #InvertedSummary  
  
While @id_is Is Not NULL  
Begin  
  
    Select @GroupValue = Groupby FROM #InvertedSummary WHERE ID = @id_is  
  
 Set @j = 1  
 While @j <= @NoLabels  
  Begin  
  --  
  If Exists ( Select * FROM #Summary WHERE SortOrder = @j)  
     
   Begin  
           Select @FIELDName = FieldName FROM @ColumnVisibility WHERE ColId = @j  
     
     Select @SQLString = ''  
     Select @SQLString = 'Select ' + @FIELDName +  
      ' FROM #InvertedSummary ' +  
      ' WHERE GroupBy = ''' + @GroupValue + ''''  
     -- Print @SQLSTring  
     --   
     TRUNCATE Table #TEMPORARY  
     Insert #TEMPORARY (TEMPValue1)  
     Execute (@SQLString)  
     --  
     -- Set @TEMPValue = null      
     Select @TEMPValue = TEMPValue1 FROM #TEMPORARY  
     -- Select @SQLString = ''  
     --  
     Select @SQLString = 'UPDATE #Summary' +  
      ' Set '+ @GroupValue + ' = ''' + LTrim(RTrim(@TEMPValue)) + '''' +  
      ' WHERE SortOrder = ' + Convert(VARCHAR(25),@J)  
     --   
     -- Print @SQLString         
     Execute (@SQLString)  
  
   End  
  --  
  Set @j = @j + 1  
 End  
  
    Select @id_is = Min(ID) FROM #InvertedSummary WHERE ID > @id_is  
  
End  
END  
ELSE  
        UPDATE #Summary   
                Set Label = 'The Report has reach the maximun number of columns!'  
  
  
-- Select * FROM #Summary  
----------------------------------------------------------------------------  
--   
----------------------------------------------------------------------------  
  
----------------------------------------------------------------------------------------------------------  
-- UPDATE the report definition FROM the @ColumnVisibility table  
--Print convert(varchar(25), getdate(), 120) + ' UPDATE the parameters table'   
----------------------------------------------------------------------------------------------------------  
-- Select * FROM #Temp_ColumnVisibility  
-- Select * FROM @ColumnVisibility  
  
UPDATE dbo.Report_Definition_Parameters   
        Set Value = 'TRUE'  
FROM dbo.Report_Definition_Parameters rdp WITH(NOLOCK)  
Join dbo.Report_Definitions r WITH(NOLOCK) on rdp.report_id=r.report_id  
Join dbo.Report_Type_Parameters rtp WITH(NOLOCK) on rtp.rtp_id = rdp.rtp_id  
Join dbo.Report_Parameters rp WITH(NOLOCK) on rp.rp_id = rtp.rp_id  
Join (select 'DPR_' + VariableName as VariableName FROM @ColumnVisibility) cv On cv.VariableName = rp_name  
WHERE r.report_id = @Report_Id  and rp_name Not Like '%ShowTop5%'  
and rp_name Not Like '%DPR_Flexible_Variable%'  
and rp_name Not Like '%DPR_HorizontalLayout%'  
  
UPDATE dbo.Report_Definition_Parameters  
        Set Value = '!Null'  
FROM dbo.Report_Definition_Parameters rdp WITH(NOLOCK)  
Join dbo.Report_Definitions r WITH(NOLOCK) on rdp.report_id=r.report_id  
Join dbo.Report_Type_Parameters rtp WITH(NOLOCK) on rtp.rtp_id = rdp.rtp_id  
Join dbo.Report_Parameters rp on rp.rp_id = rtp.rp_id  
WHERE r.report_id = @Report_id  
and rp_name = 'Local_PG_strRptDPRColumnVisibility'  
  
--Print convert(varchar(25), getdate(), 120) + ' End UPDATE the parameters table'   
  
----------------------------------------------------------------------------  
-- Data Check: Used For Trouble Shooting  
----------------------------------------------------------------------------  
-- Select 'DPR_'+ VariableName FROM @ColumnVisibility  
-- Select * FROM #Status WHERE pu_id = 166 --order by start_time  
-- Select * FROM #PLIDList   
-- Select * FROM @Products  
-- Select * FROM #Production order by pu_id,StartTime   
-- Select * FROM #Summary  
-- Select * FROM @Class  
-- Select * FROM @LineStatus WHERE pu_id = 233   
-- Select * FROM #ShiftDESCList  
-- Select * FROM #CrewDESCList   
-- Select * FROM #PLStatusDESCList  
-- Select * FROM #Variables   
-- Select * FROM Local_PG_Line_Status  
-- Select * FROM Crew_Schedule  
-- Select * FROM #Splices  
-- Select * FROM #Rejects  
-- Select * FROM #Production WHERE Class = 3  
-- Select pu_id, count(*) FROM #Downtimes WHERE isStops = 1 group by pu_id  --pu_id = 93 order by start_Time   
-- Select schedtime,* FROM #Production order by pu_id,starttime  
-- Select * FROM #Downtimes Where Class = 1 and Shift = 3 Order by PU_Id,Start_Time   
-- Select * FROM #TESTS  
-- Select ColType,Uptime,Downtime,ProdTime,TotalProdTime,'->',* FROM #InvertedSummary  
----------------------------------------------------------------------------  
-- OUTPUT RESULT SETS For REPORT:  
----------------------------------------------------------------------------  
----------------------------------------------------------------------------  
-- OUTPUT RESULT SETS For REPORT: Result Set 1 For header  
----------------------------------------------------------------------------  
Select  
  
 @StartDateTime                          StartDateTime,  
 @EndDateTime                   EndDateTime,  
 @CompanyName                  CompanyName,  
 @SiteName                  SiteName,  
 NULL                  PeriodInCompleteFlag,  
 SUBString(@ProdCodeList, 1, 50)  Product,  
 SUBString(@CrewDESCList, 1, 25)  CrewDESC,  
 SUBString(@ShiftDESCList, 1, 10) ShiftDESC,  
 SUBString(@PLStatusDESCList, 1, 100) LineStatusDESC,  
 SUBString(@PLDESCList, 1, 100)  LineDESC,  
 SUBString(@lblPlant, 1, 25)  Plant,  
 @lblStartDate                  StartDate,  
 @lblShift                  Shift,  
 @lblProductCode                  ProductCode,  
 @lblLine                  Line,  
 @lblEndDate                  EndDate,  
 @lblCrew                  Crew,  
 @lblProductionStatus                 LineStatus,  
 @lblTop5Downtime                 Top5Downtime,  
 @lblTop5Stops                  Top5Stops,  
 @lblTop5Rejects                  Top5Rejects,  
 SUBString(@lblSecurity,1, 500)  Security  
  
----------------------------------------------------------------------------  
-- Restore the original settings to check if RptMajor = RptMinor  
----------------------------------------------------------------------------  
Set @RPTMajorGroupBy = @RPTMajorGroupByOld  
Set @RPTMinorGroupBy  = @RPTMinorGroupByOld  
----------------------------------------------------------------------------  
-- OUTPUT RESULT SETS FOR REPORT: Result Set 2 For Summary  
----------------------------------------------------------------------------  
If @RPTMajorGroupBy = @RPTMinorGroupBy  
Begin  
Set @i = 1  
Set @SQLString = 'UPDATE #Summary Set '   
  
While @i <= @ColNum  
begin  
        set @SQLString = @SQLString + 'Value' + convert(varchar,@i) + ' = ''' + '' + ''' ,'  
 set @i = @i + 1  
end  
set @SQLString = @SQLSTring + ' Null02 = ''' + @RPTMajorGroupBy + ''',Aggregate = ''' + '' + ''' WHERE GroupField = ''' + 'Major' + ''''  
Exec (@SQLString)  
End  
  
Set @i = 1  
Set @SQLString = 'Select SortOrder,Label,null01,null02,'   
  
While @i <= @ColNum  
begin  
        set @SQLString = @SQLString + 'Value' + convert(varchar,@i) + ','  
 set @i = @i + 1  
end  
set @SQLString = @SQLSTring + 'AGGregate,EmptyCol FROM #Summary'          
  
exec(@SQLString)  
  
-- Select * FROM #Summary   
----------------------------------------------------------------------------  
-- OUTPUT RESULT SETS FOR REPORT: Result Set 3 For Top 5 Downtime  
----------------------------------------------------------------------------  
If @RPTMajorGroupBy = @RPTMinorGroupBy  
Begin  
Set @i = 1  
Set @SQLString = 'UPDATE #Top5Downtime Set '   
  
While @i <= @ColNum  
begin  
        set @SQLString = @SQLString + 'Value' + convert(varchar,@i) + ' = ''' + '' + ''' ,'  
 set @i = @i + 1  
end  
set @SQLString = @SQLSTring + ' Stops = ''' + @RPTMajorGroupBy + ''',Aggregate = ''' + '' + ''' WHERE GroupField = ''' + 'Major' + ''''  
Exec (@SQLString)  
End  
  
Set @i = 1  
Set @SQLString = 'Select SortOrder,DESC01,DESC02,stops,'   
While @i <= @ColNum  
begin  
  set @SQLString = @SQLString + 'Value' + convert(varchar,@i) + ','  
  set @i = @i + 1  
end  
  set @SQLString = @SQLSTring + 'AGGregate,EmptyCol FROM #Top5Downtime'  
  
exec(@SQLString)  
--Select * FROM #Top5Downtime  
----------------------------------------------------------------------------  
-- OUTPUT RESULT SETS FOR REPORT: Result Set 4 For Top 5 Stops  
----------------------------------------------------------------------------  
If @RPTMajorGroupBy = @RPTMinorGroupBy  
Begin  
Set @i = 1  
Set @SQLString = 'UPDATE #Top5Stops Set '   
  
While @i <= @ColNum  
begin  
        set @SQLString = @SQLString + 'Value' + convert(varchar,@i) + ' = ''' + '' + ''' ,'  
 set @i = @i + 1  
end  
set @SQLString = @SQLSTring + ' Downtime = ''' + @RPTMajorGroupBy + ''', Aggregate = ''' + '' + ''' WHERE GroupField = ''' + 'Major' + ''''  
Exec (@SQLString)  
End  
  
Set @i = 1  
Set @SQLString = 'Select SortOrder,DESC01,DESC02,downtime,'   
While @i <= @ColNum  
begin   
  set @SQLString = @SQLString + 'Value' + convert(varchar,@i) + ','  
  set @i = @i + 1  
end  
  set @SQLString = @SQLSTring + 'AGGregate,EmptyCol FROM #Top5Stops'  
  
exec(@SQLString)  
  
--Select * FROM #Top5Stops   
----------------------------------------------------------------------------  
-- OUTPUT RESULT SETS FOR REPORT: Result Set 5 For Top 5 Rejects  
----------------------------------------------------------------------------  
If @RPTMajorGroupBy = @RPTMinorGroupBy  
Begin  
Set @i = 1  
Set @SQLString = 'UPDATE #Top5Rejects Set '   
  
While @i <= @ColNum  
begin  
        set @SQLString = @SQLString + 'Value' + convert(varchar,@i) + ' = ''' + '' + ''' ,'  
 set @i = @i + 1  
end  
set @SQLString = @SQLSTring + ' Events = ''' + @RPTMajorGroupBy + ''', Aggregate = ''' + '' + ''' WHERE GroupField = ''' + 'Major' + ''''  
Exec (@SQLString)  
End  
  
Set @i = 1  
Set @SQLString = 'Select SortOrder,DESC01,DESC02,events,'   
While @i <= @ColNum  
begin  
  set @SQLString = @SQLString + 'Value' + convert(varchar,@i) + ','  
  set @i = @i + 1  
end  
  set @SQLString = @SQLSTring + 'AGGregate,EmptyCol FROM #Top5Rejects'  
  
exec(@SQLString)  
  
--Select * FROM #Top5Rejects  
----------------------------------------------------------------------------  
-- OUTPUT RESULT SETS FOR REPORT: Result Set 7 For Equations  
----------------------------------------------------------------------------  
UPDATE #Equations Set Class = Class + ','  
  
Declare   
 @ClassDesc as nvarchar(50),  
 @iClass as int  
  
Set @ClassNo = 20 -- (Select Max(Class) FROM @Class)  
  
Set @iClass = 1  
  
While @iClass < @ClassNo + 1  
Begin  
  
Set @ClassList = ''  
  
Declare cUnits Cursor For (Select PuDesc FROM @Class WHERE Class = @iClass)  
Open cUnits  
  
Fetch Next FROM cUnits Into @ClassDesc  
  
While @@Fetch_Status = 0   
Begin  
 Set @ClassList = @ClassList + @ClassDesc + ';'  
 Fetch Next FROM cUnits Into @ClassDesc  
End  
  
Close cUnits  
Deallocate cUnits  
  
Set @SQLString = 'UPDATE #Equations Set Class = Replace(Class,''' + Convert(varchar,@iClass)+ ','+''',''' + @ClassList + ''')'  
Exec (@SQLString)  
  
-- print 'Cursor de Clases ->' + @SQLString  
  
Set @iClass = @iClass + 1  
End  
  
-- Select * FROM #Equations  
  
Insert @RptEqns (VariableName, Equation) Values ('Variable Name','Equation')  
Insert @RptEqns (VariableName, Equation) Select 'Repair Time > T', Operator + ' of ( Count Stops > T ) FROM ' + Class  FROM #Equations WHERE Variable = 'RepairTimeT'  
Insert @RptEqns (VariableName, Equation) Select 'Total Scrap', Operator + ' of Total Scrap FROM ' + Class FROM #Equations WHERE Variable = 'TotalScrap'  
Insert @RptEqns (VariableName, Equation) Select 'Success Rate', Operator + ' of ( Succesful Splices / Total Splices ) FROM ' + Class FROM #Equations WHERE Variable = 'SuccessRate'  
Insert @RptEqns (VariableName, Equation) Select 'Survival Rate', Operator + ' of ( Count of Uptime >' + Convert(varchar,@RPTDowntimesurvivalRate) + ' ) FROM ' + Class  FROM #Equations WHERE Variable = 'SurvivalRate'  
Insert @RptEqns (VariableName, Equation) Select 'Target Speed', Operator + ' of Target Speed FROM ' + Class  FROM #Equations WHERE Variable = 'TargetSpeed'  
Insert @RptEqns (VariableName, Equation) Select 'Total Product', Operator + ' of ( Count of Product ) FROM ' + Class  FROM #Equations WHERE Variable = 'TotalPads'  
Insert @RptEqns (VariableName, Equation) Select 'Total Splices', Operator + ' of ( Count of Total Splices ) FROM ' + Class FROM #Equations WHERE Variable = 'TotalSplices'  
Insert @RptEqns (VariableName, Equation) Select 'Uptime', Operator + ' of ( Production Time - Downtime ) FROM ' + Class  FROM #Equations WHERE Variable = 'Uptime'  
Insert @RptEqns (VariableName, Equation) Select 'Downtime', Operator + ' of ( # of Stops with 3rd level FMECA edited ) FROM ' + Class  FROM #Equations WHERE Variable = 'Downtime'  
Insert @RptEqns (VariableName, Equation) Select 'Edited Stops', Operator + ' of Downtimes FROM ' + Class  FROM #Equations WHERE Variable = 'NumEdits'  
Insert @RptEqns (VariableName, Equation) Select 'Failed Splices', Operator + ' of (Count of Failed Splices) FROM ' + Class  FROM #Equations WHERE Variable = 'FailedSplices'  
Insert @RptEqns (VariableName, Equation) Select 'False Starts T', Operator + ' of (False Starts (Uptime <= 2) / Line Stops (not filtered)) FROM ' + Class  FROM #Equations WHERE Variable = 'FalseStartsT'  
Insert @RptEqns (VariableName, Equation) Select 'Good Product',Operator + ' of ( Count of Good Product ) FROM ' + Class  FROM #Equations WHERE Variable = 'GoodPads'  
Insert @RptEqns (VariableName, Equation) Select 'Line Stops', Operator + ' of ( Count of Converter Stops ) FROM ' + Class  FROM #Equations WHERE Variable = 'LineStops'  
Insert @RptEqns (VariableName, Equation) Select 'Production Time', Operator + ' of ( Scheduled Time FROM STLS ) FROM ' + Class FROM #Equations WHERE Variable = 'ProdTime'  
Insert @RptEqns (VariableName, Equation) Values ('ACP Stops','Count of Packer Stops')  
Insert @RptEqns (VariableName, Equation) Values ('ACP Stops/Day','ACP Stops*1440/ (Uptime-Downtime)')  
Insert @RptEqns (VariableName, Equation) Values ('Area 4 Loss','(Good Product - (Total Cases * Product per Case)) / Total Product')  
Insert @RptEqns (VariableName, Equation) Values ('Availability','Uptime / (Uptime + Downtime)')  
Insert @RptEqns (VariableName, Equation) Values ('Average Line Speed','(Total Product - DowntimeScrap) / Uptime')  
Insert @RptEqns (VariableName, Equation) Values ('Converter Scrap %','Total Scrap / Total Product')  
Insert @RptEqns (VariableName, Equation) Values ('Down/MSU','Sum of Downtime / MSU')  
Insert @RptEqns (VariableName, Equation) Values ('Downtime Scrap %','Downtime Scrap / Total Product in %')  
Insert @RptEqns (VariableName, Equation) Values ('Edited Stops%','% of Stops with 3rd level FMECA edited')  
Insert @RptEqns (VariableName, Equation) Values ('Failed Splices','Count of Failed Splices')  
Insert @RptEqns (VariableName, Equation) Values ('False Starts % (0)','False Starts (Zero Ups) / Line Stops (not filtered)')  
Insert @RptEqns (VariableName, Equation) Values ('False Starts % (T)','False Starts (Up time<=2) / Line Stops (not filtered)')  
Insert @RptEqns (VariableName, Equation) Values ('False Starts (0)','Count of Zero Ups')  
Insert @RptEqns (VariableName, Equation) Values ('MSU','Good Product / ProdPerStat / 1000')  
Insert @RptEqns (VariableName, Equation) Values ('MTBF','Uptime / Stops')  
Insert @RptEqns (VariableName, Equation) Values ('MTTR','Downtime / Stops')  
Insert @RptEqns (VariableName, Equation) Values ('PR Using Avaiability','(Availability * (   1- (  Running Scrap / (Total Product - Downtime Scrap)  )   ) ')  
Insert @RptEqns (VariableName, Equation) Values ('PR','Good Product * 100 / (Scheduled Time * Target Speed)  ')  
Insert @RptEqns (VariableName, Equation) Values ('R(0)','Stops > 0 / Stops')  
Insert @RptEqns (VariableName, Equation) Values ('R(T)','Stops > T / Stops')  
Insert @RptEqns (VariableName, Equation) Values ('Real Downtime','Total Downtime with All shifts, All Teams, All Line Status, All Products')  
Insert @RptEqns (VariableName, Equation) Values ('Real Uptime','Total Uptime with All shifts, All Teams, All Line Status, All Products')  
Insert @RptEqns (VariableName, Equation) Values ('Rejected Product','Downtime Scrap  + Running Scrap')  
Insert @RptEqns (VariableName, Equation) Values ('Running Scrap %','Running Scrap / Total Product')  
Insert @RptEqns (VariableName, Equation) Values ('Stops Per Day','Line Stops * 1440 / (Uptime + Downtime)')  
Insert @RptEqns (VariableName, Equation) Values ('Stops/MSU','Count of Stops / MSU')  
Insert @RptEqns (VariableName, Equation) Values ('Suc. Splices','Count of Good Splices')  
  
-- Select * FROM #Equations  
-- Select * FROM @RptEqns -- order by VariableName  
  
----------------------------------------------------------------------------  
-- Drop Temporary All Tables:  
-- select * FROM #PLIDList  
----------------------------------------------------------------------------  
--Print convert(varchar(25), getdate(), 120) + ' Finshed SP'  
  
DROP TABLE #Timed_Event_Detail_History  
DROP TABLE #PLIDList   
DROP TABLE #ShiftDESCList  
DROP TABLE #CrewDESCList   
DROP TABLE #PLStatusDESCList  
DROP TABLE #Summary  
DROP TABLE #Top5Downtime  
DROP TABLE #Top5Stops  
DROP TABLE #Top5Rejects  
DROP TABLE #Splices  
DROP TABLE #Rejects  
DROP TABLE #Downtimes  
DROP TABLE #Production  
DROP TABLE #InvertedSummary  
DROP TABLE #Temporary  
DROP TABLE #FlexParam  
DROP TABLE #Equations  
DROP TABLE #ReasonsToExclude  
DROP TABLE #ac_Top5Downtimes  
DROP TABLE #ac_Top5Stops  
DROP TABLE #ac_Top5Rejects  
DROP TABLE #Temp_LinesParam  
DROP TABLE #Temp_ColumnVisibility  
DROP TABLE #Params  
DROP TABLE #Temp_Uptime  
  
  
  
RETURN  
  
  
  
  
