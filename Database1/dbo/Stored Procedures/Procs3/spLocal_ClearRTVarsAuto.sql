   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : This procedure clears out the variable entries in the Test_History and Tests Table  
     for the real time variables  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
  
CREATE PROCEDURE spLocal_ClearRTVarsAuto  
  
AS  
SET NOCOUNT ON  
--select * from test_history  
--where test_id in (select test_id from tests t where var_id in   
-- (select var_id from variables v, prod_units p  
--  where p.pu_id  = v.pu_id and p.pu_desc like '%Materials%'  
--  and (var_desc like '%flow 10 Min%' or var_desc like '%consistency 10 Min%'))  
--  and t.result_on < dateadd(day, -1, getdate()))  
  
select * from dbo.tests t  
where var_id in (select var_id from dbo.variables v, prod_units p  
  where p.pu_id  = v.pu_id and p.pu_desc like '%Materials%'  
  and (var_desc like '%flow 10 Min%' or var_desc like '%consistency 10 Min%'))  
  and t.result_on < dateadd(day, -1, getdate())  
  
if @@error <> 0   
begin  
 insert into local_reperrmsg (err_time, err_msg)  
  values (getdate(),'Error in spLocal_ClearRTVarsAuto')  
end  
  
SET NOCOUNT OFF  
  
