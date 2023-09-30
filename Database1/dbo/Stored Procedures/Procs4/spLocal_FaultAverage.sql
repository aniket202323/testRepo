   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
CREATE procedure dbo.spLocal_FaultAverage  
@OutputValue varchar(25) OUTPUT,  
@PU_Id int,   
@TimeStamp datetime  
AS  
  
SET NOCOUNT ON  
Declare @CurrentFault int  
Declare @Avg float  
  
  
--Get The Current Fault Id  
Select @CurrentFault = NULL  
Select @CurrentFault = TEFault_Id From [dbo].Timed_Event_Details Where PU_Id = @PU_Id and Start_Time = @TimeStamp  
  
Select @Avg = Avg(datediff(second, Start_Time, End_Time)/60.0) From Timed_Event_Details Where PU_Id = @PU_Id and Start_Time > dateadd(day,-90,@TimeStamp) and Start_Time < @TimeStamp  
  
If @Avg is Not Null  
  Select @OutputValue = convert(varchar(25),@Avg)  
Else  
  Select @OutputValue = null  
  
  
SET NOCOUNT OFF  
  
