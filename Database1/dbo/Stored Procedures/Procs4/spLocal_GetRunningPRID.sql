  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.4  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetRunningPRID  
Author:   Barry Stewart, Stier Automation  
Date Created:  07/02/02  
  
Description:  
=========  
Returns the currently running PRID.  
  
Change Date Who   What  
=========== ====   =====  
08/14/02 JSJ/BAS/VMK  Added text when there is no running PR  
10/18/02 BAS   Added join to make sp run more efficiently.  
04/25/03 BAS   Decreased window from 20 to 5 days  
*/  
  
  
CREATE procedure dbo.spLocal_GetRunningPRID   
@Output_Value  varchar(25) OUTPUT,  
@Var_Id  int,  
@PU_Id  int  
AS  
SET NOCOUNT ON  
  
DECLARE @PR as varchar(25)  
  
Select Top 1 @PR  =  t.Result  
From [dbo].Events e   
 Left Join [dbo].tests t On e.TimeStamp = t.Result_On And t.Var_Id = @Var_Id  
Where e.PU_Id = @PU_Id  
And e.Event_Status=4  
And e.TimeStamp > getdate()-5        /*Search for Running Events back 5 days*/  
Order By TimeStamp Desc  
  
If @PR is Null   
 Select @Output_Value = 'No Running PR'  
Else  
 Select @Output_Value = @PR  
  
SET NOCOUNT OFF  
  
