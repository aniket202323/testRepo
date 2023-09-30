  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-01  
Version  : 1.0.4  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_GeneCvtgSwitchPositions  
Author:   Matthew Wells (MSI)  
Date Created:  07/08/02  
  
Description:  
=========  
The procedure unloads a roll out of the running position if a specific reason  
has been selected in the reason tree and reloads it into the staged position.  
  
Change Date Who What  
=========== ==== =====  
07/08/02 MKW Created procedure.  
07/31/03 MKW Increased varchar size to 100  
08/08/03 MKW Fixed issue with Timestamps being the same  
02/02/04 MKW Fixed truncated PU_Desc and End_Time  
   Changed temp tables to table variables  
*/  
CREATE PROCEDURE dbo.spLocal_GeneCvtgSwitchPositions  
@Output_Value   varchar(25) OUTPUT,  
@TEDet_Id   int,  
@Roll_PU_Id   int,  
@Internal_Location  varchar(100),  
@Internal_Input_Name  varchar(100),  
@External_Location  varchar(100),  
@External_Input_Name  varchar(100),  
@PRC_Reason_Level1_Name  varchar(100),  
@PRC_Reason_Level2_Name  varchar(100)  
AS  
  
SET NOCOUNT ON  
  
/*  
SELECT @Var_Id   = 0,  
 @TEDet_Id  = 59966,  
 @Roll_PU_Id  = 69,  
 @Internal_Location = 'UT01 Internal UWS',  
 @External_Location = 'UT01 External UWS',  
 @Internal_Input_Name = 'Internal Backstand',  
 @External_Input_Name = 'External Backstand',  
 @PRC_Reason_Level1_Name = 'Parent Roll Change',  
 @PRC_Reason_Level2_Name = 'Both PRC Only'  
*/  
  
DECLARE @InputEvents TABLE (  
 Result_Set_Type  int DEFAULT 12,  
 Pre_Update  int DEFAULT 1,  
 User_Id   int DEFAULT 26,  
 Transaction_Type  int DEFAULT 1,   
 Transaction_Number int DEFAULT 0,  -- Must be 0  
 TimeStamp   varchar(25) NULL,   
 Entry_On   datetime NULL,   
 Comment_Id   int NULL,   
 PEI_Id    int NULL,   
 PEIP_Id   int NULL,   
 Event_Id   int NULL,   
 Dimension_X  float NULL,  
 Dimension_Y  float NULL,  
 Dimension_Z  float NULL,  
 Dimension_A  float NULL,  
 Unloaded   int NULL)  
  
DECLARE @PEI_Id    int,  
 @InputEventId   int,  
 @EventId   int,  
 @PU_Id    int,  
 @EventNum   varchar(25),  
 @Status    int,  
 @Source    int,  
 @Now    datetime,  
 @TimeStamp   datetime,  
 @Reason_Level1_Id  int,  
 @Reason_Level2_Id  int,  
 @Reason_Level1_Name  varchar(100),  
 @Reason_Level2_Name  varchar(100),  
 @Internal_PEI_Id  int,  
 @External_PEI_Id  int,  
 @Reason_Level   int,  
 @Start_Time   datetime,  
 @End_Time   datetime,  
 @Range_Start   datetime,  
 @DEFAULT_Window   int,  
 @Complete_History_Id  int,  
 @Staged_Position  int,  
 @Staged_Event_Id  int,  
 @Running_Position  int,  
 @Running_Event_Id  int,  
 @Running_TimeStamp  datetime,  
 @Location   int,  
 @PU_Desc   varchar(50),  
 @Consumed_Status_Id  int,  
 @User_id   int  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
/* Initialization */  
SELECT  @InputEventId   = NULL,  
 @Output_Value   = '0',  
 @DEFAULT_Window  = 1,  
 @Range_Start   = NULL,  
 @Running_Position = 1,  
 @Staged_Position = 2,  
 @Consumed_Status_Id = 8,  
 @TimeStamp  = getdate()  
  
-- Remove the milliseconds from the timestamp  
SELECT @TimeStamp = dateadd(ms, -datepart(ms, @TimeStamp), @TimeStamp)  
  
-- Clean Arguments  
SELECT  @Reason_Level1_Name = ltrim(rtrim(@Reason_Level1_Name)),  
 @Reason_Level2_Name = ltrim(rtrim(@Reason_Level2_Name))  
  
-- Get reason1 and check for parent roll change  
SELECT @Start_Time   = Start_Time,  
 @End_Time   = End_Time,  
 @Location   = Source_PU_Id,  
 @Reason_Level1_Id = Reason_Level1,  
 @Reason_Level2_Id = Reason_Level2  
FROM [dbo].Timed_Event_Details  
WHERE TEDet_Id = @TEDet_Id  
  
IF @Reason_Level1_Id > 0  
     BEGIN  
     -- Get reason names  
  
     SELECT @Reason_Level1_Name = Event_Reason_Name  
     FROM [dbo].Event_Reasons  
     WHERE Event_Reason_Id = @Reason_Level1_Id  
  
     SELECT @Reason_Level2_Name = Event_Reason_Name  
     FROM [dbo].Event_Reasons  
     WHERE Event_Reason_Id = @Reason_Level2_Id  
  
     IF @Reason_Level1_Name Like @PRC_Reason_Level1_Name  
          BEGIN  
          SELECT @PU_Desc = PU_Desc  
          FROM [dbo].Prod_Units  
          WHERE PU_Id = @Location  
  
          /************************************************************************************************************************************************************************  
          *                                                            Process Internal Backstand                                                           *  
          ************************************************************************************************************************************************************************/  
          IF @PU_Desc = @Internal_Location OR @Reason_Level2_Name LIKE @PRC_Reason_Level2_Name  
               BEGIN  
               -- Get the inputs for the attached unit   
               SELECT @Internal_PEI_Id = PEI_Id  
               FROM [dbo].PrdExec_Inputs  
               WHERE PU_Id = @Roll_PU_Id  
   AND Input_Name = @Internal_Input_Name  
  
               -- Check to see IF an event is actually loaded   
               SELECT @Running_Event_Id = Event_Id,  
   @Running_TimeStamp = TimeStamp  
               FROM [dbo].PrdExec_Input_Event  
               WHERE PEI_Id = @Internal_PEI_Id  
   AND PEIP_Id = @Running_Position  
  
               -- IF event was loaded into the running position before the start of the downtime then unload it and reload into the staged position   
               IF @Running_Event_Id IS NOT NULL AND @Running_TimeStamp < @Start_Time  
                    BEGIN  
                    -- Unload the running position  
                    INSERT INTO @InputEvents( Transaction_Type,  
      TimeStamp,  
      Entry_On,  
      PEI_Id,  
      PEIP_Id,  
      Event_Id,  
      Unloaded,User_Id)   
                    VALUES ( 3,  
    convert(varchar(25), @End_Time, 120),  
    convert(varchar(25), @TimeStamp, 120),  
    @Internal_PEI_Id,  
    @Running_Position,  
    @Running_Event_Id,  
    1,@User_Id)  
  
                    -- Check for an event in the staged position  
                    SELECT @Staged_Event_Id = Event_Id  
                    FROM [dbo].PrdExec_Input_Event  
                    WHERE PEI_Id = @Internal_PEI_Id AND PEIP_Id = @Staged_Position  
  
                    IF @Staged_Event_Id IS NOT NULL  
                         BEGIN  
                         -- Unload the staged position  
                         INSERT INTO @InputEvents( Transaction_Type,  
       TimeStamp,  
       Entry_On,  
       PEI_Id,  
       PEIP_Id,  
       Event_Id,  
       Unloaded,User_Id)   
                         VALUES ( 3,  
     convert(varchar(25), @End_Time, 120),  
     convert(varchar(25), @TimeStamp, 120),  
     @Internal_PEI_Id,  
     @Staged_Position,  
     @Staged_Event_Id,  
     1,@User_Id)  
  
                         -- Load the running position  
                         INSERT INTO @InputEvents( Transaction_Type,  
       TimeStamp,  
       Entry_On,  
       PEI_Id,  
       PEIP_Id,  
       Event_Id,  
       Unloaded,User_Id)   
                         VALUES ( 2,  
     convert(varchar(25), @End_Time, 120),  
     convert(varchar(25), @TimeStamp, 120),  
     @Internal_PEI_Id,  
     @Running_Position,  
     @Staged_Event_Id,  
     0,@User_Id)  
                         END  
  
                    -- Reload the running event into the staged position  
                    INSERT INTO @InputEvents( Transaction_Type,  
      TimeStamp,  
      Entry_On,  
      PEI_Id,  
      PEIP_Id,  
      Event_Id,  
      Unloaded,User_Id)   
                    VALUES ( 2,  
    convert(varchar(25), @End_Time, 120),  
    convert(varchar(25), @TimeStamp, 120),  
    @Internal_PEI_Id,  
    @Staged_Position,  
    @Running_Event_Id,  
    0,@User_Id)  
  
                    END  
  
               -- Increment the timestamp in case you need to process the external backstand as well  
               SELECT @TimeStamp = dateadd(s, 1, @TimeStamp)  
               END  
  
          /************************************************************************************************************************************************************************  
          *                                                            Process External Backstand                                                           *  
          ************************************************************************************************************************************************************************/  
          -- Get the inputs for the attached unit   
          IF @PU_Desc = @External_Location Or @Reason_Level2_Name Like @PRC_Reason_Level2_Name  
               BEGIN  
               SELECT @External_PEI_Id = PEI_Id  
               FROM [dbo].PrdExec_Inputs  
               WHERE PU_Id = @Roll_PU_Id And Input_Name = @External_Input_Name  
  
               -- Check to see IF an event is actually loaded   
               SELECT @Running_Event_Id = Event_Id,  
   @Running_TimeStamp = TimeStamp  
               FROM [dbo].PrdExec_Input_Event  
               WHERE PEI_Id = @External_PEI_Id And PEIP_Id = @Running_Position  
  
               -- IF event was loaded into the running position before the start of the downtime then complete it   
               IF @Running_Event_Id Is Not NULL And @Running_TimeStamp < @Start_Time  
                    BEGIN  
                    -- Complete the roll   
                    INSERT INTO @InputEvents( Transaction_Type,  
      TimeStamp,  
      Entry_On,  
      PEI_Id,  
      PEIP_Id,  
      Event_Id,  
      Unloaded,User_Id)   
                    VALUES ( 3,  
    convert(varchar(25), @End_Time, 120),  
    convert(varchar(25), @TimeStamp, 120),  
    @External_PEI_Id,  
    @Running_Position,  
    @Running_Event_Id,  
    1,@User_Id)  
        
                    -- Check for an event in the staged position  
                    SELECT @Staged_Event_Id = Event_Id  
                    FROM [dbo].PrdExec_Input_Event  
                    WHERE PEI_Id = @External_PEI_Id And PEIP_Id = @Staged_Position  
  
                    IF @Staged_Event_Id Is Not NULL  
                         BEGIN  
                         -- Unload the staged position  
                         INSERT INTO @InputEvents( Transaction_Type,  
       TimeStamp,  
       Entry_On,  
       PEI_Id,  
       PEIP_Id,  
       Event_Id,  
       Unloaded,User_Id)   
                         VALUES ( 3,  
     convert(varchar(25), @End_Time, 120),  
     convert(varchar(25), @TimeStamp, 120),  
     @External_PEI_Id,  
     @Staged_Position,  
     @Staged_Event_Id,  
     1,@User_Id)  
  
                         -- Load the running position  
                         INSERT INTO @InputEvents( Transaction_Type,  
       TimeStamp,  
       Entry_On,  
       PEI_Id,  
       PEIP_Id,  
       Event_Id,  
       Unloaded,User_Id)   
                         VALUES ( 2,  
     convert(varchar(25), @End_Time, 120),  
     convert(varchar(25), @TimeStamp, 120),  
     @External_PEI_Id,  
     @Running_Position,  
     @Staged_Event_Id,  
     0,@User_Id)  
                         END  
  
                    -- Reload the running event into the staged position  
                    INSERT INTO @InputEvents( Transaction_Type,  
      TimeStamp,  
      Entry_On,  
      PEI_Id,  
      PEIP_Id,  
      Event_Id,  
      Unloaded,User_Id)   
                    VALUES ( 2,  
    convert(varchar(25), @End_Time, 120),  
    convert(varchar(25), @TimeStamp, 120),  
    @External_PEI_Id,  
    @Staged_Position,  
    @Running_Event_Id,  
    0,@User_Id)  
                    END  
               END  
  
          /************************************************************************************************************************************************************************  
          *                                                            Output Results                                                          *  
          ************************************************************************************************************************************************************************/  
          IF (SELECT Count(Transaction_Type) FROM @InputEvents) > 0  
               BEGIN  
               SELECT Result_Set_Type,  
      Pre_Update,  
      User_Id,  
      Transaction_Type,  
      Transaction_Number,  
      TimeStamp,  
      Entry_On,  
      Comment_Id,  
      PEI_Id,  
      PEIP_Id,  
      Event_Id,  
      Dimension_X,  
      Dimension_Y,  
      Dimension_Z,  
      Dimension_A,  
      Unloaded  
               FROM @InputEvents  
               END  
          END  
  
          -- Note reason selection for next time  
          SELECT @Output_Value = '1'  
     END  
  
SET NOCOUNT OFF  
  
