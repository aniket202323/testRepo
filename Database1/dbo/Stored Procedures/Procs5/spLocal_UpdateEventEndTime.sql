  CREATE procedure dbo.spLocal_UpdateEventEndTime  
@OutputValue varchar(25) OUTPUT,  
@Event_Id int,  
@Event_Status  int,  
@Start_Time  datetime,  
@End_Time datetime  
AS  
  
Return  
  
Create Table #EventUpdates (  
 Id        Int,  
 Transaction_Type  int,   
 Event_Id   int NULL,   
 Event_Num   Varchar(25),   
 PU_Id    int,   
 TimeStamp   datetime,   
 Applied_Product  int Null,   
 Source_Event   int Null,   
 Event_Status   int Null,   
 Confirmed   int Null,  
 User_Id   int Null,  
 Post_Update  int Null)  
  
Declare @PU_Id  int,  
 @Event_Num varchar(25),  
 @Next_Event_Id int,  
 @TimeStamp datetime,  
 @Next_TimeStamp datetime,  
 @Last_TimeStamp datetime  
  
/* Initialization */  
Select @TimeStamp = getdate()  
Select @TimeStamp = DateAdd(ms, -Datepart(ms, @TimeStamp), @TimeStamp)  
  
Select @PU_Id = PU_Id, @Event_Num = Event_Num  
From Events  
Where Event_Id = @Event_Id  
  
If @Event_Status = 5 And Datediff(s, @Start_Time, @End_Time) <= 0  
Begin  
     /* Get other pending events */  
     Insert Into #EventUpdates  
     Select 1, 2, Event_Id, Event_Num, PU_Id, TimeStamp, Null, Null, Event_Status, 1, 1, 0  
     From Events  
     Where PU_Id = @PU_Id And (TimeStamp > @Start_Time Or TimeStamp > @End_Time)  
  
     /* Make sure future TimeStamps are updated and are at least 1 sec after the current one */  
     Select @Last_TimeStamp = @TimeStamp  
  
     Declare ClothingChanges Cursor For  
     Select Event_Id, TimeStamp   
     From #EventUpdates  
     Order By TimeStamp Asc  
     Open ClothingChanges  
  
     Fetch Next From ClothingChanges Into @Next_Event_Id, @Next_TimeStamp  
     While @@FETCH_STATUS = 0   
     Begin  
          If @Next_TimeStamp <= @Last_TimeStamp  
          Begin  
               Select @Last_TimeStamp = DateAdd(s, 1, @Last_TimeStamp)  
  
               Update #EventUpdates  
               Set TimeStamp = @Last_TimeStamp  
               Where Event_Id = @Next_Event_Id  
          End  
          Fetch Next From ClothingChanges Into @Next_Event_Id, @Next_TimeStamp  
     End            
  
     /* Insert updates for the current event */  
     Insert Into #EventUpdates  
     Values (1, 2, @Event_Id, @Event_Num, @PU_Id, @TimeStamp, Null, Null, @Event_Status, 1, 1, 0)  
  
    /* Send out updates for all events */  
    Select 1, *  
    From #EventUpdates  
    Order By TimeStamp Desc  
End  
  
/* Cleanup */  
Close ClothingChanges  
Deallocate ClothingChanges  
Drop Table #EventUpdates  
  
  
  
  
  
  
  
  
  
  
  
  
