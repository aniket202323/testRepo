  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Version + SET NOCOUNT ON/OFF  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_ConvertTime  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
Converts the time into standard MSI format.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
  
CREATE procedure dbo.spLocal_ConvertTime  
@OutputValue varchar(30) OUTPUT,  
@TimeStamp datetime,  
@Format varchar(30)  
As  
  
SET NOCOUNT ON  
Select @OutputValue = convert(varchar(30), @TimeStamp, 108)  
SET NOCOUNT OFF  
  
