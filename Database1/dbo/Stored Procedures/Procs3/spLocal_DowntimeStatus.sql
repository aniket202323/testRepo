  /*  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_DowntimeStatus  
Author:   Matthew Wells (MSI)  
Date Created:  11/23/01  
  
Description:  
=========  
This procedure retrieves the downtimes status for the associated downtime event.  
  
Change Date Who What  
=========== ==== =====  
11/23/01 MKW Created  
05/22/02 MKW Added default status of 'Valid' (ITSM: 3835353)  
*/  
CREATE PROCEDURE dbo.spLocal_DowntimeStatus  
@Output_Value varchar(25) OUTPUT,  
@TEDet_Id  int  
As  
  
SET NOCOUNT OFF  
  
Declare @TimeStamp   datetime,  
 @TEStatus_Id   int,  
 @Default_TEStatus_Name varchar(25)  
  
/* Initialize */  
Select @TEStatus_Id   = Null,  
 @Default_TEStatus_Name = 'Valid'  
  
/* Validate Arguments */  
Select @TEStatus_Id = TEStatus_Id  
From [dbo].Timed_Event_Details  
Where TEDet_Id = @TEDet_Id  
  
If @TEStatus_Id Is Not Null  
     Select @Output_Value = TEStatus_Name  
     From [dbo].Timed_Event_Status  
     Where TEStatus_Id = @TEStatus_Id  
Else  
     Select @Output_Value = @Default_TEStatus_Name  
  
SET NOCOUNT OFF  
