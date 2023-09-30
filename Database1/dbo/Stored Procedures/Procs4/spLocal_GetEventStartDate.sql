     /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetEventStartDate  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
CREATE procedure dbo.spLocal_GetEventStartDate   
@OutputValue varchar(25) OUTPUT,  
@Event_Id int,  
@Check_Status varchar(25)  
AS  
  
SET NOCOUNT ON  
  
Declare @Start_Time   datetime,  
 @TimeStamp  datetime,  
 @Event_Status  int,  
 @Event_Status_Desc varchar(25)  
  
Select @TimeStamp = TimeStamp, @Start_Time = Start_Time, @Event_Status = Event_Status From [dbo].Events Where Event_Id = @Event_Id  
Select @Event_Status_Desc = ProdStatus_Desc From [dbo].Production_Status Where ProdStatus_Id = @Event_Status  
  
If @Start_Time Is Not Null  And (datediff(s, @Start_Time, @TimeStamp) > 0 Or @Event_Status_Desc = @Check_Status)  
     Exec spLocal_ConvertDate @OutputValue OUTPUT, @Start_Time, Null  
Else  
     Select @OutputValue = Null  
  
SET NOCOUNT OFF  
  
