



-------------------------------------------------------------------------------------------------------------------------
---- FAM LEDS DDS Report
----
---- 2018-12-18		Martin Casalis						Arido Software
-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
---- EDIT HISTORY: 
-------------------------------------------------------------------------------------------------------------------------
---- ========		====	  		====					=====
---- 1.0			2018-12-18		Martin Casalis			Initial Release (HTML5 version)
---- 1.1			2019-08-28		Damian Campana			Capability to filter with the time option 'Last Week'
----=====================================================================================================================

--------------------------------------------------[Creation Of SP]-------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_RptFAMLEDSDDS_HTML5]  
--DECLARE                                                          
    @intTimeOption			INT, 
	@LineId					INT,                                                              
    @RptShiftDescList		VARCHAR(4000),                                                   
    @RptCrewDescList		VARCHAR(4000),                                                                  
    @RptPLStatusDescList    VARCHAR(4000),                                                              
    @RptStartDate			VARCHAR(25),                                                              
    @RptEndDate				VARCHAR(25) ,
	@intShowAuditSheets		INT                               

--WITH ENCRYPTION 
AS                                                        
/*                                                            
Stored Procedure :   [spLocal_RptFAMLEDSDDS_HTML5]                                                            
Author   :     TCS                                                            
Date Created  :    14-Dec-2009                                                            
SP Type   :       Report                                                            
Called By  :      Web Server                                                            
Editor Tab Spacing :  3                                                            
                                                            
Description:                                                            
=====================================================================================================                                                      
This report SP populates the LEDS DDS Summary report. It is specifically designed for Belleville.                                                       
For data retrieval, this report uses the UDP "FAMDDS". See documentation for more details.                                                           
                                                      
Test Syntax:                                                            
=====================================================================================================                                                      
Exec [dbo].spLocal_RptFAMLEDSDDS_HTML5                                                          
@Report_name    = 'FAM_DPR_DDS_TEST2',                                                            
@RptShiftDescList   = '!Null',                                                                 
@RptCrewDescList   = '!Null',                                                                 
@RptPLStatusDescList  = '!Null',                                                                 
@RptStartDate    = '2010-02-03 06:50:00',                                                                 
@RptEndDate    = '2010-02-04 06:50:00'                                                            
                                        
Sections:                                                      
=========                                                      
Section 1 : Declare Variables                                                      
Section 2 : Declare Tables                                                      
Section 3 : Initialize Variables                                                      
Section 4  : Team Runs                                                      
Section 5  : Sheet Breaks                                                      
Section 6  : Turnover Events                                                      
Section 7  : Roll Events                                                      
Section 8  : Sheet break top 5                                                      
                                                      
Section 9.1  : Measures - Losses (Downtime , uptime, schedule run time, FMDS,FMDL)                                                      
Section 9.2  : Measures - Utilization                                                      
Section 9.3  : Measures - Pour                                                      
                                                      
Section 10  : Preparing the Summary Table \ Top 5 SheetBreaks - Header                                                      
Section 11  : Populating Top 5 SheetBreaks \ Updating the AGGREGATE column                                                      
Section 12  : Inverted Summary - Populate Inverted \ Top 5 Sheet Breaks                                                      
Section 13  : Inverted Summary - Populating Aggregate column                                                      
Section 14  : Populate Summary                                                   
Section 15  : Result set                                          
                                                      
Revision   Date      Who      What                                                            
========================================================================                              
v0.0.1   14-Dec-2009  TCS   Initial Version  
V1.0.0   27-Apr-2017  Rakendra Added App Version and If Exists entry                         
========================================================================                                               
*/                                                          
                                                                                            
                                                      
SET NOCOUNT OFF                             
                                                      
--********************************************************************************************************************************                                                          
--Start - Section 1 - Declare Variables                                                        
--********************************************************************************************************************************                                                          
                                                      
DECLARE                                                              
 @SiteName               VARCHAR(50),                                                
 @CompanyName            VARCHAR(50),                                                                                                                   
 @intRptShiftLength    INT,                                                      
 @dtmRptShiftStart   NVARCHAR(25) ,                                                      
 @CrewDESCList           VARCHAR(4000),                                                              
 @ShiftDESCList          VARCHAR(4000),                                                              
 @PLStatusDESCList       VARCHAR(4000),                                                              
 @lblPlant      VARCHAR(50),                                                              
 @lblStartDate      VARCHAR(50),                                                              
 @lblShift        VARCHAR(50),                                                              
 @lblLine         VARCHAR(50),                                                              
 @lblEndDate       VARCHAR(50),                                                             
 @lblCrew         VARCHAR(50),                                                              
 @lblProductionStatus    VARCHAR(50),                                                       
 @lblTop5Downtime     VARCHAR(50),                                                              
 @lblAll          VARCHAR(50),                                                              
 @lblSecurity      VARCHAR(1000),                                                         
 @RptStartTime     DATETIME,                                                          
 @RptEndTime      DATETIME,                                             
                                                        
 @RptTeams       VARCHAR(255),                                                          
 @LineDesc       VARCHAR(255),        
 @RptShifts       VARCHAR(255),                                                          
 @RPTMajorGroupBy        VARCHAR(50),         
 @RPTMinorGroupBy        VARCHAR(50),
 
 @ReportName VARCHAR(50),
 @vchTimeOption VARCHAR(50)
                                                      
           
DECLARE                                                            
 @GroupMajorFieldName   VARCHAR(50),                                                              
 @GroupMinorFieldName   VARCHAR(50),                                                          
 @TableName             VARCHAR(50),                                                          
 @i             INT,                                                          
 @top5col        INT,                                                      
 @intShowStatic         INT,                                                                                               
 @j                     INT,                                                          
 @k                     INT,                                     
 @ColNum                VARCHAR(3) ,                                                          
 @SQLString             VARCHAR(4000),                                                          
 @Rpt_ShowTop5Downtimes VARCHAR(10),                                                          
 @RollsPUID       INT                                                          
                                                          
---- Inverted Summary Table                             
DECLARE                                                               
  @DraftConst     VARCHAR(6),                                                      
  @Draftval      NUMERIC(10,2),                                                      
  @GroupByString    NVARCHAR(500),                                                      
  @Prev_Value     NVARCHAR(100) ,                                                             
  @SumDTDuration    NUMERIC(10,2),                                                          
  @SumUptime      NUMERIC(10,2),                                   
  @SumGlblIncUptime    FLOAT,                                                          
  @SumGroupBy      VARCHAR(25),                                                          
  @MaxBeltSpeed      NUMERIC(10,2),                                                          
  @MaxReelSpeed      NUMERIC(10,2),                                                          
  @AvgPctShrinkage     NUMERIC(5,2),                                                          
  @AvgWinderDrumAvg    NUMERIC(5,2),                                                          
  @SumTotalPourTime    FLOAT,                                                          
  @SumFMDL               NUMERIC(5,2),                                                           
  @SumFMDS               NUMERIC(5,2),                                                          
  @SumRateUtil      NUMERIC(15,2),                                                          
  @SumScheduleUtil     NUMERIC(15,2),                                                          
  @AvgTargetRate     NUMERIC(15,2),                                                          
  @AvgIdealRate      NUMERIC(15,2),                                                          
  @TARGETTYPECNT     NUMERIC(10,2),                                                          
  @MEDIUMTYPECNT     NUMERIC(10,2),                                                          
  @PLUSTYPECNT     NUMERIC(10,2),                                                          
  @SMALLTYPECNT      NUMERIC(10,2),                                                          
  @STUBTYPECNT      NUMERIC(10,2),                                                          
  @SUMTotalMetersMade    NUMERIC(15,2),                                               
  @SUMGoodMetersWound    NUMERIC(15,2),                                                       
  @SUMGoodSqMeters     NUMERIC(15,2),                 
  @CapUtil               NUMERIC(15,2),                                                       
  @SUMMSU       NUMERIC(15,2),                                       
  @SUMAvailability       NUMERIC(15,2),                                         
  @SumSheetBreakCount    NUMERIC(15,2),                                                          
  @SumMinutesBreak     NUMERIC(15,2),                                                          
  @SumDTMinutes     NUMERIC(15,2),                                        
  @SumMCUptime    NUMERIC(15,2),                                      
  @SumWidthReelSpeed   NUMERIC(15,2),                                      
  @SumPartialAreaRej   NUMERIC(15,2),                                                        
  @SumRejectedRollTime   NUMERIC(15,2),                                                          
  @SumWindPercent        NUMERIC(5,2),                                                          
  @SumGoodProdRollTime   NVARCHAR(50),                                                          
  @BeltPourTimeAGG    NUMERIC(6,2),                                                          
  @BeltSteamTimeAGG    NUMERIC(6,2),                                                      
  @SUMREPORTTARGETWIDTH  NUMERIC(15,2),                                                      
  @ReportTargetSpeedvar  FLOAT,                       
  @ReportTargetSpeedfrom  VARCHAR(25),                          
  @PRusingProductCount   NUMERIC(15,2),                                                      
  @ScheduleTime    NUMERIC(15,2),                                                  
  @SumAverageLanes    NUMERIC(15,2)                             
                                                         
--Used while calculating Schedule Utilization                                                          
DECLARE                                                       
 @CalendarTime   NUMERIC(15,2)                                                          
-- @Reporttimehh   NUMERIC(10,2)                    
                    
DECLARE @CurEndTime DATETIME  -- used for cursor                                                      
                                                          
---Used For Rolls                                                          
DECLARE                                                      
  @GoodStatus          INT,                                                            
  @RejectStatus       INT,                                                            
  @HoldStatus          INT,                                                            
  @PerfectStatus       INT,                                                          
  @TARGETTYPE     VARCHAR(25),                                                          
  @MEDIUMTYPE     VARCHAR(25),                                                          
  @PLUSTYPE      VARCHAR(25), --PLUS                                                  
  @SMALLTYPE      VARCHAR(25),                                                          
  @STUBTYPE      VARCHAR(25)                                                          
                                                          
                                                      
--Pour Events                                                          
DECLARE                                                          
 @PouringRateVarId        INT,                                                          
 @PouringWidthVarId       INT,                                                          
 @BeltPourTimeVarId       INT,                                                          
 @BeltSpeedVarID          INT,                                                          
 @BeltSteamTimeVarId      INT,            
 @PourEventSubType        INT,                                                          
 @UDEEventType           INT,                                                          
 @PctShrinkageVarID       INT,                                                  
 @WinderDrumAvgVarId     INT,                                                          
 @CONVERSION_SPEED        FLOAT,                                                          
 @CONVERSION_WIDTH        FLOAT,                                                          
 @PourTotalTime          NUMERIC(15,2),                      
                                                        
--- Required Turnovers | Rolls                                                          
 @RollLengthVarID    INT,                                                       
 @RollAreaVarID     INT,                                                          
 @SpecVarTableID        INT,      -- For UDP retrieval, it's the ID for the Specifications table                                                          
 @TurnoverLengthVarID    INT,                                                          
 @TurnoverWidthVarId      INT,                                                          
 @TurnoverRollCountVarID  INT,                                                          
 @TurnoverLastEndTime    DATETIME,                                                          
 @FAMConfigCharID        INT,       -- Characteristic for current line in the property that contains turnover limits (Bell: FAM Configuration Data)                                                          
 @TurnoverTargetSpecID    INT,                                                          
 @TurnoverMediumSpecID    INT,                                        
 @TurnoverPlusSpecID    INT,    --Plus                                                         
 @TurnoverSmallSpecID     INT,                                                          
 @TurnoverStubSpecID      INT,                                              
 @TargetSpecID      INT,                                                    
 @YfwVarID         INT                   
                                     
--Sheet break top 5                                                          
DECLARE                                                           
 @SheetbreakRateVarId     INT,                                                          
 @SheetbreakWidthVarId    INT,                                                          
 @UDPThisReport       VARCHAR(50),                                                           
 @VarTableID        INT,                                                          
 @ProductionPUID       INT,                                                          
 @MinStart        DATETIME                                                          
                                                      
-- For PR calculation                                                      
DECLARE                                      
 @TargetRateVarID    INT,                                                           
 @IdealTargetVarID    INT,                                                        
 @TotalTime      NUMERIC(10,2)                                                 
                                                            
--********************************************************************************************************************************                                                          
--End - Section 1 - Declare Variables                                                          
--********************************************************************************************************************************                                                          
                        
--********************************************************************************************************************************           
--Start - Section 2 - Declare Tables                                                          
--********************************************************************************************************************************                                                          
                           
IF OBJECT_ID('tempdb.dbo.#RptTeams', 'U') IS NOT NULL  DROP TABLE #RptTeams              
CREATE TABLE #RptTeams                                          
(                                                          
 pKey         INT ,                                                          
 TeamDesc  VARCHAR(25)                                                          
)                                                          
                       
IF OBJECT_ID('tempdb.dbo.#RptShifts', 'U') IS NOT NULL  DROP TABLE #RptShifts                                   
CREATE TABLE #RptShifts                                                          
(                                                          
 pKey         INT,                                                          
 ShiftDesc  VARCHAR(25)                           
)                                                          
                      
IF OBJECT_ID('tempdb.dbo.#TeamRuns', 'U') IS NOT NULL  DROP TABLE #TeamRuns                                
CREATE TABLE #TeamRuns                                                            
(                         
 PKey         INT IDENTITY(1,1),                                                     
 Team         VARCHAR(25),                                                          
 Shift         VARCHAR(25),                                                          
 StartTime      DATETIME,                                                          
 EndTime        DATETIME                                                          
)                                                          
                                 
IF OBJECT_ID('tempdb.dbo.#InvertedSummary', 'U') IS NOT NULL  DROP TABLE #InvertedSummary   
CREATE TABLE #InvertedSummary                                                              
(                                                           
 ID           INT PRIMARY KEY IDENTITY,                                                              
 GroupBy         VARCHAR(25),                                                              
 ColType         VARCHAR(25),                                                              
 Downtime        VARCHAR(25),             
 Uptime          VARCHAR(25),                                                           
 ProdTime        VARCHAR(25),                                                          
 BeltSpeed      NUMERIC(10,2),                                                          
 ReelSpeed      NUMERIC(10,2),                                                          
 PctShrinkage     NUMERIC(5,2),                                                          
 WinderDrumAvg     NUMERIC(5,2),                      
 TotalPourTime    FLOAT,                                                          
 Belt1PourTime    NUMERIC(6,2),                                               
 Belt1SteamTime    NUMERIC(6,2),                                                          
 TotalScrap     NUMERIC(5,2),                                                          
 FMDL              NUMERIC(5,2),                                                          
 FMDS              NUMERIC(5,2),                                                    
 FMRJ              NUMERIC(5,2),                                                          
 ScheduleUtil     NUMERIC(15,2),                                                          
 RateUtil          NUMERIC(15,2),                                                          
 TargetRolls     NUMERIC(10,2),                                                          
 MeduimRolls     NUMERIC(10,2),                                                      
 PlusRolls       NUMERIC(10,2),                                                      
 SmallRolls     NUMERIC(10,2),                                                          
 StubRolls     NUMERIC(10,2),                                                          
 TotalMetersMade   NUMERIC(15,2),         
 GoodMetersWound   NUMERIC(15,2),                                                          
 MSU       NUMERIC(15,2),                                               
 Availability      NUMERIC(15,2),                                                          
 SheetBreakCount   INT,                                                          
 SheetBreakMin      NUMERIC(15,2),                                                   
 MinutesBreak      NUMERIC(15,2),                                                          
 BreaksPerDay    NUMERIC(15,2),                                                          
 BreaksPerMSU      NUMERIC(15,2),                                                          
 RejectedRollTime   NUMERIC(15,2),                                                          
 WindPercent       NUMERIC(5,2),                                                      
 PRusingProductCount  NUMERIC(15,2),           
 AverageLanes    NUMERIC(15,2),                                                      
 CapacityUtil    NUMERIC(15,2)                                                      
)                                                          
                                
IF OBJECT_ID('tempdb.dbo.#Summary', 'U') IS NOT NULL  DROP TABLE #Summary                      
CREATE TABLE #Summary                                                              
(                                                       
 Sortorder      INT,                                                              
 Label       VARCHAR(60),                                               
 null01       VARCHAR(60),                                                              
 null02       VARCHAR(25),                                          
 GroupField      VARCHAR(25),                                                              
 Value1       NVARCHAR(35),                                                              
 Value2       NVARCHAR(35),                                                      
 Value3       NVARCHAR(35),                                                              
 Value4       NVARCHAR(35),                                                              
 Value5       NVARCHAR(35),                                                              
 Value6       NVARCHAR(35),                                                              
 Value7       NVARCHAR(35),                                                              
 Value8       NVARCHAR(35),                                                              
 Value9       NVARCHAR(35),                                                              
 Value10       NVARCHAR(35),                                                                       
 Value11       NVARCHAR(35),                                                    
 Value12       NVARCHAR(35),                                                              
 Value13       NVARCHAR(35),                                                              
 Value14       NVARCHAR(35),                                                              
 Value15       NVARCHAR(35),                                                      
 AGGREGATE      NVARCHAR(35),                                                              
 EmptyCol      NVARCHAR(35)                                   
)               
                                                          
                       
IF OBJECT_ID('tempdb.dbo.#Top5SheetBreaks', 'U') IS NOT NULL  DROP TABLE #Top5SheetBreaks                                   
CREATE TABLE #Top5SheetBreaks                                                              
(                                                           
 Sortorder      INT IDENTITY,                                                              
 DESC01       VARCHAR(150),                                                              
 DESC02       VARCHAR(150),                                                              
 Stops       VARCHAR(25),                                                              
 GroupField      VARCHAR(25),                                                              
 Value1       NVARCHAR(35),                                    
 Value2       NVARCHAR(35),                                                              
 Value3       NVARCHAR(35),                                                             
 Value4       NVARCHAR(35),                                                              
 Value5       NVARCHAR(35),                                                              
 Value6       NVARCHAR(35),                                                              
 Value7       NVARCHAR(35),       
 Value8       NVARCHAR(35),                                                              
 Value9       NVARCHAR(35),                                             
 Value10       NVARCHAR(35),                                                              
 Aggregate      NVARCHAR(35),                                                              
 EmptyCol      NVARCHAR(35)                                                          
)                                                          
                                                          
-- For SheetBreaks              
IF OBJECT_ID('tempdb.dbo.#Sheetbreaks', 'U') IS NOT NULL  DROP TABLE #Sheetbreaks                                            
CREATE TABLE #Sheetbreaks                                                          
(                                                            
 PKey           INT IDENTITY(1,1),                                                            
 Extended         BIT NULL,                                                            
 TEDET_Id         INT,                                                            
 StartTime        DATETIME,                                                            
 EndTime         DATETIME,                                                           
 Team      VARCHAR(25),                                                          
 Shift      VARCHAR(25),                                                           
 TEFault_Id       INT,                                                            
 Source_PU_Id     INT,                             
 Reason1         INT,                                                            
 Reason2         INT,                                                            
 Reason3         INT,                                                            
 Reason4 INT,                                                            
 EventReasonTreeDataID  INT,                                                            
 Duration         NUMERIC(12,2)-- DT Duration in seconds                                                       
 )                                                           
                                                          
DECLARE @Cursor TABLE                                                              
(                                                         
 Cur_Id     INT PRIMARY KEY IDENTITY,                                                              
 Major_id    NVARCHAR(200),                                                              
 Major_desc    NVARCHAR(200),                                                              
 Minor_id    NVARCHAR(200),                                 
 Minor_desc    NVARCHAR(200),                                                              
 Major_Order_by   INT,                                                              
 Minor_Order_by   INT                                                      
)                                                      
                                                         
                                                          
--Primary table that contains all data to get results for the Sheetbreaks Top 5 Causes section       
IF OBJECT_ID('tempdb.dbo.#TED1', 'U') IS NOT NULL  DROP TABLE #TED1                                                   
CREATE TABLE #TED1                                                    
(                                      
 Ted_Id     INT IDENTITY,                                                        
 Start_Time    DATETIME,                           
 End_Time    DATETIME,                                                        
 Uptime     FLOAT,                                                        
 TEFault_Id    INT,                                                        
 Reason_Level2  INT,                                                        
 Uptime2     FLOAT,
 ISSheetBreak INT,                                                        
 Start_Time2    DATETIME,                                                        
 End_Time2    DATETIME,                                               
 Duration    FLOAT,       
 Reason2     VARCHAR(255),                                              
 Team          VARCHAR(25),                                       
 Shift          VARCHAR(25)                                                        
)                                                        
                                                          
--Working table that contains all data to get results for the Sheetbreaks Top 5 Causes section                                                          
DECLARE @TED2 TABLE                                                      
(                                                          
 Ted_Id     INT IDENTITY,                                              
 Start_Time    DATETIME,                                                          
 End_Time    DATETIME,                                                          
 Uptime     FLOAT,                                                          
 TEFault_Id    INT,                                                          
 Reason_Level2  INT                                       
)                                                          
                                                          
DECLARE @LineStatuses TABLE                                                           
(                                                          
 Pkey      INT IDENTITY(1,1),                                                          
 Phrase     VARCHAR(25),                                                          
 StartTime    DATETIME,                                                          
 EndTime     DATETIME,                                                          
 PRIN      BIT,    -- 1=PR IN ; 0=PR OUT ; NULL=OTHER                                                          
 DTDuration    INT,    -- Downtime duration in seconds                                                          
 DTSolids  INT,    -- Solids downtime duration in seconds                                                          
 DTLiquids    INT    -- Liquids downtime duration in seconds                             
)                                                          
                                               
IF OBJECT_ID('tempdb.dbo.#DownUptime', 'U') IS NOT NULL  DROP TABLE #DownUptime           
CREATE TABLE #DownUptime                                                          
(                                                 
 PKey       INT IDENTITY(1,1),                                                          
 Team       VARCHAR(25),                                                          
 Shift       VARCHAR(25),                                                          
 StartTime      DATETIME,                                                          
 EndTime       DATETIME,                                                          
 LineStatus      VARCHAR(25),                                                          
 PRIN       BIT,                                                          
 DTDuration      INT,    -- Downtime duration in seconds                                                          
 DTSolids      INT,                         
 DTLiquids      INT,                                                          
 GlblIncUptime   NUMERIC(10,2),                                                          
 Uptime       NUMERIC(10,2),                                                          
 FAMMakingSchTime   INT,                                                  
 MasterUnitUpTime   NUMERIC(15,2),            
 TargetRate      NUMERIC(15,6),    -- Average target rate on report window                                                           
 TargetCnt      INT,    -- Average target rate on report window                  
 IdealTarget     NUMERIC(10,6),                                                          
 IdealCnt      INT                             
)                                                          
                                                
IF OBJECT_ID('tempdb.dbo.#Top5Temp', 'U') IS NOT NULL  DROP TABLE #Top5Temp          
CREATE TABLE #Top5Temp                                                           
(                                               
 Reason2     VARCHAR(255),                                                          
 Duration    NUMERIC(10,2),                                                          
 Cnt      INT                                                          
)                                                          
                                                     
--- FOR POUR EVENTS                                      
                                       
IF OBJECT_ID('tempdb.dbo.#PourEvents', 'U') IS NOT NULL  DROP TABLE #PourEvents
CREATE TABLE #PourEvents                                                           
(                                                          
 Pkey       INT IDENTITY(1,1),                                                          
 Number       VARCHAR(1000),                                     
 StartTime      DATETIME,                                             
 EndTime       DATETIME,                                                          
 ActualStartTime      DATETIME,                                                          
 ActualEndTime       DATETIME,                                                          
 Team       VARCHAR(25),                                                             
 Shift    VARCHAR(25),                                                          
 TotalTime      INT,         -- Duration for the pouring event, in seconds.                                                          
 BeltSpeed NUMERIC(10,2),                                                          
 ProdCode      VARCHAR(25),                                                          
 PctTotalTime     NUMERIC(5,2),                                                          
 Width       NUMERIC(7,2),                                                          
 Rate       NUMERIC(10,4),                                
 GoodProduction   BIGINT,                                                          
 CONVERSION_SPEED   FLOAT,                                                          
 PctShrinkage     NUMERIC(5,2),                                                          
 ReelSpeed      NUMERIC(10,2),                                                          
 BeltSteamTime    NUMERIC(6,2),                                                          
 BeltPourTime     NUMERIC(6,2),                                                          
 WinderDrumAvg    NUMERIC(5,2)                                                          
)                                                      
                                                          
--- FOR SHEET BREAKS                                                          
                                     
IF OBJECT_ID('tempdb.dbo.#RollEvents', 'U') IS NOT NULL  DROP TABLE #RollEvents                     
CREATE TABLE #RollEvents                                                           
(                                                          
 PKey        INT IDENTITY(1,1),                                                          
 EventID        INT,                                                          
 ParentId       INT,                                   
 EventStartTime  DATETIME,                                                
 EventEndTime    DATETIME,                                                          
 StartTime       DATETIME,                                                          
 EndTime        DATETIME,                                             
 EstimatedStartTime  DATETIME,                                          
 EstimatedDuration  NUMERIC(10,2),                                          
 ReelSpeed          NUMERIC(10,2),                                           
 YFW           NUMERIC(10,2),                                          
 Timeequivalent  NUMERIC(15,2),                                       
 Team        VARCHAR(25),                                                          
 Shift        VARCHAR(25),                                                          
 Length        NUMERIC(7,2),                                                          
 Width        NUMERIC(7,2),                                                          
 Area        NUMERIC(13,2),                                                          
 Status        INT,                                                          
 Type        VARCHAR(10),                                                          
 PartialLength    FLOAT,                                                          
 PartialArea     FLOAT,                    
 TeamSplitFlag     INT                                                         
)                                  
                                     
--- FOR TURNOVER EVENTS                                      
                                      
IF OBJECT_ID('tempdb.dbo.#TurnoverEv', 'U') IS NOT NULL  DROP TABLE #TurnoverEv
CREATE TABLE #TurnoverEv                                                           
(                                                          
 PKey         INT IDENTITY(1,1),                                                          
 EventID         INT,                                                 
 EventStartTime  DATETIME,                
 EventEndTime    DATETIME,                                                         
 StartTime       DATETIME,                                                          
 EndTime         DATETIME,                                            
 EstimatedStartTime  DATETIME,                                          
 EstimatedDuration  NUMERIC(10,2),                                          
 ReelSpeed          NUMERIC(10,2),                                           
 ActualStartTime    DATETIME,                                          
 ActualDuration    NUMERIC(10,2),                                          
 Team         VARCHAR(25),                                                          
 Shift         VARCHAR(25),                                   
 [Length]        NUMERIC(7,2),                                                          
 Width         NUMERIC(7,2),                                        
 Area         NUMERIC(13,2),                                                    BeltSpeed       NUMERIC(10,2),                                                  
 YFW           NUMERIC(10,2),                                         
 Status         INT,                                                          
 Type         VARCHAR(10),                                                          
 PartialLength     FLOAT,                                                              
 RollCount       FLOAT,                                                        
 RollTotalLength    NUMERIC(7,2),                                                          
 TargetSpeed    NUMERIC(10,2),                                                          
 Belt1SetSpeed   NUMERIC(10,2),                                                      
 Belt1ActualSpeed   NUMERIC(10,2),                                                       
 WinderActualSpeed   NUMERIC(10,2),                                      
 LastGood_Belt1Speed  VARCHAR(50),                    
 TeamSplitFlag     INT                                 
                                       
)                                                          
                                     
IF OBJECT_ID('tempdb.dbo.#Turnovers', 'U') IS NOT NULL  DROP TABLE #Turnovers 
CREATE TABLE #Turnovers                                                           
(                                                          
 Pkey       INT IDENTITY(1,1),                                                          
 SpecVarID      INT,                
 StartTime      DATETIME,     -- StartTime for the specification values                                                          
 EndTime       DATETIME,     -- EndTime for the specification values                                                          
 LimitDesc      VARCHAR(10),                                                          
 LLimitValue    NUMERIC(7,2),                                                          
 ULimitValue    NUMERIC(7,2)                                                      
)                                                          
                                                      
                                 
IF OBJECT_ID('tempdb.dbo.#ac_Top5SheetBreaks', 'U') IS NOT NULL  DROP TABLE #ac_Top5SheetBreaks                
CREATE TABLE #ac_Top5SheetBreaks                                                              
(                
 SortOrder   INT,                                                               
 DESC01    NVARCHAR(200),                                                               
 DESC02    NVARCHAR(200),                                                              
 WHEREString1   NVARCHAR(500),                                                              
 WHEREString2   NVARCHAR(500)                                                          
)                                                      
                                                          
CREATE TABLE #TEMPORARY                                                              
(                                                           
 TEMPValue1     VARCHAR(100),                                                              
 TEMPValue2     VARCHAR(100),                                                              
 TEMPValue3     VARCHAR(100),              
 TEMPValue4     VARCHAR(100),                                                              
 TEMPValue5     VARCHAR(100),                                                              
 TEMPValue6     VARCHAR(100),                                                              
 TEMPValue7     VARCHAR(100),                                       
 TEMPValue8     VARCHAR(100),                                                              
 TEMPValue9     VARCHAR(100),                                         
 TEMPValue10    VARCHAR(100),                                                              
 TEMPValue11    VARCHAR(100)                                                          
)                                           
                            
IF OBJECT_ID('tempdb.dbo.#CompanionMeasures', 'U') IS NOT NULL  DROP TABLE #CompanionMeasures            
CREATE TABLE #CompanionMeasures                                                              
(                                                           
 ColId       INT PRIMARY KEY IDENTITY,                                         
 Measures     VARCHAR(100),                                                              
 Totalvalue     VARCHAR(100)                                        
)                                      
                                                      
                                                      
DECLARE @ColumnVisibility TABLE                                                              
(                                                
 ColId       INT PRIMARY KEY IDENTITY,                                                              
 VariableName     VARCHAR(100),                                                              
 LabelName        VARCHAR(100),                                                              
 TranslatedName   VARCHAR(100),                                                              
 FieldName        VARCHAR(100),                                                          
 Unit       VARCHAR(20)                                                          
)                                                       
                                     
--********************************************************************************************************************************                                                          
--End - Section 2 - Declare Tables                             
--********************************************************************************************************************************                                    
                                                      
--********************************************************************************************************************************                                                          
--Start - Section 3 - Initialize Variables                                                       
--********************************************************************************************************************************                                                          
--select * from report_definitions where report_name like '%fam%'    
--select * from prod_lines where pl_desc = 'FXHY001'                         
                                   
--SELECT       
--@LineId					= 29,
--@intTimeOption			= 1,
--@RptStartDate			= '2010-02-13 06:50:00',
--@RptEndDate				= '2010-02-14 06:50:00',
--@RptShiftDescList		= null,	--'!Null',
--@RptCrewDescList		= null,	--'!Null',
--@RptPLStatusDescList	= null,	--'!Null',
--@intShowAuditSheets		= 1
            
IF @RptShiftDescList IS NULL OR @RptShiftDescList = '' SET @RptShiftDescList = '!Null'
IF @RptCrewDescList IS NULL OR @RptCrewDescList = '' SET @RptCrewDescList = '!Null'
IF @RptPLStatusDescList IS NULL OR @RptPLStatusDescList = '' SET @RptPLStatusDescList = '!Null'                                          
                                        
SET @RptStartTime       = @RPTStartDate                                                      
SET @RptEndTime			= @RPTEndDate                                                      
SET @RptTeams			= @RPTCrewDESCList                                                    
SET @RptShifts			= @RPTShiftDESCList                                                      
SET @RPTMajorGroupBy    = 'Line'                                                 
SET @RPTMinorGroupBy    = 'Team'   --Set @RPTMinorGroupBy  = 'Shift'                                                      
SET @lblPlant           = 'Plant'                                                              
SET @lblStartDate       = 'Start Date'                  
SET @lblShift           = 'Shift'                                                              
SET @lblLine			= 'Line'                                                              
SET @lblEndDate         = 'End Date'                                                              
SET @lblCrew			= 'Team'                                               
SET @lblProductionStatus = 'Production Status'                                                      
SET @lblTop5Downtime	= 'Top 5 SheetBreaks'                                                        
SET @lblAll				= 'All'                                                      
SET @lblSecurity		= 'For P&G internal use Only'                                                      
SET @TARGETTYPE			= 'TARGET'                                                      
SET @MEDIUMTYPE			= 'MEDIUM'                             
SET @PLUSTYPE			= 'PLUS'                                                      
SET @SMALLTYPE			= 'SMALL'                                                          
SET @STUBTYPE			= 'STUB'                                                      
                                     
SELECT @CompanyName  = COALESCE (Value, 'Company Name') FROM Site_Parameters WITH(NOLOCK)  WHERE Parm_Id = 11                                       
                                                             
SELECT @SiteName  = COALESCE(Value, 'Site Name')    FROM Site_Parameters WITH(NOLOCK)  WHERE Parm_Id = 12         

SET @ReportName =  'FAM DDS Report'

-------------------------------------------------------------------------------------------------------------------
-- Time Options
-------------------------------------------------------------------------------------------------------------------
	SELECT @vchTimeOption = CASE @intTimeOption
									WHEN	1	THEN	'Last3Days'	
									WHEN	2	THEN	'Yesterday'
									WHEN	3	THEN	'Last7Days'
									WHEN	4	THEN	'Last30Days'
									WHEN	5	THEN	'MonthToDate'
									WHEN	6	THEN	'LastMonth'
									WHEN	7	THEN	'Last3Months'
									WHEN	8	THEN	'LastShift'
									WHEN	9	THEN	'CurrentShift'
									WHEN	10	THEN	'Shift'
									WHEN	11	THEN	'Today'
									WHEN	12	THEN	'LastWeek'
							END


	IF @vchTimeOption IS NOT NULL
	BEGIN
		SELECT	@RptStartTime	= dtmStartTime ,
				@RptEndTime		= dtmEndTime
		FROM [dbo].[fnLocal_DDSStartEndTime](@vchTimeOption)

	END
	                                      
--EXEC spCmn_GetReportParameterValue  @Report_Name, 'Local_PG_strLinesByID1'      , 29  , @LineId  OUTPUT                                                          
--EXEC spCmn_GetReportParameterValue  @Report_Name, 'TimeOption'      , 0  , @intTimeOption   OUTPUT   -- NOT BEEN USED                                                        
--EXEC spCmn_GetReportParameterValue  @Report_Name, 'Local_PG_StartShift'    , '6:50:00' , @dtmRptShiftStart OUTPUT   -- NOT BEEN USED                                                      
--EXEC spCmn_GetReportParameterValue  @Report_Name, 'Local_PG_ShiftLength'   , 12   , @intRptShiftLength  OUTPUT    -- NOT BEEN USED                                                   
--EXEC spCmn_GetReportParameterValue  @Report_Name, 'intRptDDSDraft'    , '0.03' , @DraftConst   OUTPUT                                                        
--EXEC spCmn_GetReportParameterValue  @Report_Name, 'intRptDDSShowCrewStatic'   , 0 , @intShowStatic  OUTPUT  -- NOT BEEN USED                                                     
--EXEC spCmn_GetReportParameterValue  @Report_Name, 'intRptWithDataValidation'   , 1 , @intShowAuditSheets OUTPUT                  


	SELECT	@DraftConst	= ISNULL([OpsDataStore].[dbo].[fnRptGetParameterValue] (@ReportName,'intRptDDSDraft'), '0.03')            
                                              
SET @Draftval  = CONVERT(NUMERIC(10,2),@DraftConst)                                                      
SET @CONVERSION_SPEED   = 22.0 * 0.95                                                           
SET @CONVERSION_WIDTH   = 1.18                                                       
SET @UDPThisReport   =   'FAMDDS'                                                      
SET @intShowStatic = 1                                                      
SET @TotalTime = isnull((DATEDIFF(ss, @RptStartTime, @RptEndTime)), 0)                 
              
DECLARE @ErrorMessages TABLE(                
 ErrMsg    nVarChar(255) )               
              
IF @TotalTime <= 0                 
BEGIN                
 INSERT @ErrorMessages (ErrMsg)                
  VALUES ('START DATE IS GREATER THAN OR EQUAL TO END DATE.')                 
 GOTO ErrorMessagesWrite                
END                
                                                      
-- Get event statuses                                                            
SET @GoodStatus    =                                                 
(                                                      
 SELECT ProdStatus_Id                                                       
 FROM dbo.Production_Status WITH(NOLOCK)                                                       
 WHERE ProdStatus_Desc = 'Good'                                                      
)                                                      
                                                      
SET @RejectStatus  =                                                       
(                                                      
 SELECT ProdStatus_Id                                                       
 FROM dbo.Production_Status WITH(NOLOCK)                   
 WHERE ProdStatus_Desc = 'Reject'                                                      
)                                                      
SET @HoldStatus    =                                                       
(                                                      
 SELECT ProdStatus_Id                                                       
 FROM dbo.Production_Status WITH(NOLOCK)                                                       
 WHERE ProdStatus_Desc = 'Hold'                                                      
)                                                      
SET @PerfectStatus =                                                       
(                                                      
 SELECT ProdStatus_Id                                      
 FROM dbo.Production_Status WITH(NOLOCK)                                                       
 WHERE ProdStatus_Desc = 'Perfect'                                                      
)                                                      
                                                      
-- Get the "Production" production unit on the selected line (passed as report parameter)                                                          
SET @ProductionPUID =                                        
(                                                           
 SELECT  PU_Id                                                          
 FROM  dbo.Prod_Units_Base WITH(NOLOCK)                                                          
 WHERE  pl_id = @LineID                                                          
 AND   Pu_Desc LIKE '%Production%'                                                          
)                                                          
                                                      
-- Table_Id for the dbo.Variables_Base table (for UDP retrieval)                                                          
SET @VarTableId =                                                             
(                                         
 SELECT  TableID                                                          
 FROM  dbo.Tables WITH(NOLOCK)                                                          
 WHERE  TableName = 'Variables'                         
)                                                          
                                                         
SET @RollsPUID =                                                          
(                                                          
 SELECT  PU_Id                                                          
 FROM  dbo.Prod_Units_Base WITH(NOLOCK)                                                          
 WHERE  pl_id = @LineId                                              
 AND  Pu_Desc LIKE '%Rolls%'                                                          
)                                                          
                                                          
SET @SheetbreakRateVarId =                                                             
(                                                          
  SELECT f.KeyId                                   
  FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Sheetbreak Rate') f                                                          
  JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
  WHERE  v.PU_id = @ProductionPUID                                   
)                                                          
                                                          
SET @SheetbreakWidthVarId =                                                          
(                                                   
  SELECT  f.KeyId                                                          
  FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Sheetbreak Width') f                                                          
  JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
  WHERE  v.PU_id = @ProductionPUID                                                           
)                                                          
                                                          
                                                          
                                                      
-- Get the "Target Production Hr Avg" var_id from an UDP                                                          
SET @TargetRateVarID =                                           
(                                                           
 SELECT  f.KeyId                                           
 FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Target Production') f                                                          
 JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE  v.PU_id = @ProductionPUID                                                          
)                                                          
                                                          
-- Get the "Ideal Target" var_id from an UDP                                                
SET @IdealTargetVarID =                                                          
(                                                           
 SELECT f.KeyId                                                          
 FROM dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Ideal Target') f                                                          
 JOIN dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE v.PU_id = @ProductionPUID                                                          
)                                                          
                                                          
-- Event_Type for 'User-defined Event'                                                          
SET @UDEEventType =                                                          
(                                                           
 SELECT  ET_Id                                                          
 FROM  dbo.Event_Types WITH(NOLOCK)                                                          
 WHERE  ET_Desc = 'User-Defined Event'                         
)                                                          
                                                          
SET @BeltPourTimeVarId =                                                          
(                                                          
 SELECT f.KeyId                                                          
 FROM dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Belt1 Pour Time') f                                                          
 JOIN dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE v.PU_id = @ProductionPUID                                                          
)                                                          
                                                          
SET @BeltSteamTimeVarId =                                                          
(                                                          
 SELECT f.KeyId                                                          
 FROM dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Belt1 Steam Time') f                                                   
 JOIN dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE v.PU_id = @ProductionPUID                                                          
)                                                          
                                                          
-- Get the "Production Rate Hr Avg" var_id from an UDP                                                          
SET @PouringRateVarId =                                                           
(                                                           
 SELECT  f.KeyId                                           
 FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Production Rate') f                                                          
 JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE  v.PU_id = @ProductionPUID                                                          
)                                                        
                                                          
-- Get the "Sheet Width Official" var_id from an UDP                                                          
SET @PouringWidthVarId =                                                          
(                                                           
   SELECT f.KeyId                                                          
   FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Turnover Width') f                                                        
   JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                 
   WHERE  v.PU_id = @ProductionPUID                                
)                                                   
                                                          
-- Get the "Winder Drum Avg" var_id from an UDP                                                          
-- SET @WinderDrumAvgVarId =                                                          
-- (                                                           
--  SELECT  f.KeyId                                                          
--  FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Winder Drum Avg') f                                                          
--  JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
--  WHERE  v.PU_id = @ProductionPUID                                                         
-- )                                                          
                   
SET @WinderDrumAvgVarId = (        
SELECT var_id FROM VARIABLES (NOLOCK)        
WHERE PU_ID = @ProductionPUID        
AND Extended_Info LIKE '%GlblDesc=Reel Speed Reel Avg%' )        
        
        
-- Get the "Belt Speed" var_id from an UDP                                                          
SET @BeltSpeedVarID =                                                 
(                                                           
 SELECT  f.KeyId                                                          
 FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Belt Speed') f                                                          
 JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE  v.PU_id = @ProductionPUID                                                          
)                                                          
                                                          
-- Event subtype for the pouring event UDE created on the line                                                          
SET @PourEventSubType =                                                          
(                                                           
 SELECT Event_Subtype_Id                                                          
 FROM  dbo.Event_SubTypes WITH(NOLOCK)                                                          
 WHERE  ET_Id = @UDEEventType                                                          
 AND  Event_Subtype_Desc = 'Pouring'                                               
)                                                          
                                                          
-- Get the "PctShrinkage" var_id from an UDP                                                          
SET @PctShrinkageVarID =                                                          
(                                                           
 SELECT f.KeyId                                                          
 FROM dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'PctShrinkage') f                                                          
 JOIN dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE v.PU_id = @ProductionPUID                                                          
)                                 
                                          
-- Get the Line_Desc for the report line (@LineID)                                                          
SET @LineDesc =                                                          
(                                                 
 SELECT  PL_Desc                                                          
 FROM  dbo.Prod_Lines_Base WITH(NOLOCK)                                                          
 WHERE  PL_Id = @LineID                                                          
)                                                            
                                                          
                                                          
----FOR Turnovers \ Rolls                                         
                                                          
-- Get the "Roll Length Official" var_id from an UDP                      
SET @RollLengthVarID  =              
(                                                           
   SELECT f.KeyId                                                          
   FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Roll Length') f                                        
   JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
   WHERE  v.PU_id = @RollsPUID                                                          
)                                                          
              
-- Get the "Roll Area Official" var_id from an UDP                                                        
SET @RollAreaVarID =                                                          
(                                                           
 SELECT  f.KeyId                         FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Roll Area') f                                                          
 JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE  v.PU_id = @RollsPUID                                                          
)                                                          
                                                          
                                                          
-- Table_Id for the dbo.Specifications table (for UDP retrieval)                                                          
SET @SpecVarTableID =                                                            
(                                                           
 SELECT  TableID                                                          
 FROM  dbo.Tables WITH(NOLOCK)                                    
 WHERE  TableName = 'Specifications'                                                          
)                             
                               
-- Get the characteristic that represents the line for getting line-level specifications                                                          
SET @FAMConfigCharID =                                                            
(                                                          
  SELECT  Char_Id                                                          
  FROM  dbo.Characteristics WITH(NOLOCK)                                                          
  WHERE  Extended_Info LIKE '%/FAMDDS-' + @LineDesc + '/%'                                                          
)                                                          
                                                          
-- Get the "Turnover Length" var_id from an UDP                                                          
SET @TurnoverLengthVarID =                                                              
(                                                           
 SELECT  f.KeyId                                                          
 FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Turnover Length') f                                                          
 JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE  v.PU_id = @ProductionPUID                                                          
)                                                          
                                                          
-- Get the "Sheet Width Official" var_id from an UDP                                                          
SET @TurnoverWidthVarId =                                   
(                                                           
 SELECT  f.KeyId                                                          
 FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Turnover Width') f                                 
 JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                   
 WHERE  v.PU_id = @ProductionPUID                                                          
)                                                          
                                                          
-- Get the "Sheet Width Official" var_id from an UDP                                                          
SET @TurnoverRollCountVarID =                        
(                                    
 SELECT  f.KeyId                                                          
 FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Turnover Roll Count') f                                                          
 JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                          
 WHERE  v.PU_id     = @ProductionPUID                                                          
)                                                          
                                                      
-- Get the "Yield Factor variable" var_id from an UDP                                                        
SET @YfwVarID  =                                                      
(                                                       
 SELECT f.KeyId                                                      
   FROM  dbo.fnLocal_STI_Cmn_GetUDPs (@VarTableID, @UDPThisReport, 'Yield Factor') f                                                      
   JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = f.KeyID                                                      
   WHERE  v.PU_id = @ProductionPUID                                                      
)                                                      
                                                      
-- Get turnover limits specifications based on hardcoded classification                                                          
SET @TurnoverTargetSpecID = (SELECT f.KeyID FROM dbo.fnLocal_STI_Cmn_GetUDPs(@SpecVarTableID, @UDPThisReport, 'Turnover-Target') f)                                                      
SET @TurnoverMediumSpecID = (SELECT f.KeyID FROM dbo.fnLocal_STI_Cmn_GetUDPs(@SpecVarTableID, @UDPThisReport, 'Turnover-Medium') f)                                                      
SET @TurnoverPlusSpecID   = (SELECT f.KeyID FROM dbo.fnLocal_STI_Cmn_GetUDPs(@SpecVarTableID, @UDPThisReport, 'Turnover-Plus') f)  --Plus                                                    
SET @TurnoverSmallSpecID  = (SELECT f.KeyID FROM dbo.fnLocal_STI_Cmn_GetUDPs(@SpecVarTableID, @UDPThisReport, 'Turnover-Small') f)                                                      
SET @TurnoverStubSpecID   = (SELECT f.KeyID FROM dbo.fnLocal_STI_Cmn_GetUDPs(@SpecVarTableID, @UDPThisReport, 'Turnover-Stubs') f)                                                      
SET @TargetSpecID         = (SELECT f.KeyID FROM dbo.fnLocal_STI_Cmn_GetUDPs(@SpecVarTableID, @UDPThisReport, 'Target Speed') f)                                          
                                      
--==========================                                      
PRINT ' GET Parameter Values'                                       
PRINT ' ***********************************************************************'                                       
PRINT ' --> RptStartDateTime: '          + CONVERT(VARCHAR(25), @RptStartTime)                                       
PRINT ' --> RptEndDateTime: '         + CONVERT(VARCHAR(25),@RptEndTime)                                        
PRINT ' --> PL DESC: '   + CONVERT(VARCHAR(25),@LineDesc)                                        
PRINT ' --> PL ID: '           + CONVERT(VARCHAR(25),@LineId)                                        
PRINT ' --> Production PUID: '          + CONVERT(VARCHAR(25),@ProductionPUID)                                        
PRINT  ' --> Rolls PUID: '         + CONVERT(VARCHAR(25),@RollsPUID)                                        
PRINT ' --> Sheet Break Rate VarId: '         + CONVERT(VARCHAR(25), @SheetbreakRateVarId)              
PRINT ' --> SheetbreakWidth VarId: '         + CONVERT(VARCHAR(25), @SheetbreakWidthVarId)                                       
PRINT ' --> IdealTarget VarID: '         + CONVERT(VARCHAR(25), @IdealTargetVarID)                                       
PRINT ' --> BeltPourTime VarId: '         + CONVERT(VARCHAR(25), @BeltPourTimeVarId)                                       
PRINT ' --> BeltSteamTime VarId: '         + CONVERT(VARCHAR(25), @BeltSteamTimeVarId)                                   
PRINT ' --> PouringRate VarId: '         + CONVERT(VARCHAR(25), @PouringRateVarId)             
PRINT ' --> PouringWidth VarId: '         + CONVERT(VARCHAR(25), @PouringWidthVarId)                                       
PRINT ' --> WinderDrumAvg VarId: '         + CONVERT(VARCHAR(25), @WinderDrumAvgVarId)                                       
PRINT ' --> BeltSpeed VarID: '          + CONVERT(VARCHAR(25), @BeltSpeedVarID)                                       
PRINT ' --> PctShrinkage VarID: '         + CONVERT(VARCHAR(25), @PctShrinkageVarID)                                       
PRINT ' --> RollLength VarID: '          + CONVERT(VARCHAR(25), @RollLengthVarID)                         
PRINT ' --> RollArea VarID: '          + CONVERT(VARCHAR(25), @RollAreaVarID)                                       
PRINT ' --> SpecVar TableID: '          + CONVERT(VARCHAR(25), @SpecVarTableID)                                       
PRINT ' --> FAMConfig CharID: '          + CONVERT(VARCHAR(25), @FAMConfigCharID)                                       
PRINT ' --> TurnoverLength VarID: '         + CONVERT(VARCHAR(25), @TurnoverLengthVarID)                                       
PRINT ' --> TurnoverWidth VarId: '         + CONVERT(VARCHAR(25), @TurnoverWidthVarId)                                       
PRINT ' --> TurnoverRollCount VarID: '         + CONVERT(VARCHAR(25), @TurnoverRollCountVarID)                                       
PRINT ' --> Yfw VarID: '          + CONVERT(VARCHAR(25), @YfwVarID)                                       
PRINT ' --> TurnoverTarget SpecID: '         + CONVERT(VARCHAR(25), @TurnoverTargetSpecID)                                       
PRINT ' --> TurnoverMedium SpecID: '         + CONVERT(VARCHAR(25), @TurnoverMediumSpecID)                                
PRINT ' --> TurnoverPlus SpecID: '         + CONVERT(VARCHAR(25), @TurnoverPlusSpecID)                                       
PRINT ' --> TurnoverSmall SpecID: '         + CONVERT(VARCHAR(25), @TurnoverSmallSpecID)                                       
PRINT ' --> TurnoverStub SpecID: '         + CONVERT(VARCHAR(25), @TurnoverStubSpecID)                                       
PRINT ' --> Target SpecID: '          + CONVERT(VARCHAR(25), @TargetSpecID)                                       
PRINT ' ***********************************************************************'                                       
                              
--==========================                                            
                                           
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('Availability','Availability 9\10','Availability','%')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('PRusingProductCount','PR using Product Count','PRusingProductCount','%')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('MSU','MSU','MSU','Stat Units')                                                  
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('AverageLanes','Average Lanes','AverageLanes','Lanes')                                           
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('TotalPourTime','Total Pour Time','TotalPourTime','Hours')                                            
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('WindPercent','Wind % Pour','WindPercent','%')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('SheetBreakCount','Sheetbreaks (Line Stops)','SheetBreakCount','Sheetbreaks')                       
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('SheetBreakMin','Sheetbreak Time','SheetBreakMin','Minutes')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('BreaksPerDay','Breaks/Day (24hrs)','BreaksPerDay','Sheetbreaks')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('MinutesBreak','Minutes / Break','MinutesBreak','Minutes')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('BreaksPerMSU','Breaks/MSU','BreaksPerMSU','Sheetbreaks')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('Downtime','Downtime','Downtime','Hours')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('Uptime','Uptime','Uptime','Hours')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('BeltSpeed','Belt 1 Speed','BeltSpeed','Meters/Minute')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('PctShrinkage','Shrinkage','PctShrinkage','%')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('ReelSpeed','Calculated Speed @ Reel','ReelSpeed','Meters/Minute')                               
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('WinderDrumAvg','Winder Vac Drum Speed','WinderDrumAvg','Meters/Minute')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('Belt1SteamTime','Belt 1 Steam Time','Belt1SteamTime','Hours')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('Belt1PourTime','Belt 1 Pour Time','Belt1PourTime','Hours')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('TotalScrap','Total Scrap %','TotalScrap','%')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('FMDL','FMDL ','FMDL','%')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('FMDS','FMDS ','FMDS','%')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('FMRJ','FMRJ ','FMRJ','%')                    
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('TargetRolls','Target Roll Turnovers','TargetRolls','Rolls')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('MeduimRolls','Meduim Roll Turnovers','MeduimRolls','Rolls')                                                  
--INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('PlusRolls','Plus Roll Turnovers','PlusRolls','Rolls')                                                  
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('SmallRolls','Small Roll Turnovers','SmallRolls','Rolls')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('StubRolls','Stub Roll Turnovers','StubRolls','Rolls')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('TotalMetersMade','Total Meters Made','TotalMetersMade','Meters')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('GoodMetersWound','Good Meters Wound','GoodMetersWound','Meters')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('ProductionTime','Line Status Schedule Time','ProdTime','Minutes')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('ScheduleUtil','Schedule Utilization','ScheduleUtil','%')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('RateUtil','Rate Utilization','RateUtil','%')                                                      
INSERT INTO @ColumnVisibility(VariableName,LabelName,FieldName,Unit) VALUES('CapacityUtil','Capacity Utilization','CapacityUtil','%')                                                      
                                                      
                                      
--********************************************************************************************************************************                                             
--End - Section 3 - Initialize Variables                                                       
--********************************************************************************************************************************                                             
                                                      
--********************************************************************************************************************************                                                          
--End - Section 4 - Team Runs                                                      
                                                      
-- Parse report parameter @Teams                                                          
-- If "All" teams are selected, get the teams that were in crew_schedule at this moment. We will still calculate stats with all teams, but                                                          
-- at the moment of filling the @PrdStats table, we'll only have one "ALL" line which will regroup all teams.                                                          
--********************************************************************************************************************************                                                          
                                                      
IF @RptShifts <> '!Null'                                                      
 BEGIN                                                      
   SET @ShiftDESCList = @RptShifts                                                
                                                        
   INSERT INTO #RptShifts(pKey, ShiftDesc)                                                      
   EXEC dbo.SPCMN_ReportCollectionParsing                                      
    @PRMCollectionString = @RptShifts,                                                      
    @PRMFieldDelimiter = NULL,                                                      
    @PRMRecordDelimiter = ',',                                                       
    @PRMDataType01 = 'VARCHAR(25)'                                                      
 END                                                      
ELSE                                                
 BEGIN                                                      
   SET @ShiftDESCList = @lblAll                                                       
     
   INSERT INTO #RptShifts(ShiftDesc)                                                      
   SELECT  Distinct Shift_Desc                                                          
   FROM dbo.Crew_Schedule cs WITH(NOLOCK)                                                      
   WHERE cs.pu_id = @RollsPUID AND Start_Time <= @RptEndTime AND (End_Time > @RptStartTime)                                                          
 END                                          
                                                      
IF @RptTeams <> '!Null'                                                      
 BEGIN                                                      
   SET @CrewDESCList = @RptTeams                                                      
                                                        
   INSERT INTO #RptTeams(pKey, TeamDesc)                                                      
   EXEC dbo.SPCMN_ReportCollectionParsing                                                      
    @PRMCollectionString = @RptTeams,                                                      
    @PRMFieldDelimiter = NULL,                                                      
    @PRMRecordDelimiter = ',',                          
    @PRMDataType01 = 'VARCHAR(25)'                                                      
 END                                                      
ELSE                                                      
 BEGIN                                                      
   SET @CrewDESCList = @lblAll                                                       
                                                        
   INSERT INTO #RptTeams(TeamDesc)                                                      
   SELECT  DISTINCT CREW_Desc                                                          
   FROM dbo.Crew_Schedule cs WITH(NOLOCK)                                                          
   WHERE cs.pu_id = @RollsPUID AND Start_Time <= @RptEndTime AND (End_Time > @RptStartTime)                                                          
 END                                                          
                                      
                                      
-- BUILDING TEAM RUNS FOR THE REPORT TIME FRAME AND FILTERING TEAMS AS PER SELECTION                                                          
                                      
 INSERT INTO #TeamRuns                                                           
  (                                                          
   Team,                                                          
   Shift,                                                          
   StartTime,                                                          
   EndTime                                                
  )                           
 SELECT                                       
    cs.Crew_Desc,                                                          
    cs.Shift_Desc,                                                         
  -- Get start_time for product run (decide between report start time or product run start time                          
   CASE WHEN cs.Start_Time < @RptStartTime  THEN @RptStartTime                                                          
   ELSE cs.Start_Time END AS StartTime,                                                          
  -- Get end_time for product run (decide between report end time or product run end time                 
  CASE WHEN cs.End_Time > @RptEndTime OR  cs.End_Time IS NULL   THEN @RptEndTime                                                          
   ELSE cs.End_Time  END AS EndTime                                                          
 FROM dbo.Crew_Schedule cs  WITH(NOLOCK)                                                          
 JOIN dbo.#RptTeams  r  WITH(NOLOCK) ON r.TeamDesc  = cs.Crew_Desc                                                          
 JOIN dbo.#RptShifts s  WITH(NOLOCK) ON s.ShiftDesc = cs.Shift_Desc                         
 WHERE cs.PU_Id = @RollsPUID                                                          
  AND (                                                          
     (                                                          
       cs.Start_Time <= @RptStartTime                                                          
       AND                                                          
       (                                                          
         cs.End_Time > @RptStartTime                                                          
         OR                                                          
         cs.End_Time IS NULL                                                          
       )                                                   
     )                                                          
     OR                                                          
     (                                                          
       cs.Start_Time >= @RptStartTime                                                          
       AND                                                          
       cs.Start_Time < @RptEndTime                                                          
     )                                                          
   )                                                          
                                                          
--********************************************************************************************************************************                                                          
--End - Section 4 - Team Runs                                                      
--********************************************************************************************************************************                                                          
                                                      
--********************************************************************************************************************************                                   
--Start - Section 5 - Sheet Breaks                                                      
-- Get the sheetbreaks                                                            
-- Sheetbreaks are all the DTs on production production unit minus those who have a fault of @TurnoverFaultID/@MasterUnitDownFaultID                                                            
--********************************************************************************************************************************                                                          
                                                          
INSERT INTO #Sheetbreaks                                                        
(                                                            
  TEDET_Id,                                                            
  StartTime,                                                            
  EndTime,                                                            
  TEFault_Id,                                                            
  Source_PU_Id,                                                            
  Reason1,                                                  
  Reason2,                                                            
  Reason3,                                                            
  Reason4,                                    
  EventReasonTreeDataID                   
)                                                            
SELECT                                                       
  ted.TEDet_Id,                                                            
--   ted.Start_Time,                                       
--   isnull(ted.End_Time, @RptEndTime), -- When downtime is still open, take Report's end time as DT's end time.                                                            
Case       
   When ted.Start_Time < @RptStartTime THEN @RptStartTime      
   Else ted.Start_Time      
  End,      
  Case      
   --When ted.End_Time Is null THEN @Now      
   When ted.End_Time Is null THEN @RptEndTime -- JJR 4/24/03      
   When ted.End_Time > @RptEndTime THEN @RptEndTime      
   Else ted.End_Time      
  End,  
  ted.TEFault_Id,                                                            
  ted.Source_PU_Id,                                                            
  ted.Reason_Level1,                                                            
  ted.Reason_Level2,                                                            
  ted.Reason_Level3,                                 
  ted.Reason_Level4,                                                            
  ted.Event_Reason_Tree_Data_Id                                                            
 FROM  dbo.Timed_Event_Details ted WITH(NOLOCK)                                                            
 JOIN  dbo.Prod_Units_Base pu    WITH(NOLOCK) ON pu.Pu_Id = ted.Source_Pu_Id                                                            
 WHERE  ted.Start_Time < @RptEndTime  --and  ted.Start_Time >= @RptStartTime                                                        
 AND  (                                                            
     ted.End_Time > @RptStartTime                                                            
     OR                                                            
     ted.End_Time IS NULL                                                            
    )                                                            
 AND  (                                                            
     pu.PU_Desc LIKE '%Curing Oven%'                                                            
     OR                                                            
     pu.PU_Desc LIKE '%Dewatering%'                                                            
     OR                                                            
     pu.PU_Desc LIKE '%Winder%'                                                            
     OR                                                            
     pu.PU_Desc LIKE '%Dryer%'                                                            
    )     
 AND  ted.Pu_Id = @ProductionPUID                                                            
                 
                                       
-- Identify the Extended downtimes                                                            
-- Extended: all DTs who have a start_time that equals the end_time of another DT on same unit      
-- SELECT * FROM #Sheetbreaks order by starttime                                                       
UPDATE #Sheetbreaks                                                            
SET  Extended = 1                                                            
WHERE  StartTime IN                                                            
(                                                            
    SELECT  t.End_Time                                                            
    FROM   dbo.Timed_Event_Details t WITH(NOLOCK)                                                            
    WHERE   t.PU_Id = @ProductionPUID                                                         
    AND   t.Start_Time > @RptStartTime                                                            
)                                                            
                                                          
-- Identify primary downtimes                                                            
-- By definition, all downtimes that are not extended are primary                                                            
UPDATE #Sheetbreaks  SET  Extended = 0                                                            
WHERE  Extended IS NULL                                                            
                                                 
-- Calculate for each DT their duration (End_Time - Start_Time). For precision purposes, we calculate the duration in seconds.                                                     
UPDATE #Sheetbreaks                                                            
SET  Duration = DATEDIFF(ss, StartTime, EndTime)                                   
       
                                                            
UPDATE #Sheetbreaks                                                            
SET  Duration = (Duration / CONVERT(NUMERIC(15,2), 60))                                                            
                                                         
--Update Shifts in SheetBreaks Table                                                      
UPDATE  #Sheetbreaks  SET Team=tr.Team, Shift=tr.Shift                                                          
FROM #Sheetbreaks SE                                                          
JOIN  #TeamRuns TR ON SE.EndTime > TR.StartTime AND (SE.EndTime <= TR.EndTime OR TR.EndTime IS NULL)                                                           
                                                            
DELETE  #Sheetbreaks WHERE Team IS NULL AND Shift IS NULL -- Filter Option                                                          
                                                         
--********************************************************************************************************************************                                                          
--End - Section 5 - Sheet Breaks                                                      
--********************************************************************************************************************************                                       
                                                          
--*********************************************************************************************************************************************                                                          
--Start - Section 6 - Turnover Events                                                      
-- Get all the limits for turnovers in the report timeframe. In the event that we have more than one specification active for each turnover                                                          
-- classification in the report window, we need to have one line per classification specification shown in the report.                                                          
                                                      
--*********************************************************************************************************************************************                                                          
                                                      
    INSERT INTO #Turnovers (LimitDesc, SpecVarID, LLimitValue, ULimitValue, StartTime, EndTime)                                                          
    SELECT  CASE WHEN a.Spec_Id = @TurnoverTargetSpecID                                                          
        THEN 'TARGET'                                                          
        WHEN a.Spec_Id = @TurnoverMediumSpecID                                                          
        THEN 'MEDIUM'                                                          
        WHEN a.Spec_Id = @TurnoverPlusSpecID   --Plus                                                    
        THEN 'PLUS'      --Plus                                                    
        WHEN a.Spec_Id = @TurnoverSmallSpecID                                                          
        THEN 'SMALL'                                                          
        WHEN a.Spec_Id = @TurnoverStubSpecID                                                          
        THEN 'STUB'                                                       
       END AS LimitDesc,                                
       a.Spec_Id,                                                          
       a.L_Reject,                                                          
       a.U_Reject,                                                    
       CASE WHEN a.Effective_Date < @RptStartTime                                                       
         THEN @RptStartTime                                                          
         ELSE a.Effective_Date                                                          
       END AS StartTime,                                 
       CASE WHEN a.Expiration_Date > @RptEndTime                                                           
         THEN @RptEndTime                                                          
  ELSE a.Expiration_Date                                                        
       END AS EndTime                          
    FROM dbo.Active_Specs a WITH(NOLOCK)                                                          
    WHERE a.Spec_Id IN            
    (                                      
     @TurnoverTargetSpecID,                                                 
     @TurnoverMediumSpecID,                                                          
     @TurnoverPlusSpecID,     --Plus                                                    
     @TurnoverSmallSpecID,                                                          
     @TurnoverStubSpecID                                                      
    )                                                          
    AND  a.Char_Id = @FAMConfigCharID                                                          
    AND a.Effective_Date <= @RptEndTime                                                          
    AND                                                       
    (                                     
      a.Expiration_Date >= @RptStartTime                                                          
      OR                                                              
      a.Expiration_Date IS NULL                                         
     )                                                          
    ORDER BY a.Spec_Id ASC, StartTime DESC                                                          
                            
                            
DELETE #Turnovers WHERE  LLimitValue IS NULL AND ULimitValue IS NULL                                                          
 ----------------------------------------------------------------------------------                                                          
 -- GETTING @Turnover Events - START OF SECTION                                                          
 -- Get the turnover events in the report timeframe                                                          
 ----------------------------------------------------------------------------------                                                          
                                                      
   INSERT INTO #TurnoverEv                                                           
   (                                                          
    EventID,                                                          
    EventStartTime,                                                
    EventEndTime,                                                
    StartTime,               
    EndTime,                                                          
    Status                                                          
   )                                                       
   SELECT Event_Id,                                                          
    Start_Time,                                                          
    [TimeStamp],                                                          
    Start_Time,                                                          
    [TimeStamp],                                                          
    Event_Status                                                          
   FROM dbo.Events WITH(NOLOCK)                                                             
   WHERE PU_Id = @ProductionPUID                                                          
   AND  Start_Time < @RptEndTime                                                   
   AND ([Timestamp] >= @RptStartTime AND [Timestamp] IS NOT NULL)                                                          
                                                      
                                                    
UPDATE #TurnoverEv                                                      
SET                                   
   Length = ISNULL((                                                      
     SELECT CONVERT(NUMERIC(7,2), t.Result)                                                      
     FROM  dbo.Tests t WITH(NOLOCK)                                                      
     WHERE  t.Var_Id = @TurnoverLengthVarID                                                      
     AND  t.Result_On = EndTime                                                      
     ), 0),                                                      
   Width = ISNULL((                                                      
     SELECT CONVERT(NUMERIC(7,2), t.Result)                                                      
     FROM  dbo.Tests t WITH(NOLOCK)                                                      
     WHERE  t.Var_Id = @TurnoverWidthVarID                                   
     AND  t.Result_On = EndTime                                                      
     ), 0)                                            
                           
                                      
-- calculate area of each turnover    --                                                      
UPDATE #TurnoverEv                                                          
   SET Area = (Length * (Width / 1000))                     
                    
-- Classify each turnover                                                          
UPDATE te                                                          
   SET te.Type =                                                          
   (                                                          
 SELECT t.LimitDesc                                                          
 FROM #Turnovers t                                                          
  WHERE                             
   (                                             
           te.EndTime > t.StartTime and (te.EndTime <= t.EndTime OR t.EndTime IS NULL )                                                         
   )                                                 
  AND ISNULL(t.LLimitValue, (SELECT MIN(te2.Length) - 1 FROM #TurnoverEv te2)) < te.Length                                                         
  AND ISNULL(t.ULimitValue, (SELECT MAX(te2.Length) + 1 FROM #TurnoverEv te2)) >= te.Length                                                       
    )                                                          
   FROM #TurnoverEv te                               
                                               
                                                             
--   DELETE #TurnoverEv Where Type is NULL -- Type is not       --Plus                                         
                                                      
UPDATE #TurnoverEv                                                          
 SET BeltSpeed =                                                          
  (                                                          
 SELECT AVG(CONVERT(NUMERIC(10,2), t.Result))                                                      
 FROM dbo.Tests t WITH(NOLOCK)                                                           
 WHERE t.Var_Id = @BeltSpeedVarID                                                          
 AND  t.Result IS NOT NULL              
 AND  t.Result_On > te.StartTime                                                          
 AND  t.Result_On <= te.EndTime                                                           
  )                                                      
 FROM #TurnoverEv te                                                      
                                            
                                          
UPDATE #TurnoverEv                                                          
 SET YFW =                         
  (                                                          
 SELECT ISNULL(AVG(CONVERT(NUMERIC(10,2), t.Result)), 1.0)                                                      
 FROM dbo.Tests t WITH(NOLOCK)                                                           
 WHERE t.Var_Id = @YfwVarID                                                          
 AND t.Result IS NOT NULL                                                          
 AND  t.Result_On > te.StartTime                                                          
 AND  t.Result_On <= te.EndTime            
                                                            
  )                                                      
 FROM #TurnoverEv te                                                      
                                               
--Calculate the BELT1SPEED   @WinderDrumAvgVarId                                    
UPDATE #TurnoverEv                                             
SET Belt1ActualSpeed =                                                       
 (                                                      
 SELECT AVG(CONVERT(NUMERIC(15,2),Result))                                                      
 FROM dbo.Tests WITH(NOLOCK)                                                      
 WHERE Var_Id = @BeltSpeedVarID                                                      
 AND Result_On > StartTime   -- Edited                                                      
 AND Result_On <=  EndTime                              
 AND Result IS NOT NULL                                     
 ),                                                      

Belt1SetSpeed =                                                        
 (                                                      
 SELECT Result                                                       
 FROM dbo.Tests WITH(NOLOCK)                                                      
 WHERE Var_Id = @BeltSpeedVarID                                          
 AND Result_On =                                                        
        (                                                      
          SELECT MAX(Result_On)                                                      
          FROM dbo.Tests WITH(NOLOCK)                                                      
          WHERE Var_Id = @BeltSpeedVarID                                                      
          AND Result_On <=  EndTime                                                      
          AND Result IS NOT NULL                                                      
        )                                                      
 ),                                           
LastGood_Belt1Speed =                                       
 (                                      
 SELECT MAX(Result_On)                                                      
 FROM dbo.Tests WITH(NOLOCK)                                                      
 WHERE Var_Id = @BeltSpeedVarID                                                      
 AND Result_On <=  EndTime                                                      
 AND Result IS NOT NULL                                               
 ),                                      
-- WinderActualSpeed =                                                      
--  (                                                      
--  SELECT AVG(CONVERT(NUMERIC(15,2),Result))                                                      
--  FROM dbo.Tests WITH(NOLOCK)                                                      
--  WHERE Var_Id = @WinderDrumAvgVarId                                                      
--  AND Result_On > StartTime   -- Edited                                                      
--  AND Result_On <=  EndTime                              
--  AND Result IS NOT NULL                                     
--  )                         
WinderActualSpeed =                                                      
 (                                                      
   SELECT Result                                                       
 FROM dbo.Tests WITH(NOLOCK)                                                      
 WHERE Var_Id = @WinderDrumAvgVarId                                          
 AND Result_On =                                                        
        (                                                      
          SELECT MAX(Result_On)                                                      
          FROM dbo.Tests WITH(NOLOCK)                                                      
          WHERE Var_Id = @WinderDrumAvgVarId                                                      
          AND Result_On <=  EndTime                                                      
          AND Result IS NOT NULL                                                      
    )                                                                  
 )                                                     
                                                  
                                            
UPDATE #TurnoverEv                                                      
SET TargetSpeed =                                                      
 (                                                      
    SELECT a.Target                                                     
    FROM dbo.Active_Specs a WITH(NOLOCK)                                                      
    WHERE Spec_Id = @TargetSpecID                                                  
    AND a.Char_Id = @FAMConfigCharID                                                   
    AND Effective_Date <= Endtime                                            
     AND                                                       
     (                                                          
       Expiration_Date >= Starttime                                            
                                                         
       OR                                                              
       Expiration_Date IS NULL                                                          
      )                                                          
 )                                            
                                            
UPDATE #TurnoverEv                                                      
SET ActualDuration =                                           
  (                                          
   Length / ( WinderActualSpeed * YFW )                           
  )                                        
WHERE   WinderActualSpeed IS NOT NULL AND WinderActualSpeed > 0.0                                      
                                  
UPDATE #TurnoverEv                                                      
SET ActualStartTime =                                           
  (                                          
  CONVERT(DATETIME,EndTime) - (ActualDuration * .0006944333)                                          
  )                                          
                                          
--Updating LastGood_value to NULL if it's not between the event start & end time.                                      
UPDATE #TurnoverEv                                                      
SET LastGood_Belt1Speed = NULL                                          
WHERE LastGood_Belt1Speed BETWEEN EventStarttime AND EventEndtime                                      
                                                   
        
--*********************************************************************************************************************************************                                                          
--End - Section 6 - Turnover Events                                                      
--*********************************************************************************************************************************************                                                          
                                                      
--*********************************************************************************************************************************************                                                          
--Start - Section 7 - Roll Events                                                      
--*********************************************************************************************************************************************                                               
                                                       
 SET @TurnoverLastEndTime = (SELECT DATEADD(SS, 10, MAX(EndTime)) FROM #TurnoverEv)                                                          
                                                       
 --Get the roll events and area                                                          
 INSERT #RollEvents (EventId, ParentId, EventStartTime, EventEndTime, StartTime, EndTime, Length, Width, Area, Status)                                                          
 SELECT r.Event_Id, r.Source_Event, p.Start_Time, r.Timestamp, p.Start_Time, r.Timestamp, NULL, NULL, CONVERT(NUMERIC(15,2), t.Result), r.Event_Status                                                          
 FROM                                                          
 dbo.Events r WITH(NOLOCK)                                                           
 LEFT JOIN dbo.Tests t WITH(NOLOCK) ON (t.Result_On = r.TimeStamp)                                                          
 LEFT JOIN dbo.Events p WITH(NOLOCK) ON (r.Source_Event = p.Event_Id)                                                           
 WHERE                                                          
  t.Var_Id = @RollAreaVarID                                                          
  AND r.PU_Id = @RollsPUID                                                  
  AND t.Result_On   >=   @RptStartTime                                                          
  AND t.Result_On   <=   @TurnoverLastEndTime                                             
 ORDER BY p.Start_Time                                                
                                                       
                                       
--Updating rolls with length                                                          
UPDATE r                                                          
 SET  Length =                                                  
 (                                           
   SELECT t.Result  FROM dbo.Tests t WITH(NOLOCK)                                                          
   WHERE  t.Result_On = r.EndTime                                                         
   AND t.Var_Id = @RollLengthVarID                                                          
)                                                          
 FROM  #RollEvents r                                                          
                                        
                            
 --Getting Type from the turnover                
UPDATE  r                                                          
 SET                                       
 Type  = (SELECT  t.Type  FROM #TurnoverEv t WHERE t.EventId = r.ParentId),                                      
 Width  = (SELECT t.Width  FROM #TurnoverEv t WHERE t.EventId = r.ParentId),                                      
 YFW  = (SELECT  t.YFW  FROM #TurnoverEv t WHERE t.EventId = r.ParentId)                                                          
 FROM #RollEvents r                                          
                                      
-- DELETE #RollEvents Where Type is NULL -- Type is not      --Plus                                                                      
                                      
-- Select * from #TurnoverEv        
          
--Change                                      
UPDATE  #RollEvents                                                
 SET EstimatedDuration = T.ActualDuration, EstimatedStartTime = T.ActualStartTime , ReelSpeed = T.WinderActualSpeed          
FROM #RollEvents R                                          
INNER JOIN #TurnoverEv T ON T.EventID = R.ParentID                                          
          
-- --Change                                          
-- UPDATE  #RollEvents                                                
--   SET ReelSpeed =                               
--   (                                    
--    CASE WHEN EstimatedDuration IS NULL THEN NULL                                          
--    ELSE   Length / EstimatedDuration  END                                          
--   )                                          
--                                           
--                                           
-- UPDATE  #TurnoverEv                                                
--   SET ReelSpeed =                                           
--    (                                          
--      SELECT AVG(ReelSpeed)                                          
--      FROM #RollEvents R                                          
--      WHERE R.ParentID = T.EventID                                          
--    )                                          
--   FROM #TurnoverEv T                                          
                                         
-- UPDATE  #TurnoverEv                                                
--   SET ActualDuration =                                           
--    (                                          
--     CASE                                       
--     WHEN ReelSpeed IS NULL THEN  NULL                                          
--      ELSE Length / (ReelSpeed * YFW)                                          
--     END                                          
--    )                                          
                                            
                                      
-- UPDATE #TurnoverEv                                                
--   SET  ActualStartTime =                                           
--    (                                          
--     CONVERT(DATETIME,EndTime) - (ActualDuration * .0006944333)                                          
--    )                                          
                                        
UPDATE #TurnoverEv                                                          
    SET  RollCount                                      
 = (                                                          
      SELECT CONVERT(NUMERIC(7,2), t.Result)                                                          
      FROM  dbo.Tests t WITH(NOLOCK)                                
      WHERE  t.Var_Id   = @TurnoverRollCountVarID                                                          
      AND  t.Result_On   = EndTime                                                          
      )                       
                    
                   
-- Filter Events which does not belong to Window TimeFrame.                                
DELETE #TurnoverEv WHERE ActualStartTime > @RptEndTime                                
DELETE #RollEvents WHERE EstimatedStartTime > @RptEndTime                      
                    
                    
--Calculate PartialLength                                                          
UPDATE #TurnoverEv                                                          
   SET  PartialLength =                                                           
    CASE                                                           
     WHEN ActualStartTime < @RptStartTime                                                           
      THEN CAST(DATEDIFF(SS, @RptStartTime, EndTime) AS FLOAT) /                                          
        CAST(DATEDIFF(SS, ActualStartTime, EndTime) AS FLOAT) * Length                                                          
     WHEN EndTime > @RptEndTime                                                           
      THEN CAST(DATEDIFF(SS, StartTime, @RptEndTime) AS FLOAT) /                                                           
        CAST(DATEDIFF(SS, StartTime, EndTime) AS FLOAT) * Length                                 
     ELSE Length                                                   
    END                                                          
                                                          
   -----------------------------------------------                                            
   -- For MSU math                                                          
   -----------------------------------------------                                                          
                                           
                                        
--Updating partial area for all rolls                                                          
UPDATE #RollEvents                                                          
 SET                                                           
 PartialArea =                                                           
  CASE                                                           
  WHEN EstimatedStartTime < @RptStartTime THEN                                                           
   CAST(DATEDIFF(SS, @RptStartTime, EndTime) AS FLOAT) /                                                           
   CAST(DATEDIFF(SS, EstimatedStartTime, EndTime) AS FLOAT) * Area                                                          
  WHEN EndTime > @RptEndTime THEN                                                           
  CAST(DATEDIFF(SS, StartTime, @RptEndTime) AS FLOAT) /                                                           
   CAST(DATEDIFF(SS, StartTime, EndTime) AS FLOAT) * Area                                                          
  ELSE                                                           
   Area                                             
  END,                                                          
 PartialLength =                                                           
  CASE                                                           
  WHEN EstimatedStartTime < @RptStartTime THEN                                                           
   CAST(DATEDIFF(SS, @RptStartTime, EndTime) AS FLOAT) /                                                           
   CAST(DATEDIFF(SS, EstimatedStartTime, EndTime) AS FLOAT) * Length                                                          
  WHEN EndTime > @RptEndTime THEN                                                           
   CAST(DATEDIFF(SS, StartTime, @RptEndTime) AS FLOAT) /                                        
   CAST(DATEDIFF(SS, StartTime, EndTime) AS FLOAT) * Length                                                          
  ELSE                                                           
   Length                                                           
  END                           
                                        
--=========================================================================                             
                    
                    
--Updating start time \ end time for the first\ Last Turnover                                                          
UPDATE  #TurnoverEv  SET StartTime = @RptStartTime  WHERE StartTime < @RptStartTime                                             
UPDATE  #TurnoverEv  SET EndTime = @RptEndTime      WHERE EndTime > @RptEndTime          
          
--To Avoid Split          
UPDATE  #TurnoverEv  SET StartTime = ActualStartTime  WHERE StartTime < ActualStartTime                                             
                          
          
                    
--Updating start time \ end time for the first\ Last rolls                                                          
UPDATE #RollEvents SET StartTime = @RptStartTime WHERE StartTime < @RptStartTime                                                          
UPDATE #RollEvents SET EndTime = @RptEndTime  WHERE EndTime > @RptEndTime                                           
          
--To Avoid Split          
UPDATE  #RollEvents  SET StartTime = EstimatedStartTime  WHERE StartTime < EstimatedStartTime                                             
          
                                                        
                    
----===================NEED TO SPLIT TEAM WISE FOR TURNOVERS\ ROLLS ============================                    
DECLARE CrewStatusSplit INSENSITIVE CURSOR FOR (                             
  SELECT EndTime FROM #TeamRuns) ORDER BY EndTime                        
                            
  FOR READ ONLY                        
 --                            
 OPEN CrewStatusSplit                             
 --                            
 FETCH NEXT FROM CrewStatusSplit INTO @CurEndTime                            
 --                            
 WHILE @@Fetch_Status = 0                            
 --                            
 BEGIN                             
                          
INSERT INTO #TurnoverEv                     
  (                    
  EventID,                    
  EventStartTime,                    
  EventEndTime,                    
  StartTime,                    
  EndTime,                    
  EstimatedStartTime,                    
  EstimatedDuration,                    
  ReelSpeed,                    
  ActualStartTime,                    
  ActualDuration,                    
  Status,                    
  Length,                    
  Width,                    
  Area,                    
  BeltSpeed,                    
  YFW,                    
  Type,                    
  RollCount,                    
  TargetSpeed,                    
  Belt1SetSpeed,                    
  Belt1ActualSpeed,                    
  WinderActualSpeed,                    
  LastGood_Belt1Speed,                    
  TeamSplitFlag                    
  )                    
   SELECT                     
   EventID,                    
   EventStartTime,                    
   EventEndTime,                    
   @CurEndTime,                    
   EndTime,                    
   EstimatedStartTime,                    
   EstimatedDuration,                    
   ReelSpeed,                    
   ActualStartTime,                    
   ActualDuration,                    
   Status,                    
   Length,                    
   Width,                    
   Area,                    
   BeltSpeed,                    
   YFW,                    
   Type,                    
   RollCount,                    
   TargetSpeed,                    
   Belt1SetSpeed,                    
   Belt1ActualSpeed,                    
   WinderActualSpeed,                    
   LastGood_Belt1Speed,                    
   1                    
   FROM #TurnoverEv                         
   WHERE StartTime < @CurEndTime                            
   AND (EndTime > @CurEndTime OR EndTime IS NULL)                            
                            
                            
  UPDATE #TurnoverEv                            
   Set EndTime = @CurEndTime,TeamSplitFlag=1                             
   WHERE StartTime < @CurEndTime                            
    AND (EndTime > @CurEndTime OR EndTime IS NULL)                             
INSERT INTO #RollEvents                     
  (                    
  EventID,                    
  ParentId,                    
  EventStartTime,                    
  EventEndTime,                    
  StartTime,--@CurEndTime                    
  EndTime,                    
  EstimatedStartTime,                    
  EstimatedDuration,                    
  ReelSpeed,                    
  YFW,                    
  Status,                    
  Type,                    
  Length,                    
  Width,                    
  Area,                    
  TeamSplitFlag                    
  )                    
   SELECT                     
  EventID,                    
  ParentId,                    
  EventStartTime,                    
  EventEndTime,                    
  @CurEndTime,--@CurEndTime                    
  EndTime,                    
  EstimatedStartTime,                    
  EstimatedDuration,                    
  ReelSpeed,                    
  YFW,                    
  Status,                    
  Type,                    
  Length,                    
  Width,                    
  Area,                    
  1                    
   FROM #RollEvents                             
   WHERE StartTime < @CurEndTime                            
   AND (EndTime > @CurEndTime OR EndTime IS NULL)                            
                            
                            
  UPDATE #RollEvents                            
   Set EndTime = @CurEndTime,TeamSplitFlag=1                             
   WHERE StartTime < @CurEndTime                            
    AND (EndTime > @CurEndTime OR EndTime IS NULL)                          
                        
  FETCH NEXT FROM CrewStatusSplit INTO @CurEndTime                            
 END                             
                             
 CLOSE CrewStatusSplit                             
 DEALLOCATE CrewStatusSplit                    
----======================================================================                    
                    
                    
---=======Calculating Partial Length For Splits                    
                    
UPDATE #TurnoverEv                                                          
 SET                
 PartialLength =                     
  CASE                                                           
  WHEN ActualStartTime > EndTime                                                           
  THEN 0.0                    
  WHEN ActualStartTime < StartTime THEN                    
  CAST(DATEDIFF(SS, StartTime, EndTime) AS FLOAT) /                                                           
  CAST(DATEDIFF(SS, ActualStartTime, EventEndTime) AS FLOAT) * Length                     
  ELSE                    
  CAST(DATEDIFF(SS, ActualStartTime, EndTime) AS FLOAT) /                                                        
  CAST(DATEDIFF(SS, ActualStartTime, EventEndTime) AS FLOAT) * Length                     
  END              
WHERE TeamSplitFlag =1                     
                    
              
UPDATE #RollEvents                            
 SET                      
 PartialArea =                    
   CASE                                                           
   WHEN EstimatedStartTime > EndTime                                                           
   THEN 0.0                    
   WHEN EstimatedStartTime < StartTime Then                    
   CAST(DATEDIFF(SS, StartTime, EndTime) AS FLOAT) /                                                           
   CAST(DATEDIFF(SS, EstimatedStartTime, EventEndTime) AS FLOAT) * Area                     
   ELSE                    
   CAST(DATEDIFF(SS, EstimatedStartTime, EndTime) AS FLOAT) /                                                           
   CAST(DATEDIFF(SS, EstimatedStartTime, EventEndTime) AS FLOAT) * Area                     
   END,                    
 PartialLength =                     
   CASE                                                           
   WHEN EstimatedStartTime > EndTime                                                           
   THEN 0.0                    
   WHEN EstimatedStartTime < StartTime Then                    
   CAST(DATEDIFF(SS, StartTime, EndTime) AS FLOAT) /                                                           
   CAST(DATEDIFF(SS, EstimatedStartTime, EventEndTime) AS FLOAT) * Length                     
   ELSE                    
   CAST(DATEDIFF(SS, EstimatedStartTime, EndTime) AS FLOAT) /                                                           
   CAST(DATEDIFF(SS, EstimatedStartTime, EventEndTime) AS FLOAT) * Length                     
   END                    
WHERE TeamSplitFlag =1                     
                    
                    
--Updating TEAMS & SHIFTS                                           
UPDATE  #TurnoverEv                                                      
    SET Team=tr.Team, Shift=tr.Shift                                                          
FROM  #TurnoverEv TE                                                          
JOIN  #TeamRuns TR ON TE.EndTime > TR.StartTime AND (TE.EndTime <= TR.EndTime OR TR.EndTime IS null)                                                            
                                      
--Updating TEAMS & SHIFTS                                      
UPDATE  #RollEvents                                                          
 SET  Team=tr.Team, Shift=tr.Shift                                                          
FROM    #RollEvents RE                                                          
JOIN    #TeamRuns TR ON RE.EndTime > TR.StartTime AND (RE.EndTime <= TR.EndTime OR TR.EndTime IS null)                                          
                                        
                                      
-- Filter Condition                                      
DELETE #RollEvents WHERE Team IS NULL AND Shift IS NULL                                        
DELETE #TurnoverEv WHERE Team IS NULL AND Shift IS NULL                                     
                    
                                        
                                      
UPDATE #RollEvents                                      
SET Timeequivalent =                                      
(                                       
 CASE                                       
  WHEN ( (Width/1000) * ReelSpeed * Yfw ) = 0.0 THEN NULL                                      
  ELSE PartialArea / ( (Width/1000) * ReelSpeed * Yfw )                                      
 END                                      
)                                
                    
                    
UPDATE #TurnoverEv                                                          
    SET RollTotalLength = PartialLength * CAST(RollCount AS FLOAT)                        
                          
--WHERE Type= 'STUB' AND ( STATUS = @RejectStatus OR Status =@HoldStatus )                                      
                                      
--=========================================================================                                        
                                        
--*********************************************************************************************************************************************                                                          
--End - Section 7 - Roll Events                                                      
--*********************************************************************************************************************************************                                                          
                                                         
--*********************************************************************************************************************************************                                                          
--Start - Section 8 - Sheet break top 5                                                      
--*********************************************************************************************************************************************                                                          
                                                          
 --1. We first get all Timed_Event_Details entries within report window.                                                          
 INSERT #TED1 (Start_Time, End_Time, Uptime, TEFault_Id, Reason_Level2)                                                          
 SELECT start_time, end_time, Uptime, TEFault_Value, ted.Reason_Level2                                                          
 FROM  dbo.Timed_Event_Details ted WITH(NOLOCK)                                                          
 JOIN  dbo.Timed_Event_Fault tef  WITH(NOLOCK) ON tef.TEFault_Id = ted.TEFault_Id                                                          
 WHERE  ted.PU_id = @ProductionPUID                                                          
 AND ted.start_time < @RptEndTime                                                          
 AND (ted.end_time > @RptStartTime OR ted.end_time IS NULL)                                                          
 AND Uptime IS NOT NULL                                                          
 ORDER BY start_time ASC                                                          
                                                       
 --2. We store start_time of the first entry.                
 SET @MinStart = (SELECT Start_Time FROM #TED1 WHERE Ted_Id = 1)                                                         
                                                       
 --3. We insert again all Timed_Event_Details entries within report window (Report End Time + 7 days)                                                          
 --   (We do + 7 days to make sure we get very first entry after report window. We need this entry in order to calculate)                                                          
 INSERT @TED2 (Start_Time, End_Time, Uptime, TEFault_Id, Reason_Level2)                                                        
 SELECT start_time, end_time, Uptime, TEFault_Value, ted.Reason_Level2                                                          
 FROM  dbo.Timed_Event_Details ted WITH(NOLOCK)                                                          
 JOIN  dbo.Timed_Event_Fault tef  WITH(NOLOCK) ON tef.TEFault_Id = ted.TEFault_Id                                                          
 WHERE  ted.PU_id = @ProductionPUID                               
 --AND tef.TEFault_Value > 31                                                          
 --AND                                                          
 --tef.TEFault_Value < 7500                              
 AND ted.start_time < DATEADD(DD, 7,@RptEndTime)                                                          
 AND (ted.end_time > @RptStartTime OR ted.end_time IS NULL)                                                          
 AND ted.start_time > @MinStart                                                          
 AND Uptime IS NOT NULL                                                          
 ORDER BY start_time ASC                                                          
                                                       
 --4. Here we match Primary and Working tables together. We want Uptime and Start_Time values from the next event for each entry                                                          
 --   of the primary table                                           
 UPDATE ted1                                                          
 SET                                                          
 Uptime2 = ted2.Uptime * 60.0,                                                          
 Start_Time2 = ted2.Start_Time                                                          
 FROM                                                          
 @TED2 ted2,                                                          
 #TED1 ted1                                                          
 WHERE                                                          
 ted2.ted_id = ted1.ted_id                                                          
                                                       
 --5. Having Uptime and Start_Time of the next event, We can then calculate End_Time for each entry.       
 UPDATE #TED1 SET End_Time2 = DATEADD(SS, -1 * CAST(Uptime2 AS INT), Start_Time2)                                  
                            
-- GET MAX END TIME OF ROLL EVENT                            
 IF EXISTS (SELECT * FROM #TED1 WHERE END_TIME2 is NULL)                             
 BEGIN                      
 SET @MinStart=(Select MAX(EndTime)FROM #Sheetbreaks)                            
 UPDATE #TED1 SET End_Time2 = @MinStart WHERE END_TIME2 is NULL                            
 END                                                    
                                                       
 --6. Doing correction for report window overlapping entries                                                          
 UPDATE #TED1                                                          
 SET                                                          
 Start_Time = @RptStartTime                                             
 WHERE                                                          
 Start_Time < @RptStartTime                                                          
                                                       
 --7. Doing correction for report window overlapping entries                                                          
 UPDATE #TED1                                                          
 SET                                                          
 End_Time2 = @RptEndTime                                                          
 WHERE                                                          
 End_Time2 > @RptEndTime         

 UPDATE #TED1 SET IsSheetbreak= 1

-- ----===================NEED TO SPLIT TEAM WISE FOR #TED ============================

DECLARE CrewStatusSplit INSENSITIVE CURSOR FOR ( SELECT EndTime FROM #TeamRuns) ORDER BY EndTime

  FOR READ ONLY                      
 --                          
 OPEN CrewStatusSplit                           
 --                          
 FETCH NEXT FROM CrewStatusSplit INTO @CurEndTime                          
 --                          
 WHILE @@Fetch_Status = 0                          
 --                          
 BEGIN                           
                        
INSERT INTO #TED1                   
  (                  
	Start_Time,
	End_Time,
	Uptime,                                                
	TEFault_Id,
	Reason_Level2, 
	--Uptime2,                                               
	--Start_Time2,                                            
	End_Time2,                                              
	IsSheetbreak                                                  
  )                  
SELECT                   
	@CurEndTime,                  
	End_Time,
	Uptime,                                                
	TEFault_Id,
	Reason_Level2, 
	--Uptime2,                                               
	--Start_Time2,                                            
	End_Time2,
	0                     
FROM #TED1                       
WHERE Start_Time < @CurEndTime                          
AND (End_Time > @CurEndTime OR End_Time IS NULL)                          
                          
                          
UPDATE #TED1                          
Set End_Time = @CurEndTime,Uptime=0,End_Time2= @CurEndTime                          
WHERE Start_Time < @CurEndTime                          
AND (End_Time > @CurEndTime OR End_Time IS NULL)                           
                       
                      
  FETCH NEXT FROM CrewStatusSplit INTO @CurEndTime                          
END                           
                           
 CLOSE CrewStatusSplit                           
 DEALLOCATE CrewStatusSplit                  
-- ----==================================================

                                         
 --8. Calculating durations                                                          
 UPDATE #TED1 SET Duration = DATEDIFF(SS, Start_Time, End_Time2) / 60.0                                                          
                                                       
 --9. Getting Level 2 reason names                                                          
 UPDATE ted1                                                          
 SET                                                          
 Reason2 = er.Event_Reason_Name                                                          
 FROM                                                          
 Event_Reasons er                                                          
 LEFT JOIN #TED1 ted1 ON (ted1.Reason_Level2 = er.Event_Reason_Id)                                                          
                                                       
 --10. Just in case we have missing reasons               
 UPDATE #TED1                                              
 SET                                                          
 Reason2 = COALESCE(Reason2, 'Missing reasons')                                                          
                                                       
                                      
 UPDATE #TED1                                                       
 SET Team=tr.Team, Shift=tr.shift                                                          
 FROM #TED1 sb                                                          
 JOIN #TeamRuns tr ON sb.end_time > tr.StartTime AND (sb.end_time <= tr.EndTime OR tr.EndTime IS NULL)          
                                                       
 DELETE #TED1 WHERE Team IS NULL AND Shift IS NULL -- Need clarification    
  
  
--*********************************************************************************************************************************************                                                   
--End - Section 8 - Sheet break top 5                                                      
--*********************************************************************************************************************************************                               
                                                          
                                                          
                                                
--*********************************************************************************************************************************************                                                          
--Start - Section 9.1 - Measures - Losses (Downtime , uptime, schedule run time, FMDS,FMDL)                                
--*********************************************************************************************************************************************                                                          
                                                          
 -- Get line statuses in the report window                                                          
 INSERT INTO @LineStatuses                                                           
 (                                                          
  Phrase,                                                          
  StartTime,                                                          
  EndTime,                                                          
  PRIN                                                          
 )                                                          
   SELECT p.Phrase_Value,                                                          
   -- Get start_time                                                          
   CASE WHEN ls.Start_datetime < @RptStartTime                                                           
     THEN @RptStartTime                                                          
     ELSE ls.Start_datetime                                                          
   END AS StartTime,                                                  
   -- Get end_time                                                          
   CASE WHEN ls.End_datetime > @RptEndTime                                                           
     OR  ls.End_datetime IS NULL                                                          
     THEN @RptEndTime                        
     ELSE ls.End_datetime                                                          
   END AS EndTime,                                                          
   -- Determine if line status is PR:IN or PR:OUT                                                          
   CASE WHEN p.Phrase_Value LIKE 'PR IN:%'                                                          
     THEN 1                                                          
     WHEN p.Phrase_value LIKE 'PR OUT:%'                                                          
     THEN 0                                                          
     ELSE NULL                                                          
   END AS PRIN                                                          
  FROM dbo.Local_PG_Line_Status ls WITH(NOLOCK)                                                          
   JOIN dbo.Phrase p   WITH(NOLOCK) ON p.Phrase_Id = ls.Line_Status_Id                                                          
   WHERE ls.Unit_Id = @ProductionPUID                                                          
   AND                                  
  (                                                          
   (                                         
    ls.Start_datetime <= @RptStartTime                                                          
    AND                                                  
    (                                                          
     ls.End_datetime > @RptStartTime                                                          
     OR                                                          
     ls.End_datetime IS NULL                                                          
    )                                              
   )                                                          
   OR                                                          
   (                                                          
    ls.Start_datetime >= @RptStartTime                                                          
    AND                                                          
   ls.Start_datetime < @RptEndTime                                                          
   )                                                          
  )                                                          
                           
 --Logic to split line status                                                          
                    
 DECLARE                                     
 @Phrase    VARCHAR(25),                                                          
 @StartTime   DATETIME,                                                          
 @EndTime   DATETIME,                                                          
 @PRIN    BIT                                                          
                                                           
 DECLARE RSMiCursor INSENSITIVE CURSOR FOR                                                           
 (                                                          
  SELECT StartTime,EndTime, phrase,PRIN FROM  @LineStatuses                                              
 )    ORDER BY StartTime                                                          
 OPEN RSMiCursor                                                              
 FETCH NEXT FROM RSMiCursor INTO @StartTime,@EndTime, @phrase, @PRIN                                                             
                                                                 
 WHILE @@Fetch_Status = 0 --and @i < 10                                           
 BEGIN                                                              
                                                               
  INSERT INTO #DownUptime                                                           
  (                                                          
   Team  ,                                                          
   Shift  ,                                                          
   StartTime ,                                                          
   EndTime  ,                                                          
   LineStatus ,                                                          
   PRIN                                                              
  )                                                          
  SELECT cs.Crew_Desc,                                                          
   cs.Shift_Desc,                                                          
   -- Get start_time for product run (decide between report start time or product run start time                                                       
   CASE WHEN cs.Start_Time < @StartTime                                                           
    THEN @StartTime                                                          
     ELSE cs.Start_Time                                                          
   END AS StartTime,                                                          
   -- Get end_time for product run (decide between report end time or product run end time                                                                    
   CASE WHEN cs.End_Time > @EndTime                                                           
     OR  cs.End_Time IS NULL                                                          
     THEN @EndTime                                                          
     ELSE cs.End_Time                                                          
   END AS EndTime,                  
  @phrase,                                       
  @PRIN                                                          
  FROM dbo.Crew_Schedule cs  WITH(NOLOCK)                                                   
  JOIN dbo.#RptTeams r   WITH(NOLOCK) ON r.TeamDesc = cs.Crew_Desc                                                          
  JOIN dbo.#RptShifts s  WITH(NOLOCK) ON s.ShiftDesc = cs.Shift_Desc                                                          
  WHERE cs.PU_Id = @RollsPUID                                                          
  AND (                                                          
    (                                                          
     cs.Start_Time <= @StartTime                                                          
     AND                                                          
     (                                                          
      cs.End_Time > @StartTime                                               
      OR                                                          
      cs.End_Time IS NULL                                         
     )                                                          
    )                                                          
    OR                                                          
    (                                                          
     cs.Start_Time >= @StartTime                                                          
     AND                                                          
     cs.Start_Time < @EndTime                                                          
    )                                                          
   )                                                                
                                              
   FETCH NEXT FROM RSMiCursor INTO @StartTime,@EndTime, @phrase, @PRIN                         
                 END                                                    
                                                               
   CLOSE  RSMiCursor                                                              
   DEALLOCATE RSMiCursor                                                                
                                                        
                                      
DELETE #DownUptime WHERE Team IS NULL AND Shift IS NULL -- Need clarification                                       
                                      
                                      
 -- DTDuration: For each line status, get the sum of downtime durations (in seconds)                                                          
 UPDATE l                                                           
 SET l.DTDuration =                                                           
 (                                                          
  SELECT isnull                                                          
  (                                                          
   SUM                                                          
 (                                          
    DATEDIFF                                                          
    (                                                          
     ss,                                                          
      -- Get start_time                                                          
     CASE WHEN ted.Start_Time < l2.StartTime                                                           
       THEN l2.StartTime                                                          
       ELSE ted.Start_Time                                                          
     END,                                                          
      -- Get end_time                                                          
     CASE WHEN ted.End_Time > l2.EndTime                                                           
   OR  ted.End_Time IS NULL                                                    
       THEN l2.EndTime                                                          
       ELSE ted.End_Time                                                          
     END                                                          
    )                                                          
   )                                                 
   , 0                                                          
  )                                                          
  FROM dbo.Timed_Event_Details ted WITH(NOLOCK)                                                          
  JOIN #DownUptime l2     ON l2.Pkey = l.PKey                                                          
  JOIN dbo.Timed_Event_Fault tef WITH(NOLOCK) ON tef.TEFault_Id = ted.TEFault_Id                                                          
  WHERE ted.PU_id = @ProductionPUID                                                          
  AND tef.TEFault_Value = 0                                                          
  AND                                                           
  (                                                          
   (                                                          
    ted.Start_Time <= l.StartTime                                                          
    AND                                                          
     (                                                          
     ted.End_Time > l.StartTime                                                          
     OR                                                          
     ted.End_Time IS NULL                                                          
     )                                                          
    )                                                          
    OR                                                          
    (                                                          
    ted.Start_Time >= l.StartTime                                                          
    AND                                                          
    ted.Start_Time < l.EndTime                                                          
   )                                                    
   )                                                          
  )                                                          
 FROM   #DownUptime l                                                          
                                                           
--Start - FMDS FMDL FMRJ                                                      
                                                         
-- DTDuration: For each line status, get the sum of downtime durations (in seconds)                                                          
UPDATE l                                                           
SET l.DTLiquids =                      
(                                                          
 SELECT isnull                                                          
    (                              
     SUM                                                          
     (                     
      DATEDIFF                                                          
      (                                                          
       ss,                                                          
       -- Get start_time                                                          
       CASE WHEN ted.Start_Time < l2.StartTime                                                           
         THEN l2.StartTime                                                          
         ELSE ted.Start_Time                                                          
       END,                                                          
       -- Get end_time                                                          
       CASE WHEN ted.End_Time > l2.EndTime                                                           
         OR  ted.End_Time IS NULL                                                          
         THEN l2.EndTime                                                          
         ELSE ted.End_Time                                                          
       END                                                          
      )                                                      )                                                          
     , 0                                                          
    )                                                          
 FROM  dbo.Timed_Event_Details ted WITH(NOLOCK)                                        
 JOIN  #DownUptime l2     ON l2.Pkey = l.PKey                                               
 JOIN  dbo.Timed_Event_Fault tef WITH(NOLOCK) ON tef.TEFault_Id = ted.TEFault_Id                                                       
 WHERE  ted.PU_id = @ProductionPUID                                                         
 AND  (                                       
     tef.TEFault_Value > 0            
     AND                                                          
     tef.TEFault_Value < 30                                                          
    )                          
    AND                                                            
    (                                                          
     (                                                          
      ted.Start_Time <= l.StartTime                                                          
      AND                                                          
      (                                                          
       ted.End_Time > l.StartTime                                                          
       OR                                                          
       ted.End_Time IS NULL                                                          
      )                                                          
     )                                                          
     OR                                                          
     (                                                          
      ted.Start_Time >= l.StartTime                                                          
      AND                                                          
      ted.Start_Time < l.EndTime                                                        
     )                                                          
    )                                                          
 )                                                          
                                                          
FROM   #DownUptime l                                                          
                                                          
-- DTDuration: For each line status, get the sum of downtime durations (in seconds)                                                          
UPDATE l                                                           
SET l.DTSolids =                                                           
(                                                          
 SELECT isnull                                                           
    (                                                          
     SUM                                                          
     (                                                          
      DATEDIFF                                                          
      (                                                          
       ss,                                                          
       CASE WHEN ted.Start_Time < l2.StartTime                                                           
         THEN l2.StartTime                         
         ELSE ted.Start_Time                                                          
       END,                                                          
       CASE WHEN ted.End_Time > l2.EndTime                                                           
         OR  ted.End_Time IS NULL                                                          
         THEN l2.EndTime                                                          
         ELSE ted.End_Time                                                          
       END                                          
      )                                                          
     )                                                          
     , 0                                                          
    )                                                          
 FROM  dbo.Timed_Event_Details ted WITH(NOLOCK)         
 JOIN  dbo.Timed_Event_Fault tef WITH(NOLOCK) ON tef.TEFault_Id = ted.TEFault_Id                                                          
 JOIN  #DownUptime l2  ON l2.Pkey = l.PKey                                                          
 WHERE  ted.PU_id = @ProductionPUID                                                          
 AND  (                                                          
    tef.TEFault_Value > 31 AND tef.TEFault_Value < 7500                                  
   )                                                          
 AND  (                                                          
    (                                                          
     ted.Start_Time <= l.StartTime                                            
     AND                                             
     (                                                          
      ted.End_Time > l.StartTime OR ted.End_Time IS NULL                                                          
     )                                                          
    )                                                          
   OR                                                          
    (                                         
     ted.Start_Time >= l.StartTime AND ted.Start_Time < l.EndTime                                                          
   )                                                          
   )                                         
)                                                          
FROM   #DownUptime l                                                          
                                                          
UPDATE #DownUptime                                                           
SET    GlblIncUptime   = ISNULL(DATEDIFF(ss, StartTime, EndTime), 0)                                                           
WHERE PRIN = 1                                                          
                                                           
UPDATE #DownUptime                                                           
SET   Uptime   = GlblIncUptime - DTDuration                                                          
                                                           
-- FAM Making Scheduled Time (in seconds)                                                          
-- It is the time wihin report window that we were producing (PRIN)                                                          
Update #DownUptime                                                          
SET FAMMakingSchTime = (SELECT DATEDIFF(ss, DU.StartTime, DU.EndTime))                                            
FROM #DownUptime DU                                                          
WHERE PRIN = 1                                                          
                                                          
-- calculate master unit uptime for FMxx measures (uptime = scheduled time - downtimes) DTDuration                                        
Update #DownUptime                                                      
SET MasterUnitUpTime = CONVERT(NUMERIC(15,4), FAMMakingSchTime) - CONVERT(NUMERIC(15,4), DTDuration)                                                          
FROM #DownUptime DU                                                          
WHERE PRIN = 1                                                          
                                       
--*********************************************************************************************************************************************                                                          
--End - Section 9.1 - Measures - Losses (Downtime , uptime, schedule run time, FMDS,FMDL)                                                      
--*********************************************************************************************************************************************                                                          
                                                          
                                                      
--*********************************************************************************************************************************************                                                     
--Start - Section 9.2 - Measures - Utilization                             
--*********************************************************************************************************************************************                                                                              
UPDATE #DownUptime                                                           
SET IdealTarget =                                                           
 (                                                          
 SELECT  AVG(CONVERT(NUMERIC(10,6), t.Result))                                                          
 FROM   dbo.Tests t WITH(NOLOCK)                                                          
 WHERE   t.Var_Id = @IdealTargetVarID                                                          
 AND   t.Result_On > StartTime    --TCS                          
 AND   t.Result_On <= EndTime                                                          
 AND   t.Result IS NOT NULL                                        
 )                                                          
,IdealCnt=                                                          
 (                                                          
 SELECT COUNT(t.Result)                                                          
 FROM   dbo.Tests t WITH(NOLOCK)                                                          
 WHERE   t.Var_Id = @IdealTargetVarID                                                          
 AND   t.Result_On > StartTime    --TCS                                                      
 AND   t.Result_On <= EndTime                                                          
 AND   t.Result IS NOT NULL                                                          
 )                                                          
                                                          
, TargetRate =                                                          
(                                                          
  SELECT AVG(CONVERT(NUMERIC(15,6),  t.Result))                                                          
  FROM dbo.Tests t WITH(NOLOCK)                                      
  WHERE t.Var_Id = @TargetRateVarID                                                          
  AND t.Result_On > StartTime    --TCS                                                      
  AND t.Result_On <=  EndTime                                                          
AND t.Result IS NOT NULL                                                          
)                                                          
, TargetCnt =                                                          
(                                                          
  SELECT COUNT(t.Result)                                                          
  FROM dbo.Tests t WITH(NOLOCK)                                                          
  WHERE t.Var_Id = @TargetRateVarID                                                          
  AND t.Result_On > StartTime    --TCS                                                      
  AND t.Result_On <=  EndTime                                                          
  AND t.Result IS NOT NULL                                                          
)                                                          
                                                          
--*********************************************************************************************************************************************                                                          
--End - Section 9.2 - Measures - Utilization                                                      
--*********************************************************************************************************************************************                                                          
                                                          
                                           
--*********************************************************************************************************************************************                                  
--Start - Section 9.3 - Measures - Pour                                
-- This section fills the pour events stats part of the report.                                       
-- It takes its informations from the pouring UDEs on the "production" production unit.                                                    
-- Get all Pour events in report timeframe                                               
--*********************************************************************************************************************************************                                                          
                                                           
 INSERT INTO #PourEvents (Number, StartTime, EndTime)                                                          
  SELECT u.UDE_Desc,                                                     
  -- Get start_time for pour event (decide between report start time or pour event start time                                                                    
  CASE WHEN u.Start_Time < @RptStartTime                                 
    THEN @RptStartTime                                                          
    ELSE u.Start_Time                                                          
  END AS StartTime,                                                          
  -- Get end_time for pour event (decide between report end time or pour event end time                                                                    
  CASE WHEN u.End_Time > @RptEndTime                                                           
    OR  u.End_Time IS NULL                                                      
    THEN @RptEndTime                                                          
    ELSE u.End_Time                                                          
  END AS EndTime                                                          
  FROM dbo.User_Defined_Events u WITH(NOLOCK)                                                          
  WHERE u.Event_Subtype_Id = @PourEventSubType                                                          
  AND (                                                          
   (                                                          
    u.Start_Time <= @RptStartTime                                                          
    AND                                                          
    (                                                          
     u.End_Time > @RptStartTime                                                          
     OR                                                          
     u.End_Time IS NULL                                                          
    )                                                          
   )                                                          
   OR                                                          
   (                                                          
    u.Start_Time >= @RptStartTime                                                          
    AND                                
    u.Start_Time < @RptEndTime                                                          
   )                                                  
  )                                                          
                        
                      
--                      
Update #PourEvents                       
Set ActualStartTime=StartTime,ActualEndTime=EndTime                      
                      
                        
---Split it as per Team                        
--DECLARE @CurEndTime DATETIME                        
                        
DECLARE CrewStatusSplit INSENSITIVE CURSOR FOR (                             
  SELECT EndTime FROM #TeamRuns) ORDER BY EndTime                            
                            
  FOR READ ONLY                        
 --                            
 OPEN CrewStatusSplit                             
 --                            
 FETCH NEXT FROM CrewStatusSplit INTO @CurEndTime                            
 --   
 WHILE @@Fetch_Status = 0                            
 --                            
 BEGIN                             
                          
  INSERT INTO #PourEvents (Number, StartTime, EndTime)                          
  SELECT 'ShiftSplit', @CurEndTime, EndTime                        
   FROM #PourEvents                         
   WHERE StartTime < @CurEndTime                            
    AND (EndTime > @CurEndTime OR EndTime IS NULL)                            
                            
                            
  UPDATE #PourEvents                            
   Set EndTime = @CurEndTime                            
   WHERE StartTime < @CurEndTime                            
    AND (EndTime > @CurEndTime OR EndTime IS NULL)                            
                        
  FETCH NEXT FROM CrewStatusSplit INTO @CurEndTime                            
 END                             
                             
 CLOSE CrewStatusSplit                             
 DEALLOCATE CrewStatusSplit                       
-----                        
                                                           
--- Update Shfit\Team assignment                                                          
UPDATE  #PourEvents                                                          
 SET     Team=tr.Team, Shift=tr.Shift                                                          
FROM  #PourEvents PE                                                          
JOIN  #TeamRuns TR ON PE.EndTime > TR.StartTime AND (PE.EndTime <= TR.EndTime OR TR.EndTime IS null)                        
                                            
----FILTERING TEAMS & SHIFTS                                      
DELETE #PourEvents WHERE Team IS NULL AND Shift IS NULL                                                         
                                      
-- Retrieve width AND length AND calculate duration for each pouring event                                                          
UPDATE #PourEvents                                                          
 SET                                                           
 Width = ISNULL(                                                          
  (                                                          
   SELECT CONVERT(NUMERIC(7,2), t.Result)                                                      
   FROM  dbo.Tests t WITH(NOLOCK)                                                          
   WHERE  t.Var_Id = @PouringWidthVarID                                                          
   AND  t.Result_On =                                                           
       (                                                          
        SELECT MIN(Result_On)                                                      
        FROM dbo.Tests WITH(NOLOCK)                                                          
        WHERE Var_Id = @PouringWidthVarID                                                          
        AND Result_On >= StartTime                                                          
        AND Result IS NOT NULL                                                          
        AND CONVERT(NUMERIC(10,4), Result) != 0.0000                                                          
       )                                                          
   )                                                          
  , 0),                                      
 Rate = ISNULL(                                                          
 (                                                          
   SELECT CONVERT(NUMERIC(10,4), t.Result)                                                          
   FROM  dbo.Tests t WITH(NOLOCK)                                       
   WHERE  t.Var_Id = @PouringRateVarID                                                          
   AND  t.Result_On = (                                                          
        SELECT MIN(Result_On)                                                          
 FROM  dbo.Tests WITH(NOLOCK)                                                          
        WHERE  Var_Id = @PouringRateVarID                                                          
        AND  Result_On >= StartTime                                                          
        AND  Result IS NOT NULL                                                          
        AND  CONVERT(NUMERIC(10,4), Result) != 0.0000                        
       )                                                          
  )                                                          
  , 0),                                                          
  TotalTime = DATEDIFF(ss, StartTime, EndTime)                                                          
           
 -- Calculate an average on the belt speeds tests for the report window                                                        
Update #PourEvents                                                          
 SET BeltSpeed =                                                          
 (                                                          
  SELECT COALESCE(AVG(CONVERT(NUMERIC(10,2), t.Result)), 0.0)                                                          
  FROM dbo.Tests t WITH(NOLOCK)                                                           
  WHERE t.Var_Id = @BeltSpeedVarID                                            
  AND t.Result IS NOT NULL                                                          
  AND  t.Result_On > pe.StartTime                                                          
  AND  t.Result_On <= pe.EndTime                                                           
                                                           
 ),                                           
                                                      
 -- calculate winder vacuum drum average speed over report duration          
WinderDrumAvg =                                                      
 (                                                      
   SELECT Result                                                       
 FROM dbo.Tests WITH(NOLOCK)                                                      
 WHERE Var_Id = @WinderDrumAvgVarId                                          
 AND Result_On =                                                        
        (                                                      
          SELECT MAX(Result_On)                                                      
          FROM dbo.Tests WITH(NOLOCK)                                                      
          WHERE Var_Id = @WinderDrumAvgVarId                                                      
          AND Result_On <=  pe.EndTime                                                      
          AND Result IS NOT NULL                                                      
        )                                                                  
 )                                                             
-- WinderDrumAvg =                                                          
--  (                                                          
--   SELECT AVG(CONVERT(NUMERIC(10,4), Result))                                                          
--   FROM dbo.Tests WITH(NOLOCK)                                                          
--   WHERE Var_Id = @WinderDrumAvgVarId                                                          
--   AND Result_On > pe.StartTime                                                          
--   AND Result_On <= pe.EndTime                                                           
--   AND Result IS NOT NULL                                                          
--  )                                                      
 FROM #PourEvents pe                                                          
                           
UPDATE #PourEvents                                                          
SET CONVERSION_SPEED = (CASE WHEN (COALESCE(BeltSpeed, 0.0) * (1 - 0.03) * 0.9655) > (COALESCE(WinderDrumAvg, 0.0) * 0.9655)                                                           
        THEN (COALESCE(BeltSpeed, 0.0) * (1 - 0.03) * 0.9655)                                                          
        ELSE (COALESCE(WinderDrumAvg, 0.0) * 0.9655) END)                                                          
                                                           
 -- calculate good production                                                          
UPDATE #PourEvents         
 SET GoodProduction = (TotalTime / 60) * @CONVERSION_WIDTH * CONVERSION_SPEED                                                          
           
                                      
DElETE FROM #PourEvents WHERE TotalTime <= 0                                                          
    
-- commented out for script Martin              
/*                                         
 -- Get the running product for each pour event                                                          
UPDATE pe                                       
 SET pe.ProdCode =                                                          
 (                                                          
  SELECT p.Prod_Code                                                          
  FROM dbo.Products_Base p WITH(NOLOCK)                                                          
  WHERE p.Prod_Id = (SELECT dbo.fnLocal_STI_Cmn_GetRunningProduct (@ProductionPUID, pe.StartTime))                                                          
 )                                                          
 FROM #PourEvents pe                                                          
  */                                                         
 -- Sum up all the pour events's durations                                                          
 SET @PourTotalTime = CONVERT(NUMERIC(15,2), (SELECT SUM(TotalTime) FROM #PourEvents))                                                          
                                                           
 -- Calculate PctTime for each turnover                                                          
UPDATE #PourEvents                                                          
 SET PctTotalTime = (CONVERT(NUMERIC(15,2), TotalTime) / CASE WHEN @PourTotalTime = 0                                                      
         THEN NULL                                                           
         ELSE @PourTotalTime                                                           
         END) * CONVERT(NUMERIC(15,2), 100)                                                          
    
-- commented out for script Martin              
/*                                                           
 -- Retrieve PctShrinkage from the specification on the line variable                                                          
UPDATE pe                                                          
 SET PctShrinkage =                                                          
 (                                                          
  SELECT TOP 1 vs.Target                                                          
  FROM  dbo.Var_Specs vs WITH(NOLOCK)                                                          
  JOIN  dbo.Variables_Base v WITH(NOLOCK) ON v.Var_Id = vs.Var_Id                                                          
  WHERE  vs.Var_Id = @PctShrinkageVarID                                    
  AND  vs.Prod_Id = (SELECT dbo.[fnLocal_STI_Cmn_GetRunningProduct](v.PU_Id, pe.EndTime))                                                          
  AND  vs.Effective_Date <= pe.EndTime                            AND  (                                                  
      vs.Expiration_Date > pe.EndTime                                                          
      OR                                                          
      vs.Expiration_Date IS NULL                                                          
     )                                                          
  ORDER BY vs.Effective_Date DESC                                                          
 )                   
 FROM #PourEvents pe                                                          
*/
                                        
 -- Calculate an average on the reel speeds based on PctShrinkage AND Belt1Speed                                                        
UPDATE #PourEvents                                                          
 SET ReelSpeed = (BeltSpeed - (BeltSpeed * (PctShrinkage / CONVERT(NUMERIC(5,2), 100))))                                                          
                                                           
 -- retrieve belt1 pour time                                                          
UPDATE #PourEvents                                                          
 SET BeltPourTime = (                                                          
   SELECT Result                                                          
   FROM  dbo.Tests WITH(NOLOCK)                                                          
   WHERE  Var_Id = @BeltPourTimeVarId                                                          
   AND  Result_On = (                                                          
           SELECT max(Result_On)                                                          
           FROM  dbo.Tests WITH(NOLOCK)                                                          
           WHERE  Var_Id = @BeltPourTimeVarId                                                          
           AND  Result IS NOT NULL                                                          
           AND  Result_On <= pe.EndTime                                                          
          )                                                          
  )                                                          
FROM #PourEvents pe                                              
                                                           
UPDATE #PourEvents                                                          
 SET BeltSteamTime =  (                                                          
   SELECT Result                                                          
   FROM  dbo.Tests WITH(NOLOCK)                                                          
   WHERE  Var_Id = @BeltSteamTimeVarId                                                          
   AND  Result_On = (                                                          
           SELECT MAX(Result_On)                                                          
      FROM  dbo.Tests WITH(NOLOCK)                                                          
           WHERE  Var_Id = @BeltSteamTimeVarId                                                          
           AND  Result IS NOT NULL                                                          
           AND  Result_On <= pe.EndTime                                                          
          )                                                          
  )                                                          
 FROM #PourEvents pe                                                          
                                                      
-- Retrieve belt1 pour time                                                          
SET @BeltPourTimeAGG =                                                           
(                                                          
 SELECT Result                                                          
 FROM  dbo.Tests WITH(NOLOCK)                                                          
 WHERE  Var_Id = @BeltPourTimeVarId                                                          
 AND  Result_On =                                                           
 (                                                          
      SELECT MAX(Result_ON)                                                          
      FROM  dbo.Tests WITH(NOLOCK)                                                          
      WHERE  Var_Id = @BeltPourTimeVarId    
      AND  Result IS NOT NULL                                                 
      AND  Result_On > @RptStartTime                             
      AND  Result_On <= @RptEndTime                                                          
     )                                                          
)                                                          
                                                          
-- Retrieve belt1 steam time                                                          
SET @BeltSteamTimeAGG =                                                            
(                                                          
 SELECT Result                                             
 FROM  dbo.Tests WITH(NOLOCK)                                          
 WHERE  Var_Id = @BeltSteamTimeVarId                                                          
 AND  Result_On =                                                           
(                                                          
      SELECT max(Result_On)                     
      FROM  dbo.Tests WITH(NOLOCK)                                                          
      WHERE  Var_Id = @BeltSteamTimeVarId                                                          
      AND  Result IS NOT NULL                                                          
      AND  Result_On > @RptStartTime                                                           
      AND  Result_On <= @RptEndTime                                                          
     )                                   
)                                                          
                                                          
--*********************************************************************************************************************************************                                                
--End - Section 9.3 - Measures - Pour                                                          
--*********************************************************************************************************************************************                                                          
                                                      
--*********************************************************************************************************************************************                                                          
--Start - Section 10 - Preparing the Summary Table \ Top 5 SheetBreaks - Header                                                      
--*********************************************************************************************************************************************                                                          
                                                          
INSERT #Summary   (GroupField,null01,null02,AGGregate) VALUES ('Minor','Unit of Measure',@RPTMinorGroupBy,'Total' )                                                              
INSERT #Top5SheetBreaks (GroupField,Desc01, Desc02, Stops) VALUES ('Minor','Location Top Level', '', 'Count')                                                            
                                                          
IF @intShowStatic <> 0                                                        
 BEGIN                                                  
  IF @RPTMinorGroupBy = 'Team'                                                              
  BEGIN                                                              
  INSERT INTO @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)                                                           
  SELECT @LineID,@LineDesc,t.TeamName,t.TeamName,0,0 FROM Local_PG_Teams t (NOLOCK) WHERE t.TeamName NOT IN ('E Team', 'F Team')ORDER BY t.TeamName                                                      
 -- SELECT Distinct @LineID,@LineDesc,Team,Team,0,0 from #TeamRuns                                                          
  END                                      
  ELSE                                                          
  BEGIN                                                              
  INSERT INTO @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)                                                         
  SELECT DISTINCT @LineID,@LineDesc,Shift_Desc,Shift_Desc,0,0 FROM dbo.Crew_Schedule cs WITH(NOLOCK) WHERE cs.pu_id = @RollsPUID                                                         
  -- SELECT Distinct @LineID,@LineDesc,Shift,Shift,0,0 from #TeamRuns                                                          
  END                                                         
 END            
ELSE                                                      
 BEGIN                              
  IF @RPTMinorGroupBy = 'Team'                                                              
  BEGIN                                                              
  INSERT INTO @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)                                                 
  SELECT DISTINCT @LineID,@LineDesc,Team,Team,0,0 FROM #TeamRuns                                                          
  --SELECT @LineID,@LineDesc,TeamName,TeamName,0,0 FROM Local_PG_Teams (NOLOCK) ORDER BY TeamName                                                      
  END                                       
  ELSE                    
  BEGIN                                                              
  INSERT INTO @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)                                                         
  SELECT DISTINCT @LineID,@LineDesc,Shift,Shift,0,0 FROM #TeamRuns                                                          
  --SELECT Distinct @LineID,@LineDesc,Shift_Desc,Shift_Desc,0,0 FROM dbo.Crew_Schedule cs WITH(NOLOCK) Where cs.pu_id = @RollsPUID                                                         
  END                                                         
END                                                      
                                                      
SET @RPT_ShowTop5Downtimes = 'TRUE'                                                          
                                                          
IF @RPTMajorGroupBy = 'Line'                                                              
 SET @RPTMajorGroupBy = 'PLID'                                                           
                                                          
                                                          
DECLARE @ShowAll  INT                                                      
DECLARE @TotalTables  INT                                                      
                                                              
SELECT @ShowAll = COUNT(DISTINCT Major_id) FROM @Cursor                                                              
                                                      
SET @TotalTables = 2                                                      
SET @GroupMajorFieldName = @RPTMajorGroupBy                     
SET @GroupMinorFieldName = @RPTMinorGroupBy                                                              
                                                             
DECLARE                                                               
 @MajGroupValue NVARCHAR(20),                                                              
 @MajGroupDesc  NVARCHAR(100),                                                              
 @MinGroupValue NVARCHAR(20),                                                              
 @MinGroupDesc  NVARCHAR(100),                                                              
 @MajOrderby    INT,                                                              
 @MinOrderby    INT,                                                              
 @Class_var     INT                                                              
                                 
SET @i = 1                                                           
SET @j = 1                                                              
                                                          
WHILE @j <= @TotalTables                                                              
BEGIN                           
 IF @j = 1                                                               
  SELECT @TableName =  '#Summary'                                                          
                                                           
 IF @j = 2 and @RPT_ShowTop5Downtimes = 'TRUE'                                                              
  SELECT @TableName =  '#Top5SheetBreaks'                                           
                                       
 DECLARE RSMjCursor INSENSITIVE CURSOR FOR (SELECT DISTINCT Major_Order_by,Major_Id, Major_desc FROM @Cursor)                                                              
 ORDER BY Major_Order_by,Major_Desc                                                              
 OPEN RSMjCursor                                                              
                                                               
 FETCH NEXT FROM RSMjCursor INTO @Class_Var,@MajGroupValue, @MajGroupDesc                   
                                                               
 WHILE @@Fetch_Status = 0 AND @i < 10                                                              
 BEGIN                   
                                                               
  SET @ColNum = LTRIM(RTRIM(CONVERT(VARCHAR(3), @i)))                                                              
                                      
   SELECT @SQLString = ''                                                
   SELECT @SQLString =  ' UPDATE ' + @TableName + ' '                                                               
       + ' SET Value'  + @ColNum + ' = ''' + @MajGroupDesc + '''' +                 
       + ' WHERE GroupField = ''' + 'Major' + ''''                                                              
                                                               
   EXEC (@SQLString)                                                          
                                                           
                                                             
   IF @GroupMajorFieldName <> @GroupMinorFieldName                                                              
   BEGIN                                                              
                                                     
    DECLARE RSMiCursor INSENSITIVE CURSOR FOR (SELECT Minor_Order_by,Minor_Id, Minor_desc FROM @Cursor                                                              
            WHERE Major_id = @MajGroupValue                                                              
                                    UNION SELECT 99,'ZZZ','ZZZ'                                 
              ) ORDER BY Minor_Order_by,Minor_desc                                                              
    OPEN RSMiCursor                                                              
    FETCH NEXT FROM RSMiCursor INTO @Class_Var,@MinGroupValue,@MinGroupDesc                                                              
    WHILE @@Fetch_Status = 0 AND @i < 10                                                              
    BEGIN                                                              
       IF @MinGroupValue <> 'ZZZ'                                                              
       BEGIN                                                              
         SET @ColNum = LTRIM(RTRIM(CONVERT(VARCHAR(3), @i)))                                                              
         SELECT @SQLString = ''                                                              
         SELECT @SQLString =  ' UPDATE '  + @TableName + ' '                                             
          + ' SET Value'  + @ColNum + ' = ''' + @MinGroupDesc + '''' +                                                              
          + ' WHERE GroupField = ''' + 'Minor' + ''''                                                              
                                                                 
         EXEC (@SQLString)                                                              
                                                                   
         SET @i = @i + 1                                                              
       END                                                               
                                                               
     FETCH NEXT FROM RSMiCursor INTO @Class_Var,@MinGroupValue, @MinGroupDesc                                                              
     END                                                              
                                                  
     CLOSE  RSMiCursor                                                              
     DEALLOCATE RSMiCursor                                                                
                               
       END                                                                
                                                          
                                                               
      SET @i = @i + 1                                                              
                                                              
 FETCH NEXT FROM RSMjCursor INTO @Class_Var,@MajGroupValue, @MajGroupDesc                                                              
                                                              
END                                                              
                                                              
CLOSE  RSMjCursor                                                             
DEALLOCATE RSMjCursor                                                              
                           
SET @j = @j + 1                                                            
SET @i = 1                                                              
END                                         
                                                          
DECLARE @lblDowntime VARCHAR(20)                           
SET @lblDowntime = 'Minutes'                                                          
                                                              
   SELECT @SQLString = ''                                                              
   SELECT @SQLString = 'UPDATE #Top5SheetBreaks ' + ' '                   + ' SET AGGREGATE = ''' + @lblDowntime + '''' +                                                              
   + ' WHERE Sortorder = 1 OR Sortorder IS Null'                                                              
                          
   EXEC  (@SQLString)                                                   
                                                          
--*********************************************************************************************************************************************                                                          
--End - Section 10 - Preparing the Summary Table \ Top 5 SheetBreaks - Header                                                      
--*********************************************************************************************************************************************                                                          
                                                          
--*********************************************************************************************************************************************                                                          
--Start - Section 11 - Populating Top 5 SheetBreaks \ Updating the AGGREGATE column                                                       
--*********************************************************************************************************************************************                                                          
                                                          
INSERT INTO #Top5Temp (Reason2, Duration, Cnt)                                                          
SELECT TOP 5                                                          
 Reason2,                                                          
 CONVERT(NUMERIC(10,2), SUM(Duration)) AS 'Duration',                                                          
 COUNT(Reason2) AS 'Cnt'                                                          
FROM  #TED1 s                                                          
WHERE  TEFault_Id > 31 AND TEFault_Id < 7500                                                          
GROUP BY Reason2                                                          
ORDER BY  Duration DESC                                             
                                                  
                                                  
INSERT INTO #Top5SheetBreaks (DESC01, DESC02, AGGREGATE, Stops)                                                          
SELECT Reason2, ' ' , Duration, Cnt FROM #Top5Temp                                                          
                                                          
SELECT @SQLString = 'INSERT #Top5SheetBreaks (Desc01,Stops, AGGREGATE) ' +                                                              
  ' SELECT '''+'.'+''', LTRIM(RTRIM(CONVERT(VARCHAR(50),SUM(CONVERT(FLOAT,stops))))), LTRIM(RTRIM(CONVERT(VARCHAR(50),SUM(CONVERT(FLOAT,AGGREGATE))))) ' +                                                              
  ' FROM #Top5SheetBreaks ' +                                                           
  ' WHERE SortOrder > 1'                                                              
                                                              
EXECUTE (@SQLString)                                                              
                                                        
--*********************************************************************************************************************************************                                                          
--End - Section 11 - Populating Top 5 SheetBreaks \ Updating the AGGREGATE column                                                       
--*********************************************************************************************************************************************                            
                                                      
--*********************************************************************************************************************************************                                                          
--Start - Section 12 - Inverted Summary - Populate Inverted \ Top 5 Sheet Breaks                                                      
--*********************************************************************************************************************************************                                                          
                                                      
SELECT  @top5col= COUNT(sortorder) FROM  #Top5SheetBreaks                                                     
                              
-- Inserting 'ZZZ' group into @Cursor                                                          
IF @RPTMajorGroupBy <> @RPTMinorGroupBy                                                              
        INSERT INTO @Cursor (Major_id,Major_desc,Minor_id,Minor_desc,Major_Order_by,Minor_Order_by)                       
        SELECT DISTINCT Major_id,Major_Desc,'ZZZ','ZZZ',Major_Order_by,99 FROM @Cursor                                                              
ELSE                                                              
        UPDATE @Cursor SET Minor_id = 'ZZZ',Minor_Desc = 'ZZZ'                                                            
                                                          
DECLARE @FIELD1 VARCHAR(50)                                                          
DECLARE @FIELD2 VARCHAR(50)                                                          
DECLARE @TEMPValue VARCHAR(50)                                                          
                                                          
INSERT INTO #ac_Top5SheetBreaks (SortOrder, DESC01, DESC02)                                                              
 SELECT SortOrder, DESC01, ''                                                              
   FROM #Top5SheetBreaks                                                    
   WHERE SortOrder > 1 and SortOrder < @top5col                                                            
                                                          
SELECT @FIELD1 = 'Reason2'              
          
--FLAG USED FOR BELTSPEED          
DECLARE @FLAG_BELTSPEED int                                                          
                                                           
UPDATE #ac_Top5SheetBreaks                                                              
SET WHEREString1 = (CASE ISNULL(DESC01,'xyz') WHEN 'xyz' THEN CONVERT(NVARCHAR,@FIELD1 + ' IS null') ELSE CONVERT(NVARCHAR(200),@FIELD1 + ' = ''' + DESC01 + '''') END)                                                              
                                 
SET @i = (SELECT MIN(Cur_id) FROM @Cursor)                                                              
SET @k = (SELECT MAX(Cur_id) FROM @Cursor)                                                           
                                                          
SET @Prev_Value = ''                                                             
                     
DECLARE RSMiCursor INSENSITIVE CURSOR FOR ( SELECT Major_id, Major_desc,Major_Order_by,Minor_id, Minor_desc,Minor_Order_by  FROM @Cursor)                                                               
ORDER BY Major_Order_by,Major_Desc,Minor_Order_by,Minor_Desc                                                               
                                                              
OPEN RSMiCursor                                                              
                                                         
FETCH NEXT FROM RSMiCursor INTO @MajGroupValue, @MajGroupDesc,@MajOrderby,@MinGroupValue, @MinGroupDesc,@MinOrderby                                                              
                                                              
WHILE  @@FETCH_Status = 0 AND @i <= @k                                                          
BEGIN                                                              
 SELECT  @SumGroupBy   = 'Value' + CONVERT(VARCHAR(25),@i)                                            
                        
 ---------------====================================================              
 --------Start - Section 12.0 - Inverted Summary - Calendar Time                                                         
 ---------------====================================================                                                      
  SELECT @SQLString =  ' SELECT STR(SUM(DATEDIFF(ss, StartTime, EndTime)),15,2) ' +                                        
     ' FROM #TeamRuns '                                                          
                                                           
  IF @MinGroupValue <> 'ZZZ'                                                          
   SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                              
  TRUNCATE TABLE #TEMPORARY                                                              
                                                                 
   INSERT #Temporary(TempValue1)                                                              
   EXECUTE (@SQLString)                                                              
          
   SELECT  @CalendarTime = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                          
                                      
 ---------------====================================================                                                      
 --------End - Section 12.0 - Inverted Summary - Calendar Time                                                      
 ---------------====================================================                                                
                                                    
                                                          
 ---------------====================================================                                                 
 --------Start - Section 12.1 - Inverted Summary - Downtime                                                          
 ---------------====================================================                                                      
  SELECT @SQLString =  ' SELECT STR(SUM(DTDuration),15,2), STR(SUM(Uptime),15,2), STR(SUM(GlblIncUptime),15,2) ' +                                                           
     ' FROM #DownUptime '                                                          
                                                           
  IF @MinGroupValue <> 'ZZZ'                                                          
   SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                            
  TRUNCATE TABLE #TEMPORARY                   
                                                                 
   INSERT #Temporary(TempValue1, TempValue2, TempValue3)                                                              
   EXECUTE (@SQLString)                                                              
                                                          
   SELECT  @SumDTDuration = CONVERT(NUMERIC(10,2),TempValue1)/3600.00 FROM #Temporary                                                           
   SELECT  @SumUptime   = CONVERT(NUMERIC(10,2),TempValue2)/3600.00 FROM #Temporary                                                           
   SELECT  @SumGlblIncUptime  = CONVERT(NUMERIC(10,2),TempValue3)/60.00 FROM #Temporary                                                           
--   Select  @CalendarTime     =Convert(numeric(10,2),TempValue3) FROM #Temporary                                                                      
                                                    
 ---------------====================================================                                                      
 --------End - Section 12.1 - Inverted Summary - Downtime   #TeamRuns Starttime, Endtime                                                       
 ---------------====================================================                                                
                                                    
 ---------------====================================================================                                                          
 --------Start - Section 12.2 - Inverted Summary - Belt Speed, % Shrinkage, Reel, Winder drum                                                          
 ---------------====================================================================                                                          
--BeltSpeed               
          
-- SELECT COUNT(1) FROM #TurnoverEv WHERE BeltSpeed IS NULL          
-- SELECT COUNT(1) FROM #TurnoverEv WHERE Belt1SetSpeed IS NULL          
-- SELECT BELTSPEED,* FROM #TurnoverEv WHERE BeltSpeed IS NULL          
-- SELECT BELTSPEED,BELT1ActualSpeed,* FROM #TurnoverEv WHERE BeltSpeed IS NULL          
          
                                                     
   SELECT @SQLString =  ' SELECT CASE WHEN COALESCE(SUM(CAST(DATEDIFF(SS, StartTime, EndTime)AS FLOAT)), 0.0) = 0.0 THEN NULL ' +                                                       
      ' ELSE SUM (Belt1SetSpeed * CAST(DATEDIFF(SS, StartTime, EndTime)AS FLOAT))/ SUM(CAST(DATEDIFF(SS, StartTime, EndTime)AS FLOAT)) END ' +                                                      
      ' FROM #TurnoverEv WHERE Belt1SetSpeed IS NOT NULL '                                                      
                            
   IF @MinGroupValue <> 'ZZZ'                                                      
    SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                       
                                                       
    TRUNCATE TABLE #TEMPORARY                                                       
    INSERT #Temporary(TempValue1)                                                          
    EXECUTE (@SQLString)                                                    
                                                         
    SELECT  @MaxBeltSpeed   = CONVERT(NUMERIC(10,2),TempValue1) FROM #Temporary            
                                                    
       
--WinderDrumAvg                                         
                                                      
  SELECT @SQLString =  ' SELECT CASE WHEN COALESCE(SUM(CAST(DATEDIFF(SS, StartTime, EndTime)AS FLOAT)), 0.0) = 0.0 THEN NULL ' +                                                       
     ' ELSE SUM (WinderDrumAvg * CAST(DATEDIFF(SS, StartTime, EndTime)AS FLOAT))/ SUM(CAST(DATEDIFF(SS, StartTime, EndTime)AS FLOAT)) END ' +                                                      
     ' FROM #PourEvents WHERE WinderDrumAvg IS NOT NULL '                                                      
                        
  IF @MinGroupValue <> 'ZZZ'                                                      
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                       
                                                      
   TRUNCATE TABLE #TEMPORARY                
   INSERT #Temporary(TempValue1)                                                          
   EXECUTE (@SQLString)                                                          
                                                        
   SELECT  @AvgWinderDrumAvg   = CONVERT(NUMERIC(10,2),TempValue1) FROM #Temporary                                                       
                                                      
                                                      
--% Shrinkage                                                       
  SELECT @AvgPctShrinkage =                                                      
  CASE WHEN COALESCE(@MaxBeltSpeed, 0.0) = 0.0                                                       
  THEN NULL                                                        
  ELSE  (1 - (@AvgWinderDrumAvg / @MaxBeltSpeed )) * 100                                                      
   --@AvgWinderDrumAvg / @MaxBeltSpeed                                                      
  END                                                           
            
--Calculated Speed @ Reel                                                      
                 SELECT  @MaxReelSpeed  =   @MaxBeltSpeed * (1-@Draftval)             
        
-- Decide Whether to show the Value of BeltSpeed        
SELECT @SQLString =  ' SELECT COUNT(1) FROM #TurnoverEv WHERE BeltSpeed IS NULL '           
                       
 IF @MinGroupValue <> 'ZZZ'                                                      
 SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''            
           
    TRUNCATE TABLE #TEMPORARY                                                       
    INSERT #Temporary(TempValue1)                                                          
    EXECUTE (@SQLString)           
           
 SELECT  @FLAG_BELTSPEED   = CONVERT(NUMERIC(10,2),TempValue1) FROM #Temporary            
          
 IF @FLAG_BELTSPEED >=1            
 BEGIN         
  SET @MaxBeltSpeed = NULL        
 END                                                 
                                                          
 ---------------====================================================================                                                          
 --------End - Section 12.2 - Inverted Summary - Belt Speed, % Shrinkage, Reel, Winder drum                                                          
 ---------------====================================================================                                                          
                                                          
                                                    
 ---------------====================================================================                                                          
 --------Start - Section 12.3 - Inverted Summary - Total Pour Time                                                          
 ---------------====================================================================                                               
                                                      
SELECT @SQLString =  ' SELECT SUM(TotalTime / 3600.0) ' +     --changed from 86400.0 to 3600.00                              
     ' FROM #PourEvents '                                                          
                                                           
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                            
  TRUNCATE TABLE #TEMPORARY                                                              
                                      
   INSERT #Temporary(TempValue1)                                                              
   EXECUTE (@SQLString)                                                              
                                                          
SELECT  @SumTotalPourTime  = CONVERT(NUMERIC(10,2),TempValue1) FROM #Temporary                                                           
                                      
 ---------------====================================================================                                                          
 --------End - Section 12.3 - Inverted Summary - Total Pour Time                                                          
 ---------------====================================================================                                                          
                                                          
 ---------------====================================================================                                                          
 --------Start - Section 12.4 - Inverted Summary - WindPercent                                                          
 ---------------====================================================================                                       
                                  
--Good Sq Meters                                     
  SELECT @SQLString =  ' SELECT  STR(SUM(Timeequivalent)* 60.0,15,2) FROM #RollEvents WHERE ' +                                                        
     '  Status <> ' + CONVERT(VARCHAR,@RejectStatus) +                                                          
     ' AND Status <> ' + CONVERT(VARCHAR,@HoldStatus)                                                  
                                                          
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
                                            
  TRUNCATE TABLE #TEMPORARY                                                              
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                                              
                                                 
  SELECT  @SUMGoodProdRollTime =   CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                           
                                  
  SELECT @SQLString =' SELECT CASE WHEN COALESCE(SUM(TotalTime), 0.0) = 0.0 THEN NULL ' +                                                            
                     ' ELSE (' + CONVERT(VARCHAR(25),@SUMGoodProdRollTime ) + ' / SUM(TotalTime) ) * 100  END ' +                                             
                     ' FROM #PourEvents '                                                          
                                                    
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
  TRUNCATE TABLE #TEMPORARY               
                                                                 
   INSERT #Temporary(TempValue1)                                                              
   EXECUTE (@SQLString)                                                              
                                                          
   SELECT  @SumWindPercent = CONVERT(NUMERIC(5,2),TempValue1) FROM #Temporary                             
                            
 IF @SumWindPercent > 100.00                                                         
                SELECT  @SumWindPercent =100.0                            
                                          
 ---------------====================================================================                                                          
 --------End - Section 12.3 - Inverted Summary - WindPercent                 
 ---------------====================================================================                                                          
                                                          
 ---------------====================================================================                                                          
 --------Start - Section 12.4 - Inverted Summary - FMDS FMDL                                                          
 ---------------====================================================================                                        
                                                          
  SELECT @SQLString =  ' SELECT CASE WHEN COALESCE(SUM(MasterUnitUpTime), 0.0) = 0.0 THEN NULL ELSE ' +                                                           
     ' (CONVERT(NUMERIC(15,2), SUM(DTLiquids)) / SUM(MasterUnitUpTime)) * CONVERT(NUMERIC(5,2), 100) END, ' +                                      
     ' CASE WHEN COALESCE(SUM(MasterUnitUpTime), 0.0) = 0.0 THEN NULL ELSE ' +                                                          
     ' (CONVERT(NUMERIC(15,2), SUM(DTSolids)) / SUM(MasterUnitUpTime)) * CONVERT(NUMERIC(5,2), 100) END ' +                                                   
     ' FROM #DownUptime '                                                          
                                                           
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
  TRUNCATE TABLE #TEMPORARY                            
                                                                 
  INSERT #Temporary(TempValue1,TempValue2)                                                              
   EXECUTE (@SQLString)                                                              
                                                          
   SELECT  @SumFMDL  = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                           
   SELECT  @SumFMDS  = CONVERT(NUMERIC(15,2),TempValue2) FROM #Temporary                                                           
                                                         
 ---------------====================================================================                                                          
 --------End - Section 12.4 - Inverted Summary - FMDS FMDL                                                          
 ---------------====================================================================                                                          
                                                          
 ---------------====================================================================                                                  
 --------Start - Section 12.5 - Inverted Summary - FMRJ                                                         
 ---------------====================================================================         
                                      
  SELECT @SQLString =  ' SELECT COALESCE(SUM(Timeequivalent), 0.0) FROM #RollEvents WHERE ( Type = ''' + @STUBTYPE + '''' +                                      
     ' OR  Status = '+ CONVERT(VARCHAR,@RejectStatus) +                                                          
     ' OR Status = '+ CONVERT(VARCHAR,@HoldStatus) + ')'                
                                  
  IF @MinGroupValue <> 'ZZZ'                                
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                       
                                                        
  TRUNCATE TABLE #TEMPORARY                                                          
                                                             
   INSERT #Temporary(TempValue1)                                                          
EXECUTE (@SQLString)                                        
   SELECT @SUMRejectedRollTime = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                   
                
 ---------------====================================================================              
 --------End - Section 12.5 - Inverted Summary - FMRJ                                            
 ---------------====================================================================                                                    
                                                          
 ---------------====================================================================                                                          
 --------Start - Section 12.6 - Inverted Summary - Schedule Time                                                          
 ---------------====================================================================                                        
                                      
  SELECT @SQLString =  ' SELECT CASE WHEN COALESCE( ' + CONVERT(VARCHAR,@CalendarTime) + ' , 0.0) = 0.0 THEN NULL ELSE ' +                                                           
     '  (CONVERT(NUMERIC(15,6), SUM(FAMMakingSchTime)) / CONVERT(NUMERIC(15,6), ' + CONVERT(VARCHAR,@CalendarTime) + ' )) * CONVERT(NUMERIC(15,2), 100) END ' +                                                          
     ' FROM #DownUptime '                                                          
                                      
                                                           
  IF @MinGroupValue <> 'ZZZ'                                             
   SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                            
  TRUNCATE TABLE #TEMPORARY                                                              
                                                                 
   INSERT #Temporary(TempValue1)                                                              
   EXECUTE (@SQLString)                                                              
                            
   SELECT  @SumScheduleUtil = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                           
                                                          
 ---------------====================================================================                                                          
 --------End - Section 12.6 - Inverted Summary -  Schedule Time                                                          
 ---------------====================================================================                                                          
                                               
 ---------------====================================================================                                                          
 --------Start - Section 12.7 - Inverted Summary - Availability                                                          
 ---------------====================================================================                                                          
          
  SELECT @SQLString =  ' SELECT CASE WHEN COALESCE(SUM(GlblIncUptime), 0.0) = 0.0 THEN NULL ' +                                                           
     '  ELSE (COALESCE(SUM(Uptime), 0.0)  * 100) / SUM(GlblIncUptime) END ' +                                                          
     ' FROM #DownUptime '                                                
                                                           
  IF @MinGroupValue <> 'ZZZ'                                                          
   SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                            
  TRUNCATE TABLE #TEMPORARY                                                              
                                                               
   INSERT #Temporary(TempValue1)                     
   EXECUTE (@SQLString)                                                              
                                                          
   SELECT  @SumAvailability = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                           
                                                          
 ---------------====================================================================                                                          
 --------End - Section 12.7 - Inverted Summary -  Availability                         
 ---------------====================================================================                                                          
                                                          
                                           
 ---------------==============================================================================================================                                                          
 --------Start - Section 12.9 - Inverted Summary - Sheetbreaks                                                          
 ---------------==============================================================================================================                                                          
  --Sheetbreak SELECT * FROM  #TED1 WHERE  TEFault_Id > 31 AND TEFault_Id < 7500    order by   start_time                                                    
  SELECT @SQLString =  ' SELECT CASE WHEN COUNT(1)=0 THEN NULL ELSE COUNT(1) END FROM  #TED1 WHERE  TEFault_Id > 31 AND TEFault_Id < 7500 AND IsSheetbreak = 1  '                                                        
--  SELECT @SQLString =  ' SELECT CASE WHEN COUNT(1)=0 THEN NULL ELSE COUNT(1) END FROM  #Sheetbreaks WHERE  Extended = 0  '  
  IF @MinGroupValue <> 'ZZZ'                                                          
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
  TRUNCATE TABLE #TEMPORARY                                                              
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                                              
  SELECT  @SumSheetBreakCount  = CONVERT(NUMERIC(15),TempValue1) FROM #Temporary                                                           
                                                  
  --Minutes\Break                                                          
SELECT @SQLString =  ' SELECT CONVERT(NUMERIC(10,2), SUM(Duration)) FROM  #TED1 WHERE  TEFault_Id > 31 AND TEFault_Id < 7500 '                                                           
  IF @MinGroupValue <> 'ZZZ'                                                          
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                     
                                                  
                                                         
  TRUNCATE TABLE #TEMPORARY                                                          
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                                              
  SELECT  @SumDTMinutes  = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                           
                                                      
                                                      
 SELECT @SumMinutesBreak =                                                      
  CASE                                            
   WHEN COALESCE (@SumSheetBreakCount,0)=0 THEN NULL                                                      
  ELSE                                                       
   @SumDTMinutes / @SumSheetBreakCount                                                
  END                                                       
                                                  
                                                        
 ---------------==============================================================================================================                                                          
 --------End - Section 12.9 - Inverted Summary -   Sheetbreaks                                                          
 ---------------==============================================================================================================                                                          
                                                         
 ---------------==============================================================================================================                                                          
 --------Start - Section 12.10 - Inverted Summary - --Target \ Medium \ Small \ Stub- Turnovers \ Total Meters Made \GoodMeters Wound \MSU                                                          
 ---------------==============================================================================================================                       
  --Target                                                          
 SELECT @SQLString =  ' SELECT  CASE WHEN CONVERT(NUMERIC(10,2),SUM(PartialLength/length))=0.0 THEN NULL ELSE CONVERT(NUMERIC(10,2),SUM(PartialLength/length)) END FROM #TurnoverEv WHERE Type= ''' + @TARGETTYPE + ''''                                      
  
    
      
        
         
            
              
                
                  
                    
                      
  IF @MinGroupValue <> 'ZZZ'                              SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
  TRUNCATE Table #TEMPORARY           
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                                              
  SELECT  @TARGETTYPECNT  = CONVERT(NUMERIC(10,2),TempValue1) FROM #Temporary                                                           
                                                  
                                                  
  --MEDIUM                                                          
  SELECT @SQLString =  ' SELECT  CASE WHEN CONVERT(NUMERIC(10,2),SUM(PartialLength/length))=0.0 THEN NULL ELSE CONVERT(NUMERIC(10,2),SUM(PartialLength/length)) END FROM #TurnoverEv WHERE Type= ''' + @MEDIUMTYPE + ''''                                      
  
    
     
         
          
            
              
                
                  
                    
                     
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
  TRUNCATE Table #TEMPORARY                                                              
 INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                               
  SELECT  @MEDIUMTYPECNT  = CONVERT(NUMERIC(10,2),TempValue1) FROM #Temporary                           
                                                          
                                                  
  --PLUS                                                          
  SELECT @SQLString =  ' SELECT  CASE WHEN CONVERT(NUMERIC(10,2),SUM(PartialLength/length))=0.0 THEN NULL ELSE CONVERT(NUMERIC(10,2),SUM(PartialLength/length)) END FROM #TurnoverEv WHERE Type= ''' + @PLUSTYPE + ''''                                        
  
    
      
        
          
            
              
               
                   
                   
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
  TRUNCATE Table #TEMPORARY                                                              
  INSERT #Temporary(TempValue1)                           
  EXECUTE (@SQLString)                                                              
  SELECT  @PLUSTYPECNT  = CONVERT(NUMERIC(10,2),TempValue1) FROM #Temporary                                               
                                                --SMALL                                                          
  SELECT @SQLString =  ' SELECT  CASE WHEN CONVERT(NUMERIC(10,2),SUM(PartialLength/length))=0.0 THEN NULL ELSE CONVERT(NUMERIC(10,2),SUM(PartialLength/length)) END FROM #TurnoverEv  WHERE Type= ''' + @SMALLTYPE + ''''                                      
  
    
      
        
         
             
              
                
                  
                   
                      
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                         
  TRUNCATE Table #TEMPORARY                                                              
  INSERT #Temporary(TempValue1)                                                              
  Execute (@SQLString)                                                              
  SELECT  @SMALLTYPECNT  = CONVERT(NUMERIC(10,2),TempValue1) FROM #Temporary                                                           
                                  
                             
  --STUB                                                          
  SELECT @SQLString =  ' SELECT  CASE WHEN CONVERT(NUMERIC(10,2),SUM(PartialLength/length))=0.0 THEN NULL ELSE CONVERT(NUMERIC(10,2),SUM(PartialLength/length)) END FROM #TurnoverEv WHERE Type= ''' + @STUBTYPE + ''''                                        
  
    
      
        
                     
  IF @MinGroupValue <> 'ZZZ'                   
  SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
  TRUNCATE Table #TEMPORARY                                                        
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                                              
  SELECT  @STUBTYPECNT  = CONVERT(NUMERIC(10,2),TempValue1) FROM #Temporary                                                           
                                       
                                            
  --Total Meters Made                                                          
  SELECT @SQLString =  ' SELECT STR(SUM(PartialLength),15,2) FROM #TurnoverEv '                                                           
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
  TRUNCATE Table #TEMPORARY                                                              
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                                              
  SELECT  @SUMTotalMetersMade = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                           
                                                         
  --GoodMeters Wound                                                          
  SELECT @SQLString =  ' SELECT  STR(SUM(PartialLength),15,2) FROM #TurnoverEv WHERE EVENTID IN ( SELECT DISTINCT ParentID FROM #RollEvents WHERE Type <> ''' + @STUBTYPE + '''' +                            
     ' AND Status <> '+ CONVERT(VARCHAR,@RejectStatus) +                                                          
     ' AND Status <> '+ CONVERT(VARCHAR,@HoldStatus) + ' ) '                                                    
                                                            
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
  TRUNCATE Table #TEMPORARY                            
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                                              
  SELECT  @SUMGoodMetersWound = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                
                                              
  --MSU                                                          
  SELECT @SQLString =  ' SELECT SUM(PartialLength) /(66.0/1000.0)/240.0/1000.0  FROM  #RollEvents  ' +                                                          
     ' WHERE PartialArea IS NOT NULL ' +                                
     ' AND Status <> '+ CONVERT(VARCHAR,@RejectStatus) +                                                          
     ' AND Status <> ' + CONVERT(VARCHAR,@HoldStatus)                                                     
                                                           
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                   
                                             
  TRUNCATE TABLE #TEMPORARY                                                          
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                 
  SELECT  @SUMMSU  = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                           
                                                          
 ---------------==============================================================================================================                                                          
 --------End - Section 12.10 - Inverted Summary -   --Target \ Medium \ Small \ Stub-Turnovers \ Total Meters Made \GoodMeters Wound \MSU                                                          
 ---------------==============================================================================================================                                                          
                                                      
 ---------------==============================================================================================================                                                          
 --------Start - Section 12.11 - Inverted Summary - Good Sq Meters                              
 ---------------==============================================================================================================                                                        
                                      
  -- Calculating Ideal Rate                                                          
  SELECT @SQLString =  ' SELECT CONVERT(NUMERIC(15,2),SUM((IdealTarget*IdealCnt))/SUM(IdealCnt)) FROM #DownUptime ' +                                                           
     '  WHERE IdealTarget > 0.0 AND IdealCnt > 0'                                               
                                                           
  IF @MinGroupValue <> 'ZZZ'                                                
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                  
                                                          
  TRUNCATE TABLE #TEMPORARY                                                              
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                                              
  Select  @AvgIdealRate  = Convert(numeric(15,2),TempValue1) FROM #Temporary                                         
                                      
                                                      
  --Good Sq Meters                                                       
  SELECT @SQLString =  ' SELECT  STR(SUM(PartialArea),15,2) FROM #RollEvents WHERE ' +                                                        
     '  Status <> ' + CONVERT(VARCHAR,@RejectStatus) +                                                          
     ' AND Status <> ' + CONVERT(VARCHAR,@HoldStatus)                                                  
                           
  IF @MinGroupValue <> 'ZZZ'                                                          
  SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                                          
                                                        
  TRUNCATE TABLE #TEMPORARY                                                              
  INSERT #Temporary(TempValue1)                                                              
  EXECUTE (@SQLString)                                                              
  SELECT  @SUMGoodSqMeters = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                           
                                                      
 ---------------==============================================================================================================                                                          
 --------End - Section 12.11 - Inverted Summary - Good Sq Meters                        
 ---------------==============================================================================================================                                                        
                                              
 ---------------====================================================================                                     
--------Start - Section 12.12 Inverted Summary - PR USING PRODUCT COUNT                 
-------- Report Target Speed \ Report Target Width \ Report Target Rate                                                      
---------------====================================================================           
          
--TargetSpeed                                                      
  SELECT @SQLString =  ' SELECT CASE WHEN COALESCE(SUM(ActualDuration), 0.0) = 0.0 THEN NULL ' +                                      
     ' ELSE SUM (TargetSpeed * ActualDuration)/ SUM(ActualDuration)* ( 1- ' + CONVERT(VARCHAR,@Draftval) + ' )* Avg(YFW) END,1  ' +                                                      
     ' FROM #TurnoverEv WHERE TargetSpeed IS NOT NULL '                                    
                                                       
  IF @MinGroupValue <> 'ZZZ'                                                      
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                       
                                                        
  TRUNCATE TABLE #TEMPORARY                                                          
                                                             
   INSERT #Temporary(TempValue1,TempValue2)                                                        
   EXECUTE (@SQLString)                                   
                                                      
                                                      
--Belt1ActualSpeed                                                      
                                      
  SELECT @SQLString =  ' SELECT CASE WHEN COALESCE(SUM(ActualDuration), 0.0) = 0.0 THEN NULL ' +                                      
     ' ELSE SUM (Belt1ActualSpeed * ActualDuration)/ SUM(ActualDuration)* ( 1- ' + CONVERT(VARCHAR,@Draftval) + ' )* Avg(YFW) END,2  ' +                                                      
     ' FROM #TurnoverEv WHERE Belt1ActualSpeed IS NOT NULL '                                                    
                                                     
  IF @MinGroupValue <> 'ZZZ'                                                      
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                       
                                      
   INSERT #Temporary(TempValue1,TempValue2)                           
   EXECUTE (@SQLString)                                                          
                                      
--Belt1SetSpeed                                   
                                      
  SELECT @SQLString =  ' SELECT CASE WHEN COALESCE(SUM(ActualDuration), 0.0) = 0.0 THEN NULL ' +                                      
     ' ELSE SUM (Belt1SetSpeed * ActualDuration)/ SUM(ActualDuration)* ( 1- ' + CONVERT(VARCHAR,@Draftval) + ' )* Avg(YFW) END,3  ' +                                                      
     ' FROM #TurnoverEv WHERE Belt1SetSpeed IS NOT NULL '                                                   
                                      
  IF @MinGroupValue <> 'ZZZ'                                                      
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                       
                                      
   INSERT #Temporary(TempValue1,TempValue2)                           
   EXECUTE (@SQLString)                                                          
                                      
---ReelSpeed                                       
                                      
  SELECT @SQLString =  ' SELECT CASE WHEN COALESCE(SUM(ActualDuration), 0.0) = 0.0 THEN NULL ' +                                      
     ' ELSE SUM (WinderActualSpeed * ActualDuration)/ SUM(ActualDuration) * Avg(YFW) END,4  ' +                                                      
     ' FROM #TurnoverEv WHERE WinderActualSpeed IS NOT NULL '                                       
                                     
  IF @MinGroupValue <> 'ZZZ'                                      
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                      
              
   INSERT #Temporary(TempValue1,TempValue2)                           
   EXECUTE (@SQLString)                         
                                      
-- Taking the Max value                                      
 SELECT @ReportTargetSpeedvar = MAX(CONVERT(FLOAT,TempValue1)) FROM #Temporary                           
 SELECT @ReportTargetSpeedfrom= MAX(CONVERT(FLOAT,TempValue2))FROM #Temporary where CONVERT(FLOAT,TempValue1)= @ReportTargetSpeedvar                                                      
                                 
--REPORT TARGET WIDTH                                      
  Select @SQLString =  ' SELECT CASE WHEN COALESCE(SUM(CAST(DATEDIFF(SS, StartTime, EndTime)AS FLOAT)), 0.0) = 0.0 THEN NULL ' +                                                      
           ' ELSE (SUM (width * CAST(DATEDIFF(SS, StartTime, EndTime)AS FLOAT))/ SUM(CAST(DATEDIFF(SS, StartTime, EndTime)AS FLOAT)))/ 1000.0 END ' +                                                      
            ' FROM #TurnoverEv '                                         
  IF @MinGroupValue <> 'ZZZ'                                                      
   SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                       
                                        
  TRUNCATE Table #TEMPORARY                                                          
  INSERT #Temporary(TempValue1)                                                          
  EXECUTE (@SQLString)                                                        
  SELECT  @SUMREPORTTARGETWIDTH = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                 
                                      
                                      
--Schedule Time                                                     
  SELECT @SQLString =  ' SELECT CASE WHEN COALESCE( SUM(FAMMakingSchTime), 0.0) = 0.0 THEN NULL ' +                                                           
         ' ELSE STR(SUM(FAMMakingSchTime)/60,15,2)  END ' +                                                          
         ' FROM #DownUptime '                                                          
                                      
   IF @MinGroupValue <> 'ZZZ'                                          
   SELECT @SQLString = @SQLString + ' WHERE ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                           
                                      
   TRUNCATE TABLE #TEMPORARY                                                            
                                      
   INSERT #Temporary(TempValue1)                                                              
   EXECUTE (@SQLString)                                                              
                                      
   SELECT  @ScheduleTime = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                      
                                 
  SELECT  @PRusingProductCount =                                                      
  CASE                                                       
   WHEN COALESCE( (@ReportTargetSpeedvar * @SUMREPORTTARGETWIDTH * @ScheduleTime ), 0.0) = 0.0 THEN NULL                                                       
  ELSE                                                       
    ((@SUMGoodSqMeters/ (@ReportTargetSpeedvar * @SUMREPORTTARGETWIDTH))/@ScheduleTime ) * 100                                                     
  END                                                         
                                      
---------------====================================================================                                                      
--------End - Section 12.12 Inverted Summary - PR USING PRODUCT COUNT                                                  
-------- Report Target Speed \ Report Target Width \ Report Target Rate                 
---------------====================================================================                                                      
                                        
                                        
 ---------------====================================================================                                   
 --------Start - Section 12.8 - Inverted Summary - Rate Utilization                                                       
 ---------------====================================================================                                                   
                                        
  SELECT  @AvgTargetRate  = @ReportTargetSpeedvar * @SUMREPORTTARGETWIDTH                                        
  IF @MinGroupValue = 'ZZZ'                                          
  BEGIN                                      
                          
 SELECT @ReportTargetSpeedfrom = CASE  when @ReportTargetSpeedfrom='1' then 'Target Speed'                          
  when @ReportTargetSpeedfrom='2' then 'Belt 1 Actual Speed'                          
  when @ReportTargetSpeedfrom='3' then 'Belt Speed Hr Avg'                          
  when @ReportTargetSpeedfrom='4' then 'Reel Speed'                           
  ELSE NULL                          
 END                                 
                                      
   INSERT INTO #CompanionMeasures (Measures,Totalvalue)                                        
     SELECT 'Draft',STR(CONVERT(FLOAT,@Draftval),6,2)                                         
     UNION All                                         
     SELECT 'Good Square Meters',STR(CONVERT(FLOAT,@SUMGoodSqMeters),15,2)                                         
     UNION All                                        
     SELECT 'Report Target Width',STR(CONVERT(FLOAT,@SUMREPORTTARGETWIDTH),6,2)                                         
     UNION All                               
     SELECT 'Greatest Speed',@ReportTargetSpeedfrom                                         
     UNION All                                    
     SELECT 'Report Target Speed',STR(CONVERT(FLOAT,@ReportTargetSpeedvar),6,2)                                         
     UNION All                                       
     SELECT 'Report Target Rate',STR(CONVERT(FLOAT,@AvgTargetRate),6,2)                                         
    
  END                                        
                                                          
          
  -- Calculating RateUtilization                                                          
IF @AvgTargetRate < @AvgIdealRate                                  
BEGIN                                  
  SELECT  @SumRateUtil  = (                                                          
       SELECT CONVERT(NUMERIC(15,2),CASE WHEN COALESCE(@AvgIdealRate, 0.0) = 0.0 THEN NULL ELSE                                                          
       (CONVERT(NUMERIC(15,6), COALESCE(@AvgTargetRate, 0.0)) / CONVERT(NUMERIC(15,6), @AvgIdealRate)) * CONVERT(NUMERIC(15,2), 100) END ))                    
                              
SELECT  @CapUtil =                                                      
CASE                                 
 WHEN COALESCE( (@CalendarTime*@AvgIdealRate ), 0.0) = 0.0 THEN NULL                                                       
ELSE                                                       
 ((@SUMGoodSqMeters/ @AvgIdealRate)/(@CalendarTime /60) ) * 100                                                       
END                               
                              
END                                  
ELSE                                  
BEGIN                                  
  SELECT  @SumRateUtil  = (                                                          
       SELECT CONVERT(NUMERIC(15,2),CASE WHEN COALESCE(@AvgIdealRate, 0.0) = 0.0 THEN NULL ELSE                                   
       100.00 END ))                                
                              
SELECT  @CapUtil =                                                      
CASE                                                       
 WHEN COALESCE( (@CalendarTime*@AvgTargetRate ), 0.0) = 0.0 THEN NULL                                                       
ELSE                                                       
 ((@SUMGoodSqMeters/ @AvgTargetRate)/(@CalendarTime /60) ) * 100                                                       
END                                                       
                                  
END                              
                                                        
 ---------------====================================================================                                                          
 --------End - Section 12.8 - Inverted Summary -  Rate Utilization-- Rate Utilization                                                          
 ---------------====================================================================                                             
                                                  
                                                  
 ---------------==============================================================================================================                                                          
 --------Start - Section 12.13 - Inverted Summary - Average Lanes                                       
 ---------------==============================================================================================================                                                     
           
  SELECT @SQLString =  ' Select CASE WHEN sum (ActualDuration)=0.0 THEN NULL ' +                                                       
     ' ELSE SUM(ROLLCOUNT*ActualDuration)/ SUM (ActualDuration) END ' +                                                      
     ' FROM #TurnoverEv WHERE ROLLCOUNT IS NOT NULL '           
        
--                                                   
--   SELECT @SQLString =  ' Select CASE WHEN SUM (Partiallength * WinderActualSpeed * YFW )=0.0 THEN NULL ' +                                                       
--      ' ELSE SUM (ROLLCOUNT * Partiallength * WinderActualSpeed * YFW )/ SUM (Partiallength * WinderActualSpeed * YFW ) END ' +                                                      
--      ' FROM #TurnoverEv WHERE WinderActualSpeed IS NOT NULL '                                                      
                                                       
  IF @MinGroupValue <> 'ZZZ'                                                      
   SELECT @SQLString = @SQLString + ' AND ' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''                                                       
                                                        
  TRUNCATE TABLE #TEMPORARY                                                          
                                                             
   INSERT #Temporary(TempValue1)                                                          
   EXECUTE (@SQLString)                                                   
                                                  
   SELECT  @SumAverageLanes = CONVERT(NUMERIC(15,2),TempValue1) FROM #Temporary                                                     
                                                  
 ---------------==============================================================================================================                                                          
 --------End - Section 12.13 - Inverted Summary - Average Lanes                                                  
 ---------------==============================================================================================================                        
                                                    
                                                          
 Insert #InvertedSummary                                                    
 (                                                           
 GroupBy,                                                               
 ColType,                                                       
 Downtime,                                                              
 Uptime,                                             
 ProdTime,                                                          
 BeltSpeed,                                                          
 ReelSpeed,                                                          
 PctShrinkage,                                                          
 WinderDrumAvg,                                                          
 TotalPourTime,                                                          
 FMDL,              
 FMDS,                                         
 ScheduleUtil,                                                         
 RateUtil,                                                          
 TargetRolls,                                                          
 MeduimRolls,                                                    
 PlusRolls,                                                        
 SmallRolls,                                                          
 StubRolls,                                                          
 TotalMetersMade,                                             
 GoodMetersWound,                                                          
 MSU,                                                          
 Availability,                                                          
 SheetBreakCount,                                                  
 SheetBreakMin,                                                           
 MinutesBreak,                                                          
 RejectedRollTime,  --FMRJ                                                        
 WindPercent,                                                      
 CapacityUtil,                                                      
 PRusingProductCount,                                                  
 AverageLanes                                                      
                               
 )                                                          
 Values                                                             
 (                                                           
 @SumGroupBy,                             
 @MinGroupValue,                                                          
 @SumDTDuration,                                                          
 @SumUptime,                                                          
 @SumGlblIncUptime,                                                          
 @MaxBeltSpeed,                                                          
 @MaxReelSpeed,                                                          
 @AvgPctShrinkage,                                                   
 @AvgWinderDrumAvg,                                                          
 @SumTotalPourTime,                                                          
 @SumFMDL,                                                          
 @SumFMDS,                                                          
 @SumScheduleUtil,                                                          
 @SumRateUtil,                                                          
 @TARGETTYPECNT,                                                          
 @MEDIUMTYPECNT,                                                   
 @PLUSTYPECNT,                                                         
 @SMALLTYPECNT,                                                          
 @STUBTYPECNT,                                                          
 @SUMTotalMetersMade,                                                          
 @SUMGoodMetersWound,                                                          
 @SUMMSU,                                                          
 @SumAvailability,                                                          
 @SumSheetBreakCount,                                                  
 @SumDTMinutes,                                                          
 @SumMinutesBreak,                                                          
 @SUMRejectedRollTime,                                                          
 @SUMWindPercent,             
 @CapUtil,                                                      
 @PRusingProductCount,                                                  
 @SumAverageLanes                                                             
 )                                                          
                                                                
                                                      
 SET @GROUPBYString = ' GROUP BY DESC01'                                                              
 SELECT @SQLString =  'SELECT ac.desc01,STR(SUM(Duration),6,2) ' +                                                              
                      ' FROM  #TED1 tdt ' +                                                       
        ' JOIN #ac_Top5SheetBreaks ac ON ISNULL(ac.desc01,''' +'xyz' +''') = ISNULL(tdt.'+ @FIELD1 +', ''' + 'xyz' + ''')'                                                              
                                      
 SELECT @SQLString = @SQLString + ' WHERE TEFault_Id > 31 AND TEFault_Id < 7500 AND tdt.' + @RPTMinorGroupBy + ' = ''' + @MinGroupValue + ''''             
 SELECT @SQLString = @SQLString + @GROUPBYString                                                              
                                                      
 TRUNCATE TABLE #TEMPORARY                                                              
 INSERT #Temporary(TempValue1, TempValue3)                                                              
 EXECUTE (@SQLString)                                                              
                                                           
 SELECT @SQLString =    ' UPDATE #Top5SheetBreaks ' +                                                              
            ' SET Value' + CONVERT(VARCHAR,@i) + ' = CONVERT(VARCHAR,t.TEMPValue3)' +                                                              
   ' FROM #Top5SheetBreaks tdt ' +                                              
   ' JOIN #Temporary t ON ISNULL(tdt.desc01,''' + 'xyz' + ''') = ISNULL(t.TempValue1,''' + 'xyz' + ''')'                      
                                                      
 SELECT @SQLString = @SQLString + ' WHERE Sortorder > 1 '                                                               
                                                          
 EXECUTE (@SQLString)                                                              
 SELECT @TEMPValue = SUM(CONVERT(FLOAT,TEMPValue3)) FROM #TEMPORARY                                                               
                                      
 SELECT @SQLString =   'UPDATE #Top5SheetBreaks ' +                                                              
    'SET Value' + CONVERT(VARCHAR,@i) + ' = ''' + CONVERT(VARCHAR,@TEMPValue) + '''' +                                                              
    'WHERE SortOrder = '+ CONVERT(VARCHAR,@top5col)                                                            
                                                      
 EXECUTE (@SQLString)                                                            
                                                      
---INTIALIZING THE VARIABLES                                                      
 SELECT                                                       
 @SumDTDuration  = NULL,                                                          
 @SumUptime  = NULL,                                                          
 @SumGlblIncUptime  = NULL,                                                 
 @MaxBeltSpeed  = NULL,                                                          
 @MaxReelSpeed  = NULL,                                    
 @AvgIdealRate  = NULL,                                                         
 @AvgPctShrinkage  = NULL,                                                           
 @AvgWinderDrumAvg  = NULL,                                                          
 @SumTotalPourTime  = NULL,                                                          
 @SumFMDL  = NULL,                      
 @SumFMDS  = NULL,                                                          
 @SumScheduleUtil  = NULL,                                                          
 @SumRateUtil  = NULL,                                                          
 @TARGETTYPECNT  = NULL,                                                          
 @MEDIUMTYPECNT  = NULL,                                                   
 @PLUSTYPECNT  = NULL,                                          
 @SMALLTYPECNT  = NULL,                                                          
 @STUBTYPECNT  = NULL,                         
 @SUMTotalMetersMade  = NULL,                                                          
 @SUMGoodMetersWound  = NULL,                                                          
 @SUMMSU  = NULL,                                                          
 @SumAvailability  = NULL,                                                          
 @SumSheetBreakCount  = NULL,                                                  
 @SumDTMinutes =NULL,                                                 
 @SumMinutesBreak  = NULL,                                                          
 @SUMRejectedRollTime  = NULL,                                                          
 @SUMWindPercent   = NULL,                                                      
 @SUMGoodSqMeters        = NULL,                                                 
 @CapUtil  = NULL,            
 @ReportTargetSpeedvar  = NULL,                                                      
 @SUMREPORTTARGETWIDTH  = NULL,                                                      
 @PRusingProductCount  = NULL,                                                      
 @ScheduleTime  = NULL,                                                  
 @SumAverageLanes = NULL,                                      
 @SUMGoodProdRollTime = NULL,                                      
 @SumMCUptime = NULL,                                      
 @SumPartialAreaRej = NULL,                                      
 @SumWidthReelSpeed = NULL,                                      
 @CalendarTime = NULL,                          
 @ReportTargetSpeedfrom=NULL,        
 @FLAG_BELTSPEED = NULL                                      
                                                      
                                                      
                                               
 SELECT @i = @i + 1                                                                
                                                                
  FETCH NEXT FROM RSMiCursor INTO @MajGroupValue, @MajGroupDesc,@MajOrderby,@MinGroupValue, @MinGroupDesc,@MinOrderby                                                              
  END                                                       
                                                              
CLOSE RSMiCursor                                                              
DEALLOCATE RSMiCursor                                                           
                                                          
                                                      
--*********************************************************************************************************************************************                                                          
--End - Section 12 - Inverted Summary - Populate Inverted \ Top 5 Sheet Breaks                                                      
--*********************************************************************************************************************************************                                                          
                                                         
                                                          
--*********************************************************************************************************************************************                                                          
--Start - Section 13 - Inverted Summary - Populating Aggregate column                                                       
--*********************************************************************************************************************************************                                                          
                                                       
SET @ColNum = LTRIM(RTRIM(CONVERT(VARCHAR(3), @i)))                                         
                                      
                                
INSERT #InvertedSummary                                                              
(GroupBy, Uptime,PRusingProductCount,AverageLanes,Downtime,ProdTime,BeltSpeed,ReelSpeed,PctShrinkage,WinderDrumAvg,TotalPourTime,TotalScrap,FMDL,FMDS,FMRJ,ScheduleUtil,RateUtil,CapacityUtil,TargetRolls,                                                    
  
    
      
MeduimRolls,PlusRolls,SmallRolls,StubRolls,TotalMetersMade,GoodMetersWound,MSU,Availability,SheetBreakCount,SheetBreakMin,MinutesBreak,BreaksPerDay,BreaksPerMSU,RejectedRollTime,WindPercent,                                                          
Belt1PourTime,Belt1SteamTime                                                          
)                                                              
                                      
SELECT 'AGGREGATE',                                           
STR(SUM(CONVERT(FLOAT,Uptime)),15,2) ,                                                        
STR(SUM(CONVERT(FLOAT,PRusingProductCount)),15,2) ,                                                        
STR(SUM(CONVERT(FLOAT,AverageLanes)),15,2) ,                                                  
STR(SUM(CONVERT(FLOAT,Downtime)),15,2),                                                              
STR(SUM(CONVERT(FLOAT,ProdTime)),15,2),                
STR(MAX(CONVERT(FLOAT,BeltSpeed)),15,2),                                                          
STR(MAX(CONVERT(FLOAT,ReelSpeed)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,PctShrinkage)),15,2),                                       
STR(SUM(CONVERT(FLOAT,WinderDrumAvg)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,TotalPourTime)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,TotalScrap)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,FMDL)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,FMDS)),15,2),                                              
STR(SUM(CONVERT(FLOAT,FMRJ)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,ScheduleUtil)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,RateUtil)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,CapacityUtil)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,TargetRolls)),15,2),                                                   
STR(SUM(CONVERT(FLOAT,MeduimRolls)),15,2),                                             
STR(SUM(CONVERT(FLOAT,PlusRolls)),15,2), --PLUS                                        
STR(SUM(CONVERT(FLOAT,SmallRolls)),15,2),                                      
STR(SUM(CONVERT(FLOAT,StubRolls)),15,2),                                                   
STR(SUM(CONVERT(FLOAT,TotalMetersMade)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,GoodMetersWound)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,MSU)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,Availability)),15,2),                                                          
STR(SUM(SheetBreakCount)),                                                          
STR(SUM(CONVERT(FLOAT,SheetBreakMin)),15,2),                                                   
STR(SUM(CONVERT(FLOAT,MinutesBreak)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,BreaksPerDay)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,BreaksPerMSU)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,RejectedRollTime)),15,2),                                                          
STR(SUM(CONVERT(FLOAT,WindPercent)),15,2),                                                          
@BeltPourTimeAGG,                                                          
@BeltSteamTimeAGG                                                          
FROM #InvertedSummary                                                              
WHERE ColType = 'ZZZ'                            
               
                
                
UPDATE #InvertedSummary                                                               
SET                                                           
  BreaksPerDay = (CASE WHEN COALESCE(TotalPourTime, 0.0) = 0.0 THEN NULL ELSE (SheetBreakCount/TotalPourTime) * 24.0 END),                                                          
  BreaksPerMSU = (CASE WHEN COALESCE(MSU, 0.0) = 0.0 THEN NULL ELSE SheetBreakCount/MSU  END),                                       
  FMRJ         = (CASE WHEN COALESCE(CONVERT(FLOAT,Uptime), 0) = 0.0 THEN NULL ELSE (RejectedRollTime/Uptime) / 60.0*  100.0  END)                                                          
                                                          
UPDATE #InvertedSummary                  
  SET TotalScrap = CAST(FMDL AS FLOAT) + CAST(FMDS AS FLOAT) +  CAST(FMRJ AS FLOAT)                     
                                                    
--*********************************************************************************************************************************************                                                          
--END - Section 13 - Inverted Summary - Populating Aggregate column                                                      
--*********************************************************************************************************************************************                                                          
                                                      
--*********************************************************************************************************************************************                                                          
--Start - Section 14 - Populate Summary                                                       
--*********************************************************************************************************************************************                                                          
                                                      
INSERT INTO #Summary (SortOrder, Label,null01)                                                              
SELECT CONVERT(VARCHAR(10),ColId),LabelName,Unit FROM @ColumnVisibility                                                               
                                                         
 DECLARE @GroupValue VARCHAR(50)                                                          
 DECLARE @FIELDName VARCHAR(50)                             
 DECLARE @id_is   INT                                                              
 DECLARE @NoLabels INT                                                          
                                                           
 SELECT @NoLabels = COUNT(*) FROM @ColumnVisibility                                                           
                                                          
 SELECT @id_is = MIN(id) FROM #InvertedSummary                                                              
                                                               
 WHILE @id_is IS NOT NULL                                                              
 BEGIN                                                              
                                                               
  SELECT @GroupValue = Groupby FROM #InvertedSummary WHERE ID = @id_is                                                              
                                                                
   SET @j = 1                                                              
   WHILE @j <= @NoLabels                                                              
    BEGIN                                                              
                                                      
IF EXISTS ( SELECT * FROM #Summary WHERE SortOrder = @j)                                                              
     BEGIN                               
       SELECT @FIELDName = FieldName FROM @ColumnVisibility WHERE ColId = @j                                                              
                                                                
       SELECT @SQLString = ''                                                              
       SELECT @SQLString = ' SELECT ' + @FIELDName +                                                              
             ' FROM #InvertedSummary ' +                                                              
       ' WHERE GroupBy = ''' + @GroupValue + ''''                                                              
                                   
       TRUNCATE TABLE #TEMPORARY                                                              
       INSERT #TEMPORARY (TEMPValue1)                                                              
       EXECUTE (@SQLString)                                                              
                                                      
       SELECT @TEMPValue = TEMPValue1 FROM #TEMPORARY                                       
                                 
       SELECT @SQLString = 'UPDATE #Summary' +                                                              
        ' SET '+ @GroupValue + ' = ''' + LTRIM(RTRIM(@TEMPValue)) + '''' +                      
        ' WHERE SortOrder = ' + CONVERT(VARCHAR(25),@J)                                                              
                                                      
       EXECUTE (@SQLString)                                                              
                                                                
     END                                                              
                                         
    SET @j = @j + 1                                                              
                                                          
   END                                                              
                                              
   SELECT @id_is = MIN(ID) FROM #InvertedSummary WHERE ID > @id_is                                                              
                                                          
 END                                                          
                                                          
--*********************************************************************************************************************************************                                                          
--End - Section 14 - Populate Summary                                                       
--*********************************************************************************************************************************************                                                          
                                                      
--*********************************************************************************************************************************************                                                          
--Start - Section 15 - Result set                                                        
--*********************************************************************************************************************************************                                                          
                                                      
--OUTPUT RESULT SETS For REPORT:                                                       
                                     
--RS 1 for header                                  
                                                          
SET @PLStatusDESCList = @lblAll                                                          
                                                          
SELECT                                                              
 @RptStartTime    StartDateTime,                                                              
 @RptEndTime      EndDateTime,                                                              
 @CompanyName     CompanyName,                                                              
 @SiteName        SiteName,                                 
 NULL             PeriodInCompleteFlag,                                                              
 SUBSTRING(@CrewDESCList, 1, 25)   CrewDESC,                                                              
 SUBSTRING(@ShiftDESCList, 1, 10)  ShiftDESC,                                                              
 SUBSTRING(@PLStatusDESCList, 1, 100)  LineStatusDESC,                                                              
 SUBSTRING(@LineDesc, 1, 100)   LineDESC,                                                              
 SUBSTRING(@lblPlant, 1, 25)   Plant,                                                              
 @lblStartDate                  StartDate,                                                              
 @lblShift                   Shift,                                                              
 @lblLine                   Line,                                                              
 @lblEndDate                   EndDate,                                                
 @lblCrew                   Crew,            
 @lblProductionStatus           LineStatus,                                                            
 @lblTop5Downtime           Top5Downtime,                                                              
 SUBSTRING(@lblSecurity,1, 500) Security                                                            
                                                          
                                                          
--RS 1 - Measures                                                          
                                                          
SET @i = 1                                                              
SET @SQLString = 'SELECT SortOrder,Label,null01,'                                                               
                                   
WHILE @i < @ColNum - 1                                                              
BEGIN                                                              
        SET @SQLString = @SQLString + 'Value' + CONVERT(VARCHAR,@i) + ','                                                              
 SET @i = @i + 1                                                              
END                                                              
SET @SQLString = @SQLSTring + 'AGGregate,EmptyCol FROM #Summary'                                                                      
                                                              
EXEC(@SQLString)                                                          
                                                          
--RS 2 - Sheet Break                                                        
                                                   
SET @i = 1                                                              
SET @SQLString = 'SELECT SortOrder,DESC01,stops,'                                        
WHILE @i < @ColNum - 1                                                            
BEGIN                                                              
  SET @SQLString = @SQLString + 'Value' + CONVERT(VARCHAR,@i) + ','                                                              
  SET @i = @i + 1                                                      
END                                                              
  SET @SQLString = @SQLSTring + 'AGGregate,EmptyCol FROM #Top5SheetBreaks '                                                              
                                                          
EXEC(@SQLString)                                                          
                                                          
---RS 3 --changes done as per requirement                                                      
                                                              
SELECT '.' Sortorder,'Start Time' [Start Time], 'End Time' [End Time], 'Duration' [Duration]                                                            
UNION All                                                            
SELECT '.' Sortorder,                  
CONVERT(VARCHAR(19), ActualStartTime, 120)[Start Time],                                                            
--CONVERT(VARCHAR(19), EndTime, 120)[End Time],                                                   
 CASE WHEN ActualEndTime = @RptEndTime                                                             
   THEN NULL                                                            
   ELSE CONVERT(VARCHAR(19), ActualEndTime, 120)                                                            
 END AS 'End Time',                                                            
CASE WHEN DATEDIFF(ss, ActualStartTime, ActualEndTime) < 359999                                                             
    THEN RIGHT('0' + RTRIM(CONVERT(CHAR(2), DATEDIFF(ss, ActualStartTime, ActualEndTime) / (60 * 60))), 2) + ':' +                                                             
     RIGHT('0' + RTRIM(CONVERT(CHAR(2), (DATEDIFF(ss, ActualStartTime, ActualEndTime) / 60) % 60)), 2) + ':' +                                                             
     RIGHT('0' + RTRIM(CONVERT(CHAR(2), DATEDIFF(ss, ActualStartTime, ActualEndTime) % 60)),2)                                                            
    ELSE REPLACE(STR((DATEDIFF(ss, ActualStartTime, ActualEndTime))/3600,len(LTRIM((DATEDIFF(ss, ActualStartTime, ActualEndTime))/3600))+ABS(SIGN((DATEDIFF(ss, ActualStartTime, ActualEndTime))/359999)-1)) + ':' + STR(((DATEDIFF(ss, ActualStartTime, ActualEndTime))/60)%60,2) + ':' + STR((DATEDIFF(ss, ActualStartTime, ActualEndTime))%60,2),' ','0')                                                            
  END AS Duration                                                            
FROM #PourEvents WHERE ActualStartTime is NOT NULL --ORDER BY StartTime                                                          
UNION All                                                           
SELECT '.' Sortorder,NUll [Start Time], NULL [End Time], NULL [Duration]                                                            
                                                  
--DATEDIFF(ss, StartTime, EndTime)                                                  
---RS 4,5 --Audit Tables                                                  
                                              
IF @intShowAuditSheets = 1                                              
BEGIN                                              
                                              
 SELECT                                         
 Pkey,                                        
 EventID,                                        
 EventStartTime,                                        
 EventEndTime,                                        
 StartTime AS StartTimeForRpt,                                        
 EndTime AS EndTimeForRpt,                                        
 -- EstimatedStartTime,                                       
 -- EstimatedDuration,                                        
 --ReelSpeed,                                        
 ActualStartTime As 'ActualStartTime : Calculated (Event end time - Actual Duration)',                                        
 ActualDuration As 'ActualDuration: Calculated (Lenth/Reel Speed)',           
-- ReelSpeed AS 'From Rollevents',                                         
 Team,                                        
 Shift,                     
 TeamSplitFlag AS 'TEAM SPLIT',                                       
 Length,                                        
 Width,                                        
 Area,                                        
 -- BeltSpeed,    NOT SHOWING                                    
 YFW,                                        
 Status,                                        
 Type,                                        
 PartialLength,                                        
 RollCount,                                        
 RollTotalLength,                                        
 TargetSpeed,                                        
 Belt1ActualSpeed AS 'Belt Speed Hr Avg',                                        
 WinderActualSpeed  AS 'Reel Speed Reel Avg',                                   
 Belt1SetSpeed AS 'Belt1Speedfor Report',                                      
 LastGood_Belt1Speed AS 'Belt Speed Hr Avg [ LAST GOOD VALUE Timestamp]'                                      
 FROM #TurnoverEv ORDER BY StartTime                       
                                        
 SELECT                                         
 PKey,                                        
 EventID,                                        
 ParentId,                                        
 EventStartTime,                                        
 EventEndTime,                                        
 StartTime AS StartTimeForRpt,                           
 EndTime AS EndTimeForRpt,                                        
 EstimatedStartTime,                                        
 EstimatedDuration AS 'Actual Duration from Turnover',                                        
 ReelSpeed AS 'ReelSpeed From Turnover',                       
 YFW,                                      
 Timeequivalent,                                         
 Team,                                        
 Shift,                      
 TeamSplitFlag AS 'TEAM SPLIT',                                      
 Length,                                        
 Width AS TurnoverWidth,                                        
 Area,                                        
 Status,                                        
 Type,                                        
 PartialLength,                                        
 PartialArea                                        
 FROM #RollEvents ORDER BY StartTime                                             
                                        
SELECT  Measures,LTRIM(Totalvalue)'Totalvalue' FROM #CompanionMeasures ORDER BY ColId                              
                              
                                             
END                                                   
--*********************************************************************************************************************************************                                                          
--End - Section 15 - Result set                                                        
--*********************************************************************************************************************************************                                                          
                    
GOTO Finished              
              
              
ErrorMessagesWrite:                
-------------------------------------------------------------------------------                
-- Error Messages.                
-------------------------------------------------------------------------------             
 SELECT ErrMsg FROM @ErrorMessages                
                
Finished:                
                           
           
DROP TABLE #TurnoverEv                                  
DROP TABLE #RollEvents                                                                
DROP TABLE #Turnovers                                                                 
DROP TABLE #TED1                                                                
DROP TABLE #DownUptime                                                                
DROP TABLE #Top5SheetBreaks                                                                    
DROP TABLE #Summary                                                                
DROP TABLE #InvertedSummary                                                                
DROP TABLE #RptTeams                                                                
DROP TABLE #RptShifts                                                                
DROP TABLE #TEMPORARY                                                                
DROP TABLE #ac_Top5SheetBreaks                                                                
DROP TABLE #Top5Temp                                                                
DROP TABLE #PourEvents                                                                
DROP TABLE #Sheetbreaks                                 
DROP TABLE #CompanionMeasures                                        
DROP TABLE #TeamRuns  

