     /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-17  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_UpdatePreviousEvent  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
*/  
  
CREATE procedure dbo.spLocal_UpdatePreviousEvent  
@Output_Value As varchar(25) OUTPUT,  
@ThisTime varchar(30),  
@PU_Id_1 int,  
@PU_Id_2 int,  
@PU_Id_3 int,  
@PU_Id_4 int,  
@PU_Id_5 int,  
@PU_Id_6 int,  
@PU_Id_7 int,  
@PU_Id_8 int,  
@PU_Id_9 int,  
@PU_Id_10 int  
As  
  
SET NOCOUNT ON  
  
DECLARE  @PreviousEvents Table(  
 PU_Id  int,  
 TimeStamp  datetime)  
  
Declare @TimeStamp datetime,  
 @PU_Id int,  
 @Event_Id int,  
 @Found int,  
 @Workstarted int  
  
/* Get the previous events' timestamps */  
Insert into @PreviousEvents   
Select PU_Id, Max(TimeStamp)   
From [dbo].Events  
Where ( PU_Id = @PU_Id_1 Or   
 PU_Id = @PU_Id_2 Or  
 PU_Id = @PU_Id_3 Or  
 PU_Id = @PU_Id_4 Or  
 PU_Id = @PU_Id_5 Or  
 PU_Id = @PU_Id_6 Or  
 PU_Id = @PU_Id_7 Or  
 PU_Id = @PU_Id_8 Or  
 PU_Id = @PU_Id_9 Or  
 PU_Id = @PU_Id_10 ) And  
             TimeStamp < convert(datetime, @ThisTime)  
Group By PU_Id  
  
/* Get the previous events' ids */  
Declare PreviousEvent Cursor For  
Select PU_Id, TimeStamp  
From @PreviousEvents  
Open PreviousEvent  
  
Fetch Next From PreviousEvent Into @PU_Id, @TimeStamp  
While @@FETCH_STATUS = 0  
Begin  
     /* Initialize */  
/*  
     Select @Found = NULL  
     Select @WorkStarted = NULL  
*/  
     /* Get Event Id and then insert it into Pending tasks */  
     Select @Event_Id = Event_Id From Events Where PU_Id = @PU_Id And TimeStamp = @TimeStamp  
     Exec [dbo].spServer_CmnAddScheduledTask @Event_Id, 1  
/*  
     Select @Found = ActualId, @WorkStarted = WorkStarted From PendingTasks Where (ActualId = @Event_Id) And (TaskId = 5)  
     If (@Found Is NULL)  
          Insert Into PendingTasks (ActualId,TaskId) Values (@Event_Id,5)  
*/  
     Fetch Next From PreviousEvent Into @PU_Id, @TimeStamp  
End  
  
Close PreviousEvent  
Deallocate PreviousEvent  
  
Select @Output_Value = convert(varchar(30), @Event_Id)  
  
  
  
  
SET NOCOUNT OFF  
  
  
  
