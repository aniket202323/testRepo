  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-04  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_PmkgGetTONum  
Author:   Dan Hinchey (MSI)  
Date Created:  03/13/03  
  
Description:  
============  
Retrieves Turnover number based on the Event ID  
  
Change Date Who What  
=========== ==== =====  
*/  
  
CREATE PROCEDURE dbo.spLocal_PmkgGetTONum  
@OutputValue VARCHAR(25) OUTPUT,  
@Event_Id INT  
AS  
SET NOCOUNT ON  
  
SELECT @OutputValue = Right(Event_Num,3)  
  FROM [dbo].Events  
  WHERE Event_Id = @Event_Id  
IF ISNUMERIC(@OutputValue) = 1  
 SELECT @OutputValue = CONVERT(INT, @OutputValue)  
ELSE  
 SELECT @OutputValue = NULL  
  
SET NOCOUNT OFF  
