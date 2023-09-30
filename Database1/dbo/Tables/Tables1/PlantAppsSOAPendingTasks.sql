CREATE TABLE [dbo].[PlantAppsSOAPendingTasks] (
    [PendingTaskId] INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ActualId]      INT     NOT NULL,
    [TableId]       INT     NOT NULL,
    [WorkStarted]   TINYINT CONSTRAINT [PlantAppsSOAPendingTasks_DF_WorkStarted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PlantAppsSOAPendingTasks_PK_PendingTaskId] PRIMARY KEY NONCLUSTERED ([PendingTaskId] ASC)
);


GO
CREATE CLUSTERED INDEX [PlantAppsSOAPendingTasks_IX_TaskIdPendingTaskId]
    ON [dbo].[PlantAppsSOAPendingTasks]([TableId] ASC, [PendingTaskId] ASC);

