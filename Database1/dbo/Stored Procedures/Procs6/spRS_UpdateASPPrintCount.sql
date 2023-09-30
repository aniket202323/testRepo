CREATE PROCEDURE dbo.spRS_UpdateASPPrintCount
@ReportId int
AS
Update Report_ASPPrintQue Set
 	 RunAttempts = RunAttempts + 1
 	 Where ReportId = @ReportId
