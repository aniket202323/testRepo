-- ECR #25526(mt/5-12-2003): Want Publish-To-Web Wizard (via ProficyAddIn) existing template list sorted by 
-- "Template Name" (which corresponds to field name "Description").
-- ECR #26538 (mt/9-22-2003): Safeguard against template w/o XLTs: SP change. Add To Where-Clause AND Template_File Is NOT NULL
--
CREATE PROCEDURE dbo.spXLAWbWiz_GetReportTypes
 	   @Report_Type_Id Int = NULL
 	 , @Description    Varchar(255) = NULL
AS
If @Report_Type_Id Is NOT NULL --get single record based on ID
  BEGIN
    SELECT t.Report_Type_Id, t.Description, t.Template_File_Name, t.Date_Saved, t.Date_Tested_Locally, t.Date_Tested_Remotely, t.Image_Ext, t.Detail_Desc
      FROM Report_Types t WHERE t.Is_AddIn = 1 AND t.Report_Type_Id = @Report_Type_Id 
  END
Else If @Description Is NOT NULL --get single record based on "Description"
  BEGIN  
    SELECT t.Report_Type_Id, t.Description, t.Template_File_Name, t.Date_Saved, t.Date_Tested_Locally, t.Date_Tested_Remotely, t.Image_Ext, t.Detail_Desc
      FROM Report_Types t WHERE t.Is_AddIn = 1 AND t.Description = @Description
  END
Else -- @Report_Type_Id & @Description are null; get complete list of ProficyAddIn templates (Currently Wizard only uses this code)
  BEGIN
      SELECT t.Report_Type_Id, t.Description, t.Template_File_Name, t.Date_Saved, t.Date_Tested_Locally, t.Date_Tested_Remotely , t.Image_Ext, t.Detail_Desc
        FROM Report_Types t WHERE t.Is_AddIn = 1 AND Template_File Is NOT NULL -- added AND Template_File Is NOT NULL; mt/9-22-2003
    ORDER BY t.Description
  END
--EndIf:Report_Type_Id
