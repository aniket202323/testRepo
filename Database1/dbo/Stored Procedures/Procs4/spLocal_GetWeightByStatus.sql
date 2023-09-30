 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetWeightByStatus  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
  
CREATE procedure dbo.spLocal_GetWeightByStatus  
@Output_Value As varchar(25) OUTPUT,  
@PU_ID int,  
@Var_ID int,  
@Weight_Var_ID int,  
@End_Time datetime,  
@Status varchar(50)  
AS  
  
SET NOCOUNT ON  
  
DECLARE @Status_ID int  
DECLARE @Start_Time datetime  
DECLARE @Duration int  
DECLARE @Total_Weight real  
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
  
SELECT @Total_Weight = SUM(convert(real,tests.Result))   
FROM [dbo].Events   
 INNER JOIN [dbo].tests ON Events.TimeStamp = tests.Result_On  
WHERE Events.PU_ID = @PU_ID AND   
      Events.Event_Status = @Status_ID AND   
      tests.Var_ID = @Weight_Var_ID AND  
      Events.TimeStamp > @Start_Time AND  
      Events.TimeStamp <= @End_Time  
  
SELECT @Output_Value = convert(varchar(25),@Total_Weight)  
  
SET NOCOUNT OFF  
  
