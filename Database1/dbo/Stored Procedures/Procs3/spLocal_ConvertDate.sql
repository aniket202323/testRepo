  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Version + SET NOCOUNT ON/OFF  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_ConvertDate  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
Converts the date into standard MSI format.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
CREATE procedure dbo.spLocal_ConvertDate  
@OutputValue varchar(30) OUTPUT,  
@TimeStamp datetime,  
@Format varchar(30)  
As  
SET NOCOUNT ON  
  
Declare @Year   varchar(20),  
 @Month varchar(20),  
 @Day   varchar(20)  
   
/* Add something to look up a Site specific date format */  
Select   @Year = datepart(yy, @TimeStamp),  
 @Month = datename(mm, @TimeStamp),  
 @Day = datepart(dd, @TimeStamp)  
  
Select @OutputValue = @Day+'-'+Left(@Month, 3)+'-'+Right(@Year, 2)  
  
  
SET NOCOUNT OFF  
