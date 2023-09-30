CREATE PROCEDURE [dbo].[spASP_GetSheetIdByDesc]
@p_SheetDesc nVarChar(50)
AS 
SELECT 	 Sheet_Id
FROM 	 Sheets
WHERE 	 Sheet_Desc = @p_SheetDesc
