   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-17  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_UpdateAutologSheet  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
07/29/03 MKW Updated timestamp for 215.508  
*/  
  
CREATE PROCEDURE dbo.spLocal_UpdateAutologSheet  
@OutputValue varchar(25) OUTPUT,  
@TimeStamp datetime,  
@Sheet_Id int  
AS  
SET NOCOUNT ON  
  
/* Calculate timestamp of the Product/Time variable */  
SELECT @TimeStamp = dateAdd(s, 1, @TimeStamp)  
  
/* Create the Product Change column and delete the Product/Time column */  
SELECT 7,  
  @Sheet_Id,  
  1,  
  1,  
  @TimeStamp,  
  0  
  
SELECT @OutputValue = @Sheet_Id  
  
SET NOCOUNT OFF  
  
