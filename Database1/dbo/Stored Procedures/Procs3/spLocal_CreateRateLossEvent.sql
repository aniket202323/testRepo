  /*  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-26  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_CreateRateLossEvent  
Author:   Matthew Wells (MSI)  
Date Created:  10/24/01  
  
Description:  
=========  
This procedure monitors yankee speed and crepe signals and creates/updates Production and Downtime events when the value of the signal changes.  
The yankee speed and crepe values are used to calculate reel speed signals.  This is used instead of the raw reel speed signal b/c the reel speed signal  
can show a zero value during a sheetbreak.  The procedure gets the Target speed value and uses a deadband to determine whether the speed has  
exceeded the speed target.  The procedure also checks for downtime and if found will end any open rate loss events and prevent new ones from being   
created if currently in downtime.  
  
For the Target Speed value a variable must be created with the specified @Speed_Target_Flag value in its Extended_Info field.  The actual target speed  
value must be entered as that variables' Target value in the specifications.  Similarly, for the downtime a variable must be created under the downtime unit  
with the @DT_PU_Flag value in its Extended_Info field.  The procedure will use this to get the unit and search for Downtime events under that unit.  
  
Change Date Who What  
=========== ==== =====  
08/27/01 MKW Created procedure.  
01/24/02 MKW Moved up call to PU_Id.  
   Changed the search of Timed_Event_Sum for most recent event to Timed_Event_Details  
01/29/02 MKW Added TEDet_Id to the Downtime event result sets for updates (Transaction_Type = 2)  
01/30/02 MKW Changed search for most recent RL record to have '>= @TimeStamp' instead of just '>' and modifed the @JumpToTime selection  
02/02/02 MKW Changed closure of Rate Loss downtime to match the actual downtime record.  
   Added check for most recent Event (as well as Timed_Event) to prevent reruns.  
02/20/02 MKW Changed check for last event to check for Production Event instead of Downtime event b/c Production Events are guarranteed to be there.  
03/13/02 MKW Fixed Julian Date  
*/  
  
CREATE procedure dbo.spLocal_CreateRateLossEvent  
@Success int OUTPUT,  
@ErrorMsg varchar(255) OUTPUT,  
@JumpToTime varchar(30) OUTPUT,  
@ECId int,  
@Reserved1 varchar(30),  
@Reserved2 varchar(30),  
@Reserved3 varchar(30),  
@ChangedTagNum int,  
@ChangedTagPrevValue varchar(30),  
@ChangedTagNewValue varchar(30),  
@ChangedTagPrevTime varchar(30),  
@ChangedTagNewTime varchar(30),  
@SpeedPrevValue varchar(30),  
@SpeedNewValue varchar(30),  
@SpeedPrevTime varchar(30),  
@SpeedNewTime varchar(30),  
@CrepePrevValue varchar(30),  
@CrepeNewValue varchar(30),  
@CrepePrevTime varchar(30),  
@CrepeNewTime varchar(30),  
@ReliabilityPrevValue varchar(30),  
@ReliabilityNewValue varchar(30),  
@ReliabilityPrevTime varchar(30),  
@ReliabilityNewTime varchar(30)  
As  
  
--Insert Into Local_TestRateLoss (ECId,Reserved1,Reserved2,Reserved3,ChangedTagNum,ChangedTagPrevValue,ChangedTagNewValue,ChangedTagPrevTime,ChangedTagNewTime,SpeedPrevValue,SpeedNewValue,SpeedPrevTime,SpeedNewTime,CrepePrevValue,CrepeNewValue,CrepePrevTime,CrepeNewTime,ReliabilityPrevValue,ReliabilityNewValue,ReliabilityPrevTime,ReliabilityNewTime)  
--Values (@ECId,@Reserved1,@Reserved2,@Reserved3,@ChangedTagNum,@ChangedTagPrevValue,@ChangedTagNewValue,@ChangedTagPrevTime,@ChangedTagNewTime,@SpeedPrevValue,@SpeedNewValue,@SpeedPrevTime,@SpeedNewTime,@CrepePrevValue,@CrepeNewValue,@CrepePrevTime,@CrepeNewTime,@ReliabilityPrevValue,@ReliabilityNewValue,@ReliabilityPrevTime,@ReliabilityNewTime)  
  
Declare @EventUpdates Table (  
-- Result_Set_Type int Default 1,  
 Id        int Identity,  
 Transaction_Type  int Default 1,   
 Event_Id   int Null,   
 Event_Num   varchar(25) Null,   
 PU_Id    int Null,   
 TimeStamp   varchar(30) Null,   
 Applied_Product  int Null,   
 Source_Event   int Null,   
 Event_Status   int Null,   
 Confirmed   int Default 1,  
 User_Id   int Default 1,  
 Post_Update  int Default 0)  
  
Declare @EventDetails Table  (  
-- Result_Set_Type int Default 10,  
 Pre_Update       int Default 1,  
  
 User_Id   int Default 1,  
 Transaction_Type  int Default 1,   
 Transaction_Number int Null,  
  Event_Id  int Null,  
  PU_Id   int Null,  
 Primary_Event_Num varchar(25) Null,  
 Alt_Event_Num  varchar(25) Null,  
 Comment_Id  int Null,  
 Event_Type  int Null,  
 Original_Product  int Null,  
 Applied_Product  int Null,  
 Event_Status  int Null Default 5,  
 TimeStamp  datetime Null,  
 Entered_On  datetime Null,  
 PP_Setup_Detail_Id int Null,  
 Shipment_Item_Id int Null,  
 Order_Id  int Null,  
 Order_Line_Id  int Null,  
 PP_Id   int Null,  
 Initial_Dimension_X float Null,  
 Initial_Dimension_Y float Null,  
 Initial_Dimension_Z float Null,  
 Initial_Dimension_A float Null,  
 Final_Dimension_X float Null,  
 Final_Dimension_Y float Null,  
 Final_Dimension_Z         float Null,  
 Final_Dimension_A         float Null,  
 Orientation_X   tinyint Null,  
 Orientation_Y   tinyint Null,  
 Orientation_Z  tinyint Null)  
  
Declare @DowntimeEvents Table  (  
-- Result_Set_Type int Default 5,  
 PU_Id   int Null,  
 Source_PU_Id  int Null,  
 Status_Id  int Null,  
 Fault_Id   int Null,  
 Reason1  int Null,  
 Reason2  int Null,  
 Reason3  int Null,  
 Reason4  int Null,  
 Prod_Rate  int Null,  
 Duration  float Null,  
 Transaction_Type  int Default 1,  
 Start_Time  datetime Null,  
 End_Time  datetime Null,  
 TEDet_Id   int Null)  
  
Declare @Julian_Date  varchar(25),  
 @RL_Start_Date varchar(30),  
 @Prod_Start_Date datetime,  
 @Event_Count  int,  
 @Event_Num  varchar(25),  
 @Event_Id  int,   
 @New_Event_Id int,  
 @PU_Id  int,   
 @PL_Id   int,  
 @DT_PU_Id  int,  
 @DT_PU_Flag  varchar(25),  
 @DT_Start_Time datetime,   
 @DT_End_Time datetime,  
 @RL_Start_Time datetime,   
 @RL_End_Time  datetime,  
 @RL_TEDet_Id  int,  
 @RL_Event_Id  int,  
 @RL_TimeStamp datetime,  
 @TimeStamp  datetime,  
 @Last_TimeStamp datetime,  
 @Last_Event_Id int,  
 @Speed  float,  
 @Speed_Target  float,  
 @Speed_Target_Flag varchar(25),  
 @Speed_Target_Name varchar(25),  
 @Speed_Target_Var_Id int,  
 @Last_Speed  float,  
 @Last_Speed_Target float,  
 @Result_On  datetime,  
 @Deadband  float,  
 @Prod_Id  int,  
 @Prod_PU_Id  int,  
 @Prod_Start_Time datetime,  
 @Event_Status  int,  
 @Running_Status int,  
 @Complete_Status int,  
 @Default_Window int,  
 @Range_Start_Time datetime,  
 @Duplicate_Count int,  
 @Loop_Count  int,  
 @TEDet_Id  int,  
 @TE_Start_Time datetime,   
 @TE_End_Time  datetime,  
 @User_id    int,  
 @AppVersion   varchar(30),  
 @StrSQL    varchar(8000)  
  
  
 SET NOCOUNT ON  
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
   
  
If @ChangedTagPrevValue <> @ChangedTagNewValue  
     Begin  
/*  
Insert Into Local_TestRateLossEvent (ECId, Reserved1, Reserved2, Reserved3, ChangedTagNum,ChangedTagPrevValue, ChangedTagNewValue, ChangedTagPrevTime, ChangedTagNewTime, SpeedPrevValue, SpeedNewValue, SpeedPrevTime, SpeedNewTime, CrepePrevValue, CrepeNewV
alue, CrepePrevTime, CrepeNewTime, ReliabilityPrevValue, ReliabilityNewValue, ReliabilityPrevTime, ReliabilityNewTime)  
Values (@ECId, @Reserved1, @Reserved2, @Reserved3, @ChangedTagNum, @ChangedTagPrevValue, @ChangedTagNewValue, @ChangedTagPrevTime, @ChangedTagNewTime, @SpeedPrevValue, @SpeedNewValue, @SpeedPrevTime, @SpeedNewTime, @CrepePrevValue, @CrepeNewValue, @CrepeP
revTime, @CrepeNewTime, @ReliabilityPrevValue, @ReliabilityNewValue, @ReliabilityPrevTime, @ReliabilityNewTime)  
*/  
 /************************************************************************************************************************************************************************  
     *                                                                                         Initialization and Arguments                                                                                           *  
     ************************************************************************************************************************************************************************/  
  
 /* User_Id Initialization */  
  SELECT @User_id = User_id   
  FROM Users  
  WHERE username = 'Reliability System'  
  
    /* Initialization */  
     Select @Deadband    = 100,  
    @DT_PU_Flag  = '/Machine_Downtime_PU/',  
    @Speed_Target_Flag  = '/Target_Speed/',  
    @Speed_Target_Name = '%',  
    @Running_Status   = 4,  
    @Complete_Status   = 5,  
    @Event_Id    = Null,  
    @New_Event_Id   = 0,  
    @Default_Window   = 365,  
    @RL_TEDet_Id   = Null,  
    @Duplicate_Count   = 1,  
    @Loop_Count   = 0,  
    @TimeStamp    = convert(datetime, rtrim(ltrim(@ChangedTagNewTime))),  
    @Range_Start_Time   = DateAdd(dd, -@Default_Window, @TimeStamp),  
    @Speed    = convert(float, rtrim(ltrim(@SpeedNewValue)))*(1+convert(float, rtrim(ltrim(@CrepeNewValue)))/100)  
  
     /* Get PU Id And PL_Id - MKW 01/24/02 - Moved up from below */  
     Select @PU_Id = PU_Id  
     From [dbo].Event_Configuration  
     Where EC_Id = @ECId  
  
     /************************************************************************************************************************************************************************  
     *                                                                       Get Most Recent Event TimeStamp to Prevent Reruns                                                                  *  
     ************************************************************************************************************************************************************************/  
     /* MKW 01/30/02 - Change '> @TimeStamp to '>= @TimeStamp */  
     Select TOP 1 @TEDet_Id = TEDet_Id, @TE_Start_Time = Start_Time, @TE_End_Time = End_Time  
     From [dbo].Timed_Event_Details  
     Where PU_Id = @PU_Id And Start_Time >= @TimeStamp  
     Order By Start_Time Desc  
  
     If @TEDet_Id Is Null  
          Begin  
          /************************************************************************************************************************************************************************  
          *                                                                       Get Most Recent Event TimeStamp to Prevent Reruns                                                                  *  
          ************************************************************************************************************************************************************************/  
          Select TOP 1 @RL_Event_Id = Event_Id, @RL_TimeStamp = TimeStamp  
          From [dbo].Events  
          Where PU_Id = @PU_Id And TimeStamp >= @TimeStamp  
          Order By TimeStamp Desc  
  
          If @RL_Event_Id Is Null  
               Begin  
  
               /************************************************************************************************************************************************************************  
               *                                                                                                         Get Inputs                                                                                                      *  
               ************************************************************************************************************************************************************************/  
               /* Downtime PU_Id  */  
               Select @PL_Id = PL_Id  
               From [dbo].Prod_Units  
               Where PU_Id = @PU_Id  
  
               Select @DT_PU_Id = PU_Id  
               From [dbo].Prod_Units  
               Where PL_Id = @PL_Id And Extended_Info = @DT_PU_Flag  
  
               /* Get the current speed target value to test against the current calculated speed  */  
               Select @Speed_Target_Var_Id = Var_Id  
               From [dbo].Variables  
               Where  PU_Id = @PU_Id And Var_Desc Like @Speed_Target_Name And Extended_Info = @Speed_Target_Flag  
  
               /* Get current product running */  
               Select @Prod_Id = Prod_Id, @Prod_Start_Time = Start_Time  
               From [dbo].Production_Starts  
               Where PU_Id = @PU_Id And Start_Time <= @TimeStamp And (End_Time > @TimeStamp Or End_Time Is Null)       
  
               /* Get the current speed target */  
               Select @Speed_Target = Target   
               From [dbo].Var_Specs  
               Where Var_id = @Speed_Target_Var_Id And Prod_Id = @Prod_Id And Effective_Date <= @TimeStamp And (Expiration_Date > @TimeStamp Or Expiration_Date Is Null)  
  
               /************************************************************************************************************************************************************************  
               *                                                                                              Get current event data                                                                                              *  
               ************************************************************************************************************************************************************************/  
               /* Get last open Rate Loss Event */  
               Select Top 1  @RL_Event_Id   = e.Event_Id,   
     @Last_TimeStamp  = e.TimeStamp,  
     @Event_Status   = e.Event_Status,   
     @Event_Num   = e.Event_Num,   
     @Last_Speed   = ed.Final_Dimension_X,   
     @Last_Speed_Target  = ed.Final_Dimension_Y  
               From [dbo].Events  e with(nolock)
					join dbo.event_details ed with(Nolock) on e.event_id = ed.event_id
               Where e.PU_Id = @PU_Id And TimeStamp < @TimeStamp  
               Order By e.TimeStamp Desc  
  
               Select @RL_Start_Date = convert(varchar(30), @Last_TimeStamp, 120)  
  
               /* Check rate loss/rate gain condition - current rate < target rate */  
               If Abs(@Speed_Target - @Speed) > @Deadband -- Or @Last_Speed_Target <> @Speed_Target  
                    Begin  
                    /* Check to see if in a Downtime */  
                    Select @DT_Start_Time = Start_Time  
                    From [dbo].Timed_Event_Details  
                    Where PU_ID = @DT_PU_ID And Start_Time < @TimeStamp And (End_Time > @TimeStamp Or End_Time Is Null)  
  
                    If @DT_Start_Time Is Not Null  
                         Begin  
                         If @RL_Event_Id Is Not Null  
                              Begin  
                              /************************************************************************************************************************************************************************  
                              *                                                                                      Close Open Rate Loss Event                                                                                           *  
                              ************************************************************************************************************************************************************************/  
                              /* Close existing loss production event */  
                              Insert into @EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,User_id)  
                              Values(2, @RL_Event_Id, @Event_Num, @PU_Id, @RL_Start_Date, @Complete_Status,@User_id)  
  
                              /* Close existing loss downtime event */  
                              Insert Into @DowntimeEvents (PU_Id, Start_Time, End_Time, Transaction_Type, TEDet_Id)  
                     Select PU_Id, Start_Time, @DT_Start_Time, 2, TEDet_Id  
                              From [dbo].Timed_Event_Details  
                              Where PU_Id = @PU_Id And Start_Time = @RL_Start_Date And End_Time Is Null  
--                              Values(@PU_Id, @RL_Start_Date, @DT_Start_Time, 2, @RL_TEDet_Id)  
                              End  
                         End  
                    Else  
                         Begin  
                         If @RL_Event_Id Is Not Null  
                              Begin  
                              /* Check the current rate loss condition against the last one to see if should close old event and create a new one */  
                              If Abs(@Speed_Target - @Last_Speed_Target) > @Deadband Or  -- Target Speed changed beyond the deadband value  
                                 @Prod_Start_Time > @RL_Start_Time Or     -- There was product change  
                                 Abs(@Speed - @Last_Speed) > @Deadband    -- Actual Speed changed beyond the deadband value  
                                   Begin  
                                   /************************************************************************************************************************************************************************  
                                   *                                                                                      Close Open Rate Loss Event                                                                                           *  
                                   ************************************************************************************************************************************************************************/  
                                   /* Close existing loss production event */  
                                   Insert into @EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,User_id)  
                                   Values(2, @RL_Event_Id, @Event_Num, @PU_Id, @RL_Start_Date, @Complete_Status,@User_id)  
  
                                   /* Close existing loss downtime event */  
                                   Insert Into @DowntimeEvents (PU_Id, Start_Time, End_Time, Transaction_Type, TEDet_Id)  
                                   Select PU_Id, Start_Time, @TimeStamp, 2, TEDet_Id  
                                   From [dbo].Timed_Event_Details  
                                   Where PU_Id = @PU_Id And Start_Time = @RL_Start_Date And End_Time Is Null  
  
                                   /************************************************************************************************************************************************************************  
                                   *                                                                           Create Rate Loss Production Event Number                                                                               *  
                                   ************************************************************************************************************************************************************************/  
                                   /* Get Julian date */  
                                   Select @Julian_Date = right(datename(yy, @TimeStamp),1)+right('000'+datename(dy, @TimeStamp), 3)  
  
                                   /* Get TimeStamp for the start of the current day and then calculate number of events in the current day*/  
                                   Select @Prod_Start_Date = convert(datetime, floor(convert(float, @TimeStamp)))  
  
                                   Select @Event_Count = count(Event_Id)  
                                   From [dbo].Events   
                                   Where PU_Id = @PU_Id And TimeStamp >= @Prod_Start_Date And TimeStamp < dateadd(dd, 1, @Prod_Start_Date)  
  
                                   /* Build the Event number, check for duplicates and if found increment counter and rebuild the event number */  
                                   While @Duplicate_Count > 0 And @Loop_Count < 1000  
                                        Begin  
                                        Select @Event_Num = right(convert(varchar(25),@Event_Count+1001),3) + @Julian_Date  
  
                                        Select @Duplicate_Count = count(Event_Id)   
                                        From [dbo].Events   
                                        Where PU_Id = @PU_Id And Event_Num = @Event_Num  
  
  
                                        Select @Event_Count = @Event_Count + 1  
                                        Select @Loop_Count = @Loop_Count + 1        /* Prevent infinite loops */  
                                        End  
  
                                   /************************************************************************************************************************************************************************  
                                   *                                                              Create New Rate Loss Production Event and Downtime Event                                                               *  
                                   ************************************************************************************************************************************************************************/  
                                   /* Create a new Rate Loss production event */     
            SELECT @StrSQL = 'Execute spServer_DBMgrUpdEvent ' +   
             convert(varchar(10),@New_Event_Id) + ' OUTPUT, ' +     -- Event_Id  
             '' + @Event_Num + ''',' +          -- Event_Num  
             convert(varchar(10),@PU_Id) + ', ' +           -- PU_Id  
             '' + @TimeStamp + ''',' +          -- TimeStamp  
             'Null, ' +           -- Applied_Product  
             'Null, ' +           -- Source_Event  
             convert(varchar(10),@Running_Status) + ', ' +       -- Event_Status  
             convert(varchar(10),1) + ', ' +            -- TransactionType  
             convert(varchar(10),0) + ', ' +            -- TransNum  
             convert(varchar(10),@User_Id) + ', ' +          -- UserId  
             'Null, ' +           -- CommentId  
             'Null, ' +           -- EventSubTypeId  
             'Null, ' +           -- TestingStatus  
             'Null, ' +           -- StartTime  
             'Null, ' +           -- EntryOn  
             convert(varchar(10),1)            -- ReturnResultSet  
  
            IF @AppVersion LIKE '4%'  
             BEGIN  
              -- Added P4 --  
              SELECT @StrSQL = @StrSQL +   
                ',Null, ' +           -- Conformance  
                'Null, ' +           -- TestPctComplete  
                'Null, ' +           -- SecondUserId  
                'Null, ' +           -- ApproverUserId  
                'Null, ' +           -- ApproverReasonId  
                'Null, ' +           -- UserReasonId  
                'Null, ' +           -- UserSignoffId  
                'Null'            -- Extended_Info  
             END  
  
            EXEC @StrSQL  
  
            --replace by a resultset  
--                                    Update [dbo].Events  
--                                    Set Final_Dimension_X = @Speed, Final_Dimension_Y = @Speed_Target  
--                                    Where Event_Id = @New_Event_Id  
  
            /* Update the Production Event Details */  
--              SELECT 10,  
--                0,             -- Post-Update  
--              @User_Id,           -- UserId  
--              2,             -- TransactionType  
--              0,             -- TransactionNumber  
--              @New_Event_Id,         -- EventId  
--              @PU_Id,           -- UnitId  
--              @Event_Num,          -- PrimaryEventNumber  
--              Null,            -- AlternateEventNumber  
--              Null,            -- CommentId  
--              Null,            -- EventSubTypeId  
--              Null,            -- OriginalProduct  
--              Null,            -- AppliedProduct  
--              @Running_Status,        -- EventStatus  
--              Null,            -- TimeStamp (No Longer Used)  
--              Null,            -- EntryOn  
--              Null,            -- ProductionPlanSetup  
--              Null,            -- ShipmentItemId  
--              Null,            -- OrderId  
--              Null,            -- OrderLineId  
--              Null,            -- ProductionPlanId  
--              Null,            -- Initial_DimensionX  
--              Null,            -- Initial_DimensionY  
--              Null,            -- Initial_DimensionZ  
--              Null,            -- Initial_DimensionA  
--              @Speed,           -- Final_DimensionX  
--              @Speed_Target,         -- Final_DimensionY  
--              Null,            -- Final_DimensionZ  
--              Null            -- Final_DimensionA  
  
                                   Insert into @EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,User_id)  
                                   Values(1, @New_Event_Id, @Event_Num, @PU_Id, @ChangedTagNewTime, @Running_Status,@User_id)  
  
                                   /* Update the Event_Details table with Rate Loss paramenters */  
                                   Insert Into @EventDetails (Event_Id, PU_Id, Event_Status, TimeStamp, Final_Dimension_X, Final_Dimension_Y, Primary_Event_Num,User_id)  
                                   Values(@New_Event_Id, @PU_Id, @Running_Status, @TimeStamp, @Speed, @Speed_Target, @Event_Num,@User_id)  
  
                                   /* Create new Rate Loss downtime event */  
                                   Insert Into @DowntimeEvents (PU_Id, Start_Time, End_Time, Transaction_Type)  
                                   Values(@PU_Id, @TimeStamp, Null, 1)  
                                   End  
                              End  
                         Else  
                              Begin  
                              /************************************************************************************************************************************************************************  
                              *                                                                           Create Rate Loss Production Event Number                                                                               *  
                              ************************************************************************************************************************************************************************/  
                              /* Get Julian date */  
                              Select @Julian_Date = right(datename(yy, @TimeStamp),1)+right('000'+datename(dy, @TimeStamp), 3)  
  
                              /* Get TimeStamp for the start of the current day and then calculate number of events in the current day*/  
                              Select @Prod_Start_Date = convert(datetime, floor(convert(float, @TimeStamp)))  
  
                              Select @Event_Count = count(Event_Id)  
                              From [dbo].Events   
                              Where PU_Id = @PU_Id And TimeStamp >= @Prod_Start_Date And TimeStamp < dateadd(dd, 1, @Prod_Start_Date)  
  
                              /* Build the Event number, check for duplicates and if found increment counter and rebuild the event number */  
                              While @Duplicate_Count > 0 And @Loop_Count < 1000  
                                   Begin  
                                   Select @Event_Num = right(convert(varchar(25),@Event_Count+1001),3) + @Julian_Date  
  
                                   Select @Duplicate_Count = count(Event_Id)   
                                   From [dbo].Events   
                                   Where PU_Id = @PU_Id And Event_Num = @Event_Num  
  
                                   Select @Event_Count = @Event_Count + 1  
                                   Select @Loop_Count = @Loop_Count + 1        /* Prevent infinite loops */  
                                   End  
  
                              /************************************************************************************************************************************************************************  
                              *                                                              Create New Rate Loss Production Event and Downtime Event                                                               *  
                              ************************************************************************************************************************************************************************/  
--                               /* Create a new Rate Loss Event */     
--                               Execute spServer_DBMgrUpdEvent @New_Event_Id OUTPUT, @Event_Num, @PU_Id, @TimeStamp,   
--                                                             Null, Null, @Running_Status, 1, 0, 6, Null, Null, Null, Null, Null, 1  
  
           /* Create a new Rate Loss production event */     
            SELECT @StrSQL = 'Execute spServer_DBMgrUpdEvent ' +   
             convert(varchar(10),@New_Event_Id) + ' OUTPUT, ' +     -- Event_Id  
             '' + @Event_Num + ''',' +          -- Event_Num  
             convert(varchar(10),@PU_Id) + ', ' +           -- PU_Id  
             '' + @TimeStamp + ''',' +          -- TimeStamp  
             'Null, ' +           -- Applied_Product  
             'Null, ' +           -- Source_Event  
             convert(varchar(10),@Running_Status) + ', ' +       -- Event_Status  
             convert(varchar(10),1) + ', ' +            -- TransactionType  
             convert(varchar(10),0) + ', ' +            -- TransNum  
             convert(varchar(10),@User_Id) + ', ' +          -- UserId  
             'Null, ' +           -- CommentId  
             'Null, ' +           -- EventSubTypeId  
             'Null, ' +           -- TestingStatus  
             'Null, ' +           -- StartTime  
             'Null, ' +           -- EntryOn  
             convert(varchar(10),1)            -- ReturnResultSet  
  
            IF @AppVersion LIKE '4%'  
             BEGIN  
              -- Added P4 --  
              SELECT @StrSQL = @StrSQL +   
                ',Null, ' +           -- Conformance  
                'Null, ' +           -- TestPctComplete  
                'Null, ' +           -- SecondUserId  
                'Null, ' +           -- ApproverUserId  
                'Null, ' +           -- ApproverReasonId  
                'Null, ' +           -- UserReasonId  
                'Null, ' +           -- UserSignoffId  
                'Null'            -- Extended_Info  
             END  
  
           EXEC @StrSQL  
  
           -- Replace by a resultset  
--                               Update Events  
--                               Set Final_Dimension_X = @Speed, Final_Dimension_Y = @Speed_Target  
--                               Where Event_Id = @New_Event_Id  
  
          /* Update the Production Event Details */  
--            SELECT 10,  
--              0,             -- Post-Update  
--            @User_Id,           -- UserId  
--            2,             -- TransactionType  
--            0,             -- TransactionNumber  
--            @New_Event_Id,         -- EventId  
--            @PU_Id,           -- UnitId  
--            @Event_Num,          -- PrimaryEventNumber  
--            Null,            -- AlternateEventNumber  
--            Null,            -- CommentId  
--            Null,            -- EventSubTypeId  
--            Null,            -- OriginalProduct  
--            Null,            -- AppliedProduct  
--            @Running_Status,        -- EventStatus  
--            Null,            -- TimeStamp (No Longer Used)  
--            Null,            -- EntryOn  
--            Null,            -- ProductionPlanSetup  
--            Null,            -- ShipmentItemId  
--            Null,            -- OrderId  
--            Null,            -- OrderLineId  
--            Null,            -- ProductionPlanId  
--            Null,            -- Initial_DimensionX  
--            Null,            -- Initial_DimensionY  
--            Null,            -- Initial_DimensionZ  
--            Null,            -- Initial_DimensionA  
--            @Speed,           -- Final_DimensionX  
--            @Speed_Target,         -- Final_DimensionY  
--            Null,            -- Final_DimensionZ  
--            Null            -- Final_DimensionA  
  
  
                              Insert into @EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,User_id)  
                              Values(1, @New_Event_Id, @Event_Num, @PU_Id, @ChangedTagNewTime, @Running_Status,@User_id)  
  
                              /* Update the Event_Details table and then update the Events table details */  
                              Insert Into @EventDetails (Event_Id, PU_Id, Event_Status, TimeStamp, Final_Dimension_X, Final_Dimension_Y, Primary_Event_Num,User_id)  
                              Values(@New_Event_Id, @PU_Id, @Running_Status, @TimeStamp, @Speed, @Speed_Target, @Event_Num,@User_id)  
  
                              /* Create new Rate Loss downtime event */  
                              Insert Into @DowntimeEvents (PU_Id, Start_Time, End_Time, Transaction_Type)  
                              Values(@PU_Id, @TimeStamp, Null, 1)  
                              End  
                         End  
                    End  
               /* If not in Rate Loss check for open Rate Loss event and if necessary close it */  
               Else If @RL_Event_Id Is Not Null  
                    Begin  
                    /************************************************************************************************************************************************************************  
                    *                                                                                      Close Open Rate Loss Event                                                                                           *  
                    ************************************************************************************************************************************************************************/  
                    /* Close existing Rate Loss production event */  
                    Insert Into @EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status,User_id)  
                    Values ( 2, @RL_Event_Id, @Event_Num, @PU_Id, @RL_Start_Date, @Complete_Status,@User_id)  
  
                    /* Close existing Rate Loss downtime event */  
                    Insert Into @DowntimeEvents (PU_Id, Start_Time, End_Time, Transaction_Type, TEDet_Id)  
                    Select PU_Id, Start_Time, @ChangedTagNewTime, 2, TEDet_Id  
                    From [dbo].Timed_Event_Details  
                    Where PU_Id = @PU_Id And Start_Time = @RL_Start_Date And End_Time Is Null  
                    End  
  
               /* Return result sets */  
               If (Select count(Transaction_Type) From @EventUpdates) > 0  
                    Select 1, Id , Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Applied_Product, Source_Event, Event_Status, Confirmed,User_Id,Post_Update   
       From @EventUpdates  
       
               If (Select count(Transaction_Type) From @DowntimeEvents) > 0  
                    Select 5, PU_Id ,Source_PU_Id,Status_Id,Fault_Id,Reason1,Reason2,Reason3,Reason4,Prod_Rate,Duration,Transaction_Type,Start_Time,End_Time,TEDet_Id   
       From @DowntimeEvents  
  
               If (Select count(Transaction_Type) From @EventDetails) > 0  
                    Select 10, * From @EventDetails  
               End  
               /* MKW 02/02/02 - Modified selection of @JumpToTime b/c don't want to jump to the same time */  
               If @RL_TimeStamp > @TimeStamp  
                    Select @JumpToTime = @RL_TimeStamp  
          End  
     Else  
          /* MKW 01/30/02 - Modified selection of @JumpToTime b/c don't want to jump to the same time */  
          If @TE_Start_Time > @TimeStamp  
               Select @JumpToTime = Coalesce(@TE_End_Time, @TE_Start_Time)  
          Else  
               Select @JumpToTime = @TE_End_Time  
     End  
  
/* Return Values */  
Select @Success = -1  
Select @ErrorMsg = NULL  
  
/* Clean Up */  
-- Drop Table #EventUpdates  
-- Drop Table #EventDetails  
-- Drop Table #DowntimeEvents  
  
SET NOCOUNT OFF  
  
