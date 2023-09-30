  /*  
Stored Procedure: dbo.spLocal_GlblChangeOverProducts  
Author:    Fran Osorno  
Date Created:  06/22/2008  
Version:    1.0  
  
Description:  
=========  
This procedure will return the prod_code and prod_desc from the inputs  
  
  
Change Date  Who What  
=========== ==== =====  
06/22/2008   FGO  Created  
06/25/08   fgo  changed code to global name and for coding practices  
*/  
  
CREATE   PROCEDURE dbo.spLocal_GlblChangeOverProducts  
 @prodcode1 varchar(25),  
 @prodcode2 varchar(25)  
as   
--select @prodcode1 = '84983624',  
--  @prodcode2 ='84983743'  
select prod_code,prod_desc from dbo.products with(nolock) where prod_code in (@prodcode1,@prodcode2)  
  
