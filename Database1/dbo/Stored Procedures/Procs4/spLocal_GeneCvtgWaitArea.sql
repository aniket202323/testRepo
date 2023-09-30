    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-01  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
CREATE procedure dbo.spLocal_GeneCvtgWaitArea  
@Success Int  Output,  
@ErrMsg VarChar(255) Output,  
@ECId  Int,  
@TableName VarChar(255),  
@Id  Int   
AS  
  
SET NOCOUNT ON  
  
Declare @PEI_Id  Int,  
 @PEIP_Id  Int,  
 @ECPEI_Id  Int,  
 @UnLoaded  Int,  
 @EventId  Int,  
 @NewPU  Int,  
 @MaxTimeStamp Datetime,  
 @SourceId  Int,  
 @ComponentId  Int,  
 @TimeStamp  DateTime,  
 @Start_Time  DateTime,  
 @EventStartTime DateTime,  
 @Now   DateTime,  
 @CurrentEventId Int,  
 @EventEndTime DateTime,  
 @EventHistId  Int,  
 @InputStartTime DateTime,  
 @SubEventId  Int,  
 @HTimeStamp  DateTime,  
 @InputEndTime  DateTime,  
 @MaxEntryOn  DateTime,  
 @OldStatus  Int,  
 @NewEventNum VarChar(25),  
 @EventNum  VarChar(25),  
 @Status  Int,  
 @InputPU  Int,  
 @MaxId  Int,  
   @NewEventId  int,  
 @PU_Id  int,  
 @EventPattern  varchar(25),  
 @EventNumCount int,  
 @strTimeStamp  varchar(30),  
  @LastEventTimeStamp datetime,  
  @LastInputTimeStamp datetime,  
 @LastInputEventHistoryId int,  
 @HotEventStatus int,  
 @EventStatus  int,  
 @StagedHistoryId  int,  
 @StagedEventId int,  
 @DimX   float,  
 @DimY   float,  
 @DimZ   float,  
 @DimA   float,  
 @Running_Status int,  
 @Staged_Status int,  
 @Waiting_Status int,  
 @Input_Order  int,  
 @Wait_PEI_Id  int,  
 @User_id    int,  
 @AppVersion   varchar(30)  
  
-- Create Table #EventComponent (  
--  Post_Update       Int,  
--  User_Id   Int,  
--  Transaction_Type  Int,   
--  Transaction_Number Int,  
--  ComponentId  Int Null,  
--  EventId   Int,  
--  SrcEventId   Int,  
--  DimX   Float,   
--  DimY   Float,   
--  DimZ   Float,   
--  DimA   Float )  
--   
-- Create Table #EventUpdates (  
--  Id        Int,  
--  Transaction_Type  int,   
--  Event_Id   int NULL,   
--  Event_Num   Varchar(25),   
--  PU_Id    int,   
--  TimeStamp   varchar(30),   
--  Applied_Product  int Null,   
--  Source_Event   int Null,   
--  Event_Status   int Null,   
--  Confirmed   int Null,  
--  User_Id   int Null,  
--  Post_Update  int Null)  
--   
-- Create Table #EventDetails (  
--  Post_Update       int Null,  
--  User_Id   int Null,  
--  Transaction_Type  int Null,   
--  Transaction_Number int Null,  
--   EventId   int Null,  
--   PUId   int Null,  
--  PriEventNum  varchar(25) Null,  
--  AltEventNum  varchar(25) Null,  
--  CommentId  int Null,  
--  EventType  int Null,  
--  OriginalProduct  int Null,  
--  AppliedProduct  int Null,  
--  EventStatus  int Null,  
--  TimeStamp  datetime Null,  
--  EntryOn   datetime Null,  
--  PP_Setup_Detail_Id int Null,  
--  Shipment_Item_Id int Null,  
--  Order_Id  int Null,  
--  Order_Line_Id  int Null,  
--  PP_Id   int Null,  
--  Initial_Dimension_X float Null,  
--  Initial_Dimension_Y float Null,  
--  Initial_Dimension_Z float Null,  
--  Initial_Dimension_A float Null,  
--  Final_Dimension_X float Null,  
--  Final_Dimension_Y float Null,  
--  Final_Dimension_Z         float Null,  
--  Final_Dimension_A         float Null,  
--  Orientation_X   tinyint Null,  
--  Orientation_Y   tinyint Null,  
--  Orientation_Z  tinyint Null)  
  
DECLARE @EventUpdates TABLE (  
 Result_Set_Type  int DEFAULT 1,  
 Id   int,  
 Transaction_Type  int DEFAULT 1,   
 Event_Id   int NULL,   
 Event_Num   varchar(25) NULL,   
 PU_Id    int NULL,   
 TimeStamp   datetime NULL,  
 Applied_Product  int NULL,   
 Source_Event   int NULL,   
 Event_Status   int NULL,   
 Confirmed   int DEFAULT 1,  
 User_Id   int DEFAULT 6,  
 Post_Update  int DEFAULT 0,  
 Conformance  int NULL,  
 TestPctComplete  int NULL,  
 StartTime  datetime NULL,  
 TransNum  int DEFAULT 0,  
 TestingStatus  int NULL,  
 CommentId  int NULL,  
 EventSubTypeId  int NULL,  
 EntryOn   varchar(25) NULL,  
 Approved_User_Id  int NULL,  
 Second_User_Id   int NULL,  
 Approved_Reason_Id int NULL,  
 User_Reason_Id   int NULL,  
 User_SignOff_Id  int NULL,  
 Extended_Info   int NULL  
)  
  
DECLARE @EventDetails TABLE (  
 Result_Set_Type  int DEFAULT 10,  
 Pre_Update   int DEFAULT 1,  
 User_Id   int DEFAULT 6,  
 Transaction_Type  int DEFAULT 1,   
 Transaction_Number int NULL,   -- Must be NULL  
  Event_Id  int NULL,  
  PU_Id   int NULL,  
 Primary_Event_Num varchar(25) NULL,  
 Alternate_Event_Num varchar(25) NULL,  
 Comment_Id  int NULL,  
 Event_Type  int NULL,  
 Original_Product int NULL,  
 Applied_Product  int NULL,  
 Event_Status  int DEFAULT 5,  
 TimeStamp  datetime NULL,  
 Entered_On  datetime NULL,  
 PP_Setup_Detail_Id int NULL,  
 Shipment_Item_Id int NULL,  
 Order_Id  int NULL,  
 Order_Line_Id  int NULL,  
 PP_Id   int NULL,  
 Initial_Dimension_X float NULL,  
 Initial_Dimension_Y float NULL,  
 Initial_Dimension_Z float NULL,  
 Initial_Dimension_A float NULL,  
 Final_Dimension_X float NULL,  
 Final_Dimension_Y float NULL,  
 Final_Dimension_Z   float NULL,  
 Final_Dimension_A   float NULL,  
 Orientation_X   tinyint NULL,  
 Orientation_Y   tinyint NULL,  
 Orientation_Z  tinyint NULL)  
  
DECLARE @EventComponents TABLE (  
 Result_Set_Type  int DEFAULT 11,  
 Pre_Update  int DEFAULT 1,  
 User_Id   int DEFAULT 6,  
 Transaction_Type  int DEFAULT 1,   
 Transaction_Number int DEFAULT 0,  -- Must be 0  
 Component_Id  int NULL,  
 Event_Id  int NULL,  
 Source_Event_Id  int NULL,  
 Dimension_X  float DEFAULT 0,   
 Dimension_Y  float DEFAULT 0,   
 Dimension_Z  float DEFAULT 0,   
 Dimension_A  float DEFAULT 0,  
 StartCoordinateX float Null,  
 StartCoordinateY float Null,  
 StartCoordinateZ float Null,  
 StartCoordinateA float Null,  
 Start_Time   datetime Null,  
 Timestamp   datetime Null,  
 PP_Component_Id  int Null,  
 Entry_On    datetime Null,  
 Extended_Info  varchar(250) Null  
)  
  
  
 -- user id for the resulset  
 SELECT @User_id = User_id   
 FROM [dbo].Users  
 WHERE username = 'Reliability System'  
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
/* Initialization */  
Select @ErrMsg = @TableName  
Select @Success = 0  
  
Select @Running_Status = 4,  
 @Staged_Status = 3,  
 @Waiting_Status = 23  
  
/*  
Insert Into Local_Genealogy_Input (Success, ErrMsg, ECId, TableName,Id )  
Values (@Success, @ErrMsg, @ECId, @TableName, @Id)  
*/  
  
--Select @ECPEI_Id = PEI_Id From Event_Configuration Where EC_Id = @ECId  
  
If @TableName = 'PrdExec_Input_Event'   
Begin  
     Select @ErrMsg = ''  
     Select @Success = 1  
End  
Else If  @TableName = 'PrdExec_Input_Event_History'  
Begin  
  
     Select @PEI_Id = PEI_Id,@PEIP_Id = PEIP_Id,@UnLoaded = Unloaded,@EventId = Event_Id,@HTimeStamp = TimeStamp  
     From [dbo].PrdExec_Input_Event_History  
     Where Input_Event_History_Id = @Id  
  
     Select @PU_Id = PU_Id, @Input_Order = Input_Order  
     From [dbo].PrdExec_Inputs   
     Where PEI_Id = @PEI_Id  
  
     /* Make sure that time for events is at least 1 minute apart */  
     Select @LastInputEventHistoryId = Max(Input_Event_History_Id)  
     From [dbo].PrdExec_Input_Event_History   
   Inner Join [dbo].Event_Configuration On PrdExec_Input_Event_History.PEI_Id = Event_Configuration.PEI_Id  
     Where Event_Configuration.PU_Id = @PU_Id And TimeStamp < @HTimeStamp And TimeStamp >  '01/01/1970'  
  
     Select @LastEventTimeStamp = TimeStamp   
     From [dbo].PrdExec_Input_Event_History  
     Where Input_Event_History_Id = @LastInputEventHistoryId  
  
     If  (Datediff(s, @LastEventTimeStamp, @HTimeStamp) < 1)       
          Select @TimeStamp = DateAdd(s, 1, @LastEventTimeStamp)   
     Else  
          Select @TimeStamp = @HTimeStamp  
     Select @strTimeStamp = convert(varchar(25), @TimeStamp, 121)  
  
/*******************************************************************************************************************  
                                  Load the running or staged position      
*******************************************************************************************************************/  
     If (@UnLoaded = 0) and ((@PEIP_Id = 1) Or (@PEIP_Id = 2)) and (@EventId is Not null)  /* Loaded in the running position */  
     Begin  
          /* Initialization */  
          Select @EventStatus = @Waiting_Status  
  
          /* Setup input parameters */  
          If @PEIP_Id = 1  
          Begin  
               /* Set update status */  
               Select @HotEventStatus = 2  
  
               /* Check to see if the roll was previously staged */  
               Select @StagedHistoryId = Max(Input_Event_History_Id)   
               From [dbo].PRDExec_Input_Event_History   
               Where PEI_Id = @PEI_Id And PEIP_Id = 2 And Unloaded = 1  
  
               Select @StagedEventId = Event_Id   
               From [dbo].PrdExec_Input_Event_History   
               Where Input_Event_History_Id = @StagedHistoryId  
          End  
          Else  If @PEIP_Id = 2  
          Begin  
               /* Set update status */  
               Select @HotEventStatus = 1  
          End  
  
          /* Check to see if Event is already created */  
          If ((@PEIP_Id = 1 And (@EventId <> @StagedEventId Or @StagedEventId Is Null)) Or (@PEIP_Id = 2))  
          Begin  
               /* Get Event Number and ensure there are no duplicates */  
               Select @EventNum = ltrim(rtrim(Event_Num)) From [dbo].Events Where Event_Id = @EventId  
               Select @EventPattern = '%' + @EventNum + '%'  
               Select @EventNumCount = Count(Event_Num) From [dbo].Events Where Event_Num Like @EventPattern And PU_Id = @PU_Id  
               If @EventNumCount > 0  
                    Select @EventNum = @EventNum + '-' + convert(varchar(25), @EventNumCount)  
  
               /* Hot update because need to ensure that events are getting in immediately so don't end up with same timestamp and need the Event_Id */  
               Execute spServer_DBMgrUpdEvent @NewEventId   OUTPUT, @EventNum, @PU_Id, @strTimeStamp, Null,   
     @EventId, @EventStatus, 1, 0, @User_id, Null, Null, Null, Null, Null, 1  
 --    @EventId, @HotEventStatus, 1, 0, 6, Null, Null, Null, Null, Null, 1  
  
               Update [dbo].Events  
               Set Start_Time = @TimeStamp  
               Where Event_Id = @NewEventId  
  
               -- Fill out the event component (before the event update inorder to complete event components before the calculations use it.  
               Insert into @EventComponents (Pre_Update, User_Id,Transaction_Type,Transaction_Number,Component_Id,Event_Id,Source_Event_Id,Dimension_X , Dimension_Y , Dimension_Z , Dimension_A)  
               Values (1,@User_id,1,0,Null,@NewEventId ,@EventId,0,0,0,0)  
  
               If (select Count(*) from @EventComponents) > 0   
      BEGIN  
       IF @AppVersion LIKE '4%'  
        BEGIN  
         SELECT  Result_Set_Type,  
          Pre_Update ,  
          User_Id ,  
          Transaction_Type ,   
          Transaction_Number ,   
          Component_Id,  
          Event_Id ,  
          Source_Event_Id,  
          Dimension_X ,   
          Dimension_Y ,   
          Dimension_Z ,   
          Dimension_A,  
          StartCoordinateX,  
          StartCoordinateY,  
          StartCoordinateZ,  
          StartCoordinateA,  
          Start_Time,  
          Timestamp,  
          PP_Component_Id,  
          Entry_On,  
          Extended_Info  
          FROM @EventComponents  
        END  
       ELSE  
        BEGIN  
         SELECT  Result_Set_Type,  
          Pre_Update ,  
          User_Id ,  
          Transaction_Type ,   
          Transaction_Number ,   
          Component_Id,  
          Event_Id ,  
          Source_Event_Id,  
          Dimension_X ,   
          Dimension_Y ,   
          Dimension_Z ,   
          Dimension_A  
          FROM @EventComponents  
        END  
      END  
  
               -- Post update notification to Message Bus  
               Insert into @EventUpdates (Id,Transaction_Type,Event_Id,Event_Num, PU_Id, TimeStamp,Source_Event, Event_Status, Confirmed, user_Id, Post_Update)  
               Values(1, 1, @NewEventId, @EventNum, @PU_Id, @strTimeStamp, @EventId, @EventStatus, 1, @User_id, 1)  
  
               /* Refresh attached event */  
               Exec spServer_CmnAddScheduledTask @EventId, 1  
          End  
--          Else  
--          Begin  
               /* Get the current event */  
--               Select @ComponentId = Max(Component_Id) From Event_Components Where Source_Event_Id = @EventId  
--               Select @NewEventId = Event_Id From Event_Components Where Component_Id = @ComponentId  
  
               /* Send an update message to change the status to Running */  
--               Insert into #EventUpdates (Id,Transaction_Type,Event_Id,Event_Num, PU_Id, TimeStamp,Source_Event, Event_Status, Confirmed, user_Id, Post_Update)  
--               Select 1, 2, Event_Id, Event_Num, PU_Id, @strTimeStamp, Source_Event, @EventStatus, 1, 6, 0  
--               From Events  
--               Where Event_Id = @NewEventId  
--          End  
  
          If (Select Count(*) From @EventUpdates) > 0  
    BEGIN  
     IF @AppVersion LIKE '4%'  
      BEGIN  
       SELECT Result_Set_Type,  
        Id ,  
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
        StartTime  ,  
        TransNum  ,  
        TestingStatus ,  
        CommentId ,  
        EventSubTypeId,  
        EntryOn,  
        Approved_User_Id,  
        Second_User_Id,  
        Approved_Reason_Id,  
        User_Reason_Id,  
        User_SignOff_Id,  
        Extended_Info  
       FROM @EventUpdates  
       Order By Id Asc  
      END  
     ELSE  
      BEGIN  
       SELECT Result_Set_Type,  
        Id ,  
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
        StartTime  ,  
        TransNum  ,  
        TestingStatus ,  
        CommentId ,  
        EventSubTypeId,  
        EntryOn  
       FROM @EventUpdates  
       Order By Id Asc  
      END  
    END  
     End  
/*******************************************************************************************************************  
                                  Complete the roll in the running position      
*******************************************************************************************************************/  
     Else If (@UnLoaded = 0) and (@PEIP_Id = 1) and (@EventId is null)  
          Begin  
           /* Find the running event */  
          Select @MaxId = max(Input_Event_History_Id)   
          From [dbo].PrdExec_Input_Event_History  
          Where   (PEI_Id = @PEI_Id) and (PEIP_Id = 1)  and (Unloaded = 0) and (timestamp < @HTimeStamp) and (Event_Id is not null)  
  
          Select @SourceId = Event_Id   
          From [dbo].PrdExec_Input_Event_History  
          Where Input_Event_History_Id = @MaxId  
  
          Select @EventId = Event_Id   
          From [dbo].Event_Components   
          Where Source_Event_Id = @SourceId  
  
          /* Set the child event status to Complete and the end time to the current time */  
          Insert into @EventUpdates (Id,Transaction_Type,Event_Id,Event_Num, PU_Id, TimeStamp,Source_Event, Event_Status, Confirmed, user_Id, Post_Update)  
          Select 1, 2, Event_Id, Event_Num, PU_Id, @strTimeStamp, Source_Event, 5, 1, @User_id, 0   
          From [dbo].Events  
          Where Event_Id = @EventId  
  
          /* Update the Event_Details table with the dimensions */  
          Insert Into @EventDetails (Pre_Update, User_Id, Transaction_Type, Event_Id, PU_Id, Event_Status, TimeStamp,   
    Initial_Dimension_X, Final_Dimension_X,   
    Initial_Dimension_Y, Final_Dimension_Y,   
    Initial_Dimension_Z, Final_Dimension_Z,   
    Initial_Dimension_A, Final_Dimension_A)  
          Select 1, @User_id, 1, @EventId, @PU_Id, 5, @TimeStamp,   
     Initial_Dimension_X, Final_Dimension_X,   
     Initial_Dimension_Y, Final_Dimension_Y,   
     Initial_Dimension_Z, Final_Dimension_Z,   
     Initial_Dimension_A, Final_Dimension_A  
          From [dbo].Event_Details  
          Where Event_Id = @SourceId  
  
          /* Update the Event_Components table with the dimensions */  
          Select  @DimX = (Final_Dimension_X-Initial_Dimension_X),   
      @DimY = (Final_Dimension_Y-Initial_Dimension_Y),  
      @DimZ = (Final_Dimension_Z-Initial_Dimension_Z),  
      @DimA = (Final_Dimension_A-Initial_Dimension_A)  
          From [dbo].Event_Details  
          Where Event_Id = @SourceId  
  
          Update [dbo].Event_Components   
          Set Dimension_X = @DimX, Dimension_Y = @DimY, Dimension_Z = @DimZ, Dimension_A = @DimA  
          Where Event_Id = @EventId  
  
          /*********** Temporary Fix - Model is supposed to do this *******************/  
          /* Set the parent event status to Consumed */  
          /*  
          Insert into #EventUpdates (Id,Transaction_Type,Event_Id,Event_Num, PU_Id, TimeStamp,Source_Event, Event_Status, Confirmed, user_Id, Post_Update)  
          Select 2, 2, Event_Id, Event_Num, PU_Id, TimeStamp, Source_Event, 8, 1, 6, 0   
          From Events  
          Where Event_Id = @SourceId  
          */  
          /***********************************************************************************/  
  
          /* Send event messages */  
          If (Select Count(*) From @EventUpdates) > 0   
    BEGIN  
     IF @AppVersion LIKE '4%'  
      BEGIN  
       SELECT Result_Set_Type,  
        Id ,  
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
        StartTime  ,  
        TransNum  ,  
        TestingStatus ,  
        CommentId ,  
        EventSubTypeId,  
        EntryOn,  
        Approved_User_Id,  
        Second_User_Id,  
        Approved_Reason_Id,  
        User_Reason_Id,  
        User_SignOff_Id,  
        Extended_Info  
       FROM @EventUpdates  
       Order By Id Asc  
      END  
     ELSE  
      BEGIN  
       SELECT Result_Set_Type,  
        Id ,  
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
        StartTime  ,  
        TransNum  ,  
        TestingStatus ,  
        CommentId ,  
        EventSubTypeId,  
        EntryOn  
       FROM @EventUpdates  
       Order By Id Asc  
      END  
    END  
  
          If (Select Count(*) From @EventDetails) > 0   
               SELECT  Result_Set_Type,  
       Pre_Update,  
       User_Id ,  
       Transaction_Type ,   
       Transaction_Number,  
        Event_Id ,  
        PU_Id ,  
       Primary_Event_Num ,  
       Alternate_Event_Num ,  
       Comment_Id,  
       Event_Type ,  
       Original_Product ,  
       Applied_Product,  
       Event_Status ,  
       TimeStamp ,  
       Entered_On ,  
       PP_Setup_Detail_Id ,  
       Shipment_Item_Id ,  
       Order_Id  ,  
       Order_Line_Id ,  
       PP_Id  ,  
       Initial_Dimension_X ,  
       Initial_Dimension_Y ,  
       Initial_Dimension_Z ,  
       Initial_Dimension_A ,  
       Final_Dimension_X ,  
       Final_Dimension_Y ,  
       Final_Dimension_Z,  
       Final_Dimension_A ,  
       Orientation_X ,  
       Orientation_Y ,  
       Orientation_Z   
     FROM @EventDetails  
          End  
/*******************************************************************************************************************  
                                  Unload the roll in the staged/running position      
*******************************************************************************************************************/  
     Else If @UnLoaded = 1  
          Begin  
  
/*  
          Select @MaxId = max(Input_Event_History_Id)   
          From PrdExec_Input_Event_History  
          Where   (PEI_Id = @PEI_Id) and (PEIP_Id = 1)  and (Unloaded = 0) and (timestamp < @HTimeStamp) and (Event_Id is not null)  
  
          Select @SourceId = Event_Id   
          From PrdExec_Input_Event_History  
          Where Input_Event_History_Id = @MaxId  
*/  
          Select @SourceId = Event_Id   
          From [dbo].PrdExec_Input_Event_History  
          Where Input_Event_History_Id = @Id  
  
          Select @EventId = Event_Id   
          From [dbo].Event_Components   
          Where Source_Event_Id = @SourceId  
  
          If @PEIP_Id = 1  
               /* Set the child event status to Partially-Run and the end time to the current time */  
               Insert into @EventUpdates (Id,Transaction_Type,Event_Id,Event_Num, PU_Id, TimeStamp,Source_Event, Event_Status, Confirmed, user_Id, Post_Update)  
               Select 1, 2, Event_Id, Event_Num, PU_Id, @strTimeStamp, Source_Event, 13, 1, @User_id, 0   
               From [dbo].Events  
               Where Event_Id = @EventId  
          Else /* If @PEIP_Id = 2 */  
               /* Set the child event status to Inventory  */  
               /* Don't update the time b/c don't want to collect converting data for a roll that wasn't run */  
               Insert into @EventUpdates (Id,Transaction_Type,Event_Id,Event_Num, PU_Id, TimeStamp,Source_Event, Event_Status, Confirmed, user_Id, Post_Update)  
               Select 1, 2, Event_Id, Event_Num, PU_Id, TimeStamp, Source_Event, 9, 1, @User_id, 0   
               From [dbo].Events  
               Where Event_Id = @EventId  
  
  
          /* Send event messages */  
          If (Select Count(*) From @EventUpdates) > 0   
               IF @AppVersion LIKE '4%'  
      BEGIN  
       SELECT Result_Set_Type,  
        Id ,  
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
        StartTime  ,  
        TransNum  ,  
        TestingStatus ,  
        CommentId ,  
        EventSubTypeId,  
        EntryOn,  
        Approved_User_Id,  
        Second_User_Id,  
        Approved_Reason_Id,  
        User_Reason_Id,  
        User_SignOff_Id,  
        Extended_Info  
       FROM @EventUpdates  
       Order By Id Asc  
      END  
     ELSE  
      BEGIN  
       SELECT Result_Set_Type,  
        Id ,  
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
        StartTime  ,  
        TransNum  ,  
        TestingStatus ,  
        CommentId ,  
        EventSubTypeId,  
        EntryOn  
       FROM @EventUpdates  
       Order By Id Asc  
      END  
          End  
  
     Select @ErrMsg = ''  
     Select @Success = 1  
     End  
Else If  @TableName = 'Events'  
     Begin  
  
     Select @PU_Id =   PU_Id, @TimeStamp =  TimeStamp, @Start_Time = Start_Time, @Status = Event_Status, @SourceId = Source_Event  
     From [dbo].Events  
     Where Event_Id = @Id  
  
     -- Update the start time to the current time  
     -- Update Events  
     -- Set Start_Time = @TimeStamp  
     -- Where Event_Id = @Id  
     --- Select 1, 1, 2, Event_Id, Event_Num, PU_Id, TimeStamp, Applied_Product, Source_Event, Event_Status,  1, 1, 0 From Events Where Event_Id = @Id  
  
     /* Link To Source */  
     If (@SourceId is Not Null) And ((Select Source_Event_Id From [dbo].Event_Components Where Event_Id = @Id) Is Null)  
          Begin  
  
          Insert into @EventComponents (Pre_Update, User_Id,Transaction_Type,Transaction_Number,Component_Id,Event_Id,Source_Event_Id, Dimension_X ,Dimension_Y, Dimension_Z , Dimension_A)  
          Values (1,@User_id,1,0,Null,@Id ,@SourceId,0,0,0,0)  
  
          If (select Count(*) from @EventComponents) > 0   
               BEGIN  
       IF @AppVersion LIKE '4%'  
        BEGIN  
         SELECT  Result_Set_Type,  
          Pre_Update ,  
          User_Id ,  
          Transaction_Type ,   
          Transaction_Number ,   
          Component_Id,  
          Event_Id ,  
          Source_Event_Id,  
          Dimension_X ,   
          Dimension_Y ,   
          Dimension_Z ,   
          Dimension_A,  
          StartCoordinateX,  
          StartCoordinateY,  
          StartCoordinateZ,  
          StartCoordinateA,  
          Start_Time,  
          Timestamp,  
          PP_Component_Id,  
          Entry_On,  
          Extended_Info  
          FROM @EventComponents  
        END  
       ELSE  
        BEGIN  
         SELECT  Result_Set_Type,  
          Pre_Update ,  
          User_Id ,  
          Transaction_Type ,   
          Transaction_Number ,   
          Component_Id,  
          Event_Id ,  
          Source_Event_Id,  
          Dimension_X ,   
          Dimension_Y ,   
          Dimension_Z ,   
          Dimension_A  
          FROM @EventComponents  
        END  
      END  
  
          End  
  
     Select @ErrMsg = ''  
     Select @Success = 1  
  
     End  
  
-- Cleanup  
-- Drop table #EventComponent  
-- Drop table #EventUpdates  
  
SET NOCOUNT OFF  
  
