    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_CreateDowntimeStartEvent  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
When a downtime event is ended/closed, this procedure is called by a calculation and creates a production event with the timestamp  
of the start of the downtime.  This enables additional entry of data against the downtime and calculations to be fired with the starting timestamp.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
02/03/02 MKW Added hot insert b/c result set updates not fast enough.  Duplicate event nums being generated due to next event coming in before  
   event created.  
03/13/02 MKW Fixed Julian Date.  
05/09/02 MKW Modified event creation so that the same user who created the downtime event is applied to the production event and will not automatically  
   refresh the production event unless the downtime event was modified by a non-system user.  
   Changed the initialization count of events in the current day to use the Timed_Event_Details instead of the Event records.  
   Changed the hot insert to be a result set.  
05/10/02 MKW Changed the event_num format to Julian Date + Seconds in Day so that won't have duplicate event_nums (caused by timing issue)  
05/24/02 MKW Added check for valid @PU_Id and @TEDet_Id  
08/22/02 MKW Added check for Valid/Invalid status and if Invalid then delete production event.  
*/  
CREATE procedure dbo.spLocal_CreateDowntimeStartEvent  
@OutputValue  varchar(25) OUTPUT,  
@PU_Id  int,  
@TEDet_Id  int,  
@Invalid_Status_Name varchar(25) = Null -- optional argument  
As  
  
Declare @Event_Id   int,   
 @Event_Num  varchar(25),  
 @Event_User_Id int,  
 @DT_PU_Id  int,  
 @DT_User_Id  int,  
 @Last_TEDet_Id int,  
 @Start_Time  datetime,  
 @End_Time  datetime,  
 @Last_Start  datetime,  
 @Default_Window int,  
 @Range_Start_Time datetime,  
 @Julian_Date  varchar(25),  
 @Event_Count  int,  
 @Loop_Count  int,  
 @Duplicate_Count int,  
 @Prod_Start_Date datetime,  
 @Complete_Status int,  
 @TEStatus_Id  int,  
 @Invalid_Status_Id int,  
 @AppVersion   varchar(30),  
 @User_id   int  
  
 -- user id for the resulset  
 SELECT @User_id = User_id   
 FROM [dbo].Users  
 WHERE username = 'Reliability System'  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
-- Create Table #EventUpdates (  
-- -- Result_Set_Type int Default 1,  
--  Id        int Identity,  
--  Transaction_Type  int Default 1,   
--  Event_Id   int Null,   
--  Event_Num   varchar(25) Null,   
--  PU_Id    int Null,  
--  TimeStamp   datetime Null,   
--  Applied_Product  int Null,   
--  Source_Event   int Null,   
--  Event_Status   int Null,   
--  Confirmed   int Default 1,  
--  User_Id   int Default 1,  
--  Post_Update  int Default 0)  
--   
-- Create Table #VariableUpdates (  
-- -- Result_Set_Type int Default 2,  
--  Var_Id        int Null,  
--  PU_Id    int Null,   
--  User_Id   int Default 1,  
--  Cancelled   int Default 0,  
--  Result    varchar(25) Null,   
--  Result_On   datetime Null,   
--  Transaction_Type  int Default 1,   
--  Post_Update  int Default 0)  
  
DECLARE @EventRS TABLE(  
 NotUsed    varchar(10),  
 Transaction_Type  int,   
 Event_Id    int ,   
 Event_Num    Varchar(25),   
 PU_Id     int,   
 TimeStamp    datetime,   
 Applied_Product  int,   
 Source_Event   int,   
 Event_Status   int,   
 Confirmed    int,  
 User_Id     int,  
 Post_Update    int Null,  
 Conformance   Varchar(25) Null,  
 TestPctComplete Varchar(25) Null,  
 Start_Time   DateTime Null,  
 Trans_Num    Varchar(25) Null,  
 Testing_Status  Varchar(25) Null,  
 Comment_Id   int Null,  
 Event_SubType_Id  int Null,  
 Entry_On    DateTime Null,  
 Approved_User_Id  int Null,  
 Second_User_Id  int Null,  
 Approved_Reason_Id int Null,  
 User_Reason_Id  int Null,  
 User_SignOff_Id  int Null,  
 Extended_Info  Varchar(250) Null  
)  
DECLARE @VariableRS TABLE(  
 Var_Id    int,  
 PU_Id     int,  
 User_Id       int,  
 Canceled    int,  
 Result    varchar(25),  
 Result_On   datetime,  
 Transaction_Type int,  
 Post_Update   int,  
 SecondUserId  int Null,  
 TransNum    int Null,  
 EventId    int Null,  
 ArrayId    int Null,  
 CommentId   int Null  
)  
  
/* Initialization */  
Select  @Default_Window  = 365,  
 @Event_Count  = 0,  
 @Loop_Count  = 0,  
 @Duplicate_Count = 1,  
 @Complete_Status = 5,  
 @Invalid_Status_Id = Null,  
 @Event_User_Id = Null  
  
If @PU_Id Is Not Null And @PU_Id > 0 And @TEDet_Id Is Not Null And @TEDet_Id > 0  
     Begin  
     Select  @DT_PU_Id  = PU_Id,   
  @Start_Time  = Start_Time,   
  @End_Time  = End_Time,  
  @DT_User_Id = User_Id,  
  @TEStatus_Id = TEStatus_Id  
     From [dbo].Timed_Event_Details   
     Where TEDet_Id = @TEDet_Id  
  
     Select @Invalid_Status_Id = TEStatus_Id  
     From [dbo].Timed_Event_Status  
     Where PU_Id = @PU_Id And TEStatus_Name = @Invalid_Status_Name  
  
     Select  @Event_Id   = Event_Id,  
  @Event_Num  = Event_Num,  
  @Event_User_Id = User_Id  
     From [dbo].Events   
     Where PU_Id = @PU_Id and TimeStamp = @Start_Time  
  
     If @Invalid_Status_Id <> @TEStatus_Id Or @TEStatus_Id Is Null Or @Invalid_Status_Name Is Null  
          Begin  
          /************************************************************************************************************************************************************************  
          *                                                                       Get Last Downtime Event And Delete Any Orphans In Between                                                     *  
          ************************************************************************************************************************************************************************/  
          /* Get the start time of the previous event */  
          Select @Range_Start_Time = dateadd(dd, -@Default_Window, @Start_Time)  
  
          Select TOP 1  @Last_TEDet_Id = TEDet_Id,   
   @Last_Start = Start_Time  
          From [dbo].Timed_Event_Details  
          Where PU_Id = @DT_PU_Id And Start_Time < @Start_Time And Start_Time > @Range_Start_Time  
          Order By Start_Time Desc  
  
          If (Select count(Event_Id) From Events Where PU_Id = @PU_Id And ((TimeStamp > @Last_Start And TimeStamp < @Start_Time)Or (TimeStamp > @Start_Time And TimeStamp < @End_Time))) > 0  
               Begin  
               /* Cleanup -- Get and then delete all events between previous start and this start and between the downtime start and end time */  
               Insert into @EventRS (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,User_id)  
               Select 3, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,@User_id  
               From [dbo].Events  
               Where PU_Id = @PU_Id And ((TimeStamp > @Last_Start And TimeStamp < @Start_Time)Or (TimeStamp > @Start_Time And TimeStamp < @End_Time))  
  
               /* Cleanup -- Get and then delete all downtime tests not associated with a Downtime */  
               Insert Into @VariableRS (Var_Id, PU_Id, Result, Result_On, Transaction_Type,User_id)  
               Select tests.Var_Id, Variables.PU_Id, NULL, tests.Result_On, 2,@User_id  
               From ([dbo].Variables Inner Join [dbo].tests on Variables.Var_Id = tests.Var_Id) Left Join [dbo].Timed_Event_Details On tests.Result_On = Timed_Event_Details.End_Time  
               Where Variables.PU_Id = @DT_PU_Id and Variables.Event_Type = 2 And Timed_Event_Details.End_Time Is Null And tests.Result_On > @Last_Start  
               End  
  
          /************************************************************************************************************************************************************************  
          *                                                                                        Create Downtime Production Event                                                                                *  
          ************************************************************************************************************************************************************************/  
          If @Event_Id Is Null /* Event doesn't exist so create it */  
               Begin  
               /* Get Julian date and starting event increment*/  
               Select @Julian_Date = right(datename(yy, @Start_Time),1)+right('000'+datename(dy, @Start_Time), 3)  
  
               Select @Event_Count = round((convert(float, @Start_Time)-floor(convert(float, @Start_Time)))*86400, 0)  
  
               /* Build the Event number, check for duplicates and if found increment counter and rebuild the event number */  
               While @Duplicate_Count > 0 And @Loop_Count < 1000  
                    Begin  
                    Select @Event_Num =  @Julian_Date + right(convert(varchar(25),@Event_Count+1000000),5)  
  
                    Select @Duplicate_Count = count(Event_Id)   
                    From [dbo].Events   
                    Where PU_Id = @PU_Id And Event_Num = @Event_Num  
  
                    Select @Event_Count = @Event_Count + 1  
                    Select @Loop_Count = @Loop_Count + 1        /* Prevent infinite loops */  
                    End  
  
               Insert into @EventRS (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status, User_Id)  
               Values (1, Null, @Event_Num, @PU_Id, @Start_Time, @Complete_Status, @DT_User_Id)       
               End  
          Else  
               Begin  
               /* Refresh attached event if the downtime event was modified by a non-system user */  
               If @DT_User_Id > 50  
                    Exec [dbo].spServer_CmnAddScheduledTask @Event_Id, 1  
               End  
          End  
     Else If @Event_Id Is Not Null  
          Begin  
          Insert into @EventRS (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status, User_Id)  
          Values (3, @Event_Id, @Event_Num, @PU_Id, @Start_Time, @Complete_Status, @Event_User_Id)  
          End  
  
     /************************************************************************************************************************************************************************  
     *                                                                                                        Output Results                                                                                               *  
     ************************************************************************************************************************************************************************/  
     /* Issue event updates */  
     IF (SELECT count(*) FROM @EventRS) > 0   
   BEGIN  
    IF @AppVersion LIKE '4%'  
     BEGIN  
      SELECT 1,  
       NotUsed ,  
       Transaction_Type,   
       Event_Id ,   
       Event_Num ,   
       PU_Id  ,   
       TimeStamp,  
       Applied_Product ,   
       Source_Event,   
       Event_Status ,   
       Confirmed ,  
       User_Id ,  
       Post_Update ,  
       Conformance ,  
       TestPctComplete ,  
       Start_Time  ,  
       Trans_Num  ,  
       Testing_Status ,  
       Comment_Id ,  
       Event_SubType_Id,  
       Entry_On,  
       Approved_User_Id,  
       Second_User_Id,  
       Approved_Reason_Id,  
       User_Reason_Id,  
       User_SignOff_Id,  
       Extended_Info  
      FROM @EventRS  
     END  
    ELSE  
     BEGIN  
      SELECT 1,  
       NotUsed ,  
       Transaction_Type,   
       Event_Id ,   
       Event_Num ,   
       PU_Id  ,   
       TimeStamp,  
       Applied_Product ,   
       Source_Event,   
       Event_Status ,   
       Confirmed ,  
       User_Id ,  
       Post_Update ,  
       Conformance ,  
       TestPctComplete ,  
       Start_Time  ,  
       Trans_Num  ,  
       Testing_Status ,  
       Comment_Id ,  
       Event_SubType_Id,  
       Entry_On  
      FROM @EventRS  
     END  
     
   END  
  
     /* Issue variable updates */  
  IF (SELECT COUNT(*) FROM @VariableRS) > 0  
   BEGIN  
    IF @AppVersion LIKE '4%'  
     BEGIN  
      SELECT 2,  
        Var_Id,   
        PU_Id,   
        User_Id,   
        Canceled,   
        Result,   
        Result_On,   
        Transaction_Type,   
        Post_Update,   
        SecondUserId,   
        TransNum,   
        EventId,   
        ArrayId,   
        CommentId  
      FROM @VariableRS  
     END  
    ELSE  
     BEGIN  
      SELECT 2,  
        Var_Id,   
        PU_Id,   
        User_Id,   
        Canceled,   
        Result,   
        Result_On,   
        Transaction_Type,   
        Post_Update  
      FROM @VariableRS  
     END  
   END  
  
     Select @OutputValue = convert(varchar(25), @Event_Id)  
     End  
Else  
     Select @OutputValue = '-1'  
  
SET NOCOUNT OFF  
  
