/* This stored procedure is used by Report Server Version 2*/
CREATE PROCEDURE dbo.spRS_DeleteReportQue
@Que_Id int
AS
  Delete from report_que
  Where Que_Id = @que_id
If @@Error <> 0 Return (1)
Return (0)
