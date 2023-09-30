--spXLAWbWiz_UpdateTemplateFileName(). Proficy Publish-To-Web Wizard uses this stored procedure to update Template_File_Name
-- when an existing template's XLT is replaced successfully. #26454 (mt/9-23-2003)
--
CREATE PROCEDURE dbo.spXLAWbWiz_UpdateTemplateFileName
 	   @Report_Type_Id       Int
 	 , @Template_File_Name 	 Varchar(255) 
        , @ReturnStatus         Int OUTPUT
AS
--SET NOCOUNT ON
SELECT @ReturnStatus = -1  --initialize
UPDATE Report_Types SET Template_File_Name = @Template_File_Name WHERE Report_Type_Id = @Report_Type_Id
SELECT @ReturnStatus = @@Error
