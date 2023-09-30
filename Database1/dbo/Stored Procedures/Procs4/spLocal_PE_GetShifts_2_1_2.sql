              /*  
Stored Procedure: spLocal_PE_GetShifts  
Author:   S. Stier (Stier Automation)  
Date Created:  10/01/02  
  
Description:  
=========  
returns All the Valid Shift Name for the Production Unit in Question - Assumes use of the ScheduleUnit paramter in Exteded info field  
  
XLA Version Change Date Who What  
============ =========== ==== =====  
V0.0.5  10/09/02 SLS Issue to K. Rafferty  
V0.0.7  10/10/02 SLS Another Issue  
V0.0.8  10/11/02 SLS Issue to Kim and Bunch of Fixes  
V0.0.9  10/29/02 SLS Issue to Kim   
V0.1.4  12/09/03 SLS Handle Multiple Produciton Units  
V0.1.5  1/27/04  SLS     Release to B.Barre  
V2.1.2  9/21/04  BAS Renamed sp with XLA version.  
  
*/  
  
  
CREATE  PROCEDURE dbo.spLocal_PE_GetShifts_2_1_2  
@InputMasterProdUnits  VarChar(8000) --nVarChar(4000) 12/20/04 BAS Changed to varchar because nVarChar has a max character limit of 4000.  This was causing an issue when MP was pulling all Reliabity master units.  
  
AS   
  
  
-----------------------------------------------------------  
-- Declare program variables.  
-----------------------------------------------------------  
  
    
------------------------------------------------------------  
---- CREATE  Temp TABLES   -----------  
------------------------------------------------------------  
  
Create table #Shifts(   
 Shift  varchar(30)  
)  
  
  
---- get the production schedule id from the extended Info field-  
----------get Valid Crew Schedule for the time Period in Question -------------  
  
create table #schedule_puid (pu_id int, schedule_puid int, tmp1 int,tmp2 int,info varchar(300))  
  
  
 insert into #schedule_puid (pu_id,info) select pu_id,extended_info from prod_units   
 where (charindex(','+pu_desc+',',','+@inputmasterprodunits+',')>0 or @inputmasterprodunits='All')  
  
 update #schedule_puid set tmp1=charindex('scheduleunit=',info)  
   
 update #schedule_puid set tmp2=charindex(';',info,tmp1) where tmp1>0  
  
 update #schedule_puid set schedule_puid=cast(substring(info,tmp1+13,tmp2-tmp1-13) as int) where tmp1>0 and tmp2>0 and not tmp2 is null  
  
 update #schedule_puid set schedule_puid=cast(substring(info,tmp1+13,len(info)-tmp1-12) as int)where tmp1>0 and tmp2=0  
  
 update #schedule_puid set schedule_puid=pu_id where schedule_puid is null  
  
  
  
  
insert into #Shifts( Shift) (Select distinct shift_desc from crew_schedule cs Join #Schedule_puid sp on sp.schedule_puid = cs.PU_ID)  
  
select * from #Shifts order by shift  
  
drop table #Shifts  
  
Drop Table #schedule_puid  
  
