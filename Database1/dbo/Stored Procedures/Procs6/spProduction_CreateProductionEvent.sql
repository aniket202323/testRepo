
CREATE PROCEDURE dbo.spProduction_CreateProductionEvent @PUId           INT,
                                                        @EventNum       NVarchar(50),
                                                        @StartTime      DATETIME,
                                                        @EndTime        DATETIME,
                                                        @EventStatus    TINYINT     = NULL,
                                                        @AppliedProduct INT         = NULL,
                                                        @CommentId      INT         = NULL,
                                                        @UserId         INT,
                                                        @EventId        INT OUTPUT

AS
BEGIN
    IF @PUId IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Unit not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'Unit',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF NOT EXISTS(SELECT TOP 1 PU_Id FROM Prod_Units WHERE PU_Id = @PUId)
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
    IF @EventNum IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Evet Number not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'EventNumber',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF EXISTS(SELECT TOP 1 Event_Id FROM Events WHERE PU_Id = @PUId
                                                      AND Event_Num = @EventNum)
        BEGIN
            SELECT Code = 'EventRecordConflict',
                   Error = 'Invalid - Another event exists on the selected product with the same Event Number',
                   ErrorType = 'EventNumberConflict',
                   PropertyName1 = 'EventNum',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @EventNum,
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
    IF @EndTimeDB > DATEADD(HOUR, 2, dbo.fnServer_CmnGetDate(GETUTCDATE()))
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'End time must be less than 2 hours from now',
                   ErrorType = 'InvalidParameterValue',
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
    IF EXISTS(SELECT TOP 1 Event_Id FROM events AS E WHERE E.PU_Id = @PUId
                                                           AND E.TimeStamp = @EndTimeDB)
        BEGIN
            SELECT Code = 'EventRecordConflict',
                   Error = 'Invalid - Another event exists on the selected product in this StartTime and EndTime',
                   ErrorType = 'TimeRangeConflict',
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

    IF @AppliedProduct IS NOT NULL
       AND NOT EXISTS(SELECT TOP 1 Prod_Id FROM Products WHERE Prod_Id = @AppliedProduct)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Product not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'Product',
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
    SELECT Sheet_Id FROM Sheets WHERE Sheet_type = 2
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

    EXEC spServer_DBMgrUpdEvent @EventId OUTPUT, @EventNum, @PUId, @EndTimeDB, @AppliedProduct, NULL, @EventStatus, 1, 1010, @UserId, @CommentId, NULL, NULL, @StartTimeDB, NULL, NULL, NULL

    IF @EventId IS NOT NULL
        BEGIN
            EXEC spProduction_GetEventDetails @EventId
        END
        ELSE
        BEGIN
            SELECT Code = 'EventRecordConflict',
                   Error = 'Invalid - Another event exists on the selected product in this StartTime and EndTime',
                   ErrorType = 'TimeRangeConflict',
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
END
