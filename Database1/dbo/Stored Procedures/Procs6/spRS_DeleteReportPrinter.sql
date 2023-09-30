CREATE PROCEDURE dbo.spRS_DeleteReportPrinter
@Printer_Id int
 AS
  Delete From Report_Printers Where Printer_Id = @Printer_Id
  Return (0) -- Delete ok
