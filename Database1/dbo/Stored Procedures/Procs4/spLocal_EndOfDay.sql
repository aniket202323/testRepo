  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_EndOfDay  
Author:   MSI  
Date Created:    
  
Description:  
=========  
System stored procedure.  Do Not Edit/Delete.  
  
Change Date Who What  
=========== ==== =====  
*/  
  
  
CREATE PROCEDURE dbo.spLocal_EndOfDay  
@EndOfDayHour int output,  
@EndOfDayMinute int output  
AS  
Select @EndOfDayHour = Convert(int,Value) From [DBO].Site_Parameters Where Parm_Id = 14  
Select @EndOfDayMinute = Convert(int,Value) From [DBO].Site_Parameters Where Parm_Id = 15   
  
