CREATE PROCEDURE dbo.spRS_DeleteReportEngineMessage
@MessageId int
 AS
Delete From Report_Engine_Activity
Where REA_Id = @MessageId
If @@Error <> 0
  Return (1)
Else
  Return (0)
