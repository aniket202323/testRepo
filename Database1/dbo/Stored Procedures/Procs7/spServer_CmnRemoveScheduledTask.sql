Create Procedure dbo.spServer_CmnRemoveScheduledTask
@ActualId int,
@TableId int
AS
Delete From PendingTasks Where (ActualId = @ActualId) And (TaskId in (Select TaskId From Tasks Where TableId = @TableId))
