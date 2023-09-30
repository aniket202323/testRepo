  /*  
------------------------------------------------------------------------------------------------------------------  
Version 1.00 Created 2007-NOV-10 by Langdon Davis  
------------------------------------------------------------------------------------------------------------------  
This SP works with RptUnitStops.xls to gather stops data for the specified date/time range and Master Unit.  The   
data are provided by Location, by Failure Mode and by Failure Mode Cause.  
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
--  Revision History:  
  
Rev 1.1  
- testing code was originally left in place when this sp was checked in the first time.    
 they were subsequently removed.  
  
2009-02-13 Jeff Jaeger Rev1.2  
- added dbo. and with (nolock) to the use of temp tables.  
- modified the definition of StopsUnscheduled, StopsMinor, StopsEquipFails, and   
 StopsProcessFailures in #Delays  
- modified the method for pulling ScheduleID, CategoryID, GroupCauseID, and SubsystemID in #delays.  
  
2009-02-26 Jeff Jaeger Rev1.3  
- updated the revision numbers of this sp so that changes can be accurately reflected in the version  
 tracking spreadsheet.  
  
2009-03-17 Jeff Jaeger Rev1.31  
- modified the definition of StopsUnscheduled, StopsMinor, StopsEquipFails, StopsProcessFailures in #Delays  
- modified the definition of SplitUnscheduledDT in #SplitDowntimes  
  
  
------------------------------------------------------------------------------------------------------------------  
  
*/  
  
CREATE  PROCEDURE dbo.spLocal_RptCvtgUnitStops  
--declare  
 @StartTime DateTime, -- Beginning period for the data.  
 @EndTime  DateTime, -- Ending period for the data.  
 @ProdUnit INTEGER  -- Prod_Units.PU_Id for the Master Unit selected.  
  
AS  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
-------------------------------------------------------------------------------  
-- Declare testing parameters.  
-------------------------------------------------------------------------------  
  
/*  
SELECT    
@StartTime = '2008-02-01 00:00:00',  
@EndTime = '2008-02-10 00:00:00',   
@ProdUnit = 76   
*/  
  
  
----------------------------------------------------------  
-- Section 1:  Define variables for this procedure.  
----------------------------------------------------------  
DECLARE  
 @ScheduleStr    VARCHAR(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CategoryStr    VARCHAR(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @GroupCauseStr    VARCHAR(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @SubSystemStr    VARCHAR(50), -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CatMechEquipId   INTEGER,   -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
 @CatElectEquipId   INTEGER,   -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
 @CatProcFailId    INTEGER,   -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
 @CatELPId     INTEGER,   -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
 @SchedPRPolyId    INTEGER,   -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
 @SchedUnscheduledId  INTEGER,   -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
 @SchedBlockedStarvedId INTEGER,   -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
 @RptWindowMaxDays   INTEGER,   -- Maximum number of days allowed in the date range specified for a given report.  
 @PUDelayTypeStr   VARCHAR(100),  
 @PUScheduleUnitStr  VARCHAR(100),  
  @PULineStatusUnitStr  VARCHAR(100),  
 @Max_TEDet_Id     INTEGER,  
 @Min_TEDet_Id    INTEGER,  
 @StartReportRun   datetime,  
 @EndReportRun    datetime--,  
  
  
--------------------------------------------------------------  
-- Section 4: Assign constant values  
--------------------------------------------------------------  
  
select @StartReportRun = getdate()  
  
SELECT  
 @ScheduleStr    = 'Schedule',  
 @CategoryStr    = 'Category',  
 @GroupCauseStr    = 'GroupCause',  
 @SubSystemStr    = 'Subsystem',  
 @CatMechEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Mechanical Equipment'),  
 @CatElectEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Electrical Equipment'),  
 @CatProcFailId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Process/Operational'),  
 @CatELPId     = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Paper (ELP)'),  
 @SchedPRPolyId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:PR/Poly Change'),  
 @SchedUnscheduledId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Unscheduled'),  
 @SchedBlockedStarvedId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Blocked/Starved'),  
 @RptWindowMaxDays   = 31,  
  @PUDelayTypeStr    = 'DelayType=',  
 @PUScheduleUnitStr   = 'ScheduleUnit=',  
  @PULineStatusUnitStr  = 'LineStatusUnit='--,  
  
  
----------------------------------------------------------------------------------  
-- Section 6: Create temp tables and table variables  
----------------------------------------------------------------------------------  
  
DECLARE @ErrorMessages TABLE ( ErrMsg VARCHAR(255) )  
  
/*  
------------------------------------------------------------------  
-- This table will hold the category information based on the   
-- values specific specific to each location.  
------------------------------------------------------------------  
DECLARE @TECategories table   
 (  
 TEDet_Id            INTEGER,  
 ERC_Id            INTEGER  
 primary key (TEDet_ID, ERC_ID)  
 )  
*/  
  
  
--------------------------------------------------------------------------  
-- this table holds information about the Event Reasons.  
--------------------------------------------------------------------------  
DECLARE @EventReasons table   
 (  
 Event_Reason_ID         int PRIMARY KEY NONCLUSTERED,  
 Event_Reason_Name         varchar(100)  
 )  
  
CREATE TABLE #Delays   
 (  
 TEDetId     INTEGER PRIMARY KEY NONCLUSTERED,  
 PrimaryId    INTEGER,  
 SecondaryId    INTEGER,  
 PLId      INTEGER,  
 PLDesc     VARCHAR(100),  
 PUId      INTEGER,  
 PUDesc     VARCHAR(100),  
 StartTime    DateTime,  
 EndTime     DateTime,  
 LocationId    INTEGER,  
 L1ReasonId    INTEGER,  
 L2ReasonId    INTEGER,  
 L3ReasonId    INTEGER,  
 L4ReasonId    INTEGER,  
 Comment     VARCHAR(5000),  
 TEFaultId    INTEGER,  
 L1TreeNodeId   INTEGER,  
 L2TreeNodeId   INTEGER,  
 L3TreeNodeId   INTEGER,  
 L4TreeNodeId   INTEGER,  
 ERTD_ID     integer,  
 ProdCode     VARCHAR(50),  
 ProdDesc     VARCHAR(50),  
 LineStatus    VARCHAR(50),  
 Shift      VARCHAR(10),  
 Team      VARCHAR(10),  
 ScheduleId    INTEGER,  
 CategoryId    INTEGER,  
 GroupCauseId   INTEGER,  
 SubSystemId    INTEGER,  
 DownTime     FLOAT,  
 SplitDowntime   FLOAT,  
 Uptime     FLOAT,  
 SplitUptime    FLOAT,  
 Stops      INTEGER,  
 StopsUnscheduled  INTEGER,  
 StopsMinor    INTEGER,  
 StopsEquipFails  INTEGER,  
 StopsProcessFailures INTEGER,  
 StopsELP     INTEGER,  
 StopsBlockedStarved INTEGER,  
 UpTime2m     INTEGER   
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
 Reason_Level1          int,  
 Reason_Level2          int,  
 Reason_Level3          int,  
 Reason_Level4          int,  
 TEFault_Id           int,  
 ERTD_ID            int,  
 Cause_Comment_Id         int,       
 Cause_Comment          VARCHAR(5000),  
 Uptime            FLOAT   
 )  
CREATE CLUSTERED INDEX ted_TEDetId_ERCId  
ON dbo.#TimedEventDetails (pu_id, start_time, end_time)  
  
DECLARE @ProdUnits TABLE   
 (  
 PUId             INTEGER PRIMARY KEY,  
 PLId             INTEGER,  
 PUDesc            VARCHAR(100),  
 PLDesc            VARCHAR(100),  
 ExtendedInfo          VARCHAR(255),  
 ScheduleUnit          INTEGER,  
 LineStatusUnit          INTEGER  
 )  
  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
IF IsDate(@StartTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('The specified Start Time is not a valid date.')  
 GOTO ReturnResultSets  
END  
  
IF IsDate(@EndTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('The specified End Time is not a valid date.')  
 GOTO ReturnResultSets  
END  
  
-- If the endtime is in the future, set it to current day.    
IF @EndTime > GetDate()  
 SELECT @EndTime = CONVERT(VarChar(4),YEAR(GetDate())) + '-' + CONVERT(VarChar(2),MONTH(GetDate())) + '-' +   
     CONVERT(VarChar(2),DAY(GetDate())) + ' ' + CONVERT(VarChar(2),DATEPART(hh,@EndTime)) + ':' +   
     CONVERT(VarChar(2),DATEPART(mi,@EndTime))+ ':' + CONVERT(VarChar(2),DATEPART(ss,@EndTime))  
  
--/*  
IF DATEDIFF(d, @StartTime,@EndTime) > @RptWindowMaxDays  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('The date range selected exceeds the maximum days allowed for this report: ' + CONVERT(VARCHAR(50),@RptWindowMaxDays) +  
      '.  Decrease the date range.')  
 GOTO ReturnResultSets  
 END  
--*/  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
INSERT @ProdUnits (  
   PUId,  
   PUDesc,   
   PLId,  
   PLDesc,   
   ExtendedInfo,  
   ScheduleUnit,  
   LineStatusUnit  )  
SELECT PU_Id,  
   PU_Desc,   
   pu.PL_Id,  
   PL_Desc,   
   pu.Extended_Info,  
   GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUScheduleUnitStr),  
   GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PULineStatusUnitStr)  
FROM   dbo.Prod_Units pu WITH (NOLOCK)  
JOIN  dbo.Prod_Lines pl with (nolock)  
ON pl.PL_ID = pu.PL_ID  
WHERE  PU_Id = @ProdUnit  
  
-------------------------------------------------------------------------------  
-- Get the Time Event Details  
-------------------------------------------------------------------------------  
  
-- We get basic delays information from the real table, Timed_Event_Details.  
-- #TimedEventDetails is an intermediary table that is used so that we don't have to   
-- join to the real table 3 times in populating #Delays.  
  
-- Note that after the intermediary table is populated we do still access the real table   
-- a number of times (with multiple inserts to #TimedEventDetails.  This is done to get related   
-- records that are outside of our report window.  If we could find   
-- a way to identify these records and include them in the initial insert to #TimedEventDetails,   
-- then we could remove a lot of the code below and reduce the hits to the database.    
  
INSERT dbo.#TimedEventDetails  
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
  ERTD_ID,  
  Cause_Comment_Id,  
  Cause_Comment,  
  Uptime  
  )  
SELECT  
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
  ted.event_reason_tree_data_id,  
  Co.Comment_Id,  
  REPLACE(coalesce(convert(varchar(5000),co.comment_text),''), char(13)+char(10), ' '),  
  Uptime  
FROM dbo.timed_event_details ted WITH (NOLOCK)  
JOIN @produnits pu ON ted.pu_id = pu.puid  
LEFT JOIN dbo.Comments Co WITH (NOLOCK) ON Co.Comment_Id = ted.Cause_Comment_Id  
WHERE Start_Time < @EndTime  
AND (End_Time > @StartTime or End_Time is null)  
ORDER BY ted.pu_id, ted.start_time, ted.end_time  
OPTION (KEEP PLAN)  
  
-- Add the secondary events that span after the report window.  
INSERT dbo.#TimedEventDetails  
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
  ERTD_ID,  
  Cause_Comment_Id,  
  Cause_Comment,   
  Uptime  
  )  
SELECT  
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
  ted2.event_reason_tree_data_id,  
  Co.Comment_Id,  
   REPLACE(coalesce(convert(varchar(5000),co.comment_text),''), char(13)+char(10), ' '),  
  ted2.Uptime  
FROM  dbo.#TimedEventDetails ted1 WITH (NOLOCK)  
JOIN  (  
  SELECT   
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
   tted.event_reason_tree_data_id,  
   tted.Cause_Comment_Id,  
   tted.Uptime  
  FROM dbo.timed_event_details tted WITH (NOLOCK)  
  JOIN  @produnits tpu ON tted.pu_id = tpu.puid   
  AND  tted.start_time >= @Endtime   
  ) ted2  
ON ted1.PU_Id = ted2.PU_Id  
AND ted1.End_Time = ted2.Start_Time  
AND ted2.start_time >= @endtime  
AND ted1.TEDet_Id <> ted2.TEDet_Id  
LEFT JOIN dbo.Comments Co WITH (NOLOCK) ON Co.Comment_Id = ted2.Cause_Comment_Id  
OPTION (KEEP PLAN)  
  
-- Add the secondary events that span before the report window.  
INSERT dbo.#TimedEventDetails  
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
  ERTD_ID,  
   Cause_Comment_Id,  
   Cause_Comment,  
  Uptime  
   )  
SELECT  
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
  ted1.event_reason_tree_data_id,  
   Co.Comment_Id,  
    REPLACE(coalesce(convert(varchar(5000),co.comment_text),''), char(13)+char(10), ' '),  
  ted1.Uptime  
FROM dbo.#TimedEventDetails ted2 WITH (NOLOCK)  
JOIN  (  
   SELECT   
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
   tted.event_reason_tree_data_id,  
   tted.Cause_Comment_Id,  
   tted.Uptime  
   FROM dbo.timed_event_details tted WITH (NOLOCK)  
   JOIN @produnits tpu ON tted.pu_id = tpu.puid   
   AND tted.start_time < @Starttime   
   AND tted.end_time <= @Starttime   
   ) ted1  
ON ted1.PU_Id = ted2.PU_Id  
AND ted1.End_Time = ted2.Start_Time  
AND ted1.end_time <= @Starttime  
AND ted2.end_time <= @Endtime  -- Added to address OX issue  
AND ted1.TEDet_Id <> ted2.TEDet_Id  
LEFT JOIN dbo.Comments Co WITH (NOLOCK) ON Co.Comment_Id = ted2.Cause_Comment_Id  
OPTION (KEEP PLAN)  
  
  
INSERT  dbo.#Delays (  
   TEDetId,  
   PLID,  
   PLDesc,  
   PUId,  
   PUDesc,  
   StartTime,  
   EndTime,  
   LocationId,  
   L1ReasonId,  
   L2ReasonId,  
   L3ReasonId,  
   L4ReasonId,  
   TEFaultId,  
   ERTD_ID,  
   Downtime,  
   SplitDowntime,  
   Uptime,  
   SplitUptime,  
   PrimaryId,  
   SecondaryId,  
   Comment)  
SELECT ted.TEDet_Id,  
   tpu.plid,  
   tpu.PLDesc,  
   ted.PU_Id,  
   tpu.PUDesc,  
   ted.Start_Time,  
   COALESCE(ted.End_Time, @EndTime),  
   ted.Source_PU_Id,  
   ted.Reason_Level1,  
   ted.Reason_Level2,     ted.Reason_Level3,  
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
   ted.Uptime * 60.0,  
   CASE WHEN (DATEADD(ss, -(ted.Uptime * 60.0), ted.Start_Time)) < @StartTime   
     THEN (DATEDIFF(ss, @StartTime, ted.Start_Time))  
     ELSE ted.Uptime * 60.0  
     END,   
   ted2.TEDet_Id,  
   ted3.TEDet_Id,  
   ted.Cause_Comment  
FROM dbo.#TimedEventDetails ted with (nolock)  
JOIN  @ProdUnits tpu ON ted.PU_Id = tpu.PUId  
AND  tpu.PUId > 0  
LEFT JOIN dbo.#TimedEventDetails ted2 with (nolock)  
ON ted.PU_Id = ted2.PU_Id  
AND ted.Start_Time = ted2.End_Time  
AND ted.TEDet_Id <> ted2.TEDet_Id  
LEFT JOIN dbo.#TimedEventDetails ted3 with (nolock)  
ON ted.PU_Id = ted3.PU_Id  
AND ted.End_Time = ted3.Start_Time  
AND ted.TEDet_Id <> ted3.TEDet_Id  
OPTION (KEEP PLAN)  
  
-------------------------------------------------------------------------------  
-- Ensure that all the PrimaryIds point to the actual Primary event.  
-------------------------------------------------------------------------------  
WHILE (   
  SELECT count(td1.TEDetId)  
  FROM  dbo.#Delays td1 with (nolock)  
  JOIN  dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
  WHERE  td2.PrimaryId IS NOT NULL  
  ) > 0  
 BEGIN  
  UPDATE   td1  
  SET    PrimaryId = td2.PrimaryId  
  FROM    dbo.#Delays td1 with (nolock)  
  INNER JOIN  dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL  
 END  
  
UPDATE dbo.#Delays  
SET  PrimaryId = TEDetId  
WHERE  PrimaryId IS NULL  
  
-------------------------------------------------------------------------------  
-- Get the Timed Event Categories for #Delays.  
-------------------------------------------------------------------------------  
  
-- APPROACH #1  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- Timed_Event_Details row FROM the Local_Timed_Event_Categories table using  
-- the TEDet_Id.  
-------------------------------------------------------------------------------  
/*  
SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
   @Min_TEDet_Id = MIN(TEDetId) - 1  
FROM   dbo.#Delays with (nolock)  
option (keep plan)  
  
INSERT INTO @TECategories   
 (  
 TEDet_Id,  
 ERC_Id  
 )  
SELECT tec.TEDet_Id,  
   tec.ERC_Id  
FROM  dbo.#Delays td with (nolock)  
JOIN   dbo.Local_Timed_Event_Categories tec with (nolock)  
ON  td.TEDetId = tec.TEDet_Id  
AND  tec.TEDet_Id > @Min_TEDet_Id  
AND  tec.TEDet_Id < @Max_TEDet_Id  
option (keep plan)  
  
UPDATE td  
SET  ScheduleId = tec.ERC_Id  
FROM  dbo.#Delays td with (nolock)  
JOIN   @TECategories tec   
ON   td.TEDetId = tec.TEDet_Id  
JOIN   dbo.Event_Reason_Catagories erc with (nolock)  
ON  tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
UPDATE td  
SET  CategoryId = tec.ERC_Id  
FROM  dbo.#Delays td with (nolock)  
JOIN   @TECategories tec   
ON   td.TEDetId = tec.TEDet_Id  
JOIN   dbo.Event_Reason_Catagories erc with (nolock)  
ON  tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @CategoryStr + '%'  
  
UPDATE td  
SET   GroupCauseId = tec.ERC_Id  
FROM   dbo.#Delays td with (nolock)  
JOIN   @TECategories tec   
ON   td.TEDetId = tec.TEDet_Id  
JOIN   dbo.Event_Reason_Catagories erc with (nolock)  
ON  tec.ERC_Id = erc.ERC_Id                     
AND  erc.ERC_Desc LIKE @GroupCauseStr + '%'  
  
UPDATE td  
SET   SubSystemId = tec.ERC_Id  
FROM   dbo.#Delays td with (nolock)  
JOIN   @TECategories tec   
ON   td.TEDetId = tec.TEDet_Id  
JOIN   dbo.Event_Reason_Catagories erc with (nolock)  
ON  tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @SubSystemStr + '%'  
  
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
  
  
-------------------------------------------------------------------------------  
-- Add the Products to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET ProdCode = p.Prod_Code   
 FROM dbo.#Delays td with (nolock)  
 JOIN dbo.Production_Starts ps WITH (NOLOCK) ON td.PUId = ps.PU_Id  
  AND td.StartTime >= ps.Start_Time  
  AND (td.StartTime < ps.End_Time OR ps.End_Time IS NULL)  
 JOIN dbo.products p WITH (NOLOCK) ON  ps.prod_id = p.prod_id  
  
UPDATE td  
 SET ProdDesc = p.Prod_Desc  
 FROM dbo.#Delays td with (nolock)  
 JOIN dbo.Production_Starts ps WITH (NOLOCK) ON td.PUId = ps.PU_Id  
  AND td.StartTime >= ps.Start_Time  
  AND (td.StartTime < ps.End_Time OR ps.End_Time IS NULL)  
 JOIN dbo.products p WITH (NOLOCK) ON  ps.prod_id = p.prod_id  
  
-------------------------------------------------------------------------------  
-- Add the Shift and Crew to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET Shift = cs.Shift_Desc,  
  Team = cs.Crew_Desc  
 FROM dbo.#Delays td with (nolock)  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
 JOIN dbo.Crew_Schedule cs WITH (NOLOCK) ON tpu.ScheduleUnit = cs.PU_Id  
  AND td.StartTime >= cs.Start_Time  
  AND td.StartTime < cs.End_Time  
  
-------------------------------------------------------------------------------  
-- Add the Line Status to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
  SET LineStatus = ( SELECT phrase_value  
         FROM  dbo.Local_PG_Line_Status ls with (nolock)  
         JOIN  @ProdUnits pu ON ls.Unit_Id = pu.LineStatusUnit   
         JOIN  dbo.Phrase p with (nolock)ON line_status_id = p.Phrase_Id  
         WHERE ls.update_status <> 'DELETE'    
         AND  td.StartTime >= ls.start_datetime   
         AND  (td.StartTime < ls.end_datetime or ls.end_datetime is null))  
  FROM dbo.#Delays td with (nolock)  
           
-------------------------------------------------------------------------  
-- Calculate the Statistics for stops information in the #Delays dataset.   
-------------------------------------------------------------------------  
/*  
UPDATE td SET   
 Stops =     
  CASE   
  WHEN (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsUnscheduled =  
  CASE   
--  WHEN tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN tpu.pudesc like '%reliability%'  
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
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN td.DownTime < 600  
  and tpu.pudesc like '%reliability%'  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsEquipFails =     
  CASE   
--  WHEN td.DownTime >= 600  
--  and tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN td.DownTime >= 600  
  and tpu.pudesc like '%reliability%'  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsELP =    
  CASE   
  WHEN (td.CategoryId = @CatELPId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsBlockedStarved =   
  CASE   
  WHEN td.ScheduleId = @SchedBlockedStarvedId    
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 UpTime2m =    
  CASE   
  WHEN td.UpTime < 120  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsProcessFailures =   
  CASE   
--  WHEN td.DownTime >= 600  
--  and tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId)   
--   OR coalesce(td.CategoryId,0)=0)  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN td.DownTime >= 600  
  and tpu.pudesc like '%reliability%'  
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
WHERE td.TEDetId = td.PrimaryId  
*/  
  
UPDATE td SET   
 Stops =     
  CASE   
  WHEN (td.StartTime >= @StartTime)  
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
  WHEN (td.CategoryId = @CatELPId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsBlockedStarved =   
  CASE   
  --WHEN td.CategoryId = @CatBlockStarvedId     
  WHEN td.ScheduleId = @SchedBlockedStarvedId  --FLD 01-NOV-2007 Rev11.53  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 UpTime2m =    
  CASE   
  WHEN td.UpTime < 120  
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
  
  
--------------------------------------------------------------------------------  
--  Get Event_Reason and Event_Reason_Category info.  
--------------------------------------------------------------------------------  
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
  
  
---------------------------------------------------------------------  
ReturnResultSets:  
  
IF (SELECT count(*) FROM @ErrorMessages) > 0  
 BEGIN  
 SELECT ErrMsg  
 FROM  @ErrorMessages  
 END  
ELSE  
 BEGIN  
  -----------------------------------------------------------------------------  
  -- Return the Stops data summarized by Location for the Line.  
  -----------------------------------------------------------------------------  
  SELECT  pu.PU_Desc [Location],  
   SUM(Coalesce(td.Stops, 0)) [Total Unscheduled Stops],  
   ROUND(SUM(CONVERT(FLOAT, td.SplitDowntime) / 60.0),2) [Total Unscheduled Downtime]  
  FROM  dbo.#Delays td with (nolock)  
   LEFT JOIN dbo.Prod_Units pu WITH (NOLOCK) ON td.LocationId = pu.PU_Id  
  WHERE td.StopsUnscheduled = 1  
  GROUP BY pu.PU_Desc  
--  ORDER BY [Total Unscheduled Stops] DESC, [Total Unscheduled Downtime] DESC  
  ORDER BY [Total Unscheduled Downtime] DESC  
  
  -----------------------------------------------------------------------------  
  -- Return the Stops data summarized by Failure Mode for the Line.  
  -----------------------------------------------------------------------------  
  SELECT  er.Event_Reason_Name [Failure Mode],  
   SUM(Coalesce(td.Stops, 0)) [Total Unscheduled Stops],  
   ROUND(SUM(CONVERT(FLOAT, td.SplitDowntime) / 60.0),2) [Total Unscheduled Downtime]  
  FROM  dbo.#Delays td with (nolock)  
   LEFT JOIN dbo.Event_Reasons er WITH (NOLOCK) ON td.L1ReasonId = er.Event_Reason_Id  
  WHERE td.StopsUnscheduled = 1  
  GROUP BY er.Event_Reason_Name  
  ORDER BY [Total Unscheduled Stops] DESC, [Total Unscheduled Downtime] DESC  
  
  -----------------------------------------------------------------------------  
  -- Return the Stops data summarized by Failure Mode for the Line.  
  -----------------------------------------------------------------------------  
  SELECT  er.Event_Reason_Name [Failure Mode Cause],  
   SUM(Coalesce(td.Stops, 0)) [Total Unscheduled Stops],  
   ROUND(SUM(CONVERT(FLOAT, td.SplitDowntime) / 60.0),2) [Total Unscheduled Downtime]  
  FROM  dbo.#Delays td with (nolock)  
   LEFT JOIN dbo.Event_Reasons er WITH (NOLOCK) ON td.L2ReasonId = er.Event_Reason_Id  
  WHERE td.StopsUnscheduled = 1  
  GROUP BY er.Event_Reason_Name  
  ORDER BY [Total Unscheduled Downtime] DESC  
  
  -------------------------------------------------------------------------------  
  -- If the dataset has more than 65000 records, then send an error message and  
  -- suspend processing.  This is because Excel can not handle more than 65536 rows  
  -- in a spreadsheet.  
  -------------------------------------------------------------------------------  
  
   if (SELECT Count(TEDetId)FROM dbo.#Delays with (nolock)) > 65000  
   begin  
     SELECT 'The dataset contains more than 65000 rows.  This exceeds the Excel limit.'  
   end -- begin  
   else  
   begin  
    SELECT --td.tedetid,  
       td.PLDesc [Production Line],  
       td.PUDesc [Master Unit],  
       CONVERT(VARCHAR(25), td.StartTime, 101) [Start Date],  
       CONVERT(VARCHAR(25), td.StartTime, 114) [Start Time],  
       CONVERT(VARCHAR(25), td.EndTime, 101) [End Date],  
       CONVERT(VARCHAR(25), td.EndTime, 114) [End Time],  
       CASE  WHEN td.TEDetId = td.PrimaryId THEN 'Primary'   
         ELSE 'Secondary' END [Event Type],  
       ROUND(CONVERT(FLOAT, COALESCE(td.Downtime,0)),2) / 60.0 [Event Downtime],  
       ROUND(COALESCE(td.SplitDowntime,0)/60.0,2) [Split Downtime],  
       COALESCE(td.Stops, 0) [Stop],  
       COALESCE(td.StopsUnscheduled, 0) [Unscheduled Stop],  
       COALESCE(td.StopsMinor, 0) [Minor Stop],  
       COALESCE(td.StopsEquipFails, 0) [Equipment Failure],   
       COALESCE(td.StopsProcessFailures, 0) [Process Failure],  
       COALESCE(td.StopsELP, 0) [ELP Stop],  
       COALESCE(td.StopsBlockedStarved, 0) [Blocked/Starved Stop],  
       ROUND(CONVERT(FLOAT, COALESCE(td.UpTime,0)),2) / 60.0 [Raw Uptime],  
       ROUND(COALESCE(td.SplitUpTime,0)/60.0,2) [Split Uptime],   
       COALESCE(td.UpTime2m, 0) [Uptime < 2 Min],  
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
       td.Comment [Comment],  
       td.ProdCode [Product],  
       td.ProdDesc [Product Desc],  
       td.team [Team],  
       td.Shift [Shift],  
       td.LineStatus [Line Status],  
       er3.Event_Reason_Name [Reason Level 3],  
       er4.Event_Reason_Name [Reason Level 4]  
    FROM dbo.#Delays td with (nolock)  
    LEFT JOIN dbo.Event_Reason_Catagories erc1 with (nolock)  
    ON td.ScheduleId   = erc1.ERC_Id  
    LEFT JOIN dbo.Event_Reason_Catagories erc2 with (nolock)  
    ON td.CategoryId   = erc2.ERC_Id  
    LEFT JOIN dbo.Event_Reason_Catagories erc3 with (nolock)  
    ON td.SubSystemId  = erc3.ERC_Id  
    LEFT JOIN dbo.Event_Reason_Catagories erc4 with (nolock)  
    ON td.GroupCauseId  = erc4.ERC_Id  
    LEFT JOIN dbo.Prod_Units loc with (nolock) ON td.LocationId = loc.PU_Id  
    LEFT JOIN @EventReasons  er1  ON td.L1ReasonId   = er1.Event_Reason_Id  
    LEFT JOIN @EventReasons  er2  ON td.L2ReasonId   = er2.Event_Reason_Id  
    LEFT JOIN @EventReasons  er3  ON td.L3ReasonId   = er3.Event_Reason_Id  
    LEFT JOIN @EventReasons  er4  ON td.L4ReasonId   = er4.Event_Reason_Id  
    LEFT  JOIN  dbo.Timed_Event_Fault tef  with (nolock) ON (td.TEFaultID   = TEF.TEFault_ID)  
    ORDER  BY td.Starttime  
    OPTION (KEEP PLAN)  
  end -- else  
 END -- else  
  
  
select @EndReportRun = getdate()  
  
-- we want to track the runtime of this report, in case larger report windows begin   
-- to cause a problem with processor resources.  the local table being used for this tracking  
-- has the Master_Unit, the time the run started, the start of the report window, the end   
-- of the report window, and the runtime, which is approximate, since the sp hasn't completed   
-- quite yet.  
insert Local_PG_UnitStops_Tracking  
 (  
 [Master_Unit],  
 [TimeStamp],  
 [Report_Start],  
 [Report_End],  
 [Runtime]  
 )  
select  
 @ProdUnit,  
 @StartReportRun,  
 @StartTime,  
 @EndTime,  
 datediff(ss,@StartReportRun,@EndReportRun)  
  
  
-------------------------------------  
--Drop Tables.  
  
DROP TABLE dbo.#TimedEventDetails  
DROP TABLE dbo.#Delays  
  
  
Finished:  
 RETURN  
  
  
