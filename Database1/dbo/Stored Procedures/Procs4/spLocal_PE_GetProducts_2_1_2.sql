      /*  
Stored Procedure: spLocal_PE_GetProducts_2_1_2  
Author:   S. Stier (Stier Automation)  
Date Created:  1/14/04  
  
Description:  
=========  
returns All products for the converting units  
  
XLA Version Change Date Who What  
============ =========== ==== =====  
V0.1.4  1/14/04  SLS Initial Release  
V0.1.5  1/27/04  SLS     Release to B.Barre  
V2.1.2  9/21/04  BAS Renamed sp with XLA version.  
  
*/  
  
  
CREATE PROCEDURE dbo.spLocal_PE_GetProducts_2_1_2  
  
AS   
  
  
-----------------------------------------------------------  
-- Declare program variables.  
-----------------------------------------------------------  
  
    
------------------------------------------------------------  
---- CREATE  Temp TABLES   -----------  
------------------------------------------------------------  
  
Create table #TempProducts(   
 prod_code  varchar(50),  
 prod_Desc varchar(50)  
)  
  
  
  
 insert into #TempProducts (prod_code, prod_Desc) (select  prod_code, prod_Desc from products p   
 Inner join Product_family pf on  p.Product_Family_id = pf.Product_family_id  
                WHERE (Patindex('%Cvtg%', pf.Product_family_Desc) <> 0) and (Patindex('%Raw%', pf.Product_family_Desc) = 0))  
  
  
select * from #TempProducts order by Prod_desc  
  
drop table #TempProducts  
  
  
  
  
