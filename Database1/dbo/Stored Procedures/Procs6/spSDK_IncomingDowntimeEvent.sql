CREATE PROCEDURE dbo.spSDK_IncomingDowntimeEvent
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @LineName 	  	  	  	 nvarchar(50),
 	 @UnitName 	  	  	  	 nvarchar(50),
 	 @StartTime 	  	  	  	 DATETIME,
 	 @EndTime 	  	  	  	 DATETIME,
 	 @Duration 	  	  	  	 FLOAT,
 	 @Fault 	  	  	  	  	 nvarchar(100),
 	 @Cause1 	  	  	  	  	 nvarchar(100),
 	 @Cause2 	  	  	  	  	 nvarchar(100),
 	 @Cause3 	  	  	  	  	 nvarchar(100),
 	 @Cause4 	  	  	  	  	 nvarchar(100),
 	 @Action1 	  	  	  	 nvarchar(100),
 	 @Action2 	  	  	  	 nvarchar(100),
 	 @Action3 	  	  	  	 nvarchar(100),
 	 @Action4 	  	  	  	 nvarchar(100),
 	 @ResearchStatus 	  	  	 nvarchar(50),
 	 @ResearchUserName 	  	 nvarchar(50),
 	 @SourceLineName 	  	  	 nvarchar(50),
 	 @SourceUnitName 	  	  	 nvarchar(50),
 	 @ResearchOpenDate 	  	 DATETIME,
 	 @ResearchCloseDate 	  	 DATETIME,
 	 @UserId 	  	  	  	  	 INT,
 	 @DowntimeStatusName 	  	 nvarchar(100),
 	 -- Input/Output Parameters
 	 @TEDetId 	  	  	  	 INT OUTPUT,
 	 @TransactionType 	  	 INT OUTPUT,
    @ESignatureId           INT OUTPUT,
 	 -- Output Parameters
 	 @PUId 	  	  	  	  	 INT OUTPUT,
 	 @FaultId 	  	  	  	 INT OUTPUT,
 	 @Cause1Id 	  	  	  	 INT OUTPUT,
 	 @Cause2Id 	  	  	  	 INT OUTPUT,
 	 @Cause3Id 	  	  	  	 INT OUTPUT,
 	 @Cause4Id 	  	  	  	 INT OUTPUT,
 	 @CauseCommentId 	  	  	 INT OUTPUT,
 	 @Action1Id 	  	  	  	 INT OUTPUT,
 	 @Action2Id 	  	  	  	 INT OUTPUT,
 	 @Action3Id 	  	  	  	 INT OUTPUT,
 	 @Action4Id 	  	  	  	 INT OUTPUT,
 	 @ActionCommentId 	  	 INT OUTPUT,
 	 @ResearchStatusId 	  	 INT OUTPUT,
 	 @ResearchUserId 	  	  	 INT OUTPUT,
 	 @ResearchCommentId 	  	 INT OUTPUT,
 	 @SrcPUId 	  	  	  	 INT OUTPUT,
 	 @DowntimeStatusId 	  	 INT OUTPUT,
 	 @TransNum 	  	  	  	 INT 	 OUTPUT
AS
DECLARE 	 @PLId 	  	  	 INT,
 	  	 @SrcPLId 	  	 INT,
 	  	 @RC 	  	  	  	 INT
IF @ESignatureId = 0 SELECT @ESignatureId = NULL
-- initilize all true outputs to null
SELECT 	 @PUId 	 = NULL,
 	 @FaultId 	 = NULL,
 	 @Cause1Id 	 = NULL,
 	 @Cause2Id 	 = NULL,
 	 @Cause3Id 	 = NULL,
 	 @Cause4Id 	 = NULL,
 	 @CauseCommentId 	 = NULL,
 	 @Action1Id 	 = NULL,
 	 @Action2Id 	 = NULL,
 	 @Action3Id 	 = NULL,
 	 @Action4Id 	 = NULL,
 	 @ActionCommentId 	 = NULL,
 	 @ResearchStatusId 	 = NULL,
 	 @ResearchUserId 	 = NULL,
 	 @ResearchCommentId 	 = NULL,
 	 @SrcPUId 	 = NULL,
 	 @DowntimeStatusId 	 = NULL
SELECT @TransNum = isnull(@TransNum,0)
-- Return Values
-- 0 - Success
-- 1 = Line Specified Not Found
-- 2 = Unit Specified Not Found
-- 3 = Source Event Line Specified Not Found
-- 4 = Source Event Unit Specified Not Found
-- 5 = Unable to Find Downtime Event
-- 6 = Invalid Downtime Status
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
SELECT 	 @ResearchStatusId = NULL
SELECT 	 @ResearchStatusId = Research_Status_Id
 	 FROM 	 Research_Status
 	 WHERE 	 Research_Status_Desc = @ResearchStatus
SELECT 	 @ResearchUserId = NULL
SELECT 	 @ResearchUserId = User_Id
 	 FROM 	 Users
 	 WHERE UserName = @ResearchUserName
SELECT 	 @CauseCommentId = NULL
SELECT 	 @ActionCommentId = NULL
SELECT 	 @ResearchCommentId = NULL
--Confirm TEDetId
IF @TransactionType IN (2,3) OR @UpdateClientOnly = 1
BEGIN
 	 IF (SELECT COUNT(*) FROM Timed_Event_Details WHERE TEDet_Id = @TEDetId) = 0
 	 BEGIN
 	  	 RETURN(5)
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @CauseCommentId = Cause_Comment_Id,
 	  	  	  	  	 @ActionCommentId = Action_Comment_Id,
 	  	  	  	  	 @ResearchCommentId = Research_Comment_Id
 	  	  	 FROM 	 Timed_Event_Details
 	  	  	 WHERE 	 TEDet_Id = @TEDetId
 	 END
END
SELECT 	 @FaultId = NULL
SELECT 	 @FaultId = TEFault_Id
 	 FROM 	 Timed_Event_Fault
 	 WHERE 	 TEFault_Name = @Fault AND PU_Id = @SrcPUId
IF 	 @DowntimeStatusName IS NOT NULL
BEGIN
 	 SET 	  	 @DowntimeStatusId = NULL
 	 SELECT 	 @DowntimeStatusId = TEStatus_Id
 	  	 FROM 	 Timed_Event_Status
 	  	 WHERE 	 PU_Id = @PUId
 	  	 AND 	 TEStatus_Name = @DowntimeStatusName
 	 IF @DowntimeStatusId IS NULL
 	 BEGIN
 	  	 RETURN(6)
 	 END
END
IF 	 @WriteDirect = 1 AND @UpdateClientOnly = 0
BEGIN
 	 EXECUTE @RC = spServer_DBMgrUpdTimedEvent
 	  	  	  	 @TEDetId OUTPUT , 
 	  	  	  	 @PUId, 
 	  	  	  	 @SrcPUId, 
 	  	  	  	 @StartTime, 
 	  	  	  	 @EndTime OUTPUT , 
 	  	  	  	 @DowntimeStatusId, 
 	  	  	  	 @FaultId, 
 	  	  	  	 @Cause1Id, 
 	  	  	  	 @Cause2Id, 
 	  	  	  	 @Cause3Id,
 	  	  	  	 @Cause4Id, 
 	  	  	  	 @Duration, 
 	  	  	  	 NULL, 
 	  	  	  	 @TransactionType, 
 	  	  	  	 @TransNum, 
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
 	  	  	  	 NULL, 
 	  	  	  	 NULL, 
 	  	  	  	 NULL, 
 	  	  	  	 NULL, 
 	  	  	  	 NULL,
 	  	  	  	 NULL, 
 	  	  	  	 @ResearchOpenDate, 
 	  	  	  	 @ResearchCloseDate, 
 	  	  	  	 @ResearchUserId,
                NULL,
                @ESignatureId
 	 IF @RC < 0
 	 BEGIN
 	  	 RETURN(6)
 	 END
END
RETURN(0)
