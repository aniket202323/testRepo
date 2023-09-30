CREATE PROCEDURE [dbo].[spASP_GetSheetType]
@Sheet_Id int
AS 
SELECT 	 Sheet_Type_Desc
FROM 	 Sheets
JOIN 	 Sheet_Type ON Sheet_Type = Sheet_Type_Id
WHERE 	 Sheet_Id = @Sheet_Id
