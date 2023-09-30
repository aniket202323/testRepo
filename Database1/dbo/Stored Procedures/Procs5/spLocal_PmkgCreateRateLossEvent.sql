 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-04  
Version  : 1.0.7  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_PmkgCreateRateLossEvent  
Author:   Matthew Wells (MSI)  
Date Created:  01/14/03  
  
Description:  
=========  
This procedure monitors line speed and creates/UPDATEs Production and Downtime events when the value of the signal changes. The procedure gets   
the Target speed value and uses a deadband to determine whether the speed has exceeded the speed target.  The procedure also checks for   
downtime and if found will END any open rate loss events and prevent new ones FROM being created if currently in downtime.  
  
For the Target Speed value a variable must be created with the specified @Speed_Target_Flag value in its Extended_Info field.  The actual target speed  
value must be entered as that variables' Target value in the specifications.  Similarly, for the downtime a variable must be created under the downtime unit  
with the @DT_PU_Flag value in its Extended_Info field.  The procedure will use this to get the unit and search for Downtime events under that unit.  
  
Due to the potential high frequency of changes, this stored procedure MUST use direct UPDATEs to the database for the events.  Because downtime events  
don't support post-UPDATE messages, we have to use a local table (Local_Event_Starts) to track open/closed rate loss events.  
  
Change Date Who What  
=========== ==== =====  
01/14/03 MKW Round 2: Copied FROM Cvtg  
01/17/03 MKW Modifed so that the Event UPDATE is done directly.  
05/02/03 MKW Copied FROM Cvtg again.  This time using a local table.  
05/05/03 MKW Added configurable deadband  
11/06/03 DWFH Replaced temp tables with variable tables.  
04/07/04 MKW Updated for GlblDesc  
*/  
  
CREATE procedure dbo.spLocal_PmkgCreateRateLossEvent  
@Success    int OUTPUT,  
@ErrorMsg    varchar(255) OUTPUT,  
@JumpToTime    varchar(30) OUTPUT,  
@ECId     int,  
@Reserved1    varchar(30),  
@Reserved2    varchar(30),  
@Reserved3    varchar(30),  
@ChangedTagNum   int,  
@ChangedTagPrevValue  varchar(30),  
@ChangedTagNewValue  varchar(30),  
@ChangedTagPrevTime  varchar(30),  
@ChangedTagNewTime  varchar(30),  
@SpeedPrevValue   varchar(30),--Linespeed  
@SpeedNewValue   varchar(30),  
@SpeedPrevTime   varchar(30),  
@SpeedNewTime   varchar(30),  
@ReliabilityPrevValue   varchar(30),--Machine Down  
@ReliabilityNewValue  varchar(30),  
@ReliabilityPrevTime   varchar(30),  
@ReliabilityNewTime   varchar(30)  
As  
SET NOCOUNT ON  
  
DECLARE @DowntimeEvents TABLE (  
 Result_SET_Type int Default 5,  
 PU_Id   int NULL,  
 Source_PU_Id  int NULL,  
 Status_Id  int NULL,  
 Fault_Id   int NULL,  
 Reason1  int NULL,  
 Reason2  int NULL,  
 Reason3  int NULL,  
 Reason4  int NULL,  
 Prod_Rate  int NULL,  
 Duration  float NULL,  
 Transaction_Type int Default 1,  -- Transaction Types (   1) Insert/Add;  (   2) UPDATE;  (   3) Delete;   (   4) Complete  
 Start_Time  nvarchar(25) NULL,  
 END_Time  nvarchar(25) NULL,  
 TEDet_Id   int NULL,  
 PostDB  int Null,  
 TransNum  varchar(50) Null,  
 Action1  int Null,  
 Action2  int Null,  
 Action3  int Null,  
 Action4  int Null,  
 ActionCommentId int Null,  
 ResearchCommentId int Null,  
 ResearchStatusId int Null,  
 ResearchOpenDate datetime Null,  
 ResearchCloseDate datetime Null,  
 CommentId   int Null,  
 TargetProdRate  varchar(50) Null,  
 DimensionX1   float Null,  
 DimensionX2   float Null,  
 DimensionY1   float Null,  
 DimensionY2   float Null,  
 DimensionZ1   float Null,  
 DimensionZ2   float Null,  
 ResearchUserId  int Null,  
 RsnTreeDataId  int Null)  
  
DECLARE @PU_Id   int,   
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
 @Deadband   float,  
 @TEDet_Id   int,  
 @TEDet_TimeStamp  datetime,  
 @Start_Time   datetime,   
 @END_Time   datetime,  
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
 @ES_Status_Id   int,  
 @Extended_Info  varchar(255),  
 @Deadband_Flag  varchar(25),  
 @Flag_Start   int,  
 @Flag_Value   varchar(255),  
 @AppVersion   varchar(30)  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
/************************************************************************************************************************************************************************  
*                                                                                         Initialization and Arguments                                                                                           *  
************************************************************************************************************************************************************************/  
SELECT  @Success  = -1,  
 @ErrorMsg  = NULL  
  
SELECT  @MachineDown = convert(float, rtrim(ltrim(@ReliabilityNewValue))),  
 @MachineDownPrev = convert(float, rtrim(ltrim(@ReliabilityPrevValue))),  
 @Speed   = convert(float, rtrim(ltrim(@SpeedNewValue))),  
 @SpeedPrev   = convert(float, rtrim(ltrim(@SpeedPrevValue)))  
  
/* --Debugging  
 INSERT INTO Local_Model_Inputs ( EC_Id,  
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
 VALUES ( @ECId,   
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
IF (@ChangedTagNum = 1 AND @SpeedPrev <> @Speed AND @MachineDown = 0)  
-- Check if the machine goes down  
OR (@ChangedTagNum = 2 AND @MachineDownPrev <> @MachineDown)   
 BEGIN  
  
 /************************************************************************************************************************************************************************  
 *                                                                                            More Initialization                                                                                                       *  
 ************************************************************************************************************************************************************************/  
 -- Arguments  
 SELECT @TimeStamp   = convert(datetime, rtrim(ltrim(@ChangedTagNewTime))),  
  @SpeedPrevTimeStamp = convert(datetime, rtrim(ltrim(@SpeedPrevTime)))  
  
 -- Initialization  
 SELECT   @Deadband   = 25,  
  @Deadband_Flag  = 'DEADBAND=',  
     @Speed_Target_Flag  = '%/Target_Speed/%',  
     @Speed_Target_Name  = '%',  
     @Default_Window   = 365,  
     @TEDet_Id    = NULL,  
  @Range_Start_Time   = dateadd(dd, -@Default_Window, @TimeStamp)  
  
 -- Configuration  
        SELECT @PU_Id = PU_Id  
      FROM [dbo].Event_Configuration  
      WHERE EC_Id = @ECId  
  
          /************************************************************************************************************************************************************************  
          *                                                                                                      Get the Flags                                                                                                    *  
          ************************************************************************************************************************************************************************/  
          -- Get Extended info field AND parse out the schedule PU_Id  
          SELECT @Extended_Info = upper(replace(Extended_Info, ' ', ''))+';'  
          FROM [dbo].Prod_Units  
          WHERE PU_Id = @PU_Id  
  
          SELECT @Flag_Start = charindex(@Deadband_Flag, @Extended_Info)  
          IF @Flag_Start > 0  
               BEGIN  
               SELECT @Flag_Start = @Flag_Start+len(@Deadband_Flag)  
               SELECT @Flag_Value = substring(@Extended_Info, @Flag_Start, charindex(';', @Extended_Info, @Flag_Start) - @Flag_Start )  
  
               IF isnumeric(@Flag_Value) = 1  
                    BEGIN  
                    SELECT @Deadband = convert(float, @Flag_Value)  
                    END  
               END  
  
 /************************************************************************************************************************************************************************  
 *                                                                       Get Most Recent Event TimeStamp to Prevent Reruns                                                                  *  
 ************************************************************************************************************************************************************************/  
 SELECT TOP 1  @TEDet_Id  = TEDet_Id,  
   @TEDet_TimeStamp = coalesce(END_Time, Start_Time)  
 FROM [dbo].Timed_Event_Details  
 WHERE PU_Id = @PU_Id   
  AND (Start_Time > @TimeStamp OR END_Time > @TimeStamp)   
  AND User_Id > 50  
 ORDER BY Start_Time Desc  
  
 IF @TEDet_Id IS NULL  
  BEGIN  
  /************************************************************************************************************************************************************************  
  *                               Track the downtimes separately as well b/c the historian data for multiple tags is not collated properly                                  *  
  ************************************************************************************************************************************************************************/  
  -- Open the downtime event in a local table and also save the associated fault  
  IF @ChangedTagNum = 2  
   BEGIN  
   IF @MachineDown = 1  
    BEGIN  
    SELECT @ES_Id = ES_Id  
    FROM [dbo].Local_Event_Starts  
    WHERE EC_Id = @ECId   
     AND Start_Time = @TimeStamp  
      
    IF @ES_Id IS NULL  
     BEGIN  
     INSERT INTO [dbo].Local_Event_Starts ( EC_Id,  
          Start_Time,  
          Entry_On)  
     VALUES ( @ECId,  
       @TimeStamp,  
       getdate())  
     END  
    END  
   ELSE  
    BEGIN  
    SELECT  @ES_Id   = ES_Id  
    FROM [dbo].Local_Event_Starts  
    WHERE EC_Id = @ECId   
     AND Event_Status = 0  
     AND Start_Time < @TimeStamp   
     AND END_Time IS NULL  
  
    IF @ES_Id IS NOT NULL  
     BEGIN  
     UPDATE [dbo].Local_Event_Starts  
     SET END_Time = @TimeStamp  
     WHERE ES_Id = @ES_Id  
     END  
    END  
   END  
  
  /************************************************************************************************************************************************************************  
  *                                                                                                         Get Inputs                                                                                                      *  
  ************************************************************************************************************************************************************************/  
  -- Get the current speed target value to test against the current calculated speed   
  SELECT @Speed_Target_Var_Id = Var_Id  
  FROM [dbo].Variables  
  WHERE PU_Id = @PU_Id   
   AND Var_Desc LIKE @Speed_Target_Name   
   AND Extended_Info LIKE @Speed_Target_Flag  
  
  -- Get current product running  
  SELECT @Prod_Id = Prod_Id  
  FROM [dbo].Production_Starts  
  WHERE  PU_Id = @PU_Id   
   AND Start_Time <= @TimeStamp   
   AND (END_Time > @TimeStamp OR END_Time IS NULL)  
  
  -- Get the current speed target   
  SELECT @Speed_Target = convert(float, Target) - @Deadband  
  FROM [dbo].Var_Specs  
  WHERE  Var_id = @Speed_Target_Var_Id  
   AND Prod_Id = @Prod_Id   
   AND Effective_Date <= @TimeStamp   
   AND (Expiration_Date > @TimeStamp OR Expiration_Date IS NULL)  
  
  -- Get the previous speed target  
  SELECT @Speed_Prev_Target = convert(float, Target) - @Deadband  
  FROM [dbo].Var_Specs  
  WHERE  Var_id = @Speed_Target_Var_Id  
   AND Prod_Id = @Prod_Id  
   AND Effective_Date <= @SpeedPrevTimeStamp  
   AND (Expiration_Date > @SpeedPrevTimeStamp Or Expiration_Date IS NULL)  
  
  /************************************************************************************************************************************************************************  
  *                                                              Check for transition to Rate Loss and create new downtime event                                                          *  
  ************************************************************************************************************************************************************************/  
  IF (@ChangedTagNum = 1 AND @Speed  <  @Speed_Target AND @SpeedPrev > @Speed_Prev_Target AND @MachineDown = 0)  
  OR (@ChangedTagNum = 2 AND @Speed  <  @Speed_Target AND @MachineDown = 0)  
   BEGIN  
   SELECT @ES_Id = NULL  
   SELECT @ES_Id = ES_Id  
   FROM [dbo].Local_Event_Starts  
   WHERE EC_Id = @ECId  
    AND Start_Time = @TimeStamp  
  
   -- If no event then create one  
   IF @ES_Id IS NULL  
    BEGIN  
    -- Get next Rate Loss Event  
    SELECT TOP 1  @Next_TEDet_Id  = TEDet_Id,  
      @Next_Start_Time = Start_Time  
    FROM [dbo].Timed_Event_Details  
    WHERE  PU_Id = @PU_Id  
     And Start_Time > @TimeStamp  
    ORDER BY Start_Time ASC  
  
    -- If a speed change, check for existing ENDing downtimes (i.e. PRCs)  
    SELECT TOP 1 @END_Time = Start_Time  
    FROM [dbo].Local_Event_Starts  
    WHERE  EC_Id = @ECId  
     And Event_Status = 0  
     And Start_Time > @TimeStamp  
     And (Start_Time < @Next_Start_Time Or @Next_Start_Time Is NULL)  
    ORDER BY Start_Time ASC  
  
    -- Check for open event and close   
    SELECT @ES_Id = ES_Id  
    FROM [dbo].Local_Event_Starts  
    WHERE EC_Id = @ECId  
     AND Start_Time < @TimeStamp  
     AND END_Time IS NULL  
  
    If @ES_Id Is Not NULL  
     BEGIN  
     UPDATE [dbo].Local_Event_Starts  
     SET END_Time = @TimeStamp  
     WHERE ES_Id = @ES_Id  
     END  
  
    -- Create new event  
    INSERT INTO [dbo].Local_Event_Starts ( EC_Id,  
         Start_Time,  
         END_Time,  
         Entry_On,  
         Event_Status)  
    VALUES ( @ECId,  
      @TimeStamp,  
      @END_Time,  
      getdate(),  
      1)  
  
    -- Issue the result SET for the new Rate Loss downtime event  
    INSERT INTO @DowntimeEvents ( PU_Id,   
        Source_PU_Id,   
        Start_Time,  
        END_Time)  
    VALUES( @PU_Id,   
     @PU_Id,   
     convert(nvarchar(25), @TimeStamp, 120),  
     convert(nvarchar(25), @END_Time, 120))  
  
    END  
   END  
  
  /************************************************************************************************************************************************************************  
  *                                      Close Open Rate Loss Event If Speed = (Target Speed * Threshold) Or PRC Fault                                                         *  
  ************************************************************************************************************************************************************************/  
  ELSE If (@ChangedTagNum = 1 AND @Speed > @Speed_Target AND @SpeedPrev < @Speed_Prev_Target AND @MachineDown = 0)  
  OR (@ChangedTagNum = 2 AND @MachineDown = 1)  
   BEGIN  
   SELECT @ES_Id = NULL  
   SELECT TOP 1 @ES_Id = ES_Id,  
     @Start_Time = Start_Time,  
     @END_Time = END_Time  
   FROM [dbo].Local_Event_Starts  
   WHERE EC_Id = @ECId  
    AND Event_Status = 1  
    AND Start_Time < @TimeStamp  
    AND (END_Time >= @TimeStamp Or END_Time Is NULL)  
  
   If @ES_Id Is Not NULL  
    BEGIN  
    --UPDATE the END time with this time  
    UPDATE [dbo].Local_Event_Starts  
    SET END_Time = @TimeStamp  
    WHERE ES_Id = @ES_Id  
  
    -- If open record then just close it  
    IF @END_Time IS NULL  
     BEGIN  
     INSERT INTO @DowntimeEvents ( PU_Id,  
         Transaction_Type,  
         Start_Time,  
         END_Time)  
     VALUES ( @PU_Id,  
      4,  
      convert(nvarchar(25), @Start_Time, 120),  
      convert(nvarchar(25), @Timestamp, 120))  
     END  
    -- ELSE If closed record and the timestamp is different than the END time then modify the record to the new END time  
    ELSE IF @END_Time > @TimeStamp  
     BEGIN  
     INSERT INTO @DowntimeEvents ( TEDet_Id,  
         PU_Id,  
         Transaction_Type,  
         Start_Time,  
         END_Time,  
         Source_PU_Id,  
         Status_Id,  
         Fault_Id,  
         Reason1,  
         Reason2,  
         Reason3,  
         Reason4,  
         --Prod_Rate,  
         Duration)  
     SELECT TEDet_Id,  
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
      --Production_Rate,  
      Duration  
     FROM [dbo].Timed_Event_Details  
     WHERE PU_Id = @PU_Id  
      AND Start_Time = @Start_Time  
  
     If @@ROWCOUNT = 0  
      BEGIN  
      SELECT @Success = 0  
      SELECT @ErrorMsg = 'UPDATE failed due to missing matched downtime event at ' + convert(varchar(25), @Start_Time)  
      END  
     END  
    END  
   END  
  
  
  -- Return result SETs      
  If (SELECT count(Result_SET_Type) FROM @DowntimeEvents) > 0  
   BEGIN  
      
    IF @AppVersion LIKE '4%'  
     BEGIN  
      SELECT Result_SET_Type,  
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
        TEDET_Id,  
        PostDB,  
        TransNum,  
        Action1,  
        Action2,  
        Action3,  
        Action4,  
        ActionCommentId,  
        ResearchCommentId,  
        ResearchStatusId,  
        ResearchOpenDate,  
        ResearchCloseDate,  
        CommentId,  
        TargetProdRate,  
        DimensionX1,  
        DimensionX2,  
        DimensionY1,  
        DimensionY2,  
        DimensionZ1,  
        DimensionZ2,  
        ResearchUserId,  
        RsnTreeDataId  
      FROM @DowntimeEvents  
     END  
    ELSE  
     BEGIN  
      SELECT Result_SET_Type,  
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
        END_Time,  
        TEDet_Id  
      FROM @DowntimeEvents  
     END  
     
   END  
  
  END --Check Event_Id Is NULL  
 ELSE  
  BEGIN  
  SELECT @JumpToTime = convert(varchar(30), @TEDet_TimeStamp, 120)  
  END  
  
 END --Check Tag Change  
  
SET NOCOUNT OFF  
  
