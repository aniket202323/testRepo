

CREATE PROCEDURE dbo.spActivities_GetGroupHeaders @Transaction_Id   INT,
                                                  @StatusList       NVARCHAR(100) = NULL, -- Optional activity statuses seperated by a comma
                                                  @EquipmentList    NVARCHAR(max) = NULL, -- Optional Filter List of Equipments seperated by a comma
                                                  @EventTypeList    NVARCHAR(max) = NULL, -- Optional Filter List of Event Types seperated by a comma
                                                  @ProductList      NVARCHAR(max) = NULL, -- Optional Filter List of Products seperated by a comma
                                                  @ProcessOrderList NVARCHAR(max) = NULL, -- Optional Filter List of Process Orders seperated by a comma
                                                  @CompleteType     nvarchar(20)  = NULL, -- Optional Filter List of Complete activity types
                                                  @VariableName     NVARCHAR(100) = NULL, -- Optional Variable Description
                                                  @ProcessOrderName nvarchar(200) = NULL, -- Optional Process Order name
                                                  @ProductCode      nvarchar(200) = NULL, -- Optional Product Code
                                                  @Event            NVARCHAR(100) = NULL, -- Optional Prodution Event / User Defined Event
                                                  @Batch            NVARCHAR(100) = NULL, -- Optional Batch Prodution Event
                                                  @IsOverdue        TINYINT      = NULL, -- Optional is overdue indicator
                                                  @DisplayType      TINYINT      = NULL, -- Optional Filter for Display Type
                                                  @TimeSelection    INT          = NULL, -- Optional Time Selection to fetch start and end times basing on time selection
                                                  @StartTime        DATETIME     = NULL, -- Minimum start time of the activity
                                                  @EndTime          DATETIME     = NULL, -- Maximum end time of the activity
                                                  @TimeZone         nvarchar(200) = NULL, -- Ex: 'India Standard Time','Central Stardard Time'
                                                  @StartTimeOutput  DATETIME     = NULL OUTPUT, -- Returns the start time for the selected time range
                                                  @EndTimeOutput    DATETIME     = NULL OUTPUT -- Returns the end time for the selected time range

 AS
BEGIN
    
 ---------------------------------------------Set default values-----------------------------------------------
    IF @Transaction_Id IS NULL
        BEGIN
            SET @Transaction_Id = 1
        END
-------------------------------------------Get activities for variable---------------------------------------------
    IF @VariableName IS NOT NULL
        BEGIN
            DECLARE @VariableIdList INTEGERTABLETYPE, @ActivityIdList INTEGERTABLETYPE, @LocalVariableId INT

            INSERT INTO @VariableIdList
            SELECT Var_Id FROM Variables WHERE Var_Desc = @VariableName

            INSERT INTO @ActivityIdList
            SELECT A.ActivityId FROM @VariableIdList AS V
                                     CROSS APPLY dbo.fnActivities_GetActivitiesForVariable(V.Item) AS A
        END
    DECLARE @Now DATETIME= (SELECT dbo.fnServer_CmnGetDate(GETUTCDATE())) 
--------------------------------------------------------------------------------------------------------------------
    IF @EquipmentList IS NOT NULL
        BEGIN
            DECLARE @TopEquipmentId INT= (SELECT TOP 1 Item FROM dbo.fnCMN_SplitString(@EquipmentList, ','))
            IF @TopEquipmentId IS NOT NULL
               AND @TimeSelection IS NOT NULL
               AND @TimeSelection <> 7
                BEGIN
                    DECLARE @TempEndTime DATETIME= @EndTime
                    EXECUTE dbo.spBF_CalculateOEEReportTime @TopEquipmentId, @TimeSelection, @StartTime OUTPUT, @EndTime OUTPUT, 0
                    IF @TempEndTime IS NOT NULL
                        BEGIN
                            SET @EndTime = @TempEndTime
                        END
                END
        END

    IF @StartTime IS NOT NULL
        BEGIN
            SET @StartTime = dbo.fnServer_CmnConvertToDBTime(@StartTime, @TimeZone)
        END

    IF @EndTime IS NOT NULL
        BEGIN
            SET @Endtime = dbo.fnServer_CmnConvertToDBTime(@Endtime, @TimeZone)
        END

    DECLARE @Sql NVARCHAR(MAX);

    SET @Sql = '';

    IF @Transaction_Id = 1 --Product
        BEGIN
            SET @Sql+='SELECT ISNULL(P1.Prod_Id,P.Prod_Id) AS        Id,
                                     ISNULL(P1.Prod_Desc,P.Prod_Desc) AS Name, ';
        END
        ELSE
        BEGIN
            IF @Transaction_Id = 2
                BEGIN --Equipment
                    SET @Sql+='SELECT DISTINCT
                               PUB.PU_Id AS            Id,
                               PUB.PU_Desc AS          Name, ';
                END
                ELSE
                BEGIN
                    IF @Transaction_Id = 3 --Process Order
                        BEGIN
                            SET @Sql+='SELECT DISTINCT
                                       PP.PP_Id AS             Id,
                                       PP.Process_Order AS     Name, '
                        END
                        ELSE
                        BEGIN
                            IF @Transaction_Id = 4 --Events
                                BEGIN
                                    SET @Sql+='SELECT DISTINCT
                                               AT.Activity_Type_Id AS  Id,
                                               AT.Activity_Desc AS     Name, '
                                END
                        END
                END
        END

	   SET @Sql += 'COUNT(A.Activity_Id) AS             ActivityCount,
                     COUNT(CASE
					WHEN CASE
						    WHEN A.End_Time IS NULL
						    THEN DATEDIFF(SECOND, @Now, DATEADD(MINUTE, A.Target_Duration, A.Execution_Start_Time))
						    ELSE DATEDIFF(SECOND, A.End_Time, DATEADD(MINUTE, A.Target_Duration, A.Execution_Start_Time))
						END < 0
					THEN 1
				 END) AS OverdueCount ';

    IF @StatusList IS NOT NULL
       OR @EndTime IS NOT NULL
        BEGIN
            DECLARE @SubSql NVARCHAR(MAX)= 'FROM (SELECT * FROM Activities WITH (NOLOCK) WHERE 1 = 1 ';
            IF @EndTime IS NOT NULL
                BEGIN
                    SET @SubSql+='AND Execution_Start_Time <= @EndTime '
                    IF @StartTime IS NOT NULL
                        BEGIN
                            SET @SubSql+='AND Execution_Start_Time >= @StartTime '
                        END
                END

            IF @CompleteType IS NOT NULL
                BEGIN
                    SET @SubSql+='AND (Activity_Status = 3 AND Complete_Type IN ('+@CompleteType+') '
                    -- Remove status 3 from status list
                    SET @StatusList = REPLACE(@StatusList,
                                              CASE
                                                  WHEN @StatusList LIKE '%3,%'
                                                  THEN '3,'
                                                  WHEN @StatusList LIKE '%,3%'
                                                  THEN ',3'
                                                  ELSE '3'
                                              END, '')

                    IF @StatusList <> ''
                        BEGIN
                            SET @SubSql+='OR Activity_Status IN ('+@StatusList+') ';
                        END
                    SET @SubSql+=') '
                END
                ELSE
                BEGIN
                    IF @StatusList IS NOT NULL
                        BEGIN
                            SET @SubSql+='AND Activity_Status IN ('+@StatusList+') ';
                        END
                END

            SET @SubSql+=')AS A ';
            SET @Sql+=@SubSql
        END
        ELSE
        BEGIN
            SET @Sql+='FROM Activities AS A ';
        END

    SET @Sql+='INNER JOIN Activity_Statuses AS AST WITH (NOLOCK) ON AST.ActivityStatus_Id = A.Activity_Status
               INNER JOIN Activity_Types AS AT WITH (NOLOCK) ON AT.Activity_Type_Id = A.Activity_Type_Id
               INNER JOIN Prod_Units_Base AS PUB WITH (NOLOCK) ON PUB.PU_Id = A.PU_Id
               INNER JOIN Prod_Lines_Base AS PLB WITH (NOLOCK) ON PLB.PL_Id = PUB.PL_Id
               LEFT JOIN Departments_Base AS DB WITH (NOLOCK) ON DB.Dept_Id = PLB.Dept_Id
               LEFT JOIN Users AS U WITH (NOLOCK) ON U.User_Id = A.UserId
               LEFT JOIN Production_Plan_Starts AS PPS WITH (NOLOCK) ON PPS.PU_Id = PUB.PU_Id
                                                                       AND PPS.Start_Time <= A.KeyId
                                                                       AND (PPS.End_Time > A.KeyId
                                                                               OR PPS.End_Time IS NULL)
			LEFT JOIN Production_Plan AS PP WITH (NOLOCK) ON PP.PP_Id = PPS.PP_Id
			LEFT JOIN Production_Starts AS PS WITH (NOLOCK) ON PS.PU_Id = PUB.PU_Id
                                                                   AND PS.Start_Time <= A.KeyId
                                                                   AND (PS.End_Time > A.KeyId
                                                                            OR PS.End_Time IS NULL)
               LEFT JOIN Events E1 WITH (NOLOCK) ON E1.PU_Id = PUB.PU_ID AND E1.TimeStamp = A.KeyId                                                                       
               LEFT JOIN Products AS P WITH (NOLOCK) ON P.Prod_Id = PS.Prod_Id 
			LEFT JOIN Products P1 WITH (nolock) ON P1.Prod_Id = E1.Applied_Product'
    --Joining required tables
    IF @ProcessOrderList IS NOT NULL
       OR @ProcessOrderName IS NOT NULL
        BEGIN
            SET @Sql+='LEFT JOIN Production_Plan AS PP WITH (NOLOCK) ON PP.PP_Id = PPS.PP_Id '
        END

    IF @Event IS NOT NULL
       OR @Batch IS NOT NULL
        BEGIN
            SET @Sql+='LEFT JOIN Events AS E WITH (NOLOCK) ON E.Event_Id = A.KeyId1
                                                        AND A.Activity_Type_Id = 2 '
            IF @Event IS NOT NULL
                BEGIN
                    SET @Sql+='LEFT JOIN User_Defined_Events AS UDE WITH (NOLOCK) ON UDE.UDE_Id = A.KeyId1
															 AND A.Activity_Type_Id = 3 '
                END
        END

    SET @Sql+=' WHERE 1 = 1 '
    --Adding where conditions if required
    IF @ProductList IS NOT NULL
        BEGIN
            SET @Sql+='AND P.Prod_Id IN ('+@ProductList+') '
        END

    IF @EquipmentList IS NOT NULL
        BEGIN
            SET @Sql+='AND A.PU_Id IN ('+@EquipmentList+') '
        END

    IF @ProcessOrderList IS NOT NULL
        BEGIN
            SET @Sql+='AND PP.PP_Id IN ('+@ProcessOrderList+') '
        END

    IF @EventTypeList IS NOT NULL
        BEGIN
            SET @Sql+='AND A.Activity_Type_Id IN ('+@EventTypeList+') '
        END

    IF @IsOverdue IS NOT NULL
        BEGIN
            SET @Sql+='AND CASE
						  WHEN A.End_Time IS NULL
						  THEN DATEDIFF(SECOND, @Now, DATEADD(MINUTE, A.Target_Duration, A.Execution_Start_Time))
						  WHEN A.End_Time IS NOT NULL
						  THEN DATEDIFF(SECOND, A.End_Time, DATEADD(MINUTE, A.Target_Duration, A.Execution_Start_Time))
					   END < 0 '
        END

    IF @ProcessOrderName IS NOT NULL
        BEGIN
            SET @Sql+='AND PP.Process_Order = @ProcessOrderName '
        END

    IF @ProductCode IS NOT NULL
        BEGIN
            SET @Sql+='AND ISNULL(P1.Prod_Code,P.Prod_Code) = @ProductCode '
        END

    IF @Event IS NOT NULL
        BEGIN
            SET @Sql+='AND ((A.Activity_Type_Id = 3
                                AND UDE.UDE_Desc = @Event)
                                OR (A.Activity_Type_Id = 2
                                AND E.Event_Num = @Event)) '
        END

    IF @Batch IS NOT NULL
        BEGIN
            SET @Sql+='AND A.Activity_Type_Id = 2
						  AND E.Event_Num = @Batch '
        END

    IF @VariableName IS NOT NULL
        BEGIN
            SET @Sql+='AND EXISTS(SELECT 1 FROM @ActivityIdList WHERE Item = A.Activity_Id) '
        END

    IF @DisplayType IS NOT NULL
        BEGIN
            SET @Sql+='AND A.Display_Activity_Type_Id = @DisplayType '
        END

    IF @Transaction_Id = 1 --Product
        BEGIN
            SET @Sql+='AND ISNULL(P1.Prod_Id,P.Prod_Id) IS NOT NULL
                       GROUP BY ISNULL(P1.Prod_Id,P.Prod_Id),
                                ISNULL(P1.Prod_Desc,P.Prod_Desc)
                       ORDER BY ISNULL(P1.Prod_Desc,P.Prod_Desc) DESC ';
        END
        ELSE
        BEGIN
            IF @Transaction_Id = 2 --Equipment
                BEGIN
                    SET @Sql+='AND PUB.PU_Id IS NOT NULL
                               GROUP BY PUB.PU_Id,
                                        PUB.PU_Desc
                               ORDER BY PUB.PU_Desc DESC ';
                END
                ELSE
                BEGIN
                    IF @Transaction_Id = 3 --Process Order
                        BEGIN
                            SET @Sql+='AND PP.PP_Id IS NOT NULL
                                       GROUP BY PP.PP_Id,
                                                PP.Process_Order
                                       ORDER BY PP.Process_Order DESC '
                        END
                        ELSE
                        BEGIN
                            IF @Transaction_Id = 4 --Events
                                BEGIN
                                    SET @Sql+='AND AT.Activity_Type_Id IS NOT NULL
                                               GROUP BY AT.Activity_Type_Id,
                                                        AT.Activity_Desc
                                               ORDER BY AT.Activity_Desc DESC '
                                END
                        END
                END
        END

    EXEC sp_executesql @Sql, N'@Now DATETIME, @StatusList NVARCHAR(20), @ProcessOrderName NVARCHAR(200), @ProductCode NVARCHAR(200), @Event NVARCHAR(200), @Batch NVARCHAR(200), @StartTime DATETIME, @EndTime DATETIME, @TimeZone NVARCHAR(200), @ActivityIdList IntegerTableType READONLY', @Now, @StatusList, @ProcessOrderName, @ProductCode, @Event, @Batch, @StartTime, @EndTime, @TimeZone, @ActivityIdList
    SET @StartTimeOutput = dbo.fnserver_CmnConvertFromDbTime(@StartTime, @TimeZone);
    SET @EndTimeOutput = dbo.fnserver_CmnConvertFromDbTime(@EndTime, @TimeZone);
END
