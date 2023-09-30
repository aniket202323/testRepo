CREATE PROCEDURE dbo.spRS_GetPrinters
 AS
Select * 
from Report_Printers
where Printer_Id > 1
