 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetTarget  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
06/30/03 MKW Updated for 215.508  
*/  
  
  
CREATE PROCEDURE dbo.spLocal_GetTarget  
@OutputValue  varchar(25) OUTPUT,  
@PU_Id   int,  
@Var_Id   int,  
@TimeStamp_Str varchar(30)  
AS  
  
SET NOCOUNT ON  
  
DECLARE @As_Id  int,  
  @Prod_Id int,  
  @TimeStamp datetime  
  
SELECT @TimeStamp = convert(datetime, @TimeStamp_Str)  
  
-- Add a second so get the new product in the case of a Product Change  
SELECT @TimeStamp = dateadd(s, 1, @TimeStamp)  
  
SELECT @Prod_Id = Prod_Id  
FROM [dbo].Production_Starts  
WHERE PU_Id = @PU_Id  
  AND Start_Time <= @TimeStamp  
  AND (End_Time > @TimeStamp OR End_Time IS NULL)      
  
  
SELECT @OutputValue = Target  
FROM [dbo].Var_Specs  
WHERE Var_Id = @Var_Id  
  AND Prod_id = @Prod_id  
  AND Effective_Date <= @TimeStamp  
  AND (Expiration_Date > @TimeStamp OR Expiration_Date IS NULL)  
  
IF @OutputValue = NULL  
     BEGIN  
     SELECT @OutputValue = ''  
     END  
  
SET NOCOUNT OFF  
  
