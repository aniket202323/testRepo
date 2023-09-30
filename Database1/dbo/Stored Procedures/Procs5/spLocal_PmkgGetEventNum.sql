  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-04  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_PmkgGetEventNum  
Author:   Dan Hinchey (MSI)  
Date Created:  03/13/03  
  
Description:  
============  
Retrieves event number based on the Event ID  
  
Change Date Who What  
=========== ==== =====  
*/  
  
  
  
CREATE PROCEDURE dbo.spLocal_PmkgGetEventNum  
@OutputValue VARCHAR(25) OUTPUT,  
@Event_Id INT  
AS  
  
SET NOCOUNT ON  
  
SELECT @OutputValue = Event_Num  
 FROM [dbo].Events  
 WHERE Event_Id = @Event_Id  
  
SET NOCOUNT OFF  
