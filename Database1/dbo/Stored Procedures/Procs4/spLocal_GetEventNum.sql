 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
  
CREATE procedure dbo.spLocal_GetEventNum  
@OutputValue varchar(25) OUTPUT,  
@Event_Id int  
As  
SET NOCOUNT ON  
  
Select @OutputValue = Event_Num  
From [dbo].Events  
Where Event_Id = @Event_Id  
  
SET NOCOUNT OFF  
  
