   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetRethreadCount  
Author:   Matthew Wells (MSI)  
Date Created:  11/12/01  
  
Description:  
=========  
This stored procedure calculates the number of rethread attempts.  
  
Change Date Who What  
=========== ==== =====  
11/12/01 MKW Creation.  
*/  
CREATE procedure dbo.spLocal_GetRethreadCount  
@Output_Value  varchar(25) OUTPUT, -- Category  
@Start_Time_Str varchar(25),  -- a : Start Time  
@End_Time_Str  varchar(25),  -- b : End Time  
@PU_Id   int   -- c : Rethread count PU_Id  
As  
SET NOCOUNT ON  
/* Declarations */  
Declare @Rethread_Count int,  
 @Start_Time  datetime,  
 @End_Time  datetime  
  
/* Convert arguments */  
Select @Start_Time = convert(datetime, @Start_Time_Str),  
           @End_Time = convert(datetime, @End_Time_Str)  
  
Select @Rethread_Count = count(Event_Id)  
From [dbo].Events  
Where PU_Id = @PU_Id And TimeStamp > @Start_Time And TimeStamp <= @End_Time  
  
Select @Output_Value = convert(varchar(25), @Rethread_Count)  
  
SET NOCOUNT OFF  
  
