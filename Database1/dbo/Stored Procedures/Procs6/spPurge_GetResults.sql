CREATE PROCEDURE dbo.spPurge_GetResults(@PurgeId int) AS
DECLARE @CurrentRun Int
SELECT @CurrentRun = max(RunId) 
 	 From PurgeResult
SELECT PurgeResult_Id,PurgeResult_Desc,PurgeResult_Recs,MinutesRun = (TotalSeconds) /60.0,RecordsPerMinute = Case When TotalSeconds = 0 Then 0 ELSE PurgeResult_Recs/(TotalSeconds) * 60 End
 	  	  from PurgeResult
 	  	  where RunId = @CurrentRun
