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
  
CREATE procedure dbo.spLocal_FaultCountByPeriod  
@OutputValue varchar(25) OUTPUT,  
@PU_ID int,  
@Var_ID int,  
@EndTime datetime,  
@Fault_Desc varchar(50)  
AS  
  
SET NOCOUNT ON   
  
DECLARE @StartTime datetime  
DECLARE @FaultCount int  
DECLARE @Duration int  
DECLARE @Fault_ID INT  
DECLARE @Window_Start_Time datetime  
DECLARE @Last_Record_Time datetime  
  
SELECT @Fault_Desc = LTRIM(RTRIM(@Fault_Desc))  
  
SELECT @Duration = Sampling_Window  
FROM [dbo].Variables  
WHERE Var_ID = @Var_ID  
  
IF @Duration > 0  
BEGIN  
    SELECT @Window_Start_Time = Dateadd(mi, -@Duration, @EndTime)  
  
    SELECT TOP 1 @Last_Record_Time = Result_On  
    FROM [dbo].tests   
    WHERE Var_ID = @Var_ID AND Result_On > @Window_Start_Time AND Result_On < @EndTime  
    ORDER BY Result_On DESC  
  
    IF @Last_Record_Time IS NULL  
        SELECT @StartTime = @Window_Start_Time  
    ELSE  
        SELECT @StartTime = @Last_Record_Time  
  
  SELECT @Fault_ID = TEFault_ID   
 FROM [dbo].Timed_Event_Fault   
 WHERE TEFault_Name = @Fault_Desc   
  
  SELECT @FaultCount = Count(TEFault_ID)   
  FROM [dbo].Timed_Event_Details  
  WHERE Pu_id = @PU_ID and TEFault_ID = @FAULT_ID And Start_Time > @StartTime And Start_Time <=@EndTime  
  
  SELECT @OutputValue = Convert(varchar(25), @FaultCount)  
END  
  
  
SET NOCOUNT OFF  
