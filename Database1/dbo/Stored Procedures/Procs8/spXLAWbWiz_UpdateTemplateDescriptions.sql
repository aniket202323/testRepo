--spXLAWbWiz_UpdateTemplateDescriptions(). Proficy Publish-To-Web Wizard uses this stored procedure to rename template
-- rename template (Report_Types.Description) and its description (Report_Types.Detail_Desc). Wizard will check
-- for unique Report_Types.Description before calling this stored procedure.  mt/11-27-2002
--
CREATE PROCEDURE dbo.spXLAWbWiz_UpdateTemplateDescriptions
 	   @Report_Type_Id       Int
 	 , @Description  	         Varchar(255) 
 	 , @Detail_Desc          Varchar(255)
        , @ReturnStatus         Int OUTPUT
AS
SELECT @ReturnStatus = -1  --initialize
UPDATE Report_Types SET Description = @Description, Detail_Desc = @Detail_Desc WHERE Report_Type_Id = @Report_Type_Id
SELECT @ReturnStatus = @@Error
