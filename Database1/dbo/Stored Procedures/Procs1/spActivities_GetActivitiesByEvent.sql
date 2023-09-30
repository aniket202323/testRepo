
CREATE PROCEDURE dbo.spActivities_GetActivitiesByEvent @EventType INT, -- 1-> Sheet column, 2-> Production event, 3-> UDE based
                                                       @EventId   INT, -- Used for UDE and production event
                                                       @SheetId   INT, -- Used for sheet
                                                       @PUId      INT, -- Unit ID for product chagne event
                                                       @ResultOn  DATETIME --Used for sheet columns

  AS
BEGIN

    DECLARE @ResultOnDB DATETIME= dbo.fnserver_CmnConvertToDbTime(@ResultOn, 'UTC');
    IF @EventType = 1
        BEGIN
            SELECT Activity_Id AS          ActivityId,
                   Activity_Desc AS        ActivityDesc,
                   Title AS                Title,
                   Start_Time AS           StartTime,
                   End_Time AS             EndTime,
                   Execution_Start_Time AS ExecutionStartTime,
                   Activity_Priority AS    ActivityPriority,
                   Comment_Id AS           CommentId
                   FROM Activities
                   WHERE KeyId = @ResultOnDB
                         AND Sheet_Id = @SheetId
        END

    IF @EventType = 4
        BEGIN
			--NOTE: Workaround to map activity to events as the activty time is 1 second earlier to that of event.
            SET @ResultOnDB = DATEADD(SECOND, -1, CONVERT(DATETIME, CONVERT(NVARCHAR(20), @ResultOnDB, 120)));

            SELECT Activity_Id AS          ActivityId,
                   Activity_Desc AS        ActivityDesc,
                   Title AS                Title,
                   Start_Time AS           StartTime,
                   End_Time AS             EndTime,
                   Execution_Start_Time AS ExecutionStartTime,
                   Activity_Priority AS    ActivityPriority,
                   Comment_Id AS           CommentId
                   FROM Activities
                   WHERE KeyId = @ResultOnDB
                         AND PU_Id = @PUId
        END
        ELSE
        BEGIN
            IF @EventType IN(2, 25)
                BEGIN
                    SELECT Activity_Id AS          ActivityId,
                           Activity_Desc AS        ActivityDesc,
                           Title AS                Title,
                           Start_Time AS           StartTime,
                           End_Time AS             EndTime,
                           Execution_Start_Time AS ExecutionStartTime,
                           Activity_Priority AS    ActivityPriority,
                           Comment_Id AS           CommentId
                           FROM Activities
                           WHERE KeyId1 = @EventId
							and case when @EventType = 25 then 3 Else @EventType end = Activity_Type_Id
                END
                ELSE
                BEGIN
                    RETURN NULL
                END
        END
END

