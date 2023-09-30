
CREATE PROCEDURE dbo.spActivities_UpdateActivity @Activity_Id        BIGINT,
                                                 @Activity_Status    INT    = NULL,
                                                 @Comment_Id 		 INT    = NULL,
                                                 @Overdue_Comment_Id INT    = NULL,
                                                 @Skip_Comment_Id    INT    = NULL,
                                                 @UserId             INT

 AS
    BEGIN
		------------------------------------------Error Handling---------------------------------------------------
        IF @Activity_Id = ''
            BEGIN
                SET @Activity_Id = NULL
            END
        IF @Activity_Status = ''
            BEGIN
                SET @Activity_Status = NULL
            END

        IF NOT EXISTS(SELECT 1 FROM Activities WHERE Activity_Id = @Activity_Id)
           OR @Activity_Id IS NULL
            BEGIN
                SELECT Code = 'ResourceNotFound',
                       Error = 'Activity Id is Invalid ',
                       ErrorType = 'InvalidParameterValue',
                       PropertyName1 = 'Activity Id',
                       PropertyName2 = '',
                       PropertyName3 = '',
                       PropertyName4 = '',
                       PropertyValue1 = @Activity_Id,
                       PropertyValue2 = '',
                       PropertyValue3 = '',
                       PropertyValue4 = ''
                RETURN
            END
		-----------------------------------------------------------------------------------------------------------
        DECLARE @Activity_Status_Updated INT, @Error INT, @StartTime DATETIME, @EndTime DATETIME, @SheetId INT, @UnitId INT, @IsLocked INT, @CurrentActivityUser INT, @CanBeLocked INT, @CanOverride INT, @ActivityTypeId INT, @ActivityStatus_Exist INT, @Now DATETIME;
        SET @Now = dbo.fnserver_CmnConvertToDbTime( DateAdd(millisecond,-DatePart(millisecond,GETUTCDATE()),GETUTCDATE()), 'UTC');
        SELECT @SheetId = Sheet_Id,
               @UnitId = PU_Id,
               @IsLocked = ISNULL(Locked, 0),
               @CanBeLocked = Lock_Activity_Security,
               @ActivityTypeId = Activity_Type_Id,
               @ActivityStatus_Exist = Activity_Status,
               @CurrentActivityUser = ISNULL(UserId, ''),
               @StartTime = COALESCE(Start_Time, @Now),
               @EndTime = @Now
               FROM Activities
               WHERE Activity_Id = @Activity_Id

        BEGIN
            --------Update percent complete and HasAvailableCells when user performs an action and when status is Not Started---------------------------
            IF @Activity_Status IS NULL OR @ActivityStatus_Exist = 1
                BEGIN
                    EXEC spServer_DBMgrUpdActivities @Activity_Id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @ActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL
                END
		  	-------Update the Status In progress when the Perform Button Click-----------------
            IF @Activity_Status = 2
               AND @Error IS NULL
               AND @UserId IS NOT NULL
                BEGIN

                    IF @CanBeLocked = 0
                        BEGIN
                            EXEC dbo.spServer_DBMgrUpdActivities @Activity_Id, NULL, NULL, @Comment_Id, @Activity_Status, NULL, @StartTime, NULL, @ActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 0, @UserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, @Overdue_Comment_Id, @Skip_Comment_Id, NULL, NULL
                        END
                        ELSE
                        BEGIN
                            IF @CanBeLocked = 1
                                BEGIN
							 		--TODO: sanity data check for multiple users
                                    IF @CurrentActivityUser = @UserId
                                       OR @IsLocked = 0
                                        BEGIN
                                            EXEC dbo.spServer_DBMgrUpdActivities @Activity_Id, NULL, NULL, @Comment_Id, @Activity_Status, NULL, @StartTime, NULL, @ActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 0, @UserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, @Overdue_Comment_Id, @Skip_Comment_Id, NULL, NULL
                                        END
                                        ELSE
                                        BEGIN
								    		-- Check can user override
                                            IF dbo.fnActivities_CheckSheetSecurityForActivities(@SheetId, 454, 2, @UnitId, @UserId) = 1
                                               OR (SELECT System FROM users_base WHERE user_id = @CurrentActivityUser) = 1
                                                BEGIN
                                                    EXEC dbo.spServer_DBMgrUpdActivities @Activity_Id, NULL, NULL, @Comment_Id, @Activity_Status, NULL, @StartTime, NULL, @ActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 0, @UserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, @Overdue_Comment_Id, @Skip_Comment_Id, NULL, NULL
                                                END
                                                ELSE
                                                BEGIN
										  			--throw ERROR
                                                    SELECT Code = 'InvalidOperation',
                                                           Error = 'Locked by other user',
                                                           ErrorType = 'ResourceLocked',
                                                           PropertyName1 = 'Unit',
                                                           PropertyName2 = '',
                                                           PropertyName3 = '',
                                                           PropertyName4 = '',
                                                           PropertyValue1 = @CurrentActivityUser,
                                                           PropertyValue2 = @UserId,
                                                           PropertyValue3 = '',
                                                           PropertyValue4 = ''
                                                    RETURN
                                                END
                                        END
                                END
                        END
                    GOTO Fetch_Data
                END
			-------Update the Status Complete when the Complete Button Click-------------------
            IF @Activity_Status = 3
               AND @Error IS NULL
                BEGIN
                    EXEC dbo.spServer_DBMgrUpdActivities @Activity_Id, NULL, NULL, @Comment_Id, @Activity_Status, NULL, NULL, @EndTime, @ActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 0, @UserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, @Overdue_Comment_Id, @Skip_Comment_Id, NULL, NULL
                    GOTO Fetch_Data
                END
			-------Update the Status Skipped when the Skip Button Click------------------------
            IF @Activity_Status = 4
               AND @Error IS NULL
                BEGIN
                    EXEC dbo.spServer_DBMgrUpdActivities @Activity_Id, NULL, NULL, @Comment_Id, @Activity_Status, NULL, @StartTime, @EndTime, @ActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 0, @UserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, @Overdue_Comment_Id, @Skip_Comment_Id, NULL, NULL
                    GOTO Fetch_Data
                END
			-------Update the Status Released when the release Button Click------------------------
            IF @Activity_Status = 5
               AND @Error IS NULL
               AND @UserId IS NOT NULL
                BEGIN
                    IF @CurrentActivityUser = @UserId
                        BEGIN
                            EXEC dbo.spServer_DBMgrUpdActivities @Activity_Id, NULL, NULL, @Comment_Id, @Activity_Status, NULL, @StartTime, NULL, @ActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 0, @UserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, @Overdue_Comment_Id, @Skip_Comment_Id, NULL, NULL
                        END
                        ELSE
                        BEGIN
                            IF dbo.fnActivities_CheckSheetSecurityForActivities(@SheetId, 454, 2, @UnitId, @UserId) = 1
                                BEGIN
                                    EXEC dbo.spServer_DBMgrUpdActivities @Activity_Id, NULL, NULL, @Comment_Id, @Activity_Status, NULL, @StartTime, NULL, @ActivityTypeId, NULL, NULL, NULL, NULL, NULL, NULL, 2, 0, @UserId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, @Overdue_Comment_Id, @Skip_Comment_Id, NULL, NULL
                                END
                                ELSE
                                BEGIN
									--throw ERROR
                                    SELECT Code = 'InsufficientPermission',
                                           Error = 'Locked by other user',
                                           ErrorType = 'ResourceLocked',
                                           PropertyName1 = 'ActivityId',
                                           PropertyName2 = '',
                                           PropertyName3 = '',
                                           PropertyName4 = '',
                                           PropertyValue1 = @Activity_Id,
                                           PropertyValue2 = '',
                                           PropertyValue3 = '',
                                           PropertyValue4 = ''
                                    RETURN
                                END
                        END
                    GOTO Fetch_Data
                END
			------------Return The Updated Status record--------------------------------------------------------
            Fetch_Data:
            BEGIN
                EXEC dbo.spActivities_GetActivities @TransactionId = 1, @ActivityId = @Activity_Id, @StatusList = NULL
            END
			----------------------------------------------------------------------------------------------------
        END
    END
