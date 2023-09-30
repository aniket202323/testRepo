    /*  
Stored Procedure: spLocal_PE_BCDowntimeRaw_2_1_2  
Author:   J. Jaeger (Stier Automation)  
Date Created:  09/24/03  
  
Description:  
=========  
Returns  Downtime data for Proficy Explorer tool   
  
XLA Version Change Date Who What  
============ =========== ==== =====  
V0.1.5  1/27/04  SLS     Release to B.Barre  
V2.1.0_T 8/9/04  BAS Changed from output formatting of Prod_Date and Starttime columns to support PE VBA Regional Settings format.  
V2.1.2  9/21/04  BAS Renamed sp with XLA version.  
V2.1.3  10/21/04 rm Don't error out if product is not formated for prod/bag  
*/  
  
/*  
spLocal_PE_BCDowntimeRaw_2_1_2  '2004-9-23 00:00:00 ', '2004-9-24 00:00:00 ',  
  'qxae47 converter'  
*/  
  
--/*  
create procedure dbo.spLocal_PE_BCDowntimeRaw_2_1_2  
@InputStartTime DateTime,  
@InputEndTime  DateTime,  
@InputMasterProdUnit nVarChar(4000)=null  
As  
--*/  
  
/*  
-- testing values  
  
declare  
@InputStartTime  DateTime,  
@InputEndTime  DateTime,  
@InputMasterProdUnit nVarChar(4000)  
  
select  
@InputStartTime  = '01/21/03',  
@InputEndTime  = '01/22/03',  
@InputMasterProdUnit = 'STM Plant Converter Reliability'  
*/  
  
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
  @tmpLoopCounter  int  
  
  
------------------------------------------------------------  
---- CREATE  Temp TABLES   ---------------------------------  
------------------------------------------------------------  
  
create table #puid_list(  
 puid  integer,  
 pudesc  varchar(100),  
 plid  integer,  
 pldesc  varchar(100),  
 converter_puid  integer,  
 schedule_puid  integer,   
 tmp1   integer,  
 tmp2   integer,  
 info   varchar(300)  
)  
  
  
Create table #DownTime(      
  DT_ID           int IDENTITY (0, 1) NOT NULL ,  
 StartTime datetime,  
 EndTime  datetime,  
 prod_start datetime,  
 prod_end datetime,  
 Uptime  Float,  
 Downtime Float,  
 MasterProdUnit varchar(100),  
 Location varchar(50),  
 tefault_id integer,  
 plc_cause varchar(100),  
 Reason1  varchar(100),  
 Main_Component_Global_LU varchar(50),  
 Reason2  varchar(100),  
 Reason3  varchar(100),  
 Reason4  varchar(100),  
 Team  varchar(25),  
 Shift  varchar(25),  
 Cause_Comment_ID int,  
 Comment1 varchar(2000),  
 comment2 varchar(255),  
 Endtime_Prev datetime,  
 PUID  INT,  
 SourcePUID INT,  
 tedet_id INT,  
 ReasonID1 INT,  
 ReasonID2 INT,  
 ReasonID3 INT,  
 ReasonID4 INT,  
 Plant  varchar(100),  
 Line  varchar(100),  
 Line_Status varchar(100),  
 Line_Mode varchar(100),  
 Line_Speed float,  
 Tgt_Line_Speed float,  
 Cycles  float,  
 prod_desc varchar(100),  
 Count_Package varchar(100),  
 [Size]  varchar(100),  
 Platform varchar(100),  
 DT_Status varchar(50),  
 Spare1  varchar(255),   
 Spare2  varchar(255),   
 Spare3  varchar(255),  
 Spare4  varchar(255),   
 Spare5  varchar(255),   
 Spare6  varchar(255),   
 Spare7  varchar(255),   
 Spare8  varchar(255),   
 Spare9  varchar(255),   
 Spare10  varchar(255)  
)  
  
  
create  table #variables(  
 var_id  integer,  
 var_desc varchar(50),  
 varpuid  integer  
)   
  
CREATE TABLE #Tests (    
 Result_on Datetime,  
 Result  varchar(50),  
 Product_ID Integer,  
 Var_id  Integer,  
 Var_desc varchar(50),  
 VarPUId  Integer  
)  
  
  
create table #prod_info(  
 prod_desc varchar(300),  
 [size]  varchar(50),  
 platform varchar(50),  
 count_package varchar(50)  
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
  
  
----------Populate the #puid_list table -------------  
  
insert into  #puid_list (puid, pudesc, plid, pldesc, info, tmp1)  
 select  distinct pu.pu_id, pu.pu_desc, pl.pl_id, pl.pl_desc,  
  pu.extended_info,charindex('scheduleunit=',pu.extended_info)   
 from  dbo.prod_units pu with (nolock)    
 join  dbo.prod_lines pl with (nolock) on pu.pl_id = pl.pl_id  
 where  (CHARINDEX( ','+pu_desc+',' , ','+ @InputMasterProdUnit+ ','  ) > 0   
  or  (@InputMasterProdUnit = 'All'))  
   
  
update #puid_list set  
 converter_puid =    
   (  
   select pu_id   
   from dbo.prod_units pu with (nolock)  
   where plid = pu.pl_id  
   and pu_desc like '% Converter'  
   )  
  
  
----------get Valid Crew Schedule for the time Period in Question -------------  
  
update #puid_list set   
 tmp2=charindex(';',info,tmp1)   
where tmp1>0  
  
update #puid_list set   
 schedule_puid = cast(substring(info,tmp1+13,tmp2-tmp1-13) as integer)   
where tmp1>0   
and tmp2>0   
and tmp2 is not null  
  
update #puid_list set   
 schedule_puid = cast(substring(info,tmp1+13,len(info)-tmp1-12) as integer)  
where tmp1>0   
and tmp2=0  
  
update #puid_list set   
 schedule_puid = converter_puid   
where schedule_puid is null  
  
--select * from #puid_list  
  
----------Populate the #Downtime Table from Timed Event Details Table -------------  
insert into #DownTime (StartTime,EndTime,tefault_id,PUID,REASONID1,REASONID2,REASONID3,REASONID4,tedet_id,SourcePUID)  
select ted.start_time, ted.end_time,tefault_id,ted.pu_ID,ted.reason_level1, ted.reason_level2,ted.reason_level3,  
 ted.reason_level4,ted.tedet_id,ted.Source_PU_ID  
FROM dbo.timed_event_details AS ted with (nolock)   
WHERE Start_time < =  @InputEndTime   
and (end_time > @InputStartTime or end_time Is Null)   
and EXISTS(SELECT puid from #puid_list where PU_ID = puid  )  
order by ted.start_Time,  ted.pu_ID  
  
--select * from #downtime  
  
insert into #variables  
 (var_id, var_desc, varpuid)  
select  var_id, var_desc, pu_id  
from dbo.variables with (nolock)  
where  (  
 lower(var_desc) = 'average line speed (actual)'  
 or lower(var_desc) = 'average line speed (target)'  
 or lower(var_desc) = 'total cycles'  
 )  
and  EXISTS(SELECT converter_puid from dbo.#puid_list with (nolock) where PU_ID = puid  )   
  
  
insert into #tests  
 (result_on, result, var_id)  
select  result_on, result, var_id   
from  dbo.tests t with (nolock)  
where  result_on >= @InputStartTime  
AND  result_on < @InputEndTime  
and  EXISTS(SELECT var_id from #variables v where v.var_ID = t.var_id  )   
order by result_on  
  
update #tests set  
 var_desc = v.var_desc,  
 varpuid = v.varpuid  
from dbo.#variables v with (nolock)  
where #tests.var_id = v.var_id  
  
  
CREATE nonclustered INDEX t_PUId_result_on  
 ON #tests (result_on)  
  
  
-- get reason information  
update  #downtime set  
 main_component_global_lu = event_reason_code,  
 Reason1 = event_reason_name  
from  dbo.#downtime dt with (nolock)  
join dbo.event_reasons er with (nolock)  
on  dt.reasonid1 = event_reason_id  
  
update  #downtime set  
 Reason2 = event_reason_name  
from  dbo.#downtime dt with (nolock)  
join dbo.event_reasons er with (nolock)  
on  dt.reasonid2 = event_reason_id  
  
update  #downtime set  
 Reason3 = event_reason_name  
from  dbo.#downtime dt with (nolock)  
join dbo.event_reasons er with (nolock)  
on  dt.reasonid3 = event_reason_id  
  
update  #downtime set  
 Reason4 = event_reason_name  
from  dbo.#downtime dt with (nolock)  
join dbo.event_reasons er with (nolock)  
on  dt.reasonid4 = event_reason_id  
  
update  #downtime set  
 plc_cause = tefault_value  
from  dbo.#downtime dt with (nolock)  
join dbo.timed_event_fault tef with (nolock)  
on dt.tefault_id = tef.tefault_id  
  
update  #downtime set  
 location = pu_desc  
from  dbo.#downtime dt with (nolock)  
join dbo.prod_units pu with (nolock)  
on dt.SourcePuid = pu.pu_id  
  
  
-- UPDATE #DOWNTIME SET COMMENTS = (SELECT TOP 1 CAST(wtc.Comment_Text AS VARCHAR(255)) FROM waste_n_timed_comments AS wtc WHERE wtc.wtc_source_id = #DOWNTIME.tedet_id)  
/*  
UPDATE  #DOWNTIME SET   
 COMMENT1 =  (  
   SELECT  TOP 1 CAST(wtc.Comment_Text AS VARCHAR(255))   
   FROM  waste_n_timed_comments AS wtc  
    WHERE  wtc.wtc_source_id = #DOWNTIME.tedet_id   
   AND wtc.timestamp= (  
      select  max(wtc2.timestamp)   
      from  waste_n_timed_comments wtc2   
      where  wtc.wtc_source_id=wtc2.wtc_source_id  
      )  
   )  
*/  
  
update ted set  
 comment1 = REPLACE(coalesce(convert(varchar(2000),co.comment_text),''), char(13)+char(10), ' ')  
from dbo.#Downtime ted with (nolock)  
left join dbo.Comments co with (nolock)  
on ted.cause_comment_id = co.comment_id  
  
----------set Downtime -------------  
  
update #downtime set Downtime = datediff(s,starttime,endtime)/60.0  
  
  
----If there is in no endtime (which should mean that the record is still open (downtime is still active) aussume that the endtime of the event is  
  
update #downtime set Downtime = datediff(s,starttime,@InputEndTime)/60.0  
 where Endtime is null  
  
  
-- Set shift and team   
  
update #downtime set   
 team = cs.crew_desc,  
 shift = cs.shift_desc  
from dbo.crew_schedule cs with (nolock)   
join dbo.#puid_list plist with (nolock) on cs.pu_id = plist.schedule_puid  
and cs.start_time < @InputEndTime  
and (cs.end_time > @InputStartTime or cs.end_time is null)  
where plist.puid = #downtime.puid    
and starttime >= cs.start_time  
and (starttime < cs.end_time or cs.end_time is null)  
  
  
update #downtime set uptime=datediff(s,(  
  select max(dt2.endtime) from dbo.#downtime dt2 with (nolock) where ((dt2.starttime<=#downtime.starttime) and ( dt2.tedet_id <> #downtime.tedet_id)) and dt2.puid=#downtime.puid  
  ),starttime)/60.0  
  
 update #downtime set uptime=datediff(s,@inputstarttime,starttime)/60.0 where uptime is null  
  
----  
  
  
 ----------set Line Status-------------  
  
 update #downtime set line_status = (select Top 1 phr.phrase_value  
 from dbo.local_pg_line_status lls with (nolock)  
 join dbo.phrase phr with (nolock) on lls.line_status_id = phr.phrase_id  
 where lls.unit_id = #downtime.puid  
 and #downtime.starttime >= lls.start_datetime  
 order by lls.start_datetime ASC)  
  
  
update #downtime set   
 prod_start = ps.start_time,   
 prod_end = ps.end_time,  
 prod_desc = p.prod_desc,  
 Plant = upper(substring(plist.pudesc,3,2)),  
 Line = plist.pldesc,  
 MasterProdUnit = plist.pudesc   
from  dbo.products p with (nolock)   
join  dbo.production_starts ps with (nolock) on ps.prod_id= p.prod_id  
and  ps.start_time < @InputEndTime  
and  (ps.end_time > @InputStartTime or ps.end_time is null)  
join dbo.#puid_list plist with (nolock) on ps.pu_id = plist.converter_puid  
where  ps.start_time <= #downtime.starttime  
and  ((#downtime.starttime < ps.end_time) or (ps.end_time is null))   
and plist.puid = #downtime.puid  
  
insert into #prod_info (prod_desc)  
select distinct prod_desc from dbo.#downtime with (nolock)  
  
update #prod_info set  
 [size] =   
 reverse(rtrim(left(prod_desc,charindex('(',prod_desc)-1)))  
 where charindex('(',prod_desc)>0  
update #prod_info set  
 platform =   
 ltrim(rtrim(left(prod_desc, (charindex(' ',prod_desc))-1)))  
 where charindex(' ',prod_desc)>0  
update #prod_info set  
 count_package =   
 ltrim(rtrim(stuff(stuff(prod_desc,charindex(')',prod_desc),len(prod_desc),''),1,charindex('(',prod_desc),'')))  
 where charindex('(',prod_desc)>0  
  
  
update #prod_info set  
 [size] = reverse(rtrim(left([size],charindex(' ',[size])-1)))  
  
update #downtime set  
 [size] = pinfo.[size],  
 platform = pinfo.platform,  
 count_package = pinfo.count_package  
from dbo.#prod_info pinfo with (nolock)  
join dbo.#downtime dt with (nolock) on pinfo.prod_desc = dt.prod_desc  
  
  
update #downtime set  
 Line_Speed = result  
from dbo.#tests t with (nolock)  
join dbo.#downtime dt with (nolock) on t.varpuid = dt.puid  
and result_on >= dt.prod_start  
and (result_on <= dt.prod_end or dt.prod_end is null)  
where lower(t.var_desc) = 'average line speed (actual)'  
    
  
update #downtime set  
 Tgt_Line_Speed = result  
from dbo.#tests t with (nolock)  
join dbo.#downtime dt with (nolock) on t.varpuid = dt.puid  
and result_on >= dt.prod_start  
and (result_on <= dt.prod_end or dt.prod_end is null)  
where lower(t.var_desc) = 'average line speed (target)'  
    
  
update #downtime set  
 Cycles = result  
from dbo.#tests t with (nolock)  
join dbo.#downtime dt with (nolock) on t.varpuid = dt.puid  
and result_on >= dt.prod_start  
and (result_on <= dt.prod_end or dt.prod_end is null)  
where lower(t.var_desc) = 'total cycles'  
    
  
Select   
 Plant,  
 Line,  
/*  
 right('0' + convert(varchar,datepart(mm,starttime)),2) + '/' +  
  right('0' + convert(varchar,datepart(dd,starttime)),2) + '/' +  
  convert(varchar,datepart(yyyy,starttime)) 'Prod_Date',  
 right('0' + convert(varchar,datepart(mm,starttime)),2) + '/' +  
  right('0' + convert(varchar,datepart(dd,starttime)),2) + '/' +  
  convert(varchar,datepart(yyyy,starttime)) + ' ' +  
  left(convert(varchar,starttime,114),8) Start_DateTime,  
*/  
 convert(datetime,left(starttime,11),102) Prod_Date,--BAS, 080904, Changed from above.  Format date time to support Regional Settings  
 starttime Start_DateTime,--BAS, 080904, Changed from above.  Format date time in PE VBA to support Regional Settings  
 Downtime,  
 Uptime,  
 PLC_Cause,  
 reason1 Feature,  
 Main_Component_Global_LU,  
 reason2 Component,  
 Reason3 Failure_Mode,  
 Reason4 Root_Cause,  
 location EA,  
 Shift,  
 Team,  
 Line_Status,  
 Line_Mode,  
 Line_Speed,  
 Tgt_Line_Speed,  
 Cycles,  
 [Size],  
 Platform,  
 Count_Package,  
 right('00' + convert(varchar,datepart(dy,starttime)),3) Julian_Date,  
 DT_Status,  
 Comment1,  
 Comment2  
from dbo.#downtime with (nolock)   
order by plant, line, starttime  
  
  
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
drop table #puid_list  
drop table #variables  
drop table #tests  
drop table #prod_info  
  
  
  
  
  
