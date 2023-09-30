           /*  
Stored Procedure: spLocal_PE_BCWasteRaw_2_1_2  
Author:   J. Jaeger (Stier Automation)  
Date Created:  08/18/03  
  
Description:  
=========  
Returns  waste data for Proficy Explorer tool   
  
XLA Version Change Date Who What  
============ =========== ==== =====  
V0.1.5  1/27/04  SLS     Release to B.Barre  
V2.1.0_T 8/9/04  BAS Changed from output formatting of Prod_Date and Reject_Datetime columns to support PE VBA Regional Settings format.  
V2.1.2  9/21/04  BAS Renamed sp with XLA version.  
V2.1.2  10/22/04 rm/BAS Don't error out if product is not formated for prod/bag  
  
*/  
  
--  exec spLocal_PE_BCWasteRaw_2_1_2 '08/20/03', '08/21/03', 'STM Plant Waste1', 1   
  
--/*  
CREATE    procedure dbo.spLocal_PE_BCWasteRaw_2_1_2  
@InputStartTime  DateTime,  
@InputEndTime  DateTime,  
@InputMasterProdUnit nVarChar(4000)=null,  
@InputUseVars  integer = 1  
As  
--*/  
  
set nocount on  
  
/*  
declare @teststart datetime  
select @teststart = current_timestamp  
  
-- testing values  
  
declare @InputStartTime  DateTime,  
 @InputEndTime  DateTime,  
 @InputMasterProdUnit nVarChar(4000),  
 @InputUseVars  integer  
  
  
select  @InputStartTime  = '01/21/03',  
 @InputEndTime  = '01/22/03',  
 @InputMasterProdUnit = 'DICG158 Converter',  
 @InputUseVars  =  1  
*/  
  
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
  
  
Create table #Waste(      
  Plant  varchar(100),  
 Line  varchar(100),  
 Line_Status varchar(100),  
 Line_Mode varchar(100),  
 Line_Speed float,  
 Tgt_Line_Speed float,  
 Cycles  float,  
 Prod_Date datetime,  
 End_Date datetime,  
 prod_desc varchar(100),  
 Reject_datetime datetime,  
 MasterProdUnit varchar(100),  
 Location varchar(50), -- Reject_Area  
 Fault_id integer,  
 Fault  varchar(100), -- Reject Code  
 Reason1  varchar(100),   
 Reason2  varchar(100),  
 Team  varchar(25),  
 Shift  varchar(25),  
 Amount   integer,  -- Pad_Count_DDE  
 Count_Package varchar(100),  
 PUID  INTeger,  
 SourcePUID INTeger,  
 wed_id  INTeger,  
 ReasonID1 INTeger,  
 ReasonID2 INTeger,  
 [Size]  varchar(100),  
 Platform varchar(100),  
 Spare1  varchar(255),   
 Spare2  varchar(255),   
 Spare3  varchar(255),  
 Spare4  varchar(255),   
 Spare5  varchar(255),   
 Spare6  varchar(255),   
 Spare7  varchar(255),   
 Spare8  varchar(255),   
 Spare9  varchar(255),   
 Spare10  varchar(255),  
 sched_id integer  
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
 VarPUId  Integer,  
 converter_puid integer  
)  
  
  
create table #prod_info(  
 prod_desc varchar(300),  
 [size]  varchar(50),  
 platform varchar(50),  
 count_package varchar(50)  
)  
  
  
CREATE TABLE #ErrorMessages (  
 ErrMsg nVarChar(255) )  
  
  
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
IF @InputMasterProdUnit is null  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('MasterProdUnit is not assigned.')  
 GOTO ErrorMessagesWrite  
END  
IF IsNumeric(@InputUseVars) <> 1  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('Use Vars is not assigned.')  
 GOTO ErrorMessagesWrite  
END  
  
  
  
----------Populate the #puid_list table -------------  
  
insert into  #puid_list (puid, pudesc, plid, pldesc, info, tmp1)  
 select  distinct pu.pu_id, pu.pu_desc, pl.pl_id, pl.pl_desc,  
  pu.extended_info,charindex('scheduleunit=',pu.extended_info)   
 from  prod_units pu   
 join  prod_lines pl on pu.pl_id = pl.pl_id  
 and  (CHARINDEX( ','+pu_desc+',' , ','+ @InputMasterProdUnit+ ','  ) > 0   
  or  (@InputMasterProdUnit = 'All'))  
   
  
update #puid_list set  
 converter_puid =    
   (  
   select pu_id   
   from prod_units pu  
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
  
  
----------Populate the #waste Table from waste Event Details Table -------------  
  
declare @min integer, @max integer  
  
select @min = min(wed_id), @max = max(wed_id)   
from waste_event_details  
where  EXISTS(SELECT puid from #puid_list where PU_ID = puid  ) and  
 [timestamp] >= @InputStartTime  
and  [timestamp] <= @InputEndTime  
  
  
insert into #waste  
 (wed_id,Reject_Datetime,puid,SourcePuid,fault_id,reasonID1,reasonID2,amount)  
select  wed_id,[timestamp],pu_id,source_pu_id,wefault_id,reason_level1,reason_level2,amount  
from waste_event_details wed  
where wed_id >= @min  
and  wed_id <= @max  
and  EXISTS(SELECT puid from #puid_list where PU_ID = puid  )  
and [timestamp] >= @InputStartTime  
and  [timestamp] <= @InputEndTime  
order by [timestamp], pu_id  
  
CREATE nonclustered INDEX w_PUId_EventTime  
 ON #Waste (reject_datetime)  
  
  
if @InputUseVars = 1  
  
 begin  
  
  insert into #variables  
   (var_id, var_desc, varpuid)  
  select  var_id, var_desc, pu_id  
  from variables  
  where  (  
   lower(var_desc) = 'average line speed (actual)'  
   or lower(var_desc) = 'average line speed (target)'  
   or lower(var_desc) = 'total cycles'  
   )  
  and  EXISTS(SELECT converter_puid from #puid_list where PU_ID = converter_puid  )   
  
  
  insert into #tests  
   (result_on, result, var_id)  
  select  result_on, result, var_id    
  from  tests t  
  where  result_on >= @InputStartTime  
  AND  result_on < @InputEndTime  
  and  EXISTS(SELECT var_id from #variables v where v.var_ID = t.var_id  )   
  order by result_on  
  
  update #tests set  
   var_desc = v.var_desc,  
   varpuid = v.varpuid  
  from #variables v  
  where #tests.var_id = v.var_id  
  
  
  CREATE nonclustered INDEX t_PUId_result_on  
   ON #tests (result_on)  
  
  
 end  
  
  
update  #waste set  
 Reason1 = event_reason_name  
from  #waste w  
join event_reasons er  
on  w.reasonid1 = event_reason_id  
  
update  #waste set  
 Reason2 = event_reason_name  
from  #waste w  
join event_reasons er  
on  w.reasonid2 = event_reason_id  
  
update  #waste set  
 fault = wefault_value  
from  #waste w  
join waste_event_fault wef  
on w.fault_id = wef.wefault_id  
  
update  #waste set  
 location = pu_desc  
from  #waste w  
join prod_units pu  
on w.SourcePuid = pu.pu_id  
  
  
  
  
begin  
 ----------set Line Status-------------  
  
 update #waste set line_status = (select Top 1 phr.phrase_value  
 from local_pg_line_status lls  
 join phrase phr on lls.line_status_id = phr.phrase_id  
 where lls.unit_id = #waste.PUID  
 and #waste.Reject_Datetime >= lls.start_datetime  
 order by lls.start_datetime ASC)  
end  
  
  
  
update #waste set   
 prod_date = ps.start_time,   
 end_date = ps.end_time,  
 prod_desc = p.prod_desc,  
 Plant = upper(substring(plist.pudesc,3,2)),  
 Line = plist.pldesc,  
 MasterProdUnit = plist.pudesc   
from  products p   
join  production_starts ps on ps.prod_id= p.prod_id  
and  ps.start_time < @InputEndTime  
and  (ps.end_time > @InputStartTime or ps.end_time is null)  
join #puid_list plist on ps.pu_id = plist.converter_puid  
where  ps.start_time <= #waste.reject_datetime  
and  ((#waste.reject_datetime < ps.end_time) or (ps.end_time is null))   
and plist.puid = #waste.puid  
  
insert into #prod_info (prod_desc)  
select distinct prod_desc from #waste  
  
  
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
  
update #waste set  
 [size] = pinfo.[size],  
 platform = pinfo.platform,  
 count_package = pinfo.count_package  
from #prod_info pinfo  
join #waste w on pinfo.prod_desc = w.prod_desc  
  
--  get values from test variables  
  
  
if @InputUseVars = 1  
  
 begin  
  
  update #waste set  
   Line_Speed = result  
  from #tests t  
  join #puid_list plist on t.varpuid = plist.converter_puid  
  join #waste w on w.puid = plist.puid  
  and result_on >= w.prod_date  
  and (result_on <= w.end_date or w.end_date is null)   
  where lower(t.var_desc) = 'average line speed (actual)'  
    
  update #waste set  
   Tgt_Line_Speed = result  
  from #tests t  
  join #puid_list plist on t.varpuid = plist.converter_puid  
  join #waste w on w.puid = plist.puid  
  and result_on >= w.prod_date  
  and (result_on <= w.end_date or w.end_date is null)    
  where lower(t.var_desc) = 'average line speed (target)'  
  
  update #waste set  
   Cycles = result  
  from #tests t  
  join #puid_list plist on t.varpuid = plist.converter_puid  
  join #waste w on w.puid = plist.puid  
  and result_on >= w.prod_date  
  and (result_on <= w.end_date or w.end_date is null)    
  where lower(t.var_desc) = 'total cycles'  
  
  
/*  
  update #waste set  
   Tgt_Line_Speed = result  
  from #tests t  
  join #waste w on t.varpuid = w.puid  
  and result_on >= w.prod_date  
  and (result_on <= w.end_date or w.end_date is null)  
  where lower(t.var_desc) = 'average line speed (target)'  
    
  
  
  update #waste set  
   Cycles = result  
  from #tests t  
  join #waste w on t.varpuid = w.puid  
  and result_on >= w.prod_date  
  and (result_on <= w.end_date or w.end_date is null)  
  where lower(t.var_desc) = 'total cycles'  
*/    
  
 end  
  
-- Set shift and team   
  
update #waste set   
 team = cs.crew_desc,  
 shift = cs.shift_desc  
from crew_schedule cs   
join #puid_list plist on cs.pu_id = plist.schedule_puid  
and cs.start_time < @InputEndTime  
and (cs.end_time > @InputStartTime or cs.end_time is null)  
where plist.puid = #waste.puid    
and reject_datetime >= cs.start_time  
and (reject_datetime < cs.end_time or cs.end_time is null)  
  
  
update #waste set  
 Line_Mode = 'Line Mode'  
   
  
-------------- Get result data set -------------------------------------  
  
select  Plant,  
 Line,  
/*  
 right('0' + convert(varchar,datepart(mm,Reject_Datetime)),2) + '/' +  
  right('0' + convert(varchar,datepart(dd,Reject_Datetime)),2) + '/' +  
  convert(varchar,datepart(yyyy,Reject_Datetime)) 'Prod_Date',  
 wed_id 'Event ID',  
 right('0' + convert(varchar,datepart(mm,Reject_Datetime)),2) + '/' +  
  right('0' + convert(varchar,datepart(dd,Reject_Datetime)),2) + '/' +  
  convert(varchar,datepart(yyyy,Reject_Datetime)) + ' ' +  
  left(convert(varchar,Reject_Datetime,114),8) Reject_Datetime,  
*/   
 convert(datetime,left(Reject_Datetime,11),102) Prod_Date,--Prod Date  
 wed_id 'Event ID',  
 Reject_Datetime Reject_Datetime,--Start_DateTime  
 Location Reject_Area,  
 fault Reject_Code,  
 Amount Pad_Count_DDE,  
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
 right('00' + convert(varchar,datepart(dy,Reject_Datetime)),3) Julian_Date  
from #waste  
order by plant, line, reject_datetime  
  
  
GOTO Finished  
  
  
  
ErrorMessagesWrite:  
-------------------------------------------------------------------------------  
-- Error Messages.  
-------------------------------------------------------------------------------  
 SELECT ErrMsg  
  FROM #ErrorMessages  
  
Finished:  
  
drop table #puid_list  
drop table #waste  
drop table #ErrorMessages  
drop table #variables  
drop table #tests  
drop table #prod_info  
  
  
--select datediff(ms,@teststart,current_timestamp)  
  
  
