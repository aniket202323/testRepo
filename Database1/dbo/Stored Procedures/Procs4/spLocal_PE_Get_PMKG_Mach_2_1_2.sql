      /*  
Stored Procedure: pLocal_PE_Get_PMKG_Mach  
Author:   S. Stier (Stier Automation)  
Date Created:  1/14/04  
  
Description:  
=========  
returns All Pmkg Machines on the server for Proficy Explorer Application  
  
XLA Version Change Date Who What  
============ =========== ==== =====  
V0.1.4  1/14/04  SLS Initial Release  
V0.1.5  1/27/04  SLS     Release to B.Barre  
V2.1.2  9/21/04  BAS Renamed sp with XLA version.  
  
*/  
  
  
CREATE PROCEDURE dbo.spLocal_PE_Get_PMKG_Mach_2_1_2  
  
AS   
  
  
-----------------------------------------------------------  
-- Declare program variables.  
-----------------------------------------------------------  
  
    
------------------------------------------------------------  
---- CREATE  Temp TABLES   -----------  
------------------------------------------------------------  
  
Create table #PMKGMach(   
 PMKGMachName  varchar(50)  
)  
  
  
  
--insert into #PMKGMach (PMKGMachName) (select  UPPER(RTRIM(LTRIM(LEFT(PU_desc, PatINDEX ('%Rolls%', pu_Desc) - 1)))) from prod_units  
--where PatINDEX ('%Rolls%', pu_Desc)<> 0)  
insert into #PMKGMach (PMKGMachName) (select  UPPER(RTRIM(LTRIM(Right(     (LEFT(PU_desc, PatINDEX ('%Rolls%', pu_Desc) - 1)),3)  )   ) ) from prod_units  
where PatINDEX ('%Rolls%', pu_Desc)<> 0)  
  
  
select * from #PMKGMach order by PMKGMachName  
  
drop table #PMKGMach  
  
  
