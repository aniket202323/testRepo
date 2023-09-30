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
  
CREATE procedure dbo.spLocal_GetParentValueBySourceId  
@OutputValue varchar(25) OUTPUT,  
@Var_id int,  
@Event_Id int  
AS  
  
SET NOCOUNT ON  
  
DECLARE @Timestamp   datetime  
  
Select @Event_Id = Source_Event From [dbo].Events Where Event_Id = @Event_Id  
Select @TimeStamp = TimeStamp From [dbo].Events Where Event_Id = @Event_Id  
Select @OutputValue = convert(varchar(25), Result) FROM [dbo].tests WHERE Var_Id = @Var_Id AND Result_On = @Timestamp  
  
SET NOCOUNT OFF  
  
