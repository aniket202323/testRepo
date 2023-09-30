     /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetBrandToDateAvg  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
CREATE procedure dbo.spLocal_GetBrandToDateAvg  
@Output_Value As varchar(25) OUTPUT,  
@PU_Id int,  
@Var_Id int,  
@End_Time datetime  
AS  
  
SET NOCOUNT ON  
  
Declare @Start_Time datetime  
  
Select @Start_Time = Max(Start_Time)  
From [dbo].Production_Starts  
Where PU_Id  = @PU_Id And Start_Time < @End_Time  
  
Select @Output_Value = Avg(convert(float,Result))  
From [dbo].tests  
Where Var_Id = @Var_Id And Result_On > @Start_Time and Result_On <= @End_Time And Result Is Not Null  
  
SET NOCOUNT OFF  
  
