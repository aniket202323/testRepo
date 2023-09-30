CREATE PROCEDURE [dbo].[spRS_WWWDeleteReportDefinitionData]
@Report_Id int
 AS
Delete From Report_Definition_Data Where Report_Id = @Report_Id
Select * From Report_Definition_Data Where Report_Id = @Report_Id
