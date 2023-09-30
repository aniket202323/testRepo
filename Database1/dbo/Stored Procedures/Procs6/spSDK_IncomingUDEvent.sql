CREATE PROCEDURE dbo.spSDK_IncomingUDEvent
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @TransactionType 	  	 INT,
 	 @TransNum 	  	  	  	 INT,
 	 @UDEId 	  	  	  	  	 INT,
 	 @LineName 	  	  	  	 nvarchar(50),
 	 @UnitName 	  	  	  	 nvarchar(50),
 	 @EventSubType 	  	  	 nvarchar(50),
 	 @EventName 	  	  	  	 nvarchar(50),
 	 @StartTime 	  	  	  	 DATETIME,
 	 @EndTime 	  	  	  	  	 DATETIME,
 	 @Duration 	  	  	  	 FLOAT,
 	 @Ack 	  	  	  	  	  	 BIT,
 	 @AckBy 	  	  	  	  	 nvarchar(50),
 	 @AckOn 	  	  	  	  	 DATETIME,
 	 @Cause1 	  	  	  	  	 nvarchar(50),
 	 @Cause2 	  	  	  	  	 nvarchar(50),
 	 @Cause3 	  	  	  	  	 nvarchar(50),
 	 @Cause4 	  	  	  	  	 nvarchar(50),
 	 @Action1 	  	  	  	  	 nvarchar(50),
 	 @Action2 	  	  	  	  	 nvarchar(50),
 	 @Action3 	  	  	  	  	 nvarchar(50),
 	 @Action4 	  	  	  	  	 nvarchar(50),
 	 @ResearchStatus 	  	 nvarchar(50),
 	 @ResearchUserName 	  	 nvarchar(50),
 	 @ResearchOpenDate 	  	 DATETIME,
 	 @ResearchCloseDate 	 DATETIME,
 	 @UserId 	  	  	  	  	 INT,
        --Input/Output parameters
        @ESignatureId                           INT OUTPUT
AS
DECLARE 	 @RC 	  	  	  	  	  	 INT,
 	  	  	 @ErrMsg 	  	  	  	  	 nvarchar(255),
 	  	  	 @PLId 	  	  	  	  	  	 INT,
 	  	  	 @PUId 	  	  	  	  	  	 INT,
 	  	  	 @EventSubTypeId 	  	 INT,
 	  	  	 @AckById 	  	  	  	  	 INT,
 	  	  	 @Cause1Id 	  	  	  	 INT,
 	  	  	 @Cause2Id 	  	  	  	 INT,
 	  	  	 @Cause3Id 	  	  	  	 INT,
 	  	  	 @Cause4Id 	  	  	  	 INT,
 	  	  	 @CauseCommentId 	  	 INT,
 	  	  	 @Action1Id 	  	  	  	 INT,
 	  	  	 @Action2Id 	  	  	  	 INT,
 	  	  	 @Action3Id 	  	  	  	 INT,
 	  	  	 @Action4Id 	  	  	  	 INT,
 	  	  	 @ActionCommentId 	  	 INT,
 	  	  	 @ResearchStatusId 	  	 INT,
 	  	  	 @ResearchUserId 	  	 INT,
 	  	  	 @ResearchCommentId 	 INT,
 	  	  	 @CommentId 	  	  	  	 INT
IF @ESignatureId = 0 SELECT @ESignatureId = NULL
SELECT 	 @RC = 0,
 	  	  	 @ErrMsg = ''
--Lookup Unit
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id
 	 FROM 	 Prod_Lines 
 	 WHERE 	 PL_Desc = @LineName
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id 
 	 FROM 	 Prod_Units 
 	 WHERE 	 PL_Id = @PLId AND
 	  	  	 PU_Desc = @UnitName
SELECT 	 @EventSubTypeId = NULL
SELECT 	 @EventSubTypeId = Event_Subtype_Id
 	 FROM 	 Event_Subtypes
 	 WHERE 	 Event_Subtype_Desc = @EventSubType
 	 AND 	 ET_Id = 14
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
SELECT 	 @AckById = NULL
SELECT 	 @AckById = User_Id
 	 FROM 	 Users
 	 WHERE UserName = @AckBy
SELECT 	 @CommentId 	  	  	  	 = NULL,
 	  	  	 @CauseCommentId 	  	 = NULL,
 	  	  	 @ActionCommentId 	  	 = NULL,
 	  	  	 @ResearchCommentId 	 = NULL
--Confirm TEDetId
IF @TransactionType IN (2,3) OR @UpdateClientOnly = 1
BEGIN
 	 IF (SELECT COUNT(*) FROM User_Defined_Events WHERE UDE_Id = @UDEId) = 0
 	 BEGIN
 	  	 SELECT 	 @RC = 1,
 	  	  	  	  	 @ErrMsg = 'User Defined Event Not Found'
 	 END ELSE
 	 BEGIN
 	  	 SELECT 	 @CommentId 	  	  	  	 = Comment_Id,
 	  	  	  	  	 @CauseCommentId 	  	 = Cause_Comment_Id,
 	  	  	  	  	 @ActionCommentId 	  	 = Action_Comment_Id,
 	  	  	  	  	 @ResearchCommentId 	 = Research_Comment_Id
 	  	  	 FROM 	 User_Defined_Events
 	  	  	 WHERE 	 UDE_Id = @UDEId
 	 END
END
IF @PLId IS NULL
BEGIN
 	 SELECT 	 @RC = 2,
 	  	  	  	 @ErrMsg = 'Line Specified Not Found'
END ELSE
IF @PUId IS NULL
BEGIN
 	 SELECT 	 @RC = 3,
 	  	  	  	 @ErrMsg = 'Unit Specified Not Found'
END ELSE
IF @EventSubTypeId IS NULL
BEGIN
 	 SELECT 	 @RC = 4,
 	  	  	  	 @ErrMsg = 'Event SubType Not Found'
END
IF @RC = 0
BEGIN
 	 IF @WriteDirect = 0 AND @UpdateClientOnly = 0
 	 BEGIN
 	  	 SELECT 	 8,1,@UDEId, @EventName, @PUId, @EventSubTypeId, @StartTime, @EndTime, @Duration, @Ack, @AckOn, @AckById,
 	  	  	  	  	 @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id, @CauseCommentId, @Action1Id, @Action2Id, @Action3Id, @Action4Id, @ActionCommentId, 
 	  	  	  	  	 @ResearchUserId, @ResearchStatusId, @ResearchOpenDate, @ResearchCloseDate, @ResearchCommentId, @CommentId,
 	  	  	  	  	 @TransactionType, @EventSubType, @TransNum, @UserId, @ESignatureId
 	 END ELSE
 	 IF @WriteDirect = 0 AND @UpdateClientOnly = 1
 	 BEGIN
 	  	 SELECT 	 8,0,@UDEId, @EventName, @PUId, @EventSubTypeId, @StartTime, @EndTime, @Duration, @Ack, @AckOn, @AckById,
 	  	  	  	  	 @Cause1Id, @Cause2Id, @Cause3Id, @Cause4Id, @CauseCommentId, @Action1Id, @Action2Id, @Action3Id, @Action4Id, @ActionCommentId, 
 	  	  	  	  	 @ResearchUserId, @ResearchStatusId, @ResearchOpenDate, @ResearchCloseDate, @ResearchCommentId, @CommentId,
 	  	  	  	  	 @TransactionType, @EventSubType, @TransNum, @UserId,@ESignatureId
 	 END ELSE
 	 IF @WriteDirect = 1 AND @UpdateClientOnly = 0
 	 BEGIN
 	  	 EXECUTE @RC = spServer_DBMgrUpdUserEvent
 	  	  	  	  	 @TransNum, 
 	  	  	  	  	 @EventSubType, 
 	  	  	  	  	 @ActionCommentId, 
 	  	  	  	  	 @Action4Id, 
 	  	  	  	  	 @Action3Id, 
 	  	  	  	  	 @Action2Id, 
 	  	  	  	  	 @Action1Id, 
 	  	  	  	  	 @CauseCommentId, 
 	  	  	  	  	 @Cause4Id, 
 	  	  	  	  	 @Cause3Id, 
 	  	  	  	  	 @Cause2Id, 
 	  	  	  	  	 @Cause1Id, 
 	  	  	  	  	 @AckById, 
 	  	  	  	  	 @Ack, 
 	  	  	  	  	 @Duration, 
 	  	  	  	  	 @EventSubTypeId, 
 	  	  	  	  	 @PUId, 
 	  	  	  	  	 @EventName, 
 	  	  	  	  	 @UDEId, 
 	  	  	  	  	 @UserId, 
 	  	  	  	  	 @AckOn, 
 	  	  	  	  	 @StartTime, 
 	  	  	  	  	 @EndTime, 
 	  	  	  	  	 @ResearchCommentId, 
 	  	  	  	  	 @ResearchStatusId, 
 	  	  	  	  	 @ResearchUserId, 
 	  	  	  	  	 @ResearchOpenDate, 
 	  	  	  	  	 @ResearchCloseDate, 
 	  	  	  	  	 @TransactionType, 
 	  	  	  	  	 @CommentId,
                                        NULL,
                                        @ESignatureId
 	 
 	  	 IF @RC < 0
 	  	 BEGIN
 	  	  	 SELECT 	 @ErrMsg = 'WriteDirect Error: ' + CONVERT(VARCHAR, @RC) + '.'
 	  	 END ELSE
 	  	 BEGIN
 	  	  	 SELECT 	 @RC = 0
 	  	 END
 	 END
END 
-- RETURN BACK SUCCESS CODE AND ERROR MESSAGES
SELECT 	 ResultSet 	 = -999, 
 	  	  	 ReturnCode 	 = @RC, 
 	  	  	 ErrorMsg 	  	 = @ErrMsg
RETURN
