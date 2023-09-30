   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-01  
Version  : 1.0.1  
Purpose  : Added [dbo]. template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_ExpireRolls  
Author:   Matthew Wells (MSI)  
Date Created:  12/01/01  
  
Description:  
=========  
This procedure expires old rolls so they no long appear in the Genealogy window.  MUST MODIFY ROLLS PU_ID!!!!  
  
Change Date Who What  
=========== ==== =====  
02/01/02 MKW Added comment  
*/  
  
CREATE PROCEDURE spLocal_ExpireRolls  
AS  
  
SET NOCOUNT ON  
  
Declare @Consumed_Status int,  
 @Inventory_Window int,  
 @Rolls_PU_Id  int  
   
  
Select  @Consumed_Status = 8,  
 @Rolls_PU_Id   = 12,  
 @Inventory_Window = 120  
  
Update [dbo].Events  
Set Event_Status = @Consumed_Status  
Where PU_Id = @Rolls_PU_Id And Event_Status <> @Consumed_Status And TimeStamp < DateAdd(dd, -@Inventory_Window, getdate())  
  
SET NOCOUNT OFF  
  
