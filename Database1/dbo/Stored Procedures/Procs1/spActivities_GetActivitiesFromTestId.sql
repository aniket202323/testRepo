
/*
 Sproc to get the list of ActivityIds associated with a TestId

*/

CREATE PROCEDURE dbo.spActivities_GetActivitiesFromTestId @TestId BIGINT = 0
AS
    BEGIN

        SET @TestId = COALESCE(@TestId, 0)
        DECLARE @SQL NVARCHAR(max)
        DECLARE @ActivityIds TABLE(ActivityId     BIGINT, 
                                   ActivityTypeId INT)

        DECLARE @VariableId INT, @EventId INT, @ResultOn DATETIME;

        SELECT @VariableId = Var_Id, 
               @EventId = ISNULL(Event_Id, 0), 
               @ResultOn = Result_On FROM Tests WHERE Test_Id = @TestId;

        SELECT @SQL = '
WITH SV_Base
     AS (
     SELECT Sheet_Id,
            Var_Id,
            Title,
            Title_Var_Order_Id,
            Var_Order FROM Sheet_Variables WHERE SHEET_ID IN (SELECT SHEET_ID FROM Sheet_Variables WHERE
			Var_Id = ' + CAST(@VariableId AS nVARCHAR) + '
			)),
     SV
     AS (
     SELECT S1.Sheet_Id,
            CASE
                WHEN S2.Var_Order = S1.Title_Var_Order_Id
                     AND S2.Sheet_Id = S1.Sheet_Id
                     AND S2.Title IS NOT NULL
                     AND ISNULL(SDO.Value, 0) = 1
                THEN S2.Title
                ELSE S1.Title
            END AS Title
            FROM SV_Base AS S1
                 JOIN SV_Base AS S2 ON S2.Sheet_Id = S1.Sheet_Id
                                       AND S1.Var_Id = ' + CAST(@VariableId AS nVARCHAR) + '
                                       AND (S2.Var_Order = S1.Title_Var_Order_Id
                                            AND S2.Title IS NOT NULL
                                            OR ISNULL(S2.Title_Var_Order_Id,0) = ISNULL(S1.Title_Var_Order_Id,0)
                                            AND S2.Var_Id = S1.Var_Id
                                            AND S2.Title IS NULL
                                            AND ISNULL(S2.Title_Var_Order_Id,0) = 0)
                 LEFT JOIN Sheet_Display_Options AS SDO ON S1.Sheet_Id = SDO.Sheet_Id
                                                           AND SDO.Display_Option_Id = 445)
	
     SELECT A.Activity_Id AS ActivityId
            FROM (Select Activity_Id,Activity_type_id,KeyId, KeyId1,Sheet_Id,Title from Activities'
        IF @EventId <> 0
            BEGIN
                SELECT @SQL = @SQL + ' WHERE Activity_type_id in (2,3,4,5) '
        END
        ELSE
            BEGIN
                SELECT @SQL = @SQL + ' WHERE Activity_type_id =1 '
        END

        SELECT @SQL = @SQL + ') AS A
                 JOIN SV ON SV.Sheet_Id = A.Sheet_Id'
        IF @EventId <> 0
            BEGIN
                SELECT @SQL = @SQL + ' LEFT JOIN Events AS E ON E.Event_Id = A.KeyId1
                                         AND A.Activity_Type_Id = 2'
        END

        SELECT @SQL = @SQL + '
            WHERE ISNULL(A.Title, '''') = ISNULL(SV.Title, '''')
                  AND ((A.Activity_Type_Id NOT in (4,5) and ' + CAST(@EventId AS nVARCHAR) + ' = '

        IF @EventId <> 0
            BEGIN
                SELECT @SQL = @SQL + '	A.KeyId1 '
        END
        ELSE
            BEGIN
                SELECT @SQL = @SQL + '	0 '
        END

        SELECT @SQL = @SQL + ') OR 1=1)'
        IF @EventId <> 0
            BEGIN
                SELECT @SQL = @SQL + ' AND ''' + CONVERT(nVARCHAR, @ResultOn, 25) + ''' = CASE A.Activity_Type_Id
                                      WHEN 2
                                      THEN  E.TimeStamp ELSE A.KeyId END'
        END
        ELSE
            BEGIN
                SELECT @SQL = @SQL + ' AND ''' + CONVERT(nVARCHAR, @ResultOn, 25) + ''' = A.KeyId'
        END
        EXEC (@SQL)
    END

