CREATE PROCEDURE dbo.spServer_PrtSvrMarkProcessed
@File_ID int
 AS
Update PrintServer_Files
   set File_Processed = 1, File_Processed_TimeStamp = dbo.fnServer_CmnGetDate(GetUTCDate())
 where File_ID = @File_ID
