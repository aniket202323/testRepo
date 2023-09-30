  ---------------------------------------------------------------------------------------------------------------  
--  
-- Procedure: spLocal_CreateUpdateUDE   
-- Created: 2009-01-26  
-- Last Modified: 2009-02-12  
-- Current Revision: 1.04  
--  
-- Created By: Vince King (King Designs and Consulting, Inc.)  
--  
-- Purpose: This sp receives parameter data and creates or updates a user defined event.  
-- Called From: spLocal_GeneCvtg  
--  
-- 2009-01-26 Vince King Rev1.0  
--     Original Version  
--  
-- 2009-01-28 Vince King Rev1.01  
--     Modified code to indicate whether the UDE is to be created or updated.  
--  
-- 2009-02-04 Vince King Rev1.02  
--     Modified to use hot update for user defined event.  
--   
-- 2009-02-05 Vince King Rev1.03  
--     Changed code for creating sheets column.  
--  
-- 2009-02-12 Vince King Rev1.04  
--     Commented out sheet column code.  Tests entries are being created without use of the code.  
--  
---------------------------------------------------------------------------------------------------------------  
CREATE procedure dbo.spLocal_CreateUpdateUDE  
-- DECLARE  
@UserId     INTEGER,      --User id for the result sets  
@PUId      INTEGER,      --Production unit where to create the UDE  
@EventSubTypeId  INTEGER,      --SP needs event subtype when creating or updating UDE  
@Id      INTEGER      --Id of PrdExec_Input_Event_History table.  
  
AS  
  
SET NOCOUNT ON  
  
-- Assign parameters for testing.  
-- SELECT @UserId    = 400,  
--    @PUId     = 75,  
--    @EventSubTypeId = 62,  
--    @Id     = 4688913  
     
DECLARE  @UDEId     INTEGER,      --UDE_Id  
   @EndTime     DATETIME,     --UDE end time  
   @StartTime    DATETIME,     --UDE start time  
   @UDEDesc     VARCHAR(50),    --UDE description.  
   @UWS      VARCHAR(50),    --PrdExec_Inputs.Input_Name  
   @TimeStamp    DATETIME,     --TimeStamp - StartTime for create, EndTime for update.  
   @TransType    INTEGER,      --1=Create;2=Update   
   @EventNum    VARCHAR(50),    --Events.Event_Num  
   @EventStatus   INTEGER,      --Events.Event_Status  
   @EventSubTypeDesc  VARCHAR(50),    --Event_SubTypes.Event_SubType_Desc  
   @EventId     INTEGER,      --Events.Event_Id  
   @SourceEventId   INTEGER      --Events.Source_Event   
  
-- Get the Event SubType Description  
SET @EventSubTypeDesc = (SELECT Event_SubType_Desc  
        FROM dbo.Event_SubTypes WITH(NOLOCK)  
        WHERE Event_SubType_Id = @EventSubTypeId)  
  
--User Defined Event Result Set (Result Set 8)  
DECLARE @rs8UserDefinedEvent TABLE (  
 rs8ResultSetType   INTEGER DEFAULT 8,  -- 00 - Result Set Type  
 rs8UpdateType    INTEGER DEFAULT 1,  -- 01 - Update Type  
 rs8EventId     INTEGER,     -- 02 - Event Id  
 rs8EventNum    VARCHAR(25),      
 rs8PUId      INTEGER,     -- 04 - PU Id  
 rs8EventSubTypeId  INTEGER,     -- 05 - Event SubType Id  
 rs8StartTime    DATETIME,     -- 06 - Start Time  
 rs8EndTime     DATETIME,     -- 07 - End Time  
 rs8Duration    FLOAT,       
 rs8Acknowledged  BIT,     
 rs8AckTimestamp   DATETIME,  
 rs8AcknowledgedBy  INTEGER,  
 rs8Cause1    INTEGER,  
 rs8Cause2    INTEGER,   
 rs8Cause3    INTEGER,  
 rs8Cause4    INTEGER,  
 rs8CauseCommentId  INTEGER,  
 rs8Action1    INTEGER,  
 rs8Action2    INTEGER,  
 rs8Action3    INTEGER,  
 rs8Action4    INTEGER,  
 rs8ActionCommentId INTEGER,  
 rs8ResearchUserId  INTEGER,  
 rs8ResearchStatusId INTEGER,  
 rs8ResearchOpenDate DATETIME,  
 rs8ResearchCloseDate DATETIME,  
 rs8ResearchCommentId INTEGER,  
 rs8UDEventCommentId INTEGER,  
 rs8TransactionType  INTEGER,     -- 28 - Transaction Type (1:Add, 2:Update, 3:Delete)  
 rs8UDEDesc    VARCHAR(1000),   -- 29 - UDE Description  
 rs8TransactionNumber INTEGER DEFAULT 0, -- 30 - Transaction number (0:Update fields not null, 2:Update all fields)   
 rs8UserId     INTEGER,     -- 31 - User Id  
 rs8ESignature   INTEGER  
)  
  
-- Get the Input Name to be stored in the UDE_Desc column.  
SELECT @UWS = Input_Name  
FROM dbo.PrdExec_Inputs WITH(NOLOCK)  
WHERE PEI_Id = (SELECT PEI_Id FROM dbo.PrdExec_Input_Event_History WITH(NOLOCK) WHERE Input_Event_History_Id = @Id)  
  
-- Get Event_Id from PrdExec_Input_Event_History table.  
SELECT @SourceEventId  = Event_Id,  
   @TimeStamp    = TimeStamp  
FROM dbo.PrdExec_Input_Event_History WITH(NOLOCK)  
WHERE Input_Event_History_Id = @Id  
  
-- Get Event_Id and Event_Status  
SELECT @EventStatus = Event_Status,  
   @EventId   = Event_Id  
FROM dbo.Events WITH(NOLOCK)  
WHERE Source_Event = @SourceEventId  
  
-- Check to see if an open UDE exists for the PEI_Id AND Event_Status = 4 (Running).  
-- If it does then return and do nothing.  
IF (SELECT COUNT(UDE_Id) FROM dbo.User_Defined_Events WITH(NOLOCK) WHERE UDE_Desc = @UWS AND PU_Id = @PUId   
  AND Event_SubType_Id = @EventSubTypeId AND End_Time IS NULL) = 0 AND @EventStatus <> 4  
 BEGIN  
  RETURN  
 END  
  
-- Get Event_Status from Event where  
-- Process of creating a UDE.  The event status is 'Running', create a new UDE with the start_time = time that  
-- the roll was moved to running.  
IF @EventStatus = 4   
 BEGIN  
  --Getting other values  
  SET @TransType = 1  
    
  SET @EndTime = NULL  
  SET @StartTime = (SELECT TimeStamp FROM dbo.PrdExec_Input_Event_History WITH(NOLOCK)  
         WHERE Input_Event_History_Id = @Id)  
  SET @UDEId = NULL  
  SET @EventNum = (SELECT Event_Num FROM dbo.Events WITH(NOLOCK) WHERE Event_Id = @EventId)  
  
 END  
--Process of updating a UDE.  The event status something other than 'Running' so update the UDE, set the endtime.  
ELSE   
 BEGIN  
  --Getting infos from the UDE  
  SET @TransType = 2  
  SET @UDEId = NULL  
  SELECT TOP 1 @UDEId = UDE_Id, @StartTime = Start_Time, @UDEDesc = UDE_Desc, @EventId = Event_Id  
  FROM dbo.User_Defined_Events WITH(NOLOCK)   
  WHERE UDE_Desc = @UWS AND PU_Id = @PUId AND Event_Subtype_Id = @EventSubTypeId AND End_Time IS NULL  
  ORDER BY Start_Time DESC  
   
  IF @UDEId IS NULL   
   BEGIN  
    RETURN  
   END  
  
  SET @EndTime = (SELECT TimeStamp FROM dbo.PrdExec_Input_Event_History WITH(NOLOCK)  
         WHERE Input_Event_History_Id = @Id)  
  
  SELECT  @EventNum   = Event_Num,  
     @EventStatus = Event_Status  
  FROM dbo.Events WITH(NOLOCK)  
  WHERE Event_Id = @EventId  
  
 END  
  
  IF @EventStatus = 4  
   BEGIN  
    
    EXEC dbo.spServer_DBMgrUpdUserEvent   
       2,                -- *Transaction Number  0=Update fields that are not null 2=Update all fields  
       @EventSubTypeDesc,          -- *Event Subtype Desc  
       NULL,               -- Action Comment Id  
       NULL,               -- Action 4  
       NULL,               -- Action 3  
       NULL,               -- Action 2  
       NULL,               -- Action 1  
       NULL,               -- Cause Comment Id  
       NULL,               -- Cause 4  
       NULL,               -- Cause 3  
       NULL,               -- Cause 2  
       NULL,               -- Cause 1  
       @UserId,              -- Ack By  
       1,                -- *Ack  
       NULL,               -- Duration  
       @EventSubtypeId,           -- *Event Subtype Id  
       @PUId,              -- *Pu Id  
       @UWS,               -- *Ude Desc  
       @UDEId OUTPUT,            -- *Ude Id  
       @UserId,              -- *User Id  
       NULL,               -- Ack On  
       @StartTime,             -- *Start Time  
       @EndTime,             -- *End Time  
       NULL,               -- Research Comment Id  
       NULL,               -- Research Status Id  
       NULL,               -- Research User Id  
       NULL,               -- Research Open Date  
       NULL,               -- Research Close Date  
       1,                -- *Transtype  
       NULL,               -- UDE Comment Id  
       NULL               -- Event Reason Tree Data Id  
  
    -- Hot Update for User_Defined_Events.Event_Id  
     IF @EventId IS NOT NULL AND @UDEId IS NOT NULL  
      UPDATE dbo.User_Defined_Events SET Event_Id = @EventId WHERE UDE_Id = @UDEId  
  
   END  
 ELSE  
   BEGIN  
    
    EXEC dbo.spServer_DBMgrUpdUserEvent   
       2,                -- *Transaction Number  0=Update fields that are not null 2=Update all fields  
       @EventSubTypeDesc,          -- *Event Subtype Desc  
       NULL,               -- Action Comment Id  
       NULL,               -- Action 4  
       NULL,               -- Action 3  
       NULL,               -- Action 2  
       NULL,               -- Action 1  
       NULL,               -- Cause Comment Id  
       NULL,               -- Cause 4  
       NULL,               -- Cause 3  
       NULL,               -- Cause 2  
       NULL,               -- Cause 1  
       @UserId,              -- Ack By  
       1,                -- *Ack  
       NULL,               -- Duration  
       @EventSubtypeId,           -- *Event Subtype Id  
       @PUId,              -- *Pu Id  
       @UWS,               -- *Ude Desc  
       @UDEId,              -- *Ude Id  
       @UserId,              -- *User Id  
       NULL,               -- Ack On  
       @StartTime,             -- *Start Time  
       @EndTime,             -- *End Time  
       NULL,               -- Research Comment Id  
       NULL,               -- Research Status Id  
       NULL,               -- Research User Id  
       NULL,               -- Research Open Date  
       NULL,               -- Research Close Date  
       2,                -- *Transtype  
       NULL,               -- UDE Comment Id  
       NULL               -- Event Reason Tree Data Id  
  
--     -- The roll has been moved out of the running status so   
--     -- Create columns for UWS Running sheet to populate variables.  
--     SELECT   [ResultSetType]   = 7,  
--        [SheetId]     = sc.Sheet_Id,  
--        [UserId]      = @UserId,  
--        [TransType]     = 1,  
--        [TimeStamp]     = sc.Result_On,  
--        [PostDB]      = 0,  
--        [ApprovedUserId]   = NULL,  
--        [ApprovedReasonId]  = NULL,  
--        [UserReasonId]    = NULL,  
--        [UserSignOffId]   = NULL  
--     FROM      dbo.Sheet_Columns sc WITH(NOLOCK)  
--     JOIN        dbo.Sheets s  WITH(NOLOCK) ON sc.Sheet_Id = s.Sheet_Id  
--     AND        s.Master_Unit = @PUId  
--     AND        s.Event_Subtype_Id = @EventSubTypeId  
--     WHERE    sc.Result_On = @EndTime  
  
   END  
  
    -- Update the Modified_On column.  
     UPDATE dbo.User_Defined_Events SET Modified_On = GETDATE() WHERE UDE_Id = @UDEId  
  
RETURN  
  
