CREATE TABLE [dbo].[PendingTasks] (
    [Pending_Task_Id] INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [ActualId]        INT           NOT NULL,
    [Misc]            VARCHAR (255) NULL,
    [OldTimestamp]    DATETIME      NULL,
    [PU_Id]           INT           NULL,
    [TaskId]          INT           NOT NULL,
    [Timestamp]       DATETIME      NULL,
    [WorkStarted]     BIT           CONSTRAINT [PendingTasks_DF_WorkStarted] DEFAULT ((0)) NOT NULL,
    [WorkStartedTime] DATETIME      NULL,
    CONSTRAINT [PK_PendingTasks] PRIMARY KEY NONCLUSTERED ([Pending_Task_Id] ASC),
    CONSTRAINT [PendingTasks_FK_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Tasks] ([TaskId])
);


GO
CREATE CLUSTERED INDEX [PendingTasks_IX_TaskIdPendingTaskId]
    ON [dbo].[PendingTasks]([TaskId] ASC, [Pending_Task_Id] ASC);


GO
CREATE NONCLUSTERED INDEX [PendingTasks_IX_TaskIdActualId]
    ON [dbo].[PendingTasks]([TaskId] ASC, [ActualId] ASC);

