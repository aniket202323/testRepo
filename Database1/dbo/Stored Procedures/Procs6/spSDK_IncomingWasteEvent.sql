CREATE PROCEDURE dbo.spSDK_IncomingWasteEvent
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @LineName 	  	  	  	 nvarchar(50),
 	 @UnitName 	  	  	  	 nvarchar(50),
 	 @EventName 	  	  	 nvarchar(25),
 	 @Timestamp 	  	  	 DATETIME,
 	 @Amount 	  	  	  	 REAL,
 	 @Cause1 	  	  	  	 nvarchar(50),
 	 @Cause2 	  	  	  	 nvarchar(50),
 	 @Cause3 	  	  	  	 nvarchar(50),
 	 @Cause4 	  	  	  	 nvarchar(50),
 	 @Action1 	  	  	  	 nvarchar(50),
 	 @Action2 	  	  	  	 nvarchar(50),
 	 @Action3 	  	  	  	 nvarchar(50),
 	 @Action4 	  	  	  	 nvarchar(50),
 	 @Measurement 	  	  	 nvarchar(50),
 	 @ResearchOpenDate 	  	 DATETIME,
 	 @ResearchCloseDate 	  	 DATETIME,
 	 @ResearchStatus 	  	 nvarchar(50),
 	 @ResearchUserName 	  	 nvarchar(50),
 	 @SourceLineName 	  	 nvarchar(50),
 	 @SourceUnitName 	  	 nvarchar(50),
 	 @WasteType 	  	  	 nvarchar(50),
 	 @UserId 	  	  	  	 INT,
 	 @Fault 	  	  	  	 nvarchar(50),
 	 @UserGeneral1 	  	  	 nvarchar(255),
 	 @UserGeneral2 	  	  	 nvarchar(255),
 	 @UserGeneral3 	  	  	 nvarchar(255),
 	 @UserGeneral4 	  	  	 nvarchar(255),
 	 @UserGeneral5 	  	  	 nvarchar(255),
 	 -- Input/Output Parameters
 	 @WasteId 	  	  	  	 INT OUTPUT,
 	 @TransactionType 	  	 INT OUTPUT,
 	 @ESignatureId 	  	  	 INT OUTPUT,
 	 -- Output Parameters
 	 @PUId 	  	  	  	 INT OUTPUT,
 	 @EventId 	  	  	  	 INT OUTPUT,
 	 @Cause1Id 	  	  	  	 INT OUTPUT,
 	 @Cause2Id 	  	  	  	 INT OUTPUT,
 	 @Cause3Id 	  	  	  	 INT OUTPUT,
 	 @Cause4Id 	  	  	  	 INT OUTPUT,
 	 @CauseCommentId 	  	 INT OUTPUT,
 	 @Action1Id 	  	  	 INT OUTPUT,
 	 @Action2Id 	  	  	 INT OUTPUT,
 	 @Action3Id 	  	  	 INT OUTPUT,
 	 @Action4Id 	  	  	 INT OUTPUT,
 	 @ActionCommentId 	  	 INT OUTPUT,
 	 @WEMTId 	  	  	  	 INT OUTPUT,
 	 @ResearchStatusId 	  	 INT OUTPUT,
 	 @ResearchUserId 	  	 INT OUTPUT,
 	 @ResearchCommentId 	  	 INT OUTPUT,
 	 @SrcPUId 	  	  	  	 INT OUTPUT,
 	 @WETId 	  	  	  	 INT OUTPUT,
 	 @WEFaultId 	  	  	 INT OUTPUT
AS
DECLARE 	 @PLId 	  	  	 INT,
 	  	 @SrcPLId 	  	  	 INT
IF @ESignatureId = 0 SELECT @ESignatureId = NULL
-- Return Values
-- 0 - Success
-- 1 = Line Specified Not Found
-- 2 = Unit Specified Not Found
-- 3 = Source Event Line Specified Not Found
-- 4 = Source Event Unit Specified Not Found
-- 5 = Unable to Find Waste Event
--Lookup Unit
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id
 	 FROM 	 Prod_Lines 
 	 WHERE 	 PL_Desc = @LineName
IF @PLId IS NULL RETURN(1)
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id 
 	 FROM 	 Prod_Units 
 	 WHERE 	 PL_Id = @PLId AND
 	  	  	 PU_Desc = @UnitName
IF @PUId IS NULL RETURN(2)
SELECT 	 @SrcPLId = NULL
SELECT 	 @SrcPLId = PL_Id
 	 FROM 	 Prod_Lines
 	 WHERE 	 PL_Desc = @SourceLineName
IF @SrcPLId IS NULL RETURN(3)
SELECT 	 @SrcPUId = NULL
SELECT 	 @SrcPUId = PU_Id 
 	 FROM 	 Prod_Units 
 	 WHERE 	 PL_Id = @PLId AND
 	  	  	 PU_Desc = @SourceUnitName
 	  	  	 
IF @SrcPUId IS NULL RETURN(4)
SELECT 	 @EventId = NULL
SELECT 	 @EventId = Event_Id
 	 FROM 	 Events
 	 WHERE 	 Event_Num = @EventName AND
 	  	  	 PU_Id = @PUId
SELECT 	 @Cause1Id = NULL
SELECT 	 @Cause1Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Cause1
SELECT 	 @Cause2Id = NULL
SELECT 	 @Cause2Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Cause2
SELECT 	 @Cause3Id = NULL
SELECT 	 @Cause3Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Cause3
SELECT 	 @Cause4Id = NULL
SELECT 	 @Cause4Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Cause4
SELECT 	 @Action1Id = NULL
SELECT 	 @Action1Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Action1
SELECT 	 @Action2Id = NULL
SELECT 	 @Action2Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Action2
SELECT 	 @Action3Id = NULL
SELECT 	 @Action3Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Action3
SELECT 	 @Action4Id = NULL
SELECT 	 @Action4Id = Event_Reason_Id
 	 FROM 	 Event_Reasons
 	 WHERE 	 Event_Reason_Name = @Action4
SELECT 	 @WEMTId = NULL
SELECT 	 @WEMTId = WEMT_Id
 	 FROM  	 Waste_Event_Meas
 	 WHERE 	 PU_Id = @PUId AND
 	  	  	 WEMT_Name = @Measurement
 	 
SELECT 	 @ResearchStatusId = NULL
SELECT 	 @ResearchStatusId = Research_Status_Id
 	 FROM 	 Research_Status
 	 WHERE 	 Research_Status_Desc = @ResearchStatus
SELECT 	 @ResearchUserId = NULL
SELECt 	 @ResearchUserId = User_Id
 	 FROM 	 Users
 	 WHERE UserName = @ResearchUserName
SELECT 	 @WETId = NULL
SELECT 	 @WETId = WET_Id
 	 FROM 	 Waste_Event_Type
 	 WHERE 	 WET_Name = @WasteType
SELECT 	 @WEFaultId = NULL
SELECT 	 @WEFaultId = WEFault_Id
 	 FROM 	 Waste_Event_Fault
 	 WHERE 	 PU_Id = @PUId AND WEFault_Name = @Fault
SELECT 	 @CauseCommentId 	  	 = NULL
SELECT 	 @ActionCommentId 	  	 = NULL
SELECT 	 @ResearchCommentId 	 = NULL
IF 	 @TransactionType IN (2,3) OR @UpdateClientOnly = 1
BEGIN
 	 IF @WasteId IS NULL
 	 BEGIN
 	  	 SELECT 	 @WasteId = WED_Id
 	  	  	 FROM 	 Waste_Event_Details
 	  	  	 WHERE 	 Timestamp = @Timestamp AND
 	  	  	  	  	 (Event_Id = @EventId OR (@EventId IS NULL AND Event_Id IS NULL))
 	 END ELSE
 	 BEGIN
 	  	 IF (SELECT COUNT(*) FROM Waste_Event_Details WHERE WED_Id = @WasteId) = 0
 	  	 BEGIN
 	  	  	 SELECT 	 @WasteId = NULL
 	  	 END
 	 END
 	 SELECT 	 @CauseCommentId = Cause_Comment_Id,
 	  	  	  	 @ActionCommentId = Action_Comment_Id,
 	  	  	  	 @ResearchCommentId = Research_Comment_Id
 	  	 FROM 	 Waste_Event_Details
 	  	 WHERE 	 WED_Id = @WasteId
 	 IF @TransactionType = 2 AND @WasteId IS NULL
 	 BEGIN
 	  	 SELECT @TransactionType = 1
 	 END ELSE
 	 IF @TransactionType = 3 AND @WasteId IS NULL
 	 BEGIN
 	  	 RETURN(5)
 	 END
END
IF @WriteDirect = 1 AND @UpdateClientOnly 	 = 0
BEGIN
 	 DECLARE 	 @RC 	  	  	 INT
 	 EXECUTE @RC = spServer_DBMgrUpdWasteEvent
 	  	  	  	 @WasteId OUTPUT,
 	  	  	  	 @PUId,
 	  	  	  	 @SrcPUId,
 	  	  	  	 @TimeStamp,
 	  	  	  	 @WETId,
 	  	  	  	 @WEMTId,
 	  	  	  	 @Cause1Id,
 	  	  	  	 @Cause2Id,
 	  	  	  	 @Cause3Id,
 	  	  	  	 @Cause4Id,
 	  	  	  	 @EventId,
 	  	  	  	 @Amount,
 	  	  	  	 NULL,
 	  	  	  	 NULL,
 	  	  	  	 @TransactionType,
 	  	  	  	 0,
 	  	  	  	 @UserId,
 	  	  	  	 @Action1Id,
 	  	  	  	 @Action2Id,
 	  	  	  	 @Action3Id,
 	  	  	  	 @Action4Id,
 	  	  	  	 @ActionCommentId,
 	  	  	  	 @ResearchCommentId,
 	  	  	  	 @ResearchStatusId,
 	  	  	  	 @CauseCommentId,
 	  	  	  	 NULL,
 	  	  	  	 @ResearchOpenDate,
 	  	  	  	 @ResearchCloseDate,
 	  	  	  	 @ResearchUserId,
 	  	  	  	 @WEFaultId,
 	  	  	  	 NULL,
 	  	  	  	 NULL,
 	  	  	  	 NULL,
 	  	  	  	 NULL,
 	  	  	  	 NULL,
 	  	  	  	 NULL,
 	  	  	  	 NULL,
 	  	  	  	 NULL,
 	  	  	  	 NULL,
 	  	  	  	 @UserGeneral4,
 	  	  	  	 @UserGeneral5,
 	  	  	  	 NULL,
 	  	  	  	 @UserGeneral1,
 	  	  	  	 @UserGeneral2,
 	  	  	  	 @UserGeneral3,
 	  	  	  	 NULL,
 	  	  	  	 @ESignatureId
 	 IF @RC < 0
 	 BEGIN
 	  	 RETURN(6)
 	 END
END
RETURN(0)
