    CREATE procedure dbo.spLocal_SetDefaultProductionStatus  
@Output_Value As varchar(25) OUTPUT,  
@Event_Id int,  
@Status_Id int  
AS  
  
Return  
  
Declare @Current_Status_Id int,  
 @Start_Time  datetime  
  
Select @Current_Status_Id = Event_Status, @Start_Time = Start_Time From Events Where Event_Id = @Event_Id  
  
If @Start_Time Is Null And @Current_Status_Id = 5  
     Select 1, 1, 2, Event_Id, Event_Num, PU_Id, TimeStamp, Null, Null, @Status_Id, 1, 1, 0  
     From Events  
     Where Event_Id = @Event_Id  
  
  
  
  
  
  
