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
  
CREATE procedure dbo.spLocal_FaultCountByTime   
@OutputValue varchar(25) OUTPUT,  
@PU_ID int,  
@StartTime datetime,  
@EndTime datetime,  
@Fault_Desc varchar(50)  
AS  
  
SET NOCOUNT ON  
  
DECLARE @FaultCount int  
DECLARE @Fault_ID INT  
  
SELECT @Fault_Desc = LTRIM(RTRIM(@Fault_Desc))  
  
SELECT @Fault_ID = TEFault_ID FROM [dbo].Timed_Event_Fault WHERE TEFault_Name = @Fault_Desc   
  
SELECT @FaultCount = Count(TEFault_ID)   
FROM [dbo].Timed_Event_Details  
WHERE Pu_id = @PU_ID and TEFault_ID = @FAULT_ID And Start_Time > @StartTime And Start_Time <=@EndTime  
  
SELECT @OutputValue = Convert(varchar(25), @FaultCount)  
  
SET NOCOUNT OFF  
  
