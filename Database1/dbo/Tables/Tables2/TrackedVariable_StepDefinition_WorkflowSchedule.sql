CREATE TABLE [dbo].[TrackedVariable_StepDefinition_WorkflowSchedule] (
    [StepDefinitionId]         NVARCHAR (64)    NOT NULL,
    [VariableDefinitionId]     NVARCHAR (64)    NOT NULL,
    [Version]                  BIGINT           NULL,
    [WorkflowScheduleId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision] BIGINT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC, [StepDefinitionId] ASC, [VariableDefinitionId] ASC),
    CONSTRAINT [TrackedVariable_StepDefinition_WorkflowSchedule_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision]) REFERENCES [dbo].[WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision])
);

