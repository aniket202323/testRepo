   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
  
CREATE procedure dbo.spLocal_DownTimeCurrent  
@OutputValue varchar(25) OUTPUT,  
@PU_ID int,  
@TimeStamp datetime  
As  
  
SET NOCOUNT ON  
  
Declare @TEDet_Id int  
Select @TEDet_Id = Null  
  
Select @TEDet_Id = TEDet_Id  
From [dbo].Timed_Event_Details  
Where Start_Time < @TimeStamp And (End_Time > @TimeStamp Or End_Time Is Null) And PU_Id = @PU_Id  
  
If @TEDet_Id Is Not Null  
     Select @OutputValue = '1'  
Else  
     Select @OutputValue = '0'  
  
  
SET NOCOUNT OFF  
  
