CREATE PROCEDURE dbo.spRS_DeleteReportWebPageParameter
@RWP_Id int,
@RP_Id int
 AS
Delete From Report_WebPage_Parameters
Where RWP_Id = @RWP_Id
and RP_Id = @RP_Id
