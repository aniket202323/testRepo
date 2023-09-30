  
/*  
Stored Procedure: spLocal_GetTestValueByDowntime  
Author:   Matthew Wells (MSI)  
Date Created:  02/20/02  
  
Description:  
=========  
Get test value by downtime.  
  
Change Date Who What  
=========== ==== =====  
02/20/02 MKW Created.  
*/  
  
CREATE procedure dbo.spLocal_GetTestValueByDowntime  
@Output_Value   varchar(25) OUTPUT,  
@Var_Id   int,  
@Source_Var_Id int,  
@TimeStamp  datetime  
AS  
  
Declare @PU_Id int,  
 @End_Time datetime  
  
Select @PU_Id = PU_Id  
From Variables  
Where Var_Id = @Var_Id  
  
Select @End_Time = End_Time  
From Timed_Event_Details  
Where PU_Id = @PU_Id And Start_Time = @TimeStamp  
  
If @End_Time Is Not Null  
     Select @Output_Value = Result  
     From tests  
     Where Var_Id = @Source_Var_Id And Result_On = @End_Time  
Else  
     Select @Output_Value = ''  
  
  
  
  
  
  
  
  
  
  
  
  
  
