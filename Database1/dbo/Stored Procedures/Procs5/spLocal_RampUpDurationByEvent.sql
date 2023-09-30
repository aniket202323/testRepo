    /*  
Stored Procedure: spLocal_RampUpDurationByEvent  
Author:   Barry Stewart (Stier Automation, LLC.)  
Date Created:  02/10/03  
  
Description:  
=========  
This procedure sums the ramp up durations of downtime event for rate loss duration adjustment  
  
Change Date Who What  
=========== ==== =====  
02/10/03 BAS Created procedure.  
  
  
*/  
CREATE procedure dbo.spLocal_RampUpDurationByEvent  
@Output_Value varchar(25) OUTPUT,  
@Start_Time datetime,  
@End_Time datetime,  
@DT_PU_ID int  
AS  
  
Declare @Ramp_Up_Sum float  
  
/*Testing  
Select @Start_Time = '2003-02-10 14:25:33.000',  
 @End_Time = '2003-02-10 14:26:42.000',  
 @DT_PU_ID = 74  
*/  
  
Create table #Downtime (  
 Start_Time  datetime,  
 End_Time  datetime,  
 Ramp_Up_Duration int Default 0)  
  
Insert #Downtime  
 Select Start_Time, End_Time, 0  
  From Timed_Event_Details  
  Where PU_Id = @DT_PU_Id  
  And Start_Time > @Start_Time  
  And End_Time < @End_Time  
  
/* Search for downtime starts*/  
Update #Downtime  
 Set Ramp_Up_Duration = (Select DateDiff(s, #Downtime.End_Time, Min(dt.Start_Time))  
     From #Downtime dt  
     Where dt.Start_Time > #Downtime.Start_Time)  
  
/* Search for downtime ends*/  
Update #Downtime  
 Set Ramp_Up_Duration = sel.newtime   
    from (select DateDiff(s, Max(End_Time), @End_Time) newtime  
     from #downtime) sel  
     Where End_Time = (Select Max(End_Time)From #Downtime)  
  
/* Make any records over one min equal to one min*/     
Update #Downtime  
 Set Ramp_Up_Duration = 60.0  
  Where Ramp_Up_Duration > 60.0  
  
/* Sum each record's ramp up duration */  
Select @Ramp_Up_Sum = Sum(Ramp_Up_Duration)from #Downtime  
  
/* Convert value to mins */  
If @Ramp_Up_Sum > 0  
 Select @Output_Value = @Ramp_Up_Sum/60  
Else  
 Select @Output_Value = 0  
  
Drop table #Downtime  
