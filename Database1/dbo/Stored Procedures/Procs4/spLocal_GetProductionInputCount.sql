  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
  
CREATE procedure dbo.spLocal_GetProductionInputCount  
@Output_Value As varchar(25) OUTPUT,  
@PU_Id int  
AS  
  
SET NOCOUNT ON  
  
Select @Output_Value = Count(PEI_Id)  
From [dbo].PrdExec_Inputs  
Where PU_Id = @PU_Id  
  
SET NOCOUNT OFF  
  
