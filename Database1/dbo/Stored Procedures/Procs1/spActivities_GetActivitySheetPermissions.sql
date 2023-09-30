
CREATE PROCEDURE dbo.spActivities_GetActivitySheetPermissions @SheetList VARCHAR(100), -- Sheet Ids seperated by a comma
                                                              @UserId    INT -- User Id
AS
    BEGIN

        IF @SheetList IS NOT NULL
            BEGIN
                DECLARE @SheetIdList INTEGERTABLETYPE

                INSERT INTO @SheetIdList
                SELECT Item FROM dbo.fnActivities_SplitString(@SheetList, ',')

                SELECT DISTINCT
                       S.Sheet_Id AS                                                                      SheetId,
                       dbo.fnActivities_CheckSheetSecurityForActivities(S.Sheet_Id, 454, 3,
                                                                                         CASE S.Sheet_Type
                                                                                             WHEN 1
                                                                                             THEN SD.Value
                                                                                             ELSE S.Master_Unit
                                                                                         END, @UserId) AS OverrideLock
                       FROM @SheetIdList AS SL
                            JOIN Sheets AS S ON S.Sheet_Id = SL.Item
                            LEFT JOIN Sheet_Display_Options AS SD ON SD.Sheet_Id = S.Sheet_Id
                                                                     AND SD.Display_Option_Id = 446
            END
    END
