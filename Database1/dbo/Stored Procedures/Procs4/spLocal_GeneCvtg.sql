   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry   
Date   : 2005-10-31  
Version  : 1.0.17  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo]. template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_GeneCvtg  
Author:   Matthew Wells (MSI)  
Date Created:  11/02/01  
  
Description:  
=========  
When a parent roll is loaded in the inputs on the Genealogy display, this procedure fires AND creates a 'consumed roll' event on the associated production unit.    
It then attaches that 'consumed roll' to the original through genealogy.  As the roll is either staged, put in running, completed, unloaded or rejected this procedure  
updates the status of the 'consumed roll' accordingly.  
  
Change Date Who What  
=========== ==== =====  
11/02/01 MKW Created procedure.  
01/29/02 MKW Added check for unloaded events in the Event completion section - Whenever an event is unloaded it is followed by a 'Completion'   
   event so need to check for unloaded events b/c don't want to process the same way as completed events.  
01/29/02 MKW Added Event_Num to the Event_Details result set b/c now required to process the record.  
07/19/02 MKW Added check for @Last_Event_Id being NULL for first time startup AND added hot insert of event components to make sure link there in time for calculations.  
01/14/03 MKW Added assignment of 'Received' status upon receipt into Cvtg  
02/14/03 MKW Event completion by result sets (ie. by the PRC downtime calculation) doesn't automatically issue a 'Consumed' status change so added it in here.  
05/05/03 MKW Modified so that when status is "Partially-Run" or "Inventory", it resets the source event status to what it was before being "Received"  
11/06/03 DWFH Replaced tempdb tables with local variable tables.  
01/30/04 MKW Fixed problem with events have the same timestamp  
02/04/04 MKW Fixed double scanning of rolls into Staged position  
02/18/04 MKW Fixed issue with having additional children in different units by adding check for PU_Id  
04/30/04 MKW Added complete functionality to Parent Roll Details display  
05/06/04 MKW Fixed issue with staged rolls not moving to running postion when complete from Parent Roll Details display.  
06/16/04 MKW Fixed another issue with double scanned rolls (it will reset to the first scanned roll)  
   Made the event EntryOn timestamp = InputTimeStamp so the GeneCvtgRunTimeStamp and GeneCvtgCompleteTimeStamp  
   calcs pull the right value out of the event history  
   Hot inserted all the updates so the timing was correct  
   Added code so that whenever a new roll is loaded, any existing rolls that have a status of   
   'Staged' or 'Running' will be respectively updated to 'Inventory' and 'Partially-Run'  
06/30/04 MKW Added FL1 functionality so can use same sp and not have to copy changes to multiple versions  
11/24/04 MKW Fixed issue with completion of source events erasing the applied product  
12/23/04 MKW Fixed issue with resetting of parent status when unloading rolls  
02/09/09 Rev1.0.18 Vince King Added code to execute spLocal_CreateUpdateUDE for UWS Running UDE.  
  
*/  
  
CREATE procedure dbo.spLocal_GeneCvtg  
@Success int OUTPUT,  
@ErrMsg  varchar(255) OUTPUT,  
@ECId  int,  
@TableName varchar(255),  
@Id  int   
AS  
  
--INSERT INTO Local_Genealogy_Input_Test (ECId, TABLEName, Id, TimeStamp)  
--VALUES (@ECId, @TableName, @Id, getdate())  
SET NOCOUNT ON  
  
DECLARE @PEIId    int,  
 @PEIPId    int,  
 @PLId    int,  
 @UnLoaded   int,  
 @Event_Id   int,  
 @SourceEventId   int,  
 @Staged_Event_Id  int,  
 @Component_Id   int,  
 @InputTimeStamp   datetime,  
 @TimeStamp   datetime,  
 @EntryOn   datetime,  
 @User_Id   int,  
 @Event_Num   varchar(25),  
 @Status_Desc   varchar(25),  
 @MaxId    int,  
 @InputPUId   int,  
 @DetailsPUId   int,   
 @EventPattern   varchar(25),  
 @Count    int,  
 @Event_Status   int,  
 @SourceEventStatus  int,  
 @Last_Staged_History_Id  int,  
 @Last_Staged_Event_Id  int,  
 @Last_History_Id  int,  
 @Last_Event_Id   int,  
 @Last_Unloaded   int,  
 @Dimension_X   float,  
 @Dimension_Y   float,  
 @Dimension_Z   float,  
 @Dimension_A   float,  
 @Reject_Status_Desc  varchar(25),  
 @Reject_Status_Id  int,  
 @Received_Status_Desc  varchar(25),  
 @Received_Status_Id  int,  
 @Complete_Status_Id  int,  
 @Partial_Run_Status_Id  int,  
 @Inventory_Status_Id  int,  
 @Consumed_Status_Id  int,  
 @Was_Unloaded   int,  
 @InputVarDesc   varchar(50),  
 @InputVarId   int,  
 @InputName   varchar(50),  
 @InputEventId   int,  
 @AppliedProductId  int,  
 @AppVersion   varchar(30),  
 @EventSubTypeId INTEGER       -- 2009-02-09 Vince King Rev1.0.18 Added.  
  
DECLARE @Events TABLE (  
 Result_Set_Type  int DEFAULT 1,  
 Id   int IDENTITY,  
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
  
DECLARE @EventInputs TABLE (  
 Result_Set_Type  int DEFAULT 12,  
 Pre_Update  int DEFAULT 1,  
 User_Id   int DEFAULT 6,  
 Transaction_Type  int DEFAULT 1,   -- 1 = ; 2 = ; 3 = Unload  
 Transaction_Number int DEFAULT 0,  -- Must be 0  
 TimeStamp   varchar(30) NULL,   
 EntryOn   varchar(30) NULL,   
 Comment_Id   int NULL,   
 PEI_Id    int NULL,   
 PEIP_Id   int NULL,   
 Event_Id   int NULL,   
 Dimension_X  float NULL,  
 Dimension_Y  float NULL,  
 Dimension_Z  float NULL,  
 Dimension_A  float NULL,  
 Unloaded   int NULL)  
  
/* Initialization */  
SELECT  @ErrMsg    = @TableName,  
 @Success    = 0,  
 @Reject_Status_Desc   = 'Reject',  
 @Received_Status_Desc  = 'Received',  
 @Consumed_Status_Id  = 8,  
 @Complete_Status_Id  = 5,  
 @Partial_Run_Status_Id  = 13,  
 @Inventory_Status_Id  = 9,  
 @Was_Unloaded   = NULL,  
 @InputVarDesc   = 'Unwind Stand'  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM Users  
WHERE username = 'Reliability System'  
  
-- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
IF @TableName = 'PrdExec_Input_Event'   
 BEGIN  
 SELECT @ErrMsg = '',  
  @Success = 1  
 END  
ELSE IF @TableName = 'PrdExec_Input_Event_History'  
 BEGIN  
 -- Get configuration data  
 SELECT @PEIId   = PEI_Id,  
  @PEIPId   = PEIP_Id,  
  @UnLoaded  = Unloaded,  
  @SourceEventId  = Event_Id,  
  @InputTimeStamp  = TimeStamp,  
  @EntryOn  = Entry_On  
 FROM [dbo].PrdExec_Input_Event_History  
 WHERE Input_Event_History_Id = @Id  
  
 SELECT @InputPUId = PU_Id   
 FROM [dbo].PrdExec_Inputs  
 WHERE PEI_Id = @PEIId  
  
 SELECT @DetailsPUId = coalesce(GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, 'DETAILSUNIT='), @InputPUId)  
 FROM [dbo].Prod_Units  
 WHERE PU_Id = @InputPUId  
  
 -- Get custom status ids  
 SELECT @Received_Status_Id = ProdStatus_Id  
 FROM [dbo].Production_Status  
 WHERE ProdStatus_Desc = @Received_Status_Desc  
  
 SELECT @Reject_Status_Id = ProdStatus_Id  
 FROM [dbo].Production_Status  
 WHERE ProdStatus_Desc = @Reject_Status_Desc  
  
 /********************************************************************************************************  
 *    Loaded the running or staged position     *  
 ********************************************************************************************************/  
 IF @UnLoaded = 0  
  AND ( @PEIPId = 1  
   OR @PEIPId = 2)  
  AND @SourceEventId IS NOT NULL  
  BEGIN  
  ------------------------------------------------------------------------------------------  
  -- Prevent multiple scan errors by verifying that the last event was unloaded. --  
  -- This is a workaround for MSI case 51670      --  
  ------------------------------------------------------------------------------------------  
  -- Get the last loaded event  
  SELECT TOP 1 @Last_History_Id = Input_Event_History_Id,  
    @Last_Event_Id  = Event_Id  
  FROM [dbo].PrdExec_Input_Event_History   
  WHERE PEI_Id = @PEIId  
   AND PEIP_Id = @PEIPId  -- MKW 02/04/04  
   AND Unloaded = 0  
   AND Event_Id IS NOT NULL  
   AND Input_Event_History_Id < @Id  
  ORDER BY Input_Event_History_Id DESC  
  
  -- Check to see if it was unloaded  
  SELECT TOP 1 @Last_Unloaded = Unloaded  
  FROM [dbo].PrdExec_Input_Event_History   
  WHERE PEI_Id = @PEIId  
   AND PEIP_Id = @PEIPId -- MKW 02/04/04  
   AND ( (Event_Id = @Last_Event_Id -- Unloaded  
     AND Unloaded = 1)  
    OR (Event_Id IS NULL  -- Completed  
     AND Unloaded = 0))  
   AND Input_Event_History_Id < @Id  
   AND Input_Event_History_Id > @Last_History_Id  
  ORDER BY Input_Event_History_Id ASC  
  
  -- If it wasn't unloaded (and the previous event is different from the current event),  
  -- unload the current event and restore the previous event    
  IF @Last_History_Id IS NOT NULL  
   AND @Last_Unloaded IS NULL  
   BEGIN  
   IF @Last_Event_Id <> @SourceEventId  
    BEGIN  
    -- Unload the current event  
    INSERT INTO @EventInputs( Transaction_Type,  
        TimeStamp,  
        EntryOn,  
        PEI_Id,  
        PEIP_Id,  
        Event_Id,  
        Unloaded,  
        User_id)   
    VALUES (3,  
     convert(varchar(25), getdate(), 121),  
     NULL,  
     @PEIId,  
     @PEIPId,  
     @SourceEventId,  
     1,  
     @User_id)  
   
    -- Load the previous event back up  
    INSERT INTO @EventInputs( Transaction_Type,  
        TimeStamp,  
        EntryOn,  
        PEI_Id,  
        PEIP_Id,  
        Event_Id,  
        Unloaded,  
        User_id)   
    VALUES (2,  
     convert(varchar(25), getdate(), 121),  
     NULL,  
     @PEIId,  
     @PEIPId,  
     @Last_Event_Id,  
     0,  
     @User_id)  
    END  
   END  
  ELSE  
   ----------------------------------------------------------------------------------  
   -- Create Event        --  
   ----------------------------------------------------------------------------------  
   BEGIN  
   -- Get the most recent event and check if it's 'open'  
   -- (ie. status of running, staged or inventory)  
   SELECT TOP 1 @Event_Id = e.Event_Id,  
     @Event_Num = e.Event_Num,  
     @TimeStamp = e.TimeStamp,  
     @Event_Status = e.Event_Status  
   FROM [dbo].Event_Components ec  
    INNER JOIN [dbo].Events e ON e.Event_Id = ec.Event_Id  
       AND e.PU_Id = @DetailsPUId  
   WHERE ec.Source_Event_Id = @SourceEventId  
   ORDER BY e.TimeStamp DESC  
     
   -- If no open event, create a new one  
   IF @Event_Id IS NULL  
    OR ( @Event_Id IS NOT NULL  
     AND @Event_Status NOT IN (3, 4, 9))  
    BEGIN  
    -- Reset event id  
    SELECT @Event_Id = NULL  
  
    -- Set event status  
    IF @PEIPId = 1  
     BEGIN  
     SELECT @Event_Status = 4 -- Running  
     END  
    ELSE  
     BEGIN  
     SELECT @Event_Status = 3 -- Staged  
     END  
  
    -- Get Event Number and ensure there are no duplicates  
    SELECT @Event_Num = ltrim(rtrim(Event_Num))  
    FROM [dbo].Events  
    WHERE Event_Id = @SourceEventId  
  
    SELECT @EventPattern = '%' + @Event_Num + '%'  
  
    SELECT @Count = count(Event_Num)  
    FROM [dbo].Events   
    WHERE Event_Num LIKE @EventPattern  
     AND PU_Id = @DetailsPUId  
  
    IF @Count > 0  
     BEGIN  
     SELECT @Event_Num = @Event_Num + '-' + convert(varchar(25), @Count)  
     END  
  
    -- Set TimeStamp and ensure there are no duplicates  
    SELECT @TimeStamp = dateadd(ms, -datepart(ms, @InputTimeStamp), @InputTimeStamp)  
  
    SELECT @Count = count(TimeStamp)  
    FROM [dbo].Events  
    WHERE PU_Id = @DetailsPUId  
  
     AND TimeStamp = @TimeStamp  
  
    WHILE @Count > 0  
     BEGIN  
     SELECT @TimeStamp = dateadd(s, 1, @TimeStamp)  
  
     SELECT @Count = count(TimeStamp)  
     FROM [dbo].Events  
     WHERE PU_Id = @DetailsPUId  
      AND TimeStamp = @TimeStamp  
     END  
  
    -- Hot update because need to ensure that events are getting in immediately so don't END up with same timestamp AND need the Event_Id   
    EXEC spServer_DBMgrUpdEvent @Event_Id OUTPUT,   -- Event_Id  
        @Event_Num,    -- Event_Num  
        @DetailsPUId,    -- PU_Id  
        @TimeStamp,   -- TimeStamp  
        NULL,     -- Applied_Product  
        @SourceEventId,  -- Source_Event_Id  
        @Event_Status,   -- Event_Status  
        1,    -- Transaction_Type  
        0,     -- Transaction_Num  
        @User_id,     -- User_Id  
        NULL,     -- Comment_Id  
        NULL,     -- Event_Subtype_Id  
        NULL,     -- Testing_Status  
        NULL,     -- Start_Time  
        @InputTimeStamp,   -- Entry_On  
        1    -- Return_Result_Set  
  
    -- Post update notification to Message Bus  
    INSERT INTO @Events ( Event_Id,  
       Event_Num,  
       PU_Id,  
       TimeStamp,  
       Source_Event,  
       Event_Status,  
       Post_Update,  
       User_id)  
    VALUES( @Event_Id,  
     @Event_Num,  
     @DetailsPUId,  
     convert(varchar(25), @TimeStamp, 120),  
     @SourceEventId,  
     @Event_Status,  
     1,  
     @User_id)  
  
    -- Hot insert roll into Event_Components  
    EXEC spServer_DBMgrUpdEventComp @User_id,    -- User_Id  
        @Event_Id,   -- Event_Id  
        @Component_Id OUTPUT, -- Component_Id  
        @SourceEventId,  -- Source_Event_Id  
        0,    -- Dimension_X  
        0,    -- Dimension_Y  
        0,    -- Dimension_Z  
        0,    -- Dimension_A  
        0,    -- Transaction_Num  
        1,    -- Transaction_Type  
        NULL    -- Child_Unit_Id  
  
    --  Fill out the event component.  
    INSERT INTO @EventComponents ( Pre_Update,  
        Component_Id,  
        Event_Id,  
        Source_Event_Id,User_id)  
    VALUES (0,  
     @Component_Id,  
     @Event_Id,  
     @SourceEventId,@User_id)  
  
    IF @Received_Status_Id Is Not NULL  
     BEGIN  
     --  Set source event status to received  
     INSERT INTO @Events ( Transaction_Type,   
        Event_Id,   
        Event_Num,    
        PU_Id,   
        TimeStamp,   
        Source_Event,   
        Event_Status,   
        Applied_Product,  
        Post_Update,User_id)  
     SELECT 2,   
      @SourceEventId,   
      Event_Num,   
      PU_Id,   
      TimeStamp,   
      Source_Event,   
      @Received_Status_Id,   
      Applied_Product,  
      0,@User_id  
     FROM [dbo].Events  
     WHERE Event_Id = @SourceEventId  
     END  
  
    END  
   ELSE  
    BEGIN  
    -- If the status is different than the input position,  
    -- update the status of the event  
    IF ( @PEIPId = 1  
      AND @Event_Status <> 4)  
     OR ( @PEIPId = 2  
      AND @Event_Status <> 3)  
     BEGIN  
     SELECT @Event_Status =  CASE @PEIPId  
         WHEN 1 THEN 4  
         ELSE 3  
         END  
  
     -- Hot update  
     EXEC spServer_DBMgrUpdEvent @Event_Id OUTPUT,   -- Event_Id  
         @Event_Num,    -- Event_Num  
         @DetailsPUId,    -- PU_Id  
         @TimeStamp,   -- TimeStamp  
         NULL,     -- Applied_Product  
         @SourceEventId,  -- Source_Event_Id  
         @Event_Status,   -- Event_Status  
         2,    -- Transaction_Type  
         0,     -- Transaction_Num  
         @User_id,     -- User_Id  
         NULL,     -- Comment_Id  
         NULL,     -- Event_Subtype_Id  
         NULL,     -- Testing_Status  
         NULL,     -- Start_Time  
         @InputTimeStamp,   -- Entry_On  
         0    -- Return_Result_Set  
  
     INSERT INTO @Events ( Transaction_Type,  
        Event_Id,  
        Event_Num,  
        PU_Id,  
        TimeStamp,  
        Source_Event,  
        Event_Status,  
        Post_Update,User_id)  
     VALUES( 2,  
      @Event_Id,  
      @Event_Num,  
      @DetailsPUId,  
      @TimeStamp,  
      @SourceEventId,  
      @Event_Status,  
      1,@User_id)  
     END  
    END  
  
   ----------------------------------------------------------------------------------  
   -- Close any previously open events (ie. so we don't have any hanging --  
   -- events).  This is normally due to the operators changing the status --  
   -- of the display in the Parent Roll Details display.   --  
   ----------------------------------------------------------------------------------  
   -- Get the unwind stand  
   SELECT @InputVarId = GBDB.dbo.fnLocal_GlblGetVarId(@DetailsPUId, @InputVarDesc)  
   
   SELECT @InputName = Input_Name  
   FROM [dbo].PrdExec_Inputs  
   WHERE PEI_Id = @PEIId  
   
   -- Update the event(s)  
   INSERT INTO @Events ( Transaction_Type,  
      Event_Id,  
      Event_Num,  
      PU_Id,  
      TimeStamp,  
      Source_Event,  
      Event_Status,User_id)  
   SELECT 2,  
    e.Event_Id,  
    e.Event_Num,  
    e.PU_Id,  
    e.TimeStamp,  
    e.Source_Event,  
    CASE @Event_Status  
     WHEN 4 THEN @Partial_Run_Status_Id  
     ELSE @Inventory_Status_Id  
     END,  
    @User_id  
   FROM [dbo].Events e  
    INNER JOIN [dbo].tests t ON t.Var_Id = @InputVarId  
       AND t.Result_On = e.TimeStamp  
       AND t.Result = @InputName  
   WHERE e.PU_Id = @DetailsPUId  
    AND e.TimeStamp < @TimeStamp  
    AND e.Event_Status = @Event_Status  
   END  
  END  
 /********************************************************************************************************  
 *       Completed the roll in the running position     *  
 ********************************************************************************************************/  
 ELSE IF (@UnLoaded = 0) AND (@PEIPId = 1) AND (@SourceEventId Is NULL)  
  BEGIN  
  -- Check for unloaded rolls - Everytime a roll is unloaded it is followed by a 'Completion' Input event  
  -- so we don't want to recalculate  
  SELECT @Was_Unloaded = Unloaded  
  FROM [dbo].PrdExec_Input_Event_History  
  WHERE PEI_Id = @PEIId  
   AND PEIP_Id = 1  
   AND Unloaded = 1  
   AND Timestamp = @InputTimeStamp  
   AND Event_Id Is Not NULL  
  
  IF @Was_Unloaded Is NULL  
   BEGIN  
   -- Find the last running/completed event  
   SELECT @MaxId = MAX(Input_Event_History_Id)   
   FROM [dbo].PrdExec_Input_Event_History  
   WHERE PEI_Id = @PEIId  
    AND PEIP_Id = 1  
    AND Unloaded = 0  
    AND Timestamp < @InputTimeStamp  
    AND Event_Id IS NOT NULL  
  
   SELECT @SourceEventId = Event_Id   
   FROM [dbo].PrdExec_Input_Event_History  
   WHERE Input_Event_History_Id = @MaxId  
  
   -- MKW 02/18/04 - Added check for PU_Id and consolidated with query below  
   SELECT TOP 1  @Event_Id = e.Event_Id,  
     @Event_Num = e.Event_Num,  
     @TimeStamp = e.TimeStamp, --MKW 01/30/04  
     @Event_Status = e.Event_Status  
   FROM [dbo].Event_Components ec  
    INNER JOIN [dbo].Events e ON e.Event_Id = ec.Event_Id  
       AND e.PU_Id = @DetailsPUId  
   WHERE ec.Source_Event_Id = @SourceEventId  
--    AND e.Event_Status IN (3, 4)  
    AND e.TimeStamp < @InputTimeStamp  
   ORDER BY e.TimeStamp DESC  
  
   IF @Event_Status IN (3, 4)  
    BEGIN  
    -- Set the child event status to Complete AND the END time to the current time  
    -- Hot update  
    EXEC spServer_DBMgrUpdEvent @Event_Id OUTPUT,   -- Event_Id  
        @Event_Num,    -- Event_Num  
        @DetailsPUId,    -- PU_Id  
        @TimeStamp,   -- TimeStamp  
        NULL,     -- Applied_Product  
        @SourceEventId,  -- Source_Event_Id  
        @Complete_Status_Id,  -- Event_Status  
        2,    -- Transaction_Type  
        0,     -- Transaction_Num  
        @User_id,     -- User_Id  
        NULL,     -- Comment_Id  
        NULL,     -- Event_Subtype_Id  
        NULL,     -- Testing_Status  
        NULL,     -- Start_Time  
        @InputTimeStamp,   -- Entry_On  
        0    -- Return_Result_Set  
   
    INSERT INTO @Events ( Transaction_Type,  
       Event_Id,  
       Event_Num,  
       PU_Id,  
       TimeStamp,  
       Source_Event,  
       Event_Status,  
       Post_Update,User_id)  
    VALUES( 2,  
     @Event_Id,  
     @Event_Num,  
     @DetailsPUId,  
     @TimeStamp,  
     @SourceEventId,  
     @Complete_Status_Id,  
     1,@User_id)  
  
    -- Set the parent event status to Consumed  - MKW 02/14/03   
    INSERT INTO @Events ( Transaction_Type,  
       Event_Id,  
       Event_Num,  
       PU_Id,  
       TimeStamp,  
       Event_Status,  
       Applied_Product,User_id)  
    SELECT 2,  
     Event_Id,  
     Event_Num,  
     PU_Id,  
     TimeStamp,  
     @Consumed_Status_Id,  
     Applied_Product,@User_id  
    FROM [dbo].Events  
    WHERE Event_Id = @SourceEventId  
    END  
  
   /* Update the Event_Details TABLE with the dimensions */  
   INSERT INTO @EventDetails ( Transaction_Type,  
       Event_Id,  
       PU_Id,  
       Event_Status,  
       TimeStamp,  
       Primary_Event_Num,  
       Initial_Dimension_X, Final_Dimension_X,   
       Initial_Dimension_Y, Final_Dimension_Y,   
       Initial_Dimension_Z, Final_Dimension_Z,   
       Initial_Dimension_A, Final_Dimension_A,User_id)  
   SELECT  1,  
    @Event_Id,  
    @DetailsPUId,  
    @Complete_Status_Id,  
    @TimeStamp,  
    @Event_Num,  
    Initial_Dimension_X, Final_Dimension_X,   
    Initial_Dimension_Y, Final_Dimension_Y,   
    Initial_Dimension_Z, Final_Dimension_Z,   
    Initial_Dimension_A, Final_Dimension_A,@User_id  
   FROM [dbo].Event_Details  
   WHERE Event_Id = @SourceEventId  
  
   /* Update the Event_Components TABLE with the dimensions */  
   SELECT  @Dimension_X = (Final_Dimension_X-Initial_Dimension_X),   
    @Dimension_Y = (Final_Dimension_Y-Initial_Dimension_Y),  
    @Dimension_Z = (Final_Dimension_Z-Initial_Dimension_Z),  
    @Dimension_A = (Final_Dimension_A-Initial_Dimension_A)  
   FROM [dbo].Event_Details  
   WHERE Event_Id = @SourceEventId  
  
   UPDATE [dbo].Event_Components   
   SET Dimension_X = @Dimension_X,  
    Dimension_Y = @Dimension_Y,  
    Dimension_Z = @Dimension_Z,  
    Dimension_A = @Dimension_A  
   WHERE Event_Id = @Event_Id  
   END  
  END  
 /********************************************************************************************************  
 *    Unload the roll in the staged/running position    *  
 ********************************************************************************************************/  
 ELSE IF @UnLoaded = 1  
  BEGIN  
  SELECT @SourceEventId = Event_Id   
  FROM [dbo].PrdExec_Input_Event_History  
  WHERE Input_Event_History_Id = @Id  
  
  -- MKW 02/18/04 - Added check for PU_Id and consolidated with query below  
  -- MKW 06/15/04 - Added check/sort for timestamp and for event status  
  SELECT TOP 1 @Event_Id = e.Event_Id,  
    @Event_Num = e.Event_Num,  
    @TimeStamp = e.TimeStamp,  
    @Event_Status = e.Event_Status  
  FROM [dbo].Event_Components ec  
   INNER JOIN [dbo].Events e ON ec.Event_Id = e.Event_Id  
      AND e.PU_Id = @DetailsPUId  
  WHERE ec.Source_Event_Id = @SourceEventId  
   AND e.Event_Status IN (3, 4)  
   AND e.TimeStamp < @InputTimeStamp  
  ORDER BY e.TimeStamp DESC  
  
  -- Update the child event status  
  IF @Event_Id IS NOT NULL  
   AND @Event_Status <> @Reject_Status_Id  
   BEGIN  
   SELECT @Event_Status = CASE @PEIPId  
       WHEN 1 THEN @Partial_Run_Status_Id  
       ELSE @Inventory_Status_Id  
       END  
  
   -- Hot update  
   EXEC spServer_DBMgrUpdEvent @Event_Id OUTPUT,   -- Event_Id  
       @Event_Num,    -- Event_Num  
       @DetailsPUId,    -- PU_Id  
       @TimeStamp,   -- TimeStamp  
       NULL,     -- Applied_Product  
       @SourceEventId,  -- Source_Event_Id  
       @Event_Status,   -- Event_Status  
       2,    -- Transaction_Type  
       0,     -- Transaction_Num  
       @User_Id,     -- User_Id  
       NULL,     -- Comment_Id  
       NULL,     -- Event_Subtype_Id  
       NULL,     -- Testing_Status  
       NULL,     -- Start_Time  
       @InputTimeStamp,   -- Entry_On  
       0    -- Return_Result_Set  
  
   INSERT INTO @Events ( Transaction_Type,  
      Event_Id,  
      Event_Num,  
      PU_Id,  
      TimeStamp,  
      Source_Event,  
      Event_Status,  
      Post_Update,User_Id)  
   VALUES( 2,  
    @Event_Id,  
    @Event_Num,  
    @DetailsPUId,  
    @TimeStamp,  
    @SourceEventId,  
    @Event_Status,  
    1,@User_Id)  
   END  
  END  
  
 SELECT @ErrMsg = ''  
 SELECT @Success = 1  
 END  
ELSE IF  @TableName = 'Events'  
 BEGIN  
 --------------------------------------------------------------------------------------------------  
 --     Initialization      --  
 --------------------------------------------------------------------------------------------------  
 SELECT @Received_Status_Id = ProdStatus_Id  
 FROM [dbo].Production_Status  
 WHERE ProdStatus_Desc = @Received_Status_Desc  
  
 SELECT @Reject_Status_Id = ProdStatus_Id  
 FROM [dbo].Production_Status  
 WHERE ProdStatus_Desc = @Reject_Status_Desc  
  
 SELECT @PEIId = PEI_Id  
 FROM [dbo].Event_Configuration  
 WHERE EC_Id = @ECId  
  
 SELECT @DetailsPUId  = PU_Id,   
  @TimeStamp = TimeStamp,   
  @Event_Status = Event_Status,  
  @EntryOn = Entry_On,  
  @User_Id = User_Id  
 FROM [dbo].Events  
 WHERE Event_Id = @Id  
  
 -- Get genealogy and if missing try to create it with the source_event value (legacy)  
 SELECT @SourceEventId = Source_Event_Id  
 FROM [dbo].Event_Components  
 WHERE Event_Id = @Id  
  
 IF @SourceEventId Is NULL  
  BEGIN  
  SELECT @SourceEventId = Source_Event  
  FROM [dbo].Events  
  WHERE Event_Id = @Id  
  
  -- IF not already, then link to source  
  IF @SourceEventId IS Not NULL  
   BEGIN  
   INSERT INTO @EventComponents ( Transaction_Type,   
       [dbo].Event_Id,   
       Source_Event_Id,User_Id)  
   VALUES (1,  
    @Id,  
    @SourceEventId,@User_Id)  
   END  
  END  
  
 -- Get source event information  
 SELECT @SourceEventStatus = Event_Status  
 FROM [dbo].Events  
 WHERE Event_Id = @SourceEventId  
  
 --------------------------------------------------------------------------------------------------  
 --    Verify the we have the right input    --  
 --------------------------------------------------------------------------------------------------  
 SELECT @InputEventId = Input_Event_Id,  
  @PEIPId  = PEIP_Id  
 FROM [dbo].PrdExec_Input_Event  
 WHERE PEI_Id = @PEIId  
  AND Event_Id = @SourceEventId  
  
 IF @InputEventId IS NULL  
  BEGIN  
  SELECT @PLId = PL_Id  
  FROM [dbo].Prod_Units  
  WHERE PU_Id = @DetailsPUId  
    
  SELECT TOP 1 @InputEventId = pei.Input_Event_Id,  
    @PEIId  = pei.PEI_Id,  
    @PEIPId  = pei.PEIP_Id  
  FROM [dbo].PrdExec_Input_Event pei  
   INNER JOIN [dbo].PrdExec_Inputs pe ON pei.PEI_Id = pe.PEI_Id  
       AND pe.PEI_Id > 0  -- Just to force the index  
   INNER JOIN [dbo].Prod_Units pu ON pe.PU_Id = pu.PU_Id  
  WHERE PL_Id = @PLId  
   AND GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, 'DETAILSUNIT=') = @DetailsPUId  
   AND pei.Event_Id = @SourceEventId  
  ORDER BY TimeStamp DESC  
  END  
  
 --------------------------------------------------------------------------------------------------  
 --    Act on the different roll statuses    --  
 --------------------------------------------------------------------------------------------------  
 -- Roll was rejected then unload from the input  
 IF @Event_Status = @Reject_Status_Id  
  BEGIN  
  IF @InputEventId IS NOT NULL  
   BEGIN  
   -- Issue movement commmand to 'Unload' the roll   
   INSERT INTO @EventInputs ( Transaction_Type,  
       TimeStamp,  
       EntryOn,  
       PEI_Id,  
       PEIP_Id,  
       Event_Id,  
       Unloaded,User_Id)  
   SELECT 3,  
    convert(varchar(30), getdate(), 121),  
    NULL,  
    PEI_Id,  
    PEIP_Id,  
    NULL,  
    1,@User_Id  
   FROM [dbo].PrdExec_Input_Event  
   WHERE PEI_Id = @PEIId  
    AND Event_Id = @SourceEventId  
    AND TimeStamp <= @EntryOn  
  
   IF @@ROWCOUNT > 0  
    BEGIN  
    -- Set the parent event status to Consumed   
    INSERT INTO @Events ( Transaction_Type,  
       Event_Id,  
       Event_Num,  
       PU_Id,  
       TimeStamp,  
       Source_Event,  
       Event_Status,  
       Applied_Product,User_Id)  
    SELECT 2,  
     Event_Id,  
     Event_Num,  
     PU_Id,  
     TimeStamp,  
     Source_Event,  
     @Consumed_Status_Id,  
     Applied_Product,@User_Id  
    FROM [dbo].Events  
    WHERE Event_Id = @SourceEventId  
    END  
   END  
  END  
 ELSE IF @Event_Status = 5  -- Complete  
  BEGIN  
  -- Check to see if the event is loaded in the input  
  IF @InputEventId IS NOT NULL  
   BEGIN  
   SELECT @PEIPId = NULL  
   SELECT @PEIPId = PEIP_Id  
   FROM [dbo].PrdExec_Input_Event  
   WHERE PEI_Id = @PEIId  
    AND Event_Id = @SourceEventId  
    AND TimeStamp <= @EntryOn  
   
   IF @PEIPId IS NOT NULL  
    BEGIN  
    IF @PEIPId = 1  
     BEGIN -- Issue movement command to 'Complete' the roll   
     INSERT INTO @EventInputs ( Transaction_Type,  
         TimeStamp,  
         EntryOn,  
         PEI_Id,  
         PEIP_Id,  
         Event_Id,  
         Unloaded,User_id)  
     VALUES( 1,  
      convert(varchar(30), @EntryOn, 121),  
      NULL,  
      @PEIId,  
      @PEIPId,  
      NULL,  
      1,@User_id)  
     
     -- Consume the parent event  
     INSERT INTO @Events ( Transaction_Type,  
        Event_Id,  
        Event_Num,  
        PU_Id,  
        TimeStamp,  
        Source_Event,  
        Event_Status,  
        Applied_Product,User_id)  
     SELECT 2,  
      Event_Id,  
      Event_Num,  
      PU_Id,  
      TimeStamp,  
      Source_Event,  
      @Consumed_Status_Id,  
      Applied_Product,@User_id  
     FROM [dbo].Events  
     WHERE Event_Id = @SourceEventId  
     END  
   
    -- Check for an event in the staged position  
    SELECT @Staged_Event_Id = Event_Id  
    FROM [dbo].PrdExec_Input_Event  
    WHERE PEI_Id = @PEIId  
     And PEIP_Id = 2  --@Staged_Position  
   
    IF @Staged_Event_Id IS NOT NULL  
     BEGIN  
     -- Unload the staged position  
     INSERT INTO @EventInputs( Transaction_Type,  
         TimeStamp,  
         EntryOn,  
         PEI_Id,  
         PEIP_Id,  
         Event_Id,  
         Unloaded,User_id)   
     VALUES (3,  
      convert(varchar(25), @EntryOn, 121),  
      NULL,  
      @PEIId,  
      2,   --@Staged_Position,  
      @Staged_Event_Id,  
      1,@User_id)  
   
     -- Load the running position  
     INSERT INTO @EventInputs( Transaction_Type,  
         TimeStamp,  
         EntryOn,  
         PEI_Id,  
         PEIP_Id,  
         Event_Id,  
         Unloaded,User_id)   
     VALUES (2,  
      convert(varchar(25), @EntryOn, 121),  
      NULL,  
      @PEIId,  
      1,   --@Running_Position,  
      @Staged_Event_Id,  
      0,@User_id)  
     END  
    END  
   END  
  END  
 -- IF event was only partially run then reset the source event's status to what it was before  
 ELSE IF @Event_Status = @Partial_Run_Status_Id  
  OR @Event_Status = @Inventory_Status_Id  
  BEGIN  
  -- Check to see if this is the most recent event component b/c don't want to accidentally reset  
  SELECT @Count = count(e.Event_Id)  
  FROM [dbo].Events e  
      INNER JOIN [dbo].Event_Components ec ON e.Event_Id = ec.Event_Id  
       AND ec.Source_Event_Id = @SourceEventId  
  WHERE e.TimeStamp > @TimeStamp  
  
  IF @Count = 0  
   BEGIN  
   IF @SourceEventStatus IN (@Consumed_Status_Id, @Received_Status_Id)  
    BEGIN  
    -- Get previous id  
    SELECT TOP 1 @Event_Status = Event_Status  
    FROM [dbo].Event_History  
    WHERE Event_Id = @SourceEventId  
     AND Event_Status <> @Consumed_Status_Id  
     AND Event_Status <> @Received_Status_Id  
    ORDER BY Entry_On DESC  
   
    IF @Event_Status IS NOT NULL  
     BEGIN      
     -- Reset the parent event status  
     INSERT INTO @Events ( Transaction_Type,  
        Event_Id,  
        Event_Num,  
        PU_Id,  
        TimeStamp,  
        Source_Event,  
        Event_Status,  
        Applied_Product,User_id)  
     SELECT 2,  
      Event_Id,  
      Event_Num,  
      PU_Id,  
      TimeStamp,  
      Source_Event,  
      @Event_Status,  
      Applied_Product,@User_id  
     FROM [dbo].Events  
     WHERE Event_Id = @SourceEventId  
     END  
    END  
   END  
  END  
  
 -- Cleanup   
 SELECT @ErrMsg = ''  
 SELECT @Success = 1  
 END  
  
/* Issue Result Sets - Issue Event Components before Event Updates so in place before Genealogy calcs trigger */  
IF (SELECT count(Result_Set_Type) FROM @EventComponents) > 0  
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
  
IF (SELECT count(Result_Set_Type) FROM @Events) > 0   
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
    FROM @Events  
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
    FROM @Events  
   END  
   
 END  
  
IF (SELECT count(Result_Set_Type) FROM @EventDetails) > 0   
 BEGIN  
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
 END  
  
IF (SELECT count(Result_Set_Type) FROM @EventInputs) > 0   
 BEGIN  
 SELECT  Result_Set_Type ,  
    Pre_Update ,  
    User_Id ,  
    Transaction_Type  ,     
    Transaction_Number ,  
    TimeStamp ,   
    EntryOn  ,   
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
 END  
  
-------------------------------------------------------------------------------------------------------------------------  
-- 2009-02-09 Vince King Added for UWS Running code.  
-- Check to see if the UDE (Event_SubType) is configured for this unit. If not then skip and do not execute code.  
-------------------------------------------------------------------------------------------------------------------------  
SELECT @EventSubTypeId = Event_SubType_Id  
FROM dbo.Event_Subtypes  
WHERE Event_SubType_Desc = 'UWS Running'  
  
-- Only execute sp when table name = PrdExec_Input_Event_History and event status <> staged and when the UWS Running   
-- UDE is configured on the production unit.  
IF @TableName = 'PrdExec_Input_Event_History' AND @Event_Status <> 3 AND  
  ((SELECT COUNT(EC_Id) FROM dbo.Event_Configuration WHERE PU_Id = @DetailsPUId AND Event_SubType_Id = @EventSubTypeId) > 0)  
 BEGIN  
  
  -- 2009-02-09 Vince King  
  -- spLocal_CreateUpdateUDE creates or updates (closes) the UDE 'UWS Running' based on the Event Status.  It will  
  -- create a new UDE when the event status is running and then updates or closes the UDE when the roll is moved  
  -- out of running.  The parameters are as follows:  
  --  @User_Id    - Users.User_Id to be assigned to the UDE.  
  --  @DetailsPUId   - Prod_Units.PU_Id of the production unit that the UDE is assigned to.  
  --  @EventSubTypeId - Event_SubTypes.Event_SubType_Id of the 'UWS Running' UDE.  
  --  @Id      - Event_Id of the production event.  
  
  EXECUTE spLocal_CreateUpdateUDE @User_Id, @DetailsPUId, @EventSubTypeId, @Id  
  
 END  
-------------------------------------------------------------------------------------------------------------------------  
  
SET NOCOUNT OFF  
  
