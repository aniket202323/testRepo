
CREATE PROCEDURE dbo.spTime_CreateTimeBasedEvent @SheetId   INT,
                                                 @Timestamp DATETIME,
                                                 @CommentId INT,
                                                 @UserId    INT

 AS
BEGIN
    IF @SheetId IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Sheet not found',
                   ErrorType = 'ParameterResourceNotFound',
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
    IF NOT EXISTS(SELECT TOP 1 Sheet_Id FROM Sheets WHERE Sheet_Id = @SheetId)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Sheet not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'Sheet',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @SheetId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF @Timestamp IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Timestamp not found',
                   ErrorType = 'InvalidParameterValue',
                   PropertyName1 = 'Timestamp',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    DECLARE @TimestampDB DATETIME= dbo.fnServer_CmnConvertToDBTime(@Timestamp, 'UTC')
    IF @TimestampDB > DATEADD(HOUR, 2, dbo.fnServer_CmnGetDate(GETUTCDATE()))
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Timestamp must be less than 2 hours from now',
                   ErrorType = 'InvalidParameterValue',
                   PropertyName1 = 'Timestamp',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @Timestamp,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END

    DECLARE @SecurityCheck INT, @UnitId INT
    SELECT @UnitId = Value FROM Sheet_Display_Options WHERE Display_Option_Id = 446
                                                            AND Sheet_Id = @SheetId
    SELECT @SecurityCheck = dbo.fnActivities_CheckSheetSecurityForActivities(@SheetId, 8, 3, @UnitId, @UserId)
    IF @SecurityCheck <> 1
        BEGIN
            SELECT Code = 'InsufficientPermission',
                   Error = 'Invalid add attempt',
                   ErrorType = '',
                   PropertyName1 = '',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END

    IF EXISTS(SELECT TOP 1 Result_On FROM Sheet_Columns WHERE Sheet_Id = @SheetId
                                                              AND Result_On = @TimestampDB)
        BEGIN
            SELECT Code = 'EventRecordConflict',
                   Error = 'Invalid - Another event exists on the selected product in this Timestamp',
                   ErrorType = 'TimestampConflict',
                   PropertyName1 = 'Timestamp',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @Timestamp,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    DECLARE @DisplayActivityTypeId INT= ISNULL((SELECT Value FROM Sheet_Display_Options WHERE Sheet_Id = @SheetId
                                                                                              AND Display_Option_Id = 461), 0)
    --IF NOT EXISTS(SELECT 1 FROM Sheet_Variables WHERE Sheet_Id = @SheetId)
    --   AND @DisplayActivityTypeId <> 1
    --    BEGIN
    --        SELECT Code = 'InvalidData',
    --               Error = 'Variables not configured',
    --               ErrorType = 'VariablesNotFound',
    --               PropertyName1 = 'Sheet',
    --               PropertyName2 = '',
    --               PropertyName3 = '',
    --               PropertyName4 = '',
    --               PropertyValue1 = @SheetId,
    --               PropertyValue2 = '',
    --               PropertyValue3 = '',
    --               PropertyValue4 = ''
    --        RETURN
    --    END

    DECLARE @PUId INT;
    SELECT @PUId = Value FROM Sheet_Display_Options WHERE display_option_id = 446
                                                          AND Sheet_id = @SheetId
    DECLARE @SheetIds INTEGERTABLETYPE
    INSERT INTO @SheetIds
    SELECT @SheetId

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

    BEGIN
        EXEC spServer_DBMgrUpdColumn2 @SheetId, NULL, @TimestampDB, 1010, @UserId, @CommentId, NULL, NULL, NULL, NULL, NULL, NULL
        EXEC spTime_GetSheetColumns NULL, NULL, NULL, @TimestampDB, @SheetId, @UserId
        -- Send a post message to update dependent data on sheet columns
        EXEC spServer_DBMgrUpdPendingResultSet NULL, 20, @SheetId, 1, 1010, 7, @UserId, @TimestampDB
    END
END
