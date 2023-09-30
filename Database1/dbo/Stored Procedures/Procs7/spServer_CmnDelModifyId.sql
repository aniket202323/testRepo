CREATE PROCEDURE dbo.spServer_CmnDelModifyId
@PendingTaskId int
AS
Delete From PendingTasks Where (Pending_Task_Id = @PendingTaskId)
