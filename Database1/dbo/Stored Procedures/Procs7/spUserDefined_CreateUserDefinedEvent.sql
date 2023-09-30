
CREATE PROCEDURE dbo.spUserDefined_CreateUserDefinedEvent @PUId           INT,
                                                          @EventName      NVarchar(50),
                                                          @EventSubtypeId INT,
                                                          @StartTime      DATETIME,
                                                          @EndTime        DATETIME,
                                                          @EventStatus    TINYINT     = NULL,
                                                          @CommentId      INT         = NULL,
                                                          @Cause4         INT         = NULL,
                                                          @Cause3         INT         = NULL,
                                                          @Cause2         INT         = NULL,
                                                          @Cause1         INT         = NULL,
                                                          @UserId         INT,
                                                          @EventId        INT OUTPUT

 AS
BEGIN
    IF @PUId IS NULL
       OR NOT EXISTS(SELECT TOP 1 PU_Id FROM Prod_Units WHERE PU_Id = @PUId)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Unit not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'Unit',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @PUId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF @EventName IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'EventName not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'EventName',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF @EventSubtypeId IS NULL
       OR NOT EXISTS(SELECT TOP 1 Event_Subtype_Id FROM Event_Subtypes WHERE Event_Subtype_Id = @EventSubtypeId)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'EventSubtype not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'EventSubtype',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @EventSubtypeId,
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
    DECLARE @StartTimeDB DATETIME= dbo.fnServer_CmnConvertToDBTime(@StartTime, 'UTC')
    DECLARE @EndTimeDB DATETIME= dbo.fnServer_CmnConvertToDBTime(@EndTime, 'UTC')
    IF @StartTimeDB >= @EndTimeDB
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
    DECLARE @SheetIds INTEGERTABLETYPE
    INSERT INTO @SheetIds
    SELECT Sheet_Id FROM Sheets WHERE Sheet_type = 25
                                      AND Master_Unit = @PUId
    --IF NOT EXISTS(SELECT 1
    --                     FROM @SheetIds AS S
    --                          LEFT JOIN Sheet_Variables AS SV ON SV.Sheet_Id = S.Item
    --                          LEFT JOIN Sheet_Display_Options AS SDO ON SDO.Sheet_Id = S.Item
    --                                                                    AND SDO.Display_Option_Id = 461
    --                     WHERE SV.Sheet_Id IS NOT NULL
    --                           OR ISNULL(SDO.Value, 0) = 1)
    --    BEGIN
    --        SELECT Code = 'InvalidData',
    --               Error = 'Variables not configured',
    --               ErrorType = 'VariablesNotFound',
    --               PropertyName1 = 'Sheet',
    --               PropertyName2 = '',
    --               PropertyName3 = '',
    --               PropertyName4 = '',
    --               PropertyValue1 = '',
    --               PropertyValue2 = '',
    --               PropertyValue3 = '',
    --               PropertyValue4 = ''

    --        RETURN
    --    END
    IF NOT EXISTS(SELECT 1 FROM(SELECT dbo.fnActivities_CheckSheetSecurityForActivities(Item, 8, 3, @PUId, @UserId) AS AddSecurity FROM @SheetIds) AS S WHERE S.AddSecurity = 1)
        BEGIN
            SELECT Code = 'InsufficientPermission',
                   Error = 'Insufficient permissions to add event',
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
---------------------------------------------------------------------------------------------------------------------------
--DE111559--------Check for event conflict , Should not allow multiple ude with same sub type on same unit on same end time
---------------------------------------------------------------------------------------------------------------------------
	IF EXISTS(SELECT 1 FROM User_Defined_Events WHERE PU_Id = @PUId AND End_Time = @EndTimeDB AND Event_Subtype_Id = @EventSubtypeId)
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
	


    EXEC spServer_DBMgrUpdUserEvent 1010, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @Cause4, @Cause3, @Cause2, @Cause1, NULL, 0, NULL, @EventSubtypeId, @PUID, @EventName, @EventId OUTPUT, @UserId, NULL, @StartTimeDB, @EndTimeDB, NULL, NULL, NULL, NULL, NULL, 1, @CommentId, NULL, NULL, NULL, NULL, @EventStatus, NULL
    EXEC spUserDefined_GetUserDefinedEvent @EventId
END
