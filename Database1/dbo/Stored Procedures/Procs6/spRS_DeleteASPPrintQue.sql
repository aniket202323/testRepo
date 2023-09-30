CREATE PROCEDURE dbo.spRS_DeleteASPPrintQue
@ReportId int
AS
if @ReportId = 0
  Delete From Report_ASPPrintQue
else
  Delete From Report_ASPPrintQue Where ReportId = @ReportId
