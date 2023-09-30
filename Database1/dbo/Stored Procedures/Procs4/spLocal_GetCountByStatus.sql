  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
  
CREATE procedure dbo.spLocal_GetCountByStatus  
@Output_Value As varchar(25) OUTPUT,  
@PU_ID int,  
@Var_ID int,  
@End_Time datetime,  
@Status varchar(50)  
AS  
  
SET NOCOUNT ON  
  
DECLARE @Status_ID int  
DECLARE @Start_Time datetime  
DECLARE @Duration int  
DECLARE @Count int  
DECLARE @Window_Start_Time datetime  
DECLARE @Last_Record_Time datetime  
  
SELECT @Status = LTRIM(RTRIM(@Status))  
  
SELECT @Duration = Sampling_Window  
FROM [dbo].Variables  
WHERE Var_ID = @Var_ID  
  
SELECT @Window_Start_Time = Dateadd(mi, -@Duration, @End_Time)  
  
SELECT TOP 1 @Last_Record_Time = Result_On  
FROM [dbo].tests  
WHERE Var_ID = @Var_ID AND Result_On > @Window_Start_Time AND Result_On < @End_Time  
ORDER BY Result_On DESC  
  
IF @Last_Record_Time IS NULL  
    SELECT @Start_Time = @Window_Start_Time  
ELSE  
    SELECT @Start_Time = @Last_Record_Time  
  
SELECT @Status_ID = ProdStatus_ID  
FROM [dbo].Production_Status  
WHERE ProdStatus_Desc = @Status  
  
SELECT @Count = Count(Events.Event_Status)   
FROM [dbo].Events  
WHERE Events.PU_ID = @PU_ID AND   
      Events.Event_Status = @Status_ID AND   
      Events.TimeStamp > @Start_Time AND  
      Events.TimeStamp <= @End_Time  
  
SELECT @Output_Value = convert(varchar(25),@Count)  
  
SET NOCOUNT OFF  
  
