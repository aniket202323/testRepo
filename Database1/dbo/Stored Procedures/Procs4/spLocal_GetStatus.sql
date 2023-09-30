 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetStatus  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
Returns the text equivalent of the event status.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
  
CREATE procedure dbo.spLocal_GetStatus   
@Output_Value  varchar(25) OUTPUT,  
@Status_Id   int  
AS  
SET NOCOUNT ON  
  
Select @Output_Value = convert(varchar(25), ProdStatus_Desc) From [dbo].Production_Status Where ProdStatus_Id = @Status_Id  
  
SET NOCOUNT OFF  
  
