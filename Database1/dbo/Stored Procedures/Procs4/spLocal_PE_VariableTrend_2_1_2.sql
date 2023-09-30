         /*  
Stored Procedure: spLocal_PE_VariableTrend_2_1_2  
Author:   S. Stier (Stier Automation)  
Date Created:  10/10/03  
  
Description:  
=========  
Returns  Variable Data from the Tests Table  for the  Proficy Explorer tool   
  
XLA Version Change Date Who What  
============ =========== ==== =====  
V1.0.4  10/10/03 SLS Initial Design  
V1.0.4  12/16/03 SLS Issue to Kim  
V0.1.5  1/27/04  SLS     Release to B.Barre  
V2.1.2  9/21/04  BAS Renamed sp with XLA version.  
  
*/  
--spLocal_PE_VariableTrend_2_1_2  '2003-11-10 12:45:00 ', '2003-11-10 13:15:00 ','Widget Line 1','Widget Line 1 Paint Machine','Colour Saturation','raw',5,'warning'  
--spLocal_PE_VariableTrend_2_1_2  '2004-02-22 00:00:00 ', '2004-02-23 00:00:00 ','TT MK71','MK71 Converter Audits','Ears [N]','Interval',5,'Reject'  
--/*  
CREATE  procedure spLocal_PE_VariableTrend_2_1_2  
  
@InputStartTime datetime,  
@InputEndTime datetime,  
@InputLine varchar(300),  
@InputProdUnit varchar(300),  
@InputVarName varchar(300),  
@InputMode varchar(8)='raw',  
@InputInterval varchar(10)=5,  
@InputLimitType varchar(7)='warning'  
  
as  
  
  
  
--set nocount on  
  
--*/  
-- Create temp tables... one hold the raw data, one holds places for each time interval in the report window  
  
CREATE TABLE #ErrorMessages   
 (  
 ErrMsg nVarChar(255)   
 )  
  
  
create table #tests   
 (  
 result_on datetime,   
 result varchar(25),  
 prod_id int,  
 Prod_Desc varchar(99),  
 Prod_Code varchar(99),  
 vs_id int,  
 L_Entry varchar(99),  
 L_Reject varchar(99),  
 L_Warning Varchar(99),  
 L_User Varchar(99),  
 Target varchar(99),  
 U_User Varchar(99),  
 U_Warning Varchar(99),  
 U_Reject varchar(99),  
 U_Entry varchar(99),  
 Upper_Limit varchar(99),  
 Lower_Limit varchar(99),  
 Interval_id int  
 )  
  
  
create table #intervals   
 (  
 Interval_ID                 int IDENTITY (0, 1) NOT NULL ,  
 interval_start datetime,  
 interval_end datetime,  
 )  
  
  
  
  
declare @loopcounter int  
declare @intervalclock datetime  
declare @VAR_id int  
declare @PU_Id int  
declare @testcount as int  
Declare @Data_Type_ID as int  
  
-- Check for Invalid Input Start time  if not generate an error messsage.  
  
  
IF IsDate(@InputStartTime) <> 1  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('StartTime is not a Date.')  
 GOTO ErrorMessagesWrite  
END  
  
-- Check for Invalid Input Start time  if not generate an error messsage.  
  
IF IsDate(@InputEndTime) <> 1  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('EndTime is not a Date.')  
 GOTO ErrorMessagesWrite  
END  
  
  
  
--  
-- get the PU_id for the Produciton Unit in Question from the Prod_units Table.  
--  
  
select @PU_Id = (Select PU_ID  from prod_units pu   
                             join prod_lines pl on pl.pl_id=pu.pl_id   
                            where  pu.pu_desc =  @InputProdUnit and  pl.pl_desc = @InputLine)  
--  
-- Check to see if the Production Unit  was found in the Prod Units table if not generate an error messsage.  
--  
if  @PU_Id is Null  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('Production Unit Not Found. /InputLine=' + @inputLine + ' /InputProdUnit=' + @InputProdUnit)  
 GOTO ErrorMessagesWrite  
END  
  
--  
-- get the Var_id from the variables using the PU_Id and Input Variable Name.  
--  
  
select @VAR_id = (Select var_id  from variables v   
                             where v.pu_id = @PU_Id and   
                            v.var_desc = @InputVarName)  
  
--  
-- Check to see if the Variable was found in the Variables table if not generate an error messsage.  
--  
if  @VAR_id is Null  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('Variable Not Found. /' + @inputLine + '/' + @InputProdUnit + '/' + @InputVarName+ '/')  
 GOTO ErrorMessagesWrite  
END  
  
select @Data_Type_ID = (Select Data_Type_ID  from variables v   
                             where v.var_id = @VAR_id )  
  
insert into #tests    
 (  
 result_on,  
 result  
 )  
select    
 result_on,   
 result  
from   
tests t  
Where (var_id = @VAR_id) and ( t.result_on > @InputStarttime) and (t.result_on <= @InputEndtime)  and result is not NULL  
--  
--- Check to see if any results were found if not then Generate Error Message  
--  
select @testcount = (select count(*) from #Tests)  
  
if  @testcount = 0  
BEGIN  
 INSERT #ErrorMessages (ErrMsg)  
  VALUES ('No Variable Data found in Time Window Specified.')  
 GOTO ErrorMessagesWrite  
END  
  
  
  
  
-- get the prod_id  for each test record  
  
update #tests set prod_id=(select prod_id from Production_Starts ps   
                                                     where (ps.pu_id = @PU_Id)  
    and (ps.start_time < #tests.result_on)   
    and (#tests.result_on <=  ps.end_time or ps.end_time is null)  
   )  
  
update #tests set prod_Desc=(select prod_Desc from Products where #tests.prod_id = prod_id)  
  
update #tests set prod_Code=(select prod_Code from Products where #tests.prod_id = prod_id)  
  
-- get var spec Id ---------------------------------------------------------  
  
update #tests set vs_id =(  
select vs_id  
from var_specs vs where vs.var_id=@VAR_id and vs.prod_id=#tests.prod_id  
and vs.effective_date<#tests.result_on    
and  (vs.expiration_date>=#tests.result_on   
 or vs.expiration_date is null)  
and vs.vs_id= (  
  select max(vs_id)   
  from var_specs vs2   
  where vs.var_id=vs2.var_id   
  and vs.prod_id=vs2.prod_id   
  and vs.effective_date=vs2.effective_date  
  )  
)  
  
Update #tests set L_Entry =( select L_Entry from var_specs vs where  vs.vs_id=#tests.vs_id)  
  
Update #tests set L_Reject =( select L_Reject from var_specs vs where  vs.vs_id=#tests.vs_id)  
  
Update #tests set L_Warning =( select L_Warning from var_specs vs where  vs.vs_id=#tests.vs_id)  
  
Update #tests set L_User =( select L_User from var_specs vs where  vs.vs_id=#tests.vs_id)  
  
Update #tests set target =( select target from var_specs vs where  vs.vs_id=#tests.vs_id)  
  
Update #tests set U_User =( select U_User from var_specs vs where  vs.vs_id=#tests.vs_id)  
  
Update #tests set U_Warning =( select U_Warning from var_specs vs where  vs.vs_id=#tests.vs_id)  
  
Update #tests set U_Reject =( select U_Reject from var_specs vs where  vs.vs_id=#tests.vs_id)  
  
Update #tests set U_Entry=( select  U_Entry from var_specs vs where  vs.vs_id=#tests.vs_id)  
  
  
--select * from #tests order by Result_on  
  
if lower(@InputLimitType) = 'entry'  
  
 begin  
  
  update #tests set Lower_Limit = L_Entry  
  update #tests set Upper_Limit = U_Entry  
 end  
Else  
 if lower(@InputLimitType) = 'reject'  
  
  begin  
   
   update #tests set Lower_Limit = L_Reject  
   update #tests set Upper_Limit = U_Reject  
  end  
 else  
  
  if lower(@InputLimitType) = 'warning'  
  
   begin  
   
    update #tests set Lower_Limit = L_Warning  
    update #tests set Upper_Limit = U_Warning  
   end  
  else  
   if lower(@InputLimitType) = 'user'  
    
     begin  
     
      update #tests set Lower_Limit = L_User  
      update #tests set Upper_Limit = U_User  
     end  
    else  
     begin  
       
     INSERT #ErrorMessages (ErrMsg)  
      VALUES ('Input Limit Type Not Valid. Must be (Entry,Reject,Warning or User) Input Limit Type ='  + @InputLimitType)  
     Goto ErrorMessagesWrite  
     end  
  
  
  
-- if interval data is requested, populate that table and return the data  
if lower(@Inputmode) = 'interval'  
  
 Begin  
  
  if @Data_Type_ID > 3   
   Begin  
  
   INSERT #ErrorMessages (ErrMsg)  
    VALUES ('Cannot Generate Inverval data for non-numeric Variables')  
     Goto ErrorMessagesWrite  
  
   end  
                               else  
  
   Begin  
  select @loopcounter = 0  
  select @intervalclock = @InputStartTime  
  
  -- insert timestamps for each interval in the report window  
  while @intervalclock <= @InputEndTime    
  
   begin  
     
   -- guard against endless loops or intervals that are too small to be useful  
   IF @LoopCounter > 32000  
   
    BEGIN  
      INSERT #ErrorMessages (ErrMsg)  
      VALUES ('Too many intervals entered... '  )  
    GOTO ErrorMessagesWrite  
    End  
     
   insert #intervals (interval_Start, interval_End)   
   values (@intervalclock,dateadd(mi,convert(integer,@InputInterval),@intervalclock))  
  
   select @intervalclock = dateadd(mi,convert(integer,@InputInterval),@intervalclock)  
   select @LoopCounter = @LoopCounter + 1  
  
   end  
  --- Now update the #tests Table  
  update #tests set Interval_ID=(select Interval_ID from #intervals i  
                                                     where  (i.interval_start <= #tests.result_on)  
    and (#tests.result_on < i.interval_end or  i.interval_end is null))  
  
  select  [Product] =Prod_Desc + ' (' + Prod_code + ')',  
     
   [TimeStamp] = i.interval_start,   
   [Value] = avg(convert(float,t.result)),  
   [Upper] = avg(convert(float,t.Upper_Limit)),   
   [Target] = avg(convert(float,T.Target)),   
   [Lower] = avg(convert(float,T.Lower_Limit)),  
   [Count] = count(t.result)  
  from #tests t  
  Right join #intervals as i on (i.Interval_id = t.Interval_id)  
  Group by i.Interval_id, VS_ID,Prod_code,Prod_Desc, I.Interval_start  
  order by I.Interval_start  
                                end  
 end   
  
else  
  
 if lower(@Inputmode) = 'raw'  
  
 -- if raw data is requested, return those records  
 begin  
  -- return the raw results  
  select  [Product] =Prod_Desc + '(' + Prod_code + ')',  
   [TimeStamp] = result_on,   
   [Value] = result,   
   [Upper] = Upper_Limit,   
   [Target] = Target,   
   [Lower] = Lower_Limit,  
   [Count] = '1'  
  from #tests   
  order by result_on  
  
 end  
  
 Else  
   Begin  
  
    INSERT #ErrorMessages (ErrMsg)  
     VALUES ('Input Mode Not Valid. Must be (Raw or Interval) Input Mode ='  + @InputMode)  
    Goto ErrorMessagesWrite  
  
   End  
  
---select * from #Tests order by Result_on  
--select * from #intervals order by interval_start  
  
GOTO Finished  
  
  
ErrorMessagesWrite:  
-------------------------------------------------------------------------------  
-- Error Messages.  
-------------------------------------------------------------------------------  
 SELECT ErrMsg  FROM #ErrorMessages  
  
  
Finished:  
  
drop table #ErrorMessages  
drop table #tests  
drop table #intervals  
  
--select datediff(ms,@teststart,current_timestamp)  
  
  
  
