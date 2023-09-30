CREATE FUNCTION dbo.fnCMN_GetSheetDisplayOptionValues(@SheetIds         NVARCHAR(MAX),
                                                      @DisplayOptionIds NVARCHAR(MAX))
RETURNS @Output TABLE(Sheet_Id                   INT,
                      Display_Option_Id          INT,
                      Display_Option_Description nVARCHAR(255),
                      Value                      NVARCHAR(MAX),
                      Value_Descripton           NVARCHAR(MAX))
AS
BEGIN
    DECLARE @SheetIdList INTEGERTABLETYPE, @DisplayOptionIdList INTEGERTABLETYPE
    INSERT INTO @SheetIdList
    SELECT Item FROM dbo.fnCMN_SplitString(@SheetIds, ',')
    INSERT INTO @DisplayOptionIdList
    SELECT Item FROM dbo.fnCMN_SplitString(@DisplayOptionIds, ',');
    WITH CTE_Sheets
         AS (
         SELECT Sheet_Id FROM Sheets WHERE Sheet_Id IN(SELECT * FROM @SheetIdList))
         INSERT INTO @Output
         SELECT S.Sheet_Id,
                DOL.Item,
                DO.Display_Option_Desc,
                SDO.Value,
                FT.Field_Desc
                FROM CTE_Sheets AS S
                     CROSS JOIN @DisplayOptionIdList AS DOL
                     INNER JOIN Display_Options AS DO ON DO.Display_Option_Id = DOL.Item
                     LEFT JOIN Sheet_Display_Options AS SDO ON SDO.Sheet_Id = S.Sheet_Id
                                                               AND SDO.Display_Option_Id = DO.Display_Option_Id
                     LEFT JOIN ED_FieldType_ValidValues AS FT ON FT.ED_Field_Type_Id = DO.Field_Type_Id
                                                                 AND CONVERT(nVARCHAR(200), FT.Field_Id) = CONVERT(nVARCHAR(200), SDO.Value)
    RETURN
END
