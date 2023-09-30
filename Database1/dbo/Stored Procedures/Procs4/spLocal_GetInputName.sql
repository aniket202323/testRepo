  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetInputName  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
07/01/04 MKW Updated for Facial Line 1.  
*/  
  
  
CREATE  PROCEDURE dbo.spLocal_GetInputName  
@Output_Value As varchar(25) OUTPUT,  
@Event_Id int  
AS  
SET NOCOUNT ON  
  
DECLARE @PEI_Id   int,  
 @PUId   int,  
 @PLId   int,  
 @Source_Event_Id int  
  
SELECT @Source_Event_Id = Source_Event_Id   
FROM [dbo].Event_Components   
WHERE Event_Id = @Event_Id  
  
SELECT TOP 1 @PEI_Id = PEI_Id   
FROM [dbo].PrdExec_Input_Event_History   
WHERE Event_Id = @Source_Event_Id   
ORDER BY TimeStamp DESC  
  
-- MKW - 07/01/04 - If no input, check for Facial inputs (ie. inputs on another unit)  
IF @PEI_Id IS NULL  
 BEGIN  
 SELECT @PUId = PU_Id  
 FROM [dbo].Events  
 WHERE Event_Id = @Event_Id  
  
 SELECT @PLId = PL_Id  
 FROM [dbo].Prod_Units  
 WHERE PU_Id = @PUId  
  
 SELECT TOP 1 @PEI_Id  = pei.PEI_Id  
 FROM [dbo].PrdExec_Input_Event pei  
  INNER JOIN [dbo].PrdExec_Inputs pe ON pei.PEI_Id = pe.PEI_Id  
      AND pe.PEI_Id > 0  -- Just to force the index  
  INNER JOIN [dbo].Prod_Units pu ON pe.PU_Id = pu.PU_Id  
 WHERE PL_Id = @PLId  
  AND GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, 'DETAILSUNIT=') = @PUId  
  AND pei.Event_Id = @Source_Event_Id  
 ORDER BY TimeStamp DESC  
 END  
  
SELECT @Output_Value = convert(varchar(25), Input_Name)   
FROM [dbo].PrdExec_Inputs   
WHERE PEI_Id = @PEI_Id   
  
SET NOCOUNT OFF  
  
