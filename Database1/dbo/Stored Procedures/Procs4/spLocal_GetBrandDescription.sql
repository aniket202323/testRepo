 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-01  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_GetBrandDescription  
Author:   ??  
Date Created:  ??/??/??  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
03/26/03 MKW Changed the input from a data type of int to varchar(25)  
*/  
  
CREATE procedure dbo.spLocal_GetBrandDescription  
@OutputValue varchar(25) OUTPUT,  
@Prod_Code  varchar(25)  
AS  
  
SET NOCOUNT ON  
  
DECLARE @Desc as varchar(25)  
  
SELECT @Desc = Prod_Desc  
FROM [dbo].Products  
WHERE Prod_Code = @Prod_Code  
  
SELECT @OutputValue = @Desc  
  
SET NOCOUNT OFF  
  
