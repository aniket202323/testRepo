 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-09  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_EndOfDay  
Author:   MSI  
Date Created:    
  
Description:  
=========  
System stored procedure.  Do Not Edit/Delete.  
  
Change Date Who What  
=========== ==== =====  
*/  
  
CREATE PROCEDURE dbo.spLocal_ShiftInfo  
@ShiftInterval int output,  
@ShiftOffset int output  
AS  
SET NOCOUNT ON  
Select @ShiftInterval = Convert(int,Value) From [dbo].Site_Parameters Where Parm_Id = 16  
Select @ShiftOffset = Convert(int,Value) From [dbo].Site_Parameters Where Parm_Id = 17  
SET NOCOUNT OFF  
