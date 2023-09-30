  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetDownStartTime  
Author:   Matthew Wells (MSI)  
Date Created:  09/09/02  
  
Description:  
=========  
Takes a timestamp and a PU_Id and finds the downtime start time and if none found then returns the timestamp.  
  
Change Date Who What  
=========== ==== =====  
09/09/02 MKW Created  
*/  
  
  
CREATE procedure dbo.spLocal_GetDownStartTime  
@Output_Value  varchar(25) OUTPUT,  
@PU_Id   int,  
@TimeStamp_Str varchar(25)  
As  
  
/*  
Select  @PU_Id   = 878,  
 @TimeStamp_Str = '9-Sep-02 07:36:26'  
*/  
SET NOCOUNT ON  
  
Declare @TimeStamp  datetime,  
 @Start_Time  datetime,  
 @End_Time  datetime,  
 @Output_Time  datetime,  
 @Year    varchar(20),  
 @Month  varchar(20),  
 @Day    varchar(20)  
   
/* Convert arguments */  
If isdate(@TimeStamp_Str) = 1  
     Begin  
     Select @TimeStamp = convert(datetime, @TimeStamp_Str)  
  
     Select @Start_Time = Start_Time  
     From [dbo].Timed_Event_Details  
     Where PU_Id = @PU_Id And Start_Time <= @TimeStamp And (End_Time > @TimeStamp Or End_Time Is Null)  
  
     /* Check for split events */  
     While @Start_Time Is Not Null  
          Begin  
          /* Reinitialize */  
          Select  @End_Time  = @Start_Time,  
   @Start_Time = Null  
  
          Select @Start_Time = Start_Time  
          From [dbo].Timed_Event_Details  
          Where PU_Id = @PU_Id And End_Time = @End_Time  
          End  
  
     If @End_Time Is Not Null  
          Select @TimeStamp = @End_Time  
     End  
  
/* Format result */  
Select  @Year   = datepart(yy, @TimeStamp),  
 @Month  = datename(mm, @TimeStamp),  
 @Day   = right('0' + ltrim(str(datepart(dd, @TimeStamp), 2, 0)), 2)  
  
Select @Output_Value = @Day +'-'+Left(@Month, 3)+'-'+Right(@Year, 2) + ' '+ convert(varchar(25), @TimeStamp, 108)  
  
SET NOCOUNT OFF  
  
  
