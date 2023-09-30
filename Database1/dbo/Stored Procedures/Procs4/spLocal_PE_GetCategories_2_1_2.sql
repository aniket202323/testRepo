            /*  
Stored Procedure: spLocal_PE_GetCategories  
Author:   S. Stier (Stier Automation)  
Date Created:  10/01/02  
  
Description:  
=========  
returns All the Suffixes Based upon a prefix passed to it from the event categories table  
  
XLA Version Change Date Who What  
============ =========== ==== =====  
V0.0.5  10/09/02 SLS Issue to K. Rafferty  
V0.0.7  10/10/02 SLS Another Issue  
V0.0.8  10/11/02 SLS Issue to Kim and Bunch of Fixes  
V0.0.9  10/29/02 SLS Issue to Kim   
V0.0.9  11/4/02  SLS Fixed bug where searching anywahere in string.  
V0.1.4  12/09/03 SLS Handle Multiple Produciton Units  
V0.1.5  1/27/04  SLS     Release to B.Barre  
V2.1.2  9/21/04  BAS Renamed sp with XLA version.  
  
*/  
  
CREATE PROCEDURE dbo.spLocal_PE_GetCategories_2_1_2  
@CategoryPrefix  nVarChar(4000)  
  
AS   
  
  
  
  
-----------------------------------------------------------  
-- Declare program variables.  
-----------------------------------------------------------  
DECLARE @Position int,  
  @PU_Id  int,  
  @ScheduleUnit_PU_Id int,  
  @PUScheduleUnitStr  nVarChar(255),  
  @PartialString  nVarChar(255),  
  @@ExtendedInfo nvarChar(255)  
    
------------------------------------------------------------  
---- CREATE  Temp TABLES   -----------  
------------------------------------------------------------  
  
Create table #CategorySuffixes(Suffixes  varchar(100))  
  
  
insert into #CategorySuffixes(Suffixes) (select distinct  right(erc_desc,len(erc_desc)-len(@CategoryPrefix)-1) from event_reason_catagories where ( left(erc_desc,len(@CategoryPrefix)) = @CategoryPrefix)  and (len(erc_desc) > Len(@CategoryPrefix)))  
  
  
select * from #CategorySuffixes order by Suffixes  
  
  
  
  
