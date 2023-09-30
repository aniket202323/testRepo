   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-16  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_TriggerRollSummaries  
Author:   Matthew Wells (MSI)  
Date Created:  06/04/02  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
08/20/02 MKW Rewrote sp to be much faster.  
*/  
  
  
CREATE PROCEDURE dbo.spLocal_TriggerRollSummaries  
@Output_Value  varchar(25) OUTPUT,  
@TimeStamp   datetime,  
@Start_Var_Id  int,  
@End_Var_Id  int,  
@Recalc_Var_Id int  
As  
SET NOCOUNT ON  
  
/* Testing   
Select  @TimeStamp  = '2001-11-22 14:04:00',  
 @Start_Var_Id = 7061,   
 @End_Var_Id = 7064,  
 @Recalc_Var_Id = 9999  
*/  
  
Declare @Result   varchar(25),  
 @Result_On   datetime,  
 @Value    int,  
 @PU_Id   int,  
 @Start_Time   datetime,  
 @End_Time   datetime,  
 @Event_Id   int,  
 @Loaded_Event_Id  int,  
 @Unloaded_Event_Id  int,  
 @PEI_Id   int  
  
Select @PU_Id = PU_Id  
From [dbo].Variables  
Where Var_Id = @Recalc_Var_Id  
  
Declare Inputs Cursor For  
Select PEI_Id  
From [dbo].PrdExec_Inputs  
Where PU_Id = @PU_Id  
For Read Only  
  
Open Inputs  
Fetch Next From Inputs Into @PEI_Id  
While @@FETCH_STATUS = 0  
     Begin  
     /* Reinitialization */  
     Select  @Start_Time  = Null,  
  @End_Time  = Null,  
  @Loaded_Event_Id = Null,  
  @Unloaded_Event_Id = Null  
  
     /* Get start time for this input */  
     Select TOP 1 @Start_Time   = TimeStamp,  
   @Loaded_Event_Id = Event_Id  
     From [dbo].PrdExec_Input_Event_History  
     Where PEI_Id = @PEI_Id And PEIP_Id = 1 And TimeStamp < @TimeStamp  
     Order By Timestamp Desc  
  
     /* Get end time for this input */  
     If @Start_Time Is Not Null And @Loaded_Event_Id Is Not Null  
          Begin  
          Select TOP 1  @End_Time   = TimeStamp,  
   @Unloaded_Event_Id = Event_Id  
          From [dbo].PrdExec_Input_Event_History  
          Where PEI_Id = @PEI_Id And PEIP_Id = 1 And TimeStamp > @TimeStamp  
          Order By TimeStamp Asc  
  
          If @End_Time Is Not Null And @Unloaded_Event_Id Is Null  
               Begin  
               Select TOP 1 @Result_On = e.TimeStamp  
               From [dbo].Event_Components ec  
                    Inner Join [dbo].Events e On ec.Event_Id = e.Event_Id And e.TimeStamp <= @Start_Time  
               Where Source_Event_Id = @Loaded_Event_Id  
               Order By e.TimeStamp Desc  
  
               Select @Result = Result  
               From [dbo].tests  
               Where Var_Id = @Recalc_Var_Id And Result_On = @Result_On  
  
               Select  2,        -- @Result_Set_Type  
  @Recalc_Var_Id,      -- @Var_Id  
  @PU_Id,        -- @PU_Id  
  26,        -- @User_ID       
  0,        -- @Cancelled  
  Case  When isnumeric(@Result) = 1 Then convert(int, @Result) + 1  
   Else 1  
   End,   
  @Result_On,       -- @Result_On  
  Case  When isnumeric(@Result) = 1 Then 2  
   Else 1  
   End,       -- @Transaction_Type  
  0        -- @Post_Update  
               End  
          End  
     Fetch Next From Inputs Into @PEI_Id  
     End  
  
Close Inputs  
Deallocate Inputs  
  
/*  
Declare Result_Times Cursor For  
Select s.Result_On  
From tests s  
     Inner Join tests e On s.Result_On = e.Result_On   
Where s.Var_Id = @Start_Var_Id And e.Var_Id = @End_Var_Id And s.Result Is Not Null And e.Result Is Not Null   
 And convert(datetime, s.Result) < @TimeStamp And convert(datetime, e.Result) > @TimeStamp  
For Read Only  
  
Open Result_Times  
Fetch Next From Result_Times Into @Result_On  
While @@FETCH_STATUS = 0  
     Begin  
     Select @Result = Null  
     Select @Result = Result  
     From tests  
     Where Var_Id = @Recalc_Var_Id And Result_On = @Result_On  
  
     If IsNumeric(@Result) = 1  
          Select 2, @Recalc_Var_Id, @PU_Id, 1, 0, convert(int, @Result)+1, @Result_On, 1, 0  
     Else   
          Select 2, @Recalc_Var_Id, @PU_Id, 1, 0, 1, @Result_On, 2, 0  
  
     Fetch Next From Result_Times Into @Result_On  
     End  
  
Close Result_Times  
Deallocate Result_Times  
*/  
  
  
  
SET NOCOUNT OFF  
  
  
