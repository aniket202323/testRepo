CREATE PROCEDURE dbo.spServer_PrtSvrGetFiles
 AS
Select File_Id, FileName, PrinterName, Copies, DeleteFlag,
       MoveToDirectory, ErrorDirectory, NumberOfAttempts
  from PrintServer_Files
 where File_Processed = 0
