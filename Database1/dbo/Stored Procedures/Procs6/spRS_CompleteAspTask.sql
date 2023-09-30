CREATE PROCEDURE [dbo].[spRS_CompleteAspTask]
@Schedule_Id int
 AS
-----------------------------------
-- Local Variables
-----------------------------------
Declare @ReportId Int
-----------------------------------
-- Get Other Schedule Information
-----------------------------------
Select @ReportId = Report_Id 
From   Report_Schedule 
Where  Schedule_Id = @Schedule_Id 
-----------------------------------
-- Set The Next Run Interval
-----------------------------------
exec spRS_UpdateAdvancedReportQue @Schedule_Id
--------------------------------
-- Put Request Into Print Que
--------------------------------
exec spRS_AddASPPrintQue @ReportId
--------------------------------
-- Reset Schedule Fields
--------------------------------
Update report_schedule Set 
Status = 4, 
Last_Result = 1, 
Computer_Name = NULL, 
Process_Id = NULL 
Where Schedule_Id = @Schedule_Id
