  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetPRID  
Author:   Matthew Wells (MSI)  
Date Created:  10/30/01  
  
Description:  
=========  
Gets the PRID from the Event_Details  
  
Change Date Who What  
=========== ==== =====  
10/30/01 MKW Created procedure.  
*/  
CREATE PROCEDURE dbo.spLocal_GetPRID  
@Output_Value varchar(25) OUTPUT,  
@Event_Id int  
As  
  
SET NOCOUNT ON  
  
Select @Output_Value = Alternate_Event_Num  
From [dbo].Event_Details  
Where Event_Id = @Event_Id  
  
SET NOCOUNT OFF  
  
