CREATE TABLE [dbo].[TrackedVariable_WorkflowSchedule] (
    [VariableDefinitionId]     NVARCHAR (64)    NOT NULL,
    [Version]                  BIGINT           NULL,
    [WorkflowScheduleId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [TrackedVariable_WorkflowSchedule_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision]) REFERENCES [dbo].[WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision])
);

