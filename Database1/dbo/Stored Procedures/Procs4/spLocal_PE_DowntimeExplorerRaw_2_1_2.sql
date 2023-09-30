      /*  
Stored Procedure: spLocal_PE_DowntimeExplorerRaw_2_1_2  
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
V0.0.9  11/01/02 SLS Eliminate duplicate downtime where multiple comments added to a record  
v0.1.0  02/28/03 SLS multiple lines, optional columns  
v0.1.1  03/14/03 SLS changes to uptime update  
v0.1.2  03/14/03 SLS Issue for Release V0.1.2  
v0.1.2  03/26/03 SLS fix team/shift change uptime to be independant of puid  
v0.1.2  04/02/03 SLS modiifed split record  
V0.1.3          06/04/03        SLS     fixed bad uptime calcs  
V0.1.3  11/21/03 sls used Local_Timed_Event_Categories instead of looking up from reason tree  
V0.1.3          3/5/04          SLS     Fixed Category Assignment  
V0.1.4  6/29/04 hrm ALTER  parameter for user selected variables 1 & 2 (showvar)  
V0.1.5  07/27/04 BAS Rewrote ShowTurnover query and user variables added in 0.1.4  
V2.0.3  08/09/04 BAS Changed spare1,2 data types to float  
V2.0.3  08/17/04 BAS Added Shift Change to Reason2 and Fault columns per Jeff H.  
V2.0.3  08/18/04 HRM Modifiy InsertMidnight and SplitOnShift   
V2.1.2  9/21/04  BAS Renamed sp with XLA version.  
V2.1.2  9/22/04  RM Included categories in datechange inserted record  
V2.1.2  9/24/04  BAS Replaced '`' to 'Date Change' in the Insert Mignight section.  Not sure why that was there.  
V2.1.2  10/11/04 HRM Added Sheetbreak unit in the shift and date change code.  
V2.1.2  10/14/04 HRM sheetbreak and reliability units act as one unit for uptime & breaks  
V2.1.2  11/02/04 HRM Get T/O Events, Sheetbreaks and Reliability events per Matt Overley's requirements:  
     1) Merge all data sets requested by the user; don't calculate uptime yet.  
     2) Add in T/O events, if requested by the user.  
     3) Add in the shift and/or date changes (no duplicates!).  
     4) Sort all lines in the merged data set in order of start time.  
     5) Where the start time and end time for any event crosses over one or more shift/date changes, this event must be duplicated with the same fault, location, reason level 1, etc information.    
          For an event spanning a single shift/date change, the end time of the original event becomes the end time of the duplicate event, and the end time of the original event and the start time of the duplicate event are set equal the timestamp of the
 shift/date change.    
          For an event spanning multiple shift/date changes, this is just a bit more complicated.  
     6) Calculate the uptime for each line in the merged data set: start time of current event minus end time of previous event.  
  
V2.1.3  03/27/07 Marc Charest (STI) Since we upgraded to PA 423, the Waste_N_Comments table is no more in use. We now query for the Comments table  
V2.1.4  11/11/08 Mike Thoams (PG) Added conditional logic to check for Family Care reason categories so that we don't get an error from Baby/Fem sites.  
V2.1.5  02/19/09 Jeff Jaeger (Stier Automation)   
     modified the method for pulling Cat1, Cat2, Cat3, and Cat4.  
     updated the source for the Comment field in #Downtime.  
  
*/  
/*  
spLocal_PE_DowntimeExplorerRaw_2_1_2  '2004-08-01 00:00:00.000', '2004-09-24 00:00:00.000','AY5A Reliability,ay5a sheetbreak',  
 @showmasterprodunit =1, @showShift=1, @ShowTurnOvers=1, @SplitOnShift=1, @insertmidnight=1  
-- long reliability - AY5A Reliability is down from 2004-08-11 23:47 to 2004-08-16 05:40 total duration = 6112.8  
spLocal_PE_DowntimeExplorerRaw_2_1_2  '2004-08-1 23:00:00.000', '2004-09-24 00:00:00.000','AY5A Reliability,ay5a sheetbreak',  
 @showmasterprodunit =1, @showShift=1, @ShowTurnOvers=0, @SplitOnShift=0, @insertmidnight=1  
  
select pu.pu_desc, datediff(s,ted2.end_time,ted1.start_time)/60.0, ted2.start_time, ted2.end_time, ted1.start_time, ted1.end_time  
from timed_event_details ted1  
join prod_units pu on pu.pu_id = ted1.pu_id and pu_desc like '%sheetbreak'  
join timed_event_details ted2 on ted2.pu_id = ted1.pu_id  and ted2.start_time > '2004-08-01'  
 and ted2.start_time =  
(select max(start_time) from timed_event_details ted3 where ted3.pu_id = ted2.pu_id and ted3.start_time<ted1.start_time)  
where ted1.start_time > '2004-08-01' order by datediff(s,ted2.end_time,ted1.start_time)/60.0 desc  
  
-- Big uptimes  sheetbreak from 8/11  22:09 to 8/16 05:40  
spLocal_PE_DowntimeExplorerRaw_2_1_2  '2004-08-11 22:00:00.000', '2004-08-16 06:00:00.000','AY5A Reliability,AY5A Sheetbreak'  
 ,@showmasterprodunit =1, @showShift=1, @ShowTurnOvers=0, @SplitOnShift=0, @insertmidnight=1  
  
-- BOTH UNITS ARE DOWN reliability from 6/3 4:41 to 6/13 14:13 & sheetbreak spans a shift 7:05 to 7:36  
update timed_event_details  set end_time = '2004-06-03 07:36:38' where tedet_id = 7301248  
spLocal_PE_DowntimeExplorerRaw_2_1_2  '2004-06-03 00:00:00.000', '2004-06-04 00:00:00.000','AY3A Reliability,AY3A Sheetbreak'  
 ,@showmasterprodunit =1, @showShift=1, @ShowTurnOvers=0, @SplitOnShift=0, @insertmidnight=1  
update timed_event_details  set end_time = '2004-06-03 07:06:38' where tedet_id = 7301248  
----   
  
-- BOTH UNITS span midnight  
update timed_event_details  set start_time = '2004-04-25 23:59:00' where tedet_id = 6647879  
spLocal_PE_DowntimeExplorerRaw_2_1_2  '2004-04-25 00:00:00.000', '2004-04-27 00:00:00.000','AY2A Reliability,AY2A Sheetbreak'  
 ,@showmasterprodunit =1, @showShift=1, @ShowTurnOvers=0, @SplitOnShift=0, @insertmidnight=0  
update timed_event_details  set start_time = '2004-04-26 00:03:24' where tedet_id = 6647879  
----   
  
*/  
  
  
CREATE    procedure dbo.spLocal_PE_DowntimeExplorerRaw_2_1_2  
@InputStartTime  DateTime,  
@InputEndTime  DateTime,  
@InputMasterProdUnit nVarChar(4000)=null,  
@showmasterprodunit int=0,  
@showReason3 int=0,  
@showReason4 int=0,  
@showTeam int=0,  
@showShift int=0,  
@showComment int=0,  
@showProduct int=0,  
@showBrandCode int=0,  
@showCat1 int=0,  
@showCat2 int=0,  
@showCat3 int=0,  
@showCat4 int=0,  
@showvar1 varchar(100)='',  
@showvar2 varchar(100)='',  
@InsertMidnight int=0,  
@SplitOnShift int=0,  
@ShowTurnOvers int=0  
  
As  
  
  
-----------------------------------------------------------  
-- Declare program variables.  
-----------------------------------------------------------  
DECLARE @Position int,  
  @InputOrderByClause nvarChar(4000),  
  @InputGroupByClause nvarChar(4000),  
  @strSQL   VarChar(4000),  
  @current datetime,  
  @tmpStartTime as datetime,  
  @tmpEndTime as datetime,  
  @tmpCount as int,  
  @tmpLoopCounter  int,  
  @CatPrefix   varchar (30)  
------------------------------------------------------------  
---- CREATE  Temp TABLES   ---------------------------------  
------------------------------------------------------------  
Create table #DownTime(      
  DT_ID                 int IDENTITY (0, 1) NOT NULL ,  
 StartTime datetime,  
 EndTime  datetime,  
 Uptime  Float,  
 Downtime Float,  
 MasterProdUnit varchar(100),  
 Location varchar(50),  
 split  varchar(50),  
 Fault  varchar(100),  
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
 Comments varchar(2000),  
 StartTime_Act datetime,  
 EndTime_Act datetime,  
 Endtime_Prev datetime,  
 PUID  INT,  
 SourcePUID INT,  
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
 Spare1  Float,--varchar(255), --Changed to float for Line Target Speed  
 Spare2  Float,--varchar(255), --Changed to float for Line Actual Speed  
 Spare3  varchar(255),  
 Spare4  varchar(255),   
 Spare5  varchar(255),   
 Spare6  varchar(255),   
 Spare7  varchar(255),   
 Spare8  varchar(255),   
 Spare9  varchar(255),   
 Spare10  varchar(255),  
 cause_comment_id INTEGER  
)  
CREATE INDEX td_PUId_StartTime  
 ON #DownTime (PUId, StartTime)  
CREATE INDEX td_PUId_EndTime  
 ON #DownTime (PUId, EndTime)  
  
  
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
  
----------Populate the #Downtime Table from Timed Event Details Table -------------  
if @showreason3=1 and @showreason4=1   
insert into #DownTime (StartTime,EndTime,MasterProdUnit,Fault,Location,PUID,Reason1,Reason2,Reason3,REASONID3  
,Reason4,REASONID4,startTime_act,EndTime_act,tedet_id,REASONID1,REASONID2,SourcePUID,cause_comment_id,ERTD_ID)  
select ted.start_time, ted.end_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc, ted.pu_ID, r1.event_reason_name,  
r2.event_reason_name,r3.event_reason_name,ted.reason_level3,r4.event_reason_name,ted.reason_level4,  
ted.start_time, ted.end_time, ted.tedet_id,ted.reason_level1, ted.reason_level2,   ted.Source_PU_ID,ted.cause_comment_id,  
ted.event_reason_tree_data_id  
FROM dbo.timed_event_details AS ted with (nolock)   
LEFT JOIN dbo.event_reasons AS r1 with (nolock) ON (r1.event_reason_id = ted.reason_level1)  
LEFT JOIN dbo.event_reasons AS r2 with (nolock) ON (r2.event_reason_id = ted.reason_level2)  
LEFT JOIN dbo.event_reasons AS r3 with (nolock) ON (r3.event_reason_id = ted.reason_level3)  
LEFT JOIN dbo.event_reasons AS r4 with (nolock) ON (r4.event_reason_id = ted.reason_level4)  
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) on (pu2.pu_id = ted.pu_id)  
WHERE ( ((Start_time < =  @InputEndTime) and (end_time > @InputStartTime)) or ((Start_time < =  @InputEndTime )and end_time Is Null) )  
and ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  )) > 0 or (@InputMasterProdUnit = 'All'))  
order by ted.start_Time,  ted.pu_ID  
  
if @showreason3=0 and @showreason4=1  
insert into #DownTime (StartTime,EndTime,MasterProdUnit,Fault,Location,PUID,Reason1,Reason2,  
Reason4,REASONID4,startTime_act,EndTime_act,tedet_id,REASONID1,REASONID2,SourcePUID,cause_comment_id,ERTD_ID)  
select ted.start_time, ted.end_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc, ted.pu_ID, r1.event_reason_name,  
r2.event_reason_name,r4.event_reason_name,ted.reason_level4,  
ted.start_time, ted.end_time, ted.tedet_id,ted.reason_level1, ted.reason_level2,   ted.Source_PU_ID,ted.cause_comment_id,  
ted.event_reason_tree_data_id  
FROM dbo.timed_event_details AS ted with (nolock)   
LEFT JOIN dbo.event_reasons AS r1 with (nolock) ON (r1.event_reason_id = ted.reason_level1)  
LEFT JOIN dbo.event_reasons AS r2 with (nolock) ON (r2.event_reason_id = ted.reason_level2)  
LEFT JOIN dbo.event_reasons AS r4 with (nolock) ON (r4.event_reason_id = ted.reason_level4)  
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) on (pu2.pu_id = ted.pu_id)  
WHERE ( ((Start_time < =  @InputEndTime) and (end_time > @InputStartTime)) or ((Start_time < =  @InputEndTime )and end_time Is Null) )  
and ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  )) > 0 or (@InputMasterProdUnit = 'All'))  
order by ted.start_Time,  ted.pu_ID  
  
if @showreason4=0 and @showreason3=1  
insert into #DownTime (StartTime,EndTime,MasterProdUnit,Fault,Location,PUID,Reason1,Reason2,  
Reason3,REASONID3,startTime_act,EndTime_act,tedet_id,REASONID1,REASONID2,SourcePUID,cause_comment_id,ERTD_ID)  
select ted.start_time, ted.end_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc, ted.pu_ID, r1.event_reason_name,  
r2.event_reason_name,r3.event_reason_name,ted.reason_level3,  
ted.start_time, ted.end_time, ted.tedet_id,ted.reason_level1, ted.reason_level2,   ted.Source_PU_ID,ted.cause_comment_id,  
ted.event_reason_tree_data_id  
FROM dbo.timed_event_details AS ted with (nolock)  
LEFT JOIN dbo.event_reasons AS r1 with (nolock) ON (r1.event_reason_id = ted.reason_level1)  
LEFT JOIN dbo.event_reasons AS r2 with (nolock) ON (r2.event_reason_id = ted.reason_level2)  
LEFT JOIN dbo.event_reasons AS r3 with (nolock) ON (r3.event_reason_id = ted.reason_level3)  
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) on (pu2.pu_id = ted.pu_id)  
WHERE ( ((Start_time < =  @InputEndTime) and (end_time > @InputStartTime)) or ((Start_time < =  @InputEndTime )and end_time Is Null) )  
and ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  )) > 0 or (@InputMasterProdUnit = 'All'))  
order by ted.start_Time,  ted.pu_ID  
  
if @showreason4=0 and @showreason3=0  
insert into #DownTime (StartTime,EndTime,MasterProdUnit,Fault,Location,PUID,Reason1,Reason2,  
startTime_act,EndTime_act,tedet_id,REASONID1,REASONID2,SourcePUID,cause_comment_id,ERTD_ID)  
select ted.start_time, ted.end_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc, ted.pu_ID, r1.event_reason_name,  
r2.event_reason_name,  
ted.start_time, ted.end_time, ted.tedet_id,ted.reason_level1, ted.reason_level2,   ted.Source_PU_ID,ted.cause_comment_id,  
ted.event_reason_tree_data_id  
FROM dbo.timed_event_details AS ted with (nolock)   
LEFT JOIN dbo.event_reasons AS r1 with (nolock) ON (r1.event_reason_id = ted.reason_level1)  
LEFT JOIN dbo.event_reasons AS r2 with (nolock) ON (r2.event_reason_id = ted.reason_level2)  
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) on (pu2.pu_id = ted.pu_id)  
WHERE ( ((Start_time < =  @InputEndTime) and (end_time > @InputStartTime)) or ((Start_time < =  @InputEndTime )and end_time Is Null) )  
and ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  )) > 0 or (@InputMasterProdUnit = 'All'))  
order by ted.start_Time,  ted.pu_ID  
  
-- UPDATE #DOWNTIME SET COMMENTS = (SELECT TOP 1 CAST(wtc.Comment_Text AS VARCHAR(255)) FROM waste_n_timed_comments AS wtc WHERE wtc.wtc_source_id = #DOWNTIME.tedet_id)  
if @showcomment=1  
--UPDATE #DOWNTIME SET COMMENTS = (  
--SELECT TOP 1 CAST(c.comment_text AS VARCHAR(255))   
--FROM dbo.comments c with (nolock)  
--WHERE c.comment_id = #DOWNTIME.cause_comment_id)  
update ted set  
 comments = REPLACE(coalesce(convert(varchar(2000),co.comment_text),''), char(13)+char(10), ' ')  
from dbo.#Downtime ted with (nolock)  
left join dbo.Comments co with (nolock)  
on ted.cause_comment_id = co.comment_id  
/*  
zzz  
SELECT TOP 1 CAST(wtc.Comment_Text AS VARCHAR(255)) FROM waste_n_timed_comments AS wtc  
 WHERE wtc.wtc_source_id = #DOWNTIME.tedet_id AND wtc.timestamp=(  
select max(wtc2.timestamp) from waste_n_timed_comments wtc2 where wtc.wtc_source_id=wtc2.wtc_source_id))  
zzz  
*/  
  
/*  
----If the downtime event started before the period then change the starttime to the period start and Set SBP (Downtime Started before period)--  
update #downtime set starttime=@InputStartTime,  
  SBP = 1  
 where starttime<@InputStartTime  
----If the downtime event ended after the report period then change the endttime to the period Endtime and Set EAP (Downtime Ended After period)--  
  
update #downtime set endtime=@InputEndTime,  
  EAP = 1  
  where endtime>@InputEndTime   
  
*/  
----------set Downtime -------------  
if @ShowTurnOvers=1  
 begin  
 insert #downtime(starttime, endtime, downtime, uptime, masterprodunit, puid, sourcepuid, FAULT, location)  
 select timestamp, timestamp, 0 ,0, pu.pu_desc, pu.pu_id, pu.pu_id, TT.RESULT, 'Parent Roll T/O'   
 from dbo.events ee with (nolock)  
 join dbo.prod_units pu with (nolock) on pu.pu_id = ee.pu_id   
 and pu.extended_info like '%QCSDataUnit=%'  
 and pu.pl_id=(  
  select distinct pl_id from dbo.prod_units pu2 with (nolock)   
  join dbo.#downtime dt with (nolock) on dt.puid = pu2.pu_id   
  where charindex(','+pu2.pu_desc+',', ','+@InputMasterProdUnit+',')>0   
 )   
 join dbo.prod_units pu3 with (nolock) on pu3.pl_id = pu.pl_id  
 join dbo.variables vv with (nolock) on vv.extended_info like 'GlblDesc=Basis Weight Manual;%'  
 and vv.pu_id =pu3.pu_id  
 and vv.DS_id <> 7 --Not an Aliased variable    
 left JOIN dbo.tests tt with (nolock) ON TT.result_on = TIMESTAMP and tt.var_id = vv.var_id  
 where ee.timestamp>=@inputstarttime and ee.timestamp<@inputendtime  
  
 end  
  
update #downtime set Downtime = datediff(s,starttime,endtime)/60.0  
  
----If there is in no endtime (which should mean that the record is still open (downtime is still active) aussume that the endtime of the event is  
  
update #downtime set Downtime = datediff(s,starttime,@InputEndTime)/60.0  
 where Endtime is null  
  
  
  
----------get Valid Crew Schedule for the time Period in Question -------------  
  
create table #schedule_puid (pu_id int, schedule_puid int, tmp1 int,tmp2 int,info varchar(300))  
  
if @showteam=1 or @showshift=1  
  
 begin  
  
 insert into #schedule_puid (pu_id,info) select pu_id,extended_info from dbo.prod_units with (nolock)   
 where (charindex(','+pu_desc+',',','+@inputmasterprodunit+',')>0 or @inputmasterprodunit='All')  
  
 update #schedule_puid set tmp1=charindex('scheduleunit=',info)  
   
 update #schedule_puid set tmp2=charindex(';',info,tmp1) where tmp1>0  
  
 update #schedule_puid set schedule_puid=cast(substring(info,tmp1+13,tmp2-tmp1-13) as int) where tmp1>0 and tmp2>0 and not tmp2 is null  
  
 update #schedule_puid set schedule_puid=cast(substring(info,tmp1+13,len(info)-tmp1-12) as int)where tmp1>0 and tmp2=0  
  
 update #schedule_puid set schedule_puid=pu_id where schedule_puid is null  
  
 end  
----------set Team -------------  
  
if @showteam=1  
update #downtime set team=( select  crew_desc from dbo.crew_schedule cs with (nolock) join dbo.#schedule_puid sp with (nolock) on cs.pu_id=sp.schedule_puid  
 where #downtime.starttime>=cs.start_time and cs.end_time>#downtime.starttime and #downtime.puid=sp.pu_id)  
  
----------set Shift -------------  
if @showshift=1  
 begin  
 if @splitonshift=1  
  begin  
  -- mark which records need to have end time changed  
  update dt1 set split = cs.end_time   
  from dbo.#downtime dt1 with (nolock)   
  join dbo.#schedule_puid sp with (nolock) on sp.pu_id = dt1.puid  
  join dbo.crew_schedule cs with (nolock) on cs.pu_id = sp.schedule_puid  
  where dt1.starttime>cs.start_time and dt1.starttime < cs.end_time -- this matches any record  
  and dt1.endtime > cs.end_time and (masterprodunit like '%sheetbreak' or masterprodunit like '%reliability') -- this crosses schedule boundary  
--  and  (charindex(','+pu_desc+',',','+@inputmasterprodunit+',')>0   
  
  insert #downtime (starttime, endtime, puid, sourcepuid, uptime, split, downtime, masterprodunit, tedet_id, fault, reason1, reason2, reason3, reason4, reasonid1, reasonid2, reasonid3, reasonid4,team, location, ERTD_ID)   
  select cs.start_time  
  , case when endtime < cs.end_time then endtime else cs.end_time end -- endtime  
  , puid, sourcepuid, 0, 'inserted', 0, masterprodunit, tedet_id, fault, reason1, reason2, reason3, reason4, reasonid1, reasonid2, reasonid3, reasonid4, cs.crew_desc, location, ERTD_ID  
  from dbo.#downtime dt1 with (nolock)   
  join dbo.#schedule_puid sp with (nolock) on sp.pu_id = dt1.puid  
  join dbo.crew_schedule cs with (nolock) on cs.pu_id = sp.schedule_puid  
  and dt1.starttime<cs.start_time and dt1.endtime > cs.start_time and (masterprodunit like '%reliability' or masterprodunit like '%sheetbreak')  
  
  -- fix the downtime for the inserted record  
  update #downtime set downtime = datediff(s,starttime,endtime)/60.0  
  where split = 'inserted'  
  
  -- fix the endtime and the downtime of the original record  
  update #downtime set   
  endtime = split, downtime = datediff(s,starttime, split)/60.0  
  where split is not null and split<>'marker' and split<>'inserted'  
   
  -----------------------------------------------------------------  
  
  
  -- add records with correct starttimes and endtimes  
  --BAS, Added Shift Change to other columns  
  insert #downtime (starttime, endtime, puid, uptime, split, downtime, masterprodunit, fault, reason1, reason2, location, team )   
  select cs.end_time, cs.end_time, sp.pu_id, 0, 'marker', 0, masterprodunit, 'Shift Change', 'Shift Change', 'Shift Change', null, crew_desc  
  from dbo.#schedule_puid sp with (nolock)   
  join dbo.crew_schedule cs with (nolock) on cs.pu_id = sp.schedule_puid    
  join dbo.#downtime dt with (nolock) on dt.puid = sp.pu_id and  dt.starttime =   
  (select top 1 starttime from dbo.#downtime dt2 with (nolock) where dt2.puid = sp.pu_id)  
  and (masterprodunit like '%sheetbreak' or masterprodunit like '%reliability')   
  where (select min(starttime) from dbo.#downtime with (nolock)) < cs.end_time   
  and (select max(endtime) from dbo.#downtime with (nolock)) > cs.end_time   
  
   
  -- delete dupes caused by actual splitting of event on shift  
--  delete from #downtime where fault  ='shift change' and  ( select COUNT(*) from #downtime dt2 where dt2.starttime = #downtime.starttime and dt2.masterprodunit<>#downtime.masterprodunit  and masterprodunit like '%reliability')>0  and masterprodunit like  '%sheetbreak'  
  
  update #downtime set split=null  
  end  
  
 update #downtime set uptime = datediff(s,  
 (select max(endtime) from dbo.#downtime dt2 with (nolock) where dt2.puid = #downtime.puid and dt2.starttime<#downtime.starttime),starttime)/60.0   
 where not masterprodunit like '%Production' --CHARINDEX( ',' + masterprodunit + ','  ,  ','+ @InputMasterProdUnit+','  ) > 0   
  
 update #downtime set shift=( select  shift_desc from dbo.crew_schedule cs with (nolock) join dbo.#schedule_puid sp with (nolock) on cs.pu_id=sp.schedule_puid  
 where #downtime.starttime>=cs.start_time and cs.end_time>#downtime.starttime and #downtime.puid=sp.pu_id)  
 end   
  
  
if @insertmidnight=1  
 begin  
  
 CREATE TABLE #DAYS ( DT DATETIME)  
  
  
 DECLARE @DT DATETIME  
 SELECT @DT = min(starttime) from dbo.#downtime with (nolock)  
 select @dt = convert(datetime,ltrim(datepart(yyyy,@dt)) + '-' + ltrim(datepart(mm,@dt)) + '-' + ltrim(datepart(d,@dt)) )+1  
 WHILE (@DT<(select max(endtime) from dbo.#downtime with (nolock)))  
  BEGIN  
  INSERT #DAYS SELECT @DT  
  SELECT @DT = @DT+1  
  END  
  
 ---------------------------- SPLIT LONG DOWNTIMES ---------------------------------------  
 -- remainder record  
 insert #downtime (starttime, endtime, downtime, puid, masterprodunit, uptime, split, fault, reason1, reason2, team, shift, ERTD_ID ) --  
 select  CONVERT(DATETIME,ltrim(datepart(yyyy,dt.endtime)) + '-' + ltrim(datepart(mm, dt.endtime)) + '-' + ltrim(datepart(dd, dt.endtime)) )  
 ,endtime, datediff(s,starttime,endtime)/60.0, dt.puid, dt.masterprodunit, 0, 'remainder', fault,reason1, reason2, dt.team, dt.shift, dt.ERTD_ID  
 from dbo.#downtime dt with (nolock) where   
 convert(datetime,endtime) > CONVERT(DATETIME,ltrim(datepart(yyyy,dt.STARTtime)) + '-' + ltrim(datepart(mm, dt.STARTtime)) + '-' + ltrim(datepart(dd, dt.STARTtime)) )+1  
 and (masterprodunit like '%sheetbreak' or masterprodunit like '%reliability')  
  
 -- LOST DAY record  
 insert #downtime (starttime, endtime, downtime, puid, masterprodunit, uptime, split, fault, reason1, reason2, team, shift ) --  
 select  dt1.DT, dt2.DT, 1440, dt.puid, dt.masterprodunit, 0, 'LST DAY', fault,reason1, reason2, dt.team, dt.shift  
 from dbo.#downtime dt with (nolock)  
 join dbo.#days DT1 with (nolock) on DT1.dt>starttime AND DT1.DT<ENDTIME  
 JOIN dbo.#DAYS DT2 with (nolock) ON DT2.DT>STARTTIME and DT2.dt<endtime AND DT1.DT = DT2.DT-1  
 where   
 convert(datetime,endtime) > CONVERT(DATETIME,ltrim(datepart(yyyy,dt.STARTtime)) + '-' + ltrim(datepart(mm, dt.STARTtime)) + '-' + ltrim(datepart(dd, dt.STARTtime)) )+1  
 and (masterprodunit like '%sheetbreak' or masterprodunit like '%reliability')  
  
 insert #downtime (starttime, endtime, downtime, puid, masterprodunit, uptime, split, fault, reason1, reason2, team, shift ) --  
 select  dt,dt, 0, dt.puid, dt.masterprodunit, 0, 'Date Change', 'Date Change', 'Date Change','Date Change', dt.team, dt.shift  
 from dbo.#downtime dt with (nolock)  
 join dbo.#days with (nolock) on #days.dt>starttime and #days.dt<endtime  
 where   
 convert(datetime,endtime) > CONVERT(DATETIME,ltrim(datepart(yyyy,dt.STARTtime)) + '-' + ltrim(datepart(mm, dt.STARTtime)) + '-' + ltrim(datepart(dd, dt.STARTtime)) )+1  
 and (masterprodunit like '%sheetbreak' or masterprodunit like '%reliability')  
  
  
 -- original record  
 update #downtime set endtime=  
 CONVERT(DATETIME,ltrim(datepart(yyyy,STARTtime)) + '-' + ltrim(datepart(mm, STARTtime)) + '-' + ltrim(datepart(dd, STARTtime)) )+1  
 where   
 endtime>CONVERT(DATETIME,ltrim(datepart(yyyy,STARTtime)) + '-' + ltrim(datepart(mm, STARTtime)) + '-' + ltrim(datepart(dd, STARTtime)) )+1  
 and (masterprodunit like '%sheetbreak' or masterprodunit like '%reliability')  
  
 ---------------------------- SPLIT LONG UPTIMES ---------------------------------------  
 -- add day change records between downtime records   
 -- insert day change records before the first downtime  
 insert #downtime (starttime, endtime, downtime, puid, masterprodunit, uptime, split, fault, reason1, reason2, team ) --  
 select DT, DT, 0, dt.puid, dt.masterprodunit, 0, 'marker1', 'Date Change', 'Date Change', 'Date Change', dt.team--BAS Changed '`' to 'Date Change  
 from dbo.#downtime dt with (nolock)   
 JOIN dbo.#DAYS with (nolock) ON #DAYS.DT < CONVERT(DATETIME,DT.starttime)  
 WHERE (dt.masterprodunit  LIKE '%sheetbreak' or dt.masterprodunit like '%Reliability')  
 and dt.starttime = (select min(dt2.starttime) from dbo.#downtime dt2 with (nolock) where dt2.puid = dt.puid)  
  
 -- insert day change records after the last downtime  
 insert #downtime (starttime, endtime, downtime, puid, masterprodunit, uptime, split, fault, reason1, reason2, team ) --  
 select  DT,DT  
 , 0, dt.puid, dt.masterprodunit, 0, 'marker1', 'Date Change', 'Date Change', 'Date Change', dt.team--BAS Changed '`' to 'Date Change  
 from dbo.#downtime dt with (nolock)   
 JOIN dbo.#DAYS with (nolock) ON #DAYS.DT > CONVERT(DATETIME,DT.ENDTIME)  
 WHERE (dt.masterprodunit  LIKE '%sheetbreak' or dt.masterprodunit like '%Reliability')  
 and dt.starttime = (select max(dt2.starttime) from dbo.#downtime dt2 with (nolock) where dt2.puid = dt.puid)  
  
 -- insert day change records between downtimes  
 insert #downtime (starttime, endtime, downtime, puid, masterprodunit, uptime, split, fault, reason1, reason2, team ) --  
 select  DT,DT  
 , 0, dt.puid, dt.masterprodunit, 0, 'marker2', 'Date Change', 'Date Change', 'Date Change', dt.team--BAS Changed '`' to 'Date Change  
 from dbo.#downtime dt with (nolock)   
 join dbo.#downtime dtprev with (nolock) on  dtprev.starttime = (  
  select max(starttime) from dbo.#downtime with (nolock) where starttime<dt.starttime and puid = dt.puid -- (masterprodunit  LIKE '%sheetbreak' or masterprodunit like '%Reliability')  
 ) and  
 datepart(dd,dtprev.endtime)<>datepart(dd,dt.starttime)  --  AND DTPREV.FAULT<>'DATE CHANGE'  
 and dtprev.puid = dt.puid -- (dtprev.masterprodunit  LIKE '%sheetbreak' or dtprev.masterprodunit like '%Reliability')  
 JOIN dbo.#DAYS with (nolock) ON #DAYS.DT>CONVERT(DATETIME,DTPREV.STARTTIME) AND #DAYS.DT<CONVERT(DATETIME,DT.ENDTIME)  
 WHERE (dt.masterprodunit  LIKE '%sheetbreak' or dt.masterprodunit like '%Reliability')  
  
 -- delete duplicate date change records  
 update dt set fault = 'delete' from dbo.#downtime dt with (nolock)  
 join dbo.#downtime dt2 with (nolock) on dt2.puid = dt.puid and dt2.starttime = dt.starttime and dt.dt_id>dt2.dt_id and dt.fault = dt2.fault  
 delete #downtime where fault = 'delete'  
  
  
 update #downtime set split=null  
  
 update #DOWNTIME set DOWNTIME = datediff(s, STARTTIME,ENDTIME)/60.0  
  
 update dt set uptime = datediff(s, DTPREV.ENDTIME, DT.STARTTIME)/60.0  
 from dbo.#downtime dt with (nolock) join dbo.#downtime dtprev with (nolock) on dtprev.puid = dt.puid and   
 (dtPREV.masterprodunit  LIKE '%sheetbreak' or dtPREV.masterprodunit like '%Reliability')  
 AND dtprev.starttime =   
 (select max(dt2.starttime) from #downtime dt2 where dt2.starttime<dt.starttime and DT2.PUID= DTPREV.PUID )  
 WHERE (dt.masterprodunit  LIKE '%sheetbreak' or dt.masterprodunit like '%Reliability')  
  
 end  
  
  
----------set Product -------------  
if @showproduct=1  
update #DownTime set product=(  
 select p.Prod_Desc from dbo.products p with (nolock) join dbo.production_starts ps with (nolock) on ps.prod_id= p.prod_id   
 join dbo.prod_units with (nolock) on ps.pu_id=prod_units.pu_id where ps.start_time <= #downtime.starttime  
 and ((#downtime.starttime < ps.end_time) or (ps.end_time is null)) and ps.pu_id=#downtime.puid)  
if @showbrandcode=1  
update #DownTime set brand=(  
 select p.prod_code from dbo.products p with (nolock) join dbo.production_starts ps with (nolock) on ps.prod_id= p.prod_id   
 join dbo.prod_units with (nolock) on ps.pu_id=prod_units.pu_id where ps.start_time <= #downtime.starttime  
 and ((#downtime.starttime < ps.end_time) or (ps.end_time is null)) and ps.pu_id=#downtime.puid)  
  
  
/*  
----------Get Event Reason tree data IDs for each Reason-------------  
if @showcat1=1  
update #downtime set ErtdID1=(  
select  ertd.Event_reason_tree_data_id from   
Prod_events pe  
join event_reason_tree_data ertd on ertd.tree_name_id=pe.Name_id   
where ertd.event_reason_level=1  
and #downtime.SourcePUID=pe.pu_id   
and ertd.event_reason_id=#downtime.reasonid1  
and pe.Event_type = 2)where #downtime.reasonid1 is NOT null  
  
if @showcat2=1  
update #downtime set ErtdID2=(  
select  ertd.Event_reason_tree_data_id from   
Prod_events pe  
join event_reason_tree_data ertd on ertd.tree_name_id=pe.Name_id   
where ertd.event_reason_level=2  
and #downtime.SourcePUID=pe.pu_id   
and ertd.event_reason_id=#downtime.reasonid2  
and ertd.Parent_Event_reason_id=#downtime.reasonid1  
and pe.Event_type = 2)where #downtime.reasonid2 is NOT null  
  
if @showcat3=1  
update #downtime set ErtdID3=(  
select  ertd.Event_reason_tree_data_id from   
Prod_events pe  
join event_reason_tree_data ertd on ertd.tree_name_id=pe.Name_id   
join event_reason_tree_data ertd1 on ertd1.Event_reason_tree_data_id = ertd.Parent_Event_R_Tree_Data_Id  
where ertd.event_reason_level=3  
and #downtime.SourcePUID=pe.pu_id   
and ertd.event_reason_id=#downtime.reasonid3   
and ertd.Parent_Event_reason_id=#downtime.reasonid2  
and ertd1.Parent_Event_reason_id=#downtime.reasonid1  
and pe.Event_type = 2  
)where #downtime.reasonid3 is NOT null  
  
if @showcat4=1  
update #downtime set ErtdID4=(  
select  ertd.Event_reason_tree_data_id from   
Prod_events pe  
join event_reason_tree_data ertd on ertd.tree_name_id=pe.Name_id  
join event_reason_tree_data ertd1 on ertd1.Event_reason_tree_data_id = ertd.Parent_Event_R_Tree_Data_Id  
join event_reason_tree_data ertd2 on ertd2.Event_reason_tree_data_id = ertd1.Parent_Event_R_Tree_Data_Id  
where ertd.event_reason_level=4  
and #downtime.SourcePUID=pe.pu_id   
and ertd.event_reason_id=#downtime.reasonid4  
and ertd.Parent_Event_reason_id=#downtime.reasonid3  
and ertd1.Parent_Event_reason_id=#downtime.reasonid2  
and ertd2.Parent_Event_reason_id=#downtime.reasonid1  
and pe.Event_type = 2  
)where #downtime.reasonid4 is NOT null  
  
  
--Apply Family Care reason categories if they exist  
IF (SELECT count(erc_id) FROM event_reason_catagories   
WHERE charindex('category:', erc_desc) > 0  
OR charindex('Schedule:', erc_desc) > 0  
OR charindex('Subsystem:', erc_desc) > 0  
OR charindex('GroupCause:', erc_desc) > 0) > 5  
BEGIN  
  
----------SET Category -------------  
  
IF @showcat1=1  
 BEGIN  
 SELECT @CatPrefix='category:'  
 UPDATE #downtime SET Cat1=(  
                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
                          event_reason_catagories erc  
                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
                           )  
  
 END  
  
----------SET Schedule -------------  
  
  
IF @showcat2=1  
 BEGIN  
             SELECT @CatPrefix='Schedule:'  
 UPDATE #downtime SET Cat2=(  
                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
                          event_reason_catagories erc  
                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
                           )  
 END  
  
----------SET Subsystem -------------  
  
  
IF @showcat3=1  
 BEGIN  
 SELECT @CatPrefix='Subsystem:'  
 UPDATE #downtime SET Cat3=(  
                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
                          event_reason_catagories erc  
                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
                           )  
 END  
----------SET GroupCause -------------  
  
  
IF @showcat4=1  
 BEGIN  
  
 SELECT @CatPrefix='GroupCause:'  
 UPDATE #downtime SET Cat4=(  
                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
                          event_reason_catagories erc  
                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
                           )  
 END  
  
END  
*/  
  
SELECT @CatPrefix='category:'  
UPDATE td SET  
-- CategoryId = erc.ERC_Id  
 Cat1 = right(erc.erc_desc,len(erc.erc_desc)-len(@CatPrefix))  
FROM dbo.#downtime td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
  
SELECT @CatPrefix='Schedule:'  
UPDATE td SET  
-- ScheduleId = erc.ERC_Id  
 Cat2 = right(erc.erc_desc,len(erc.erc_desc)-len(@CatPrefix))  
FROM dbo.#downtime td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
  
/*  
UPDATE td SET   
 ScheduleId = @SchedBlockedStarvedId  
FROM dbo.#downtime td with (nolock)  
JOIN dbo.Event_Reasons er with (nolock)  
on Event_Reason_ID = L1ReasonId   
WHERE ScheduleId IS NULL   
AND (Event_Reason_Name LIKE '%BLOCK%' OR Event_Reason_Name LIKE '%STARVE%')  
*/  
  
  
select @CatPrefix='Subsystem:'  
UPDATE td SET  
-- SubSystemId = erc.ERC_Id  
 Cat3 = right(erc.erc_desc,len(erc.erc_desc)-len(@CatPrefix))  
FROM dbo.#downtime td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
  
select @CatPrefix='GroupCause:'  
UPDATE td SET  
-- GroupCauseId = erc.ERC_Id  
 Cat4 = right(erc.erc_desc,len(erc.erc_desc)-len(@CatPrefix))  
FROM dbo.#downtime td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
  
-------------------------------------------------------------------------  
  
update #downtime set split='S'  where starttime=(select max(endtime) from dbo.#downtime dt2 with (nolock) where dt2.puid=#downtime.puid and   
dt2.endtime<#downtime.endtime)  
  
update #downtime set split='P'  where endtime=(select min(starttime) from dbo.#downtime dt2 with (nolock) where dt2.puid=#downtime.puid and   
dt2.starttime>#downtime.starttime) and split is null  
  
  
update #downtime set uptime = datediff(s,(  
 select max(endtime) from dbo.#downtime dt2 with (nolock) where dt2.starttime<#downtime.starttime  
 and dt2.puid = #downtime.puid),starttime)/60.0  
where not masterprodunit like '%production' -- CHARINDEX( ',' + masterprodunit + ','  ,  ','+ @InputMasterProdUnit+','  ) > 0   
  
---------------------------- fix block 2 --------------------  
delete from dbo.#downtime where exists(  
select dt2.starttime from dbo.#downtime dt2 with (nolock) where dt2.starttime = #downtime.starttime   
and dt2.fault = #downtime.fault  
) and fault like '%change' AND MASTERPRODUNIT LIKE '%SHEETBREAK%'  
  
  
update #downtime set uptime = datediff(s,  
(select max(dtprev.endtime) from dbo.#downtime dtprev with (nolock) where dtprev.starttime < #downtime.starttime )  
,starttime)/60.0  
  
--update #downtime set uptime = 0  
--where location ='Parent Roll T/O'  
----------------------------------------------------------------------  
  
  
/*   
declare @preEnd datetime  
  
select @preEnd = max(end_time)  
from timed_event_details ted   
LEFT JOIN timed_event_fault AS tef ON (tef.tefault_id = ted.tefault_id)  
LEFT Join prod_units AS pu ON (pu.pu_id = ted.source_PU_Id)  
inner join prod_units as pu2 on (pu2.pu_id = ted.pu_id)  
WHERE  (end_time <= @InputStartTime) --or (Start_time <=  @InputEndTime and end_time Is Null) )  
and (CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  ) > 0 or (@InputMasterProdUnit = 'All'))  
  
update #downtime set uptime=datediff(s,@preEnd,starttime)/60.0   
where uptime is null  
*/  
update #downtime set uptime = 0  
where uptime is null and masterprodunit not like '%production'  
  
if @showvar1<>''   
 begin  
  
 update #downtime set spare1=(select distinct result from dbo.tests tt with (nolock)   
 join dbo.variables vv with (nolock) on vv.var_id = tt.var_id   
 and vv.extended_info like @showvar1   
 and tt.result_on = #downtime.starttime  
 and vv.pu_id=#downtime.puid)  
  
 end   
  
if @showvar2<>''   
 begin  
   
 update #downtime set spare2=(select distinct result from dbo.tests tt with (nolock)   
 join dbo.variables vv with (nolock) on vv.var_id = tt.var_id   
 and vv.extended_info like @showvar2  
 and tt.result_on = #downtime.starttime  
 and vv.pu_id=#downtime.puid)  
   
 end   
  
select @strsql='Select starttime,endtime,downtime,uptime,location,fault,reason1,reason2,split'  
  
if @showmasterprodunit =1  
 select @strsql=@strsql+',MasterProdUnit'  
if @showReason3 =1  
 select @strsql=@strsql+',Reason3'  
if @showReason4 =1  
 select @strsql=@strsql+',Reason4'  
if @showTeam =1  
 select @strsql=@strsql+',team'  
if @showShift =1  
 select @strsql=@strsql+ ',shift'  
if @showComment =1  
 select @strsql=@strsql+ ',comments'  
if @showProduct =1  
 select @strsql=@strsql+ ',product'  
if @showBrandCode=1  
 select @strsql=@strsql+ ',brand'  
if @showCat1 =1  
 select @strsql=@strsql+ ',cat1'  
if @showCat2 =1  
 select @strsql=@strsql+ ',Cat2'  
if @showCat3 =1  
 select @strsql=@strsql+ ',cat3'  
if @showCat4 =1  
 select @strsql=@strsql+ ',cat4'  
if @showvar1<>''   
 select @strsql = @strsql + ',spare1 as [' + @showvar1 + ']'  
if @showvar2<>''   
 select @strsql = @strsql + ',spare2 as [' + @showvar2 + ']'  
  
select @strsql=@strsql+' from dbo.#downtime with (nolock) order by starttime, ENDTIME'  
  
print @strsql  
  
exec (@strsql)  
  
  
GOTO Finished  
  
  
ErrorMessagesWrite:  
-------------------------------------------------------------------------------  
-- Error Messages.  
-------------------------------------------------------------------------------  
 SELECT ErrMsg  
  FROM dbo.#ErrorMessages with (nolock)  
  
Finished:  
  
drop table #downtime  
drop table #ErrorMessages  
drop table #schedule_puid  
drop table #days  
  
