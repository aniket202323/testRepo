
CREATE PROCEDURE dbo.spActivities_GetVariablesForActivity @ActivityId INT

AS
BEGIN
    DECLARE @SheetId INT, @AliasColumnId INT;
    SELECT @SheetId = A.Sheet_Id FROM Activities AS A WHERE A.Activity_Id = @ActivityId;

    SET @AliasColumnId = ISNULL((SELECT Value FROM dbo.Sheet_Display_Options AS SDO WHERE SDO.Display_Option_Id = 458
                                                                                          AND SDO.Sheet_Id = @SheetId), 0);

    WITH V(VariableId)
         AS (
         SELECT varId AS VariableId FROM fnActivities_GetVariablesForActivity(@ActivityId))
         SELECT VariableId,
                Var_Desc AS VariableName,
                CASE @AliasColumnId
                    WHEN 0
                    THEN V1.Var_Desc
                    WHEN 1
                    THEN ISNULL(V1.User_Defined1, V1.Var_Desc)
                    WHEN 2
                    THEN ISNULL(V1.User_Defined2, V1.Var_Desc)
                    WHEN 3
                    THEN ISNULL(V1.User_Defined3, V1.Var_Desc)
                END AS      VariableAlias
                FROM V
                     INNER JOIN dbo.Variables AS V1 ON V.VariableId = V1.Var_Id
END

