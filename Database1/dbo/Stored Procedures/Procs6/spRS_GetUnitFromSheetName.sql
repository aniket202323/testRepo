CREATE PROCEDURE dbo.spRS_GetUnitFromSheetName
 	 @SheetName varchar(50) = NULL
AS
--***********************************/
select master_unit from Sheets where sheet_desc = ltrim(rtrim(@Sheetname))
