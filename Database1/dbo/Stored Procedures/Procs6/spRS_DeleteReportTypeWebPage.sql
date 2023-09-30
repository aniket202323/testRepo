CREATE PROCEDURE dbo.spRS_DeleteReportTypeWebPage
@ReportTypeId int, 
@WebPageId int
 AS
Delete From Report_Type_Webpages
Where Report_Type_Id = @ReportTypeId
and RWP_Id = @WebPageId
