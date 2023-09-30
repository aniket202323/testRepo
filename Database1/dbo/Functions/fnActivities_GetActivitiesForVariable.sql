
CREATE FUNCTION dbo.fnActivities_GetActivitiesForVariable(@VariableId INT)
RETURNS @Activities TABLE(ActivityId INT,
                          SheetId    INT)
AS
BEGIN
    WITH S
         AS (
         SELECT DISTINCT
                SV.Sheet_Id,
                SV.Var_Order,
                SV.Title_Var_Order_Id,
                SDO.Display_Option_Id,
                CASE
                    WHEN SDO.Display_Option_Id = 445
                    THEN Value
                    ELSE 0
                END AS                                                           Value,
                ROW_NUMBER() OVER(PARTITION BY SV.Sheet_Id ORDER BY SV.Sheet_Id,
                                                                    CASE
                                                                        WHEN SDO.Display_Option_Id = 445
                                                                        THEN 1
                                                                        ELSE 0
                                                                    END DESC) AS RowNumber
                FROM Sheet_Variables AS SV
                     JOIN Sheet_Display_Options AS SDO ON SV.Sheet_Id = SDO.Sheet_Id
                WHERE SV.Var_Id = @VariableId)
         INSERT INTO @Activities
         SELECT CASE
                    WHEN A1.Activity_Id IS NULL
                    THEN A2.Activity_Id
                    ELSE A1.Activity_Id
                END AS ActivityId,
                S.Sheet_Id
                FROM S
                     LEFT JOIN Activities AS A1 ON A1.Sheet_Id = S.Sheet_Id
                                                   AND S.Value = 0
                     LEFT JOIN Sheet_Variables AS SV ON SV.Sheet_Id = S.Sheet_Id
                                                        AND SV.Var_Order = S.Title_Var_Order_Id
                     LEFT JOIN Activities AS A2 ON A2.Sheet_Id = S.Sheet_Id
                                                   AND S.Value = 1
                                                   AND SV.Title = A2.Title
                WHERE S.RowNumber = 1
    RETURN
END

