    /*  
Stored Procedure: spLocal_PE_DowntimeExplorer_2_1_4  
Author:   S. Stier (Stier Automation)  
Date Created:  10/01/02  
  
Description:  
=========  
Returns  Downtime data for Proficy Explorer tool   
  
XLA Version Change Date Who What  
============ =========== ==== =====  
V0.0.1  10/01/02 SLS Initial Design  
V0.0.2  10/02/02 SLS Updates for Categories  
V0.0.2  10/04/02 SLS Changed Occurnaces to Stops  
V0.0.3  10/09/02 SLS Added All Inputs  
V0.0.4  10/09/02 SLS Added All Inputs  
V0.0.5  10/09/02 SLS Issue to K. Rafferty  
V0.0.7  10/10/02 SLS Added interval Chart Capability  
V0.0.8  10/11/02 SLS Issue to Kim and Bunch of Fixes  
V0.0.9  10/29/02 SLS Issue to Kim and fixed shift and Team Duplicate returns  
V0.1.3  11/01/02 HRM Eliminate duplicate downtime where multiple comments added to a record  
V0.1.3  11/21/03 sls used Local_Timed_Event_Categories instead of looking up from reason tree  
V0.1.4  12/8/03 SLS Allow Multiple Units to be passed to it.  
V0.1.4  12/09/03 SLS Handle Multiple Produciton Units  
V0.1.4  12/14/03 SLS Added Some new Options  
  12/15/03  Added Parent Roll data (UWS1 and UWS2: PRID, Fresh/Storage, PaperMachine)  
  12/16/03  Issue to Kim Rafferty  
  1/13/04 SLS Bunch of Changes  
  1/23/04 SLS Fresh/Storage mods  
V0.1.5  1/27/04 SLS     Release to B.Barre  
V0.1.5  2/12/04 SLS     Fixed Minor Stops calc  
V0.1.9           3/5/04           SLS     Fixed Some Bad Category Calcs  
V2.0.0           6/7/04           SLS     Made Shift/Team Calc Optional  
V2.1.2  7/14/04 BAS Changed StartD and EndD declaration from varchar (10) to datetime on #DownTime and #DownTimeFinal temp tables to support regional date/time settings.  
     Removed datepart programming from StartD and EndD in the @InputOutPutType section.  
V2.1.2  9/21/04 BAS Renamed sp with XLA version.  
V2.1.3  1/03/05 HRM if reason2 is null, 'other', 'troubleshooting' or 'unknown', add reason1 to reason2  
V2.1.3  2/3/05  BAS Modified downtime event FM and FMC appending per Kims new requirements  
     Added Rate Loss event text  **UNCODED**: RATE LOSS  to blank FMs and FMCs  
V2.1.3  2/16/05 BAS Changed update code for StartD and EndD columns  to correct Excel VBA  formatting issue for Bruce Barre.  Bruce requres these Excel columns to be date ONLY for correct pivot table functionality.  Also need to make sure that  
     the date formatting works for Non-U.S. sites. (Item 73)  
V2.1.3  3/24/05 BAS Replaced code that queries for Comments when Raw Data is selected because of missing comments issue submitted by Kim Rafferty 3/23/05. (Item 74)   
     The old code was selecting the last comment (timestamp) entry of a split event.  This is usually NULL.  
     Added code to remove CrLf from Comments.  
V2.1.3  3/25/05 BAS/HRM Added code to get all comments from a downtime event per Bruce Barre's request (Item 75)  
V2.1.4  4/1/05  BAS/HRM Added Rate Loss queries (Item 58)  
V2.1.4  6/3/05  BAS Corrected issue when too many characters were in the comments.  
v2.1.4  10/17/05 JSJ/BAS updated code to draw PRID, Paper Machine, and Fresh/Storage info from the test table.  
    11/3/05 BAS  Moved #test table creation to top because errors occured when the table does not exist.  
v2.1.5  2006-09-28 Marc Charest Did corrections for minor bug with Actual & Target Speed  
             We now update target & actual speed befor updating startimes & endtimes.  
             We then retreive  speed even if some starttimes and endtimes are before  
             inputStarttime or after inputEndtime.   
2007-06-19 FGO correct line status for mp only  
2008-11-11 MAT INserted considtional logic so the SP works without Local_PG_Line Status or fnLocal_GLblParseInfo  
    select pu_desc from prod_units where pu_desc like 'mt66%'  
2009-02-19 Jeff Jaeger (Stier Automation)    
 modified the method for pulling Cat1, Cat2, Cat3, and Cat4.  
  
*/  
/*  
spLocal_PE_DowntimeExplorer_2_1_4    '2004-03-03 00:00:00 ', '2004-03-04 00:00:00 ','MT66 Converter Reliability,MT66 rate loss','All','All','All','All','All','All','All','All','All','All','All','All','Fault','Downtime',0,'>','RAW DATA',60  
spLocal_PE_DowntimeExplorer_2_1_4  '2002-08-16 11:00:00 ', '2002-08-31 11:00:00 ','qxae71 cell','Card','All','All','All','All','All','All','All','All','All','All','All','Location','Downtime',0,'>','Interval Chart',60  
spLocal_PE_DowntimeExplorer_2_1_4  '2002-11-03 11:30:00 ', '2002-11-05 16:00:00 ','Widget Making Line 1','All','All','All','All','All','All','All','All','All','All','All','All','Location','Downtime',0,'>','Interval Chart',60  
*/  
  
  
CREATE    procedure spLocal_PE_DowntimeExplorer_2_1_4  
--declare  
  
@InputStartTime  DateTime,  
@InputEndTime  DateTime,  
@InputMasterProdUnits VarChar(8000), --nVarChar(4000), 12/20/04 BAS Changed to varchar because nVarChar has a max character limit of 4000.  This was causing an issue when MP was pulling all Reliabity master units.  
@InputLocations  nVarChar(4000),  
@InputFaults  nVarChar(4000),  
@InputReason1s  nVarChar(4000),  
@InputReason2s  nVarChar(4000),  
@InputReason3s  nVarChar(4000),  
@InputReason4s  nVarChar(4000),  
@InputTeams  nVarChar(4000),  
@InputShifts  nVarChar(4000),  
@InputCat1s  nVarChar(4000),  
@InputCat2s  nVarChar(4000),  
@InputCat3s  nVarChar(4000),  
@InputCat4s  nVarChar(4000),  
@InputGroupBy  varchar(50),  
@InputOrderBy  varchar(50),  
@InputDurationLimit varchar(50),  
@InputDurationOper varchar(50),  
@InputOutPutType varchar(50),  
@InputInterval  int,  
@InputProducts  nvarchar(4000)= 'All',  
@InputFailureTypes nvarchar(4000)='All',  
@InputPmkgMachines nvarchar(4000)='All',  
@InputFreshStorage nvarchar(4000)='All',  
@InputCalcFreshStorage int = 0,  
@InputCalcUptime int = 0,  
@InputCalcShiftTeam int = 1  
  
  
As  
--return  
  
/*  
  
select  
@InputStartTime = '2009-02-16 07:30:00',  
@InputEndTime = '2009-02-17 07:30:00',  
@InputMasterProdUnits = 'OTT1 Converter Reliability',  
@InputLocations = 'All',  
@InputFaults = 'All',  
@InputReason1s = 'All',  
@InputReason2s = 'All',  
@InputReason3s = 'All',  
@InputReason4s = 'All',  
@InputTeams = 'All',  
@InputShifts = 'All',  
@InputCat1s = 'All',  
@InputCat2s = 'All',  
@InputCat3s = 'All',  
@InputCat4s = 'All',  
@InputGroupBy = 'Downtime',  
@InputOrderBy = 'Downtime',  
@InputDurationLimit = '0',  
@InputDurationOper = '>',  
@InputOutPutType = 'Raw Data', --'Pareto',  
@InputInterval = 1440,  
@InputProducts = 'All',  
@InputFailureTypes = 'All',  
@InputPmkgMachines = 'All',  
@InputFreshStorage = 'All',  
@InputCalcFreshStorage = 1,  
@InputCalcUptime = 0,  
@InputCalcShiftTeam = 0  
  
*/  
  
  
 Set Nocount On  
-----------------------------------------------------------  
-- Declare program variables.  
-----------------------------------------------------------  
DECLARE           @InputOrderByClause nvarChar(4000),   
  @InputGroupByClause nvarChar(4000),  
  @strSQL  nVarChar(4000),  
  @current   datetime,  
  @tmpStartTime as datetime,  
  @tmpEndTime as datetime,  
  @tmpCount as int,  
  @tmpLoopCounter  int,  
  @DetermineFresh  int,  
  @StartTime DateTime,  
  @EndTime DateTime,  
  @PRIDVarId Integer,  
  @PRIDVarStr nVarChar(50),  
  @MaxUWSHistoryHrs Integer,  
  @CatPrefix    varchar (30)--,  
--  @PULineStatusUnitStr   VARCHAR(100)  
  
-- The @MaxUWSHistoryHrs variable is used to set the number of hours to go back in history and search  
-- for the PRID that was running at the time of the downtime event.  If the last  
-- parent roll loaded on the line is older than the difference between the event end time    
-- and this number of hours, then return NULL.  A negative value means to subtract   
-- the number of hours from the event end time.  
SELECT @MaxUWSHistoryHrs = -24--,  
--@PULineStatusUnitStr  = 'LineStatusUnit='  
  
------------------------------------------------------------  
---- CREATE  Temp TABLES   ---------------------------------  
------------------------------------------------------------  
Create table #DownTime(      
    
 StartTime datetime,  
 EndTime datetime,  
 StartD  datetime,--varchar(10),  
 StartT  varchar(10),  
 EndD  datetime,--varchar(10),  
 EndT  varchar(10),  
 ClockDuration Float,--Added to contain rate loss event durations  
 Uptime  Float,  
 Downtime Float,  
 MasterProdUnit varchar(100),  
 Location varchar(50),  
 Fault  varchar(100),  
 Reason1 varchar(100),  
 Reason2 varchar(100),  
 Reason3 varchar(100),  
 Reason4 varchar(100),  
 Team  varchar(25),  
 Shift  varchar(25),  
 Cat1  varchar(50),  
 Cat2  varchar(50),  
 Cat3  varchar(50),  
 Cat4  varchar(50),  
 Cat5  varchar(50),  
 Cat6  varchar(50),  
 Cat7  varchar(50),  
 Cat8  varchar(50),  
 Cat9  varchar(50),  
 Cat10  varchar(50),  
 Product  varchar(100),  
 Brand  varchar(100),  
 FailureType varchar(100),  
 Comments varchar(2000),  
 LineStatus varchar(50),  
 UWS1_Prid varchar(100),  
 UWS1_Fresh_Storage varchar(25),  
 UWS1_Pkmg_Machine  varchar(100),  
 UWS2_Prid varchar(100),  
 UWS2_Fresh_Storage varchar(25),  
 UWS2_Pkmg_Machine  varchar(100),  
 StartTime_Act datetime,  
 EndTime_Act datetime,  
 Endtime_Prev datetime,  
 Sched_PUID INT,  
 PUID  INT,  
 PLID  INT,  --used to get the Converter Production PU_Id for each event.  
 ProdPUID INT,  --used to get the Converter Production PU_Id for each event.  
 SourcePUID INT,  
-- LineStatusPUID int,  
 tedet_id  INT,  
 ReasonID1 INT,  
 ReasonID2 INT,  
 ReasonID3 INT,  
 ReasonID4 INT,  
 ERTD_ID  int,  
 ErtdID1 INT,  
 ErtdID2 INT,  
 ErtdID3 INT,  
 ErtdID4 INT,  
 SBP INT,  
 EAP  INT,  
 ActualSpeed float,  
 TargetSpeed float,  
 Spare1  varchar(255),   
 Spare2  varchar(255),   
 Spare3  varchar(255),  
 Spare4  varchar(255),   
 Spare5  varchar(255),   
 Spare6  varchar(255),   
 Spare7  varchar(255),   
 Spare8  varchar(255),   
 Spare9  varchar(255),   
 Spare10 varchar(255),  
 LAST_ID  INT,  
 Cause_Comment_Id INT --07/05/05 BAS  
)  
CREATE INDEX td_PUId_StartTime  
 ON #DownTime (PUId, StartTime)  
CREATE INDEX td_PUId_EndTime  
 ON #DownTime (PUId, EndTime)  
  
  
Create table #DownTimeFinal(      
    
 StartTime  datetime,  
 EndTime  datetime,  
 StartD   datetime,--varchar(10),  
 StartT   varchar(10),  
 EndD   datetime,--varchar(10),  
 EndT   varchar(10),  
 ClockDuration Float,--Added to contain rate loss event durations  
 Uptime   Float,  
 Downtime  Float,  
 MasterProdUnit  varchar(100),  
 Location  varchar(50),  
 Fault   varchar(100),  
 Reason1  varchar(100),  
 Reason2  varchar(100),  
 Reason3  varchar(100),  
 Reason4  varchar(100),  
 Team  varchar(25),  
 Shift  varchar(25),  
 Cat1  varchar(50),  
 Cat2  varchar(50),  
 Cat3  varchar(50),  
 Cat4  varchar(50),  
 Cat5  varchar(50),  
 Cat6  varchar(50),  
 Cat7  varchar(50),  
 Cat8  varchar(50),  
 Cat9  varchar(50),  
 Cat10  varchar(50),  
 Product  varchar(100),  
 Brand  varchar(100),  
 FailureType varchar(100),  
 Comments varchar(2000),  
 LineStatus varchar(50),  
 UWS1_Prid varchar(100),  
 UWS1_Fresh_Storage varchar(25),  
 UWS1_Pkmg_Machine  varchar(100),  
 UWS2_Prid varchar(100),  
 UWS2_Fresh_Storage varchar(25),  
 UWS2_Pkmg_Machine  varchar(100),  
 StartTime_Act datetime,  
 EndTime_Act datetime,  
 Endtime_Prev datetime,  
 Sched_PUID INT,  
 PUID  INT,  
 PLID  INT,  --used to get the Converter Production PU_Id for each event.  
 ProdPUID INT,  --used to get the Converter Production PU_Id for each event.     
 SourcePUID INT,  
-- LineStatusPUID int,  
 tedet_id  INT,  
 ReasonID1 INT,  
 ReasonID2 INT,  
 ReasonID3 INT,  
 ReasonID4 INT,  
 ERTD_ID  int,  
 ErtdID1 INT,  
 ErtdID2 INT,  
 ErtdID3 INT,  
 ErtdID4 INT,  
 SBP INT,  
 EAP  INT,  
 ActualSpeed float,  
 TargetSpeed float,   
 Spare1  varchar(255),   
 Spare2  varchar(255),   
 Spare3  varchar(255),  
 Spare4  varchar(255),   
 Spare5  varchar(255),   
 Spare6  varchar(255),   
 Spare7  varchar(255),   
 Spare8  varchar(255),   
 Spare9  varchar(255),   
 Spare10 varchar(255),  
 LAST_ID  INT,  
 Cause_Comment_Id INT --07/05/05 BAS  
)  
  
  
Create table #DTSummary(   
  
 groupName  varchar(100),  
 Downtime Float,  
 Stops Int  
)  
  
Create table #DTInterval(      
    
 StartTime  datetime,  
 EndTime  datetime,  
 Duration  Float,  
 TotalDowntime  Float,  
 TotalStops  Int  
)  
  
create table #ttl(st datetime, totl float)  
  
create table dbo.#Tests   
  (  
  VarId             INTEGER,  
  Value             varchar(25),  
  StartTime           DATETIME--,  
  primary key (varid, starttime)  
  )  
  
CREATE TABLE #ErrorMessages (  
 ErrMsg    nVarChar(255) )  
  
  
IF IsDate(@InputStartTime) <> 1   
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('StartTime is not a Date.')  
 GOTO ErrorMessagesWrite  
END  
IF IsDate(@InputEndTime) <> 1  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('EndTime is not a Date.')  
 GOTO ErrorMessagesWrite  
END  
  
  
--added code to pull PL_Id and ProdPUID (Converter Production PU_Id) from Prod_Units  
insert into #DownTime (StartTime,EndTime,MasterProdUnit,Fault,Location,PUID,PLID,ProdPUID, Reason1,Reason2,Reason3,Reason4,  
startTime_act,EndTime_act,tedet_id,REASONID1,REASONID2,REASONID3,REASONID4,SourcePUID,Cause_Comment_Id, ERTD_ID) --Added 07/05/05 BAS  
select ted.start_time, ted.end_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc ,  ted.pu_ID, pu.PL_Id, pup.PU_Id,  
r1.event_reason_name, r2.event_reason_name, r3.event_reason_name, r4.event_reason_name, ted.start_time, ted.end_time, ted.tedet_id,  
ted.reason_level1, ted.reason_level2, ted.reason_level3, ted.reason_level4, ted.Source_PU_ID,ted.Cause_Comment_Id, ted.event_reason_tree_data_id --Added 07/05/05 BAS  
  
--insert into #DownTime (StartTime,EndTime,MasterProdUnit,Fault,Location,PUID,PLID,ProdPUID,Reason1,Reason2,Reason3,Reason4,  
--startTime_act,EndTime_act,tedet_id,REASONID1,REASONID2,REASONID3,REASONID4,SourcePUIDCause_Comment_Id) --Added 07/05/05 BAS)   
--select ted.start_time, ted.end_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc ,  ted.pu_ID, pu.PL_Id, pup.PU_Id,r1.event_reason_name,   
--r2.event_reason_name, r3.event_reason_name, r4.event_reason_name, ted.start_time, ted.end_time, ted.tedet_id,  
--ted.reason_level1, ted.reason_level2, ted.reason_level3, ted.reason_level4, ted.Source_PU_ID,ted.Cause_Comment_Id --Added 07/05/05 BAS  
FROM dbo.timed_event_details AS ted with (nolock)   
LEFT JOIN dbo.event_reasons AS r1 with (nolock) ON (r1.event_reason_id = ted.reason_level1)  
LEFT JOIN dbo.event_reasons AS r2 with (nolock) ON (r2.event_reason_id = ted.reason_level2)  
LEFT JOIN dbo.event_reasons AS r3 with (nolock) ON (r3.event_reason_id = ted.reason_level3)  
LEFT JOIN dbo.event_reasons AS r4 with (nolock) ON (r4.event_reason_id = ted.reason_level4)  
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) on (pu2.pu_id = ted.pu_id)  
LEFT JOIN dbo.prod_units pup with (nolock) ON (pu2.pl_id = pup.pl_id AND pup.pu_desc LIKE '%Converter Production')  
WHERE    ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnits+','  )) > 0 or (@InputMasterProdUnits = 'All'))  
and( ((Start_time < =  @InputEndTime) and (end_time > @InputStartTime)) or ((Start_time < =  @InputEndTime )and end_time Is Null) )  
and ((CHARINDEX( ','+PU.pu_desc+','  ,  ','+ @InputLocations+','  )) > 0 or (@InputLocations = 'All'))  
and ((CHARINDEX( ','+tef.tefault_name+','  ,  ','+ @InputFaults+','  )) > 0 or (@InputFaults = 'All'))  
and ((CHARINDEX( ','+r1.event_reason_name+','  ,  ','+ @InputReason1s+','  )) > 0 or (@InputReason1s = 'All'))  
and ((CHARINDEX( ','+r2.event_reason_name+','  ,  ','+ @InputReason2s+','  )) > 0 or (@InputReason2s = 'All'))  
and ((CHARINDEX( ','+r3.event_reason_name+','  ,  ','+ @InputReason3s+','  )) > 0 or (@InputReason3s = 'All'))  
and ((CHARINDEX( ','+r4.event_reason_name+','  ,  ','+ @InputReason4s+','  )) > 0 or (@InputReason4s = 'All'))  
  
  
--- Determine the Comments added for the data  
  
if  @InputOutPutType = 'Raw Data'   
begin  
  
 UPDATE #DOWNTIME SET LAST_ID= (  
  Select MIN(Comment_Id)  
  from dbo.comments wtc with (nolock)   
  WHERE #DOWNTIME.Cause_Comment_Id = WTC.TopOfChain_Id )  
   
 DECLARE @cnt int  
 Select @cnt = 10  
  
 While  @cnt > 0  
  begin  
     
   UPDATE #DOWNTIME SET   
    Comments = isnull(comments,'') + ISNULL(  
    (select TOP 1 convert(varchar(2000),WTC.Comment_Text)        
    FROM dbo.Comments WTC with (nolock)  
    WHERE #downtime.LAST_ID = WTC.Comment_Id   
    ) ,'')  
    , LAST_ID = (SELECT MIN(Comment_Id)  
    FROM dbo.Comments WTC with (nolock)  
    WHERE TopOfChain_Id = #DOWNTIME.Cause_Comment_Id  
    AND WTC.Comment_ID > #DOWNTIME.LAST_ID)  
  
   update #DOWNTIME set comments = replace(comments,  char(13), '')  
   update #DOWNTIME set comments = replace(comments, char(10) , '')  
   update #DOWNTIME set comments = replace(comments, '   ' , '')  
   update #DOWNTIME set comments = rtrim(ltrim(comments)) + ' | ' where comments is not null and comments <> '' AND RIGHT(COMMENTS,2)<>'| '  
  
   select @cnt = @cnt - 1  
    
  end  
    
  update #downtime set comments = LEFT(COMMENTS, LEN(COMMENTS) - 2) WHERE RIGHT(COMMENTS,3) = ' | '  
end  
   
--Block 1  
------------------------------------------ 4/1/05:  (Item 58) Rate Loss data ------------------------  
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fnLocal_GlblParseInfo]'))  
BEGIN  
  
 update #downtime set targetspeed = (  
  select result from dbo.tests tt with (nolock)  
  join dbo.variables vv with (nolock) on vv.var_id = tt.var_id  
   and vv.pu_id = #downtime.puid  
   --and var_desc = 'line target speed'  
   and dbo.fnLocal_GlblParseInfo(vv.Extended_Info, 'GlblDesc=') LIKE '%' + replace('Line Target Speed',' ','')  
  where tt.result_on = #downtime.starttime)    
  
  
 update #downtime set actualspeed = (  
  select result from dbo.tests tt with (nolock)  
  join dbo.variables vv with (nolock) on vv.var_id = tt.var_id  
   and vv.pu_id = #downtime.puid  
   --and var_desc = 'line actual speed'  
   and dbo.fnLocal_GlblParseInfo(vv.Extended_Info, 'GlblDesc=') LIKE '%' + replace('Line Actual Speed',' ','')  
  where tt.result_on = #downtime.starttime)    
END  
  
----If the downtime event started before the period then change the starttime to the period start and Set SBP (Downtime Started before period)--  
update #downtime set starttime=@InputStartTime,  
  SBP = 1  
 where starttime<@InputStartTime  
  
  
----If the downtime event ended after the report period then change the endttime to the period Endtime and Set EAP (Downtime Ended After period)--  
  
update #downtime set endtime=@InputEndTime,  
  EAP = 1  
  where endtime>@InputEndTime   
  
  
----------set Downtime -------------  
  
update #downtime set Downtime = datediff(s,starttime,endtime)/60.0  
   
----If there is in no endtime (which should mean that the record is still open (downtime is still active) assume that the endtime of the event is  
  
  
update #downtime set Downtime = datediff(s,starttime,@InputEndTime)/60.0  
 where Endtime is null  
  
--Copy Downtime column to ClockDuration column for rate loss events (4/5/05) BAS  
update #downtime set ClockDuration = Downtime  
  
  
---- Calculate Uptime but only if the user needs it----  
  
If (@InputCalcUptime = 1) and (@InputOutPutType = 'Raw Data') and (@InputLocations = 'All') and (@InputFaults = 'All') and  (@InputReason1s = 'All')  and (@InputReason2s = 'All') and (@InputReason3s = 'All') and (@InputReason4s = 'All')  
Begin  
  
 update #downtime set uptime=datediff(s,(  
  select max(dt2.endtime) from dbo.#downtime dt2 with (nolock) where ((dt2.starttime<=#downtime.starttime) and ( dt2.tedet_id <> #downtime.tedet_id)) and dt2.puid=#downtime.puid  
  ),starttime)/60.0  
  
 update #downtime set uptime=datediff(s,@inputstarttime,starttime)/60.0 where uptime is null  
  
End  
  
  
--- Do some formating of the Downtimes but only when going for the Raw Data--  
  
If  @InputOutPutType = 'Raw Data'  
  
Begin  
  
/*  
 update #downtime set StartD = right('0' + convert(varchar,datepart(mm,starttime)),2) + '/' +  
   right('0' + convert(varchar,datepart(dd,starttime)),2) + '/' +  
   convert(varchar,datepart(yyyy,starttime))  --Replaced with below  
*/  
  
 update #downtime set StartD = convert(datetime,left(starttime,11),120)--changed BAS 2/16/05  
  
  
 update #downtime set StartT = right('0' + convert(varchar,datepart(hh,starttime)),2) + ':' +  
   right('0' + convert(varchar,datepart(mi,starttime)),2) + ':' +  
   right('0' +convert(varchar,datepart(ss,starttime)),2)  
  
/*  
 update #downtime set EndD = right('0' + convert(varchar,datepart(mm,endtime)),2) + '/' +  
   right('0' + convert(varchar,datepart(dd,endtime)),2) + '/' +  
   convert(varchar,datepart(yyyy,endtime))  
                                 where endtime is not NULL  --Replaced with  below  
*/  
 update #downtime set EndD = convert(datetime,left(endtime,11),120) where endtime is not NULL--Changed BAS 2/16/05  
  
  
 update #downtime set EndT = right('0' + convert(varchar,datepart(hh,endtime)),2) + ':' +  
   right('0' + convert(varchar,datepart(mi,endtime)),2) + ':' +  
   right('0' +convert(varchar,datepart(ss,endtime)),2)  
                                 where endtime is not NULL  
end  
  
  
----------get Valid Crew Schedule for the time Period in Question -------------  
  
create table #schedule_puid (pu_id int, schedule_puid int, tmp1 int,tmp2 int,info varchar(300))  
  
--- start of my Add for Team shift optional calc  
If  (@InputOutPutType = 'Raw Data'  and (@InputCalcShiftTeam = 1) )  
or  (  (@InputOutPutType =  'Pareto')  and (( @InputGroupBy = 'Team') or (@InputGroupBy = 'Shift')) )  
or  (  (@InputOutPutType =  'Pareto') and (@InputCalcShiftTeam = 1) )  
  
 BEGIN  
----   
  
  insert into #schedule_puid (pu_id,info) select pu_id,extended_info from dbo.prod_units with (nolock)   
  where (charindex(','+pu_desc+',',','+@inputmasterprodunits+',')>0 or @inputmasterprodunits='All')  
   
  update #schedule_puid set tmp1=charindex('scheduleunit=',info)  
    
  update #schedule_puid set tmp2=charindex(';',info,tmp1) where tmp1>0  
   
  update #schedule_puid set schedule_puid=cast(substring(info,tmp1+13,tmp2-tmp1-13) as int) where tmp1>0 and tmp2>0 and not tmp2 is null  
   
  update #schedule_puid set schedule_puid=cast(substring(info,tmp1+13,len(info)-tmp1-12) as int)where tmp1>0 and tmp2=0  
   
  update #schedule_puid set schedule_puid=pu_id where schedule_puid is null  
   
   
  --Update # downtime set Sched_PUID = (select sp.schedule_puid from #schedule_puid sp where sp.pu_id = #downtime.puid)  
    
    
  ----------set Team -------------  
    
  update #downtime set team=( select  crew_desc from dbo.crew_schedule cs with (nolock) join dbo.#schedule_puid sp with (nolock) on cs.pu_id=sp.schedule_puid  
   where #downtime.starttime>=cs.start_time and cs.end_time>#downtime.starttime and #downtime.puid=sp.pu_id)  
    
  ----------set Shift -------------  
  update #downtime set shift=( select  shift_desc from dbo.crew_schedule cs with (nolock) join dbo.#schedule_puid sp with (nolock) on cs.pu_id=sp.schedule_puid  
   where #downtime.starttime>=cs.start_time and cs.end_time>#downtime.starttime and #downtime.puid=sp.pu_id)  
  
 end   
  
if  @InputOutPutType = 'Raw Data'   
begin  
 ----------set Line Status-------------  
  
-- update #downtime set linestatus = (select Top 1 phr.phrase_value  
-- from local_pg_line_status lls  
-- join phrase phr on lls.line_status_id = phr.phrase_id  
-- where lls.unit_id = #downtime.Prodpuid  
-- and #downtime.starttime >= lls.start_datetime  
-- order by lls.start_datetime ASC)  
 update d  
   set linestatus = phr.phrase_value  
  from dbo.#downtime d with (nolock)  
   join dbo.local_pg_line_status lls with (nolock) on lls.unit_id = d.prodpuid --d.LineStatusPUID  
   join dbo.phrase phr with(nolock) on  phr.phrase_id = lls.line_status_id  
 where d.starttime >= lls.start_datetime   
 and (d.endtime <= lls.end_datetime or lls.end_datetime is null or d.endtime is null)  
  
end  
  
  
----------set Product -------------  
update #DownTime set product=(  
 select p.Prod_Desc from dbo.products p with (nolock) join dbo.production_starts ps with (nolock) on ps.prod_id= p.prod_id   
 join dbo.prod_units with (nolock) on ps.pu_id=prod_units.pu_id where ps.start_time <= #downtime.starttime  
 and ((#downtime.starttime < ps.end_time) or (ps.end_time is null)) and ps.pu_id=#downtime.puid)  
  
  
update #DownTime set brand=(  
 select p.prod_code from dbo.products p with (nolock) join dbo.production_starts ps with (nolock) on ps.prod_id= p.prod_id   
 join dbo.prod_units with (nolock) on ps.pu_id=prod_units.pu_id where ps.start_time <= #downtime.starttime  
 and ((#downtime.starttime < ps.end_time) or (ps.end_time is null)) and ps.pu_id=#downtime.puid)  
  
  
/*  
--Apply Family Care reason categories if they exist  
IF (SELECT count(erc_id) FROM event_reason_catagories   
WHERE charindex('category:', erc_desc) > 0  
OR charindex('Schedule:', erc_desc) > 0  
OR charindex('Subsystem:', erc_desc) > 0  
OR charindex('GroupCause:', erc_desc) > 0) > 5  
BEGIN  
  
----------SET Category -------------  
  
 SELECT @CatPrefix='category:'  
 UPDATE #downtime SET Cat1=(  
                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
                          event_reason_catagories erc  
                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
                           )  
----------SET Schedule -------------  
  
    SELECT @CatPrefix='Schedule:'  
 UPDATE #downtime SET Cat2=(  
                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
                          event_reason_catagories erc  
                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
                           )  
   
----------SET Subsystem -------------  
 SELECT @CatPrefix='Subsystem:'  
 UPDATE #downtime SET Cat3=(  
                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
                          event_reason_catagories erc  
                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
                           )  
  
----------SET GroupCause -------------  
 SELECT @CatPrefix='GroupCause:'  
 UPDATE #downtime SET Cat4=(  
                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
                          event_reason_catagories erc  
                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
                           )  
END  
*/  
  
  
SELECT @CatPrefix='category:'  
UPDATE td SET  
 Cat1 = right(erc_desc,len(erc_desc)-len(@CatPrefix))  
FROM dbo.#downtime td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
  
SELECT @CatPrefix='Schedule:'  
UPDATE td SET  
 Cat2 = right(erc_desc,len(erc_desc)-len(@CatPrefix))  
FROM dbo.#downtime td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
/*  
UPDATE td SET   
 ScheduleId = @SchedBlockedStarvedId  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Event_Reasons er with (nolock)  
on Event_Reason_ID = L1ReasonId   
WHERE ScheduleId IS NULL   
AND (Event_Reason_Name LIKE '%BLOCK%' OR Event_Reason_Name LIKE '%STARVE%')  
*/  
  
  
SELECT @CatPrefix='Subsystem:'  
UPDATE td SET  
 Cat3 = right(erc_desc,len(erc_desc)-len(@CatPrefix))  
FROM dbo.#downtime td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
  
SELECT @CatPrefix='GroupCause:'  
UPDATE td SET  
 Cat4 = right(erc_desc,len(erc_desc)-len(@CatPrefix))  
FROM dbo.#downtime td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
  
------------------------------------------------------------------  
  
  
Update #downtime set FailureType = 'Minor Stop' where Downtime  < 10   
     and (Cat1 <> 'Blocked/Starved' or Cat1 IS NULL)  
               and (Cat2  = 'Unscheduled' or Cat2 is NULL)  
           and SBP is NULL  
  
  
Update #downtime Set FailureType = 'Break Down' Where  Downtime  >= 10   
               and ((Cat1 = 'Mechanical Equipment') or (Cat1 = 'Electrical Equipment'))   
     and (Cat2  = 'Unscheduled' or Cat2 is NULL)  
               and SBP is NULL  
  
Update #downtime Set FailureType = 'Process Failure' Where  Downtime  >= 10   
               and FailureType is NULL  
     and (Cat1 <> 'Blocked/Starved' )  
               and (Cat2  = 'Unscheduled' or Cat2 is NULL)  
               and SBP is Null  
  
-----------------------------------------------------------------------------------  
-- Get PRID data.  
-- Get PRID through genealogy using the events tables and the Production unit  
-- in converting (xxxx Converter Production).  This is seen above in code where   
-- #downtime table is initially populated and the ProdPUID is retrieved.  
-- Input_Order is defined in the configuration.  This code works for 1 or 2 backstands.  
-----------------------------------------------------------------------------------  
If ( (@InputCalcFreshStorage = 1) and (@InputOutPutType = 'Raw Data') )   
 or (  ((@InputOutPutType =  'Pareto') or (@InputOutPutType =  'Interval Chart'))  and ((@InputPmkgMachines <>  'All') or (@InputFreshStorage <> 'All')) )  
or  (  (@InputOutPutType =  'Pareto')  and (( @InputGroupBy = 'PMKGMach') or (@InputGroupBy = 'FreshStorage')) )  
  
BEGIN  
  
 SELECT @DetermineFresh = 1  
  
  
END  
  
  
If @DetermineFresh = 1   
begin  
  
 declare  
 @PackOrLineStr    varchar(50),  
 @VarStartTimeVN   varchar(50),  
 @VarEndTimeVN    varchar(50),  
 @VarParentPRIDVN   varchar(50),  
 @VarUnwindStandVN   varchar(50),  
 @StagedStatusId   int,  
 @RangeStartTime   datetime,  
 @RangeEndTime    datetime  
  
 select  
 @PackOrLineStr    = 'PackOrLine=',  
 @VarStartTimeVN   = 'Roll Conversion Start Date/Time',  
 @VarEndTimeVN    = 'Roll Conversion End Date/Time',  
 @VarParentPRIDVN   = 'Parent PRID',  
 @VarUnwindStandVN   = 'Unwind Stand'  
  
  
-- Get the minimum - maximum range for later queries  
SELECT   
 @RangeStartTime = MIN(StartTime),  
 @RangeEndTime = MAX(EndTime)  
FROM dbo.#Downtime with (nolock)  
option (keep plan)  
  
  
 DECLARE @ProdLines TABLE   
  (  
  PLId             int primary key,  
  PLDesc            VARCHAR(50),  
  ProdPUID            integer,  
  PackOrLine           varchar(5),  
  VarStartTimeId          INTEGER,   
  VarEndTimeId          INTEGER,   
  VarParentPRIDId         INTEGER,  
  VarUnwindStandId         INTEGER,   
  Extended_Info          varchar(225)--,  
  )   
  
  
 DECLARE @UWS TABLE   
  (   
  InputName           VARCHAR(50),  
  InputOrder           INTEGER,  
  PLId             INTEGER,  
  UWSPUId            INTEGER primary key   
  )  
  
  
 DECLARE @PRsRun TABLE   
  (  
  EventId            INTEGER,  
  PUId             INTEGER,  
  StartTime           DATETIME,  
  EndTime            DATETIME,  
  ParentPRID           VARCHAR(50),   
  UWS             VARCHAR(25),  
  InputOrder           int  
  primary key (puid, starttime, eventid)  
   )  
  
/*  
 create table dbo.#Tests   
  (  
  VarId             INTEGER,  
  Value             varchar(25),  
  StartTime           DATETIME--,  
  primary key (varid, starttime)  
  )  
*/  
  
-- pull in prod lines that have an ID in the list  
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fnLocal_GlblParseInfo]'))  
BEGIN  
  
 insert @ProdLines   
  (  
  PLID,   
  PLDesc,  
  Extended_Info,  
  PackOrLine  
  )  
 select distinct  
  pl.PL_ID,   
  PL_Desc,  
  pl.Extended_Info,  
  GBDB.dbo.fnLocal_GlblParseInfo(pl.Extended_Info, @PackOrLineStr)  
 from dbo.prod_lines pl with (nolock)  
 join dbo.prod_units pu with (nolock)  
 on pl.pl_id = pu.pl_id  
 where charindex(',' + convert(varchar,pu.pu_desc) + ',',',' + @InputMasterProdUnits + ',') > 0  
 option (keep plan)  
END  
  
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
join dbo.Prod_Units pu  
on pl.plid = pu.pl_id  
where pu_desc like '%Converter Production%'  
  
  
-- get the following variable IDs associated with the line  
update pl set  
 VarStartTimeId  = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId, @VarStartTimeVN),  
 VarEndTimeId   = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId, @VarEndTimeVN),  
 VarParentPRIDId  = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId, @VarParentPRIDVN),  
 VarUnwindStandId  = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId, @VarUnwindStandVN)  
from @ProdLines pl  
where PackOrLine = 'Line'  
  
-- get the UWS info  
INSERT INTO @UWS   
 (   
 InputName,  
 InputOrder,  
 PLId,  
 UWSPUId   
 )  
SELECT   
 pei.Input_Name,  
 pei.Input_Order,  
 pl.PLId,  
 pu.PU_Id  
FROM dbo.PrdExec_Inputs pei with (nolock)  
JOIN @ProdLines pl ON pl.ProdPUId = pei.PU_Id  
AND PackOrLine = 'LINE'  
LEFT JOIN dbo.Prod_Units pu ON pu.PL_Id = pl.PLId  
--JOIN dbo.Prod_Units pu ON pu.PL_Id = pl.PLId  
AND charindex('UWSORDER='+CONVERT(VARCHAR(5), pei.Input_Order), upper(REPLACE(pu.Extended_Info, ' ', ''))) > 0  
option (keep plan)  
  
 INSERT dbo.#Tests   
  (   
  VarId,  
  Value,  
  StartTime  
  )  
 SELECT   
  t.Var_Id,  
  t.Result,     
  t.Result_On  
 FROM  @ProdLines pl  
 join dbo.tests t with (nolock)  
 on t.var_id in   
  (  
  -- for @PRsRun  
  pl.VarStartTimeId,  
  pl.VarEndTimeId,  
  pl.VarParentPRIDId,  
  pl.VarUnwindStandId--,  
  )  
 and result_on <= @InputEndTime  
 AND result_on >= dateadd(d, -1, @InputStartTime)  
 and result is not null  
 option (keep plan)  
  
  
 SELECT @StagedStatusId = ProdStatus_Id  
 FROM dbo.Production_Status with (nolock)  
 WHERE ProdStatus_Desc = 'Staged'  
 option (keep plan)  
  
 INSERT INTO @PRsRun   
  (   
  EventId,  
  PUId,  
  StartTime,  
  EndTime,  
  ParentPRID,  
  UWS,  
  InputOrder  
  )  
 SELECT   
  e.Event_Id,  
  e.pu_id,  
  CASE   
  WHEN CONVERT(DATETIME, st.value) < @InputStartTime   
  THEN @InputStartTime   
  ELSE CONVERT(DATETIME, st.value)  
  END,  
  CASE   
  WHEN CONVERT(DATETIME, et.value) > @InputEndTime   
  THEN @InputEndTime   
  ELSE CONVERT(DATETIME, et.value)  
  END,  
  UPPER(RTRIM(LTRIM(pt.value))),  
  ut.value,   
  uws.InputOrder  
 FROM dbo.Events e with (nolock)  
 JOIN @ProdLines pl   
 ON e.PU_Id = pl.ProdPUId  
 AND pl.ProdPUId > 0   
 AND PackOrLine = 'LINE'  
 JOIN dbo.#Tests st with (nolock)   
 on st.VarId = pl.VarStartTimeId  
 and st.starttime = e.TimeStamp  
 AND st.value is not null   
 JOIN dbo.#Tests et with (nolock)   
 on et.VarId = pl.VarEndTimeId  
 and et.starttime = e.TimeStamp  
 AND et.value is not null  
 LEFT JOIN dbo.#Tests pt with (nolock)   
 on pt.varid = pl.VarParentPRIDId  
 and pt.starttime = e.TimeStamp  
 LEFT JOIN dbo.#Tests ut with (nolock)   
 on ut.VarId = pl.VarUnwindStandId  
 and ut.starttime = e.TimeStamp  
 LEFT JOIN @UWS uws   
 ON uws.PLId = pl.PLId  
 AND uws.InputName = ut.value  
 WHERE e.TimeStamp < @InputEndTime  
 AND e.TimeStamp > dateadd(d, -1, @InputStartTime)  
 AND e.Event_Status <> @StagedStatusId  
 option (keep plan)  
  
 -- I would like to get rid of this delete statement and convert it into a restriction   
 -- in the initial insert.  however, doing so *sometimes* causes an error (of the converting   
 -- varchar to datetime type) that I haven't been able to eliminate.  
 delete from @PRsRun  
 where starttime >= @RangeEndTime  
 or endtime <= @RangeStartTime  
  
--select * from @prodlines  
--select * from @uws  
--select * from @tests  
--select * from @prsrun  
  
  
--UPDATE td SET  UWS1_PRID = (SELECT TOP 1  UPPER(RTRIM(LTRIM(eds.Alternate_Event_Num)))  
--     FROM events e   
--      INNER JOIN event_components ec ON e.event_id = ec.event_id  
--      INNER JOIN events ed ON ec.source_event_id = ed.event_id  
--      INNER JOIN PrdExec_Input_Event_History peih ON ec.source_event_id = peih.event_id  
--            AND peih.PEIP_Id = 1  
--      INNER JOIN production_status ps ON e.event_status = ps.prodstatus_id  
--      INNER JOIN event_details eds ON ec.source_event_id = eds.event_id  
--      INNER JOIN PrdExec_Inputs pei ON peih.PEI_Id = pei.PEI_Id  
--           AND pei.Input_Order = 1  
--     WHERE e.timestamp < td.endtime  
--      AND e.timestamp > DATEADD(hour, @MaxUWSHistoryHrs, td.endtime)  
--      AND e.PU_Id = td.ProdPUID  
--      AND ps.prodstatus_desc <> 'Staged'  
--     ORDER BY e.timestamp desc)  
  
 UPDATE td SET   
  [UWS1_PRID] = prs.ParentPRID,  
  [UWS1_Pkmg_Machine] = left(prs.ParentPRID,2)  
 FROM dbo.#Downtime td with (nolock)  
 JOIN @PRsRun prs   
 ON prs.PUId = td.ProdPUId  
 AND prs.StartTime < td.StartTime  
 AND prs.EndTime > td.StartTime  
 AND prs.InputOrder = 1  
  
  
 update td set  
   UWS1_Fresh_Storage = (SELECT TOP 1 CASE WHEN (DATEDIFF(ss, ed.timestamp, e.timestamp) / 3600.0) < 1.0 THEN  
       'Fresh'  
      ELSE  
       'Storage'  
      END  
     FROM dbo.events e with (nolock)   
      INNER JOIN dbo.event_components ec with (nolock) ON e.event_id = ec.event_id  
      INNER JOIN dbo.events ed with (nolock) ON ec.source_event_id = ed.event_id  
      INNER JOIN dbo.PrdExec_Input_Event_History peih  with (nolock)ON ec.source_event_id = peih.event_id  
            AND peih.PEIP_Id = 1  
      INNER JOIN dbo.production_status ps  with (nolock)ON e.event_status = ps.prodstatus_id  
      INNER JOIN dbo.event_details eds with (nolock) ON ec.source_event_id = eds.event_id  
      INNER JOIN dbo.PrdExec_Inputs pei with (nolock) ON peih.PEI_Id = pei.PEI_Id  
           AND pei.Input_Order = 1  
     WHERE e.timestamp < td.endtime  
      AND e.timestamp > DATEADD(hour, @MaxUWSHistoryHrs, td.endtime)  
      AND e.PU_Id = td.ProdPUID  
      AND ps.prodstatus_desc <> 'Staged'  
     ORDER BY e.timestamp desc)  
 from dbo.#downtime td with (nolock)  
  
-- update td set  
--   UWS1_Pkmg_Machine = (SELECT TOP 1 UPPER(RTRIM(LTRIM(LEFT(eds.Alternate_Event_Num, 2))))  
--     FROM events e   
--      INNER JOIN event_components ec ON e.event_id = ec.event_id  
--      INNER JOIN events ed ON ec.source_event_id = ed.event_id  
--      INNER JOIN PrdExec_Input_Event_History peih ON ec.source_event_id = peih.event_id  
--            AND peih.PEIP_Id = 1  
--      INNER JOIN production_status ps ON e.event_status = ps.prodstatus_id  
--      INNER JOIN event_details eds ON ec.source_event_id = eds.event_id  
--      INNER JOIN PrdExec_Inputs pei ON peih.PEI_Id = pei.PEI_Id  
--           AND pei.Input_Order = 1  
--     WHERE e.timestamp < td.endtime  
--      AND e.timestamp > DATEADD(hour, @MaxUWSHistoryHrs, td.endtime)  
--      AND e.PU_Id = td.ProdPUID  
--      AND ps.prodstatus_desc <> 'Staged'  
--     ORDER BY e.timestamp desc)  
-- from #delays td  
  
--   UWS2_PRID = (SELECT TOP 1 UPPER(RTRIM(LTRIM(eds.Alternate_Event_Num)))  
--     FROM events e   
--      INNER JOIN event_components ec ON e.event_id = ec.event_id  
--      INNER JOIN events ed ON ec.source_event_id = ed.event_id  
--      INNER JOIN PrdExec_Input_Event_History peih ON ec.source_event_id = peih.event_id  
--            AND peih.PEIP_Id = 1  
--      INNER JOIN production_status ps ON e.event_status = ps.prodstatus_id  
--      INNER JOIN event_details eds ON ec.source_event_id = eds.event_id  
--      INNER JOIN PrdExec_Inputs pei ON peih.PEI_Id = pei.PEI_Id  
--           AND pei.Input_Order = 2  
--     WHERE e.timestamp < td.endtime  
--      AND e.timestamp > DATEADD(hour, @MaxUWSHistoryHrs, td.endtime)  
--      AND e.PU_Id = td.ProdPUID  
--      AND ps.prodstatus_desc <> 'Staged'  
--     ORDER BY e.timestamp desc),  
  
 UPDATE td SET   
  [UWS2_PRID] = prs.ParentPRID,  
  [UWS2_Pkmg_Machine] = left(prs.ParentPRID,2)  
 FROM dbo.#Downtime td with (nolock)  
 JOIN @PRsRun prs   
 ON prs.PUId = td.ProdPUId  
 AND prs.StartTime < td.StartTime  
 AND prs.EndTime > td.StartTime  
 AND prs.InputOrder = 2  
  
 update td set  
   UWS2_Fresh_Storage = (SELECT TOP 1 CASE WHEN (DATEDIFF(ss, ed.timestamp, e.timestamp) / 3600.0) < 1.0 THEN  
       'Fresh'  
      ELSE  
       'Storage'  
      END  
     FROM dbo.events e with (nolock)   
      INNER JOIN dbo.event_components ec with (nolock) ON e.event_id = ec.event_id  
      INNER JOIN dbo.events ed with (nolock) ON ec.source_event_id = ed.event_id  
      INNER JOIN dbo.PrdExec_Input_Event_History peih with (nolock) ON ec.source_event_id = peih.event_id  
            AND peih.PEIP_Id = 1  
      INNER JOIN dbo.production_status ps with (nolock) ON e.event_status = ps.prodstatus_id  
      INNER JOIN dbo.event_details eds with (nolock) ON ec.source_event_id = eds.event_id  
      INNER JOIN dbo.PrdExec_Inputs pei with (nolock) ON peih.PEI_Id = pei.PEI_Id  
           AND pei.Input_Order = 2  
     WHERE e.timestamp < td.endtime  
      AND e.timestamp > DATEADD(hour, @MaxUWSHistoryHrs, td.endtime)  
      AND e.PU_Id = td.ProdPUID  
      AND ps.prodstatus_desc <> 'Staged'  
     ORDER BY e.timestamp desc)  
 from dbo.#downtime td with (nolock)  
  
-- update td set  
--   UWS2_Pkmg_Machine = (SELECT TOP 1 UPPER(RTRIM(LTRIM(LEFT(eds.Alternate_Event_Num, 2))))  
--     FROM events e   
--      INNER JOIN event_components ec ON e.event_id = ec.event_id  
--      INNER JOIN events ed ON ec.source_event_id = ed.event_id  
--      INNER JOIN PrdExec_Input_Event_History peih ON ec.source_event_id = peih.event_id  
--            AND peih.PEIP_Id = 1  
--      INNER JOIN production_status ps ON e.event_status = ps.prodstatus_id  
--      INNER JOIN event_details eds ON ec.source_event_id = eds.event_id  
--      INNER JOIN PrdExec_Inputs pei ON peih.PEI_Id = pei.PEI_Id  
--           AND pei.Input_Order = 2  
--     WHERE e.timestamp < td.endtime  
--      AND e.timestamp > DATEADD(hour, @MaxUWSHistoryHrs, td.endtime)  
--      AND e.PU_Id = td.ProdPUID  
--      AND ps.prodstatus_desc <> 'Staged'  
--     ORDER BY e.timestamp desc)  
-- FROM #downtime td  
  
  
  
end  
----------------------------------- 1/3/05 -----------------  
  
 /* Add UNCODED to all Blank FMCs */  
 update #downtime set  reason2 = '**UNCODED**: ' where  
 reason2 is null   
    
 /* Append RATE LOSS to FMC for Rate Loss MUs only */  
 update #downtime set  reason2 = '**UNCODED**: RATE LOSS' where  
 reason2 = '**UNCODED**: '  
 and MasterProdUnit like '%Rate Loss'  
  
 /* Append  'UNCODED:RATE LOSS'  to FM for Rate Loss MUs only */  
 update #downtime set  reason1 = '**UNCODED**: RATE LOSS' where  
 reason1 is null  
 and MasterProdUnit like '%Rate Loss'   
  
 /* Append FM to FMC when FMC is 'unknown', 'other', 'troubleshooting'  */  
 update #downtime set  reason2 = ltrim(reason1) + ' - ' + ltrim(reason2) where  
 reason2 in ('unknown', 'other', 'troubleshooting') and not reason1 is null  
  
 /* Append UNCODED  to FMC when FMC is blank */  
 update #downtime set  reason2 = '**UNCODED**: ' + ltrim(reason1) where  
 reason2 = '**UNCODED**: ' and not reason1 is null  
  
 /*  
 update #downtime set  reason2 = ltrim(ISNULL(FAULT,' ')) + ' - ' + ltrim(reason2) where  
 reason2 in ('unknown', 'other', 'troubleshooting') and reason1 is null  
 */  
 /* Add UNCODED plus the Fault to the FMC */  
 update #downtime set  reason2 =  ltrim(reason2) + ltrim(ISNULL(FAULT,' ')) where  
 reason2 = '**UNCODED**: ' and reason1 is null  
  
 /* Add UNCODED plus the Fault to the FM */  
 --update #downtime set reason1 = ltrim(isnull(fault,' ')) + ' - **UNCODED**'  
 update #downtime set reason1 =  '**UNCODED**: '+  ltrim(isnull(fault,' ')) --1/3/05 BAS Changed to put UNCODED first in the concatenation.  
 where reason1 is null  
  
--Calculate Effective Downtime and add to the Downtime colum  
update #downtime set downtime = (targetspeed - actualspeed) * downtime / targetspeed,  
 /*  Remove Failure Type from Rate loss events */  
 Failuretype = null  
 where targetspeed is not null   
  
  
---- End of PRID data gathering.   
  
IF @InputDurationOper <>  '<' and @InputDurationOper <> '>'  
  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
 VALUES ('Duration Oper Not Valid=' +  @InputDurationOper )  
 GOTO ErrorMessagesWrite  
END  
  
IF @InputDurationLimit =  ''   
  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
 VALUES ('Duration Limit Not Valid=' +  @InputDurationLimit )  
 GOTO ErrorMessagesWrite  
END  
  
  
--select starttime, endtime, uws1_prid, uws2_prid    
--from #downtime  
--order by starttime, uws1_prid  
  
  
If @InputDurationOper = '<'  
  
Begin  
  
 insert into #DownTimeFinal  
 select *  
 FROM dbo.#DownTime as DT with (nolock)  
 WHERE  ((CHARINDEX( ','+DT.Shift+','  ,  ','+ @InputShifts+','  )) > 0 or (@InputShifts = 'All'))  
 and ((CHARINDEX( ','+DT.Team+','  ,  ','+ @InputTeams+','  )) > 0 or (@InputTeams = 'All'))  
 and ((CHARINDEX( ','+DT.Cat1+','  ,  ','+ @InputCat1s+','  )) > 0 or (@InputCat1s = 'All'))  
 and ((CHARINDEX( ','+DT.Cat2+','  ,  ','+ @InputCat2s+','  )) > 0 or (@InputCat2s = 'All'))  
 and ((CHARINDEX( ','+DT.Cat3+','  ,  ','+ @InputCat3s+','  )) > 0 or (@InputCat3s = 'All'))  
 and ((CHARINDEX( ','+DT.Cat4+','  ,  ','+ @InputCat4s+','  )) > 0 or (@InputCat4s = 'All'))  
 and ((CHARINDEX( ','+DT.Product+','  ,  ','+ @InputProducts +','  )) > 0 or (@InputProducts = 'All'))  
 and ((CHARINDEX( ','+DT.FailureType+','  ,  ','+ @InputFailureTypes+','  )) > 0 or (@InputFailureTypes = 'All'))  
 and (((CHARINDEX( ','+DT.UWS1_Pkmg_Machine+','  ,  ','+ @InputPmkgMachines+','  )) > 0 or (@InputPmkgMachines = 'All'))   
                OR  ((CHARINDEX( ','+DT.UWS2_Pkmg_Machine+','  ,  ','+ @InputPmkgMachines+','  )) > 0 or (@InputPmkgMachines = 'All')))  
 and ( ((CHARINDEX( ','+DT.UWS1_Fresh_Storage+','  ,  ','+ @InputFreshStorage+','  )) > 0 or (@InputFreshStorage = 'All'))  
                OR  ((CHARINDEX( ','+DT.UWS1_Fresh_Storage+','  ,  ','+ @InputFreshStorage+','  )) > 0 or (@InputFreshStorage = 'All')))  
  
 and downtime <  @InputDurationLimit  
end  
  
  
If @InputDurationOper = '>'  
  
Begin  
  
 insert into #DownTimeFinal  
 select *  
 FROM dbo.#DownTime as DT with (nolock)  
 WHERE  ((CHARINDEX( ','+DT.Shift+','  ,  ','+ @InputShifts+','  )) > 0 or (@InputShifts = 'All'))  
 and ((CHARINDEX( ','+DT.Team+','  ,  ','+ @InputTeams+','  )) > 0 or (@InputTeams = 'All'))  
 and ((CHARINDEX( ','+DT.Cat1+','  ,  ','+ @InputCat1s+','  )) > 0 or (@InputCat1s = 'All'))  
 and ((CHARINDEX( ','+DT.Cat2+','  ,  ','+ @InputCat2s+','  )) > 0 or (@InputCat2s = 'All'))  
 and ((CHARINDEX( ','+DT.Cat3+','  ,  ','+ @InputCat3s+','  )) > 0 or (@InputCat3s = 'All'))  
 and ((CHARINDEX( ','+DT.Cat4+','  ,  ','+ @InputCat4s+','  )) > 0 or (@InputCat4s = 'All'))  
 and ((CHARINDEX( ','+DT.Product+','  ,  ','+ @InputProducts +','  )) > 0 or (@InputProducts = 'All'))  
 and ((CHARINDEX( ','+DT.FailureType+','  ,  ','+ @InputFailureTypes+','  )) > 0 or (@InputFailureTypes = 'All'))  
 and (((CHARINDEX( ','+DT.UWS1_Pkmg_Machine+','  ,  ','+ @InputPmkgMachines+','  )) > 0 or (@InputPmkgMachines = 'All'))   
                OR  ((CHARINDEX( ','+DT.UWS2_Pkmg_Machine+','  ,  ','+ @InputPmkgMachines+','  )) > 0 or (@InputPmkgMachines = 'All')))  
 and (((CHARINDEX( ','+DT.UWS1_Fresh_Storage+','  ,  ','+ @InputFreshStorage+','  )) > 0 or (@InputFreshStorage = 'All'))  
                OR  ((CHARINDEX( ','+DT.UWS1_Fresh_Storage+','  ,  ','+ @InputFreshStorage+','  )) > 0 or (@InputFreshStorage = 'All')))  
 and downtime >  @InputDurationLimit  
end  
  
  
IF @InputOutPutType <>  'Pareto' and @InputOutPutType <> 'Raw Data' and @InputOutPutType <> 'Interval Chart'  
  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
 VALUES ('OutPut Type Not Valid=' + @InputOutPutType )  
 GOTO ErrorMessagesWrite  
END  
  
  
IF @InputOutPutType =  'Pareto'  
  
BEGIN  
  
  
  
 --SELECT StartTime,EndTime, Uptime, Downtime, MasterProdUnit, Location,Fault,Reason1,Reason2,Reason3,Reason4,Team,Shift,Cat1,Cat2,Cat3,Cat4,Product,Comments,StartTime_Act,EndTime_aCT, Endtime_PrevP, SourcePUID,tedet_id, ReasonID1,ReasonID2,ReasonID3, ReasonID4, ErtdID1, ErtdID2, ErtdID3, ErtdID4,SBp,EAP FROM #DOWNTIMEFinal ORDER BY sTARTTIME       
   
   
 --select * from #downtimeFinal  order by starttime   
   
 -- create the summary table  
   
 SELECT @InputGroupByClause =  
       CASE   
          WHEN @InputGroupBy = 'ProdUnit'  THEN 'MasterProdUnit'  
          WHEN @InputGroupBy = 'Location'  THEN 'Location'  
          WHEN @InputGroupBy = 'Fault'  THEN 'Fault'  
          WHEN @InputGroupBy = 'Reason1'  THEN 'Reason1'  
          WHEN @InputGroupBy = 'Reason2'  THEN 'Reason2'  
          WHEN @InputGroupBy = 'Reason3'  THEN 'Reason3'  
          WHEN @InputGroupBy = 'Reason4'  THEN 'Reason4'  
          WHEN @InputGroupBy = 'Team'  THEN 'Team'  
          WHEN @InputGroupBy = 'Shift'  THEN 'Shift'  
          WHEN @InputGroupBy = 'Cat1' THEN 'Cat1'  
          WHEN @InputGroupBy = 'Cat2' THEN 'Cat2'  
          WHEN @InputGroupBy = 'Cat3' THEN 'Cat3'  
          WHEN @InputGroupBy = 'Cat4' THEN 'Cat4'  
          WHEN @InputGroupBy = 'FailureType' THEN 'FailureType'  
          WHEN @InputGroupBy = 'Product' THEN 'Product'  
                         WHEN @InputGroupBy = 'PMKGMach' THEN 'UWS1_Pkmg_Machine'  
          WHEN @InputGroupBy = 'FreshStorage' THEN 'UWS1_Fresh_Storage'  
   ELSE '???????????'  
  END  
   
 IF @InputGroupByClause = '???????????'   
   
 BEGIN  
  
  INSERT #ErrorMessages (ErrMsg)  
  VALUES ('GroupBy Not Valid=' + @InputGroupBy )   
  GOTO ErrorMessagesWrite  
 END  
   
    
   SELECT @strSQL = 'Insert into #DTSummary (groupName,Downtime,Stops)(Select '   
   SELECT @strSQL = @strSQL + @InputGroupByClause  
   SELECT @strSQL = @strSQL + ', Sum(Downtime) as [Downtime], Count(StartTime) as [Stops] from dbo.#DowntimeFinal with (nolock) group by '  
   SELECT @strSQL = @strSQL + @InputGroupByClause  
   SELECT @strSQL = @strSQL + ')'  
   Print @strSQL  
   exec (@strSQL)  
   
 IF @InputOrderBy = 'Stops'  
   
 BEGIN  
   select * from dbo.#DTSummary with (nolock) order by Stops DESC  
 End  
   
 IF @InputOrderBy = 'Downtime' or @InputOrderBy is NULL  
   
 BEGIN  
   select * from dbo.#DTSummary with (nolock) order by Downtime DESC  
 End  
   
 IF @InputOrderBy <> 'Stops' and @InputOrderBy <> 'Downtime'  
   
 BEGIN  
   INSERT #ErrorMessages (ErrMsg)  
  VALUES ('OrderBy Not Valid=' + @InputGroupBy )  
  GOTO ErrorMessagesWrite  
 End  
  
END  
  
  
IF @InputOutPutType = 'Raw Data'  
  
BEGIN  
  
  
--SELECT StartTime,EndTime, Uptime, Downtime, MasterProdUnit, Location,Fault,Reason1,Reason2,Reason3,Reason4,Team,Shift,Cat1,Cat2,Cat3,Cat4,Product,Comments,StartTime_Act,EndTime_act, Endtime_Prev, SourcePUID,tedet_id, ReasonID1,ReasonID2,ReasonID3, ReasonID4, ErtdID1, ErtdID2, ErtdID3, ErtdID4,SBp,EAP FROM #DOWNTIMEFINAL  ORDER BY sTARTTIME       
  
--Modified for rate loss events (Added Clock Duration, Target Speed, Actual Speed)  
SELECT StartTime, StartD,StartT, EndTime,EndD, EndT, ClockDuration, Downtime,Uptime, ActualSpeed, TargetSpeed, MasterProdUnit, FailureType, Location,Fault,Reason1,Reason2,Reason3,Reason4,Team,Shift,Cat1,Cat2,Cat3,Cat4,Product,Comments, LineStatus, UWS1_Prid, UWS1_Fresh_Storage,  UWS1_Pkmg_Machine, UWS2_Prid, UWS2_Fresh_Storage, UWS2_Pkmg_Machine,StartTime_Act,EndTime_act, PUID, SourcePUID,tedet_id,SBp,EAP FROM dbo.#DOWNTIMEFINAL with (nolock) ORDER BY StartTime       
  
end  
  
  
IF @InputOutPutType =  'Interval Chart'  
  
BEGIN  
  
Select @tmpLoopCounter = 0  
  
  
select @current=@InputStartTime  
  
while @current<@InputEndTime   
begin  
  
   
 Select @tmpLoopCounter = @tmpLoopCounter + 1  
  
 IF @tmpLoopCounter > 32000  
   
 BEGIN  
   INSERT #ErrorMessages (ErrMsg)  
  VALUES ('Premature Exit of loop='  )  
  GOTO ErrorMessagesWrite  
 End  
  
  
 insert into #DTInterval (starttime) values (@current)  
 Print @current  
  
 select @current=DateAdd(mi, @InputInterval, @current)  
end  
  
  
update #DTInterval set endtime=(select min(i2.starttime) from dbo.#DTInterval i2 with (nolock) where i2.starttime>#DTInterval.starttime)  
update #DTInterval set endtime=@InputEndTime  where endtime is null  
Update #DTInterval set Duration = datediff(s,starttime,endtime)/60.0  
  
Update #DTInterval set totalStops=( select count(StartTime) as [Stops] from dbo.#DowntimeFinal with (nolock) where  ((#DowntimeFinal.starttime  >=  #DTInterval.Starttime) and (#DowntimeFinal.starttime < #DTInterval.Endtime)))  
  
--Update #DTInterval set totalDowntime=(select Sum(Downtime) as [durtn] from #DowntimeFinal where  ((#DowntimeFinal.starttime  >=  #DTInterval.Starttime) and (#DowntimeFinal.starttime < #DTInterval.Endtime)))  
  
  
  
insert into #ttl (st,totl)  
select dti.starttime,Sum (Datediff(s,  
case  
 when  dtf.starttime< dti.starttime   
 then dti.starttime   
 else dtf.starttime  
 end  
,  
case   
 when  dtf.endtime>dti.endtime or dtf.endtime is null  
 then dti.endtime   
 else dtf.endtime  
 end  
)/60.00)  
from #downtimefinal dtf,#DTInterval dti  
where   ((dtf.starttime < =  dti.endtime) and (dtf.endtime > dti.starttime)) or   
 ((dtf.starttime < =  dti.endtime )and dtf.endtime Is Null)   
group by dti.starttime  
  
  
  
update #dtinterval set totaldowntime=(select totl from dbo.#ttl with (nolock) where #dtinterval.starttime = st)  
  
  
  
--Select StartTime,Endtime,Duration,TotalDowntime,TotalStops  from  #DTInterval  
  
Select StartTime,TotalDowntime,TotalStops  from  dbo.#DTInterval with (nolock)  
    
  
end  
  
  
  
GOTO Finished  
  
  
ErrorMessagesWrite:  
-------------------------------------------------------------------------------  
-- Error Messages.  
-------------------------------------------------------------------------------  
 SELECT ErrMsg  
  FROM dbo.#ErrorMessages with (nolock)  
  
Finished:  
  
  
drop table #schedule_puid --  
drop table #downtime  
drop table #downtimeFinal  
drop table #DTSummary --   
drop table #ErrorMessages  
drop table #DTInterval --  
drop table #ttl --  
drop table #tests  
  
  
