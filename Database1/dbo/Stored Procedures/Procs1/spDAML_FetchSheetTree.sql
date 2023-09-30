CREATE PROCEDURE [dbo].[spDAML_FetchSheetTree] 
AS
BEGIN
    SELECT 	  	 TreeCode = '1',
 	  	  	  	 SheetGroupId = IsNull(sg.Sheet_Group_Id,0), 
 	  	  	  	 SheetGroupName = sg.Sheet_Group_Desc,
 	  	  	  	 SheetId = IsNull(s.Sheet_Id,0), 
 	  	  	  	 SheetName = s.Sheet_Desc
     FROM 	  	 Sheets s 
 	  INNER JOIN 	 Sheet_Groups sg ON sg.Sheet_Group_Id = s.Sheet_Group_Id
    -- order is critical if the load is to be successful 	  	  	  	  	  	  	  	 
 	 ORDER BY TreeCode, SheetGroupName, SheetName
END
