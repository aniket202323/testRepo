 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-22  
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
  
CREATE procedure dbo.spLocal_UptimeByEvent   
@OutputValue varchar(25) OUTPUT,  
@PU_Id int,   
@TimeStamp datetime  
AS  
SET NOCOUNT ON  
  
Declare @PreviousStart datetime  
Declare @PreviousEnd datetime  
  
--Go Find Record Before This One  
Select @PreviousStart = NULL  
Select @PreviousStart = max(Start_Time) From [dbo].Timed_Event_Details Where PU_Id = @PU_Id and Start_Time < @TimeStamp and Start_Time > dateadd(day,-5,@TimeStamp)  
  
Select @PreviousEnd = End_Time From [dbo].Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @PreviousStart  
  
  
If @PreviousEnd is Not Null  
  Select @OutputValue = convert(varchar(25),datediff(second, @PreviousEnd, @TimeStamp) / 60.0)  
Else  
  Select @OutputValue = 'DONOTHING'  
  
SET NOCOUNT OFF  
  
