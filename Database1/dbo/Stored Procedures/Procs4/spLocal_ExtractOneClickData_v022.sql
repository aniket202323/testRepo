  
  
/*  
StORed Procedure: spLocal_ExtractONeClickData_v022  
AuthOR:   S. Stier (Stier AutomatiON)  
Date Created:  10/01/02  
  
DescriptiON:  
=========  
Returns Downtime data fOR the ONe Click tool.  
  
VersiON Date  Who What  
======= ======== === =====================================================================  
V0.0.1 10/01/02 SLS Initial Design  
V0.0.2 10/02/02 SLS UPDATEs fOR categories  
V0.0.2 10/04/02 SLS Changed Occurnaces to STOPs  
V0.0.3 10/09/02 SLS Added All Inputs  
V0.0.4 10/09/02 SLS Added All Inputs  
V0.0.5 10/09/02 SLS ISsue to K. Rafferty  
V0.0.7 10/10/02 SLS Added interval Chart Capability  
V0.0.8 10/11/02 SLS ISsue to Kim AND Bunch of Fixes  
V0.0.9 10/29/02 SLS ISsue to Kim AND fixed shift AND Team Duplicate returns  
V0.0.9 11/01/02 SLS Eliminate duplicate downtime WHERE multiple comments added to a recORd  
v0.1.0 02/28/03 SLS multiple lines, optiONal columns  
v0.1.1 03/14/03 SLS changes to uptime UPDATE  
v0.1.2 03/14/03 SLS ISsue fOR Release V0.1.2  
v0.1.2 03/26/03 SLS fix team/shift change uptime to be indepENDant of puid  
v0.1.2 04/02/03 SLS modiIFed split recORd  
V0.1.3  06/04/03  SLS     fixed bad uptime calcs  
V0.1.3 11/21/03 sls used Local_Timed_Event_categories instead of looking up FROM reason tree  
V0.1.3  03/05/04  SLS     Fixed category Assignment  
Rev1.4 09/09/05  FLD Changed name to spLocal_ExtractONeClickData_v018.  
V0.1.5  03/01/06   MAT     Changed ORder of raw data fields to group reasons together  
V0.1.6 02/22/07 MAT Added Beauty/Health Line status field to result SET Also added the capability to report either FamC or BHC reason categories    
V0.1.7  03/01/07 MAT     Added STLS Line Status   
v0.1.8  2007-11-19 FRio :  Fixed the way in wich the report set the Stops splits, it was wrongly including the 0 Uptimes.  
v0.1.9  01/07/09 WCG :   Changed Shift & Brand to integer; Moved Comments field to end of Select statement.  
v0.1.9  01/08/09 WCG :   Changed name to spLocal_ExtractONeClickData_v019; Added Shift & Brand output for parameter=2.  
v0.2.0  02/24/09 JSJ :   Changed the method for pulling ScheduleID, CategoryID, SubsystemID, and GroupCauseID to   
         eliminate the use of Local_Timed_Event_Categories.    
         Added code to populate the Comment field in #Downtimes.  
         added the use of .dbo and "with (nolock)" when accessing data from tables.  
  
v0.2.1  2009/05/20 JSJ :   Added TargetSpeed and ActualSpeed to #downtimes, as well as the updates for   
  Rateloss lines.  
v0.2.2 2009/06/05 MAT :   Added Product Group to result set  
  
*/  
/*  
spLocal_ExtractONeClickData_v019  '2005-7-20 00:00:00', '2005-7-24 00:00:00','MT66 East Wrapper Reliability,MT66 East Wrapper Blocked/Starved',1,1,1,1,1,1,1,1,1,1,1,1  
spLocal_ExtractONeClickData_v019  '2006-02-01 00:00:00 ', '2006-02-06 00:00:00 ','IC L10 MAIN,IC L10 Casepacker Reliability',1,1,1,1,1,1,1,1,1,1,1,1  
*/  
  
CREATE PROCEDURE dbo.spLocal_ExtractOneClickData_v022  
-- DECLARE   
    @InputStartTime   DateTime,  
    @Inputendtime   DateTime,  
    @InputMasterProdUnit nVarChar(4000),  
    @ShowMasterProdUnit  int,  
    @showreason3   int,  
    @showreason4   int,  
    @showTeam    int,  
    @showshift    int,  
    @showComment   int,  
    @showProduct   int,  
    @showbrandCode   int,  
    @showProdGroup   int,  
    @showCat1    int,  
    @showCat2    int,  
    @showCat3    int,  
    @showCat4    int  
AS  
  
/*  
SELECT  
    @InputStartTime   ='2009-01-15',  
    @Inputendtime   ='2009-01-16',  
    @InputMasterProdUnit = 'OTT1 Rate Loss', --'OTT1 Converter Reliability',  
    @ShowMasterProdUnit  =1,  
    @showreason3   =1,  
    @showreason4   =1,  
    @showTeam    =1,  
    @showshift    =1,  
    @showComment   =1,  
    @showProduct   =1,  
    @showProdGroup   =1,  
    @showbrandCode   =1,  
    @showCat1    =1,  
    @showCat2    =1,  
    @showCat3    =1,  
    @showCat4    =1  
*/  
  
-----------------------------------------------------------  
-- Declare program variables.  
-----------------------------------------------------------  
DECLARE @PositiON    int,  
  @InputORderByClause nvarChar(4000),  
  @InputGroupByClause nvarChar(4000),  
  @strSQL    VarChar(4000),  
  @current    datetime,  
  @tmpStartTime as  datetime,  
  @tmpendtime as   datetime,  
  @tmpCount as   int,  
  @tmpLoopCounter   int,  
  @RptProdPUId  int,  
  @ShowLineStatus  int,  
  @CatPrefix    varchar (30)  
------------------------------------------------------------  
---- CREATE  Temp TABLES   ---------------------------------  
------------------------------------------------------------  
Create table #DownTime(      
  DT_ID           int IDENTITY (0, 1) NOT NULL ,  
 StartTime  datetime,  
 endtime   datetime,  
 Uptime   Float,  
 Downtime  Float,  
 MasterProdUnit varchar(100),  
 location  varchar(50),  
 split   varchar(50),  
 Fault   varchar(100),  
 reason1   varchar(100),  
 reason2   varchar(100),  
 reason3   varchar(100),  
 reason4   varchar(100),  
 Team   varchar(25),  
 shift   varchar(25),   
 ishift   INT, -- new field definition added by WCG  
 Cat1   varchar(50),  
 Cat2   varchar(50),  
 Cat3   varchar(50),  
 Cat4   varchar(50),  
 Cat5   varchar(50),  
 Cat6   varchar(50),  
 Cat7   varchar(50),  
 Cat8   varchar(50),  
 Cat9   varchar(50),  
 Cat10   varchar(50),  
 Product   varchar(100),  
 ProductGroup varchar(100),  
 brand   varchar(100),   
 ibrand   INT, -- new field definition added by WCG  
 LineStatus  varchar(100),  
 Cause_Comment_ID  int,  
 Comments  varchar(2000),  
 StartTime_Act datetime,  
 endtime_Act  datetime,  
 endtime_Prev datetime,  
 PUID   INT,  
 SourcePUID  INT,  
 tedet_id  INT,  
 reasonID1  INT,  
 reasonID2  INT,  
 reasonID3  INT,  
 reasonID4  INT,  
 ERTD_ID   int,  
 ErtdID1   INT,  
 ErtdID2   INT,  
 ErtdID3   INT,  
 ErtdID4   INT,  
 SBP    INT,  
 EAP    INT,  
 TargetSpeed  float,  
 ActualSpeed  float  
 )  
  
DECLARE @schedule_puid TABLE  (  
 pu_id    int,   
 schedule_puid  int,   
 tmp1    int,  
 tmp2    int,  
 info    varchar(300))  
  
DECLARE @TESTS TABLE  (  
 var_id   int,  
 result   varchar(100),  
 result_ON   datetime,  
 extendedinfo varchar(255))  
  
  
CREATE INDEX td_PUId_StartTime  
 ON #DownTime (PUId, StartTime)  
CREATE INDEX td_PUId_endtime  
 ON #DownTime (PUId, endtime)  
  
  
DECLARE @ErrORMessages TABLE  (  
 ErrMsg   nVarChar(255) )  
  
  
IF ISDate(@InputStartTime) <> 1  
BEGIN  
 INSERT @ErrORMessages (ErrMsg)  
  VALUES ('StartTime IS not a Date.')  
 GOTO ErrORMessagesWrite  
END  
IF ISDate(@Inputendtime) <> 1  
BEGIN  
 INSERT @ErrORMessages (ErrMsg)  
  VALUES ('endtime IS not a Date.')  
 GOTO ErrORMessagesWrite  
END  
  
----------Populate the #Downtime Table FROM Timed Event Details Table -------------  
IF @showreason3=1 AND @showreason4=1   
insert into #DownTime (StartTime,endtime,MasterProdUnit,Fault,location,PUID,reason1,reason2,reason3,reasonID3  
,reason4,reasonID4,startTime_act,endtime_act,tedet_id,reasonID1,reasonID2,SourcePUID, ERTD_ID, Cause_Comment_ID)  
SELECT ted.start_time, ted.END_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc, ted.pu_ID, r1.event_reason_name,  
r2.event_reason_name,r3.event_reason_name,ted.reason_level3,r4.event_reason_name,ted.reason_level4,  
ted.start_time, ted.END_time, ted.tedet_id,ted.reason_level1, ted.reason_level2,   ted.Source_PU_ID,   
ted.event_reason_tree_data_id, ted.Cause_Comment_ID  
FROM dbo.timed_event_details AS ted with (nolock)   
LEFT JOIN dbo.event_reasons AS r1 with (nolock) ON (r1.event_reason_id = ted.reason_level1)  
LEFT JOIN dbo.event_reasons AS r2 with (nolock) ON (r2.event_reason_id = ted.reason_level2)  
LEFT JOIN dbo.event_reasons AS r3 with (nolock) ON (r3.event_reason_id = ted.reason_level3)  
LEFT JOIN dbo.event_reasons AS r4 with (nolock) ON (r4.event_reason_id = ted.reason_level4)  
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) ON (pu2.pu_id = ted.pu_id)  
WHERE ( ((Start_time < =  @Inputendtime) AND (END_time > @InputStartTime)) OR ((Start_time < =  @Inputendtime )AND END_time IS NULL) )  
AND ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  )) > 0 OR (@InputMasterProdUnit = 'All'))  
ORder by ted.start_Time,  ted.pu_ID  
  
IF @showreason3=0 AND @showreason4=1  
insert into #DownTime (StartTime,endtime,MasterProdUnit,Fault,location,PUID,reason1,reason2,  
reason4,reasonID4,startTime_act,endtime_act,tedet_id,reasonID1,reasonID2,SourcePUID, ERTD_ID, Cause_Comment_ID)  
SELECT ted.start_time, ted.END_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc, ted.pu_ID, r1.event_reason_name,  
r2.event_reason_name,r4.event_reason_name,ted.reason_level4,  
ted.start_time, ted.END_time, ted.tedet_id,ted.reason_level1, ted.reason_level2,   ted.Source_PU_ID,   
ted.event_reason_tree_data_id, ted.Cause_Comment_ID  
FROM dbo.timed_event_details AS ted with (nolock)   
LEFT JOIN dbo.event_reasons AS r1 with (nolock) ON (r1.event_reason_id = ted.reason_level1)  
LEFT JOIN dbo.event_reasons AS r2 with (nolock) ON (r2.event_reason_id = ted.reason_level2)  
LEFT JOIN dbo.event_reasons AS r4 with (nolock) ON (r4.event_reason_id = ted.reason_level4)  
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) ON (pu2.pu_id = ted.pu_id)  
WHERE ( ((Start_time < =  @Inputendtime) AND (END_time > @InputStartTime)) OR ((Start_time < =  @Inputendtime )AND END_time IS NULL) )  
AND ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  )) > 0 OR (@InputMasterProdUnit = 'All'))  
ORder by ted.start_Time,  ted.pu_ID  
  
IF @showreason4=0 AND @showreason3=1  
insert into #DownTime (StartTime,endtime,MasterProdUnit,Fault,location,PUID,reason1,reason2,  
reason3,reasonID3,startTime_act,endtime_act,tedet_id,reasonID1,reasonID2,SourcePUID, ERTD_ID, Cause_Comment_ID)  
SELECT ted.start_time, ted.END_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc, ted.pu_ID, r1.event_reason_name,  
r2.event_reason_name,r3.event_reason_name,ted.reason_level3,  
ted.start_time, ted.END_time, ted.tedet_id,ted.reason_level1, ted.reason_level2,   ted.Source_PU_ID,   
ted.event_reason_tree_data_id, ted.Cause_Comment_ID  
FROM dbo.timed_event_details AS ted with (nolock)   
LEFT JOIN dbo.event_reasons AS r1 with (nolock) ON (r1.event_reason_id = ted.reason_level1)  
LEFT JOIN dbo.event_reasons AS r2 with (nolock) ON (r2.event_reason_id = ted.reason_level2)  
LEFT JOIN dbo.event_reasons AS r3 with (nolock) ON (r3.event_reason_id = ted.reason_level3)  
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) ON (pu2.pu_id = ted.pu_id)  
WHERE ( ((Start_time < =  @Inputendtime) AND (END_time > @InputStartTime)) OR ((Start_time < =  @Inputendtime )AND END_time IS NULL) )  
AND ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  )) > 0 OR (@InputMasterProdUnit = 'All'))  
ORder by ted.start_Time,  ted.pu_ID  
  
IF @showreason4=0 AND @showreason3=0  
insert into #DownTime (StartTime,endtime,MasterProdUnit,Fault,location,PUID,reason1,reason2,  
startTime_act,endtime_act,tedet_id,reasonID1,reasonID2,SourcePUID, ERTD_ID, Cause_Comment_ID)  
SELECT ted.start_time, ted.END_time, Pu2.pu_desc, tef.tefault_name, Pu.pu_desc, ted.pu_ID, r1.event_reason_name,  
r2.event_reason_name,  
ted.start_time, ted.END_time, ted.tedet_id,ted.reason_level1, ted.reason_level2,   ted.Source_PU_ID,   
ted.event_reason_tree_data_id, ted.Cause_Comment_ID  
FROM dbo.timed_event_details AS ted with (nolock)   
LEFT JOIN dbo.event_reasons AS r1 with (nolock) ON (r1.event_reason_id = ted.reason_level1)  
LEFT JOIN dbo.event_reasons AS r2 with (nolock) ON (r2.event_reason_id = ted.reason_level2)  
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) ON (pu2.pu_id = ted.pu_id)  
WHERE ( ((Start_time < =  @Inputendtime) AND (END_time > @InputStartTime)) OR ((Start_time < =  @Inputendtime )AND END_time IS NULL) )  
AND ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  )) > 0 OR (@InputMasterProdUnit = 'All'))  
ORder by ted.start_Time,  ted.pu_ID  
  
-- UPDATE #DOWNTIME SET COMMENTS = (SELECT TOP 1 CAST(wtc.Comment_Text AS VARCHAR(255)) FROM waste_n_timed_comments AS wtc WHERE wtc.wtc_source_id = #DOWNTIME.tedet_id)  
-- IF @showcomment=1  
-- UPDATE #DOWNTIME SET COMMENTS = (  
-- SELECT TOP 1 CAST(wtc.Comment_Text AS VARCHAR(255)) FROM waste_n_timed_comments AS wtc  
--  WHERE wtc.wtc_source_id = #DOWNTIME.tedet_id AND wtc.timestamp=(  
-- SELECT max(wtc2.timestamp) FROM waste_n_timed_comments wtc2 WHERE wtc.wtc_source_id=wtc2.wtc_source_id))  
IF @showcomment=1  
update ted set  
 comments = REPLACE(coalesce(convert(varchar(2000),co.comment_text),''), char(13)+char(10), ' ')  
from dbo.#Downtime ted with (nolock)  
left join dbo.Comments co with (nolock)  
on ted.cause_comment_id = co.comment_id  
  
  
/*  
----IF the downtime event started befORe the period then change the starttime to the period start AND SET SBP (Downtime Started befORe period)--  
UPDATE #downtime SET starttime=@InputStartTime,  
  SBP = 1  
 WHERE starttime<@InputStartTime  
  
  
----IF the downtime event ENDed after the repORt period then change the ENDttime to the period endtime AND SET EAP (Downtime ENDed After period)--  
  
UPDATE #downtime SET endtime=@Inputendtime,  
  EAP = 1  
  WHERE endtime>@Inputendtime   
  
*/  
----------SET Downtime -------------  
  
UPDATE #downtime SET Downtime = datedIFf(s,starttime,endtime)/60.0  
  
----IF there IS in no endtime (which should mean that the recORd IS still open (downtime IS still active) aussume that the endtime of the event IS  
  
UPDATE #downtime SET Downtime = datedIFf(s,starttime,@Inputendtime)/60.0  
 WHERE endtime IS NULL  
  
  
  
----------get Valid Crew Schedule fOR the time Period in QuestiON -------------  
  
IF @showteam=1 OR @showshift=1  
  
 BEGIN  
  
 insert into @schedule_puid (pu_id,info) SELECT pu_id,extended_info FROM dbo.prod_units with (nolock)   
 WHERE (charindex(','+pu_desc+',',','+@inputmasterprodunit+',')>0 OR @inputmasterprodunit='All')  
  
 UPDATE @schedule_puid SET tmp1=charindex('scheduleunit=',info)  
   
 UPDATE @schedule_puid SET tmp2=charindex(';',info,tmp1) WHERE tmp1>0  
  
 UPDATE @schedule_puid SET schedule_puid=cast(substring(info,tmp1+13,tmp2-tmp1-13) as int) WHERE tmp1>0 AND tmp2>0 AND not tmp2 IS NULL  
  
 UPDATE @schedule_puid SET schedule_puid=cast(substring(info,tmp1+13,len(info)-tmp1-12) as int)WHERE tmp1>0 AND tmp2=0  
  
 UPDATE @schedule_puid SET schedule_puid=pu_id WHERE schedule_puid IS NULL  
  
 END  
----------SET Team -------------  
  
IF @showteam=1  
UPDATE #downtime SET team=( SELECT  crew_desc FROM dbo.crew_schedule cs with (nolock)   
join @schedule_puid sp ON cs.pu_id=sp.schedule_puid  
 WHERE #downtime.starttime>=cs.start_time AND cs.END_time>#downtime.starttime AND #downtime.puid=sp.pu_id)  
/*  
UPDATE #downtime SET team=( SELECT  crew_desc FROM crew_schedule cs join @schedule_puid sp ON cs.pu_id=sp.pu_id  
 WHERE #downtime.starttime>=cs.start_time AND cs.END_time>#downtime.starttime AND #downtime.puid=sp.pu_id)  
UPDATE #downtime SET shift=( SELECT  shift_desc FROM crew_schedule cs join @schedule_puid sp ON cs.pu_id=sp.pu_id WHERE #downtime.starttime>=cs.start_time AND cs.END_time>#downtime.starttime AND #downtime.puid=sp.pu_id)  
*/  
----------SET shift -------------  
IF @showshift=1  
UPDATE #downtime SET shift=( SELECT  shift_desc FROM dbo.crew_schedule cs with (nolock)   
join @schedule_puid sp ON cs.pu_id=sp.schedule_puid  
 WHERE #downtime.starttime>=cs.start_time AND cs.END_time>#downtime.starttime AND #downtime.puid=sp.pu_id)  
  
  
  
  
----------SET Product -------------  
IF @showproduct=1  
UPDATE #DownTime SET product=(  
 SELECT p.Prod_Desc FROM dbo.products p with (nolock)   
 join dbo.production_starts ps with (nolock) ON ps.prod_id= p.prod_id   
 join dbo.prod_units with (nolock) ON ps.pu_id=prod_units.pu_id WHERE ps.start_time <= #downtime.starttime  
 AND ((#downtime.starttime < ps.END_time) OR (ps.END_time IS NULL)) AND ps.pu_id=#downtime.puid)  
IF @showbrandcode=1  
UPDATE #DownTime SET brand=(  
 SELECT p.prod_code FROM dbo.products p with (nolock) join dbo.production_starts ps with (nolock) ON ps.prod_id= p.prod_id   
 join dbo.prod_units with (nolock) ON ps.pu_id=prod_units.pu_id WHERE ps.start_time <= #downtime.starttime  
 AND ((#downtime.starttime < ps.END_time) OR (ps.END_time IS NULL)) AND ps.pu_id=#downtime.puid)  
  
----------SET Product Group-------------  
-- Get product groups looking first for "package size" groups  
update #DownTime set ProductGroup = (  
 select top 1 product_grp_desc from product_groups pg  
 join product_group_data pgd on pgd.Product_Grp_Id = pg.Product_Grp_Id  
 join products p on pgd.Prod_Id = p.Prod_Id  
 join comments c ON pg.comment_id = c.comment_id  
 where p.prod_code = #downtime.brand  
 AND c.comment_text Like '%Package Size%')  
  
update #DownTime set ProductGroup = (  
 select top 1 product_grp_desc from product_groups pg  
 join product_group_data pgd on pgd.Product_Grp_Id = pg.Product_Grp_Id  
 join products p on pgd.Prod_Id = p.Prod_Id  
 where p.prod_code = #downtime.brand)  
WHERE ProductGroup is null  
  
-- *******************************************************  
-- Add Line Status if it exists.  Check for Line status   
-- variable first, then check local_pg_line_status  
-- *******************************************************  
  
--Use local_pg_line_status table if data is available  
IF (SELECT TOP 1 pu_id FROM dbo.prod_units pu with (nolock)  
 JOIN dbo.local_pg_line_status ls with (nolock) ON pu.pu_id=ls.unit_id  
 WHERE PL_ID = (SELECT DISTINCT PL_Id FROM dbo.prod_units with (nolock)   
     WHERE (charindex(','+pu_desc+',',','+@inputmasterprodunit+',')>0 OR @inputmasterprodunit='All')))   
IS NOT NULL  
BEGIN  
  
SELECT @RptProdPUId = (SELECT TOP 1 pu_id FROM dbo.prod_units pu with (nolock)  
JOIN dbo.local_pg_line_status ls with (nolock) ON pu.pu_id=ls.unit_id  
WHERE PL_ID = (SELECT DISTINCT PL_Id FROM dbo.prod_units with (nolock)   
    WHERE (charindex(','+pu_desc+',',','+@inputmasterprodunit+',')>0 OR @inputmasterprodunit='All')))  
  
--Add line status from local_pg_line_status table  
UPDATE #DownTime SET LineStatus=(  
 SELECT p.phrase_value FROM dbo.phrase p with (nolock)   
 JOIN dbo.local_pg_line_status ls with (nolock) ON ls.line_status_id = p.phrase_id   
 JOIN dbo.prod_units pu with (nolock) ON pu.pu_id=ls.unit_id WHERE ls.start_datetime <= #downtime.starttime  
 AND ((#downtime.starttime < ls.end_datetime) OR (ls.end_datetime IS NULL)) AND ls.unit_id=@RptProdPUId)  
END  
  
-- Look for Line status in a variable if it's not in local_pg_line_status  
IF (SELECT TOP 1 pu_id FROM dbo.prod_units pu with (nolock)  
 JOIN dbo.local_pg_line_status ls with (nolock) ON pu.pu_id=ls.unit_id  
 WHERE PL_ID = (SELECT DISTINCT PL_Id FROM dbo.prod_units with (nolock)   
     WHERE (charindex(','+pu_desc+',',','+@inputmasterprodunit+',')>0 OR @inputmasterprodunit='All')))  
IS NULL  
BEGIN  
SELECT @RptProdPUId = (SELECT TOP 1 pu_id FROM dbo.prod_units with (nolock)   
WHERE PL_ID = (SELECT DISTINCT PL_Id FROM dbo.prod_units with (nolock)   
     WHERE (charindex(','+pu_desc+',',','+@inputmasterprodunit+',')>0 OR @inputmasterprodunit='All'))  
AND charindex('production=true', extended_info) > 0)  
  
--- make temporary tests table  
INSERT @TESTS (var_id, extendedinfo, result_ON, result)  
SELECT vv.var_id, vv.extended_info, result_ON, result FROM dbo.tests tt with (nolock)  
JOIN dbo.variables vv with (nolock) ON vv.var_id = tt.var_id   
 AND (charindex('rpthook=productionstatus', vv.extended_info)>0)   
-- OR charindex('rpthook=starttime', vv.extended_info)>0   
-- OR charindex('rpthook=team', vv.extended_info)>0   
-- OR charindex('rpthook=shift', vv.extended_info)>0)  
JOIN dbo.prod_units pu with (nolock) ON pu.pu_id = vv.pu_id AND pu.pu_id = @RPTProdPUId  
WHERE tt.result_ON <= @inputendtime+1 AND tt.result_ON > @inputstarttime-1  
  
-- Add production status to downtime data  
UPDATE #downtime SET LineStatus = (  
 SELECT TOP 1 result FROM @tests tt   
 JOIN dbo.prod_units pu with (nolock) ON pu.pu_id = @RPTProdPUId  
 WHERE charindex('rpthook=productionstatus', tt.extendedinfo)>0  
 AND tt.result_ON > #downtime.starttime   
 ORDER BY tt.result_ON)  
END  
  
  
----------Get Event reason tree data IDs fOR each reason-------------  
IF @showcat1=1  
UPDATE #downtime SET ErtdID1=(  
SELECT  ertd.Event_reason_tree_data_id FROM   
dbo.Prod_events pe with (nolock)  
join dbo.event_reason_tree_data ertd with (nolock) ON ertd.tree_name_id=pe.Name_id   
WHERE ertd.event_reason_level=1  
AND #downtime.SourcePUID=pe.pu_id   
AND ertd.event_reason_id=#downtime.reasonid1  
AND pe.Event_type = 2)WHERE #downtime.reasonid1 IS NOT NULL  
  
IF @showcat2=1  
UPDATE #downtime SET ErtdID2=(  
SELECT  ertd.Event_reason_tree_data_id FROM   
dbo.Prod_events pe with (nolock)  
join dbo.event_reason_tree_data ertd with (nolock) ON ertd.tree_name_id=pe.Name_id   
WHERE ertd.event_reason_level=2  
AND #downtime.SourcePUID=pe.pu_id   
AND ertd.event_reason_id=#downtime.reasonid2  
AND ertd.Parent_Event_reason_id=#downtime.reasonid1  
AND pe.Event_type = 2)WHERE #downtime.reasonid2 IS NOT NULL  
  
IF @showcat3=1  
UPDATE #downtime SET ErtdID3=(  
SELECT  ertd.Event_reason_tree_data_id FROM   
dbo.Prod_events pe with (nolock)  
join dbo.event_reason_tree_data ertd with (nolock) ON ertd.tree_name_id=pe.Name_id   
join dbo.event_reason_tree_data ertd1 with (nolock) ON ertd1.Event_reason_tree_data_id = ertd.Parent_Event_R_Tree_Data_Id  
WHERE ertd.event_reason_level=3  
AND #downtime.SourcePUID=pe.pu_id   
AND ertd.event_reason_id=#downtime.reasonid3   
AND ertd.Parent_Event_reason_id=#downtime.reasonid2  
AND ertd1.Parent_Event_reason_id=#downtime.reasonid1  
AND pe.Event_type = 2  
)WHERE #downtime.reasonid3 IS NOT NULL  
  
IF @showcat4=1  
UPDATE #downtime SET ErtdID4=(  
SELECT  ertd.Event_reason_tree_data_id FROM   
dbo.Prod_events pe with (nolock)  
join dbo.event_reason_tree_data ertd with (nolock) ON ertd.tree_name_id=pe.Name_id  
join dbo.event_reason_tree_data ertd1 with (nolock) ON ertd1.Event_reason_tree_data_id = ertd.Parent_Event_R_Tree_Data_Id  
join dbo.event_reason_tree_data ertd2 with (nolock) ON ertd2.Event_reason_tree_data_id = ertd1.Parent_Event_R_Tree_Data_Id  
WHERE ertd.event_reason_level=4  
AND #downtime.SourcePUID=pe.pu_id   
AND ertd.event_reason_id=#downtime.reasonid4  
AND ertd.Parent_Event_reason_id=#downtime.reasonid3  
AND ertd1.Parent_Event_reason_id=#downtime.reasonid2  
AND ertd2.Parent_Event_reason_id=#downtime.reasonid1  
AND pe.Event_type = 2  
)WHERE #downtime.reasonid4 IS NOT NULL  
  
--Apply Beauty/Health reason categories if they exist  
IF (SELECT count(erc_id) FROM dbo.event_reason_catagories with (nolock)   
WHERE charindex('DTSched', erc_desc) > 0  
OR charindex('DTGroup', erc_desc) > 0  
OR charindex('DTMach', erc_desc) > 0) > 5  
BEGIN  
IF @showcat1=1  
 BEGIN  
 SELECT @CatPrefix='DTSched-'  
 UPDATE #downtime SET Cat1=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID4 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat1 IS NULL AND #downtime.ErtdID4 IS NOT NULL  
   
 UPDATE #downtime SET Cat1=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID3 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat1 IS NULL AND #downtime.ErtdID3 IS NOT NULL  
   
 UPDATE #downtime SET Cat1=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID2 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat1 IS NULL AND #downtime.ErtdID2 IS NOT NULL  
   
 UPDATE #downtime SET Cat1=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID1 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat1 IS NULL AND #downtime.ErtdID1 IS NOT NULL  
 END  
  
IF @showcat2=1  
 BEGIN  
 SELECT @CatPrefix='DTGroup-'  
   
 UPDATE #downtime SET Cat2=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID4 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat2 IS NULL AND #downtime.ErtdID4 IS NOT NULL  
   
 UPDATE #downtime SET Cat2=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID3 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat2 IS NULL AND #downtime.ErtdID3 IS NOT NULL  
   
 UPDATE #downtime SET Cat2=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID2 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat2 IS NULL AND #downtime.ErtdID2 IS NOT NULL  
   
 UPDATE #downtime SET Cat2=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID1 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat2 IS NULL AND #downtime.ErtdID1 IS NOT NULL  
 END  
  
IF @showcat3=1  
 BEGIN  
 SELECT @CatPrefix='DTMach-'  
 UPDATE #downtime SET Cat3=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID4 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat3 IS NULL AND #downtime.ErtdID4 IS NOT NULL  
   
 UPDATE #downtime SET Cat3=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID3 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat3 IS NULL AND #downtime.ErtdID3 IS NOT NULL  
   
 UPDATE #downtime SET Cat3=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID2 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat3 IS NULL AND #downtime.ErtdID2 IS NOT NULL  
   
 UPDATE #downtime SET Cat3=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID1 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat3 IS NULL AND #downtime.ErtdID1 IS NOT NULL  
 END  
  
IF @showcat4=1  
 BEGIN  
 SELECT @CatPrefix='DTType-'  
 UPDATE #downtime SET Cat4=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID4 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat4 IS NULL AND #downtime.ErtdID4 IS NOT NULL  
   
 UPDATE #downtime SET Cat4=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID3 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat4 IS NULL AND #downtime.ErtdID3 IS NOT NULL  
   
 UPDATE #downtime SET Cat4=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID2 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat4 IS NULL AND #downtime.ErtdID2 IS NOT NULL  
   
 UPDATE #downtime SET Cat4=(  
 SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
 dbo.event_reason_catagories erc with (nolock)  
 join dbo.event_reason_category_data ercd with (nolock) ON ercd.erc_id =  erc.erc_id  
 WHERE ercd.Event_reason_tree_data_id = #downtime.ErtdID1 AND (charindex(lower(@CatPrefix),erc_desc)>0)   
 AND ercd.Propegated_FROM_etDid IS NULL  
 )WHERE #downtime.Cat4 IS NULL AND #downtime.ErtdID1 IS NOT NULL  
 END  
  
END  
  
  
--Apply Family Care reason categories if they exist  
IF (SELECT count(erc_id) FROM dbo.event_reason_catagories with (nolock)   
WHERE charindex('category:', erc_desc) > 0  
OR charindex('Schedule:', erc_desc) > 0  
OR charindex('Subsystem:', erc_desc) > 0  
OR charindex('GroupCause:', erc_desc) > 0) > 5  
BEGIN  
  
----------SET Category -------------  
  
IF @showcat1=1  
 BEGIN  
 SELECT @CatPrefix='category:'  
-- UPDATE #downtime SET Cat1=(  
--                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
--                          event_reason_catagories erc  
--                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
--                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
--                           )  
  
 UPDATE td SET  
  Cat1 = right(erc_desc,len(erc_desc)-len(@CatPrefix))  
 FROM dbo.#downtime td with (nolock)  
 JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
 ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
 JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
 ON ercd.erc_id = erc.erc_id   
 where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
 END  
  
  
----------SET Schedule -------------  
  
IF @showcat2=1  
 BEGIN  
   SELECT @CatPrefix='Schedule:'  
-- UPDATE #downtime SET Cat2=(  
--                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
--                          event_reason_catagories erc  
--                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
--                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
--                           )  
  
 UPDATE td SET  
  Cat2 = right(erc_desc,len(erc_desc)-len(@CatPrefix))  
 FROM dbo.#downtime td with (nolock)  
 JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
 ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
 JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
 ON ercd.erc_id = erc.erc_id   
 where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
 END  
  
  
----------SET Subsystem -------------  
  
IF @showcat3=1  
 BEGIN  
 SELECT @CatPrefix='Subsystem:'  
-- UPDATE #downtime SET Cat3=(  
--                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
--                          event_reason_catagories erc  
--                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
--                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
--                           )  
  
 UPDATE td SET  
  Cat3 = right(erc_desc,len(erc_desc)-len(@CatPrefix))  
 FROM dbo.#downtime td with (nolock)  
 JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
 ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
 JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
 ON ercd.erc_id = erc.erc_id   
 where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
 END  
  
  
----------SET GroupCause -------------  
  
IF @showcat4=1  
 BEGIN  
  
 SELECT @CatPrefix='GroupCause:'  
-- UPDATE #downtime SET Cat4=(  
--                    SELECT  TOP 1 right(erc_desc,len(erc_desc)-len(@CatPrefix)) FROM   
--                          event_reason_catagories erc  
--                             join Local_Timed_Event_categories ltec ON ltec.erc_id =  erc.erc_id  
--                          WHERE  ltec.tedet_id = #downtime.Tedet_id AND (charindex(lower(@CatPrefix),erc_desc)>0)   
--                           )  
  
 UPDATE td SET  
  Cat4 = right(erc_desc,len(erc_desc)-len(@CatPrefix))  
 FROM dbo.#downtime td with (nolock)  
 JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
 ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
 JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
 ON ercd.erc_id = erc.erc_id   
 where erc.ERC_Desc LIKE @CatPrefix + '%'  
  
 END  
  
END  
  
  
---------------------------------------------------------------------------------------------------  
-- Check Parameter: Database version  
---------------------------------------------------------------------------------------------------  
DECLARE   
   @fltDBVersion  FLOAT  
  
IF ( SELECT  IsNumeric(App_Version)  
   FROM dbo.AppVersions with (nolock)  
   WHERE App_Id = 2) = 1  
BEGIN  
 SELECT  @fltDBVersion = Convert(Float, App_Version)  
  FROM dbo.AppVersions with (nolock)  
  WHERE App_Id = 2  
END  
ELSE  
BEGIN  
 SELECT @fltDBVersion = 1.0  
END  
  
DECLARE   
  @DowntimesystemUserID  INT  
  
Select @DowntimesystemUserID =   
 User_ID  
 FROM dbo.USERS with (nolock)  
 WHERE UserName = 'ReliabilitySystem'  
  
IF @fltDBVersion <= 300172.90   
BEGIN  
  UPDATE #Downtime  
    Set Split = 'S'  
  FROM dbo.#Downtime tdt with (nolock)  
  Join dbo.Timed_Event_Detail_History ted with (nolock) on tdt.TeDet_Id = ted.TEDET_ID   
  and ted.User_ID = '2'   
  WHERE ted.TEDET_ID IS NOT Null  
     And tdt.Split IS Null  
  
  -- UPDATE #Downtime  
  --   Set IsStops = 0  
  -- FROM #Downtime tdt  
  -- WHERE (tdt.Action_Level1 Is Null or tdt.Action_Level1 = 0)  
    
END  
ELSE   
BEGIN      
  
  UPDATE #Downtime  
    Set Split = ISNULL((Select Case WHEN Min(User_Id) < 50  
          THEN 'P'  
          WHEN Min(User_Id) = @DowntimeSystemUserID  
          THEN 'P'  
          ELSE 'S'  
        END  
        FROM dbo.Timed_Event_Detail_History with (nolock)   
        WHERE Tedet_Id = ted.TEDET_ID   
        ),'S')  
  FROM dbo.#Downtime tdt with (nolock)  
  Left Join dbo.Timed_Event_Detail_History ted with (nolock) on tdt.TEDet_ID = ted.TEDET_ID  
  
  UPDATE #Downtime  
    Set Split = 'P'  
  FROM dbo.#Downtime tdt with (nolock)  
  Join dbo.Timed_Event_Detail_History tedh with (nolock) on tdt.TEDet_ID = tedh.TEDET_ID  
  WHERE tedh.User_ID = @DowntimeSystemUserID  
     And tdt.Downtime <> 0  
  
END  
  
UPDATE #Downtime  
 SET Split = NULL  
FROM dbo.#Downtime dd with (nolock)  
JOIN (SELECT d.tedet_id,d.PUID,EndTime   
 FROM dbo.#Downtime d with (nolock)  
 JOIN (SELECT PUID,StartTime FROM dbo.#Downtime with (nolock) WHERE Split = 'S') d2 ON d.PUID = d2.PUID AND d.EndTime = d2.StartTime  
 WHERE Split = 'P') dd2 ON dd.tedet_id <> dd2.tedet_id  
WHERE dd.Split = 'P'  
  
-- UPDATE #downtime SET Split = ''    
-- WHERE StartTime  <> (SELECT MAX(EndTime) FROM #Downtime dt2 WHERE dt2.puid=#downtime.puid AND dt2.endtime<#downtime.endtime)  
  
-- UPDATE #downtime SET split="P"  WHERE endtime=(SELECT min(starttime) FROM #downtime dt2 WHERE dt2.puid=#downtime.puid AND   
-- dt2.starttime>#downtime.starttime) AND split IS NULL  
  
--UPDATE #downtime SET uptime=datedIFf(s,(  
--SELECT max(dt2.endtime) FROM #downtime dt2 WHERE ((dt2.starttime<=#downtime.starttime) AND ( dt2.tedet_id <> #downtime.tedet_id)) -- AND dt2.puid=#downtime.puid -- 3/26/03  
--),starttime)/60.0  
  
UPDATE #downtime SET uptime=datedIFf(s,(  
SELECT TOP 1 dt2.endtime FROM dbo.#downtime dt2 with (nolock) WHERE ((dt2.DT_ID=(#downtime.DT_ID - 1)))),starttime)/60.0  
WHERE #downtime.DT_ID > 0  
  
-- FRIO Testing  
-- SELECT Split,TeDet_Id,* FROM #Downtime  
  
---- added ON 3/26/03 -- get last uptime independent of puid as long as a puid in master list  
UPDATE #downtime SET uptime=datedIFf(s,(  
SELECT max(dt2.END_time) FROM dbo.timed_event_details dt2 with (nolock)   
join dbo.prod_units pu2 with (nolock) ON pu2.pu_id=dt2.pu_id  
WHERE  END_time<=#downtime.starttime -- AND dt2.puid=#downtime.puid -- 3/26/03  
AND ((CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  )) > 0 OR (@InputMasterProdUnit = 'All'))  
),starttime)/60.0 WHERE uptime IS NULL  
  
  
--UPDATE #downtime SET uptime=datedIFf(s,@inputstarttime,starttime)/60.0 WHERE uptime IS NULL  
  
declare @preEND datetime  
  
SELECT @preEND = max(END_time)  
FROM dbo.timed_event_details ted with (nolock)   
LEFT JOIN dbo.timed_event_fault AS tef with (nolock) ON (tef.tefault_id = ted.tefault_id)  
LEFT Join dbo.prod_units AS pu with (nolock) ON (pu.pu_id = ted.source_PU_Id)  
inner join dbo.prod_units as pu2 with (nolock) ON (pu2.pu_id = ted.pu_id)  
WHERE  (END_time <= @InputStartTime) --OR (Start_time <=  @Inputendtime AND END_time IS NULL) )  
AND (CHARINDEX( ','+pu2.pu_desc+','  ,  ','+ @InputMasterProdUnit+','  ) > 0 OR (@InputMasterProdUnit = 'All'))  
  
UPDATE #downtime SET uptime=datedIFf(s,@preEND,starttime)/60.0   
WHERE uptime IS NULL  
  
  
--v0.2.1  
--RATE LOSS --------------------------------------------------------------------------------  
---------------------------------------------------------------------------------------------  
  
IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[fnLocal_GlblParseInfo]'))  
BEGIN  
  
      IF EXISTS (SELECT PU_ID from prod_units where charindex('RateLoss', extended_info) > 0)  
      BEGIN  
  
            update #downtime set targetspeed = (  
                  select result from tests tt  
                  join variables vv on vv.var_id = tt.var_id  
                        and vv.pu_id = #downtime.puid  
                        --and var_desc = 'line target speed'  
                        and dbo.fnLocal_GlblParseInfo(vv.Extended_Info, 'GlblDesc=') LIKE '%' + replace('Line Target Speed',' ','')  
                  where tt.result_on = #downtime.starttime)    
  
            update #downtime set actualspeed = (  
                  select result from tests tt  
                  join variables vv on vv.var_id = tt.var_id  
                        and vv.pu_id = #downtime.puid  
                        --and var_desc = 'line actual speed'  
                        and dbo.fnLocal_GlblParseInfo(vv.Extended_Info, 'GlblDesc=') LIKE '%' + replace('Line Actual Speed',' ','')  
                  where tt.result_on = #downtime.starttime)    
  
  
      --Calculate Effective Downtime and add to the Downtime colum  
            update #downtime set downtime = (targetspeed - actualspeed) * downtime / targetspeed--,  
                  /*  Remove Failure Type from Rate loss events */  
                  --Failuretype = null  
                  where targetspeed is not null   
  
      END  
END  
  
---------------------------------------------------------------------------------------------  
  
  
-- Initialize @ShowLineStatus to ONe IF it exISts.  Remove thIS line IF @ShowLineStatus becomes a parameter  
IF (SELECT COUNT(LineStatus) FROM dbo.#Downtime with (nolock)) > 0   
BEGIN  
 SELECT @ShowLineStatus = 1  
END  
  
-- Set the integer values for Shift and Brand  (WCG)  
Update #DownTime  
set iBrand=cast(Brand as INT)  
where IsNumeric(Brand)=1  
  
Update #DownTime  
set iShift=cast(Shift as INT)  
where IsNumeric(Shift)=1  
-- End of added section (WCG)  
  
-- OUTPUT  
SELECT @strsql='SELECT starttime,endtime,downtime,uptime,location,fault,reason1,reason2,split'  
  
IF @showreason3 =1  
 SELECT @strsql='SELECT starttime,endtime,downtime,uptime,location,fault,reason1,reason2,reason3,split'  
IF @showreason4 =1  
 SELECT @strsql='SELECT starttime,endtime,downtime,uptime,location,fault,reason1,reason2,reason3,reason4,split'  
IF @showmasterprodunit =1  
 SELECT @strsql=@strsql+',MasterProdUnit'  
IF @showTeam =1  
 SELECT @strsql=@strsql+',team'  
IF @showshift =1  
 SELECT @strsql=@strsql+ ',ishift' --changed to integervalue by WCG  
IF @showshift =2                        -- Added by WCG  
 SELECT @strsql=@strsql+ ',shift'  -- Added by WCG  
-- IF @showComment =1                  -- Moved to below by WCG  
-- SELECT @strsql=@strsql+ ',comments' -- Moved to below by WCG  
IF @showProduct =1  
 SELECT @strsql=@strsql+ ',product'  
IF @showbrandCode=1  
 SELECT @strsql=@strsql+ ',ibrand' --changed to integervalue by WCG  
IF @showbrandCode=2                       -- Added by WCG   
 SELECT @strsql=@strsql+ ',brand'  -- Added by WCG  
IF @showProdGroup = 1  
 SELECT @strsql=@strsql+ ',ProductGroup'  
IF @showCat1 =1  
 SELECT @strsql=@strsql+ ',cat1'  
IF @showCat2 =1  
 SELECT @strsql=@strsql+ ',Cat2'  
IF @showCat3 =1  
 SELECT @strsql=@strsql+ ',cat3'  
IF @showCat4 =1  
 SELECT @strsql=@strsql+ ',cat4'  
IF @ShowLineStatus =1  
 SELECT @strsql=@strsql+ ',LineStatus'  
IF @showComment =1   
 SELECT @strsql=@strsql+ ',comments'   
  
SELECT @strsql=@strsql+' FROM dbo.#downtime with (nolock) ORder by starttime'  
  
print @strsql  
  
exec (@strsql)  
  
  
GOTO FinIShed  
  
  
ErrORMessagesWrite:  
-------------------------------------------------------------------------------  
-- ErrOR Messages.  
-------------------------------------------------------------------------------  
 SELECT ErrMsg  
  FROM @ErrORMessages  
  
FinIShed:  
  
DROP TABLE #Downtime  
  
