
CREATE PROCEDURE dbo.spActivities_GetSheetDisplayOptionValues @SheetIds         NVARCHAR(MAX),
                                                              @DisplayOptionIds NVARCHAR(MAX)

 AS
BEGIN

    SELECT * FROM fnCMN_GetSheetDisplayOptionValues(@SheetIds, @DisplayOptionIds);
END

