CREATE PROCEDURE dbo.spServer_PrtSvrMarkAttempt
@File_ID int
 AS
Update PrintServer_Files
   set NumberOfAttempts = NumberOfAttempts + 1
 where File_ID = @File_ID
