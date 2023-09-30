   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-22  
Version  : 1.0.3  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_ValidCenterline  
Author:   Matthew Wells (MSI)  
Date Created:  11/27/01  
  
Description:  
=========  
Returns a bit indicating whether the downtime alarming can be activated.  Returns a 1 if valid and 0 if not.  
  
Change Date Who What  
=========== ==== =====  
11/27/01 MKW Created procedure  
02/22/02 MKW Modified select statement to check for downtimes less than the TimeStamp in case of reruns.  
07/17/02 MKW Added check for product change and if so set valid centerline to 0 to clear out alarms.  
*/  
CREATE Procedure spLocal_ValidCenterline  
@Output_Value  int OUTPUT,  
@Var_Id  int,  
@TimeStamp  datetime,  
@Downtime_PU_Id int,  
@Periods_Str  varchar(25)  
As  
SET NOCOUNT ON  
/*  
Select  @Var_Id  = 5436,  
 @TimeStamp = '2002-07-12 15:00:00',  
 @Downtime_PU_Id = 508,  
 @Periods_Str = 2  
*/  
  
Declare @Sampling_Window int,  
 @Var_PU_Id  int,  
 @Downtime_End_Time datetime,  
 @Product_Start_Time datetime,  
 @Search_TimeStamp datetime,  
 @Periods  int,  
 @TEDet_Id  int  
  
/* Initialization */  
If IsNumeric(@Periods_Str) = 1  
     Select @Periods = convert(int, @Periods_Str)  
Else  
     Select @Periods = 0  
  
/* Get variable sampling window */  
Select  @Sampling_Window = Sampling_Window,  
 @Var_PU_Id  = PU_ID  
From [dbo].Variables  
Where Var_Id = @Var_Id  
  
/* Get downtime end time */  
Select TOP 1 @TEDet_Id = TEDet_Id, @Downtime_End_Time = End_Time  
From [dbo].Timed_Event_Details  
Where PU_Id = @Downtime_PU_Id And Start_Time < @TimeStamp  
Order By Start_Time Desc  
  
/* Get product change time */  
Select @Search_TimeStamp = dateadd(s, 60, @TimeStamp) -- Needed for pre-215 product/time records b/c of the :59 second thing (in 215 can reduce to 1 sec)  
Select @Product_Start_Time = Start_Time  
From [dbo].Production_Starts  
Where PU_Id = @Var_PU_Id And Start_Time <= @Search_TimeStamp And (End_Time > @Search_TimeStamp Or End_Time Is Null)  
  
If (datediff(mi, @Product_Start_Time, @TimeStamp) < @Sampling_Window * @Periods) Or (@TEDet_Id Is Not Null And   
   (@Downtime_End_Time Is Null Or datediff(mi, @Downtime_End_Time, @TimeStamp) < @Sampling_Window * @Periods))  
     Select @Output_Value = '0'  
Else  
     Select @Output_Value = '1'  
  
SET NOCOUNT OFF  
  
