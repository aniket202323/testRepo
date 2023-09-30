CREATE PROCEDURE dbo.spServer_CmnWorkingModifyId
@PendingTaskId int
AS
Update PendingTasks Set WorkStarted = 1, WorkStartedTime = dbo.fnServer_CmnGetDate(GetUTCDate()) Where (Pending_Task_Id = @PendingTaskId)
