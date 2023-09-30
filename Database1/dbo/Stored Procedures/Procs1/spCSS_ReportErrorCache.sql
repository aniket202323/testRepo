CREATE PROCEDURE dbo.spCSS_ReportErrorCache 
AS
SELECT [Error_Id], [Response_Id] FROM [dbo].[Report_Engine_Errors]
