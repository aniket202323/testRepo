

CREATE PROCEDURE dbo.spProduction_UpdateProductionEvent @EventId                          INT, 
                                                        @UserId                           INT, 
                                                        @EventNum                         NVarchar(50), 
                                                        @StartTime                        DATETIME, 
                                                        @EndTime                          DATETIME, 
                                                        @EventStatus                      TINYINT, 
                                                        @FinalDimensionX                  FLOAT       = NULL, 
                                                        @FinalDimensionY                  FLOAT       = NULL, 
                                                        @FinalDimensionZ                  FLOAT       = NULL, 
                                                        @FinalDimensionA                  FLOAT       = NULL, 
                                                        @AppliedProduct                   INT         = NULL, 
                                                        @SendProductChangeActivityMessage BIT         = NULL
AS
    BEGIN
        DECLARE @PUId INT, @TimeStamp DATETIME, @InitialDimensionX FLOAT, @InitialDimensionY FLOAT, @InitialDimensionZ FLOAT, @InitialDimensionA FLOAT


        SELECT @PUId = PU_Id, 
               @TimeStamp = TimeStamp FROM Events WHERE Event_Id = @EventId
        IF @EndTime IS NULL
            BEGIN
                SET @EndTime = dbo.fnServer_CmnConvertFromDBTime(@TimeStamp, 'UTC')
        END
        SELECT @InitialDimensionX = Initial_Dimension_X, 
               @InitialDimensionY = Initial_Dimension_Y, 
               @InitialDimensionZ = Initial_Dimension_Z, 
               @InitialDimensionA = Initial_Dimension_A
               FROM Event_Details
               WHERE Event_Id = @EventId

        DECLARE @SheetIds INTEGERTABLETYPE
        INSERT INTO @SheetIds
        SELECT Sheet_Id FROM Sheets WHERE Sheet_type = 2
                                          AND Master_Unit = @PUId

        IF NOT EXISTS(SELECT 1 FROM(SELECT dbo.fnActivities_CheckSheetSecurityForActivities(Item, 46, 3, @PUId, @UserId) AS AddSecurity FROM @SheetIds) AS S WHERE S.AddSecurity = 1)
            BEGIN
                SELECT Code = 'InsufficientPermission', 
                       Error = 'Insufficient permissions to edit event', 
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
        IF EXISTS(SELECT TOP 1 Event_Id FROM Events WHERE PU_Id = @PUId
                                                          AND Event_Num = @EventNum
                                                          AND Event_Id <> @EventId)
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
        IF EXISTS(SELECT TOP 1 Event_Id FROM events AS E WHERE E.PU_Id = @PUId
                                                               AND E.TimeStamp = @EndTimeDB
                                                               AND Event_Id <> @EventId)
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
        IF @InitialDimensionX IS NULL
           AND @FinalDimensionX IS NOT NULL
            BEGIN
                SELECT Code = 'InvalidData', 
                       Error = 'Invalid - Initial Value required to set Final Value', 
                       ErrorType = 'MissingInitialValue', 
                       PropertyName1 = 'InitialDimensionX', 
                       PropertyName2 = 'FinalDimensionX', 
                       PropertyName3 = '', 
                       PropertyName4 = '', 
                       PropertyValue1 = @InitialDimensionX, 
                       PropertyValue2 = @FinalDimensionX, 
                       PropertyValue3 = '', 
                       PropertyValue4 = ''
                RETURN
        END
        IF @InitialDimensionY IS NULL
           AND @FinalDimensionY IS NOT NULL
            BEGIN
                SELECT Code = 'InvalidData', 
                       Error = 'Invalid - Initial Value required to set Final Value', 
                       ErrorType = 'MissingInitialValue', 
                       PropertyName1 = 'InitialDimensionY', 
                       PropertyName2 = 'FinalDimensionY', 
                       PropertyName3 = '', 
                       PropertyName4 = '', 
                       PropertyValue1 = @InitialDimensionY, 
                       PropertyValue2 = @FinalDimensionY, 
                       PropertyValue3 = '', 
                       PropertyValue4 = ''
                RETURN
        END
        IF @InitialDimensionZ IS NULL
           AND @FinalDimensionZ IS NOT NULL
            BEGIN
                SELECT Code = 'InvalidData', 
                       Error = 'Invalid - Initial Value required to set Final Value', 
                       ErrorType = 'MissingInitialValue', 
                       PropertyName1 = 'InitialDimensionZ', 
                       PropertyName2 = 'FinalDimensionZ', 
                       PropertyName3 = '', 
                       PropertyName4 = '', 
                       PropertyValue1 = @InitialDimensionZ, 
                       PropertyValue2 = @FinalDimensionZ, 
                       PropertyValue3 = '', 
                       PropertyValue4 = ''
                RETURN
        END
        IF @InitialDimensionA IS NULL
           AND @FinalDimensionA IS NOT NULL
            BEGIN
                SELECT Code = 'InvalidData', 
                       Error = 'Invalid - Initial Value required to set Final Value', 
                       ErrorType = 'MissingInitialValue', 
                       PropertyName1 = 'InitialDimensionA', 
                       PropertyName2 = 'FinalDimensionA', 
                       PropertyName3 = '', 
                       PropertyName4 = '', 
                       PropertyValue1 = @InitialDimensionA, 
                       PropertyValue2 = @FinalDimensionA, 
                       PropertyValue3 = '', 
                       PropertyValue4 = ''
                RETURN
        END
        IF @InitialDimensionX IS NOT NULL
           AND @FinalDimensionX IS NOT NULL
           AND @FinalDimensionX > @InitialDimensionX
            BEGIN
                SELECT Code = 'InvalidData', 
                       Error = 'Invalid - Final Value cannot be greater than Initial Value', 
                       ErrorType = 'FinalValueGreaterThanInitialValue', 
                       PropertyName1 = 'InitialDimensionX', 
                       PropertyName2 = 'FinalDimensionX', 
                       PropertyName3 = '', 
                       PropertyName4 = '', 
                       PropertyValue1 = @InitialDimensionX, 
                       PropertyValue2 = @FinalDimensionX, 
                       PropertyValue3 = '', 
                       PropertyValue4 = ''
                RETURN
        END
        IF @InitialDimensionY IS NOT NULL
           AND @FinalDimensionY IS NOT NULL
           AND @FinalDimensionY > @InitialDimensionY
            BEGIN
                SELECT Code = 'InvalidData', 
                       Error = 'Invalid - Final Value cannot be greater than Initial Value', 
                       ErrorType = 'FinalValueGreaterThanInitialValue', 
                       PropertyName1 = 'InitialDimensionY', 
                       PropertyName2 = 'FinalDimensionY', 
                       PropertyName3 = '', 
                       PropertyName4 = '', 
                       PropertyValue1 = @InitialDimensionY, 
                       PropertyValue2 = @FinalDimensionY, 
                       PropertyValue3 = '', 
                       PropertyValue4 = ''
                RETURN
        END
        IF @InitialDimensionZ IS NOT NULL
           AND @FinalDimensionZ IS NOT NULL
           AND @FinalDimensionZ > @InitialDimensionZ
            BEGIN
                SELECT Code = 'InvalidData', 
                       Error = 'Invalid - Final Value cannot be greater than Initial Value', 
                       ErrorType = 'FinalValueGreaterThanInitialValue', 
                       PropertyName1 = 'InitialDimensionZ', 
                       PropertyName2 = 'FinalDimensionZ', 
                       PropertyName3 = '', 
                       PropertyName4 = '', 
                       PropertyValue1 = @InitialDimensionZ, 
                       PropertyValue2 = @FinalDimensionZ, 
                       PropertyValue3 = '', 
                       PropertyValue4 = ''
                RETURN
        END
        IF @InitialDimensionA IS NOT NULL
           AND @FinalDimensionA IS NOT NULL
           AND @FinalDimensionA > @InitialDimensionA
            BEGIN
                SELECT Code = 'InvalidData', 
                       Error = 'Invalid - Final Value cannot be greater than Initial Value', 
                       ErrorType = 'FinalValueGreaterThanInitialValue', 
                       PropertyName1 = 'InitialDimensionA', 
                       PropertyName2 = 'FinalDimensionA', 
                       PropertyName3 = '', 
                       PropertyName4 = '', 
                       PropertyValue1 = @InitialDimensionA, 
                       PropertyValue2 = @FinalDimensionA, 
                       PropertyValue3 = '', 
                       PropertyValue4 = ''
                RETURN
        END

        EXECUTE spServer_DBMgrUpdEvent @EventId, @EventNum, @PUId, @EndTimeDB, @AppliedProduct, NULL, @EventStatus, 2, 0, @UserId, NULL, NULL, NULL, @StartTimeDB, NULL, 2, NULL

        EXECUTE spServer_DBMgrUpdEventDet @UserId, @EventId, NULL, NULL, 1, 0, NULL, NULL, @InitialDimensionX, @InitialDimensionY, @InitialDimensionZ, @InitialDimensionA, @FinalDimensionX, @FinalDimensionY, @FinalDimensionZ, @FinalDimensionA, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL

        EXECUTE spProduction_GetEventDetails @EventId

        --Send Messages to related activities by inserting records into Pending result sets
        IF @SendProductChangeActivityMessage = 1
            BEGIN;
                WITH ActivitiyIdsView
                     AS (SELECT Activity_Id FROM Activities AS a WHERE a.Activity_Type_Id = 2 -- Production event
                                                                       AND a.KeyId1 = @EventId)
                     INSERT INTO Pending_ResultSets( Processed, 
                                                     RS_Value, 
                                                     User_Id, 
                                                     Entry_On )
                     SELECT 0, 
                            (SELECT ResultSetType = 4, 
                                    TopicId = 300, 
                                    MessageKey = b.PU_Id, -- Message Key
                                    PUId = b.PU_Id, -- Also put it in the topic result set
                                    EventType = b.Activity_Type_Id, 
                                    KeyId = b.KeyId1, 
                                    KeyTime = b.KeyId, 
                                    ActivityId = a.Activity_Id, 
                                    ActivityDesc = b.Activity_Desc, 
                                    APriority = b.Activity_Priority, 
                                    AStatus = b.Activity_Status, 
                                    StartTime = dbo.fnServer_CmnConvertFromDbTime(b.Start_Time, 'UTC'), 
                                    EndTime = dbo.fnServer_CmnConvertFromDbTime(b.End_Time, 'UTC'), 
                                    TDuration = b.Target_Duration, 
                                    Title = b.Title, 
                                    UserId = b.UserId, 
                                    EntryOn = dbo.fnServer_CmnConvertFromDbTime(b.EntryOn, 'UTC'), 
                                    TransType = 2, 
                                    PercentComplete = b.PercentComplete, 
                                    Tag = b.Tag, 
                                    ExecutionStartTime = b.Execution_Start_Time, 
                                    AutoComplete = b.Auto_Complete, 
                                    ExtendedInfo = b.Extended_Info, 
                                    ExternalLink = b.External_Link, 
                                    TestsToComplete = b.Tests_To_Complete, 
                                    Locked = b.Locked, 
                                    CommentId = b.Comment_Id, 
                                    OverdueCommentId = b.Overdue_Comment_Id, 
                                    SkipCommentId = b.Skip_Comment_Id, 
                                    SheetId = b.Sheet_Id, 
                                    TransNum = 0, 
                                    LockActivity = b.Lock_Activity_Security, 
                                    NeedOverdueComment = b.Overdue_Comment_Security
                                    FROM ActivitiyIdsView AS a
                                         LEFT JOIN Activities AS b ON b.Activity_Id = a.Activity_Id FOR XML PATH('row'), ROOT('rows')), 
                            @UserId, 
                            dbo.fnServer_CmnGetDate(GETUTCDATE())
        END

        -- Send a post message to update dependent data on event details
        --EXEC spServer_DBMgrUpdPendingResultSet NULL, 14, @EventId, 2, 2, 10, @UserId
    END

