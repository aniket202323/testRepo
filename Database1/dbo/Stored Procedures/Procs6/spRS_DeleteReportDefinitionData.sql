CREATE PROCEDURE [dbo].[spRS_DeleteReportDefinitionData]
@Report_Id int
 AS
Delete from Report_Definition_Data where Report_id = @Report_Id
