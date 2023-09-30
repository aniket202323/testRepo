CREATE PROCEDURE dbo.spRS_DeleteReportDefWebPage
@ReportId int,
@RWP_Id int
 AS
Delete From Report_Def_WebPages
Where Report_Def_Id = @ReportId
and RWP_Id = @RWP_Id
