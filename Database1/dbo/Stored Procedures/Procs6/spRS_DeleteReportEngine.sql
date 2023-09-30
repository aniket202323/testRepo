CREATE PROCEDURE dbo.spRS_DeleteReportEngine
@EngineId int
 AS
Delete from Report_Runs
Where Engine_Id = @EngineId
Delete From Report_Engines
Where Engine_Id = @EngineId
If @@Error <> 0
  Return (1)
Else
  Return (0)
