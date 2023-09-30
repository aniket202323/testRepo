CREATE TABLE [dbo].[LinkedDocument_StepDefinition_WorkflowSchedule] (
    [DocumentId]               UNIQUEIDENTIFIER NOT NULL,
    [DocumentName]             NVARCHAR (50)    NULL,
    [DocumentUrlUnc]           NVARCHAR (255)   NULL,
    [Version]                  BIGINT           NULL,
    [WorkflowScheduleId]       UNIQUEIDENTIFIER NOT NULL,
    [WorkflowScheduleRevision] BIGINT           NOT NULL,
    [StepDefinitionId]         NVARCHAR (64)    NOT NULL,
    PRIMARY KEY CLUSTERED ([WorkflowScheduleId] ASC, [WorkflowScheduleRevision] ASC, [StepDefinitionId] ASC, [DocumentId] ASC),
    CONSTRAINT [LinkedDocument_StepDefinition_WorkflowSchedule_StepDefinition_WorkflowSchedule_Relation1] FOREIGN KEY ([WorkflowScheduleId], [WorkflowScheduleRevision], [StepDefinitionId]) REFERENCES [dbo].[StepDefinition_WorkflowSchedule] ([WorkflowScheduleId], [WorkflowScheduleRevision], [StepDefinitionId])
);

