CREATE TABLE [dbo].[LinkedDocument_WorkflowSchedule] (
    [DocumentId]               UNIQUEIDENTIFIER NOT NULL,
    [DocumentName]             NVARCHAR (50)    NULL,
    [DocumentUrlUnc]           NVARCHAR (255)   NULL,
    [Version]                  BIGINT           NULL,
    [WorkflowScheduleId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC, [DocumentId] ASC),
    CONSTRAINT [LinkedDocument_WorkflowSchedule_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision]) REFERENCES [dbo].[WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision])
);

