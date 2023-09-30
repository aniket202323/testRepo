     /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-01  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_GeneCvtgCompleteRoll  
Author:   Matthew Wells (MSI)  
Date Created:  11/21/01  
  
Description:  
=========  
The procedure completes a roll out of the running position if a parent roll change has been selected in the reason tree.  
  
Note:  
Each slave unit location must contain 'UWS=#' in the Extended Info field where the number indicates the order of the UWS   
input in the genealogy configuration for the production unit (ie. UWS=1).   
  
Change Date Who What  
=========== ==== =====  
11/21/01 MKW Created procedure.  
10/31/02 MKW Increased name variables to varchar(50)  
   Added reinitialization of variables  
   Rewrote to accomodate the fact that the PU names are larger than the input field can hold.  
*/  
CREATE Procedure dbo.spLocal_GeneCvtgCompleteRoll  
@Output_Value   varchar(25) OUTPUT,  
@TEDet_Id   int,  
@Roll_PU_Id   int,  
@PRC_Reason_Level1_Name varchar(100),  
@PRC_Reason_Level2_Name varchar(100)  
As  
  
SET NOCOUNT ON  
  
-- NOT USE  
-- DECLARE @EventUpdates TABLE (  
--  Result_Set_Type  int DEFAULT 1,  
--  Id   int,  
--  Transaction_Type  int DEFAULT 1,   
--  Event_Id   int NULL,   
--  Event_Num   varchar(25) NULL,   
--  PU_Id    int NULL,   
--  TimeStamp   datetime NULL,  
--  Applied_Product  int NULL,   
--  Source_Event   int NULL,   
--  Event_Status   int NULL,   
--  Confirmed   int DEFAULT 1,  
--  User_Id   int DEFAULT 6,  
--  Post_Update  int DEFAULT 0,  
--  Conformance  int NULL,  
--  TestPctComplete  int NULL,  
--  StartTime  datetime NULL,  
--  TransNum  int DEFAULT 0,  
--  TestingStatus  int NULL,  
--  CommentId  int NULL,  
--  EventSubTypeId  int NULL,  
--  EntryOn   varchar(25) NULL,  
--  Approved_User_Id  int NULL,  
--  Second_User_Id   int NULL,  
--  Approved_Reason_Id int NULL,  
--  User_Reason_Id   int NULL,  
--  User_SignOff_Id  int NULL,  
--  Extended_Info   int NULL  
-- )  
  
  
DECLARE @EventInputs TABLE (  
 Result_Set_Type  int DEFAULT 12,  
 Pre_Update  int DEFAULT 1,  
 User_Id   int DEFAULT 6,  
 Transaction_Type  int DEFAULT 1,   -- 1 = ; 2 = ; 3 = Unload  
 Transaction_Number int DEFAULT 0,  -- Must be 0  
 TimeStamp   varchar(30) NULL,   
 Entry_On   varchar(30) NULL,   
 Comment_Id   int NULL,   
 PEI_Id    int NULL,   
 PEIP_Id   int NULL,   
 Event_Id   int NULL,   
 Dimension_X  float NULL,  
 Dimension_Y  float NULL,  
 Dimension_Z  float NULL,  
 Dimension_A  float NULL,  
 Unloaded   int NULL)  
  
Declare @PEI_Id   int,  
 @InputEventId   int,  
 @EventId   int,  
 @PU_Id   int,  
 @EventNum   varchar(25),  
 @Status   int,  
 @Source   int,  
 @Now    datetime,  
 @TimeStamp   datetime,  
 @Reason_Level1_Id  int,  
 @Reason_Level2_Id  int,  
 @Reason_Level1_Name varchar(100),  
 @Reason_Level2_Name varchar(100),  
 @Reason_Level  int,  
 @Start_Time   datetime,  
 @End_Time   datetime,  
 @Range_Start   datetime,  
 @Default_Window  int,  
 @Complete_History_Id  int,  
 @Staged_Position  int,  
 @Staged_Event_Id  int,  
 @Running_Position  int,  
 @Running_Event_Id  int,  
 @Running_TimeStamp  datetime,  
 @Location   int,  
 @PU_Desc   varchar(50),  
 @Consumed_Status_Id  int,  
 @Extended_Info  varchar(255),  
 @Flag_Start   int,  
 @Flag_Value   varchar(255),  
 @UWS_Flag   varchar(50),  
 @UWS_Position  int,  
 @UWS_Id   int,  
 @User_id   int,  
 @AppVersion   varchar(30)  
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
 -- user id for the resulset  
 SELECT @User_id = User_id   
 FROM [dbo].Users  
 WHERE username = 'Reliability System'  
  
/* Initialization */  
Select   @InputEventId    = Null,  
 @Output_Value    = '0',  
 @Default_Window  = 1,  
 @Range_Start    = Null,  
 @Running_Position  = 1,  
 @Staged_Position  = 2,  
 @Consumed_Status_Id  = 8,  
 @UWS_Flag   = 'UWSOrder=',  
 @UWS_Position  = Null,  
 @UWS_Id   = Null  
  
/* Clean Arguments */  
Select  @Reason_Level1_Name = LTrim(RTrim(@Reason_Level1_Name)),  
 @Reason_Level2_Name = LTrim(RTrim(@Reason_Level2_Name))  
  
/* Get reason1 and check for parent roll change */  
Select @Start_Time   = Start_Time,  
  @End_Time   = End_Time,  
 @Location   = Source_PU_Id,  
 @Reason_Level1_Id = Reason_Level1,  
 @Reason_Level2_Id = Reason_Level2  
From [dbo].Timed_Event_Details  
Where TEDet_Id = @TEDet_Id  
  
--Select  @End_Time = getdate(),  
-- @Start_Time = dateadd(mi, -2, @End_Time)  
  
/* Get Extended info field and parse out the unwind stand */  
Select @Extended_Info = upper(replace(Extended_Info, ' ', ''))+';'  
From [dbo].Prod_Units  
Where PU_Id = @Location  
  
/* Get the unwind stand flag */  
Select @Flag_Start = charindex(@UWS_Flag, @Extended_Info)  
If @Flag_Start > 0  
     Begin  
     Select @Flag_Start = @Flag_Start + len(@UWS_Flag)  
     Select @Flag_Value = substring(@Extended_Info, @Flag_Start, charindex(';', @Extended_Info, @Flag_Start) - @Flag_Start )  
     If isnumeric(@Flag_Value) = 1  
          Select @UWS_Position = convert(real, @Flag_Value)  
     End  
  
/* Get the unwind stand input id */  
Select @UWS_Id = PEI_Id  
From [dbo].PrdExec_Inputs  
Where PU_Id = @Roll_PU_Id And Input_Order = @UWS_Position  
  
If @UWS_Id Is Not Null  
     Begin  
     /* Get reason names */  
     Select @Reason_Level1_Name = Event_Reason_Name  
     From [dbo].Event_Reasons  
     Where Event_Reason_Id = @Reason_Level1_Id  
  
     Select @Reason_Level2_Name = Event_Reason_Name  
     From [dbo].Event_Reasons  
     Where Event_Reason_Id = @Reason_Level2_Id  
  
     /************************************************************************************************************************************************************************  
     *                                                            Process Current Backstand                                                              *  
     ************************************************************************************************************************************************************************/  
     /* Check for parent roll change */  
     If @Reason_Level1_Name = @PRC_Reason_Level1_Name  
          Begin  
          /* Reinitialize */  
          Select  @Running_Event_Id = Null,  
  @Running_TimeStamp = Null  
  
          /* Check to see if an event is actually loaded */  
          Select  @Running_Event_Id = Event_Id,   
      @Running_TimeStamp = TimeStamp  
          From [dbo].PrdExec_Input_Event  
          Where PEI_Id = @UWS_Id And PEIP_Id = @Running_Position  
  
          /* If event was loaded into the running position before the start of the downtime then complete it */  
          If @Running_Event_Id Is Not Null And @Running_TimeStamp < @Start_Time  
               Begin  
               /* Complete the roll */  
               Insert Into @EventInputs(Transaction_Type, TimeStamp, Entry_On, PEI_Id, PEIP_Id,Event_Id, Unloaded,User_id)   
               Values (1, @End_Time, getdate(), @UWS_Id, @Running_Position, Null, 1,@User_id)  
            
      -- NOT USE  
--                /* Consume the parent event */  
--                Insert into @EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Source_Event, Event_Status,User_id)  
--                Select 2, Event_Id, Event_Num, PU_Id, TimeStamp, Source_Event, @Consumed_Status_Id,@User_id  
--                From [dbo].Events  
--                Where Event_Id = @Running_Event_Id  
                      
               /* Check for an event in the staged position */  
               Select @Staged_Event_Id = Event_Id  
               From [dbo].PrdExec_Input_Event  
               Where PEI_Id = @UWS_Id And PEIP_Id = @Staged_Position  
  
               If @Staged_Event_Id Is Not Null  
                    Begin  
                    /* Unload the staged position */   
                    Insert Into @EventInputs(Transaction_Type, TimeStamp, Entry_On, PEI_Id, PEIP_Id,Event_Id, Unloaded,User_id)   
                    Values (3, @End_Time, getdate(), @UWS_Id, @Staged_Position, @Staged_Event_Id, 1,@User_id)  
  
                    /* Load the running position */   
                    Insert Into @EventInputs(Transaction_Type, TimeStamp, Entry_On, PEI_Id, PEIP_Id,Event_Id, Unloaded,User_id)   
                    Values (2, @End_Time, getdate(), @UWS_Id, @Running_Position, @Staged_Event_Id, 0,@User_id)  
                    End  
               End  
          End  
  
     /************************************************************************************************************************************************************************  
     *                                                            Process All Backstands                                                              *  
     ************************************************************************************************************************************************************************/  
     /* Check for double parent roll change */  
     If @Reason_Level2_Name = @PRC_Reason_Level2_Name  
          Begin  
          Declare Backstands Insensitive Cursor For  
          Select PEI_Id  
          From [dbo].PrdExec_Inputs  
          Where PU_Id = @Roll_PU_Id And PEI_Id <> @UWS_Id  
          For Read Only  
  
          Open Backstands  
          Fetch Next From Backstands Into @PEI_Id  
          While @@FETCH_STATUS = 0  
               Begin  
               /* Reinitialize */  
               Select  @Running_Event_Id = Null,  
        @Running_TimeStamp = Null  
  
               /* Check to see if an event is actually loaded */  
               Select  @Running_Event_Id = Event_Id,   
        @Running_TimeStamp = TimeStamp  
               From [dbo].PrdExec_Input_Event  
               Where PEI_Id = @PEI_Id And PEIP_Id = @Running_Position  
  
               /* If event was loaded into the running position before the start of the downtime then complete it */  
               If @Running_Event_Id Is Not Null And @Running_TimeStamp < @Start_Time  
                    Begin  
                    /* Complete the roll */  
                    Insert Into @EventInputs(Transaction_Type, TimeStamp, Entry_On, PEI_Id, PEIP_Id,Event_Id, Unloaded,User_id)   
                    Values (1, @End_Time, getdate(), @PEI_Id, @Running_Position, Null, 1,@User_id)  
  
        -- NOT USE        
--                     /* Consume the parent event */  
--                     Insert into @EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Source_Event, Event_Status,User_id)  
--                     Select 2, Event_Id, Event_Num, PU_Id, TimeStamp, Source_Event, @Consumed_Status_Id,@User_id  
--                     From [dbo].Events  
--                     Where Event_Id = @Running_Event_Id  
                      
                    /* Check for an event in the staged position */  
                    Select @Staged_Event_Id = Event_Id  
                    From [dbo].PrdExec_Input_Event  
                    Where PEI_Id = @PEI_Id And PEIP_Id = @Staged_Position  
  
                    If @Staged_Event_Id Is Not Null  
                         Begin  
                         /* Unload the staged position */   
                         Insert Into @EventInputs(Transaction_Type, TimeStamp, Entry_On, PEI_Id, PEIP_Id,Event_Id, Unloaded,User_id)   
                         Values (3, @End_Time, getdate(), @PEI_Id, @Staged_Position, @Staged_Event_Id, 1,@User_id)  
  
                         /* Load the running position */   
                         Insert Into @EventInputs(Transaction_Type, TimeStamp, Entry_On, PEI_Id, PEIP_Id,Event_Id, Unloaded,User_id)   
                         Values (2, @End_Time, getdate(), @PEI_Id, @Running_Position, @Staged_Event_Id, 0,@User_id)  
                         End  
                    End  
               Fetch Next From Backstands Into @PEI_Id  
               End  
          Close Backstands  
          Deallocate Backstands  
          End  
     /************************************************************************************************************************************************************************  
     *                                                            Output Results                                                          *  
     ************************************************************************************************************************************************************************/  
     If (Select Count(Transaction_Type) From @EventInputs) > 0  
         SELECT  Result_Set_Type ,  
    Pre_Update ,  
    User_Id ,  
    Transaction_Type  ,     
    Transaction_Number ,  
    TimeStamp ,   
    Entry_On  ,   
    Comment_Id ,   
    PEI_Id ,   
    PEIP_Id ,   
    Event_Id ,   
    Dimension_X ,  
    Dimension_Y ,  
    Dimension_Z ,  
    Dimension_A ,  
    Unloaded    
   FROM @EventInputs  
  
      /* Note reason selection for next time */  
      Select @Output_Value = '1'  
     End  
  
  
/* Cleanup */  
-- Drop Table #EventInputs  
-- Drop Table #EventUpdates  
  
SET NOCOUNT OFF  
  
