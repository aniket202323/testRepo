CREATE PROCEDURE dbo.spServer_CmnPrintFile
@FileName nVarChar(1000), @PrinterName nVarChar(1000) = NULL, @Copies tinyint = 1,
@DeleteFlag bit = 1, @MoveToDirectory nVarChar(1000) = NULL,
@ErrorDirectory nVarChar(1000) = NULL
 AS
insert
   into PrintServer_Files
        (File_Processed, File_Processed_TimeStamp, NumberOfAttempts,
         FileName, PrinterName, Copies, DeleteFlag, MoveToDirectory,
         ErrorDirectory)
 values (0, NULL, 0, @FileName, @PrinterName, @Copies, @DeleteFlag,
         @MoveToDirectory, @ErrorDirectory)
