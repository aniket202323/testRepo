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
  
CREATE procedure dbo.spLocal_GetSourceEventVariableValue  
@OutputValue varchar(25) OUTPUT,  
@Var_id int,  
@Event_Id int,  
@MaxLevels int  
AS  
SET NOCOUNT ON  
  
DECLARE @Timestamp   datetime,  
                  @Source_PU_Id int,  
                  @PU_id  int,  
                  @Counter  int  
  
Select @Source_PU_Id = PU_Id From [dbo].Variables Where Var_Id = @Var_Id  
  
Select @Counter = 0  
While @Counter < @MaxLevels  
     Begin  
     --Select @Event_Id = Source_Event FROM Events WHERE Event_Id = @Event_Id  
     Select @Event_Id = Source_Event_Id From [dbo].Event_Components Where Event_Id = @Event_Id  
     Select @PU_Id = PU_Id, @TimeStamp = TimeStamp From [dbo].Events Where Event_Id = @Event_Id  
     If @PU_Id = @Source_PU_Id  
          Begin  
           Select @Timestamp = TimeStamp FROM [dbo].Events WHERE Event_Id = @Event_Id  
           Select @OutputValue = convert(varchar(25), Result) FROM [dbo].tests WHERE Var_Id = @Var_Id AND Result_On = @Timestamp  
           Break  
          End  
     Select @Counter = @Counter + 1  
     End  
  
SET NOCOUNT OFF  
  
