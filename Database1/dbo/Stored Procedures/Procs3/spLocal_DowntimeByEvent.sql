    /*  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Added version.  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_DowntimeByEvent  
Author:   Barry Stewart, Stier Automation  
Date Created:  09/19/02  
  
Description:  
=========  
This procedure summarizes downtime duration for a rate loss event.   
  
Change Date Who What  
=========== ==== =====  
  
*/  
CREATE PROCEDURE dbo.spLocal_DowntimeByEvent  
@Output_Value  varchar(25) OUTPUT,  
@PU_Id   int,  
@RL_Start_Time  datetime,  
@RL_End_Time  datetime,  
@Conversion  float  
As  
  
SET NOCOUNT ON  
  
Declare @Start_Time  datetime,  
 @End_Time  datetime,  
 @Var_Precision  int,  
 @Downtime  real  
   
     Select @Var_Precision = 2  
     Select @Downtime = 0.0  
     Select @Downtime = isnull(convert(real, Sum(Datediff(s,  Case   
        When Start_Time < @RL_Start_Time Then @RL_Start_Time  
               Else Start_Time   
        End,  
            Case   
        When End_Time > @RL_End_Time Or End_Time Is Null Then @RL_End_Time  
         Else End_Time   
        End)))/@Conversion, 0.0)  
     From [DBO].Timed_Event_Details  
     Where PU_Id = @PU_Id   
     And TEStatus_Id Is Null  
     And Start_Time < @RL_End_Time  
     And (End_Time > @RL_Start_Time Or End_Time Is Null)  
  
    Select @Output_Value = ltrim(str(@Downtime, 15, @Var_Precision))  
  
SET NOCOUNT OFF  
  
