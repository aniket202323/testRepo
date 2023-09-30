
CREATE PROCEDURE dbo.spUserDefined_UpdateUserDefinedEvent @EventId       INT,
                                                          @UserId        INT,
                                                          @AckStatus     INT,
                                                          @AckUserId     INT,
                                                          @AckTime       DATETIME,
                                                          @Description   NVarchar(50),
                                                          @StartTime     DATETIME,
                                                          @EndTime       DATETIME,
                                                          @EventStatusId INT,
                                                          @Cause1        INT,
                                                          @Cause2        INT,
                                                          @Cause3        INT,
                                                          @Cause4        INT

 AS
BEGIN

    DECLARE @EventSubTypeDesc nVARCHAR(100), @EventSubTypeId INT, @PUID INT, @Action4 INT, @Action3 INT, @Action2 INT, @Action1 INT, @Duration INT, @ResearchCommentId INT, @ResearchStatusId INT, @ResearchUserId INT, @ResearchOpenDate DATETIME, @ResearchCloseDate DATETIME, @UDECommentId INT, @SignatureId INT, @EventId2 INT, @ParentUDEId INT, @TestingStatus INT


    SELECT @EventSubTypeDesc = es.Event_Subtype_Desc,
           @EventSubTypeId = ude.Event_Subtype_Id,
           @PUID = ude.PU_Id,
           @Action4 = ude.Action4,
           @Action3 = ude.Action3,
           @Action2 = ude.Action2,
           @Action1 = ude.Action1,
           @Duration = ude.Duration,
           @ResearchCommentId = ude.Research_Comment_Id,
           @ResearchStatusId = ude.Research_Status_Id,
           @ResearchUserId = ude.Research_User_Id,
           @ResearchOpenDate = ude.Research_Comment_Id,
           @ResearchCloseDate = ude.Research_Close_Date,
           @UDECommentId = ude.Comment_Id,
           @SignatureId = ude.Signature_Id,
           @EventId2 = ude.Event_Id,
           @ParentUDEId = ude.Parent_UDE_Id,
           @TestingStatus = ude.Testing_Status
           FROM User_Defined_Events AS ude
                LEFT JOIN Event_Subtypes AS es ON ude.Event_Subtype_Id = es.Event_Subtype_Id
           WHERE UDE_Id = @EventId

    IF @EventId IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'User Defined Event not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'UDE_Id',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
        
     DECLARE @SheetIds INTEGERTABLETYPE
    INSERT INTO @SheetIds
    SELECT Sheet_Id FROM Sheets WHERE Sheet_type = 25
                                      AND Master_Unit = @PUId    
    IF NOT EXISTS(SELECT 1 FROM(SELECT dbo.fnActivities_CheckSheetSecurityForActivities(Item, 46, 3, @PUId, @UserId) AS AddSecurity FROM @SheetIds) AS S WHERE S.AddSecurity = 1)
        BEGIN
            SELECT Code = 'InsufficientPermission',
                   Error = 'Insufficient permissions to edit user defined event',
                   ErrorType = 'Unauthorized',
                   PropertyName1 = 'Sheet',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''

            RETURN
        END    
        
    IF @StartTime IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'StartTime not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'StartTime',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF @EndTime IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'EndTime not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'EndTime',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF @Description IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Invalid - Description Is Required',
                   ErrorType = 'MissingRequiredData',
                   PropertyName1 = 'Description',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF @StartTime >= @EndTime
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Invalid - StartTime Must be Less than EndTime',
                   ErrorType = 'StartTimeNotBeforeEndTime',
                   PropertyName1 = 'StartTime',
                   PropertyName2 = 'EndTime',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @StartTime,
                   PropertyValue2 = @EndTime,
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    DECLARE @StartTimeDB DATETIME= dbo.fnServer_CmnConvertToDBTime(@StartTime, 'UTC')
    DECLARE @EndTimeDB DATETIME= dbo.fnServer_CmnConvertToDBTime(@EndTime, 'UTC')
    DECLARE @AckTimeDB DATETIME= dbo.fnServer_CmnConvertToDBTime(@AckTime, 'UTC')

---------------------------------------------------------------------------------------------------------------------------
--DE111559--------Check for event conflict , Should not allow multiple ude with same sub type on same unit on same end time
---------------------------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT 1 FROM User_Defined_Events WHERE PU_Id = @PUId AND End_Time = @EndTimeDB AND Event_Subtype_Id = @EventSubtypeId AND UDE_Id <> @EventId)
        BEGIN
            SELECT Code = 'EventRecordConflict',
                   Error = 'User Defined exists with same end time',
                   ErrorType = 'TimeStampConflict',
                   PropertyName1 = 'EndTime',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @EndTime,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''

            RETURN
        END

    EXECUTE spServer_DBMgrUpdUserEvent 2, @EventSubTypeDesc, NULL, @Action4, @Action3, @Action2, @Action1, NULL, @Cause4, @Cause3, @Cause2, @Cause1, @AckUserId, @AckStatus, @Duration, @EventSubTypeId, @PUID, @Description, @EventId OUTPUT, @UserId, @AckTimeDB, @StartTimeDB, @EndTimeDB, @ResearchCommentId, @ResearchStatusId, @ResearchUserId, @ResearchOpenDate, @ResearchCloseDate, 2, @UDECommentId, NULL, @SignatureId, @EventId2, @ParentUDEId, @EventStatusId, @TestingStatus

    EXECUTE spUserDefined_GetUserDefinedEvent @EventId
END

