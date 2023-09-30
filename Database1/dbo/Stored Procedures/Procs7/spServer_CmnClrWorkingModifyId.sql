CREATE PROCEDURE dbo.spServer_CmnClrWorkingModifyId
@PendingTaskId int
AS
Update PendingTasks Set WorkStarted = 0, WorkStartedTime = NULL Where (Pending_Task_Id = @PendingTaskId)
