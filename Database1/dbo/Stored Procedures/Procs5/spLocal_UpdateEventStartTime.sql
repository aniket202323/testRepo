   CREATE procedure dbo.spLocal_UpdateEventStartTime  
@OutputValue varchar(25) OUTPUT,  
@Event_Id int,  
@Event_Status  int,  
@Date  varchar(25),  
@Time  varchar(25)  
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
  
Declare @Start_Time  datetime,  
 @End_Time  datetime,  
 @DateTime  varchar(25),  
 @PU_Id  int,  
 @Event_Num  varchar(25),  
 @Next_Event_Id int,  
 @Next_TimeStamp datetime,  
 @Last_TimeStamp  datetime  
  
/* Initialization */  
Select @PU_Id = PU_Id, @Event_Num = Event_Num, @End_Time = TimeStamp  
From Events  
Where Event_Id = @Event_Id  
  
If @Event_Status = 4  /* Running */  
Begin  
     /* Create the Event Start TimeStamp */  
     Select @DateTime = @Date + ' ' + @Time  
     Select @Start_Time = convert(datetime, @DateTime)  
  
     /* Get other pending events */  
     Insert Into #EventUpdates  
     Select 1, 2, Event_Id, Event_Num, PU_Id, TimeStamp, Null, Null, Event_Status, 1, 1, 0  
     From Events  
     Where PU_Id = @PU_Id And (TimeStamp > @Start_Time Or TimeStamp > @End_Time) And Event_Status <> 5  
  
     /* Make sure future TimeStamps are updated and are at least 1 sec after the current one */  
     Select @Last_TimeStamp = @Start_Time  
  
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
  
    /* Insert updates for the current event - Set the TimeStamp to be equal to the Start_Time */  
     Insert Into #EventUpdates  
     Values (1, 2, @Event_Id, @Event_Num, @PU_Id, @Start_Time, Null, Null, @Event_Status, 1, 1, 0)  
  
    /* Send out updates for all events */  
    Select 1, *  
    From #EventUpdates  
    Order By TimeStamp Desc  
  
     /* Update the Events tables with the Start TimeStamp */  
     Update Events  
     Set Start_Time = @Start_Time  
     Where Event_Id = @Event_Id  
End  
  
/* Cleanup */  
Close ClothingChanges  
Deallocate ClothingChanges  
Drop Table #EventUpdates  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
