 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-22  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
  
CREATE procedure dbo.spLocal_UptimeTotalByEvent  
@OutputValue varchar(25) OUTPUT,  
@Event_Id int  
As  
SET NOCOUNT ON  
  
Declare @Start_Time   datetime,  
 @End_Time   datetime,  
 @PU_Id  int,  
 @Fault_Start_Time datetime,  
 @Fault_End_Time datetime,  
 @Fault_Time  real  
  
Select @PU_Id = PU_Id, @Start_Time = Start_Time, @End_Time = TimeStamp  
From [dbo].Events  
Where Event_Id = @Event_Id  
  
Select @Fault_Time = datediff(s, @Start_Time, @End_Time)/60  
  
Declare Faults Cursor For  
Select Start_Time, End_Time  
From [dbo].Timed_Event_Details  
Where PU_Id = @PU_Id AND  
              ((End_Time   > @Start_Time And End_Time   <= @End_Time) OR  
               (Start_Time >= @Start_Time And Start_Time < @End_Time) OR  
               (Start_Time <= @Start_Time And End_Time   >=  @End_Time) OR  
               (End_Time IS NULL))  
    
Open Faults  
  
Fetch Next From Faults Into @Fault_Start_Time, @Fault_End_Time  
While @@FETCH_STATUS = 0  
Begin  
      If @Fault_Start_Time > @Start_Time  
      Begin  
          If @Fault_End_Time <= @End_Time  
              Select @Fault_Time = @Fault_Time - convert(real,Datediff(s,@Fault_Start_Time,@Fault_End_Time))/60  
          Else  
              Select @Fault_Time = @Fault_Time - convert(real,Datediff(s,@Fault_Start_Time,@End_Time))/60  
      End  
      Else  
      Begin  
          If @Fault_End_Time <= @End_Time   
              Select @Fault_Time = @Fault_Time - convert(real,Datediff(s,@Start_Time,@Fault_End_Time))/60  
          Else  
              Select @Fault_Time = @Fault_Time - convert(real,Datediff(s,@Start_Time,@End_Time))/60  
      End    
      Fetch Next From Faults Into @Fault_Start_Time, @Fault_End_Time  
  End  
Close Faults  
Deallocate Faults  
  
Select @OutputValue = Convert(varchar(25), IsNull(@Fault_Time,0.00))  
  
SET NOCOUNT OFF  
