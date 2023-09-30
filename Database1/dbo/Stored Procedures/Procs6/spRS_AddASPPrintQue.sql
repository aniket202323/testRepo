CREATE PROCEDURE dbo.spRS_AddASPPrintQue
@ReportId int
AS
-----------------------------------------------------------------------------
-- Table Containing Each Reports Individual Printer/PrintStyle Configuration
-----------------------------------------------------------------------------
Create Table #Printout(
 	 RowId int,
 	 PrinterId int,
 	 Copies int,
 	 PrinterName varchar(255)
)
Declare @Printers varchar(7000)
Declare @PrintStyles varchar(7000)
Declare @PrintOutCount int
Declare @Exists int
-- Get Printers and PrintStyles for this report definition
exec spRS_GetReportParamValue 'Printers', @ReportId, @Printers output
exec spRS_GetReportParamValue 'PrintStyles', @ReportId, @PrintStyles output
-- Determine if this report definition is configured to use a printer
Insert Into #Printout(RowId, PrinterId, Copies, PrinterName) Exec spRS_ReadPrintConfiguration @Printers, @PrintStyles
select @PrintOutCount = Count(*) from #Printout
-- If @PrintOutCount > 0 then this definition is configured to use a printer
-- and should be added to the asp print que
if (@PrintOutCount > 0)
  Begin
 	 -- Check if it is already in the que...
 	 Select @Exists = Max(QId) From Report_ASPPrintQue Where ReportId = @ReportId
 	 If @Exists Is Null
 	   Begin
         	 Insert Into Report_ASPPrintQue(ReportId, RunAttempts) Values(@ReportId, 1)
 	   End
 	 Select * from Report_ASPPrintQue Where ReportId = @ReportId
  End
Drop Table #Printout
