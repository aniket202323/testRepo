CREATE PROCEDURE dbo.spPurge_GetVariables(@PU_Id int) AS
--get time based variables for a specific unit
select 
 	 Var_Id,PU_Id,Var_Desc 
from 
 	 Variables v 
where 
 	 v.Event_Type not in (1,2)
 	 and PU_Id=@PU_Id 
order by 
 	 Var_Desc
