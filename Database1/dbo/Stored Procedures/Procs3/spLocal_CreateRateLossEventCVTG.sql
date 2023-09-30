 /*  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-26  
Version  : 1.0.10  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_CreateRateLossEventCVTG  
Author:   Matthew Wells (MSI)  
   Modified by Barry Stewart (Stier Automation, LLC.)  
Date Created:  10/24/01  
  
Description:  
=========  
This procedure is based on written requirements submitted by Eric Zahn, RE at WHTC.    
The procedure samples and monitors the lineâ€™s speed and compare to the lineâ€™s target speed for the brand code that is being produced.   
A speed threshold is used to determine if a rate loss event is triggered and initiated. The threshold is defined as a speed 3% below the target speed for that brand code â€“ or, 0.97*target speed.  
  
A rate loss event can be triggered/detected:  
a) the line rate, while running, drops below the threshold speed;  
b) after startup, the line is not above the threshold 60 seconds after startup.   
  
The end of a rate loss event occurs when either:  
a) the speed of the line goes above the threshold value; or  
b) the machine goes down  
  
The order of the inputs are important and need to remain as they are.  
  
Change Date Who What  
=========== ==== =====  
02/12/03 BAS Cleaned up and reomved fault code input tag and table updates  
03/07/03 BAS Added hot insert  
04/20/03 MKW Changed to hot insert Timed_Event_Details directly  
04/24/03 MKW Added tracking of downtime events in Local_Event_Starts  
   Also changed to end on every downtime event  
05/01/03 MKW Removed hot insert of Timed_Event_Details and put in Local_Event_Starts instead b/c result sets  
   weren't being processed fast enough  
07/25/03 MKW Removed User_Id from recent event query for JumpToTime  
10/04/03 MKW Dropped End_Time from the Timed_Event_Details query into the future.  
11/06/03 DWFH Replaced tempdb tables with local variable tables.  
04/06/04 BAS Changed the @Speed_Target_Flag initalization and query' to accomodate to 'GblDesc=' addtion in the Ext Info Field  
*/  
  
CREATE procedure dbo.spLocal_CreateRateLossEventCVTG  
@Success    int OUTPUT,  
@ErrorMsg    varchar(255) OUTPUT,  
@JumpToTime    varchar(30) OUTPUT,  
@ECId    int,  
@Reserved1    varchar(30),  
@Reserved2    varchar(30),  
@Reserved3    varchar(30),  
@ChangedTagNum   int,  
@ChangedTagPrevValue  varchar(30),  
@ChangedTagNewValue  varchar(30),  
@ChangedTagPrevTime  varchar(30),  
@ChangedTagNewTime  varchar(30),  
@SpeedPrevValue   varchar(30),  /* Input Tag #1: Linespeed */  
@SpeedNewValue   varchar(30),  
@SpeedPrevTime   varchar(30),  
@SpeedNewTime   varchar(30),  
@ReliabilityPrevValue   varchar(30),  /* Input Tag#2: Machine Down */  
@ReliabilityNewValue   varchar(30),  
@ReliabilityPrevTime   varchar(30),  
@ReliabilityNewTime   varchar(30)  
As  
  
Declare @DowntimeEvents Table (  
 Result_Set_Type int Default 5,  
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
 Transaction_Type int Default 1,  -- Transaction Types (   1) Insert/Add;  (   2) Update;  (   3) Delete;   (   4) Complete  
 Start_Time  nvarchar(25) Null,  
 End_Time  nvarchar(25) Null,  
 TEDet_Id   int Null)  
  
Declare @PU_Id   int,   
 @TimeStamp   datetime,  
 @Speed   float,  
 @SpeedPrev   float,  
 @SpeedPrevTimeStamp  datetime,  
 @MachineDown  float,   
 @MachineDownPrev  float,  
 @Fault    varchar(25),  
 @Speed_Target   float,  
 @Speed_Prev_Target  float,  
 @Speed_Target_Flag  varchar(25),  
 @Speed_Target_Name  varchar(25),  
 @Speed_Target_Var_Id  int,  
 @Prod_Id   int,  
 @Prod_PU_Id   int,  
 @Default_Window  int,  
 @Range_Start_Time  datetime,  
 @Threshold   float,  
 @TEDet_Id   int,  
 @TEDet_TimeStamp  datetime,  
 @Start_Time   datetime,   
 @End_Time   datetime,  
 @Source_PU_Id  int,  
 @TEStatus_Id   int,  
 @TEFault_Id   int,  
 @Reason_Level1  int,  
 @Reason_Level2  int,  
 @Reason_Level3  int,  
 @Reason_Level4  int,  
 @Production_Rate  real,  
 @Duration   real,  
 @Next_TEDet_Id  int,  
 @Next_Start_Time  datetime,  
 @ES_Id   int,  
 @ES_TimeStamp  datetime,  
 @ES_Status_Id   int  
  
SET NOCOUNT ON  
  
/************************************************************************************************************************************************************************  
*                                                                                         Initialization and Arguments                                                                                           *  
************************************************************************************************************************************************************************/  
Select  @Success  = -1,  
 @ErrorMsg  = NULL  
--   
-- INSERT INTO STI_TEST (SP_NAME,Parm_name,Value,entry_on) VALUES ('spLocal_CreateRateLossEventCVTG','@ReliabilityNewValue',@ReliabilityNewValue,getdate())  
-- INSERT INTO STI_TEST (SP_NAME,Parm_name,Value,entry_on) VALUES ('spLocal_CreateRateLossEventCVTG','@ReliabilityPrevValue',@ReliabilityPrevValue,getdate())  
-- INSERT INTO STI_TEST (SP_NAME,Parm_name,Value,entry_on) VALUES ('spLocal_CreateRateLossEventCVTG','@SpeedNewValue',@SpeedNewValue,getdate())  
-- INSERT INTO STI_TEST (SP_NAME,Parm_name,Value,entry_on) VALUES ('spLocal_CreateRateLossEventCVTG','@SpeedPrevValue',@SpeedPrevValue,getdate())  
  
Select  @MachineDown = convert(float, rtrim(ltrim(@ReliabilityNewValue))),  
 @MachineDownPrev = convert(float, rtrim(ltrim(@ReliabilityPrevValue))),  
 @Speed   = convert(float, rtrim(ltrim(@SpeedNewValue))),  
 @SpeedPrev   = convert(float, rtrim(ltrim(@SpeedPrevValue)))  
  
 --Debugging  
/* Insert Into Local_Model_Inputs ( EC_Id,  
     ChangedTagNum,  
     ChangedTagPrevValue,   
     ChangedTagNewValue,   
     ChangedTagPrevTime,   
     ChangedTagNewTime,   
     Entry_On,  
     A,  
     B,  
     C,  
     D,  
     E,  
     F,  
     G,  
     H)  
 Values ( @ECId,   
  @ChangedTagNum,   
  @ChangedTagPrevValue,   
  @ChangedTagNewValue,   
  @ChangedTagPrevTime,   
  @ChangedTagNewTime,   
  getdate(),  
  @SpeedPrevValue,  
  @SpeedNewValue,  
  @SpeedPrevTime,  
  @SpeedNewTime,  
  @ReliabilityPrevValue,  
  @ReliabilityNewValue,  
  @ReliabilityPrevTime,  
  @ReliabilityNewTime)  
*/  
-- Check if Linespeed Changed  and if machine is running  
If (@ChangedTagNum = 1 And @SpeedPrev <> @Speed And @MachineDown = 0)  
-- Check if the machine goes down  
Or (@ChangedTagNum = 2 And @MachineDownPrev <> @MachineDown)   
 Begin  
  
 /************************************************************************************************************************************************************************  
 *                                                                                            More Initialization                                                                                                       *  
 ************************************************************************************************************************************************************************/  
 -- Arguments  
 Select @TimeStamp   = convert(datetime, rtrim(ltrim(@ChangedTagNewTime))),  
  @SpeedPrevTimeStamp = convert(datetime, rtrim(ltrim(@SpeedPrevTime)))  
  
 -- Initialization  
 Select   @Threshold   = 0.97,  
     @Speed_Target_Flag  = '%/Target_Speed/%', --Changed from '/Target_Speed/' 04/05/04 BAS  
     @Speed_Target_Name  = '%',  
     @Default_Window   = 365,  
     @TEDet_Id    = Null,  
  @Range_Start_Time   = dateadd(dd, -@Default_Window, @TimeStamp),  
  @ES_Id   = Null    
 -- Configuration  
        Select @PU_Id = PU_Id  
      From [dbo].Event_Configuration  
      Where EC_Id = @ECId  
  
 /************************************************************************************************************************************************************************  
 *                                                                       Get Most Recent Event TimeStamp to Prevent Reruns                                                                  *  
 ************************************************************************************************************************************************************************/  
 Select TOP 1  @TEDet_Id  = TEDet_Id,  
   @TEDet_TimeStamp = coalesce(End_Time, Start_Time)  
 From [dbo].Timed_Event_Details  
 Where PU_Id = @PU_Id And Start_Time > @TimeStamp -- Or End_Time > @TimeStamp) --And User_Id > 50  
 Order By Start_Time Desc  
  
 If @TEDet_Id Is Null  
  Begin  
  /************************************************************************************************************************************************************************  
  *                               Track the downtimes separately as well b/c the historian data for multiple tags is not collated properly                                  *  
  ************************************************************************************************************************************************************************/  
  -- Open the downtime event in a local table and also save the associated fault  
  If @ChangedTagNum = 2  
   Begin  
   If @MachineDown = 1  
    Begin  
    Select @ES_Id = ES_Id  
    From [dbo].Local_Event_Starts  
    Where EC_Id = @ECId   
     And Start_Time = @TimeStamp  
      
    If @ES_Id Is Null  
     Begin  
     Insert Into [dbo].Local_Event_Starts ( EC_Id,  
          Start_Time,  
          Entry_On)  
     Values ( @ECId,  
       @TimeStamp,  
       getdate())  
     End  
    End  
   Else  
    Begin  
    Select  @ES_Id   = ES_Id  
    From [dbo].Local_Event_Starts  
    Where EC_Id = @ECId   
     And Event_Status = 0  
     And Start_Time < @TimeStamp   
     And End_Time Is Null  
  
    If @ES_Id Is Not Null  
     Begin  
     Update [dbo].Local_Event_Starts  
     Set End_Time = @TimeStamp  
     Where ES_Id = @ES_Id  
     End  
    End  
   End  
  
  /************************************************************************************************************************************************************************  
  *                                                                                                         Get Inputs                                                                                                      *  
  ************************************************************************************************************************************************************************/  
  -- Get the current speed target value to test against the current calculated speed   
                     Select @Speed_Target_Var_Id = Var_Id  
                     From [dbo].Variables  
                     Where PU_Id = @PU_Id   
   And Var_Desc Like @Speed_Target_Name   
   And Extended_Info Like @Speed_Target_Flag --Changed from = to Like 04/05/04 BAS  
  
                     -- Get current product running  
                     Select @Prod_Id = Prod_Id  
                     From [dbo].Production_Starts  
                    Where  PU_Id = @PU_Id   
   And Start_Time <= @TimeStamp   
   And (End_Time > @TimeStamp Or End_Time Is Null)  
  
                     -- Get the current speed target   
                     Select @Speed_Target = convert(float, Target) * @Threshold  
                     From [dbo].Var_Specs  
                     Where  Var_id = @Speed_Target_Var_Id  
   And Prod_Id = @Prod_Id   
   And Effective_Date <= @TimeStamp   
   And (Expiration_Date > @TimeStamp Or Expiration_Date Is Null)  
  
                     -- Get the previous speed target  
                     Select @Speed_Prev_Target = convert(float, Target) * @Threshold  
                     From [dbo].Var_Specs  
                     Where  Var_id = @Speed_Target_Var_Id  
   And Prod_Id = @Prod_Id   
   And Effective_Date <= @SpeedPrevTimeStamp  
   And (Expiration_Date > @SpeedPrevTimeStamp Or Expiration_Date Is Null)  
  
  /************************************************************************************************************************************************************************  
  *                                                              Check for transition to Rate Loss and create new downtime event                                                          *  
  ************************************************************************************************************************************************************************/  
  If (@ChangedTagNum = 1 AND @Speed  <  @Speed_Target AND @SpeedPrev > @Speed_Prev_Target AND @MachineDown = 0)  
  OR (@ChangedTagNum = 2 AND @Speed  <  @Speed_Target AND @MachineDown = 0)  
   Begin  
   -- Check for existing rate loss event   
   Select @ES_Id = Null  
   Select @ES_Id = ES_Id  
   From [dbo].Local_Event_Starts  
   Where EC_Id = @ECId  
    AND Start_Time = @TimeStamp  
  
   -- If no event then create one  
   If @ES_Id Is Null  
  
    Begin  
    -- Get next Rate Loss Event  
    Select TOP 1  @Next_TEDet_Id  = TEDet_Id,  
      @Next_Start_Time = Start_Time  
    From [dbo].Timed_Event_Details  
    Where  PU_Id = @PU_Id  
     And Start_Time > @TimeStamp  
  
    Order By Start_Time Asc  
  
    -- If a speed change, check for existing ending downtimes (i.e. PRCs)  
    Select TOP 1 @End_Time = Start_Time  
    From [dbo].Local_Event_Starts  
    Where  EC_Id = @ECId  
     And Event_Status = 0  
     And Start_Time > @TimeStamp  
     And (Start_Time < @Next_Start_Time Or @Next_Start_Time Is Null)  
    Order By Start_Time Asc  
  
    -- Check for open event and close   
    Select @ES_Id = ES_Id  
    From [dbo].Local_Event_Starts  
    Where EC_Id = @ECId  
     AND Start_Time < @TimeStamp  
     AND End_Time IS NULL  
  
    If @ES_Id Is Not Null  
     Begin  
     Update [dbo].Local_Event_Starts  
     Set End_Time = @TimeStamp  
     Where ES_Id = @ES_Id  
     End  
  
    -- Create new event  
    Insert Into [dbo].Local_Event_Starts ( EC_Id,  
         Start_Time,  
         End_Time,  
         Entry_On,  
         Event_Status)  
    Values ( @ECId,  
      @TimeStamp,  
      @End_Time,  
      getdate(),  
      1)  
  
    -- Issue the result set for the new Rate Loss downtime event  
                              Insert Into @DowntimeEvents ( PU_Id,   
        Source_PU_Id,   
        Start_Time,  
        End_Time)  
                              Values( @PU_Id,   
     @PU_Id,   
     convert(nvarchar(25), @TimeStamp, 120),  
     convert(nvarchar(25), @End_Time, 120))  
  
    End  
   End  
  
  /************************************************************************************************************************************************************************  
  *                                      Close Open Rate Loss Event If Speed = (Target Speed * Threshold) Or PRC Fault                                                         *  
  ************************************************************************************************************************************************************************/  
  Else If (@ChangedTagNum = 1 AND @Speed > @Speed_Target AND @SpeedPrev < @Speed_Prev_Target AND @MachineDown = 0)  
  OR (@ChangedTagNum = 2 AND @MachineDown = 1)  
                           Begin  
   Select @ES_Id = Null  
   Select TOP 1 @ES_Id = ES_Id,  
     @Start_Time = Start_Time,  
     @End_Time = End_Time  
   From [dbo].Local_Event_Starts  
   Where EC_Id = @ECId  
    AND Event_Status = 1  
    AND Start_Time < @TimeStamp  
    AND (End_Time >= @TimeStamp Or End_Time Is Null)  
  
   If @ES_Id Is Not Null  
    Begin  
    --Update the end time with this time  
    Update [dbo].Local_Event_Starts  
    Set End_Time = @TimeStamp  
    Where ES_Id = @ES_Id  
  
    -- If open record then just close it  
    If @End_Time Is Null  
     Begin  
     Insert Into @DowntimeEvents ( PU_Id,  
         Transaction_Type,  
         Start_Time,  
         End_Time)  
                             Values ( @PU_Id,  
      4,  
      convert(nvarchar(25), @Start_Time, 120),  
      convert(nvarchar(25), @Timestamp, 120))  
     End  
    -- Else If closed record and the timestamp is different than the end time then modify the record to the new end time  
    Else If @End_Time > @TimeStamp  
     Begin  
     Insert Into @DowntimeEvents ( TEDet_Id,  
         PU_Id,  
         Transaction_Type,  
         Start_Time,  
         End_Time,  
         Source_PU_Id,  
         Status_Id,  
         Fault_Id,  
         Reason1,  
         Reason2,  
         Reason3,  
         Reason4,  
       --  Prod_Rate,  --no in the table anymore
         Duration)  
            Select TEDet_Id,  
      PU_Id,  
      2,  
      convert(nvarchar(25), Start_Time, 120),  
      convert(nvarchar(25), @Timestamp, 120),  
      Source_PU_Id,  
      TEStatus_Id,  
      TEFault_Id,  
      Reason_Level1,  
      Reason_Level2,  
      Reason_Level3,  
      Reason_Level4,  
 --     Production_Rate,  --not in the table anymore
      Duration  
     From [dbo].Timed_Event_Details  
     Where PU_Id = @PU_Id  
      AND Start_Time = @Start_Time  
  
     If @@ROWCOUNT = 0  
      Begin  
      Select @Success = 0  
      Select @ErrorMsg = 'Update failed due to missing matched downtime event at ' + convert(varchar(25), @Start_Time)  
      End  
     End  
    End  
   End  
  
  -- Return result sets      
  If (Select count(Result_Set_Type) From @DowntimeEvents) > 0  
   Begin  
   Select Result_Set_Type,  
    PU_Id,  
    Source_PU_Id,  
    Status_Id,  
    Fault_Id,  
    Reason1,  
    Reason2,  
    Reason3,  
    Reason4,  
    Prod_Rate,  
    Duration,  
    Transaction_Type,  
    Start_Time,  
    End_Time,  
    TEDet_Id  
   From @DowntimeEvents  
   End  
  
  End --Check Event_Id Is Null  
 Else  
  Begin  
  Select @JumpToTime = convert(varchar(30), @TEDet_TimeStamp, 120)  
  
  End  
  
 End --Check Tag Change  
  
-- Clean Up   
-- Drop Table @DowntimeEvents  
  
SET NOCOUNT OFF  
  
