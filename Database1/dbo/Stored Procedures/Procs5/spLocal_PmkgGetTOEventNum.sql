 /*  
Stored Procedure: spLocal_PmkgGetTOEventNum  
Author:   Dan Hinchey (MSI)  
Date Created:  03/13/03  
  
Description:  
============  
Retrieves Turnover event number.  
  
Change Date Who What  
=========== ==== =====  
*/  
CREATE PROCEDURE dbo.spLocal_PmkgGetTOEventNum  
@OutputValue VARCHAR(25) OUTPUT,  
@Next_TO_Value VARCHAR(25)  
AS  
SELECT @OutputValue = @Next_TO_Value  
