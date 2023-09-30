   /*  
Stored Procedure: spLocal_GlblChangeOverCharDesc  
Author:    Fran Osorno  
Date Created:  04/22/2004  
Version:    1.0  
  
Description:  
=========  
This procedure will return a list of Char_desc based on the desc passed and adding Changeover to it  
  
  
Change Date  Who What  
=========== ==== =====  
04/22/0225   FGO  Created  
02/23/07   fgo  updated to best practices  
06/25/08   fgo  changed code to global name and for coding practices  
*/  
  
CREATE  PROCEDURE dbo.spLocal_GlblChangeOverCharDesc  
  @PropDesc VARCHAR(50)  
  
AS  
/* Test Setup */  
  
/*  
 SELECT @PropDesc = 'FTL4 East Wrapper'  
*/  
  
SELECT char_desc  
 FROM dbo.characteristics AS chars with(nolock)  
  LEFT JOIN dbo.product_properties AS pp with(nolock) ON (pp.prop_id = chars.prop_id)  
 WHERE prop_desc = @PropDesc + ' Changeover'  
  AND char_desc <> 'All Brands'  
 ORDER BY char_desc  
  
