  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-16  
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
CREATE procedure dbo.spLocal_TriggerGenealogyCalcs  
@OutputValue varchar(25) OUTPUT,  
@Parent_Var_Id int,  
@Parent_PU_Id int,  
@Child_Var_id int,  
@Child_Event_Id int  
AS  
SET NOCOUNT ON  
  
DECLARE @Child_TimeStamp   datetime,  
                  @Parent_TimeStamp   datetime,  
      @Parent_Event_Id  int  
  
Select @Parent_Event_Id = Source_Event, @Child_TimeStamp = TimeStamp From [dbo].Events Where Event_Id = @Child_Event_Id  
Select @OutputValue = convert(varchar(25), Result) FROM [dbo].tests WHERE Var_Id = @Child_Var_Id AND Result_On = @Child_TimeStamp  
Select @Parent_TimeStamp = TimeStamp From [dbo].Events Where Event_Id = @Parent_Event_Id  
Select 2, @Parent_Var_Id, @Parent_PU_Id, 6, 0, @OutputValue, @Parent_Timestamp, 1, 0  
  
  
  
  
SET NOCOUNT OFF  
  
  
