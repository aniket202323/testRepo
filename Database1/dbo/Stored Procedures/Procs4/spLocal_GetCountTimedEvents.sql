 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
CREATE PROCEDURE dbo.spLocal_GetCountTimedEvents   
  
@InputMasterProdUnitPrefix nVarChar(4000)=null  
  
As  
  
SET NOCOUNT ON  
  
select Count(*)  
FROM [dbo].timed_event_details AS ted   
inner join [dbo].prod_units as pu2 on (pu2.pu_id = ted.pu_id)  
Where pu2.pu_desc like @InputMasterProdUnitPrefix +'%'  
  
select distinct pu2.pu_desc  
FROM [dbo].timed_event_details AS ted   
inner join [dbo].prod_units as pu2 on (pu2.pu_id = ted.pu_id)  
Where pu2.pu_desc like @InputMasterProdUnitPrefix +'%'  
  
SET NOCOUNT OFF  
  
