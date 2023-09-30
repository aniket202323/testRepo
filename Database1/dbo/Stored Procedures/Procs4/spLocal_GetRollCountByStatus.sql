  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetRollCountByStatus  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
  
CREATE procedure dbo.spLocal_GetRollCountByStatus   
@Output_Value As varchar(25) OUTPUT,  
@PU_ID int,  
@End_Time datetime,  
@Status varchar(50)  
AS  
SET NOCOUNT ON  
  
DECLARE @Status_ID int  
DECLARE @Actual_Status_ID int  
  
SELECT @Status = LTRIM(RTRIM(@Status))  
  
SELECT @Status_ID = ProdStatus_ID  
FROM [dbo].Production_Status  
WHERE ProdStatus_Desc = @Status  
  
SELECT @Actual_Status_ID = Events.Event_Status  
FROM [dbo].Events  
WHERE Events.PU_ID = @PU_ID AND   
      Events.TimeStamp = @End_Time  
  
IF @Actual_Status_ID = @Status_ID  
      SELECT @Output_Value = 1  
ELSE  
      SELECT @Output_Value = 0  
  
SET NOCOUNT OFF  
  
