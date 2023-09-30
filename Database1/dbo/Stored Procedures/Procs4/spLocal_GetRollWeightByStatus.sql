 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetRollWeightByStatus  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
  
CREATE procedure dbo.spLocal_GetRollWeightByStatus  
@Output_Value As varchar(25) OUTPUT,  
@PU_ID int,  
@Weight_Var_ID int,  
@End_Time datetime,  
@Status varchar(50)  
AS  
SET NOCOUNT ON  
  
DECLARE @Status_ID int  
DECLARE @Weight varchar(25)  
  
SELECT @Status = LTRIM(RTRIM(@Status))  
  
SELECT @Status_ID = ProdStatus_ID  
FROM [dbo].Production_Status  
WHERE ProdStatus_Desc = @Status  
  
SELECT @Weight = tests.Result   
FROM [dbo].Events   
 INNER JOIN [dbo].tests ON Events.TimeStamp = tests.Result_On  
WHERE Events.PU_ID = @PU_ID AND   
      Events.Event_Status = @Status_ID AND   
      tests.Var_ID = @Weight_Var_ID AND  
      Events.TimeStamp = @End_Time  
  
SELECT @Output_Value = @Weight  
  
SET NOCOUNT OFF  
  
